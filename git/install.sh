#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";

echo "Configuring git...";

if [[ -s ~/.gitconfig ]]; then
    ls -laF ~/.gitconfig | grep "${THISDIR}/.gitconfig" &>/dev/null;
    if [[ $? -eq 0 ]]; then
        echo "Removing ~/.gitconfig symlink";
        rm ~/.gitconfig;
    fi
fi

echo "Including ~/.dotfiles.gitconfig";
# include the .dotfiles.gitconfig file in the main .gitconfig.  This way the dotfiles gitconfig won't get clobbered by other tools that modify the main gitconfig
GITINCLUDESTMP="$(mktemp)";
git config --file ~/.gitconfig --get-all include.path | grep -v '~/.dotfiles.gitconfig' | grep -v '${HOME}/.dotfiles.gitconfig' | grep -v "${HOME}/.dotfiles.gitconfig" > "${GITINCLUDESTMP}";
git config --file ~/.gitconfig --unset-all include.path;
git config --file ~/.gitconfig include.path '~/.dotfiles.gitconfig';
git config --file ~/.gitconfig credential.usehttppath true
cat "${GITINCLUDESTMP}" | while read include; do
    git config --file ~/.gitconfig --add include.path "${include}";
done
