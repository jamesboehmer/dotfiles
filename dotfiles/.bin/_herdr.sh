#!/bin/bash

# Wrapper for herdr, symlinked as ~/.local/bin/herdr at install time.
# Inside a devcontainer, ensure a herdr server is running (launching one in
# the background if needed) before starting the client. Everywhere else, it
# just passes through to the real herdr binary.

# Resolve the real herdr binary: the first `herdr` on PATH that isn't this
# wrapper. Comparing resolved paths avoids recursing into ourselves, since
# ~/.local/bin/herdr resolves back to this script.
SELF="$(readlink -f "${BASH_SOURCE[0]}")";
REAL_HERDR="";
for candidate in $(type -ap herdr); do
	[[ "$(readlink -f "${candidate}")" != "${SELF}" ]] && { REAL_HERDR="${candidate}"; break; }
done

[[ -z "${REAL_HERDR}" ]] && { echo "herdr: could not find the real herdr binary on PATH" >&2; exit 1; }

# Outside a devcontainer, herdr manages its own server; just pass through.
if [[ "${DEVCONTAINER}" != "true" && "${REMOTE_CONTAINERS}" != "true" ]]; then
	exec "${REAL_HERDR}" "$@";
fi

# Only ensure a background server for interactive session launches: a bare
# invocation, or one with leading flags like --session/--remote. A bareword
# subcommand (server, status, api, config, ...) is passed straight through so
# we never spawn a server just to run a management or status command.
if [[ $# -gt 0 && "${1}" != -* ]]; then
	exec "${REAL_HERDR}" "$@";
fi

function _server_running() {
	"${REAL_HERDR}" status server 2>/dev/null | grep -q '^status: running';
}

if ! _server_running; then
	echo "herdr: no server running, launching one in the background..." >&2;
	nohup "${REAL_HERDR}" server >/dev/null 2>&1 &
	disown;
	for _ in $(seq 1 50); do
		_server_running && break;
		sleep 0.2;
	done
	_server_running || { echo "herdr: server did not come up in time" >&2; exit 1; }
fi

exec "${REAL_HERDR}" "$@";
