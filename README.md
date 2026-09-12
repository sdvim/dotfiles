# Dotfiles

## Bootstrap

Homebrew is the only manual prerequisite. On a fresh Mac:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"
brew install chezmoi
chezmoi init \
  --source "$HOME/Git/dotfiles" \
  --apply \
  --verbose \
  "https://github.com/$GITHUB_USERNAME/dotfiles.git"
```

Chezmoi stores the repository in `~/Git/dotfiles`, installs the packages in
`Brewfile`, and then imports the Git signing key from 1Password. Sign in to
1Password or enable its CLI integration before the key import runs. Homebrew
may request an administrator password while installing system-level casks such
as Karabiner-Elements.

## Keyboard Automation

- Karabiner handles low-level keyboard remaps: Caps Lock as Control, external keyboard Command/Option swapping, app-switcher suppression, and small app-scoped key remaps.

## Codex Session Watcher

`codex-sessions` lists running local Codex CLI sessions and uses `fzf` to
select one before following its tool calls. Use `codex-sessions --from-start`
to replay existing calls first. The watcher prints command and tool metadata,
not tool output. Its default log is colored and command-only; use
`--all-fields` for timestamps and diagnostic metadata or `--no-color` for
plain output.

## Local project configuration

Company instructions, repository mappings, and private tools stay outside this
public repository. Optional files in `~/.config/dotfiles-local/` extend the
managed setup on this machine:

- `AGENTS.md`: project-scoped instructions included in the Codex and Claude
  instruction files when rendered by chezmoi.
- `frontend.md`: project-specific recipes read by the frontend verification skill.
- `git.inc`: local Git configuration, including conditional repository hooks.
- `agent-hooks.json`: engine-specific hook groups, for example
  `{"codex":{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"/path/to/local-check"}]}]}}}`.

Missing files add no project configuration. The hook merge preserves unrelated
settings and handlers and replaces handlers with matching local commands on
reapplication. Removing a local command does not uninstall an already-installed
hook: remove that hook from the effective client settings too.

Apply the instruction and hook targets after changing their local inputs:

```sh
chezmoi apply --exclude=scripts --source "$HOME/Git/dotfiles" -- \
  "$HOME/.codex/AGENTS.md" "$HOME/.codex/hooks.json" \
  "$HOME/.claude/CLAUDE.md" "$HOME/.claude/settings.json" \
  "$HOME/.config/git/config"
```

Keep local scripts and their configuration outside the source tree, and back
those files up privately. Do not import rendered company instructions or hooks
with `chezmoi add`; it can copy private content back into the public source.
Chezmoi's `private_` filename prefix controls permissions, not Git visibility.
Review hook commands in the client after applying; a fresh session may be needed
for changed instructions and hooks to take effect.

## Global frontend tools for Codex

Codex's personal frontend instructions apply across repositories. The
`frontend-verify` skill follows supplied Figma mocks by default, reuses project
components and tokens, requires opening screenshots as images, and checks the
actual browser or native screen before reporting visual fidelity. Explicit user
instructions take precedence; unavailable checks must be reported. This adds
instructions, not another Stop hook.

The existing Figma MCP provides design context. `chrome-devtools` MCP launches
visible Helium with an isolated temporary profile per connection; normal Helium
tabs and logins remain separate. Playwright and Chrome DevTools windows move to
AeroSpace workspace **5** on the main monitor. Use **Ctrl+5** to visit it or
**Ctrl+Shift+5** to move a window there. The rule checks Helium's automation
debugging transport flags; regular Helium windows keep their normal placement.

`frontend-browser` wraps the pinned Playwright
CLI with Helium defaults, per-worktree/session naming, and external artifacts.
`maestro` MCP uses the installed native CLI with an explicit Java 21 environment.
The current setup targets web and iOS. Helium is compatibility-tested locally;
Chrome DevTools upstream officially supports Chrome/Chrome for Testing only.

```sh
chezmoi apply --exclude=scripts --source "$HOME/Git/dotfiles" -- \
  "$HOME/.config/mise/config.toml"
mise install java@temurin-21.0.12+8.0.LTS \
  npm:chrome-devtools-mcp@1.9.0 npm:@playwright/cli@0.1.18
