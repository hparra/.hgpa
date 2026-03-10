#
# Git prompt
#

autoload -Uz vcs_info
autoload -Uz add-zsh-hook
zmodload zsh/datetime 2>/dev/null
zstyle ':vcs_info:*' enable git

# Script-level defaults. Change these to adjust behavior globally.
# Only declare when unset so re-sourcing (e.g. . ~/.zshrc) doesn't hit read-only.
(( ${+HGPA_DEFAULT_SHOW_DIRTY} )) || typeset -gr HGPA_DEFAULT_SHOW_DIRTY=1
(( ${+HGPA_DEFAULT_SHOW_AHEADBEHIND} )) || typeset -gr HGPA_DEFAULT_SHOW_AHEADBEHIND=1
(( ${+HGPA_DEFAULT_SHOW_WORKTREE} )) || typeset -gr HGPA_DEFAULT_SHOW_WORKTREE=1
(( ${+HGPA_DEFAULT_GIT_REFRESH_MS} )) || typeset -gr HGPA_DEFAULT_GIT_REFRESH_MS=1000

typeset -g HGPA_LAST_SHOW_DIRTY
HGPA_LAST_SHOW_DIRTY=''
typeset -g HGPA_LAST_SHOW_AHEADBEHIND
HGPA_LAST_SHOW_AHEADBEHIND=''
typeset -g HGPA_LAST_SHOW_WORKTREE
HGPA_LAST_SHOW_WORKTREE=''
typeset -g HGPA_VCS_CONFIG_CHANGED
HGPA_VCS_CONFIG_CHANGED=0
typeset -gi HGPA_LAST_VCS_REFRESH_MS
HGPA_LAST_VCS_REFRESH_MS=0
typeset -gA HGPA_AB_HEAD_BY_REPO
typeset -gA HGPA_AB_UPSTREAM_BY_REPO
typeset -gA HGPA_AB_MISC_BY_REPO

zstyle ':vcs_info:git:*' formats       ' %F{cyan}%b%f%u%c%m'
zstyle ':vcs_info:git:*' actionformats ' %F{cyan}%b%f%F{red}|%a%f%u%c%m'

function hgpa-configure-vcs-info() {
  local show_dirty="${HGPA_SHOW_DIRTY:-$HGPA_DEFAULT_SHOW_DIRTY}"
  local show_aheadbehind="${HGPA_SHOW_AHEADBEHIND:-$HGPA_DEFAULT_SHOW_AHEADBEHIND}"
  local show_worktree="${HGPA_SHOW_WORKTREE:-$HGPA_DEFAULT_SHOW_WORKTREE}"
  HGPA_VCS_CONFIG_CHANGED=0
  if [[ "$show_dirty" == "$HGPA_LAST_SHOW_DIRTY" && "$show_aheadbehind" == "$HGPA_LAST_SHOW_AHEADBEHIND" && "$show_worktree" == "$HGPA_LAST_SHOW_WORKTREE" ]]; then
    return 0
  fi
  HGPA_LAST_SHOW_DIRTY="$show_dirty"
  HGPA_LAST_SHOW_AHEADBEHIND="$show_aheadbehind"
  HGPA_LAST_SHOW_WORKTREE="$show_worktree"
  HGPA_VCS_CONFIG_CHANGED=1

  local -a hooks
  hooks=()
  [[ "$show_aheadbehind" == "1" ]] && hooks=(git-aheadbehind "${hooks[@]}")
  [[ "$show_worktree" == "1" ]] && hooks=(git-worktree "${hooks[@]}")

  if [[ "$show_dirty" == "1" ]]; then
    zstyle ':vcs_info:*' check-for-changes true
    zstyle ':vcs_info:*' stagedstr '%F{green}+%f'
    zstyle ':vcs_info:*' unstagedstr '%F{yellow}*%f'
    hooks=(git-untracked "${hooks[@]}")
  else
    zstyle ':vcs_info:*' check-for-changes false
    zstyle ':vcs_info:*' stagedstr ''
    zstyle ':vcs_info:*' unstagedstr ''
  fi

  zstyle ':vcs_info:git*+set-message:*' hooks "${hooks[@]}"
}

