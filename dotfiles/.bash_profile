# .bash_profile is used for loading environment variables, and is only called by bash interactive login shells
# For dotfiles, your shell's rc should explicitly source .shell_profile
# See https://www.gnu.org/software/bash/manual/html_node/Bash-Startup-Files.html

export SHELL=/bin/bash
[[ -e ~/.shell_profile ]] && . ~/.shell_profile &>/dev/null;
[[ -e ~/.shellrc ]] && . ~/.shellrc &>/dev/null;
