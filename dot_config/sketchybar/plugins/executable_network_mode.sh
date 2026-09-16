#!/bin/sh

SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-sketchybar}"
TRAFFIC_FILE="${SKETCHYBAR_NETWORK_TRAFFIC_FILE:-${TMPDIR:-/tmp}/sketchybar-network-traffic.state}"
TRAFFIC_STATE="off"
if [ -r "$TRAFFIC_FILE" ]; then
  read -r TRAFFIC_STATE < "$TRAFFIC_FILE"
fi

case "$TRAFFIC_STATE" in
  on)
    TRAFFIC_STATE="off"
    ;;
  *)
    TRAFFIC_STATE="on"
    ;;
esac

printf '%s\n' "$TRAFFIC_STATE" > "$TRAFFIC_FILE"
"$SKETCHYBAR_BIN" --trigger network_mode_change
