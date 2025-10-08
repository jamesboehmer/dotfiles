#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";

THISDIR="$(dirname "${THIS}")";

. "${THISDIR}/functions.sh";

checkfor tflint || dangerous "https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh" "bash";
