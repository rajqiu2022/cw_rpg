"""Build the v6 world-map navigation contract from one authored route graph.

The route polylines are traced against the final 3072x2048 painted map.  The
same graph generates the Godot walkable polygons, review overlay, binary mask,
portal gate anchors and M-map metadata.  This prevents visual roads, collision
and map markers from drifting apart again.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont
from skimage.graph import route_through_array


ROOT = Path(__file__).resolve().parents[1]
BACKGROUND = ROOT / "game" / "art" / "backgrounds" / "bg_world_map_jianghu_v5_realesrgan_hd.png"
OUT_DIR = ROOT / "assets" / "processed" / "scene" / "world_map_v6"
LAYOUT = ROOT / "game" / "data" / "maps" / "world_map_jianghu_layout_v6.tres"
SIZE = (3072, 2048)
HALF_WIDTH = 28.0
ROAD_REFERENCE_BGR = np.uint8([[[147, 176, 192]]])
MASK_GRID = 16
TRACE_SIZE = (768, 512)


# Normalized centre lines traced over the painted beige roads.
ROUTES: dict[str, list[tuple[float, float]]] = {
    "linxi_zhuwei": [(0.104, 0.792), (0.112, 0.826), (0.135, 0.850), (0.168, 0.860), (0.207, 0.838)],
    "zhuwei_south_cross": [(0.207, 0.838), (0.244, 0.864), (0.286, 0.864), (0.322, 0.835), (0.350, 0.790)],
    "south_cross_luoyang": [(0.350, 0.790), (0.395, 0.778), (0.438, 0.792), (0.480, 0.842), (0.527, 0.850), (0.571, 0.807), (0.612, 0.748), (0.645, 0.685), (0.674, 0.616)],
    "south_spine": [(0.350, 0.790), (0.374, 0.723), (0.399, 0.654), (0.419, 0.585), (0.405, 0.525), (0.407, 0.455), (0.410, 0.393), (0.392, 0.334), (0.421, 0.269)],
    "lingyue_bridge": [(0.213, 0.226), (0.230, 0.250), (0.262, 0.272), (0.300, 0.286), (0.348, 0.306), (0.386, 0.311), (0.421, 0.269)],
    "huashan_stairs": [(0.118, 0.402), (0.111, 0.374), (0.103, 0.346), (0.101, 0.318)],
    "huashan_bridge": [(0.118, 0.402), (0.148, 0.362), (0.190, 0.331), (0.240, 0.309), (0.300, 0.286)],
    "bridge_central": [(0.421, 0.269), (0.458, 0.235), (0.496, 0.226), (0.535, 0.241), (0.570, 0.278), (0.600, 0.302)],
    "central_wudang": [(0.600, 0.302), (0.608, 0.266), (0.610, 0.218)],
    "central_luoyang_west": [(0.421, 0.269), (0.458, 0.296), (0.500, 0.311), (0.548, 0.311), (0.580, 0.347), (0.590, 0.410), (0.595, 0.485)],
    "wudang_yanmen": [(0.600, 0.302), (0.650, 0.316), (0.704, 0.318), (0.750, 0.300), (0.774, 0.250), (0.778, 0.180)],
    "luoyang_ring_west": [(0.595, 0.485), (0.592, 0.540), (0.615, 0.585), (0.674, 0.616)],
    "luoyang_ring_north": [(0.595, 0.485), (0.600, 0.406), (0.620, 0.346), (0.660, 0.326), (0.704, 0.318), (0.748, 0.327), (0.775, 0.374)],
    "luoyang_ring_east": [(0.775, 0.374), (0.785, 0.430), (0.786, 0.492), (0.775, 0.548), (0.743, 0.590), (0.704, 0.606), (0.674, 0.616)],
    "luoyang_east_port": [(0.775, 0.374), (0.806, 0.342), (0.842, 0.334), (0.878, 0.350)],
    "luoyang_qinghe": [(0.674, 0.616), (0.662, 0.665), (0.635, 0.715), (0.602, 0.765)],
    "qinghe_mingwu": [(0.602, 0.765), (0.650, 0.788), (0.704, 0.795), (0.758, 0.790), (0.775, 0.790)],
    "south_cross_qinghe": [(0.438, 0.792), (0.490, 0.774), (0.545, 0.775), (0.602, 0.765)],
    "qinghe_coast": [(0.602, 0.765), (0.635, 0.815), (0.675, 0.851), (0.730, 0.855), (0.780, 0.835), (0.820, 0.855)],
}


# Gate anchors sit outside the painted settlement/temple, on the route itself.
PORTALS = [
    {"id": "linxi_village", "label": "林西村", "pos": (0.105, 0.775), "target_scene": "linxi_village_scrollmap", "target_pos": (0.925, 0.500)},
    {"id": "zhuwei_village", "label": "竹尾村", "pos": (0.225, 0.850), "target_scene": "ch1_s2_qingfeng", "target_pos": (0.520, 0.790)},
    {"id": "lingyue", "label": "凌月山", "pos": (0.230, 0.250), "target_scene": "ch2_s4_lingyue_gate", "target_pos": (0.110, 0.780)},
    {"id": "huashan", "label": "华山", "pos": (0.145, 0.405), "action": "dialog:world_map_huashan_locked", "require_flag": "chapter2_complete", "locked_label": "华山 · 山道未通"},
    {"id": "wudang", "label": "武当山", "pos": (0.610, 0.250), "target_scene": "ch3_s1_wulin_assembly", "target_pos": (0.110, 0.780)},
    {"id": "gufeng", "label": "古月峰", "pos": (0.548, 0.311), "action": "dialog:world_map_gufeng_locked", "require_flag": "chapter2_complete", "locked_label": "古月峰 · 山路险阻"},
    {"id": "luoyang", "label": "洛阳", "pos": (0.704, 0.606), "target_scene": "ch4_s1_luoyang_yamen", "target_pos": (0.110, 0.780)},
    {"id": "mingwu", "label": "茗雾山", "pos": (0.775, 0.790), "action": "dialog:world_map_mingwu_locked", "require_flag": "chapter5_complete", "locked_label": "茗雾山 · 雾障封路"},
    {"id": "bailu_ferry", "label": "白鹿渡", "pos": (0.421, 0.269), "require_flag": "region_bailu_ferry_open", "locked_label": "白鹿渡 · 秋汛封航"},
    {"id": "qinghe_town", "label": "清河镇", "pos": (0.602, 0.765), "require_flag": "region_qinghe_town_open", "locked_label": "清河镇 · 官道正在修整"},
    {"id": "yanmen_pass", "label": "雁门关", "pos": (0.778, 0.180), "require_flag": "region_yanmen_pass_open", "locked_label": "雁门关 · 边关戒严"},
    {"id": "east_sea_port", "label": "东海埠", "pos": (0.852, 0.338), "require_flag": "region_east_sea_port_open", "locked_label": "东海埠 · 风浪封港"},
]


def px(point: tuple[float, float]) -> tuple[float, float]:
    return point[0] * SIZE[0], point[1] * SIZE[1]


def norm(point: tuple[float, float]) -> tuple[float, float]:
    return point[0] / SIZE[0], point[1] / SIZE[1]


def segment_polygon(a_n: tuple[float, float], b_n: tuple[float, float], half_width: float = HALF_WIDTH) -> list[tuple[float, float]]:
    ax, ay = px(a_n)
    bx, by = px(b_n)
    dx, dy = bx - ax, by - ay
    length = max(1e-6, math.hypot(dx, dy))
    ux, uy = dx / length, dy / length
    nx, ny = -uy * half_width, ux * half_width
    extension = half_width * 0.92
    ax -= ux * extension
    ay -= uy * extension
    bx += ux * extension
    by += uy * extension
    return [norm((ax + nx, ay + ny)), norm((bx + nx, by + ny)), norm((bx - nx, by - ny)), norm((ax - nx, ay - ny))]


def build_exact_walkable_mask() -> np.ndarray:
    image = cv2.imread(str(BACKGROUND), cv2.IMREAD_COLOR)
    lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB).astype(np.float32)
    road_lab = cv2.cvtColor(ROAD_REFERENCE_BGR, cv2.COLOR_BGR2LAB)[0, 0].astype(np.float32)
    colour_distance = np.linalg.norm(lab - road_lab, axis=2)
    road_pixels = (colour_distance < 27.0).astype(np.uint8) * 255
    corridor = np.zeros((SIZE[1], SIZE[0]), dtype=np.uint8)
    for guide in ROUTES.values():
        points = np.array([(round(x * (SIZE[0] - 1)), round(y * (SIZE[1] - 1))) for x, y in guide], dtype=np.int32)
        cv2.polylines(corridor, [points], False, 255, 220, cv2.LINE_AA)
    mask = cv2.bitwise_and(road_pixels, corridor)
    mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, np.ones((9, 9), np.uint8))
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, np.ones((17, 17), np.uint8))
    mask = cv2.dilate(mask, np.ones((9, 9), np.uint8))
    component_count, labels, stats, _ = cv2.connectedComponentsWithStats((mask > 0).astype(np.uint8), 8)
    cleaned = np.zeros_like(mask)
    for component in range(1, component_count):
        if int(stats[component, cv2.CC_STAT_AREA]) >= 1000:
            cleaned[labels == component] = 255
    small_image = cv2.resize(image, TRACE_SIZE, interpolation=cv2.INTER_AREA)
    small_lab = cv2.cvtColor(small_image, cv2.COLOR_BGR2LAB).astype(np.float32)
    small_distance = np.linalg.norm(small_lab - road_lab, axis=2)
    base_cost = 1.0 + np.power(np.clip(small_distance / 17.0, 0.0, 5.0), 3.0)
    for guide in ROUTES.values():
        for start_n, end_n in zip(guide, guide[1:]):
            start_xy = np.array([round(start_n[0] * (TRACE_SIZE[0] - 1)), round(start_n[1] * (TRACE_SIZE[1] - 1))], dtype=np.int32)
            end_xy = np.array([round(end_n[0] * (TRACE_SIZE[0] - 1)), round(end_n[1] * (TRACE_SIZE[1] - 1))], dtype=np.int32)
            corridor_small = np.zeros((TRACE_SIZE[1], TRACE_SIZE[0]), dtype=np.uint8)
            cv2.line(corridor_small, tuple(start_xy), tuple(end_xy), 255, 46, cv2.LINE_AA)
            cost = base_cost.copy()
            cost[corridor_small == 0] = 1_000_000.0
            indices, _ = route_through_array(
                cost,
                (int(start_xy[1]), int(start_xy[0])),
                (int(end_xy[1]), int(end_xy[0])),
                fully_connected=True,
                geometric=True,
            )
            points = np.array(
                [(round(col * SIZE[0] / TRACE_SIZE[0]), round(row * SIZE[1] / TRACE_SIZE[1])) for row, col in indices],
                dtype=np.int32,
            )
            cv2.polylines(cleaned, [points], False, 255, 30, cv2.LINE_AA)
    exclusions = [
        (0.125, 0.025, 0.225, 0.235),
        (0.045, 0.215, 0.140, 0.440),
        (0.535, 0.035, 0.665, 0.235),
        (0.720, 0.035, 0.820, 0.165),
        (0.585, 0.340, 0.785, 0.585),
        (0.860, 0.220, 0.960, 0.400),
        (0.785, 0.700, 0.900, 0.850),
    ]
    for left, top, right, bottom in exclusions:
        cv2.rectangle(cleaned, (round(left * SIZE[0]), round(top * SIZE[1])), (round(right * SIZE[0]), round(bottom * SIZE[1])), 0, -1)
    authored_stairs = {
        "lingyue_approach": [(0.213, 0.226), (0.230, 0.250)],
        "huashan_approach": [(0.118, 0.402), (0.145, 0.405)],
        "wudang_approach": [(0.600, 0.302), (0.608, 0.270), (0.610, 0.250)],
    }
    for guide in authored_stairs.values():
        points = np.array([(round(x * (SIZE[0] - 1)), round(y * (SIZE[1] - 1))) for x, y in guide], dtype=np.int32)
        cv2.polylines(cleaned, [points], False, 255, 40, cv2.LINE_AA)
    for entry in PORTALS:
        x, y = px(entry["pos"])
        cv2.circle(cleaned, (round(x), round(y)), 34, 255, -1, cv2.LINE_AA)
    return cleaned


def mask_to_rectangles(mask: np.ndarray) -> list[list[tuple[float, float]]]:
    rows = math.ceil(SIZE[1] / MASK_GRID)
    cols = math.ceil(SIZE[0] / MASK_GRID)
    occupied = np.zeros((rows, cols), dtype=np.uint8)
    for row in range(rows):
        y0, y1 = row * MASK_GRID, min(SIZE[1], (row + 1) * MASK_GRID)
        for col in range(cols):
            x0, x1 = col * MASK_GRID, min(SIZE[0], (col + 1) * MASK_GRID)
            if np.count_nonzero(mask[y0:y1, x0:x1]) >= max(1, int((y1 - y0) * (x1 - x0) * 0.22)):
                occupied[row, col] = 1
    active: dict[tuple[int, int], list[int]] = {}
    merged: list[tuple[int, int, int, int]] = []
    for row in range(rows):
        runs: list[tuple[int, int]] = []
        col = 0
        while col < cols:
            if occupied[row, col] == 0:
                col += 1
                continue
            start = col
            while col < cols and occupied[row, col] != 0:
                col += 1
            runs.append((start, col))
        next_active: dict[tuple[int, int], list[int]] = {}
        for run in runs:
            if run in active:
                rect = active[run]
                rect[3] = row + 1
                next_active[run] = rect
            else:
                next_active[run] = [run[0], row, run[1], row + 1]
        for run, rect in active.items():
            if run not in next_active:
                merged.append(tuple(rect))
        active = next_active
    merged.extend(tuple(rect) for rect in active.values())
    polygons: list[list[tuple[float, float]]] = []
    for x0, y0, x1, y1 in merged:
        left, top = x0 * MASK_GRID / SIZE[0], y0 * MASK_GRID / SIZE[1]
        right, bottom = min(SIZE[0], x1 * MASK_GRID) / SIZE[0], min(SIZE[1], y1 * MASK_GRID) / SIZE[1]
        polygons.append([(left, top), (right, top), (right, bottom), (left, bottom)])
    return polygons


def fmt_vec(point: tuple[float, float]) -> str:
    return f"Vector2({point[0]:.5f}, {point[1]:.5f})"


def portal_tres(entry: dict) -> str:
    fields = [
        f'"id":"{entry["id"]}"',
        f'"label":"{entry["label"]}"',
        f'"pos":{fmt_vec(entry["pos"])}',
        '"size":Vector2(0.042, 0.050)',
    ]
    for key in ["target_scene", "action", "require_flag", "locked_label"]:
        if key in entry:
            fields.append(f'"{key}":"{entry[key]}"')
    if "target_pos" in entry:
        fields.append(f'"target_pos":{fmt_vec(entry["target_pos"])}')
    return "\t{" + ", ".join(fields) + "}"


def build_tres(polygons: list[list[tuple[float, float]]]) -> str:
    region_lines = []
    for polygon in polygons:
        region_lines.append("\tPackedVector2Array(" + ", ".join(f"{x:.5f}, {y:.5f}" for x, y in polygon) + ")")
    portal_lines = [portal_tres(entry) for entry in PORTALS]
    probes = [f'\t{{"id":"{entry["id"]}_gate", "pos":{fmt_vec(entry["pos"])}}}' for entry in PORTALS]
    blocked = [
        '\t{"id":"snow_peak", "pos":Vector2(0.050, 0.120)}',
        '\t{"id":"north_bamboo", "pos":Vector2(0.410, 0.120)}',
        '\t{"id":"central_river", "pos":Vector2(0.440, 0.480)}',
        '\t{"id":"east_sea", "pos":Vector2(0.965, 0.600)}',
        '\t{"id":"south_forest", "pos":Vector2(0.500, 0.930)}',
    ]
    return f'''[gd_resource type="Resource" script_class="WalkableMapLayout" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/domain/walkable_map_layout.gd" id="1_layout"]

[resource]
script = ExtResource("1_layout")
schema_version = 6
design_size = Vector2i(3072, 2048)
display_at_native_size = false
walkable_regions = Array[PackedVector2Array]([\n{',\n'.join(region_lines)}\n])
visual_objects = []
occluders = []
actor_fade_zones = []
blockers = []
interactions = []
portals = [\n{',\n'.join(portal_lines)}\n]
walkable_probes = [\n{',\n'.join(probes)}\n]
blocked_probes = [\n{',\n'.join(blocked)}\n]
'''


def font(size: int) -> ImageFont.ImageFont:
    path = Path("C:/Windows/Fonts/msyh.ttc")
    return ImageFont.truetype(str(path), size) if path.exists() else ImageFont.load_default()


def build_review_images(mask_array: np.ndarray) -> None:
    background = Image.open(BACKGROUND).convert("RGB")
    overlay = background.copy()
    draw = ImageDraw.Draw(overlay, "RGBA")
    mask = Image.fromarray(mask_array, mode="L")
    tint = Image.new("RGBA", SIZE, (30, 235, 120, 0))
    tint.putalpha(mask.point(lambda value: round(value * 0.58)))
    overlay = Image.alpha_composite(overlay.convert("RGBA"), tint).convert("RGB")
    draw = ImageDraw.Draw(overlay, "RGBA")
    for entry in PORTALS:
        x, y = px(entry["pos"])
        draw.ellipse((x - 22, y - 22, x + 22, y + 22), fill=(255, 106, 62, 230), outline=(255, 255, 255, 255), width=4)
        draw.text((x + 28, y - 18), entry["label"], font=font(25), fill=(255, 246, 210, 255), stroke_width=3, stroke_fill=(0, 0, 0, 230))
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    overlay.save(OUT_DIR / "world_map_v6_navigation_overlay.png", optimize=True)
    mask.save(OUT_DIR / "world_map_v6_walkable_mask.png", optimize=True)


def main() -> None:
    if Image.open(BACKGROUND).size != SIZE:
        raise RuntimeError(f"World map must be {SIZE}, got {Image.open(BACKGROUND).size}")
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    walkable_mask = build_exact_walkable_mask()
    polygons = mask_to_rectangles(walkable_mask)
    build_review_images(walkable_mask)
    LAYOUT.write_text(build_tres(polygons), encoding="utf-8", newline="\n")
    metadata = {"design_size": SIZE, "grid_px": MASK_GRID, "route_guides": ROUTES, "walkable_region_count": len(polygons), "portals": PORTALS}
    (OUT_DIR / "world_map_v6_topology.json").write_text(json.dumps(metadata, ensure_ascii=False, indent=2), encoding="utf-8")
    print(LAYOUT)
    print(OUT_DIR / "world_map_v6_navigation_overlay.png")


if __name__ == "__main__":
    main()
