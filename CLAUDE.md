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
- Applying only installs packages; never remove them automatically

Workflow:
- Edit the source under `home/`, then `chezmoi diff` and `chezmoi apply`
- Run `tests/run.sh` before committing; the pre-push hook runs it too
- Add a file only when Steve asks for it

Public repository:
- No keys, tokens, passwords, licensed fonts, the tailnet name, or work material
- No private context
