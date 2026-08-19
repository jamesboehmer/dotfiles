#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
. "${THISDIR}/functions.sh";

# Install Python CLI tools that aren't available as brew formulae (e.g. crudini)
# via `uv tool install`. Tools are listed one per line in uvtools.txt.
if ! which uv &>/dev/null; then
	echo "uv not found.  Skipping uv tools.";
	exit 0;
fi

TOOLS_FILE="${THISDIR}/uvtools.txt";
[[ -f "${TOOLS_FILE}" ]] || exit 0;

# Skip blank lines and comments; uv tool install is a no-op if already present.
grep -vE '^[[:space:]]*(#|$)' "${TOOLS_FILE}" | while read -r tool; do
	tool="$(echo "${tool}" | xargs)";
	[[ -z "${tool}" ]] && continue;
	echo "#### Installing uv tool: ${tool} ####";
	uv tool install "${tool}" < /dev/null;
done
