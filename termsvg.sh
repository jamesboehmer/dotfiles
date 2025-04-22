#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

VERSION="0.9.2";

EXT=".zip";
TARGZ="";
[[ "${KERNEL}" == "linux" ]] && EXT=".tar.gz" && TARGZ="true";

URL="https://github.com/MrMarble/termsvg/releases/download/v${VERSION}/termsvg-${VERSION}-${KERNEL}-${ARCH}${EXT}";
which termsvg &>/dev/null || TARGZ="${TARGZ}" curlzipinstall "${URL}" "${HOME}/.local/bin/" "termsvg-${VERSION}-${KERNEL}-${ARCH}/termsvg";
