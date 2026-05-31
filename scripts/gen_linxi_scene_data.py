"""
gen_linxi_scene_data.py — 生成林西村主街完整游戏场景数据 (.tres)

包含：
- scene_objects: 模块化 Sprite2D 元素（道路/建筑/植物/道具/半透遮挡）
- collision_rects: 建筑/树木/墙体的碰撞盒
- trigger_zones: NPC 对话触发区
- exits: 场景出口
- player_spawn: 玩家出生点

坐标均为归一化 0~1，由 field_walkable_controller.gd 的 _norm_to_screen 转为像素。
"""

import json
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
LABELS_PATH = PROJECT_ROOT / "assets" / "library" / "element_labels.json"
OUT = PROJECT_ROOT / "game" / "data" / "scenes" / "ch1_s0_linxi_main_walkable.tres"

W, H = 1920, 1080


def norm(x, y):
    return f"Vector2({round(x/W, 4)}, {round(y/H, 4)})"


def load_labels():
    raw = json.loads(LABELS_PATH.read_text(encoding="utf-8"))
    # Reverse: spec_name -> {key, cat}
    rev = {}
    for key, info in raw.items():
        cat = key.split("_")[0]
        spec = info.get("spec_name", key)
        if spec == "unknown":
            spec = key
        rev[spec] = {"key": key, "cat": cat}
    return rev


def find(labels: dict, cat: str, *keywords: str) -> list[str]:
    """Return spec_names matching category and all keywords."""
    result = []
    for spec, info in labels.items():
        if info["cat"] != cat:
            continue
        if all(kw.lower() in spec.lower() for kw in keywords):
            result.append(spec)
    return result


def any_in(labels: dict, cat: str) -> list[str]:
    return [s for s, i in labels.items() if i["cat"] == cat]


def obj(spec: str, x: int, y: int, z: int, scale: float = 1.0, extra: str = ""):
    """Format a scene_object entry."""
    cat = labels.get(spec, {}).get("cat", "prop")
    tex = f'"res://art/modules/{cat}/{spec}.png"'
    pos = norm(x, y)
    s = f'{{\n"id": "{spec}",\n"texture": {tex},\n"pos": {pos},\n"z_index": {z},\n"scale": {round(scale, 2)}'
    if extra:
        s += f",\n{extra}"
    s += "\n}"
    return s


def collision_rect(id_str: str, x: int, y: int, w: int, h: int) -> str:
    return f'{{\n"id": "{id_str}",\n"pos": {norm(x, y)},\n"size": {norm(w, h)}\n}}'


def trigger_zone(id_str: str, x: int, y: int, w: int, h: int, action: str) -> str:
    return f'{{\n"id": "{id_str}",\n"pos": {norm(x, y)},\n"size": {norm(w, h)},\n"action": "{action}"\n}}'


def exit_zone(label: str, x: int, y: int, w: int, h: int, target: str, tpos: tuple) -> str:
    return f'{{\n"label": "{label}",\n"pos": {norm(x, y)},\n"size": {norm(w, h)},\n"target_scene": "{target}",\n"target_pos": Vector2({tpos[0]}, {tpos[1]})\n}}'


