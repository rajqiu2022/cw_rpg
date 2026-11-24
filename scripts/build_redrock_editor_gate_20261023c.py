"""Build an isolated, native-node Redrock gate scene, then publish explicit new files.

No image editing, shared project mutation, or production-wide import is performed.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "assets/staging/redrock_editor_gate_20261023c"
PROJECT = STAGE / "validation_project"
NAMESPACE = "redrock_gate_20261023c"
SCENE = f"scenes/drafts/{NAMESPACE}/redrock_gate.tscn"
SCRIPT = f"scripts/drafts/{NAMESPACE}/gate_preview.gd"
SHADER = f"art/modules/{NAMESPACE}/ground_blend.gdshader"
ART = f"art/modules/{NAMESPACE}"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def protected() -> list[Path]:
    paths = [ROOT / "game/project.godot", ROOT / "prompts/tasks.yaml"]
    paths += list((ROOT / "game/scripts/autoload").glob("*.gd"))
    paths += list((ROOT / "game/scripts/field").glob("*.gd"))
    for folder in ("assets/raw/redrock_gate_resources_20261023a", "assets/raw/redrock_ground_resources_20261023b", "assets/processed/redrock_gate_20261023b"):
        paths += list((ROOT / folder).rglob("*.png"))
    user_dir = Path(os.environ["APPDATA"]) / "Godot/app_userdata/云影侠传"
    paths += [p for p in user_dir.rglob("save*") if p.is_file()]
    return sorted(set(paths))


def snapshot() -> list[dict]:
    return [{"path": str(p), "sha256": sha(p), "bytes": p.stat().st_size, "mtime_ns": p.stat().st_mtime_ns} for p in protected()]


def build() -> None:
    if PROJECT.exists():
        raise SystemExit("Refusing to overwrite existing validation project")
    save(STAGE / "protected-before.json", snapshot())
    pack = json.loads((ROOT / "assets/processed/redrock_gate_20261023b/resource-pack.json").read_text(encoding="utf-8"))
    wanted = {"gate_opening", "tower", "front_wall", "side_wall", "cargo", "trough", "guard_idle"}
    sources = {r["key"]: ROOT / r["output"] for r in pack["assets"] if r["key"] in wanted}
    sources.update(earth=ROOT / "assets/raw/redrock_ground_resources_20261023b/ground/redrock_20261023b_earth_v1.png", rock=ROOT / "assets/raw/redrock_ground_resources_20261023b/ground/redrock_20261023b_rock_v1.png")
    media = []
    for key, source in sources.items():
        relative = f"{ART}/{key}.png"
        dest = PROJECT / relative
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, dest)
        media.append({"key": key, "source": str(source.relative_to(ROOT)).replace("\\", "/"), "destination": relative, "sha256": sha(source), "pixel_edits": 0})
    (PROJECT / "project.godot").write_text('config_version=5\n[application]\nconfig/name="赤岩峡口隔离核验"\nrun/main_scene="res://' + SCENE + '"\nconfig/features=PackedStringArray("4.6", "GL Compatibility")\n[display]\nwindow/size/viewport_width=1920\nwindow/size/viewport_height=1080\nwindow/stretch/mode="canvas_items"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\ntextures/default_filters/use_nearest_mipmap_filter=false\n', encoding="utf-8")
    build_scene()
    save(STAGE / "manifest.json", {"status": "BUILT_FOR_ISOLATED_VALIDATION", "scene": SCENE, "script": SCRIPT, "shader": SHADER, "media": media, "formal_world_entry": False, "world_size": [2560, 1760], "adult_height": 112, "body_size": [35, 25], "gate_uniform_pixel_scale": .86, "gate_original_canvas_origin": [601.46, 320], "gate_padding_compensated": True, "walk_animation_enabled": False})


def build_scene() -> None:
    review = STAGE / "design-review.json"
    if review.exists() and json.loads(review.read_text(encoding="utf-8")).get("continue_layout") is False:
        raise SystemExit("User rejected this assembly. Do not regenerate it as a current design.")
    lines = ['[gd_scene load_steps=15 format=3]', '']
    for key in ("gate_opening", "tower", "front_wall", "side_wall", "cargo", "trough", "guard_idle", "earth", "rock"):
        lines += [f'[ext_resource type="Texture2D" path="res://{ART}/{key}.png" id="{key}"]']
    lines += [f'[ext_resource type="Script" path="res://{SCRIPT}" id="script"]', f'[ext_resource type="Shader" path="res://{SHADER}" id="shader"]', '']
    lines += ['[sub_resource type="ShaderMaterial" id="ground_mat"]', 'shader = ExtResource("shader")', 'shader_parameter/earth_tex = ExtResource("earth")', 'shader_parameter/rock_tex = ExtResource("rock")', '']
    lines += ['[sub_resource type="RectangleShape2D" id="body_shape"]', 'size = Vector2(35, 25)', '']
    lines += ['[sub_resource type="SystemFont" id="font"]', 'font_names = PackedStringArray("Microsoft YaHei", "Noto Sans CJK SC")', '']
    lines += ['[node name="RedrockGateDraft" type="Node2D"]', 'script = ExtResource("script")', 'metadata/status = "首分区编辑草案；尚未接入正式世界"', 'metadata/source_design = "assets/raw/sect_western_map_designs_20261022d/redrock_masterplan_overview_v1.png"', '']
    lines += ['[node name="Ground" type="ColorRect" parent="."]', 'material = SubResource("ground_mat")', 'offset_right = 2560.0', 'offset_bottom = 1760.0', 'mouse_filter = 2', '']
    lines += ['[node name="Depth" type="Node2D" parent="."]', 'y_sort_enabled = true', '']

    placements = []
    def sprite(name: str, key: str, origin: tuple[float, float], scale: float, pad: tuple[int, int], foot_y: float, solid: list[tuple[float, float]] | None = None, x: float = 0) -> None:
        lines.extend([f'[node name="{name}" type="Node2D" parent="Depth"]', f'position = Vector2({x}, {foot_y})', f'metadata/asset_key = "{key}"', f'metadata/original_canvas_origin = Vector2({origin[0]}, {origin[1]})', f'metadata/source_pixel_scale = {scale}', ''])
        px, py = origin[0] - pad[0] * scale - x, origin[1] - pad[1] * scale - foot_y
        lines.extend([f'[node name="Art" type="Sprite2D" parent="Depth/{name}"]', f'position = Vector2({px}, {py})', f'scale = Vector2({scale}, {scale})', f'texture = ExtResource("{key}")', 'centered = false', ''])
        if solid:
            lines.extend([f'[node name="Solid" type="StaticBody2D" parent="Depth/{name}"]', 'collision_layer = 1', 'collision_mask = 0', '', f'[node name="Footprint" type="CollisionPolygon2D" parent="Depth/{name}/Solid"]', 'polygon = PackedVector2Array(' + ', '.join(f'{a-x}, {b-foot_y}' for a, b in solid) + ')', ''])
        placements.append({"node": name, "asset": key, "source_origin": origin, "padding": pad, "scale": scale, "sort_foot": [x, foot_y], "solid_world": solid})

    # Thick front walls connect behind the gate piers; side wall is a true perspective asset.
    sprite("WestWall", "front_wall", (-160, 752), .45, (311, 104), 1000, [(0, 966), (1100, 966), (1100, 1004), (0, 1004)])
    sprite("EastWall", "front_wall", (1730, 752), .45, (311, 104), 1000, [(1460, 966), (2560, 966), (2560, 1004), (1460, 1004)])
    sprite("Watchtower", "tower", (20, 30), .60, (175, 184), 742, [(76, 564), (625, 601), (721, 742), (61, 703)])
    sprite("Gate", "gate_opening", (601.46, 320), .86, (227, 142), 1030)
    # Two independent piers: the opening remains an actual physical gap.
    for name, pts in {"GateWestPier": [(730, 920), (1100, 920), (1100, 1030), (710, 1030)], "GateEastPier": [(1460, 920), (1830, 920), (1850, 1030), (1460, 1030)]}.items():
        lines.extend([f'[node name="{name}" type="StaticBody2D" parent="."]', 'collision_layer = 1', 'collision_mask = 0', '', f'[node name="Footprint" type="CollisionPolygon2D" parent="{name}"]', 'polygon = PackedVector2Array(' + ', '.join(f'{a}, {b}' for a, b in pts) + ')', ''])
    sprite("EastRetainingWall", "side_wall", (1855, 600), .44, (220, 147), 1017, [(1930, 740), (2445, 1008), (2461, 963), (1940, 703)])
    sprite("WaterTrough", "trough", (300, 1030), .36, (227, 142), 1315, [(378, 1260), (758, 1323), (815, 1273), (417, 1220)])
    sprite("CargoBales", "cargo", (1720, 1000), .37, (220, 147), 1303, [(1867, 1247), (2114, 1304), (2162, 1259), (1923, 1218)])
    # Adult height uses one shared pixel scale; there is no frame-specific fit.
    s = 112 / 958
    origin = (1020 - 625.5*s, 1180 - 1110*s)
    sprite("AnonymousGuard", "guard_idle", origin, s, (180, 180), 1180, [(1002, 1168), (1038, 1168), (1038, 1193), (1002, 1193)], x=1020)

    lines += ['[node name="SurveyActor" type="CharacterBody2D" parent="Depth"]', 'position = Vector2(680, 1510)', 'collision_layer = 2', 'collision_mask = 1', 'motion_mode = 1', 'metadata/purpose = "尺度与通行检查；非正式玩家角色"', '']
    lines += ['[node name="Body" type="CollisionShape2D" parent="Depth/SurveyActor"]', 'shape = SubResource("body_shape")', '']
    # Reuse the same approved idle at exactly 112px, clearly labelled as a survey double.
    lines += ['[node name="Art" type="Sprite2D" parent="Depth/SurveyActor"]', f'position = Vector2({-805.5*s}, {-1290*s})', f'scale = Vector2({s}, {s})', 'texture = ExtResource("guard_idle")', 'centered = false', '']
    lines += ['[node name="Bounds" type="StaticBody2D" parent="."]', 'collision_layer = 1', 'collision_mask = 0', '']
    for name, pts in {"West": [(0, 0), (32, 0), (32, 1760), (0, 1760)], "East": [(2528, 0), (2560, 0), (2560, 1760), (2528, 1760)], "North": [(0, 0), (2560, 0), (2560, 32), (0, 32)], "South": [(0, 1728), (2560, 1728), (2560, 1760), (0, 1760)]}.items():
        lines += [f'[node name="{name}" type="CollisionPolygon2D" parent="Bounds"]', 'polygon = PackedVector2Array(' + ', '.join(f'{a}, {b}' for a, b in pts) + ')', '']
    lines += ['[node name="Camera" type="Camera2D" parent="."]', 'position = Vector2(1280, 880)', 'zoom = Vector2(0.58, 0.58)', '']
    lines += ['[node name="Notes" type="CanvasLayer" parent="."]', '']
    for name, text, pos, size in (("Title", "赤岩关镇 · 峡口关门", (34, 24), 28), ("Status", "首分区编辑草案 · 关防 / 饮水 / 候检", (35, 65), 17), ("Controls", "WASD / 方向键 移动   Tab 全景 / 跟随   R 回起点   F1 制作标记", (35, 1010), 19), ("Limits", "待补：峡壁立面、后接层台、阶街建筑；行走序列尚未接入", (35, 1042), 16)):
        lines += [f'[node name="{name}" type="Label" parent="Notes"]', f'offset_left = {pos[0]}.0', f'offset_top = {pos[1]}.0', 'theme_override_colors/font_color = Color(1, 0.92, 0.75, 1)', 'theme_override_colors/font_shadow_color = Color(0.12, 0.065, 0.035, 1)', 'theme_override_constants/shadow_offset_x = 2', 'theme_override_constants/shadow_offset_y = 2', 'theme_override_fonts/font = SubResource("font")', f'theme_override_font_sizes/font_size = {size}', f'text = "{text}"', '']
    labels = [("NorthInterface", "后续层台接口（未连接）", (2070, 255)), ("TowerLabel", "平顶岗楼 · 门前保留", (265, 760)), ("WaterLabel", "商队饮水", (460, 1360)), ("CargoLabel", "候检货位", (1930, 1340)), ("ActorLabel", "尺度检查员", (620, 1532))]
    lines += ['[node name="MakingNotes" type="Node2D" parent="."]', '']
    for name, text, pos in labels:
        lines += [f'[node name="{name}" type="Label" parent="MakingNotes"]', f'offset_left = {pos[0]}.0', f'offset_top = {pos[1]}.0', 'theme_override_fonts/font = SubResource("font")', 'theme_override_colors/font_color = Color(1, 0.9, 0.67, 1)', 'theme_override_colors/font_shadow_color = Color(0.1, 0.04, 0.02, 1)', 'theme_override_constants/shadow_offset_x = 2', 'theme_override_constants/shadow_offset_y = 2', 'theme_override_font_sizes/font_size = 24', f'text = "{text}"', '']
    out = PROJECT / SCENE
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text('\n'.join(lines), encoding="utf-8")
    save(STAGE / "placements.json", placements)


def publish() -> None:
    receipt = STAGE / "publication.json"
    if receipt.exists():
        raise SystemExit("Refusing duplicate publication")
    report = json.loads((PROJECT / "artifacts_verified/verification.json").read_text(encoding="utf-8"))
    if not report.get("passed"):
        raise SystemExit("Native verification must pass before publication")
    media = json.loads((STAGE / "manifest.json").read_text(encoding="utf-8"))["media"]
    # Import only the exact NEW leaves validated in the isolated project. Paths
    # are identical res:// paths, so the ctex leaf names are identical too.
    imports = [r["destination"] + ".import" for r in media]
    keys = {r["key"] + ".png-" for r in media}
    cache = [str(p.relative_to(PROJECT)).replace("\\", "/") for p in (PROJECT / ".godot/imported").iterdir() if p.suffix in (".ctex", ".md5") and any(p.name.startswith(key) for key in keys)]
    if len(cache) != 18:
        raise SystemExit("Expected exactly 18 new ctex/md5 cache leaves")
    files = cache + imports + [SCRIPT, SCRIPT + ".uid", SHADER, SHADER + ".uid"] + [r["destination"] for r in media] + [SCENE]
    for rel in files:
        if (ROOT / "game" / rel).exists():
            raise SystemExit(f"Refusing to replace existing game file: {rel}")
    rows = []
    for rel in files:
        src, dst = PROJECT / rel, ROOT / "game" / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
        rows.append({"path": f"game/{rel}", "sha256": sha(dst), "identical_to_validated": sha(src) == sha(dst)})
    save(receipt, {"status": "NEW_EDITOR_DRAFT_FILES_ONLY", "files": rows, "scene": SCENE, "formal_entry": False, "production_import_invoked": False, "new_import_leaves_promoted": 27, "editor_open_command_sent": False})


def configure_imports() -> None:
    """Change only isolated importer parameters, retaining the PNG bytes."""
    changes = []
    for p in (PROJECT / ART).glob("*.png.import"):
        old = p.read_text(encoding="utf-8")
        new = old.replace("process/fix_alpha_border=true", "process/fix_alpha_border=false").replace("detect_3d/compress_to=1", "detect_3d/compress_to=0")
        p.write_text(new, encoding="utf-8")
        changes.append({"path": str(p.relative_to(PROJECT)), "before_text": old, "after_text": new})
    save(STAGE / "import-parameter-changes.json", changes)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("action", choices=("build", "publish", "configure-imports", "protect-after"))
    args = parser.parse_args()
    if args.action == "build":
        build()
    elif args.action == "publish":
        publish()
    elif args.action == "configure-imports":
        configure_imports()
    else:
        before = json.loads((STAGE / "protected-before.json").read_text(encoding="utf-8"))
        after = snapshot()
        baseline = {r["path"]: r for r in before}
        changed = [{"before": baseline[r["path"]], "after": r} for r in after if r["path"] in baseline and r != baseline[r["path"]]]
        save(STAGE / "protected-after.json", {"files": after, "changed": changed, "new_protected_paths": [r for r in after if r["path"] not in baseline]})
        print(f"protected={len(before)} changed={len(changed)}")
