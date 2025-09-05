#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";

CLEANUPFILE="${1:-${CLEANUPFILE:-$(mktemp)}}"
export CLEANUPFILE;

function cleanup() {
	# Clean up the old symlinks
	if [[ -z "${SKIPCLEANUP}" ]]; then
		echo "*** Cleaning old files.  Set SKIPCLEANUP=true to skip cleanup next time. ***";
		xargs -t -I {} rm {} < "${CLEANUPFILE}";
	else
		echo "*** CLEANUP SKIPPED: ***";
		cat "${CLEANUPFILE}";
	fi
}

trap cleanup EXIT SIGINT SIGQUIT SIGHUP;

${THISDIR}/brew.sh && [[ -e /opt/homebrew/bin/brew ]] && eval $(/opt/homebrew/bin/brew shellenv);
${THISDIR}/apt.sh;
${THISDIR}/debian.sh;
# ${THISDIR}/cargo.sh;
${THISDIR}/ssh.sh;
${THISDIR}/starship.sh;
${THISDIR}/direnv.sh;
${THISDIR}/iterm.sh;
${THISDIR}/localrc.sh;
${THISDIR}/git.sh;
${THISDIR}/touchid.sh;
${THISDIR}/docker.sh;
${THISDIR}/defaults.sh;
${THISDIR}/termsvg.sh;
${THISDIR}/dotfiles.sh;
${THISDIR}/launchagents.sh;

# Ensure GPG git signatures in codespaces
[[ "${CODESPACES}" == "true" && -e "${HOME}/.bin/git-gpg-config" ]] && "${HOME}/.bin/git-gpg-config" local codespace;

# Fix zsh compinit permission issue
type zsh &>/dev/null && zsh -ic 'compaudit' | while read f; do chmod g-w "$f"; done
