# AGENTS.md

## Repository Purpose

- This is the `mini-chezmoi` reboot branch for personal dotfiles.
- Treat this repository as a chezmoi source tree, not as the home directory itself.
- Keep the branch intentionally small and conservative until the reboot grows a clearer structure.

## Current Managed Surface

- `dot_zprofile` manages `~/.zprofile` and should keep Homebrew shell setup available.
- `dot_zshrc` manages `~/.zshrc` for interactive zsh setup.
- `dot_config/starship.toml` manages `~/.config/starship.toml`.
- `private_dot_codex/private_config.toml` manages `~/.codex/config.toml`.
- Project-local Codex files under `.codex/` are repository configuration, not chezmoi home targets.

## Tooling Conventions

- Prefer stock integrations for `brew`, `zsh`, `fnm`, `atuin`, and `starship`.
- Do not add custom Atuin history wrapper commands unless the user explicitly asks.
- Let Atuin own Ctrl+R, but keep up-arrow on default zsh history behavior.
- Keep Starship initialized after other shell history/runtime setup.
- Initialize `fnm` before tools that may require Node in the shell.
- Use bash for supplemental scripts when scripts are needed.

## Machine Roles

- Chezmoi machine role lives in local config data as `role = "workstation"` or `role = "server"`.
- Use `.chezmoi.toml.tmpl` to initialize or change this data; the default role is `workstation`.
- Server-only files must be gated with `.chezmoiignore.tmpl` so workstation machines do not receive them.
- The Mac mini server role is intended for a headless, always-on machine reachable by SSH.
- Privileged macOS server tuning must be installed as an explicit command and run manually with sudo. Do not hide `pmset` or `systemsetup` mutations inside normal shell startup.
- `macos-server-power status` is safe for inspection; `macos-server-power apply` changes power and SSH settings.
- For executables under `~/.local/bin`, put the `executable_` attribute on the basename, for example `dot_local/bin/executable_tool`.

## Chezmoi Rules

- Use chezmoi source naming conventions instead of raw home paths.
- Before applying, run `chezmoi diff --source "$PWD"` and check for unrelated drift.
- Apply targeted files when a full apply would overwrite unrelated live config.
- Never commit generated local state, shell history databases, Atuin sync keys, tokens, credentials, or machine-specific secrets.

## Checks

- For zsh changes, run `zsh -n dot_zshrc`.
- For Starship changes, run `STARSHIP_CONFIG="$PWD/dot_config/starship.toml" starship prompt >/dev/null`.
- For Codex custom agents, parse the TOML before finishing.
- For chezmoi changes, run `chezmoi managed --source "$PWD"` and `chezmoi diff --source "$PWD"`.
- For server-role commands, run `bash -n` and prefer `status` checks over privileged `apply` tests.
- If Atuin hooks or Codex hooks change, use official Atuin/Codex commands and note that Codex hooks may need `/hooks` trust after restart.

## Review Expectations

- Keep edits narrowly scoped to the requested dotfiles behavior.
- Prefer documenting durable repo rules in this file when the user corrects repeated assumptions.
- In reviews, prioritize shell startup order, chezmoi target mapping, secret leakage, unintended home-target changes, and whether integrations stay close to upstream behavior.
