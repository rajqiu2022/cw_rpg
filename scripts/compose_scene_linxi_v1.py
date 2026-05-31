"""
compose_scene_linxi_v1.py — 从 4 张模块化 atlas 拼装林西村主街完整场景

步骤：
1. 对每张 atlas 做背景移除（rembg 或聚类检测）
2. 自动切分为独立元素 PNG（基于连通分量 bbox）
3. 按场景布局定义，将元素组合到 1920x1080 画布

用法：
    python scripts/compose_scene_linxi_v1.py
    python scripts/compose_scene_linxi_v1.py --output game/art/backgrounds/bg_linxi_main_composed.png
"""

import json
import os
import sys
from pathlib import Path

from PIL import Image
from rembg import remove as rembg_remove

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ATLAS_DIR = PROJECT_ROOT / "assets" / "raw" / "scene_background"
ELEMENTS_DIR = PROJECT_ROOT / "assets" / "library" / "scene_elements"
OUTPUT_PATH = PROJECT_ROOT / "game" / "art" / "backgrounds" / "bg_linxi_main_composed.png"

SCENE_W = 1920
SCENE_H = 1080

# 背景底色（草地 / 远景）
BG_COLOR = (85, 120, 80)  # 深绿草地

ATLAS_FILES = {
    "ground": "scene_kit_ground_road_linxi_v1.png",
    "building": "scene_kit_building_linxi_v1.png",
    "veg": "scene_kit_veg_linxi_v1.png",
    "prop": "scene_kit_prop_linxi_v1.png",
}


def load_image(path: Path) -> Image.Image:
    img = Image.open(path).convert("RGBA")
    return img


def remove_background(img: Image.Image) -> Image.Image:
    """Use rembg to remove background from atlas element."""
    return rembg_remove(img, alpha_matting=True, alpha_matting_foreground_threshold=200)


def find_elements_from_original(img: Image.Image, min_area: int = 500, margin: int = 10) -> list[dict]:
    """Find element bounding boxes by detecting non-background regions.
    
    Background = pixels similar to image border average. Elements = everything else.
    """
    import numpy as np
    arr = np.array(img.convert("RGBA"))
    h, w = arr.shape[:2]
    rgb = arr[:, :, :3].astype(float)

    # Sample border pixels to estimate background color
    border_mask = np.zeros((h, w), dtype=bool)
    border_mask[0:5, :] = True
    border_mask[-5:, :] = True
    border_mask[:, 0:5] = True
    border_mask[:, -5:] = True
    bg_pixels = rgb[border_mask]
    bg_mean = bg_pixels.mean(axis=0)
    bg_std = bg_pixels.std(axis=0) + 30  # generous tolerance

    # Distance from background color
    diff = np.sqrt(((rgb - bg_mean) ** 2).sum(axis=2))
    threshold = float(np.sqrt((bg_std ** 2).sum())) * 0.8
    binary = (diff > threshold).astype(np.uint8)

    # Morphological close to merge nearby pixels within same element
    from scipy.ndimage import binary_closing, binary_dilation
    binary = binary_closing(binary, structure=np.ones((5, 5)), iterations=2)

    # Connected components
    from scipy.ndimage import label, find_objects
    labeled, num_features = label(binary)

    components = []
    for i in range(1, num_features + 1):
        region = (labeled == i)
        area = region.sum()
        if area < min_area:
            continue
        rows = np.any(region, axis=1)
        cols = np.any(region, axis=0)
        min_y, max_y = np.where(rows)[0][[0, -1]]
        min_x, max_x = np.where(cols)[0][[0, -1]]
        bw = max_x - min_x + 1
        bh = max_y - min_y + 1
        # Skip full-frame fragments
        if bw > w * 0.7 or bh > h * 0.7:
            continue
        components.append({
            "bbox": (
                max(0, min_x - margin),
                max(0, min_y - margin),
                min(w - max(0, min_x - margin), bw + margin * 2),
                min(h - max(0, min_y - margin), bh + margin * 2),
            ),
            "area": int(area),
            "cx": float((min_x + max_x) / 2 / w),
            "cy": float((min_y + max_y) / 2 / h),
        })

    components.sort(key=lambda c: (c["bbox"][1], c["bbox"][0]))
    return components


