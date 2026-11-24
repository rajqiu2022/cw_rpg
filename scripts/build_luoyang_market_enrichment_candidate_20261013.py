#!/usr/bin/env python3
"""Build a real-module, offline Luoyang south-market enrichment candidate.

This script reads the frozen/current market layout and existing PNG modules.  It
writes only a new ignored preview directory.  It never edits or imports a Godot
resource, scene, walk mask, collision asset, portal, NPC, or interaction.
"""

from __future__ import annotations

import hashlib
import json
import math
import re
from pathlib import Path
from typing import Any

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/previews/scene_module/luoyang_city_enrichment_20261013/market_candidate_v2"
DESIGN_SIZE = (3072, 2048)

LAYOUT = ROOT / "game/data/maps/luoyang_enclosure_v11_candidates/ch4_s3_luoyang_market_layout.tres"
SCENE = ROOT / "game/data/scenes/luoyang_enclosure_v11_candidates/ch4_s3_luoyang_market.tres"
BASE_CONTRACT = ROOT / "game/art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s3_luoyang_market/art_contract.json"
EXPORT_PLAN = ROOT / "game/art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/export_plan.json"
FLOOR = ROOT / "game/art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/ground_v14/root_ground_v14_02/floor.png"
BEFORE = ROOT / "game/build/luoyang_enclosure_v13_export_preview/root_full_v14_ch4_s3_luoyang_market_01/full_region.png"
MODULE_SEMANTICS = ROOT / "game/art/maps/luoyang_modular_v3/source/module_semantics.json"

STREET_ROW = ROOT / "game/art/maps/luoyang_modular_v3/source/street_row_v3.png"
STALL = ROOT / "game/art/maps/luoyang_modular_v3/source/goods_stall_v2.png"
TREE = ROOT / "game/art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s3_luoyang_market/entities/native_tree.png"
COTTAGE = ROOT / "assets/processed/scene_module/zhuwei-release/building-v2/prop_zhuwei_cottage_25d_v2_alpha.png"
COTTAGE_RAW = ROOT / "assets/raw/scene_module/zhuwei-release/building-v2/prop_zhuwei_cottage_25d_v2.png"
COTTAGE_META = ROOT / "assets/raw/scene_module/zhuwei-release/building-v2/prop_zhuwei_cottage_25d_v2.meta.json"

