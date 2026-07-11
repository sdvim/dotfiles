---
name: zsh
description: Edit and validate this dotfiles repo's zsh configuration. Use when Codex is asked to add, remove, explain, or troubleshoot shell startup, PATH/fpath, history, completions, autosuggestions, ZLE keybindings, plugin initialization, aliases, functions, or entries in dot_zprofile, dot_zshrc, or dot_config/zsh/*.zsh.
---

# Zsh

## Scope

Edit only `dot_zprofile`, `dot_zshrc`, and files under `dot_config/zsh/` for zsh configuration changes.

Do not change Brewfile, Ghostty, mise, AeroSpace, or broader dotfiles config for zsh work unless the user explicitly asks for it.

## Docs

Use official zsh docs when startup order, options, ZLE, or completion behavior is uncertain:

- `https://zsh.sourceforge.io/Doc/Release/Files.html`
- `https://zsh.sourceforge.io/Doc/Release/Options.html`
- `https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html`
- `https://zsh.sourceforge.io/Doc/Release/Completion-System.html`

Use upstream plugin docs or local Homebrew plugin source when plugin behavior is uncertain:

- `https://github.com/zsh-users/zsh-autosuggestions`
- `https://github.com/zsh-users/zsh-syntax-highlighting`
- `/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh`
- `/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh`

## Workflow

1. Read the relevant zsh source files and preserve their existing style.
2. Keep login-shell setup in `dot_zprofile`, interactive startup and plugin wiring in `dot_zshrc`, and Git shell helpers in the existing `dot_config/zsh/aliases/git.zsh` / `dot_config/zsh/functions/git.zsh` split.
3. Make the smallest change that satisfies the request. Avoid permanent migration cleanup or defensive removal code unless the user explicitly asks for it.
4. Validate syntax with:

```bash
zsh -n dot_zprofile && zsh -n dot_zshrc && for file in dot_config/zsh/**/*.zsh(.N); do zsh -n "$file" || exit; done
```

5. Apply and validate the managed targets with:

```bash
chezmoi apply --parent-dirs --source "$PWD" -- ~/.zprofile ~/.zshrc ~/.config/zsh && chezmoi diff --source "$PWD" -- ~/.zprofile ~/.zshrc ~/.config/zsh
```

For PATH or command availability changes, verify in a fresh shell:

```bash
zsh -ic 'command -v <tool>'
```

For keybinding, autosuggestion, completion, or ZLE changes, inspect the live widgets and keymaps before and after the change:

```zsh
bindkey -M main '^I'
bindkey -M emacs '^I'
bindkey -M viins '^I'
print -r -- "widget=${widgets[<widget-name>]}"
typeset -pm 'ZSH_AUTOSUGGEST*' 2>/dev/null
```

If a custom widget must see the current autosuggestion text, make sure `zsh-autosuggestions` does not wrap it as a generic modify widget on the next `precmd`; add the widget name to `ZSH_AUTOSUGGEST_IGNORE_WIDGETS` when needed.

Report whether syntax validation passed, whether chezmoi applied cleanly, whether the target diff is clean, and any shell command or widget probe used to verify the behavior.
