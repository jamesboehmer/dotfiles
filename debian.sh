#!/bin/bash

[[ -e /usr/bin/apt-get ]] || { echo "Not Debian.  Skipping Debian config" && exit 0; }

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

SUDO="";
if [[ $EUID -ne 0 ]]
then
    SUDO="sudo";
fi
export DEBIAN_FRONTEND=noninteractive;
ARCH="$(dpkg --print-architecture)";


function gitcloneinstall() {
	# Usage: gitcloneinstall URL dir
	if [[ -e "${2}" ]]; then
		echo "${2} exists.  Skipping install.";
		return;
	fi
	echo "Cloning ${1} to ${2}...";
	PARENTDIR="$(dirname ${2})";
	mkdir -p "${PARENTDIR}";
	git clone "${1}" "${2}";
}

function curlbininstall() {
	# Usage: curlbininstall URL targetfile
	if [[ -e "${2}" ]]; then
		echo "${2} exists.  Skipping install.";
		return;
	fi
	echo "Downloading ${1} to ${2}...";
	PARENTDIR="$(dirname ${2})";
	mkdir -p "${PARENTDIR}";
	curl -fsSL "${1}" -o "${2}" && chmod +x "${2}";
}

function dangerous() {
	# Usage: dangerous url $args (e.g. "bash" "FORCE=yes sh" etc)
	echo "Installing from ${1}...";
	URL="${1}";
	shift;
	curl -fsSL "${URL}" | ${@}
}

gitcloneinstall "https://github.com/pyenv/pyenv.git" "$HOME/.pyenv";
gitcloneinstall "https://github.com/pyenv/pyenv-virtualenv.git" "$HOME/.pyenv/plugins/pyenv-virtualenv";
gitcloneinstall "https://github.com/go-nv/goenv.git" "${HOME}/.goenv";
gitcloneinstall "https://github.com/tfutils/tfenv.git" "${HOME}/.tfenv";
gitcloneinstall "https://github.com/nodenv/nodenv.git" "${HOME}/.nodenv";
gitcloneinstall "https://github.com/nodenv/node-build.git" "${HOME}/.nodenv/plugins/node-build";

AWS_VAULT_VERSION="v7.2.0";
curlbininstall "https://github.com/99designs/aws-vault/releases/download/${AWS_VAULT_VERSION}/aws-vault-linux-${ARCH}" "${HOME}/.local/bin/aws-vault";

YQ_VERSION="v4.45.1";
curlbininstall "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_${ARCH}" "${HOME}/.local/bin/yq";

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

[[ "$(which poetry &>/dev/null; echo $?)" -ne 0 ]] && pipx install poetry && ${HOME}/.local/bin/poetry self add poetry-dynamic-versioning;
[[ "$(which aws &>/dev/null; echo $?)" -ne 0 ]] && pipx install aws;

which tflint &>/dev/null || dangerous "https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh" "bash";
which tfsec &>/dev/null || dangerous "https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh" "bash";
which uv &>/dev/null || dangerous "https://astral.sh/uv/install.sh" "sh";
which starship &>/dev/null || dangerous "https://starship.rs/install.sh" "$SUDO" "FORCE=yes" "sh";

