#!/usr/bin/env python3
"""Quick test harness for pre_tool_guard.py — runs all 3 scenarios."""
import json
import subprocess
import sys
import os
from pathlib import Path

HOOK = "scripts/automation/hooks/pre_tool_guard.py"
STATE_DIR = Path("scripts/automation/.pipeline_state")
CWD = os.getcwd()

def run_hook(tool_name, tool_input):
    """Run the hook with given input and return parsed output."""
    payload = json.dumps({"tool_name": tool_name, "tool_input": tool_input, "cwd": CWD})
    result = subprocess.run(
        [sys.executable, HOOK],
        input=payload, capture_output=True, text=True, timeout=10,
    )
    try:
        out = json.loads(result.stdout)
        return out["hookSpecificOutput"]["permissionDecision"]
    except (json.JSONDecodeError, KeyError):
        return f"ERROR: {result.stdout} {result.stderr}"

def test(label, tool_name, tool_input, expected):
    decision = run_hook(tool_name, tool_input)
    status = "PASS" if decision == expected else "FAIL"
    print(f"  [{status}] {label}: got={decision} expected={expected}")
    return status == "PASS"

def main():
    passed = 0
    failed = 0

    # Clean state
    if STATE_DIR.exists():
        import shutil
        shutil.rmtree(STATE_DIR)

    print("=== SCENARIO 1: No state file — all v_psa_stg ops blocked ===")
    tests = [
        ("Read v_psa_stg model SQL", "Read",
         {"file_path": f"{CWD}/models/int_staging_views/shipments/v_psa_stg_payment_terms_lines__ml_ebs.sql"},
         "deny"),
        ("Write v_psa_stg SQL", "Write",
         {"file_path": f"{CWD}/models/int_staging_views/v_psa_stg_test__source.sql", "content": "SELECT 1"},
         "deny"),
        ("Write hub SQL (Rule 1 extended)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/hub/hub_customer.sql", "content": "SELECT 1"},
         "deny"),
        ("Write sat SQL (Rule 1 extended)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/sat/sat_order__sap.sql", "content": "SELECT 1"},
         "deny"),
        ("Write lnk SQL (Rule 1 extended)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/link/lnk_order_item.sql", "content": "SELECT 1"},
         "deny"),
        ("Write msat SQL (Rule 1 extended)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/sat/msat_address__sap.sql", "content": "SELECT 1"},
         "deny"),
        ("Write lsat SQL (Rule 1 extended)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/sat/lsat_order_item__sap.sql", "content": "SELECT 1"},
         "deny"),
        ("Write lmsat SQL (Rule 1 extended)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/sat/lmsat_order_item__sap.sql", "content": "SELECT 1"},
         "deny"),
        ("Write link SQL (Rule 1 extended)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/link/link_order_item.sql", "content": "SELECT 1"},
         "deny"),
        ("Write tlink SQL (Rule 1 extended)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/link/tlink_order_item.sql", "content": "SELECT 1"},
         "deny"),
        ("Write esat SQL (Rule 1 extended)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/sat/esat_order_item__sap.sql", "content": "SELECT 1"},
         "deny"),
        ("Write rsat SQL (Rule 1 extended)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/sat/rsat_order_item__sap.sql", "content": "SELECT 1"},
         "deny"),
        ("Edit v_psa_stg YAML", "Edit",
         {"file_path": f"{CWD}/models/int_staging_views/v_psa_stg_test__source.yml", "old_string": "x", "new_string": "y"},
         "deny"),
        ("Edit _sources_staging_psa.yml", "Edit",
         {"file_path": f"{CWD}/models/sources/_sources_staging_psa.yml", "old_string": "x", "new_string": "y"},
         "deny"),
        ("Bash main.py --yaml-config", "Bash",
         {"command": "python3 scripts/automation/src/main.py --yaml-config configs/test.yml"},
         "deny"),
        ("Bash main.py --rootdir", "Bash",
         {"command": "python3 scripts/automation/src/main.py --rootdir /tmp"},
         "deny"),
        ("Bash generate_tech_spec.py", "Bash",
         {"command": "python3 scripts/automation/generate_tech_spec.py --yaml-config configs/test.yml"},
         "deny"),
        ("Bash pipeline_orchestrator.py (ALLOW)", "Bash",
         {"command": "python3 scripts/automation/pipeline_orchestrator.py init --model-name test"},
         "allow"),
        ("Read non-v_psa_stg file (ALLOW)", "Read",
         {"file_path": f"{CWD}/models/staging/base/base_customer__sap.sql"},
         "allow"),
        ("Write non-v_psa_stg file (ALLOW)", "Write",
         {"file_path": f"{CWD}/scripts/test.py", "content": "pass"},
         "allow"),
        ("Bash git status (ALLOW)", "Bash",
         {"command": "git status"},
         "allow"),
    ]
    for label, tool, inp, exp in tests:
        if test(label, tool, inp, exp):
            passed += 1
        else:
            failed += 1

    # Create state with init + profile
    print("\n=== SCENARIO 2: After init+profile — can read, cannot create ===")
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    state = {
        "model_name": "v_psa_stg_payment_terms_lines__ml_ebs",
        "steps_completed": [
            {"step": "init", "timestamp": "2026-04-09T00:00:00"},
            {"step": "profile", "timestamp": "2026-04-09T00:01:00"},
        ],
    }
    with open(STATE_DIR / "v_psa_stg_payment_terms_lines__ml_ebs.json", "w") as f:
        json.dump(state, f)

    tests2 = [
        ("Read v_psa_stg model (ALLOW after profile)", "Read",
         {"file_path": f"{CWD}/models/int_staging_views/shipments/v_psa_stg_payment_terms_lines__ml_ebs.sql"},
         "allow"),
        ("Write v_psa_stg SQL (DENY - no approve-code)", "Write",
         {"file_path": f"{CWD}/models/int_staging_views/v_psa_stg_payment_terms_lines__ml_ebs.sql", "content": "SELECT 1"},
         "deny"),
        ("Bash main.py --yaml-config (DENY - no approve-xlsx)", "Bash",
         {"command": "python3 scripts/automation/src/main.py --yaml-config configs/payment_terms_lines__ml_ebs.yml"},
         "deny"),
        ("Bash generate_tech_spec.py (DENY - no generate-yaml)", "Bash",
         {"command": "python3 scripts/automation/generate_tech_spec.py --yaml-config configs/payment_terms_lines__ml_ebs.yml"},
         "deny"),
    ]
    for label, tool, inp, exp in tests2:
        if test(label, tool, inp, exp):
            passed += 1
        else:
            failed += 1

    # Full pipeline through approve-code
    print("\n=== SCENARIO 3: Full pipeline through approve-code — can create ===")
    state["steps_completed"] = [
        {"step": s, "timestamp": "2026-04-09T00:00:00"}
        for s in ["init", "profile", "approve-profile", "generate-yaml",
                   "generate-xlsx", "approve-xlsx", "generate-code", "approve-code"]
    ]
    with open(STATE_DIR / "v_psa_stg_payment_terms_lines__ml_ebs.json", "w") as f:
        json.dump(state, f)

    tests3 = [
        ("Read v_psa_stg model (ALLOW)", "Read",
         {"file_path": f"{CWD}/models/int_staging_views/shipments/v_psa_stg_payment_terms_lines__ml_ebs.sql"},
         "allow"),
        ("Write v_psa_stg SQL (ALLOW after approve-code)", "Write",
         {"file_path": f"{CWD}/models/int_staging_views/v_psa_stg_payment_terms_lines__ml_ebs.sql", "content": "SELECT 1"},
         "allow"),
        ("Write v_psa_stg YAML (ALLOW after approve-code)", "Write",
         {"file_path": f"{CWD}/models/int_staging_views/v_psa_stg_payment_terms_lines__ml_ebs.yml", "content": "version: 2"},
         "allow"),
        ("Edit _sources_staging_psa.yml (ALLOW after approve-code)", "Edit",
         {"file_path": f"{CWD}/models/sources/_sources_staging_psa.yml", "old_string": "x", "new_string": "y"},
         "allow"),
        ("Bash main.py --yaml-config (ALLOW after approve-xlsx)", "Bash",
         {"command": "python3 scripts/automation/src/main.py --yaml-config configs/payment_terms_lines__ml_ebs.yml"},
         "allow"),
        ("Bash generate_tech_spec.py (ALLOW after generate-yaml)", "Bash",
         {"command": "python3 scripts/automation/generate_tech_spec.py --yaml-config configs/payment_terms_lines__ml_ebs.yml"},
         "allow"),
        # H-3: Hub/sat/lnk mapped to v_psa_stg via _model_from_file_path
        ("Write hub SQL (ALLOW — maps to v_psa_stg pipeline)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/hub/hub_payment_terms_lines__ml_ebs.sql", "content": "SELECT 1"},
         "allow"),
        ("Write sat SQL (ALLOW — maps to v_psa_stg pipeline)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/sat/sat_payment_terms_lines__ml_ebs.sql", "content": "SELECT 1"},
         "allow"),
        ("Write lsat YAML (ALLOW — maps to v_psa_stg pipeline)", "Write",
         {"file_path": f"{CWD}/models/raw_vault/sat/lsat_payment_terms_lines__ml_ebs.yml", "content": "version: 2"},
         "allow"),
    ]
    for label, tool, inp, exp in tests3:
        if test(label, tool, inp, exp):
            passed += 1
        else:
            failed += 1

    # Cleanup
    import shutil
    shutil.rmtree(STATE_DIR, ignore_errors=True)

    print(f"\n{'='*60}")
    print(f"TOTAL: {passed} passed, {failed} failed out of {passed + failed}")
    return failed == 0



