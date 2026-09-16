#!/bin/bash

# Render the active AeroSpace workspaces and their windows as a compact,
# clickable overview on SketchyBar's left side.

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

FULL_COLOR=0xffffffff
INACTIVE_WORKSPACE_COLOR=0x40ffffff
INACTIVE_WINDOW_COLOR=0x80ffffff
ITEM_PREFIX="aerospace_max_"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/sketchybar"
STATE_FILE="$STATE_DIR/aerospace_max.state"
FOCUS_STATE_FILE="$STATE_DIR/aerospace_max.focus"

save_focus_state() {
  focus_state_tmp="$FOCUS_STATE_FILE.$$"
  if printf '%s\n%s\n' "$1" "$2" > "$focus_state_tmp" 2>/dev/null; then
    mv -f "$focus_state_tmp" "$FOCUS_STATE_FILE" 2>/dev/null || :
  fi
}

save_render_state() {
  state_tmp="$STATE_FILE.$$"
  if printf '%s\n' "$1" > "$state_tmp" 2>/dev/null; then
    mv -f "$state_tmp" "$STATE_FILE" 2>/dev/null || :
  fi
  save_focus_state "$2" "$3"
}

update_cached_focus() {
  if [ -r "$STATE_FILE" ]; then
    state_tmp="$STATE_FILE.$$"
    if jq --arg focused_workspace "$1" --arg focused_window "$2" \
      '.focused_workspace = $focused_workspace | .focused_window = $focused_window' \
      "$STATE_FILE" > "$state_tmp" 2>/dev/null; then
      mv -f "$state_tmp" "$STATE_FILE" 2>/dev/null || :
    fi
  fi
  save_focus_state "$1" "$2"
}

previous_focused_workspace=""
previous_focused_window=""
if [ -r "$FOCUS_STATE_FILE" ]; then
  {
    IFS= read -r previous_focused_workspace
    IFS= read -r previous_focused_window
  } < "$FOCUS_STATE_FILE"
fi

event_focused_workspace="${FOCUSED_WORKSPACE:-}"
if [ -z "$event_focused_workspace" ] && [ -n "${FOCUSED_WINDOW_ID:-}" ]; then
  event_focused_workspace="$(aerospace list-windows --focused --format '%{workspace}' 2>/dev/null)"
fi

# Focus callbacks are much more frequent than window topology changes. When
# only the focused window changed within the same workspace, keep the existing
# item layout and update just the two affected labels in one SketchyBar call.
if [ "${SENDER:-}" = "aerospace_max_change" ] &&
  [ -n "${FOCUSED_WINDOW_ID:-}" ] &&
  [ -n "$event_focused_workspace" ] &&
  [ -r "$FOCUS_STATE_FILE" ]; then
  if [ "$previous_focused_workspace" = "$event_focused_workspace" ] &&
    [ "$previous_focused_window" != "$FOCUSED_WINDOW_ID" ]; then
    case "$previous_focused_window" in
      ''|*[!0-9]*) ;;
      *)
        case "$FOCUSED_WINDOW_ID" in
          ''|*[!0-9]*) ;;
          *)
            previous_window_item="${ITEM_PREFIX}window_${previous_focused_window}"
            focused_window_item="${ITEM_PREFIX}window_${FOCUSED_WINDOW_ID}"
            if sketchybar --set "$previous_window_item" label.color="$INACTIVE_WINDOW_COLOR" \
              --set "$focused_window_item" label.color="$FULL_COLOR" >/dev/null 2>&1; then
              update_cached_focus "$event_focused_workspace" "$FOCUSED_WINDOW_ID"
              exit 0
            fi
            ;;
        esac
        ;;
    esac
  fi
fi

focused_window="${FOCUSED_WINDOW_ID:-$(aerospace list-windows --focused --json --format '%{window-id}' 2>/dev/null | jq -r '.[0]["window-id"] // empty' 2>/dev/null)}"

windows_json="$(aerospace list-windows --all --json --format '%{workspace} %{window-id} %{app-name}' 2>/dev/null)" || exit 0
[ -n "$windows_json" ] || windows_json='[]'
printf '%s\n' "$windows_json" | jq -e . >/dev/null 2>&1 || exit 0

