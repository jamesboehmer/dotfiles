#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

[[ $KERNEL == "darwin" ]] && KERNEL="apple-darwin";
[[ $KERNEL == "linux" ]] && KERNEL="unknown-linux-gnu";
[[ $ARCH == "arm64" ]] && ARCH="aarch64";

checkfor asciinema || curlbininstall "$(get_gh_latest_release asciinema/asciinema "asciinema-${ARCH}-${KERNEL}")" "${HOME}/.local/bin/asciinema"
