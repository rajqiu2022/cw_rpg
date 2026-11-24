"""Freeze source-only expected local mask bytes; no publisher result is consumed.

PNG decoding is read-only. No PNG/native outputs, engine, imports, collector or
canonical writes. Geometry, real native Physics and outdoor ART remain pending.
"""
from pathlib import Path
from collections import Counter
import copy
import hashlib
import json
import math
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT / "game"
QA = Path(__file__).resolve().parent
SYSTEM = GAME / "build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch03"
OUT = QA / "wall_yamen_independent_recipe04_SOURCE_FROZEN_NOT_ACTUAL.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def fixed(path, expected):
    assert sha(path) == expected, str(path)
    return json.loads(path.read_bytes())


def local(path):
    assert path.startswith("res://") and ".." not in path
    return GAME / path[6:]


def box(poly):
    return min(p[0] for p in poly), min(p[1] for p in poly), max(p[0] for p in poly), max(p[1] for p in poly)


def on_line(point, a, b):
    x, y = point
    return (b[0]-a[0])*(y-a[1]) == (b[1]-a[1])*(x-a[0]) and min(a[0], b[0]) <= x <= max(a[0], b[0]) and min(a[1], b[1]) <= y <= max(a[1], b[1])


def inside_closed(point, poly):
    x, y = point
    answer = False
    for a, b in zip(poly, poly[1:] + poly[:1]):
        if on_line(point, a, b):
            return True
        if (a[1] > y) != (b[1] > y) and x < (b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0]:
            answer = not answer
    return answer


def native_blocked(point, rows):
    x, y = point
    if x < 24 or y < 24 or x >= 3048 or y >= 2024:
        return True
    for row in rows:
        poly = row["points_px"]
        left, top, right, bottom = box(poly)
        if "RECT" in row["kind"]:
            if math.ceil(left) <= x < math.ceil(right) and math.ceil(top) <= y < math.ceil(bottom):
                return True
        elif left <= x <= right and top <= y <= bottom and inside_closed(point, poly):
            return True
    return False


def rgba(path):
    with Image.open(path) as source:
        assert source.size == (3072, 2048)
        return source.convert("RGBA").tobytes()


