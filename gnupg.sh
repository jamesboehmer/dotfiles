#!/bin/bash

KERNEL="$(uname -s)";

# Inside a Linux devcontainer, disable every local gpg-agent and keyboxd binary
# so gnupg can't spawn its own -- gpg should instead talk to the sockets that
# socat forwards to the mac host (see dotfiles/.bin/_gpg-agent.sh and
# dotfiles/.bin/_keyboxd.sh).  Set ENABLE_GPG_AGENT=true to opt out.
if [[ "${KERNEL}" == "Linux" ]]; then
    if [[ ("${DEVCONTAINER}" == "true" || "${REMOTE_CONTAINERS}" == "true") \
        && "${ENABLE_GPG_AGENT}" != "true" \
        && "${CODESPACES}" != "true" \
        && "${GITHUB_CODESPACES}" != "true" ]]; then

        # Use sudo for root-owned installs (e.g. system gnupg in /usr/lib/gnupg).
        SUDO="";
        [[ ${EUID} -ne 0 ]] && SUDO="sudo";

        # Collect candidate binary paths: every copy on PATH plus the ones gnupg
        # itself resolves via gpgconf (keyboxd normally lives in libexecdir, not
        # on PATH, so "which" alone would miss it).  Query EVERY gpgconf on PATH:
        # there may be more than one gnupg install (e.g. system apt in
        # /usr/lib/gnupg and homebrew in its Cellar), and each gpgconf only
        # reports the dirs for its own install.
        CANDIDATES="";
        for name in gpg-agent keyboxd; do
            CANDIDATES="${CANDIDATES}"$'\n'"$(which -a "${name}" 2>/dev/null)";
        done
        for gpgconf in $(which -a gpgconf 2>/dev/null | sort -u); do
            for dir in "$("${gpgconf}" --list-dirs bindir 2>/dev/null)" "$("${gpgconf}" --list-dirs libexecdir 2>/dev/null)"; do
                [[ -z "${dir}" ]] && continue;
                for name in gpg-agent keyboxd; do
                    CANDIDATES="${CANDIDATES}"$'\n'"${dir}/${name}";
                done
            done
        done

        echo "${CANDIDATES}" | sort -u | while read -r bin; do
            [[ -z "${bin}" ]] && continue;
            # never disable our own socat-forwarding intercepts in ~/.local/bin
            [[ "${bin}" == "${HOME}/.local/bin/"* ]] && continue;
            # disable the binary and its symlink target (if any)
            for x in "${bin}" "$(readlink -f "${bin}" 2>/dev/null)"; do
                [[ -z "${x}" || "${x}" == *.disabled || "${x}" == "${HOME}/.local/bin/"* ]] && continue;
                if [[ -e "${x}" && ! -e "${x}.disabled" ]]; then
                    echo "Disabling ${x} -> ${x}.disabled";
                    # renaming needs write access to the containing dir; root-owned
                    # system dirs (e.g. /usr/lib/gnupg) require sudo.
                    if [[ -w "$(dirname "${x}")" ]]; then
                        mv "${x}" "${x}.disabled";
                    else
                        ${SUDO} mv "${x}" "${x}.disabled";
                    fi
                fi
            done
        done
    fi
    exit 0;
fi

[[ "${KERNEL}" == "Darwin" ]] || { echo "Not OSX.  Skipping gnupg." && exit 0; }

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