def test_rule7():
    """Rule 7: Direct writes to .pipeline_state/ must ALWAYS be denied."""
    import shutil

    passed = 0
    failed = 0

    # Clean state for fresh start
    if STATE_DIR.exists():
        shutil.rmtree(STATE_DIR)

    print("\n=== RULE 7: .pipeline_state/ write protection ===")

    # Scenario A: No state — Write to state dir denied
    tests_r7 = [
        ("Write state JSON (no state exists)", "Write",
         {"file_path": f"{CWD}/scripts/automation/.pipeline_state/v_psa_stg_test__src.json",
          "content": '{"steps_completed": []}'},
         "deny"),
        ("Edit state JSON (no state exists)", "Edit",
         {"file_path": f"{CWD}/scripts/automation/.pipeline_state/v_psa_stg_test__src.json",
          "old_string": "ADD-SOURCE", "new_string": "CLEAR"},
         "deny"),
    ]
    for label, tool, inp, exp in tests_r7:
        if test(label, tool, inp, exp):
            passed += 1
        else:
            failed += 1

    # Scenario B: State exists (full pipeline) — still denied
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    state = {
        "model_name": "v_psa_stg_test__src",
        "steps_completed": [
            {"step": s, "timestamp": "2026-04-09T00:00:00"}
            for s in ["init", "profile", "approve-profile", "generate-yaml",
                       "generate-xlsx", "approve-xlsx", "generate-code", "approve-code"]
        ],
    }
    with open(STATE_DIR / "v_psa_stg_test__src.json", "w") as f:
        json.dump(state, f)

    tests_r7b = [
        ("Write state JSON (full pipeline — still denied)", "Write",
         {"file_path": f"{CWD}/scripts/automation/.pipeline_state/v_psa_stg_test__src.json",
          "content": '{"steps_completed": []}'},
         "deny"),
        ("Edit state JSON (tamper ADD-SOURCE→CLEAR — denied)", "Edit",
         {"file_path": f"{CWD}/scripts/automation/.pipeline_state/v_psa_stg_test__src.json",
          "old_string": "ADD-SOURCE", "new_string": "CLEAR"},
         "deny"),
        ("Write arbitrary file in .pipeline_state/ — denied", "Write",
         {"file_path": f"{CWD}/scripts/automation/.pipeline_state/malicious.json",
          "content": "{}"},
         "deny"),
    ]
    for label, tool, inp, exp in tests_r7b:
        if test(label, tool, inp, exp):
            passed += 1
        else:
            failed += 1

    # Cleanup
    shutil.rmtree(STATE_DIR, ignore_errors=True)

    print(f"\n{'='*60}")
    print(f"RULE 7 TOTAL: {passed} passed, {failed} failed out of {passed + failed}")
    return failed == 0




