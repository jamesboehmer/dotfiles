#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

VERSION="0.6.1";

[[ $KERNEL == "darwin" ]] && KERNEL="apple-darwin";
[[ $KERNEL == "linux" ]] && KERNEL="unknown-linux-gnu";
[[ $ARCH == "arm64" ]] && ARCH="aarch64";

URL="https://github.com/ynqa/jnv/releases/download/v${VERSION}/jnv-${ARCH}-${KERNEL}.tar.xz";

which jnv &>/dev/null || TARXZ=true curlzipinstall "${URL}" "${HOME}/.local/bin" "jnv-${ARCH}-${KERNEL}/jnv";
