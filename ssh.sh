#!/bin/bash

THIS="$(pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";

TIME="$(date +%Y%m%d%H%M%S)";
CLEANUPFILE="${1}";
[[ -z $CLEANUPFILE ]] && CLEANUPFILE="/dev/null";

SSHDIR="${HOME}/.ssh";
SSHCONFIG="${SSHDIR}/config";
SSHCONFIGD="${SSHDIR}/config.d";
THISSSHCONFIGD="${THISDIR}/ssh/config.d"

echo "Configuring ssh...";

mkdir -p "${SSHDIR}";
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

if [[ -d "${SSHCONFIGD}" && ! -L "${SSHCONFIGD}" ]]; then
    mv "${SSHCONFIGD}" "${SSHCONFIGD}.dotfilebak.${TIME}";
    echo "Your SSH config files were moved to ${SSHCONFIGD}.dotfilebak.${TIME}.  You should put those files in ${HOME}/.local/.ssh/config.d instead";
fi

echo "Linking ${SSHCONFIGD} -> ${THISSSHCONFIGD}";

ln -sfn "${THISSSHCONFIGD}" "${SSHCONFIGD}";
