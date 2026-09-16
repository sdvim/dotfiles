#!/bin/sh

BATTERY_INFO="$(pmset -g batt)"
PERCENTAGE="$(printf '%s\n' "$BATTERY_INFO" | grep -Eo '[0-9]+%' | head -n 1 | cut -d% -f1)"

if [ -z "$PERCENTAGE" ]; then
  exit 0
fi

# Show the plug whenever the Mac is drawing from external power, including
# when optimized charging is holding the battery at its current level.
if printf '%s\n' "$BATTERY_INFO" | grep -qE "Now drawing from 'AC Power'|; charging([;[:space:]]|$)"; then
  ICON="􀢋"
else
  ICON="􀛨"
fi

sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%"
