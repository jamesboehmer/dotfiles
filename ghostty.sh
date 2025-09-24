#!/bin/bash

echo "Configuring ghostty...";

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
TIME="$(date +%Y%m%d%H%M%S)";

CONFIGDIR="${HOME}/.config/ghostty";
THISCONFIGDIR="${THISDIR}/ghostty";

mkdir -p "$(dirname "${CONFIGDIR}")";

if [[ -d "${CONFIGDIR}" && ! -L "${CONFIGDIR}" ]]; then
    mv "${CONFIGDIR}" "${CONFIGDIR}.dotfilebak.${TIME}";
fi


echo -e "Linking ${CONFIGDIR} -> ${THISCONFIGDIR}";
ln -sfn "${THISCONFIGDIR}" "${CONFIGDIR}";


