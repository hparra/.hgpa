# Cursor Agent: ensure node/npm/npx use .nvmrc version before running
# This is a quick hack to ensure cursor agents use the correct node version.
# [[ -n "$CURSOR_AGENT" ]] && . ~/.zshrc.d/nvm-quick.zsh


_cursor_ensure_node() {
  [[ -r ".nvmrc" ]] || return 0
  local wanted=$(< .nvmrc)
  wanted="${wanted#v}"; wanted="${wanted%%[[:space:]]*}"
  local current; current="$(command node --version 2>/dev/null)"; current="${current#v}"
  if [[ "$current" == "$wanted"* ]]; then
    return 0
  fi
  echo "Node $current does not satisfy .nvmrc ($wanted), running nvm use…" >&2
  nvm use >&2
}

node() { _cursor_ensure_node && command node "$@"; }
npm()  { _cursor_ensure_node && command npm "$@"; }
npx()  { _cursor_ensure_node && command npx "$@"; }
