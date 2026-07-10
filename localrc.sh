#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
WHEN="$(date)";


function newlocalrcfile() {
	# Usage: newlocalrcfile ${basename} [varname value [varname value [...]]]
	FILENAME="${HOME}/.local/$1";
	echo "Configuring ${FILENAME}";
	mkdir -p "${HOME}/.local" && rm -f "${FILENAME}" && echo "# CREATED BY ${THIS} at ${WHEN}.  DO NOT EDIT" > "${FILENAME}";
	shift;
	while [ $# -gt 1 ]; do
		varname="$1";
		value="$2";
		shift;
		shift;
		if [[ $(declare -F "${varname}" &>/dev/null; echo $?) -eq 0 ]]; then
			declare -f "${varname}" >> "${FILENAME}";
			[[ $(declare -F "${value}" &>/dev/null; echo $?) -eq 0 ]] && declare -f "${value}" >> "${FILENAME}";
		else
			echo "export ${varname}=\"${value}\"" >> ${FILENAME};
		fi
	done
}

#disable DVC analytics
type dvc &>/dev/null && dvc config --global core.analytics false

[[ "$(uname -s)" == "Darwin" ]] && [[ $(which brew &>/dev/null; echo $?) -eq 0 ]] && newlocalrcfile devrc \
OPENBLAS "$(brew --prefix openblas)" \
OPENSSL "$(brew --prefix openssl@1.1)" \
ZLIB "$(brew --prefix zlib)" \
PROTOBUF "$(brew --prefix protobuf)" \
LDFLAGS '-L${OPENSSL}/lib:${ZLIB}/lib:${PROTOBUF}/lib' \
CPPFLAGS '-I${OPENSSL}/include:${ZLIB}/include:${PROTOBUF}/include' \
CFLAGS '${CPPFLAGS}' \
HDF5_DIR "$(brew --prefix hdf5)" \
PKG_CONFIG_PATH '-L${OPENSSL}/lib/pkgconfig:${ZLIB}/lib/pkgconfig'

[[ "$(uname -s)" == "Darwin" ]] && newlocalrcfile grpcpythonrc 'GRPC_PYTHON_BUILD_SYSTEM_OPENSSL' '1' 'GRPC_PYTHON_BUILD_SYSTEM_ZLIB' '1';

newlocalrcfile pyenvrc 'PYENV_ROOT' '$HOME/.pyenv' 'PATH' '$PYENV_ROOT/bin:$PATH';
newlocalrcfile goenvrc 'GOENV_ROOT' '$HOME/.goenv' 'PATH' '$GOENV_ROOT/bin:$PATH';
newlocalrcfile tfenvrc 'PATH' '$HOME/.tfenv/bin:$PATH';
newlocalrcfile nodenvrc 'PATH' '$HOME/.nodenv/bin:$PATH';
newlocalrcfile pipxrc 'PIPX_DEFAULT_PYTHON' 'python';
newlocalrcfile kubectlrc && cat >> "${HOME}/.local/kubectlrc" <<EOF
alias k='kubectl';
EOF

newlocalrcfile terraformrc && cat >> "${HOME}/.local/terraformrc" <<'EOF'
alias t='terraform'
export TF_PLUGIN_CACHE_DIR="$HOME/.config/terraform.d/plugin-cache";
[[ -e $TF_PLUGIN_CACHE_DIR ]] || mkdir -p $TF_PLUGIN_CACHE_DIR;
EOF

if [[ "${USER}" == "vscode" ]]; then
	newlocalrcfile sshauthsockrc && cat >> "${HOME}/.local/sshauthsockrc" << 'EOF'
mkdir -p $HOME/.ssh;
ln -sf "$(/bin/ls -t /tmp/vscode-ssh-auth-* 2>/dev/null | head -1)" "$HOME/.ssh/vscode-agent.sock" 2>/dev/null
if [[ -e "$HOME/.ssh/vscode-agent.sock" ]]; then
	export SSH_AUTH_SOCK="$HOME/.ssh/vscode-agent.sock"
fi
EOF
fi

newlocalrcfile vscoderc.poststarship && cat >> "${HOME}/.local/vscoderc.poststarship" << 'EOF'
# --- VS Code IPC socket auto-heal (herdr/tmux long-lived shell fix) ---
# Paste this block into both ~/.bashrc and ~/.zshrc.
# It's a no-op unless run inside a VS Code devcontainer.

_in_vscode_devcontainer() {
  [ "$REMOTE_CONTAINERS" = "true" ] && return 0

  if [ -f /.dockerenv ] || grep -qa 'docker\|containerd' /proc/1/cgroup 2>/dev/null; then
    if [ -d "$HOME/.vscode-server" ] || [ -d "$HOME/.vscode-remote" ]; then
      return 0
    fi
  fi

  return 1
}

_vscode_ipc_heal() {
  _in_vscode_devcontainer || return

  local newest
  newest=$(command ls -t /tmp/vscode-ipc-*.sock 2>/dev/null | head -n1)

  if [ -n "$newest" ] && [ "$newest" != "$VSCODE_IPC_HOOK_CLI" ]; then
    export VSCODE_IPC_HOOK_CLI="$newest"
    unset VSCODE_SHELL_INTEGRATION

    local shellname
    if [ -n "$ZSH_VERSION" ]; then
      shellname="zsh"
    elif [ -n "$BASH_VERSION" ]; then
      shellname="bash"
    fi

    # shellcheck disable=SC1090
    source "$(code --locate-shell-integration-path "$shellname" 2>/dev/null)" 2>/dev/null
  fi
}

if [ -n "$ZSH_VERSION" ]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _vscode_ipc_heal
elif [ -n "$BASH_VERSION" ]; then
  if declare -p PROMPT_COMMAND 2>/dev/null | grep -q 'declare -a'; then
    # bash 5.1+ array form — safe to append regardless of what else uses it
    PROMPT_COMMAND+=(_vscode_ipc_heal)
  else
    case "$PROMPT_COMMAND" in
      *_vscode_ipc_heal*) ;;
      *) PROMPT_COMMAND="_vscode_ipc_heal${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
    esac
  fi
fi
# --- end VS Code IPC socket auto-heal ---
EOF
