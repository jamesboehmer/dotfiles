# .bashrc must NOT output anything

function loadAliases {
    which ggrep &>/dev/null && alias grep='ggrep --color=auto';
    which gsed &>/dev/null && alias sed='gsed';
    which gawk &>/dev/null && alias awk='gawk';
    [[ -e "/Applications" ]] && alias ls='ls -laFG' || alias ls='ls -laF --color'
    alias scalaenvinit='eval "$(scalaenv init - --no-rehash)" && eval "$(sbtenv init - --no-rehash)"';
    alias goenvinit='eval "$(goenv init - --no-rehash)"';
    alias luaenvinit='eval "$(luaenv init - --no-rehash)"';
    alias luaverinit='source luaver';
    alias rbenvinit='eval "$(rbenv init - --no-rehash)"';
    alias jenvinit='eval "$(jenv init - --no-rehash)"';
    alias nodenvinit='eval "$(nodenv init - --no-rehash)"';
    alias pyenvinit='eval "$(pyenv init - --no-rehash)" && eval "$(pyenv virtualenv-init init - --no-rehash)"';
    alias sdkinit='source "${SDKMAN_DIR}/bin/sdkman-init.sh" || test 0';
    alias kubectlinit='source <(kubectl completion $(basename ${SHELL}))'

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
    [[ -n ${ZSH_VERSION-} ]] && setopt NONOMATCH;
    [[ -e ~/.private ]] && source /dev/stdin <<<"$(awk 'FNR==1{print ""}{print}' ~/.private/*rc 2>/dev/null)";
    [[ -e ~/.local ]] && source /dev/stdin <<<"$(awk 'FNR==1{print ""}{print}' ~/.local/*rc 2>/dev/null)";
    [[ -n ${ZSH_VERSION-} ]] && setopt NOMATCH;
    [[ -n ${SHELL-} ]] && which direnv &>/dev/null && eval "$(direnv hook ${SHELL})"
    [[ -n ${SHELL-} ]] && which starship &>/dev/null && eval "$(starship init ${SHELL})";
fi
