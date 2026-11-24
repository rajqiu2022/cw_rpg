"""Prepare independent finite geometry expectations, never publisher observations.

This is not an acceptance runner. It decodes no PNG/binary, invokes no engine,
and writes no canonical file. Final publisher/input identities remain unfrozen.
"""
from pathlib import Path
import copy
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT / "game"
QA = Path(__file__).resolve().parent
SYSTEM = GAME / "build/luoyang_city_full_rollout_20261022ap_system01"
OUT = QA / "wall_yamen_independent_delta_recipe01_PREPARED_NOT_ACTUAL.json"
AUTH = GAME / "build/luoyang_city_full_rollout_20261022ap_root01/new_geometry_wall_yamen_finite_preparation_authorization_READY.json"
FIXTURE = QA / "bounded_groups_v5_author_anchors_READY.json"
WALL = SYSTEM / "market_wall_retirement_epoch01/author_delta_READY.json"
YAMEN = SYSTEM / "yamen_waiting_cluster_epoch01_retry1/author_delta_READY.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def res(path):
    return "res://" + path.relative_to(GAME).as_posix()


inputs = {}


def frozen(path, expected, decode_json=True):
    assert sha(path) == expected.lower(), str(path)
    inputs[res(path)] = expected.lower()
    return json.loads(path.read_bytes()) if decode_json else None


def path_for(value):
    assert value.startswith("res://") and ".." not in value
    return GAME / value[6:]


def declaration(row, decode_json=True):
    return frozen(path_for(row["path"]), row["sha256"], decode_json)


def f32(value):
    return struct.unpack("<f", struct.pack("<f", float(value)))[0]


def source_to_world(point, anchor, foot):
    # Native Vector2 subtraction, scalar .12 multiply and addition each round to
    # real_t; this is source geometry, not the publisher's projected safe_body.
    return [f32(f32(f32(f32(p) - f32(a)) * f32(.12)) + f32(b)) for p, a, b in zip(point, anchor, foot)]


assert not OUT.exists()
auth = frozen(AUTH, "ecb42286415c56ba8bf9bdea909fa6cd9c13aace36051810e55db89973637c73")
assert auth["approved_by_root"] is True and auth["engine_not_authorized_to_subagents"] is True
fixed = frozen(FIXTURE, "56af9d883a163e6cd0646f6ef4b394e46fc2c29e10baf254fc5d0bc548ee618d")
wall = frozen(WALL, auth["wall"]["author_sha256"])
yamen = frozen(YAMEN, auth["yamen"]["proposal_sha256"])
rows = {s["id"]: s for s in fixed["scenes"]}
market_old = copy.deepcopy(rows["ch4_s3_luoyang_market"]["geometry"])
yamen_old = copy.deepcopy(rows["ch4_s1_luoyang_yamen"]["geometry"])
assert len(market_old["solids"]) == 44 and len(yamen_old["solids"]) == 39
report = declaration(wall["geometry_parent"]["actual_report"])
assert report["passed"] is True and report["geometry"]["checked_samples"] == 437
declaration(wall["geometry_parent"]["actual_author"])
for name in ("walk_png", "raw_ground"):
    declaration(wall["geometry_parent"][name], False)
for path, value in wall["geometry_parent"]["native_artifacts"].items():
    frozen(path_for(path), value, False)
market_new = copy.deepcopy(market_old)
removed = [s for s in market_old["solids"] if s["id"] == "v13_market_west_plot_wall_poly_0"]
assert len(removed) == 1 and removed[0]["points_px"] == [[35, 1408], [145, 1408], [145, 1420], [35, 1420]]
market_new["solids"] = [s for s in market_new["solids"] if s["id"] != removed[0]["id"]]
assert len(market_new["solids"]) == 43
district_path = GAME / "data/maps/luoyang_district_life_20261016f/author.json"
district = frozen(district_path, "d98c65879681b58feea64158a4d0bde33d2ef9fc6b8a25d7d2f33dc961a9c59c")
assets = {a["asset_id"]: a for a in yamen["assets"]}
source_assets = {}
for asset_id, asset in assets.items():
    authored = declaration(asset["existing_interior_author"])
    source = next(r for r in authored["furniture"] if r["id"] == asset["existing_row_id"])
    for key in ("texture", "source_size_px", "source_ground_anchor_px", "source_ground_solid_polygons_px"):
        assert source[key] == asset[key]
    assert source["source_size_px"] == [1536, 1024]
    for leaf in asset["media_three_leaves"]:
        declaration(leaf, False)
    source_assets[asset_id] = source
