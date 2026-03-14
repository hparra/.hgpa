# .hgpa

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

## Commands

- `status` (`s`) is the primary re-entry command: repo, branch, worktree, local changes, and PR status
- `copilotwait` (`cw`) polls the current PR until a Copilot review/comment appears or a timeout is reached
- `context` (`ctx`) prints a compact environment snapshot for agents or handoff-style metadata
- `commit` (`c`) stages all repo changes and commits either from arguments or stdin

## Git shortcuts

- `gss` runs `git status --short`
- `gds` runs `git diff --stat`
- `commit "message"` stages all changes and commits with `-m "message"`
- `echo "message" | commit` stages all changes and reads the commit message from stdin
- `commit < message.txt` stages all changes and reads the commit message from a file via stdin

## Shortcuts

## Workflows

```sh
# return to a terminal and understand what this checkout is
s

# compact metadata snapshot for agent/handoff context
ctx

# quick git summaries
gss
gds

# commit with an inline message
commit "fix shell aliases"

# commit from stdin
echo "fix shell aliases" | commit

# wait for Copilot review output on the current PR
cw

# inspect tool/app install state
./setup/cli.zsh
./setup/apps.zsh

# apply macOS defaults
./setup/macos.zsh

# run the full setup flow
./setup/init.zsh
```
