"""Source-only comparison of frozen AP rect transforms; not native observations.

No packet decode/engine/epsilon/actual-value backfill. Does not alter any oracle.
"""
from pathlib import Path
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT / "game"
QA = Path(__file__).resolve().parent
SYSTEM = GAME / "build/luoyang_city_full_rollout_20261022ap_system01"
OUT = QA / "market_source_rect_association_diagnostic_ONLY.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed(path, expected):
    assert sha(path) == expected
    return json.loads(path.read_bytes())


def f(v):
    return struct.unpack("<f", struct.pack("<f", float(v)))[0]


def add(a, b):
    return [f(f(x)+f(y)) for x, y in zip(a, b)]


def sub(a, b):
    return [f(f(x)-f(y)) for x, y in zip(a, b)]


def mul(a, scalar):
    return [f(f(x)*f(scalar)) for x in a]


def transform(p, foot, anchor, scale):
    return add(foot, mul(sub(p, anchor), scale))


assert not OUT.exists()
author = fixed(SYSTEM / "market_alpha_pin_retry6/market_author.json", "b11f48b8249ab27784aef1dc5b960e9ede7430e381a923c389c6461d95ca7a2e")
raw = fixed(SYSTEM / "independent_raw_geometry_handoff_READY.json", "3ed674aa85b9cd8ac459a3f32baf3c90df872822bcd8cc7a26ee1a623f930f43")
report = fixed(SYSTEM / "market_alpha_pin_retry6/publication/17536/result.json", "0058e2da30d0b0bbccc8579724ff9e916137de583cd3495bd2fdfb6025372511")
transform_path = SYSTEM / "market_alpha_pin_retry6/market_transform.gd"
res = "res://" + transform_path.relative_to(GAME).as_posix()
assert sha(transform_path) == report["source_first"][res] == report["source_final"][res]
old_by_id = {r["id"]: r for r in raw["geometry"]["ch4_s3_luoyang_market"]["solids"]}
all_rows = []
for index, asset_key in enumerate(("pawn", "tailor")):
    asset = author["assets"][asset_key]
    obj = author["new_objects"][index]
    for ordinal, rect in enumerate(asset["solid_rects"]):
        low = [f(rect[0]), f(rect[1])]
        high = add(low, rect[2:])
        source_corners = [low, [high[0], low[1]], high, [low[0], high[1]]]
        per_vertex = [transform(p, obj["world_foot_px"], asset["source_ground_anchor_px"], asset["scale"]) for p in source_corners]
        old_low = transform(rect[:2], obj["world_foot_px"], asset["source_ground_anchor_px"], asset["scale"])
        old_high = add(old_low, mul(rect[2:], asset["scale"]))
        old_low_plus_size = [old_low, [old_high[0], old_low[1]], old_high, [old_low[0], old_high[1]]]
        identity = obj["id"] + "_solid_" + str(ordinal)
        assert old_by_id[identity]["points_px"] == old_low_plus_size
        differences = [{"vertex": pi, "axis": axis, "frozen_oracle": old_low_plus_size[pi][axis], "source_per_vertex_expression": per_vertex[pi][axis]} for pi in range(4) for axis in range(2) if old_low_plus_size[pi][axis] != per_vertex[pi][axis]]
        all_rows.append({"id": identity, "source_rect": rect, "source_foot": obj["world_foot_px"], "source_anchor": asset["source_ground_anchor_px"], "source_uniform_scale": asset["scale"], "old_frozen_oracle_low_plus_size": old_low_plus_size, "per_vertex_author_expression_NOT_observed_native": per_vertex, "differences": differences})
out = {"status": "STATIC_SOURCE_ARITHMETIC_ASSOCIATION_MISMATCH_NOT_NATIVE_OBSERVATION_OR_ACCEPTANCE", "source_author_sha256": "b11f48b8249ab27784aef1dc5b960e9ede7430e381a923c389c6461d95ca7a2e", "source_transform": {"path": res, "sha256": sha(transform_path), "expression": "Rect2 sourcecorners; every vertex independently foot+(point-anchor)*scale_value"}, "frozen_oracle_expression": "from_rect transforms low, scales size, adds low+size for high; non-associative float32 differs", "rows": all_rows, "differing_polygon_count": sum(bool(r["differences"]) for r in all_rows), "differing_component_count": sum(len(r["differences"]) for r in all_rows), "engine_runs": 0, "binary_decodes": 0, "actual_source_values_consumed": False, "old_oracles_and_failure_unchanged": True, "not_proof_this_is_only_actual38992_predicate_failure": True}
OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(json.dumps({"path": str(OUT), "sha256": sha(OUT), "differing_polygon_count": out["differing_polygon_count"], "differing_component_count": out["differing_component_count"], "engine_runs": 0, "actual_values_consumed": False}))
