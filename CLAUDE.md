# Dotfiles

Personal dotfiles for my Macs, managed by chezmoi.

Layout:
- `.chezmoiroot` points chezmoi at `home/`, which mirrors `~`
- `home/dot_config/` installs to `~/.config/`, `home/dot_claude/` to `~/.claude/`
- Everything outside `home/` is about this repository and is never installed

Data:
- Personal values (machines, roles, git identity, keys) live only in `home/.chezmoidata.toml`
- Choose per-machine behavior by role, never by machine name
- Packages are in `home/.chezmoitemplates/Brewfile`
- Applying only installs missing packages; never upgrade or remove them automatically

Workflow:
- Edit the source under `home/`, then `chezmoi diff` and `chezmoi apply`
- Run `tests/run.sh` before committing; the pre-push hook runs it too
- Add a file only when Steve asks for it

Public repository:
- No keys, tokens, passwords, licensed fonts, or the tailnet name
- No employer or client names, work email addresses, internal hostnames or URLs,
  or workspace, organization, repository or project names
- No 1Password references outside the Private vault
- No other private context
- Tool names, public service URLs and roles like `work` are fine

To set up another Mac remotely, use the `setup-mac` skill.