if [ -n "${FOCUSED_WORKSPACE:-}" ]; then
  focused_workspace="$FOCUSED_WORKSPACE"
elif [ -n "$focused_window" ]; then
  focused_workspace="$(printf '%s\n' "$windows_json" | jq -r --arg window_id "$focused_window" 'first(.[] | select((.["window-id"] | tostring) == $window_id) | .workspace) // empty' 2>/dev/null)"
  [ -n "$focused_workspace" ] || focused_workspace="$(aerospace list-workspaces --focused 2>/dev/null)"
else
  focused_workspace="$(aerospace list-workspaces --focused 2>/dev/null)"
fi

[ -n "$focused_workspace" ] || exit 0

focused_workspace_window_count="$(printf '%s\n' "$windows_json" | jq -r --arg workspace "$focused_workspace" '[.[] | select(.workspace == $workspace)] | length' 2>/dev/null)"
if [ "$focused_workspace_window_count" -gt 0 ] 2>/dev/null && [ -z "$focused_window" ]; then
  # Do not cache a partially initialized render with every window dimmed.
  exit 0
fi

state_signature="$(jq -cnS \
  --arg focused_workspace "$focused_workspace" \
  --arg focused_window "$focused_window" \
  --argjson windows "$windows_json" \
  '{focused_workspace: $focused_workspace, focused_window: $focused_window, windows: ($windows | sort_by([.workspace, (."window-id" | tostring), ."app-name"]))}' \
  2>/dev/null)" || exit 0

# A workspace change with an unchanged window topology only changes colors.
# Reuse the existing item layout and batch the recolor, including the native
# space_windows_change event if it was emitted alongside the focus callback.
case "${SENDER:-}" in
  aerospace_max_change|space_windows_change)
    if [ -r "$STATE_FILE" ] &&
      [ -n "$previous_focused_workspace" ] &&
      [ "$previous_focused_workspace" != "$focused_workspace" ]; then
      previous_workspace_window_count="$(printf '%s\n' "$windows_json" | jq -r --arg workspace "$previous_focused_workspace" '[.[] | select(.workspace == $workspace)] | length' 2>/dev/null)"
      if [ "$focused_workspace_window_count" -gt 0 ] 2>/dev/null &&
        [ "$previous_workspace_window_count" -gt 0 ] 2>/dev/null; then
        current_windows_signature="$(printf '%s\n' "$windows_json" | jq -cS 'sort_by([.workspace, (."window-id" | tostring), ."app-name"])' 2>/dev/null)"
        previous_windows_signature="$(jq -cS '.windows // []' "$STATE_FILE" 2>/dev/null)"
        if [ -n "$current_windows_signature" ] &&
          [ "$current_windows_signature" = "$previous_windows_signature" ]; then
          workspace_recolor_actions=()
          workspace_recolor_workspaces=""
          window_rows="$(printf '%s\n' "$windows_json" | jq -r 'sort_by([.workspace, (."window-id" | tostring)])[] | [.workspace, (."window-id" | tostring)] | @tsv' 2>/dev/null)"

          while IFS=$'\t' read -r workspace window_id; do
            [ -n "$workspace" ] || continue
            case " $workspace_recolor_workspaces " in
              *" $workspace "*) ;;
              *) workspace_recolor_workspaces="$workspace_recolor_workspaces $workspace" ;;
            esac
          done <<< "$window_rows"

          for workspace in $workspace_recolor_workspaces; do
            workspace_color="$INACTIVE_WORKSPACE_COLOR"
            [ "$workspace" = "$focused_workspace" ] && workspace_color="$FULL_COLOR"
            workspace_recolor_actions+=(--set "${ITEM_PREFIX}workspace_${workspace}" "icon.color=$workspace_color")
          done

          while IFS=$'\t' read -r workspace window_id; do
            [ -n "$window_id" ] || continue
            window_color="$INACTIVE_WORKSPACE_COLOR"
            if [ "$workspace" = "$focused_workspace" ]; then
              window_color="$INACTIVE_WINDOW_COLOR"
              [ "$window_id" = "$focused_window" ] && window_color="$FULL_COLOR"
            fi
            workspace_recolor_actions+=(--set "${ITEM_PREFIX}window_${window_id}" "label.color=$window_color")
          done <<< "$window_rows"

          if [ "${#workspace_recolor_actions[@]}" -gt 0 ] &&
            sketchybar "${workspace_recolor_actions[@]}" >/dev/null 2>&1; then
            save_render_state "$state_signature" "$focused_workspace" "$focused_window"
            exit 0
          fi
        fi
      fi
    fi
    ;;
