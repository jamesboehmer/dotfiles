#!/usr/bin/env bash

# Connect stdin/stdout to the Rex server inside a devcontainer.  The socat
# launchagents that rexdevcontainers.sh creates run this once per connection,
# so the container is looked up fresh each time and survives rebuilds.
# Usage: _rex-devcontainer-dial.sh [devcontainer.config_file label value]
# (defaults to $REX_DEVCONTAINER_CONFIG)

if [[ -n "${DEBUG}" ]]; then
    set -x
fi

CONFIG="${1:-${REX_DEVCONTAINER_CONFIG}}";
[[ -z "${CONFIG}" ]] && echo "Usage: $0 <devcontainer.config_file>" >&2 && exit 1;

CONTAINER="$(docker ps -q --filter "label=devcontainer.config_file=${CONFIG}" | head -1)";
[[ -z "${CONTAINER}" ]] && echo "No running devcontainer for ${CONFIG}" >&2 && exit 1;

# Run as the devcontainer's remoteUser (the last one set in its metadata wins),
# since that's who owns the Rex server.  Fall back to the container's default user.
REMOTEUSER="$(docker inspect "${CONTAINER}" --format '{{index .Config.Labels "devcontainer.metadata"}}' 2>/dev/null | jq -r '[.[] | .remoteUser // empty] | last // empty' 2>/dev/null)";

exec docker exec -i ${REMOTEUSER:+-u "${REMOTEUSER}"} "${CONTAINER}" rex __internal dial-stdio
