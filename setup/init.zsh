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
command -v node >/dev/null 2>&1 || nvm install --lts

"$root/apps.zsh"
"$root/macos.zsh"
