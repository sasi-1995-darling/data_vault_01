# Setup Guide: DV Pipeline Coordinator

Sections A–H for new developers and onboarding.

---

## A. VS Code Prerequisites

### Required Extensions
Install all recommended extensions via the workspace prompt, or manually:

| Extension | ID | Purpose |
|-----------|----|---------|
| dbt Power User | `innoverio.vscode-dbt-power-user` | dbt Fusion integration |
| dbt Formatter | `henriblancke.vscode-dbt-formatter` | SQL formatting |
| Prettier | `esbenp.prettier-vscode` | YAML formatting |
| GitHub Copilot | `github.copilot` | AI completion |
| GitHub Copilot Chat | `github.copilot-chat` | Agent system |
| SQLFluff | `dorzey.vscode-sqlfluff` | SQL linting |
| Python | `ms-python.python` | Python tooling |
| Pylance | `ms-python.vscode-pylance` | Python type checking |

### VS Code Settings (Auto-Applied)
The repo ships `.vscode/settings.json` with:
- dbt Fusion mode enabled
- Copilot agent/subagent features enabled
- `chat.customAgentInSubagent.enabled: true` (critical for pipeline)
- `chat.subagents.allowInvocationsFromSubagents: true`
- SQLFluff configured with `.venv/bin/sqlfluff`

These settings are committed to the repo — no manual configuration needed.

---

## B. Repository Setup

```bash
# 1. Clone the repo
git clone https://github.com/<org>/dbt-datavault.git
cd dbt-datavault

# 2. Create Python virtual environment
python3 -m venv .venv
source .venv/bin/activate

# 3. Install automation dependencies (runtime set — includes the Snowflake driver
#    the orchestrator/cron uses at runtime; it layers onto requirements.txt via -r)
.venv/bin/python3 -m pip install -r scripts/automation/requirements-runtime.txt

# 4. Verify installation
.venv/bin/python3 scripts/automation/pipeline_orchestrator.py --help

# 4.5. Activate the entry-7 enforcement git hook (per-clone, one-time)
# This sets core.hooksPath to the version-controlled hook directory
# so the artifact-ship + score-update same-commit rule fires on
# `git commit`. See docs/triage-agent/lessons-learned.md entry 7 and
# sprint-1-deferred.md #21 closure for the rule and its honor-system
# bypass contract.
git config core.hooksPath scripts/automation/hooks/git
# Verify: should print "scripts/automation/hooks/git"
git config --get core.hooksPath

# 5. Verify Snowflake connectivity (requires PAT or credentials)
# Option A: Set environment variables
export SNOWFLAKE_ACCOUNT="your_account"
export SNOWFLAKE_USER="your_user"
export SNOWFLAKE_PAT="your_pat_token"

# Option B: Configure .vscode/mcp.json (gitignored, local only)
# Copy from a teammate's setup — contains snow-mcp server config

# Option C (recommended on macOS): Store secrets in OS Keychain — see below
```

### Option C — macOS Keychain (recommended for shared mcp.json)

`.vscode/mcp.json` is git-ignored — each developer creates their own copy
(typically from the template at `scripts/automation/mcp.example.json` — see
section F. Snowflake MCP Access below). If your local copy uses
`${input:...}` placeholders, VS Code resolves them at chat-server startup.
The orchestrator runs as a separate Python process and can transparently
resolve those same placeholders from the OS Keychain. Adopters store
secrets once; no plaintext on disk, no env-var exports.

```bash
# One-time setup (run for each secret you use)
security add-generic-password -s fbin-snowflake -a pat   -w 'YOUR_PAT'         -U
security add-generic-password -s fbin-github    -a pat   -w 'YOUR_GH_TOKEN'    -U
security add-generic-password -s fbin-dbt-cloud -a token -w 'YOUR_DBT_TOKEN'   -U

# Verify the orchestrator can read it
.venv/bin/python3 -c "import sys; sys.path.insert(0,'scripts/automation/src'); \
  from secret_resolver import resolve_placeholder; \
  v = resolve_placeholder('\${input:snowflake_password}'); \
  print('OK' if v and not v.startswith('\${') else 'NOT FOUND — re-run security add-generic-password')"
```

