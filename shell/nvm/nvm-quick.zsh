# nvm-quick.zsh - lightweight node version shim for non-interactive shells
#
# Agents (Claude Code, Codex, Gemini CLI) only source ~/.zshenv, not ~/.zshrc,
# so nvm is never loaded and `node` resolves to the wrong version when a repo
# has a .nvmrc.
#
# Add to ~/.zshenv:
#   export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
#   [[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
#   [[ -s "$HOME/.hgpa/shell/nvm/nvm-quick.zsh" ]] && . "$HOME/.hgpa/shell/nvm/nvm-quick.zsh"

NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

_hgpa_ensure_node() {
  [[ -r ".nvmrc" ]] || return 0
  local wanted
  wanted=$(< .nvmrc)
  wanted="${wanted#v}"; wanted="${wanted%%[[:space:]]*}"
  local current
  current="$(command node --version 2>/dev/null)"; current="${current#v}"
  if [[ "$current" == "$wanted"* ]]; then
    return 0
  fi
  echo "Node $current does not satisfy .nvmrc ($wanted), running nvm use…" >&2
  nvm use >&2
}

node() { _hgpa_ensure_node && command node "$@"; }
npm()  { _hgpa_ensure_node && command npm  "$@"; }
npx()  { _hgpa_ensure_node && command npx  "$@"; }
