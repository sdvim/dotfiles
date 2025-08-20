#!/bin/bash

# Claude tmux title updater with status indicators
# Usage: ~/.claude-tmux-title.sh [status] [conversation_name]

STATUS="${1:-active}"
CONVERSATION_NAME="${2:-Claude}"

# Status indicators
case "$STATUS" in
    "waiting")
        INDICATOR="⏳ "
        ;;
    "complete")
        INDICATOR="✓ "
        ;;
    "thinking")
        INDICATOR="🤔 "
        ;;
    "active"|*)
        INDICATOR="💬 "
        ;;
esac

# Update tmux window title
if [[ -n "$TMUX" ]]; then
    tmux rename-window "${INDICATOR}${CONVERSATION_NAME}"
fi