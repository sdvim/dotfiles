#!/bin/sh

SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-sketchybar}"
STATE_FILE="${TMPDIR:-/tmp}/sketchybar-network.state"
TRAFFIC_FILE="${SKETCHYBAR_NETWORK_TRAFFIC_FILE:-${TMPDIR:-/tmp}/sketchybar-network-traffic.state}"
SPEED_CACHE_FILE="${TMPDIR:-/tmp}/sketchybar-network-speed.state"
SPEED_LOCK_DIR="${TMPDIR:-/tmp}/sketchybar-network-speed.lock"
SPEED_REFRESH_INTERVAL=300
INTERFACE="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"

NETWORK_DOWN_ITEM="${NETWORK_DOWN_ITEM:-network_down}"
NETWORK_UP_ITEM="${NETWORK_UP_ITEM:-network_up}"
NETWORK_CONNECTION_ITEM="${NETWORK_CONNECTION_ITEM:-network_connection}"

hide_network() {
  "$SKETCHYBAR_BIN" --set "$NETWORK_DOWN_ITEM" drawing=off icon.drawing=off label.drawing=off
  "$SKETCHYBAR_BIN" --set "$NETWORK_UP_ITEM" drawing=off icon.drawing=off label.drawing=off
  "$SKETCHYBAR_BIN" --set "$NETWORK_CONNECTION_ITEM" drawing=off icon.drawing=off label.drawing=off
  exit 0
}

set_network_item() {
  item="$1"
  icon="$2"
  label="$3"

  "$SKETCHYBAR_BIN" --set "$item" \
    drawing=on \
    icon.drawing=on \
    icon="$icon" \
    label.drawing=on \
    label="$label" \
    label.width=dynamic \
    width=dynamic
}

if ! command -v "$SKETCHYBAR_BIN" >/dev/null 2>&1; then
  exit 1
fi

if [ -z "$INTERFACE" ]; then
  hide_network
fi

COUNTERS="$(
  netstat -ib 2>/dev/null | awk -v interface="$INTERFACE" \
    '$1 == interface && $3 ~ /^<Link#/ { print $7, $10; exit }'
)"

RX_BYTES="${COUNTERS%% *}"
TX_BYTES="${COUNTERS#* }"

case "$RX_BYTES" in
  ''|*[!0-9]*) hide_network ;;
esac
case "$TX_BYTES" in
  ''|*[!0-9]*) hide_network ;;
esac

NOW="$(date +%s)"
PREVIOUS_INTERFACE=""
PREVIOUS_TIME=0
PREVIOUS_RX=0
PREVIOUS_TX=0
if [ -r "$STATE_FILE" ]; then
  read -r PREVIOUS_INTERFACE PREVIOUS_TIME PREVIOUS_RX PREVIOUS_TX < "$STATE_FILE"
fi

RX_RATE=0
TX_RATE=0
if [ "$PREVIOUS_INTERFACE" = "$INTERFACE" ] \
  && [ "$PREVIOUS_TIME" -gt 0 ] 2>/dev/null \
  && [ "$PREVIOUS_RX" -ge 0 ] 2>/dev/null \
  && [ "$PREVIOUS_TX" -ge 0 ] 2>/dev/null; then
  ELAPSED=$((NOW - PREVIOUS_TIME))
  if [ "$ELAPSED" -gt 0 ] && [ "$RX_BYTES" -ge "$PREVIOUS_RX" ] && [ "$TX_BYTES" -ge "$PREVIOUS_TX" ]; then
    RX_RATE=$(( (RX_BYTES - PREVIOUS_RX) / ELAPSED ))
    TX_RATE=$(( (TX_BYTES - PREVIOUS_TX) / ELAPSED ))
  fi
fi

printf '%s %s %s %s\n' "$INTERFACE" "$NOW" "$RX_BYTES" "$TX_BYTES" > "$STATE_FILE"

format_rate() {
  awk -v bytes="$1" 'BEGIN {
    kilobytes = bytes / 1024
    if (bytes == 0) {
      printf "0 KB"
    } else if (kilobytes < 1) {
      printf "%.1f KB", kilobytes
    } else if (kilobytes < 1024) {
      printf "%.0f KB", kilobytes
    } else if (kilobytes < 1024 * 1024) {
      printf "%.0f MB", kilobytes / 1024
    } else {
      printf "%.0f GB", kilobytes / (1024 * 1024)
    }
  }'
}

