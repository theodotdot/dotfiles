#!/usr/bin/env zsh
#
# .aliases - Set whatever shell aliases you want.
#

# better ls
alias ls='eza'
alias la='eza -a'

# find
alias fd='find . -type d -name'
alias ff='find . -type f -name'

# Editing zsh configs
alias zdot='cd ${ZDOTDIR:-~}'
alias zshrc='hx $ZDOTDIR/.zshrc'
alias sourcezsh='source $HOME/.zshenv'

# grep pretty
alias grep='grep -i --color=auto'

# curl better
alias curl='curl -L'
# gitui theme
alias gitui='gitui -t macchiato.ron'
# git
alias gfp='git fetch && git pull'
# cat and bat
alias cat='bat'
#
## python aliases
alias sourcevenv='source .venv/bin/activate'
