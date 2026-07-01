#!/usr/bin/env bash

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

# Set up keyboxd socket forwarding via socat
SOCKET=$HOME/.gnupg/S.keyboxd
PROCESS="socat.*${SOCKET}.*:8126"

# Kill any existing keyboxd
KEYBOXDPID="$(pgrep keyboxd)";
echo $KEYBOXDPID
if [[ "${KEYBOXDPID}" != "" ]]; then
    # keyboxd usually lives in libexecdir, so ask gpgconf where it is
    if type gpgconf &>/dev/null; then
        OLDPATH="$(gpgconf --list-components 2>/dev/null | awk -F: '$1=="keyboxd"{print $3}')";
    fi
    [[ -z "${OLDPATH}" ]] && OLDPATH="$(dirname $(which gpg))/keyboxd";
    [[ -n "${DEBUG}" ]] && echo "Killing keyboxd..."
    kill -9 "${KEYBOXDPID}";
    if [[ -e "${OLDPATH}" ]]; then
        mv "${OLDPATH}" "${OLDPATH}.old";
        if [[ -s "${OLDPATH}.old" ]]; then
            OLDTARGETPATH="$(readlink -f "${OLDPATH}.old")";
            mv "${OLDTARGETPATH}" "${OLDTARGETPATH}.old";
        fi
    fi
    SOCATPID="$(pgrep -f "${PROCESS}")";
    if [[ "${SOCATPID}" != "" ]]; then
        [[ -n "${DEBUG}" ]] && echo "Killing socat..."
        kill -9 "${SOCATPID}";
    fi
fi


# Check if socat is already running AND controlling the socket
SOCATPID="$(pgrep -f "${PROCESS}")";
if [[ "${SOCATPID}" != "" ]]; then
    # Socat process exists - check if it's actually controlling our socket
    if [ -S "$SOCKET" ] && [[ $(fuser $SOCKET | tail -1 | awk '{print $NF}') == "${SOCATPID}" ]] > /dev/null 2>&1; then
        [[ -n "${DEBUG}" ]] && echo "Socat already running and controlling $SOCKET, skipping restart"
        exit 0
    else
        # Socat is running but not controlling the socket - kill it
        [[ -n "${DEBUG}" ]] && echo "Socat running but not controlling socket, restarting"
        pkill -f "${PROCESS}"
    fi
fi

rm -f "$SOCKET"

# Start socat in background to forward keyboxd socket to host
# Use setsid to properly detach from the shell
setsid socat UNIX-LISTEN:"$SOCKET",fork,mode=600 TCP:host.docker.internal:8126 >/dev/null 2>&1 &

TIMEOUT=5
ELAPSED=0
while [ ! -S "$SOCKET" ]; do
    sleep 0.1
    ELAPSED=$((ELAPSED + 1))
    if [ "$ELAPSED" -ge "$((TIMEOUT * 10))" ]; then
        echo "Timed out waiting for socat to create $SOCKET"
        exit 1
    fi
done

echo "Socat started for keyboxd forwarding"
