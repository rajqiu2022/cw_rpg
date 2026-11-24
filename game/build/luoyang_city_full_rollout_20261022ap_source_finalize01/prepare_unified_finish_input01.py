"""NEW unified source recipe only. Does not execute staging or collectors."""
import copy
import json
from prepare_handoff10 import HERE, resource, sha, write_new, read_pointer

S = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
SYS = "res://build/luoyang_city_full_rollout_20261022ap_system01/"
DEP = S + "unified_finish_dependencies01/"
def pinned(path, expected):
    raw = resource(path).read_bytes()
    assert sha(raw) == expected, ("PIN", path)
    return json.loads(raw)

scope = pinned(S + "unified_finish_exact29_scope_request_READY.json", "2d0722677898290e7dbe69e14103644b2ee2ab79104ada57b7cc9fa37e25647b")
current = {r["target"]: r for r in scope["targets"]}
oldplan = pinned(S + "source_finalization_input_handoff17_repair_ROOT_LOCKED.json", "6c8c26972186df5dac249f3fac467fc5fbe01751017ff44b30031931a55d4723")
plan = copy.deepcopy(oldplan)
pins = {r["id"]: r for r in plan["pinned_inputs"]}
def pin(ident, path, expected):
    raw = resource(path).read_bytes()
    assert sha(raw) == expected
    row = {"id": ident, "path": path, "sha256": expected}
    if ident in pins:
        pins[ident].update(row)
    else:
        plan["pinned_inputs"].append(row)
        pins[ident] = row
    return row

system = pinned(SYS + "unified_runtime_visual_finish_candidates_v2_READY.json", "84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee")
systemtargets = {r["canonical"]: r for r in system["targets"]}
dep = pinned(DEP + "handoff_READY.json", "6760847d3c58fad92fed3024f30c16360df894b24602cccfefda05c4ad487b58")
authority = pinned(dep["execution_proposal"]["path"], dep["execution_proposal"]["sha256"])
pin("execution_approval", dep["execution_proposal"]["path"], dep["execution_proposal"]["sha256"])
pin("unified_system_candidates", SYS + "unified_runtime_visual_finish_candidates_v2_READY.json", "84cee79025acadd0e87bbba2e0d3cfa4c3f97aa9fdebc973a9417d301a3871ee")
pin("unified_dependency_handoff", DEP + "handoff_READY.json", "6760847d3c58fad92fed3024f30c16360df894b24602cccfefda05c4ad487b58")
pin("root_unified_execution_approval", "res://build/luoyang_city_full_rollout_20261022ap_root01/execution_unified_visual_resident_successor_authorization_READY.json", "318ce82bd6d59dfa3203d365a1d67a45ea5b19d5750535c36fa2224e300c8c15")
pin("docks22_lineage", S + "docks22_frozen_registry_lineage_retry1_READY.json", "2e2134ac6ae883e67636adbc751fedbcd3d1e8150d2b1c123ac889537c9147c1")
for ident, target in [("environment_helper", "res://scripts/city/luoyang_environment_layer_20261022ap.gd"), ("environment_final", "res://data/maps/luoyang_full_city_20261022ap/environment.json")]:
    row = systemtargets[target]["candidate"]
    pin(ident, row["path"], row["sha256"])
contractrow = next(r for r in dep["additional_canonical_targets"] if r["target"].endswith("runtime_contract.json"))
pin("runtime_contract_candidate", contractrow["candidate"]["path"], contractrow["candidate"]["sha256"])
for row in plan["prospective_targets"]:
    if row["target"] in authority["owned"]:
        value = authority["owned"][row["target"]]
        edge = next(e for e in reversed(value["edges"]) if e["new_sha256"] == value["current_sha256"])
        row.update(candidate_path=edge["new_snapshot"], sha256=value["current_sha256"])

# Current metadata input bytes are frozen deployment outputs, not a new disk
# crawl and not old AO expected collectors. Keep original four map baselines.
stage02 = pinned(S + "outputs/root_integration1_stage02/receipt.json", "b3ed75f8303d8b62a8cbe56b79a857309930c7493b28b216c2a11ee2110e1d39")
stage03 = pinned(S + "outputs/root_integration3_repair_stage03/receipt.json", "481fb21e1cd5a15a597e329ddb3e369538161aaee8cf091ab774f69092dbcae1")
nodes_by_id = {r["id"]: r for r in plan["nodes"]}
nodes_by_id["ap_environment_index"]["target"] = "res://scripts/city/luoyang_environment_index_20261022ap.gd"
target_ids = {r["target"]: r["id"] for r in plan["nodes"] if "target" in r}
changed_refs = {}
for target, row in systemtargets.items():
    changed_refs[target] = {"$pin": "environment_helper"} if target.endswith("environment_layer_20261022ap.gd") else {"$pin": "environment_final"} if target.endswith("/environment.json") else row["candidate"]["sha256"]
