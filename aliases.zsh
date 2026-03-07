# aliases.zsh - general shell aliases

# Navigation
alias ..='cd ..'
alias ...='cd ../..'

# Safer file ops
alias ls='ls -G'
alias la='ls -la'
alias ll='ls -lh'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'

# Fast search (ripgrep)
if command -v rg >/dev/null 2>&1; then
  alias rgf='rg --files'
  alias rgi='rg -i'
  alias rgl='rg --line-number'
fi

# System
alias dfh='df -h'
alias duh='du -sh *'
alias ports='lsof -i -P -n | grep LISTEN'
