#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

checkfor gh || URL="$(get_gh_latest_release cli/cli "gh_.+_${KERNEL}_${ARCH}.tar.gz")" TARGZ=true curlzipinstall "${URL}" "${HOME}/.local/bin" "gh_${VERSION}_${KERNEL}_${ARCH}/bin/gh";
