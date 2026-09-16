#!/bin/sh

SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-sketchybar}"
STATE_FILE="${SKETCHYBAR_DISK_STATE_FILE:-${TMPDIR:-/tmp}/sketchybar-disk-speed.state}"
LOCK_DIR="${TMPDIR:-/tmp}/sketchybar-disk-speed.lock"

DISK_READ_ITEM="${SKETCHYBAR_DISK_READ_ITEM:-disk_read}"
DISK_WRITE_ITEM="${SKETCHYBAR_DISK_WRITE_ITEM:-disk_write}"

release_lock() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

if ! command -v "$SKETCHYBAR_BIN" >/dev/null 2>&1; then
  exit 1
fi

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi
trap release_lock 0 HUP INT TERM

hide_disk() {
  "$SKETCHYBAR_BIN" --set "$DISK_READ_ITEM" drawing=off icon.drawing=off label.drawing=off
  "$SKETCHYBAR_BIN" --set "$DISK_WRITE_ITEM" drawing=off icon.drawing=off label.drawing=off
  exit 0
}

if ! command -v ioreg >/dev/null 2>&1 \
  || ! command -v plutil >/dev/null 2>&1 \
  || ! command -v jq >/dev/null 2>&1; then
  hide_disk
fi

# IOBlockStorageDriver exposes cumulative read/write byte counters. Summing
# the drivers includes the internal disk and any currently attached volumes.
IOREG_JSON="$(
  ioreg -c IOBlockStorageDriver -r -a 2>/dev/null |
    plutil -convert json -o - -- - 2>/dev/null || true
)"
COUNTERS="$(printf '%s' "$IOREG_JSON" | jq -r '
  reduce .[]?.Statistics? as $stats
    ({read: 0, write: 0};
      .read += ($stats["Bytes (Read)"] // 0) |
      .write += ($stats["Bytes (Write)"] // 0))
  | [.read, .write] | @tsv
' 2>/dev/null)"

READ_BYTES="$(printf '%s\n' "$COUNTERS" | awk '{print $1}')"
WRITE_BYTES="$(printf '%s\n' "$COUNTERS" | awk '{print $2}')"

case "$READ_BYTES" in
  ''|*[!0-9]*)
    hide_disk
    ;;
esac
case "$WRITE_BYTES" in
  ''|*[!0-9]*)
    hide_disk
    ;;
esac

NOW="$(date +%s)"
PREVIOUS_TIME=0
PREVIOUS_READ=0
PREVIOUS_WRITE=0
if [ -r "$STATE_FILE" ]; then
  read -r PREVIOUS_TIME PREVIOUS_READ PREVIOUS_WRITE < "$STATE_FILE"
fi

READ_RATE=0
WRITE_RATE=0
if [ "$PREVIOUS_TIME" -gt 0 ] 2>/dev/null \
  && [ "$PREVIOUS_READ" -ge 0 ] 2>/dev/null \
  && [ "$PREVIOUS_WRITE" -ge 0 ] 2>/dev/null; then
  ELAPSED=$((NOW - PREVIOUS_TIME))
  if [ "$ELAPSED" -gt 0 ] \
    && [ "$READ_BYTES" -ge "$PREVIOUS_READ" ] \
    && [ "$WRITE_BYTES" -ge "$PREVIOUS_WRITE" ]; then
    READ_RATE=$(( (READ_BYTES - PREVIOUS_READ) / ELAPSED ))
    WRITE_RATE=$(( (WRITE_BYTES - PREVIOUS_WRITE) / ELAPSED ))
  fi
fi

printf '%s %s %s\n' "$NOW" "$READ_BYTES" "$WRITE_BYTES" > "$STATE_FILE"

format_rate() {
  awk -v bytes="$1" 'BEGIN {
    kilobytes = bytes / 1024
    if (bytes == 0) {
      printf "0 KB/s"
    } else if (kilobytes < 1) {
      printf "%.1f KB/s", kilobytes
    } else if (kilobytes < 1024) {
      printf "%.0f KB/s", kilobytes
    } else if (kilobytes < 1024 * 1024) {
      printf "%.0f MB/s", kilobytes / 1024
    } else {
      printf "%.0f GB/s", kilobytes / (1024 * 1024)
    }
  }'
}

set_disk_item() {
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

set_disk_item "$DISK_READ_ITEM" '↓' "$(format_rate "$READ_RATE")"
set_disk_item "$DISK_WRITE_ITEM" '↑' "$(format_rate "$WRITE_RATE")"
