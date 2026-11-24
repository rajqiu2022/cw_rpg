"""Add authored walkable silhouettes to chapter 2-4 fixed-camera scenes.

The original backgrounds remain intact.  These layouts turn them from full-screen
concept backdrops into actual field spaces: cliffs, sky and black margins are no
longer walkable, while legacy scene/world actions are rendered as portal arrows.
"""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCENE_DIR = ROOT / "game" / "data" / "scenes"
MAP_DIR = ROOT / "game" / "data" / "maps"

REGIONS: dict[str, list[list[tuple[float, float]]]] = {
    "ch2_s2_forest_edge": [[(0.04, 0.94), (0.05, 0.68), (0.18, 0.52), (0.38, 0.37), (0.62, 0.17), (0.97, 0.03), (0.97, 0.34), (0.78, 0.46), (0.58, 0.64), (0.36, 0.76), (0.16, 0.92)]],
    "ch2_s3_forest_ambush": [[(0.04, 0.92), (0.05, 0.66), (0.23, 0.48), (0.42, 0.25), (0.84, 0.17), (0.96, 0.34), (0.83, 0.62), (0.96, 0.90)]],
    "ch2_s4_lingyue_gate": [[(0.02, 0.96), (0.02, 0.74), (0.22, 0.60), (0.43, 0.45), (0.64, 0.30), (0.82, 0.10), (0.98, 0.02), (0.98, 0.27), (0.82, 0.42), (0.61, 0.58), (0.40, 0.72), (0.20, 0.90)]],
    "ch2_s5_bandit_cave": [[(0.18, 0.86), (0.16, 0.38), (0.30, 0.20), (0.70, 0.20), (0.84, 0.38), (0.82, 0.88)]],
    "ch2_s6_river_camp": [[(0.03, 0.94), (0.04, 0.66), (0.25, 0.53), (0.45, 0.40), (0.64, 0.27), (0.96, 0.05), (0.97, 0.36), (0.76, 0.50), (0.55, 0.65), (0.32, 0.78), (0.14, 0.92)]],
    "ch3_s1_wulin_assembly": [[(0.06, 0.88), (0.10, 0.28), (0.24, 0.14), (0.86, 0.16), (0.94, 0.34), (0.92, 0.88)]],
    "ch3_s2_trial_ground": [[(0.06, 0.90), (0.08, 0.22), (0.20, 0.12), (0.88, 0.12), (0.95, 0.28), (0.94, 0.90)]],
    "ch3_s3_faction_training": [[(0.06, 0.90), (0.08, 0.22), (0.20, 0.12), (0.88, 0.12), (0.95, 0.28), (0.94, 0.90)]],
    "ch3_s4_forbidden_tomb": [[(0.18, 0.88), (0.17, 0.29), (0.29, 0.18), (0.72, 0.18), (0.83, 0.30), (0.82, 0.89)]],
    "ch4_s1_luoyang_yamen": [[(0.05, 0.92), (0.06, 0.31), (0.18, 0.18), (0.90, 0.18), (0.96, 0.32), (0.95, 0.92)]],
    "ch4_s2_canal_docks": [[(0.03, 0.95), (0.03, 0.14), (0.16, 0.07), (0.78, 0.04), (0.77, 0.18), (0.70, 0.29), (0.65, 0.48), (0.66, 0.66), (0.74, 0.95)]],
    "ch4_s3_luoyang_market": [[(0.04, 0.93), (0.05, 0.20), (0.17, 0.11), (0.91, 0.12), (0.97, 0.25), (0.96, 0.92)]],
    "ch4_s4_ancient_temple": [[(0.04, 0.92), (0.05, 0.28), (0.18, 0.14), (0.86, 0.12), (0.96, 0.29), (0.95, 0.92)]],
    "ch4_s5_temple_tunnel": [[(0.18, 0.88), (0.17, 0.29), (0.29, 0.18), (0.72, 0.18), (0.83, 0.30), (0.82, 0.89)]],
}


def packed(points: list[tuple[float, float]]) -> str:
    values = ", ".join(f"{x:.4f}, {y:.4f}" for x, y in points)
    return f"\tPackedVector2Array({values})"


def layout_text(regions: list[list[tuple[float, float]]]) -> str:
    probes: list[tuple[float, float]] = []
    for polygon in regions:
        probes.append((sum(x for x, _ in polygon) / len(polygon), sum(y for _, y in polygon) / len(polygon)))
    return f'''[gd_resource type="Resource" script_class="WalkableMapLayout" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/domain/walkable_map_layout.gd" id="1_layout"]

[resource]
script = ExtResource("1_layout")
schema_version = 3
design_size = Vector2i(1536, 1024)
display_at_native_size = false
walkable_regions = Array[PackedVector2Array]([\n{',\n'.join(packed(region) for region in regions)}\n])
visual_objects = []
occluders = []
actor_fade_zones = []
blockers = []
interactions = []
portals = []
walkable_probes = [\n{',\n'.join(f'\t{{"id":"route_{index}", "pos":Vector2({x:.4f}, {y:.4f})}}' for index, (x, y) in enumerate(probes))}\n]
blocked_probes = [
\t{{"id":"top_left_margin", "pos":Vector2(0.01, 0.01)}},
\t{{"id":"top_right_margin", "pos":Vector2(0.99, 0.01)}}
]
'''


def attach_layout(scene_path: Path, layout_path: Path) -> None:
    text = scene_path.read_text(encoding="utf-8")
    if "map_layout = ExtResource" in text:
        return
    text = re.sub(
        r'\[gd_resource([^\]]*?)load_steps=(\d+)([^\]]*?)\]',
        lambda match: f'[gd_resource{match.group(1)}load_steps={int(match.group(2)) + 1}{match.group(3)}]',
        text,
        count=1,
    )
    ext_line = f'[ext_resource type="Resource" path="res://data/maps/{layout_path.name}" id="99_layout"]\n'
    last_ext = list(re.finditer(r'^\[ext_resource[^\n]*\]\n?', text, re.MULTILINE))
    insert_at = last_ext[-1].end() if last_ext else text.index("[resource]")
    text = text[:insert_at] + ext_line + text[insert_at:]
    text = text.replace("is_walkable = true\n", 'is_walkable = true\nmap_layout = ExtResource("99_layout")\n', 1)
    scene_path.write_text(text, encoding="utf-8", newline="\n")


def main() -> None:
    for scene_id, regions in REGIONS.items():
        layout_path = MAP_DIR / f"{scene_id}_layout_v1.tres"
        layout_path.write_text(layout_text(regions), encoding="utf-8", newline="\n")
        attach_layout(SCENE_DIR / f"{scene_id}.tres", layout_path)
        print(scene_id)


if __name__ == "__main__":
    main()
