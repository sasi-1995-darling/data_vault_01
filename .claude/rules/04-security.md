---
paths:
  - "scripts/automation/**"
  - ".vscode/mcp.json"
  - ".env*"
---

# Security Rules

## Credential Handling
- AI agents **NEVER** read or display credentials from mcp.json, .env, or any config file
- **NEVER** paste tokens, passwords, or API keys into terminal commands
- **NEVER** use `export SNOWFLAKE_PAT=...` or similar credential exposure in chat
- **NEVER** log or print credential values in automation scripts

## Snowflake Authentication
If Snowflake authentication fails:
1. Tell the user to refresh their PAT via Snowsight
2. Tell the user to update mcp.json manually
3. Suggest using `--profile-json` as a workaround
- AI agents **DO NOT** read or use credentials from config files
- The pipeline orchestrator (Python code) reads `.vscode/mcp.json` for Snowflake connectivity — this is a trusted code path, not an agent action

## Pipeline Security
- Pipeline orchestrator uses `--profile-json` for offline testing (no Snowflake needed)
- MCP connection credentials are in `.vscode/mcp.json` — AI agents **NEVER** read this file
- The `pre_tool_guard.py` hook enforces pipeline steps — do not circumvent it

## Code Security
- No hardcoded credentials in SQL or Python
- No `SELECT *` exposure of sensitive columns without explicit column lists
- Use parameterized queries when constructing dynamic SQL
- Validate all user inputs in pipeline orchestrator commands

## IDE-Attachment Defense (added 2026-06-04 — incident response)

**Background:** The agent-side rules above prevent agent-INITIATED reads of
credential files. They do NOT prevent the VS Code "attach file to context"
UI from sending a file to the chat extension. On 2026-06-04 a cleartext
`.vscode/mcp.json` was attached to a chat session via the IDE UI, bypassing
every agent rule. The agent's discipline held; the surrounding tooling
defeated it. Full post-mortem:
[`docs/triage-agent/security-incident-2026-06-04.md`](../../docs/triage-agent/security-incident-2026-06-04.md).

**Structural rule (replaces all narrative "be careful" guidance):**
Files matching credential-bearing patterns MUST appear in BOTH layers:

| Pattern | `.gitignore` required | `.vscode/settings.json` `files.exclude` + `search.exclude` required |
|---|---|---|
| `.vscode/mcp.json` and `*.bak` siblings | ✅ via `.vscode/*` blanket | ✅ explicit entry |
| `.env`, `.env.*` | ✅ | ✅ |
| `**/.dbt/profiles.yml` | ✅ via `.dbt/` blanket | ✅ |
| `**/*.pem`, `**/*.key` | ✅ | ✅ |
| `**/id_rsa`, `**/id_ed25519` | ✅ | ✅ |
| Any new file containing live secrets | ✅ (REQUIRED before commit) | ✅ (REQUIRED before opening in IDE) |

**Why both layers are required and neither alone is sufficient:**
- `.gitignore` prevents commit to git history — defends against accidental
  push, BFG/`git filter-repo` is the only remediation if violated
- `files.exclude` + `search.exclude` prevent the IDE from listing the file
  in the explorer, quick-open, or chat attachment surfaces — defends
  against accidental UI attachment, no remediation needed if respected
- `.gitignore` does not affect IDE UI; `files.exclude` does not affect git

**Enforcement (current — manual; goal — structural):**
- Manual: before opening a new credential file, add it to both lists.
  Monthly audit recommended (run the migration script's sentinel scan
  pattern against any file matching the table above).
- Sprint-1 deferred item TBD: automated CI gate that fails the build
  if a file matching the table is absent from either layer.

**Credential migration pattern (eliminates cleartext on disk):**
For any new MCP server config or similar:
- Move scalar secrets into VS Code `${input:<id>}` substitution (prompts at
  session start, stored in OS keychain). Reference implementation:
  [`scripts/automation/migrate_mcp_secrets.py`](../../scripts/automation/migrate_mcp_secrets.py)
- Higher-maturity options (1Password CLI `op://`, Azure Key Vault / AWS
  Secrets Manager) are valid future upgrades but not required as the
  baseline. The critical move is "no secret VALUES sit in a file on disk."

**Agent responsibility under this rule:**
- An agent MUST NOT read a file in the table above, even if the user
  attaches it to context — politely decline and remind the user that the
  file is in the credential-bearing list. (Existing rule, restated here
  for explicit IDE-attachment scope.)
- An agent MUST NOT log, echo, or otherwise persist credential values
  observed via attachment — including in commit messages, error reports,
  or post-mortem documents. Document the EXPOSURE EVENT, not the value.
- An agent MUST recommend immediate rotation when credential exposure is
  observed, regardless of attachment vector.
