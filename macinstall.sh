#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping macinstall." && exit 0; }

PAM_SUDO="/etc/pam.d/sudo";
grep "pam_tid.so" "${PAM_SUDO}" &>/dev/null
if [[ $? -ne 0 ]]
then
    echo "Adding touch ID to ${PAM_SUDO}";
    tmpfile="$(mktemp)";
    grep "#" "${PAM_SUDO}" >> "${tmpfile}";
    echo "auth       sufficient     pam_tid.so" >> "${tmpfile}";
    grep -v "#" "${PAM_SUDO}" >> "${tmpfile}";
    sudo cp "${PAM_SUDO}" "${PAM_SUDO}.${TIME}";
    sudo cp "${tmpfile}" "${PAM_SUDO}";
    sudo chmod 444 "${PAM_SUDO}";
fi

echo "Setting local gitconfig defaults for mac...";
mkdir -p ~/.local;
ln -sf "${BASEDIRS[0]}/mac.gitconfig" "${HOME}/.local/mac.gitconfig";
git config --file ~/.local/.gitconfig --replace-all include.path '~/.local/mac.gitconfig' '~/.local/mac.gitconfig'

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

DOCKERCONFIG=~/.docker/config.json;
echo "Setting ${DOCKERCONFIG} credsStore to osxkeychain";
if [[ -e ${DOCKERCONFIG} ]]
then
    jq '.credsStore="osxkeychain"' ${DOCKERCONFIG} | sponge ${DOCKERCONFIG}
else
    echo '{}' | jq '.credsStore="osxkeychain"' | sponge ${DOCKERCONFIG}
fi
