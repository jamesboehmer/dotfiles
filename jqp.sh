#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

VERSION="0.7.0";

URL="https://github.com/noahgorstein/jqp/releases/download/v${VERSION}/jqp_${OKERNEL}_${ARCH}.tar.gz";

which jqp &>/dev/null || TARGZ=true curlzipinstall "${URL}" "${HOME}/.local/bin" "jqp";
