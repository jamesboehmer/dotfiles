#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
. "${THISDIR}/functions.sh";

# crudini has no brew formula; install it with `uv tool install crudini`.
for x in crudini curl; do
	which $x &>/dev/null || { echo "You must install $x first (crudini: uv tool install crudini)" && exit 1; }
done

PGCLI_BASE_DIR="${HOME}/.config/pgcli";
PGCLI_CONFIG="${PGCLI_BASE_DIR}/config";
PGCLI_LOCAL_CONFIG="${PGCLI_BASE_DIR}/config.local";
PGCLI_DEFAULT_URL="https://raw.githubusercontent.com/dbcli/pgcli/refs/heads/main/pgcli/pgclirc";
CONFIG_D="${THISDIR}/pgcli/config.d";

# Bootstrap the config from the upstream default if it doesn't exist yet.
if [[ ! -f "${PGCLI_CONFIG}" ]]; then
	echo "Creating ${PGCLI_CONFIG} from ${PGCLI_DEFAULT_URL}";
	mkdir -p "${PGCLI_BASE_DIR}";
	curl -fsSL "${PGCLI_DEFAULT_URL}" -o "${PGCLI_CONFIG}" || { echo "Failed to download default pgclirc" >&2; exit 1; }
fi

echo "Updating pgcli named queries...";

# Merge the config.d fragments, then config.local, into the main config with
# crudini. crudini --merge only touches the keys present in its input, so other
# sections, comments, and any queries you've added yourself are left in place.
# Precedence for a given key: existing main config < dotfiles fragments < local.
# Work on a temp copy so a failure never truncates the live config.
cp "${PGCLI_CONFIG}" "${PGCLI_CONFIG}.tmp";
MERGE_OK=true;

for f in "${CONFIG_D}"/*.ini; do
	[[ -e "$f" ]] || continue;
	echo "Merging $(basename "$f")...";
	crudini --merge "${PGCLI_CONFIG}.tmp" < "$f" || { MERGE_OK=false; break; }
done

if [[ "${MERGE_OK}" == true && -f "${PGCLI_LOCAL_CONFIG}" ]]; then
	echo "Applying local overrides from ${PGCLI_LOCAL_CONFIG}...";
	crudini --merge "${PGCLI_CONFIG}.tmp" < "${PGCLI_LOCAL_CONFIG}" || MERGE_OK=false;
fi

if [[ "${MERGE_OK}" == true ]]; then
	# Add/refresh a provenance header. crudini can't write comments, so we do it
	# here: strip any previous managed block (and the blank lines it left) so
	# re-runs refresh rather than accumulate, then prepend a fresh one.
	LOCAL_NOTE="";
	[[ -f "${PGCLI_LOCAL_CONFIG}" ]] && LOCAL_NOTE=" + ${PGCLI_LOCAL_CONFIG}";
	STRIPPED="$(sed '/^# >>> pgcli\.sh managed >>>$/,/^# <<< pgcli\.sh managed <<<$/d' "${PGCLI_CONFIG}.tmp" | sed '/./,$!d')";
	{
		echo "# >>> pgcli.sh managed >>>";
		echo "# Named queries merged by ${THIS}";
		echo "# on $(date).";
		echo "# Sources: ${CONFIG_D}/*.ini${LOCAL_NOTE}";
		echo "# Do not edit the [named queries] section here; edit those sources instead.";
		echo "# <<< pgcli.sh managed <<<";
		echo "";
		printf '%s\n' "${STRIPPED}";
	} > "${PGCLI_CONFIG}.tmp" && mv "${PGCLI_CONFIG}.tmp" "${PGCLI_CONFIG}";
else
	echo "WARNING: failed to update pgcli named queries; leaving ${PGCLI_CONFIG} unchanged." >&2;
	rm -f "${PGCLI_CONFIG}.tmp";
fi
