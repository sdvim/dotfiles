if command -v codex >/dev/null 2>&1; then
  alias cx='codex --dangerously-bypass-approvals-and-sandbox'
  alias cxr='cx resume'
  alias cxd='command codex resume --last --cd "$HOME/Git/dotfiles" --dangerously-bypass-approvals-and-sandbox'

  cxh() {
    command codex --dangerously-bypass-approvals-and-sandbox help "$@" | awk '
      /^Commands:$/ {
        in_commands = 1
      }

      in_commands && seen && /^[^[:space:]].*:$/ && $0 !~ /^Commands:$/ {
        exit
      }

      in_commands {
        print
        seen = 1
      }
    '
  }
fi
