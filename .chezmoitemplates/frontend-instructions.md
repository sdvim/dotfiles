# Frontend implementation and visual verification

For UI work in any repository, use the `frontend-verify` skill and the repository's
own instructions. Unless the user says otherwise, a supplied Figma mock is the
visual target: fetch its design context and screenshot, reuse project components
and tokens, and make scoped adjustments to match it.

Before finishing UI changes, run the actual page or native screen, open and
inspect screenshots as images, exercise the changed interactions, and correct
visible discrepancies. Use Chrome DevTools MCP with dedicated Helium for web
inspection, `frontend-browser` for Playwright CLI workflows, and Maestro MCP for
iOS. Native claims require native inspection. A saved screenshot, DOM snapshot,
successful build, or tool availability check alone is not visual verification.

After the final edits, capture current evidence and report the tested states,
artifact paths, remaining differences and blockers. If access, startup, or tools
remain unavailable after a focused recovery attempt, report the gap and finish
the authorized work without claiming visual parity. Respect explicit requests
to skip visual checks. This workflow adds no completion gate and does not
authorize modifying Figma, publishing, or unrelated source changes.
