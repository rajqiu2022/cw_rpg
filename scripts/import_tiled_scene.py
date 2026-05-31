"""Import a Tiled .tmj/.json map into a Godot SceneScript .tres.

This importer treats Tiled as a visual scene assembly tool for painterly
Sprite2D modules, not as a strict tilemap pipeline. It extracts:

- visible tile/object placements -> SceneScript.scene_objects
- object layers named collisions/collision -> collision_rects
- object layers named triggers/trigger -> trigger_zones
- object layers named exits/exit -> exits
- object layers named npcs/npc -> npcs
- object layer named spawn -> player_spawn

Usage:
    python scripts/import_tiled_scene.py maps/linxi_tutorial.tmj --out game/data/scenes/linxi_tutorial.tres --scene-id linxi_tutorial --display-name "林西村 · 新手关"
"""

from __future__ import annotations

import argparse
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parent.parent
GAME_ROOT = PROJECT_ROOT / "game"
DEFAULT_CANVAS = (1920, 1080)

SCENE_OBJECT_LAYER_DEFAULTS = {
    "ground": 0,
    "road": 0,
    "roads": 0,
    "terrain": 0,
    "buildings": 10,
    "building": 10,
    "props": 12,
    "prop": 12,
    "vegetation": 18,
    "veg": 18,
    "foreground": 30,
    "fg": 30,
}


def _props(raw: dict[str, Any]) -> dict[str, Any]:
    result: dict[str, Any] = {}
    for item in raw.get("properties", []) or []:
        name = item.get("name")
        if name:
            result[str(name)] = item.get("value")
    return result


def _layer_key(layer_name: str) -> str:
    return layer_name.strip().lower().replace(" ", "_").replace("-", "_")