The mapping from `${input:<id>}` to `(keychain_service, keychain_account)` lives
in [scripts/automation/src/secret_resolver.py](scripts/automation/src/secret_resolver.py).
Non-adopters and non-macOS users see zero behavior change.

### dbt Cloud CLI Setup
```bash
# Install dbt Cloud CLI (v0.40+)
brew tap dbt-labs/dbt-cli
brew install dbt

# Authenticate
dbt auth login

# Verify
dbt --version
```

---

## C. Agent Installation & Verification

### Verify Agents Are Discoverable
1. Open VS Code in the `dbt-datavault` workspace
2. Open Copilot Chat (Cmd+Shift+I)
3. Click the agent dropdown (top of chat panel)
4. Verify these agents appear:
   - **DV Pipeline Coordinator** ← entry point
   - DV Source Analyzer
   - DV Model Generator
   - DV Validator
   - DV Knowledge Advisor ← read-only DV 2.x modeling advisor (Phase 1.5; also usable standalone)

If agents don't appear:
- Check that `.github/agents/*.agent.md` files exist
- Ensure `chat.agent.enabled: true` in settings
- Restart VS Code (agents are discovered at startup)

### Verify Subagent Dispatch
The Coordinator dispatches work via `runSubagent`. This requires:
- `chat.customAgentInSubagent.enabled: true` (in settings.json)
- `chat.subagents.allowInvocationsFromSubagents: true` (in settings.json)

Both are pre-configured in the committed `.vscode/settings.json`.

---

## D. Pipeline Walkthrough (Happy Path)

### Step 1: Select the Coordinator
Click the agent dropdown → select **"DV Pipeline Coordinator"**

### Step 2: Provide Your Request
Example prompt:
```
Create v_psa_stg for schema SHOPIFY_MOEN, table SUBSCRIPTION.
BK: TERM_ID::TEXT as SUBSCRIPTION_BK
HK: SUBSCRIPTION_HK : TERM_ID, BKCC
REC_SRC: USOHNO.SHOPIFY.MOEN_PRIVE.SUBSCRIPTION
Model name: v_psa_stg_subscription__moen_prive
```

### Step 3: Phase 0 — Coordinator Confirms Parameters
The Coordinator will parse your request, present a summary table, and ask you to confirm:
- Model name
- BK definition
- HK definitions
- REC_SRC
- Domain folder

### Step 4: Phase 1 — Source Profiling
Coordinator dispatches **DV Source Analyzer** which runs:
1. `pipeline_orchestrator.py init ...`
2. `pipeline_orchestrator.py profile`
3. `pipeline_orchestrator.py show-profile`

**⛔ STOP**: You review the profile (columns, NULLs, volume, BK uniqueness, BKCC).

### Step 4.5: Phase 1.5 — Conceptual Design Review (optional)
Before any code is generated, the Coordinator **offers** a read-only design review by the
**DV Knowledge Advisor**: *"Would you like the DV Knowledge Advisor to review the proposed
construct, grain, and business key before we generate? (yes / skip)"*

- **Skip** → proceed straight to Phase 2 (never blocks the pipeline).
- **Yes** → the Coordinator dispatches the advisor in REVIEW mode. It checks the design
  against `.github/knowledge/data-vault/` — construct choice, grain, business-key validity,
  satellite splits, link modeling, and hash-collision / BKCC traps — and returns findings as
  `FINDING / RISK / OK` with citations. It never edits models or runs dbt.

**⛔ STOP**: You review the findings, then choose: (a) proceed as-is, (b) adjust parameters
and re-run Phase 0/1, or (c) plan Raw Vault objects for Phase 2's Option B. The Coordinator
presents the findings; **you** decide.

### Step 5: Phase 2 — YAML/XLSX Generation
After you approve the profile, Coordinator dispatches **DV Model Generator**:
1. `approve-profile`
2. `generate-yaml`
3. `generate-xlsx`

