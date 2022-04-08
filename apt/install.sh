#!/bin/bash

[[ -e /usr/bin/apt-get ]] || { echo "Not Debian.  Bye" && exit 0; }

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SUDO="";
if [[ $EUID -ne 0 ]]
then
    SUDO="sudo";
fi
export DEBIAN_FRONTEND=noninteractive;

$SUDO apt update;
$SUDO apt-get install -y $(grep -vE "^\s*#" "${BASEDIR}/packages.txt"  | tr "\n" " ")

#disable DVC analytics
which dvc &>/dev/null && dvc config --global core.analytics false

which starship &>/dev/null
if [[ $? -ne 0 ]]
then
	echo "Installing starship...";
	curl -fsSL https://starship.rs/install.sh | $SUDO FORCE=yes bash
fi

if [[ ! -e ~/.pyenv ]]
then
	mkdir -p ~/.private
	git clone https://github.com/pyenv/pyenv.git ~/.pyenv;
	git clone https://github.com/pyenv/pyenv-virtualenv.git $HOME/.pyenv/plugins/pyenv-virtualenv
	echo 'export PYENV_ROOT="$HOME/.pyenv"' > ~/.private/pyenvrc
	echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.private/pyenvrc
fi