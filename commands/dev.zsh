# dev.zsh - development-related functions and aliases
# These are major commands that encapsulate developent lifecycle.
#
# - status (s) -- super git status with branch vs base, staged/unstaged/untracked sections
# - context (ctx) -- compact environment snapshot for agent/session context
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

  local current top repo worktree_main worktree_kind
  top=$(git rev-parse --show-toplevel 2>/dev/null)
  repo="${top:t}"
  current=$(git symbolic-ref --short HEAD 2>/dev/null || echo "(detached HEAD)")
  worktree_main=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree / {print substr($0, 10); exit}')
  if [[ -n "$worktree_main" ]]; then
    if [[ "$top" == "$worktree_main" ]]; then
      worktree_kind="main"
    else
      worktree_kind="linked"
    fi
  fi

  printf "${bold}%s${reset} on branch %s\n" "$repo" "$current"
  if [[ -n "$worktree_kind" ]]; then
    printf "        ${dim}worktree: %s${reset}\n" "$worktree_kind"
    [[ "$worktree_kind" == "linked" ]] && printf "        ${dim}main tree: %s${reset}\n" "${worktree_main/#$HOME/~}"
  fi

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

  # -- pr --
  if [[ "$current" != "(detached HEAD)" ]] && command -v gh &>/dev/null && command -v jq &>/dev/null; then
    local pr_json pr_number pr_state pr_reviews pr_ci ci_color rev_color
    pr_json=$(PAGER=cat gh pr view --json number,state,reviewDecision,statusCheckRollup 2>/dev/null)
    if [[ -n "$pr_json" ]]; then
      pr_number=$(jq -r '.number' <<< "$pr_json")
      pr_state=$(jq -r '.state // empty' <<< "$pr_json")
      pr_reviews=$(jq -r '.reviewDecision // "none"' <<< "$pr_json")
      pr_ci=$(jq -r '[.statusCheckRollup[]? | .state] | if length == 0 then "none" elif all(. == "SUCCESS") then "passing" elif any(. == "FAILURE" or . == "ERROR") then "failing" else "pending" end' <<< "$pr_json")

      ci_color="$reset"
      [[ "$pr_ci" == "passing" ]] && ci_color="$green"
      [[ "$pr_ci" == "failing" ]] && ci_color="$red"
      [[ "$pr_ci" == "pending" ]] && ci_color="$yellow"

      rev_color="$dim"
      [[ "$pr_reviews" == "APPROVED" ]] && rev_color="$green"
      [[ "$pr_reviews" == "CHANGES_REQUESTED" ]] && rev_color="$red"

      printf "\n${bold}Pull request #%s${reset}  %s\n" "$pr_number" "$pr_state"
      printf "        CI: ${ci_color}%s${reset}\n" "$pr_ci"
      printf "        reviews: ${rev_color}%s${reset}\n" "$pr_reviews"
    fi
  fi

  unfunction _gbs_files
}
alias s=status

