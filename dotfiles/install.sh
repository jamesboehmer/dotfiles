#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
TIME="$(date +%Y%m%d%H%M%S)";
CLEANUPFILE="${1:-$(mktemp)}"

find "${THISDIR}" -maxdepth 1 -name '.*' | egrep -ve '.DS_Store|.gitignore|.git$' | awk -F'/' '{print $NF}' | while read dotfile
do
    [[ -e "${HOME}/${dotfile}" ]] && mv "${HOME}/${dotfile}" "${HOME}/${dotfile}.dotfilebak.${TIME}" && echo "${HOME}/${dotfile}.dotfilebak.${TIME}" >> "${CLEANUPFILE}";
    echo -e "Linking ${HOME}/${dotfile} -> ${THISDIR}/${dotfile}";
    ln -sf "${THISDIR}/${dotfile}" "${HOME}/${dotfile}";
done
