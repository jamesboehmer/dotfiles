#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

VERSION="3.0.0";


[[ $KERNEL == "darwin" ]] && KERNEL="apple-darwin";
[[ $KERNEL == "linux" ]] && KERNEL="unknown-linux-gnu";
[[ $ARCH == "arm64" ]] && ARCH="aarch64";

URL="https://github.com/asciinema/asciinema/releases/download/v${VERSION}/asciinema-${ARCH}-${KERNEL}";

which asciinema &>/dev/null || curlbininstall "${URL}" "${HOME}/.local/bin/asciinema"
