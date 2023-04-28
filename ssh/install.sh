#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
THIS="$(pwd)/$(basename ${BASH_SOURCE[0]})";

TIME="$(date +%Y%m%d%H%M%S)";
CLEANUPFILE="${1}";
[[ -z $CLEANUPFILE ]] && CLEANUPFILE="/dev/null";

SSHDIR="${HOME}/.ssh";
SSHCONFIG="${SSHDIR}/config";

echo "Creating ssh config...";

mkdir -p "${SSHDIR}/config.d";
mkdir -p "${HOME}/.local/.ssh/config.d"
touch "${SSHCONFIG}";

sed -i.dotfilebak.${TIME} -e '/^$/N;/^\n$/D' -e '/### START DOTFILES CONFIG ###/,/### END DOTFILES CONFIG ###/d' "${SSHCONFIG}";
echo "${SSHCONFIG}.dotfilebak.${TIME}" >> "${CLEANUPFILE}";

cat << EOF >> "${SSHCONFIG}"

### START DOTFILES CONFIG ###
### Added by ${THIS} $(date "+%Y-%m-%d %H:%M:%S") ###

Include ~/.ssh/config.d/*
Include ~/.local/.ssh/config.d/*

### END DOTFILES CONFIG ###
EOF
set -x
if [[ -d "${SSHDIR}/config.d" && ! -L "${SSHDIR}/config.d" ]]; then
    mv "${SSHDIR}/config.d" "${SSHDIR}/config.d.dotfilebak.${TIME}";
    echo "Your SSH config files were moved to ${SSHDIR}/config.d.dotfilebak.${TIME}.  You should put those files in ${HOME}/.local/.ssh/config.d instead";
fi

ln -sf "$(pwd)/config.d" "${SSHDIR}/";
