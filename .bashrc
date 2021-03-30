# .bashrc must NOT output anything

[[ -e ~/.private ]] && source /dev/stdin <<<"$(awk 'FNR==1{print ""}{print}' ~/.private/*rc 2>/dev/null)";

# [[ "$(uname -s)" == "Darwin" ]] && alias ls='ls -laFG' || alias ls='ls -laF --color'
[[ -e "/Applications" ]] && alias ls='ls -laFG' || alias ls='ls -laF --color'
[[ -e "/usr/local/bin/exa" ]] && alias ls='exa -laF'

function loadAliases {
    alias nonascii='pcregrep --color=auto -n "[\x80-\xFF]"';
    which ggrep &>/dev/null && alias grep='ggrep --color=auto';
    which gsed &>/dev/null && alias sed='gsed';
    which gawk &>/dev/null && alias awk='gawk';
    alias cerebro='docker run -d --rm $([[ -e ${HOME}/.cerebro/application.conf ]] && echo "-v ${HOME}/.cerebro/application.conf:/opt/cerebro/conf/application.conf") --name cerebro -it -p9000:9000 yannart/cerebro && urlWaitSpin http://localhost:9000 200 true && docker attach cerebro';
    alias swagger='docker run -d --rm --name swagger -it -p8889:8080 swaggerapi/swagger-editor && urlWaitSpin http://localhost:8889 200 true && docker attach swagger';
    alias openapi='docker run -d --rm --name openapi -it -p3000:3000 mermade/openapi-gui && urlWaitSpin http://localhost:3000 200 true && docker attach openapi';
    alias es='docker run -d --rm --name elasticsearch -it -p9200:9200 -p9300:9300 -e discovery.type=single-node -v /usr/share/elasticsearch/data elasticsearch:7.7.1 && urlWaitSpin http://localhost:9200 200 true && docker attach elasticsearch';
    alias ff='docker run -d --rm --name=firefox -p5800:5800 -v "${HOME}/.firefox-container":/config --shm-size 2g --security-opt seccomp=unconfined jlesage/firefox && urlWaitSpin http://localhost:5800 200 true && docker attach firefox';
    alias ubuntu='PORT="$(getFreePort)" && docker run -d --rm --name=ubuntu -p${PORT}:80 --shm-size 2g dorowu/ubuntu-desktop-lxde-vnc:bionic && urlWaitSpin http://localhost:${PORT} 200 true && docker attach ubuntu';
    alias dockerps='docker ps --format "{{json .}}" | jq';
    alias dockerpsa='docker ps -a --format "{{json .}}" | jq';
    alias dockerimages='docker images --format "{{json .}}" | jq';
    function dockerinspect { image="$1"; shift; docker inspect $image --format "{{json .}}" | jq $@; }
    alias jwt='/usr/local/bin/jwt';
    alias sha256='openssl dgst -sha256';
    alias weather='curl wttr.in';
    alias whereami='curl -s ifconfig.co/json | jq';
    alias scalaenvinit='eval "$(scalaenv init - --no-rehash)" && eval "$(sbtenv init - --no-rehash)"';
    alias goenvinit='eval "$(goenv init - --no-rehash)"';
    alias luaenvinit='eval "$(luaenv init - --no-rehash)"';
    alias luaverinit='. /usr/local/bin/luaver';
    alias rbenvinit='eval "$(rbenv init - --no-rehash)"';
    alias jenvinit='eval "$(jenv init - --no-rehash)"';
    alias nodenvinit='eval "$(nodenv init - --no-rehash)"';
    alias pyenvinit='eval "$(pyenv init - --no-rehash)" && eval "$(pyenv virtualenv-init init - --no-rehash)"';
    alias sdkinit='source "${SDKMAN_DIR}/bin/sdkman-init.sh" || test 0';

    function openapi-generator-cli {
        [[ $# -eq 2 ]] || echo "Usage: $0 <filename> <language>" && return 1;
        filename="$1";
        language="$2"
        tmpdir="$(mktemp -d)";
        cp "$filename" "$tmpdir";
        docker run --rm \
            -v "$tmpdir:/local" openapitools/openapi-generator-cli generate \
            -i "/local/$filename" \
            -g "$language"
    }

    function urlWaitSpin {
        url="${1}";
        expectedStatus="${2:-200}";
        openUrl="${3:-false}";
        timeout=300;
        sp="⣾⣽⣻⢿⡿⣟⣯⣷";
        i=0;
        until [[ $(curl -o /dev/null -sw "%{http_code}" "${url}") == "${expectedStatus}" && ${timeout} -gt 0 ]]
        do
            [[ "${BASH_VERSION}" != "" ]] && printf "\b${sp:i++%${#sp}:1}"
            if [[ "${ZSH_VERSION}" != "" ]]
            then
                ((i%=${#sp}));
                ((i+=1));
                printf "\b${${(@z)sp}[$i]//\"}"
            fi
            sleep .1
            ((timeout-=1))
            [[ ${timeout} -le 0 ]] && printf "\b \b" && return 1;
        done
        printf "\b \b";
        [[ "${openUrl}" == "true" ]] && open "${url}";
        return 0;
    }

    function getFreePort {
        local port="";
        until [[ "${port}" != "" ]]
        do
            port="$(($RANDOM % 64511 + 1024))"
            netstat -an | grep tcp4 | grep LISTEN | awk '{print $4}' | awk -F"." '{print $NF}' | /usr/bin/grep -e "^${port}$" &>/dev/null;
            [[ $? -eq 0 ]] && port="";
        done
        echo ${port};
    }

    function shellLoadTime {
        for i in $(seq 1 10); do /usr/bin/time $SHELL -i -c exit; done
    }

    function serv {
        function usage { echo "Usage: $0 [-p <port:random>] [-d <dir:pwd>] [-b <bind:localhost>]"; }
        local port=$(getFreePort);
        local dir=$(pwd);
        local bind="localhost";

        while getopts 'p:d:b:' OPT; do
          case "$OPT" in
            p)
              if [[ "${OPTARG}" =~ ^-?[0-9]+$ ]]
              then
                port="${OPTARG}"
              else
                usage;
                return 1;
              fi
              ;;

            d)
              dir="${OPTARG}";
              ;;

            b)
              bind="${OPTARG}";
              ;;
            ?)
              usage && return 0
              ;;
          esac
        done
        python3 -m http.server $port --directory "$dir" --bind "$bind" &
        echo "HTTP server listening at http://$bind:$port";
        open http://$bind:$port;
        fg;

    }
}

# Only if this is a login shell
if [[ $- = *i* ]]
then
    loadAliases
    [[ -e "${HOME}/.loginenv" ]] && source "${HOME}/.loginenv" 2>/dev/null;
    [[ -e "${HOME}/.git-completion" ]] && source "${HOME}/.git-completion" 2>/dev/null;
    # [[ -e "/usr/local/bin/kubectl" ]] && source <(kubectl completion $(basename ${SHELL}))
    [[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh" || test 0;
    which direnv &>/dev/null && eval "$(direnv hook ${SHELL})"
    which starship &>/dev/null && eval "$(starship init ${SHELL})";
fi
