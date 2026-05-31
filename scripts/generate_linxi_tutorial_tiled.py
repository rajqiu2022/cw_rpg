"""Generate a deterministic first-pass Tiled map for the Linxi tutorial scene.

This is intentionally not an LLM "free layout". It uses a fixed composition
template and picks assets by category / filename hints from a Tiled image
collection tileset. The result is meant to be reviewed in Tiled, then imported
with scripts/import_tiled_scene.py.

Usage:
    python scripts/create_tiled_tileset.py --out maps/tiled/tilesets/scene_elements.tsx
    python scripts/generate_linxi_tutorial_tiled.py
"""

from __future__ import annotations

import argparse
import json
import math
import os
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_TILESET = PROJECT_ROOT / "maps" / "tiled" / "tilesets" / "scene_elements.tsx"
DEFAULT_MANIFEST = PROJECT_ROOT / "maps" / "tiled" / "scene_elements_manifest.json"
DEFAULT_OUT = PROJECT_ROOT / "maps" / "tiled" / "linxi_tutorial.tmj"
DEFAULT_PREVIEW = PROJECT_ROOT / "tools" / "linxi_tutorial_tiled_preview.png"

MAP_W = 1920
MAP_H = 1088
TILE_W = 32
TILE_H = 32

LAYER_ORDER = ["ground", "buildings", "vegetation", "props", "foreground"]


def _props(el: ET.Element) -> dict[str, Any]:
    result: dict[str, Any] = {}
    props_el = el.find("properties")
    if props_el is None:
        return result
    for prop in props_el.findall("property"):
        name = prop.attrib.get("name", "")
        value: Any = prop.attrib.get("value", "")
        prop_type = prop.attrib.get("type", "string")
        if prop_type == "int":
            value = int(value or 0)
        elif prop_type == "float":
            value = float(value or 0.0)
        elif prop_type == "bool":
            value = str(value).lower() == "true"
        if name:
            result[name] = value
    return result


def _load_tileset(tsx_path: Path) -> list[dict[str, Any]]:
    if not tsx_path.exists():
        raise SystemExit(
            f"Tileset not found: {tsx_path}. "
            "Put the sliced PNG modules under game/art/modules/{ground,building,veg,prop}/, "
            "then run: python scripts/create_tiled_tileset.py --out maps/tiled/tilesets/scene_elements.tsx"
        )
    root = ET.parse(tsx_path).getroot()
    tiles: list[dict[str, Any]] = []
    for tile_el in root.findall("tile"):
        image_el = tile_el.find("image")
        if image_el is None:
            continue
        props = _props(tile_el)
        image_path = (tsx_path.parent / image_el.attrib["source"]).resolve()
        tile_id = int(tile_el.attrib["id"])
        tiles.append(
            {
                "gid": tile_id + 1,
                "id": str(props.get("id", image_path.stem)),
                "category": str(props.get("category", _guess_category(image_path.stem))),
                "z_index": int(props.get("z_index", 12)),
                "image": image_path,
                "width": int(image_el.attrib.get("width", 1)),
                "height": int(image_el.attrib.get("height", 1)),
            }
        )
    if not tiles:
        raise SystemExit(f"No tiles found in {tsx_path}")
    return tiles


def _load_manifest(manifest_path: Path) -> dict[str, Any]:
    if not manifest_path.exists():
        raise SystemExit(f"Scene element manifest not found: {manifest_path}")
    with manifest_path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    assets = data.get("assets", {})
    if not isinstance(assets, dict):
        raise SystemExit(f"Invalid scene element manifest: {manifest_path}")
    return assets


def _apply_manifest(tiles: list[dict[str, Any]], manifest: dict[str, Any]) -> None:
    for tile in tiles:
        meta = manifest.get(tile["id"], {})
        if not isinstance(meta, dict):
            meta = {}
        tile["meta"] = meta
        if "category" in meta:
            tile["category"] = str(meta["category"])
        if "z_index" in meta:
            tile["z_index"] = int(meta["z_index"])


def _guess_category(stem: str) -> str:
    if stem.startswith(("road_", "ground_")):
        return "ground"
    if stem.startswith(("build_", "building_")):
        return "building"
    if stem.startswith("veg_"):
        return "veg"
    if stem.startswith("prop_"):
        return "prop"
    return "prop"


def _pick(tiles: list[dict[str, Any]], category: str | None = None, hints: tuple[str, ...] = ()) -> dict[str, Any] | None:
    candidates = tiles
    if category:
        aliases = {
            "buildings": {"building", "buildings"},
            "vegetation": {"veg", "vegetation"},
            "ground": {"ground"},
            "props": {"prop", "props"},
            "foreground": {"foreground", "veg"},
        }.get(category, {category})
        candidates = [tile for tile in candidates if tile["category"] in aliases]
    for hint in hints:
        matched = [tile for tile in candidates if hint in tile["id"].lower()]
        if matched:
            return matched[0]
    return candidates[0] if candidates else None