**⛔ STOP**: You review XLSX validation (22 single-table checks; 30 total if multi-table) + decide:
- **Option A**: STG-only (just the view)
- **Option B**: Add Raw Vault objects (hub/link/sat)

### Step 6: Phase 3 — Code Generation

Coordinator dispatches Model Generator with your option choice from Step 5:

#### Option A (STG-only) — single dispatch
Coordinator dispatches Model Generator to run:
1. `approve-xlsx`
2. `generate-code --stg-only`
3. `show-code`

Returns generated SQL and YAML.

**⛔ STOP**: You review generated SQL and YAML. Approve to proceed to Phase 4.

#### Option B (Add Raw Vault) — TWO dispatches with a user gate between

**Why two dispatches?** When `add-raw-vault` runs, it surgically resets the
`generate-yaml`, `generate-xlsx`, and `approve-xlsx` steps from pipeline state.
The XLSX must be regenerated with the new hub/link/sat sheets and reviewed
before code generation runs.

**Dispatch 3a** — Coordinator dispatches Model Generator to run:
1. `approve-xlsx` (approves the STG-only XLSX from Step 5)
2. `add-raw-vault --hub-name ... --lnk-name ... --sat-parent-model ...`
   (registers Raw Vault objects, surgically resets state)
3. `generate-yaml` (regenerates YAML with RV objects)
4. `generate-xlsx` (regenerates XLSX — now has 4 model sheets:
   STG + HUB + LNK + SAT, all 22 validation checks re-run)

**⛔ STOP**: You review the **regenerated XLSX** (4 model sheets now,
not just 1). Verify hub/link/sat structure, BKCC composition,
HK references, grain columns. Approve to proceed.

**Dispatch 3b** — Coordinator dispatches Model Generator to run:
1. `approve-xlsx` (approves the regenerated XLSX)
2. `generate-code` (generates SQL/YAML for STG + 3 RV objects)
3. `show-code`

Returns generated SQL and YAML for all 4 models.

**⛔ STOP**: You review generated SQL and YAML for all 4 models
(v_psa_stg, hub_\*, lnk_\*, sat_\*). Approve to proceed to Phase 4.

> **Note:** Option B has **5 STOP gates** total (params → profile → XLSX →
> regenerated XLSX → code), while Option A has **4 STOP gates** (no
> regenerated XLSX gate).

### Step 7: Phase 4 — Implementation
After code approval, Coordinator asks which domain folder, then dispatches **DV Validator**:
1. `approve-code`
2. `implement --domain <folder>`

The `--domain` parameter is validated against path traversal attacks (`re.match(r'^[a-z][a-z0-9_]*$')`).

This places files, registers source, runs `dbt build` (compile + materialize + test in one pass with line-by-line streaming output via `stderr=subprocess.STDOUT`), and validates row counts via Snowflake.

---

## E. Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `ModuleNotFoundError: snowflake` | Using system python | Always use `.venv/bin/python3` |
| `ERROR: Prerequisites not met` | Skipped a STOP gate | Run `pipeline_orchestrator.py status` to see current state |
| Agents not in dropdown | VS Code not discovering `.agent.md` | Restart VS Code; check settings |
| Subagent dispatch fails | Settings not enabled | Verify `chat.customAgentInSubagent.enabled: true` |
| Subagent dispatch shows an **"Allow"** prompt each dispatch | VS Code's client-side tool-confirmation for the `runSubagent`/`agent` tool — a **platform** behavior, not an agent or repo defect. Its appearance changed with a VS Code Copilot update; no repo commit governs it (the subagent settings have been stable since 2026-05-11). | On the popup, use the dropdown → **"Always Allow"** (VS Code remembers it per tool). It cannot be suppressed from the agent `.md` — an agent may not self-authorize its own tool calls. |
| Profile shows "source not on branch" | Normal — step [9/9] | Informational only; `implement` auto-registers |
| dbt build timeout | Large model, slow warehouse | Use `timeout: 600000` (10 min) in terminal calls |
| `BKCC: NOT FOUND` in profile | BKCC not registered in Snowflake | Register via Streamlit app before proceeding |
| "0 rows" after build | First load with no data in PSA | Expected for first-time loads (warning, not error) |
| Validator using expensive model | Frontmatter `model:` is advisory; VS Code uses dropdown | Switch to Haiku 4.5 in dropdown before Phase 4 |
| BK silently reinterpreted | `_extract_raw_col_from_bk` strips non-identifier chars from BK input | If BK contains `$`, `(`, `)`, `;`, `--`, etc., orchestrator extracts the first valid identifier fragment. If resulting column doesn't match intent, correct the input. Warning message is a planned enhancement. |
| `dbt binary not found` | dbt not installed or not on PATH | See dbt Binary Resolution below |

