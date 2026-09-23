#!/bin/sh

SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-sketchybar}"
ITEM_PREFIX="bluetooth_device_"
DISK_WRITE_ITEM="${SKETCHYBAR_DISK_WRITE_ITEM:-disk_write}"
DISK_READ_ITEM="${SKETCHYBAR_DISK_READ_ITEM:-disk_read}"
LOCK_DIR="${TMPDIR:-/tmp}/sketchybar-bluetooth-devices.lock"

# Set BLUETOOTH_HIDE_DEVICE_NAME=0 to show names again. The default is to show
# only device icons and battery levels.
HIDE_DEVICE_NAME="${BLUETOOTH_HIDE_DEVICE_NAME:-1}"
case "$(printf '%s' "$HIDE_DEVICE_NAME" | LC_ALL=C tr '[:upper:]' '[:lower:]')" in
  1|true|yes|on)
    HIDE_DEVICE_NAME=1
    ;;
  *)
    HIDE_DEVICE_NAME=0
    ;;
esac

# SF Symbols: airpod.left, airpod.right, and airpods.chargingcase.
AIRPOD_LEFT_ICON='􀲌'
AIRPOD_RIGHT_ICON='􀲋'
AIRPODS_CASE_ICON='􀹧'

release_lock() {
  rmdir "$LOCK_DIR" 2>/dev/null || true
}

if ! mkdir "$LOCK_DIR" 2>/dev/null; then
  exit 0
fi
trap release_lock 0 HUP INT TERM

remove_device_items() {
  "$SKETCHYBAR_BIN" --query bar 2>/dev/null |
    jq -r --arg prefix "$ITEM_PREFIX" \
      '.items[]? | select(startswith($prefix))' 2>/dev/null |
    while IFS= read -r item; do
      [ -n "$item" ] && "$SKETCHYBAR_BIN" --remove "$item"
    done
}

hide_devices() {
  remove_device_items
  "$SKETCHYBAR_BIN" --set "$NAME" \
    drawing=off \
    icon.drawing=off \
    label.drawing=off
  exit 0
}

if ! command -v jq >/dev/null 2>&1 \
  || ! command -v system_profiler >/dev/null 2>&1; then
  hide_devices
fi

PROFILE="$(system_profiler SPBluetoothDataType -json 2>/dev/null || true)"
DEVICES="$(printf '%s' "$PROFILE" | jq -r '
  .SPBluetoothDataType[]?.device_connected[]? | to_entries[] |
  [
    .key,
    (.value.device_address // "-"),
    (.value.device_minorType // "-"),
    (.value.device_vendorID // "-"),
    (.value.device_productID // "-"),
    (.value.device_batteryLevelMain // "-"),
    (.value.device_batteryLevelLeft // "-"),
    (.value.device_batteryLevelRight // "-"),
    (.value.device_batteryLevelCase // "-")
  ] | map(tostring) | @tsv
' 2>/dev/null)"

if [ -z "$DEVICES" ]; then
  hide_devices
fi

# system_profiler reports battery levels for some devices, such as AirPods.
# pmset also exposes accessory power sources and fills in levels for devices
# such as Logitech HID accessories that do not include them in that profile.
ACCESSORY_BATTERIES="$(
  LC_ALL=C pmset -g accps 2>/dev/null |
    LC_ALL=C awk '
      /^[[:space:]]*-/ {
        source = $0
        sub(/^[[:space:]]*-[[:space:]]*/, "", source)
        sub(/[[:space:]]+\(id=[0-9]+\).*/, "", source)
        battery = $0
        sub(/^.*\)[[:space:]]*/, "", battery)
        sub(/%.*/, "", battery)
        if (battery ~ /^[0-9]+$/) print source "\t" battery
      }
    '
)"

normalize() {
  printf '%s' "$1" |
    LC_ALL=C tr '[:upper:]' '[:lower:]' |
    LC_ALL=C tr -cd '[:alnum:]'
}

accessory_battery_for() {
  target="$(normalize "$1")"
  [ -n "$target" ] || return 0

  printf '%s\n' "$ACCESSORY_BATTERIES" |
    LC_ALL=C awk -F '\t' -v target="$target" '
      function normalize(value) {
        gsub(/[^[:alnum:]]/, "", value)
        return tolower(value)
      }
      {
        source = normalize($1)
        if (source == target) {
          print $2
          found = 1
          exit
        }
        if (!found && source !~ /case/ && index(source, target) > 0) {
          fallback = $2
        }
        if (!found && source !~ /case/ && index(target, source) > 0) {
          fallback = $2
        }
      }
      END {
        if (!found && fallback != "") print fallback
      }
    '
}

percent_value() {
  printf '%s' "$1" | sed -n 's/[^0-9]*\([0-9][0-9]*\)%.*/\1/p'
}

device_kind_for() {
  name_key="$(normalize "$1")"
  type_key="$(normalize "$2")"
  vendor_key="$(normalize "$3")"

  case "$name_key" in
    *airpod*)
      printf '%s' airpods
      return
      ;;
  esac

  case "$vendor_key:$type_key" in
    0x004c*:*headphone*|0x004c*:*headset*|0x004c*:*earbud*|0x004c*:*earphone*)
      printf '%s' airpods
      return
      ;;
  esac

  case "$type_key:$name_key" in
    *keyboard*)
      printf '%s' keyboard
      ;;
    *mouse*|*trackpad*)
      printf '%s' mouse
      ;;
    *headphone*|*headset*|*earbud*|*earphone*)
      printf '%s' headphones
      ;;
    *)
      printf '%s' generic
      ;;
  esac
}