# context: print a compact environment snapshot for humans and agents
# - includes time, user, current directory, and git metadata when available
# - summarizes local changes, branch/base state, upstream tracking, and PR status
context() {
  local reset="\033[0m" bold="\033[1m" dim="\033[2m"
  local green="\033[32m" red="\033[31m" yellow="\033[33m"

  printf "${bold}Context${reset}\n"
  printf "  ${bold}time:${reset} %s\n" "$(date '+%Y-%m-%d %H:%M:%S %Z')"
  printf "  ${bold}user:${reset} %s\n" "${USER:-$(whoami)}"
  printf "  ${bold}dir:${reset} %s\n" "${PWD/#$HOME/~}"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "  ${bold}git:${reset} ${dim}not a git repository${reset}\n"
    return 0
  fi

  local repo top current base base_ref staged_count unstaged_count untracked_count
  local upstream upstream_ref ahead behind up_ahead up_behind
  local worktree_main worktree_kind
  local pr_json pr_number pr_state pr_reviews pr_ci ci_color rev_color

  top=$(git rev-parse --show-toplevel 2>/dev/null) || return 1
  repo="${top:t}"
  current=$(git symbolic-ref --short HEAD 2>/dev/null || echo "(detached HEAD)")
  worktree_main=$(git worktree list --porcelain 2>/dev/null | awk '/^worktree / {print substr($0, 10); exit}')
  if [[ -n "$worktree_main" ]]; then
    if [[ "$top" == "$worktree_main" ]]; then
      worktree_kind="main"
    else
      worktree_kind="linked"
    fi
  fi

  base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
  base=${base#refs/remotes/origin/}
  if [[ -z "$base" ]]; then
    for b in main master; do
      git rev-parse --verify "$b" >/dev/null 2>&1 && base="$b" && break
    done
  fi
  [[ -n "$base" ]] && base_ref="origin/$base" || base_ref="(unknown)"

  staged_count=$(git diff --name-only --cached HEAD 2>/dev/null | wc -l | tr -d ' ')
  unstaged_count=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
  untracked_count=$(git ls-files --others --exclude-standard | wc -l | tr -d ' ')

  printf "  ${bold}repo:${reset} %s\n" "$repo"
  if [[ -n "$worktree_kind" ]]; then
    printf "  ${bold}worktree:${reset} %s\n" "$worktree_kind"
    [[ "$worktree_kind" == "linked" ]] && printf "  ${bold}main tree:${reset} %s\n" "${worktree_main/#$HOME/~}"
  fi
  printf "  ${bold}branch:${reset} %s\n" "$current"
  [[ -n "$base" ]] && printf "  ${bold}base:${reset} %s\n" "$base_ref"

  if [[ -n "$base" ]] && [[ "$current" != "(detached HEAD)" ]]; then
    read -r behind ahead <<<"$(git rev-list --left-right --count "$base"...HEAD 2>/dev/null)"
    printf "  ${bold}branch diff:${reset} ahead %s, behind %s vs %s\n" "${ahead:-0}" "${behind:-0}" "$base"
  fi

  printf "  ${bold}changes:${reset} staged %s, unstaged %s, untracked %s\n" \
    "$staged_count" "$unstaged_count" "$untracked_count"

  upstream=$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)
  if [[ -n "$upstream" ]]; then
    upstream_ref="$upstream"
    read -r up_behind up_ahead <<<"$(git rev-list --left-right --count '@{upstream}'...HEAD 2>/dev/null)"
    printf "  ${bold}upstream:${reset} %s (ahead %s, behind %s)\n" \
      "$upstream_ref" "${up_ahead:-0}" "${up_behind:-0}"
  else
    printf "  ${bold}upstream:${reset} ${dim}none${reset}\n"
  fi

  if [[ "$current" != "(detached HEAD)" ]] && command -v gh >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    pr_json=$(PAGER=cat gh pr view --json number,state,reviewDecision,statusCheckRollup 2>/dev/null)
    if [[ -n "$pr_json" ]]; then
      pr_number=$(jq -r '.number' <<< "$pr_json")
      pr_state=$(jq -r '.state // empty' <<< "$pr_json")
      pr_reviews=$(jq -r '.reviewDecision // "none"' <<< "$pr_json")
      pr_ci=$(jq -r '[.statusCheckRollup[]? | .state] | if length == 0 then "none" elif all(. == "SUCCESS") then "passing" elif any(. == "FAILURE" or . == "ERROR") then "failing" else "pending" end' <<< "$pr_json")

      ci_color="$reset"
      [[ "$pr_ci" == "passing" ]] && ci_color="$green"
      [[ "$pr_ci" == "failing" ]] && ci_color="$red"
      [[ "$pr_ci" == "pending" ]] && ci_color="$yellow"

      rev_color="$dim"
      [[ "$pr_reviews" == "APPROVED" ]] && rev_color="$green"
      [[ "$pr_reviews" == "CHANGES_REQUESTED" ]] && rev_color="$red"

      printf "  ${bold}pr:${reset} #%s %s\n" "$pr_number" "$pr_state"
      printf "  ${bold}ci:${reset} ${ci_color}%s${reset}\n" "$pr_ci"
      printf "  ${bold}reviews:${reset} ${rev_color}%s${reset}\n" "$pr_reviews"
    else
      printf "  ${bold}pr:${reset} ${dim}none${reset}\n"
    fi
  fi
}
alias ctx=context

# commit: stage all and commit with message from stdin
# Usage: echo "msg" | commit   or   commit < message.txt
commit() {
  git add . && git commit -a -F -
}
alias c=commit

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