for row in dep["additional_canonical_targets"]:
    changed_refs[row["target"]] = {"$pin": "runtime_contract_candidate"} if row["target"].endswith("runtime_contract.json") else {"$owned": row["target"]}
changed_refs[dep["execution_parent"]["path"]] = {"$pin": "execution_approval"}
for target, ident in target_ids.items():
    changed_refs[target] = {"$sha": ident}

for node in plan["nodes"]:
    if node["kind"] == "map":
        continue
    ident = node["id"]
    if "target" in node:
        basis = current[node["target"]]
        node["old_sha256"] = basis["old_sha256"]
        basepath = basis["old_snapshot"]
        basesha = basis["old_sha256"]
    else:
        assert ident == "registry_final"
        basepath, basesha = stage02["nodes"][ident]["path"], stage02["nodes"][ident]["sha256"]
    basepin = "unified_current_" + ident
    pin(basepin, basepath, basesha)
    node["base_input"] = basepin
    node.pop("derived_parent", None)
    if node["kind"] == "index":
        prior = stage03["nodes"].get(ident, stage02["nodes"].get(ident))
        replacements = []
        if ident == "ap_environment_index":
            replacements = [{"old": "5a9994d84b4a2adf6d8e02048fce236bd433d6b163b1aaec5cdb8ea992cbc98f", "new": {"$pin": "environment_final"}}]
        else:
            for hunk in node["replacements"]:
                new = hunk["new"]
                if not isinstance(new, dict):
                    continue
                if "$sha" in new:
                    depid = new["$sha"]
                    if depid == "market_final":
                        old = current[nodes_by_id[depid]["target"]]["old_sha256"]
                    else:
                        old = stage03["nodes"].get(depid, stage02["nodes"].get(depid))["sha256"]
                else:
                    assert new == {"$pin": "execution_approval"}
                    old = dep["execution_parent"]["sha256"]
                replacements.append({"old": old, "new": new})
        node["replacements"] = replacements + [{"old": node["enabled_literal"], "new": node["disabled_literal"]}]
        continue
    base = pinned(basepath, basesha)
    operations = []
    for operation in node.get("operations", []):
        operation = copy.deepcopy(operation)
        holder = read_pointer(base, operation["pointer"][:-1])
        operation["existed"] = operation["pointer"][-1] in holder
        if operation["existed"]:
            operation["old"] = copy.deepcopy(holder[operation["pointer"][-1]])
        operations.append(operation)
    fields = [r["pointer"] for r in node.get("source_fields", [])] or node.get("source_bundle", {}).get("fields", [])
    if ident == "registry_final":
        operations = []
        for field in node["source_fields"]:
            field["promote_owned"] = False
        node["operations"] = []
        continue
    # Explicit existing nonowned successors before guarded source group merges.
    for field in fields:
        for path, old in read_pointer(base, field).items():
            if path not in changed_refs:
                continue
            pointer = field + [path]
            existing = [op for op in operations if op["pointer"] == pointer]
            assert len(existing) <= 1
            if existing:
                existing[0]["new"] = changed_refs[path]
            else:
                operations.append({"op": "set", "pointer": pointer, "existed": True, "old": old, "new": changed_refs[path]})
    node["operations"] = operations

