# Dotfiles

Dotfiles for my Macs, managed by [chezmoi](https://www.chezmoi.io/). Everything under
`home/` installs to `~`.

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/sdvim/dotfiles/main/install.sh)"
```

It installs Homebrew and chezmoi, names the Mac, applies the dotfiles, and
imports the GPG signing key from 1Password. chezmoi asks once for the tailnet
domain, which stays out of this repository. Rerunning it is safe.
