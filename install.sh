#!/bin/bash

git submodule init && git submodule update;

TIME="$(date +%Y%m%d%H%M%S)";
BASEDIRS=( "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" "$( cd "$( dirname "${BASH_SOURCE[0]}" )"/../privatedotfiles && pwd )" );

CLEANUPFILE="$(mktemp)";

#Enable thumbprint ID for sudo
PAM_SUDO="/etc/pam.d/sudo";
grep "pam_tid.so" "${PAM_SUDO}" &>/dev/null
if [[ $? -ne 0 ]]
then
    echo "Adding thumbprint ID to sudo...";
    tmpfile="$(mktemp)";
    grep "#" "${PAM_SUDO}" >> "${tmpfile}";
    echo "auth       sufficient     pam_tid.so" >> "${tmpfile}";
    grep -v "#" "${PAM_SUDO}" >> "${tmpfile}";
    sudo cp "${PAM_SUDO}" "${PAM_SUDO}.${TIME}";
    sudo cp "${tmpfile}" "${PAM_SUDO}";
    sudo chmod 444 "${PAM_SUDO}";
fi

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

if [[ "$(uname -s)" != "Darwin" ]]
then
    mkdir -p ~/.local;
    echo "Setting git credential helper to cache...";
    git config --file ~/.local/.local.gitconfig credential.helper 'cache --timeout=30000'
    echo "Unsetting git diff and merge tools...";
    git config --file ~/.local/.local.gitconfig merge.tool ""
    git config --file ~/.local/.local.gitconfig diff.tool ""

fi

which defaults &>/dev/null;
if [[ $? -eq 0 ]]
then

echo "Setting up iTerm2 defaults..."

defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string ${HOME}/.iterm
defaults write com.googlecode.iterm2.plist SUEnableAutomaticChecks -bool false
defaults write com.apple.gamed Disabled -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores true # disable creation of .DS_Store files
defaults write com.googlecode.iterm2.plist BootstrapDaemon -bool false #makes sudo thumbprint ID work
defaults read com.googlecode.iterm2.plist >/dev/null
defaults read -app iTerm >/dev/null

# Enable keyboard to be used to navigate dialogs.
# This probably won't take effect until after you open the sysprefs->keyboard->shortcuts window or restart.
# See https://stackoverflow.com/a/54192723
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2

# disable the macos tips thing
sudo launchctl disable system/com.apple.tipsd

fi

# Prevent iTunes from hijacking the play key, but only if not on High Sierra
which launchctl &>/dev/null && defaults read loginwindow SystemVersionStampAsString | egrep "10.1(3|4)" &>/dev/null || launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist &>/dev/null

# Prevent Cisco AnyConnect from launching at startup
[[ -e /Library/LaunchAgents/com.cisco.anyconnect.gui.plist ]] &>/dev/null && launchctl unload -w /Library/LaunchAgents/com.cisco.anyconnect.gui.plist

# Fix zsh compinit permission issue
zsh -ic 'compaudit' | while read f; do chmod g-w "$f"; done

if [[ -s "${CLEANUPFILE}" ]]
then
	# read -p "Would you like to clean up backed up files? " -n 1 -r
	# echo
	# if [[ $REPLY =~ ^[Yy]$ ]]
	# then
        echo "Cleaning up backed up files...";
    	cat "${CLEANUPFILE}" | while read line
    	do
    		echo -e "Removing ${line}";
    		rm "${line}";
    	done
    # fi
fi

