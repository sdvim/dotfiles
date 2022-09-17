alias dotfiles='git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME'
alias ls='ls -a'
alias df=dotfiles
alias reload='source ~/.zshrc'

eval "$(/opt/homebrew/bin/brew shellenv)"
eval "$(nodenv init -)"

ZSH_THEME="robbyrussell"
# PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"
  
plugins=(
  git
  zsh-autosuggestions
  zsh-history-substring-search
  zsh-syntax-highlighting
)

export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh