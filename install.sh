#!/bin/bash

git submodule init && git submodule update;

TIME="$(date +%Y%m%d%H%M%S)";
BASEDIRS=( "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" "$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../privatedotfiles && pwd )" );

CLEANUPFILE="$(mktemp)";

# ensure brew runs first
echo "${BASEDIRS[0]}/brew/install.sh ${CLEANUPFILE}";
"${BASEDIRS[0]}/brew/install.sh" "${CLEANUPFILE}";

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

${BASEDIRS[0]}/macinstall.sh

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

