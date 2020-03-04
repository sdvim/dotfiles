### Setup
```sh
git init --bare $HOME/.dotfiles
alias config='git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
config config status.showUntrackedFiles no
config remote add origin git@github.com:sdvim/dotfiles.git
```

### Load
```sh
git clone --separate-git-dir=$HOME/.dotfiles https://github.com/sdvim/dotfiles.git dotfiles-setup
rsync --recursive --verbose --exclude '.git' dotfiles-setup/ $HOME/
rm -r dotfiles-setup
```

### Usage
```sh
config status
config add .gitconfig
config commit -m 'Add gitconfig'
config push
```

via [A simpler way to manage your dotfiles](https://www.anand-iyer.com/blog/2018/a-simpler-way-to-manage-your-dotfiles.html)
