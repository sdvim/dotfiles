#!/bin/bash

# Claude tmux wrapper script
# This script manages tmux window titles during Claude interactions

TITLE_SCRIPT="$HOME/.claude-tmux-title.sh"

# Function to update title with conversation name if available
update_title() {
    local status="$1"
    local conversation_name="${CLAUDE_PROJECT_NAME:-Claude}"
    
    # Extract just the name part if it's a path
    conversation_name=$(basename "$conversation_name")
    
    "$TITLE_SCRIPT" "$status" "$conversation_name"
}

# Handle different invocation modes
case "$1" in
    "start")
        update_title "active"
        ;;
    "waiting")
        update_title "waiting"
        ;;
    "complete")
        update_title "complete"
        ;;
    "thinking")
        update_title "thinking"
        ;;
    *)
        update_title "active"
        ;;
esac