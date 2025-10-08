#!/bin/bash

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

