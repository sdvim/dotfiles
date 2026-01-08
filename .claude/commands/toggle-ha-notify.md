---
description: Toggle Home Assistant notifications on/off for this session
allowed-tools: Bash(touch:*), Bash(rm:*), Bash(test:*)
---

Toggle HA notifications. Creates/removes a marker file that the hook checks.

Current status: !`[ -f ~/.claude/.ha-notify-disabled ] && echo "DISABLED" || echo "ENABLED"`

If "$ARGUMENTS" is "off", create ~/.claude/.ha-notify-disabled
If "$ARGUMENTS" is "on", remove ~/.claude/.ha-notify-disabled
If no argument, just show the status above.
