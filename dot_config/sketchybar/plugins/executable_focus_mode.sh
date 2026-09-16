#!/bin/sh

DB_DIR="${FOCUS_DB_DIR:-$HOME/Library/DoNotDisturb/DB}"
ASSERTIONS="$DB_DIR/Assertions.json"
MODES="$DB_DIR/ModeConfigurations.json"

hide_focus_mode() {
  sketchybar --set "$NAME" drawing=off icon.drawing=off label.drawing=off
  exit 0
}

if [ ! -r "$ASSERTIONS" ] || [ ! -r "$MODES" ]; then
  hide_focus_mode
fi

mode_id="$(
  jq -r '
    [
      .data[0].storeAssertionRecords[]?
      | .assertionDetails.assertionDetailsModeIdentifier?
      | select(type == "string" and length > 0)
    ]
    | .[0] // empty
  ' "$ASSERTIONS" 2>/dev/null
)"

if [ -z "$mode_id" ]; then
  now_hour="$(date '+%H')"
  now_hour="${now_hour#0}"
  [ -n "$now_hour" ] || now_hour=0

  now_minute="$(date '+%M')"
  now_minute="${now_minute#0}"
  [ -n "$now_minute" ] || now_minute=0

  now_minutes=$((now_hour * 60 + now_minute))

  mode_id="$(
    jq -r --argjson now_minutes "$now_minutes" '
      .data[0].modeConfigurations
      | to_entries[]
      | . as $mode
      | ($mode.value.triggers.triggers[]? // empty)
      | select(
          .enabledSetting == 2
          and (.timePeriodStartTimeHour? != null)
          and (.timePeriodEndTimeHour? != null)
        )
      | (.timePeriodStartTimeHour * 60 + .timePeriodStartTimeMinute) as $start
      | (.timePeriodEndTimeHour * 60 + .timePeriodEndTimeMinute) as $end
      | select(
          if $start < $end then
            $now_minutes >= $start and $now_minutes < $end
          elif $start > $end then
            $now_minutes >= $start or $now_minutes < $end
          else
            false
          end
        )
      | $mode.key
    ' "$MODES" 2>/dev/null | head -n 1
  )"
fi

if [ -z "$mode_id" ]; then
  hide_focus_mode
fi

symbol="$(jq -r --arg mode_id "$mode_id" '.data[0].modeConfigurations[$mode_id].mode.symbolImageName // empty' "$MODES" 2>/dev/null)"

case "$symbol" in
  moon.fill) icon="􀆺" ;;
  bed.double.fill) icon="􀙪" ;;
  house.fill) icon="􀎟" ;;
  curlybraces) icon="􀡅" ;;
  *) icon="􀆺" ;;
esac

sketchybar --set "$NAME" \
  drawing=on \
  icon.drawing=on \
  icon="$icon" \
  label.drawing=off \
  width=28
