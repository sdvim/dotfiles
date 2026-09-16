#!/bin/sh

# Reads the JSON snapshots written by the iPhone/Apple Watch Shortcuts in
# HEALTH.md. The files intentionally live in iCloud Drive rather than this
# repository because they contain personal health data.

SKETCHYBAR_BIN="${SKETCHYBAR_BIN:-sketchybar}"
JQ_BIN="${JQ_BIN:-jq}"
HEALTH_FILE="${SKETCHYBAR_HEALTH_FILE:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/SketchyBar/health.json}"
WORKOUT_FILE="${SKETCHYBAR_WORKOUT_FILE:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/SketchyBar/workout.json}"

NAME="${NAME:-apple_health}"
TODAY="$(date '+%Y-%m-%d')"

hide_item() {
  "$SKETCHYBAR_BIN" --set "$NAME" drawing=off icon.drawing=off label.drawing=off
  exit 0
}

show_item() {
  "$SKETCHYBAR_BIN" --set "$NAME" drawing=on icon.drawing=on label.drawing=on icon="$1" label="$2" label.width=dynamic width=dynamic
}

format_integer() {
  awk -v value="$1" 'BEGIN {
    whole = sprintf("%.0f", value)
    grouped = ""
    while (length(whole) > 3) {
      grouped = "," substr(whole, length(whole) - 2) grouped
      whole = substr(whole, 1, length(whole) - 3)
    }
    print whole grouped
  }'
}

format_duration() {
  elapsed_seconds="$1"
  total_minutes=$((elapsed_seconds / 60))
  hours=$((total_minutes / 60))
  minutes=$((total_minutes % 60))

  if [ "$hours" -gt 0 ]; then
    printf '%dh%02dm' "$hours" "$minutes"
  else
    printf '%dm' "$minutes"
  fi
}

timestamp_to_epoch() {
  timestamp="$1"

  # Shortcuts commonly emits ISO 8601 values with fractional seconds and a
  # colon in the UTC offset. BSD date accepts neither in this input format.
  normalized="$(printf '%s' "$timestamp" \
    | sed -E 's/\.[0-9]+(Z|[+-][0-9]{2}:?[0-9]{2})$/\1/' \
    | sed -E 's/Z$/+0000/; s/([+-][0-9]{2}):([0-9]{2})$/\1\2/')"

  /bin/date -j -f '%Y-%m-%dT%H:%M:%S%z' "$normalized" '+%s' 2>/dev/null \
    || /bin/date -j -f '%Y-%m-%d %H:%M:%S %z' "$normalized" '+%s' 2>/dev/null \
    || /bin/date -j -f '%Y-%m-%dT%H:%M:%S' "$normalized" '+%s' 2>/dev/null \
    || /bin/date -j -f '%Y-%m-%d %H:%M:%S' "$normalized" '+%s' 2>/dev/null
}

command -v "$SKETCHYBAR_BIN" >/dev/null 2>&1 || exit 1
command -v "$JQ_BIN" >/dev/null 2>&1 || hide_item

health_valid=0
if [ -r "$HEALTH_FILE" ] && "$JQ_BIN" -e --arg today "$TODAY" '
  (.schema == 1)
  and (.date == $today)
  and ([.steps, .active_calories, .exercise_minutes, .stand_hours]
       | all(type == "number" and . >= 0))
' "$HEALTH_FILE" >/dev/null 2>&1; then
  health_valid=1
fi

if [ "$health_valid" -eq 1 ]; then
  steps="$("$JQ_BIN" -r '.steps | round' "$HEALTH_FILE")"
  active_calories="$("$JQ_BIN" -r '.active_calories | round' "$HEALTH_FILE")"
  exercise_minutes="$("$JQ_BIN" -r '.exercise_minutes | round' "$HEALTH_FILE")"
  stand_hours="$("$JQ_BIN" -r '.stand_hours | round' "$HEALTH_FILE")"

  health_label="$(printf '%s · %s kcal · %sm · %sh' \
    "$(format_integer "$steps")" \
    "$(format_integer "$active_calories")" \
    "$(format_integer "$exercise_minutes")" \
    "$(format_integer "$stand_hours")")"
else
  health_label='Health —'
fi

workout_duration=''
if [ -r "$WORKOUT_FILE" ] \
  && "$JQ_BIN" -e '
    (.schema == 1)
    and (.active == true)
    and ((.started_at_epoch | type) == "number" or (.started_at | type) == "string")
  ' "$WORKOUT_FILE" >/dev/null 2>&1; then
  started_at_epoch="$("$JQ_BIN" -r '
    if (.started_at_epoch | type) == "number" then
      (.started_at_epoch | floor | tostring)
    else
      empty
    end
  ' "$WORKOUT_FILE")"

  if [ -z "$started_at_epoch" ]; then
    started_at="$("$JQ_BIN" -r '.started_at // empty' "$WORKOUT_FILE")"
    started_at_epoch="$(timestamp_to_epoch "$started_at")"
  fi

  case "$started_at_epoch" in
    ''|*[!0-9]*) ;;
    *)
      now_epoch="$(date '+%s')"
      elapsed_seconds=$((now_epoch - started_at_epoch))
      # A stale state file should not make an old workout timer live forever.
      if [ "$elapsed_seconds" -ge 0 ] && [ "$elapsed_seconds" -le 86400 ]; then
        workout_duration="$(format_duration "$elapsed_seconds")"
      fi
      ;;
  esac
fi

if [ "$health_valid" -eq 0 ] && [ -z "$workout_duration" ]; then
  hide_item
fi

if [ -n "$workout_duration" ]; then
  health_label="$health_label · $workout_duration"
fi

show_item '♥' "$health_label"
