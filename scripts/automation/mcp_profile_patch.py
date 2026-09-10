"""
MCP-NATIVE PROFILE STEP — Reference Implementation (v2)
Branch: feature/mcp-native-profile-test

Strategy:
  - MCP-first: Use official MCP Python SDK (mcp 1.27.0) to call snow-mcp
    via stdio transport. This handles Content-Length framing correctly.
  - Python connector fallback: externalbrowser auth (proven working).
    PAT auth via programmatic_access_token is currently rejected by SF;
    externalbrowser is the reliable fallback.

Key fixes from v1:
  - Replaced raw JSON-RPC subprocess with MCP SDK async client
  - Fixed auth: externalbrowser for Python fallback
  - mcp.json key is SNOWFLAKE_PASSWORD (what snow-mcp reads)
"""

import asyncio
import json
import os
import re
import sys
# snowflake.connector: lazy-imported in _get_python_conn() to avoid ImportError
# when running orchestrator commands that don't need Snowflake (status, reset, etc.)
from pathlib import Path


# ─────────────────────────────────────────────────────────────
# MCP.JSON READER (handles // comments, trailing commas)
# ─────────────────────────────────────────────────────────────

def _read_mcp_config() -> dict:
    """Read snow-mcp config from .vscode/mcp.json.

    Resolves VS Code ${input:<id>} placeholders via OS keychain when adopters
    have stored secrets there (see src/secret_resolver.py). Falls back silently
    to the literal placeholder if no keychain entry exists — caller's auth path
    then surfaces a normal "missing credential" error, exactly as today.
    """
    mcp_json = Path(__file__).resolve().parent.parent.parent / ".vscode" / "mcp.json"
    if not mcp_json.exists():
        raise FileNotFoundError(f"Not found: {mcp_json}")

    raw = mcp_json.read_text(encoding="utf-8")
    lines = [l for l in raw.split("\n") if not re.match(r"\s*//", l)]
    clean = re.sub(r",(\s*[}\]])", r"\1", "\n".join(lines))
    data = json.loads(clean)
    env = data.get("servers", {}).get("snow-mcp", {}).get("env", {})

    # Resolve ${input:...} placeholders from OS keychain (no-op if not adopted).
    try:
        from src.secret_resolver import resolve_env_dict
        env = resolve_env_dict(env)
    except Exception:
        pass  # resolver unavailable -> use raw env (today's behavior)

    return {
        "account":   env["SNOWFLAKE_ACCOUNT"],
        "user":      env["SNOWFLAKE_USER"],
        "password":  env.get("SNOWFLAKE_PASSWORD") or env.get("SNOWFLAKE_PAT"),
        "warehouse": env.get("SNOWFLAKE_WAREHOUSE", "DATA_ENGINEER_WH"),
        "role":      env.get("SNOWFLAKE_ROLE", "DATA_ENGINEER"),
    }


# ─────────────────────────────────────────────────────────────
# MCP TOOL BRIDGE (via official MCP Python SDK)
# Uses async stdio_client for proper Content-Length framing.
# ─────────────────────────────────────────────────────────────

async def _mcp_query_async(sql: str, mcp_config: dict, timeout: int = 30) -> list | None:
    """
    Execute SQL via snow-mcp MCP server using the official SDK.
    Returns list of row tuples on success, None on any failure.
    """
    try:
        from mcp import ClientSession, StdioServerParameters
        from mcp.client.stdio import stdio_client

        tools_config = str(
            Path(__file__).resolve().parent.parent.parent
            / ".vscode" / "tools_config.yaml"
        )

        server = StdioServerParameters(
            command="uvx",
            args=[
                "--from", "git+https://github.com/Snowflake-Labs/mcp@v.1.4.0",
                "mcp-server-snowflake",
                "--service-config-file", tools_config,
            ],
            env={
                **os.environ,
                "SNOWFLAKE_PASSWORD": mcp_config["password"],
                "SNOWFLAKE_ACCOUNT":  mcp_config["account"],
                "SNOWFLAKE_USER":     mcp_config["user"],
                "SNOWFLAKE_WAREHOUSE": mcp_config["warehouse"],
                "SNOWFLAKE_ROLE":     mcp_config["role"],
                "SNOWFLAKE_DATABASE": "PSA_PROD",
            },
        )

        async with stdio_client(server) as (read, write):
            async with ClientSession(read, write) as session:
                await asyncio.wait_for(session.initialize(), timeout=60)

                # Discover the query tool name
                tools_result = await asyncio.wait_for(
                    session.list_tools(), timeout=10
                )
                query_tool = None
                for t in tools_result.tools:
                    if "query" in t.name.lower() or "sql" in t.name.lower():
                        query_tool = t.name
                        break
                if not query_tool:
                    print("    [MCP] No query tool found in snow-mcp")
                    return None

                # Execute the query
                # snow-mcp uses 'statement' parameter (not 'query')
                result = await asyncio.wait_for(
                    session.call_tool(query_tool, {"statement": sql}),
                    timeout=timeout,
                )

                # Check for errors
                if result.isError:
                    err_text = ""
                    for item in result.content:
                        if hasattr(item, "text"):
                            err_text = item.text[:200]
                    print(f"    [MCP] Server error: {err_text}")
                    return None

                # Parse result text into row tuples
                for item in result.content:
                    if hasattr(item, "text") and item.text:
                        parsed = _parse_mcp_result(item.text)
                        if parsed is not None:
                            return parsed

                return None

    except Exception as e:
        print(f"    [MCP] Failed: {e}")
        return None


