#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
GITCONFIGFILE="${HOME}/.gitconfig";
DOTFILESGITCONFIGFILE="${HOME}/.dotfiles.gitconfig";
LOCALGITCONFIGFILE="${HOME}/.local/.gitconfig";
LOCALMACGITCONFIGFILE="${HOME}/.local/mac.gitconfig";

echo "Configuring git...";

for s in ${GITCONFIGFILE} ${LOCALMACGITCONFIGFILE} ${LOCALGITCONFIGFILE} ${DOTFILESGITCONFIGFILE}; do
    if [[ -L ${s} && ! -e ${s} ]]; then
        echo "Removing old ${s} symlink";
        rm ${s};
    fi
done

echo "Including ${DOTFILESGITCONFIGFILE} in ${GITCONFIGFILE}";
# include the .dotfiles.gitconfig file in the main .gitconfig.  This way the dotfiles gitconfig won't get clobbered by other tools that modify the main gitconfig
GITINCLUDESTMP="$(mktemp)";
git config --file ${GITCONFIGFILE} --get-all include.path | grep -v "$(basename $DOTFILESGITCONFIGFILE)" > "${GITINCLUDESTMP}";
git config --file ${GITCONFIGFILE} --unset-all include.path;
git config --file ${GITCONFIGFILE} include.path "${DOTFILESGITCONFIGFILE}";
git config --file ${GITCONFIGFILE} credential.usehttppath true
cat "${GITINCLUDESTMP}" | while read include; do
    git config --file ${GITCONFIGFILE} --add include.path "${include}";
done

if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "Configuring ${LOCALGITCONFIGFILE}";
    git config --file ${LOCALGITCONFIGFILE} credential.helper "osxkeychain"
    git config --file ${LOCALGITCONFIGFILE} mergetool.prompt false
    git config --file ${LOCALGITCONFIGFILE} core.pager "delta"
    if [[ $(type smerge &>/dev/null; echo $?) -eq 0 ]]; then
        git config --file ${LOCALGITCONFIGFILE} mergetool.smerge.cmd 'smerge mergetool "$BASE" "$LOCAL" "$REMOTE" -o "$MERGED"'
        git config --file ${LOCALGITCONFIGFILE} mergetool.smerge.trustExitCode true
        git config --file ${LOCALGITCONFIGFILE} merge.tool "smerge"
    fi
fi