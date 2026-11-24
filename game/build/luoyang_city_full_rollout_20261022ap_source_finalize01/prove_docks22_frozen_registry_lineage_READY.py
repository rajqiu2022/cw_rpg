"""Independent frozen G/registry lineage for Docks' 22 declaration gap.

No runtime diagnostic/collector map supplies expected hashes. All values come
from the existing immutable stage02 registry and executable G declarations.
This only writes a NEW proof and scope proposal, never a stage/canonical file.
"""
import copy
import json
import re
from prepare_handoff10 import resource, sha, same, write_new

P = "res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/"
REGISTRY = "res://data/maps/luoyang_estate_rooms_20261021am/registry.json"
G = "res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
Q = "res://scripts/city/luoyang_quarters_family_20261022ap.gd"
DOCKS = "res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json"
DOCKS_INDEX = "res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd"
first = {}


def read(path, expected):
    raw = resource(path).read_bytes()
    assert sha(raw) == expected, ("PIN_CHANGED", path)
    first[path] = expected
    return raw


stage_path = P + "outputs/root_integration1_stage02/receipt.json"
stage_sha = "b3ed75f8303d8b62a8cbe56b79a857309930c7493b28b216c2a11ee2110e1d39"
stage = json.loads(read(stage_path, stage_sha))
targets = {r["target"]: r for r in stage["targets"]}
registry_sha = targets[REGISTRY]["candidate_sha256"]
assert registry_sha == "69602933f93d6c0ede6feb2a8e3c1f355a224017bb59c638440135e42e7634f6"
registry = json.loads(read(targets[REGISTRY]["candidate_path"], registry_sha))
read(REGISTRY, registry_sha)
g_sha = targets[G]["candidate_sha256"]
assert g_sha == "2e305b0477c2cc0b8f48450377409f88ef38e769e7fe3f827912c81f591d15f9"
graw = read(targets[G]["candidate_path"], g_sha).decode("utf-8")
read(G, g_sha)
consts = dict(re.findall(r'^const (AP_PARENT|AP_PARENT_SHA|AP_QUARTERS|AP_ROOT)="([^"]+)"', graw, re.M))
assert consts["AP_QUARTERS"] == Q
assert 'paths[AP_PARENT]=true;paths[AP_QUARTERS]=true' in graw
assert 'for path: String in row.source_sha256: paths[path]=true' in graw
proof = registry["ap_return_successor"]
assert proof["parent_snapshot"] == consts["AP_PARENT"] and proof["parent_sha256"] == consts["AP_PARENT_SHA"]
assert proof["other_seven_rows_unchanged"] is True and proof["no_interior_geometry_replay"] is True
parent = json.loads(read(consts["AP_PARENT"], consts["AP_PARENT_SHA"]))
assert consts["AP_PARENT_SHA"] == "4d05631fa7f032f90d1eefdd600408235930b47c54aa5653a7f34a21d2db1297"
ids = json.loads(re.search(r'^const AP_ROOMS=(\[.*\])$', graw, re.M).group(1))
assert ids == proof["room_ids"] and len(ids) == 5
q_sha = targets[Q]["candidate_sha256"]
assert q_sha == "cc97a68a178936ccb6bf54c1c8a65292adaeb7e5f6ae5a314c343810d07210f1"
read(targets[Q]["candidate_path"], q_sha)
read(Q, q_sha)
leaves = {consts["AP_PARENT"]: consts["AP_PARENT_SHA"], Q: q_sha}
lineage = [
    {"path": consts["AP_PARENT"], "sha256": consts["AP_PARENT_SHA"], "origin": "G.AP_PARENT_SHA + registry.ap_return_successor.parent_snapshot/parent_sha256"},
    {"path": Q, "sha256": q_sha, "origin": "G.AP_QUARTERS explicit source_paths AP branch + exact actual stage02 Quarter code target"},
]
room_rows = []
for room_id in ids:
    row = registry["rooms"][room_id]
    assert row["ap_return_only_successor"] is True
    assert same(row["ap_parent_row"], parent["rooms"][room_id]), ("STRICT_FROZEN_PARENT_ROOM", room_id)
    native = {}
    for kind in ["author", "layout", "scene", "storage"]:
        path, expected = row[kind + "_path"], row[kind + "_sha256"]
        assert path == consts["AP_ROOT"] + room_id + "/" + {"author": "author.json", "layout": "layout.res", "scene": "scene.res", "storage": "storage.bin"}[kind]
        assert row["source_sha256"][path] == expected and path not in row["ap_parent_row"]["source_sha256"]
        read(path, expected)
        assert path not in leaves
        leaves[path] = native[path] = expected
        lineage.append({"path": path, "sha256": expected, "origin": "frozen registry.rooms[room].source_sha256 and corresponding native path/hash pair", "room_id": room_id, "kind": kind, "registry_pointer": ["rooms", room_id, "source_sha256", path]})
    assert len(native) == 4
    room_rows.append({"room_id": room_id, "native_leaves": native, "strict_parent_row_equal": True, "return_only_successor": True})
