#!/bin/bash

echo "Configuring docker...";

DOCKERCONFIG="${HOME}/.docker/config.json";

BREWPREFIX="$(type brew &>/dev/null && brew --prefix || echo "")";
PLUGINDIRS=("${BREWPREFIX}/lib/docker/cli-plugins" "/usr/libexec/docker/cli-plugins");

mkdir -p $(dirname ${DOCKERCONFIG});

[[ ! -e ${DOCKERCONFIG} ]] && echo '{}' > "${DOCKERCONFIG}";

[[ "$(uname -s)" == "Darwin" ]] && echo "Setting credsStore to osxkeychain" && jq '.credsStore="osxkeychain"' "${DOCKERCONFIG}" | sponge "${DOCKERCONFIG}";

for PLUGINDIR in ${PLUGINDIRS[@]}; do
    [[ -e "${PLUGINDIR}" ]] && echo "Adding ${PLUGINDIR} to cliPluginsExtraDirs" && cat "${DOCKERCONFIG}" | jq --arg PLUGINDIR "${PLUGINDIR}" '.cliPluginsExtraDirs=((.cliPluginsExtraDirs // [])  + [$PLUGINDIR] | sort | unique)' | sponge "${DOCKERCONFIG}";
done