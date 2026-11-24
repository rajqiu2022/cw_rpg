"""Build-only second epoch from exact stage02 metadata, not old AO targets.

No stager, Godot, collector, canonical mutation or expected-current-hash crawl.
Root must approve fresh exact20 scope before this input can be LOCKED.
"""
from __future__ import annotations

import copy
import json

from prepare_handoff10 import HERE, GAME, SYS, resource, sha, write_new, read_pointer

APPROVAL_TARGET = "res://data/maps/luoyang_full_city_20261022ap/execution_successor.json"
EXEC_INDEX = "res://scripts/city/luoyang_execution_index_20261022ap.gd"
TEMPLE = "res://scripts/city/luoyang_temple_assembly_20261016.gd"
APPROVAL_OLD = "9c3f9b5a35360ca2b488424ea0a3922759bf3b70d21452c7298dff51e7aac817"
APPROVAL_NEW = "80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11"


def main():
    previous = (HERE / "source_finalization_input_handoff13_ROOT_LOCKED.json").read_bytes()
    assert sha(previous) == "18ae3e12b29d21e8f9dd8225712dce82c50e5a85856b211a221851b5df3c3abe"
    plan = json.loads(previous)
    stagepath = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/outputs/root_integration1_stage02/receipt.json"
    stagebytes = resource(stagepath).read_bytes()
    assert sha(stagebytes) == "b3ed75f8303d8b62a8cbe56b79a857309930c7493b28b216c2a11ee2110e1d39"
    stage = json.loads(stagebytes)
    oldnodes = stage["nodes"]
    oldtargets = {r["target"]: r for r in stage["targets"]}
    originalpins = {r["id"]: copy.deepcopy(r) for r in plan["pinned_inputs"]}
    originalapproval = json.loads(resource(originalpins["execution_approval"]["path"]).read_bytes())
    rootsystem = SYS + "temple_binding_pin_successor_retry1/"
    rootapprovalpath = "res://build/luoyang_city_full_rollout_20261022ap_root01/integration3/temple_execution_approval_READY.json"
    rootapprovalbytes = resource(rootapprovalpath).read_bytes()
    assert sha(rootapprovalbytes) == "e903ae3aec61cd829be7a874a3cf54818d0f5b85c988f6626afba6d14d6835c2"
    assert json.loads(rootapprovalbytes)["approved_by_root"] is True
    pins = {r["id"]: r for r in plan["pinned_inputs"]}
    pins["execution_approval"].update(path=rootsystem + "execution_successor_READY.json", sha256=APPROVAL_NEW)
    newapproval = json.loads(resource(pins["execution_approval"]["path"]).read_bytes())
    assert sha(resource(pins["execution_approval"]["path"]).read_bytes()) == APPROVAL_NEW
    plan["pinned_inputs"].extend([
        {"id": "repair_parent_actual_stage02", "path": stagepath, "sha256": sha(stagebytes)},
        {"id": "repair_parent_execution_9C3F", **{k: v for k, v in originalpins["execution_approval"].items() if k != "id"}},
        {"id": "root_temple_execution_approval", "path": rootapprovalpath, "sha256": sha(rootapprovalbytes)},
        {"id": "system_temple_pin_handoff", "path": rootsystem + "handoff_READY.json", "sha256": "63b2fcf91fb8e038f428e46ad16ba604b877a618f9c68ca390d34cade445d9e6"},
        {"id": "temple_real_binding", "path": rootsystem + "binding_READY.json", "sha256": "cc9dec2b08cb58e6a192a41e3e1bdc508f42f4a81317e0eb074ca6b13752414c"},
        {"id": "temple_real_binding_inverse", "path": rootsystem + "binding_successor_proof_READY.json", "sha256": "b3f347081f1e7c9aad3e0fddc97f2c71f15bffd78463aa9f4010d50e0900206a"},
    ])
    old_value_pins = {r["id"]: r for r in originalpins.values()}
    def resolve_old(value):
        if isinstance(value, dict) and "$sha" in value:
            return oldnodes[value["$sha"]]["disabled_sha256" if value.get("variant") == "disabled" else "sha256"]
        if isinstance(value, dict) and set(value) == {"$pin"}: return old_value_pins[value["$pin"]]["sha256"]
        if isinstance(value, dict) and set(value) == {"$owned"}: return originalapproval["owned"][value["$owned"]]["current_sha256"]
        if isinstance(value, dict): return {k: resolve_old(v) for k, v in value.items()}
        if isinstance(value, list): return [resolve_old(v) for v in value]
        return value
    def rewrite_runtime_ref(value):
        if isinstance(value, dict) and value.get("$sha") == "runtime_contract_final": return {"$pin": "runtime_contract_candidate"}
        if isinstance(value, dict): return {k: rewrite_runtime_ref(v) for k, v in value.items()}
        if isinstance(value, list): return [rewrite_runtime_ref(v) for v in value]
        return value
    plan = rewrite_runtime_ref(plan)
    repair_deploy_ids = {"estate_final", *("legacy_manifest_" + str(i) for i in range(2, 9)), *("legacy_index_" + str(i) for i in range(5)), "ap_execution_index", "quarter_final", "market_final", "ap_quarter_index", "ap_city_index"}
    updated_nodes = []
    explicit_data_pin_ops = {}
    for row in plan["nodes"]:
        ident = row["id"]
        if ident == "runtime_contract_final":
            continue
        if row["kind"] == "map":
            # The four fixed AO baseline seeds/old operation values are retained.
            updated_nodes.append(row)
            continue
        previous_node = oldnodes[ident]
        pin_id = "stage02_base_" + ident
        plan["pinned_inputs"].append({"id": pin_id, "path": previous_node["path"], "sha256": previous_node["sha256"]})
        original_input = row["base_input"]
        row["base_input"] = pin_id
        row.pop("derived_parent", None)
        if ident in repair_deploy_ids:
            assert row["target"] in oldtargets
            row["old_sha256"] = oldtargets[row["target"]]["candidate_sha256"]
        else:
            assert ident in {"registry_final", "ap_environment_index"}
            row.pop("target", None)
            row.pop("old_sha256", None)
        if row["kind"] == "metadata":
            base = previous_node["value"]
            for operation in row.get("operations", []):
                holder = read_pointer(base, operation["pointer"][:-1])
                operation["existed"] = operation["pointer"][-1] in holder
                if operation["existed"]: operation["old"] = holder[operation["pointer"][-1]]
            fields = [f["pointer"] for f in row.get("source_fields", [])] or row.get("source_bundle", {}).get("fields", [])
            data_ops = []
            for field in fields:
                source = read_pointer(base, field)
                if APPROVAL_TARGET in source:
                    assert source[APPROVAL_TARGET] == APPROVAL_OLD
                    data_ops.append({"op": "set", "pointer": field + [APPROVAL_TARGET], "existed": True, "old": APPROVAL_OLD, "new": {"$pin": "execution_approval"}})
                if EXEC_INDEX in source:
                    assert ident == "quarter_final" and source[EXEC_INDEX] == oldnodes["ap_execution_index"]["sha256"]
                    data_ops.append({"op": "set", "pointer": field + [EXEC_INDEX], "existed": True, "old": source[EXEC_INDEX], "new": {"$sha": "ap_execution_index"}})
            row["operations"] = row.get("operations", []) + data_ops
            explicit_data_pin_ops[ident] = data_ops
        else:
            assert row["kind"] == "index"
            original_row = next(r for r in json.loads(previous)["nodes"] if r["id"] == ident)
            replacements = []
            for hunk in original_row["replacements"]:
                if isinstance(hunk["new"], dict):
                    old = resolve_old(hunk["new"])
                    new = rewrite_runtime_ref(hunk["new"])
                    if new == {"$pin": "environment_final"}:
                        assert old == originalpins["environment_final"]["sha256"]
                        continue
                    replacements.append({"old": old, "new": new})
                elif hunk["old"] == "const FORMAL_ENABLED=true" and hunk["new"] == "const FORMAL_ENABLED=false":
                    continue
                else:
                    # Literal path migration is already present in stage02.
                    assert ident == "ap_quarter_index" and hunk["new"] == "res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json"
            replacements.append({"old": row["enabled_literal"], "new": row["disabled_literal"]})
            row["replacements"] = replacements
        updated_nodes.append(row)
    plan["nodes"] = updated_nodes
    plan["pass_through_targets"] = [
        {"target": TEMPLE, "old_sha256": originalapproval["owned"][TEMPLE]["current_sha256"], "candidate_from_authority": True},
        {"target": APPROVAL_TARGET, "old_sha256": APPROVAL_OLD, "candidate_path": rootsystem + "execution_successor_READY.json", "candidate_sha256": APPROVAL_NEW},
    ]
    plan["root_target_allowlist"] = [r["target"] for r in plan["pass_through_targets"]] + [r["target"] for r in plan["nodes"] if "target" in r]
    assert len(plan["root_target_allowlist"]) == len(set(plan["root_target_allowlist"])) == 20
    plan["required_gates"] = [r for r in plan["required_gates"] if r["id"] != "root_target_preauthorization"]
    plan["status"] = "PENDING_ROOT_NEW_EXACT20_SCOPE_NOT_EXECUTABLE"
    plan["blockers"] = ["Root must authorize fresh exact20 repair target scope/backups against deployedstage02 (not oldAO37) and provide new scope JSON pin; then add fifth gate/LOCKED status and external SHA. No engine/stager/canonical write by this agent."]
    plan["output_root"] = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/outputs/root_integration3_repair_stage01/"
    assert not resource(plan["output_root"]).exists()
    tool = (HERE / "stage_sources_repair_retry4.py").read_bytes()
    assert sha(tool) == "e89bfd88844ceffe127518fcbe29e570eb6db276f8ddcead2a76b3e5d7470792"
    plan["required_generator"] = {"path": "res://" + (HERE / "stage_sources_repair_retry4.py").relative_to(GAME).as_posix(), "sha256": sha(tool), "root_must_read_before_execution": True, "reason": "Deployedstage02 source-only Temple-binding repair,19patch +1 existing approval byte-copy; no old37 no-op deployment."}
    plan["predecessor_input"] = {"path": "res://" + (HERE / "source_finalization_input_handoff13_ROOT_LOCKED.json").relative_to(GAME).as_posix(), "sha256": sha(previous), "actual_stage02_preserved": True}
    plan["repair_epoch_contract"] = {
        "root_approval_input": "root_temple_execution_approval", "approval_old_sha256": APPROVAL_OLD, "approval_new_sha256": APPROVAL_NEW,
        "immutable_other9_owned": True, "native_geometry_and_asset_import_replay": False,
        "runtime_contract4D_and_registry_and_APENVindex_noop_excluded": True,
        "explicit_existing_approval_and_EXECindex_data_pin_operations": explicit_data_pin_ops,
        "all_metadata_typed_inverse_parent_is_deployed_stage02": True,
        "four_expected_maps_still_fixed_original_AO_baseline_not_currentcollector": True,
        "all37_stage02_and_all_FAIL_evidence_preserved": True,
    }
    target_rows = []
    for target in plan["root_target_allowlist"]:
        current_sha = oldtargets[target]["candidate_sha256"]
        target_rows.append({"target": target, "old_sha256": current_sha, "path": resource(target).as_posix(), "old_candidate_snapshot": oldtargets[target]["candidate_path"], "old_bytes": len(resource(oldtargets[target]["candidate_path"]).read_bytes()), "new_sha256": newapproval["owned"][TEMPLE]["current_sha256"] if target == TEMPLE else APPROVAL_NEW if target == APPROVAL_TARGET else "DERIVED_FROM_EXACT_TYPED_SOURCE_REPAIR_AFTER_ROOT_SCOPE"})
    inputs = {r["id"]: r for r in plan["pinned_inputs"]}
    assert len(inputs) == len(plan["pinned_inputs"])
    for ident in ["system_temple_pin_handoff", "temple_real_binding", "temple_real_binding_inverse", "root_temple_execution_approval", "repair_parent_actual_stage02"]:
        assert sha(resource(inputs[ident]["path"]).read_bytes()) == inputs[ident]["sha256"]
    # Final recipe old-value pointers are all based on the exact stage02 value.
    pointer_count = 0
    for row in plan["nodes"]:
        if row["kind"] != "metadata": continue
        base = oldnodes[row["id"]]["value"]
        seen = set()
        for operation in row.get("operations", []):
            keys = operation["pointer"]
            assert tuple(keys) not in seen
            seen.add(tuple(keys))
            holder = read_pointer(base, keys[:-1])
            assert (keys[-1] in holder) == operation["existed"]
            assert not operation["existed"] or holder[keys[-1]] == operation["old"]
            pointer_count += 1
    input_sha = write_new("source_finalization_input_handoff14_repair_PENDING.json", plan)
    scope_sha = write_new("handoff14_exact20_root_scope_request.json", {"status": "EXACT20_REPAIR_TARGETS_REQUESTING_ROOT_FRESH_SCOPE_NOT_CANONICAL_AUTHORIZATION", "input_sha256": input_sha, "parent_actual_receipt_sha256": sha(stagebytes), "targets": target_rows, "target_count": 20, "independent_original_pointer_checks": pointer_count, "new_approval_sha256": APPROVAL_NEW, "root_execution_approval_sha256": sha(rootapprovalbytes), "no_stager_engine_collector_or_canonical_write": True})
    print(json.dumps({"h14_pending_sha256": input_sha, "exact20_scope_request_sha256": scope_sha, "targets": 20, "pointers": pointer_count, "stager_executed": False}))


if __name__ == "__main__":
    main()
