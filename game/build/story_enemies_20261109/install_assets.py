import json
import math
import re
import shutil
from pathlib import Path

import numpy as np
from PIL import Image

work = Path("game/build/story_enemies_20261109")
art = Path("art/characters/story_enemies_20261109")
raw = Path("assets/raw/story_enemies_20261109")
sources = json.loads((work / "adopt.json").read_text(encoding="utf-8"))
map_actors = {
    "bandit_cave_guard": ("interior_bandit_cave", "interior_bandit_cave_guard", 132),
    "openworld_yanmen_cave_guard": ("openworld_yanmen_hidden_cave", "openworld_yanmen_cave_guard", 144),
}

def install(source, relative, archive):
    for output in (raw / archive, Path("game") / relative, work / "import_project" / relative):
        output.parent.mkdir(parents=True, exist_ok=True)
        if not output.exists() or output.read_bytes() != Path(source).read_bytes():
            shutil.copyfile(source, output)

def read(path):
    return path.read_bytes().decode("utf-8").replace("\r\n", "\n")

def write(path, content):
    original = path.read_bytes() if path.exists() else b""
    payload = content.replace("\n", "\r\n").encode("utf-8") if b"\r\n" in original else content.encode("utf-8")
    if original != payload:
        path.write_bytes(payload)

def boxes(source, dividers):
    a = np.asarray(Image.open(source).convert("RGBA"))[:, :, 3]
    h, w = a.shape
    edges = [0, *dividers, w]
    result = []
    for start, stop in zip(edges, edges[1:]):
        y, local_x = np.where(a[:, start:stop] >= 128)
        assert len(y) > 15000, (source, start, stop)
        x = local_x + start
        assert a[:, start:stop].mean() < 130, source
        bounds = (
            max(start, int(x.min()) - 3), max(0, int(y.min()) - 3),
            min(stop, int(x.max()) + 4), min(h, int(y.max()) + 4),
        )
        result.append((bounds, int(y.max()), int(y.min())))
    return result

def atlas(output, source, bounds, padding):
    x1,y1,x2,y2 = bounds
    left, top, full_w, full_h = padding
    width,height = x2-x1,y2-y1
    write(output, f'''[gd_resource type="AtlasTexture" load_steps=2 format=3]
[ext_resource type="Texture2D" path="res://{source.as_posix()}" id="1"]
[resource]
atlas = ExtResource("1")
region = Rect2({x1}, {y1}, {width}, {height})
margin = Rect2({left}, {top}, {full_w-width}, {full_h-height})
filter_clip = true
''')