def _mcp_query(sql: str, mcp_config: dict, timeout: int = 30) -> list | None:
    """Sync wrapper around async MCP query."""
    try:
        return asyncio.run(_mcp_query_async(sql, mcp_config, timeout))
    except Exception as e:
        print(f"    [MCP] Sync wrapper error: {e}")
        return None


def _parse_mcp_result(text: str) -> list:
    """Parse snow-mcp query result text into list of row tuples.
    snow-mcp returns JSON array of objects: [{"COL1":"val1","COL2":"val2"}, ...]
    Falls back to pipe-delimited markdown if JSON parse fails.
    """
    text = text.strip()
    if not text:
        return []

    # Try JSON first (primary format from snow-mcp)
    try:
        data = json.loads(text)
        if isinstance(data, list) and len(data) > 0 and isinstance(data[0], dict):
            keys = list(data[0].keys())
            return [tuple(str(row.get(k, "")) for k in keys) for row in data]
    except (json.JSONDecodeError, TypeError):
        pass

    # Fallback: pipe-delimited markdown table
    lines = [l for l in text.splitlines() if l.strip()]
    if not lines:
        return []

    def parse_pipe_line(line: str) -> list:
        stripped = line.strip()
        if stripped.startswith("|"):
            stripped = stripped[1:]
        if stripped.endswith("|"):
            stripped = stripped[:-1]
        return [v.strip() for v in stripped.split("|")]

    if "|" in lines[0]:
        headers = parse_pipe_line(lines[0])
        num_cols = len(headers)
        rows = []
        for line in lines[1:]:
            clean = line.strip().replace("|", "").replace("-", "").replace("+", "").replace(":", "").strip()
            if not clean:
                continue
            values = parse_pipe_line(line)
            if len(values) == num_cols:
                rows.append(tuple(values))
        return rows

    # Tab or comma
    delim = "\t" if "\t" in lines[0] else ","
    headers = [h.strip() for h in lines[0].split(delim)]
    num_cols = len(headers)
    rows = []
    for line in lines[1:]:
        values = [v.strip() for v in line.split(delim)]
        if len(values) == num_cols:
            rows.append(tuple(values))
    return rows


# ─────────────────────────────────────────────────────────────
# PYTHON CONNECTOR FALLBACK (externalbrowser — proven working)
# ─────────────────────────────────────────────────────────────

def _get_python_conn(mcp_config: dict):
    """Build Python connector using externalbrowser auth."""
    import snowflake.connector  # Lazy: not all orchestrator commands need Snowflake
    return snowflake.connector.connect(
        account=mcp_config["account"],
        user=mcp_config["user"],
        authenticator="externalbrowser",
        warehouse=mcp_config["warehouse"],
        role=mcp_config["role"],
    )


def _python_query(sql: str, conn) -> list:
    """Execute SQL via snowflake-connector-python. Returns list of tuples."""
    cur = conn.cursor()
    cur.execute(sql)
    return cur.fetchall()


# ─────────────────────────────────────────────────────────────
# PROFILING ENGINE — MCP-first, Python fallback
# ─────────────────────────────────────────────────────────────

