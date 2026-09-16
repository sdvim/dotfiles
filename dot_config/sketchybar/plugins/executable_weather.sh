#!/bin/sh

# Prefer the location most recently fetched by Apple's Weather app. Set
# WEATHER_LATITUDE and WEATHER_LONGITUDE to override it when needed.
WEATHER_DB="${WEATHER_DB:-$HOME/Library/Weather/weather-data.db}"
WEATHER_CACHE_FILE="${WEATHER_CACHE_FILE:-$HOME/Library/Caches/sketchybar-weather.json}"

hide_weather() {
  sketchybar --set "$NAME" drawing=off icon.drawing=off label.drawing=off
  exit 0
}

if ! command -v jq >/dev/null 2>&1; then
  hide_weather
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
  URL="https://api.open-meteo.com/v1/forecast?latitude=${LATITUDE}&longitude=${LONGITUDE}&current=temperature_2m,weather_code,is_day&temperature_unit=fahrenheit&timezone=auto"
  RESPONSE="$(curl -fsS --connect-timeout 3 --max-time 8 "$URL" 2>/dev/null || true)"
fi

if ! printf '%s' "$RESPONSE" | jq -e \
  '(.current.temperature_2m | numbers) and (.current.weather_code | numbers) and (.current.is_day | numbers)' \
  >/dev/null 2>&1; then
  if [ -r "$WEATHER_CACHE_FILE" ]; then
    RESPONSE="$(cat "$WEATHER_CACHE_FILE")"
  else
    hide_weather
  fi
else
  CACHE_DIR="$(dirname "$WEATHER_CACHE_FILE")"
  mkdir -p "$CACHE_DIR" 2>/dev/null || true
  CACHE_TEMP="${WEATHER_CACHE_FILE}.$$"
  if printf '%s\n' "$RESPONSE" > "$CACHE_TEMP" 2>/dev/null; then
    mv -f "$CACHE_TEMP" "$WEATHER_CACHE_FILE" 2>/dev/null || true
  fi
fi

TEMPERATURE="$(printf '%s' "$RESPONSE" | jq -er '.current.temperature_2m | round | tostring' 2>/dev/null)"
WEATHER_CODE="$(printf '%s' "$RESPONSE" | jq -er '.current.weather_code | floor | tostring' 2>/dev/null)"
IS_DAY="$(printf '%s' "$RESPONSE" | jq -er '.current.is_day | if . == 1 then "1" else "0" end' 2>/dev/null)"

if [ -z "$TEMPERATURE" ] || [ -z "$WEATHER_CODE" ] || [ -z "$IS_DAY" ]; then
  hide_weather
fi

if [ "$IS_DAY" = "1" ]; then
  CLEAR_ICON="􀆮"              # sun.max.fill
  PARTLY_CLOUDY_ICON="􀇕"      # cloud.sun.fill
  SHOWERS_ICON="􀇗"            # cloud.sun.rain.fill
else
  CLEAR_ICON="􀇁"              # moon.stars.fill
  PARTLY_CLOUDY_ICON="􀇛"      # cloud.moon.fill
  SHOWERS_ICON="􀇝"            # cloud.moon.rain.fill
fi

case "$WEATHER_CODE" in
  0)
    ICON="$CLEAR_ICON"
    ;;
  1|2)
    ICON="$PARTLY_CLOUDY_ICON"
    ;;
  3)
    ICON="􀇃"                # cloud.fill
    ;;
  45|48)
    ICON="􀇋"                # cloud.fog.fill
    ;;
  51|53|56)
    ICON="􀇅"                # cloud.drizzle.fill
    ;;
  55|57)
    ICON="􀇇"                # cloud.rain.fill
    ;;
  61|63)
    ICON="􀇇"                # cloud.rain.fill
    ;;
  65|66|67)
    ICON="􀇉"                # cloud.heavyrain.fill
    ;;
  71|73|75|77|85|86)
    ICON="􀇏"                # cloud.snow.fill
    ;;
  80|81)
    ICON="$SHOWERS_ICON"
    ;;
  82)
    ICON="􀇉"                # cloud.heavyrain.fill
    ;;
  95)
    ICON="􀇟"                # cloud.bolt.rain.fill
    ;;
  96|99)
    ICON="􀇍"                # cloud.hail.fill
    ;;
  *)
    ICON="􀇃"                # cloud.fill
    ;;
esac

sketchybar --set "$NAME" \
  drawing=on \
  icon.drawing=on \
  icon="$ICON" \
  label.drawing=on \
  label="${TEMPERATURE}°"
