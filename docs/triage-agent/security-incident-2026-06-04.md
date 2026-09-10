# Security Incident — Cleartext Secrets in `.vscode/mcp.json`

**Date:** 2026-06-04
**Severity:** Medium (bounded local exposure; zero remote exposure)
**Incident class:** Credential exposure via IDE-attached chat context
**Status:** Mitigated 2026-06-04 (rotation + structural remediation complete)

---

## TL;DR

While processing a Day 4 Phase B request, the VS Code Copilot chat extension
attached `.vscode/mcp.json` to the conversation context via the IDE UI
(not via agent action). The file contained three live cleartext credentials.
The agent flagged the exposure, the user rotated all three tokens, and
the file was migrated to VS Code `${input:...}` substitution so cleartext
never sits on disk again. Repository git history was audited — zero
historical commits of `mcp.json` exist on any branch, so the exposure was
bounded to the chat session storage of a single workstation.

## Timeline

| Time (UTC, approx) | Event |
|---|---|
| ~13:00 | User initiated Day 4 Phase A evidence pull session |
| ~13:30 | Coordinator dispatched curl-direct workaround for failed dbt-mcp wrapper; needed account ID from mcp.json structure |
| ~13:35 | User attached `.vscode/mcp.json` to chat via VS Code "Add Context" UI to provide account ID |
| ~13:36 | Attached file body included 3 cleartext secrets (SNOWFLAKE_PASSWORD JWT line 17, GITHUB_PERSONAL_ACCESS_TOKEN line 32, DBT_TOKEN line 46) |
| ~13:37 | Agent detected credential exposure during structure inspection and raised alert |
| ~13:38 | Agent committed to discarding observed values from working memory; user committed to rotation |
| ~14:00 | User completed Day 4 Phase B + commit `ac2c384c` using EXISTING (now-suspect) DBT_TOKEN |
| ~14:15 | User rotated all 3 tokens (Snowflake → GitHub → dbt Cloud) |
| ~14:20 | Pre-flight audit: `.gitignore` covers `.vscode/mcp.json` (line 162 blanket `.vscode/*`); zero history of commit |
| ~14:25 | Migration script `migrate_mcp_secrets.py` rewrote 3 scalar secrets to `${input:...}`; added `inputs[]` with `password: true` |
| ~14:30 | Cut-over `mv`; old file preserved as `.preinput.bak` (also gitignored); `files.exclude` + `search.exclude` added to `.vscode/settings.json` |
| ~14:35 | New dbt token smoke-tested against 3 Admin v2 endpoints; user deleted `.preinput.bak` |
| ~14:40 | Pattern 2 provenance amended with credential-lineage clarification |

## Blast radius determination

| Exposure vector | Bounded? | Evidence |
|---|---|---|
| Git history (any branch, any commit) | YES — never present | `git log --all --full-history -- .vscode/mcp.json` empty; `git log --all --full-history -- '**/mcp.json' 'mcp.json'` empty; only tracked `mcp.example.json` template + `mcp_profile_patch.py` |
| Remote repo (origin / FBWINN-Data-Analytics) | YES — `.gitignore:162` `.vscode/*` blanket | `git check-ignore -v .vscode/mcp.json` → `.gitignore:162` |
| VS Code chat session storage (local) | NO — exposed | File body attached to chat session; persists in `~/Library/Application Support/Code/User/workspaceStorage/.../GitHub.copilot-chat/` until session cleanup |
| VS Code Copilot telemetry | UNKNOWN — assume exposed | Treat as exposed for severity calculation; depends on Copilot transmit policy |
| Other developer machines | NO — file is per-user, not synced | Each developer's mcp.json is local-only |

**Severity classification: MEDIUM.** Tokens were exposed beyond the user's
machine boundary in the worst case (Copilot telemetry), but never in a
mass-distributed location (repo history, public artifact). Rotation
within minutes of detection bounds the exposure window further.

## Root cause

**Two-layer failure:**

1. **Cleartext credentials on disk** — the file pattern was "scalar string
   inline in JSON," same as the committed template's pattern. The
   `mcp.example.json` template uses `<placeholder>` strings as a soft hint
   but the local file evolved to real values without ever migrating to
   environment variables or VS Code's `${input:...}` substitution.

