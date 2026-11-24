"""Read completed finite visual report and hash PNG bytes, without opening images."""
from pathlib import Path
import hashlib
import json

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).resolve().parent
SYSTEM = GAME / "build/luoyang_city_full_rollout_20261022ap_system01/finite_wall_yamen_visual_probe_epoch01"
OUT = QA / "wall_yamen_visual_124504_independent_readonly_review_READY.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed(path, expected):
    assert sha(path) == expected, str(path)
    return json.loads(path.read_bytes())


def local(path):
    assert path.startswith("res://") and ".." not in path
    return GAME / path[6:]


assert not OUT.exists()
admission_path = GAME / "build/luoyang_city_full_rollout_20261022ap_root01/wall_yamen_finite_visual_admission_READY.json"
admission = fixed(admission_path, "aacbc800e4c770d4aa62ff32aa71bf64060ecf347b42a8aea5cde315b49e2cae")
report_path = SYSTEM / "output/124504_2540/result.json"
r = fixed(report_path, "8e4716297237edd0f89c06de2eddd1acb8ec84cb75d5bf4330134ffd1a66a670")
config = fixed(SYSTEM / "input_READY.json", "be82f54b44ad1d1e1aea43dff026d3942b5812413c0b3a30a68c7c45f9d14ec8")
assert sha(SYSTEM / "renderer_retry1_READY.gd") == admission["renderer_sha256"]
assert r["complete"] is True and r["checks"] == 591 and r["failures"] == 0 and r["elapsed_ms"] == 3835
assert r["source_before"] == r["source_after"] and len(r["source_before"]) == 145
assert r["players_before"] == r["players_after"] and len(r["players_before"]) == 15
for path, fact in r["source_before"].items():
    p = local(path)
    assert fact["exists"] is True and p.stat().st_size == fact["bytes"] and sha(p) == fact["sha256"]
    if not path.endswith("/input_READY.json"):
        assert config["source_pins"][path] == fact["sha256"]
expected_players = {f"user://save_{slot}{suffix}" for slot in range(5) for suffix in (".json", ".json.bak", ".json.tmp")}
assert set(r["players_before"]) == expected_players
expected = {
    "yamen": ([1150, 1280], "2fe67c103771c2cdea57a651b97cd266155f6ecdae1a02ded3a5a2185162d75d"),
    "market": ([640, 1460], "b9aa7c8d39259151f9b7049460341ead607622629cca35c4cafb781eed4ef92a"),
}
assert len(r["records"]) == 2
for record in r["records"]:
    camera, digest = expected[record["domain"]]
    assert record["camera_center"] == camera and record["world_raster_scale"] == 1
    assert record["picture"]["sha256"] == digest and sha(local(record["picture"]["path"])) == digest
    assert record["picture"]["size"] == "(1280, 960)"
    for key in ("Field_calls", "NPC_spawn_calls", "Physics_queries", "geometry_calls", "import_calls", "walk_PNG_decode_calls"):
        assert record[key] == 0
    assert record["runtime_consumer_or_ART_admission"] is False

result = {
    "status": "INDEPENDENT_READONLY_FINITE_VISUAL_REPORT_FACTS_VERIFIED_NOT_RUNTIME",
    "report": {"path": "res://" + report_path.relative_to(GAME).as_posix(), "sha256": sha(report_path)},
    "root_finite_art_admission_sha256": sha(admission_path),
    "actual_report": {"complete": True, "checks": 591, "failures": 0, "elapsed_ms": 3835},
    "source_facts": {"selected_runtime_inputs": 145, "before_after_complete_facts_equal": True, "current_SHA_and_bytes_exact": True, "not_full_1985_declared_closure_revalidation": True},
    "player_facts": {"count": 15, "before_after_complete_facts_equal": True, "mtime_precision": "Godot integer seconds, not exact ticks", "current_player_read_or_rehash": False},
    "pictures": [{"domain": k, "camera_center": v[0], "sha256": v[1], "current_file_SHA_exact": True, "image_open_or_decode": False} for k, v in expected.items()],
    "boundaries": ["Root reports natural exit; QA does not re-execute or independently recapture process exit", "Root finite art admission only; QA does not reopen images", "No Field, NPC, Physics, geometry, walk decode, import, canonical deployment or loading credit", "Whole Market/Yamen ground and city art remain unapproved", "Original WASAPI/canvas-map/exit texture errors remain non-clean"],
    "qa_engine_runs": 0,
}
OUT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"review": OUT.name, "sha256": sha(OUT), "sources": 145, "players": 15, "PNG_hashes": 2, "image_decodes": 0}))
