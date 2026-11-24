#!/usr/bin/env python3
"""Release gate for the v7 gameplay-first world map."""

from __future__ import annotations

import json
import re
from pathlib import Path

import cv2
import numpy as np


ROOT = Path(__file__).resolve().parents[1]
MASTER = ROOT / "assets" / "raw" / "scene_background" / "world_map_v7_gameplay" / "bg_world_map_v7_gameplay.png"
RUNTIME = ROOT / "game" / "art" / "backgrounds" / "bg_world_map_jianghu_v7_gameplay_hd.png"
NAV_SOURCE = ROOT / "assets" / "processed" / "scene" / "world_map_v7" / "world_map_v7_navigation_mask_1536.png"
NAV_RUNTIME = ROOT / "game" / "art" / "navigation_masks" / "world_map_jianghu_walk_v7.png"
VISIBLE = ROOT / "assets" / "processed" / "scene" / "world_map_v7" / "world_map_v7_visible_road_mask.png"
TOPOLOGY = ROOT / "assets" / "processed" / "scene" / "world_map_v7" / "world_map_v7_topology.json"
LAYOUT = ROOT / "game" / "data" / "maps" / "world_map_jianghu_layout_v7.tres"
SCENE = ROOT / "game" / "data" / "scenes" / "world_map_jianghu.tres"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def image(path: Path, flags: int) -> np.ndarray:
    value = cv2.imread(str(path), flags)
    if value is None:
        raise AssertionError(f"could not read {path}")
    return value


def main() -> None:
    master = image(MASTER, cv2.IMREAD_COLOR)
    runtime = image(RUNTIME, cv2.IMREAD_COLOR)
    nav = image(NAV_SOURCE, cv2.IMREAD_GRAYSCALE) > 127
    nav_runtime = image(NAV_RUNTIME, cv2.IMREAD_GRAYSCALE) > 127
    visible = image(VISIBLE, cv2.IMREAD_GRAYSCALE) > 127
    require((master.shape[1], master.shape[0]) == (1536, 1024), "v7 painted master must be 1536x1024")
    require((runtime.shape[1], runtime.shape[0]) == (3072, 2048), "v7 runtime background must be 3072x2048")
    require((nav_runtime.shape[1], nav_runtime.shape[0]) == (3072, 2048), "v7 runtime mask must be 3072x2048")
    require(np.all(~nav | visible), "navigation mask must stay inside the visible road contract")
    require(cv2.connectedComponents(nav.astype(np.uint8), 8)[0] - 1 == 1, "all land portals must share one road component")

    hsv = cv2.cvtColor(master, cv2.COLOR_BGR2HSV)
    road_like = (
        (hsv[:, :, 0] >= 12)
        & (hsv[:, :, 0] <= 32)
        & (hsv[:, :, 1] >= 45)
        & (hsv[:, :, 1] <= 175)
        & (hsv[:, :, 2] >= 55)
    )
    road_coverage = float(np.mean(road_like[nav]))
    require(road_coverage >= 0.85, f"navigation leaves visible road too often: {road_coverage:.3f}")

    topology = json.loads(TOPOLOGY.read_text(encoding="utf-8"))
    for portal in topology["portals"]:
        x = round(portal["pos"][0] * (nav.shape[1] - 1))
        y = round(portal["pos"][1] * (nav.shape[0] - 1))
        require(bool(nav[y, x]), f"portal is outside walkable mask: {portal['id']}")
    require(topology["ferry_contract"]["walking_on_water"] is False, "sea travel must never become walking")
    require(set(topology["ferry_contract"]["embarkation_portals"]) == {"bailu_ferry", "east_sea_port"}, "ferry portals drifted")

    layout = LAYOUT.read_text(encoding="utf-8")
    scene = SCENE.read_text(encoding="utf-8")
    require('schema_version = 7' in layout, "layout schema must be v7")
    require('walkable_mask_path = "res://art/navigation_masks/world_map_jianghu_walk_v7.png"' in layout, "layout must bind runtime mask")
    require(layout.count("PackedVector2Array(") < 100, "v7 must not restore hundreds of raster rectangles")
    require(layout.count('"travel_mode":"ferry"') == 2, "exactly two ferry embarkation portals are required")
    require('world_map_jianghu_layout_v7.tres' in scene and 'bg_world_map_jianghu_v7_gameplay_hd.png' in scene, "runtime scene must use v7 art and layout")
    require('camera_zoom = 1.0' in scene, "world-map camera must avoid non-integer 1.15 sampling")

    controller = (ROOT / "game" / "scripts" / "field" / "field_walkable_controller.gd").read_text(encoding="utf-8")
    player = (ROOT / "game" / "scripts" / "field" / "player.gd").read_text(encoding="utf-8")
    map_panel = (ROOT / "game" / "scripts" / "ui" / "world_map_panel.gd").read_text(encoding="utf-8")
    require("Camera2D.new()" in controller and "position_smoothing_enabled = true" in controller, "large maps must use Camera2D smoothing")
    require("or is_instance_valid(_world_camera)" in controller, "legacy WorldContainer scrolling must be disabled while Camera2D is active")
    require("_variant_texture_cache" in player, "field sprite textures must be cached")
    require('travel_mode' in map_panel and '乘船换乘' in map_panel, "map panel must explain ferry-only sea travel")
    physics_start = player.index("func _physics_process")
    move_index = player.index("move_and_slide()", physics_start)
    emit_index = player.index('emit_signal("moved"', physics_start)
    require(move_index < emit_index, "moved signal must follow movement settlement")

    v5_runtime_refs = []
    for path in [ROOT / "game" / "data" / "scenes", ROOT / "game" / "scripts"]:
        for file in path.rglob("*"):
            if file.is_file() and file.suffix in {".gd", ".tres"} and "game\\build" not in str(file):
                if re.search(r"bgm_[a-z_]+_v5\.wav", file.read_text(encoding="utf-8-sig")):
                    v5_runtime_refs.append(str(file.relative_to(ROOT)))
    require(not v5_runtime_refs, f"runtime still references rejected v5 music: {v5_runtime_refs}")

    print(
        "World map v7 PASS: "
        f"road_coverage={road_coverage:.3f} components=1 "
        f"portals={len(topology['portals'])} ferries=2 fallback_regions={layout.count('PackedVector2Array(')}"
    )


if __name__ == "__main__":
    main()