assert not OUT.exists()
parent_path = QA / "wall_yamen_independent_delta_recipe03_PREPARED_NOT_ACTUAL.json"
plan = fixed(parent_path, "8c70c30132f17f6f082931afafed5a6c3a0d7be8bc7523380f266a4316c911a5")
input_path = SYSTEM / "input_READY.json"
config = fixed(input_path, "044d933bba30484de5b82c083a7e3ed487a33a977945c04e990912b0430904db")
publisher = SYSTEM / "publisher_READY.gd"
assert sha(publisher) == "55b9c28203079a8943612df6a8076b45e7d0f5e335515dcdb49da30510591615"
assert config["status"] == "FROZEN_FINITE_TWO_DOMAIN_ROOT_ONLY_INPUT"
expectations = {}
for name, key in (("Market", "market"), ("Yamen", "yamen")):
    parent_geometry = plan[name]["parent_geometry"]
    assert config[key]["raw_geometry"] == parent_geometry
    old_native = [r for r in parent_geometry["solids"] if r["kind"] != "ADDITIVE_NATIVE_BASE"]
    dg = [r for r in parent_geometry["solids"] if r["kind"] == "ADDITIVE_NATIVE_BASE"]
    child_native = [r for r in plan[name]["expected_child_geometry"]["solids"] if r["kind"] != "ADDITIVE_NATIVE_BASE"]
    assert len(old_native) == (31 if name == "Market" else 29)
    assert len(child_native) == (30 if name == "Market" else 32)
    assert len(dg) == (13 if name == "Market" else 10)
    if name == "Market":
        domains = [[35, 1408, 111, 13]]
    else:
        domains = []
        for row in plan["Yamen"]["new_native_source_polygons"]:
            left, top, right, bottom = box(row["points_px"])
            domains.append([math.floor(left), math.floor(top), math.ceil(right)+1-math.floor(left), math.ceil(bottom)+1-math.floor(top)])
        assert domains == [[1069, 1148, 143, 14], [1069, 1278, 143, 14], [1063, 1425, 134, 27]] == config[key]["local_mask_domains_px"]
    seen = set()
    for x, y, width, height in domains:
        for py in range(y, y+height):
            for px in range(x, x+width):
                assert (px, py) not in seen
                seen.add((px, py))
    assert len(seen) == (1443 if name == "Market" else 7622)
    parent_png = local(config[key]["walk_path"])
    raw_png = local(config[key]["raw_walk_path"])
    assert sha(parent_png) == parent_geometry["mask_sha256"]
    assert sha(raw_png) == "0dc78a4affde8a13d1d2f58385b4ac5da102b1718f8e5b48d12dd066b0dedcfa"
    original, raw = rgba(parent_png), rgba(raw_png)
    assert digest(original) == config[key]["mask_rgba_sha256"]
    child = bytearray(original)
    changes = []
    for px, py in sorted(seen, key=lambda p: (p[1], p[0])):
        index = (py*3072+px)*4
        base = raw[index:index+4]
        expected_old = b"\0\0\0\xff" if native_blocked((px, py), old_native) else base
        assert original[index:index+4] == expected_old, (name, px, py, "independent parent RAW/native rule mismatch")
        desired = b"\0\0\0\xff" if native_blocked((px, py), child_native) else base
        if name == "Yamen" and desired != original[index:index+4]:
            assert desired == b"\0\0\0\xff"
        if desired != original[index:index+4]:
            child[index:index+4] = desired
            changes.append({"x": px, "y": py, "old_RGBA": list(original[index:index+4]), "new_RGBA": list(desired)})
    assert changes
    inverse = bytearray(child)
    for row in changes:
        index = (row["y"]*3072+row["x"])*4
        inverse[index:index+4] = original[index:index+4]
    assert inverse == original
    assert sha(parent_png) == parent_geometry["mask_sha256"]
    expectations[name] = {"old_native_source_count": len(old_native), "new_native_source_count": len(child_native), "DG_source_count_unchanged": len(dg), "old_native_geometry": old_native, "new_native_geometry": child_native, "original_DG_geometry_unchanged": dg, "domains_xywh": domains, "visited_pixel_count": len(seen), "changed_pixel_count": len(changes), "parent_RGBA_sha256": digest(original), "independent_expected_child_RGBA_sha256": digest(child), "changes_RGBA_sha256": digest((json.dumps(changes, sort_keys=True, separators=(",", ":"))+"\n").encode()), "expected_changed_pixels": changes, "whole_25MiB_RGBA_inverse": True, "outside_domains_identical": True, "RAW_not_blind_white_or_black": True, "PNG_edits": 0, "not_native_geometry_or_runtime_ART_PASS": True}
plan["status"] = "INDEPENDENT_SOURCE_FROZEN04_LOCAL_RGBA_EXPECTED_NOT_NATIVE_RUNTIME_OR_ART_ACCEPTANCE"
plan["prepared_recipe03"] = {"path": "res://" + parent_path.relative_to(GAME).as_posix(), "sha256": sha(parent_path)}
plan["unique_publisher_input_identity_only_not_expected_output"] = {"publisher": {"path": "res://" + publisher.relative_to(GAME).as_posix(), "sha256": sha(publisher)}, "input": {"path": "res://" + input_path.relative_to(GAME).as_posix(), "sha256": sha(input_path)}}
plan["independent_local_mask_expectations"] = expectations
plan["PNG_decodes_or_edits"] = "4 read-only parent/RAW decodes,0 edits or PNG outputs"
plan["freeze_barriers_completed_now"] = ["fixed source input/publisher identities", "native/DGsource separation", "source-derived three integer envelopes", "independent originalPNG/RAW local mask and completeRGBA inverse"]
plan["remaining_actual_barriers"] = ["Root actual unique publisher/native typed readback", "independent fixed-packet route extraction/affected selection", "native and independent fullbody87517/1085 local geometry result", "outdoor original-alpha picture", "future consumer/source closure/formal admission"]
OUT.write_text(json.dumps(plan, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(json.dumps({"path": str(OUT), "sha256": sha(OUT), "local": {name: {k: r[k] for k in ("visited_pixel_count", "changed_pixel_count", "parent_RGBA_sha256", "independent_expected_child_RGBA_sha256")} for name, r in expectations.items()}, "engine_runs": 0, "PNG_outputs": 0, "canonical_writes": 0, "geometry_accepted": False}))
