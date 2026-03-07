alias gs="git status --show-stash"
alias gp="git pull"

# Git aliases (hgpa)
alias gcommit="git add . && git commit -a -F -"
alias goops="git commit -a --amend --no-edit"
alias greset="git reset HEAD^"

# git log (gl)
alias gl="git log"
alias glo="git log --oneline"
alias glg="git log --graph --oneline --decorate --all"

gbs() {
  local reset="\033[0m" bold="\033[1m"
  local green="\033[32m" red="\033[31m" yellow="\033[33m" dim="\033[2m"

  _gbs_files() {
    local color="$1"
    while IFS= read -r line; do
      local fstat="${line%%$'\t'*}"
      local rest="${line#*$'\t'}"
      local label="" file=""
      case "${fstat:0:1}" in
        M) label="modified:  "; file="$rest" ;;
        A) label="new file:  "; file="$rest" ;;
        D) label="deleted:   "; file="$rest" ;;
        R) label="renamed:   "
           file="${rest%%$'\t'*} -> ${rest#*$'\t'}" ;;
        *) label="${fstat}:        "; file="$rest" ;;
      esac
      printf "        ${color}%-11s %s${reset}\n" "$label" "$file"
    done
  }

  local no_commits=0
  git rev-parse HEAD &>/dev/null || no_commits=1

  local current
  current=$(git symbolic-ref --short HEAD 2>/dev/null || echo "(detached HEAD)")
  printf "${bold}On branch %s${reset}\n" "$current"

  local base=""
  if (( !no_commits )); then
    base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
    base=${base#refs/remotes/origin/}
    if [[ -z "$base" ]]; then
      for b in main master; do
        git rev-parse --verify "$b" &>/dev/null && base="$b" && break
      done
    fi
  fi

  # -- branch vs base --
  if (( !no_commits )) && [[ -n "$base" ]] && [[ "$current" != "$base" ]]; then
    local branch_files
    branch_files=$(git diff --name-status "$base"...HEAD)
    printf "\n${bold}Changes from %s:${reset}\n" "$base"
    if [[ -n "$branch_files" ]]; then
      _gbs_files "$yellow" <<< "$branch_files"
    else
      printf "        ${dim}(none)${reset}\n"
    fi
  fi

  # -- staged --
  local staged
  staged=$(git diff --name-status --cached HEAD 2>/dev/null)
  printf "\n${bold}Changes to be committed:${reset}\n"
  if [[ -n "$staged" ]]; then
    _gbs_files "$green" <<< "$staged"
  else
    printf "        ${dim}(none)${reset}\n"
  fi

  # -- unstaged --
  local unstaged
  unstaged=$(git diff --name-status 2>/dev/null)
  printf "\n${bold}Changes not staged for commit:${reset}\n"
  if [[ -n "$unstaged" ]]; then
    _gbs_files "$red" <<< "$unstaged"
  else
    printf "        ${dim}(none)${reset}\n"
  fi

  # -- untracked --
  local untracked
  untracked=$(git ls-files --others --exclude-standard)
  printf "\n${bold}Untracked files:${reset}\n"
  if [[ -n "$untracked" ]]; then
    while IFS= read -r file; do
      printf "        ${red}%s${reset}\n" "$file"
    done <<< "$untracked"
  else
    printf "        ${dim}(none)${reset}\n"
  fi

  unfunction _gbs_files
}

# git worktree (gw)
alias gw="git worktree"
alias gwl="git worktree list"
alias gwa="git worktree add"
alias gwr="git worktree remove"

# git branch (gb)
alias gb="git branch"

# git checkout
alias gco="git checkout"
alias gcob="git checkout -b"

# git add
alias ga="git add"
alias gaa="git add --all"

# git commit
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit --amend"
alias gcan="git commit --amend --no-edit"

alias gplr="git pull --rebase"
alias gf="git fetch"
alias gfa="git fetch --all"

alias gd="git diff"
alias gdc="git diff --cached"

alias gr="git rebase"
alias gri="git rebase -i"
alias grc="git rebase --continue"
alias gra="git rebase --abort"

alias grh="git reset HEAD"
alias grhh="git reset --hard HEAD"
alias gclean="git clean -fd"

# git worktree switch
gws() {
  local cwd="$PWD"
  local IFS=$'\n'
  local -a workpaths
  local -a displays
  local line

  # collect worktree paths and a short display form
  for line in $(git worktree list 2>/dev/null); do
    # first token is the path, the rest is branch/commit info
    local wtpath="${line%%[[:space:]]*}"
    local rest="${line#"$wtpath"}"
    rest="${rest## }"
    # show ~ instead of $HOME
    local dpath="${wtpath/#$HOME/~}"

    workpaths+=("$wtpath")
    displays+=("$dpath"$'\t'"$rest")
  done

  if [ ${#workpaths[@]} -eq 0 ]; then
    echo "No worktrees found."
    return 1
  fi

  # build a numbered, marked list for fzf
  local idx=0
  local input=""
  for dp in "${displays[@]}"; do
    idx=$((idx+1))
    local p="${workpaths[$((idx-1))]}"
    if [ "$p" = "$cwd" ]; then
      input+="→ $idx) $dp"$'\n'
    else
      input+="   $idx) $dp"$'\n'
    fi
  done

  # choose with fzf
  local choice
  choice=$(printf "%s" "$input" | fzf --no-hscroll --prompt="Switch worktree: ")
  [ -z "$choice" ] && return

  # extract the chosen number and map back to path
  local num
  num=$(echo "$choice" | sed -E 's/^[^0-9]*([0-9]+).*/\1/')
  if ! [[ "$num" =~ ^[0-9]+$ ]]; then
    echo "Couldn't parse selection."
    return 1
  fi

  local selpath="${workpaths[$((num-1))]}"
  cd "$selpath" || echo "Failed to cd to $selpath"
}

#
# github
#

# gh pr
alias ghpr="gh pr"
alias ghprv="gh pr view"
alias ghprvw="gh pr view --web"

# gh repo
alias ghr="gh repo"
alias ghrv="gh repo view"
alias ghrvw="gh repo view --web"
