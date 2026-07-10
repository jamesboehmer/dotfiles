#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
. "${THISDIR}/functions.sh";

for x in herdr jq yq; do
	which $x &>/dev/null || { echo "You must brew install $x first" && exit 1; }
done

export HERDR_BASE_DIR="${HOME}/.config/herdr";
export HERDER_PLUGIN_CONFIG_DIR="${HERDR_BASE_DIR}/plugins/config";
export HERDR_CONFIG="${HERDR_BASE_DIR}/config.toml";

mkdir -p "${HERDER_PLUGIN_CONFIG_DIR}";
touch "${HERDR_CONFIG}";

NEW_KEYS='[
  {"key": "prefix+p", "type": "plugin_action", "command": "jt.command-palette.open", "description": "Plugin Command Palette"}
]'

echo "Updating herdr config...";

yq -p toml -o json '.' "${HERDR_CONFIG}" | \
jq --argjson newkeys "${NEW_KEYS}" '
  .onboarding = false |
  .keys.command = ((.keys.command // []) + $newkeys
    | reduce .[] as $item ([]; if any(.[]; .key == $item.key) then . else . + [$item] end))
' | yq -p json -o toml > "${HERDR_CONFIG}.tmp" && mv "${HERDR_CONFIG}.tmp" "${HERDR_CONFIG}"

[[ "${REINSTALL_PLUGINS}" == "true" || ! -d "${HERDER_PLUGIN_CONFIG_DIR}/jt.command-palette" ]] && herdr plugin install JanTvrdik/herdr-command-palette --yes;
[[ "${REINSTALL_PLUGINS}" == "true" || ! -d "${HERDER_PLUGIN_CONFIG_DIR}/cloudmanic.herdr-plus" ]] && herdr plugin install cloudmanic/herdr-plus --yes
[[ "${REINSTALL_PLUGINS}" == "true" || ! -d "${HERDER_PLUGIN_CONFIG_DIR}/herdr-session-parker" ]] && herdr plugin install iviaxpow3r/herdr-session-parker --yes

herdr server reload-config 2>/dev/null;

[[ "${REINSTALL_PLUGINS}" == "true" || ! -f ${HOME}/.claude/skills/herdr/SKILL.md ]] && DISABLE_TELEMETRY=1 npx -y skills add ogulcancelik/herdr --skill herdr -g -a claude-code -y
[[ "${REINSTALL_PLUGINS}" == "true" || ! -f ${HOME}/.agents/skills/herdr/SKILL.md ]] && DISABLE_TELEMETRY=1 npx -y skills add ogulcancelik/herdr --skill herdr -g -a codex -y

[[ "${REINSTALL_PLUGINS}" == "true" ]] || echo "Set REINSTALL_PLUGINS=true to force update herdr plugins and skills";

