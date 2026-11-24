"""NEW source-only successor for the exact frozen native1135 route amendment.

No engine, image/binary decode, production mutation or runtime PASS prediction.
"""
from pathlib import Path
import copy
import hashlib
import json

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT / "game"
QA = Path(__file__).resolve().parent
ROOT_OUT = GAME / "build/luoyang_city_full_rollout_20261022ap_root01"
OUT = QA / "wall_yamen_independent_delta_recipe02_PREPARED_NOT_ACTUAL.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed(path, expected):
    assert sha(path) == expected, str(path)
    return json.loads(path.read_bytes())


def path_for(value):
    assert value.startswith("res://") and ".." not in value
    return GAME / value[6:]


def bounds(points):
    return [min(p[0] for p in points), min(p[1] for p in points), max(p[0] for p in points), max(p[1] for p in points)]


def closed_overlap(a, b):
    return a[0] <= b[2] and a[2] >= b[0] and a[1] <= b[3] and a[3] >= b[1]


assert not OUT.exists()
old_path = QA / "wall_yamen_independent_delta_recipe01_PREPARED_NOT_ACTUAL.json"
base = fixed(old_path, "7557be30da7ec3793bd4a4eaa006144f4371cebdbe788f7ab339deae5300834d")
amend_path = ROOT_OUT / "yamen_native_route1135_ordinal_preparation_amendment_READY.json"
amend = fixed(amend_path, "d917e3e35d499b09a30d23e38b16104d2386fc634d35ff12112e4715fa096c2f")
parent_row = amend["immutable_native_parent"]
native_parent = fixed(path_for(parent_row["path"]), parent_row["sha256"])
assert amend["approved_by_root"] is True
parent_routes = native_parent["record"]["routes"]
changes = amend["allowed_exact_ordinals"]
assert len(changes) == 4
child_routes = copy.deepcopy(parent_routes)
for row in changes:
    route = parent_routes[row["route_ordinal"]]
    assert route["id"] == row["route_id"]
    assert route["points_px"][row["point_ordinal"]] == row["old_pair"]
    child_routes[row["route_ordinal"]]["points_px"][row["point_ordinal"]] = copy.deepcopy(row["new_pair"])
reverse = copy.deepcopy(child_routes)
for row in changes:
    reverse[row["route_ordinal"]]["points_px"][row["point_ordinal"]] = copy.deepcopy(parent_routes[row["route_ordinal"]]["points_px"][row["point_ordinal"]])
assert json.dumps(reverse, sort_keys=True) == json.dumps(parent_routes, sort_keys=True)
selected = []
for ordinal in sorted({r["route_ordinal"] for r in changes}):
    original = parent_routes[ordinal]
    child = child_routes[ordinal]
    for index, (a, b) in enumerate(zip(child["points_px"], child["points_px"][1:])):
        if a != original["points_px"][index] or b != original["points_px"][index+1]:
            selected.append({"route_id": child["id"], "route_ordinal": ordinal, "segment_ordinal": index, "original_from_px": original["points_px"][index], "original_to_px": original["points_px"][index+1], "child_from_px": a, "child_to_px": b, "not_inherited_unchanged": True})
assert [(r["route_id"], r["segment_ordinal"]) for r in selected] == [("court_loop", 0), ("court_loop", 1), ("court_loop", 2), ("case_board", 0), ("case_board", 1)]
court = next(r for r in child_routes if r["id"] == "court_loop")
assert court["points_px"][6:8] == [[1100, 1135], [1100, 1080]]
adjacent = [{"route_id": "court_loop", "segment_ordinal": index, "points_px": court["points_px"][index:index+2], "unchanged_source_but_new_bench_adjacent": True} for index in (5, 6)]
owners_path = GAME / "build/luoyang_city_full_rollout_20261022ap_source_finalize01/unified06_06_independent_qa_owner_source_maps_READY.json"
owners = fixed(owners_path, "3f8d04fde11e7a64b1f1364510cee817466a853c31ae3a98375ca8bcc7283ac8")
yamen_owner = next(r for r in owners["scenes"] if r["id"] == "ch4_s1_luoyang_yamen")
motion_paths = ["res://scripts/city/luoyang_district_life_crowd_20261016f.gd", "res://scripts/field/npc_node.gd"]
motion_pins = {p: yamen_owner["source_sha256"][p] for p in motion_paths}
for path, value in motion_pins.items():
    assert sha(path_for(path)) == value
