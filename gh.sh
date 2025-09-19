#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

VERSION="2.79.0";

URL="https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_${KERNEL}_${ARCH}.tar.gz"

which gh &>/dev/null || TARGZ=true curlzipinstall "${URL}" "${HOME}/.local/bin" "gh_${VERSION}_${KERNEL}_${ARCH}/bin/gh";
