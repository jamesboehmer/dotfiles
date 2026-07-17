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

# Echo the newest socket matching glob $1 that is actually being listened on,
# using the `ss -lxn` snapshot passed as $2. A VS Code IPC socket *file* lingers
# in /tmp after its window/connection closes; connecting to such a dead socket
# yields ECONNREFUSED, and mtime cannot distinguish live from dead. So we only
# ever pick sockets present in the listening set. Falls back to newest-by-mtime
# when the snapshot is empty (e.g. ss unavailable) so behavior degrades safely.
_vscode_newest_live_sock() {
  local glob="$1" listening="$2" f newest=""
  if [ -n "$listening" ]; then
    for f in $(command ls -t $glob 2>/dev/null); do
      case "$listening" in
        *"$f"*) newest="$f"; break ;;
      esac
    done
  fi
  [ -z "$newest" ] && newest=$(command ls -t $glob 2>/dev/null | head -n1)
  [ -n "$newest" ] && printf '%s\n' "$newest"
}

# Directory holding the stable symlinks the env vars point at.
_VSCODE_HEAL_DIR="$HOME/.local/vscode-heal"

# (Re)point stable symlink $2 at the newest live socket matching glob $1, then
# echo the symlink path. The symlink gives a fixed path that survives socket
# rotation, so env vars (and anything that captured them earlier) stay valid —
# only the link target moves. Echoes nothing when no live socket is found, so
# callers leave the existing env var untouched. $3 is the `ss -lxn` snapshot.
_vscode_link_live_sock() {
  local glob="$1" link="$2" listening="$3" target
  target=$(_vscode_newest_live_sock "$glob" "$listening")
  [ -n "$target" ] || return 0
  [ "$(readlink "$link" 2>/dev/null)" = "$target" ] || ln -sfn "$target" "$link"
  printf '%s\n' "$link"
}

_vscode_ipc_heal() {
  _in_vscode_devcontainer || return

  # One snapshot of all LISTENing unix sockets, reused for every family below.
  local listening
  listening=$(ss -lxn 2>/dev/null)

  mkdir -p "$_VSCODE_HEAL_DIR" 2>/dev/null

  # Point each env var at a stable symlink under $_VSCODE_HEAL_DIR and re-aim the
  # symlink at the newest *live* socket. Do NOT re-source the VS Code shell
  # integration script from here: it captures the current $PROMPT_COMMAND as its
  # "original" and rewires PROMPT_COMMAND=__vsc_prompt_cmd_original, so
  # re-sourcing from within PROMPT_COMMAND corrupts that chain into
  # self-reference and crashes the shell. The `code`/git CLIs read these env
  # vars at exec time and follow the symlink, so updating the link is enough.
  local link
  link=$(_vscode_link_live_sock '/tmp/vscode-ipc-*.sock' "$_VSCODE_HEAL_DIR/ipc.sock" "$listening")
  [ -n "$link" ] && export VSCODE_IPC_HOOK_CLI="$link"

  link=$(_vscode_link_live_sock '/tmp/vscode-git-*.sock' "$_VSCODE_HEAL_DIR/git.sock" "$listening")
  [ -n "$link" ] && export VSCODE_GIT_IPC_HANDLE="$link"

  link=$(_vscode_link_live_sock '/tmp/vscode-remote-containers-ipc-*.sock' "$_VSCODE_HEAL_DIR/remote-containers-ipc.sock" "$listening")
  [ -n "$link" ] && export REMOTE_CONTAINERS_IPC="$link"

  # REMOTE_CONTAINERS_SOCKETS is a JSON list: the (rotating) ssh-auth socket
  # plus the stable gpg-agent and keyboxd sockets. Use the ssh-auth symlink so
  # the list value itself stays stable across rotation.
  local ssh_auth_link gpg_agent_sock gpg_keyboxd_sock
  ssh_auth_link=$(_vscode_link_live_sock '/tmp/vscode-ssh-auth-*.sock' "$_VSCODE_HEAL_DIR/ssh-auth.sock" "$listening")
  gpg_agent_sock=$(gpgconf --list-dir agent-socket 2>/dev/null)
  gpg_keyboxd_sock=$(gpgconf --list-dir keyboxd-socket 2>/dev/null)

  if [ -n "$ssh_auth_link" ] && [ -n "$gpg_agent_sock" ] && [ -n "$gpg_keyboxd_sock" ]; then
    local rebuilt="[\"$ssh_auth_link\",\"$gpg_agent_sock\",\"$gpg_keyboxd_sock\"]"
    if [ "$rebuilt" != "$REMOTE_CONTAINERS_SOCKETS" ]; then
      export REMOTE_CONTAINERS_SOCKETS="$rebuilt"
    fi
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

# Also heal immediately before every `code` invocation. PROMPT_COMMAND/precmd
# only fire when a prompt is drawn, so a long-idle shell (herdr/tmux pane) can
# still be pointing at a socket that died since its last prompt — the classic
# "Unable to connect to VS Code server ... ECONNREFUSED" from an old terminal.
# Healing here guarantees `code <file>` targets a live socket. `command` bypasses
# this function to reach the real CLI.
if _in_vscode_devcontainer; then
  code() { _vscode_ipc_heal; command code "$@"; }
fi
# --- end VS Code IPC socket auto-heal ---
EOF
