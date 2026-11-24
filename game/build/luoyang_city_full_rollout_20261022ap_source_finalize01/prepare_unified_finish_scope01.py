"""Exact current target basis from frozen deployment receipts, no staging."""
import json
from prepare_handoff10 import HERE, resource, sha, write_new

S = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
receipts = [
    (S + "outputs/root_integration1_stage02/receipt.json", "b3ed75f8303d8b62a8cbe56b79a857309930c7493b28b216c2a11ee2110e1d39"),
    (S + "outputs/root_integration3_repair_stage03/receipt.json", "481fb21e1cd5a15a597e329ddb3e369538161aaee8cf091ab774f69092dbcae1"),
    (S + "outputs/root_integration9_market_fade_stage01/receipt.json", "596047637fe6ad52f033d8599d55bf355d435f02a43c47b656d89fd02604eaae"),
]
current = {}
for path, expected in receipts:
    raw = resource(path).read_bytes()
    assert sha(raw) == expected
    for row in json.loads(raw)["targets"]:
        current[row["target"]] = {"target": row["target"], "old_sha256": row["candidate_sha256"], "old_snapshot": row["candidate_path"], "basis_receipt": {"path": path, "sha256": expected}}
planraw = (HERE / "source_finalization_input_handoff17_repair_ROOT_LOCKED.json").read_bytes()
assert sha(planraw) == "6c8c26972186df5dac249f3fac467fc5fbe01751017ff44b30031931a55d4723"
oldplan = json.loads(planraw)
targets = {r["target"]: current[r["target"]] for r in oldplan["nodes"] if "target" in r}
envindex = "res://scripts/city/luoyang_environment_index_20261022ap.gd"
targets[envindex] = current[envindex]
systempath = "res://build/luoyang_city_full_rollout_20261022ap_system01/unified_runtime_visual_finish_candidates_v2_READY.json"
systemraw = resource(systempath).read_bytes()
assert sha(systemraw) == "84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee"
for row in json.loads(systemraw)["targets"]:
    targets[row["canonical"]] = {"target": row["canonical"], "old_sha256": row["parent_sha256"], "candidate": row["candidate"], "basis_handoff": {"path": systempath, "sha256": sha(systemraw)}}
deppath = S + "unified_finish_dependencies01/handoff_READY.json"
depraw = resource(deppath).read_bytes()
assert sha(depraw) == "6760847d3c58fad92fed3024f30c16360df894b24602cccfefda05c4ad487b58"
dep = json.loads(depraw)
for row in dep["additional_canonical_targets"]:
    targets[row["target"]] = row
execution = dep["execution_parent"]["path"]
targets[execution] = {"target": execution, "old_sha256": dep["execution_parent"]["sha256"], "candidate": dep["execution_proposal"]}
assert len(targets) == 29
for target, row in targets.items():
    assert sha(resource(target).read_bytes()) == row["old_sha256"], ("CURRENT_NOT_FROZEN_DEPLOYED_PARENT", target)
    if "old_snapshot" in row:
        assert sha(resource(row["old_snapshot"]).read_bytes()) == row["old_sha256"]
result = {"status": "REQUEST_ROOT_EXACT29_SCOPE_BACKUPS_NOT_STAGE_OR_DEPLOY_AUTHORIZATION", "targets": list(targets.values()), "target_count": 29, "build_only_shaders_and_binding_not_canonical_targets": True, "unchanged_registry696_Family_G_native_geometry_not_targets": True, "system_handoff": {"path": systempath, "sha256": sha(systemraw)}, "dependency_handoff": {"path": deppath, "sha256": sha(depraw)}, "root_execution_approval": {"path": "res://build/luoyang_city_full_rollout_20261022ap_root01/execution_unified_visual_resident_successor_authorization_READY.json", "sha256": "318ce82bd6d59dfa3203d365a1d67a45ea5b19d5750535c36fa2224e300c8c15"}, "source_only_metadata_dag_candidates_pending_root_scope": True, "no_engine_collector_stage_canonical": True}
value = write_new("unified_finish_exact29_scope_request_READY.json", result)
print(json.dumps({"scope_request_sha256": value, "targets": len(targets)}))
