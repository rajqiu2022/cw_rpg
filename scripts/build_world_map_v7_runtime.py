"""Build the v7 world-map art, exact walk mask and Godot layout.

Unlike v6, the visible road and navigation mask are rendered from the same
route graph. No colour guessing, low-resolution pathfinding or 16px raster
rectangles are involved. Sea travel remains portal-based ferry travel; water
is never added to the walking mask.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

from build_world_map_v6_navigation import PORTALS as V6_PORTALS, ROUTES


ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "assets" / "raw" / "scene_background" / "world_map_v7_refresh_20260903"
PROCESSED = ROOT / "assets" / "processed" / "scene" / "world_map_v7"
TERRAIN = RAW / "bg_world_map_v7_terrain_plate.png"
PAINTED = RAW / "bg_world_map_v7_refresh_master.png"
MASTER = RAW / "bg_world_map_v7_gameplay.png"
VISIBLE_MASK = PROCESSED / "world_map_v7_visible_road_mask.png"
NAV_MASK_MASTER = PROCESSED / "world_map_v7_navigation_mask_1536.png"
NAV_MASK_RUNTIME = ROOT / "game" / "art" / "navigation_masks" / "world_map_jianghu_walk_v7.png"
OVERLAY = PROCESSED / "world_map_v7_navigation_overlay.png"
LAYOUT = ROOT / "game" / "data" / "maps" / "world_map_jianghu_layout_v7.tres"
SIZE = (1536, 1024)
RUNTIME_SIZE = (3072, 2048)
VISIBLE_HALF_WIDTH = 13
NAV_HALF_WIDTH = 8

# The painted plate contains this short bridge spur west of the lower central
# junction. It was omitted from the older route graph, which made the visible
# bridge in the user's red box inexplicably impassable.
ROUTES["southwest_bridge_spur"] = [
    (0.283, 0.720),
    (0.325, 0.718),
    (0.374, 0.723),
]


PORTALS: list[dict] = []
for original in V6_PORTALS:
    entry = dict(original)
    if entry["id"] == "gufeng":
        entry.pop("target_scene", None)
        entry["action"] = "scene:ch5_s1_relief_road"
        entry["require_flag"] = "chapter2_complete"
        entry["locked_label"] = "古月峰 · 山路险阻"
    elif entry["id"] == "bailu_ferry":
        entry["travel_mode"] = "ferry"
        entry["locked_label"] = "白鹿渡 · 航线整备中"
    elif entry["id"] == "east_sea_port":
        entry["travel_mode"] = "ferry"
        entry["locked_label"] = "东海埠 · 海船停航"
    elif entry["id"] == "mingwu":
        entry.pop("action", None)
        entry["label"] = "茗雾茶镇"
        entry["target_scene"] = "ch7_s2_mingwu_tea_town"
        entry["target_pos"] = (0.500, 0.875)
        entry["require_flag"] = "ch7_dual_route_chosen"
        entry["locked_label"] = "茗雾茶镇 · 外院暂不接客"
    PORTALS.append(entry)

# Chapter seven introduces a second destination on the existing Qinghe-Mingwu
# road. It is an authored portal rather than a new road branch, so rebuilding
# v7 must preserve the same visible-road/navigation contract.
PORTALS.insert(
    next(index for index, entry in enumerate(PORTALS) if entry["id"] == "mingwu"),
    {
        "id": "lieyun_valley",
        "label": "烈云峡谷",
        "pos": (0.675, 0.795),
        "target_scene": "ch7_s1_lieyun_valley_ferry",
        "target_pos": (0.500, 0.875),
        "require_flag": "ch7_dual_route_chosen",
        "locked_label": "烈云峡谷 · 尚无可靠引路信物",
    },
)


def px(point: tuple[float, float]) -> tuple[int, int]:
    return round(point[0] * (SIZE[0] - 1)), round(point[1] * (SIZE[1] - 1))


def portal_approaches() -> list[tuple[tuple[float, float], tuple[float, float]]]:
    waypoints = [point for route in ROUTES.values() for point in route]
    result: list[tuple[tuple[float, float], tuple[float, float]]] = []
    for entry in PORTALS:
        target = entry["pos"]
        nearest = min(waypoints, key=lambda point: (point[0] - target[0]) ** 2 + (point[1] - target[1]) ** 2)
        if math.dist(nearest, target) > 0.002:
            result.append((nearest, target))
    return result


def route_mask(half_width: int) -> Image.Image:
    mask = Image.new("L", SIZE, 0)
    draw = ImageDraw.Draw(mask)
    width = half_width * 2
    for route in ROUTES.values():
        points = [px(point) for point in route]
        draw.line(points, fill=255, width=width, joint="curve")
        for x, y in points:
            draw.ellipse((x - half_width, y - half_width, x + half_width, y + half_width), fill=255)
    for start, end in portal_approaches():
        draw.line([px(start), px(end)], fill=255, width=width)
    for entry in PORTALS:
        x, y = px(entry["pos"])
        draw.ellipse((x - half_width - 3, y - half_width - 3, x + half_width + 3, y + half_width + 3), fill=255)
    return mask


def road_texture(seed: int = 725) -> Image.Image:
    rng = np.random.default_rng(seed)
    height, width = SIZE[1], SIZE[0]
    fine = rng.normal(0.0, 1.0, (height, width)).astype(np.float32)
    coarse = cv2.resize(rng.normal(0.0, 1.0, (height // 24 + 1, width // 24 + 1)).astype(np.float32), SIZE, interpolation=cv2.INTER_CUBIC)
    grain = fine * 4.5 + coarse * 12.0
    base = np.zeros((height, width, 4), dtype=np.uint8)
    base[..., 0] = np.clip(174 + grain, 126, 208)
    base[..., 1] = np.clip(137 + grain * 0.78, 101, 176)
    base[..., 2] = np.clip(80 + grain * 0.52, 54, 116)
    base[..., 3] = 255
    return Image.fromarray(base, "RGBA")


def compose_master() -> tuple[Image.Image, Image.Image, Image.Image]:
    terrain = Image.open(TERRAIN).convert("RGB")
    if terrain.size != SIZE:
        raise RuntimeError(f"Terrain plate must be {SIZE}, got {terrain.size}")
    visible = route_mask(VISIBLE_HALF_WIDTH)
    navigation = route_mask(NAV_HALF_WIDTH)

    edge = visible.filter(ImageFilter.GaussianBlur(2.2))
    shoulder = Image.new("RGBA", SIZE, (61, 47, 29, 0))
    shoulder.putalpha(edge.point(lambda value: round(value * 0.56)))
    result = Image.alpha_composite(terrain.convert("RGBA"), shoulder)

    texture = road_texture()
    inner = visible.filter(ImageFilter.GaussianBlur(0.75))
    texture.putalpha(inner)
    result = Image.alpha_composite(result, texture)

    # Sparse stones and wheel-worn flecks make the exact vector road read as a
    # painted environment asset rather than a flat debug line.
    detail = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    draw = ImageDraw.Draw(detail, "RGBA")
    rng = np.random.default_rng(726)
    mask_array = np.array(navigation)
    ys, xs = np.where(mask_array > 0)
    if len(xs):
        for index in rng.choice(len(xs), size=min(1450, len(xs)), replace=False):
            x, y = int(xs[index]), int(ys[index])
            radius = int(rng.integers(1, 3))
            color = (226, 194, 133, int(rng.integers(28, 78))) if index % 3 else (82, 61, 37, int(rng.integers(22, 58)))
            draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=color)
    result = Image.alpha_composite(result, detail)
    return result.convert("RGB"), visible, navigation


def segment_polygon(a: tuple[float, float], b: tuple[float, float], half_width_px: float = NAV_HALF_WIDTH) -> list[tuple[float, float]]:
    ax, ay = px(a)
    bx, by = px(b)
    dx, dy = bx - ax, by - ay
    length = max(1e-6, math.hypot(dx, dy))
    ux, uy = dx / length, dy / length
    nx, ny = -uy * half_width_px, ux * half_width_px
    extension = half_width_px * 0.88
    ax -= ux * extension
    ay -= uy * extension
    bx += ux * extension
    by += uy * extension
    return [
        ((ax + nx) / SIZE[0], (ay + ny) / SIZE[1]),
        ((bx + nx) / SIZE[0], (by + ny) / SIZE[1]),
        ((bx - nx) / SIZE[0], (by - ny) / SIZE[1]),
        ((ax - nx) / SIZE[0], (ay - ny) / SIZE[1]),
    ]


def fmt_vec(point: tuple[float, float]) -> str:
    return f"Vector2({point[0]:.5f}, {point[1]:.5f})"


def portal_tres(entry: dict) -> str:
    fields = [f'"id":"{entry["id"]}"', f'"label":"{entry["label"]}"', f'"pos":{fmt_vec(entry["pos"])}', '"size":Vector2(0.042, 0.050)']
    for key in ["target_scene", "action", "require_flag", "locked_label", "travel_mode"]:
        if key in entry:
            fields.append(f'"{key}":"{entry[key]}"')
    if "target_pos" in entry:
        fields.append(f'"target_pos":{fmt_vec(entry["target_pos"])}')
    return "\t{" + ", ".join(fields) + "}"


def build_layout() -> None:
    polygons: list[list[tuple[float, float]]] = []
    for route in ROUTES.values():
        polygons.extend(segment_polygon(a, b) for a, b in zip(route, route[1:]))
    polygons.extend(segment_polygon(a, b) for a, b in portal_approaches())
    region_lines = ["\tPackedVector2Array(" + ", ".join(f"{x:.5f}, {y:.5f}" for x, y in polygon) + ")" for polygon in polygons]
    portal_lines = [portal_tres(entry) for entry in PORTALS]
    probes = [f'\t{{"id":"{entry["id"]}_gate", "pos":{fmt_vec(entry["pos"])}}}' for entry in PORTALS]
    blocked = [
        '\t{"id":"snow_peak", "pos":Vector2(0.050, 0.120)}',
        '\t{"id":"north_bamboo", "pos":Vector2(0.410, 0.120)}',
        '\t{"id":"central_river", "pos":Vector2(0.440, 0.480)}',
        '\t{"id":"luoyang_inner_court", "pos":Vector2(0.704, 0.500)}',
        '\t{"id":"luoyang_inner_east", "pos":Vector2(0.742, 0.535)}',
        '\t{"id":"east_sea", "pos":Vector2(0.965, 0.600)}',
        '\t{"id":"south_forest", "pos":Vector2(0.500, 0.930)}',
    ]
    content = f'''[gd_resource type="Resource" script_class="WalkableMapLayout" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/domain/walkable_map_layout.gd" id="1_layout"]

[resource]
script = ExtResource("1_layout")
schema_version = 7
design_size = Vector2i(3072, 2048)
display_at_native_size = true
walkable_mask_path = "res://art/navigation_masks/world_map_jianghu_walk_v7.png"
walkable_regions = Array[PackedVector2Array]([
{',\n'.join(region_lines)}
])
visual_objects = []
occluders = []
actor_fade_zones = []
blockers = []
interactions = []
portals = [
{',\n'.join(portal_lines)}
]
walkable_probes = [
{',\n'.join(probes)}
]
blocked_probes = [
{',\n'.join(blocked)}
]
'''
    LAYOUT.write_text(content, encoding="utf-8", newline="\n")


def build_overlay(master: Image.Image, navigation: Image.Image) -> None:
    tint = Image.new("RGBA", SIZE, (30, 235, 120, 0))
    tint.putalpha(navigation.point(lambda value: round(value * 0.55)))
    overlay = Image.alpha_composite(master.convert("RGBA"), tint)
    draw = ImageDraw.Draw(overlay, "RGBA")
    for entry in PORTALS:
        x, y = px(entry["pos"])
        draw.ellipse((x - 12, y - 12, x + 12, y + 12), fill=(255, 104, 60, 235), outline=(255, 255, 255, 255), width=3)
    overlay.convert("RGB").save(OVERLAY, optimize=True)


def main() -> None:
    PROCESSED.mkdir(parents=True, exist_ok=True)
    NAV_MASK_RUNTIME.parent.mkdir(parents=True, exist_ok=True)
    visible = route_mask(VISIBLE_HALF_WIDTH)
    navigation = route_mask(NAV_HALF_WIDTH)
    if PAINTED.exists():
        master = Image.open(PAINTED).convert("RGB")
        if master.size != SIZE:
            raise RuntimeError(f"Painted master must be {SIZE}, got {master.size}")
    else:
        master, visible, navigation = compose_master()
    master.save(MASTER, optimize=True)
    visible.save(VISIBLE_MASK, optimize=True)
    navigation.save(NAV_MASK_MASTER, optimize=True)
    navigation.resize(RUNTIME_SIZE, Image.Resampling.NEAREST).save(NAV_MASK_RUNTIME, optimize=True)
    build_overlay(master, navigation)
    build_layout()
    metadata = {
        "design_size": RUNTIME_SIZE,
        "source_size": SIZE,
        "visible_half_width_px": VISIBLE_HALF_WIDTH,
        "navigation_half_width_px": NAV_HALF_WIDTH,
        "route_ids": list(ROUTES),
        "art_refresh": "2026-09-03 realistic 2.5D repaint; Luoyang roads terminate at exterior gates",
        "portals": PORTALS,
        "ferry_contract": {
            "walking_on_water": False,
            "embarkation_portals": ["bailu_ferry", "east_sea_port"],
            "future_destinations": ["海崖古港", "东海离岛", "沿海水寨"],
        },
    }
    (PROCESSED / "world_map_v7_topology.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    print(MASTER)
    print(NAV_MASK_RUNTIME)
    print(LAYOUT)


if __name__ == "__main__":
    main()
