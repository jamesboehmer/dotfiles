#make sure we don't create pyc files
export PYTHONDONTWRITEBYTECODE=True
export PYTHONSTARTUP="${HOME}/.pythonrc";
export COPY_EXTENDED_ATTRIBUTES_DISABLE=true
export COPYFILE_DISABLE=true
export ANSIBLE_HOST_KEY_CHECKING=False
export BASH_SILENCE_DEPRECATION_WARNING=1;
export PATH="${HOME}/.local/bin:${HOME}/.private/.bin:${HOME}/.bin:${HOME}/.luaenv/bin:/opt/homebrew/bin:/usr/local/bin:/usr/local/sbin:$PATH";
export STARSHIP_CONFIG="${HOME}/.starship.toml";
export SDKMAN_DIR="${HOME}/.sdkman";
# Set EDITOR from least to most preferable.
which nano &>/dev/null && export VISUAL="nano";
which vim &>/dev/null && export VISUAL="vim";
which subl &>/dev/null && export VISUAL="subl -w";
[[ -x /usr/local/bin/code ]] &>/dev/null && export VISUAL="code -w";
export EDITOR="${VISUAL}";
export GIT_EDITOR="${EDITOR}";
