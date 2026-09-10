# .claude/agents/ — DO NOT add agent files here

Agent files live in `.github/agents/` (canonical source).

VS Code Copilot discovers agent frontmatter in ALL `.md` files across the
workspace — having copies here creates duplicate entries in the agent dropdown.

If you use Claude Code CLI and need agents, configure it to read from
`.github/agents/` directly.
