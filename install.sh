#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";

CLEANUPFILE="$(mktemp)";

function ensurebrewpath() {
    # ensure brew is in the path first, otherwise first-time installations fail
    if [[ -e /opt/homebrew/bin/brew ]]; then
        eval $(/opt/homebrew/bin/brew shellenv);

        HOMEBREW_DIR="$(brew --prefix)";
        CASKROOM_DIR="${HOMEBREW_DIR}/Caskroom";
        CELLAR_DIR="${HOMEBREW_DIR}/Cellar";
        export PATH="${HOMEBREW_DIR}/bin:$PATH";
        export HOMEBREW_NO_ENV_HINTS=1
        export HOMEBREW_NO_INSTALL_CLEANUP=1
    fi
}

function fix_zsh_compinit_perms() {
    # Fix zsh compinit permission issue
    zsh -ic 'compaudit' | while read f; do chmod g-w "$f"; done
}

function ensure_codespace_gpg() {
    # Automatically enabled git PGP signing in codespaces
    if [[ "${CODESPACES}" == "true" ]]
    then
        [[ -e ~/.bin/git-gpg-config ]] && ~/.bin/git-gpg-config local codespace
        # echo 'export EDITOR=code' > ~/.private/codespacerc
    fi
}

function cleanup(){
    if [[ -s "${CLEANUPFILE}" ]]
    then
        echo "Cleaning up backed up files...";
        cat "${CLEANUPFILE}" | while read line
        do
            echo -e "Removing ${line}";
            rm "${line}";
        done
    fi
}

${THISDIR}/dotfiles/install.sh "${CLEANUPFILE}";
${THISDIR}/brew/install.sh && ensurebrewpath;
${THISDIR}/debian/install.sh;
${THISDIR}/git/config.sh;
${THISDIR}/mac/config.sh
${THISDIR}/starship/config.sh
${THISDIR}/direnv/config.sh
${THISDIR}/localrc/config.sh;

fix_zsh_compinit_perms;
ensure_codespace_gpg;
cleanup;



