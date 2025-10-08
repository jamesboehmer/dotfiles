#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

checkfor aws-vault || curlbininstall "$(get_gh_latest_release ByteNess/aws-vault "aws-vault-${KERNEL}-${ARCH}")" "${HOME}/.local/bin/aws-vault";
