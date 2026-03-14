# .hgpa

## Usage

Place `.hgpa` in HOME directory.

Add the following to shell file, e.g. [~/.zshrc](../.zshrc):

    source .hgpa/shell/init.zsh

## Layout

- `shell/` contains environment and bootstrap files that are sourced into the shell session
- `commands/` contains command-oriented aliases and functions

Alternatively, you can source individual files.

## Commands

- `status` (`s`) is the primary re-entry command: repo, branch, worktree, local changes, and PR status
- `copilotwait` (`cw`) polls the current PR until a Copilot review/comment appears or a timeout is reached
- `context` (`ctx`) prints a compact environment snapshot for agents or handoff-style metadata

## Shortcuts

## Workflows

```sh
# return to a terminal and understand what this checkout is
s

# compact metadata snapshot for agent/handoff context
ctx

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
