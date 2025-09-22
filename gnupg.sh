#!/bin/bash

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping gnupg." && exit 0; }

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";

TIME="$(date +%Y%m%d%H%M%S)";

which pinentry-mac &>/dev/null || { echo "Missing pinentry-mac.  Skipping gpg-agent config." && exit 0; }

CONFFILE="${HOME}/.gnupg/gpg-agent.conf";
CONFLINE="pinentry-program $(which pinentry-mac)";

[[ ! -e "${CONFFILE}" ]] && mkdir "$(dirname "${CONFFILE}")" && touch "${CONFFILE}";

grep "${CONFLINE}" "${CONFFILE}" &>/dev/null;

if [[ $? -ne 0 ]]; then
    echo "Adding '${CONFFILE}' to ${CONFFILE}";
    TMPFILE="$(mktemp)";
    grep -v "pinentry-program" "${CONFFILE}" > "${TMPFILE}";
    echo "${CONFLINE}" >> "${TMPFILE}";
    cat "${TMPFILE}" > "${CONFFILE}";
    killall gpg-agent;
fi

LINKED="$(brew info gnupg --json | jq '.[0].linked_keg')";
if [[ "${LINKED}" == "null" ]]; then
    killall gpg-agent >/dev/null;
    brew link gnupg;
fi

gpg-agent --daemon;