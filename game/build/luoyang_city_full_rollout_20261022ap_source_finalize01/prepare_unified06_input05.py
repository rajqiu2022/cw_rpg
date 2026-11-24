"""NEW05 fixes sole stale canonical control pin from fixed EF969 snapshot.

Read-only all-input/old-pointer/active-source-group preflight, not a stager.
No expected value is derived from a current file hash or gameplay collector.
"""
import copy
import json
from prepare_handoff10 import HERE, resource, sha, same, write_new, read_pointer

S = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
raw = (HERE / "unified06_input04_ROOT_LOCKED.json").read_bytes()
assert sha(raw) == "f2b48a5870837fd9d39a24d56bf8e4ea71f365adc8153722d1b47754e1185cf8"
p = json.loads(raw)
stagepath = S + "outputs/root_unified_visual_resident_stage01/receipt.json"
stagebytes = resource(stagepath).read_bytes()
assert sha(stagebytes) == "ef969c47a3433fd160d2e70f48de30b0d14d0eb88b8ce916c3ba38c2e405f429"
stage = json.loads(stagebytes)
fixed_targets = {r["target"]: r for r in stage["targets"]}
pins = {r["id"]: r for r in p["pinned_inputs"]}
oldpin = copy.deepcopy(pins["unified_contract_parent"])
assert oldpin == {"id": "unified_contract_parent", "path": "res://data/luoyang_culture_integration_20261019x/runtime_contract.json", "sha256": "4d931f41daddaedcdee75d0d09572ef713ce0ce43cf4b15ba836552ecfeb3a5a"}
frozen = stage["nodes"]["runtime_contract_final"]
assert frozen["sha256"] == "acf3fd349454f6f25f98c0ed9de895f8a8b51c7b7a0e7732adf689b21b947b1c"
pins["unified_contract_parent"].update(path=frozen["path"], sha256=frozen["sha256"])
first = {}
def verify(path, expected):
    data = resource(path).read_bytes()
    assert sha(data) == expected, ("DECLARED_PIN_MISMATCH", path)
    first[path] = expected
    return data
parsed = {}
for row in p["pinned_inputs"]:
    data = verify(row["path"], row["sha256"])
    try:
        parsed[row["id"]] = json.loads(data)
    except (UnicodeDecodeError, json.JSONDecodeError):
        pass
authority = parsed[p["authority_input"]]
owned = {path: row["current_sha256"] for path, row in authority["owned"].items()}
prospective = {}
for path, row in authority["owned"].items():
    edge = next(e for e in reversed(row["edges"]) if e["new_sha256"] == row["current_sha256"])
    prospective[path] = {"path": edge["new_snapshot"], "sha256": row["current_sha256"]}
for row in p["pass_through_targets"]:
    prospective[row["target"]] = {"path": row["candidate_path"], "sha256": row["candidate_sha256"]}
prospective["res://data/luoyang_culture_integration_20261019x/runtime_contract.json"] = {k: pins["runtime_contract_candidate"][k] for k in ["path", "sha256"]}
nodes = {r["id"]: r for r in p["nodes"]}
pointer_checks = 0
for row in p["nodes"]:
    if "target" in row:
        assert row["old_sha256"] == fixed_targets[row["target"]]["candidate_sha256"]
        assert pins[row["base_input"]]["path"] == stage["nodes"][row["id"]]["path"]
    if row["kind"] == "index":
        continue
    base = parsed[row["base_input"]]
    seen = set()
    for op in row.get("operations", []):
        keys = op["pointer"]
        assert tuple(keys) not in seen
        seen.add(tuple(keys))
        holder = read_pointer(base, keys[:-1])
        assert (keys[-1] in holder) == op["existed"]
        assert not op["existed"] or same(holder[keys[-1]], op["old"]), (row["id"], keys)
        pointer_checks += 1
for row in p["pass_through_targets"]:
    assert row["old_sha256"] == fixed_targets[row["target"]]["candidate_sha256"]

groups = {r["id"]: r for r in p["source_groups"]}
active = set()
def include(ident):
    if ident in active:
        return
    assert ident in groups
    active.add(ident)
    for child in groups[ident].get("groups", []):
        include(child)
