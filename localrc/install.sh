#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
WHEN="$(date)";


function newrcfile() {
	# Usage: newrcfile ${filename} [varname value [varname value [...]]]
	mkdir -p ~/.local;
	FILENAME=$1;
	echo "Configuring ${FILENAME}";
	mkdir -p ~/.local && rm -f "${FILENAME}" && echo "# CREATED BY ${THIS} at ${WHEN}.  DO NOT EDIT" > "${FILENAME}";
	shift;
	echo "$@" | while read varname value; do
		if [[ $(declare -F "${varname}" &>/dev/null; echo $?) -eq 0 ]]; then
			declare -f "${varname}" >> "${FILENAME}";
			[[ $(declare -F "${value}" &>/dev/null; echo $?) -eq 0 ]] && declare -f "${value}" >> "${FILENAME}";
		else
			echo "export ${varname}=\"${value}\"" >> ${FILENAME};
		fi
	done
}

#disable DVC analytics
which dvc &>/dev/null && dvc config --global core.analytics false

LOGITECHPLIST="/Library/LaunchAgents/com.logitech.manager.daemon.plist";
logiload() {
	launchctl load ${LOGITECHPLIST}
}
logiunload() {
	launchctl unload ${LOGITECHPLIST}
}
setbluetoothaptx() {
	sudo defaults write bluetoothaudiod "Enable AptX codec" -bool true
	sudo defaults write bluetoothaudiod "Enable AAC codec" -bool true
	sudo defaults read bluetoothaudiod
}

[[ "$(uname -s)" == "Darwin" ]] && [[ -e "${LOGITECHPLIST}" ]] && newrcfile ~/.local/logitechrc logiload logiunload && echo 'logiunload &>/dev/null' >> ~/.local/logitechrc;
[[ "$(uname -s)" == "Darwin" ]] && [[ -e /usr/bin/defaults ]] && newrcfile ~/.local/bluetoothrc setbluetoothaptx;

[[ "$(uname -s)" == "Darwin" ]] && [[ $(which brew &>/dev/null; echo $?) -eq 0 ]] && newrcfile ~/.local/devrc \
OPENBLAS "$(brew --prefix openblas)" \
OPENSSL "$(brew --prefix openssl@1.1)" \
ZLIB "$(brew --prefix zlib)" \
PROTOBUF "$(brew --prefix protobuf)" \
LDFLAGS '-L${OPENSSL}/lib:${ZLIB}/lib:${PROTOBUF}/lib' \
CPPFLAGS '-I${OPENSSL}/include:${ZLIB}/include:${PROTOBUF}/include' \
CFLAGS '${CPPFLAGS}' \
HDF5_DIR "$(brew --prefix hdf5)" \
PKG_CONFIG_PATH '-L${OPENSSL}/lib/pkgconfig:${ZLIB}/lib/pkgconfig'

[[ "$(uname -s)" == "Darwin" ]] && newrcfile ~/.local/grpcpythonrc 'GRPC_PYTHON_BUILD_SYSTEM_OPENSSL' '1' 'GRPC_PYTHON_BUILD_SYSTEM_ZLIB' '1';

newrcfile ~/.local/pyenvrc 'PYENV_ROOT' '$HOME/.pyenv' 'PATH' '$PYENV_ROOT/bin:$PATH"';
newrcfile ~/.local/goenvrc 'GOENV_ROOT' '$HOME/.goenv' 'PATH' '$GOENV_ROOT/bin:$PATH';
newrcfile ~/.local/tfenvrc 'PATH' '$HOME/.tfenv/bin:$PATH';
newrcfile ~/.local/nodenvrc 'PATH' '$HOME/.nodenv/bin:$PATH';
newrcfile ~/.local/pipxrc 'PIPX_DEFAULT_PYTHON' 'python';
