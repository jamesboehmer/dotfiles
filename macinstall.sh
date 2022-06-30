#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

if [[ "$(uname -s)" == "Darwin" ]]
then
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
    git config --file ~/.local/.local.gitconfig include.path '~/.local/mac.gitconfig'

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


    # Prevent iTunes from hijacking the play key, but only if not on High Sierra
    which launchctl &>/dev/null && defaults read loginwindow SystemVersionStampAsString | egrep "10.1(3|4)" &>/dev/null || launchctl unload -w /System/Library/LaunchAgents/com.apple.rcd.plist &>/dev/null

    # Prevent Cisco AnyConnect from launching at startup
    [[ -e /Library/LaunchAgents/com.cisco.anyconnect.gui.plist ]] &>/dev/null && launchctl unload -w /Library/LaunchAgents/com.cisco.anyconnect.gui.plist

    DOCKERCONFIG=~/.docker/config.json;
    echo "Setting ${DOCKERCONFIG} credsStore to osxkeychain";
    if [[ -e ${DOCKERCONFIG} ]]
    then
        jq '.credsStore="osxkeychain"' ${DOCKERCONFIG} | sponge ${DOCKERCONFIG}
    else
        echo '{}' | jq '.credsStore="osxkeychain"' | sponge ${DOCKERCONFIG}
    fi

fi