for node in p["nodes"]:
    for ident in node.get("groups", []) + node.get("source_bundle", {}).get("groups", []):
        include(ident)
    for field in node.get("source_fields", []):
        for ident in field.get("groups", []):
            include(ident)

deferred, leaves = [], {}
def resolve(value):
    if isinstance(value, dict) and "$pin" in value:
        assert value["$pin"] in pins
        return pins[value["$pin"]]["sha256"]
    if isinstance(value, dict) and "$owned" in value:
        assert value["$owned"] in owned
        return owned[value["$owned"]]
    if isinstance(value, dict) and "$sha" in value:
        assert value["$sha"] in nodes
        return "GENERATED:" + value["$sha"]
    return value
for ident in sorted(active):
    row = groups[ident]
    if row["kind"] == "union":
        continue
    if row["kind"] == "node_dictionary":
        assert row["node"] in nodes and row["node"] in stage["nodes"]
        assert isinstance(read_pointer(stage["nodes"][row["node"]]["value"], row["pointer"]), dict)
        deferred.append({"group": ident, "kind": "generated_metadata_table", "node": row["node"], "pointer": row["pointer"], "frozen_parent_table_verified_not_current_hash_filled": True})
        continue
    table = row["leaves"] if row["kind"] == "explicit" else read_pointer(parsed[row["input"]], row["pointer"])
    assert isinstance(table, dict)
    for path, declared in table.items():
        expected = resolve(declared)
        if row.get("promote_owned") and path in owned:
            expected = owned[path]
        if isinstance(expected, str) and expected.startswith("GENERATED:"):
            deferred.append({"group": ident, "path": path, "value": expected, "only_immutable_parent_and_declared_successor_not_computed_here": True})
            continue
        source = prospective[path]["path"] if path in prospective and prospective[path]["sha256"] == expected else path
        verify(source, expected)
        leaves[source] = expected
assert pointer_checks == 141 and len(p["root_target_allowlist"]) == 23
p["output_root"] = S + "outputs/root_unified06_numeric_stage03/"
p["pinned_parent_successor05"] = {"previous_failed_input": {"path": S + "unified06_input04_ROOT_LOCKED.json", "sha256": sha(raw)}, "sole_corrected_control_pin": {"old": oldpin, "new": pins["unified_contract_parent"], "authority": {"path": stagepath, "sha256": sha(stagebytes), "pointer": ["nodes", "runtime_contract_final"]}}, "no_tool_recipe_candidate_target_or_native_change": True}
assert all(sha(resource(path).read_bytes()) == expected for path, expected in first.items())
value = write_new("unified06_input05_ROOT_LOCKED.json", p)
audit = write_new("unified06_input05_complete_static_preflight_READY.json", {"status": "ALL_PINNED_INPUTS_AND141_TYPED_OLD_POINTERS_ACTIVE_GROUP_DECLARATIONS_STATIC_PASS_NOT_STAGER", "input_sha256": value, "fixed_parent_actual_stage": {"path": stagepath, "sha256": sha(stagebytes)}, "source_first_final_same": True, "all_pinned_inputs_count": len(p["pinned_inputs"]), "only_predecessor_bad_control_pin": {"old": oldpin, "new": pins["unified_contract_parent"]}, "old_pointer_checks": pointer_checks, "exact_target_old_values_from_EF969": 23, "active_source_groups": sorted(active), "inactive_historical_groups_preserved_not_claimed_as_runtime_sources": sorted(set(groups)-active), "non_generated_active_leaf_count": len(leaves), "deferred_generated_source_headers_and_tables": deferred, "deferred_headers_will_still_use_unchanged_tool04_full_merge_inverse_guards": True, "all_non_generated_leaf_sha256": leaves, "no_live_or_collector_hash_expected_fill": True, "no_engine_import_collector_stager_or_canonical_write": True})
print({"input_sha256": value, "static_preflight_sha256": audit, "pinned_inputs": len(p["pinned_inputs"]), "typed_old_pointers": pointer_checks, "active_groups": len(active), "fixed_leaf_count": len(leaves), "deferred_generated": len(deferred), "stager_executed": False})