2. **No IDE-attachment defense** — the agent's `.claude/rules/04-security.md`
   prevents agent-INITIATED reads ("AI agents NEVER read or display
   credentials from mcp.json"). The rule held: the agent did not read the
   file. The VS Code "Add Context" UI is a user-initiated attachment that
   bypasses agent rules entirely. Once a file is in the chat context,
   the agent receives its content as part of the user message, with no
   gating opportunity. There was no `files.exclude` entry to make the file
   invisible to the IDE's file-picker surfaces.

The first layer is necessary but not sufficient; the second layer was
missing entirely.

## What worked

- **Agent detection.** The agent recognized credential shapes in the
  attached file body and raised an alert immediately, before processing
  any further request.
- **Agent restraint.** No tool calls echoed token values; no terminal
  commands embedded credentials. The `04-security.md` rule "NEVER paste
  tokens into terminal commands" held throughout.
- **User response.** Rotation happened within ~30 min of detection across
  all three credentials.
- **`.gitignore` discipline.** The blanket `.vscode/*` rule meant zero
  remote exposure despite the cleartext local state — a much better
  outcome than if `.vscode/mcp.json` had ever been committed.

## What failed

- **`mcp.example.json` template-vs-real-file drift.** Template used
  `<placeholder>` syntax that does not match VS Code's `${input:...}`
  syntax, so following the template's pattern produces a real-secret file.
- **No structural IDE-attachment defense.** `04-security.md` was
  narrative-only ("agents never read"); no machine-checkable equivalent
  prevented the IDE-UI bypass.
- **Day 4 Phase B continued after exposure detection.** The Phase B work
  used `DBT_TOKEN` for curl calls between ~13:38 (exposure) and ~14:15
  (rotation), extending the exposure window for that specific credential.
  Right call would have been to halt Day 4 immediately and resume after
  rotation. (This is a process lesson, not a credential outcome — the
  catalog work in commit `ac2c384c` is architecturally clean and uses
  only Gate-D-validated fields.)

## Remediation (completed 2026-06-04)

1. **Token rotation** — Snowflake PAT, GitHub PAT, dbt Cloud token all
   rotated. Old tokens revoked.
2. **`.gitignore` audit** — confirmed `.vscode/mcp.json` covered, no
   historical commits. No history rewrite required.
3. **`${input:...}` migration** — `migrate_mcp_secrets.py` rewrote all 3
   scalar secrets to placeholders; `inputs[]` array added with
   `password: true` on each. Live `.vscode/mcp.json` reduced from 4,336 B
   (with secrets) to 1,786 B (placeholders only).
4. **IDE-attachment defense** — `.vscode/settings.json` updated with
   `files.exclude` (11 entries) and `search.exclude` (6 entries) covering
   `.vscode/mcp.json` + its `.bak` siblings, `.env*`, `**/.dbt/profiles.yml`,
   `**/*.pem`, `**/*.key`, `**/id_rsa`, `**/id_ed25519`.
5. **`04-security.md` amendment** — "IDE-Attachment Defense" section added
   with the two-layer structural rule, the file-pattern table, and the
   credential-migration pattern. Replaces narrative-only guidance.
6. **Smoke test** — new dbt token validated against 3 Admin v2 endpoints
   (200/200/200); no tokens echoed to chat or shell history.

## Lessons banked

1. **Agent rules cannot defend against IDE-side context attachment.**
   Two-layer defense (`.gitignore` + `files.exclude`) is structural and
   does not depend on agent compliance.
2. **Templates must use the production-syntax placeholder, not a
   readable-hint placeholder.** The `<your_token_here>` pattern reads
   well but does not survive a copy-paste-then-replace workflow. VS Code
   `${input:...}` survives because it is a runtime construct, not a
   textual placeholder.
3. **Exposure detection should trigger immediate work halt for any
   credential in active use.** Continuing Day 4 Phase B with the suspect
   `DBT_TOKEN` extended the exposure window unnecessarily. The catalog
   work was sound, but the token-handling discipline could have been
   tighter.
4. **Provenance includes credential lineage, not just data lineage.**
   Pattern 2 in the catalog is architecturally clean (only Gate-D-validated
   fields) but was discovered using a now-suspect credential. The note
   field documents both the data source AND the credential under which
   it was retrieved, so future readers can re-validate if needed.
5. **Working files for active investigation should live under
   `~/scratch/<topic>/`, not `/tmp/`.** macOS may purge `/tmp` at sleep,
   and credential-pulled payloads should persist long enough to be
   re-validated under a rotated token without re-fetching from the
   upstream API. Sprint-1 follow-up will move `/tmp/triage_day4/` to
   `~/scratch/triage-day4/` and overwrite under the new token.

## Follow-up items (queued)

| # | Item | Owner | Trigger |
|---|---|---|---|
| 1 | Move `/tmp/triage_day4/` → `~/scratch/triage-day4/`, re-pull under new dbt token, overwrite cached files | User | Before Day 3.7 mini-Gate-D |
| 2 | Add `.gitignore` entry for `~/scratch/` (already global by default but document) | Agent | Next session |
| 3 | Update `mcp.example.json` template to use `${input:<id>}` syntax + commit a matched `mcp.settings.example.json` showing the `inputs[]` pattern + `files.exclude` entries | Agent | Next session |
| 4 | Pre-commit hook OR CI gate that scans new commits for credential-shaped strings (length-only allowlist) | Sprint 1 backlog | Sprint 1 planning |
| 5 | Automated CI gate validating that every entry in the credential-pattern table is present in BOTH `.gitignore` AND `.vscode/settings.json` | Sprint 1 backlog | Sprint 1 planning |
| 6 | Verify VS Code Copilot telemetry retention policy for chat session content (escalate to org admin if non-zero retention) | User / IT | This week |

## References

- [`.claude/rules/04-security.md`](../../.claude/rules/04-security.md) — security policy
- [`scripts/automation/migrate_mcp_secrets.py`](../../scripts/automation/migrate_mcp_secrets.py) — migration tool
- [`scripts/automation/configs/fbin_error_catalog.yml`](../../scripts/automation/configs/fbin_error_catalog.yml) — Pattern 2 credential-lineage note
- [`docs/triage-agent/sprint-1-deferred.md`](./sprint-1-deferred.md) — Sprint 1 deferred items
- Pattern 2 commit: `ac2c384c` (stands per gitignore-history-clean audit)
