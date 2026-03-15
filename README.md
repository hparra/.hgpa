# .hgpa

Personal Zsh automation for day-to-day engineering work.

This repo gives you:
- fast bootstrap for a new machine/session,
- opinionated Git + PR helpers,
- agent-friendly commands for context, reviews, and handoffs,
- plus standard aliases so the common Unix/Git muscle memory still works.

---

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

---

## Layout

- `shell/` environment + bootstrap files sourced into each shell session
- `commands/` aliases/functions for daily work
- `setup/` machine bootstrap scripts
- `docs/` supporting docs

---

## Command model: what is custom vs standard?

### Custom workflow commands (the real value)
These are higher-level commands that combine multiple checks/actions:

- `s` / `status` — enriched repo status: branch/base diff, staged/unstaged/untracked, worktrees, stash, PR state, CI, review threads
- `ctx` / `context` — compact session state for handoff or agent prompts
- `gbd` — diff current branch vs inferred base branch
- `c` / `commit` — stage-all + commit via stdin (`--draft`, `--ai`)
- `review [focus]` — send branch diff to Claude for code review
- `th` / `threads` — print PR review threads with file/line context
- `cw` / `copilotwait` — wait/poll for Copilot review activity on current PR
- `merge` — guarded squash merge (blocks unresolved threads, warns on CI)
- `ho` / `hoff` / `handoff` — generate shareable session handoff block
- `doctor [--install]` — check/install expected CLI dependencies
- `gws` — fuzzy-switch Git worktrees
- `gwc <label> [base]` — create a branch + worktree in one step

### Standard convenience aliases (mostly wrappers)
These are mostly muscle-memory shortcuts around existing commands:

- Git basics: `gss`, `gds`, `gd`, `ga`, `gaa`, `gc`, `gcm`, `gca`, `gcan`, `gp`, `gf`, `gfa`, `gr*`
- GitHub CLI shortcuts: `ghpr*`, `ghrv*`
- Shell quality-of-life: `..`, `...`, `la`, `ll`, `dfh`, `duh`, `ports`

If these disappeared, you could still run the equivalent raw `git`, `gh`, and Unix commands.

---

## Engineering lifecycle workflow

The commands in this repo are enough to run an end-to-end cycle; when something is not specialized, standard Git/GitHub commands cover the rest.

### 0) Bootstrap environment
```sh
doctor
# optionally install what's missing
doctor --install
./setup/apps.zsh
./setup/macos.zsh
```

### 1) Re-enter and understand current state
```sh
s      # deep repo + PR status
ctx    # compact context snapshot
gss    # standard short status
gds    # standard diff stat
```

### 2) Start work
```sh
# create isolated feature workspace
gwc auth-refresh main

# switch between worktrees later
gws
```

### 3) Implement + inspect changes
```sh
# compare branch to inferred base
gbd --stat
gbd

# optionally use regular git tools
gd
git add -p
```

### 4) Commit changes
```sh
# draft what would be staged
commit --draft

# commit with explicit message via stdin
echo "feat: add auth refresh flow" | commit

# or ask AI to draft message (interactive)
commit --ai
```

### 5) Open/update PR and review quality
```sh
# use normal gh flow for PR creation/edit
gh pr create
gh pr view

# workflow helpers
review security           # AI review with focus area
th                        # inspect review threads
cw                        # wait for Copilot feedback
```

### 6) Resolve feedback and verify
```sh
s                          # confirm file + PR + CI state
th                         # ensure unresolved thread count is zero
gbd --name-only            # verify exact delta
```

### 7) Merge and close
```sh
merge
```

### 8) Handoff / async collaboration
```sh
handoff
```

---

## What's missing (by design) and covered by standard commands

This toolkit is strong on **status visibility, branch diffing, commit ergonomics, PR threading, and handoff**. It intentionally does **not** fully replace these parts of the lifecycle:

1. **Project-specific test/build/deploy commands**
   - Missing generic wrappers is good here; each repo has different commands.
   - Use normal commands like `npm test`, `pnpm test`, `pytest`, `go test ./...`, `make test`, CI pipelines.

2. **PR creation and metadata management abstraction**
   - You still use `gh pr create/edit/view` directly.
   - This keeps PR templates, labels, assignees, and org-specific workflows explicit.

3. **Issue tracking integration (Jira/Linear/GitHub Issues)**
   - No custom issue commands here.
   - Use native tools/APIs (`gh issue ...`, Jira CLI, Linear CLI/web UI).

4. **Release/versioning orchestration**
   - No release helper command currently.
   - Use `gh release create`, changelog tooling, and your repo’s release scripts.

5. **Environment/runtime orchestration per project**
   - No universal `dev up/down` command for containers/services.
   - Use project-local scripts (`make dev`, `docker compose up`, etc.).

In short: this repo provides excellent **cross-project shell ergonomics**, while project-specific lifecycle steps remain intentionally standard and explicit.

---

## Agent configuration

These shell commands are available in any interactive session. To make agents aware of them, add this to your global agent configuration files:

- `~/.claude/CLAUDE.md` (Claude Code)
- `~/AGENTS.md` (Codex)

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

## Organizing commands

You do **not** need one file per command.

Practical pattern:

- keep one file per domain (`git`, `dev`, `aliases`, `docker`, `k8s`, etc.)
- group tiny aliases together in shared files
- keep larger shell functions in domain files, with a short header comment per function
- split to one-command-per-file only when a function becomes long, has tests/docs, or has collaborators

`shell/init.zsh` autoloads everything under `commands/**/*.zsh`, so the strategy is simple:

1. create a domain file in `commands/`
2. add aliases/functions there
3. reload shell (`source ~/.hgpa/shell/init.zsh`) or restart terminal

If load order matters, use filename prefixes (for example `00-core.zsh`, `10-git.zsh`, `20-dev.zsh`).