new_solids, visuals = [], []
for place in yamen["placements"]:
    source = source_assets[place["asset_id"]]
    assert place["uniform_scale"] == .12 and place["rotation"] == 0
    polygons = []
    for index, poly in enumerate(source["source_ground_solid_polygons_px"]):
        transformed = [source_to_world(p, source["source_ground_anchor_px"], place["foot_px"]) for p in poly]
        polygons.append(transformed)
        new_solids.append({"id": place["id"] + "_poly_" + str(index), "kind": "QA_INDEPENDENT_SOURCE_FURNITURE_NATIVE_POLYGON", "points_px": transformed})
    visuals.append({"id": place["id"], "texture": source["texture"], "full_source_size_px": [1536, 1024], "source_ground_anchor_px": source["source_ground_anchor_px"], "foot_px": place["foot_px"], "uniform_scale": .12, "rotation": 0, "source_polygons_px": source["source_ground_solid_polygons_px"], "native_f32_polygons_px": polygons, "no_crop_or_alpha_edit": True})
assert len(new_solids) == 3
yamen_new = copy.deepcopy(yamen_old)
yamen_new["solids"] += new_solids
assert len(yamen_new["solids"]) == 42
old_district = district["districts"]["ch4_s1_luoyang_yamen"]
assert len(old_district["placements"]) == 10 and len(old_district["crowd"]) == 6
clerk = next(r for r in old_district["crowd"] if r["id"] == "yamen_clerk")
assert clerk["foot_px"] == [1260, 1500]
new_district = copy.deepcopy(old_district)
next(r for r in new_district["crowd"] if r["id"] == "yamen_clerk")["foot_px"] = [1130, 1360]
restored = copy.deepcopy(new_district)
next(r for r in restored["crowd"] if r["id"] == "yamen_clerk")["foot_px"] = [1260, 1500]
assert restored == old_district
routes = copy.deepcopy(yamen["static_routes"])
segments = [{"id": r["id"], "segment": i, "from_px": a, "to_px": b} for r in routes for i, (a, b) in enumerate(zip(r["points_px"], r["points_px"][1:]))]
assert len(routes) == 6 and len(segments) == 18
raw_yamen = "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s1_luoyang_yamen/raw_walk.png"
frozen(path_for(raw_yamen), rows["ch4_s1_luoyang_yamen"]["source_sha256"][raw_yamen], False)
frozen(path_for(yamen_old["mask_path"]), yamen_old["mask_sha256"], False)
oracle = GAME / "tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd"
frozen(oracle, "0f00d4a8a7bc7f514d4b0859275c2eb6d03296dd81eaa170416694c6068b2835", False)
recipe = {
    "status": "INDEPENDENT_FINITE_PREPARATION_ONLY_AWAIT_FIXED_PUBLISHER_INPUT_NOT_ACTUAL_PASS",
    "fixed_input_sha256": inputs,
    "expectations_never_from": ["publisher return values", "actual runtime or publication result", "production safe_body or live projected geometry", "current collector key/hash backfill"],
    "Market": {
        "parent_geometry": market_old, "expected_child_geometry": market_new,
        "independent_remove_exactly_one": removed,
        "visual_counts_separate_from_solids": {"native_visual_before": 24, "native_visual_after": 23, "DG_visual_unchanged": 12, "combined_visual_before": 36, "combined_visual_after": 35, "combined_source_solids_before": 44, "combined_source_solids_after": 43},
        "typed_packet_source_recipe": {"path": "res://data/maps/luoyang_full_city_20261022ap/market/ch4_s3_luoyang_market/packet.bin", "sha256": "edcb58007aff16bb5175ce3424b4e4bddfcb619aaab5ff07d0102f50c6962f80", "decode": "bytes_to_var fixed source packet only, no ResourceLoader/resolve/materialize/Field", "expected_transform": "remove exactly wall record row at original ordinal and its one source polygon; preserve every other typed field and old walk path for whole inverse; child walk output path must be fixed before freeze"},
        "mask": {"parent_png": wall["geometry_parent"]["walk_png"], "parent_RGBA_sha256": "d161eeabae012793be71e61f9e09e19db7a1a101b1f4e749879a42915328512e", "raw_ground": wall["geometry_parent"]["raw_ground"], "domain_xywh": [35, 1408, 111, 13], "visited_exact": 1443, "expected_not_blind_white": "For each pixel derive original RAW RGBA with border24 + remaining native polygon/ceil-half-open rect rules; verify parent pixel from original native first, child from exact wall removal. DG bodies stay separate. Restore all changed four-byte RGBA cells and require the full original25MiB array byte-equal; outside domain identical.", "no_full_raster_recompute": True, "expected_child_RGBA_sha_not_observed_or_guessed": None},
        "affected_old_route_selection": {"fixed_source": "packet.record.routes/gameplay_slots stand_px|foot_px/passage_path_px + fixed District required_routes/protected_routes and crowd lane points", "closed_conservative_selection_domain_xyxy": [18, 1393, 163, 1436], "method": "Select only source segments whose endpoint bounding box intersects domain inclusively. This overselecting AABB is selection only, not clearance proof. Preserve exact original IDs/endpoints and ordinal. Outside inherits parent17536; no full437 rerun.", "selected_segment_ids_not_yet_decoded": None},
        "new_witnesses": [{"id": "former_wall_crossing", "points_px": [[90, 1388], [90, 1440]], "expected": "strict body clearance required, not yet measured"}, {"id": "former_wall_stand", "foot_px": [90, 1414], "negative_control": "original wall oracle must reject", "child_expected": "removed-only oracle + locally recomputed mask must clear; not yet measured"}],
        "preserve_every_other_record_visual_actor_portal": True,
    },
    "Yamen": {
        "parent_geometry": yamen_old, "expected_child_geometry": yamen_new,
        "independent_new_visuals": visuals, "new_native_source_polygons": new_solids,
        "counts": {"old_combined_source_solids": 39, "new_native_polygons": 3, "new_combined_source_solids": 42, "old_DG_placements_unchanged": 10, "existing_actors_unchanged_count": 6},
        "original_district": old_district, "expected_district": new_district,
        "only_actor_delta": {"id": "yamen_clerk", "before": [1260, 1500], "after": [1130, 1360], "all_other_five_actors_and_entire_nonfoot_clerk_row_exact": True},
        "source_polygon_formula": "Vector2 native float32 subtract original frozen furniture ground anchor, multiply uniform .12, add fixed authored foot. Preserve full1536x1024 original PNG, no crop/rotation/stretch/alpha changes. JSON decimals in proposal not treated as native float identity.",
        "native_mask_delta_recipe": {"parent_png": {"path": yamen_old["mask_path"], "sha256": yamen_old["mask_sha256"]}, "raw_ground": {"path": raw_yamen, "sha256": inputs[raw_yamen]}, "membership": "3 new native record objects/visuals/solids; old10DG never baked into native mask", "algorithm": "Before runtime use independent derived three polygons to freeze union of integer raster bounding envelopes. Only those pixels recomputed from exact RAW+old native+new native rules; first verify parent RAW+old native. Outside union fullRGBA unchanged. Full inverse restores originalRGBA. Never expand old black to blind white.", "parent_RGBA_and_three_closed_envelopes_await_fixed_input": True, "expected_new_RGBA_not_observed_or_guessed": None},
        "finite_routes": routes, "only_18_local_segments": segments,
        "negative_new_footprints": [{"id": s["id"], "foot_px": [sum(p[i] for p in s["points_px"]) / len(s["points_px"]) for i in range(2)], "expected": "independent continuous34x24 and nativePhysics must reject"} for s in new_solids],
        "preserved_axis_and_doors": yamen["preserved"],
        "no_39_old_solid_geometry_republication": True,
    },
    "future_predicates": {"body": [34, 24], "half": [17, 12], "rounded_lattice": "foot.round()+x[-17..17],y[-12..12], all875 must be inside originalfloor union and outside closed solids; exact RGBAwhite native mask", "actual_17": "exact original SHOES array in fixed raw oracle, no tolerance enlargement", "continuous": "body rectangle fully in originalfloor union, closed polygon intersection rejects touching", "max_step_px": 4, "scope": "only independently selected Market old segments+two new witnesses, three new Yamen footprints+18local segments and clerk foot; not old437/global1085/public/room travel"},
    "future_one_Field_metrics_if_separately_authorized": "Only after unchanged firstdraw scalar freezes: read C.transition_validation_state live_phase_msec/main_stage_timings and existing Field loading/preload metrics. No extra collector/resolve/validator, no separate old performance scene.",
    "visual_barriers": ["Fullsource real-alpha outdoor composite required before any ART credit", "Old strict alpha margin FAIL remains", "No background processing/crop/new PNG", "Finite ordinary camera picture still pending Root authority"],
    "freeze_barriers": ["System unique publisher/input fixed SHA", "parent typed source layouts/packets and exact source DAG pins", "Yamen parent decodedRGBA pin and exact three integer envelopes", "Market affected-source IDs/segments decoded from fixed packet independently", "Root review before unique engine run"],
    "engine_runs": 0, "PNG_decodes_or_edits": 0, "binary_decodes": 0, "canonical_writes": 0, "not_acceptance_or_predicted_PASS": True,
}
OUT.write_text(json.dumps(recipe, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"path": str(OUT), "sha256": sha(OUT), "source_inputs": len(inputs), "Market_solids": [44, 43], "Yamen_solids": [39, 42], "Yamen_segments": len(segments), "engine_runs": 0, "accepted": False}))
