#!/bin/bash

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping launchagents." && exit 0; }

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
BASEDIR="${THISDIR}/launchagents";
TIME="$(date +%Y%m%d%H%M%S)";
CLEANUPFILE="${1:-${CLEANUPFILE}}"
. "${THISDIR}/functions.sh";

find "${BASEDIR}" -maxdepth 1 -name '*.plist' | awk -F'/' '{print $NF}' | while read plistfile
do
    [[ -e "${HOME}/${plistfile}" && -n "${CLEANUPFILE}" ]] && mv "${HOME}/${plistfile}" "${HOME}/${plistfile}.plistfilebak.${TIME}" && echo "${HOME}/${plistfile}.plistfilebak.${TIME}" >> "${CLEANUPFILE}";
    echo -e "Linking ${HOME}/Library/LaunchAgents/${plistfile} -> ${BASEDIR}/${plistfile}";
    ln -sf "${BASEDIR}/${plistfile}" "${HOME}/Library/LaunchAgents/${plistfile}";
    launchctl load -wF "${HOME}/Library/LaunchAgents/${plistfile}" 2>/dev/null;
done