# Already installed on this Mac; needed on a fresh machine:
brew install --formula mobile-dev-inc/tap/maestro
brew install --cask helium-browser
chezmoi apply --exclude=scripts --source "$HOME/Git/dotfiles" -- \
  "$HOME/.config/frontend-tools" \
  "$HOME/.local/bin/codex-helium-mcp" "$HOME/.local/bin/codex-maestro-mcp" \
  "$HOME/.local/bin/frontend-browser" "$HOME/.local/bin/frontend-doctor" \
  "$HOME/.local/bin/aerospace-agent-browser" "$HOME/.config/aerospace/aerospace.toml" \
  "$HOME/.codex/skills/frontend-verify" "$HOME/.codex/skills/playwright-cli" \
  "$HOME/.codex/AGENTS.md" "$HOME/.codex/config.toml"
frontend-doctor
```

Restart Codex and inspect `/mcp` for live connections. The config merge manages
only the `chrome-devtools` and `maestro` entries and preserves other parsed TOML
values, including hook trust and Figma authentication configuration. Authentication
credentials stay outside dotfiles. Existing Figma access is reused; on a new
machine, configure `https://mcp.figma.com/mcp` and run `codex mcp login figma`.
CLI and desktop clients use the same host MCP configuration. Skills are
discoverable on the next turn; existing sessions may need a restart for new MCPs.

```sh
frontend-browser open http://localhost:3000
frontend-browser resize 1440 900
frontend-browser screenshot
frontend-browser artifacts
frontend-browser close
```

The wrapper keys sessions and artifacts by Git worktree and `CODEX_THREAD_ID`.
For manual shell work, set `FRONTEND_SESSION=my-task`. Use a different task name
for concurrent work in the same checkout. `-s=name` overrides the browser session;
`--config file.json` on `open` overrides browser settings. Keep a consistent
`FRONTEND_SESSION` for the matching artifacts. Close only the task's own session.
Cookies are session-local; authenticate with the project's development workflow.

Evidence lives under `~/.cache/frontend-verification` (or `$XDG_CACHE_HOME`),
outside source repositories. Save DevTools screenshots/traces there; other output
paths may be rejected by its filesystem restrictions. Remove finished task
directories when their evidence is no longer needed. Use existing repository
Playwright/Maestro flows and versions for committed tests. For iOS, install a
development build and run its Metro server; a working simulator connection or
Expo launcher is not a passing product smoke test.

Playwright CLI is pinned to **0.1.18** because 0.1.19 lacks the npm provenance
present on its predecessor and mise rejected the trust downgrade. No trust
exceptions or npm backend bypasses were added. Its upstream skill is vendored
from `microsoft/playwright-cli` commit
`ca196c297169a494ee5517584883eada60dc8d0e`, with its Apache license. Update the
tool and skill together after validating a new release. The Figma workflow
loads its official design-to-code skill from the authenticated MCP resource.

Chrome DevTools usage statistics, CrUX requests, and update notifications are
disabled by the launcher. Native browser compatibility and app startup should
be rechecked after browser, Xcode, or tool upgrades.

```sh
node --test tests/frontend-tools/config.test.mjs
```

The tests cover settings preservation, merge idempotence, malformed TOML,
minimal-PATH launchers, worktree/session isolation and explicit CLI overrides.
`tests/frontend-tools/mcp_client.py` supports explicit live integration probes;
it does not run simulators or browsers as part of the default test suite.

## Removed Hammerspoon Automation

- `cmd+1` through `cmd+9` no longer focus numbered Ghostty panes. Ghostty's native behavior is restored: `cmd+1` through `cmd+8` select numbered tabs, and `cmd+9` selects the last tab.
- `cmd+r` no longer detects the focused Ghostty terminal's working directory and opens its GitHub pull request. Run `open-github-pr` from a repository directory until it is bound through tmux, herdr, or another terminal workflow.
- `edit-ghostty` and `reload-ghostty` still validate, apply, and reload the Ghostty config without Hammerspoon.

### iOS configuration inspection

From an Expo app directory, run:

```sh
frontend-doctor ios --device <UDID> --environment development --port 8081
```

Use `--project <path>` to select an app from elsewhere and `--env-var <name>`
when its Expo config reads a variable other than the default `APP_ENV`. The
helper sets that variable only for config inspection; it does not change the
running app or server. Environment names follow the project's own contract.

The doctor compares requested, generated, and installed bundle identifiers,
checks the selected simulator and Metro checkout, and reports an artifact path.
Exit codes are 0 for completed checks, 1 for a detected mismatch, and 2 for
incomplete inspection when no mismatch was detected. These checks do not prove
screen readiness, authentication, or visual correctness.

Validate the generic tools and local configuration merge with:

```sh
node --test tests/frontend-tools/*.test.mjs
```
