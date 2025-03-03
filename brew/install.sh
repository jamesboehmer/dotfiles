#!/bin/bash

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping brew." && exit 0; }

if [[ ! -e /opt/homebrew/bin/brew ]]
then
	echo "Installing brew...";
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo "Brew is already installed.";
fi

# ensure brew is in the path first, otherwise first-time installations fail
eval $(/opt/homebrew/bin/brew shellenv);

BREWIGNORE_FILE="${HOME}/.local/brewignore";
[[ ! -x "${BREWIGNORE_FILE} " ]] && mkdir -p ~/.local && touch "${BREWIGNORE_FILE}";

HOMEBREW_DIR="$(brew --prefix)";
CASKROOM_DIR="${HOMEBREW_DIR}/Caskroom";
CELLAR_DIR="${HOMEBREW_DIR}/Cellar";
export PATH="${HOMEBREW_DIR}/bin:$PATH";
export HOMEBREW_NO_ENV_HINTS=1;
export HOMEBREW_NO_INSTALL_CLEANUP=1;

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

while read tap
do
	basetap="$(basename ${tap})";
	tapdir="${HOMEBREW_DIR}/Library/Taps/${tap/$basetap/homebrew-$basetap}"
	[[ -e "${tapdir}" ]] && echo "Already tapped: ${tap}" || brew tap "${tap}";
done < ${BASEDIR}/taps.txt

existingcasks=($(brew ls --cask))
grep -v -f "${BREWIGNORE_FILE}" "${BASEDIR}/casks.txt" | while read cask
do
	if [[ ! -e ${CASKROOM_DIR}/${cask} ]]
	then
		echo "#### Cask: ${cask} ####";
		brew install --cask "${cask}";
		if [[ $? -ne 0 ]]; then
			echo "Installation of ${cask} failed.  Consider adding it to ${BREWIGNORE_FILE} to ignore it next time.";
		fi
	fi
done

for package in $(grep -v -f "${BREWIGNORE_FILE}" "${BASEDIR}/packages.txt")
do
	if [[ ! -e "${CELLAR_DIR}/${package}" ]]
	then
		echo "#### Installing Package: ${package} ####";
		brew install "${package}";
		if [[ $? -ne 0 ]]; then
			echo "Installation of ${package} failed.  Consider adding it to ${BREWIGNORE_FILE} to ignore it next time.";
		fi
	else
		echo "#### Already installed: ${package} ####"
	fi
done
exit


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
