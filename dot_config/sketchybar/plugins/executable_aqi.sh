#!/bin/sh

# Prefer the location most recently fetched by Apple's Weather app. Set
# WEATHER_LATITUDE and WEATHER_LONGITUDE to override it when needed.
WEATHER_DB="${WEATHER_DB:-$HOME/Library/Weather/weather-data.db}"
AQI_CACHE_FILE="${AQI_CACHE_FILE:-$HOME/Library/Caches/sketchybar-aqi.json}"

hide_aqi() {
  sketchybar --set "$NAME" drawing=off icon.drawing=off label.drawing=off
  exit 0
}

if ! command -v jq >/dev/null 2>&1; then
  hide_aqi
fi

LATITUDE="${WEATHER_LATITUDE:-}"
LONGITUDE="${WEATHER_LONGITUDE:-}"
if [ -z "$LATITUDE" ] || [ -z "$LONGITUDE" ]; then
  if command -v sqlite3 >/dev/null 2>&1 && [ -r "$WEATHER_DB" ]; then
    LOCATION="$(sqlite3 -readonly -noheader "$WEATHER_DB" \
      "SELECT printf('%.6f %.6f', latitude, longitude) FROM lastFetch ORDER BY timestamp DESC LIMIT 1;" \
      2>/dev/null)"
    LATITUDE="${LOCATION%% *}"
    LONGITUDE="${LOCATION#* }"
  fi
fi

RESPONSE=""
if [ -n "$LATITUDE" ] \
  && [ -n "$LONGITUDE" ] \
  && command -v curl >/dev/null 2>&1; then
  URL="https://air-quality-api.open-meteo.com/v1/air-quality?latitude=${LATITUDE}&longitude=${LONGITUDE}&current=us_aqi,pm2_5,pm10&timezone=auto"
  RESPONSE="$(curl -fsS --connect-timeout 3 --max-time 8 "$URL" 2>/dev/null || true)"
fi

if ! printf '%s' "$RESPONSE" | jq -e '.current.us_aqi | numbers' >/dev/null 2>&1; then
  if [ -r "$AQI_CACHE_FILE" ]; then
    RESPONSE="$(cat "$AQI_CACHE_FILE")"
  else
    hide_aqi
  fi
else
  CACHE_DIR="$(dirname "$AQI_CACHE_FILE")"
  mkdir -p "$CACHE_DIR" 2>/dev/null || true
  CACHE_TEMP="${AQI_CACHE_FILE}.$$"
  if printf '%s\n' "$RESPONSE" > "$CACHE_TEMP" 2>/dev/null; then
    mv -f "$CACHE_TEMP" "$AQI_CACHE_FILE" 2>/dev/null || true
  fi
fi

AQI="$(printf '%s' "$RESPONSE" | jq -er '.current.us_aqi | round | tostring' 2>/dev/null)"
case "$AQI" in
  ''|*[!0-9]*)
    hide_aqi
    ;;
esac

if [ "$AQI" -le 50 ]; then
  ICON="􀴾"                # aqi.low
elif [ "$AQI" -le 100 ]; then
  ICON="􀴿"                # aqi.medium
else
  ICON="􀵀"                # aqi.high
fi

sketchybar --set "$NAME" \
  drawing=on \
  icon.drawing=on \
  icon="$ICON" \
  label.drawing=on \
  label="${AQI}"