device_icon_for() {
  case "$(device_kind_for "$1" "$2" "$3")" in
    headphones)
      # headphones
      printf '%s' '􀑈'
      ;;
    mouse)
      # computermouse
      printf '%s' '􀺣'
      ;;
    keyboard)
      # keyboard
      printf '%s' '􀇳'
      ;;
    *)
      # antenna.radiowaves.left.and.right
      printf '%s' '􀖀'
      ;;
  esac
}

mark_desired_item() {
  if [ -n "$DESIRED_ITEMS" ]; then
    DESIRED_ITEMS="${DESIRED_ITEMS}
$1"
  else
    DESIRED_ITEMS="$1"
  fi
}

set_device_item() {
  item="$1"
  icon="$2"
  label="$3"
  icon_padding_right="$4"

  if ! printf '%s\n' "$EXISTING_ITEMS" | grep -Fqx "$item"; then
    "$SKETCHYBAR_BIN" --add item "$item" right
  fi

  if [ -n "$icon" ]; then
    "$SKETCHYBAR_BIN" --set "$item" \
      drawing=on \
      icon.drawing=on \
      icon="$icon" \
      icon.font="SF Pro:Medium:15.0" \
      icon.width=18 \
      icon.align=center \
      icon.padding_left=4 \
      icon.padding_right="$icon_padding_right" \
      label.drawing=on \
      label.width=dynamic \
      label.font.features=tnum \
      label="$label" \
      width=dynamic
  else
    "$SKETCHYBAR_BIN" --set "$item" \
      drawing=on \
      icon.drawing=off \
      icon.width=0 \
      label.drawing=on \
      label.width=dynamic \
      label.font.features=tnum \
      label="$label" \
      width=dynamic
  fi
}

move_disk_items_after_devices() {
  last_device_item="$(printf '%s\n' "$DESIRED_ITEMS" | tail -n 1)"
  [ -n "$last_device_item" ] || return 0

  # Right-positioned items render in reverse declaration order. Keep the
  # disk indicators after every dynamic Bluetooth item in that order so they
  # render before the Bluetooth devices on the left side of the right group.
  "$SKETCHYBAR_BIN" --move "$DISK_WRITE_ITEM" after "$last_device_item"
  "$SKETCHYBAR_BIN" --move "$DISK_READ_ITEM" after "$DISK_WRITE_ITEM"
}

