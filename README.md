# .hgpa

Shell commands and environment for the development lifecycle — from setup through merge.

Everything below assumes `.hgpa` is installed and sourced. Custom commands are marked with `⚡`. Standard git and gh aliases are listed where they fit in the workflow so you can stay in the flow without memorizing anything extra.

## Setup

```sh
# clone into HOME
git clone https://github.com/hparra/.hgpa.git ~/.hgpa

# add to ~/.zshrc
echo '\n. ~/.hgpa/shell/init.zsh' >> ~/.zshrc

# start using it
source ~/.hgpa/shell/init.zsh
```

### Machine identity (`~/.zshenv`)

`~/.zshenv` is sourced on every shell invocation — interactive and non-interactive (including AI agents). Put machine-specific variables here. This file is not tracked.

```sh
export NAME="Your Name"
export EMAIL="you@example.com"

export GIT_AUTHOR_NAME="$NAME"
export GIT_AUTHOR_EMAIL="$EMAIL"
export GIT_COMMITTER_NAME="$NAME"
export GIT_COMMITTER_EMAIL="$EMAIL"

export PATH="${HOME}/.local/bin:${PATH}"
```

### Node version management for agents

AI agents only source `~/.zshenv` — they skip `~/.zshrc`, so `nvm` is never loaded. `shell/nvm/nvm-quick.zsh` wraps `node`, `npm`, and `npx` to call `nvm use` automatically when the version doesn't match `.nvmrc`. Add to `~/.zshenv`:

```sh
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
[[ -s "$HOME/.hgpa/shell/nvm/nvm-quick.zsh" ]] && . "$HOME/.hgpa/shell/nvm/nvm-quick.zsh"
```

### Check your tools

```sh
doctor            # ⚡ audit installed CLIs and versions
doctor --install  # ⚡ install anything missing via brew/npm
```

`doctor` checks: brew, git, gh, jq, rg, fd, bat, fzf, uv, tree, wget, tmux, direnv, nvm, node, pyenv, claude, codex, gemini, copilot.

For desktop apps and macOS defaults:

```sh
./setup/apps.zsh   # install desktop apps via brew cask
./setup/macos.zsh  # apply macOS system preferences
./setup/init.zsh   # run the full setup flow
```

---

## The Workflow

### 1. Orient — where am I?

You just opened a terminal, switched to a worktree, or resumed after lunch. Start here.

```sh
s       # ⚡ rich status: branch, worktree, stash, staged/unstaged, PR state, CI checks
ctx     # ⚡ compact snapshot: time, user, dir, repo, branch, base, ahead/behind, PR, CI
```

For quick glances:

```sh
gss     # git status --short
gds     # git diff --stat
gl      # git log
glo     # git log --oneline
```

### 2. Branch — start working

Create a branch the standard way, or use worktrees for parallel work:

```sh
gcob feature-name           # git checkout -b
gwc feature-name            # ⚡ create branch + linked worktree with auto-sanitized name
gwc feature-name main       # ⚡ branch from a specific base
```

Switch between worktrees:

```sh
gws     # ⚡ fzf worktree switcher
gwl     # git worktree list
```

### 3. Code

This is the part where you write code. Use your editor, use an agent, pair — whatever works.

```sh
# launch an agent for the heavy lifting
claude
codex
gemini
```

### 4. Review your changes

Before committing, look at what you've done:

```sh
gss             # quick file-level summary
gd              # git diff (unstaged)
gdc             # git diff --cached (staged)
gbd             # ⚡ diff vs base branch (auto-detects base)
gbd --stat      # ⚡ just the file summary vs base
```

Preview what would be committed:

```sh
commit --draft  # ⚡ show files that would be staged, without committing
```

### 5. Commit

```sh
commit "fix: handle empty input"       # ⚡ stage all + commit with message
echo "fix: handle empty input" | commit # ⚡ read message from stdin
commit --ai                             # ⚡ generate message from diff via claude
```

Standard git shortcuts if you prefer manual staging:

```sh
gc      # git commit
gcm     # git commit -m
gca     # git commit --amend
goops   # stage all (including untracked) + amend last commit silently
```

### 6. Push and open a PR

```sh
git push        # push to remote (no alias — be intentional)
ghpr            # gh pr
ghprv           # gh pr view
```

### 7. Get reviews

Request an AI code review from your terminal:

