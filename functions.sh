export SUDO="";
if [[ $EUID -ne 0 ]]
then
    export SUDO="sudo";
fi

export KERNEL="$(uname -s | tr '[:upper:]' '[:lower:]')";
if [[ "${KERNEL}" == "linux" ]]; then
	export ARCH="$(dpkg --print-architecture)";
elif [[ "${KERNEL}" == "darwin" ]]; then
	export ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')";
fi

export MACHINE="$(uname -m | tr '[:upper:]' '[:lower:]')";

function gitcloneinstall() {
	# Usage: gitcloneinstall URL dir
	if [[ -e "${2}" ]]; then
		echo "${2} exists.  Skipping install.";
		return;
	fi
	echo "Cloning ${1} to ${2}...";
	PARENTDIR="$(dirname ${2})";
	mkdir -p "${PARENTDIR}";
	git clone "${1}" "${2}";
}

function curlbininstall() {
	# Usage: curlbininstall URL targetfile
	if [[ -e "${2}" ]]; then
		echo "${2} exists.  Skipping install.";
		return;
	fi
	echo "Downloading ${1} to ${2}...";
	PARENTDIR="$(dirname ${2})";
	mkdir -p "${PARENTDIR}";
	curl -fsSL "${1}" -o "${2}" && chmod +x "${2}";
}

function curlzipinstall() {
	# Usage: curlzipinstall URL targetdir file1 [file2...fileN]
	URL="${1}";
	shift;
	TARGETDIR="${1}";
	mkdir -p "${TARGETDIR}";
	shift;
	DLDIR="$(mktemp -d)";
	DLFILE="$$.zip";
	cd "${DLDIR}";
	echo "Downloading ${URL} to ${DLDIR}/${DLFILE}";
	curl -fsSL "${URL}" -o "$$.zip";
	unzip "${DLFILE}";
	for fname in "${@}"; do
		if [[ -e "${fname}" ]]; then
			echo "Copying ${fname} to ${TARGETDIR}";
			cp "${fname}" "${TARGETDIR}/";
		else
			echo "${fname} doesn't exist.  Skipping.";
		fi
	done
}

function dangerous() {
	# Usage: dangerous url $args (e.g. "bash" "FORCE=yes sh" etc)
	echo "Installing from ${1}...";
	URL="${1}";
	shift;
	curl -fsSL "${URL}" | ${@}
}

export gitcloneinstall;
export curlbininstall;
export curlzipinstall;
export dangerous;
