## Quick install of dotfiles and scripts

```console
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/sdvim/dotfiles/HEAD/.config/macos/install.sh)"
```

## Using dotfiles

### Setup
```console
git init --bare $HOME/.dotfiles.git
alias dotfiles='git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'
dotfiles config status.showUntrackedFiles no
dotfiles remote add origin git@github.com:sdvim/dotfiles.git
```

### Load
```console
git clone --separate-git-dir=$HOME/.dotfiles.git https://github.com/sdvim/dotfiles.git dotfiles-setup
rsync --recursive --verbose --exclude '.git' dotfiles-setup/ $HOME/
rm -r dotfiles-setup
```

### Usage example
```console
dotfiles status
dotfiles add .gitconfig
dotfiles commit -m 'Add gitconfig'
dotfiles push
```

via [A simpler way to manage your dotfiles](https://www.anand-iyer.com/blog/2018/a-simpler-way-to-manage-your-dotfiles.html)
