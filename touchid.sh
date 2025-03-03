#!/bin/bash

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping mac touch ID." && exit 0; }

echo "Configuring mac touch ID...";

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";

TIME="$(date +%Y%m%d%H%M%S)";

PAM_SUDO="/etc/pam.d/sudo";
grep "pam_tid.so" "${PAM_SUDO}" &>/dev/null
if [[ $? -ne 0 ]]
then
    echo "Adding touch ID to ${PAM_SUDO}";
    tmpfile="$(mktemp)";
    grep "#" "${PAM_SUDO}" >> "${tmpfile}";
    echo "auth       sufficient     pam_tid.so" >> "${tmpfile}";
    grep -v "#" "${PAM_SUDO}" >> "${tmpfile}";
    sudo cp "${PAM_SUDO}" "${PAM_SUDO}.${TIME}";
    sudo cp "${tmpfile}" "${PAM_SUDO}";
    sudo chmod 444 "${PAM_SUDO}";
fi