def _load_map(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def _load_tileset_source(path: Path) -> dict[str, Any]:
    if path.suffix.lower() in {".json", ".tsj"}:
        return _load_map(path)
    if path.suffix.lower() != ".tsx":
        raise ValueError(f"Unsupported external tileset format: {path}")

    tree = ET.parse(path)
    root = tree.getroot()
    tiles: list[dict[str, Any]] = []
    for tile_el in root.findall("tile"):
        tile: dict[str, Any] = {"id": int(tile_el.attrib.get("id", "0"))}
        image_el = tile_el.find("image")
        if image_el is not None:
            tile["image"] = image_el.attrib.get("source", "")
            tile["imagewidth"] = int(float(image_el.attrib.get("width", "0") or 0))
            tile["imageheight"] = int(float(image_el.attrib.get("height", "0") or 0))
        props_el = tile_el.find("properties")
        if props_el is not None:
            props: list[dict[str, Any]] = []
            for prop_el in props_el.findall("property"):
                value: Any = prop_el.attrib.get("value", "")
                prop_type = prop_el.attrib.get("type", "string")
                if prop_type == "int":
                    value = int(value or 0)
                elif prop_type == "float":
                    value = float(value or 0.0)
                elif prop_type == "bool":
                    value = str(value).lower() == "true"
                props.append({"name": prop_el.attrib.get("name", ""), "value": value})
            tile["properties"] = props
        tiles.append(tile)
    return {"tiles": tiles}


def _resolve_path(map_path: Path, image_path: str) -> Path:
    raw = Path(image_path.replace("\\", "/"))
    if raw.is_absolute():
        return raw
    return (map_path.parent / raw).resolve()


def _to_res_path(path: Path) -> str:
    resolved = path.resolve()
    try:
        rel = resolved.relative_to(GAME_ROOT.resolve())
        return "res://" + rel.as_posix()
    except ValueError:
        pass
    try:
        rel = resolved.relative_to(PROJECT_ROOT.resolve())
        return rel.as_posix()
    except ValueError:
        return resolved.as_posix()


def _tileset_lookup(map_path: Path, data: dict[str, Any]) -> dict[int, dict[str, Any]]:
    lookup: dict[int, dict[str, Any]] = {}
    for tileset in data.get("tilesets", []) or []:
        firstgid = int(tileset.get("firstgid", 1))
        tileset_data = tileset
        if "source" in tileset:
            source_path = _resolve_path(map_path, str(tileset["source"]))
            tileset_data = _load_tileset_source(source_path)
            tileset_base = source_path.parent
        else:
            tileset_base = map_path.parent

        for tile in tileset_data.get("tiles", []) or []:
            local_id = int(tile.get("id", 0))
            image = str(tile.get("image", ""))
            if not image:
                continue
            image_path = _resolve_path(tileset_base / "tileset.json", image)
            tile_props = _props(tile)
            lookup[firstgid + local_id] = {
                "texture": _to_res_path(image_path),
                "imagewidth": int(tile.get("imagewidth", tile_props.get("width", 0) or 0)),
                "imageheight": int(tile.get("imageheight", tile_props.get("height", 0) or 0)),
                "properties": tile_props,
            }
    return lookup


def _norm(x: float, y: float, width: float, height: float) -> str:
    return f"Vector2({x / width:.6f}, {y / height:.6f})"


def _norm_size(w: float, h: float, width: float, height: float) -> str:
    return f"Vector2({w / width:.6f}, {h / height:.6f})"


def _quote(value: Any) -> str:
    return json.dumps(str(value), ensure_ascii=False)


def _gd_scalar(value: Any) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    return _quote(value)


def _dict_block(data: dict[str, Any]) -> str:
    lines = ["{"]
    for key, value in data.items():
        if value is None or value == "":
            continue
        if isinstance(value, str) and value.startswith("Vector2("):
            rendered = value
        else:
            rendered = _gd_scalar(value)
        lines.append(f"  {_quote(key)}: {rendered},")
    lines.append("}")
    return "\n".join(lines)


def _array_block(name: str, items: list[dict[str, Any]]) -> str:
    if not items:
        return f"{name} = []"
    rendered = ",\n".join(_dict_block(item) for item in items)
    return f"{name} = [\n{rendered}\n]"


def _layer_z(layer: dict[str, Any]) -> int:
    props = _props(layer)
    if "z_index" in props:
        return int(props["z_index"])
    key = _layer_key(str(layer.get("name", "")))
    return SCENE_OBJECT_LAYER_DEFAULTS.get(key, 10)


def _object_center(obj: dict[str, Any]) -> tuple[float, float]:
    x = float(obj.get("x", 0.0))
    y = float(obj.get("y", 0.0))
    w = float(obj.get("width", 0.0))
    h = float(obj.get("height", 0.0))
    if obj.get("gid"):
        # Tiled tile objects use bottom-left origin.
        return x + w / 2.0, y - h / 2.0
    return x + w / 2.0, y + h / 2.0


def _scene_object_from_gid(
    obj: dict[str, Any],
    gid: int,
    tile_lookup: dict[int, dict[str, Any]],
    map_width_px: float,
    map_height_px: float,
    default_z: int,
) -> dict[str, Any] | None:
    tile = tile_lookup.get(gid)
    if tile is None:
        return None

    props = {**tile.get("properties", {}), **_props(obj)}
    cx, cy = _object_center(obj)
    image_w = float(tile.get("imagewidth", 0) or obj.get("width", 1) or 1)
    image_h = float(tile.get("imageheight", 0) or obj.get("height", 1) or 1)
    width = float(obj.get("width", image_w) or image_w)
    height = float(obj.get("height", image_h) or image_h)
    scale_x = float(props.get("scale_x", width / image_w))
    scale_y = float(props.get("scale_y", height / image_h))

    return {
        "id": props.get("id", obj.get("name") or f"obj_{obj.get('id', gid)}"),
        "texture": tile["texture"],
        "pos": _norm(cx, cy, map_width_px, map_height_px),
        "scale": f"Vector2({scale_x:.6f}, {scale_y:.6f})",
        "rotation": float(obj.get("rotation", props.get("rotation", 0.0)) or 0.0),
        "z_index": int(props.get("z_index", default_z)),
        "centered": bool(props.get("centered", True)),
        "require_flag": props.get("require_flag", ""),
        "hide_flag": props.get("hide_flag", ""),
    }


def _collect_scene_objects(
    map_path: Path,
    data: dict[str, Any],
    tile_lookup: dict[int, dict[str, Any]],
    map_width_px: float,
    map_height_px: float,
) -> list[dict[str, Any]]:
    objects: list[dict[str, Any]] = []
    tile_w = float(data.get("tilewidth", 0) or 1)
    tile_h = float(data.get("tileheight", 0) or 1)

    for layer in data.get("layers", []) or []:
        if not layer.get("visible", True):
            continue
        key = _layer_key(str(layer.get("name", "")))
        if key in {"collision", "collisions", "trigger", "triggers", "exit", "exits", "npc", "npcs", "spawn"}:
            continue
        default_z = _layer_z(layer)

        if layer.get("type") == "tilelayer":
            width = int(layer.get("width", data.get("width", 0)) or 0)
            layer_data = layer.get("data", []) or []
            for idx, raw_gid in enumerate(layer_data):
                gid = int(raw_gid)
                if gid == 0:
                    continue
                tile = tile_lookup.get(gid)
                if tile is None:
                    continue
                col = idx % width
                row = idx // width
                objects.append(
                    {
                        "id": f"{key}_{idx}",
                        "texture": tile["texture"],
                        "pos": _norm((col + 0.5) * tile_w, (row + 0.5) * tile_h, map_width_px, map_height_px),
                        "scale": "Vector2(1.000000, 1.000000)",
                        "rotation": 0.0,
                        "z_index": default_z,
                        "centered": True,
                    }
                )
        elif layer.get("type") == "objectgroup":
            for obj in layer.get("objects", []) or []:
                gid = int(obj.get("gid", 0) or 0)
                if gid == 0:
                    continue
                scene_obj = _scene_object_from_gid(obj, gid, tile_lookup, map_width_px, map_height_px, default_z)
                if scene_obj is not None:
                    objects.append(scene_obj)

    return objects


def _rect_entry(obj: dict[str, Any], map_width_px: float, map_height_px: float) -> dict[str, Any]:
    props = _props(obj)
    cx, cy = _object_center(obj)
    return {
        "id": props.get("id", obj.get("name") or f"rect_{obj.get('id', 0)}"),
        "pos": _norm(cx, cy, map_width_px, map_height_px),
        "size": _norm_size(float(obj.get("width", 1)), float(obj.get("height", 1)), map_width_px, map_height_px),
        "require_flag": props.get("require_flag", ""),
        "hide_flag": props.get("hide_flag", ""),
    }


def _collect_object_layers(data: dict[str, Any], map_width_px: float, map_height_px: float) -> dict[str, Any]:
    result: dict[str, Any] = {
        "player_spawn": "Vector2(0.5, 0.8)",
        "collision_rects": [],
        "trigger_zones": [],
        "exits": [],
        "npcs": [],
        "animated_props": [],
    }

    for layer in data.get("layers", []) or []:
        if layer.get("type") != "objectgroup":
            continue
        key = _layer_key(str(layer.get("name", "")))
        for obj in layer.get("objects", []) or []:
            props = _props(obj)
            cx, cy = _object_center(obj)
            if key in {"collision", "collisions"}:
                result["collision_rects"].append(_rect_entry(obj, map_width_px, map_height_px))
            elif key in {"trigger", "triggers"}:
                item = _rect_entry(obj, map_width_px, map_height_px)
                item["action"] = props.get("action", "")
                result["trigger_zones"].append(item)
            elif key in {"exit", "exits"}:
                item = _rect_entry(obj, map_width_px, map_height_px)
                item["label"] = props.get("label", obj.get("name", "前往"))
                item["target_scene"] = props.get("target_scene", "")
                item["target_pos"] = props.get("target_pos", "Vector2(0.5, 0.5)")
                result["exits"].append(item)
            elif key in {"npc", "npcs"}:
                result["npcs"].append(
                    {
                        "npc_id": props.get("npc_id", obj.get("name") or f"npc_{obj.get('id', 0)}"),
                        "npc_name": props.get("npc_name", obj.get("name", "")),
                        "pos": _norm(cx, cy, map_width_px, map_height_px),
                        "portrait_path": props.get("portrait_path", ""),
                        "sprite_path": props.get("sprite_path", ""),
                        "dialog_id": props.get("dialog_id", ""),
                        "scale": float(props.get("scale", 0.08)),
                        "require_flag": props.get("require_flag", ""),
                        "hide_flag": props.get("hide_flag", ""),
                    }
                )
            elif key in {"animated", "animated_props", "atmosphere"}:
                item = _rect_entry(obj, map_width_px, map_height_px)
                item["type"] = props.get("type", "")
                item["color"] = props.get("color", "")
                item["texture"] = props.get("texture", props.get("texture_path", ""))
                item["z_index"] = int(props.get("z_index", 22) or 22)
                item["speed"] = float(props.get("speed", 1.0) or 1.0)
                result["animated_props"].append(item)
            elif key == "spawn":
                result["player_spawn"] = _norm(cx, cy, map_width_px, map_height_px)

    return result


def import_tiled_map(map_path: Path, scene_id: str, display_name: str, background_path: str = "") -> str:
    data = _load_map(map_path)
    map_width_px = float(data.get("width", 0) or DEFAULT_CANVAS[0]) * float(data.get("tilewidth", 1) or 1)
    map_height_px = float(data.get("height", 0) or DEFAULT_CANVAS[1]) * float(data.get("tileheight", 1) or 1)

    tile_lookup = _tileset_lookup(map_path, data)
    scene_objects = _collect_scene_objects(map_path, data, tile_lookup, map_width_px, map_height_px)
    object_layers = _collect_object_layers(data, map_width_px, map_height_px)

    lines = [
        '[gd_resource type="Resource" script_class="SceneScript" load_steps=2 format=3]',
        "",
        '[ext_resource type="Script" path="res://scripts/domain/scene_script.gd" id="1_scn"]',
        "",
        "[resource]",
        'script = ExtResource("1_scn")',
        f'scene_id = &{_quote(scene_id)}',
        f"display_name = {_quote(display_name)}",
        f"background_path = {_quote(background_path)}",
        'bgm_path = ""',
        "is_walkable = true",
        f"player_spawn = {object_layers['player_spawn']}",
        "hotspots = []",
        "",
        _array_block("scene_objects", scene_objects),
        "",
        _array_block("animated_props", object_layers["animated_props"]),
        "",
        _array_block("npcs", object_layers["npcs"]),
        "",
        _array_block("exits", object_layers["exits"]),
        "",
        _array_block("collision_rects", object_layers["collision_rects"]),
        "",
        _array_block("trigger_zones", object_layers["trigger_zones"]),
        "",
    ]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description="Import Tiled .tmj/.json into Godot SceneScript .tres")
    parser.add_argument("map", type=Path, help="Path to Tiled .tmj/.json file")
    parser.add_argument("--out", type=Path, required=True, help="Output .tres path")
    parser.add_argument("--scene-id", required=True, help="SceneScript scene_id")
    parser.add_argument("--display-name", required=True, help="SceneScript display_name")
    parser.add_argument("--background-path", default="", help="Optional res:// background path")
    args = parser.parse_args()

    content = import_tiled_map(args.map, args.scene_id, args.display_name, args.background_path)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(content, encoding="utf-8", newline="\n")
    print(f"[tiled] wrote {args.out}")


if __name__ == "__main__":
    main()