function +vi-git-untracked() {
  [[ "${HGPA_SHOW_DIRTY:-$HGPA_DEFAULT_SHOW_DIRTY}" == "1" ]] || return 0
  local has_untracked
  has_untracked=$(
    command git ls-files --others --exclude-standard --directory --no-empty-directory 2>/dev/null |
      command head -n 1
  ) || return 0
  if [[ -n "$has_untracked" ]]; then
    hook_com[misc]+='%F{red}?%f'
  fi
}

function +vi-git-aheadbehind() {
  [[ "${HGPA_SHOW_AHEADBEHIND:-$HGPA_DEFAULT_SHOW_AHEADBEHIND}" == "1" ]] || return 0
  local repo_refs repo head upstream
  repo_refs=$(command git rev-parse --show-toplevel --verify HEAD --verify @{upstream} 2>/dev/null) || return 0
  repo=${repo_refs%%$'\n'*}
  repo_refs=${repo_refs#*$'\n'}
  head=${repo_refs%%$'\n'*}
  upstream=${repo_refs#*$'\n'}

  if [[ "${HGPA_AB_HEAD_BY_REPO[$repo]-}" == "$head" && "${HGPA_AB_UPSTREAM_BY_REPO[$repo]-}" == "$upstream" ]]; then
    hook_com[misc]+="${HGPA_AB_MISC_BY_REPO[$repo]-}"
    return 0
  fi

  local ahead behind
  read -r behind ahead <<<"$(command git rev-list --left-right --count @{upstream}...HEAD 2>/dev/null)" || return 0
  local misc=''
  (( ahead )) && misc+=" %F{green}↑${ahead}%f"
  (( behind )) && misc+=" %F{red}↓${behind}%f"
  HGPA_AB_HEAD_BY_REPO[$repo]="$head"
  HGPA_AB_UPSTREAM_BY_REPO[$repo]="$upstream"
  HGPA_AB_MISC_BY_REPO[$repo]="$misc"
  hook_com[misc]+="$misc"
  return 0
}

function +vi-git-worktree() {
  [[ "${HGPA_SHOW_WORKTREE:-$HGPA_DEFAULT_SHOW_WORKTREE}" == "1" ]] || return 0
  local toplevel main_wt first_line
  toplevel=$(command git rev-parse --show-toplevel 2>/dev/null) || return 0
  first_line=$(command git worktree list 2>/dev/null | command head -1) || return 0
  main_wt="${first_line%% *}"
  [[ "$toplevel" == "$main_wt" ]] && return 0
  hook_com[misc]+=" %F{magenta}⎇ ${main_wt:t}%f"
}

function hgpa-vcs-precmd() {
  if [[ "${HGPA_SHOW_GIT:-1}" != "1" ]]; then
    vcs_info_msg_0_=''
    return 0
  fi
  hgpa-configure-vcs-info
  local -i refresh_ms="${HGPA_GIT_REFRESH_MS:-$HGPA_DEFAULT_GIT_REFRESH_MS}"
  local -i now_ms=0
  if (( refresh_ms > 0 )) && (( HGPA_VCS_CONFIG_CHANGED == 0 )); then
    now_ms=$(( EPOCHREALTIME * 1000 ))
    if (( now_ms - HGPA_LAST_VCS_REFRESH_MS < refresh_ms )); then
      return 0
    fi
  fi
  vcs_info
  if (( refresh_ms > 0 )); then
    (( now_ms == 0 )) && now_ms=$(( EPOCHREALTIME * 1000 ))
    HGPA_LAST_VCS_REFRESH_MS=$now_ms
  fi
}

add-zsh-hook precmd hgpa-vcs-precmd
setopt PROMPT_SUBST
PROMPT='%F{blue}%1~%f${vcs_info_msg_0_} %F{magenta}%#%f '
