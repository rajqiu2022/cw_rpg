"""Root-approved two-row source arithmetic correction, never actual backfill.

Derives moved tree rectangle from frozen original center/size and AP's declared
center translation, not from native diagnostics. Preserves old oracle/FAIL and
both precomputed local mask expectations without decoding PNGs again.
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
OUT = QA / "wall_yamen_independent_recipe06_TWO_SOURCE_ROWS_FIXED_NOT_ACTUAL.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed(path, expected):
    assert sha(path) == expected, str(path)
    return json.loads(path.read_bytes())


def f(value):
    return struct.unpack("<f", struct.pack("<f", float(value)))[0]


def add(a, b):
    return [f(f(x)+f(y)) for x, y in zip(a, b)]


def sub(a, b):
    return [f(f(x)-f(y)) for x, y in zip(a, b)]


def mul(a, scalar):
    return [f(f(x)*f(scalar)) for x in a]


def local(path):
    assert path.startswith("res://") and ".." not in path
    return GAME / path[6:]


def aabb(points):
    return min(p[0] for p in points), min(p[1] for p in points), max(p[0] for p in points), max(p[1] for p in points)


def overlap(a, b):
    return a[0] <= b[2] and a[2] >= b[0] and a[1] <= b[3] and a[3] >= b[1]


assert not OUT.exists()
parent_path = QA / "wall_yamen_independent_recipe05_SOURCE_FROZEN_NOT_ACTUAL.json"
old = fixed(parent_path, "c1556bc33e1f14f2245aa8609c1726ba54b96eef008bb7ecee8f7f18504b0ca0")
pawn_diag_path = QA / "market_source_rect_association_diagnostic_ONLY.json"
pawn_diag = fixed(pawn_diag_path, "098be798dc517d9ee4c55ec09dc7bce9460ebadd738be21b9a7caa24ed675709")
report_path = SYSTEM / "market_alpha_pin_retry6/publication/17536/result.json"
report = fixed(report_path, "0058e2da30d0b0bbccc8579724ff9e916137de583cd3495bd2fdfb6025372511")
author_path = SYSTEM / "market_alpha_pin_retry6/market_author.json"
author = fixed(author_path, "b11f48b8249ab27784aef1dc5b960e9ede7430e381a923c389c6461d95ca7a2e")
tree_parent_res = "res://build/luoyang_city_assembled_publication_20261016b/78428_1686/ch4_s3_luoyang_market/manifest.json"
tree_parent_path = local(tree_parent_res)
tree_parent_sha = "eac64463aa3bc00835114b0856e6e00a98d57c38d0fd6e8de472f329cd28bd13"
assert report["source_first"][tree_parent_res] == report["source_final"][tree_parent_res] == tree_parent_sha
tree_parent = fixed(tree_parent_path, tree_parent_sha)
tree_record = next(r for r in tree_parent["record"]["objects"] if r["id"] == "assembled_market_tree_group_a")
move = next(r for r in author["layout_successor"]["native_moves"] if r["id"] == tree_record["id"])
assert tree_record["world_foot_px"] == move["old_foot"] == [820, 1750]
assert move["new_foot"] == [720, 980]
delta = sub(move["new_foot"], move["old_foot"])
new_center = add(tree_record["physical_center_px"], delta)
size = tree_record["collision_size_px"]
low = sub(new_center, mul(size, .5))
high = add(low, size)
source_tree_polygon = [low, [high[0], low[1]], high, [low[0], high[1]]]
old_rows = {r["id"]: r for r in old["Market"]["parent_geometry"]["solids"]}
pawn = next(r for r in pawn_diag["rows"] if r["differences"])
assert pawn["id"] == "market_west_ward_frontage_solid_2"
assert len(pawn["differences"]) == 2
replacements = {pawn["id"]: pawn["per_vertex_author_expression_NOT_observed_native"], "assembled_market_tree_group_a_rect": source_tree_polygon}
assert set(replacements) <= set(old_rows)
diffs = []
for identity, points in replacements.items():
    original = old_rows[identity]["points_px"]
    for vertex, (before, after) in enumerate(zip(original, points)):
        for axis in range(2):
            if before[axis] != after[axis]:
                diffs.append({"id": identity, "vertex": vertex, "axis": axis, "old_frozen": before[axis], "new_source_expression": after[axis]})
assert len(diffs) == 4 and sum(r["id"] == "assembled_market_tree_group_a_rect" for r in diffs) == 2
plan = copy.deepcopy(old)
tables = [plan["Market"]["parent_geometry"]["solids"], plan["Market"]["expected_child_geometry"]["solids"], plan["independent_local_mask_expectations"]["Market"]["old_native_geometry"], plan["independent_local_mask_expectations"]["Market"]["new_native_geometry"]]
for rows in tables:
    for identity, points in replacements.items():
        matching = [r for r in rows if r["id"] == identity]
        assert len(matching) == 1
        matching[0]["points_px"] = copy.deepcopy(points)
for identity, points in replacements.items():
    for x, y, width, height in old["independent_local_mask_expectations"]["Market"]["domains_xywh"]:
        domain = [x, y, x+width, y+height]
        assert not overlap(aabb(points), domain)
        assert not overlap(aabb(old_rows[identity]["points_px"]), domain)
# No pixel values, changed-cell lists, counts or pre-actual source-derived mask
# SHA is re-measured or amended. These source corrections are outside that area.
for name in ("Market", "Yamen"):
    before = old["independent_local_mask_expectations"][name]
    after = plan["independent_local_mask_expectations"][name]
    for key in ("domains_xywh", "visited_pixel_count", "changed_pixel_count", "parent_RGBA_sha256", "independent_expected_child_RGBA_sha256", "changes_RGBA_sha256", "expected_changed_pixels"):
        assert before[key] == after[key]
plan["previous_failed_epoch04_and_recipe05_retained"] = {"frozen_recipe_path": "res://" + parent_path.relative_to(GAME).as_posix(), "sha256": sha(parent_path), "actual38992_failure_not_erased_or_reclassified": True}
plan["source_arithmetic_two_row_revision"] = {"authority": "Root explicitly approved only two source rows after112732 diagnostic; diagnostic values were NOT read as input", "pawn_fixed_source_derivation": {"path": "res://" + pawn_diag_path.relative_to(GAME).as_posix(), "sha256": sha(pawn_diag_path)}, "tree_fixed_source_derivation": {"original_record": tree_record, "original_record_manifest_path": tree_parent_res, "original_record_manifest_sha256": tree_parent_sha, "move": move, "delta": delta, "new_physical_center": new_center, "collision_size_unchanged": size, "derived_low": low, "derived_high": high, "expression": "native Vector2 float32 originalCenter+declaredDelta; low=newCenter-size*.5; high=low+size. Old oracle moved already-rounded corners instead, which is nonassociative."}, "exact_four_coordinate_components_in_two_rows": diffs, "no_count_ID_kind_or_vertex_order_change": True, "no_epsilon": True, "no_current_native_or_diagnostic_values_as_expected": True, "local_expected_RGBA_and_cells_inherited_without_redecode": True}
plan["fixed_input_sha256"][tree_parent_res] = tree_parent_sha
plan["fixed_input_sha256"]["res://" + pawn_diag_path.relative_to(GAME).as_posix()] = sha(pawn_diag_path)
plan["status"] = "INDEPENDENT_SOURCE_RECIPE06_EXACT_TWO_ROW_ARITHMETIC_SUCCESSOR_AWAIT_SYSTEM_INPUT_AND_ACTUAL"
plan["remaining_actual_barriers"].append("NEW fixed publisher/input identity must consume only these two source-derived row corrections; retain first actual failure")
OUT.write_text(json.dumps(plan, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(json.dumps({"path": str(OUT), "sha256": sha(OUT), "two_source_row_diffs": diffs, "PNG_decodes": 0, "engine_runs": 0, "canonical_writes": 0, "actual_values_read": False}))