def _tile_object(tile: dict[str, Any], name: str, cx: float, cy: float, scale: float = 1.0, z_index: int | None = None) -> dict[str, Any]:
    width = max(1.0, tile["width"] * scale)
    height = max(1.0, tile["height"] * scale)
    props = [
        {"name": "id", "type": "string", "value": name},
        {"name": "z_index", "type": "int", "value": int(tile["z_index"] if z_index is None else z_index)},
    ]
    return {
        "gid": tile["gid"],
        "height": height,
        "id": 0,
        "name": name,
        "properties": props,
        "rotation": 0,
        "visible": True,
        "width": width,
        # Tiled tile objects use bottom-left origin.
        "x": cx - width / 2.0,
        "y": cy + height / 2.0,
    }


def _require_tile(tiles: list[dict[str, Any]], tile_id: str) -> dict[str, Any]:
    for tile in tiles:
        if tile["id"] == tile_id:
            return tile
    raise SystemExit(f"Required scene module not found in tileset: {tile_id}")


def _rect(name: str, x: float, y: float, w: float, h: float, props: dict[str, Any] | None = None) -> dict[str, Any]:
    prop_items = []
    for key, value in (props or {}).items():
        prop_type = "string"
        if isinstance(value, bool):
            prop_type = "bool"
        elif isinstance(value, int):
            prop_type = "int"
        elif isinstance(value, float):
            prop_type = "float"
        prop_items.append({"name": key, "type": prop_type, "value": value})
    return {
        "height": h,
        "id": 0,
        "name": name,
        "properties": prop_items,
        "rotation": 0,
        "visible": True,
        "width": w,
        "x": x,
        "y": y,
    }


def _object_layer(name: str, objects: list[dict[str, Any]], layer_id: int) -> dict[str, Any]:
    for idx, obj in enumerate(objects, start=1):
        obj["id"] = idx
    return {
        "draworder": "topdown",
        "id": layer_id,
        "name": name,
        "objects": objects,
        "opacity": 1,
        "type": "objectgroup",
        "visible": True,
        "x": 0,
        "y": 0,
    }


def build_layout(tiles: list[dict[str, Any]]) -> dict[str, list[dict[str, Any]]]:
    road_left = _require_tile(tiles, "road_dirt_linxi_curve_L")
    road_mid = _require_tile(tiles, "road_dirt_linxi_cross")
    road_right = _require_tile(tiles, "road_dirt_linxi_curve_R")
    grass_a = _require_tile(tiles, "road_grass_patch_a")
    gravel_a = _require_tile(tiles, "road_gravel_scatter_a")
    inn = _require_tile(tiles, "build_linxi_inn_storefront")
    smithy = _require_tile(tiles, "build_linxi_smithy_front")
    house = _require_tile(tiles, "build_linxi_house_wall_M")
    bamboo_a = _require_tile(tiles, "veg_bamboo_cluster_a")
    bamboo_b = _require_tile(tiles, "veg_bamboo_cluster_b")
    bush_a = _require_tile(tiles, "veg_bush_green_a")
    grass_tuft = _require_tile(tiles, "veg_grass_tuft_a")
    barrel = _require_tile(tiles, "prop_linxi_barrel_wood_a")
    cart = _require_tile(tiles, "prop_linxi_cart_wood")
    sign = _require_tile(tiles, "prop_zhuwei_road_sign")
    altar = _require_tile(tiles, "prop_zhuwei_stone_altar")

    layers: dict[str, list[dict[str, Any]]] = {name: [] for name in LAYER_ORDER}

    # Use a few large painterly modules with breathing room. These PNGs are not seamless tiles.
    for tile, name, cx, cy, scale in [
        (road_left, "road_left_curve", 420, 780, 1.15),
        (road_mid, "road_center_cross", 850, 760, 1.1),
        (road_right, "road_right_curve", 1320, 720, 1.15),
    ]:
        layers["ground"].append(_tile_object(tile, name, cx, cy, scale, 0))
    for i, (tile, cx, cy, scale) in enumerate(
        [
            (grass_a, 540, 610, 0.75),
            (grass_a, 1460, 565, 0.75),
            (gravel_a, 790, 860, 0.85),
            (gravel_a, 1180, 650, 0.75),
        ]
    ):
        layers["ground"].append(_tile_object(tile, f"ground_detail_{i}", cx, cy, scale, 1))

    for tile, name, cx, cy, scale in [
        (inn, "building_inn", 470, 430, 0.82),
        (house, "building_house_rear", 910, 360, 0.78),
        (smithy, "building_smithy", 1350, 430, 0.78),
    ]:
        layers["buildings"].append(_tile_object(tile, name, cx, cy, scale, 10))

    for i, (tile, cx, cy, scale) in enumerate(
        [
            (bamboo_a, 120, 410, 0.8),
            (bamboo_b, 1740, 390, 0.78),
            (bush_a, 285, 650, 0.7),
            (bush_a, 1540, 640, 0.7),
            (grass_tuft, 640, 900, 0.75),
            (grass_tuft, 1260, 890, 0.7),
        ]
    ):
        layers["vegetation"].append(_tile_object(tile, f"vegetation_frame_{i}", cx, cy, scale, 18))

    for tile, name, cx, cy, scale in [
        (cart, "prop_cart_by_inn", 615, 575, 0.45),
        (barrel, "prop_barrel_by_smithy", 1195, 590, 0.45),
        (sign, "prop_exit_sign", 1595, 675, 0.52),
        (altar, "tutorial_stone_altar", 850, 655, 0.52),
    ]:
        layers["props"].append(_tile_object(tile, name, cx, cy, scale, 13 if "tutorial" in name or "sign" in name else 12))

    return layers


