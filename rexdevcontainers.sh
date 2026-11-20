#!/bin/bash

# Create a socat launchagent for each running devcontainer that exposes the Rex
# server inside it as ~/.local/state/rex-devcontainer-{name}.sock, so the Rex
# GUI can add it as a remote host (unix:///Users/.../rex-devcontainer-{name}.sock).
# Agents key on the devcontainer.config_file label rather than the container, so
# they keep working across rebuilds.  Re-run to pick up new devcontainers.

[[ "$(uname -s)" == "Darwin" ]] || { echo "Not OSX.  Skipping rex devcontainers." && exit 0; }

THIS="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/$(basename ${BASH_SOURCE[0]})";
THISDIR="$(dirname "${THIS}")";
. "${THISDIR}/functions.sh";

DIAL="${THISDIR}/dotfiles/.bin/_rex-devcontainer-dial.sh";
SOCAT="$(which socat 2>/dev/null || echo /opt/homebrew/bin/socat)";
AGENTDIR="${HOME}/Library/LaunchAgents";
SOCKDIR="${HOME}/.local/state";
LOGDIR="${HOME}/Library/Logs";

type docker &>/dev/null || { echo "docker not found.  Skipping rex devcontainers." && exit 0; }
docker info &>/dev/null || { echo "docker not running.  Skipping rex devcontainers." && exit 0; }

mkdir -p "${AGENTDIR}" "${SOCKDIR}" "${LOGDIR}";

function xmlescape() {
    sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g' <<< "${1}";
}

function devcontainername() {
    # /path/to/project/.devcontainer/devcontainer.json        -> project
    # /path/to/project/.devcontainer/python/devcontainer.json -> project-python
    # /path/to/project/.devcontainer.json                     -> project
    local project="$(basename "${1%%/.devcontainer*}")";
    local sub="$(sed -nE 's#.*/\.devcontainer/([^/]+)/devcontainer\.json$#\1#p' <<< "${1}")";
    echo "${project}${sub:+-${sub}}" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9._-]+/-/g';
}

docker ps --filter label=devcontainer.config_file --format '{{.Label "devcontainer.config_file"}}' | sort -u | while read -r CONFIG
do
    [[ -z "${CONFIG}" ]] && continue;
    NAME="$(devcontainername "${CONFIG}")";
    LABEL="com.jamesboehmer.dotfiles.rex-devcontainer-${NAME}";
    PLIST="${AGENTDIR}/${LABEL}.plist";

    # Two projects with the same folder name get a short hash of their config path
    EXISTING="$([[ -e "${PLIST}" ]] && plutil -extract EnvironmentVariables.REX_DEVCONTAINER_CONFIG raw "${PLIST}" 2>/dev/null)";
    if [[ -n "${EXISTING}" && "${EXISTING}" != "${CONFIG}" ]]; then
        NAME="${NAME}-$(printf '%s' "${CONFIG}" | shasum | cut -c1-6)";
        LABEL="com.jamesboehmer.dotfiles.rex-devcontainer-${NAME}";
        PLIST="${AGENTDIR}/${LABEL}.plist";
    fi

    SOCKET="${SOCKDIR}/rex-devcontainer-${NAME}.sock";
    TMPFILE="$(mktemp)";
    cat > "${TMPFILE}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
      <string>${SOCAT}</string>
      <string>UNIX-LISTEN:${SOCKET},fork,mode=600,unlink-early</string>
      <string>EXEC:${DIAL}</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
      <key>PATH</key>
      <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
      <key>REX_DEVCONTAINER_CONFIG</key>
      <string>$(xmlescape "${CONFIG}")</string>
    </dict>
    <key>StandardErrorPath</key>
    <string>${LOGDIR}/rex-devcontainer-${NAME}.log</string>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
  </dict>
</plist>
EOF

    if cmp -s "${TMPFILE}" "${PLIST}" && launchctl list "${LABEL}" &>/dev/null; then
        echo "${LABEL} already loaded.  Skipping.";
        rm -f "${TMPFILE}";
    else
        echo "Creating ${PLIST} for ${CONFIG}";
        launchctl unload "${PLIST}" 2>/dev/null;
        mv "${TMPFILE}" "${PLIST}";
        launchctl load -wF "${PLIST}";
    fi
    echo "  Rex host address: unix://${SOCKET}";
done
