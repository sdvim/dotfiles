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

Setting up another Mac remotely:
- Check and script over SSH (`ssh pro-16`); `op` and `gh` can't reach 1Password or the
  login keychain from SSH, so their first use runs in a Terminal on that Mac
- Run sign-ins headless over SSH and open their links in the local Chrome:
  `gh auth login` (device code), `claude auth login` (paste the code), `gcloud auth login
  --no-launch-browser`, `t3 up --headless`
- Keep Screen Sharing for macOS prompts only (Touch ID, Local Network, Accessibility,
  App Store); type no secrets into a visible Terminal, since its title bar shows them
- Update macOS before Xcode; the App Store only offers the current Xcode to the current macOS
- Atuin signs in from the Atuin item in 1Password, whose `key` field holds `atuin key`
