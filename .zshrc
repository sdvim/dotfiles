eval "$(nodenv init -)"

export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$HOME/.config/oh-my-zsh"
ZSH_THEME="robbyrussell"
PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
  
plugins=( git zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting )

source $ZSH/oh-my-zsh.sh

