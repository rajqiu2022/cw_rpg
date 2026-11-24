"""Read one completed Root publication against pre-actual independent recipe07.

No engine/geometry sampling/raster rebuild or PNG writes. Actual PNG RGBA reads
are compared to prior source-derived bytes, never used to redefine expected.
"""
from pathlib import Path
import hashlib
import json
import math
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT / "game"
QA = Path(__file__).resolve().parent
SYSTEM = GAME / "build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01"
OUT = QA / "bound05_actual_89216_independent_readonly_review_READY.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed(path, expected):
    assert sha(path) == expected, str(path)
    return json.loads(path.read_bytes())


def local(path):
    assert path.startswith("res://") and ".." not in path
    return GAME / path[6:]


def point_count(a, b):
    return max(1, math.ceil(math.dist(a, b)/4)) + 1


assert not OUT.exists()
recipe_path = QA / "wall_yamen_independent_recipe07_BOUND05_SOURCE_FROZEN_RETRY1_NOT_ACTUAL.json"
recipe = fixed(recipe_path, "448c148ed5a15aaf4b1acbf6472afd6f94fe1ea2bdb654717dd59a5a56b4f947")
report_path = SYSTEM / "output/runs/89216_1733/result.json"
r = fixed(report_path, "6118b1fef2453eb99dbe4a5ceb743249728feb01ccf5064b0c3d0902acf203fa")
config = fixed(SYSTEM / "input_READY.json", "3739600a91f13531b633d215b04b92caa1eec70d8922727663868c0393afd5f7")
assert r["passed"] is True and r["published"] is True and r["checks"] == 249 and r["elapsed_ms"] == 8117 and r["error"] == ""
assert r["source_first"] == r["source_final"]
source_expected = dict(config["source_pins"])
source_expected["res://" + (SYSTEM / "input_READY.json").relative_to(GAME).as_posix()] = "3739600a91f13531b633d215b04b92caa1eec70d8922727663868c0393afd5f7"
source_expected["res://" + (SYSTEM / "publisher_READY.gd").relative_to(GAME).as_posix()] = "43cddead404f6aec31be20c3f79bf1065de4984b68cb98b99e9068a1cdbfb351"
assert len(source_expected) == 55 and r["source_first"] == source_expected
for path, value in source_expected.items():
    assert sha(local(path)) == value
domain_reviews = {}
for title, key, counts in (("Market", "market", [23,30,43]), ("Yamen", "yamen", [27,32,42])):
    actual = r[key]
    expected = recipe["independent_local_mask_expectations"][title]
    assert actual["published"] is True and [actual["native_visual_count"], actual["native_solid_count"], actual["combined_solid_count"]] == counts
    assert actual["native_whole_inverse"] is True and actual["packet_whole_inverse"] is True
    assert actual["mask_rgba_sha256"] == expected["independent_expected_child_RGBA_sha256"]
    for path, value in actual["artifacts"].items():
        assert sha(local(path)) == value
    assert len(actual["artifacts"]) == 4
    mask_path = next(p for p in actual["artifacts"] if p.endswith("/walk.png"))
    with Image.open(local(mask_path)) as image:
        assert image.size == (3072,2048)
        data = image.convert("RGBA").tobytes()
    assert hashlib.sha256(data).hexdigest() == expected["independent_expected_child_RGBA_sha256"]
    delta = actual["finite_proof"]["mask_delta"]
    assert delta["visited_pixels"] == expected["visited_pixel_count"]
    assert delta["changed"] == expected["expected_changed_pixels"]
    assert delta["parent_rgba_sha256"] == expected["parent_RGBA_sha256"] and delta["child_rgba_sha256"] == expected["independent_expected_child_RGBA_sha256"]
    inverse = bytearray(data)
    for row in expected["expected_changed_pixels"]:
        offset = (row["y"]*3072+row["x"])*4
        assert data[offset:offset+4] == bytes(row["new_RGBA"])
        inverse[offset:offset+4] = bytes(row["old_RGBA"])
    assert hashlib.sha256(inverse).hexdigest() == expected["parent_RGBA_sha256"]
    geometry = actual["finite_proof"]["geometry"]
    assert geometry["passed"] is True and geometry["failures"] == [] and geometry["body_px"] == [34,24] and geometry["full875_plus17"] is True and geometry["max_step_px"] == 4 and geometry["all_old_routes_replayed"] is False
    domain_reviews[title] = {"native_visual_solids_combined_counts": counts, "actual_RGBA_equals_pre_actual_independent_source_expectation": True, "actual_RGBA_full_inverse_matches_original": True, "visited_pixels": expected["visited_pixel_count"], "changed_pixels": expected["changed_pixel_count"], "root_actual_guarded_native_scene_layout_packet_inverse_and_readback_reported": True, "fresh_independent_binary_redecode_not_performed": True, "actual_local_CPU_geometry_source_contract": geometry}
