export SUDO="";
if [[ $EUID -ne 0 ]]
then
    export SUDO="sudo";
fi

export OKERNEL="$(uname -s)";
export KERNEL="$(echo ${OKERNEL} | tr '[:upper:]' '[:lower:]')";
if [[ "${KERNEL}" == "linux" ]]; then
	export ARCH="$(dpkg --print-architecture)";
elif [[ "${KERNEL}" == "darwin" ]]; then
	export ARCH="$(uname -m | tr '[:upper:]' '[:lower:]')";
fi

export MACHINE="$(uname -m | tr '[:upper:]' '[:lower:]')";

function gitcloneinstall() {
	# Usage: gitcloneinstall URL dir
	if [[ -e "${2}" ]]; then
		if [[ "${DOUPDATE}" == "true" ]]; then
			cd "${2}";
			echo "Updating ${2}...";
			git pull;
		else
			echo "${2} exists.  Skipping install.";
		fi
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
		if [[ "${DOUPDATE}" != "true" ]]; then
			echo "${2} exists.  Skipping install.";
			return;
		fi
	fi
	echo "Downloading ${1} to ${2}...";
	PARENTDIR="$(dirname ${2})";
	mkdir -p "${PARENTDIR}";
	curl -fsSL "${1}" -o "${2}" && chmod +x "${2}";
}

function curlzipinstall() {
	# Usage: curlzipinstall URL targetdir file1 [file2...fileN]
	if [[ "${TARGZ}" == "true" ]]; then
		EXT=".tar.gz";
		CMD="tar xzvf";
	else
		EXT=".zip";
		CMD="unzip";
	fi
	URL="${1}";
	shift;
	TARGETDIR="${1}";
	mkdir -p "${TARGETDIR}";
	shift;
	DLDIR="$(mktemp -d)";
	DLFILE="$$${EXT}";
	cd "${DLDIR}";
	echo "Downloading ${URL} to ${DLDIR}/${DLFILE}";
	curl -fsSL "${URL}" -o "${DLFILE}";
	${CMD} "${DLFILE}";
	for fname in "${@}"; do
		if [[ -e "${fname}" ]]; then
			echo "Copying ${fname} to ${TARGETDIR}";
			cp "${fname}" "${TARGETDIR}/";
		else
			echo "${fname} doesn't exist.  Skipping.";
		fi
	done
}

function checkfor() {
	# Usage: checkfor program
	which ${1} &>/dev/null;
	return $?;
}
function dangerous() {
	# Usage: dangerous url $args (e.g. "bash" "FORCE=yes sh" etc)

	DOINSTALL="true"; # be default always install
	if [[ ! -z "${CHECKFOR}" ]]; then
		# if we're asked to check for a program, do so and set DOINSTALL to false if it exists
		checkfor "${CHECKFOR}" && DOINSTALL="false";
	fi

	# ensure we DOINSTALL no matter what if DOUPDATE is set, even if the program exists
	[[ "${DOUPDATE}" == "true" ]] && DOINSTALL="true";

	if [[ "${DOINSTALL}" != "true" ]]; then
		echo "${CHECKFOR:-$1} already installed.  Skipping.";
		return;
	fi

	echo "Installing from ${1}...";
	URL="${1}";
	shift;
	curl -fsSL "${URL}" | ${@}
}

function curldpkginstall() {
	DOINSTALL="true"; # be default always install
	if [[ ! -z "${CHECKFOR}" ]]; then
		# if we're asked to check for a program, do so and set DOINSTALL to false if it exists
		checkfor "${CHECKFOR}" && DOINSTALL="false";
	fi

	# ensure we DOINSTALL no matter what if DOUPDATE is set, even if the program exists
	[[ "${DOUPDATE}" == "true" ]] && DOINSTALL="true";

	if [[ "${DOINSTALL}" != "true" ]]; then
		echo "${CHECKFOR:-$1} already installed.  Skipping.";
		return;
	fi

	echo "Installing from ${1}...";
	URL="${1}";
	shift;
	tmpfile="$(mktemp)";
	curl -fsSL "${URL}" > "${tmpfile}";
	${SUDO} dpkg -i "${tmpfile}";
}

export gitcloneinstall;
export curlbininstall;
export curlzipinstall;
export dangerous;
export curldpkginstall;
