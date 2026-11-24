"""Independent source-only review, not a source admission or expected-map builder."""
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
FIXTURE = QA / "bounded_groups_v5_author_anchors_READY.json"
RESULT = QA / "market_raw_source_diagnostic/111512_1796/result.json"
EXPECTED_PNGS = {
    "res://art/maps/luoyang_enclosure_v11/ch4_s2_canal_docks/ground_v14/root_ground_v14_02/" + leaf + ".png"
    for leaf in ("floor", "ground_off_raw", "ground_on_raw")
} | {
    "res://art/maps/luoyang_enclosure_v11/source/courtyard_wall_gate_v3.png",
    "res://art/maps/luoyang_modular_v2/source/notice_pavilion_v2.png",
    "res://art/modules/building/build_linxi_smithy_front.png",
    "res://art/modules/prop/linxi_brazier_forge_v1.png",
}

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def local(path):
    assert path.startswith("res://") and ".." not in path
    return ROOT / "game" / path[6:]

assert sha(FIXTURE) == "56af9d883a163e6cd0646f6ef4b394e46fc2c29e10baf254fc5d0bc548ee618d"
fixed = json.loads(FIXTURE.read_bytes())
expected = next(row for row in fixed["scenes"] if row["id"] == "ch4_s3_luoyang_market")["source_sha256"]
actual = json.loads(RESULT.read_bytes())
assert actual["complete"] and actual["failures"] == 0
row, = actual["records"]
assert row["raw_scene_path"] == "res://data/scenes/ch4_s3_luoyang_market.tres"
assert (row["public_request_count"], row["resolve_count"], row["geometry_runs"], row["Field_created"]) == (0, 0, 0, False)
assert row["actual_count"] == 1595 and row["fixed_count"] == 1581 and not row["missing"] and not row["mismatch"]
extra = set(row["extra"])
assert len(extra) == 14
pngs = {path[:-7] for path in extra if path.endswith(".import")}
assert pngs == EXPECTED_PNGS
rows = []
for png in sorted(pngs):
    assert png in expected and sha(local(png)) == expected[png]
    import_path = png + ".import"
    text = local(import_path).read_text(encoding="utf-8")
    source_file, = re.findall(r'^source_file="([^"]+)"$', text, re.M)
    compiled, = re.findall(r'^path="([^"]+)"$', text, re.M)
    assert source_file == png and compiled in extra and compiled.endswith(".ctex")
    assert compiled in row["actual_collector_keys"] and import_path in row["actual_collector_keys"]
    for path in (import_path, compiled):
        assert path not in expected and sha(local(path)) == row["actual_source_hashes_DIAGNOSTIC_ONLY"][path]
    rows.append({"source_png": png, "already_fixed_png_sha256": expected[png], "existing_import_path": import_path, "existing_import_sha256": sha(local(import_path)), "declared_compiled_path": compiled, "existing_compiled_sha256": sha(local(compiled))})
assert {leaf for r in rows for leaf in (r["existing_import_path"], r["declared_compiled_path"])} == extra
out = QA / "market_fourteen_existing_import_closure_independent_review_READY.json"
assert not out.exists()
out.write_text(json.dumps({"status": "INDEPENDENT_EXISTING_IMPORT_REFERENCE_PROOF_NOT_SOURCE_ADMISSION", "fixed_fixture_sha256": sha(FIXTURE), "actual_diagnostic_result_sha256": sha(RESULT), "seven_source_pngs_already_fixed": True, "existing_exact_import_and_compiled_leaves": 14, "missing": [], "mismatch": [], "rows": rows, "no_engine_import_geometry_or_canonical_writes": True, "requires_Root_explicit_closure_successor_authority": True}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"review": str(out), "sha256": sha(out), "existing_leaf_count": 14, "new_runtime_asset_count": 0}))