def slice_atlas(atlas_path: Path, category: str) -> list[Path]:
    """Slice atlas: find elements on original, then rembg each individually."""
    img = load_image(atlas_path)
    elements = find_elements_from_original(img)
    print(f"  {category}: found {len(elements)} elements")

    out_dir = ELEMENTS_DIR / category
    out_dir.mkdir(parents=True, exist_ok=True)

    paths = []
    for i, elem in enumerate(elements):
        x, y, w, h = elem["bbox"]
        cropped = img.crop((x, y, x + w, y + h))
        # Apply rembg to individual element
        try:
            cropped = rembg_remove(cropped, alpha_matting=False)
        except Exception:
            pass  # keep as-is if rembg fails
        out_path = out_dir / f"{category}_{i:02d}.png"
        cropped.save(out_path, "PNG")
        paths.append(out_path)

    return paths


# ============================================================
# 林西村主街 场景布局数据（按类别自动排版)

def build_layout(element_cache: dict[str, Image.Image]) -> list[tuple[str, tuple, float]]:
    """Stage a village street scene with proper grounding and z-ordering.
    
    Canvas: 1920x1080. Scene structure:
      Sky (top 35%) → Distant hills → Buildings L/R → Road (center) → Props → Foreground foliage
    """
    layout = []

    ground_elems = [k for k in element_cache if k.startswith("ground_")]
    building_elems = [k for k in element_cache if k.startswith("building_")]
    veg_elems = [k for k in element_cache if k.startswith("veg_")]
    prop_elems = [k for k in element_cache if k.startswith("prop_")]

    # == LAYER 0: Sky gradient handled in compose (solid bg) ==

    # == LAYER 1: Distant background (use lighter veg elements as distant trees/hills) ==
    hill_elems = [e for e in veg_elems if element_cache[e].height > 100]
    for i, eid in enumerate(hill_elems[:6]):
        x = 100 + i * 320
        y = 200
        layout.append((eid, (x, y), 2.5))

    # == LAYER 2: Ground / Road - TILE to cover full bottom 55% ==
    road_y = 550
    road_tile_w = 280
    if ground_elems:
        for col in range(0, SCENE_W + road_tile_w, road_tile_w):
            idx = col // road_tile_w % len(ground_elems)
            layout.append((ground_elems[idx], (col, road_y), 1.5))

    # Second row of ground for road top edge
    if len(ground_elems) > 1:
        for col in range(0, SCENE_W + road_tile_w, road_tile_w):
            idx = (col // road_tile_w + 1) % len(ground_elems)
            layout.append((ground_elems[idx], (col, road_y - 130), 1.3))

    # Lower ground fill
    if len(ground_elems) > 2:
        for col in range(0, SCENE_W + road_tile_w, road_tile_w):
            idx = (col // road_tile_w + 2) % len(ground_elems)
            layout.append((ground_elems[idx], (col, road_y + 150), 1.5))

    # == LAYER 3: Buildings - anchored on road top edge ==
    # Left cluster: Inn (x: 80-280)
    left_group = building_elems[: min(6, len(building_elems))]
    for i, eid in enumerate(left_group):
        x = 60 + (i % 3) * 100
        y = 360 + (i // 3) * 90
        layout.append((eid, (x, y), 0.85))

    # Center cluster: House (x: 560-760)
    center_group = building_elems[6: min(12, len(building_elems))]
    for i, eid in enumerate(center_group):
        x = 580 + (i % 3) * 90
        y = 370 + (i // 3) * 80
        layout.append((eid, (x, y), 0.8))

    # Right cluster: Smithy (x: 1200-1400)
    right_group = building_elems[12: min(18, len(building_elems))]
    for i, eid in enumerate(right_group):
        x = 1250 + (i % 3) * 90
        y = 360 + (i // 3) * 80
        layout.append((eid, (x, y), 0.85))

    # == LAYER 4: Vegetation framing ==
    # Left bamboo wall
    for i, eid in enumerate(veg_elems[6:12]):
        if i < 5:
            layout.append((eid, (15, 180 + i * 140), 1.4))
    # Right bamboo wall
    for i, eid in enumerate(veg_elems[12:18]):
        if i < 5:
            layout.append((eid, (SCENE_W - 40, 180 + i * 140), 1.4))
    # Ground shrubs along road edges
    for i, eid in enumerate(veg_elems[18:24]):
        if i < 6:
            x = 200 + i * 280
            layout.append((eid, (x, 620), 0.65))
    # Additional shrubs between buildings
    for i, eid in enumerate(veg_elems[24:27]):
        if i < 3:
            x = 400 + i * 550
            layout.append((eid, (x, 440), 0.55))

    # == LAYER 5: Props placed in front of buildings and along road ==
    prop_spots = [
        (160, 520), (240, 530),   # 酒馆前: lantern + barrel
        (660, 520), (720, 540),   # 民居前
        (1340, 520), (1400, 530), # 铁匠铺前
        (400, 580), (900, 570),   # 路中散落
        (1100, 560), (1550, 580),
        (300, 440), (800, 450),   # 建筑旁
        (1500, 450),
    ]
    for i, eid in enumerate(prop_elems[: min(len(prop_elems), len(prop_spots))]):
        layout.append((eid, prop_spots[i], 0.7))

    # == LAYER 6: Foreground foliage overlay ==
    for i, eid in enumerate(veg_elems[27:31]):
        if i < 4:
            x = -20 if i % 2 == 0 else SCENE_W - 50
            layout.append((eid, (x, 480 + i * 80), 2.0))

    return layout


def compose_scene(elements_dir: Path, output: Path) -> Image.Image:
    """Composite scene from sliced elements using auto-layout with sky gradient bg."""
    from PIL import ImageDraw

    # Sky gradient background
    canvas = Image.new("RGBA", (SCENE_W, SCENE_H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)
    sky_top = (140, 180, 210)
    sky_bot = (180, 210, 180)
    for y in range(SCENE_H):
        t = y / SCENE_H
        r = int(sky_top[0] + (sky_bot[0] - sky_top[0]) * t)
        g = int(sky_top[1] + (sky_bot[1] - sky_top[1]) * t)
        b = int(sky_top[2] + (sky_bot[2] - sky_top[2]) * t)
        draw.line([(0, y), (SCENE_W, y)], fill=(r, g, b, 255))

    # Load all available elements
    element_cache: dict[str, Image.Image] = {}
    for cat in ["ground", "building", "veg", "prop"]:
        cat_dir = elements_dir / cat
        if not cat_dir.exists():
            print(f"  [WARN] No {cat} elements found in {cat_dir}")
            continue
        for f in sorted(cat_dir.glob("*.png")):
            key = f"{cat}_{f.stem}"
            img = Image.open(f).convert("RGBA")
            if img.width < 10 or img.height < 10:
                continue
            element_cache[key] = img

    layout = build_layout(element_cache)

    # Sort layout by category for correct z-ordering:
    # ground(0) → distant_veg(1) → buildings(2) → veg(3) → props(4) → fg_veg(5)
    cat_order = {"ground": 0, "building": 2, "veg": 3, "prop": 4}
    def z_key(item):
        eid = item[0]
        for prefix, order in cat_order.items():
            if eid.startswith(prefix):
                return order
        return 5

    layout.sort(key=z_key)

    placed = 0
    for elem_id, pos, scale in layout:
        if elem_id not in element_cache:
            continue
        img = element_cache[elem_id].copy()
        w, h = img.size
        new_w = max(1, int(w * scale))
        new_h = max(1, int(h * scale))
        img = img.resize((new_w, new_h), Image.LANCZOS)

        x = max(0, min(SCENE_W - new_w, int(pos[0] - new_w // 2)))
        y = max(0, min(SCENE_H - new_h, int(pos[1] - new_h // 2)))
        canvas.paste(img, (x, y), img)
        placed += 1

    print(f"  Placed {placed} / {len(element_cache)} elements")
    return canvas


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Compose Linxi Village main street scene from atlases")
    parser.add_argument("--output", type=Path, default=OUTPUT_PATH)
    parser.add_argument("--slice-only", action="store_true", help="Only slice atlases, don't compose")
    parser.add_argument("--skip-slice", action="store_true", help="Skip slicing, use existing elements")
    args = parser.parse_args()

    ELEMENTS_DIR.mkdir(parents=True, exist_ok=True)
    args.output.parent.mkdir(parents=True, exist_ok=True)

    if not args.skip_slice:
        print("=== Step 1: Slicing atlases ===")
        for category, filename in ATLAS_FILES.items():
            atlas_path = ATLAS_DIR / filename
            if not atlas_path.exists():
                print(f"  [SKIP] {filename} not found")
                continue
            slice_atlas(atlas_path, category)

    if args.slice_only:
        print("Done slicing. Run without --slice-only to compose scene.")
        return

    print("\n=== Step 2: Composing scene ===")
    scene = compose_scene(ELEMENTS_DIR, args.output)
    scene.save(args.output, "PNG")
    print(f"\nScene saved to: {args.output}")


if __name__ == "__main__":
    main()
