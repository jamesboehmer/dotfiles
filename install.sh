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


${THISDIR}/brew/install.sh && ensurebrewpath;
${THISDIR}/apt/install.sh;
${THISDIR}/debian.sh;
${THISDIR}/ssh.sh;
${THISDIR}/starship.sh;
${THISDIR}/direnv.sh;
${THISDIR}/iterm.sh;
${THISDIR}/localrc.sh;
${THISDIR}/git.sh;
${THISDIR}/mactouchid.sh
${THISDIR}/macdocker.sh
${THISDIR}/macdefaults.sh;
${THISDIR}/dotfiles/install.sh "${CLEANUPFILE}";

# Ensure GPG git signatures in codespaces
[[ "${CODESPACES}" == "true" && -e "${HOME}/.bin/git-gpg-config" ]] && "${HOME}/.bin/git-gpg-config" local codespace;

# Fix zsh compinit permission issue
type zsh &>/dev/null && zsh -ic 'compaudit' | while read f; do chmod g-w "$f"; done

# Clean up the old symlinks
xargs -t -I {} rm {} < "${CLEANUPFILE}";



