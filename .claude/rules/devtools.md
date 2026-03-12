## Dev Environment Scripts

Local dev tooling scripts are available at `~/.local/share/claude-devtools/`.
Use these to start/monitor dev servers and read browser console/network output.

- `bash ~/.local/share/claude-devtools/tmux/dev-server.sh <package>` — start dev server in tmux window
- `bash ~/.local/share/claude-devtools/tmux/dev-status.sh <package> [lines]` — read dev server output
- `bash ~/.local/share/claude-devtools/tmux/dev-stop.sh <package>` — stop dev server
- `node ~/.local/share/claude-devtools/chrome/console-logs.mjs [--filter=error] [--limit=N]` — browser console
- `node ~/.local/share/claude-devtools/chrome/network-requests.mjs [--url-match=pattern]` — network requests
- `bash ~/.local/share/claude-devtools/chrome/browser-launch.sh` — launch browser with remote debugging

The browser must be running with `--remote-debugging-port=9222` for the chrome scripts to work.
