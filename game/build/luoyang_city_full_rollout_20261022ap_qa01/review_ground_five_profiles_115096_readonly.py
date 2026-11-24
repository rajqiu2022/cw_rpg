"""Read completed ground-only two-camera report; no image/native decoding."""
from pathlib import Path
import hashlib
import json

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).resolve().parent
HERE = GAME / "build/luoyang_city_full_rollout_20261022ap_system01/ground_purpose_preview_epoch01/retry1"
OUT = QA / "ground_five_profiles_115096_independent_readonly_review_READY.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def local(path):
    assert path.startswith("res://") and ".." not in path
    return GAME / path[6:]


def fixed(path, digest):
    assert sha(path) == digest, str(path)
    return json.loads(path.read_bytes())


assert not OUT.exists()
admission_path = GAME / "build/luoyang_city_full_rollout_20261022ap_root01/ground_five_rect_visual_admission_READY.json"
admission = fixed(admission_path, "657722693680f15564aecc55a3e75929204400e3badcb509abb076259a31d8fe")
r = fixed(local(admission["actual_report_path"]), "098735a376dc19917145fa367f5f0a9890dcd6bf3d049643cbf21312b58b71c2")
config = fixed(HERE / "input_READY.json", "6d28a6ef5a2ec3f5b83bf90704c286df4055023966b070dd55771f386a735dba")
previous = fixed(GAME / "build/luoyang_city_full_rollout_20261022ap_system01/finite_wall_yamen_visual_probe_epoch01/output/124504_2540/result.json", "8e4716297237edd0f89c06de2eddd1acb8ec84cb75d5bf4330134ffd1a66a670")
assert sha(HERE / "renderer_READY.gd") == "ec94ed58309385358b55861e37395a8956a24d84b9eeb9fdd91f1ea0a22e1e65"
env = GAME / "build/luoyang_city_full_rollout_20261022ap_system01/ground_purpose_preview_epoch01/ENV_metadata_retry2_candidate.gd"
assert sha(env) == admission["candidate_ENV_sha256"] == "a751dbd4ce014abd2e808d7c9a947dc0e4a314d4b42930a6392a1d6eb7c20a7d"
shader = GAME / "build/luoyang_city_full_rollout_20261022ap_system01/ground_purpose_visual_epoch01/rect_ground_purpose_candidate.gdshader"
assert sha(shader) == admission["candidate_shader_sha256"] == "e80916d7fa99218e3dc36ee1a83efd49f544ed426739941499c8500f23da14f1"
assert r["complete"] is True and (r["checks"], r["failures"], r["elapsed_ms"]) == (620, 0, 4032)
assert r["source_before"] == r["source_after"] and len(r["source_before"]) == 149
assert r["players_before"] == r["players_after"] and len(r["players_before"]) == 15
for path, fact in r["source_before"].items():
    p = local(path)
    assert fact["exists"] is True and p.stat().st_size == fact["bytes"] and sha(p) == fact["sha256"]
    if not path.endswith("/input_READY.json"):
        assert config["source_pins"][path] == fact["sha256"]

