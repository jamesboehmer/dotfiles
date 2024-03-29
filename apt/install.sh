#!/bin/bash

[[ -e /usr/bin/apt-get ]] || { echo "Not Debian.  Skipping apt" && exit 0; }

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
	if [[ $SUDO == "" ]]; then
		curl -fsSL https://starship.rs/install.sh | FORCE=yes sh
	else
		curl -fsSL https://starship.rs/install.sh | $SUDO FORCE=yes sh
	fi
fi

if [[ ! -e ~/.pyenv ]]
then
	mkdir -p ~/.local
	git clone https://github.com/pyenv/pyenv.git ~/.pyenv;
	git clone https://github.com/pyenv/pyenv-virtualenv.git $HOME/.pyenv/plugins/pyenv-virtualenv
	echo 'export PYENV_ROOT="$HOME/.pyenv"' > ~/.local/pyenvrc
	echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.local/pyenvrc
fi

if [[ ! -e ~/.tfenv ]]
then
	mkdir -p ~/.local
	git clone https://github.com/tfutils/tfenv.git ~/.tfenv;
	echo 'export PATH="$HOME/.tfenv/bin:$PATH"' > ~/.local/tfenvrc
fi

if [[ ! -e ~/.nodenv ]]
then
	mkdir -p ~/.local
	git clone https://github.com/nodenv/nodenv.git ~/.nodenv
	mkdir -p ~/.nodenv/plugins
	git clone https://github.com/nodenv/node-build.git ~/.nodenv/plugins/node-build
	echo 'export PATH="$HOME/.nodenv/bin:$PATH"' > ~/.local/nodenvrc 
fi
