# AI Agent Architecture — dbt-datavault

## How to Use

Select **"DV Pipeline Coordinator"** from the VS Code Copilot agent dropdown.
This is the entry point. It parses your request, confirms parameters, then
dispatches worker agents (Source Analyzer → Model Generator → Validator) via
subagent calls. The Coordinator stays in control and presents results at each
approval gate.

Do NOT use generic "Agent" mode or "Auto" model selection.

## Architecture: Coordinator + Worker Subagents

The Coordinator dispatches specialized worker agents via the `agent` tool. Each
worker runs its phase autonomously and returns results to the Coordinator,
which presents them to the user at STOP gates. Handoff buttons provide a
fallback mechanism for direct-invocation workflows. The orchestrator on disk
enforces step ordering as a second safety layer.

```
User selects: "DV Pipeline Coordinator"
  │
  ├── Phase 0: Coordinator parses + confirms parameters
  │
  ├── Phase 1: dispatch Source Analyzer (init + profile + show-profile)
  │   🛑 STOP — User reviews profile
  │
  ├── Phase 1.5 (optional): dispatch Knowledge Advisor (conceptual design review)
  │   STOP — User reviews modeling findings, decides whether to adjust
  │
  ├── Phase 2: dispatch Model Generator (approve-profile + yaml + xlsx)
  │   🛑 STOP — User reviews XLSX + Raw Vault design decision
  │
  ├── Phase 3: dispatch Model Generator (approve-xlsx + code gen + show-code)
  │   🛑 STOP — User reviews generated SQL/YAML
  │
  └── Phase 4: dispatch Validator (approve-code + implement --domain)
      Reports build results (PASS/ERROR counts)
```

## Agents

| Agent | Role | Model | Dispatch Via |
|-------|------|-------|--------------|
| DV Pipeline Coordinator | Parse params + orchestrate | Sonnet 4.6 | User selects from dropdown |
| DV Source Analyzer | init + profile + show-profile | Sonnet 4.6 | `agent` tool from Coordinator |
| DV Model Generator | YAML/XLSX/code generation | Sonnet 4.6 | `agent` tool from Coordinator |
| DV Validator | approve-code + implement | Haiku 4.5 | `agent` tool from Coordinator |
| DV Knowledge Advisor | Conceptual modeling: explain / advise / review (read-only) | Sonnet 4.6 | Dropdown, or `agent` tool from Coordinator (Phase 1.5) |

## Key Principles

- **Coordinator stays in control**: Dispatches workers, presents results, manages gates
- **Subagent isolation**: Each worker runs in isolated context (no history leakage)
- **Workers hidden from picker**: `user-invocable: false` — only reachable via Coordinator's `agent` tool
- **Orchestrator enforcement**: `pipeline_orchestrator.py` enforces step ordering on disk
- **No handoff buttons**: Coordinator-driven only — user approves via chat replies, not UI buttons
- **Design decisions**: Agents present choices — never auto-decide
- **Python env**: Always `.venv/bin/python3` (never bare `python3`)
- **Model selection**: The `model:` frontmatter in agent files is **advisory only** — VS Code Copilot uses whichever model the user selects in the dropdown. If precise model control matters, the user must set the dropdown explicitly.

## Files

| File | Purpose |
|------|---------|
| `.github/agents/dv-pipeline-coordinator.agent.md` | Entry point — parses params, dispatches workers |
| `.github/agents/dv-source-analyzer.agent.md` | Worker: init + profiling |
| `.github/agents/dv-model-generator.agent.md` | Worker: YAML/XLSX/code generation |
| `.github/agents/dv-validator.agent.md` | Worker: build + test (end of chain) |
| `.github/agents/dv-knowledge-advisor.agent.md` | Read-only DV 2.x modeling advisor (explain/advise/review) |
| `.github/knowledge/data-vault/` | Canonical DV 2.x modeling knowledge base (the advisor's grounding) |

> **Note**: Agent files live ONLY in `.github/agents/`. Do NOT copy to `.claude/agents/` —
> VS Code Copilot discovers agent frontmatter in all `.md` files and would show duplicates.

## FinOps Note

The Validator agent frontmatter specifies `Haiku 4.5` for cost efficiency, but
VS Code Copilot uses whichever model the user selects in the dropdown at runtime.
For cost-sensitive runs, switch the dropdown to a lighter model before triggering
Phase 4 (Validate). The Validator's tasks (compile + build + test) do not require
a frontier model.

## Skill Loading in Subagent Mode

FBIN custom skills (`.github/skills/`) are NOT loaded when agents run as
subagents via the `agent` tool. This is a VS Code Copilot platform limitation:
skills with `paths:` patterns require file context, which subagents don't inherit.

| Skill | Designed For | Loaded in Subagent? | Impact |
|-------|-------------|--------------------|---------|
| `v-psa-stg-generator` | Model Generator | No | Low — agent frontmatter has all operational instructions |
| `dv-raw-vault-generator` | Model Generator | No | Low — same |
| `dv-tech-design-creator` | Source Analyzer | No | Low — same |
| `dv-code-implementer` | Validator | No | Low — same |
| `dv-code-reviewer` | Code review | No | N/A — runs separately |
| `conventional-commit` | Post-pipeline | No | N/A — user invokes directly |
| `dv-modeling-advisor` | Knowledge Advisor / generators | No | Low — canonical content lives in `.github/knowledge/data-vault/`, read directly |

**Why this is OK**: Agent `.agent.md` files contain all required instructions
(commands, tool restrictions, guardrails, delegation rules). Skills contain
supplementary reference material (checklists, error recovery, pattern libraries)
that enriches the experience but is not required for correct pipeline execution.
Skills DO load when agents are invoked directly from the VS Code dropdown with
matching file context.

## Hook Activation Matrix

| Hook | Claude Code CLI | VS Code Copilot |
|------|-----------------|-----------------|
| `pre_tool_guard.py` (Rules 1-10) | Active | **Active** — fires on every tool call (~36/session) |
| `coordinator_terminal_guard.py` | Disabled (`hooks: {}`) | N/A — superseded by `tools:` frontmatter |
| `post_write_compile_check.sh` | Active | Inert |
| `session_start_digest.sh` | Active | Inert |
| `session_stop_summary.sh` | Active | Inert |

**Enforcement layers** (VS Code Copilot):
1. **Tool restriction** — `tools:` frontmatter controls which tools each agent can call
   (e.g., Coordinator has `tools: ["agent", "read", "search"]` → no terminal/edit access)
2. **Content rules** — `pre_tool_guard.py` fires on every tool call; R1-R10 enforce
   pipeline state prerequisites and anti-shortcut rules regardless of caller identity
3. **Mode** — `FBIN_HOOK_MODE=audit` (default) logs violations; `=enforce` blocks them

**Limitation**: Hook input contains no agent identifier (`session_id` and
`transcript_path` are identical for Coordinator and Workers). Agent-level
tool restriction is handled exclusively by `tools:` frontmatter, not hooks.