### dbt Binary Resolution

The orchestrator automatically resolves the dbt binary via `_get_dbt_binary()`:
1. `DBT_BINARY` env var (explicit override)
2. First `dbt` on PATH that is NOT inside a `.venv` directory
3. `dbt` — plain fallback

If you see "dbt binary not found", ensure dbt Cloud CLI is installed per the
dbt Cloud CLI Setup section above.

---

## F. Quick Reference for Modelers

### 5-Step Summary

1. Say: **"I need to create a v_psa_stg model for `PSA_PROD.<schema>.<table>`"**
   *(Have ready: BK column name, entity name, REC_SRC value, BKCC)*
2. Answer when prompted: confirm BK column(s) + entity name + domain folder
3. Review XLSX tech spec → say **"approved"**
4. Review generated SQL → say **"proceed"** or **"implement"**
5. Done: Feature branch with model files, tests passing, ready for PR

### Input Required

Before starting, you need:

| Item | Example | Where to find it |
|------|---------|-------------------|
| Source table | `OUTD_OCF_AP.AP_TERMS_LINES` | PSA_PROD schema |
| Business Key (BK) column(s) | `TERM_ID` | Domain knowledge / source system PK |
| BK staging name | `PAYMENT_TERM_BK` | Data Vault naming convention |
| REC_SRC | `USCLOUD.ORCL.OCFPRD.AP_TERMS_LINES` | `Location.System.Application.Table` format |
| BKCC | `Jumping_River` | `REF_BUSINESS_KEY_COLLISION` table |
| Domain folder | `procurement` | `models/int_staging_views/<domain>/` |

### Prerequisites (one-time)

1. **Snowflake MCP**: Add the snow-mcp server to your `.vscode/mcp.json`:
   - Copy from `scripts/automation/mcp.example.json`
   - Add your `SNOWFLAKE_PAT` (generate in Snowflake UI → My Profile)
   - Add your `SNOWFLAKE_USER` (your `@fbwinn.com` email)
   - Restart VS Code
2. **BKCC**: Register in Streamlit app (REC_SRC = `Location.System.Application.Table`)
3. **Pre-commit hook** (recommended):
   ```bash
   cp .github/hooks/pre-commit-skill-sync.sh .git/hooks/pre-commit
   chmod +x .git/hooks/pre-commit
   ```

### Environment Variables

All dbt commands require these env vars:
```bash
export DBT_ENVIRON=dev
export DBT_SOURCE_ENV=prod
export DBT_WAREHOUSE_DEFAULT=SA_DBT_WH
export DBT_WAREHOUSE_STAGING=SA_DBT_WH
export DBT_WAREHOUSE_RAW_VAULT=SA_DBT_WH
export DBT_WAREHOUSE_BUS_VAULT=SA_DBT_WH
export DBT_WAREHOUSE_INFO_MART=SA_DBT_WH
```

### Key Rules

