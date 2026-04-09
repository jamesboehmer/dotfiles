#!/usr/bin/env bash

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

# Kill any existing gpg-agent
pkill -9 -x gpg-agent
sleep 0.5

# Set up GPG agent socket forwarding via socat
SOCKET=$HOME/.gnupg/S.gpg-agent
PROCESS="socat.*${SOCKET}.*:8125"

# Check if socat is already running AND controlling the socket
if pgrep -f "${PROCESS}" > /dev/null; then
    # Socat process exists - check if it's actually controlling our socket
    if [ -S "$SOCKET" ] && fuser "$SOCKET" > /dev/null 2>&1; then
        [[ -n "${DEBUG}" ]] && echo "Socat already running and controlling $SOCKET, skipping restart"
        exit 0
    else
        # Socat is running but not controlling the socket - kill it
        [[ -n "${DEBUG}" ]] && echo "Socat running but not controlling socket, restarting"
        pkill -f "${PROCESS}"
    fi
fi

rm -f "$SOCKET"

# Start socat in background to forward GPG agent socket to host
# Use setsid to properly detach from the shell
setsid socat UNIX-LISTEN:"$SOCKET",fork,mode=600 TCP:host.docker.internal:8125 >/dev/null 2>&1 &

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

echo "Socat started for GPG agent forwarding"