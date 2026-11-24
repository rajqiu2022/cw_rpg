"""Author a raw-image, import-free native assembly preview; no production mutation."""
import json
from pathlib import Path

from redrock_joint_trial_20261023e import ROOT, BASE, STAGE, save, sha

PROJECT = STAGE / "trial_project"


def build():
    if PROJECT.exists():
        raise SystemExit("Refusing to overwrite existing trial")
    PROJECT.mkdir(parents=True)
    pack = json.loads((BASE / "manifest.json").read_text(encoding="utf-8"))
    core_scale = 1.2
    left_scale = core_scale * 178 / 277
    right_scale = core_scale * 196 / 199
    core_origin = [1450, 500]
    left_target = [1450 + 69 * core_scale - 12, 500 + 622 * core_scale]
    right_target = [1450 + 1698 * core_scale - 16, 500 + 733 * core_scale]
    origins = {"core": core_origin, "left": [left_target[0] - 1330 * left_scale, left_target[1] - 876 * left_scale], "right": [right_target[0] - 79 * right_scale, right_target[1] - 714 * right_scale]}
    scales = {"core": core_scale, "left": left_scale, "right": right_scale}
    # Pixel coordinates are inspected candidate anchors, not a certified five-anchor contract.
    ports = {
        "left": {"core_foot": [69, 622], "core_walk_front": [69, 444], "wing_foot": [1330, 876], "wing_walk_front": [1330, 599], "front_lap_world": 12},
        "right": {"core_foot": [1698, 733], "core_walk_front": [1698, 537], "wing_foot": [79, 714], "wing_walk_front": [79, 515], "front_lap_world": 16},
    }
    rows = []
    for r in pack["assets"]:
        assert r.get("output")
        rows.append({"key": r["key"], "path": str(ROOT / r["output"]).replace("\\", "/"), "sha256": r["sha256"], "origin": origins[r["key"]], "pixel_scale": scales[r["key"]]})
    guard = ROOT / "assets/processed/redrock_gate_20261023b/guard_idle/redrock_20261023a_guard_idle_v1_padded.png"
    earth = ROOT / "assets/raw/redrock_ground_resources_20261023b/ground/redrock_20261023b_earth_v1.png"
    save(PROJECT / "sources.json", {"pieces": rows, "guard": str(guard).replace("\\", "/"), "earth": str(earth).replace("\\", "/")})
    save(STAGE / "interfaces.json", {"status": "TWO_ANCHOR_RAW_TRIAL_NOT_FIVE_ANCHOR_CERTIFIED", "pieces": rows, "ports": ports, "target_full_body": [35, 25], "adult_visual_height": 112, "no_rotation": True, "no_nonuniform_scale": True, "no_pixel_edits": True, "formal_admission": False})
    (PROJECT / "project.godot").write_text('config_version=5\n[application]\nconfig/name="赤岩关防接口隔离试拼"\nrun/main_scene="res://trial.tscn"\nconfig/features=PackedStringArray("4.6", "GL Compatibility")\n[display]\nwindow/size/viewport_width=1920\nwindow/size/viewport_height=1080\nwindow/stretch/mode="canvas_items"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\nenvironment/defaults/default_clear_color=Color(0.13, 0.15, 0.16, 1)\n', encoding="utf-8")
    scene = '''[gd_scene load_steps=5 format=3]

[ext_resource type="Script" path="res://trial.gd" id="1"]
[sub_resource type="RectangleShape2D" id="body"]
size = Vector2(35, 25)
[sub_resource type="SystemFont" id="font"]
font_names = PackedStringArray("Microsoft YaHei", "Noto Sans CJK SC")
[sub_resource type="StyleBoxFlat" id="panel"]
bg_color = Color(0.055, 0.07, 0.075, 0.90)

[node name="RedrockJointTrial" type="Node2D"]
script = ExtResource("1")
metadata/status = "三块原图接口试拼，不是完整城市；未正式导入"

[node name="Ground" type="Polygon2D" parent="."]
texture_repeat = 3

[node name="Structure" type="Node2D" parent="."]
[node name="LeftWing" type="Sprite2D" parent="Structure"]
centered = false
[node name="RightWing" type="Sprite2D" parent="Structure"]
centered = false
[node name="Core" type="Sprite2D" parent="Structure"]
centered = false

[node name="Collision" type="StaticBody2D" parent="."]
collision_layer = 1
collision_mask = 0

[node name="SurveyActor" type="CharacterBody2D" parent="."]
position = Vector2(2650, 1930)
collision_layer = 2
collision_mask = 1
motion_mode = 1
[node name="Foot" type="CollisionShape2D" parent="SurveyActor"]
shape = SubResource("body")
[node name="Art" type="Sprite2D" parent="SurveyActor"]
centered = false

[node name="Camera" type="Camera2D" parent="."]
position = Vector2(2800, 1250)
zoom = Vector2(0.37, 0.37)

[node name="UI" type="CanvasLayer" parent="."]
[node name="Backing" type="Panel" parent="UI"]
offset_right = 1920.0
offset_bottom = 108.0
theme_override_styles/panel = SubResource("panel")
[node name="Title" type="Label" parent="UI"]
offset_left = 32.0
offset_top = 18.0
theme_override_fonts/font = SubResource("font")
theme_override_font_sizes/font_size = 28
text = "赤岩关防 · 三块结构试拼"
[node name="Subtitle" type="Label" parent="UI"]
offset_left = 34.0
offset_top = 61.0
theme_override_fonts/font = SubResource("font")
theme_override_font_sizes/font_size = 18
text = "左墙翼接岩肩 → 连体关楼核心 → 右转墙翼接岩肩　｜　原生PNG未裁切，非完整城市场景"
[node name="Hint" type="Label" parent="UI"]
offset_left = 34.0
offset_top = 1028.0
theme_override_fonts/font = SubResource("font")
theme_override_font_sizes/font_size = 19
text = "WASD移动　Tab全景/跟随　1左接缝　2右接缝　3门洞　R回起点　｜　透明边距/完整接口仍待适配"
'''
    (PROJECT / "trial.tscn").write_text(scene, encoding="utf-8")


if __name__ == "__main__":
    build()
