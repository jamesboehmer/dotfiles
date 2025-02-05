# .bashrc must NOT output anything

function loadAliases {
    which ggrep &>/dev/null && alias grep='ggrep --color=auto';
    which gsed &>/dev/null && alias sed='gsed';
    which gawk &>/dev/null && alias awk='gawk';
    [[ -e "/Applications" ]] && alias ls='ls -laFG' || alias ls='ls -laF --color'
    which kubecolor &>/dev/null && alias kubectl='kubecolor';
    alias jenvinit='eval "$(jenv init - --no-rehash)"';
    alias goenvinit='eval "$(goenv init - --no-rehash)"';
}

# Only if this is a login shell
if [[ $- = *i* ]]
then
    loadAliases
    [[ -e "${HOME}/.loginenv" ]] && source "${HOME}/.loginenv" 2>/dev/null;
    if [[ -n ${ZSH_VERSION-} ]]
    then
        autoload -Uz compinit && compinit
    else
        [[ -e "${HOME}/.git-completion" ]] && source "${HOME}/.git-completion" 2>/dev/null;
    fi
    if [[ -e ~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh ]]
    then
        export SSH_AUTH_SOCK=~/Library/Containers/com.maxgoedjen.Secretive.SecretAgent/Data/socket.ssh
    elif [[ -e "${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock" ]]
    then
        export SSH_AUTH_SOCK="${HOME}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    fi
    [[ -n ${ZSH_VERSION-} ]] && setopt NONOMATCH;
    [[ -e ~/.private ]] && source /dev/stdin <<<"$(awk 'FNR==1{print ""}{print}' ~/.private/*rc 2>/dev/null)";
    [[ -e ~/.local ]] && source /dev/stdin <<<"$(awk 'FNR==1{print ""}{print}' ~/.local/*rc 2>/dev/null)";
    [[ -n ${ZSH_VERSION-} ]] && setopt NOMATCH;
    [[ -n ${SHELL-} ]] && which direnv &>/dev/null && eval "$(direnv hook ${SHELL})"
    [[ -n ${SHELL-} ]] && which starship &>/dev/null && eval "$(starship init ${SHELL})";
fi