esac

workspace_json="$(aerospace list-workspaces --all --json 2>/dev/null)" || workspace_json='[]'
printf '%s\n' "$workspace_json" | jq -e . >/dev/null 2>&1 || workspace_json='[]'

# Keep the configured order, then append any workspace AeroSpace reports that
# is not in the persistent list. This keeps the normal bar stable while still
# allowing temporary or newly added workspaces to appear.
workspace_order="A B 1 2 3 4 5"
live_workspaces="$(printf '%s\n' "$workspace_json" | jq -r '.[].workspace' 2>/dev/null)"
window_workspaces="$(printf '%s\n' "$windows_json" | jq -r '.[].workspace' 2>/dev/null)"
for workspace in $live_workspaces $window_workspaces "$focused_workspace"; do
  [ -n "$workspace" ] || continue
  case " $workspace_order " in
    *" $workspace "*) ;;
    *) workspace_order="$workspace_order $workspace" ;;
  esac
done

bar_json="$(sketchybar --query bar 2>/dev/null)"
existing_items="$(printf '%s\n' "$bar_json" | jq -r '.items[] | select(startswith("aerospace_max_workspace_") or startswith("aerospace_max_window_"))' 2>/dev/null)"

if [ -r "$STATE_FILE" ] && [ "$(cat "$STATE_FILE" 2>/dev/null)" = "$state_signature" ] && [ -n "$existing_items" ]; then
  exit 0
fi

desired_items=""

append_item() {
  desired_items="$desired_items $1"
}

# Build the desired item list before removing stale entries.
for workspace in $workspace_order; do
  workspace_window_count="$(printf '%s\n' "$windows_json" | jq -r --arg workspace "$workspace" '[.[] | select(.workspace == $workspace)] | length' 2>/dev/null)"
  if [ "$workspace_window_count" -gt 0 ] 2>/dev/null || [ "$workspace" = "$focused_workspace" ]; then
    append_item "${ITEM_PREFIX}workspace_${workspace}"
    workspace_rows="$(printf '%s\n' "$windows_json" | jq -r --arg workspace "$workspace" \
      '[.[] | select(.workspace == $workspace)] | sort_by(."window-id")[] | [(."window-id" | tostring), ."app-name"] | @tsv' 2>/dev/null)"
    saved_ifs=$IFS
    IFS='
'
    for row in $workspace_rows; do
      [ -n "$row" ] || continue
      window_id="$(printf '%s\n' "$row" | cut -f1)"
      [ -n "$window_id" ] || continue
      append_item "${ITEM_PREFIX}window_${window_id}"
    done
    IFS=$saved_ifs
  fi
done

