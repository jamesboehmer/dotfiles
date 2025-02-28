#!/bin/bash

[[ $# -lt 1 ]] && echo "Usage: $0 <trusted_host>" && exit 1;

PEM=$(mktemp -t tmp) && \
openssl s_client -connect "$1" 2>/dev/null < /dev/null | sed -ne '/BEGIN CERT/,/END CERT/p' > $PEM && \
security add-trusted-cert -r trustAsRoot -k ~/Library/Keychains/login.keychain $PEM && \
rm $PEM
