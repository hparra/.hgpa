#!/usr/bin/env zsh

set -e

echo "Agent CLIs"

if command -v claude >/dev/null 2>&1; then
  echo "claude: $(claude --version 2>/dev/null | head -n 1)"
else
  echo "installing claude" >&2
  npm install -g @anthropic-ai/claude-code
fi

if command -v codex >/dev/null 2>&1; then
  echo "codex: $(codex --version 2>/dev/null | tail -n 1)"
else
  echo "installing codex" >&2
  npm install -g @openai/codex
fi

if command -v gemini >/dev/null 2>&1; then
  echo "gemini: $(npm ls -g --depth=0 @google/gemini-cli 2>/dev/null | sed -n 's/.*@google\/gemini-cli@\([^ ]*\).*/\1/p' | tail -n 1)"
else
  echo "installing gemini" >&2
  npm install -g @google/gemini-cli
fi

if command -v copilot >/dev/null 2>&1; then
  echo "copilot: $(brew list --cask --versions copilot-cli 2>/dev/null | sed 's/^copilot-cli //')"
else
  echo "installing copilot" >&2
  npm install -g @github/copilot
fi

if command -v agent >/dev/null 2>&1; then
  echo "agent: $(agent --version 2>/dev/null | head -n 1)"
else
  echo "installing agent" >&2
  curl https://cursor.com/install -fsS | bash
fi