```sh
review              # ⚡ pipe branch diff to claude for review
review "security"   # ⚡ focus the review on a specific concern
```

Wait for automated reviews:

```sh
cw      # ⚡ poll PR until Copilot review lands (600s timeout)
```

Inspect review threads:

```sh
threads         # ⚡ show all review threads with comments on current PR
threads 42      # ⚡ threads for a specific PR number
```

### 8. Iterate

Address feedback, commit again, push again. Use `s` to check CI and review status between rounds.

```sh
s               # ⚡ see updated PR status, CI checks, review state
gbd             # ⚡ verify full diff vs base still looks right
commit --ai     # ⚡ commit the next round
git push        # push
```

Rebase shortcuts if needed:

```sh
gr      # git rebase
gri     # git rebase -i
grc     # git rebase --continue
gra     # git rebase --abort
```

### 9. Merge

```sh
merge   # ⚡ squash-merge PR with safety checks (unresolved threads, CI state),
        #   then switch to default branch and pull
```

### 10. Hand off

When you're done for the day or passing context to another session or agent:

```sh
handoff     # ⚡ build handoff block: context + recent commits + diff stat + TODOs
            #   copies to clipboard automatically
```

---

## Agent configuration

`setup/init.zsh` automatically wires `.hgpa` into Claude Code's user-level config:

```
~/.claude/CLAUDE.md  → ~/.hgpa/CLAUDE.md        # global agent instructions
~/.claude/agents/    → ~/.hgpa/agents/           # user-level sub-agents
~/.claude/commands/  → ~/.hgpa/claude-commands/  # user-level slash commands
```

These are **user-level** — available in every repo automatically. Project repos can still define their own `.claude/agents/` and `.claude/commands/` that layer on top.

### Sub-agents

| Agent | Description |
|---|---|
| `commit` | Stage all + commit (with message or `--ai`) |
| `review` | AI code review on branch diff, optional focus |
| `merge` | Squash-merge PR with safety checks |
| `handoff` | Build session handoff block, copy to clipboard |

### Slash commands

| Command | Description |
|---|---|
| `/status` | Rich git status |
| `/commit [msg]` | Stage + commit; AI message if no arg |
| `/review [focus]` | AI code review |
| `/handoff` | Session handoff to clipboard |
| `/merge` | Safe squash-merge |

For Codex, add the contents of `CLAUDE.md` to `~/AGENTS.md` manually (Codex does not support user-level agent/command directories).

## Layout

```
shell/          # environment and bootstrap (sourced into session)
  init.zsh      # sources shell/**/*.zsh and commands/**/*.zsh (excludes init.zsh, nvm-quick.zsh)
  env.zsh       # EDITOR, VISUAL, locale
  prompt.zsh    # git-aware prompt with status indicators
  nvm/          # node version management
commands/       # aliases and functions by domain
  aliases.zsh   # navigation, file ops, system shortcuts
  git.zsh       # git shortcuts and worktree helpers
  dev.zsh       # status, commit, review, merge, doctor, handoff
setup/          # machine setup scripts
docs/           # additional documentation
```

### Adding commands

One file per domain. Drop aliases and functions into a file under `commands/`, restart your shell. `shell/init.zsh` sources everything under `commands/**/*.zsh`.

If load order matters, use filename prefixes: `00-core.zsh`, `10-git.zsh`, `20-dev.zsh`.

## Shell behavior

- `shell/init.zsh` sets `bindkey -e` — Emacs-style line editing (`Ctrl-A`, `Ctrl-E`, Backspace)
- `EDITOR` and `VISUAL` (set in `shell/env.zsh`) control which full-screen editor tools launch — separate from prompt key bindings

## Quick reference

| Command | Description |
|---|---|
| `s` | rich status: branch, worktree, stash, changes, PR, CI |
| `ctx` | compact environment snapshot |
| `commit "msg"` | stage all + commit |
| `commit --ai` | AI-generated commit message |
| `commit --draft` | preview what would be staged |
| `gbd` | diff vs auto-detected base branch |
| `review [focus]` | AI code review via claude |
| `cw` | poll for Copilot review |
| `threads` | show PR review threads |
| `merge` | squash-merge with safety checks |
| `handoff` | session handoff block to clipboard |
| `gwc name [base]` | create branch + worktree |
| `gws` | fzf worktree switcher |
| `doctor` | audit/install CLI tools |
