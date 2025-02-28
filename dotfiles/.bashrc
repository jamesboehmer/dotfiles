# .bashrc must NOT output anything

[[ -e ~/.shell_profile ]] && . ~/.shell_profile &>/dev/null;
[[ -e ~/.shellrc ]] && . ~/.shellrc &>/dev/null;

. "$HOME/.local/bin/env"