# Expected material profiles transcribed from frozen A751 purpose_rect_profile,
# not from current actual output. Rectangle identity is separately inherited.
profiles = {
    "official_court_axis": ("official_axis", "(44.0, 24.0, 44.0, 24.0)", 8, "(0.56, 0.57, 0.54, 1.0)", .46, .52, [1408,840,256,1000]),
    "petition_waiting_court": ("waiting_court", "(64.0, 48.0, 64.0, 48.0)", 18, "(0.55, 0.555, 0.525, 1.0)", .40, .48, [640,1460,512,256]),
    "market_pawn_clean_paved_forecourt": ("pawn_forecourt_opaque_core", "(48.0, 96.0, 64.0, 24.0)", 12, "(0.54, 0.555, 0.525, 1.0)", .34, 1, [0,1280,1160,648]),
    "market_main_street": ("market_spine", "(28.0, 20.0, 28.0, 20.0)", 6, "(0.56, 0.57, 0.54, 1.0)", .46, .50, [1472,800,128,1224]),
    "market_pawn_approach": ("pawn_public_approach", "(40.0, 24.0, 40.0, 24.0)", 8, "(0.55, 0.56, 0.53, 1.0)", .42, .56, [220,1928,1252,96]),
}
images = {
    "yamen": ([1150,1280], "5171f8147cd74d1c186fd28f96c934a3d2c890a6d29cb15a9e54cf9f475acf36"),
    "market": ([640,1460], "9e6db1a52f447bbc22e7e660cb6cf6430b4695319ae4563f37e428c2eca9c327"),
}
assert len(r["records"]) == 2
seen = []
for record in r["records"]:
    old = next(x for x in previous["records"] if x["domain"] == record["domain"])
    assert record["rendered"] == old["rendered"] and record["same_124504_native_DG_sign_context"] is True
    camera, digest = images[record["domain"]]
    assert record["camera_center"] == camera and record["world_raster_scale"] == 1
    assert record["picture"]["sha256"] == digest and sha(local(record["picture"]["path"])) == digest
    assert record["picture"]["size"] == "(1280, 960)"
    for key in ("Field_calls", "NPC_spawn_calls", "Physics_queries", "geometry_calls", "import_calls", "walk_PNG_decode_calls"):
        assert record[key] == 0
    assert record["runtime_consumer_or_ART_admission"] is False
    for row in record["purpose_ground_bindings"]:
        assert row["id"] not in seen
        seen.append(row["id"])
        purpose, edges, wear, tone, contrast, core, rect = profiles[row["id"]]
        assert row["profile"] == {"purpose": purpose, "edge_widths": edges, "wear": wear, "tone": tone, "contrast": contrast, "core": core}
        assert row["rect"] == rect and row["uniform_scale"] == .25
        assert row["unchanged_source_texture"] == "res://art/modules/ancient_temple_assembled_20261016/courtyard_floor_v1.png"
        assert row["actual_transition_metadata"] == {"whole_author_rect": True, "legacy_transition_replaced_by_purpose_profile": True, "core_opacity": core, "edge_widths_world": edges, "wear_world": wear, "no_tile_edge_feather": True}
assert set(seen) == set(profiles)

result = {
    "status": "INDEPENDENT_FINITE_FIVE_GROUND_PROFILES_ACTUAL_REPORT_READONLY_VERIFIED",
    "actual_report_sha256": admission["actual_report_sha256"],
    "Root_finite_admission_sha256": sha(admission_path),
    "actual": {"complete": True, "checks": 620, "failures": 0, "elapsed_ms": 4032},
    "selected_sources": {"count": 149, "before_after_full_facts_equal": True, "current_SHA_bytes_exact": True},
    "players": {"count": 15, "before_after_full_facts_equal": True, "mtime_precision": "Godot seconds, not Root exactticks", "current_save_read": False},
    "same_previous_native_DG_sign_render_rows": True,
    "five_fixed_A751_profiles": {key: {"purpose": values[0], "rect": values[6], "uniform_scale": .25} for key, values in profiles.items()},
    "picture_SHA_exact_no_decode": {key: value[1] for key, value in images.items()},
    "ENV_sha256": sha(env), "shader_sha256": sha(shader),
    "boundaries": ["Only finite five material profiles/two old cameras; Root art decision, no whole city approval", "0Field/Physics/NPC/import/geometry or loading credit", "Old WASAPI/CanvasMap/Texture-RID warnings remain nonclean", "No new source closure/deployment approval"],
    "operations": {"engine": 0, "PNG_decode": 0, "native_decode": 0, "geometry_sampling": 0, "collector": 0, "canonical_write": 0}
}
OUT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"review": OUT.name, "sha256": sha(OUT), "sources": 149, "players": 15, "profiles": 5, "PNG_hashes": 2, "decodes": 0}))
