"""Finite recipe amendment only. Does not import or execute the staging engine.

Creates NEW h10 and a static topology/pointer report. It does not manufacture
node hashes, run collectors, stage deployment payloads, or authorize Root gates.
"""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
OLD_SHA = "cbbd40f50caf75dac06d611b85af801e1c1e7f4a1ffa261c3d894d713839f27a"
SYS = "res://build/luoyang_city_full_rollout_20261022ap_system01/"
OLD_HELPER = "5644d3bea2795d5d0ca8e244d7d970856cbed24511676e69c8c5a078742d8781"
NEW_HELPER = "6279cd6e4596e217b4c61830d69d92c672bf115be5a39a46b5046e728365c384"
NATIVE_HELPER = "res://scripts/city/luoyang_quarters_native_geometry_20261022ap.gd"
C = "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
ESTATE = "res://scripts/city/luoyang_estate_family_20261021am.gd"
B = "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
G = "res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
AO_MARKET = "res://data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/manifest.json"


def sha(data):
    return hashlib.sha256(data).hexdigest()


def resource(path):
    assert path.startswith("res://") and ".." not in Path(path[6:]).parts
    return GAME / path[6:]


def write_new(name, value):
    data = (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    with (HERE / name).open("xb") as stream:
        stream.write(data)
    return sha(data)


def refs(value, key):
    if isinstance(value, dict):
        if key in value:
            yield value[key]
        for child in value.values():
            yield from refs(child, key)
    elif isinstance(value, list):
        for child in value:
            yield from refs(child, key)


def same(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b


def read_pointer(value, keys):
    for key in keys:
        value = value[key]
    return value


def main():
    original = (HERE / "source_finalization_input_handoff9_PENDING.json").read_bytes()
    assert sha(original) == OLD_SHA
    plan = json.loads(original)
    plan["status"] = "PENDING_MARKET_MASK_IMPORT_ROOT_SCOPE_AND_GARDEN_SINGLE_IMAGE_NOT_EXECUTABLE"
    plan["blockers"] = [
        "Root must finitely review the NEW shore-helper6279 same native overview picture. All Garden native4/mask/2299 routes and original failed image remain preserved; no geometry replay.",
        "Root must add the exact finite target scope gate from integration1 fresh baseline59C36, full backups and external input SHA, then choose a NEW output epoch and ROOT_LOCKED status. No external tasks/audio/catalog changes may be rolled back or declared authorized by the old7EAB guard.",
        "Market17536 walk_candidate future_path still lacks its own new import triple. Require NEW single-mask actual and Root promotion, then add the exact three runtime leaves to AP Market only; old two-walk58808 does not cover this third mask and no native publication history may be backfilled.",
    ]
    plan["predecessor_input"] = {
        "path": "res://" + (HERE / "source_finalization_input_handoff9_PENDING.json").relative_to(GAME).as_posix(),
        "sha256": OLD_SHA,
        "preserved": True,
    }
    pins = {row["id"]: row for row in plan["pinned_inputs"]}
    assert pins["quarter_native_geometry_helper"]["sha256"] == OLD_HELPER
    previous = copy.deepcopy(pins["quarter_native_geometry_helper"])
    previous["id"] = "quarter_native_geometry_before_shore"
    plan["pinned_inputs"].append(previous)
    pins["quarter_native_geometry_helper"].update(path=SYS + "quarter_native_geometry_shore_visual_READY.gd", sha256=NEW_HELPER)
    plan["pinned_inputs"].append({
        "id": "garden_shore_visual_successor",
        "path": SYS + "garden_shore_visual_successor_READY.json",
        "sha256": "c96a7d28676af99c1a7c32fe3ad81c52a634f58afc2e4089c99d1ec99221aa31",
    })
    for row in plan["pass_through_targets"]:
        if row["target"] == NATIVE_HELPER:
            assert row["old_sha256"] == "ABSENT" and row["candidate_sha256"] == OLD_HELPER
            row.update(candidate_path=SYS + "quarter_native_geometry_shore_visual_READY.gd", candidate_sha256=NEW_HELPER)

    plan["source_groups"].extend([
        {
            "id": "quarter_family_direct_executable_leaves",
            "kind": "explicit",
            "leaves": {
                B: {"$owned": B}, G: {"$owned": G},
                C: "c68272dd8bb2fd989a7776a1ee970a0d082290927d1fd30734c72d59b1d0fe50",
                ESTATE: "7cd3517bb2b67c007060e9e4f2dcc963aa4f3e3e2e57862f1248718060243d4e",
            },
        },
        {
            "id": "quarter_environment_execution_indices",
            "kind": "explicit",
            "leaves": {
                "res://scripts/city/luoyang_environment_index_20261022ap.gd": {"$sha": "ap_environment_index"},
                "res://scripts/city/luoyang_execution_index_20261022ap.gd": {"$sha": "ap_execution_index"},
            },
        },
        {
            "id": "quarter_consumed_runtime_small",
            "kind": "union",
            "groups": [
                "quarter_people_old_sources", "quarter_people_module_proof",
                "environment_sources", "environment_header",
                "authority_before_and_candidate_proofs", "authority_header",
                "quarter_environment_execution_indices", "quarter_family_direct_executable_leaves",
            ],
        },
        {
            "id": "quarter_garden_shore_three_media",
            "kind": "input_dictionary",
            "input": "garden_shore_visual_successor",
            "pointer": ["fixed_texture_source_sha256"],
        },
    ])
    for row in plan["nodes"]:
        if row["id"] == "quarter_final":
            assert row["source_fields"][0]["groups"] == ["two_walk_promoted_triples", "PENDING_FINAL_QUARTER_SMALL_CONSUMER_GROUP"]
            row["source_fields"][0]["groups"] = ["two_walk_promoted_triples", "quarter_consumed_runtime_small", "quarter_garden_shore_three_media"]
            row["operations"].append({
                "op": "set", "pointer": ["source_sha256", NATIVE_HELPER],
                "existed": True, "old": OLD_HELPER, "new": {"$pin": "quarter_native_geometry_helper"},
            })
        if row["id"] == "expected_ch4_s3_luoyang_market_true":
            before = row["operations"]
            redundant = [op for op in before if op["op"] == "set" and op["pointer"] == ["source_sha256", AO_MARKET]]
            assert len(redundant) == 1 and redundant[0]["new"] == {"$sha": "legacy_manifest_8"}
            row["operations"] = [op for op in before if op not in redundant]

    plan["known_manifest_seeds"]["pending_small_group_resolved"] = "quarter_consumed_runtime_small; System exact source_paths interfaces confirmed, no presentation/sign spill"
    plan["known_manifest_seeds"]["quarter_shore_helper_source_only_successor"] = {
        "parent_sha256": OLD_HELPER, "next_sha256": NEW_HELPER,
        "new_media_count": 3, "native_artifacts_geometry_unchanged": True,
        "actual_single_image_pending": True,
    }
    plan["static_handoff10_fixes"] = [
        "Define exact small Quarter consumption union from runtime interfaces, no current collector expected filling.",
        "Replace native helper5644 by6279 in exactly canonical pass-through and Quarter source pointer; preserve old input/native/publication hashes.",
        "Add only existing exact shore PNG/import/ctex triple to Quarter; AP Market acquires it solely through Quarter closure.",
        "Remove redundant AOmanifest set immediately before old-value remove in expected Market map; explicit retirement still requires original c2cf and replacement APmanifest.",
        "Preserve target set37, runtime x literal4D931 and Estate331 source-only policy; no noop RI/EstateFamily owned expansion.",
    ]

    inputs = {row["id"]: row for row in plan["pinned_inputs"]}
    groups = {row["id"]: row for row in plan["source_groups"]}
    assert len(inputs) == len(plan["pinned_inputs"]) and len(groups) == len(plan["source_groups"])
    pin_verification = {}
    # Verifying explicit pinned inputs is not deriving expected values.
    for ident, row in inputs.items():
        actual = sha(resource(row["path"]).read_bytes())
        assert actual == row["sha256"], ("PIN_CHANGED", ident, row["path"])
        pin_verification[ident] = actual
    def group_dependencies(ident, visiting, available_nodes):
        assert ident in groups and ident not in visiting, ("UNKNOWN_OR_CYCLIC_GROUP", ident)
        row = groups[ident]
        if row["kind"] == "union":
            for child in row["groups"]:
                group_dependencies(child, visiting | {ident}, available_nodes)
        if row["kind"] == "node_dictionary":
            assert row["node"] in available_nodes, ("FORWARD_NODE_GROUP", ident)
        if row["kind"] == "input_dictionary":
            assert row["input"] in inputs
        for ref in refs(row, "$sha"):
            assert ref in available_nodes, ("FORWARD_NODE_SHA", ident, ref)
    targets = [row["target"] for row in plan["pass_through_targets"]]
    available = set()
    pointers_checked = 0
    for row in plan["nodes"]:
        assert row["base_input"] in inputs
        for ref in refs(row, "$sha"):
            assert ref in available, ("FORWARD_NODE", row["id"], ref)
        uses = list(row.get("groups", []))
        for field in row.get("source_fields", []):
            uses += field.get("groups", [])
        uses += row.get("source_bundle", {}).get("groups", [])
        for ident in uses:
            group_dependencies(ident, set(), available)
        if row["kind"] in {"metadata", "map"}:
            base = json.loads(resource(inputs[row["base_input"]]["path"]).read_bytes())
            # Operations reference original fields. Any repeated pointer must be
            # independently checked by the actual typed stager, not hidden here.
            observed = set()
            for operation in row.get("operations", []):
                pointer = operation["pointer"]
                assert tuple(pointer) not in observed, ("REPEATED_ORDERED_POINTER", row["id"], pointer)
                observed.add(tuple(pointer))
                holder = read_pointer(base, pointer[:-1])
                assert (pointer[-1] in holder) is operation["existed"]
                if operation["existed"]:
                    assert same(holder[pointer[-1]], operation["old"]), ("ORIGINAL_TYPED_POINTER", row["id"], pointer)
                pointers_checked += 1
        available.add(row["id"])
        if "target" in row:
            targets.append(row["target"])
    assert len(targets) == len(set(targets)) == len(plan["root_target_allowlist"]) == 37
    assert set(targets) == set(plan["root_target_allowlist"])
    assert len(plan["required_gates"]) == 4 and all(row["id"] != "root_target_preauthorization" for row in plan["required_gates"])
    assert len([row for row in plan["pass_through_targets"] if row.get("candidate_from_authority")]) == 10
    h10_sha = write_new("source_finalization_input_handoff10_PENDING.json", plan)
    report = {
        "status": "STATIC_INPUT_TOPOLOGY_AND_ORIGINAL_POINTERS_PASS_NOT_STAGER_OR_ADMISSION",
        "input_sha256": h10_sha, "predecessor_sha256": OLD_SHA,
        "pinned_inputs_verified": pin_verification, "node_count": len(available),
        "group_count": len(groups), "original_typed_pointers_checked": pointers_checked,
        "targets": targets, "target_count": len(targets),
        "no_undefined_or_forward_group_node_reference": True,
        "no_repeated_ordered_operation_pointer": True,
        "stager_executed": False, "canonical_written": False,
        "expected_map_hashes_not_invented": True,
        "remaining": plan["blockers"],
    }
    report_sha = write_new("handoff10_static_recipe_check.json", report)
    print(json.dumps({"h10_sha256": h10_sha, "static_report_sha256": report_sha, "targets": len(targets), "pointers": pointers_checked, "stager_executed": False}))


if __name__ == "__main__":
    main()
