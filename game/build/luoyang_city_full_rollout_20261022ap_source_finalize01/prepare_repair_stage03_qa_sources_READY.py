"""Independent typed inverse and source-domain assembly from fixed stage02.

Never calls Godot, the stager or any live collector. Never derives expected
values by hashing canonical current files. Sources are explicit pinned tables,
fixed runtime interfaces and actual metadata-stage nodes, not gameplay output.
"""
from __future__ import annotations

import copy
import argparse
import json

from prepare_handoff10 import HERE, GAME, SYS, resource, sha, write_new, same, read_pointer

STAGE = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/outputs/root_integration3_repair_stage03/receipt.json"
PLAN_SHA = "6c8c26972186df5dac249f3fac467fc5fbe01751017ff44b30031931a55d4723"
CITY_C = "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
G = "res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
EF = "res://scripts/city/luoyang_estate_family_20261021am.gd"
QF = "res://scripts/city/luoyang_quarters_family_20261022ap.gd"


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--actual-stage-receipt-sha256", required=True, help="Root-provided external exact actual repair receipt pin; never inferred from current bytes")
    args = parser.parse_args()
    STAGE_SHA = args.actual_stage_receipt_sha256
    assert len(STAGE_SHA) == 64 and all(c in "0123456789abcdef" for c in STAGE_SHA)
    raw = (HERE / "source_finalization_input_handoff17_repair_ROOT_LOCKED.json").read_bytes()
    assert sha(raw) == PLAN_SHA
    plan = json.loads(raw)
    stagebytes = resource(STAGE).read_bytes()
    assert sha(stagebytes) == STAGE_SHA
    stage = json.loads(stagebytes)
    assert same(stage["source_first"], stage["source_final"])
    assert stage["status"] == "AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED"
    assert stage["target_partition"] == {"patch_count": 19, "copy_count": 1, "total": 20, "intersection_empty": True, "union_exact_targets": True}
    inputs = {r["id"]: r for r in plan["pinned_inputs"]}
    nodes = stage["nodes"]
    def read_pin(path, expected):
        data = resource(path).read_bytes()
        assert sha(data) == expected, ("PIN_CHANGED", path)
        return json.loads(data)
    def read_input(ident):
        pin = inputs[ident]
        return read_pin(pin["path"], pin["sha256"])
    approval = read_input("execution_approval")
    current = {p: r["current_sha256"] for p, r in approval["owned"].items()}
    targets = {r["target"]: r for r in stage["targets"]}
    assert len(targets) == 20 and set(targets) == set(plan["root_target_allowlist"])
    parent_pin = inputs["repair_parent_actual_stage02"]
    parent_stage = json.loads(resource(parent_pin["path"]).read_bytes())
    assert sha(resource(parent_pin["path"]).read_bytes()) == parent_pin["sha256"]
    full_target_hashes = {r["target"]: r["candidate_sha256"] for r in parent_stage["targets"]}
    full_target_hashes.update({p: r["candidate_sha256"] for p, r in targets.items()})
    for row in targets.values():
        assert sha(resource(row["candidate_path"]).read_bytes()) == row["candidate_sha256"]
    inverse_checks = {}
    for row in plan["nodes"]:
        node, proof = nodes[row["id"]], stage["proofs"][row["id"]]
        assert sha(resource(node["path"]).read_bytes()) == node["sha256"]
        if row["kind"] != "metadata":
            continue
        restored = copy.deepcopy(node["value"])
        for delta in reversed(proof["source_delta"]):
            container = read_pointer(restored, delta["pointer"][:-1])
            key = delta["pointer"][-1]
            if delta["existed"]: container[key] = delta["old"]
            else: del container[key]
        assert same(restored, read_input(row["base_input"])), ("INDEPENDENT_TYPED_WHOLE_INVERSE", row["id"])
        inverse_checks[row["id"]] = {"independent_reconstructed_typed_parent_equal": True, "operations": len(proof["source_delta"])}
    byteplan = read_pin(stage["byte_copy_plan"]["path"], stage["byte_copy_plan"]["sha256"])
    assert len(byteplan["rows"]) == 1 and byteplan["patch_copy_disjoint"] and byteplan["patch_copy_union_exact_targets"]
    assert set(byteplan["patch_targets"]) | set(byteplan["copy_targets"]) == set(targets)
    assert not set(byteplan["patch_targets"]) & set(byteplan["copy_targets"])
    assert byteplan["rows"][0]["candidate_sha256"] == "80a3899ef84551a7804517cd31123881dddaacdc66ecc805def63a431e0e3e11"

    # Independent source-table recipe evaluator; no metadata generation, patch
    # construction, executable load, collector call or current-disk expected fill.
    groups = {r["id"]: r for r in plan["source_groups"]}
    def resolve(value):
        if isinstance(value, dict) and "$sha" in value:
            return nodes[value["$sha"]]["disabled_sha256" if value.get("variant") == "disabled" else "sha256"]
        if isinstance(value, dict) and set(value) == {"$pin"}: return inputs[value["$pin"]]["sha256"]
        if isinstance(value, dict) and set(value) == {"$owned"}: return current[value["$owned"]]
        if isinstance(value, dict): return {k: resolve(v) for k, v in value.items()}
        if isinstance(value, list): return [resolve(v) for v in value]
        return value
    def promote(table):
        return {p: current.get(p, v) for p, v in table.items()}
    def merge(*tables):
        out = {}
        for table in tables:
            for path, value in table.items():
                value = current.get(path, value)
                assert path not in out or out[path] == value, ("SOURCE_RECIPE_COLLISION", path, out.get(path), value)
                out[path] = value
        return out
    def group(ident, stack=()):
        assert ident not in stack
        row = groups[ident]
        if row["kind"] == "explicit": result = resolve(row["leaves"])
        elif row["kind"] == "input_dictionary": result = read_pointer(read_input(row["input"]), row["pointer"])
        elif row["kind"] == "node_dictionary": result = read_pointer(nodes[row["node"]]["value"], row["pointer"])
        elif row["kind"] == "union": result = merge(*(group(child, stack + (ident,)) for child in row["groups"]))
        else: raise ValueError("UNKNOWN_RECIPE_GROUP")
        return promote(result) if row.get("promote_owned") else copy.deepcopy(result)
    def target_sha(path):
        return full_target_hashes[path]
    baseline = read_input("baseline_ch4_s2_canal_docks")["source_sha256"]
    def historical_leaf(path):
        assert path in baseline, ("MISSING_FIXED_AO_SOURCE_LEAF", path)
        return current.get(path, baseline[path])
    def selected_headers(paths):
        return {p: target_sha(p) if p in full_target_hashes else historical_leaf(p) for p in paths}
    execution = merge(group("authority_header"), group("authority_before_and_candidate_proofs"), {"res://scripts/city/luoyang_execution_index_20261022ap.gd": nodes["ap_execution_index"]["sha256"]})
    people = merge(group("quarter_people_old_sources"), group("quarter_people_module_proof"), execution)
    npc = merge(group("npc_old_sources"), group("npc_module_proof"), execution)
    environment = merge(group("environment_sources"), group("environment_header"), {"res://scripts/city/luoyang_environment_index_20261022ap.gd": nodes["ap_environment_index"]["sha256"]})

    # G2E305.source_paths lines133-166: all family rows, not a per-room subset.
    old_registry_path = "res://data/maps/luoyang_assembled_interiors_20261016g/registry_spacing_dependency_v3.json"
    old_registry = read_pin(old_registry_path, "959bc6f5408261586a6165bf731347959e6287bea9afa8bfb40f6e4035302ad5")
    registry = nodes["registry_final"]["value"]
    g_headers = selected_headers([
        G, "res://scripts/city/luoyang_layout_room_index_20261018t.gd",
        "res://data/maps/luoyang_layout_rooms_20261018t/registry.json",
        "res://build/luoyang_layout_quest_20261018t_layout_source01/g_geometry_original.gd",
        old_registry_path, "res://data/maps/luoyang_estate_rooms_20261021am/registry.json",
        "res://build/luoyang_market_two_shops_20261021ao_system01/before/registry_AN_167F.json",
        EF, "res://scripts/city/luoyang_estate_index_20261021am.gd",
        "res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json",
        "res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd",
    ])
    g_headers.update(group("G_new_return_header_only"))
    prior_room_headers = {}
    for row in old_registry["rooms"].values():
        for key in ["author_path", "scene_path", "layout_path"]:
            prior_room_headers[row[key]] = historical_leaf(row[key])
    g_complete = merge(g_headers, old_registry["source_sha256"], prior_room_headers, *(row["source_sha256"] for row in registry["rooms"].values()), execution)

    # TempleBF65.source_paths lines89-107, including task/presentation sources.
    temple_bind_path = inputs["temple_real_binding"]["path"]
    temple_bind_sha = inputs["temple_real_binding"]["sha256"]
    assert temple_bind_sha == "cc9dec2b08cb58e6a192a41e3e1bdc508f42f4a81317e0eb074ca6b13752414c"
    temple_bind = read_pin(temple_bind_path, temple_bind_sha)
    parent = read_pin(temple_bind["parent_binding_path"], temple_bind["parent_binding_sha256"])
    temple_config_sources = copy.deepcopy(parent["source_sha256"])
    temple_config_sources.update(temple_bind["source_delta"])
    task_spec_path = "res://data/luoyang_city_tasks_20261016/overlay.json"
    task_spec = read_pin(task_spec_path, "9e654f67be48a8da93232e0f2b66e109cdd769577fb53545f72f81885e90a3bb")
    task_binding_path = "res://build/luoyang_layout_quest_20261018t_task_integration_source01/task_runtime_binding.json"
    task_binding = read_pin(task_binding_path, "28c74795ce107f9e6a5f845394dad7e7ffe0969a45502d8c46aa128ce8a4406e")
    tasks = merge(task_spec["source_pins"], task_binding["source_sha256"], {task_spec_path: "9e654f67be48a8da93232e0f2b66e109cdd769577fb53545f72f81885e90a3bb", task_binding_path: "28c74795ce107f9e6a5f845394dad7e7ffe0969a45502d8c46aa128ce8a4406e", "res://scripts/city/luoyang_city_tasks_20261016.gd": current["res://scripts/city/luoyang_city_tasks_20261016.gd"]}, npc)
    temple_headers = selected_headers([
        "res://scripts/city/luoyang_temple_assembly_20261016.gd",
        "res://data/scenes/luoyang_temple_layout_quest_20261018t/temple.tres",
        "res://data/maps/luoyang_temple_layout_quest_20261018t/layout.tres",
        "res://data/scenes/ch4_s4_ancient_temple.tres",
        "res://data/maps/ch4_s4_ancient_temple_layout_v1.tres",
        "res://scripts/city/luoyang_temple_task_adapter_20261016.gd",
        "res://scripts/city/luoyang_temple_fade_20261016.gd",
        "res://scripts/autoload/scene_router.gd", "res://scripts/field/field_walkable_controller.gd", CITY_C,
    ])
    temple_headers.update({temple_bind_path: temple_bind_sha, temple_bind["parent_binding_path"]: temple_bind["parent_binding_sha256"]})
    temple_complete = merge(temple_config_sources, temple_headers, tasks, environment, people)

    scene_sources = {}
    for row in plan["nodes"]:
        if row["kind"] == "map":
            source = nodes[row["id"]]["value"]["source_sha256"]
            scene_sources[row["scene_id"]] = {"id": row["scene_id"], "owner": "C", "owner_path": CITY_C, "source_sha256": source, "receipt_source_sha256": copy.deepcopy(source), "recipe": "fixed AO map + explicit h13 source groups/operations; Stage02 independent expected map, not actual collector"}
    quarter = nodes["quarter_final"]["value"]
    q_header = {QF: target_sha(QF), "res://scripts/city/luoyang_quarters_index_20261022ap.gd": nodes["ap_quarter_index"]["sha256"], "res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json": nodes["quarter_final"]["sha256"]}
    for ident in quarter["scenes"]:
        scene_sources[ident] = {"id": ident, "owner": "Quarter", "owner_path": QF, "source_sha256": merge(quarter["source_sha256"], q_header), "receipt_source_sha256": quarter["source_sha256"], "recipe": "Quarter.source_paths = manifest source +3header; validation_receipt source excludes3header"}
    estate = nodes["estate_final"]["value"]
    estate_id = "luoyang_estate_riverside_20261021ai"
    e_header = {EF: historical_leaf(EF), "res://scripts/city/luoyang_estate_index_20261021am.gd": nodes["legacy_index_0"]["sha256"], "res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json": nodes["estate_final"]["sha256"]}
    scene_sources[estate_id] = {"id": estate_id, "owner": "Estate", "owner_path": EF, "source_sha256": merge(estate["source_sha256"], e_header), "receipt_source_sha256": estate["source_sha256"], "recipe": "Estate.source_paths = manifest331 +3header; validation_receipt exactly331"}
    scene_sources["ch4_s4_ancient_temple"] = {"id": "ch4_s4_ancient_temple", "owner": "Temple", "owner_path": "res://scripts/city/luoyang_temple_assembly_20261016.gd", "source_sha256": temple_complete, "receipt_source_sha256": copy.deepcopy(temple_complete), "recipe": "Temple89-107 complete source_paths = merged binding+exact headers+Task/AP presentation+ENV+quarterPeople; receipt hashes entire same set"}
    rooms = []
    for ident in registry["ap_return_successor"]["room_ids"]:
        rooms.append({"id": ident, "owner": "G", "owner_path": G, "source_sha256": g_complete, "receipt_source_sha256": registry["rooms"][ident]["source_sha256"], "recipe": "G.source_paths all12 family rows + old registry +exact headers+EXEC; per-room catalogue.source_sha256 is distinct receipt domain"})
    assert len(scene_sources) == 8 and len(rooms) == 5
    core = dict(full_target_hashes)
    core.update({CITY_C: historical_leaf(CITY_C), EF: historical_leaf(EF), "res://scripts/city/luoyang_layout_room_index_20261018t.gd": historical_leaf("res://scripts/city/luoyang_layout_room_index_20261018t.gd")})
    out = {
        "status": "ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS",
        "actual_stage_receipt": {"path": STAGE, "sha256": STAGE_SHA},
        "core_source_sha256": core,
        "scenes": list(scene_sources.values()), "rooms": rooms,
        "metadata_fields_not_invented": "QA must merge separate frozen System scene/layout/world_size/visual_ids/npc_rows oracle; this file is source-domain-only, not the final bounded fixture",
        "expected_not_derived_from_live_collector_or_canonical_hash_crawl": True,
        "not_Field_or_runtime_credit": True,
    }
    source_sha = write_new("repair_stage03_independent_qa_owner_source_maps_READY.json", out)
    review_sha = write_new("repair_stage03_independent_source_review.json", {
        "status": "INDEPENDENT_STAGE_TARGET_BYTES_TYPED_PARENT_INVERSES_AND_SOURCE_DOMAINS_PASS_NOT_DEPLOYMENT",
        "actual_stage_receipt_sha256": STAGE_SHA, "source_owner_maps_sha256": source_sha,
        "target_count": 20, "candidate_hashes_verified": 20,
        "typed_metadata_whole_inverse_checks": inverse_checks,
        "source_first_final_same": True, "source_first_count": len(stage["source_first"]),
        "exact_partition": stage["target_partition"],
        "scene_counts": {p: {"collector": len(v["source_sha256"]), "receipt": len(v["receipt_source_sha256"])} for p, v in scene_sources.items()},
        "room_collector_count": len(g_complete), "room_receipt_counts": {r["id"]: len(r["receipt_source_sha256"]) for r in rooms},
        "no_engine_stager_collector_or_canonical_write": True,
    })
    print(json.dumps({"owner_source_maps_sha256": source_sha, "review_sha256": review_sha, "scenes": 8, "rooms": 5, "room_collector": len(g_complete)}))


if __name__ == "__main__":
    main()
