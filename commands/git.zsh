alias gs="git status --show-stash"
alias gss="git status --short"
alias gp="git pull"

# Git aliases (hgpa)
alias goops="git add -A && git commit --amend --no-edit"
alias greset="git reset HEAD^"

# git log (gl)
alias gl="git log"
alias glo="git log --oneline"
alias glg="git log --graph --oneline --decorate --all"

# git worktree (gw)
alias gw="git worktree"
alias gwl="git worktree list"
alias gwa="git worktree add"
alias gwr="git worktree remove"

# gwc: create a branch + worktree together
# Usage: gwc <label> [base-branch]
# Example: gwc docs-update
gwc() {
  local label="$1"
  local base="$2"

  if [[ -z "$label" ]]; then
    echo "Usage: gwc <label> [base-branch]"
    return 1
  fi

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "gwc: not inside a git repository."
    return 1
  fi

  local top repo slug suffix branch wt_name wt_path
  top=$(git rev-parse --show-toplevel) || return 1
  repo="${top:t}"

  slug=$(printf "%s" "$label" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[ _]+/-/g; s/[^a-z0-9.-]+/-/g; s/-+/-/g; s/^-+//; s/-+$//')

  if [[ -z "$slug" ]]; then
    echo "gwc: label became empty after sanitization."
    return 1
  fi

  if [[ -z "$base" ]]; then
    base=$(git branch --show-current)
  fi
  if [[ -z "$base" ]]; then
    base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
    base="${base#refs/remotes/origin/}"
  fi
  if [[ -z "$base" ]]; then
    for b in main master; do
      if git rev-parse --verify "$b" >/dev/null 2>&1; then
        base="$b"
        break
      fi
    done
  fi
  if [[ -z "$base" ]]; then
    echo "gwc: couldn't determine base branch."
    return 1
  fi

  local attempts=0
  while :; do
    suffix=$(LC_ALL=C tr -dc 'a-z0-9' </dev/urandom | head -c 4)
    [[ -z "$suffix" ]] && suffix="${RANDOM}"

    branch="${slug}-${suffix}"
    wt_name="${repo}--${slug}-${suffix}"
    wt_path="${top:h}/${wt_name}"

    if ! git show-ref --verify --quiet "refs/heads/$branch" && [[ ! -e "$wt_path" ]]; then
      break
    fi

    attempts=$((attempts + 1))
    if (( attempts > 25 )); then
      echo "gwc: failed to generate a unique branch/worktree name."
      return 1
    fi
  done

  git worktree add -b "$branch" "$wt_path" "$base" || return 1
  echo "Created worktree: $wt_path"
  echo "Created branch:   $branch (from $base)"
}

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
alias gds="git diff --stat"
alias gdc="git diff --cached"

alias gr="git rebase"
alias gri="git rebase -i"
alias grc="git rebase --continue"
alias gra="git rebase --abort"

alias grh="git reset HEAD"
alias gtrash="git reset --hard HEAD"
alias gclean="git clean -fd"

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
