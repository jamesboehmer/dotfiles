#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
THIS="$(pwd)/$(basename ${BASH_SOURCE[0]})";

TIME="$(date +%Y%m%d%H%M%S)";
CLEANUPFILE="${1}";
[[ -z $CLEANUPFILE ]] && CLEANUPFILE="/dev/null";

LIBDIR="${HOME}/.config/direnv/lib";

pushd direnv/lib;
THISDIR="$(pwd)";

find . -type f -name '*.sh' | awk -F'/' '{print $NF}' | while read direnvscript; do
    echo -e "Linking ${LIBDIR}/${direnvscript} -> ${THISDIR}/${direnvscript}";
    ln -sf "${THISDIR}/${direnvscript}" "${LIBDIR}/${direnvscript}";
done


