#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

VERSION="0.9.2";

URL="https://github.com/MrMarble/termsvg/releases/download/v${VERSION}/termsvg-${VERSION}-${KERNEL}-${ARCH}.zip";
which termsvg &>/dev/null || curlzipinstall "${URL}" "${HOME}/.local/bin/" "termsvg-${VERSION}-${KERNEL}-${ARCH}/termsvg";
