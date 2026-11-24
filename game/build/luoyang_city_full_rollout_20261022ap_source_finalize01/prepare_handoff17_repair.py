"""Explicitly close every existing nonowned generated header before merges.

No stager/engine/canonical mutation. Declared old values come only from pinned
stage02 metadata inputs and their actual historical target receipts.
"""
from __future__ import annotations

import json

from prepare_handoff10 import HERE, GAME, resource, sha, write_new, read_pointer


def main():
    before = (HERE / "source_finalization_input_handoff16_repair_ROOT_LOCKED.json").read_bytes()
    assert sha(before) == "82bec2b482c9ea24920ec31925a2222d4f79a3cd36f1ab500fb2bbf2dad84af1"
    plan = json.loads(before)
    inputs = {r["id"]: r for r in plan["pinned_inputs"]}
    parent_pin = inputs["repair_parent_actual_stage02"]
    parentbytes = resource(parent_pin["path"]).read_bytes()
    assert sha(parentbytes) == parent_pin["sha256"]
    parent = json.loads(parentbytes)
    parent_targets = {r["target"]: r for r in parent["targets"]}
    generated = {r["target"]: r["id"] for r in plan["nodes"] if "target" in r}
    failure_path = "res://build/luoyang_city_full_rollout_20261022ap_root01/integration3/source_repair_stage02_failure.json"
    failure_bytes = resource(failure_path).read_bytes()
    failure = json.loads(failure_bytes)
    assert failure["natural_os_exit"] == 1 and "UNDECLARED_EXISTING_SOURCE_REPLACEMENT:" in failure["error"]
    plan["pinned_inputs"].append({"id": "actual_repair_stage02_failure_preserved", "path": failure_path, "sha256": sha(failure_bytes)})
    scanned, added, existing = [], [], []
    for node in plan["nodes"]:
        if node["kind"] != "metadata":
            continue
        pin = inputs[node["base_input"]]
        raw = resource(pin["path"]).read_bytes()
        assert sha(raw) == pin["sha256"]
        base = json.loads(raw)
        fields = [r["pointer"] for r in node.get("source_fields", [])] or node.get("source_bundle", {}).get("fields", [])
        operations = node.get("operations", [])
        for field in fields:
            values = read_pointer(base, field)
            for path, old in values.items():
                if path not in generated:
                    continue
                target = parent_targets[path]
                assert old in {target["candidate_sha256"], target["old_sha256"]}, ("UNPROVEN_HISTORICAL_GENERATED_HEADER", node["id"], path, old)
                pointer = field + [path]
                new = {"$sha": generated[path]}
                row = {"node": node["id"], "pointer": pointer, "old": old, "new": new, "basis": "pinned stage02 field + actual stage02 canonical target old/next succession"}
                scanned.append(row)
                matches = [op for op in operations if op["pointer"] == pointer]
                assert len(matches) <= 1
                if matches:
                    assert matches[0]["old"] == old and matches[0]["new"] == new, ("EXISTING_GENERATED_HEADER_OP_DISAGREES", node["id"], path)
                    existing.append(row)
                else:
                    operations.append({"op": "set", "pointer": pointer, "existed": True, "old": old, "new": new})
                    added.append(row)
        node["operations"] = operations
    assert any(r["node"] == "market_final" and r["pointer"][-1] == "res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json" and r["old"] == "8e365f033daeacf1a56ccc22130dc50099d21f9274327f16beaec6f44b47f22c" for r in added)
    # Validate every source-field generated header is now declared exactly once.
    for row in scanned:
        node = next(r for r in plan["nodes"] if r["id"] == row["node"])
        ops = [op for op in node["operations"] if op["pointer"] == row["pointer"]]
        assert len(ops) == 1 and ops[0]["old"] == row["old"] and ops[0]["new"] == row["new"]
    plan["output_root"] = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/outputs/root_integration3_repair_stage03/"
    assert not resource(plan["output_root"]).exists()
    plan["predecessor_input"] = {"path": "res://" + (HERE / "source_finalization_input_handoff16_repair_ROOT_LOCKED.json").relative_to(GAME).as_posix(), "sha256": sha(before), "actual_failed_before_buffered_output_write": True}
    plan["repair_epoch_contract"]["all_existing_generated_nonowned_headers_explicit_old_next_scan"] = {"scanned": len(scanned), "existing_operations": len(existing), "new_operations": len(added), "no_tool_merge_relaxation": True}
    assert len(plan["root_target_allowlist"]) == 20
    result = write_new("source_finalization_input_handoff17_repair_ROOT_LOCKED.json", plan)
    audit = write_new("handoff17_all_nonowned_header_successions_static_scan.json", {
        "status": "EXACT_SOURCE_ONLY_HEADER_OPERATIONS_COMPLETE_STATIC_SCAN_NOT_STAGER",
        "input_sha256": result, "scanned": scanned, "new_operations": added, "existing_operations": existing,
        "target_count_unchanged": 20, "scope_unchanged": "7328d3aff83bcd611166672eaa79b9c3eb9f2a91070f3522b6752dcb0b1f707e",
        "retry5_tool_unchanged_sha256": "23f21249602117ae9a3e638c94d5b1a17725d3bc1e9464912115a7ba3da776b4",
        "failure_preserved_sha256": sha(failure_bytes), "no_engine_stager_collector_or_canonical_write": True,
    })
    print(json.dumps({"h17_sha256": result, "static_scan_sha256": audit, "scanned": len(scanned), "added": len(added), "targets": 20, "stager_executed": False}))


if __name__ == "__main__":
    main()
