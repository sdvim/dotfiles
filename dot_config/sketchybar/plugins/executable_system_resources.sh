#!/bin/sh

TOP_INFO="$(LC_ALL=C top -l 1 -n 0 2>/dev/null)"

CPU_IDLE="$(printf '%s\n' "$TOP_INFO" | awk '/^CPU usage:/ { gsub("%", "", $7); print $7; exit }')"
if [ -n "$CPU_IDLE" ]; then
  CPU_USAGE="$(awk -v idle="$CPU_IDLE" 'BEGIN { printf "%.0f", 100 - idle }')"
else
  CPU_USAGE="--"
fi

PHYSICAL_MEMORY="$(sysctl -n hw.memsize 2>/dev/null)"
PAGE_SIZE="$(vm_stat 2>/dev/null | awk '/page size of/ { gsub(/[^0-9]/, "", $8); print $8; exit }')"
VM_STAT="$(vm_stat 2>/dev/null)"
RAM_USAGE="$(printf '%s\n' "$VM_STAT" | awk -F: \
  -v page_size="$PAGE_SIZE" \
  -v physical_memory="$PHYSICAL_MEMORY" '
  /^Pages wired down:/ {
    gsub(/[^0-9]/, "", $2)
    wired = $2
  }
  /^Anonymous pages:/ {
    gsub(/[^0-9]/, "", $2)
    anonymous = $2
  }
  /^Pages occupied by compressor:/ {
    gsub(/[^0-9]/, "", $2)
    compressed = $2
  }
  END {
    used = (wired + anonymous + compressed) * page_size
    if (used > 0 && physical_memory > 0) {
      printf "%.0f", used / physical_memory * 100
    }
  }
')"

if [ -z "$RAM_USAGE" ]; then
  RAM_USAGE="--"
fi

sketchybar --set cpu_usage icon="􀫥" label="${CPU_USAGE}%" \
           --set ram_usage icon="􀫦" label="${RAM_USAGE}%"
