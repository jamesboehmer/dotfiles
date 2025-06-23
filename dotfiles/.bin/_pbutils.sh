#!/bin/bash

function _pbserver() {
	socat tcp-listen:8121,fork,bind=localhost EXEC:'pbcopy' &>/dev/null &
	socat -U tcp-listen:8122,fork,bind=localhost EXEC:'pbpaste' &>/dev/null &
}

function _pbpaste() {
	socat -u tcp:host.docker.internal:8122 STDIO;
}

function _pbcopy() {
	tee <&0 | socat - tcp:host.docker.internal:8121 2>/dev/null;
}

THIS="$(basename ${BASH_SOURCE[0]})";

case "${THIS}" in
	pbserver|pbcopy|pbpaste)
		_${THIS};
		;;
	*)
		echo "Unknown command: ${THIS}";
		exit 1;
		;;
esac

