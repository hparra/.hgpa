# dev.zsh - development-related functions and aliases
# These are major commands that encapsulate developent lifecycle.
#
# - status (s) -- super git status with branch vs base, staged/unstaged/untracked sections
# - gws -- git worktree switcher with fzf
# - commit (c)

# status: show status of the repository including git
# - prints current branch and changes relative to the repo base (origin/HEAD or main/master)
# - displays sections: changes from base, staged changes, unstaged changes, untracked files
# - colored output for easier scanning
status() {
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
  [[ -n "$staged" ]] && printf "\n${bold}Changes to be committed:${reset}\n" && _gbs_files "$green" <<< "$staged"

  # -- unstaged --
  local unstaged
  unstaged=$(git diff --name-status 2>/dev/null)
  [[ -n "$unstaged" ]] && printf "\n${bold}Changes not staged for commit:${reset}\n" && _gbs_files "$red" <<< "$unstaged"

  # -- untracked --
  local untracked
  untracked=$(git ls-files --others --exclude-standard)
  if [[ -n "$untracked" ]]; then
    printf "\n${bold}Untracked files:${reset}\n"
    while IFS= read -r file; do
      printf "        ${red}%s${reset}\n" "$file"
    done <<< "$untracked"
  fi

  if [[ -z "$staged" && -z "$unstaged" && -z "$untracked" ]]; then
    printf "\n${dim}nothing to commit, working tree clean${reset}\n"
  fi

  unfunction _gbs_files
}
alias s=status

# gbd: show git diff between current branch and base branch
# - determines base from origin/HEAD; falls back to 'main' or 'master' if needed
# - if base cannot be determined the function exits with an error
# - any arguments are forwarded to 'git diff' (e.g. gbd --name-only)
# Usage: gbd [git-diff-args]
gbd() {
  local base
  base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
  base=${base#refs/remotes/origin/}

  if [[ -z "$base" ]]; then
    for b in main master; do
      git rev-parse --verify "$b" &>/dev/null && base="$b" && break
    done
  fi

  if [[ -z "$base" ]]; then
    echo "Couldn't determine base branch (origin/HEAD, main, or master)."
    return 1
  fi

  git diff "$base"...HEAD "$@"
}

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
    local p="${workpaths[$idx]}"
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

  local selpath="${workpaths[$num]}"
  cd "$selpath" || echo "Failed to cd to $selpath"
}
