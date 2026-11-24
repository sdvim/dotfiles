---
name: setup-mac
description: Finish setting up another of Steve's Macs from this one, covering what `chezmoi apply` can't do over SSH (sign-ins, 1Password, Xcode, macOS prompts).
---

1. Reach it with `ssh <host>`; list what's left with `chezmoi status` there.
2. Update macOS first; the App Store only offers the current Xcode to the current macOS.
3. `op` and `gh` can't reach 1Password or the login keychain over SSH, so run them in a
   Terminal on that Mac. If `op` says "No accounts configured" while 1Password is
   unlocked, turn 1Password → Settings → Developer → Integrate with 1Password CLI off and on.
4. Run sign-ins headless over SSH and open their links in the local Chrome:
   `gh auth login` (device code), `claude auth login` (paste the code),
   `gcloud auth login --no-launch-browser`, `t3 up --headless`.
   On `work` Macs, Claude Code and gcloud use the work account; T3 Connect stays personal.
5. Keep Screen Sharing for macOS prompts only (Touch ID, Local Network, Accessibility,
   App Store). Type no secrets into a visible Terminal: its title bar shows them.
6. Atuin signs in from the Atuin item in 1Password, whose `key` field holds `atuin key`.