assert len(leaves) == 22
docks_sha = "8607409a61ce0c98324ebaabbb24b24661967b3ccffc911a95d97ce32c2c1e18"
docks = json.loads(read(DOCKS, docks_sha))
merged = {}
for key in ["legacy_source_sha256", "runtime_authority_sha256", "artifacts"]:
    assert not (set(merged) & set(docks[key]))
    merged.update(docks[key])
assert len(merged) == 1631 and not (set(leaves) & set(merged))
assert len(merged | leaves) == 1653
index_sha = "7c212111fa98727d1296b1731a7a2ec98f46a5aced9ee7a32016067d4e480bd2"
index_raw = read(DOCKS_INDEX, index_sha)
assert index_raw.count(docks_sha.encode()) == 1
# Pure typed counterfactual proves only legacy22 would change. No candidate
# bytes, prospective SHA, index, stage, or expected map is emitted here.
value = copy.deepcopy(docks)
value["legacy_source_sha256"].update(leaves)
for path in leaves:
    del value["legacy_source_sha256"][path]
assert same(value, docks)
assert all(sha(resource(path).read_bytes()) == expected for path, expected in first.items())
result = {
    "status": "INDEPENDENT_FROZEN_G_ESTATE_REGISTRY22_SOURCE_LINEAGE_READY_NOT_STAGE",
    "fixed_stage02": {"path": stage_path, "sha256": stage_sha},
    "fixed_registry": {"path": REGISTRY, "sha256": registry_sha, "immutable_candidate_path": targets[REGISTRY]["candidate_path"]},
    "fixed_G": {"path": G, "sha256": g_sha, "immutable_candidate_path": targets[G]["candidate_path"]},
    "source_sha256": leaves,
    "lineage": lineage,
    "room_rows": room_rows,
    "header_leaves": 2,
    "room_native_leaves": 20,
    "total_leaves": 22,
    "docks_merged_before": 1631,
    "docks_merged_after_finite_addition": 1653,
    "existing_external_headers": 12,
    "describe_complete_after_expected": 1665,
    "all22_absent_across_three_existing_source_classes": True,
    "metadata_delta_proposal": "Only merge the declared22 into Docks AC legacy_source_sha256; all native/author/layout/proof/geometry/other values inverse unchanged",
    "target_proposal": [
        {"target": DOCKS, "old_sha256": docks_sha, "change": "legacy_source_sha256 add exact22; future unified runtime source substitutions separately finite"},
        {"target": DOCKS_INDEX, "old_sha256": index_sha, "change": "one literal manifest SHA after final unified metadata; not generated here"},
    ],
    "not_final_combined_scope": "Runtime/visual owned source and ENV dependencies are pending System's frozen final set; do not stage this gap alone",
    "no_actual_collector_hash_expected_source": True,
    "no_engine_collector_geometry_stage_or_canonical_write": True,
    "ancestral_and_existing_leaf_sha256": first,
}
digest = write_new("docks22_frozen_registry_lineage_READY.json", result)
print(json.dumps({"proof_sha256": digest, "leaves": len(leaves), "docks_manifest_before": len(merged), "proposed_after": 1653, "all22_absent": True, "stage_or_canonical_written": False}))