lanes = []
new_polys = base["Yamen"]["new_native_source_polygons"]
for person in base["Yamen"]["expected_district"]["crowd"]:
    x, y = person["foot_px"]
    distance = person["distance_px"]
    sweep = [x-distance-17, y-15, x+distance+17, y+15]
    candidates = [p["id"] for p in new_polys if closed_overlap(sweep, bounds(p["points_px"]))]
    lanes.append({"id": person["id"], "source_foot_px": [x, y], "distance_px": distance, "axis": [1, 0], "movement": "sin(phase)*distance; full +/-distance, not start-only", "points_px": [[x-distance, y], [x+distance, y]], "continuous_NPC34x30_sweep_bounds_xyxy": sweep, "new_polygon_AABB_candidates_only_not_clearance_acceptance": candidates, "future_actual": "original34x30/1085 rounded samples and continuous sweep plus original mask; every moving lane <=4px. Four idle feet use same NPCbody; no Playerbody substitution."})
assert len(lanes) == 6 and sum(r["distance_px"] > 0 for r in lanes) == 2
out = copy.deepcopy(base)
out["inherited_prepared_recipe"] = {"path": "res://" + old_path.relative_to(GAME).as_posix(), "sha256": sha(old_path)}
out["fixed_input_sha256"]["res://" + amend_path.relative_to(GAME).as_posix()] = sha(amend_path)
out["fixed_input_sha256"][parent_row["path"]] = parent_row["sha256"]
out["fixed_input_sha256"].update(motion_pins)
out["fixed_input_sha256"]["res://" + owners_path.relative_to(GAME).as_posix()] = sha(owners_path)
out["Yamen"]["counts"].update({"old_native_solids": 29, "old_native_polygon_solids": 23, "old_native_rect_solids": 6, "old_DG_solids": 10, "new_native_solids": 32, "new_DG_solids_unchanged": 10})
out["Yamen"]["native_mask_delta_recipe"]["old_native_only_membership"] = "Exactly fixed parent record.objects:23 polygon solids+6rect solids=29; never use all39combined as native. New3native produce32; old10DG remain separate."
out["Yamen"]["existing_route_change"] = {"authority": {"path": "res://" + amend_path.relative_to(GAME).as_posix(), "sha256": sha(amend_path)}, "obsolete1080_amendment_unexecuted_retained": amend["superseded_unexecuted_wrong_parent_amendment_sha256"], "parent_complete_routes": [parent_routes[i] for i in (1, 2)], "expected_complete_routes": [child_routes[i] for i in (1, 2)], "exact_four_ordinal_changes": changes, "five_changed_connecting_segments_require_new_checks": selected, "two_additional_unchanged1135_return_adjacent_segments_require_new_checks": adjacent, "publisher_must_compare_fixed_packet_whole_two_route_dicts_before_change": True, "restore_original_typed_four_pairs_for_full_record_inverse": True, "case_board_real_stand_unchanged": [550, 1240], "nominal_player_gap_only_not_PASS": {"y1135_Playerbody_south_edge": 1147, "north_bench_ground_top_nominal": 1148.36, "nominal_gap": 1.36, "predicate": "actual continuous34x24+875+17, no17x15 overconservative pre-reject and no epsilon"}}
out["Yamen"]["six_real_NPC_lane_expectations"] = lanes
out["Yamen"]["NPC_and_Player_predicates_separate"] = True
out["Yamen"]["finite_check_domain_after_amendment"] = "Original18 localproof segments + exactly5changed connectingsegments +2unchanged1135adjacentsegments +6trueNPC lanes/feet. Do not replay whole oldroute list; changedtwo route dictionaries are not falsely inheritedunchanged."
out["freeze_barriers"].append("Exact System publisher fixed parent packet must whole-match immutable517A routes before fourordinal mutation; actual new oldroute/narrow1135 checks remain required")
out["status"] = "INDEPENDENT_FINITE_PREPARATION02_NATIVE1135_FOURORDINALS_NOT_ACTUAL_PASS"
OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"path": str(OUT), "sha256": sha(OUT), "changed_connecting_segments": len(selected), "new_adjacent_segments": len(adjacent), "NPC_lanes": len(lanes), "NPC_new_polygon_AABB_candidate_count": sum(len(r["new_polygon_AABB_candidates_only_not_clearance_acceptance"]) for r in lanes), "engine_runs": 0, "accepted": False}))
