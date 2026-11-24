"""Mechanical two-scene scale/body derivation. New candidates only, no engine."""
from pathlib import Path
import hashlib
import json
import math
import re

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).parent
RES = "res://build/linxi_building_scale_20261030h_system01/"
LAYOUT_BASE = "game/art/modules/four_settlements_20261030e/"
SCENE_BASE = "game/scenes/drafts/four_settlements_20261030e/"
LOC = "game/build/four_settlements_20261030e_system01/locations.json"
LOC_GD = "game/build/four_settlements_20261030e_system01/locations.gd"
KEYS = ["linxi_center", "linxi_south"]
FILES = [LOC, LOC_GD, "game/build/three_towns_world_20261029j_system01/native_sources.json", "game/build/three_towns_world_20261029j_system01/town_registry.gd"]
FILES += [prefix + key + suffix for key in KEYS for prefix, suffix in [(SCENE_BASE, ".tscn"), (LAYOUT_BASE, ".json"), (LAYOUT_BASE, "_ground.gdshader")]]
FILES += ["game/build/linxi_scale_access_20261030f_system01/" + name for name in ["linxi_master.tscn", "linxi_master.json", "linxi_master_ground.gdshader", "restore.gd"]]


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


before = {key: {"sha256": sha(ROOT / key), "bytes": (ROOT / key).stat().st_size,
                "mtime_ns": str((ROOT / key).stat().st_mtime_ns)} for key in FILES}
if (HERE / "source_before.json").exists():
    assert json.loads((HERE / "source_before.json").read_text(encoding="utf-8")) == before
else:
    dump(HERE / "source_before.json", before)
    for key in FILES:
        output = HERE / "before" / key
        output.parent.mkdir(parents=True, exist_ok=True)
        output.write_bytes((ROOT / key).read_bytes())

# Existing complete images, identical native pixel anchors as the accepted30f
# office/small home. Doors are manually identified source windows, not alpha bboxes.
MEDIA = {
    "small_home": {"bbox": [548, 327, 1491, 974], "pivot": [1019.5, 974], "door_dx": 14.5, "door_height": 236, "scale": .64, "depth": 120},
    "office": {"bbox": [22, 239, 1515, 783], "pivot": [768.5, 783], "door_dx": 180, "door_height": 208, "scale": .72, "depth": 170},
    "warehouse": {"bbox": [68, 178, 1483, 845], "pivot": [775.5, 845], "door_dx": -85.5, "door_height": 239, "scale": .62, "depth": 155},
    "repair_shed": {"bbox": [226, 235, 1699, 974], "pivot": [962.5, 974], "door_dx": 390, "door_height": 305, "scale": .50, "depth": 120},
    "inn": {"bbox": [48, 88, 986, 910], "pivot": [517, 910], "door_dx": 53, "door_height": 155, "scale": .94, "depth": 185},
}
FUNCTIONS = {
    "linxi_center": {"School": "linxi_scholar_house", "FarmerHome": "linxi_farmer_cottage", "HerbHome": "linxi_herbal_home"},
    "linxi_south": {"VillagerHome": "linxi_south_villager_home", "SouthSchool": "linxi_south_scholar_house", "Apothecary": "linxi_south_apothecary_home"},
}
# Nonfunctional adjacent bodies must move only where the corrected real shell
# would intersect a neighbour/NPC/root or cut the already-existing circulation.
MOVES = {
    "linxi_center": {"HouseA": [2540, 700], "BackHouse0": [850, 900], "BackHouse1": [650, 500],
                     "Tavern": [770, 2180], "Grove1": [1050, 350], "Jars4": [970, 2235], "Bench4": [620, 2235], "BackHouse2": [2120, 2490]},
    "linxi_south": {"Home0": [1050, 2050], "Home3": [3260, 2180], "Home4": [3100, 1750],
                    "BackHouse0": [1350, 1150], "BackHouse1": [2480, 1100], "BackHouse2": [3750, 1180], "Jars7": [3450, 1785]},
}


def fmt(value):
    return f"{float(value):.14g}"


def vec(value):
    return "Vector2(" + ", ".join(fmt(n) for n in value) + ")"


def poly(points):
    return "PackedVector2Array(" + ", ".join(fmt(n) for p in points for n in p) + ")"


def field(block, name, value):
    pattern = r"^" + re.escape(name) + r" = [^\n]*"
    if re.search(pattern, block, re.M):
        return re.sub(pattern, name + " = " + value, block, count=1, flags=re.M)
    return block.rstrip() + "\n" + name + " = " + value + "\n\n"


