"""Prepare only the Root-approved single historical-row source recipe."""
import json
from prepare_handoff10 import HERE, resource, sha, write_new

P = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
pins = {
    "root_scope": {"path": "res://build/luoyang_city_full_rollout_20261022ap_root01/integration9/scope_READY.json", "sha256": "01b8340ef2bff9b0984098165b5a726b5549cd6dbc9ebe855bcd3b004b0d279c"},
    "parent_stage": {"path": P + "outputs/root_integration8_market_identity_stage02/receipt.json", "sha256": "c316ca8e4fd18b8c9296af405b6bc5e490a409db2d15915a1b83ae573fba506e"},
    "parent_owners": {"path": P + "market_identity2_retry1_actual_independent_qa_owner_source_maps_READY.json", "sha256": "b2dba75b3ca0713c616b1b24ef55dd53fc1213ee5d000d99e40a1cd1254dda1b"},
    "frozen_ao": {"path": "res://build/luoyang_market_two_shops_20261021ao_system01/staged_dependency_retry3/ao_manifest.json", "sha256": "c2cff298136ce4a3e97d6d0b87be3c9fe3c6a7577a8185b5bf1547f36477b19e"},
    "district_binding": {"path": "res://data/maps/luoyang_district_life_20261016f/binding.json", "sha256": "8bce718d3bfb363d15b9845aeedd113e02ff7cf7ef107ca94d3983363f33b668"},
}
for row in pins.values():
    assert sha(resource(row["path"]).read_bytes()) == row["sha256"]
tool = HERE / "stage_market_fade_history2_READY.py"
compile(tool.read_bytes(), str(tool), "exec")
spec = {"schema_version": 1, "status": "ROOT_LOCKED_MARKET_SINGLE_FADE_HISTORY_TWO_TARGETS", "output_root": P + "outputs/root_integration9_market_fade_stage01/", "pinned_inputs": pins, "required_generator": {"path": P + tool.name, "sha256": sha(tool.read_bytes()), "pure_patch_utility_sha256": "23f21249602117ae9a3e638c94d5b1a17725d3bc1e9464912115a7ba3da776b4", "root_must_read_before_execution": True}, "scope": "Only source_migration={source_delta:{fade: frozenC2C row}}; do not inherit other11 AO rows; index one manifest SHA literal; all sourcekeys/native/geometry/production code unchanged; future fresh exact-candidate deployment authorization required"}
assert not resource(spec["output_root"]).exists()
result = write_new("market_fade_history2_ROOT_LOCKED.json", spec)
print(json.dumps({"input_sha256": result, "tool_sha256": spec["required_generator"]["sha256"], "targets": 2, "stager_executed": False}))