def test_rule8():
    """Rule 8: Bash rm/mv of files under models/ must be denied."""
    passed = 0
    failed = 0

    print("\n=== RULE 8: Bash rm/mv model file protection ===")

    tests_r8 = [
        ("Bash rm model file — absolute path (denied)", "Bash",
         {"command": f"rm {CWD}/models/raw_vault/hub/hub_payment_term.sql"},
         "deny"),
        ("Bash mv model file — absolute path (denied)", "Bash",
         {"command": f"mv {CWD}/models/raw_vault/sat/sat_order__sap.sql /tmp/"},
         "deny"),
        # Regression: relative paths must also be blocked (PR review finding)
        ("Bash rm model file — relative path (denied)", "Bash",
         {"command": "rm models/raw_vault/hub/hub_payment_term.sql"},
         "deny"),
        ("Bash mv model file — relative path (denied)", "Bash",
         {"command": "mv models/raw_vault/sat/sat_order__sap.sql /tmp/"},
         "deny"),
    ]
    for label, tool, inp, exp in tests_r8:
        if test(label, tool, inp, exp):
            passed += 1
        else:
            failed += 1

    print(f"\n{'='*60}")
    print(f"RULE 8 TOTAL: {passed} passed, {failed} failed out of {passed + failed}")
    return failed == 0

if __name__ == "__main__":
    ok_main = main()
    ok7 = test_rule7()
    ok8 = test_rule8()
    all_ok = ok_main and ok7 and ok8
    if not all_ok:
        sys.exit(1)
    print("\nALL TESTS PASSED")
