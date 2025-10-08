#!/bin/bash

echo "Configuring direnv...";

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
. "${THISDIR}/functions.sh";

checkfor direnv || dangerous "https://direnv.net/install.sh" bash;

TIME="$(date +%Y%m%d%H%M%S)";

CONFIGDIR="${HOME}/.config/direnv";
THISCONFIGDIR="${THISDIR}/direnv";

mkdir -p "$(dirname "${CONFIGDIR}")";

if [[ -d "${CONFIGDIR}" && ! -L "${CONFIGDIR}" ]]; then
    mv "${CONFIGDIR}" "${CONFIGDIR}.dotfilebak.${TIME}";
fi


echo -e "Linking ${CONFIGDIR} -> ${THISCONFIGDIR}";
ln -sfn "${THISCONFIGDIR}" "${CONFIGDIR}";