- **Always use `.venv/bin/python3`** — system python does NOT have `snowflake-connector-python`
- **BKCC must be registered** in `REF_BUSINESS_KEY_COLLISION` before `dbt run` — the INNER JOIN returns 0 rows without it
- **PSA_DELETE_IND is data**, not a filter — do NOT add `WHERE psa_delete_ind = 'N'`
- **`_FIVETRAN_DELETED`** is included in HASHDIFF via `has_fivetran_deleted: true` flag
- **HK hash components** in YAML use raw source column names; the orchestrator resolves renames at code gen time
- **Raw source columns are preserved** — when aliased to a BK, include BOTH the original and the alias
- **Do not rename technical columns** — `_FIVETRAN_SYNCED`, `_FIVETRAN_DELETED`, `_FIVETRAN_ID` keep their original names
- **Unique test grain** is `BK + LOAD_DTS`, not `HK + LOAD_DTS`
- **Staging tests** auto-enable when `target.name == 'default'` (local sandbox) — no `--vars` needed

---

## G. Token & Cost Efficiency

Measured from real pipeline sessions (see the Architecture Guide for the full data):
you are **not** wasting tokens structurally — 79% cache hit rate and a deterministic
generator. The one real leak is **cache cold-starts**, where a paused session
reprocesses the whole 90K–110K-token prompt at full price. Two causes, one fixable:

- **Idle at a STOP gate — behavioral, fixable.** The prompt cache goes cold after a few
  idle minutes. If you step away at an approval gate, the resume turn re-pays the entire
  prefix at full price. **Aim to respond within ~3 minutes at gates (warm window *measured*
  to ~3.8–6.5 min; ~3 min sits safely below the proven-warm floor).** The smallest gap that
  went cold was ~6.5 min, so treat anything approaching the window as at-risk. In the measured
  session, 3 of 4 cold-starts were gate idle-time of 7–20 minutes.
- **Long subagent dispatch — structural, not fully fixable.** A subagent running
  Snowflake profiling or `dbt build` can itself exceed the cache window — you cannot
  "respond faster" to that. Fewer, batched dispatches help; a true fix needs a keep-alive
  VS Code doesn't expose yet.

Two more free levers:
- **One Copilot model per session** — switching the Copilot LLM in the dropdown mid-session
  forces a cold start (this is the chat model picker, not a dbt model). Pick your tier at
  session start (e.g., Haiku for a Validate-only session), not mid-flow.
- **Terse tool output** — the orchestrator already summarizes `dbt build` into
  PASS/WARN/ERROR; don't paste raw multi-thousand-line logs into chat.

**Self-check — read your effective cost off any session log (zero dependency, no LLM):**

```bash
bash scripts/automation/cache_hit_check.sh                       # newest session log
bash scripts/automation/cache_hit_check.sh path/to/main.jsonl    # a specific log
```

It prints per-call cache hit%, cold-starts, input:output ratio, and effective input-billed % (input only).

> Effective-cost figures cover **input tokens only** — cache-read ≈ 0.1× (10× cheaper) on cached
> tokens and 1.0× on cold input; output tokens are billed separately (and priced higher), so the
> printed "effective input-billed %" is a prompt-cost proxy, not total cost. It also omits the
> cache-write premium (~1.25×), so within input it slightly understates. "Respond within ~3 min" is
> a safe target, not a hard TTL — the exact warm window is bracketed to ~3.8–6.5 min, not pinned.

---

## H. Reference Links

| Resource | Path |
|----------|------|
| Pipeline coordinator agent | `.github/agents/dv-pipeline-coordinator.agent.md` |
| Prompt templates (copy-paste) | `scripts/automation/PROMPT_GUIDE.md` |
| Stage 1 skill (tech design) | `.github/skills/dv-tech-design-creator/SKILL.md` |
| Stage 3 skill (code implementer) | `.github/skills/dv-code-implementer/SKILL.md` |
| YAML config schema | `.github/skills/v-psa-stg-generator/input-schema.yml` |
| Example configs | `scripts/automation/configs/integration_test/` |
| Lessons learned | `scripts/automation/lessons.md` |
| Project standards | `CLAUDE.md` |
| Agent architecture | `AGENTS.md` |
| Skill sync script | `scripts/sync_skills.sh` |
| XLSX validator | `scripts/automation/validate_tech_spec.py` |

---

*End of setup guide.*