format_speed() {
  awk -v bits="$1" 'BEGIN {
    megabits = bits / 1000000
    if (bits == 0) {
      printf "0 Mbps"
    } else if (megabits < 1) {
      printf "%.1f Mbps", megabits
    } else if (megabits < 1000) {
      printf "%.0f Mbps", megabits
    } else {
      printf "%.1f Gbps", megabits / 1000
    }
  }'
}

refresh_speed_in_background() {
  CACHED_INTERFACE=""
  CACHED_TIME=0
  CACHED_SPEED=""
  if [ -r "$SPEED_CACHE_FILE" ]; then
    read -r CACHED_INTERFACE CACHED_TIME CACHED_SPEED < "$SPEED_CACHE_FILE"
  fi

  REFRESH_SPEED=0
  case "$CACHED_TIME" in
    ''|*[!0-9]*)
      REFRESH_SPEED=1
      ;;
    *)
      if [ "$CACHED_INTERFACE" != "$INTERFACE" ]; then
        REFRESH_SPEED=1
      elif [ $((NOW - CACHED_TIME)) -ge "$SPEED_REFRESH_INTERVAL" ]; then
        REFRESH_SPEED=1
      fi
      ;;
  esac

  if [ "$REFRESH_SPEED" -eq 0 ] || ! mkdir "$SPEED_LOCK_DIR" 2>/dev/null; then
    return
  fi

  (
    release_speed_lock() {
      rmdir "$SPEED_LOCK_DIR" 2>/dev/null || true
    }
    trap release_speed_lock 0 HUP INT TERM

    RESULT="$(networkQuality -I "$INTERFACE" -u -c 2>/dev/null)"
    DOWNLOAD_BITS="$(printf '%s\n' "$RESULT" | awk -F ':' '/"dl_throughput"/ {
      value = $2
      gsub(/[^0-9.]/, "", value)
      print value
      exit
    }')"

    case "$DOWNLOAD_BITS" in
      ''|*[!0-9.]*)
        ;;
      *)
        SPEED="$(format_speed "$DOWNLOAD_BITS")"
        printf '%s %s %s\n' "$INTERFACE" "$(date +%s)" "$SPEED" > "$SPEED_CACHE_FILE"
        ;;
    esac
  ) >/dev/null 2>&1 &
}

TRAFFIC_ENABLED=0
TRAFFIC_STATE="off"
if [ -r "$TRAFFIC_FILE" ]; then
  read -r TRAFFIC_STATE < "$TRAFFIC_FILE"
fi
if [ "$TRAFFIC_STATE" = "on" ]; then
  TRAFFIC_ENABLED=1
fi

refresh_speed_in_background

HARDWARE_PORT="$(
  networksetup -listallhardwareports 2>/dev/null | awk -v interface="$INTERFACE" '
    /^Hardware Port:/ {
      port = $0
      sub(/^Hardware Port: /, "", port)
    }
    /^Device:/ && $2 == interface {
      print port
      exit
    }
  '
)"

case "$HARDWARE_PORT" in
  Wi-Fi|AirPort)
    ICON="􀙇"
    ;;
  *)
    ICON="􀺦"
    ;;
esac

if [ "$TRAFFIC_ENABLED" -eq 1 ]; then
  set_network_item "$NETWORK_DOWN_ITEM" '↓' "$(format_rate "$RX_RATE")"
  set_network_item "$NETWORK_UP_ITEM" '↑' "$(format_rate "$TX_RATE")"
else
  "$SKETCHYBAR_BIN" --set "$NETWORK_DOWN_ITEM" drawing=off icon.drawing=off label.drawing=off
  "$SKETCHYBAR_BIN" --set "$NETWORK_UP_ITEM" drawing=off icon.drawing=off label.drawing=off
fi

CACHED_INTERFACE=""
CACHED_TIME=0
SPEED=""
if [ -r "$SPEED_CACHE_FILE" ]; then
  read -r CACHED_INTERFACE CACHED_TIME SPEED < "$SPEED_CACHE_FILE"
fi
if [ "$CACHED_INTERFACE" != "$INTERFACE" ] || [ -z "$SPEED" ]; then
  SPEED="—"
fi

set_network_item "$NETWORK_CONNECTION_ITEM" "$ICON" "$SPEED"
