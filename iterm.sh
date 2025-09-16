#!/bin/bash

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping iterm config." && exit 0; }

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
DYNAMIC_PROFILES_DIR="${HOME}/Library/Application Support/iTerm2/DynamicProfiles";
PROFILES_JSON="iterm2-profiles.json";

if [[ ! -e "${DYNAMIC_PROFILES_DIR}/${PROFILES_JSON}" ]]; then    
    mkdir -p "${DYNAMIC_PROFILES_DIR}";
    echo "Linking ${DYNAMIC_PROFILES_DIR}/${PROFILES_JSON} -> ${THISDIR}/iterm/${PROFILES_JSON}";
    ln -sf "${THISDIR}/iterm/${PROFILES_JSON}" "${DYNAMIC_PROFILES_DIR}/${PROFILES_JSON}";
fi

if [[ $(defaults read com.googlecode.iterm2 SUEnableAutomaticChecks 2>/dev/null) -ne 1 ]]; then
    echo "Enabling iTerm2 automatic update checks...";
    defaults write com.googlecode.iterm2 SUEnableAutomaticChecks -bool true
fi

if [[ $(defaults read com.googlecode.iterm2 BootstrapDaemon 2>/dev/null) -ne 0 ]]; then
    echo "Enabling iTerm2 sudo thumbprint...";
    defaults write com.googlecode.iterm2 BootstrapDaemon -bool false #makes sudo thumbprint ID work
fi

echo "Setting up iTerm2 profiles...";
OLD_DEFAULT_PROFILE_GUID="$(defaults read com.googlecode.iterm2 "Default Bookmark Guid" 2>/dev/null)";
DEFAULT_PROFILE_GUID="$(cat "${THISDIR}/iterm/${PROFILES_JSON}" | jq -r '.Profiles[] | select(.Name=="Dotfiles Atom One Dark") | .Guid' | head -1)";
if [[ "${DEFAULT_PROFILE_GUID}" == "" ]]; then
    echo "No default iTerm2 profile found in ${PROFILES_JSON}.  You'll need to switch manually.";
elif [[ "${OLD_DEFAULT_PROFILE_GUID}" != "${DEFAULT_PROFILE_GUID}" ]]; then
    defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "${DEFAULT_PROFILE_GUID}";
    echo "Default iTerm2 profile is set, but you'll need to restart iTerm2.  Do not open preferences until after you restart iTerm2.";
fi
