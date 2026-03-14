#!/usr/bin/env zsh

set -e

echo "Apps"

if [[ -d "/Applications/Claude.app" || -d "$HOME/Applications/Claude.app" ]]; then
  echo "claude app: installed"
else
  echo "installing claude app" >&2
  brew install --cask claude
fi

if [[ -d "/Applications/Codex.app" || -d "$HOME/Applications/Codex.app" ]]; then
  echo "codex app: installed"
  if ! command -v codex >/dev/null 2>&1; then
    echo "codex app cli: missing (expected via \`codex app\`)"
  fi
else
  echo "installing codex app" >&2
  brew install --cask codex-app
fi

if [[ -d "/Applications/Cursor.app" || -d "$HOME/Applications/Cursor.app" ]]; then
  echo "cursor: installed"
  if ! command -v cursor >/dev/null 2>&1; then
    echo "cursor cli: missing"
  fi
else
  echo "installing cursor" >&2
  brew install --cask cursor
fi

if [[ -d "/Applications/Visual Studio Code.app" || -d "$HOME/Applications/Visual Studio Code.app" ]]; then
  echo "visual-studio-code: installed"
  if ! command -v code >/dev/null 2>&1; then
    echo "visual-studio-code cli: missing"
  fi
else
  echo "installing visual-studio-code" >&2
  brew install --cask visual-studio-code
fi

if [[ -d "/Applications/Antigravity.app" || -d "$HOME/Applications/Antigravity.app" ]]; then
  echo "antigravity: installed"
  if ! command -v agy >/dev/null 2>&1; then
    echo "antigravity cli: missing"
  fi
else
  echo "installing antigravity" >&2
  brew install --cask antigravity
fi
