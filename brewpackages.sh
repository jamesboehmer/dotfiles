#!/bin/bash

#[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping brew." && exit 0; }

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
. "${THISDIR}/functions.sh";

[[ $KERNEL == "linux" ]] && BREW="/home/linuxbrew/.linuxbrew/bin/brew";
[[ $KERNEL == "darwin" ]] && BREW="/opt/homebrew/bin/brew";

if [[ ! -e ${BREW} ]]
then
	echo "Installing brew...";
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
	echo "Brew is already installed.";
fi

# ensure brew is in the path first, otherwise first-time installations fail
eval $(${BREW} shellenv);

BREWIGNORE_FILE="${HOME}/.local/brewignore";

[[ ! -x "${BREWIGNORE_FILE} " ]] && mkdir -p ~/.local && touch "${BREWIGNORE_FILE}";

HOMEBREW_DIR="$(brew --prefix)";
CASKROOM_DIR="${HOMEBREW_DIR}/Caskroom";
CELLAR_DIR="${HOMEBREW_DIR}/Cellar";
export PATH="${HOMEBREW_DIR}/bin:$PATH";
export HOMEBREW_NO_ENV_HINTS=1;
export HOMEBREW_NO_INSTALL_CLEANUP=1;

BASEDIR="${THISDIR}/brew";
LINUXIGNORE_FILE="${BASEDIR}/linuxignore";
while read tap
do
	basetap="$(basename ${tap})";
	tapdir="${HOMEBREW_DIR}/Library/Taps/${tap/$basetap/homebrew-$basetap}"
	[[ -e "${tapdir}" ]] && echo "Already tapped: ${tap}" || brew tap "${tap}";
done < ${BASEDIR}/taps.txt

if [[ "${KERNEL}" == "darwin" ]]
then
	existingcasks=($(brew ls --cask))
	grep -v -f "${BREWIGNORE_FILE}" "${BASEDIR}/casks.txt" | while read cask
	do
		if [[ ! -e ${CASKROOM_DIR}/${cask} ]]
		then
			echo "#### Cask: ${cask} ####";
			brew install --cask "${cask}"  < /dev/null; # brew consumes from stdin so give it null || echo "Installation of ${cask} failed.  Consider adding it to ${BREWIGNORE_FILE} to ignore it next time.";
		fi
	done
fi

[[ "${KERNEL}" == "linux" ]] && ADDL_IGNORE_ARGS="-v -f ${LINUXIGNORE_FILE}"
grep -v -f "${BREWIGNORE_FILE}" ${ADDL_IGNORE_ARGS} "${BASEDIR}/packages.txt" | while read package
do
	if [[ ! -e "${CELLAR_DIR}/$(basename ${package})" ]]
	then
		echo "#### Installing Package: ${package} ####";
		brew install "${package}" < /dev/null; # brew consumes from stdin so give it null
		[[ $? -ne 0 ]] && echo "Installation of ${package} failed.  Consider adding it to ${BREWIGNORE_FILE} to ignore it next time.";
	else
		echo "#### Already installed: ${package} ####"
	fi
done
exit


# Configure homebrew permissions to allow multiple users on MAC OSX.
# Any user from the admin group will be able to manage the homebrew and cask installation on the machine.
if [[ "${KERNEL}" == "darwin" ]]
then
	for brewdir in "${CELLAR_DIR}" "${CASKROOM_DIR}" "/Library/Caches/Homebrew"
	do
		[[ -e "${brewdir}" ]] || sudo mkdir -p "${brewdir}" &>/dev/null;
		group="$(/bin/ls -ld "${brewdir}" | awk '{print $4}')";
		[[ "${group}" == "admin" ]] || sudo chgrp -R admin "${brewdir}";
		writeable="$(/bin/ls -ld "${brewdir}" | awk '{print substr($1,5,3)}')";
		[[ "${writeable}" == "rwx" ]] || sudo chmod -R g+w "${brewdir}";
	done
fi