is_desired() {
  case " $desired_items " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

sketchybar_actions=()
for item in $existing_items; do
  if ! is_desired "$item"; then
    sketchybar_actions+=(--remove "$item")
  fi
done

workspace_icon() {
  case "$1" in
    0) printf '%s' '􀃉' ;;
    1) printf '%s' '􀃋' ;;
    2) printf '%s' '􀃍' ;;
    3) printf '%s' '􀃏' ;;
    4) printf '%s' '􀃑' ;;
    5) printf '%s' '􀃓' ;;
    6) printf '%s' '􀃕' ;;
    7) printf '%s' '􀃗' ;;
    8) printf '%s' '􀃙' ;;
    9) printf '%s' '􀃛' ;;
    A|a) printf '%s' '􀂕' ;;
    B|b) printf '%s' '􀂗' ;;
    C|c) printf '%s' '􀂙' ;;
    D|d) printf '%s' '􀂛' ;;
    E|e) printf '%s' '􀂝' ;;
    F|f) printf '%s' '􀂟' ;;
    G|g) printf '%s' '􀂡' ;;
    H|h) printf '%s' '􀂣' ;;
    I|i) printf '%s' '􀂥' ;;
    J|j) printf '%s' '􀂧' ;;
    K|k) printf '%s' '􀂩' ;;
    L|l) printf '%s' '􀂫' ;;
    M|m) printf '%s' '􀂭' ;;
    N|n) printf '%s' '􀂯' ;;
    O|o) printf '%s' '􀂱' ;;
    P|p) printf '%s' '􀂳' ;;
    Q|q) printf '%s' '􀂵' ;;
    R|r) printf '%s' '􀂷' ;;
    S|s) printf '%s' '􀂹' ;;
    T|t) printf '%s' '􀂻' ;;
    U|u) printf '%s' '􀂽' ;;
    V|v) printf '%s' '􀂿' ;;
    W|w) printf '%s' '􀃁' ;;
    X|x) printf '%s' '􀃃' ;;
    Y|y) printf '%s' '􀃅' ;;
    Z|z) printf '%s' '􀃇' ;;
    *) printf '%s' '􂐀' ;;
  esac
}

previous_item="aerospace_max"
for workspace in $workspace_order; do
  workspace_window_count="$(printf '%s\n' "$windows_json" | jq -r --arg workspace "$workspace" '[.[] | select(.workspace == $workspace)] | length' 2>/dev/null)"
  if [ "$workspace_window_count" -gt 0 ] 2>/dev/null || [ "$workspace" = "$focused_workspace" ]; then
    workspace_item="${ITEM_PREFIX}workspace_${workspace}"
    workspace_color="$INACTIVE_WORKSPACE_COLOR"
    [ "$workspace" = "$focused_workspace" ] && workspace_color="$FULL_COLOR"

    sketchybar_actions+=(--add item "$workspace_item" left)
    sketchybar_actions+=(--set "$workspace_item" \
      drawing=on \
      width=dynamic \
      icon="$(workspace_icon "$workspace")" \
      icon.drawing=on \
      icon.width=18 \
      icon.align=center \
      icon.color="$workspace_color" \
      label.drawing=off \
      background.drawing=off \
      "click_script=aerospace workspace '$workspace'")
    sketchybar_actions+=(--move "$workspace_item" after "$previous_item")
    previous_item="$workspace_item"

    workspace_rows="$(printf '%s\n' "$windows_json" | jq -r --arg workspace "$workspace" \
      '[.[] | select(.workspace == $workspace)] | sort_by(."window-id")[] | [(."window-id" | tostring), ."app-name"] | @tsv' 2>/dev/null)"
    saved_ifs=$IFS
    IFS='
'
    for row in $workspace_rows; do
      [ -n "$row" ] || continue
      window_id="$(printf '%s\n' "$row" | cut -f1)"
      app_name="$(printf '%s\n' "$row" | cut -f2-)"
      [ -n "$window_id" ] || continue
      [ -n "$app_name" ] || app_name="Unknown"
      window_item="${ITEM_PREFIX}window_${window_id}"
      window_color="$INACTIVE_WORKSPACE_COLOR"
      if [ "$workspace" = "$focused_workspace" ]; then
        window_color="$INACTIVE_WINDOW_COLOR"
        [ "$window_id" = "$focused_window" ] && window_color="$FULL_COLOR"
      fi

      sketchybar_actions+=(--add item "$window_item" left)
      sketchybar_actions+=(--set "$window_item" \
        drawing=on \
        width=dynamic \
        icon.drawing=off \
        label.drawing=on \
        label="$app_name" \
        label.width=dynamic \
        label.color="$window_color" \
        background.drawing=off \
        "click_script=aerospace focus --window-id $window_id")
      sketchybar_actions+=(--move "$window_item" after "$previous_item")
      previous_item="$window_item"
    done
    IFS=$saved_ifs
  fi
done

sketchybar "${sketchybar_actions[@]}" >/dev/null 2>&1 || :

mkdir -p "$STATE_DIR" 2>/dev/null || :
if [ -d "$STATE_DIR" ]; then
  save_render_state "$state_signature" "$focused_workspace" "$focused_window"
fi
