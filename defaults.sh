#!/bin/bash

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping mac defaults." && exit 0; }

if [[ $(defaults read com.apple.gamed Disabled 2>/dev/null) -ne 1 ]]; then
	echo "Disabling Game Center...";
	defaults write com.apple.gamed Disabled -bool true;
fi

if [[ $(defaults read com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null) -ne 1 ]]; then
	echo "Disabling .DS_Store files...";
	defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true;
fi

# This probably won't take effect until after you open the sysprefs->keyboard->shortcuts window or restart.
# See https://stackoverflow.com/a/54192723
if [[ $(defaults read NSGlobalDomain AppleKeyboardUIMode 2>/dev/null) -ne 2 ]]; then
	echo "Enabling keyboard to be used to navigate dialogs (you need to restart for this to take effect)...";
	defaults write NSGlobalDomain AppleKeyboardUIMode -int 2
fi

# disable the macos tips thing
if ! launchctl print-disabled system | grep "com.apple.tipsd" | grep disabled &>/dev/null; then
	echo "Disabling apple tips...";
	sudo launchctl disable system/com.apple.tipsd;
fi

if [[ -d "/Applications/Spotify.app" && $(defaults read digital.twisted.noTunes replacement 2>/dev/null) != "/Applications/Spotify.app" ]]; then
    echo "Setting Spotify as the default media key app for noTunes...";
    defaults write digital.twisted.noTunes replacement /Applications/Spotify.app
fi

