HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000

bindkey '^[[1~' beginning-of-line
bindkey '^a' beginning-of-line
bindkey '^[[4~' end-of-line
bindkey '^e' end-of-line
bindkey '^[[5~' history-search-backward
bindkey '^[[6~' history-search-forward
bindkey '^[[3~' delete-char
bindkey '^[[2~' quoted-insert
bindkey '^[[5C' forward-word
bindkey '^[[5D' backward-word
bindkey '^[\e[C' forward-word
bindkey '^[[1;5C' forward-word
bindkey '^[\e[D' backward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^?' backward-delete-char
bindkey '^[3;5~' delete-char
autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line
bindkey -e
autoload -U select-word-style
select-word-style bash

alias -s json='jq .'

[[ -e ~/.shell_profile ]] && . ~/.shell_profile &>/dev/null;
[[ -e ~/.shellrc ]] && . ~/.shellrc &>/dev/null;

autoload -Uz compinit
zstyle ':completion:*' menu select
fpath+=~/.zfunc
fpath+=~/.local/.zfunc
fpath+=~/.private/.zfunc

