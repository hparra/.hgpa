#!/usr/bin/env zsh

set -e

echo "Core CLIs"

if command -v brew >/dev/null 2>&1; then
  echo "brew: $(brew --version | head -n 1)"
else
  echo "installing brew" >&2
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

if command -v git >/dev/null 2>&1; then
  echo "git: $(git --version)"
else
  echo "installing git" >&2
  brew install git
fi

if command -v gh >/dev/null 2>&1; then
  echo "gh: $(gh --version | head -n 1)"
else
  echo "installing gh" >&2
  brew install gh
fi

if command -v jq >/dev/null 2>&1; then
  echo "jq: $(jq --version)"
else
  echo "installing jq" >&2
  brew install jq
fi

if command -v rg >/dev/null 2>&1; then
  echo "rg: $(rg --version | head -n 1)"
else
  echo "installing ripgrep" >&2
  brew install ripgrep
fi

if command -v fd >/dev/null 2>&1; then
  echo "fd: $(fd --version)"
else
  echo "installing fd" >&2
  brew install fd
fi

if command -v bat >/dev/null 2>&1; then
  echo "bat: $(bat --version)"
else
  echo "installing bat" >&2
  brew install bat
fi

echo
echo "Utility CLIs"

if command -v fzf >/dev/null 2>&1; then
  echo "fzf: $(fzf --version)"
else
  echo "installing fzf" >&2
  brew install fzf
fi

if command -v uv >/dev/null 2>&1; then
  echo "uv: $(uv --version | head -n 1)"
else
  echo "installing uv" >&2
  brew install uv
fi

if command -v tree >/dev/null 2>&1; then
  echo "tree: $(tree --version | head -n 1)"
else
  echo "installing tree" >&2
  brew install tree
fi

if command -v wget >/dev/null 2>&1; then
  echo "wget: $(wget --version | head -n 1)"
else
  echo "installing wget" >&2
  brew install wget
fi

if command -v tmux >/dev/null 2>&1; then
  echo "tmux: $(tmux -V)"
else
  echo "installing tmux" >&2
  brew install tmux
fi

if command -v direnv >/dev/null 2>&1; then
  echo "direnv: $(direnv version)"
else
  echo "installing direnv" >&2
  brew install direnv
fi

echo
echo "Language Tooling"

if command -v nvm >/dev/null 2>&1; then
  echo "nvm: $(nvm --version)"
elif [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  echo "nvm: installed in ~/.nvm"
else
  echo "nvm: missing"
fi

if command -v node >/dev/null 2>&1; then
  echo "node: $(node --version)"
else
  echo "node: missing"
fi

if command -v pyenv >/dev/null 2>&1; then
  echo "pyenv: $(pyenv --version)"
else
  echo "installing pyenv" >&2
  brew install pyenv
fi

if command -v python3 >/dev/null 2>&1; then
  echo "python3: $(python3 --version)"
else
  echo "python3: missing"
fi

echo
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
