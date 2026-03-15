# .hgpa

## Engineering Life Cycle Workflow

This repository provides a set of custom shell commands and aliases that augment standard Git and GitHub CLI workflows. Together, they cover the entire engineering life cycle from task creation to merging and cleanup.

### 1. Setup & Diagnostics

Before starting development, ensure your environment is ready.

- `doctor` — Checks all expected CLI tools are installed and prints their versions.
- `doctor --install` — Installs any missing tools automatically.

### 2. Task Creation & Isolation

When picking up a new task, it's best to work in an isolated environment.

- `gwc <task-name>` — Creates a new branch and a linked Git worktree simultaneously. This keeps your main working tree clean.

### 3. Context & Navigation

As you return to a terminal or switch between tasks, you can quickly reorient yourself.

- `status` (or `s`) — The primary re-entry command. Provides a rich git status including the current repo, branch, worktree, stash count, local changes, and PR status (including failing CI check names).
- `context` (or `ctx`) — Prints a compact environment snapshot (time, user, directory, git state, and PR status) for humans or AI agents.
- `gws` — Switch between your active worktrees interactively using `fzf`.

### 4. Development & Code Review

While writing code, you can use these shortcuts to review your progress and commit changes.

- `gbd` — Shows the git diff between your current branch and its base branch (resolves base automatically).
- `review [focus]` — Pipes the current branch diff to an AI agent (Claude) for a code review. Optional `focus` argument narrows the review.
- `commit` (or `c`) — Stages all repo changes and commits from `stdin`.
  - `commit "message"` — Stages and commits with an inline message.
  - `commit --draft` (or `-d`) — Shows files that would be staged without committing.
  - `commit --ai` (or `-a`) — Generates a commit message from the current diff via Claude, confirms interactively, then commits.

*Standard commands to remember:*
- `ga` / `gaa` — `git add` / `git add --all`
- `gco` / `gcob` — `git checkout` / `git checkout -b`
- `gd` / `gds` / `gdc` — `git diff` / `git diff --stat` / `git diff --cached`

### 5. Pushing & Pull Requests (Standard Commands)

Once your code is committed, push your branch and open a pull request using standard commands.

- `git push -u origin HEAD` — Push your new branch to the remote repository.
- `gh pr create --web` — Open your browser to create a Pull Request.

### 6. Feedback & CI

Wait for automated reviews and address feedback from reviewers or AI.

- `copilotwait` (or `cw`) — Polls the current PR until a Copilot review/comment appears or a timeout is reached.
- `threads` (or `th`) — Shows all review threads on the current PR with file, line, and comments.

### 7. Merging & Cleanup

Once approved and CI passes, merge your PR and clean up your local environment.

- `merge` — Safe squash-merge of the current PR. It warns if there are unresolved review threads or failing CI. Afterward, it switches back to the default branch and pulls the latest changes.
- `gwr` (or `git worktree remove <path>`) — Remove the isolated worktree you created with `gwc`.

### 8. Asynchronous Work & Handoff

If you need to pause work or hand off to another engineer or AI agent.

- `handoff` (or `hoff`, `ho`) — Builds a full session handoff block containing a context snapshot, recent commits, diff stat, and TODOs/FIXMEs, then copies it to your clipboard.

## Setup

```sh
# clone .hgpa in HOME directory:
git clone https://github.com/hparra/.hgpa.git ~/.hgpa

# add source init to [~/.zshrc](../.zshrc):
echo '\n. ~/.hgpa/shell/init.zsh' >> ~/.zshrc

# start a new shell session, or source the init file:
source ~/.hgpa/shell/init.zsh
```

## Machine-specific environment (`~/.zshenv`)

`~/.zshenv` is sourced on every shell invocation and is the right place for variables that are specific to a machine or context (home, work, etc.). It is not tracked in this repo.

```sh
# Identity — may differ between home and work machines
export NAME="Your Name"
export EMAIL="you@example.com"

# Git identity
export GIT_AUTHOR_NAME="$NAME"
export GIT_AUTHOR_EMAIL="$EMAIL"
export GIT_COMMITTER_NAME="$NAME"
export GIT_COMMITTER_EMAIL="$EMAIL"

# PATH additions specific to this machine
export PATH="${HOME}/.local/bin:${PATH}"
```

## Node version management for agents

AI agents (Claude Code, Codex, Gemini CLI) only source `~/.zshenv` — they skip `~/.zshrc` entirely. This means `nvm` is never loaded, and `node` resolves to whatever is on `PATH`, ignoring `.nvmrc`.

`shell/nvm/nvm-quick.zsh` wraps `node`, `npm`, and `npx` to call `nvm use` automatically when the current version doesn't match `.nvmrc`. To enable it for agent sessions, add to `~/.zshenv`:

```sh
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
[[ -s "$HOME/.hgpa/shell/nvm/nvm-quick.zsh" ]] && . "$HOME/.hgpa/shell/nvm/nvm-quick.zsh"
```

This file is intentionally excluded from `shell/init.zsh` — the full `nvm.zsh` with `chpwd` hooks handles interactive shells already.

## Layout

- `shell/` contains environment and bootstrap files that are sourced into the shell session
- `commands/` contains command-oriented aliases and functions

## Shell behavior

- `shell/init.zsh` sets `bindkey -e` so the prompt keeps Emacs-style editing keys such as `Ctrl-A`, `Ctrl-E`, and Backspace
- this is separate from `EDITOR` and `VISUAL`, which control which full-screen editor tools launch

### Organizing commands

You do **not** need one file per command.

A practical pattern is:

- keep one file per domain (`git`, `dev`, `aliases`, `docker`, `k8s`, etc.)
- group tiny aliases together in shared files
- keep larger shell functions in domain files, with a short header comment per function
- only split to one-command-per-file when a function becomes long, has tests/docs, or has collaborators

`shell/init.zsh` already autoloads everything under `commands/**/*.zsh`, so the collection strategy is simply:

1. create a domain file in `commands/`
2. drop aliases/functions into that file
3. source `.hgpa/shell/init.zsh` (or restart shell)

If load order ever matters, use filename prefixes (for example `00-core.zsh`, `10-git.zsh`, `20-dev.zsh`) so glob ordering stays predictable.

Alternatively, you can source individual files.

## Agent configuration

These shell commands are available in any interactive session. To make agents aware of them, add the following blurb to your global agent configuration files:

**`~/.claude/CLAUDE.md`** (Claude Code) and **`~/AGENTS.md`** (Codex):

```markdown
## Shell commands (.hgpa)

Prefer these shell functions over raw git/gh equivalents:

- `s` — rich git status: branch, worktree, stash, staged/unstaged files, PR state, CI checks
- `ctx` — compact environment snapshot (time, user, dir, git, PR)
- `gbd` — git diff vs base branch (resolves base automatically)
- `doctor` — check installed tools; `doctor --install` to install missing ones
- `c` / `commit` — stage all and commit from stdin; `--draft` to preview staged files, `--ai` for AI-generated message
- `handoff` — build a session handoff block (context + commits + diff stat + TODOs) and copy to clipboard
```
