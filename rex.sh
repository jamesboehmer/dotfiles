#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
. "${THISDIR}/functions.sh";

case "${KERNEL}" in
	linux)
		checkfor rex || dangerous "https://pkgs.superlogical.com/rex/install.sh" "sh"
		;;
	darwin)
		# Rex.app installs and updates the rex CLI itself, so check for the app, not rex on the PATH.
		# Don't replace the app out from under a running copy on DOUPDATE.
		if [[ "${DOUPDATE}" == "true" ]] && pgrep -f "/Applications/Rex.app/Contents/MacOS/" &>/dev/null; then
			echo "Rex.app is running.  Quit it and re-run to update.";
		else
			curldmginstall "https://blob.superlogical.com/download/rex-app/preview/latest.dmg" "Rex.app"
		fi
		;;
	*) echo "Unsupported kernel: ${KERNEL}.  Skipping rex.";;
esac
