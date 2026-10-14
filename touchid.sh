#!/bin/bash

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping mac touch ID." && exit 0; }

echo "Configuring mac touch ID...";

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";

TIME="$(date +%Y%m%d%H%M%S)";

# pam_tid.so can't reach Touch ID from processes detached from the GUI session
# (tmux, herdr, etc.); pam_reattach.so reattaches them first.
BREW="$(command -v brew)";
[[ -n "${BREW}" ]] && { "${BREW}" list pam-reattach &>/dev/null || "${BREW}" install pam-reattach </dev/null; };
PAM_REATTACH="$([[ -n "${BREW}" ]] && "${BREW}" --prefix)/lib/pam/pam_reattach.so";

PAM_SUDO="/etc/pam.d/sudo_local";
[[ ! -e "${PAM_SUDO}" ]] && sudo touch "${PAM_SUDO}" && sudo chmod 444 "${PAM_SUDO}";

tmpfile="$(mktemp)";
grep "#" "${PAM_SUDO}" >> "${tmpfile}";
[[ -e "${PAM_REATTACH}" ]] && echo "auth       optional       ${PAM_REATTACH}" >> "${tmpfile}";
echo "auth       sufficient     pam_tid.so" >> "${tmpfile}";
grep -v "#" "${PAM_SUDO}" | grep -v -e "pam_tid.so" -e "pam_reattach.so" >> "${tmpfile}";

if ! cmp -s "${tmpfile}" "${PAM_SUDO}"
then
    echo "Adding touch ID to ${PAM_SUDO}";
    sudo cp "${PAM_SUDO}" "${PAM_SUDO}.${TIME}";
    sudo cp "${tmpfile}" "${PAM_SUDO}";
    sudo chmod 444 "${PAM_SUDO}";
fi
rm -f "${tmpfile}";
