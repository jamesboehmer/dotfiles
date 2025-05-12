#!/bin/bash

[[ -e /usr/bin/apt-get ]] || { echo "Not Debian.  Skipping apt" && exit 0; }

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
BASEDIR="${THISDIR}/apt";

SUDO="";
if [[ $EUID -ne 0 ]]
then
    SUDO="sudo";
fi
export DEBIAN_FRONTEND=noninteractive;
ARCH="$(dpkg --print-architecture)";

APTIGNORE_FILE="${HOME}/.local/aptignore";
[[ ! -x "${APTIGNORE_FILE} " ]] && mkdir -p ~/.local && touch "${APTIGNORE_FILE}";


$SUDO apt-get update;
grep -v -f "${APTIGNORE_FILE}" "${BASEDIR}/packages.txt" | while read package; do
	dpkg -l "${package}" | grep "ii" &>/dev/null;
	if [[ $? -ne 0 ]]; then
		echo "#### Installing ${package}"
		$SUDO apt-get install -y --ignore-missing "${package}";
		if [[ $? -ne 0 ]]; then
			echo "Installation of ${package} failed.  Consider adding it to ${APTIGNORE_FILE} to ignore it next time.";
		fi
	else
		echo "#### Already installed: ${package} ####"
	fi
done