def main():
    global labels
    labels = load_labels()
    print(f"Loaded {len(labels)} labeled elements")

    objects = []
    collisions = []
    triggers = []
    exits = []

    # ============================================================
    # LAYER 0: Sky / Background — already handled by bg_linxi_main.png
    # We set background_path to the composed image
    # ============================================================

    # ============================================================
    # LAYER 1: Distant hills / trees (z=1-4)
    # ============================================================
    bg_veg = any_in(labels, "veg")
    for i, spec in enumerate(bg_veg[:4]):
        objects.append(obj(spec, 200 + i*480, 240, 2, 2.5))

    # ============================================================
    # LAYER 2: Ground / Road — continuous tiling across bottom (z=5-9)
    # ============================================================
    road_straight = find(labels, "ground", "straight")
    road_curve_l = find(labels, "ground", "curve_L")
    road_curve_r = find(labels, "ground", "curve_R")
    grass_edge = find(labels, "ground", "grass_edge")
    grass_patch = find(labels, "ground", "grass_patch")

    road_y = 620
    road_w = 300  # px per tile

    # Main road — tile left to right
    for col in range(0, W + road_w, road_w):
        idx = col // road_w % max(1, len(road_straight))
        if road_straight:
            objects.append(obj(road_straight[idx], col, road_y, 5, 1.5))

    # Road top edge — grass transition
    for col in range(0, W + 350, 350):
        if grass_edge:
            objects.append(obj(grass_edge[0], col, road_y - 120, 4, 1.2))

    # Lower ground fill
    all_gnd = any_in(labels, "ground")
    for i, spec in enumerate(all_gnd[4:12]):
        objects.append(obj(spec, 60 + i * 280, road_y + 180, 6, 1.4))

    # ============================================================
    # LAYER 3: Buildings — three clusters at road edge (z=10-19)
    # ============================================================
    house_wall_L = find(labels, "building", "wall_L")
    house_wall_M = find(labels, "building", "wall_M")
    house_wall_R = find(labels, "building", "wall_R")
    roof_L = find(labels, "building", "roof", "L")
    roof_M = find(labels, "building", "roof", "M")
    roof_R = find(labels, "building", "roof", "R")
    inn_front = find(labels, "building", "inn")
    smithy_front = find(labels, "building", "smithy")
    door_a = find(labels, "building", "door", "wood_a")
    door_open = find(labels, "building", "door", "open")
    column = find(labels, "building", "column")
    eaves = find(labels, "building", "eaves")
    signboard = find(labels, "building", "signboard")
    window = find(labels, "building", "window")

    # Building clusters: (label_prefix, cx, base_y)
    clusters = [
        ("inn", 100, 490),
        ("house", 600, 500),
        ("smithy", 1250, 490),
    ]

    for prefix, cx, by in clusters:
        # Wall
        if house_wall_L and prefix == "inn":
            pass  # inn_front replaces wall
        elif house_wall_L:
            objects.append(obj(house_wall_L[0], cx, by, 10, 0.9))
        if house_wall_M:
            objects.append(obj(house_wall_M[0], cx + 80, by, 10, 0.9))
        if house_wall_R:
            objects.append(obj(house_wall_R[0], cx + 160, by, 10, 0.9))
        # Roof
        if roof_L:
            objects.append(obj(roof_L[0], cx, by - 100, 18, 0.9))
        if roof_M:
            objects.append(obj(roof_M[0], cx + 80, by - 100, 18, 0.9))
        if roof_R:
            objects.append(obj(roof_R[0], cx + 160, by - 100, 18, 0.9))
        # Door
        if door_a:
            objects.append(obj(door_a[0], cx + 120, by + 40, 12, 0.6))
        if prefix == "inn" and inn_front:
            objects.append(obj(inn_front[0], cx + 40, by - 30, 11, 1.0))
        if prefix == "smithy" and smithy_front:
            objects.append(obj(smithy_front[0], cx + 40, by - 30, 11, 1.0))

    # Signboards on inn and smithy
    if signboard:
        objects.append(obj(signboard[0], 140, 440, 13, 0.65))
        objects.append(obj(signboard[-1], 1320, 440, 13, 0.65))

    # Columns
    if column:
        objects.append(obj(column[0], 150, 500, 9, 0.7))
        objects.append(obj(column[0], 680, 510, 9, 0.7))
        objects.append(obj(column[0], 1320, 500, 9, 0.7))

    # Eaves overhang — SEMI-TRANSPARENT for player to walk under
    if eaves:
        objects.append(obj(eaves[0], 120, 420, 25, 0.9, '"modulate": Color(1, 1, 1, 0.45)'))
        objects.append(obj(eaves[0], 580, 430, 25, 0.9, '"modulate": Color(1, 1, 1, 0.45)'))
        objects.append(obj(eaves[0], 1280, 420, 25, 0.9, '"modulate": Color(1, 1, 1, 0.45)'))

    # ============================================================
    # LAYER 4: Vegetation — framing + ground plants (z=15-24)
    # ============================================================
    bamboo_cluster = find(labels, "veg", "bamboo", "cluster")
    bamboo_single = find(labels, "veg", "bamboo", "single")
    bamboo_edge_l = find(labels, "veg", "bamboo", "edge_L")
    bamboo_edge_r = find(labels, "veg", "bamboo", "edge_R")
    bush = find(labels, "veg", "bush")
    grass_tuft = find(labels, "veg", "grass", "tuft")
    canopy = find(labels, "veg", "canopy")
    foliage_l = find(labels, "veg", "foliage", "fg_L")
    foliage_r = find(labels, "veg", "foliage", "fg_R")
    leaves = find(labels, "veg", "leaves")

    # Left bamboo wall
    left_veg = bamboo_edge_l + bamboo_cluster + bamboo_single
    for i, spec in enumerate(left_veg[:5]):
        objects.append(obj(spec, 10, 180 + i * 170, 15, 1.3))

    # Right bamboo wall
    right_veg = bamboo_edge_r + bamboo_cluster + bamboo_single
    for i, spec in enumerate(right_veg[:5]):
        objects.append(obj(spec, W - 40, 180 + i * 170, 15, 1.3))

    # Ground shrubs between buildings
    all_bush = bush + any_in(labels, "veg")
    shrub_x = [320, 480, 880, 1040, 1480, 1640]
    for i, sx in enumerate(shrub_x):
        if i < len(all_bush):
            objects.append(obj(all_bush[i], sx, 660, 16, 0.55))

    # Grass tufts along road
    all_grass = grass_tuft + any_in(labels, "veg")
    for i in range(8):
        if i + 10 < len(all_grass):
            objects.append(obj(all_grass[i+10], 180 + i * 210, 720, 8, 0.45))

    # ============================================================
    # LAYER 5: Props / Interactive objects (z=18-22)
    # ============================================================
    lantern = find(labels, "prop", "lantern")
    barrel = find(labels, "prop", "barrel")
    box_closed = find(labels, "prop", "box", "wood_a")
    wine_jar = find(labels, "prop", "wine", "jar_a")
    stone_tablet = find(labels, "prop", "stone", "tablet")
    cart = find(labels, "prop", "cart")
    weapon = find(labels, "prop", "weapon")
    fire_pot = find(labels, "prop", "fire")

    prop_positions = [
        # (x, y, label, specs, scale)
        (200, 580, "inn_lantern_l", lantern, 0.6),
        (260, 580, "inn_lantern_r", lantern, 0.6),
        (200, 600, "inn_barrel", barrel, 0.55),
        (680, 590, "house_lantern", lantern, 0.6),
        (680, 610, "house_barrel", barrel, 0.55),
        (1340, 580, "smithy_lantern", lantern, 0.6),
        (1400, 580, "smithy_lantern2", lantern, 0.6),
        (1340, 600, "smithy_barrel", barrel, 0.55),
        (400, 620, "road_box", box_closed, 0.5),
        (900, 610, "road_wine", wine_jar, 0.5),
        (1100, 620, "road_tablet", stone_tablet, 0.55),
        (1550, 610, "road_weapon", weapon, 0.5),
        (750, 640, "road_cart", cart, 0.7),
        (1360, 460, "smithy_fire", fire_pot, 0.55),
    ]
    for x, y, pid, specs, s in prop_positions:
        if specs:
            objects.append(obj(specs[0], x, y, 20, s))

    # ============================================================
    # LAYER 6: Foreground canopy / foliage overlay (z=30-35)
    # ============================================================
    # Semi-transparent canopy over the street — player walks behind
    if canopy:
        objects.append(obj(canopy[0], 400, 180, 32, 2.5, '"modulate": Color(1, 1, 1, 0.4)'))
        objects.append(obj(canopy[0], 1000, 180, 32, 2.5, '"modulate": Color(1, 1, 1, 0.4)'))

    # Foreground foliage edges
    fg = foliage_l + foliage_r
    for i, spec in enumerate(fg[:4]):
        xp = -10 if i % 2 == 0 else W - 100
        objects.append(obj(spec, xp, 520 + i * 80, 35, 2.0))

    # ============================================================
    # COLLISION RECTS — prevent player from walking through buildings/trees
    # ============================================================
    collisions = [
        collision_rect("inn_wall", 80, 440, 260, 140),
        collision_rect("house_wall", 560, 450, 260, 150),
        collision_rect("smithy_wall", 1220, 440, 260, 140),
        collision_rect("left_bamboo", 0, 160, 60, 700),
        collision_rect("right_bamboo", W-60, 160, 60, 700),
        collision_rect("road_cart_block", 710, 620, 120, 80),
    ]

    # ============================================================
    # TRIGGER ZONES — NPC interaction areas
    # ============================================================
    triggers = [
        trigger_zone("innkeeper_talk", 130, 470, 160, 100, "dialog:ch1_s2_inn_keeper"),
        trigger_zone("smith_talk", 1280, 470, 160, 100, "dialog:ch1_s2_merchant"),
        trigger_zone("stone_read", 1070, 590, 80, 60, "dialog:ch1_stone_inscription"),
        trigger_zone("cart_search", 720, 610, 120, 80, "dialog:ch1_s3_box_iron_sword"),
    ]

    # ============================================================
    # EXITS — scene transitions
    # ============================================================
    exits = [
        exit_zone("前往村外官道 →", W-80, 550, 160, 300, "ch1_s1_road", (0.1, 0.5)),
        exit_zone("← 返回主街", 30, 900, 160, 60, "ch1_s2_qingfeng", (0.5, 0.85)),
    ]

    # ============================================================
    # GENERATE .TRES
    # ============================================================
    lines = []
    lines.append('[gd_resource type="Resource" script_class="SceneScript" load_steps=2 format=3]\n')
    lines.append('\n[ext_resource type="Script" path="res://scripts/domain/scene_script.gd" id="1_scn"]\n')
    lines.append('\n[resource]\n')
    lines.append('script = ExtResource("1_scn")\n')
    lines.append('scene_id = &"ch1_s0_linxi_main_walkable"\n')
    lines.append('display_name = "林西村 · 主街"\n')
    lines.append('background_path = "res://art/backgrounds/bg_linxi_v2_composed.png"\n')
    lines.append('bgm_path = ""\n')
    lines.append('is_walkable = true\n')
    lines.append(f'player_spawn = Vector2(0.5, 0.88)\n')

    # scene_objects
    lines.append(f'scene_objects = [\n')
    for i, obj_str in enumerate(objects):
        lines.append(obj_str)
        if i < len(objects) - 1:
            lines.append(",\n")
        else:
            lines.append("\n")
    lines.append(']\n')

    # npcs — empty (we use trigger zones for interaction)
    lines.append('npcs = []\n')

    # exits
    lines.append(f'exits = [\n')
    for i, e in enumerate(exits):
        lines.append(e)
        lines.append(",\n" if i < len(exits) - 1 else "\n")
    lines.append(']\n')

    # collision_rects
    lines.append(f'collision_rects = [\n')
    for i, c in enumerate(collisions):
        lines.append(c)
        lines.append(",\n" if i < len(collisions) - 1 else "\n")
    lines.append(']\n')

    # trigger_zones
    lines.append(f'trigger_zones = [\n')
    for i, t in enumerate(triggers):
        lines.append(t)
        lines.append(",\n" if i < len(triggers) - 1 else "\n")
    lines.append(']\n')

    lines.append('hotspots = []\n')

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("".join(lines), encoding="utf-8")
    print(f"\nSaved: {OUT}")
    print(f"  scene_objects: {len(objects)}")
    print(f"  collision_rects: {len(collisions)}")
    print(f"  trigger_zones: {len(triggers)}")
    print(f"  exits: {len(exits)}")


if __name__ == "__main__":
    main()