facts = {}
locations = json.loads((ROOT / LOC).read_text(encoding="utf-8"))
old_locations = json.loads((ROOT / LOC).read_text(encoding="utf-8"))
for key in KEYS:
    data = json.loads((ROOT / (LAYOUT_BASE + key + ".json")).read_text(encoding="utf-8"))
    old = json.loads((ROOT / (LAYOUT_BASE + key + ".json")).read_text(encoding="utf-8"))
    changed = {}
    for row in data["objects"]:
        name = row["name"]
        if row["key"] == "cottage":
            row["key"] = "small_home"
        if row["key"] in MEDIA:
            spec = MEDIA[row["key"]]
            row.update(scale=spec["scale"], width=(spec["bbox"][2]-spec["bbox"][0])*spec["scale"],
                       height=(spec["bbox"][3]-spec["bbox"][1])*spec["scale"])
            if name in FUNCTIONS[key]:
                door = data["business"]["portal_targets"][FUNCTIONS[key][name]]
                row["foot"] = [door[0] - spec["door_dx"]*spec["scale"], door[1] - 38]
            elif name in MOVES[key]:
                row["foot"] = MOVES[key][name]
            width = row["width"] * .84
            for blocker in data["blockers"]:
                if blocker["path"] == "Town/" + name + "/Body":
                    blocker["polygon"] = [[-width/2, -spec["depth"]], [width/2, -spec["depth"]], [width/2, 0], [-width/2, 0]]
            changed[name] = {**row, "depth": spec["depth"], "door_height_px": spec["door_height"]*spec["scale"],
                             "body_story_note": "two storeys, approximately3 adult heights per storey" if row["key"] == "inn" else "one storey"}
        elif name in MOVES[key]:
            row["foot"] = MOVES[key][name]
    assert data["business"] == old["business"]
    # Native three data arrays other than objects/blockers remain exact: no
    # topology/ground planning expansion is hidden in this scale correction.
    assert {k:v for k,v in data.items() if k not in ["objects", "blockers"]} == {k:v for k,v in old.items() if k not in ["objects", "blockers"]}
    parts = re.split(r"(?=^\[node )", (ROOT / (SCENE_BASE + key + ".tscn")).read_text(encoding="utf-8"), flags=re.M)
    positions = {r["name"]:r["foot"] for r in data["objects"]}
    for index, block in enumerate(parts):
        header = re.match(r'\[node name="([^"]+)"[^\n]*\]', block)
        if not header:
            continue
        name = header[1]
        parent_match = re.search(r'parent="([^"]+)"', header[0])
        parent = parent_match[1] if parent_match else ""
        if parent == "Town" and (name in changed or name in MOVES[key]):
            block = field(block, "position", vec(positions[name]))
            block = field(block, "z_index", str(math.floor(positions[name][1]/4+.5)))
            if name in changed:
                row = changed[name]
                block = field(block, "metadata/visual_rect", f'Rect2({fmt(-row["width"]/2)}, {fmt(-row["height"])}, {fmt(row["width"])}, {fmt(row["height"])})')
        elif name == "Art" and parent.startswith("Town/") and parent.split("/")[1] in changed:
            row = changed[parent.split("/")[1]]
            spec = MEDIA[row["key"]]
            block = field(block, "position", vec([-v*row["scale"] for v in spec["pivot"]]))
            block = field(block, "scale", vec([row["scale"]]*2))
            block = field(block, "texture", f'ExtResource("{row["key"]}")')
        elif name == "Shape" and parent.startswith("Town/") and parent.endswith("/Body") and parent.split("/")[1] in changed:
            path = parent
            blocker = next(r for r in data["blockers"] if r["path"] == path)
            block = field(block, "polygon", poly(blocker["polygon"]))
        parts[index] = block
    scene = "".join(parts)
    scene = scene.replace("res://art/modules/four_settlements_20261030e/" + key + ".json", RES + key + ".json")
    scene = scene.replace("res://art/modules/four_settlements_20261030e/" + key + "_ground.gdshader", RES + key + "_ground.gdshader")
    scene = re.sub(r'^(\[gd_scene[^\]]*) uid="[^"]+"', r"\1", scene, count=1)
    (HERE / (key + ".tscn")).write_text(scene.rstrip()+"\n", encoding="utf-8")
    dump(HERE / (key + ".json"), data)
    scene_id = "linxi_village_center" if key == "linxi_center" else "linxi_village_scrollmap"
    locations[scene_id]["scene"] = RES + key + ".tscn"
    locations[scene_id]["layout_version"] = 3004
    facts[key] = {"buildings": changed, "nonfunctional_local_relocations": MOVES[key], "functional_doors_exact": data["business"]["portal_targets"]}
for scene_id, row in locations.items():
    if scene_id not in ["linxi_village_center", "linxi_village_scrollmap"]:
        assert row == old_locations[scene_id]
    assert row["returns"] == old_locations[scene_id]["returns"]
dump(HERE / "locations_READY.json", locations)
dump(HERE / "candidate_facts_BUILD.json", {"status": "STATIC_CANDIDATE_NO_ENGINE", "adult_height_px": 128.52,
                                          "single_storey_target": "2.5..3.5adults, every door>=141.372", "facts": facts,
                                          "all_original_business_and_returns_exact": True,
                                          "other_five_location_rows_exact": True, "master_30f_sources_preserved": True,
                                          "roads_terrain_original_exact": True, "engine_calls": 0, "formal_writes": 0})
assert all(sha(ROOT / key) == value["sha256"] for key, value in before.items())
print(json.dumps({"new_building_count": {k:len(v["buildings"]) for k,v in facts.items()}, "old_sources_exact": True}))