# Exact source-only two-value contract with original raw candidate output.
contractbase = contractrow["target"]
contractoldpin = pin("unified_contract_parent", contractbase, contractrow["old_sha256"])
contract0 = pinned(contractoldpin["path"], contractoldpin["sha256"])
contractnew = pinned(contractrow["candidate"]["path"], contractrow["candidate"]["sha256"])
contractnode = {"id": "runtime_contract_final", "kind": "metadata", "base_input": "unified_contract_parent", "target": contractbase, "old_sha256": contractrow["old_sha256"], "file": "runtime_contract_source_successor.json", "source_policy": "old_city_or_market", "operations": [{"op": "set", "pointer": ["source_sha256", p], "existed": True, "old": contract0["source_sha256"][p], "new": contractnew["source_sha256"][p]} for p in ["res://scripts/field/field_walkable_controller.gd", "res://scripts/autoload/scene_router.gd"]], "literal_candidate_input": "runtime_contract_candidate"}
plan["nodes"].insert(0, contractnode)
groups = {r["id"]: r for r in plan["source_groups"]}
rect = SYS + "visual_transition_successor02_retry2/environment_rect_color_once_READY.gdshader"
union = SYS + "visual_transition_successor02_retry2/artisan_ground_union_exterior_READY.gdshader"
newgroups = [
    {"id": "unified_rect_shader", "kind": "explicit", "leaves": {rect: "8dab8ea0515d4cc94ff89595c287d2513cb3a8d47dcd36edb1d7ed74a796ae53"}},
    {"id": "unified_shared_quarter_union_proof", "kind": "explicit", "leaves": {union: "411bceeec31d10025ff17e21e36b416054425e916e04ee39e91038b709acda83"}},
    {"id": "unified_docks22", "kind": "input_dictionary", "input": "docks22_lineage", "pointer": ["source_sha256"]},
    {"id": "unified_market_portrait", "kind": "explicit", "leaves": {
        "res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png": "4fba998b313e66b60f62804ea8968b25742dc5825a76921743265e6a26031dcc",
        "res://art/portraits/luoyang_city_finish_20261022ap/examiner_mature_v1.png.import": "284ed8f2af70e4b9d499fb561cb0ab88f299394690f6c9baf1b99149d85ee2b1",
        "res://.godot/imported/examiner_mature_v1.png-25f2af75a741a5e611494715946e4a2e.ctex": "b3140dfd0ebea21c80bab0f310802ffc2e85907a386ea4c614879442f2436cac"}},
]
plan["source_groups"] += newgroups
groups["common_four_city"]["groups"].append("unified_rect_shader")
nodes_by_id["legacy_manifest_7"]["source_bundle"]["groups"].append("unified_docks22")
nodes_by_id["quarter_final"]["source_fields"][0]["groups"] += ["unified_rect_shader", "unified_shared_quarter_union_proof"]
nodes_by_id["market_final"]["source_bundle"]["groups"].append("unified_market_portrait")
# The two full Quarter collectors inherit one shared proof set. Only Artisan
# ENV installs union material; Garden does not claim union consumption.
plan["unified_visual_source_contract"] = {"quarter_union_shared_proof_both_collectors_artisan_install_only": True, "portrait_environment_declaration_market_only": True, "docks22_derived_from_fixed_registry_G_not_actual_hashes": True, "no_native_geometry_task_or_OWNED_schema_change": True}
plan["pass_through_targets"] = []
for target in [*systemtargets, *(r["target"] for r in dep["additional_canonical_targets"] if not r["target"].endswith("runtime_contract.json")), dep["execution_parent"]["path"]]:
    row = current[target]
    candidate = row["candidate"]
    record = {"target": target, "old_sha256": row["old_sha256"], "candidate_path": candidate["path"], "candidate_sha256": candidate["sha256"]}
    if target in systemtargets and target not in authority["owned"]:
        record["system_offset_candidate"] = True
    plan["pass_through_targets"].append(record)
plan["root_target_allowlist"] = list(current)
assert set(plan["root_target_allowlist"]) == {r["target"] for r in plan["pass_through_targets"]} | {r["target"] for r in plan["nodes"] if "target" in r}
plan["required_gates"] = [r for r in plan["required_gates"] if r["id"] != "root_target_preauthorization"]
plan["status"] = "PENDING_ROOT_EXACT29_SCOPE_NOT_EXECUTABLE"
plan["blockers"] = ["Await Root exact29 scope/backups pin; then add fifth gate and external input lock. No engine or stager executed."]
plan["output_root"] = S + "outputs/root_unified_visual_resident_stage01/"
plan["required_generator"] = {"path": S + "stage_unified_finish01_READY.py", "sha256": "530314b0e22db531072e477d24171c5882dd37567ee660bdb26117172bda8125", "root_must_read_before_execution": True}
plan["unified_dependency_parent"] = {"execution_parent": dep["execution_parent"], "execution_successor": dep["execution_proposal"], "original37proof_exact": True, "only4owned_append": True, "root_approval": pins["root_unified_execution_approval"]}
value = write_new("unified_finish_input01_PENDING.json", plan)
print(json.dumps({"input_sha256": value, "targets": len(current), "nodes": len(plan["nodes"]), "stager_executed": False}))
