#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
. "${THISDIR}/functions.sh";

checkfor cship || dangerous "https://cship.dev/install.sh" "bash" "-s" "--" "--yes";

CLAUDECONFIG="${HOME}/.claude/settings.json";
mkdir -p "${HOME}/.claude" &>/dev/null;

[[ ! -e ${CLAUDECONFIG} || "$(cat ${CLAUDECONFIG})" == "" ]] && echo '{}' > "${CLAUDECONFIG}";

CLAUDECONFIGTMP="$(mktemp)";
cat "${CLAUDECONFIG}" | jq '.statusLine = { "type": "command", "command": "cship" }' > "${CLAUDECONFIGTMP}";  mv "${CLAUDECONFIGTMP}" "${CLAUDECONFIG}";
