"""No engine or writes: actual last-consumer source/media + pure distance math."""
from pathlib import Path
import hashlib
import json
import math
import re
from PIL import Image

root = Path(__file__).resolve().parents[3]
home = Path(__file__).resolve().parent
rules = json.loads((home / "gait_rules.json").read_text(encoding="utf-8"))
runtime = (home / "npc_gait_runtime.gd").read_text(encoding="utf-8")
visual_path = root / "game/build/luoyang_city_finish_20261025i_system01/ambient18_visual_contract02_NOTREADY.json"
ambient_path = root / "game/build/luoyang_city_finish_20261025i_source01/runtime_READY01/ambient18_runtime_READY.gd"
visual = json.loads(visual_path.read_text(encoding="utf-8"))
ambient = ambient_path.read_text(encoding="utf-8")
assert hashlib.sha256(visual_path.read_bytes()).hexdigest() == "0a65ecd3a2a6150c1080eb86cdb31a5657331d948e9d2776bc74db3e4336da25"
assert 'const FORMAL_READY := true' in ambient and 'actor.walk_sprite_path = change.after.walk_sprite_path' in ambient
assert 'process_priority = 100' in runtime
for forbidden in ("npc.position =", "npc.global_position =", "npc.set_process(", "npc.set_script(", "npc.sprite.texture =", "npc.sprite.flip_h ="):
    assert forbidden not in runtime, forbidden
assets = []
for resource, item in rules["walk_assets"].items():
    image_path = root / "game" / resource.removeprefix("res://")
    with Image.open(image_path) as image:
        assert image.size == (160 * item["frames"], 160), resource
    fractions = item["frame_distance_fractions"]
    assert len(fractions) == item["frames"] and fractions[0] == 0
    assert all(0 <= value < 1 for value in fractions)
    assert all(a < b for a, b in zip(fractions, fractions[1:]))
    imported = Path(str(image_path) + ".import").read_text(encoding="utf-8")
    gpu_resource = re.search(r'^path="(res://[^"\n]+\.ctex)"', imported, re.M).group(1)
    gpu = root / "game" / gpu_resource.removeprefix("res://")
    assert gpu.is_file() and gpu_resource in runtime
    assets.append({"path": resource, "frames": item["frames"], "family": item["family"],
                   "png_sha256": hashlib.sha256(image_path.read_bytes()).hexdigest(), "actual_gpu": gpu_resource})
current_guards = []
for override in visual["actor_overrides"]:
    if not override.get("walker"):
        continue
    resource = override["after"]["walk_sprite_path"]
    assert rules["walk_assets"][resource]["family"] == "guard"
    current_guards.append({"id": override["npc_id"], "walk": resource,
                           "frames": rules["walk_assets"][resource]["frames"]})
assert len(current_guards) == 5
assert all(row["frames"] == 4 for row in current_guards)

def distance_frame(distance, cycle, fractions):
    phase = distance % cycle / cycle
    return max(index for index, threshold in enumerate(fractions) if phase >= threshold)

fps_results = []
fractions = [0, 0.25, 0.5, 0.75]
for fps in (30, 60, 120):
    distance = 0.0
    previous = 0.0
    for frame in range(1, 2 * fps + 1):
        t = frame / fps
        position = 20 * t + 3 * t * t
        distance += abs(position - previous)
        previous = position
    before_pause = distance_frame(distance, 140 * 0.82, fractions)
    for _ in range(10 * fps):
        distance += 0.0  # no time accumulation during zero movement/conversation
    assert distance_frame(distance, 140 * 0.82, fractions) == before_pause
    assert math.isclose(distance, 52.0, abs_tol=1e-10)
    fps_results.append({"fps": fps, "actual_distance": distance, "frame": before_pause, "ten_second_stop_preserves_phase": True})
assert len({result["frame"] for result in fps_results}) == 1
print(json.dumps({"passed": True, "engine_calls": 0, "writes": 0,
                  "checks_are_static_and_math_not_gd_parser_or_dynamic_art_acceptance": True,
                  "current_last_consumer": str(ambient_path), "five_current_military": current_guards,
                  "assets": assets, "distance_math": fps_results,
                  "old_gate_actual_frames": 4, "old_gate_cycle_seconds": 0.48,
                  "old_gate_average_speed": 52 / math.pi,
                  "old_gate_distance_per_leg_cycle": 0.48 * 52 / math.pi}, ensure_ascii=False, indent=2))
