#!/bin/bash

which starship &>/dev/null || { echo "No Starship.  Skipping starship config." && exit 0; }

export STARSHIP_CONFIG="${HOME}/.config/starship.toml";
echo "Configuring ${STARSHIP_CONFIG}";

mkdir -p "${HOME}/.config";
touch "${STARSHIP_CONFIG}";

starship config command_timeout 600
starship config directory.truncation_length 100
starship config directory.truncate_to_repo false
starship config container.disabled true
starship config nodejs.format "via [🤖 \$version](bold green) "
starship config gcloud.detect_env_vars "[\"STARSHIP_GCLOUD\"]"
starship config python.detect_extensions "[]"
starship config battery.full_symbol "🔋 "
starship config battery.charging_symbol "⚡️ "
starship config battery.discharging_symbol "💦 "
