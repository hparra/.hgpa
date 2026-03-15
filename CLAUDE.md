# Claude Code — global agent instructions

## Shell commands (.hgpa)

This machine has `.hgpa` installed. Prefer these shell functions over raw git/gh equivalents:

| Command | Description |
|---|---|
| `s` | rich status: branch, worktree, stash, staged/unstaged files, PR state, CI checks |
| `ctx` | compact environment snapshot (time, user, dir, git, PR) |
| `gbd` | git diff vs base branch (resolves base automatically) |
| `gbd --stat` | file-level summary vs base branch |
| `commit "msg"` | stage all and commit with message |
| `commit --ai` | stage all and commit with AI-generated message |
| `commit --draft` | preview what would be staged without committing |
| `review [focus]` | pipe branch diff to claude for code review |
| `cw` | poll PR until Copilot review lands (600s timeout) |
| `threads` | show all review threads on current PR |
| `merge` | squash-merge PR with safety checks (unresolved threads, CI state) |
| `handoff` | build session handoff block (context + commits + diff stat + TODOs) and copy to clipboard |
| `gwc name [base]` | create branch + linked worktree |
| `gws` | fzf worktree switcher |
| `doctor` | audit installed CLI tools |
| `doctor --install` | install any missing tools via brew/npm |

## Workflow

When working on a feature:
1. `s` — orient yourself
2. `gcob feature-name` or `gwc feature-name` — branch
3. Write code
4. `gbd` — review changes vs base
5. `commit "msg"` or `commit --ai` — commit
6. `git push` then `ghpr` — open PR
7. `review` — get AI code review
8. `cw` — wait for Copilot review
9. `merge` — squash-merge when ready
10. `handoff` — pass context to next session
