#!/bin/bash

# Create a socat launchagent for each running devcontainer that exposes the Rex
# server inside it as ~/.local/state/rex-devcontainer-{name}.sock, and add that
# socket to the Rex GUI's hosts as rex-devcontainer-{name}.
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

# The Rex GUI shows only the hosts in its own RexSync.servers preference (JSON
# stored as data), not the ones `rex hosts add` writes to the server, so add
# records there.  Returns 0 if a record was added.
# Usage: addrexguihost LABEL ENDPOINT
REXDOMAIN="com.superlogical.rex";
function addrexguihost() {
    # The key has a dot in it, so escape it for plutil's key path.
    local servers="$(defaults export "${REXDOMAIN}" - 2>/dev/null | plutil -extract 'RexSync\.servers' raw -o - - 2>/dev/null | base64 -d 2>/dev/null)";
    # Start a new list only if the key is really missing, never because reading it failed.
    if [[ -z "${servers}" ]]; then
        if defaults read "${REXDOMAIN}" RexSync.servers &>/dev/null; then
            echo "  Couldn't read RexSync.servers.  Add ${2} as a Rex host manually.";
            return 1;
        fi
        servers='{"formatVersion":1,"records":[]}';
    fi
    if [[ "$(jq -r '.formatVersion' <<< "${servers}" 2>/dev/null)" != "1" ]]; then
        echo "  Unknown RexSync.servers format.  Add ${2} as a Rex host manually.";
        return 1;
    fi
    if jq -e --arg e "${2}" 'any(.records[]; .locators | index($e))' <<< "${servers}" &>/dev/null; then
        echo "  Rex GUI already has a host for ${2}.  Skipping.";
        return 1;
    fi

    # The GUI records which server it last reached at each host; fill those in the same way.
    local whoami="$(rex -S "${2}" whoami --json 2>/dev/null)";
    local record="$(jq -cn --arg id "$(uuidgen)" --arg name "${1}" --arg e "${2}" \
        --arg host "$(jq -r '.host_id // empty' <<< "${whoami}" 2>/dev/null)" \
        --arg instance "$(jq -r '.instance_id // empty' <<< "${whoami}" 2>/dev/null)" \
        '{acceptsAnonymousClients: false, icon: "globe", id: $id, locators: [$e], name: $name}
         + (if $host != "" then {lastHostID: $host} else {} end)
         + (if $instance != "" then {lastInstanceID: $instance} else {} end)')";

    local backup="${HOME}/Library/Preferences/${REXDOMAIN}.plist.rexdevcontainersbak.${TIME}";
    [[ -e "${backup}" ]] || defaults export "${REXDOMAIN}" "${backup}";
    # Escape slashes the way the GUI writes them.
    local updated="$(jq -c --argjson r "${record}" '.records += [$r]' <<< "${servers}" | sed 's#/#\\/#g')";
    echo "  Adding Rex GUI host ${1} -> ${2} (prefs backed up to ${backup})";
    defaults write "${REXDOMAIN}" RexSync.servers -data "$(printf '%s' "${updated}" | xxd -p | tr -d '\n')";
}

TIME="$(date +%Y%m%d%H%M%S)";
CHANGED="false";
while read -r CONFIG
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

    addrexguihost "rex-devcontainer-${NAME}" "unix://${SOCKET}" && CHANGED="true";
done < <(docker ps --filter label=devcontainer.config_file --format '{{.Label "devcontainer.config_file"}}' | sort -u)

[[ "${CHANGED}" == "true" ]] && echo "Restart Rex now to pick up changes";
