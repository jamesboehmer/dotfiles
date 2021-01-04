#!/bin/bash

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Bye" && exit 0; }

which brew &>/dev/null
if [[ $? -ne 0 ]]
then
	if [[ "$(uname -p)" == "arm" ]]
	then
		sudo mkdir -p /opt/homebrew/Caskroom /opt/homebrew/Cellar;
		sudo chown -fR "${USER}" /opt/homebrew;
		pushd /opt;
		curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip 1 -C homebrew;
		HOMEBREW_DIR="/opt/homebrew";
		CASKROOM_DIR="${HOMEBREW_DIR}/Caskroom";
		CELLAR_DIR="${HOMEBREW_DIR}/Cellar";
		export PATH="/opt/homebrew/bin:$PATH";
	else
		HOMEBREW_DIR="/usr/local/Homebrew";
		CASKROOM_DIR="/usr/local/Caskroom";
		CELLAR_DIR="/usr/local/Cellar";
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)";
	fi
fi

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while read tap
do
	basetap="$(basename ${tap})";
	tapdir="${HOMEBREW_DIR}/Library/Taps/${tap/$basetap/homebrew-$basetap}"
	[[ -e "${tapdir}" ]] && echo "Already tapped: ${tap}" || brew tap "${tap}";
done < ${BASEDIR}/taps.txt

while read cask
do
	basecask="$(basename ${cask})";
    [[ -e "${CASKROOM_DIR}/${basecask}" ]] || compgen -G "${HOME}/Library/Caches/Homebrew/Cask/${basecask}--*" >/dev/null && echo "Already installed: ${basecask}" || brew install --cask "${cask}";
done < ${BASEDIR}/casks.txt

while read package
do
    [[ -e "/usr/local/opt/${package}" || -e "${CELLAR_DIR}/${package}" || -e "${HOMEBREW_DIR}/opt/${package}" ]] && echo "Already installed: ${package}" || brew install "${package}";
done < ${BASEDIR}/packages.txt

# only install mas on high sierra
defaults read loginwindow SystemVersionStampAsString | grep "10.13" &>/dev/null && brew install mas;

# Sonos for some reason isn't installable without using brew cask
# brew cask install sonos;

# Sublime convenience script
ln -sf "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" "/usr/local/bin/subl";

# Little Snitch
if [[ ! -e "/Applications/Little Snitch Configuration.app" ]]
then
	LITTLESNITCH_VERSION="$(/bin/ls -1 ${CASKROOM_DIR}/little-snitch/ | sort | tail -1)";
	LITTLESNITCH_INSTALLER="${CASKROOM_DIR}/little-snitch/${LITTLESNITCH_VERSION}/LittleSnitch-${LITTLESNITCH_VERSION}.dmg";
	open "${LITTLESNITCH_INSTALLER}";
fi

# Configure homebrew permissions to allow multiple users on MAC OSX.
# Any user from the admin group will be able to manage the homebrew and cask installation on the machine.
for brewdir in "${CELLAR_DIR}" "${CASKROOM_DIR}" "/Library/Caches/Homebrew"
do
	[[ -e "${brewdir}" ]] || sudo mkdir -p "${brewdir}" &>/dev/null;
	group="$(/bin/ls -ld "${brewdir}" | awk '{print $4}')";
	[[ "${group}" == "admin" ]] || sudo chgrp -R admin "${brewdir}";
	writeable="$(/bin/ls -ld "${brewdir}" | awk '{print substr($1,5,3)}')";
	[[ "${writeable}" == "rwx" ]] || sudo chmod -R g+w "${brewdir}";
done

#disable DVC analytics
which dvc &>/dev/null && dvc config --global core.analytics false