rows = []
for enemy, spec in sources.items():
    if enemy == "bed":
        install(spec, Path("art/modules/story_enemies_20261109/cave_adult_bed.png"), Path("cave_adult_bed.png"))
        continue
    folder = art / enemy
    target = Path("game") / folder
    by_action = {}
    for action, options in spec.items():
        source = options[0]
        install(source, folder / (action+".png"), Path(enemy) / (action+".png"))
        if action == "portrait":
            continue
        dividers = options[1] if len(options) > 1 else [543, 1086, 1629]
        by_action[action] = boxes(source, dividers)

    for action, frames in by_action.items():
        # A lowered knee or a fallen pose stays at the standing scale of its strip.
        heights = [floor - top for _, floor, top in frames]
        reference = np.median(heights) if action != "reaction" else heights[0]
        full_h = 3 * math.ceil(max(reference / .79, max(heights) / .90) / 3)
        full_w = 4 * full_h // 3
        floor_y = round(full_h * .92)
        for idx, (bounds, floor, _) in enumerate(frames, 1):
            left, top, right, bottom = bounds
            if action == "reaction" and idx == 4:
                anchor = (left + right) / 2
            else:
                image = np.asarray(Image.open(spec[action][0]).convert("RGBA"))
                # The upper-body median excludes off-center weapons and wide stances.
                torso_y = round(top + (floor - top) * .30)
                _, core_x = np.where(image[torso_y:torso_y+24, left:right, 3] >= 128)
                anchor = left + (float(np.median(core_x)) if len(core_x) else (right - left) / 2)
            margin_x = min(full_w - (right - left), max(0, round(full_w/2 - (anchor - left))))
            margin_y = floor_y - (floor - top)
            atlas(target / f"{action}_{idx:02}.tres", folder / (action + ".png"), bounds, (margin_x, margin_y, full_w, full_h))

    if "portrait" in spec:
        portrait = f"res://{(folder / 'portrait.png').as_posix()}"
    else:
        (left, top, right, _), foot, _ = by_action["ready"][0]
        region = (left, top, right, top + round((foot-top)*.50))
        atlas(target / "portrait.tres", folder / "ready.png", region, (0, 0, region[2]-region[0], region[3]-region[1]))
        portrait = f"res://{(folder / 'portrait.tres').as_posix()}"

    def path(action, number):
        return f"res://{folder.as_posix()}/{action}_{number:02}.tres"

    moves = [("ready", 1), ("reaction", 1), ("ready", 2), ("reaction", 1)]
    hits = [("ready", 1), ("reaction", 2), ("reaction", 2), ("ready", 1)]
    defeats = [("reaction", 2), ("reaction", 3), ("reaction", 4), ("reaction", 4)]
    states = {"ready": [("ready", i) for i in range(1,5)], "move": moves,
              "attack": [("attack", i) for i in range(1,5)], "hit": hits, "defeat": defeats}
    definition = Path("game/data/enemies") / (enemy + ".tres")
    data = read(definition)
    replacements = {"portrait_path": json.dumps(portrait), "battle_actor_path": json.dumps(path("ready",1)),
                    "battle_actor_flip_h":"false"}
    for name, sequence in states.items():
        replacements[f"{name}_frame_paths"] = "PackedStringArray(" + ", ".join(json.dumps(path(action, i)) for action,i in sequence) + ")"
    for key, value in replacements.items():
        data, count = re.subn(rf"^{key} = .*$", lambda _: f"{key} = {value}", data, flags=re.M)
        assert count == 1, (enemy, key, count)
    write(definition, data)
    if enemy not in map_actors:
        continue

    scene_id, dialog_id, height = map_actors[enemy]
    png = f"res://{folder.as_posix()}/ready.png"
    scene = Path("game/data/scenes") / (scene_id+".tres")
    data = read(scene)
    lines = data.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if enemy not in line or '"sprite_path"' not in line:
            continue
        line = re.sub(r'("sprite_path":\s*)"[^"]+"', lambda m: m[1] + json.dumps(png), line)
        line = re.sub(r',\s*"portrait_path":\s*"[^"]+"', '', line)
        line = re.sub(r',\s*"conversation_base_facing":\s*"[^"]+"', '', line)
        lines[i] = line.replace("}", f', "portrait_path": "{portrait}", "conversation_base_facing": "left"'+"}", 1)
        break
    else:
        raise RuntimeError(scene)
    write(scene, "".join(lines))
    dialog = Path("game/data/dialogs") / (dialog_id+".tres")
    data = read(dialog)
    data = re.sub(r'^(speaker = "[^"]+"\n)(?:portrait_path = "[^"]+"\n)?',
                  lambda m: m[1] + f'portrait_path = "{portrait}"\n', data, count=1, flags=re.M)
    write(dialog, data)
    measurements = by_action["ready"]
    sole = int(np.median([floor for _,floor,_ in measurements]))
    visible_height = int(np.median([floor-top for _,floor,top in measurements]))
    rows.append(f'\t"{enemy}": {{"path": "{png}", "dialog": "{dialog_id}", "size": Vector2(2172, 724), "sole": {sole}, "visible_height": {visible_height}, "height": {height}}},')

write(Path("game") / art / "field_sheets.gd", "extends RefCounted\n\nconst FIELD := {\n" + "\n".join(rows) + "\n}\n")

