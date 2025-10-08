#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)";
URL="https://dl.k8s.io/release/${VERSION}/bin/${KERNEL}/${ARCH}/kubectl";

checkfor kubectl || curlbininstall "${URL}" "${HOME}/.local/bin/kubectl";
