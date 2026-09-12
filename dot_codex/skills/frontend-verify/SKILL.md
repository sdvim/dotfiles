---
name: frontend-verify
description: Implement and visually verify web or iOS UI changes against Figma or the requested behavior. Use for frontend implementation, layout, styling, responsive behavior, and interaction fixes; inspect the rendered surface and correct discrepancies.
---

# Implement and inspect frontend work

Use the user's supplied Figma mock as the visual target unless told otherwise.
Follow repository architecture and reuse existing components and tokens. Adjust
them within the task's scope when their styling differs from the mock. Ask about
material behavioral or accessibility conflicts; do not silently redesign.

## Read the design

For Figma work, first load the official `figma-design-to-code` guidance from the
Figma MCP resource `skill://figma/figma-design-to-code/SKILL.md` (use the server's
resource-list/read tools, or `get_figma_skill` if exposed). Then retrieve design
context for the supplied file and node. Use metadata to narrow a large frame,
not as a substitute for design context. Open its screenshot as an image. Use
the actual assets, inspect variables and available Code Connect mappings, and
adapt the reference to the project's stack. Do not publish mappings or write to
Figma without an explicit request. If no design was supplied, follow the task
and existing UI; do not require a Figma link for unrelated frontend work.

## Run the right surface

- **Web inspection:** use `chrome-devtools` MCP. It launches visible Helium in a
  fresh, isolated profile. Select the correct page ID. Inspect screenshots,
  computed styles, bounding boxes, console errors, and relevant network requests.
  Authentication in a fresh profile may need the project's test-login procedure.
- **Repeatable browser work:** load `playwright-cli` and use `frontend-browser`
  in place of its bare CLI examples. The wrapper selects Helium, a session keyed
  by worktree and `CODEX_THREAD_ID`, and an external artifact directory. For shell
  sessions, set `FRONTEND_SESSION` to a stable task name. An explicit `-s` can
  select another browser, but also set `FRONTEND_SESSION` for separate artifacts.
  `frontend-browser artifacts` prints the evidence directory.
- **iOS:** use Maestro MCP to select an available simulator and inspect its UI
  hierarchy, interact, and capture screenshots. Target the repository's actual
  development bundle and existing flows. Boot a free simulator for your task;
  do not reset or reuse another task's active device. A web preview of native
  code is not native verification.
- **Components:** use the existing Storybook when helpful, then check the
  consuming page or native screen for integration behavior. Use terminal-browser
  when a shared terminal preview is useful.

Use one controller for an active browser task. Keep committed Playwright and
Maestro tests on the repository's own toolchain. The global CLI is for interactive
work and exploration. Avoid `close-all`/`kill-all`; close only your own session.

```sh
frontend-doctor
frontend-browser open http://localhost:3000
frontend-browser resize 1440 900
frontend-browser screenshot
frontend-browser console error
frontend-browser requests
frontend-browser close
```

## See, measure, correct

Match the design frame's viewport, theme, text, and relevant state. Wait for fonts
and assets to load. Open screenshot files with the agent's image-viewing tool;
accessibility trees and saved filenames do not establish visual fidelity.
Compare typography, line wrapping, spacing, alignment, radii, colors and asset
geometry. Confirm discrepancies with computed styles and dimensions where
possible. For native screenshots, account for device scale and safe areas.

Exercise the changed interactions and relevant responsive sizes, focus/keyboard,
loading, empty, and error states. Scope these checks to the task. Fix differences
and capture fresh evidence after the last source change. Do not present a
synthetic demo, mocked service, or component-only preview as production or
end-to-end evidence. For regressions, use an assertion that detects the bug.

Save screenshots/traces under the directory from `frontend-browser artifacts`
or the repository's ignored evidence directory. Chrome DevTools can write under
`~/.cache/frontend-verification` (or `$XDG_CACHE_HOME/frontend-verification`).
Report the tested URL or bundle, viewport/device, states, actual results, source
revision plus dirty changes, artifact locations and remaining discrepancies.

Run relevant repository tests, types, lint and formatting too. If tooling or
access remains blocked after a focused recovery attempt, preserve partial
evidence and report exactly what was not verified. Do not claim parity or enter
an indefinite retry loop. User requests to skip checks take precedence.
