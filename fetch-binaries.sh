#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
MANAGER_DIR="${ROOT_DIR}/dist-manager"

source "${ROOT_DIR}/versions.env"

rm -rf "${DIST_DIR}" "${MANAGER_DIR}"
mkdir -p "${DIST_DIR}" "${MANAGER_DIR}"

fetch_binary() {
  local repo="$1"
  local version="$2"
  local asset="$3"
  local target_name="$4"
  local out="${DIST_DIR}/${target_name}"
  local url="https://github.com/slidebolt/${repo}/releases/download/${version}/${asset}"

  echo "Fetching ${repo} ${version} -> ${target_name}"
  curl -fsSL "${url}" -o "${out}"
  chmod +x "${out}"
}

fetch_manager() {
  local version="$1"
  local out="${MANAGER_DIR}/sb-manager"
  local url="https://github.com/slidebolt/sb-manager/releases/download/${version}/sb-manager_linux_amd64"

  echo "Fetching sb-manager ${version} -> dist-manager/sb-manager"
  curl -fsSL "${url}" -o "${out}"
  chmod +x "${out}"
}

# Core Services
fetch_manager "${SB_MANAGER_VERSION}"
fetch_binary "sb-messenger" "${SB_MESSENGER_VERSION}" "sb-messenger_linux_amd64" "sb-messenger"
fetch_binary "sb-storage" "${SB_STORAGE_VERSION}" "sb-storage_linux_amd64" "sb-storage"
fetch_binary "sb-api" "${SB_API_VERSION}" "sb-api_linux_amd64" "sb-api"
fetch_binary "sb-script" "${SB_SCRIPT_VERSION}" "sb-script_linux_amd64" "sb-script"
fetch_binary "sb-virtual" "${SB_VIRTUAL_VERSION}" "sb-virtual_linux_amd64" "sb-virtual"
fetch_binary "sb-logging" "${SB_LOGGING_VERSION}" "sb-logging_linux_amd64" "sb-logging"
fetch_binary "sb-cli" "${SB_CLI_VERSION}" "sb_linux_amd64" "sb"

# Plugins
fetch_binary "plugin-alexa" "${PLUGIN_ALEXA_VERSION}" "plugin-alexa_linux_amd64" "plugin-alexa"
fetch_binary "plugin-amcrest" "${PLUGIN_AMCREST_VERSION}" "plugin-amcrest_linux_amd64" "plugin-amcrest"
fetch_binary "plugin-androidphone" "${PLUGIN_ANDROIDPHONE_VERSION}" "plugin-androidphone_linux_amd64" "plugin-androidphone"
fetch_binary "plugin-androidtv" "${PLUGIN_ANDROIDTV_VERSION}" "plugin-androidtv_linux_amd64" "plugin-androidtv"
fetch_binary "plugin-asterisk" "${PLUGIN_ASTERISK_VERSION}" "plugin-asterisk_linux_amd64" "plugin-asterisk"
fetch_binary "plugin-automation" "${PLUGIN_AUTOMATION_VERSION}" "plugin-automation_linux_amd64" "plugin-automation"
fetch_binary "plugin-clean" "${PLUGIN_CLEAN_VERSION}" "plugin-clean_linux_amd64" "plugin-clean"
fetch_binary "plugin-esphome" "${PLUGIN_ESPHOME_VERSION}" "plugin-esphome_linux_amd64" "plugin-esphome"
fetch_binary "plugin-frigate" "${PLUGIN_FRIGATE_VERSION}" "plugin-frigate_linux_amd64" "plugin-frigate"
fetch_binary "plugin-homeassistant" "${PLUGIN_HOMEASSISTANT_VERSION}" "plugin-homeassistant_linux_amd64" "plugin-homeassistant"
fetch_binary "plugin-kasa" "${PLUGIN_KASA_VERSION}" "plugin-kasa_linux_amd64" "plugin-kasa"
fetch_binary "plugin-system" "${PLUGIN_SYSTEM_VERSION}" "plugin-system_linux_amd64" "plugin-system"
fetch_binary "plugin-virtual" "${PLUGIN_VIRTUAL_VERSION}" "plugin-virtual_linux_amd64" "plugin-virtual"
fetch_binary "plugin-wiz" "${PLUGIN_WIZ_VERSION}" "plugin-wiz_linux_amd64" "plugin-wiz"
fetch_binary "plugin-zigbee2mqtt" "${PLUGIN_ZIGBEE2MQTT_VERSION}" "plugin-zigbee2mqtt_linux_amd64" "plugin-zigbee2mqtt"
