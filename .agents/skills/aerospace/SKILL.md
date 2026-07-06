---
name: aerospace
description: Edit and validate this dotfiles repo's AeroSpace window-manager configuration. Use when Codex is asked to add, remove, explain, or troubleshoot AeroSpace keybindings, layouts, workspace rules, callbacks, or other settings in dot_config/aerospace/aerospace.toml.
---

# AeroSpace

## Scope

Edit only `dot_config/aerospace/aerospace.toml` for AeroSpace configuration changes.

Do not make broader dotfiles changes for AeroSpace unless the user explicitly asks for them.

## Docs

Use the official AeroSpace docs when command syntax or config behavior is uncertain:

- `https://raw.githubusercontent.com/nikitabobko/AeroSpace/refs/heads/main/docs/guide.adoc`
- `https://nikitabobko.github.io/AeroSpace/guide`

Use the official default config as a faster sample reference when an example is enough:

- `https://raw.githubusercontent.com/nikitabobko/AeroSpace/refs/heads/main/docs/config-examples/default-config.toml`

## Workflow

1. Read `dot_config/aerospace/aerospace.toml` and preserve its existing style.
2. Make the smallest change that satisfies the request.
3. Validate and apply the target with:

```bash
chezmoi apply --source "$PWD" -- ~/.config/aerospace/aerospace.toml && chezmoi diff --source "$PWD" -- ~/.config/aerospace/aerospace.toml && aerospace reload-config --dry-run --warnings-as-errors && aerospace reload-config
```

Report whether the command passed, whether the config was reloaded, and call out any remaining diff or warning.
