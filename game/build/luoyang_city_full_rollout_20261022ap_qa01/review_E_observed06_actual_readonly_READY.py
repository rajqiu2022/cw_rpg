"""Independently read the one completed E report; never rerun engine or collector."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
REPORT = QA / "E_observed_06/65152_2715/result.json"
FIXTURE = QA / "E_observed06_ONLY_READY.json"
GUARD = ROOT / "game/build/luoyang_city_full_rollout_20261022ap_root01/integration11/final_guard.json"
OUT = QA / "E_observed06_actual_65152_independent_readonly_review_READY.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed(path, expected):
    assert sha(path) == expected, str(path)
    return json.loads(path.read_bytes())


assert not OUT.exists()
r = fixed(REPORT, "7328b774af19b58d25d3bfa6da7fd25323321aa5b4e959e7fbabc3020395c3cb")
f = fixed(FIXTURE, "0831aa1ff22d7afcf088abd1f4d65fe24a15adeadc8ca9ef31c4b0b45f9b37fe")
g = fixed(GUARD, "1a00e4f6390df85a03dfb5fb99ebd4b749b7e04946ff5137b205512d91d569df")
assert r["complete"] is True and r["checks"] == 7089 and r["failures"] == 0 and r["elapsed_ms"] == 39846
assert r["source_before"] == r["source_after"]
assert r["players_before"] == r["players_after"] and len(r["players_before"]) == 15
assert g["passed"] is True and g["save_count"] == 15 and g["save_change_count"] == 0 and g["unexpected_change_count"] == 0
spec = {s["id"]: s for s in f["scenes"]}
post = [row for row in r["records"] if row["kind"] == "AP_POSTDRAW_OWNER"]
assert [p["id"] for p in post] == ["ch4_s3_luoyang_market", "luoyang_artisan_residential_20261022ap", "ch4_s3_luoyang_market"]
for p in post:
    expected = spec[p["id"]]
    assert p["sources"] == expected["source_sha256"]
    receipt = p["receipt"]
    if expected["owner"] == "CITY":
        assert receipt["sources_finalized"] is True and receipt["sources"] == expected["receipt_source_sha256"]
    else:
        assert receipt["finalized"] is True and receipt["source_first"] == receipt["source_final"] == expected["receipt_source_sha256"]
    for path, value in p["sources"].items():
        assert r["source_before"][path]["sha256"].lower() == value.lower()
park = next(p for p in r["records"] if p["kind"] == "AP_E_BEFORE_ORIGINAL_PARKED_ASSERT_READONLY")
ret = next(p for p in r["records"] if p["kind"] == "AP_E_BEFORE_ORIGINAL_RETURN_ASSERTS_READONLY")
final = next(p for p in r["records"] if p["kind"] == "AP_E_PERFORMANCE_ONLY_OFFCENTER_SAME_FIELD")
scope = next(p for p in r["records"] if p["kind"] == "AP_FINITE_DELTA_SCOPE")
assert park["old_Field_weakref_alive"] is True and park["old_Field_inside_tree"] is False
assert park["lease"]["phase"] == "PARKED" and park["lease"]["occupied"] is True and park["lease"]["parked"] is True
assert park["lease"]["estimated_bytes"] == 333305664 < park["lease"]["limit_bytes"] == 536870912
assert ret["old_Field_id"] == park["old_Field_id"] == ret["actual_return_Field_id"]
assert ret["old_Field_inside_tree"] is True and final["same_Field_Scene_layout"] is True
assert ret["actual_reverse_INPUT_foot"] == "(2816.0, 1744.0)" and final["author_arg_is_not_actual_foot"] is True
returned = ret["lease"]["return"]
assert returned["phase"] == "READY" and returned["hit"] is True and returned["final_live_identity"] is True
assert returned["source_count"] == 1613 and returned["source_fresh_sha"] is True and returned["source_hash_passes"] == 1
w = returned["source_worker"]
assert w["complete"] is True and w["running"] is False and w["cancelled"] is False and w["error"] == ""
assert w["active_children"] == 0 and w["children_started"] == w["children_joined"] == w["worker_limit"] == 4
assert w["started_files"] == w["completed_files"] == 1613
draws = [row["measurement"] for row in r["records"] if row["kind"] == "FIRST_OPERABLE_DRAW_BEFORE_POSTVERIFY"]
assert [d["elapsed_usec"] for d in draws] == [13287716, 2867208, 4392701]
assert draws[0]["Field_id"] == draws[2]["Field_id"] and draws[0]["Scene_id"] == draws[2]["Scene_id"] and draws[0]["Player_id"] == draws[2]["Player_id"]
assert draws[2]["foot"] == "(1100.0, 1860.0)" and draws[2]["elapsed_usec"] < 10000000
assert scope["captures"] == scope["doors"] == scope["dialogues"] == [] and scope["native_queries"] == 14
assert scope["return_performance"][0]["performance_pass"] is True and scope["return_performance"][0]["performance_target_usec"] == 10000000
review = {
    "status": "ONE_COMPLETED_E_REPORT_INDEPENDENT_READONLY_FINITE_PASS",
    "report": {"path": str(REPORT), "sha256": sha(REPORT)},
    "fixture_sha256": sha(FIXTURE), "source_fact_count": len(r["source_before"]),
    "source_first_final_same": True, "save_count": 15, "save_report_first_final_same": True,
    "save_report_precision": "SECONDS_ONLY; exact ticks are the separately pinned Root guard credit",
    "external_Root_guard": {"path": str(GUARD), "sha256": sha(GUARD), "passed": True},
    "independent_fixed_owner_maps_match_all_three_actual_postdraw_receipts": True,
    "first_draw_usec": [d["elapsed_usec"] for d in draws],
    "postverify_usec_not_loading": [p["postverify_usec"] for p in post],
    "fresh_return_source_sha_ms": returned["source_sha_ms"], "metadata_ms": returned["metadata_ms"], "resume_ms": returned["resume_ms"],
    "same_Field_Scene_layout_and_original_author_paired_memory": True,
    "actual_reverse_foot": [2816, 1744], "original_author_argument_foot": [2816, 1740],
    "original_10second_return_target_pass": True, "estimated_retained_bytes_not_measured_VRAM": 333305664,
    "prior_11_203165_second_performance_FAIL_retained": True,
    "limits": ["first Market 13.287716 seconds is not a first-load 10-second PASS", "not all-city loading or long-run LRU coverage", "not full-city ART or NPC/voice coverage", "old warnings/errors preserved; not a clean-log claim", "D and both visual checks not replayed"],
    "engine_executed_by_this_review": False, "collector_or_geometry_repeated": False,
}
OUT.write_text(json.dumps(review, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"path": str(OUT), "sha256": sha(OUT), "source_count": len(r["source_before"]), "passed": True, "engine_executed": False}))
