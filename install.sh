#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

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
case $KERNEL in
	linux)  BREW="/home/linuxbrew/.linuxbrew/bin/brew";;
	darwin) BREW="/opt/homebrew/bin/brew";;
	*) echo "Unsupported kernel :${KERNEL}" && exit 1;;
esac

${THISDIR}/brewinstall.sh && [[ -e ${BREW} ]] && eval $(${BREW} shellenv);
${BREW} install git jq starship direnv
# ${THISDIR}/apt.sh;
# ${THISDIR}/debian.sh;
# ${THISDIR}/cargo.sh;
${THISDIR}/ssh.sh;
${THISDIR}/starship.sh;
${THISDIR}/direnv.sh;
${THISDIR}/iterm.sh;
${THISDIR}/ghostty.sh;
${THISDIR}/localrc.sh;
${THISDIR}/git.sh;
${THISDIR}/touchid.sh;
${THISDIR}/docker.sh;
${THISDIR}/kubectl.sh;
${THISDIR}/defaults.sh;
${THISDIR}/asciinema.sh;
${THISDIR}/termsvg.sh;
${THISDIR}/jnv.sh;
${THISDIR}/jqp.sh;
${THISDIR}/gh.sh;
${THISDIR}/gnupg.sh;
${THISDIR}/dotfiles.sh;
${THISDIR}/launchagents.sh;
${THISDIR}/brewpackages.sh

# Ensure GPG git signatures in codespaces
[[ "${CODESPACES}" == "true" && -e "${HOME}/.bin/git-gpg-config" ]] && "${HOME}/.bin/git-gpg-config" local codespace;

# Fix zsh compinit permission issue
type zsh &>/dev/null && zsh -ic 'compaudit' | while read f; do chmod g-w "$f"; done
