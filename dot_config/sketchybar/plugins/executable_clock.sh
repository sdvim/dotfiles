#!/bin/sh

# The $NAME variable is passed from SketchyBar and holds the name of
# the item invoking this script:
# https://felixkratz.github.io/SketchyBar/config/events#events-and-scripting

sketchybar --set "$NAME" label="$(date '+%a %b %-d %I:%M:%S %p')"
