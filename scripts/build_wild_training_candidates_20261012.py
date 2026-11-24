"""Read-only candidate planner. Outputs apply_patch text, never writes files.

Art manifest entries: id, ground/path+sha256, layout/path+sha256,
enemy_ids, enemy_species, animal_asset_bindings, return_foot_uv,
entry_proof/path+sha256. A newly authored layout must contain one explicit
empty portals array. Proofs bind original RAW17/Physics/world/art/foot tuples.
Schema checking a proof is not independently executing that proof.
No art => pending report. --emit-patch requires all ten; no canonical writes.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import re
import sys


def need(value, message):
    if not value:
        raise ValueError(message)


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest().upper()


def leaf(root, resource):
    need(type(resource) is str and resource.startswith("res://"), "res path required")
    path = (root / "game" / resource[6:]).resolve()
    need(path.is_relative_to((root / "game").resolve()), "outside game")
    need(path.is_file(), "missing resource: " + resource)
    return path


def bound(root, row):
    need(type(row) is dict and set(row) == {"path", "sha256"}, "typed path/hash binding")
    sha = row["sha256"]
    need(type(sha) is str and re.fullmatch(r"[0-9A-Fa-f]{64}", sha), "SHA64")
    path = leaf(root, row["path"])
    need(digest(path) == sha.upper(), "changed resource: " + row["path"])
    return path


def vec(value, upper):
    return (type(value) is list and len(value) == 2
            and all(type(n) in (int, float) and math.isfinite(n) for n in value)
            and all(0 <= value[i] < upper[i] for i in range(2)))


def q(value):
    return json.dumps(value, ensure_ascii=False)


def prepare(root, entry, art, manifest):
    need(type(art) is dict and art.get("id") == entry["id"], "art ID mismatch")
    ground = bound(root, art.get("ground"))
    layout = bound(root, art.get("layout"))
    need(ground.suffix.lower() == ".png" and layout.suffix.lower() == ".tres", "PNG/TRES")
    need(entry["id"] in layout.stem, "independently authored layout must belong to this ID")
    need(entry["id"] in art["ground"]["path"], "independent ground binding; no whole old outskirts map")
    raw_layout = layout.read_text(encoding="utf-8-sig")
    need('script_class="WalkableMapLayout"' in raw_layout, "layout class")
    empty = "portals = Array[Dictionary]([])"
    need(raw_layout.count(empty) == 1, "exact empty authored portals array")
    for resource in re.findall(r'"(res://[^"\r\n]+)"', raw_layout):
        leaf(root, resource)
    enemies = art.get("enemy_ids")
    need(type(enemies) is list and 0 < len(enemies) <= 3, "enemy IDs")
    need(all(type(n) is str and re.fullmatch(r"[a-z0-9_]+", n) for n in enemies), "enemy ID syntax")
    need(len(set(enemies)) == len(enemies), "duplicate enemy ID")
    need(type(art.get("enemy_species")) is dict, "typed enemy species table")
    need(type(art.get("animal_asset_bindings", {})) is dict, "typed animal asset table")
    levels, species = [], set()
    for enemy in enemies:
        text = leaf(root, "res://data/enemies/" + enemy + ".tres").read_text(encoding="utf-8-sig")
        need('enemy_id = &"' + enemy + '"' in text, "enemy resource ID")
        animal = art.get("enemy_species", {}).get(enemy)
        need(animal in entry["animal_species"], "wrong animal species")
        if animal == "wolf":
            need(enemy in manifest["animal_assets"]["wolf"]["variants"], "unapproved wolf")
        else:
            approved = art.get("animal_asset_bindings", {}).get(animal)
            need(type(approved) is list and len(approved) >= 20, "dedicated animal frames pending")
            for row in approved:
                bound(root, row)
            paths = {row["path"] for row in approved}
            for state in ("ready", "move", "attack", "hit", "defeat"):
                match = re.search(state + r'_frame_paths = PackedStringArray\(([^\n]+)\)', text)
                need(match is not None, "missing animal sequence " + state)
                frames = re.findall(r'"(res://[^"\r\n]+)"', match[1])
                need(len(frames) >= 4 and all(p in paths for p in frames), "unbound animal frames")
                need(all("/wild_wolf/" not in p for p in frames), "wolf cannot impersonate another animal")
        level = re.search(r"^level = (\d+)$", text, re.M)
        need(level is not None, "enemy level")
        levels.append(int(level[1]))
        species.add(animal)
        for resource in re.findall(r'"(res://[^"\r\n]+)"', text):
            leaf(root, resource)
    need(species == set(entry["animal_species"]), "incomplete animals; no fallback")
    need(all(entry["recommended_player_levels"][0] <= n <= entry["recommended_player_levels"][1] for n in levels), "enemy outside area tier")
    foot = art.get("return_foot_uv")
    need(vec(foot, [1, 1]), "local return foot")
    proof = json.loads(bound(root, art.get("entry_proof")).read_text(encoding="utf-8-sig"))
    need(type(proof) is dict and proof.get("scene_id") == entry["id"], "proof ID")
    need(vec(proof.get("world_foot_px"), manifest["world_design_size"]) and vec(proof.get("local_foot_uv"), [1, 1]), "typed finite proof foot")
    need(proof.get("world_sha256") == manifest["bindings"]["res://data/scenes/world_map_jianghu.tres"], "proof world bytes")
    need(proof.get("ground_sha256") == art["ground"]["sha256"] and proof.get("layout_sha256") == art["layout"]["sha256"], "proof art bytes")
    need(proof.get("world_foot_px") == entry["proposed_world_foot_px"] and proof.get("local_foot_uv") == foot, "proof foot tuple")
    for key in ("source_original_raw17_clear", "source_physics_clear", "local_original_raw17_clear", "local_physics_clear", "old16_portals_props_bridges_rivers_clear"):
        need(proof.get(key) is True, "missing entry check " + key)
    world_uv = [entry["proposed_world_foot_px"][i] / manifest["world_design_size"][i] for i in range(2)]
    portal = '{"id": "return_world", "label": "返回江湖行旅图", "pos": Vector2(%s, %s), "size": Vector2(0.05, 0.05), "target_scene": "world_map_jianghu", "target_pos": Vector2(%s, %s), "show_destination_label": true}' % (*foot, *world_uv)
    raw_layout = raw_layout.replace(empty, "portals = Array[Dictionary]([" + portal + "])")
    label = entry["name"] + " · 敌人Lv%d–%d" % (min(levels), max(levels))
    groups = ", ".join('{"enemy_ids": [&"' + enemy + '"], "weight": 1.0}' for enemy in enemies)
    scene = "\n".join([
        '[gd_resource type="Resource" script_class="SceneScript" load_steps=3 format=3]',
        '[ext_resource type="Script" path="res://scripts/domain/scene_script.gd" id="1"]',
        '[ext_resource type="Resource" path=' + q(entry["output_layout_path"]) + ' id="2"]',
        '[resource]', 'script = ExtResource("1")', 'scene_id = &' + q(entry["id"]),
        'display_name = ' + q(label), 'background_path = ' + q(art["ground"]["path"]),
        'is_walkable = true', 'is_settlement = false', 'actor_positions_are_feet = true',
        'map_layout = ExtResource("2")', 'player_spawn = Vector2(%s, %s)' % tuple(foot),
        'encounter_groups = Array[Dictionary]([' + groups + '])',
        'encounter_step_distance = ' + str(float(entry["encounter_step_distance"])),
        'encounter_chance = ' + str(entry["encounter_chance"]),
        'encounter_allow_full_group_for_solo = false', 'npcs = []', 'hotspots = []', ''])
    return [(entry["output_layout_path"], raw_layout), (entry["output_scene_path"], scene)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--art-manifest", type=Path)
    parser.add_argument("--emit-patch", action="store_true")
    args = parser.parse_args()
    root = args.project_root.resolve()
    manifest = json.loads((root / "game/data/config/wild_training_candidates_20261012.json").read_text(encoding="utf-8"))
    need(manifest.get("activated") is False and len(manifest["entries"]) == 10, "candidate ten only")
    need(len({e["id"] for e in manifest["entries"]}) == 10, "unique ten IDs")
    for path, sha in manifest["bindings"].items():
        bound(root, {"path": path, "sha256": sha})
    supplied = json.loads(args.art_manifest.read_text(encoding="utf-8-sig")) if args.art_manifest else {"entries": []}
    need(type(supplied) is dict and type(supplied.get("entries")) is list, "art entries")
    rows = supplied["entries"]
    need(all(type(row) is dict and type(row.get("id")) is str for row in rows), "typed art rows")
    need(len({row["id"] for row in rows}) == len(rows), "duplicate art ID")
    need(set(row["id"] for row in rows) <= set(e["id"] for e in manifest["entries"]), "unknown art ID")
    art_by_id = {row["id"]: row for row in rows}
    pending, files = [], []
    for entry in manifest["entries"]:
        try:
            need(entry["id"] in art_by_id, "art/entry proof pending")
            files.extend(prepare(root, entry, art_by_id[entry["id"]], manifest))
        except (ValueError, KeyError, TypeError, OSError) as error:
            pending.append({"id": entry["id"], "reason": str(error)})
    if not args.emit_patch:
        print(json.dumps({"scope": manifest["scope"], "ready": 10-len(pending), "pending": pending, "writes": 0, "engine_runs": 0}, ensure_ascii=False, indent=2))
        return
    need(not pending and len(files) == 20, "all ten must be ready: " + json.dumps(pending, ensure_ascii=False))
    outputs = [(root / "game" / resource[6:]).resolve() for resource, _ in files]
    need(len(set(outputs)) == 20 and all(p.is_relative_to(root / "game") and not p.exists() for p in outputs), "never overwrite existing file")
    print("*** Begin Patch")
    for output, (_, content) in zip(outputs, files):
        print("*** Add File: " + output.as_posix())
        print("\n".join("+" + line for line in content.splitlines()))
    print("*** End Patch")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, TypeError, OSError) as failure:
        sys.exit("CANDIDATE REFUSED: " + str(failure))
