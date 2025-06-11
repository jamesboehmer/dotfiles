#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
BASEDIR="${THISDIR}/dotfiles";
TIME="$(date +%Y%m%d%H%M%S)";
CLEANUPFILE="${1:-${CLEANUPFILE}}"
. "${THISDIR}/functions.sh";

find "${BASEDIR}" -maxdepth 1 -name '.*' | egrep -ve '.DS_Store|.gitignore|.git$' | awk -F'/' '{print $NF}' | while read dotfile
do
    [[ -e "${HOME}/${dotfile}" && -n "${CLEANUPFILE}" ]] && mv "${HOME}/${dotfile}" "${HOME}/${dotfile}.dotfilebak.${TIME}" && echo "${HOME}/${dotfile}.dotfilebak.${TIME}" >> "${CLEANUPFILE}";
    echo -e "Linking ${HOME}/${dotfile} -> ${BASEDIR}/${dotfile}";
    ln -sF "${BASEDIR}/${dotfile}" "${HOME}/${dotfile}";
done

case "${KERNEL}" in
  linux)
    echo "Linking ${HOME}/.local/bin/pbcopy -> ${THISDIR}/dotfiles/.bin/_pbcopy.sh";
    ln -sf "${THISDIR}/dotfiles/.bin/_pbcopy.sh" "${HOME}/.local/bin/pbcopy";
    echo "Linking ${HOME}/.local/bin/pbpaste -> ${THISDIR}/dotfiles/.bin/_pbpaste.sh";
    ln -sf "${THISDIR}/dotfiles/.bin/_pbpaste.sh" "${HOME}/.local/bin/pbpaste";
    ;;
  darwin)
  # TODO make a pbserver launch agent
    exit 0;
    ;;
  *)
    # Unsupported OS
    echo "Unsupported OS: ${KERNEL}"
    exit 1
    ;;
esac
