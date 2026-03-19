#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${ROOT_DIR}/dist"

source "${ROOT_DIR}/versions.env"

mkdir -p "${DIST_DIR}"

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

fetch_binary "sb-manager" "${SB_MANAGER_VERSION}" "sb-manager_linux_amd64" "sb-manager"
fetch_binary "sb-messenger" "${SB_MESSENGER_VERSION}" "sb-messenger_linux_amd64" "sb-messenger"
fetch_binary "sb-storage" "${SB_STORAGE_VERSION}" "sb-storage_linux_amd64" "sb-storage"
fetch_binary "sb-api" "${SB_API_VERSION}" "sb-api_linux_amd64" "sb-api"
fetch_binary "sb-script" "${SB_SCRIPT_VERSION}" "sb-script_linux_amd64" "sb-script"
fetch_binary "sb-virtual" "${SB_VIRTUAL_VERSION}" "sb-virtual_linux_amd64" "sb-virtual"
fetch_binary "plugin-amcrest" "${PLUGIN_AMCREST_VERSION}" "plugin-amcrest_linux_amd64" "plugin-amcrest"
fetch_binary "plugin-androidtv" "${PLUGIN_ANDROIDTV_VERSION}" "plugin-androidtv_linux_amd64" "plugin-androidtv"
fetch_binary "plugin-automation" "${PLUGIN_AUTOMATION_VERSION}" "plugin-automation_linux_amd64" "plugin-automation"
fetch_binary "plugin-esphome" "${PLUGIN_ESPHOME_VERSION}" "plugin-esphome_linux_amd64" "plugin-esphome"
fetch_binary "plugin-frigate" "${PLUGIN_FRIGATE_VERSION}" "plugin-frigate_linux_amd64" "plugin-frigate"
fetch_binary "plugin-kasa" "${PLUGIN_KASA_VERSION}" "plugin-kasa_linux_amd64" "plugin-kasa"
fetch_binary "plugin-system" "${PLUGIN_SYSTEM_VERSION}" "plugin-system_linux_amd64" "plugin-system"
fetch_binary "plugin-wiz" "${PLUGIN_WIZ_VERSION}" "plugin-wiz_linux_amd64" "plugin-wiz"
fetch_binary "plugin-zigbee2mqtt" "${PLUGIN_ZIGBEE2MQTT_VERSION}" "plugin-zigbee2mqtt_linux_amd64" "plugin-zigbee2mqtt"
