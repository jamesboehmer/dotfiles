#!/bin/bash

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping mac docker config." && exit 0; }

echo "Configuring docker...";

DOCKERCONFIG="${HOME}/.docker/config.json";
echo "Setting ${DOCKERCONFIG} credsStore to osxkeychain";
mkdir -p $(dirname ${DOCKERCONFIG});
if [[ -e ${DOCKERCONFIG} ]]
then
    # sponge is included in moreutils
    jq '.credsStore="osxkeychain"' ${DOCKERCONFIG} | sponge ${DOCKERCONFIG}
else
    echo '{}' | jq '.credsStore="osxkeychain"' | sponge ${DOCKERCONFIG}
fi
