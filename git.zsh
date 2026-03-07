alias gs="git status --show-stash"
alias gp="git pull"

# Git aliases (hgpa)
alias goops="git commit -a --amend --no-edit"
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
