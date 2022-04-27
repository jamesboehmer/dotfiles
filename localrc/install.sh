#!/bin/bash

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Bye" && exit 0; }

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
WHEN="$(date)";


function newrcfile() {
	FILENAME=$1;
	echo "Configuring ${FILENAME}";
	mkdir -p ~/.local && rm -f "${FILENAME}" && echo "# CREATED BY ${THIS} at ${WHEN}.  DO NOT EDIT" > "${FILENAME}";
}

FILENAME=~/.local/devrc;
newrcfile ${FILENAME};

which brew &>/dev/null
if [[ $? -eq 0 ]]
then
	cat >> "${FILENAME}" <<EOF
export OPENBLAS="$(brew --prefix openblas)"
export OPENSSL="$(brew --prefix openssl)"
export LDFLAGS="-L\${OPENSSL}/lib"
export CPPFLAGS="-I\${OPENSSL}/include"
export HDF5_DIR="$(brew --prefix hdf5)"

EOF
fi
	cat >> "${FILENAME}" <<EOF
export GRPC_PYTHON_BUILD_SYSTEM_OPENSSL=1
export GRPC_PYTHON_BUILD_SYSTEM_ZLIB=1

EOF

LOGITECHPLIST="/Library/LaunchAgents/com.logitech.manager.daemon.plist";
if [[ -e "${LOGITECHPLIST}" ]]
then
	FILENAME=~/.local/logitechrc;
	newrcfile ${FILENAME};

	cat >> "${FILENAME}" <<EOF
logiload() {
	launchctl load ${LOGITECHPLIST}
}

logiunload() {
	launchctl unload ${LOGITECHPLIST}
}

logiunload &>/dev/null

EOF
fi

if [[ -e /usr/bin/defaults ]]
then
	FILENAME=~/.local/bluetoothrc;
	newrcfile ${FILENAME};

	cat >> "${FILENAME}" <<EOF
setbluetoothaptx() {
	sudo defaults write bluetoothaudiod "Enable AptX codec" -bool true
	sudo defaults write bluetoothaudiod "Enable AAC codec" -bool true
	sudo defaults read bluetoothaudiod
}

EOF
fi


