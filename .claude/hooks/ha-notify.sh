  #!/bin/bash
  # Claude Code PreToolUse hook that sends actionable notifications via Home Assistant
  # Requires: HA_TOKEN environment variable with a long-lived access token
  # Configure in: ~/.claude/settings.json

  set -euo pipefail

  # Check for disabled marker (toggle with /toggle-ha-notify command)
  [[ -f ~/.claude/.ha-notify-disabled ]] && echo '{}' && exit 0

  HA_URL="${HA_URL:-http://localhost:8123}"
  RESPONSE_DIR="${HOME}/Containers/homeassistant/config/claude_responses"
  TIMEOUT="${CLAUDE_HA_TIMEOUT:-120}"  # seconds to wait for response
  IDLE_THRESHOLD="${CLAUDE_HA_IDLE:-30}"  # seconds of idle before sending notification

  # Function to clear the notification
  clear_notification() {
      local req_id="$1"
      curl -s -o /dev/null \
          -X POST \
          -H "Authorization: Bearer ${HA_TOKEN}" \
          -H "Content-Type: application/json" \
          -d "{\"request_id\": \"${req_id}\"}" \
          "${HA_URL}/api/services/script/claude_clear_notification" 2>/dev/null || true
  }

  # Read input from Claude Code (JSON via stdin)
  INPUT=$(cat)

  # Parse tool info
  TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
  TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input | tostring' | head -c 200)

  # Generate unique request ID
  REQUEST_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')
  RESPONSE_FILE="${RESPONSE_DIR}/${REQUEST_ID}.response"

  # Check if HA_TOKEN is set
  if [[ -z "${HA_TOKEN:-}" ]]; then
      echo '{}' # Pass through to normal terminal prompt
      exit 0
  fi

  # Call HA script to send notification
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
      -X POST \
      -H "Authorization: Bearer ${HA_TOKEN}" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
          --arg request_id "$REQUEST_ID" \
          --arg tool_name "$TOOL_NAME" \
          --arg tool_input "$TOOL_INPUT" \
          '{request_id: $request_id, tool_name: $tool_name, tool_input: $tool_input}')" \
      "${HA_URL}/api/services/script/claude_permission_request" 2>/dev/null) || true

  # If HA call failed, pass through to terminal
  if [[ "$HTTP_CODE" != "200" ]]; then
      echo '{}' # Pass through
      exit 0
  fi

  # Wait for response file
  ELAPSED=0
  while [[ ! -f "$RESPONSE_FILE" ]] && [[ $ELAPSED -lt $TIMEOUT ]]; do
      sleep 1
      ((ELAPSED++))
  done

  # Read response
  if [[ -f "$RESPONSE_FILE" ]]; then
      RESPONSE=$(cat "$RESPONSE_FILE" | tr -d '[:space:]')
      rm -f "$RESPONSE_FILE"

      case "$RESPONSE" in
          approve)
              echo '{"decision": "approve"}'
              ;;
          always_approve)
              echo '{"decision": "approve"}'
              ;;
          deny)
              echo '{"decision": "reject", "message": "Denied via Home Assistant notification"}'
              ;;
          *)
              echo '{}' # Unknown response, pass through
              ;;
      esac
  else
      # Timeout - clear notification and pass through to terminal prompt             clear_notification "$REQUEST_ID"
      echo '{}'                                                                  fi