market_rows = r["market"]["finite_proof"]["geometry"]["segments"]
assert [(p["id"],p["segment"],p["samples"]) for p in market_rows] == [("former_wall_crossing",0,14),("former_wall_stand",0,2)]
assert r["market"]["finite_proof"]["geometry"]["checked_samples"] == 16
assert r["market"]["finite_proof"]["geometry"]["unaffected_segments_inherited_not_replayed"] == 117
yamen = recipe["Yamen"]
expected_rows = {}
for row in yamen["only_18_local_segments"]:
    expected_rows[(row["id"],row["segment"])] = (point_count(row["from_px"],row["to_px"]),False)
for row in yamen["existing_route_change"]["five_changed_connecting_segments_require_new_checks"]:
    expected_rows[(row["route_id"],row["segment_ordinal"])] = (point_count(row["child_from_px"],row["child_to_px"]),False)
for row in yamen["six_real_NPC_lane_expectations"]:
    expected_rows[("district:"+row["id"],0)] = (point_count(*row["points_px"]),True)
for row in yamen["three_additional_native_source_actors"]:
    expected_rows[("unchanged_native_source_npc_anchor:"+row["id"],0)] = (2,True)
expected_rows[("inherited_court_loop_segment5_y1135_horizontal_witness",0)] = (201,False)
expected_rows[("inherited_court_loop_segment6_y1135_vertical_witness",0)] = (15,False)
observed = r["yamen"]["finite_proof"]["geometry"]["segments"]
actual_forced = {(p["id"],p["segment"]):(p["samples"],p["npc_full1085"]) for p in observed if p["entire_changed_or_new_segment"]}
assert len(actual_forced) == len(expected_rows) and actual_forced == expected_rows
zero_rows = [p for p in observed if not p["entire_changed_or_new_segment"]]
assert {(p["id"],p["segment"],p["samples"]) for p in zero_rows} == {("court_loop",5,0),("court_loop",6,0)}
assert sum(p[0] for p in expected_rows.values()) == 1724 == r["yamen"]["finite_proof"]["geometry"]["checked_samples"]
assert r["yamen"]["finite_proof"]["geometry"]["complete_real_NPC_lanes"] == 6
overlay_path = r["yamen"]["finite_proof"]["clerk_overlay_path"]
overlay = fixed(local(overlay_path), r["yamen"]["finite_proof"]["clerk_overlay_sha256"])
assert overlay["old_spec"] == yamen["original_district"] and overlay["new_spec"] == yamen["expected_district"]
assert overlay["id"] == "yamen_clerk" and overlay["before"] == [1260,1500] and overlay["after"] == [1130,1360]
assert overlay["whole_author_inverse"] is True
assert r["collector_calls"] == r["engine_geometry_full_raster_calls"] == r["physics_frames"] == 0
assert r["old_all_city_or_room_routes_replayed"] is False
review = {"status":"READONLY_SOURCE_MASK_AND_FINITE_CPU_REPORT_REVIEW_ONLY_NOT_FIELD_OR_ART_ADMISSION","result":{"path":"res://"+report_path.relative_to(GAME).as_posix(),"sha256":sha(report_path)},"pre_actual_independent_recipe_sha256":sha(recipe_path),"limited_fixed_sources_first_final_current_exact_count":55,"domains":domain_reviews,"Yamen_expected_18local_plus5changed_plus2adjacent_plus6DGplus3native_source_anchor_rows_exact":True,"near1135_original_duplicate_rows_zero_not_credited_but_complete201plus15_witnesses_present":True,"original_clerk_author_only_foot_overlay_matches_independent_expectation":True,"limits":["Root actual native inverse/readback proof is audited from fixed publisher contract/report, not a second independent binary decode","Market old affected-route selection inherits fixed actual source packet audit; no claim full117oldsegments replayed","CPU-only local body/mask proof, not native Physics or actual actor spawning/visibility","No Field, doorway travel, opaque-prop/actor-ghost render, outdoor alpha ART or timing credit","Only55selected publication inputs, not fullcity runtime source-owner or15save new guard proof","Original04FAIL,05andall prior failures retained; logs not called clean"],"read_only_actual_PNG_decodes":2,"PNG_outputs":0,"engine_runs_by_this_review":0,"geometry_sampling_repeated":False,"canonical_writes":0}
OUT.write_text(json.dumps(review,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"path":str(OUT),"sha256":sha(OUT),"source_count":55,"Market_CPU_samples":16,"Yamen_CPU_samples":1724,"PNG_decodes":2,"engine_runs":0,"geometry_repeated":False}))
