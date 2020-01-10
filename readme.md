# dotfiles

## Setup
```sh
git init --bare $HOME/.dotfiles
alias config='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
config config status.showUntrackedFiles no
config remote add origin git@github.com:sdvim/dotfiles.git
config status
config add .gitconfig
config commit -m 'Add gitconfig'
config push
```

## Replicate
```sh
git clone --separate-git-dir=$HOME/.dotfiles https://github.com/sdvim/dotfiles.git dotfiles-setup
rsync --recursive --verbose --exclude '.git' dotfiles-setup/ $HOME/
rm --recursive dotfiles-setup
```