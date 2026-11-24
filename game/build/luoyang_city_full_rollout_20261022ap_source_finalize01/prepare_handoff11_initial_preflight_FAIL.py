"""NEW input amendment for three actual Market import leaves and exact G delta.

No staging engine, Godot, canonical write or collector invocation.
"""
from __future__ import annotations

import copy
import json

from prepare_handoff10 import HERE, GAME, SYS, resource, sha, write_new, refs

H10_SHA = "36c7bc2f032e5f39d50985407f7eba50df4374dda3f39ceac73c71daf39dc196"
HELPER_6279 = "6279cd6e4596e217b4c61830d69d92c672bf115be5a39a46b5046e728365c384"
HELPER_3EFA = "3efaeff0d0fd6c24e3056e034f25350961730ba98826918baeeffa6962c6257b"
MASK = "res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/walk.png"
CTEX = "res://.godot/imported/walk.png-74d7e4c5d28be79079c022b3e1e09e12.ctex"
NATIVE_HELPER = "res://scripts/city/luoyang_quarters_native_geometry_20261022ap.gd"


def main():
    oldbytes = (HERE / "source_finalization_input_handoff10_PENDING.json").read_bytes()
    assert sha(oldbytes) == H10_SHA
    plan = json.loads(oldbytes)
    plan["status"] = "PENDING_GARDEN_SINGLE_IMAGE_AND_ROOT_SCOPE_NOT_EXECUTABLE"
    plan["blockers"] = [
        "Root must finitely review NEW shore-helper3EFA same native overview after real unchanged317x109 texture dimension correction. Original46196 failure and6279 predecessor remain preserved; native4/mask/2299 routes do not change.",
        "Root must add exact finite target scope gate from integration1 fresh baseline59C36, complete old bytes backups and external input SHA, choose a NEW output epoch and ROOT_LOCKED status. External tasks/audio/catalog changes remain outside target37 and must be preserved.",
    ]
    plan["predecessor_input"] = {"path": "res://" + (HERE / "source_finalization_input_handoff10_PENDING.json").relative_to(GAME).as_posix(), "sha256": H10_SHA, "preserved": True}
    pins = {row["id"]: row for row in plan["pinned_inputs"]}
    previous = copy.deepcopy(pins["quarter_native_geometry_helper"])
    assert previous["sha256"] == HELPER_6279
    previous["id"] = "quarter_native_geometry_before_real_dimensions"
    plan["pinned_inputs"].append(previous)
    pins["quarter_native_geometry_helper"].update(path=SYS + "quarter_native_geometry_shore_actual_dimensions_retry1_READY.gd", sha256=HELPER_3EFA)
    newpins = [
        ("garden_shore_actual_dimensions", SYS + "garden_shore_visual_actual_dimensions_retry1_READY.json", "90c14289b3ea8969d468006ffd357764e819624244dce4da7db895e4c5572748"),
        ("market_walk_import_actual", "res://build/luoyang_city_full_rollout_20261022ap_qa01/isolate_market_mask_ready01/ap_market_walk_import_result_64516.json", "af40af91a8a63b932ebc1cdc5d3a6f170305b29ac1e57e6e14ab19f94dd57e19"),
        ("market_walk_promotion_actual", "res://build/luoyang_city_full_rollout_20261022ap_root01/market_walk_three_leaf_promotion_actual.json", "d31491793c3463dd541d97902dd064de90505cff7ccbcb47db22cdabd699ce7b"),
        ("market_walk_preauthorization", "res://build/luoyang_city_full_rollout_20261022ap_root01/market_walk_three_leaf_preadd_authorization.json", "faecc256e2b1f07dbd63dbd04cbb2f53ced20237d216374027fbdec704c57de5"),
    ]
    for ident, path, expected in newpins:
        assert ident not in pins and sha(resource(path).read_bytes()) == expected
        plan["pinned_inputs"].append({"id": ident, "path": path, "sha256": expected})
    for row in plan["pass_through_targets"]:
        if row["target"] == NATIVE_HELPER:
            assert row["candidate_sha256"] == HELPER_6279
            row.update(candidate_path=SYS + "quarter_native_geometry_shore_actual_dimensions_retry1_READY.gd", candidate_sha256=HELPER_3EFA)

    triple = {
        MASK: "16da1638c1aeb3c9761d0b988da70aa0f761c29e2a9ab8ec3acdf3fffda214ea",
        MASK + ".import": "57708a5974aa2e941fa3f4fb9d2368f63ae606c9ab044a9aa7ae64c0313dba15",
        CTEX: "5635eb3dfe3ae95d35d9f9343ef4e6f1788f3b382b1319e5e4e7bb063c28a911",
    }
    plan["source_groups"].extend([
        {"id": "market_walk_promoted_triple", "kind": "explicit", "leaves": triple},
        {
            "id": "G_new_return_header_only", "kind": "explicit",
            "leaves": {
                SYS + "before/registry_AO_4D056.json": "4d05631fa7f032f90d1eefdd600408235930b47c54aa5653a7f34a21d2db1297",
                "res://scripts/city/luoyang_quarters_family_20261022ap.gd": "cc97a68a178936ccb6bf54c1c8a65292adaeb7e5f6ae5a314c343810d07210f1",
            },
        },
        {"id": "G_five_return_added_source_delta", "kind": "union", "groups": ["published_five_return_artifacts", "G_new_return_header_only"]},
    ])
    for node in plan["nodes"]:
        if node["id"] == "market_final":
            node["source_bundle"]["groups"].extend(["G_new_return_header_only", "market_walk_promoted_triple"])
        if node["id"] == "expected_ch4_s2_canal_docks_true":
            node["groups"].append("G_five_return_added_source_delta")
        if node["id"] == "expected_ch4_s3_luoyang_market_true":
            node["runtime_media_roots"].extend([
                {"path": MASK, "compiled_paths": [CTEX]},
                {"path": "res://art/modules/ground/road_stone_grass_edge.png", "compiled_paths": ["res://.godot/imported/road_stone_grass_edge.png-f8db63f60ecff0d9b90b7a21c86f93c4.ctex"]},
            ])

    plan["known_market_walk_actual"] = {
        "passed": True, "checks": 59, "elapsed_ms": 115, "leaf_count": 3,
        "import_input": "market_walk_import_actual", "promotion_input": "market_walk_promotion_actual",
        "authorization_input": "market_walk_preauthorization", "source_sha256": triple,
        "not_covered_by_previous_two_walk_import": True,
        "old_17536_native_proof_not_modified": True,
        "runtime_scope": "AP Market own runtime closure; no other three city or Quarter media source spill",
    }
    plan["known_manifest_seeds"]["quarter_shore_helper_source_only_successor"].update(next_sha256=HELPER_3EFA, predecessor_6279_preserved=True, real_texture_size=[317, 109], failed_46196_preserved=True)
    plan["G_consumer_delta_contract"] = {
        "basis": "Actual C._transition_sources only Market/Docks call G.source_paths. Exact five published row sources compared against fixed AO registry source dictionaries; only20 added native leaves,0changed,0removed before executable promotion.",
        "affected_city_expected_maps": ["ch4_s2_canal_docks", "ch4_s3_luoyang_market"],
        "new_header_count": 2, "new_native_source_count": 20,
        "no_new_room_source_for_gate_yamen": True,
        "no_old_room253_collection_replay": True,
    }
    inputs = {row["id"]: row for row in plan["pinned_inputs"]}
    imported = json.loads(resource(inputs["market_walk_import_actual"]["path"]).read_bytes())
    assert imported["passed"] is True and imported["checks"] == 59 and imported["failures"] == [] and len(imported["rows"]) == 1
    r = imported["rows"][0]
    assert {r["texture"]: r["source_sha256"], r["import_path"]: r["import_sha256"], r["compiled_path"]: r["compiled_sha256"]} == triple
    promoted = json.loads(resource(inputs["market_walk_promotion_actual"]["path"]).read_bytes())
    assert promoted["passed"] is True and len(promoted["leaves"]) == 3
    assert {"res://" + resource_path["target"].replace("\\", "/").split("/game/", 1)[1]: resource_path["sha256"] for resource_path in promoted["leaves"]} == triple
    for path, expected in triple.items():
        assert sha(resource(path).read_bytes()) == expected
    # This is a fixed publication-vs-fixed-parent delta, never a collector/disk crawl.
    new = json.loads(resource(inputs["registry_actual"]["path"]).read_bytes())
    old = json.loads(resource(inputs["ao_metadata_0"]["path"]).read_bytes())
    delta = {}
    for room in new["ap_return_successor"]["room_ids"]:
        left, right = old["rooms"][room]["source_sha256"], new["rooms"][room]["source_sha256"]
        assert set(left) <= set(right) and all(right[k] == v for k, v in left.items())
        added = {k: v for k, v in right.items() if k not in left}
        assert len(added) == 4 and all(k.startswith("res://data/maps/luoyang_full_city_20261022ap/rooms/" + room + "/") for k in added)
        delta.update(added)
    publication = json.loads(resource(inputs["market_actual"]["path"]).read_bytes())
    assert delta == publication["five_room_returns"]["artifacts"] and len(delta) == 20
    targets = [r["target"] for r in plan["pass_through_targets"]] + [r["target"] for r in plan["nodes"] if "target" in r]
    assert len(targets) == len(set(targets)) == 37 and set(targets) == set(plan["root_target_allowlist"])
    groups = {r["id"]: r for r in plan["source_groups"]}
    completed = set()
    def check_group(name, seen):
        assert name in groups and name not in seen
        group = groups[name]
        if group["kind"] == "union":
            for child in group["groups"]: check_group(child, seen | {name})
        if group["kind"] == "node_dictionary": assert group["node"] in completed
        for ref in refs(group, "$sha"): assert ref in completed
    for node in plan["nodes"]:
        for ref in refs(node, "$sha"): assert ref in completed
        uses = node.get("groups", []) + node.get("source_bundle", {}).get("groups", [])
        for field in node.get("source_fields", []): uses += field.get("groups", [])
        for name in uses: check_group(name, set())
        completed.add(node["id"])
    outsha = write_new("source_finalization_input_handoff11_PENDING.json", plan)
    reportsha = write_new("handoff11_static_delta_check.json", {
        "status": "STATIC_EXACT_DELTA_AND_TOPOLOGY_PASS_NOT_STAGER_ADMISSION",
        "input_sha256": outsha, "predecessor_sha256": H10_SHA,
        "market_import_and_promotion_pinned": True, "market_canonical_media_three_verified": triple,
        "G_five_row_delta_exact20": delta, "G_headers_only2": True,
        "Gate_Yamen_no_new_rooms": True, "target_count": 37,
        "helper6279_failure_preserved_new3EFA": True,
        "no_engine_stager_collector_or_canonical_write": True,
        "remaining": plan["blockers"],
    })
    print(json.dumps({"h11_sha256": outsha, "static_report_sha256": reportsha, "targets": 37, "stager_executed": False}))


if __name__ == "__main__":
    main()
