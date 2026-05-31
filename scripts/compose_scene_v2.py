"""
compose_scene_v2.py — 基于 Gemini 标签的智能场景合成

改进：
1. 用标签文件知道每个元素是什么，精准摆放
2. 连续平铺道路
3. 天空+远景背景
4. 建筑锚定在地面

用法：
    python scripts/compose_scene_v2.py
"""

import json
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

PROJECT_ROOT = Path(__file__).resolve().parent.parent
MODULES_DIR = PROJECT_ROOT / "game" / "art" / "modules"
LABELS_PATH = PROJECT_ROOT / "assets" / "library" / "element_labels.json"
OUT = PROJECT_ROOT / "game" / "art" / "backgrounds" / "bg_linxi_v2_composed.png"

W, H = 1920, 1080


def load_labels() -> dict:
    raw = json.loads(LABELS_PATH.read_text(encoding="utf-8"))
    # Reverse: spec_name -> {file, cat, confidence}
    rev = {}
    for key, info in raw.items():
        cat = key.split("_")[0]
        spec = info.get("spec_name", key)
        if spec == "unknown":
            spec = key
        file_path = MODULES_DIR / cat / f"{spec}.png"
        if file_path.exists():
            rev[spec] = {"key": key, "cat": cat, "path": file_path, "confidence": info.get("confidence", "low")}
    return rev


def get_by_keyword(labels: dict, cat: str, *keywords: str) -> list:
    """Find elements matching ALL keywords in spec_name."""
    result = []
    for spec_name, info in labels.items():
        if info["cat"] != cat:
            continue
        if all(kw.lower() in spec_name.lower() for kw in keywords):
            result.append(info)
    return result


def get_any(labels: dict, cat: str) -> list:
    return [v for v in labels.values() if v["cat"] == cat]


