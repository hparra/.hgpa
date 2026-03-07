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
glb() {
  git rev-parse HEAD &>/dev/null || { echo "glb: no commits yet" >&2; return 1; }
  local base
  base=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)
  base=${base#refs/remotes/origin/}
  if [[ -z "$base" ]]; then
    for b in main master; do
      git rev-parse --verify "$b" &>/dev/null && base="$b" && break
    done
  fi
  if [[ -z "$base" ]]; then
    echo "glb: could not determine base branch" >&2
    return 1
  fi
  git log --oneline "$base"..HEAD
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