#!/bin/bash

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
WHEN="$(date)";


function newlocalrcfile() {
	# Usage: newlocalrcfile ${basename} [varname value [varname value [...]]]
	FILENAME="${HOME}/.local/$1";
	echo "Configuring ${FILENAME}";
	mkdir -p "${HOME}/.local" && rm -f "${FILENAME}" && echo "# CREATED BY ${THIS} at ${WHEN}.  DO NOT EDIT" > "${FILENAME}";
	shift;
	while [ $# -gt 1 ]; do
		varname="$1";
		value="$2";
		shift;
		shift;
		if [[ $(declare -F "${varname}" &>/dev/null; echo $?) -eq 0 ]]; then
			declare -f "${varname}" >> "${FILENAME}";
			[[ $(declare -F "${value}" &>/dev/null; echo $?) -eq 0 ]] && declare -f "${value}" >> "${FILENAME}";
		else
			echo "export ${varname}=\"${value}\"" >> ${FILENAME};
		fi
	done
}

#disable DVC analytics
type dvc &>/dev/null && dvc config --global core.analytics false

[[ "$(uname -s)" == "Darwin" ]] && [[ $(which brew &>/dev/null; echo $?) -eq 0 ]] && newlocalrcfile devrc \
OPENBLAS "$(brew --prefix openblas)" \
OPENSSL "$(brew --prefix openssl@1.1)" \
ZLIB "$(brew --prefix zlib)" \
PROTOBUF "$(brew --prefix protobuf)" \
LDFLAGS '-L${OPENSSL}/lib:${ZLIB}/lib:${PROTOBUF}/lib' \
CPPFLAGS '-I${OPENSSL}/include:${ZLIB}/include:${PROTOBUF}/include' \
CFLAGS '${CPPFLAGS}' \
HDF5_DIR "$(brew --prefix hdf5)" \
PKG_CONFIG_PATH '-L${OPENSSL}/lib/pkgconfig:${ZLIB}/lib/pkgconfig'

[[ "$(uname -s)" == "Darwin" ]] && newlocalrcfile grpcpythonrc 'GRPC_PYTHON_BUILD_SYSTEM_OPENSSL' '1' 'GRPC_PYTHON_BUILD_SYSTEM_ZLIB' '1';

newlocalrcfile pyenvrc 'PYENV_ROOT' '$HOME/.pyenv' 'PATH' '$PYENV_ROOT/bin:$PATH';
newlocalrcfile goenvrc 'GOENV_ROOT' '$HOME/.goenv' 'PATH' '$GOENV_ROOT/bin:$PATH';
newlocalrcfile tfenvrc 'PATH' '$HOME/.tfenv/bin:$PATH';
newlocalrcfile nodenvrc 'PATH' '$HOME/.nodenv/bin:$PATH';
newlocalrcfile pipxrc 'PIPX_DEFAULT_PYTHON' 'python';
