"""
label_and_build_scene.py — Gemini 识别切片元素 + 生成 Godot 场景

步骤：
1. 将每类切片元素拼成 grid 图（带编号）
2. 发送给 Gemini Vision 识别每个元素是什么
3. 输出映射表 JSON
4. 按 scene-element-kit-spec.md §6 的布局规则生成 Godot .tscn

用法：
    python scripts/label_and_build_scene.py --label-only          # 只识别
    python scripts/label_and_build_scene.py --scene-only          # 只用已有映射生成场景
    python scripts/label_and_build_scene.py                       # 全部
"""

import base64
import io
import json
import math
import os
import sys
from pathlib import Path

import requests
from PIL import Image, ImageDraw, ImageFont
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

ELEMENTS_DIR = PROJECT_ROOT / "assets" / "library" / "scene_elements"
MAPPING_PATH = PROJECT_ROOT / "assets" / "library" / "element_labels.json"
SCENE_OUT = PROJECT_ROOT / "game" / "scenes" / "linxi_main_street.tscn"

API_KEY = os.getenv("OKROUTER_API_KEY", "")
API_URL = os.getenv("OKROUTER_BASE_URL", "https://api.okrouter.com/v1") + "/chat/completions"
MODEL = os.getenv("OKROUTER_VISION_MODEL", "gemini-3.1-pro-preview-customtools")

SCENE_W = 1920
SCENE_H = 1080
GRID_COLS = 6
THUMB_SIZE = 200

CATEGORIES = ["ground", "building", "veg", "prop"]


def make_grid(elements: list[Path], category: str) -> Image.Image:
    """Create a labeled grid of element thumbnails for Gemini to review."""
    n = len(elements)
    cols = min(GRID_COLS, n)
    rows = math.ceil(n / cols)
    pad = 12
    label_h = 24
    
    cell_w = THUMB_SIZE + pad * 2
    cell_h = THUMB_SIZE + pad * 2 + label_h
    grid_w = cols * cell_w
    grid_h = rows * cell_h

    img = Image.new("RGBA", (grid_w, grid_h), (40, 44, 52, 255))
    draw = ImageDraw.Draw(img)

    try:
        font = ImageFont.truetype("arial.ttf", 14)
    except Exception:
        font = ImageFont.load_default()

    for i, elem in enumerate(elements):
        row = i // cols
        col = i % cols
        x = col * cell_w + pad
        y = row * cell_h + pad

        try:
            thumb = Image.open(elem).convert("RGBA")
            thumb.thumbnail((THUMB_SIZE, THUMB_SIZE), Image.LANCZOS)
            tx = x + (THUMB_SIZE - thumb.width) // 2
            ty = y + (THUMB_SIZE - thumb.height) // 2
            img.paste(thumb, (tx, ty), thumb)
        except Exception:
            pass

        label = f"{category}_{i:02d}"
        draw.rectangle([x, y + THUMB_SIZE + 2, x + THUMB_SIZE, y + THUMB_SIZE + label_h], fill=(30, 34, 40, 255))
        draw.text((x + 4, y + THUMB_SIZE + 4), label, fill=(220, 220, 230), font=font)

    return img


def call_gemini_vision(image: Image.Image, prompt: str, retries: int = 1) -> dict:
    """Send image to Gemini and get JSON response. Retry once if JSON parse fails."""
    buf = io.BytesIO()
    image.convert("RGB").save(buf, format="JPEG", quality=80, optimize=True)
    b64 = base64.b64encode(buf.getvalue()).decode()

    payload = {
        "model": MODEL,
        "messages": [{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{b64}"}}
            ]
        }],
        "temperature": 0.1,
        "max_tokens": 8192,
    }

    for attempt in range(retries + 1):
        r = requests.post(API_URL, headers={
            "Authorization": f"Bearer {API_KEY}",
            "Content-Type": "application/json",
        }, json=payload, timeout=180)
        r.raise_for_status()
        data = r.json()
        text = data["choices"][0]["message"]["content"]

        # Strip markdown wrappers
        if text.startswith("```json"):
            text = text[7:]
        if text.startswith("```"):
            text = text[3:]
        if text.endswith("```"):
            text = text[:-3]
        text = text.strip()

        try:
            return json.loads(text)
        except json.JSONDecodeError as e:
            if attempt < retries:
                payload["messages"][0]["content"][0]["text"] += "\n\nYour previous JSON was invalid. Output ONLY valid JSON this time."
                continue
            raise e


