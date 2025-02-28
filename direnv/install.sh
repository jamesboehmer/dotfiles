#!/bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"
THIS="$(pwd)/$(basename ${BASH_SOURCE[0]})";

LIBDIR="${HOME}/.config/direnv/lib";

pushd lib;
THISDIR="$(pwd)";

mkdir -p "${LIBDIR}"

find . -type f -name '*.sh' | awk -F'/' '{print $NF}' | while read direnvscript; do
    echo -e "Linking ${LIBDIR}/${direnvscript} -> ${THISDIR}/${direnvscript}";
    ln -sf "${THISDIR}/${direnvscript}" "${LIBDIR}/${direnvscript}";
done


