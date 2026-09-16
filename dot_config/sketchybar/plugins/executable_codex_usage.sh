#!/bin/sh

label="$({
  python3 - <<'PY'
import json
import selectors
import subprocess
import sys
import time


def send(process, message):
    process.stdin.write(json.dumps(message) + "\n")
    process.stdin.flush()


def read_response(process, selector, response_id, timeout):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ready = selector.select(max(0, deadline - time.monotonic()))
        if not ready:
            return None
        line = process.stdout.readline()
        if not line:
            return None
        try:
            message = json.loads(line)
        except json.JSONDecodeError:
            continue
        if message.get("id") == response_id:
            return message
    return None


process = subprocess.Popen(
    ["codex", "app-server", "--stdio"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    stderr=subprocess.DEVNULL,
    text=True,
    bufsize=1,
)
selector = selectors.DefaultSelector()
selector.register(process.stdout, selectors.EVENT_READ)

try:
    send(
        process,
        {
            "jsonrpc": "2.0",
            "id": 1,
            "method": "initialize",
            "params": {
                "clientInfo": {
                    "name": "sketchybar-codex-usage",
                    "version": "0.1.0",
                },
                "capabilities": {},
            },
        },
    )
    if read_response(process, selector, 1, 5) is None:
        sys.exit(1)

    send(process, {"jsonrpc": "2.0", "method": "initialized", "params": {}})
    send(
        process,
        {
            "jsonrpc": "2.0",
            "id": 2,
            "method": "account/rateLimits/read",
            "params": {},
        },
    )
    response = read_response(process, selector, 2, 10)
    if not response or "error" in response:
        sys.exit(1)

    rate_limits = response.get("result", {}).get("rateLimits", {})
    weekly_limit = None
    for key in ("primary", "secondary"):
        candidate = rate_limits.get(key)
        if isinstance(candidate, dict) and candidate.get("windowDurationMins") == 10080:
            weekly_limit = candidate
            break

    if weekly_limit is None:
        sys.exit(1)

    used_percent = weekly_limit.get("usedPercent")
    if not isinstance(used_percent, (int, float)):
        sys.exit(1)

    remaining_percent = round(100 - used_percent)
    remaining_percent = max(0, min(100, remaining_percent))
    print(f"{remaining_percent}%")
finally:
    selector.close()
    if process.poll() is None:
        process.kill()
        process.wait()
PY
} 2>/dev/null)"

if [ -z "$label" ]; then
  label="--"
fi

sketchybar --set "$NAME" label="$label"
