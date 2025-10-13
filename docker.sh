#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
. "${THISDIR}/functions.sh";

echo "Configuring docker...";

DOCKERCONFIG="${HOME}/.docker/config.json";

BREWPREFIX="$(type brew &>/dev/null && brew --prefix || echo "")";
PLUGINDIRS=("${BREWPREFIX}/lib/docker/cli-plugins" "/usr/libexec/docker/cli-plugins");

mkdir -p $(dirname ${DOCKERCONFIG});

[[ ! -e ${DOCKERCONFIG} ]] && echo '{}' > "${DOCKERCONFIG}";

DOCKERCONFIGTMP="$(mktemp)";
[[ "${KERNEL}" == "darwin" ]] && echo "Setting credsStore to osxkeychain" && cat "${DOCKERCONFIG}" | jq '.credsStore="osxkeychain"' > "${DOCKERCONFIGTMP}" && mv "${DOCKERCONFIGTMP}" "${DOCKERCONFIG}";

for PLUGINDIR in ${PLUGINDIRS[@]}; do
    [[ -e "${PLUGINDIR}" ]] && echo "Adding ${PLUGINDIR} to cliPluginsExtraDirs" && cat "${DOCKERCONFIG}" | jq --arg PLUGINDIR "${PLUGINDIR}" '.cliPluginsExtraDirs=((.cliPluginsExtraDirs // [])  + [$PLUGINDIR] | sort | unique)' > "${DOCKERCONFIGTMP}" && mv "${DOCKERCONFIGTMP}" "${DOCKERCONFIG}";
done