def main():
    print("Loading labels...")
    labels = load_labels()
    print(f"  {len(labels)} labeled elements")

    # Index by category for fallback
    by_cat = {}
    for info in labels.values():
        by_cat.setdefault(info["cat"], []).append(info)

    # Canvas with sky gradient
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    for y in range(H):
        t = y / H
        r = int(80 + (150 - 80) * t)
        g = int(150 + (200 - 150) * t)
        b = int(200 + (140 - 200) * t)
        draw.line([(0, y), (W, y)], fill=(r, g, b, 255))

    placed = [0]
    def paste_img(path: Path, x: int, y: int, scale: float = 1.0, centered: bool = True):
        try:
            img = Image.open(str(path)).convert("RGBA")
            w2 = int(img.width * scale)
            h2 = int(img.height * scale)
            img = img.resize((max(1, w2), max(1, h2)), Image.LANCZOS)
            px = x - img.width // 2 if centered else x
            py = y - img.height // 2 if centered else y
            canvas.paste(img, (px, py), img)
            placed[0] += 1
            return True
        except Exception:
            return False

    print("\n=== Background: distant trees ===")
    bg_veg = get_any(labels, "veg")[:4]
    for i, v in enumerate(bg_veg):
        paste_img(v["path"], 200 + i * 500, 260, 2.5)

    print("\n=== Ground: continuous road ===")
    road = get_by_keyword(labels, "ground", "dirt", "straight")
    road_curve_l = get_by_keyword(labels, "ground", "curve_L")
    road_curve_r = get_by_keyword(labels, "ground", "curve_R")
    grass_edge = get_by_keyword(labels, "ground", "grass_edge")

    # Build continuous road from left to right
    road_y = 580
    tile_w = 220
    if road:
        for col in range(0, W + tile_w, tile_w):
            idx = col // tile_w % len(road)
            paste_img(road[idx]["path"], col, road_y, 1.3, centered=False)

    # Road top edge - use grass edge for transition
    if grass_edge:
        for col in range(0, W + 300, 300):
            paste_img(grass_edge[0]["path"], col, road_y - 100, 1.1, centered=False)

    # Road bottom fill
    all_ground = get_any(labels, "ground")
    for i, g in enumerate(all_ground[2:8]):
        paste_img(g["path"], 50 + i * 300, road_y + 140, 1.4, centered=False)

    print("\n=== Buildings: anchored on road ===")
    wall_l = get_by_keyword(labels, "building", "wall_L")
    wall_m = get_by_keyword(labels, "building", "wall_M")
    wall_r = get_by_keyword(labels, "building", "wall_R")
    roof_l = get_by_keyword(labels, "building", "roof", "L")
    roof_m = get_by_keyword(labels, "building", "roof", "M")
    roof_r = get_by_keyword(labels, "building", "roof", "R")
    inn = get_by_keyword(labels, "building", "inn")
    smithy = get_by_keyword(labels, "building", "smithy")
    door = get_by_keyword(labels, "building", "door", "wood_a")
    column = get_by_keyword(labels, "building", "column")
    eaves = get_by_keyword(labels, "building", "eaves")

    # Left: Inn cluster
    building_y = road_y - 60
    if inn:
        paste_img(inn[0]["path"], 80, building_y - 20, 0.9)
    if wall_l:
        paste_img(wall_l[0]["path"], 40, building_y + 60, 0.75)
    if wall_m:
        paste_img(wall_m[0]["path"], 100, building_y + 60, 0.75)
    if roof_l:
        paste_img(roof_l[0]["path"], 40, building_y - 50, 0.75)
    if roof_m:
        paste_img(roof_m[0]["path"], 100, building_y - 50, 0.75)

    # Center: House cluster
    if wall_l:
        paste_img(wall_l[0]["path"], 540, building_y + 70, 0.8)
    if wall_m:
        paste_img(wall_m[0]["path"], 610, building_y + 70, 0.8)
    if wall_r:
        paste_img(wall_r[0]["path"], 680, building_y + 70, 0.8)
    if roof_l:
        paste_img(roof_l[0]["path"], 530, building_y - 40, 0.8)
    if roof_m:
        paste_img(roof_m[0]["path"], 600, building_y - 40, 0.8)
    if roof_r:
        paste_img(roof_r[0]["path"], 670, building_y - 40, 0.8)
    if door:
        paste_img(door[0]["path"], 605, building_y + 90, 0.5)

    # Right: Smithy cluster
    if smithy:
        paste_img(smithy[0]["path"], 1250, building_y - 20, 0.9)
    if wall_l:
        paste_img(wall_l[0]["path"], 1200, building_y + 60, 0.75)
    if wall_m:
        paste_img(wall_m[0]["path"], 1260, building_y + 60, 0.75)
    if roof_l:
        paste_img(roof_l[0]["path"], 1200, building_y - 50, 0.75)
    if roof_m:
        paste_img(roof_m[0]["path"], 1260, building_y - 50, 0.75)

    print("\n=== Vegetation: framing + ground ===")
    bamboo_cluster = get_by_keyword(labels, "veg", "bamboo", "cluster")
    bamboo_single = get_by_keyword(labels, "veg", "bamboo", "single")
    bamboo_edge_l = get_by_keyword(labels, "veg", "bamboo", "edge_L")
    bamboo_edge_r = get_by_keyword(labels, "veg", "bamboo", "edge_R")
    bush = get_by_keyword(labels, "veg", "bush")
    grass_tuft = get_by_keyword(labels, "veg", "grass", "tuft")
    canopy = get_by_keyword(labels, "veg", "canopy")
    foliage_l = get_by_keyword(labels, "veg", "foliage", "fg_L")
    foliage_r = get_by_keyword(labels, "veg", "foliage", "fg_R")

    # Left bamboo wall
    left_veg = (bamboo_edge_l or bamboo_cluster or get_any(labels, "veg"))[:4]
    for i, v in enumerate(left_veg):
        paste_img(v["path"], 10, 200 + i * 160, 1.3)

    # Right bamboo wall
    right_veg = (bamboo_edge_r or bamboo_cluster or get_any(labels, "veg"))[4:8]
    for i, v in enumerate(right_veg):
        paste_img(v["path"], W - 30, 200 + i * 160, 1.3)

    # Ground shrubs
    all_bush = bush or get_any(labels, "veg")
    for i, v in enumerate(all_bush[:6]):
        paste_img(v["path"], 200 + i * 280, 660, 0.6)

    # Grass tufts
    all_grass = grass_tuft or get_any(labels, "veg")[10:16]
    for i, v in enumerate(all_grass[:5]):
        paste_img(v["path"], 300 + i * 350, 700, 0.5)

    print("\n=== Props: scattered ===")
    lantern = get_by_keyword(labels, "prop", "lantern")
    barrel = get_by_keyword(labels, "prop", "barrel")
    box = get_by_keyword(labels, "prop", "box", "wood_a")
    wine_jar = get_by_keyword(labels, "prop", "wine", "jar_a")
    stone_tablet = get_by_keyword(labels, "prop", "stone", "tablet")
    cart = get_by_keyword(labels, "prop", "cart")
    weapon = get_by_keyword(labels, "prop", "weapon")

    prop_spots = [
        (180, 540, lantern), (240, 550, barrel),
        (640, 540, lantern), (700, 560, barrel),
        (1340, 540, lantern), (1400, 560, barrel),
        (400, 600, box), (900, 580, wine_jar),
        (1100, 580, stone_tablet), (1550, 580, weapon),
        (750, 610, cart),
    ]
    for x, y, items in prop_spots:
        if items:
            paste_img(items[0]["path"], x, y, 0.65)

    print("\n=== Foreground overlay ===")
    fg = (foliage_l or foliage_r or get_any(labels, "veg"))[16:20]
    for i, v in enumerate(fg[:4]):
        xy = -10 if i % 2 == 0 else W - 100
        paste_img(v["path"], xy, 500 + i * 80, 2.0)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(OUT, "PNG")
    print(f"\nSaved: {OUT} ({placed[0]} elements placed)")


if __name__ == "__main__":
    main()
