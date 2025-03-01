#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping mac install." && exit 0; }

echo "Configuring mac-specific settings...";

TIME="$(date +%Y%m%d%H%M%S)";

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
ln -sf "$(pwd)/mac.gitconfig" "${HOME}/.local/mac.gitconfig";
git config --file ~/.local/.gitconfig --replace-all include.path '~/.local/mac.gitconfig' '~/.local/mac.gitconfig'

DYNAMIC_PROFILES_DIR="${HOME}/Library/Application Support/iTerm2/DynamicProfiles";
mkdir -p "${DYNAMIC_PROFILES_DIR}";

ln -sf "$(pwd)/iterm2-profiles.json" "${DYNAMIC_PROFILES_DIR}/iterm2-profiles.json";

echo "Enabling iTerm2 automatic update checks...";
defaults write com.googlecode.iterm2 SUEnableAutomaticChecks -bool true

echo "Enabling iTerm2 sudo thumbprint...";
defaults write com.googlecode.iterm2 BootstrapDaemon -bool false #makes sudo thumbprint ID work

echo "Setting up iTerm2 profiles...";
OLD_DEFAULT_PROFILE_GUID="$(defaults read com.googlecode.iterm2 "Default Bookmark Guid" 2>/dev/null)";
DEFAULT_PROFILE_GUID="$(cat iterm2-profiles.json | jq -r '.Profiles[] | select(.Name=="Dotfiles Default") | .Guid' | head -1)";
if [[ "${DEFAULT_PROFILE_GUID}" == "" ]]; then
    echo "No Default profile found in iterm2-profiles.json.  You'll need to switch manually in iTerm2.";
elif [[ "${OLD_DEFAULT_PROFILE_GUID}" != "${DEFAULT_PROFILE_GUID}" ]]; then
    defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "${DEFAULT_PROFILE_GUID}";
    echo "Default profile is set, but you'll need to restart iTerm2.  Do not open preferences until after you restart iTerm2.";
fi

echo "Disabling Game Center...";
defaults write com.apple.gamed Disabled -bool true

echo "Disabling .DS_Store files...";
defaults write com.apple.desktopservices DSDontWriteNetworkStores true


# This probably won't take effect until after you open the sysprefs->keyboard->shortcuts window or restart.
# See https://stackoverflow.com/a/54192723
echo "Enabling keyboard to be used to navigate dialogs (you need to restart for this to take effect)...";
defaults write NSGlobalDomain AppleKeyboardUIMode -int 2

# disable the macos tips thing
echo "Disabling apple tips...";
sudo launchctl disable system/com.apple.tipsd

echo "Adding osxkeychain to docker credsStore...";
DOCKERCONFIG=~/.docker/config.json;
echo "Setting ${DOCKERCONFIG} credsStore to osxkeychain";
mkdir -p ~/.docker;
if [[ -e ${DOCKERCONFIG} ]]
then
    jq '.credsStore="osxkeychain"' ${DOCKERCONFIG} | sponge ${DOCKERCONFIG}
else
    echo '{}' | jq '.credsStore="osxkeychain"' | sponge ${DOCKERCONFIG}
fi

if [[ -d /Applications/Spotify.app ]]; then
    echo "Setting Spotify as the default media key app for noTunes...";
    defaults write digital.twisted.noTunes replacement /Applications/Spotify.app
fi
