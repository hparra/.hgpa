# dev.zsh - development-related functions and aliases
# These are major commands that encapsulate development lifecycle.
#
# - status (s) -- super git status with branch vs base, staged/unstaged/untracked sections
# - context (ctx) -- compact environment snapshot for agent/session context
# - gws -- git worktree switcher with fzf
# - commit (c)

_hgpa_git_default_base_ref() {
  local ref=""
  ref=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null) || true
  if [[ -n "$ref" ]]; then
    printf "%s\n" "${ref#refs/remotes/}"
    return 0
  fi

  for ref in origin/main origin/master; do
    git rev-parse --verify "$ref" >/dev/null 2>&1 && printf "%s\n" "$ref" && return 0
  done

  for ref in main master; do
    git rev-parse --verify "$ref" >/dev/null 2>&1 && printf "%s\n" "$ref" && return 0
  done
}

_hgpa_git_resolve_base_ref() {
  local ref="$1"
  local remote_ref=""
  [[ -z "$ref" ]] && return 1

  case "$ref" in
    refs/heads/*)
      ref="${ref#refs/heads/}"
      ;;
    refs/remotes/*)
      remote_ref="${ref#refs/remotes/}"
      git rev-parse --verify "$remote_ref" >/dev/null 2>&1 || return 1
      printf "%s\n" "$remote_ref"
      return 0
      ;;
  esac

  if git rev-parse --verify "$ref" >/dev/null 2>&1; then
    printf "%s\n" "$ref"
    return 0
  fi

  if git rev-parse --verify "origin/$ref" >/dev/null 2>&1; then
    printf "%s\n" "origin/$ref"
    return 0
  fi

  return 1
}

_hgpa_git_base_ref() {
  local current explicit merge_ref merge_remote created_from fallback
  current=$(git symbolic-ref --short HEAD 2>/dev/null || true)
  if [[ -z "$current" ]]; then
    _hgpa_git_default_base_ref
    return $?
  fi

  explicit=$(git config --get "branch.$current.gh-merge-base" 2>/dev/null || true)
  if [[ -n "$explicit" ]]; then
    _hgpa_git_resolve_base_ref "$explicit" && return 0
  fi

  merge_ref=$(git config --get "branch.$current.merge" 2>/dev/null || true)
  if [[ -n "$merge_ref" && "$merge_ref" != "refs/heads/$current" ]]; then
    merge_remote=$(git config --get "branch.$current.remote" 2>/dev/null || true)
    if [[ -n "$merge_remote" && "$merge_remote" != "." && "$merge_ref" == refs/heads/* ]]; then
      _hgpa_git_resolve_base_ref "refs/remotes/$merge_remote/${merge_ref#refs/heads/}" && return 0
    fi
    _hgpa_git_resolve_base_ref "$merge_ref" && return 0
  fi

  created_from=$(git reflog show --reverse -n 1 --format='%gs' "refs/heads/$current" 2>/dev/null || true)
  if [[ "$created_from" == branch:\ Created\ from\ * ]]; then
    created_from="${created_from#branch: Created from }"
    if [[ "$created_from" != "HEAD" ]]; then
      _hgpa_git_resolve_base_ref "$created_from" && return 0
    fi
  fi

  fallback=$(_hgpa_git_default_base_ref 2>/dev/null || true)
  [[ -n "$fallback" ]] && printf "%s\n" "$fallback"
}

_hgpa_pr_thread_summary() {
  local pr_number="$1"
  local pr_url="$2"
  local query response repo_path owner repo
  [[ -z "$pr_number" || -z "$pr_url" ]] && return 0

  repo_path="${pr_url#https://github.com/}"
  repo_path="${repo_path%%/pull/*}"
  owner="${repo_path%%/*}"
  repo="${repo_path#*/}"
  [[ -z "$owner" || -z "$repo" || "$owner" == "$repo_path" ]] && return 0

  read -r -d '' query <<EOF
