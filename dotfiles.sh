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
    for x in pbcopy pbpaste; do
      echo "Linking ${HOME}/.local/bin/${x} -> ${THISDIR}/dotfiles/.bin/_pbutils.sh";
      ln -sf "${THISDIR}/dotfiles/.bin/_pbutils.sh" "${HOME}/.local/bin/${x}";
    done
    ;;
  darwin)
    # This is now a launchagent
    # echo "Linking ${HOME}/.local/bin/pbserver -> ${THISDIR}/dotfiles/.bin/_pbutils.sh";
    # ln -sf "${THISDIR}/dotfiles/.bin/_pbutils.sh" "${HOME}/.local/bin/pbserver";
    ;;
  *)
    # Unsupported OS
    # echo "Unsupported OS: ${KERNEL}"
    # exit 1
    ;;
esac
