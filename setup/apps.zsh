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

if [[ -d "/Applications/Ghostty.app" || -d "$HOME/Applications/Ghostty.app" ]]; then
  echo "ghostty: installed"
  if ! command -v ghostty >/dev/null 2>&1; then
    echo "ghostty cli: missing"
  fi
else
  echo "installing ghostty" >&2
  brew install --cask ghostty
fi

if [[ -d "/Applications/Handy.app" || -d "$HOME/Applications/Handy.app" ]]; then
  echo "handy: installed"
else
  echo "installing handy" >&2
  brew install --cask handy
fi

if [[ -d "/Applications/Zed.app" || -d "$HOME/Applications/Zed.app" ]]; then
  echo "zed: installed"
  if ! command -v zed >/dev/null 2>&1; then
    echo "zed cli: missing"
  fi
else
  echo "installing zed" >&2
  brew install --cask zed
fi

if [[ -d "/Applications/Slack.app" || -d "$HOME/Applications/Slack.app" ]]; then
  echo "slack: installed"
else
  echo "installing slack" >&2
  brew install --cask slack
fi

if [[ -d "/Applications/Spotify.app" || -d "$HOME/Applications/Spotify.app" ]]; then
  echo "spotify: installed"
else
  echo "installing spotify" >&2
  brew install --cask spotify
fi
