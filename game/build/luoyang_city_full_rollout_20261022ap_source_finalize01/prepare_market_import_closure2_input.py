"""Write only a NEW finite Root input and static scope review, never stage."""
from __future__ import annotations

import json

from prepare_handoff10 import HERE, GAME, resource, sha, write_new


def main():
    prefix = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
    evidence_pin = {"path": "res://build/luoyang_city_full_rollout_20261022ap_system01/market_fourteen_import_historical_lineage_READY.json", "sha256": "884e0e563d123b82a85d5ca792e6217d76948476d7653f63a111c2cb6aed0f81"}
    evidence_raw = resource(evidence_pin["path"]).read_bytes()
    assert sha(evidence_raw) == evidence_pin["sha256"]
    evidence = json.loads(evidence_raw)
    media = [{"png_path": r["source_png"], "png_sha256": r["already_fixed_png_sha256"], "sidecar_path": r["existing_import_path"], "sidecar_sha256": r["existing_import_sha256"], "compiled_path": r["declared_compiled_path"], "compiled_sha256": r["existing_compiled_sha256"]} for r in evidence["seven_rows"]]
    scope_pin = {"path": "res://build/luoyang_city_full_rollout_20261022ap_root01/integration4/scope_READY.json", "sha256": "d0c33ae76a0f084e8300b2fb45ca96cec995d1e442f75adcce44314ffe2563bb"}
    scope_raw = resource(scope_pin["path"]).read_bytes()
    assert sha(scope_raw) == scope_pin["sha256"]
    scope = json.loads(scope_raw)
    targets = {r["target"]: r["old_sha256"] for r in scope["targets"]}
    assert scope["approved_by_root"] is True and len(targets) == 2
    tool = HERE / "stage_market_import_closure2_READY.py"
    # Syntax compilation does not import or execute the Root-only stager.
    compile(tool.read_bytes(), str(tool), "exec")
    spec = {
        "schema_version": 1,
        "status": "ROOT_LOCKED_MARKET14_TWO_TARGET_SOURCE_ONLY",
        "output_root": prefix + "outputs/root_integration4_market14_stage01/",
        "required_generator": {"path": prefix + tool.name, "sha256": sha(tool.read_bytes()), "root_must_read_before_execution": True},
        "target_old_sha256": targets,
        "pinned_inputs": {
            "root_scope": scope_pin,
            "root_closure_admission": {"path": "res://build/luoyang_city_full_rollout_20261022ap_root01/integration4/closure_admission_READY.json", "sha256": "be2f52342ab2e6512466959dd49babbd0e83e44954007ed850cdf7c1c0e62d27"},
            "parent_stage03": {"path": prefix + "outputs/root_integration3_repair_stage03/receipt.json", "sha256": "481fb21e1cd5a15a597e329ddb3e369538161aaee8cf091ab774f69092dbcae1"},
            "independent_stage03_owner_maps": {"path": prefix + "repair_stage03_independent_qa_owner_source_maps_READY.json", "sha256": "d951f70822dde2f19e9fd74265b9cd5252acca99b6ee7910b8c20ae6a10b88e7"},
            "independent_media_evidence": evidence_pin,
        },
        "independent_media_evidence_value": evidence,
        "media_rows": media,
        "source_additions": evidence["fourteen_existing_leaf_pins"],
        "scope_contract": {
            "canonical_targets": 2,
            "market_change": "Only add fourteen previously absent keys to legacy_source_sha256; all other JSON values unchanged with whole typed inverse",
            "index_change": "Only the one old Market manifest SHA literal, whole original-byte inverse",
            "independent_expected_changes": "Four legacy-city existing APcityindex SHA pins; Market alone +14 and manifest SHA; other four exteriors and five rooms fully unchanged",
            "diagnostic_hashes_not_expected_inputs": True,
            "no_new_import_media_geometry_or_runtime_behavior": True,
            "original_stage03_and_all_failures_preserved": True,
            "future_exact_candidate_deployment_authorization_required": True,
        },
    }
    assert not resource(spec["output_root"]).exists()
    for pin in spec["pinned_inputs"].values():
        assert sha(resource(pin["path"]).read_bytes()) == pin["sha256"]
    assert len(media) == 7 and len(spec["source_additions"]) == 14
    result = write_new("market_import_closure2_ROOT_LOCKED.json", spec)
    audit = write_new("market_import_closure2_input_static_review.json", {"status": "STATIC_FROZEN_INPUT_NOT_STAGE", "input_sha256": result, "tool_sha256": spec["required_generator"]["sha256"], "target_old_sha256": targets, "media_origins": [r["png_path"] for r in media], "source_additions": spec["source_additions"], "independent_historical_evidence_sha256": evidence_pin["sha256"], "no_actual_runtime_hash_map_read": True, "no_stager_engine_or_canonical_write": True})
    print(json.dumps({"input_sha256": result, "tool_sha256": spec["required_generator"]["sha256"], "static_review_sha256": audit, "target_count": 2, "source_additions": 14, "stager_executed": False}))


if __name__ == "__main__":
    main()
