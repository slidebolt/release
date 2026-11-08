#!/bin/sh
set -eu

cleanup() {
  if [ -n "${ZIGBEE_HOST_PID:-}" ] && kill -0 "$ZIGBEE_HOST_PID" 2>/dev/null; then
    kill "$ZIGBEE_HOST_PID" 2>/dev/null || true
  fi
  if [ -n "${UI_API_PID:-}" ] && kill -0 "$UI_API_PID" 2>/dev/null; then
    kill "$UI_API_PID" 2>/dev/null || true
  fi
  if [ -n "${MANAGER_PID:-}" ] && kill -0 "$MANAGER_PID" 2>/dev/null; then
    kill "$MANAGER_PID" 2>/dev/null || true
  fi
}

trap cleanup INT TERM EXIT

# Start from the image's binaries on every container start.
mkdir -p /app/.bin
cp -f /app/.bin.image/* /app/.bin/

mkdir -p /run/nginx

# Values each install needs its own copy of. When .env leaves them unset they are
# generated once and kept in the data directory, so they survive restarts and
# upgrades.
mkdir -p /app/.data
IDENTITY=/app/.data/identity.env
if [ ! -s "$IDENTITY" ]; then
  (
    umask 077
    hex() { od -An -N"$1" -tx1 /dev/urandom | tr -d ' \n'; }
    u="$(hex 16)"
    printf 'GEN_SYSTEM_UUID=%s-%s-%s-%s-%s\n' "$(echo "$u" | cut -c1-8)" "$(echo "$u" | cut -c9-12)" \
      "$(echo "$u" | cut -c13-16)" "$(echo "$u" | cut -c17-20)" "$(echo "$u" | cut -c21-32)"
    # A locally administered unicast MAC (02:...), never a real vendor's.
    printf 'GEN_SYSTEM_MAC=02:%s\n' "$(hex 5 | sed 's/../&:/g; s/:$//')"
    printf 'GEN_ZIGBEE_HOST_TOKEN=%s\n' "$(hex 32)"
  ) >"$IDENTITY.tmp" && mv "$IDENTITY.tmp" "$IDENTITY"
fi
. "$IDENTITY"
: "${SYSTEM_UUID:=$GEN_SYSTEM_UUID}" "${SYSTEM_MAC:=$GEN_SYSTEM_MAC}" "${ZIGBEE_HOST_TOKEN:=$GEN_ZIGBEE_HOST_TOKEN}"
export SYSTEM_UUID SYSTEM_MAC ZIGBEE_HOST_TOKEN

# Start zigbee-host (must be up before plugin-zigbee connects).
mkdir -p /app/.data/zigbee
: "${ZIGBEE_HOST_URL:=http://127.0.0.1:47831}"
export ZIGBEE_HOST_URL
cd /app/zigbee-host
node dist/host.js &
ZIGBEE_HOST_PID=$!

wait_zigbee_host() {
  i=0
  while [ "$i" -lt "${ZIGBEE_HOST_STARTUP_TIMEOUT_SECONDS:-30}" ]; do
    if ! kill -0 "$ZIGBEE_HOST_PID" 2>/dev/null; then
      echo "zigbee-host exited before becoming ready" >&2
      wait "$ZIGBEE_HOST_PID" || true
      return 1
    fi
    if node -e 'fetch(process.env.ZIGBEE_HOST_URL + "/v1/health", {headers: {authorization: "Bearer " + process.env.ZIGBEE_HOST_TOKEN}}).then((r) => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))'; then
      return 0
    fi
    i=$((i + 1))
    sleep 1
  done
  echo "zigbee-host did not become ready within ${ZIGBEE_HOST_STARTUP_TIMEOUT_SECONDS:-30}s" >&2
  return 1
}

wait_zigbee_host

cd /app/ui
node bootstrap-ui-db.mjs

cd /app
sb-manager --bin-dir .bin &
MANAGER_PID=$!

cd /app/ui/apps/api
node dist/index.js &
UI_API_PID=$!

exec nginx -g 'daemon off;'
