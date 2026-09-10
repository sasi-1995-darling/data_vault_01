"""
test_sat_type_autodetection.py — Tests for MSAT auto-detection when grain columns exceed HK+LOAD_DTS.

Validates:
- cmd_add_raw_vault auto-detects MSAT when grain_columns has entries beyond HK+LOAD_DTS
- SAT remains "sat" when grain is only HK+LOAD_DTS
- Warning message printed when auto-correction occurs
- multi_active_key is NOT required when auto-detecting MSAT
"""

import sys
import tempfile
import json
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

# Add parent dirs so we can import the modules under test
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from pipeline_orchestrator import cmd_add_raw_vault


class TestSatTypeAutodetection:
    """Test MSAT auto-detection when grain_columns exceed HK+LOAD_DTS."""

    @pytest.fixture
    def base_state(self):
        """Minimal state after approve-xlsx."""
        return {
            "model_name": "v_psa_stg_payment_terms_header__lrsn_psft",
            "schema": "lrsn_psft_sysadm",
            "table": "ps_pymt_trms_hdr",
            "bk": "pymnt_terms_cd",
            "bk_name": "PAYMENT_TERMS_HEADER_BK",
            "rec_src": "USSDBR.ORCL.PSFTPRD.PS_PYMT_TRMS_HDR",
            "objects": ["stg"],
            "steps_completed": [
                {"step": "init"},
                {"step": "profile"},
                {"step": "approve-profile"},
                {"step": "generate-yaml"},
                {"step": "generate-xlsx"},
                {"step": "approve-xlsx"},
            ],
            "profile_results": {
                "bkcc": "Swimming_Ocean",
                "ingestion_source": "fivetran",
            },
        }

    @pytest.fixture
    def temp_state_file(self, base_state):
        """Create a temporary state file."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(base_state, f)
            temp_file = f.name
        yield temp_file
        Path(temp_file).unlink()

    def test_msat_autodetect_with_grain_beyond_hk_load_dts(self, base_state, temp_state_file):
        """
        When grain_columns includes SETID (beyond HK+LOAD_DTS),
        auto-detect should change sat_type from "sat" to "msat".
        """
        args = MagicMock()
        args.model_name = None
        args.objects = "hub,sat"
        args.hub_name = "hub_payment_term"
        args.sat_type = "sat"  # Default (not explicitly set to msat)
        args.sat_name = "sat_payment_term_header__lrsn_psft"
        args.sat_parent_hk = "PAYMENT_TERM_HK"
        args.sat_parent_model = "hub_payment_term"
        args.grain_columns = "PAYMENT_TERM_HK,SETID,LOAD_DTS"  # SETID is beyond HK+LOAD_DTS
        args.sat_columns = None
        args.multi_active_key = None  # NOT required for auto-detected MSAT
        args.lnk_name = None
        args.parent_hks = None
        args.dck = None
        args.state = temp_state_file
        args.force = False

        with patch('pipeline_orchestrator._resolve_state') as mock_resolve:
            mock_resolve.return_value = base_state.copy()
            with patch('pipeline_orchestrator._semantic_collision_check') as mock_collision:
                mock_collision.return_value = {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "no existing model uses this table"},
                        "hub": {"status": "CLEAR", "message": "no collision detected"},
                        "sat": {"status": "CLEAR", "message": "no collision detected"},
                    },
                }
                with patch('pipeline_orchestrator._save_state') as mock_save:
                    with patch('builtins.print') as mock_print:
                        rc = cmd_add_raw_vault(args)

                        # Verify success
                        assert rc == 0

                        # Verify state was updated with auto-corrected MSAT
                        called_state = mock_save.call_args[0][0]
                        assert "sats" in called_state
                        assert len(called_state["sats"]) == 1
                        sat_def = called_state["sats"][0]
                        assert sat_def["sat_type"] == "msat", \
                            f"Expected sat_type='msat' but got '{sat_def['sat_type']}"
                        
                        # Verify auto-correction warning was printed
                        print_calls = [str(c) for c in mock_print.call_args_list]
                        auto_correct_printed = any(
                            "Auto-correcting sat_type: sat → msat" in str(c) 
                            for c in print_calls
                        )
                        assert auto_correct_printed, \
                            "Expected auto-correction warning in output"

    def test_sat_unchanged_when_grain_only_hk_load_dts(self, base_state, temp_state_file):
        """
        When grain_columns is only HK+LOAD_DTS (no extra columns),
        sat_type should remain "sat" (no auto-correction).
        """
        args = MagicMock()
        args.model_name = None
        args.objects = "hub,sat"
        args.hub_name = "hub_payment_term"
        args.sat_type = "sat"
        args.sat_name = "sat_payment_term_header__lrsn_psft"
        args.sat_parent_hk = "PAYMENT_TERM_HK"
        args.sat_parent_model = "hub_payment_term"
        args.grain_columns = "PAYMENT_TERM_HK,LOAD_DTS"  # Only HK+LOAD_DTS, no extra
        args.sat_columns = None
        args.multi_active_key = None
        args.lnk_name = None
        args.parent_hks = None
        args.dck = None
        args.state = temp_state_file
        args.force = False

        with patch('pipeline_orchestrator._resolve_state') as mock_resolve:
            mock_resolve.return_value = base_state.copy()
            with patch('pipeline_orchestrator._semantic_collision_check') as mock_collision:
                mock_collision.return_value = {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "no existing model uses this table"},
                        "hub": {"status": "CLEAR", "message": "no collision detected"},
                        "sat": {"status": "CLEAR", "message": "no collision detected"},
                    },
                }
                with patch('pipeline_orchestrator._save_state') as mock_save:
                    rc = cmd_add_raw_vault(args)

                    # Verify success
                    assert rc == 0

                    # Verify sat_type remains "sat" (no auto-correction)
                    called_state = mock_save.call_args[0][0]
                    sat_def = called_state["sats"][0]
                    assert sat_def["sat_type"] == "sat", \
                        f"Expected sat_type='sat' but got '{sat_def['sat_type']}"

    def test_msat_explicit_not_overridden_by_autodetect(self, base_state, temp_state_file):
        """
        When user explicitly sets --sat-type msat, auto-detection does not override it.
        """
        args = MagicMock()
        args.model_name = None
        args.objects = "hub,sat"
        args.hub_name = "hub_payment_term"
        args.sat_type = "msat"  # Explicitly set
        args.sat_name = "msat_payment_term_header__lrsn_psft"
        args.sat_parent_hk = "PAYMENT_TERM_HK"
        args.sat_parent_model = "hub_payment_term"
        args.grain_columns = "PAYMENT_TERM_HK,SETID,LOAD_DTS"
        args.sat_columns = None
        args.multi_active_key = "SETID"  # Required for explicit MSAT
        args.lnk_name = None
        args.parent_hks = None
        args.dck = None
        args.state = temp_state_file
        args.force = False

        with patch('pipeline_orchestrator._resolve_state') as mock_resolve:
            mock_resolve.return_value = base_state.copy()
            with patch('pipeline_orchestrator._semantic_collision_check') as mock_collision:
                mock_collision.return_value = {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "no existing model uses this table"},
                        "hub": {"status": "CLEAR", "message": "no collision detected"},
                        "sat": {"status": "CLEAR", "message": "no collision detected"},
                    },
                }
                with patch('pipeline_orchestrator._save_state') as mock_save:
                    rc = cmd_add_raw_vault(args)

                    # Verify success
                    assert rc == 0

                    # Verify sat_type is still "msat"
                    called_state = mock_save.call_args[0][0]
                    sat_def = called_state["sats"][0]
                    assert sat_def["sat_type"] == "msat"

    def test_no_grain_columns_stays_sat(self, base_state, temp_state_file):
        """
        When no grain_columns are provided (None),
        sat_type should remain "sat" (no auto-correction).
        """
        args = MagicMock()
        args.model_name = None
        args.objects = "hub,sat"
        args.hub_name = "hub_payment_term"
        args.sat_type = "sat"
        args.sat_name = "sat_payment_term_header__lrsn_psft"
        args.sat_parent_hk = "PAYMENT_TERM_HK"
        args.sat_parent_model = "hub_payment_term"
        args.grain_columns = None  # No explicit grain
        args.sat_columns = None
        args.multi_active_key = None
        args.lnk_name = None
        args.parent_hks = None
        args.dck = None
        args.state = temp_state_file
        args.force = False

        with patch('pipeline_orchestrator._resolve_state') as mock_resolve:
            mock_resolve.return_value = base_state.copy()
            with patch('pipeline_orchestrator._semantic_collision_check') as mock_collision:
                mock_collision.return_value = {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "no existing model uses this table"},
                        "hub": {"status": "CLEAR", "message": "no collision detected"},
                        "sat": {"status": "CLEAR", "message": "no collision detected"},
                    },
                }
                with patch('pipeline_orchestrator._save_state') as mock_save:
                    rc = cmd_add_raw_vault(args)

                    # Verify success
                    assert rc == 0

                    # Verify sat_type remains "sat"
                    called_state = mock_save.call_args[0][0]
                    sat_def = called_state["sats"][0]
                    assert sat_def["sat_type"] == "sat"

    def test_objects_msat_alias_normalizes_to_sat_and_sets_sat_type(self, base_state, temp_state_file):
        """--objects msat should normalize to sat and auto-set sat_type=msat."""
        args = MagicMock()
        args.model_name = None
        args.objects = "hub,msat"
        args.hub_name = "hub_payment_term"
        args.sat_type = None  # No explicit --sat-type flag
        args.sat_name = "msat_payment_term_header__lrsn_psft"
        args.sat_parent_hk = "PAYMENT_TERM_HK"
        args.sat_parent_model = "hub_payment_term"
        args.grain_columns = "PAYMENT_TERM_HK,SETID,LOAD_DTS"
        args.sat_columns = None
        args.multi_active_key = "SETID"  # required for msat/lmsat
        args.lnk_name = None
        args.parent_hks = None
        args.dck = None
        args.state = temp_state_file
        args.force = False

        with patch('pipeline_orchestrator._resolve_state') as mock_resolve:
            mock_resolve.return_value = base_state.copy()
            with patch('pipeline_orchestrator._semantic_collision_check') as mock_collision:
                mock_collision.return_value = {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "no existing model uses this table"},
                        "hub": {"status": "CLEAR", "message": "no collision detected"},
                        "sat": {"status": "CLEAR", "message": "no collision detected"},
                    },
                }
                with patch('pipeline_orchestrator._save_state') as mock_save:
                    rc = cmd_add_raw_vault(args)

                    assert rc == 0
                    called_state = mock_save.call_args[0][0]
                    assert "sat" in called_state["objects"]
                    assert "msat" not in called_state["objects"]
                    assert called_state["sats"][0]["sat_type"] == "msat"

    def test_explicit_sat_type_overrides_object_alias(self, base_state, temp_state_file):
        """Explicit --sat-type must take precedence over --objects alias."""
        args = MagicMock()
        args.model_name = None
        args.objects = "hub,msat"
        args.hub_name = "hub_payment_term"
        args.sat_type = "lsat"  # Explicit flag should win over msat alias
        args.sat_name = "lsat_payment_term_header__lrsn_psft"
        args.sat_parent_hk = "PAYMENT_TERM_HK"
        args.sat_parent_model = "hub_payment_term"
        args.grain_columns = "PAYMENT_TERM_HK,SETID,LOAD_DTS"
        args.sat_columns = None
        args.multi_active_key = None  # not required for LSAT
        args.lnk_name = None
        args.parent_hks = None
        args.dck = None
        args.state = temp_state_file
        args.force = False

        with patch('pipeline_orchestrator._resolve_state') as mock_resolve:
            mock_resolve.return_value = base_state.copy()
            with patch('pipeline_orchestrator._semantic_collision_check') as mock_collision:
                mock_collision.return_value = {
                    "blocked": False,
                    "layers": {
                        "v_psa_stg": {"status": "CLEAR", "message": "no existing model uses this table"},
                        "hub": {"status": "CLEAR", "message": "no collision detected"},
                        "sat": {"status": "CLEAR", "message": "no collision detected"},
                    },
                }
                with patch('pipeline_orchestrator._save_state') as mock_save:
                    rc = cmd_add_raw_vault(args)

                    assert rc == 0
                    called_state = mock_save.call_args[0][0]
                    assert called_state["sats"][0]["sat_type"] == "lsat"


class TestSatNameDoubleUnderscoreValidation:
    """Missing '__' in SAT name must be a hard error, not just a warning."""

    def test_missing_double_underscore_hard_stops(self, tmp_path):
        """add-raw-vault with sat name missing '__' must return rc=1."""
        from pipeline_orchestrator import cmd_add_raw_vault

        state_file = tmp_path / "state.json"
        base_state = {
            "model_name": "v_psa_stg_delivery_flo_serial__winn_sap",
            "schema": "SAP_DELIVERY",
            "table": "DELIVERY_FLO_SERIAL",
            "bk": "VBELN",
            "bk_name": "DELIVERY",
            "rec_src": "USOHNO.SAP.ECCPRD.DELIVERY_FLO_SERIAL",
            "objects": ["stg"],
            "sats": [],
            "steps_completed": [{"step": "approve-xlsx", "ts": "2026-01-01T00:00:00"}],
        }
        state_file.write_text(json.dumps(base_state))

        args = MagicMock()
        args.objects = "msat"
        args.hub_name = None
        args.sat_type = None
        # Intentionally WRONG: single underscore instead of double
        args.sat_name = "msat_delivery_flo_serial_winn_sap"
        args.sat_parent_hk = "DELIVERY_HK"
        args.sat_parent_model = "hub_delivery_v1"
        args.grain_columns = "DELIVERY_HK,SERIALNO,LOAD_DTS"
        args.sat_columns = None
        args.multi_active_key = "SERIALNO"
        args.lnk_name = None
        args.parent_hks = None
        args.dck = None
        args.state = str(state_file)
        args.force = False

        with patch('pipeline_orchestrator._resolve_state') as mock_resolve:
            mock_resolve.return_value = base_state.copy()
            rc = cmd_add_raw_vault(args)

        assert rc == 1, "Missing '__' in SAT name must be a hard error (rc=1)"

    def test_correct_double_underscore_passes(self, tmp_path):
        """add-raw-vault with correct '__' in sat name must succeed."""
        from pipeline_orchestrator import cmd_add_raw_vault

        state_file = tmp_path / "state.json"
        base_state = {
            "model_name": "v_psa_stg_delivery_flo_serial__winn_sap",
            "schema": "SAP_DELIVERY",
            "table": "DELIVERY_FLO_SERIAL",
            "bk": "VBELN",
            "bk_name": "DELIVERY",
            "rec_src": "USOHNO.SAP.ECCPRD.DELIVERY_FLO_SERIAL",
            "objects": ["stg"],
            "sats": [],
            "steps_completed": [{"step": "approve-xlsx", "ts": "2026-01-01T00:00:00"}],
        }
        state_file.write_text(json.dumps(base_state))

        args = MagicMock()
        args.objects = "msat"
        args.hub_name = None
        args.sat_type = None
        # CORRECT: double underscore
        args.sat_name = "msat_delivery_flo_serial__winn_sap"
        args.sat_parent_hk = "DELIVERY_HK"
        args.sat_parent_model = "hub_delivery_v1"
        args.grain_columns = "DELIVERY_HK,SERIALNO,LOAD_DTS"
        args.sat_columns = None
        args.multi_active_key = "SERIALNO"
        args.lnk_name = None
        args.parent_hks = None
        args.dck = None
        args.state = str(state_file)
        args.force = False

        with patch('pipeline_orchestrator._resolve_state') as mock_resolve:
            mock_resolve.return_value = base_state.copy()
            with patch('pipeline_orchestrator._semantic_collision_check') as mock_collision:
                mock_collision.return_value = {
                    "blocked": False,
                    "layers": {"sat": {"status": "CLEAR", "message": "no collision detected"}},
                }
                with patch('pipeline_orchestrator._save_state'):
                    rc = cmd_add_raw_vault(args)

        assert rc == 0, f"Correct SAT name with '__' should pass, got rc={rc}"
