#!/bin/bash

[[ -e /usr/bin/apt-get ]] || { echo "Not Debian.  Skipping apt" && exit 0; }

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SUDO="";
if [[ $EUID -ne 0 ]]
then
    SUDO="sudo";
fi
export DEBIAN_FRONTEND=noninteractive;
ARCH="$(dpkg --print-architecture)";

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
fi
echo 'export PYENV_ROOT="$HOME/.pyenv"' > ~/.local/pyenvrc
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.local/pyenvrc
echo 'export PIPX_DEFAULT_PYTHON="$PYENV_ROOT/shims/python"' >> ~/.local/pyenvrc

if [[ ! -e ~/.goenv ]]
then
	mkdir -p ~/.local
	git clone https://github.com/go-nv/goenv.git ~/.goenv
fi
echo 'export GOENV_ROOT="$HOME/.goenv"' > ~/.local/goenvrc;
echo 'export PATH="$GOENV_ROOT/bin:$PATH"' >> ~/.local/goenvrc;

if [[ ! -e ~/.tfenv ]]
then
	mkdir -p ~/.local
	git clone https://github.com/tfutils/tfenv.git ~/.tfenv;
fi
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' > ~/.local/tfenvrc

if [[ ! -e ~/.nodenv ]]
then
	mkdir -p ~/.local
	git clone https://github.com/nodenv/nodenv.git ~/.nodenv
	mkdir -p ~/.nodenv/plugins
	git clone https://github.com/nodenv/node-build.git ~/.nodenv/plugins/node-build
fi
echo 'export PATH="$HOME/.nodenv/bin:$PATH"' > ~/.local/nodenvrc 

which aws-vault &>/dev/null
if [[ $? -ne 0 ]]
then
	echo "Installing aws-vault...";
	AWS_VAULT_VERSION="v7.2.0";
	AWS_VAULT_URL="https://github.com/99designs/aws-vault/releases/download/${AWS_VAULT_VERSION}/aws-vault-linux-${ARCH}";
	mkdir -p "${HOME}/.local/bin" && curl -fsSL "${AWS_VAULT_URL}" -o "${HOME}/.local/bin/aws-vault" && chmod +x "${HOME}/.local/bin/aws-vault";
fi

which yq &>/dev/null
if [[ $? -ne 0 ]]
then
	echo "Installing yq...";
	YQ_VERSION="v4.45.1";
	YQ_URL="https://github.com/mikefarah/yq/releases/download/v4.45.1/yq_linux_${ARCH}";
	mkdir -p "${HOME}/.local/bin" && curl -fsSL "${YQ_URL}" -o "${HOME}/.local/bin/yq" && chmod +x "${HOME}/.local/bin/yq";
fi

which pipx &>/dev/null;
if [[ $? -ne 0 ]]
then

	PIP="/usr/local/bin/pip3";
	[[ ! -e "${PIP}" ]] && PIP="/usr/bin/pip3";
	[[ ! -e "${PIP}" ]] && $SUDO apt-get install -y python3-pip python3-venv;

	PIP="/usr/local/bin/pip3";
	[[ ! -e "${PIP}" ]] && PIP="/usr/bin/pip3";
	$PIP install pipx;
	export PIPX_DEFAULT_PYTHON="${PIP/pip3/python3}";
fi

which poetry &>/dev/null;
if [[ $? -ne 0 ]]
then
	pipx install poetry && ${HOME}/.local/bin/poetry self add poetry-dynamic-versioning;
fi

which tflint &>/dev/null;
if [[ $? -ne 0 ]]
then
	curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash;
fi

which tfsec &>/dev/null;
if [[ $? -ne 0 ]]
then
	curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash;
fi
