"""NEW source recipe rebased solely on deployed EF969, pending fresh23 scope."""
import copy
import json
from prepare_handoff10 import HERE, resource, sha, same, write_new, read_pointer

S = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
def load(path, expected):
    raw = resource(path).read_bytes()
    assert sha(raw) == expected, path
    return json.loads(raw)

plan = load(S + "unified_finish_input02_ROOT_LOCKED.json", "37210069e96cb9f867cb902d00073a96ea5865bb44398ec798c7200e23a5a9ba")
stagepath = S + "outputs/root_unified_visual_resident_stage01/receipt.json"
stage = load(stagepath, "ef969c47a3433fd160d2e70f48de30b0d14d0eb88b8ce916c3ba38c2e405f429")
scope = load(S + "unified06_exact23_scope_request_READY.json", "9614542daca55244fee725a88adaa32a48bf9a4fa34a478cdd19200f99cc6d29")
current = {r["target"]: r for r in scope["targets"]}
dep = load(S + "unified06_dependencies03/handoff_READY.json", "b2e73b62b7b0347c3ce9acc25a792a7e7adc8e026d92574a60e4fc22a8cad9d0")
assert dep["execution_parent"]["sha256"] == "0d06352a55047d6e39559e6f605976086b71149f195fa29017d9e5870a011dbb"
pins = {r["id"]: r for r in plan["pinned_inputs"]}
def pin(ident, path, expected):
    assert sha(resource(path).read_bytes()) == expected
    row = {"id": ident, "path": path, "sha256": expected}
    if ident in pins:
        pins[ident].update(row)
    else:
        plan["pinned_inputs"].append(row)
        pins[ident] = row

pin("execution_approval", dep["execution_proposal"]["path"], dep["execution_proposal"]["sha256"])
pin("unified_dependency_handoff", S + "unified06_dependencies03/handoff_READY.json", "b2e73b62b7b0347c3ce9acc25a792a7e7adc8e026d92574a60e4fc22a8cad9d0")
pin("root_unified_execution_approval", "res://build/luoyang_city_full_rollout_20261022ap_root01/execution_unified06_successor03_authorization_READY.json", "aca3ddda152c714887a54a9ccdfde5bcb0ceb11ea1670aabe28573ca3ffd9828")
pin("root_router06_numeric_and_eol", "res://build/luoyang_city_full_rollout_20261022ap_root01/execution_router06_numeric_and_format_authorization_READY.json", "ff10fdd974793a6875c111f91183031f5587b370b5bdc4c23a4036f52bc93479")
pin("temple_real_binding", dep["build_only_dependency"]["path"], dep["build_only_dependency"]["sha256"])
pin("repair_parent_actual_stage02", stagepath, "ef969c47a3433fd160d2e70f48de30b0d14d0eb88b8ce916c3ba38c2e405f429")
contract = next(r for r in dep["additional_canonical_targets"] if r["target"].endswith("runtime_contract.json"))
pin("runtime_contract_candidate", contract["candidate"]["path"], contract["candidate"]["sha256"])
authority = load(dep["execution_proposal"]["path"], dep["execution_proposal"]["sha256"])
for row in plan["prospective_targets"]:
    value = authority["owned"][row["target"]]
    edge = next(e for e in reversed(value["edges"]) if e["new_sha256"] == value["current_sha256"])
    row.update(candidate_path=edge["new_snapshot"], sha256=value["current_sha256"])