EXPECTED_PINS = {
    BASE_CONTRACT: "bc100b541f74ddaa49391ccb7e8a5161905f3586c243dc74eded840284f8dc5f",
    EXPORT_PLAN: "c8ea61b7c98bdb18169ccfeb37ec4279998a06b5fdcbd08980bafc9d279ae2f6",
    STREET_ROW: "c012d6d3698a8ce00d3f3f32202614a1d2743dc5773c53e5521fd99821da0303",
    STALL: "85cfbe6b14d6aef518d33acb3c3034e07a7b26e0d3e57dc3e9c1047452d416d0",
    MODULE_SEMANTICS: "9a2f68fd3c6c243dd690a04dbdeec8bd8627931aa498337b2fa01957a9c449c2",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def pin(path: Path) -> dict[str, Any]:
    return {
        "path": path.relative_to(ROOT).as_posix(),
        "sha256": sha256(path),
        "bytes": path.stat().st_size,
    }


def game_path(res_path: str) -> Path:
    if not res_path.startswith("res://"):
        raise ValueError(f"not a res path: {res_path}")
    return ROOT / "game" / res_path.removeprefix("res://")


def extract_top_level_dicts(text: str, marker: str) -> list[str]:
    start = text.index(marker)
    array_start = text.index("[{", start)
    blocks: list[str] = []
    depth = 0
    block_start = -1
    in_string = False
    escaped = False
    for index in range(array_start + 1, len(text)):
        char = text[index]
        if in_string:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == '"':
                in_string = False
            continue
        if char == '"':
            in_string = True
        elif char == "{":
            if depth == 0:
                block_start = index
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0 and block_start >= 0:
                blocks.append(text[block_start:index + 1])
                block_start = -1
        elif char == "]" and depth == 0:
            break
    return blocks


def string_field(block: str, name: str) -> str:
    match = re.search(rf'(?:&)?"{re.escape(name)}"\s*:\s*"([^"]*)"', block)
    if not match:
        raise ValueError(f"missing string field {name}")
    return match.group(1)


def vector2_field(block: str, name: str) -> tuple[float, float]:
    match = re.search(
        rf'(?:&)?"{re.escape(name)}"\s*:\s*Vector2\(([-+0-9.eE]+),\s*([-+0-9.eE]+)\)',
        block,
    )
    if not match:
        raise ValueError(f"missing Vector2 field {name}")
    return float(match.group(1)), float(match.group(2))


def float_field(block: str, name: str) -> float:
    match = re.search(rf'(?:&)?"{re.escape(name)}"\s*:\s*([-+0-9.eE]+)', block)
    if not match:
        raise ValueError(f"missing float field {name}")
    return float(match.group(1))


def parse_current_visual_objects() -> list[dict[str, Any]]:
    text = LAYOUT.read_text(encoding="utf-8")
    objects: list[dict[str, Any]] = []
    for block in extract_top_level_dicts(text, "visual_objects = Array[Dictionary](["):
        pos = vector2_field(block, "pos")
        size = vector2_field(block, "render_size_px")
        objects.append({
            "id": string_field(block, "id"),
            "texture": game_path(string_field(block, "texture")),
            "depth_foot_y": float_field(block, "depth_foot_y"),
            "render_size_px": size,
            "render_origin_px": (
                pos[0] * DESIGN_SIZE[0] - size[0] / 2.0,
                pos[1] * DESIGN_SIZE[1] - size[1] / 2.0,
            ),
        })
    if len(objects) < 10:
        raise RuntimeError(f"visual object parser returned only {len(objects)} objects")
    return objects


ASSETS: dict[str, dict[str, Any]] = {
    "cottage": {
        "source": COTTAGE,
        "source_size_px": [1024, 1024],
        "source_foot_px": [512.0, 880.0],
        "source_collision_rect_px": [130.0, 720.0, 920.0, 865.0],
        "source_door_approach_px": [430.0, 900.0],
        "semantic_authority": "Offline candidate author foot at visible masonry-base bottom; collision excludes front step and is not Field verified.",
        "future_game_path": "res://art/maps/luoyang_enrichment_candidates/source/prop_zhuwei_cottage_25d_v2_alpha.png",
    },
    "street_row": {
        "source": STREET_ROW,
        "source_size_px": [1536, 1024],
        "source_foot_px": [768.0, 911.0],
        "source_collision_rect_px": [92.0, 817.0, 1449.0, 906.0],
        "source_door_approach_px": [768.0, 965.0],
        "semantic_authority": "Exact registered module_semantics transform; approach is a new outside review point only.",
        "future_game_path": "res://art/maps/luoyang_modular_v3/source/street_row_v3.png",
    },
    "stall": {
        "source": STALL,
        "source_size_px": [1536, 1024],
        "source_foot_px": [768.0, 960.0],
        "source_collision_rect_px": [95.0, 780.0, 1440.0, 960.0],
        "source_door_approach_px": [768.0, 1010.0],
        "semantic_authority": "Recovered exactly from the retained formal stall transform; approach is not a new interaction identity.",
        "future_game_path": "res://art/maps/luoyang_modular_v3/source/goods_stall_v2.png",
    },
    "tree": {
        "source": TREE,
        "source_size_px": [178, 250],
        "source_foot_px": [76.0, 243.68115234375],
        "source_collision_rect_px": [64.0, 225.68115234375, 88.0, 243.68115234375],
        "source_door_approach_px": None,
        "semantic_authority": "Exact current native-tree 24x18 foot collision convention.",
        "future_game_path": "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s3_luoyang_market/entities/native_tree.png",
    },
}


PLACEMENT_SPECS = [
    ("v2_residence_nw_rear", "cottage", (320.0, 420.0), 0.42, "northwest rear residential court"),
    ("v2_residence_ne_rear", "cottage", (2750.0, 420.0), 0.42, "northeast rear residential court"),
    ("v2_residence_west_lane", "cottage", (250.0, 1390.0), 0.42, "west residential side lane"),
    ("v2_residence_east_lane", "cottage", (2820.0, 1230.0), 0.42, "east residential side lane"),
    ("v2_residence_sw_lane", "cottage", (980.0, 1610.0), 0.42, "southwest inner lane"),
    ("v2_residence_se_lane", "cottage", (2150.0, 1510.0), 0.42, "southeast inner lane"),
    ("v2_frontage_nw_back", "street_row", (800.0, 620.0), 0.36, "northwest back-row frontage"),
    ("v2_frontage_ne_back", "street_row", (2270.0, 620.0), 0.36, "northeast back-row frontage"),
    ("v2_stall_west_side", "stall", (850.0, 1180.0), 0.16, "west side-street cloth and dry goods"),
    ("v2_stall_east_side", "stall", (2220.0, 1160.0), 0.16, "east side-street household goods"),
    ("v2_tree_west_court_0", "tree", (560.0, 1450.0), 1.0, "west courtyard shade"),
    ("v2_tree_west_court_1", "tree", (760.0, 1440.0), 1.0, "west courtyard shade"),
    ("v2_tree_east_court_0", "tree", (2390.0, 1260.0), 1.0, "east courtyard shade"),
    ("v2_tree_east_court_1", "tree", (2600.0, 1250.0), 1.0, "east courtyard shade"),
]


PROTECTED_PORTALS = [
    {"id": "to_yamen_square", "foot_px": [1536.0, 770.0]},
    {"id": "to_city_gate", "foot_px": [220.0, 1060.0]},
    {"id": "to_canal_docks", "foot_px": [2840.0, 1060.0]},
    {"id": "to_ancient_temple", "foot_px": [1536.0, 1860.0]},
]

PROTECTED_NPCS = [
    {"id": "spar_luoyang_shen_guard", "foot_px": [370.0, 1130.0]},
    {"id": "spar_luoyang_examiner", "foot_px": [1170.0, 820.0]},
    {"id": "spar_luoyang_blademaster", "foot_px": [1380.0, 1540.0]},
    {"id": "spar_luoyang_patrol", "foot_px": [1710.0, 1500.0]},
    {"id": "feng_yanqiu_ch4", "foot_px": [790.0, 1030.0]},
    {"id": "luoyang_paper_scholar", "foot_px": [520.0, 1340.0]},
    {"id": "luoyang_poetry_host", "foot_px": [1260.0, 1720.0]},
    {"id": "luoyang_armorer", "foot_px": [2440.0, 950.0]},
]

PROTECTED_INTERACTIONS = [
    {"id": "armory_old_record", "foot_px": [2320.0, 950.0]},
    {"id": "paper_birdseal", "foot_px": [1320.0, 1230.0]},
    {"id": "zhao_medicine_parcel", "foot_px": [1750.0, 1230.0]},
    {"id": "xuantong_note", "foot_px": [2440.0, 1100.0]},
]


def transform_rect(rect: list[float], origin: tuple[float, float], scale: float) -> list[float]:
    return [
        origin[0] + rect[0] * scale,
        origin[1] + rect[1] * scale,
        origin[0] + rect[2] * scale,
        origin[1] + rect[3] * scale,
    ]


def build_additions() -> list[dict[str, Any]]:
    additions: list[dict[str, Any]] = []
    for object_id, asset_id, foot, scale, role in PLACEMENT_SPECS:
        asset = ASSETS[asset_id]
        source_size = asset["source_size_px"]
        source_foot = asset["source_foot_px"]
        origin = (foot[0] - source_foot[0] * scale, foot[1] - source_foot[1] * scale)
        render_size = (source_size[0] * scale, source_size[1] * scale)
        collision = transform_rect(asset["source_collision_rect_px"], origin, scale)
        approach_source = asset["source_door_approach_px"]
        approach = None
        if approach_source is not None:
            approach = [
                origin[0] + approach_source[0] * scale,
                origin[1] + approach_source[1] * scale,
            ]
        record = {
            "id": object_id,
            "operation": "add",
            "role": role,
            "asset_id": asset_id,
            "source_path": asset["source"].relative_to(ROOT).as_posix(),
            "source_sha256": sha256(asset["source"]),
            "future_game_path": asset["future_game_path"],
            "world_foot_px": [foot[0], foot[1]],
            "depth_sort_foot_y": foot[1],
            "scale": scale,
            "render_origin_px": [round(origin[0], 6), round(origin[1], 6)],
            "render_size_px": [round(render_size[0], 6), round(render_size[1], 6)],
            "blocking": True,
            "collision_foot_range_px": [round(value, 6) for value in collision],
            "solid_polygons_px": [[
                [collision[0], collision[1]], [collision[2], collision[1]],
                [collision[2], collision[3]], [collision[0], collision[3]],
            ]],
            "front_approach_foot_px": None if approach is None else [round(value, 6) for value in approach],
            "interaction_identity": None,
            "interior_identity": None,
            "semantic_authority": asset["semantic_authority"],
        }
        if origin[0] < 0 or origin[1] < 0 or origin[0] + render_size[0] > DESIGN_SIZE[0] or origin[1] + render_size[1] > DESIGN_SIZE[1]:
            raise RuntimeError(f"render bounds outside canvas: {object_id}")
        additions.append(record)
    return additions


def rects_intersect(a: list[float], b: list[float], margin: float = 0.0) -> bool:
    return not (
        a[2] + margin <= b[0] or b[2] + margin <= a[0]
        or a[3] + margin <= b[1] or b[3] + margin <= a[1]
    )


def polygon_bbox(polygon: list[list[float]]) -> list[float]:
    xs = [point[0] for point in polygon]
    ys = [point[1] for point in polygon]
    return [min(xs), min(ys), max(xs), max(ys)]


def current_blocker_rects() -> list[tuple[str, list[float]]]:
    base = json.loads(BASE_CONTRACT.read_text(encoding="utf-8"))
    plan = json.loads(EXPORT_PLAN.read_text(encoding="utf-8"))
    removed = set(plan["remove_object_ids"])
    objects = [item for item in base["objects"] if item["id"] not in removed] + plan["objects"]
    rects: list[tuple[str, list[float]]] = []
    for item in objects:
        for polygon in item.get("solid_polygons_px", []):
            rects.append((item["id"], polygon_bbox(polygon)))
        size = item.get("collision_size_px", [0, 0])
        if not item.get("solid_polygons_px") and size[0] > 0 and size[1] > 0:
            center = item["physical_center_px"]
            rects.append((item["id"], [
                center[0] - size[0] / 2, center[1] - size[1] / 2,
                center[0] + size[0] / 2, center[1] + size[1] / 2,
            ]))
    return rects


def sample_segment(a: list[float], b: list[float], step: float = 4.0) -> list[tuple[float, float]]:
    distance = math.dist(a, b)
    count = max(1, math.ceil(distance / step))
    return [
        (a[0] + (b[0] - a[0]) * index / count, a[1] + (b[1] - a[1]) * index / count)
        for index in range(count + 1)
    ]


def audit(additions: list[dict[str, Any]]) -> dict[str, Any]:
    new_rects = [(item["id"], item["collision_foot_range_px"]) for item in additions]
    existing_rects = current_blocker_rects()
    failures: list[str] = []
    for index, (item_id, rect) in enumerate(new_rects):
        for other_id, other_rect in new_rects[index + 1:]:
            if rects_intersect(rect, other_rect):
                failures.append(f"new/new overlap: {item_id} / {other_id}")
        for other_id, other_rect in existing_rects:
            if rects_intersect(rect, other_rect):
                failures.append(f"new/existing overlap: {item_id} / {other_id}")

    routes = json.loads(BASE_CONTRACT.read_text(encoding="utf-8"))["routes"]
    route_sample_count = 0
    for route in routes:
        points = route["points_px"]
        for start, end in zip(points, points[1:]):
            for x, y in sample_segment(start, end):
                route_sample_count += 1
                shoe = [x - 17.0, y - 12.0, x + 17.0, y + 12.0]
                for item_id, rect in new_rects:
                    if rects_intersect(shoe, rect):
                        failures.append(f"route shoe overlap: {route['id']} / {item_id} at {x:.3f},{y:.3f}")
                        break

    protected = (
        [("portal:" + item["id"], item["foot_px"], (48.0, 24.0)) for item in PROTECTED_PORTALS]
        + [("npc:" + item["id"], item["foot_px"], (34.0, 24.0)) for item in PROTECTED_NPCS]
        + [("interaction:" + item["id"], item["foot_px"], (34.0, 24.0)) for item in PROTECTED_INTERACTIONS]
    )
    for protected_id, point, size in protected:
        protected_rect = [
            point[0] - size[0] / 2, point[1] - size[1] / 2,
            point[0] + size[0] / 2, point[1] + size[1] / 2,
        ]
        for item_id, rect in new_rects:
            if rects_intersect(protected_rect, rect):
                failures.append(f"protected foot overlap: {protected_id} / {item_id}")

    for item in additions:
        approach = item["front_approach_foot_px"]
        if approach is None:
            continue
        if not (0 <= approach[0] < DESIGN_SIZE[0] and 0 <= approach[1] < DESIGN_SIZE[1]):
            failures.append(f"approach out of bounds: {item['id']}")
        shoe = [approach[0] - 17.0, approach[1] - 12.0, approach[0] + 17.0, approach[1] + 12.0]
        for blocker_id, rect in existing_rects + new_rects:
            if blocker_id == item["id"]:
                continue
            if rects_intersect(shoe, rect):
                failures.append(f"approach shoe overlap: {item['id']} / {blocker_id}")

    if failures:
        raise RuntimeError("; ".join(failures[:20]))
    return {
        "method": "Every original route segment sampled at <=4px with a 34x24 player-foot box; all current blockers, portals, NPC feet and interaction feet retained as protected domains.",
        "route_count": len(routes),
        "route_sample_count": route_sample_count,
        "existing_blocker_rect_count": len(existing_rects),
        "new_blocker_rect_count": len(new_rects),
        "protected_portal_count": len(PROTECTED_PORTALS),
        "protected_npc_count": len(PROTECTED_NPCS),
        "protected_interaction_count": len(PROTECTED_INTERACTIONS),
        "failures": [],
        "credit_limit": "Offline rectangle/polygon transform audit only; not Godot Physics, navigation, depth/alpha, player control, or Field credit.",
    }


def resize_rgba(image: Image.Image, size: tuple[float, float]) -> Image.Image:
    integer_size = (max(1, round(size[0])), max(1, round(size[1])))
    return image.convert("RGBA").resize(integer_size, Image.Resampling.LANCZOS)


def render_candidate(additions: list[dict[str, Any]]) -> tuple[Image.Image, Image.Image]:
    base = Image.open(FLOOR).convert("RGBA")
    if base.size != DESIGN_SIZE:
        raise RuntimeError(f"unexpected floor size: {base.size}")
    current = parse_current_visual_objects()
    layers: list[dict[str, Any]] = []
    for item in current:
        layers.append({
            "id": item["id"], "source": item["texture"], "foot_y": item["depth_foot_y"],
            "origin": item["render_origin_px"], "size": item["render_size_px"], "new": False,
        })
    for item in additions:
        layers.append({
            "id": item["id"], "source": ROOT / item["source_path"], "foot_y": item["depth_sort_foot_y"],
            "origin": item["render_origin_px"], "size": item["render_size_px"], "new": True,
        })
    layers.sort(key=lambda item: (item["foot_y"], item["id"]))
    existing_only = base.copy()
    candidate = base.copy()
    for layer in layers:
        source = Image.open(layer["source"])
        sprite = resize_rgba(source, layer["size"])
        origin = (round(layer["origin"][0]), round(layer["origin"][1]))
        if not layer["new"]:
            existing_only.alpha_composite(sprite, origin)
        candidate.alpha_composite(sprite, origin)
    return existing_only, candidate


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    path = Path("C:/Windows/Fonts/msyhbd.ttc" if bold else "C:/Windows/Fonts/msyh.ttc")
    return ImageFont.truetype(str(path), size=size)


def render_audit_overlay(candidate: Image.Image, additions: list[dict[str, Any]]) -> Image.Image:
    overlay = Image.new("RGBA", DESIGN_SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay, "RGBA")
    routes = json.loads(BASE_CONTRACT.read_text(encoding="utf-8"))["routes"]
    for route in routes:
        draw.line([tuple(point) for point in route["points_px"]], fill=(35, 224, 196, 170), width=18)
    for item in additions:
        rect = item["collision_foot_range_px"]
        draw.rectangle(rect, fill=(255, 111, 73, 72), outline=(255, 153, 96, 245), width=4)
        approach = item["front_approach_foot_px"]
        if approach:
            draw.ellipse((approach[0] - 8, approach[1] - 8, approach[0] + 8, approach[1] + 8), fill=(255, 220, 72, 240))
    for item in PROTECTED_PORTALS:
        x, y = item["foot_px"]
        draw.rectangle((x - 24, y - 12, x + 24, y + 12), outline=(63, 255, 128, 255), width=5)
    for item in PROTECTED_NPCS:
        x, y = item["foot_px"]
        draw.ellipse((x - 10, y - 10, x + 10, y + 10), fill=(196, 117, 255, 240), outline=(255, 255, 255, 255), width=2)
    draw.rounded_rectangle((32, 24, 1140, 122), radius=16, fill=(8, 15, 22, 230), outline=(62, 213, 230, 255), width=4)
    draw.text((58, 42), "南市真实模块 candidate · 实施/碰撞离线图", font=font(34, True), fill=(245, 250, 252, 255))
    draw.text((60, 82), "青=原路线  橙=新增阻挡脚域  黄=门前足点  绿=门户  紫=原NPC", font=font(22), fill=(196, 224, 231, 255))
    return Image.alpha_composite(candidate.convert("RGBA"), overlay)


def render_comparison(before: Image.Image, candidate: Image.Image) -> Image.Image:
    thumb_size = (960, 640)
    canvas = Image.new("RGB", (1944, 706), (42, 47, 52))
    canvas.paste(before.convert("RGB").resize(thumb_size, Image.Resampling.LANCZOS), (0, 66))
    canvas.paste(candidate.convert("RGB").resize(thumb_size, Image.Resampling.LANCZOS), (984, 66))
    draw = ImageDraw.Draw(canvas)
    draw.text((28, 16), "BEFORE · 当前正式视觉", font=font(30, True), fill=(240, 245, 248))
    draw.text((1012, 16), "AFTER · 离线真实模块 candidate", font=font(30, True), fill=(240, 245, 248))
    return canvas


def main() -> None:
    if OUT.exists():
        raise RuntimeError(f"refuse to overwrite existing output: {OUT}")
    required = [LAYOUT, SCENE, BASE_CONTRACT, EXPORT_PLAN, FLOOR, BEFORE, MODULE_SEMANTICS, STREET_ROW, STALL, TREE, COTTAGE, COTTAGE_RAW, COTTAGE_META]
    for path in required:
        if not path.is_file():
            raise FileNotFoundError(path)
    for path, expected in EXPECTED_PINS.items():
        if sha256(path) != expected:
            raise RuntimeError(f"source pin changed: {path}")
    before_guard = {path.relative_to(ROOT).as_posix(): sha256(path) for path in required}

    additions = build_additions()
    audit_result = audit(additions)
    existing_reconstruction, candidate = render_candidate(additions)
    official_before = Image.open(BEFORE).convert("RGBA")
    overlay = render_audit_overlay(candidate, additions)
    comparison = render_comparison(official_before, candidate)

    OUT.mkdir(parents=True)
    existing_path = OUT / "luoyang_market_existing_module_reconstruction_v2.png"
    candidate_path = OUT / "luoyang_market_enrichment_candidate_v2.png"
    overlay_path = OUT / "luoyang_market_enrichment_implementation_map_v2.png"
    comparison_path = OUT / "luoyang_market_enrichment_before_after_v2.png"
    existing_reconstruction.save(existing_path, optimize=True)
    candidate.save(candidate_path, optimize=True)
    overlay.save(overlay_path, optimize=True)
    comparison.save(comparison_path, optimize=True)

    after_guard = {path.relative_to(ROOT).as_posix(): sha256(path) for path in required}
    if before_guard != after_guard:
        raise RuntimeError("a protected source changed during offline composition")

    manifest = {
        "schema_version": 2,
        "status": "OFFLINE_REAL_MODULE_PLACEMENT_CANDIDATE_NOT_FIELD_OR_PRODUCTION_APPROVAL",
        "scene_id": "ch4_s3_luoyang_market",
        "design_size_px": list(DESIGN_SIZE),
        "engine_executed": False,
        "api_used": False,
        "formal_tres_modified": False,
        "walk_navigation_portal_npc_interaction_modified": False,
        "source_guard_before_after_equal": True,
        "source_pins": [pin(path) for path in required],
        "asset_catalog": {
            asset_id: {
                "source": pin(asset["source"]),
                "source_size_px": asset["source_size_px"],
                "source_foot_px": asset["source_foot_px"],
                "source_collision_rect_px": asset["source_collision_rect_px"],
                "source_door_approach_px": asset["source_door_approach_px"],
                "semantic_authority": asset["semantic_authority"],
                "future_game_path": asset["future_game_path"],
            }
            for asset_id, asset in ASSETS.items()
        },
        "cottage_provenance_pins": [pin(COTTAGE_RAW), pin(COTTAGE_META)],
        "changes": {
            "add": additions,
            "move": [],
            "delete": [],
            "counts_are_candidate_records_not_acceptance": {
                "buildings": 8,
                "stalls": 2,
                "trees": 4,
                "total": len(additions),
            },
        },
        "protected_routes": json.loads(BASE_CONTRACT.read_text(encoding="utf-8"))["routes"],
        "protected_portals": PROTECTED_PORTALS,
        "protected_npcs": PROTECTED_NPCS,
        "protected_interactions": PROTECTED_INTERACTIONS,
        "collision_audit": audit_result,
        "render_recipe": {
            "method": "Pillow alpha composition of current formal floor plus every current formal visual-object texture and the new unchanged source PNGs, all sorted by authored depth foot.",
            "current_visual_object_count": len(parse_current_visual_objects()),
            "new_visual_object_count": len(additions),
            "resample": "LANCZOS for the offline preview only; SYSTEM must use native game sprite transforms and exact recorded scale/foot.",
            "official_before_is_not_overwritten": BEFORE.relative_to(ROOT).as_posix(),
        },
        "outputs": [pin(existing_path), pin(candidate_path), pin(overlay_path), pin(comparison_path)],
        "system_integration_notes": [
            "Append only the listed add records; move/delete arrays are deliberately empty.",
            "Copy the existing processed cottage into its future_game_path before any formal reference; preserve its PNG bytes and raw/meta pins.",
            "Do not create interior/portal/interaction identities for the candidate door approaches.",
            "Retain every listed route, portal, NPC and interaction identity/foot; run actual Field Physics, Y-sort/alpha and doorway approach checks after integration.",
            "This first sample intentionally stops at eight buildings, two stalls and four trees; density must be visually reviewed before expansion.",
        ],
        "known_limits": [
            "Offline composition is not a Godot renderer or imported-texture proof.",
            "Cottage foot/collision is an explicit candidate author contract, not inherited Field credit.",
            "Repeated cottage/frontage sources need in-engine repetition and lighting review.",
            "No ambient NPCs, interior identities, new quests, collision data, walk mask or formal scene changes are included.",
            "Gate, yamen and docks enrichment remain separate pending work and are not implied complete by this market sample.",
        ],
    }
    placements_path = OUT / "luoyang_market_enrichment_placements_v2.json"
    placements_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "placements": pin(placements_path),
        "candidate": pin(candidate_path),
        "implementation_map": pin(overlay_path),
        "comparison": pin(comparison_path),
        "collision_audit": audit_result,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
