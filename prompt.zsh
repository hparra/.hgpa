#
# Git prompt
#

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '%F{green}+%f'
zstyle ':vcs_info:*' unstagedstr '%F{yellow}*%f'
zstyle ':vcs_info:git:*' formats       ' %F{cyan}%b%f%u%c%m'
zstyle ':vcs_info:git:*' actionformats ' %F{cyan}%b%f%F{red}|%a%f%u%c%m'

zstyle ':vcs_info:git*+set-message:*' hooks git-untracked git-aheadbehind

function +vi-git-untracked() {
  if command git status --porcelain 2>/dev/null | command grep -q '^??'; then
    hook_com[misc]+='%F{red}?%f'
  fi
}

function +vi-git-aheadbehind() {
  local ahead behind
  ahead=$(command git rev-list --count @{upstream}..HEAD 2>/dev/null)
  behind=$(command git rev-list --count HEAD..@{upstream} 2>/dev/null)
  (( ahead )) && hook_com[misc]+=" %F{green}↑${ahead}%f"
  (( behind )) && hook_com[misc]+=" %F{red}↓${behind}%f"
}

add-zsh-hook precmd vcs_info
setopt PROMPT_SUBST
PROMPT='%F{blue}%1~%f${vcs_info_msg_0_} %F{magenta}%#%f '
