# Agents

anthropic claude code
- ☁️ https://claude.ai/code
- 🤖 `claude` 📦 `npm install -g @anthropic-ai/claude-code` 📚 https://code.claude.com/docs/en/overview
- 🖥️ `claude` 📦 `brew install --cask claude`
- 📈 https://claude.ai/account/usage

openai codex
- ☁️ https://chatgpt.com/codex
- 🤖 `codex` 📦 `npm install -g @openai/codex` 📚 https://developers.openai.com/codex
- 🖥️ `codex app` 📦 `brew install --cask codex-app`
- 📈 https://chatgpt.com/codex/settings/analytics

google gemini
- ☁️ https://jules.google.com/session
- 🤖 `gemini` 📦 `npm install -g @google/gemini-cli` 📚 https://geminicli.com/
- 🖥️ `antigravity-cli` 📦 brew install --cask antigravity
- 📈 https://aistudio.google.com/

github copilot
- ☁️ https://copilot.github.com/
- 🤖 `copilot` 📦 `npm install -g @github/copilot` 📚 https://docs.github.com/en/copilot
- 🖥️ `code` 📦 `brew install --cask visual-studio-code`
- 📈 https://github.com/settings/copilot/features

anyshpere cursor
- ☁️ https://cursor.com/agents
- 🤖 `agent` 📦 `curl https://cursor.com/install -fsS | bash` 📚 https://cursor.com/docs/
- 🖥️ `cursor` 📦 `brew install --cask cursor`
- 📈 https://cursor.com/dashboard/usage

## Workflows

```sh
# help
claude -h
codex -h
gemini -h
copilot -h
agent -h

# prompt non-interactively
claude --dangerously-skip-permissions -p 'hello!'
codex --full-auto exec 'hello!'
gemini --yolo -p 'hello!'
copilot --yolo -p 'hello!'
agent --yolo -p 'hello!'

# resume the previous session interactively
claude -c
codex resume --last
gemini --resume latest
copilot --continue
agent --continue
```
