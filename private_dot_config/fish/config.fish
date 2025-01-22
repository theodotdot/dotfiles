# Yazi function to jump to dir
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end

# Format man pages
set -x MANROFFOPT -c
set -x MANPAGER "sh -c 'col -bx | bat -l man -p'"

# Aliases
alias update='yay -Syu'
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'
# better ls
alias ls='exa --icons --tree --group-directories-first --level=1'
alias la='exa --icons --tree --group-directories-first --level=1 -a'

# find
alias fd='find . -type d -name'
alias ff='find . -type f -name'

# grep pretty
alias grep='grep -i --color=auto'

# curl better
alias curl='curl -L'
# gitui theme
alias gitui='gitui -t macchiato.ron'
# git
alias gfp='git fetch && git pull'
alias gaa='git add -A'
# cat and bat
alias cat='bat'
#
## python aliases
alias sourcevenv='source .venv/bin/activate'


# Loading utilities
zoxide init fish --cmd cd | source
starship init fish | source
direnv hook fish | source
