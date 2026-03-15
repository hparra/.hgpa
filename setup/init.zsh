#!/usr/bin/env zsh

set -e

root="${0:A:h}"

# Load dev utilities (provides doctor --install, replacing cli.zsh)
source "$root/../commands/dev.zsh"

# Install missing CLI tools
doctor --install

# Re-source nvm in case it was just installed, then install node if needed
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
if command -v nvm >/dev/null 2>&1; then
  command -v node >/dev/null 2>&1 || nvm install --lts
else
  echo "nvm not available; skipping node install. Source nvm and rerun, or install node manually." >&2
fi

"$root/apps.zsh"
"$root/macos.zsh"

# Symlink .hgpa into ~/.claude so agents and commands are available in all repos
mkdir -p ~/.claude
ln -sf ~/.hgpa/CLAUDE.md       ~/.claude/CLAUDE.md
ln -sf ~/.hgpa/agents          ~/.claude/agents
ln -sf ~/.hgpa/claude-commands ~/.claude/commands