def build_map(tileset_path: Path, map_out_path: Path, layers: dict[str, list[dict[str, Any]]]) -> dict[str, Any]:
    tiled_layers: list[dict[str, Any]] = []
    layer_id = 1
    for name in LAYER_ORDER:
        tiled_layers.append(_object_layer(name, layers[name], layer_id))
        layer_id += 1

    tiled_layers.extend(
        [
            _object_layer("spawn", [_rect("player_start", 920, 850, 48, 48)], layer_id),
            _object_layer(
                "collisions",
                [
                    _rect("inn_block", 215, 360, 510, 210),
                    _rect("rear_house_block", 715, 275, 390, 170),
                    _rect("smithy_block", 1070, 350, 560, 230),
                    _rect("left_bamboo_block", 0, 210, 260, 330),
                    _rect("right_bamboo_block", 1580, 185, 320, 330),
                ],
                layer_id + 1,
            ),
            _object_layer(
                "triggers",
                [
                    _rect("stone_tablet_notice", 790, 590, 130, 130, {"action": "dialog:ch1_stone_inscription"}),
                    _rect("tutorial_battle_entry", 1220, 610, 260, 180, {"action": "battle:thug_lone", "hide_flag": "defeated_thug_lone"}),
                ],
                layer_id + 2,
            ),
            _object_layer(
                "exits",
                [
                    _rect(
                        "exit_to_road",
                        1540,
                        560,
                        220,
                        240,
                        {
                            "label": "前往村外山道",
                            "target_scene": "ch1_s1_road",
                            "target_pos": "Vector2(0.15, 0.65)",
                        },
                    )
                ],
                layer_id + 3,
            ),
            _object_layer(
                "npcs",
                [
                    _rect(
                        "npc_master",
                        580,
                        635,
                        64,
                        96,
                        {
                            "npc_id": "xingfantian",
                            "npc_name": "刑樊天",
                            "dialog_id": "ch1_road_intro",
                            "sprite_path": "res://art/characters/protagonist_neutral.png",
                            "scale": 0.08,
                        },
                    )
                ],
                layer_id + 4,
            ),
        ]
    )

    return {
        "compressionlevel": -1,
        "height": MAP_H // TILE_H,
        "infinite": False,
        "layers": tiled_layers,
        "nextlayerid": layer_id + 5,
        "nextobjectid": 1,
        "orientation": "orthogonal",
        "renderorder": "right-down",
        "tiledversion": "1.11.0",
        "tileheight": TILE_H,
        "tilesets": [{"firstgid": 1, "source": os.path.relpath(tileset_path, map_out_path.parent).replace("\\", "/")}],
        "tilewidth": TILE_W,
        "type": "map",
        "version": "1.10",
        "width": MAP_W // TILE_W,
    }


def render_preview(layers: dict[str, list[dict[str, Any]]], tiles: list[dict[str, Any]], out_path: Path) -> None:
    tile_by_gid = {tile["gid"]: tile for tile in tiles}
    canvas = Image.new("RGBA", (MAP_W, MAP_H), (86, 122, 82, 255))

    for layer_name in LAYER_ORDER:
        for obj in layers[layer_name]:
            tile = tile_by_gid.get(int(obj["gid"]))
            if tile is None:
                continue
            img = Image.open(tile["image"]).convert("RGBA")
            width = max(1, int(round(float(obj["width"]))))
            height = max(1, int(round(float(obj["height"]))))
            img = img.resize((width, height), Image.LANCZOS)
            x = int(round(float(obj["x"])))
            y = int(round(float(obj["y"]) - height))
            canvas.alpha_composite(img, (x, y))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out_path)


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate deterministic Linxi tutorial Tiled map")
    parser.add_argument("--tileset", type=Path, default=DEFAULT_TILESET)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT)
    parser.add_argument("--preview", type=Path, default=DEFAULT_PREVIEW)
    args = parser.parse_args()

    tileset_path = args.tileset if args.tileset.is_absolute() else PROJECT_ROOT / args.tileset
    manifest_path = args.manifest if args.manifest.is_absolute() else PROJECT_ROOT / args.manifest
    out_path = args.out if args.out.is_absolute() else PROJECT_ROOT / args.out
    preview_path = args.preview if args.preview.is_absolute() else PROJECT_ROOT / args.preview

    tiles = _load_tileset(tileset_path)
    manifest = _load_manifest(manifest_path)
    _apply_manifest(tiles, manifest)
    layers = build_layout(tiles)
    data = build_map(tileset_path, out_path, layers)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8", newline="\n")
    render_preview(layers, tiles, preview_path)
    print(f"[tiled] wrote {out_path}")
    print(f"[preview] wrote {preview_path}")


if __name__ == "__main__":
    main()
