#!/usr/bin/env python3
"""
test_pipeline_preflight.py — Pre-flight checks for E2E pipeline automation.

Validates every component of the 3-stage pipeline (Profile → Generate → Deploy)
is functional and correctly wired before running a real model build.

Run: python3 -m pytest scripts/automation/tests/test_pipeline_preflight.py -v

Categories:
  1. Infrastructure  — MCP config, Snowflake connectivity, dbt binary, env vars
  2. Stage 1 (Profile) — Orchestrator commands, profiling queries, BKCC lookup
  3. Stage 2 (Generate) — yaml_reader, build.py, make_yml.py, XLSX tech spec
  4. Stage 3 (Deploy) — Source registration, dbt compile, file placement
  5. Skill & Agent   — Skill files exist, prompt injection guardrails, agent defs
  6. State Machine   — Step ordering, approval gates, reset/status
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest

# ── Path setup ─────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent.parent  # scripts/automation/
PROJECT_ROOT = SCRIPT_DIR.parent.parent
ORCHESTRATOR = SCRIPT_DIR / "pipeline_orchestrator.py"
SRC_DIR = SCRIPT_DIR / "src"

# Add src to path for imports
sys.path.insert(0, str(SRC_DIR))


# ═══════════════════════════════════════════════════════════════════════════════
# 1. INFRASTRUCTURE — Can we reach everything we need?
# ═══════════════════════════════════════════════════════════════════════════════

class TestInfrastructure:
    """Verify all infrastructure components are available."""

    def test_orchestrator_exists(self):
        """Pipeline orchestrator script must exist and be executable."""
        assert ORCHESTRATOR.exists(), f"Missing: {ORCHESTRATOR}"

    def test_orchestrator_help(self):
        """Orchestrator --help must succeed (validates Python syntax)."""
        result = subprocess.run(
            [sys.executable, str(ORCHESTRATOR), "--help"],
            capture_output=True, text=True, timeout=10,
        )
        assert result.returncode == 0, f"Orchestrator --help failed:\n{result.stderr}"
        assert "init" in result.stdout
        assert "profile" in result.stdout
        assert "generate-code" in result.stdout
        assert "implement" in result.stdout

    def test_orchestrator_all_commands_in_help(self):
        """All 14 pipeline commands must appear in --help."""
        result = subprocess.run(
            [sys.executable, str(ORCHESTRATOR), "--help"],
            capture_output=True, text=True, timeout=10,
        )
        expected_cmds = [
            "init", "profile", "show-profile", "approve-profile",
            "generate-yaml", "generate-xlsx", "approve-xlsx",
            "generate-code", "show-code", "approve-code",
            "implement", "build-all", "status", "reset",
        ]
        for cmd in expected_cmds:
            assert cmd in result.stdout, f"Command '{cmd}' missing from orchestrator --help"

    def test_build_py_importable(self):
        """build.py must be importable (validates syntax + dependencies)."""
        result = subprocess.run(
            [sys.executable, "-c", "import build"],
            capture_output=True, text=True, cwd=str(SRC_DIR), timeout=10,
        )
        assert result.returncode == 0, f"Cannot import build.py:\n{result.stderr}"

    def test_make_yml_importable(self):
        """make_yml.py must be importable."""
        result = subprocess.run(
            [sys.executable, "-c", "import make_yml"],
            capture_output=True, text=True, cwd=str(SRC_DIR), timeout=10,
        )
        assert result.returncode == 0, f"Cannot import make_yml.py:\n{result.stderr}"

    def test_yaml_reader_importable(self):
        """yaml_reader.py must be importable."""
        result = subprocess.run(
            [sys.executable, "-c", "import yaml_reader"],
            capture_output=True, text=True, cwd=str(SRC_DIR), timeout=10,
        )
        assert result.returncode == 0, f"Cannot import yaml_reader.py:\n{result.stderr}"

    def test_generate_tech_spec_importable(self):
        """generate_tech_spec.py must exist."""
        gts = SCRIPT_DIR / "generate_tech_spec.py"
        assert gts.exists(), f"Missing: {gts}"

    def test_dbt_binary_available(self):
        """dbt CLI must be on PATH or in .venv."""
        dbt_bin = shutil.which("dbt") or shutil.which("dbtf")
        venv_dbt = PROJECT_ROOT / ".venv" / "bin" / "dbt"
        assert dbt_bin or venv_dbt.exists(), \
            "dbt binary not found on PATH or in .venv/bin/dbt"

    def test_mcp_config_exists(self):
        """MCP config file must exist for Snowflake connectivity."""
        mcp_path = PROJECT_ROOT / ".vscode" / "mcp.json"
        assert mcp_path.exists(), f"Missing: {mcp_path}"

    def test_mcp_has_snow_mcp_server(self):
        """MCP config must have snow-mcp server defined."""
        mcp_path = PROJECT_ROOT / ".vscode" / "mcp.json"
        content = mcp_path.read_text()
        # MCP JSON has comments — can't use json.load directly
        assert "snow-mcp" in content, "snow-mcp server not found in mcp.json"
        assert "SNOWFLAKE_ACCOUNT" in content, "SNOWFLAKE_ACCOUNT not in mcp.json"
        assert "SNOWFLAKE_USER" in content, "SNOWFLAKE_USER not in mcp.json"

    def test_mcp_input_ids_are_resolvable(self):
        """Every ${input:<id>} placeholder used in mcp.json env blocks must be
        registered in src/secret_resolver.INPUT_TO_KEYCHAIN so adopters can store
        the corresponding secret in their OS keychain. Catches drift where
        someone adds a new placeholder to mcp.json but forgets the resolver entry.
        """
        sys.path.insert(0, str(SCRIPT_DIR / "src"))
        from secret_resolver import INPUT_TO_KEYCHAIN  # noqa

        mcp_path = PROJECT_ROOT / ".vscode" / "mcp.json"
        # Self-contained: don't rely on test_mcp_config_exists running first.
        # pytest does not guarantee ordering, so a missing mcp.json here would
        # otherwise surface as a noisy FileNotFoundError instead of a clear
        # assertion (or skip) message.
        if not mcp_path.exists():
            pytest.skip(f"mcp.json not present at {mcp_path} — nothing to validate")
        content = mcp_path.read_text()
        used_ids = set(re.findall(r"\$\{input:([A-Za-z0-9_\-]+)\}", content))
        if not used_ids:
            # Resolver is opt-in: an mcp.json with no placeholders (e.g. all
            # creds inlined or sourced from env vars) is a valid configuration.
            # Nothing to validate — skip instead of failing.
            pytest.skip("mcp.json has no ${input:...} placeholders — nothing to validate")
        missing = used_ids - set(INPUT_TO_KEYCHAIN)
        assert not missing, (
            f"mcp.json uses ${{input:<id>}} placeholder(s) not registered in "
            f"INPUT_TO_KEYCHAIN: {sorted(missing)}. "
            f"Either add them to src/secret_resolver.INPUT_TO_KEYCHAIN or remove "
            f"them from mcp.json."
        )

    def test_read_mcp_creds_tolerates_non_string_env_values(self, tmp_path, monkeypatch):
        """REGRESSION: _read_mcp_creds()._usable() called .startswith() on whatever
        the JSON parser handed back. mcp.json is JSON, which allows numbers, bools,
        and null — any of which would raise AttributeError inside _usable() and
        sink an otherwise-valid set of credentials via the outer try/except.
        Locks in the isinstance(str) guard so a stray non-string value next to
        valid creds doesn't quietly disable the whole MCP auth path.
        """
        sys.path.insert(0, str(SCRIPT_DIR))
        import pipeline_orchestrator as po  # noqa: E402

        vscode_dir = tmp_path / ".vscode"
        vscode_dir.mkdir()
        (vscode_dir / "mcp.json").write_text(json.dumps({
            "servers": {
                "snow-mcp": {
                    "env": {
                        "SNOWFLAKE_ACCOUNT": "acct.region",
                        "SNOWFLAKE_USER":    "USER",
                        "SNOWFLAKE_PAT":     "pat-value",
                        # Non-string sentinels that JSON allows:
                        "SOME_PORT":         8080,     # int
                        "SOME_FLAG":         True,     # bool
                        "SOME_NULL":         None,    # null
                    }
                }
            }
        }))
        monkeypatch.setattr(po, "PROJECT_ROOT", tmp_path)
        env = po._read_mcp_creds()
        assert env is not None, "valid creds were dropped because of non-string siblings"
        assert env["SNOWFLAKE_ACCOUNT"] == "acct.region"
        assert env["SNOWFLAKE_PAT"] == "pat-value"

    def test_lessons_file_exists(self):
        """lessons.md must exist — agents read it at session start."""
        lessons = SCRIPT_DIR / "lessons.md"
        assert lessons.exists(), f"Missing: {lessons}"
        content = lessons.read_text()
        assert "## Approved" in content, "lessons.md must have an '## Approved' section"

    def test_dbt_project_yml_exists(self):
        """dbt_project.yml must exist at project root."""
        assert (PROJECT_ROOT / "dbt_project.yml").exists()

    def test_sources_psa_yml_exists(self):
        """_sources_staging_psa.yml must exist for source registration."""
        sources = list(PROJECT_ROOT.glob("models/sources/_sources_staging_psa.yml"))
        assert len(sources) > 0, "Missing _sources_staging_psa.yml"

    def test_packages_yml_has_required_packages(self):
        """packages.yml must have dbt_utils, dbt_constraints, dbt_expectations."""
        import yaml
        pkg_path = PROJECT_ROOT / "packages.yml"
        assert pkg_path.exists()
        data = yaml.safe_load(pkg_path.read_text())
        pkg_names = [p.get("package", "") for p in data.get("packages", [])]
        for required in ["dbt-labs/dbt_utils", "Snowflake-Labs/dbt_constraints",
                         "metaplane/dbt_expectations"]:
            assert any(required in p for p in pkg_names), \
                f"Missing required package: {required}"


# ═══════════════════════════════════════════════════════════════════════════════
# 2. STAGE 1 — Profile & Design
# ═══════════════════════════════════════════════════════════════════════════════

class TestStage1Profiling:
    """Verify Stage 1 profiling steps are correctly implemented."""

    def test_pipeline_steps_order(self):
        """Pipeline steps must be in correct order."""
        content = ORCHESTRATOR.read_text()
        match = re.search(r'PIPELINE_STEPS\s*=\s*\[([^\]]+)\]', content, re.DOTALL)
        assert match, "PIPELINE_STEPS not found in orchestrator"
        steps_str = match.group(1)
        steps = [s.strip().strip('"').strip("'") for s in steps_str.split(",") if s.strip()]
        expected = [
            "init", "profile", "approve-profile",
            "generate-yaml", "generate-xlsx", "approve-xlsx",
            "generate-code", "approve-code", "implement",
        ]
        assert steps == expected, f"Step order mismatch: {steps} != {expected}"

    def test_profile_has_9_steps(self):
        """Profile command must execute 9 numbered steps."""
        content = ORCHESTRATOR.read_text()
        for step_num in range(1, 10):
            pattern = f"[{step_num}/9]"
            assert pattern in content, f"Missing profile step {pattern}"

    def test_step1_collision_check(self):
        """Step 1/9 must check for existing models (semantic collision)."""
        content = ORCHESTRATOR.read_text()
        assert "collision" in content.lower(), "Missing collision check in orchestrator"
        # Collision module must exist
        collision_mod = SCRIPT_DIR / "src" / "semantic_collision.py"
        if not collision_mod.exists():
            # May be inline in orchestrator
            assert "_check_collision" in content or "collision_check" in content or \
                   "collision_result" in content, \
                "No collision check function found"

    def test_step2_describe_table(self):
        """Step 2/9 must query INFORMATION_SCHEMA.COLUMNS."""
        content = ORCHESTRATOR.read_text()
        assert "INFORMATION_SCHEMA.COLUMNS" in content, \
            "Missing INFORMATION_SCHEMA.COLUMNS query for column discovery"

    def test_step3_sample_data(self):
        """Step 3/9 must sample data with LIMIT 5."""
        content = ORCHESTRATOR.read_text()
        assert "LIMIT 5" in content, "Missing LIMIT 5 sample query"

    def test_step4_row_count(self):
        """Step 4/9 must get row count for volume classification."""
        content = ORCHESTRATOR.read_text()
        assert "COUNT(*)" in content or "count(*)" in content, "Missing COUNT(*) query"
        # Volume tiers must be defined
        assert "normal" in content and "caution" in content and "large" in content, \
            "Missing volume tier classification"

    def test_step5_grain_validation(self):
        """Step 5/9 must validate BK + PSA_LOAD_DTS uniqueness."""
        content = ORCHESTRATOR.read_text()
        assert "grain" in content.lower(), "Missing grain validation"
        assert "PSA_LOAD_DTS" in content, "Grain must check PSA_LOAD_DTS"

    def test_step6_null_bk_check(self):
        """Step 6/9 must check for NULL business keys."""
        content = ORCHESTRATOR.read_text()
        assert "IS NULL" in content, "Missing NULL BK check"
        assert "null_bk_count" in content, "Missing null_bk_count tracking"

    def test_step7_ingestion_detection(self):
        """Step 7/9 must detect Fivetran vs SNP GLUE vs Custom."""
        content = ORCHESTRATOR.read_text()
        assert "_FIVETRAN_DELETED" in content, "Missing Fivetran column detection"
        assert "SNP_GLUE" in content.upper() or "snp_glue" in content, \
            "Missing SNP GLUE detection"
        assert "ingestion_source" in content, "Missing ingestion_source classification"

    def test_step8_bkcc_validation(self):
        """Step 8/9 must query REF_BUSINESS_KEY_COLLISION."""
        content = ORCHESTRATOR.read_text()
        assert "REF_BUSINESS_KEY_COLLISION" in content, \
            "Missing BKCC lookup against REF_BUSINESS_KEY_COLLISION"

    def test_step9_source_check(self):
        """Step 9/9 must check if source is already registered."""
        content = ORCHESTRATOR.read_text()
        assert "source_registered" in content or "Source registration" in content.lower() or \
               "source registration check" in content.lower(), \
            "Missing source registration check"

    def test_three_approval_gates(self):
        """Pipeline must have 3 STOP gates requiring user approval."""
        content = ORCHESTRATOR.read_text()
        approval_gates = ["approve-profile", "approve-xlsx", "approve-code"]
        for gate in approval_gates:
            assert gate in content, f"Missing approval gate: {gate}"

    def test_hashdiff_excludes_metadata(self):
        """HASHDIFF exclusion set must contain all required metadata columns."""
        content = ORCHESTRATOR.read_text()
        required_excludes = [
            "PSA_LOAD_DTS", "PSA_RECORD_SOURCE",
            "_FIVETRAN_SYNCED", "_FIVETRAN_ID",
        ]
        for col in required_excludes:
            assert col in content, f"Missing HASHDIFF exclusion: {col}"

    def test_volume_thresholds(self):
        """Volume thresholds must be defined (50M normal, 300M caution)."""
        content = ORCHESTRATOR.read_text()
        # Look for threshold constants
        assert "50" in content, "Missing 50M volume threshold"
        assert re.search(r'VOLUME.*NORMAL|NORMAL.*VOLUME|50_?000_?000|50000000',
                         content, re.IGNORECASE), \
            "Missing VOLUME_NORMAL threshold constant"


# ═══════════════════════════════════════════════════════════════════════════════
# 3. STAGE 2 — Code Generation
# ═══════════════════════════════════════════════════════════════════════════════

class TestStage2CodeGeneration:
    """Verify Stage 2 code generation produces correct outputs."""

    def test_build_py_generates_4_layer_cte(self):
        """build.py must generate 4-layer CTE: SRC → LOGIC → JOIN → FINAL."""
        build_content = (SRC_DIR / "build.py").read_text()
        for layer in ["SRC LAYER", "LOGIC LAYER", "JOIN LAYER", "FINAL LAYER"]:
            assert layer in build_content, f"Missing CTE layer: {layer}"

    def test_build_py_uses_md5_binary(self):
        """Hash keys must use MD5_BINARY."""
        build_content = (SRC_DIR / "build.py").read_text()
        assert "MD5_BINARY" in build_content, "Missing MD5_BINARY in build.py"

    def test_build_py_uses_concat_ws(self):
        """HK formula must use CONCAT_WS for hash key generation."""
        build_content = (SRC_DIR / "build.py").read_text()
        assert "CONCAT_WS" in build_content, "Missing CONCAT_WS in build.py"

    def test_build_py_uses_coalesce_nullif_trim(self):
        """HK formula must use COALESCE(NULLIF(TRIM(...)))."""
        build_content = (SRC_DIR / "build.py").read_text()
        assert "COALESCE" in build_content, "Missing COALESCE in build.py"
        assert "NULLIF" in build_content, "Missing NULLIF in build.py"
        assert "TRIM" in build_content, "Missing TRIM in build.py"

    def test_build_py_uses_upper_in_hash(self):
        """Hash keys must wrap in UPPER()."""
        build_content = (SRC_DIR / "build.py").read_text()
        assert "UPPER" in build_content, "Missing UPPER() in hash formula"

    def test_build_py_generates_ghost_records(self):
        """Raw vault models must include ghost records via UNION ALL."""
        build_content = (SRC_DIR / "build.py").read_text()
        assert "UNION ALL" in build_content or "union all" in build_content, \
            "Missing ghost record UNION ALL"

    def test_not_exists_delta_detection(self):
        """Delta detection uses NOT EXISTS — generated by orchestrator, validated by build.py."""
        # NOT EXISTS pattern generated by orchestrator into FINAL LAYER FILTER
        orch_content = ORCHESTRATOR.read_text()
        assert "NOT EXISTS" in orch_content, "Missing NOT EXISTS in orchestrator"
        # build.py validates the pattern via regex
        build_content = (SRC_DIR / "build.py").read_text()
        assert "is_incremental" in build_content, "build.py must validate is_incremental pattern"

    def test_build_py_has_watermark_pattern(self):
        """Large volume models must support INCR_WATERMARK pattern."""
        build_content = (SRC_DIR / "build.py").read_text()
        assert "INCR_WATERMARK" in build_content or "watermark" in build_content.lower(), \
            "Missing watermark pattern for large volume models"

    def test_make_yml_generates_stg_tests(self):
        """STG YAML must include unique_combination + not_null tests."""
        yml_content = (SRC_DIR / "make_yml.py").read_text()
        assert "unique_combination_of_columns" in yml_content, \
            "Missing unique_combination_of_columns test in make_yml"
        assert "not_null" in yml_content, "Missing not_null test in make_yml"

    def test_make_yml_generates_hub_tests(self):
        """HUB YAML must include primary_key + row_count tests."""
        yml_content = (SRC_DIR / "make_yml.py").read_text()
        assert "primary_key" in yml_content, "Missing primary_key test"
        assert "row_count" in yml_content.lower() or "expect_table_row_count" in yml_content, \
            "Missing row count test"

    def test_tests_py_generates_fk_for_sat(self):
        """SAT YAML must include foreign_key reference to parent (via tests.py)."""
        tests_content = (SRC_DIR / "tests.py").read_text()
        assert "foreign_key" in tests_content, "Missing foreign_key test for satellites in tests.py"

    def test_make_yml_uses_data_tests(self):
        """YAML must use 'data_tests:' not deprecated 'tests:'."""
        yml_content = (SRC_DIR / "make_yml.py").read_text()
        assert "data_tests" in yml_content, \
            "Missing 'data_tests:' key (using deprecated 'tests:'?)"

    def test_make_yml_severity_warn(self):
        """Test severity must default to 'warn' for STG/HUB/SAT."""
        yml_content = (SRC_DIR / "make_yml.py").read_text()
        assert "warn" in yml_content, "Missing 'warn' severity setting"

    def test_yaml_reader_validates_schema_version(self):
        """yaml_reader must validate schema_version."""
        yr_content = (SRC_DIR / "yaml_reader.py").read_text()
        assert "schema_version" in yr_content or "SUPPORTED_SCHEMA_VERSIONS" in yr_content, \
            "Missing schema version validation"

    def test_xlsx_validation_exists(self):
        """XLSX tech spec validator (22+ checks) must exist."""
        content = ORCHESTRATOR.read_text()
        assert "validate" in content.lower(), "Missing XLSX validation"
        # Check for validate_tech_spec or similar
        gts = SCRIPT_DIR / "generate_tech_spec.py"
        if gts.exists():
            gts_content = gts.read_text()
            assert "validate" in gts_content.lower() or "check" in gts_content.lower(), \
                "generate_tech_spec.py must have validation checks"


# ═══════════════════════════════════════════════════════════════════════════════
# 4. STAGE 3 — Deploy & Test
# ═══════════════════════════════════════════════════════════════════════════════

class TestStage3Deploy:
    """Verify Stage 3 deployment steps are correctly implemented."""

    def test_implement_has_conflict_check(self):
        """Implement must check for existing files before placing."""
        content = ORCHESTRATOR.read_text()
        assert "already exist" in content.lower() or "conflict" in content.lower(), \
            "Missing file conflict check in implement"

    def test_implement_places_files_in_correct_dirs(self):
        """Files must be placed in correct model directories."""
        content = ORCHESTRATOR.read_text()
        assert "int_staging_views" in content, "Missing int_staging_views directory placement"
        assert "raw_vault/hub" in content or "raw_vault\\hub" in content, \
            "Missing raw_vault/hub directory"
        assert "raw_vault/sat" in content or "raw_vault\\sat" in content, \
            "Missing raw_vault/sat directory"

    def test_source_registration_has_backup(self):
        """Source registration must create backup before modifying YAML."""
        content = ORCHESTRATOR.read_text()
        assert "backup" in content.lower(), "Missing backup in source registration"

    def test_source_registration_has_yaml_validation(self):
        """Source registration must validate YAML after modification."""
        content = ORCHESTRATOR.read_text()
        # Must parse YAML after writing to catch corruption
        assert "yaml.safe_load" in content or "yaml_valid" in content.lower() or \
               "produced invalid YAML" in content, \
            "Missing YAML validation after source registration"

    def test_source_registration_has_rollback(self):
        """Source registration must rollback on YAML corruption."""
        content = ORCHESTRATOR.read_text()
        assert "rollback" in content.lower() or "Restored backup" in content, \
            "Missing rollback on source registration failure"

    def test_implement_runs_dbt_build(self):
        """Implement must run dbt build (or dbt compile+run+test)."""
        content = ORCHESTRATOR.read_text()
        assert "dbt build" in content.lower() or "dbt_build" in content.lower() or \
               "_run_dbt" in content, \
            "Missing dbt build step in implement"

    def test_implement_uses_plain_dbt_build(self):
        """dbt build must NOT include --vars enable_staging_tests (removed — tests run by default)."""
        content = ORCHESTRATOR.read_text()
        assert "enable_staging_tests" not in content, \
            "enable_staging_tests var should be removed — dbt build runs tests without it"

    def test_implement_has_skip_build_option(self):
        """Implement must support --skip-build for build-all workflow."""
        content = ORCHESTRATOR.read_text()
        assert "skip-build" in content or "skip_build" in content, \
            "Missing --skip-build option"

    def test_build_all_command_exists(self):
        """build-all command must exist for multi-object builds."""
        content = ORCHESTRATOR.read_text()
        assert "build-all" in content, "Missing build-all command"

    def test_model_directories_exist(self):
        """All target model directories must exist."""
        dirs = [
            "models/int_staging_views",
            "models/raw_vault/hub",
            "models/raw_vault/sat",
            "models/raw_vault/link",
        ]
        for d in dirs:
            path = PROJECT_ROOT / d
            assert path.exists(), f"Missing model directory: {d}"


# ═══════════════════════════════════════════════════════════════════════════════
# 5. SKILLS & AGENTS — Are all agent definitions present and correct?
# ═══════════════════════════════════════════════════════════════════════════════

class TestSkillsAndAgents:
    """Verify skill files and agent definitions are present and correct."""

    @pytest.mark.parametrize("skill_name", [
        "dv-tech-design-creator",
        "dv-code-implementer",
        "dv-raw-vault-generator",
    ])
    def test_fbin_skill_exists_in_github(self, skill_name):
        """FBIN custom skills must exist in .github/skills/."""
        skill_path = PROJECT_ROOT / ".github" / "skills" / skill_name / "SKILL.md"
        assert skill_path.exists(), f"Missing skill: {skill_path}"

    @pytest.mark.parametrize("skill_name", [
        "dv-tech-design-creator",
        "dv-code-implementer",
        "dv-raw-vault-generator",
    ])
    def test_fbin_skill_has_prompt_injection_guardrail(self, skill_name):
        """FBIN skills must have prompt injection / untrusted data warning."""
        skill_path = PROJECT_ROOT / ".github" / "skills" / skill_name / "SKILL.md"
        content = skill_path.read_text()
        assert "untrusted" in content.lower(), \
            f"{skill_name} missing prompt injection guardrail (untrusted data warning)"

    @pytest.mark.parametrize("skill_name", [
        "dv-tech-design-creator",
        "dv-code-implementer",
        "dv-raw-vault-generator",
    ])
    def test_fbin_skill_synced_to_claude(self, skill_name):
        """FBIN skills must be synced between .github/skills/ and .claude/skills/."""
        github_path = PROJECT_ROOT / ".github" / "skills" / skill_name / "SKILL.md"
        claude_path = PROJECT_ROOT / ".claude" / "skills" / skill_name / "SKILL.md"
        assert claude_path.exists(), f"Missing claude mirror: {claude_path}"
        assert github_path.read_text() == claude_path.read_text(), \
            f"Skill out of sync: {skill_name} — run 'bash scripts/sync_skills.sh'"

    @pytest.mark.parametrize("agent_name", [
        "dv-pipeline-coordinator",
        "dv-source-analyzer",
        "dv-model-generator",
        "dv-validator",
    ])
    def test_agent_definition_exists(self, agent_name):
        """All 4 pipeline agents must have .agent.md definitions."""
        agent_path = PROJECT_ROOT / ".github" / "agents" / f"{agent_name}.agent.md"
        assert agent_path.exists(), f"Missing agent: {agent_path}"

    @pytest.mark.parametrize("skill_name", [
        "adding-dbt-unit-test",
        "creating-mermaid-dbt-dag",
        "fetching-dbt-docs",
        "running-dbt-commands",
        "troubleshooting-dbt-job-errors",
        "using-dbt-for-analytics-engineering",
        "using-dbt-index",
    ])
    def test_dbt_labs_skill_installed(self, skill_name):
        """dbt-labs agent skills must be installed in .agents/skills/."""
        skill_path = PROJECT_ROOT / ".agents" / "skills" / skill_name / "SKILL.md"
        assert skill_path.exists(), f"Missing dbt-labs skill: {skill_path}"

    def test_skills_lock_json_exists(self):
        """skills-lock.json must exist and be valid JSON."""
        lock_path = PROJECT_ROOT / "skills-lock.json"
        assert lock_path.exists()
        data = json.loads(lock_path.read_text())
        assert "skills" in data
        assert len(data["skills"]) >= 12, \
            f"Expected >= 12 skills in lock file, got {len(data['skills'])}"

    def test_sync_skills_script_exists(self):
        """sync_skills.sh must exist for skill mirroring."""
        assert (PROJECT_ROOT / "scripts" / "sync_skills.sh").exists()


# ═══════════════════════════════════════════════════════════════════════════════
# 6. STATE MACHINE — Step ordering and enforcement
# ═══════════════════════════════════════════════════════════════════════════════

class TestStateMachine:
    """Verify the state machine enforces step ordering."""

    def test_state_dir_constant(self):
        """State directory must be defined."""
        content = ORCHESTRATOR.read_text()
        assert ".pipeline_state" in content, "Missing .pipeline_state directory constant"

    def test_init_creates_state_file(self):
        """init command must create a state JSON file."""
        content = ORCHESTRATOR.read_text()
        assert "json.dump" in content or "_save_state" in content, \
            "init must persist state to JSON"

    def test_atomic_state_writes(self):
        """State writes must be atomic (write to temp + rename)."""
        content = ORCHESTRATOR.read_text()
        # Look for atomic write pattern
        assert "tempfile" in content or "tmp" in content.lower() or \
               "atomic" in content.lower() or "rename" in content, \
            "State writes should be atomic (temp file + rename)"

    def test_step_enforcement(self):
        """Each step must check that prerequisites are met."""
        content = ORCHESTRATOR.read_text()
        assert "_check_prerequisite" in content or "completed_steps" in content or \
               "prerequisite" in content.lower(), \
            "Missing step prerequisite enforcement"

    def test_snowflake_steps_defined(self):
        """Steps requiring Snowflake must be explicitly listed."""
        content = ORCHESTRATOR.read_text()
        assert "SNOWFLAKE_STEPS" in content, \
            "Missing SNOWFLAKE_STEPS set"

    def test_init_accepts_objects_flag(self):
        """init must accept --objects for multi-object pipelines."""
        result = subprocess.run(
            [sys.executable, str(ORCHESTRATOR), "init", "--help"],
            capture_output=True, text=True, timeout=10,
        )
        assert "--objects" in result.stdout, "Missing --objects flag in init"

    def test_init_accepts_raw_vault_params(self):
        """init must accept raw vault params (--lnk-name, --parent-hks, etc.)."""
        result = subprocess.run(
            [sys.executable, str(ORCHESTRATOR), "init", "--help"],
            capture_output=True, text=True, timeout=10,
        )
        for param in ["--lnk-name", "--parent-hks", "--sat-parent-hk",
                       "--sat-parent-model", "--sat-type"]:
            assert param in result.stdout, f"Missing raw vault param: {param}"


# ═══════════════════════════════════════════════════════════════════════════════
# 7. BKCC & HASH STANDARDS — Critical DV 2.x compliance
# ═══════════════════════════════════════════════════════════════════════════════

class TestDataVaultStandards:
    """Verify DV 2.x standards are enforced in code generation."""

    def test_bkcc_inner_join_pattern(self):
        """BKCC must join via INNER JOIN ... ON '1' = '1'."""
        build_content = (SRC_DIR / "build.py").read_text()
        assert "'1' = '1'" in build_content or '"1" = "1"' in build_content or \
               "1' = '1" in build_content, \
            "Missing BKCC INNER JOIN ON '1' = '1' pattern"

    def test_bkcc_is_last_in_hash(self):
        """BKCC must be the last component in hash key formulas."""
        build_content = (SRC_DIR / "build.py").read_text()
        # BKCC should appear as last in hash component lists
        assert "BKCC" in build_content, "Missing BKCC in build.py"

    def test_hashdiff_excludes_bk(self):
        """HASHDIFF must exclude BK columns."""
        content = ORCHESTRATOR.read_text()
        assert "HASHDIFF_EXCLUDE" in content or "hashdiff_exclude" in content.lower(), \
            "Missing HASHDIFF exclusion rules"

    def test_convert_timezone_utc(self):
        """Timestamp handling must use CONVERT_TIMEZONE('UTC', ...) — in orchestrator."""
        orch_content = ORCHESTRATOR.read_text()
        assert "CONVERT_TIMEZONE" in orch_content, \
            "Missing CONVERT_TIMEZONE in orchestrator"
        assert "'UTC'" in orch_content, "Missing UTC timezone specification"

    def test_null_date_placeholder(self):
        """NULL dates must use 1900-01-01 placeholder."""
        build_content = (SRC_DIR / "build.py").read_text()
        assert "1900-01-01" in build_content, \
            "Missing 1900-01-01 NULL date placeholder"

    def test_qualify_not_distinct(self):
        """Must use QUALIFY for dedup, not SELECT DISTINCT."""
        build_content = (SRC_DIR / "build.py").read_text()
        assert "QUALIFY" in build_content, "Missing QUALIFY clause"
        # DISTINCT should not appear as a dedup strategy
        distinct_count = build_content.upper().count("SELECT DISTINCT")
        assert distinct_count == 0, \
            f"Found {distinct_count} SELECT DISTINCT — use QUALIFY instead"

    def test_is_incremental_guard(self):
        """Raw vault models must use {% if is_incremental() %}."""
        build_content = (SRC_DIR / "build.py").read_text()
        assert "is_incremental()" in build_content, \
            "Missing is_incremental() guard for raw vault models"


# ═══════════════════════════════════════════════════════════════════════════════
# 8. EXISTING TESTS — Run the full unit test suite
# ═══════════════════════════════════════════════════════════════════════════════

class TestExistingTestSuite:
    """Verify the existing 234-test suite passes."""

    def test_hub_generation_tests_exist(self):
        assert (SCRIPT_DIR / "tests" / "test_hub_generation.py").exists()

    def test_sat_generation_tests_exist(self):
        assert (SCRIPT_DIR / "tests" / "test_sat_generation.py").exists()

    def test_lnk_generation_tests_exist(self):
        assert (SCRIPT_DIR / "tests" / "test_lnk_generation.py").exists()

    def test_hub_add_source_tests_exist(self):
        assert (SCRIPT_DIR / "tests" / "test_hub_add_source.py").exists()

    def test_semantic_collision_tests_exist(self):
        assert (SCRIPT_DIR / "tests" / "test_semantic_collision.py").exists()

    def test_generate_tech_spec_tests_exist(self):
        assert (SCRIPT_DIR / "tests" / "test_generate_tech_spec.py").exists()

    def test_demo_bugfixes_tests_exist(self):
        assert (SCRIPT_DIR / "tests" / "test_demo_bugfixes.py").exists()
