#!/bin/bash

TIME="$(date +%Y%m%d%H%M%S)";
BASEDIRS=( "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" "$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../privatedotfiles 2&>/dev/null && pwd )" );
CLEANUPFILE="$(mktemp)";

# ensure brew runs first
echo "${BASEDIRS[0]}/brew/install.sh ${CLEANUPFILE}";
"${BASEDIRS[0]}/brew/install.sh" "${CLEANUPFILE}";

# ensure brew is in the path first, otherwise first-time installations fail
eval $(/opt/homebrew/bin/brew shellenv);

HOMEBREW_DIR="$(brew --prefix)";
CASKROOM_DIR="${HOMEBREW_DIR}/Caskroom";
CELLAR_DIR="${HOMEBREW_DIR}/Cellar";
export PATH="${HOMEBREW_DIR}/bin:$PATH";
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# First remove the old .gitconfig symlink
if [[ -s ~/.gitconfig ]]; then
    ls -laF ~/.gitconfig | grep "${BASEDIRS[0]}/.gitconfig" &>/dev/null;
    if [[ $? -eq 0 ]]; then
        echo "Removing ~/.gitconfig symlink";
        rm ~/.gitconfig;
    fi
fi

for BASEDIR in ${BASEDIRS[@]};
do
    find "${BASEDIR}" -maxdepth 1 -mindepth 1 -name '.*' | egrep -ve '.DS_Store|.gitignore|.git$' | awk -F'/' '{print $NF}' | while read dotfile
    do
        [[ -e "${HOME}/${dotfile}" ]] && mv "${HOME}/${dotfile}" "${HOME}/${dotfile}.dotfilebak.${TIME}" && echo "${HOME}/${dotfile}.dotfilebak.${TIME}" >> "${CLEANUPFILE}";
        echo -e "Linking ${HOME}/${dotfile} -> ${BASEDIR}/${dotfile}";
        ln -sf "${BASEDIR}/${dotfile}" "${HOME}/${dotfile}";
    done

    find "${BASEDIR}" -maxdepth 2 -mindepth 2 -name install.sh | grep -v brew/install.sh | while read INSTALLSCRIPT;
    do
        echo "${INSTALLSCRIPT} ${CLEANUPFILE}";
        "${INSTALLSCRIPT}" "${CLEANUPFILE}";
    done
done

# include the .dotfiles.gitconfig file in the main .gitconfig.  This way the dotfiles gitconfig won't get clobbered by other tools that modify the main gitconfig
GITINCLUDESTMP="$(mktemp)";
git config --file ~/.gitconfig --get-all include.path | grep -v '~/.dotfiles.gitconfig' | grep -v '${HOME}/.dotfiles.gitconfig' | grep -v "${HOME}/.dotfiles.gitconfig" > "${GITINCLUDESTMP}";
git config --file ~/.gitconfig --unset-all include.path;
git config --file ~/.gitconfig include.path '~/.dotfiles.gitconfig';
cat "${GITINCLUDESTMP}" | while read include; do
    git config --file ~/.gitconfig --add include.path "${include}";
done

${BASEDIRS[0]}/macinstall/macinstall.sh "${CLEANUPFILE}"

# Fix zsh compinit permission issue
zsh -ic 'compaudit' | while read f; do chmod g-w "$f"; done

# Automatically enabled git PGP signing in codespaces
if [[ "${CODESPACES}" == "true" ]]
then
    [[ -e ~/.bin/git-gpg-config ]] && ~/.bin/git-gpg-config local codespace
    # echo 'export EDITOR=code' > ~/.private/codespacerc
fi

if [[ -s "${CLEANUPFILE}" ]]
then
    echo "Cleaning up backed up files...";
    cat "${CLEANUPFILE}" | while read line
    do
        echo -e "Removing ${line}";
        rm "${line}";
    done
fi

${BASEDIRS[0]}/xdgconfig/starshipconfig.sh
${BASEDIRS[0]}/xdgconfig/direnvlibs.sh
