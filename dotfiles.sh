#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
BASEDIR="${THISDIR}/dotfiles";
TIME="$(date +%Y%m%d%H%M%S)";
CLEANUPFILE="${1:-${CLEANUPFILE}}"
. "${THISDIR}/functions.sh";

ln --version 2>/dev/null | grep GNU &>/dev/null;

case "$?" in
  0) LNARGS="-sTf";; # GNU
  1) LNARGS="-sF" ;; # BSD
esac

mkdir -p ${HOME}/.local/bin;

find "${BASEDIR}" -maxdepth 1 -name '.*' | egrep -ve '.DS_Store|.gitignore|.git$' 2>/dev/null | awk -F'/' '{print $NF}' | while read dotfile
do
    [[ -e "${HOME}/${dotfile}" && -n "${CLEANUPFILE}" ]] && mv "${HOME}/${dotfile}" "${HOME}/${dotfile}.dotfilebak.${TIME}" && echo "${HOME}/${dotfile}.dotfilebak.${TIME}" >> "${CLEANUPFILE}";
    echo -e "Linking ${HOME}/${dotfile} -> ${BASEDIR}/${dotfile}";
    ln "${LNARGS}" "${BASEDIR}/${dotfile}" "${HOME}/${dotfile}";
done

case "${KERNEL}" in
  linux)
    for x in pbcopy pbpaste; do
      echo "Linking ${HOME}/.local/bin/${x} -> ${THISDIR}/dotfiles/.bin/_pbutils.sh";
      ln -sf "${THISDIR}/dotfiles/.bin/_pbutils.sh" "${HOME}/.local/bin/${x}";
    done
    # ensure if we're in a devcontainer that's not a github codespace that we intercept gpg-agent so that socat can run and tunnel the agent socket to the host
    if [[ ("${DEVCONTAINER}" == "true" || "${REMOTE_CONTAINERS}" == "true") && ("${ENABLE_GPG_AGENT}" != "true" && "${CODESPACES}" != "true" && "${GITHUB_CODESPACES}" != "true")]]; then
      echo "Linking ${HOME}/.local/bin/gpg-agent -> ${THISDIR}/dotfiles/.bin/_gpg-agent.sh (set ENABLE_GPG_AGENT=true to disable)";
      ln -sf "${THISDIR}/dotfiles/.bin/_gpg-agent.sh" "${HOME}/.local/bin/gpg-agent";
      echo "Creating ${HOME}/.local/gpgagentrc";
      echo '$HOME/.local/bin/gpg-agent' > ${HOME}/.local/gpgagentrc;
    fi
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