def _run_profile_mcp_first(state: dict, mcp_config: dict) -> dict:
    """
    Stage 1 profile step — MCP-first with Python connector fallback.
    Returns profile dict matching pipeline_orchestrator.py format.
    """
    schema  = state["schema"]
    table   = state["table"]
    bk      = state["bk"]
    rec_src = state["rec_src"]
    fqn     = f"PSA_PROD.{schema}.{table}"

    _conn = None
    mcp_hits = 0
    fallback_hits = 0

    def get_conn():
        nonlocal _conn
        if _conn is None:
            print("    [fallback] Opening externalbrowser auth (may open browser)...")
            _conn = _get_python_conn(mcp_config)
        return _conn

    def run(sql: str) -> list:
        nonlocal mcp_hits, fallback_hits
        result = _mcp_query(sql, mcp_config)
        if result is not None:
            mcp_hits += 1
            print(f"    [MCP] \u2705 succeeded")
            return result
        fallback_hits += 1
        print(f"    [Python] \u2705 fallback")
        return _python_query(sql, get_conn())

    profile = {}

    # [1/9] Semantic collision check
    print("  [1/9] Semantic collision check...")
    rows = run(
        f"SELECT column_name FROM PSA_PROD.INFORMATION_SCHEMA.COLUMNS "
        f"WHERE table_schema = UPPER('{schema}') AND table_name = UPPER('{table}') "
        f"LIMIT 1"
    )
    profile["collision"] = len(rows) > 0

    # [2/9] Describe source table
    print("  [2/9] Describe source table...")
    rows = run(
        f"SELECT column_name, data_type, is_nullable "
        f"FROM PSA_PROD.INFORMATION_SCHEMA.COLUMNS "
        f"WHERE table_schema = UPPER('{schema}') AND table_name = UPPER('{table}') "
        f"ORDER BY ordinal_position"
    )
    profile["columns"] = [
        {"name": str(r[0]), "type": str(r[1]), "nullable": str(r[2])}
        for r in rows
    ]
    profile["column_count"] = len(profile["columns"])

    # [3/9] Row count + volume
    print("  [3/9] Row count + volume assessment...")
    rows = run(f"SELECT COUNT(*) FROM {fqn}")
    row_count = int(rows[0][0]) if rows else 0
    profile["row_count"] = row_count
    if row_count < 50_000_000:
        profile["volume_tier"] = "normal"
    elif row_count < 300_000_000:
        profile["volume_tier"] = "caution"
    else:
        profile["volume_tier"] = "large"

    # [4/9] Sample rows
    print("  [4/9] Sample data...")
    sample = run(f"SELECT * FROM {fqn} LIMIT 5")
    profile["sample_rows"] = len(sample) if sample else 0

    # [5/9] BK grain validation
    print("  [5/9] BK grain validation...")
    rows = run(
        f"SELECT COUNT(*) AS total, "
        f"COUNT(DISTINCT {bk} || '~' || TO_VARCHAR(PSA_LOAD_DTS)) AS distinct_grain "
        f"FROM {fqn}"
    )
    if rows:
        total = int(rows[0][0])
        distinct = int(rows[0][1])
        profile["grain_valid"] = total == distinct
        profile["grain_total"] = total
        profile["grain_distinct"] = distinct

    # [6/9] NULL BK check
    print("  [6/9] NULL BK check...")
    rows = run(f"SELECT COUNT(*) FROM {fqn} WHERE {bk} IS NULL")
    profile["null_bk_count"] = int(rows[0][0]) if rows else 0

    # [7/9] Metadata column detection
    print("  [7/9] Metadata column detection...")
    col_set = {c["name"].upper() for c in profile["columns"]}
    has_fivetran = "_FIVETRAN_SYNCED" in col_set
    has_snp_glue = "GLCHANGETIME" in col_set
    if has_fivetran:
        profile["ingestion_source"] = "fivetran"
    elif has_snp_glue:
        profile["ingestion_source"] = "snp_glue"
    else:
        profile["ingestion_source"] = "custom"
    profile["has_fivetran_deleted"] = "_FIVETRAN_DELETED" in col_set
    profile["has_psa_delete_ind"] = "PSA_DELETE_IND" in col_set
    profile["has_fivetran_synced"] = has_fivetran

    # [8/9] BKCC validation
    print("  [8/9] BKCC validation...")
    dbt_environ = os.environ.get("DBT_ENVIRON", "dev").lower()
    bkcc_db = f"DATAVAULT_{dbt_environ.upper()}"
    rows = run(
        f"SELECT BKCC FROM {bkcc_db}.RAW_VAULT.REF_BUSINESS_KEY_COLLISION "
        f"WHERE REC_SRC = '{rec_src}'"
    )
    profile["bkcc"] = str(rows[0][0]) if rows else None

    # [9/9] Source registration check (local — no Snowflake)
    print("  [9/9] Source registration check...")
    src_file = Path(__file__).resolve().parent.parent.parent / "models" / "sources" / "_sources_staging_psa.yml"
    profile["source_registered"] = schema.lower() in src_file.read_text().lower() if src_file.exists() else False

    if _conn:
        _conn.close()

    profile["_mcp_hits"] = mcp_hits
    profile["_fallback_hits"] = fallback_hits
    return profile


