#!/bin/bash

[[ -e /usr/bin/apt-get ]] || { echo "Not Debian.  Skipping Debian config" && exit 0; }

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

export DEBIAN_FRONTEND=noninteractive;

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

OPA_VERSION="latest";
curlbininstall "https://openpolicyagent.org/downloads/${OPA_VERSION}/opa_{$KERNEL}_{$ARCH}_static" "${HOME}/.local/bin/opa";

K9S_VERSION="v0.50.6";
CHECKFOR="k9s" curldpkginstall "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_linux_arm64.deb";

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

! checkfor poetry && pipx install poetry;
poetry self show plugins 2>/dev/null | grep poetry-dynamic-versioning &>/dev/null || poetry self add poetry-dynamic-versioning;
! checkfor aws && pipx install aws;

CHECKFOR="tflint" dangerous "https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh" "bash";
CHECKFOR="tfsec" dangerous "https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh" "bash";
CHECKFOR="uv" dangerous "https://astral.sh/uv/install.sh" "sh";
CHECKFOR="starship" dangerous "https://starship.rs/install.sh" "$SUDO" "FORCE=yes" "sh";
CHECKFOR="helm" dangerous "https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3" "bash";

[[ "${DOUPDATE}" != "true" ]] && echo "Run again with DOUPDATE=true to force installation of all debian packages.";
