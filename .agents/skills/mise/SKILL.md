---
name: mise
description: Edit and validate this dotfiles repo's mise configuration. Use when Codex is asked to add, remove, install, explain, or troubleshoot mise tools, npm-backed global packages, tasks, settings, or other entries in dot_config/mise/config.toml.
---

# Mise

## Scope

Edit only `dot_config/mise/config.toml` for mise configuration changes.

Do not make broader dotfiles changes for mise unless the user explicitly asks for them.

## Docs

Use the official mise docs when command syntax, config behavior, or backend syntax is uncertain:

- `https://mise.jdx.dev/configuration.html`
- `https://mise.jdx.dev/dev-tools/`
- `https://mise.jdx.dev/dev-tools/backends/npm.html`
- `https://mise.jdx.dev/cli/use.html`
- `https://mise.jdx.dev/cli/install.html`
- `https://mise.jdx.dev/cli/ls.html`
- `https://mise.jdx.dev/cli/doctor.html`

Use the official walkthrough as a faster sample reference when an example is enough:

- `https://mise.jdx.dev/walkthrough.html`

## Workflow

1. Read `dot_config/mise/config.toml` and preserve its existing TOML style.
2. Resolve tool names with `mise registry` or `mise tool` before adding unfamiliar tools.
3. Prefer direct source edits over `mise use -g` because chezmoi owns the durable config file.
4. Make the smallest change that satisfies the request.
5. Apply and validate the target with:

```bash
chezmoi apply --source "$PWD" -- ~/.config/mise/config.toml && chezmoi diff --source "$PWD" -- ~/.config/mise/config.toml && mise config ls --tracked-configs && mise ls -g && mise doctor
```

For a newly added or changed tool, also install and verify only that tool when practical:

```bash
mise install <tool> && mise which <tool> && mise exec <tool> -- <tool> --version
```

Report whether the commands passed, whether any tool was installed, and call out any remaining diff or warning.