TAB="$(printf '\t')"
DEVICE_INDEX=0
DESIRED_ITEMS=""
EXISTING_ITEMS="$(
  "$SKETCHYBAR_BIN" --query bar 2>/dev/null |
    jq -r --arg prefix "$ITEM_PREFIX" \
      '.items[]? | select(startswith($prefix))' 2>/dev/null
)"
while IFS="$TAB" read -r DEVICE_NAME DEVICE_ADDRESS MINOR_TYPE VENDOR_ID PRODUCT_ID MAIN_BATTERY LEFT_BATTERY RIGHT_BATTERY CASE_BATTERY; do
  [ -n "$DEVICE_NAME" ] || continue

  DEVICE_INDEX=$((DEVICE_INDEX + 1))
  SAFE_ADDRESS="$(printf '%s' "$DEVICE_ADDRESS" | LC_ALL=C tr -cd '[:alnum:]')"
  if [ -n "$SAFE_ADDRESS" ]; then
    ITEM_NAME="${ITEM_PREFIX}${SAFE_ADDRESS}"
  else
    SAFE_NAME="$(normalize "$DEVICE_NAME")"
    ITEM_NAME="${ITEM_PREFIX}${SAFE_NAME:-unknown}_${DEVICE_INDEX}"
  fi

  DISPLAY_NAME="$(printf '%s' "$DEVICE_NAME" | tr '\r\n\t' '   ')"
  [ -n "$DISPLAY_NAME" ] || DISPLAY_NAME="Bluetooth device"

  MAIN_PERCENT="$(percent_value "$MAIN_BATTERY")"
  LEFT_PERCENT="$(percent_value "$LEFT_BATTERY")"
  RIGHT_PERCENT="$(percent_value "$RIGHT_BATTERY")"
  CASE_PERCENT="$(percent_value "$CASE_BATTERY")"

  DEVICE_KIND="$(device_kind_for "$DEVICE_NAME" "$MINOR_TYPE" "$VENDOR_ID")"
  if [ "$DEVICE_KIND" = airpods ]; then
    LEFT_LABEL=""
    RIGHT_LABEL=""
    CASE_LABEL=""
    [ -n "$LEFT_PERCENT" ] && LEFT_LABEL="${LEFT_PERCENT}%"
    [ -n "$RIGHT_PERCENT" ] && RIGHT_LABEL="${RIGHT_PERCENT}%"
    [ -n "$CASE_PERCENT" ] && CASE_LABEL="${CASE_PERCENT}%"

    if [ "$HIDE_DEVICE_NAME" -eq 0 ]; then
      if [ -n "$LEFT_LABEL" ]; then
        LEFT_LABEL="$DISPLAY_NAME $LEFT_LABEL"
      elif [ -n "$RIGHT_LABEL" ]; then
        RIGHT_LABEL="$DISPLAY_NAME $RIGHT_LABEL"
      elif [ -n "$CASE_LABEL" ]; then
        CASE_LABEL="$DISPLAY_NAME $CASE_LABEL"
      fi
    fi

    AIRPOD_COMPONENT_COUNT=0
    # Right-positioned items are laid out in reverse declaration order. Add
    # case, right, then left so the bar reads left, right, case.
    if [ -n "$CASE_LABEL" ]; then
      set_device_item "${ITEM_NAME}_case" "$AIRPODS_CASE_ICON" "$CASE_LABEL" 6
      mark_desired_item "${ITEM_NAME}_case"
      AIRPOD_COMPONENT_COUNT=$((AIRPOD_COMPONENT_COUNT + 1))
    fi
    if [ -n "$RIGHT_LABEL" ]; then
      set_device_item "${ITEM_NAME}_right" "$AIRPOD_RIGHT_ICON" "$RIGHT_LABEL" 6
      mark_desired_item "${ITEM_NAME}_right"
      AIRPOD_COMPONENT_COUNT=$((AIRPOD_COMPONENT_COUNT + 1))
    fi
    if [ -n "$LEFT_LABEL" ]; then
      set_device_item "${ITEM_NAME}_left" "$AIRPOD_LEFT_ICON" "$LEFT_LABEL" 6
      mark_desired_item "${ITEM_NAME}_left"
      AIRPOD_COMPONENT_COUNT=$((AIRPOD_COMPONENT_COUNT + 1))
    fi

    if [ "$AIRPOD_COMPONENT_COUNT" -eq 0 ]; then
      AIRPOD_FALLBACK_LABEL="—"
      if [ -n "$MAIN_PERCENT" ]; then
        AIRPOD_FALLBACK_LABEL="${MAIN_PERCENT}%"
      fi
      if [ "$HIDE_DEVICE_NAME" -eq 0 ]; then
        AIRPOD_FALLBACK_LABEL="$DISPLAY_NAME $AIRPOD_FALLBACK_LABEL"
      fi
      set_device_item "$ITEM_NAME" "" "$AIRPOD_FALLBACK_LABEL" 0
      mark_desired_item "$ITEM_NAME"
    fi
  else
    if [ -z "$MAIN_PERCENT" ]; then
      MAIN_PERCENT="$(accessory_battery_for "$DEVICE_NAME")"
    fi
    if [ -n "$MAIN_PERCENT" ]; then
      BATTERY_LABEL="${MAIN_PERCENT}%"
    else
      BATTERY_LABEL="—"
    fi

    if [ "$HIDE_DEVICE_NAME" -eq 1 ]; then
      DEVICE_LABEL="$BATTERY_LABEL"
    else
      DEVICE_LABEL="${DISPLAY_NAME} ${BATTERY_LABEL}"
    fi

    ICON="$(device_icon_for "$DEVICE_NAME" "$MINOR_TYPE" "$VENDOR_ID")"
    set_device_item "$ITEM_NAME" "$ICON" "$DEVICE_LABEL" 4
    mark_desired_item "$ITEM_NAME"
  fi
done <<EOF
$DEVICES
EOF

printf '%s\n' "$EXISTING_ITEMS" |
  while IFS= read -r item; do
    [ -n "$item" ] || continue
    if ! printf '%s\n' "$DESIRED_ITEMS" | grep -Fqx "$item"; then
      "$SKETCHYBAR_BIN" --remove "$item"
    fi
  done

if [ "$DEVICE_INDEX" -gt 0 ]; then
  move_disk_items_after_devices
  "$SKETCHYBAR_BIN" --set "$NAME" drawing=off icon.drawing=off label.drawing=off
else
  hide_devices
fi
