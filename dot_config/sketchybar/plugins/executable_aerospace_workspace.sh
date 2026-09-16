#!/bin/sh

workspace="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2>/dev/null)}"

case "$workspace" in
  0) icon="􀃉" ;;
  1) icon="􀃋" ;;
  2) icon="􀃍" ;;
  3) icon="􀃏" ;;
  4) icon="􀃑" ;;
  5) icon="􀃓" ;;
  6) icon="􀃕" ;;
  7) icon="􀃗" ;;
  8) icon="􀃙" ;;
  9) icon="􀃛" ;;
  A|a) icon="􀂕" ;;
  B|b) icon="􀂗" ;;
  C|c) icon="􀂙" ;;
  D|d) icon="􀂛" ;;
  E|e) icon="􀂝" ;;
  F|f) icon="􀂟" ;;
  G|g) icon="􀂡" ;;
  H|h) icon="􀂣" ;;
  I|i) icon="􀂥" ;;
  J|j) icon="􀂧" ;;
  K|k) icon="􀂩" ;;
  L|l) icon="􀂫" ;;
  M|m) icon="􀂭" ;;
  N|n) icon="􀂯" ;;
  O|o) icon="􀂱" ;;
  P|p) icon="􀂳" ;;
  Q|q) icon="􀂵" ;;
  R|r) icon="􀂷" ;;
  S|s) icon="􀂹" ;;
  T|t) icon="􀂻" ;;
  U|u) icon="􀂽" ;;
  V|v) icon="􀂿" ;;
  W|w) icon="􀃁" ;;
  X|x) icon="􀃃" ;;
  Y|y) icon="􀃅" ;;
  Z|z) icon="􀃇" ;;
  *) icon="􂐀" ;;
esac

if [ -n "$workspace" ]; then
  sketchybar --set "$NAME" icon="$icon" label="$workspace"
fi