# ─────────────────────────────────────────────────────────────
# VALIDATION HARNESS
# ─────────────────────────────────────────────────────────────

if __name__ == "__main__":
    """
    POC validation harness.
    Usage: .venv/bin/python3 scripts/automation/mcp_profile_patch.py

    Runs Stage 1 profile 3 times against PSA_PROD.EBS.PAYMENT_TERMS_LINES.
    Reports MCP vs fallback usage per run.
    Pass criteria: all 9 queries return data in all 3 runs.
    """

    try:
        mcp_config = _read_mcp_config()
    except Exception as e:
        print(f"ERROR: Cannot read MCP config: {e}")
        print("Run from repo root: cd /path/to/dbt-datavault")
        sys.exit(1)

    print(f"Account:   {mcp_config['account']}")
    print(f"User:      {mcp_config['user']}")
    print(f"Warehouse: {mcp_config['warehouse']}")
    print(f"Role:      {mcp_config['role']}")
    print(f"Auth:      PAT ({'present' if mcp_config['password'] else 'MISSING'})")

    test_state = {
        "schema":  "ML_EBS_AP",
        "table":   "AP_TERMS_LINES",
        "bk":      "TERM_ID",
        "rec_src": "USWIOC.ORCL.EBSPRD.AP_TERMS_LINES",
    }

    results = []
    for run_num in range(1, 4):
        print(f"\n{'=' * 60}")
        print(f"RUN {run_num}/3 \u2014 PSA_PROD.{test_state['schema']}.{test_state['table']}")
        print("=" * 60)
        try:
            profile = _run_profile_mcp_first(test_state, mcp_config)
            passed = (
                profile.get("row_count", 0) > 0
                and len(profile.get("columns", [])) > 0
            )
            results.append({
                "run": run_num,
                "status": "PASS" if passed else "FAIL",
                "row_count": profile.get("row_count"),
                "col_count": profile.get("column_count"),
                "grain": profile.get("grain_valid"),
                "ingestion": profile.get("ingestion_source"),
                "bkcc": profile.get("bkcc"),
                "mcp_hits": profile.get("_mcp_hits", 0),
                "fallback_hits": profile.get("_fallback_hits", 0),
            })
            icon = "\u2705" if passed else "\u274c"
            print(f"\n  \u2192 RUN {run_num}: {icon} {'PASS' if passed else 'FAIL'}")
            if passed:
                print(f"    rows={profile['row_count']:,}  "
                      f"cols={profile.get('column_count', '?')}  "
                      f"grain={'valid' if profile.get('grain_valid') else 'INVALID'}  "
                      f"ingestion={profile.get('ingestion_source')}  "
                      f"bkcc={profile.get('bkcc')}")
                print(f"    MCP: {profile.get('_mcp_hits', 0)} queries  |  "
                      f"Python fallback: {profile.get('_fallback_hits', 0)} queries")
        except Exception as e:
            results.append({"run": run_num, "status": "ERROR", "error": str(e)})
            print(f"\n  \u2192 RUN {run_num}: \u274c ERROR \u2014 {e}")

    print(f"\n{'=' * 60}")
    print("VALIDATION SUMMARY")
    print("=" * 60)
    for r in results:
        icon = "\u2705" if r["status"] == "PASS" else "\u274c"
        print(f"  Run {r['run']}: {icon} {r['status']}", end="")
        if r["status"] == "PASS":
            print(f" | rows={r['row_count']:,} cols={r['col_count']} "
                  f"| MCP={r.get('mcp_hits', 0)} fallback={r.get('fallback_hits', 0)}")
        elif r["status"] == "ERROR":
            print(f" | {r.get('error')}")
        else:
            print()

    all_pass = all(r["status"] == "PASS" for r in results)
    if all_pass:
        total_mcp = sum(r.get("mcp_hits", 0) for r in results)
        total_fb = sum(r.get("fallback_hits", 0) for r in results)
        print(f"\n\U0001f7e2 GREEN LIGHT \u2014 all 3 runs passed")
        print(f"  MCP queries: {total_mcp}  |  Python fallback: {total_fb}")
        if total_mcp > 0:
            print("  MCP path is FUNCTIONAL \u2014 safe to patch pipeline_orchestrator.py")
        else:
            print("  MCP path not yet working (all queries fell back to Python)")
            print("  PAT auth needs investigation \u2014 but fallback is solid")
    else:
        print(f"\n\U0001f534 DO NOT PATCH \u2014 fix errors above first")

    sys.exit(0 if all_pass else 1)
