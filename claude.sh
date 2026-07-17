#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
BASEDIR="${THISDIR}/claude";
TIME="$(date +%Y%m%d%H%M%S)";
CLEANUPFILE="${1:-${CLEANUPFILE}}"
. "${THISDIR}/functions.sh";

CLAUDEDIR="${HOME}/.claude";
SETTINGS="${CLAUDEDIR}/settings.json";
BASELINE="${BASEDIR}/settings.baseline.json";
HOOKSSRC="${BASEDIR}/hooks";
HOOKSDST="${CLAUDEDIR}/hooks";

# Nothing to configure if the Claude CLI isn't installed
if ! type claude &>/dev/null; then
    echo "claude not found.  Skipping Claude configuration.";
    exit 0;
fi

echo "Configuring Claude...";

# Install cship (Claude Code status line, referenced by the baseline statusLine)
checkfor cship || dangerous "https://cship.dev/install.sh" "bash" "-s" "--" "--yes";

# Ensure ~/.claude and ~/.claude/hooks exist
mkdir -p "${CLAUDEDIR}" "${HOOKSDST}";

# Ensure settings.json exists
[[ -e "${SETTINGS}" ]] || echo '{}' > "${SETTINGS}";

# Merge the baseline into settings.json with a recursive deep merge: existing
# settings win on scalar/object conflicts (the baseline only fills in keys you
# haven't set), but arrays are unioned so baseline entries (e.g. a
# hooks.PreToolUse hook) are always present alongside your own, without
# duplicates. jq's built-in `*` can't do this — it replaces arrays wholesale, so
# a baseline array entry would be dropped whenever that array already exists.
# Only replace settings.json if jq succeeds, so a hand-broken/invalid
# settings.json is left untouched rather than destroyed.
if [[ -e "${BASELINE}" ]]; then
    echo "Merging ${BASELINE} into ${SETTINGS}";
    TMP="$(mktemp)";
    if jq -s '
      def dmerge($a; $b):
        if   ($a|type) == "object" and ($b|type) == "object" then
          reduce (($a + $b) | keys_unsorted[]) as $k ({}; .[$k] = dmerge($a[$k]; $b[$k]))
        elif ($a|type) == "array"  and ($b|type) == "array"  then
          reduce ($b + $a)[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end)
        elif $b == null then $a
        else $b end;
      dmerge(.[0]; .[1])
    ' "${BASELINE}" "${SETTINGS}" > "${TMP}" 2>/dev/null; then
        # Back up the old settings when running as part of a full install
        [[ -n "${CLEANUPFILE}" ]] && cp "${SETTINGS}" "${SETTINGS}.claudebak.${TIME}" && echo "${SETTINGS}.claudebak.${TIME}" >> "${CLEANUPFILE}";
        mv "${TMP}" "${SETTINGS}";
    else
        echo "WARNING: could not merge baseline into ${SETTINGS} (invalid JSON?). Leaving existing settings unchanged." >&2;
        rm -f "${TMP}";
    fi
fi

# Install any enabled plugins that aren't installed yet. Each key under
# .enabledPlugins is a "plugin@marketplace" id, matching the keys under
# .plugins in installed_plugins.json.
INSTALLED_PLUGINS="${CLAUDEDIR}/plugins/installed_plugins.json";
jq -r '.enabledPlugins // {} | to_entries[] | select(.value) | .key' "${BASELINE}" 2>/dev/null | while read -r plugin; do
    [[ -z "${plugin}" ]] && continue;
    if [[ -e "${INSTALLED_PLUGINS}" ]] && jq -e --arg p "${plugin}" '(.plugins // {}) | has($p)' "${INSTALLED_PLUGINS}" &>/dev/null; then
        echo "Plugin ${plugin} already installed.  Skipping.";
    else
        echo "Installing plugin ${plugin}...";
        claude plugin install "${plugin}";
    fi
done

# Symlink each hook under claude/hooks/ into ~/.claude/hooks/
if [[ -d "${HOOKSSRC}" ]]; then
    find "${HOOKSSRC}" -maxdepth 1 -type f ! -name '.gitkeep' 2>/dev/null | while read -r hook; do
        dst="${HOOKSDST}/$(basename "${hook}")";
        # Back up a real (non-symlink) file we're about to replace during a full install
        [[ -e "${dst}" && ! -L "${dst}" && -n "${CLEANUPFILE}" ]] && mv "${dst}" "${dst}.claudebak.${TIME}" && echo "${dst}.claudebak.${TIME}" >> "${CLEANUPFILE}";
        echo "Linking ${dst} -> ${hook}";
        ln -sf "${hook}" "${dst}";
    done
fi