query {
  repository(owner: "$owner", name: "$repo") {
    pullRequest(number: $pr_number) {
      reviewThreads(first: 50) {
        nodes {
          isResolved
          comments(first: 1) {
            nodes {
              author { login }
              path
            }
          }
        }
      }
    }
  }
}
EOF

  response=$(gh api graphql -f query="$query" 2>/dev/null) || return 0
  jq -r '
    (.data.repository.pullRequest.reviewThreads.nodes // []) as $threads
    | ($threads | map(select(.isResolved == false)) | length) as $unresolved
    | ($threads | map(select(.isResolved == true)) | length) as $resolved
    | if ($unresolved + $resolved) == 0 then
        empty
      else
        "\($unresolved) unresolved, \($resolved) resolved"
      end
  ' <<< "$response" 2>/dev/null
}

_hgpa_pr_thread_counts() {
  local pr_number="$1"
  local pr_url="$2"
  local query response repo_path owner repo
  [[ -z "$pr_number" || -z "$pr_url" ]] && return 1

  repo_path="${pr_url#https://github.com/}"
  repo_path="${repo_path%%/pull/*}"
  owner="${repo_path%%/*}"
  repo="${repo_path#*/}"
  [[ -z "$owner" || -z "$repo" || "$owner" == "$repo_path" ]] && return 1

  read -r -d '' query <<EOF
query {
  repository(owner: "$owner", name: "$repo") {
    pullRequest(number: $pr_number) {
      reviewThreads(first: 50) {
        nodes {
          isResolved
        }
      }
    }
  }
}
EOF

  response=$(gh api graphql -f query="$query" 2>/dev/null) || return 1
  jq -r '
    (.data.repository.pullRequest.reviewThreads.nodes // []) as $threads
    | ($threads | map(select(.isResolved == false)) | length) as $unresolved
    | ($threads | map(select(.isResolved == true)) | length) as $resolved
    | "\($unresolved) \($resolved)"
  ' <<< "$response" 2>/dev/null
}

_hgpa_copilot_review_ready() {
  local pr_ref="${1:-}"
  local pattern="${HGPA_COPILOT_LOGIN_PATTERN:-copilot|github-copilot}"
  local pr_json=""

  pr_json=$(PAGER=cat gh pr view ${pr_ref:+$pr_ref} --json number,reviews,comments,url 2>/dev/null) || return 1

  jq -e --arg pattern "$pattern" '
    def is_copilot:
      (.author.login // "")
      | ascii_downcase
      | test($pattern; "i");
    ([.reviews[]? | select(is_copilot)] | length) > 0
    or ([.comments[]? | select(is_copilot)] | length) > 0
  ' <<< "$pr_json" >/dev/null 2>&1
}

# wait for a Copilot review/comment to land on a PR
# Usage: copilotwait [pr-number-or-url]
copilotwait() {
  local pr_ref="${1:-}"
  local timeout="${HGPA_COPILOT_WAIT_TIMEOUT:-600}"
  local interval="${HGPA_COPILOT_WAIT_INTERVAL:-15}"
  local elapsed=0
  local pr_json pr_number pr_url review_decision
  local unresolved_threads=0 resolved_threads=0

  if ! command -v gh >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    echo "copilotwait requires both gh and jq."
    return 1
  fi

  pr_json=$(PAGER=cat gh pr view ${pr_ref:+$pr_ref} --json number,url,reviewDecision 2>/dev/null) || {
    echo "Couldn't resolve a pull request to watch."
    return 1
  }

  pr_number=$(jq -r '.number // empty' <<< "$pr_json")
  pr_url=$(jq -r '.url // empty' <<< "$pr_json")
  review_decision=$(jq -r 'if (.reviewDecision // "") == "" then "none" else .reviewDecision end' <<< "$pr_json")

  [[ -n "$pr_number" ]] && echo "Watching PR #$pr_number for a Copilot review..."
  [[ -n "$pr_url" ]] && echo "$pr_url"

  while (( elapsed <= timeout )); do
    if _hgpa_copilot_review_ready "$pr_ref"; then
      echo "Copilot review detected."
      pr_json=$(PAGER=cat gh pr view ${pr_ref:+$pr_ref} --json number,url,reviewDecision 2>/dev/null || true)
      review_decision=$(jq -r 'if (.reviewDecision // "") == "" then "none" else .reviewDecision end' <<< "$pr_json" 2>/dev/null)

      if read -r unresolved_threads resolved_threads <<< "$(_hgpa_pr_thread_counts "$pr_number" "$pr_url" 2>/dev/null)"; then
        printf "Threads: %s unresolved, %s resolved\n" "${unresolved_threads:-0}" "${resolved_threads:-0}"
      fi

      printf "Review decision: %s\n" "$review_decision"

      if [[ "${unresolved_threads:-0}" -gt 0 ]]; then
        echo "Next step: address review threads."
        return 10
      fi

      echo "Review is clear."
      return 0
    fi

    if (( elapsed == timeout )); then
      break
    fi

    printf "No Copilot review yet. Checked at %ss, retrying in %ss...\n" "$elapsed" "$interval"
    sleep "$interval"
    elapsed=$((elapsed + interval))
  done

  echo "Timed out after ${timeout}s without a Copilot review."
  return 2
}

# status: show status of the repository including git
# - prints current branch and changes relative to the repo base (prefer origin/*, then local fallback)
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
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf "${bold}status${reset} ${dim}not a git repository${reset}\n"
    return 0
  fi
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

  local stash_count
  stash_count=$(git stash list 2>/dev/null | wc -l | tr -d ' ')
  (( stash_count > 0 )) && printf "        ${dim}stashes: %s${reset}\n" "$stash_count"

  local wt_path="" wt_branch="" wt_line
  local -a linked_trees=()
  while IFS= read -r wt_line; do
    case "$wt_line" in
      worktree\ *)         wt_path="${wt_line#worktree }" ;;
      branch\ refs/heads/*) wt_branch="${wt_line#branch refs/heads/}" ;;
      "")
        if [[ -n "$wt_path" && "$wt_path" != "$worktree_main" ]]; then
          linked_trees+=("${wt_path/#$HOME/~}  [${wt_branch:-(detached)}]")
        fi
        wt_path=""; wt_branch=""
        ;;
    esac
  done < <(git worktree list --porcelain 2>/dev/null)
  if (( ${#linked_trees[@]} > 0 )); then
    printf "        ${dim}linked worktrees:${reset}\n"
    for lt in "${linked_trees[@]}"; do
      printf "          ${dim}%s${reset}\n" "$lt"
    done
  fi

  local base="" base_label=""
  if (( !no_commits )); then
    base=$(_hgpa_git_base_ref)
    base_label="${base#origin/}"
  fi

  # -- branch vs base --
  if (( !no_commits )) && [[ -n "$base" ]] && [[ "$current" != "$base_label" ]]; then
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
  staged=$(git diff --name-status --cached 2>/dev/null)
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
    local pr_json pr_number pr_state pr_reviews pr_ci pr_url pr_threads ci_color rev_color thread_color
    local unresolved_threads resolved_threads
    pr_json=$(PAGER=cat gh pr view --json number,state,reviewDecision,statusCheckRollup,url 2>/dev/null)
    if [[ -n "$pr_json" ]]; then
      pr_number=$(jq -r '.number' <<< "$pr_json")
      pr_state=$(jq -r '.state // empty' <<< "$pr_json")
      pr_reviews=$(jq -r '.reviewDecision // "none"' <<< "$pr_json")
      pr_ci=$(jq -r '[.statusCheckRollup[]? | .state] | if length == 0 then "none" elif all(. == "SUCCESS") then "passing" elif any(. == "FAILURE" or . == "ERROR") then "failing" else "pending" end' <<< "$pr_json")
      local pr_failing_checks
      pr_failing_checks=$(jq -r '[.statusCheckRollup[]? | select(.state == "FAILURE" or .state == "ERROR") | (.name // .context // "unknown")] | join(", ")' <<< "$pr_json")
      pr_url=$(jq -r '.url // empty' <<< "$pr_json")
      pr_threads=$(_hgpa_pr_thread_summary "$pr_number" "$pr_url")

      ci_color="$reset"
      [[ "$pr_ci" == "passing" ]] && ci_color="$green"
      [[ "$pr_ci" == "failing" ]] && ci_color="$red"
      [[ "$pr_ci" == "pending" ]] && ci_color="$yellow"

      rev_color="$dim"
      [[ "$pr_reviews" == "APPROVED" ]] && rev_color="$green"
      [[ "$pr_reviews" == "CHANGES_REQUESTED" ]] && rev_color="$red"
      [[ "$pr_reviews" == "REVIEW_REQUIRED" || "$pr_reviews" == "COMMENTED" ]] && rev_color="$yellow"

      thread_color="$dim"
      if [[ -n "$pr_threads" ]]; then
        unresolved_threads="${pr_threads%% unresolved,*}"
        resolved_threads="${pr_threads#*, }"
        resolved_threads="${resolved_threads%% resolved*}"
        [[ "$unresolved_threads" != "$pr_threads" ]] || unresolved_threads="0"
        [[ "$resolved_threads" != "$pr_threads" ]] || resolved_threads="0"

        if [[ "${unresolved_threads:-0}" -gt 0 ]]; then
          thread_color="$yellow"
        elif [[ "${resolved_threads:-0}" -gt 0 ]]; then
          thread_color="$green"
        fi
      fi

      printf "\n${bold}Pull request #%s${reset}  %s\n" "$pr_number" "$pr_state"
      [[ -n "$pr_url" ]] && printf "        link: %s\n" "$pr_url"
      printf "        CI: ${ci_color}%s${reset}\n" "$pr_ci"
      [[ -n "$pr_failing_checks" && "$pr_ci" == "failing" ]] && \
        printf "        failing: ${red}%s${reset}\n" "$pr_failing_checks"
      printf "        reviews: ${rev_color}%s${reset}\n" "$pr_reviews"
      [[ -n "$pr_threads" ]] && printf "        threads: ${thread_color}%s${reset}\n" "$pr_threads"
    fi
  fi

  unfunction _gbs_files
}
alias s=status
alias cw=copilotwait

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
  local pr_json pr_number pr_state pr_reviews pr_ci pr_url ci_color rev_color

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

  base=$(_hgpa_git_base_ref)
  [[ -n "$base" ]] && base_ref="$base" || base_ref="(unknown)"

  staged_count=$(git diff --name-only --cached 2>/dev/null | wc -l | tr -d ' ')
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
    printf "  ${bold}branch diff:${reset} ahead %s, behind %s vs %s\n" "${ahead:-0}" "${behind:-0}" "$base_ref"
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
    pr_json=$(PAGER=cat gh pr view --json number,state,reviewDecision,statusCheckRollup,url 2>/dev/null)
    if [[ -n "$pr_json" ]]; then
      pr_number=$(jq -r '.number' <<< "$pr_json")
      pr_state=$(jq -r '.state // empty' <<< "$pr_json")
      pr_reviews=$(jq -r '.reviewDecision // "none"' <<< "$pr_json")
      pr_ci=$(jq -r '[.statusCheckRollup[]? | .state] | if length == 0 then "none" elif all(. == "SUCCESS") then "passing" elif any(. == "FAILURE" or . == "ERROR") then "failing" else "pending" end' <<< "$pr_json")
      pr_url=$(jq -r '.url // empty' <<< "$pr_json")

      ci_color="$reset"
      [[ "$pr_ci" == "passing" ]] && ci_color="$green"
      [[ "$pr_ci" == "failing" ]] && ci_color="$red"
      [[ "$pr_ci" == "pending" ]] && ci_color="$yellow"

      rev_color="$dim"
      [[ "$pr_reviews" == "APPROVED" ]] && rev_color="$green"
      [[ "$pr_reviews" == "CHANGES_REQUESTED" ]] && rev_color="$red"

      printf "  ${bold}pr:${reset} #%s %s\n" "$pr_number" "$pr_state"
      [[ -n "$pr_url" ]] && printf "  ${bold}pr link:${reset} %s\n" "$pr_url"
      printf "  ${bold}ci:${reset} ${ci_color}%s${reset}\n" "$pr_ci"
      printf "  ${bold}reviews:${reset} ${rev_color}%s${reset}\n" "$pr_reviews"
    else
      printf "  ${bold}pr:${reset} ${dim}none${reset}\n"
    fi
  fi
}
alias ctx=context

# handoff: build a complete session handoff block and copy to clipboard
# - includes context snapshot, recent commits, diff stat, and TODO/FIXME scan
# Usage: handoff  (aliases: hoff, ho)
handoff() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "handoff: not inside a git repository."
    return 1
  fi

  _strip_ansi() { sed $'s/\033\\[[0-9;]*m//g'; }

  local output=""

  output+="$(context 2>&1 | _strip_ansi)"$'\n\n'

  output+="## Recent commits (last 10)"$'\n'
  local log
  log=$(git log --oneline -10 2>/dev/null || true)
  output+="${log:-(no commits)}"$'\n\n'

  local base
  base=$(_hgpa_git_base_ref)
  if [[ -n "$base" ]]; then
    output+="## Diff stat vs $base"$'\n'
    local stat
    stat=$(gbd --stat 2>/dev/null || true)
    output+="${stat:-(no diff)}"$'\n\n'
  fi

  output+="## TODOs / FIXMEs (first 20)"$'\n'
  if command -v rg >/dev/null 2>&1; then
    local todos
    todos=$(rg --no-heading --line-number -i 'TODO|FIXME' \
      --glob '!*.lock' --glob '!package-lock.json' --glob '!yarn.lock' \
      . 2>/dev/null | head -20 || true)
    output+="${todos:-(none found)}"$'\n'
  else
    output+="(rg not available)"$'\n'
  fi

  printf "%s" "$output"
  if command -v pbcopy >/dev/null 2>&1; then
    printf "%s" "$output" | pbcopy
    printf "\n[Copied to clipboard]\n" >&2
  else
    printf "\n[pbcopy not available — output printed only]\n" >&2
  fi

  unfunction _strip_ansi
}
alias hoff=handoff
alias ho=handoff

# review: pipe current branch diff to claude for a code review
# Usage: review [focus-description]
review() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "review: not inside a git repository."
    return 1
  fi
  if ! command -v claude >/dev/null 2>&1; then
    echo "review: claude CLI not found. Install: npm install -g @anthropic-ai/claude-code"
    return 1
  fi

  local diff
  diff=$(gbd 2>/dev/null || true)
  if [[ -z "$diff" ]]; then
    echo "review: no diff found vs base branch."
    return 0
  fi

  local focus="${1:-}"
  local intro="Please review the following git diff."
  [[ -n "$focus" ]] && intro="Please review the following git diff with a focus on: ${focus}."

  claude -p "${intro}

Provide:
1. A brief summary of what changed
2. Potential issues or bugs
3. Suggestions for improvement

Diff:
${diff}"
}

# commit: stage all and commit
# Usage:
#   echo "msg" | commit          pipe message from stdin (default)
#   commit --draft / -d          dry run: show what would be staged
#   commit --ai / -a             generate commit message via claude then commit
commit() {
  local draft=0 ai=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --draft|-d) draft=1; shift ;;
      --ai|-a)    ai=1;    shift ;;
      --) shift; break ;;
      -*)
        echo "commit: unknown flag: $1"
        echo "Usage: commit [--draft|-d] [--ai|-a]"
        return 1
        ;;
      *)
        echo "commit: unexpected argument: $1"
        return 1
        ;;
    esac
  done

  if (( draft )); then
    echo "Files that would be staged:"
    git status --short
    return 0
  fi

  if (( ai )); then
    if ! command -v claude >/dev/null 2>&1; then
      echo "commit --ai: claude CLI not found. Install: npm install -g @anthropic-ai/claude-code"
      return 1
    fi
    if [[ ! -t 0 ]]; then
      echo "commit --ai: requires an interactive terminal."
      return 1
    fi

    local diff
    diff=$(git diff --cached 2>/dev/null)
    [[ -z "$diff" ]] && diff=$(git diff HEAD 2>/dev/null)
    if [[ -z "$diff" ]]; then
      echo "commit --ai: no changes found."
      return 1
    fi

    local msg
    msg=$(claude -p "Generate a concise git commit message for the following diff.
Return only the commit message text — no preamble, explanation, or markdown.
Use imperative mood. Subject line under 72 characters.
If complex, add a blank line and short body paragraph.

Diff:
${diff}" 2>/dev/null)

    if [[ -z "$msg" ]]; then
      echo "commit --ai: claude returned an empty message."
      return 1
    fi

    echo "Generated commit message:"
    echo "---"
    echo "$msg"
    echo "---"
    echo -n "Commit with this message? [y/N] "
    local answer
    read -r answer
    [[ "$answer" != "y" && "$answer" != "Y" ]] && echo "Aborted." && return 0

    git add -A && printf "%s" "$msg" | git commit -F -
    return $?
  fi

  # default: read from stdin
  git add -A && git commit -F -
}
alias c=commit

# gbd: show git diff between current branch and base branch
# - determines base from explicit branch metadata, branch merge config, creation reflog, then default branch fallback
# - if base cannot be determined the function exits with an error
# - any arguments are forwarded to 'git diff' (e.g. gbd --name-only)
# Usage: gbd [git-diff-args]
gbd() {
  local base
  base=$(_hgpa_git_base_ref)

  if [[ -z "$base" ]]; then
    echo "Couldn't determine a base branch from metadata, branch history, or the repo default branch."
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

# doctor: check (and optionally install) all expected CLI tools
# Usage: doctor [--install|-i]
doctor() {
  local do_install=0
  [[ "${1:-}" == "--install" || "${1:-}" == "-i" ]] && do_install=1

  local reset="\033[0m" green="\033[32m" red="\033[31m" bold="\033[1m" dim="\033[2m" yellow="\033[33m"

  _doc_tool() {
    local label="$1" cmd="$2" version_cmd="$3" install_cmd="$4"
    if command -v "$cmd" >/dev/null 2>&1; then
      local ver=""
      [[ -n "$version_cmd" ]] && ver=$(eval "$version_cmd" 2>/dev/null | head -n 1 || true)
      printf "  ${green}✓${reset} %-12s ${dim}%s${reset}\n" "$label" "$ver"
    elif (( do_install )) && [[ -n "$install_cmd" ]]; then
      printf "  ${yellow}↓${reset} %-12s ${dim}installing…${reset}\n" "$label"
      eval "$install_cmd"
    else
      printf "  ${red}✗${reset} %-12s ${dim}not found${reset}\n" "$label"
    fi
  }

  # ensure brew is on PATH (ARM Macs)
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  printf "${bold}Core CLIs${reset}\n"
  _doc_tool brew    brew    "brew --version | head -n 1"      'curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash'
  _doc_tool git     git     "git --version"                    "brew install git"
  _doc_tool gh      gh      "gh --version | head -n 1"        "brew install gh"
  _doc_tool jq      jq      "jq --version"                    "brew install jq"
  _doc_tool rg      rg      "rg --version | head -n 1"        "brew install ripgrep"
  _doc_tool fd      fd      "fd --version"                    "brew install fd"
  _doc_tool bat     bat     "bat --version"                   "brew install bat"

  printf "\n${bold}Utility CLIs${reset}\n"
  _doc_tool fzf     fzf     "fzf --version"                   "brew install fzf"
  _doc_tool uv      uv      "uv --version | head -n 1"        "brew install uv"
  _doc_tool tree    tree    "tree --version | head -n 1"      "brew install tree"
  _doc_tool wget    wget    "wget --version | head -n 1"      "brew install wget"
  _doc_tool tmux    tmux    "tmux -V"                         "brew install tmux"
  _doc_tool direnv  direnv  "direnv version"                  "brew install direnv"

  printf "\n${bold}Language Tooling${reset}\n"
  _doc_tool nvm     nvm     "nvm --version"                   'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash'
  _doc_tool node    node    "node --version"                  "nvm install --lts"
  _doc_tool pyenv   pyenv   "pyenv --version"                 "brew install pyenv"

  printf "\n${bold}Agent CLIs${reset}\n"
  _doc_tool claude  claude  "claude --version 2>/dev/null | head -n 1"  "npm install -g @anthropic-ai/claude-code"
  _doc_tool codex   codex   "codex --version 2>/dev/null | tail -n 1"   "npm install -g @openai/codex"
  _doc_tool gemini  gemini  ""                                           "npm install -g @google/gemini-cli"
  _doc_tool copilot copilot ""                                           "npm install -g @github/copilot"

  unfunction _doc_tool
}