envindex = "res://scripts/city/luoyang_environment_index_20261022ap.gd"
for node in plan["nodes"]:
    if node["kind"] == "map":
        continue  # Four original fixed AO baselines/old operations stay exact.
    ident = node["id"]
    if node.get("target") == envindex:
        node.pop("target")
        node.pop("old_sha256")
    previous = stage["nodes"][ident]
    baseid = "unified06_current_" + ident
    pin(baseid, previous["path"], previous["sha256"])
    node["base_input"] = baseid
    if "target" in node:
        assert current[node["target"]]["old_sha256"] == previous["sha256"]
        node["old_sha256"] = previous["sha256"]
    if node["kind"] == "index":
        replacements = []
        if ident != "ap_environment_index":
            for hunk in node["replacements"]:
                new = hunk["new"]
                if isinstance(new, dict):
                    old = stage["nodes"][new["$sha"]]["sha256"] if "$sha" in new else dep["execution_parent"]["sha256"]
                    replacements.append({"old": old, "new": new})
        node["replacements"] = replacements + [{"old": node["enabled_literal"], "new": node["disabled_literal"]}]
        continue
    base = load(previous["path"], previous["sha256"])
    if ident == "runtime_contract_final":
        next_value = load(contract["candidate"]["path"], contract["candidate"]["sha256"])
        router = "res://scripts/autoload/scene_router.gd"
        node["operations"] = [{"op": "set", "pointer": ["source_sha256", router], "existed": True, "old": base["source_sha256"][router], "new": next_value["source_sha256"][router]}]
        check = copy.deepcopy(next_value)
        check["source_sha256"][router] = base["source_sha256"][router]
        assert same(check, base)
    else:
        for operation in node.get("operations", []):
            holder = read_pointer(base, operation["pointer"][:-1])
            operation["existed"] = operation["pointer"][-1] in holder
            if operation["existed"]:
                operation["old"] = copy.deepcopy(holder[operation["pointer"][-1]])
    if ident == "registry_final":
        assert not node["operations"] and all(not r["promote_owned"] for r in node["source_fields"])

plan["pass_through_targets"] = [{"target": p, "old_sha256": r["old_sha256"], "candidate_path": r["candidate"]["path"], "candidate_sha256": r["candidate"]["sha256"]} for p, r in current.items() if p in authority["owned"] or p == dep["execution_parent"]["path"]]
assert len(plan["pass_through_targets"]) == 4
plan["root_target_allowlist"] = list(current)
assert len(current) == 23 and set(current) == {r["target"] for r in plan["nodes"] if "target" in r} | {r["target"] for r in plan["pass_through_targets"]}
plan["required_gates"] = [r for r in plan["required_gates"] if r["id"] != "root_target_preauthorization"]
plan["status"] = "PENDING_ROOT_FRESH_EXACT23_SCOPE_NOT_EXECUTABLE"
plan["blockers"] = ["Root fresh integration11 exact23 scope/backups pin required; all old EF969/FAIL/native/QA component results preserved; only E remainder after actual deployment."]
plan["output_root"] = S + "outputs/root_unified06_numeric_stage01/"
plan["required_generator"] = {"path": S + "stage_unified06_03_READY.py", "sha256": "68902a20a896bb3ae0e56c509e3e275f9b47bb7f6a9696d7a871ac372803a5de", "root_must_read_before_execution": True}
plan["predecessor_input"] = {"path": S + "unified_finish_input02_ROOT_LOCKED.json", "sha256": "37210069e96cb9f867cb902d00073a96ea5865bb44398ec798c7200e23a5a9ba", "actual_stage": {"path": stagepath, "sha256": "ef969c47a3433fd160d2e70f48de30b0d14d0eb88b8ce916c3ba38c2e405f429"}}
plan["unified_dependency_parent"] = {"execution_parent": dep["execution_parent"], "execution_successor": dep["execution_proposal"], "original44proof_exact": True, "only3owned_append": True, "root_approval": pins["root_unified_execution_approval"]}
plan["repair_epoch_contract"] = {"actual_deployed_parent": plan["predecessor_input"]["actual_stage"], "exact23_noop_envindex_and_other5_excluded": True, "environment_index_fixed_node_only_same_bytes": True, "native_geometry_and_import_replay": False, "runtime_contract_exact_router_one_source_value": True, "new43_or_whole_current_collector_expected_fill": False}
plan.pop("root_authorized_byte_copy_successor", None)
value = write_new("unified06_input03_PENDING.json", plan)
print({"input_sha256": value, "targets": 23, "source_template_only": True, "stager_executed": False})
