#!/bin/bash

[[ -e /usr/bin/apt ]] || { echo "Not Debian.  Bye" && exit 0; }

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

SUDO="";
if [[ $EUID -ne 0 ]]
then
    SUDO="sudo";
fi

$SUDO apt update;
$SUDO apt-get install -y $(grep -vE "^\s*#" packages.txt  | tr "\n" " ")

#disable DVC analytics
which dvc &>/dev/null && dvc config --global core.analytics false