def label_elements():
    """Label all sliced elements via Gemini Vision."""
    all_labels = {}

    for cat in CATEGORIES:
        cat_dir = ELEMENTS_DIR / cat
        if not cat_dir.exists():
            continue
        pngs = sorted(cat_dir.glob("*.png"))
        if not pngs:
            continue

        print(f"\n{'='*50}")
        print(f"Labeling {cat} ({len(pngs)} elements)")
        print(f"{'='*50}")

        # Build the expect list from the spec
        expect_list = get_expected_elements(cat)
        expect_text = "\n".join(f"  - {e}" for e in expect_list)

        grid = make_grid(pngs, cat)
        grid_path = PROJECT_ROOT / "tools" / f"_grid_{cat}.jpg"
        grid.convert("RGB").save(grid_path, "JPEG", quality=80)
        print(f"  Grid saved: {grid_path}")

        prompt = f"""You are labeling game sprite elements for a wuxia RPG village scene module kit.

This is a grid of {cat.upper()} elements. Each has a label like "{cat}_00", "{cat}_01", etc.

Below is the INTENDED element list from the game designer's spec. Your job: match each grid element to the closest spec name. 

Expected {cat} elements:
{expect_text}

Rules:
1. Look at each element and determine what it most likely IS (road piece, wall, roof, bamboo, barrel, etc.)
2. Match it to the closest item from the expected list
3. If an element doesn't match anything, label it as "unknown"
4. If multiple spec items match, pick the best one
5. Ignore numbering - element {cat}_00 might be spec item #3

Return ONLY valid JSON (no markdown, no comments):
{{
  "elements": [
    {{"grid_label": "{cat}_00", "spec_name": "exact_spec_name", "confidence": "high|medium|low"}},
    ...
  ]
}}
Be concise. Finish the JSON completely."""
        try:
            result = call_gemini_vision(grid, prompt)
            for elem in result.get("elements", []):
                all_labels[elem["grid_label"]] = {
                    "spec_name": elem.get("spec_name", "unknown"),
                    "confidence": elem.get("confidence", "low"),
                }
            print(f"  Got {len(result.get('elements', []))} labels")
        except Exception as e:
            print(f"  [ERROR] {e}")

    MAPPING_PATH.parent.mkdir(parents=True, exist_ok=True)
    MAPPING_PATH.write_text(json.dumps(all_labels, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"\nMapping saved: {MAPPING_PATH} ({len(all_labels)} entries)")
    return all_labels


def get_expected_elements(cat: str) -> list[str]:
    """Return the list of expected element names from the spec."""
    spec = {
        "ground": [
            "road_dirt_linxi_straight_a", "road_dirt_linxi_curve_L", "road_dirt_linxi_curve_R",
            "road_dirt_linxi_cross", "road_stone_zhuwei_straight_a", "road_stone_zhuwei_straight_b",
            "road_stone_zhuwei_corner_L", "road_dirt_grass_edge", "road_stone_grass_edge",
            "road_gravel_scatter_a", "road_gravel_scatter_b", "road_dirt_footprint_trail",
            "road_grass_patch_a", "road_grass_patch_b", "road_dirt_slope_up",
        ],
        "building": [
            "build_linxi_house_wall_L", "build_linxi_house_wall_M", "build_linxi_house_wall_R",
            "build_linxi_roof_gray_L", "build_linxi_roof_gray_M", "build_linxi_roof_gray_R",
            "build_linxi_door_wood_a", "build_linxi_door_wood_open", "build_linxi_window_paper_a",
            "build_linxi_column_wood", "build_linxi_eaves_straight", "build_linxi_wall_courtyard_a",
            "build_linxi_inn_storefront", "build_linxi_smithy_front",
            "build_linxi_signboard_blank_a", "build_linxi_signboard_blank_b",
        ],
        "veg": [
            "veg_bamboo_single_a", "veg_bamboo_single_b", "veg_bamboo_cluster_a", "veg_bamboo_cluster_b",
            "veg_bamboo_edge_L", "veg_bamboo_edge_R", "veg_bamboo_top_canopy",
            "veg_bush_green_a", "veg_bush_green_b", "veg_grass_tuft_a", "veg_grass_tuft_b",
            "veg_flower_wild_a", "veg_leaves_scatter", "veg_tree_pine_a",
            "veg_foliage_fg_L", "veg_foliage_fg_R",
        ],
        "prop": [
            "prop_linxi_barrel_wood_a", "prop_linxi_barrel_wood_b",
            "prop_linxi_box_wood_a", "prop_linxi_box_wood_open",
            "prop_linxi_wine_jar_a", "prop_linxi_wine_jar_stack",
            "prop_linxi_lantern_red_a", "prop_linxi_lantern_red_b",
            "prop_linxi_wine_banner", "prop_zhuwei_stone_tablet", "prop_zhuwei_road_sign",
            "prop_linxi_weapon_scatter", "prop_linxi_fire_pot", "prop_zhuwei_stone_altar",
            "prop_ruin_wall_crack_L", "prop_ruin_wall_crack_R",
            "prop_ruin_door_broken", "prop_ruin_beam_broken", "prop_ruin_rubble_pile",
            "prop_linxi_cart_wood",
        ],
    }
    return spec.get(cat, [])


# ============================================================
# Godot .tscn 生成
# ============================================================

def generate_scene(labels: dict):
    """Generate a valid Godot .tscn file with Sprite2D nodes."""
    # Copy elements to game/art/modules first
    import shutil
    def get_spec_name(key: str) -> str:
        sn = labels.get(key, {}).get("spec_name", key)
        if sn == "unknown":
            return key
        return sn

    for cat in ["ground", "building", "veg", "prop"]:
        src_dir = ELEMENTS_DIR / cat
        dst_dir = PROJECT_ROOT / "game" / "art" / "modules" / cat
        dst_dir.mkdir(parents=True, exist_ok=True)
        for f in sorted(src_dir.glob("*.png")):
            key = f.stem  # file is already named like "ground_00"
            spec_name = get_spec_name(key)
            dst = dst_dir / f"{spec_name}.png"
            shutil.copy2(f, dst)

    # Build layout
    elements_by_cat: dict[str, list[tuple[str, dict]]] = {}
    for key, info in labels.items():
        cat = key.split("_")[0]
        spec_name = info.get("spec_name", key)
        if spec_name == "unknown":
            spec_name = key  # fall back to numbered name
        elements_by_cat.setdefault(cat, []).append((key, info))

    layout = generate_layout(elements_by_cat)

    # Generate ext_resource declarations
    ext_resources = {}
    resource_id = 1
    resource_map: dict[str, int] = {}

    for cat in ["ground", "building", "veg", "prop"]:
        for key, info in elements_by_cat.get(cat, []):
            spec_name = get_spec_name(key)
            tex_path = f"res://art/modules/{cat}/{spec_name}.png"
            if tex_path not in resource_map:
                resource_map[tex_path] = resource_id
                resource_id += 1

    load_steps = len(resource_map) + 1

    lines = []
    lines.append(f"[gd_scene load_steps={load_steps} format=3]\n")

    for tex_path, rid in sorted(resource_map.items(), key=lambda x: x[1]):
        lines.append(f'[ext_resource type=\"Texture2D\" path=\"{tex_path}\" id=\"{rid}\"]\n')

    lines.append('[node name=\"LinxiMainStreet\" type=\"Node2D\"]\n')

    # Z-order layers
    z_layers = [
        ("GroundLayer", 0, layout.get("ground", [])),
        ("BuildingLayer", 1, layout.get("building", [])),
        ("VegLayer", 2, layout.get("veg", [])),
        ("PropLayer", 3, layout.get("prop", [])),
        ("FgLayer", 4, layout.get("fg", [])),
    ]

    for layer_name, z, items in z_layers:
        lines.append(f'\n[node name=\"{layer_name}\" type=\"Node2D\" parent=\"LinxiMainStreet\"]\n')
        lines.append(f'z_index = {z * 10}\n')

        for key, pos, scale in items:
            spec_name = get_spec_name(key)
            cat = key.split("_")[0]
            tex_path = f"res://art/modules/{cat}/{spec_name}.png"
            rid = resource_map.get(tex_path, 1)

            node_name = spec_name.replace("_", " ").title().replace(" ", "")[:40]
            x, y = pos

            lines.append(f'\n[node name=\"{node_name}\" type=\"Sprite2D\" parent=\"{layer_name}\"]\n')
            lines.append(f'texture = ExtResource(\"{rid}\")\n')
            lines.append(f'position = Vector2({x}, {y})\n')
            lines.append(f'scale = Vector2({scale}, {scale})\n')
            lines.append(f'centered = true\n')

    SCENE_OUT.parent.mkdir(parents=True, exist_ok=True)
    SCENE_OUT.write_text("".join(lines), encoding="utf-8")
    print(f"Scene saved: {SCENE_OUT} ({len(resource_map)} textures, {sum(len(v) for v in layout.values())} sprites)")


def generate_layout(elements_by_cat: dict) -> dict:
    """Generate placement positions for all elements."""
    layout = {"ground": [], "building": [], "veg": [], "prop": [], "fg": []}
    
    ground_elems = elements_by_cat.get("ground", [])
    building_elems = elements_by_cat.get("building", [])
    veg_elems = elements_by_cat.get("veg", [])
    prop_elems = elements_by_cat.get("prop", [])

    # Ground: tile road across lower section
    road_y = 540
    for i, (key, info) in enumerate(ground_elems[:10]):
        x = 100 + i * 200
        layout["ground"].append((key, (x, road_y), 1.3))

    # Buildings: three clusters
    clusters = [
        (80, 340, building_elems[:5]),
        (560, 350, building_elems[5:10]),
        (1250, 340, building_elems[10:15]),
    ]
    for cx, cy, elems in clusters:
        for j, (key, info) in enumerate(elems):
            x = cx + (j % 3) * 90
            y = cy + (j // 3) * 80
            layout["building"].append((key, (x, y), 0.75))

    # Vegetation: framing + ground
    for i, (key, info) in enumerate(veg_elems[:5]):
        layout["veg"].append((key, (20, 160 + i * 140), 1.2))
    for i, (key, info) in enumerate(veg_elems[5:10]):
        layout["veg"].append((key, (SCENE_W - 40, 160 + i * 140), 1.2))
    for i, (key, info) in enumerate(veg_elems[10:16]):
        x = 200 + i * 270
        layout["veg"].append((key, (x, 640), 0.6))
    # Foreground foliage
    for i, (key, info) in enumerate(veg_elems[16:20]):
        x = -10 if i % 2 == 0 else SCENE_W - 100
        layout["fg"].append((key, (x, 500 + i * 70), 1.8))

    # Props: scattered around
    spots = [
        (160, 490), (240, 500), (660, 500), (740, 520),
        (1340, 490), (1420, 510), (400, 580), (900, 560),
        (1100, 560), (1550, 580), (320, 440), (800, 440),
    ]
    for i, (key, info) in enumerate(prop_elems[:len(spots)]):
        layout["prop"].append((key, spots[i], 0.65))

    return layout


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Label scene elements with Gemini and/or generate Godot scene")
    parser.add_argument("--label-only", action="store_true")
    parser.add_argument("--scene-only", action="store_true")
    args = parser.parse_args()

    labels = {}
    if not args.scene_only:
        labels = label_elements()
    else:
        if MAPPING_PATH.exists():
            labels = json.loads(MAPPING_PATH.read_text(encoding="utf-8"))
            print(f"Loaded {len(labels)} labels from {MAPPING_PATH}")

    if not args.label_only and labels:
        generate_scene(labels)


if __name__ == "__main__":
    main()
