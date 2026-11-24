"""Inventory authored RPG content without launching Godot or touching saves.

Run: python -B scripts/audit_content_depth.py
"""

import json
import re
from collections import Counter

from audit_art_readiness import ROOT, local
from audit_npc_resources import parse_field_npcs
from build_arsenal_catalog import (
    bool_value, collect_equipment_acquisition, collect_skill_acquisition, infer_weapon_name,
)

DATA = ROOT / "game/data"


def read(path):
    return path.read_text(encoding="utf-8-sig")


def field(source, key):
    m = re.search(rf"^{key}\s*=[ \t]*(.*)$", source, re.M)
    if not m:
        return ""
    val = m.group(1).strip()
    return val[1:].strip('"') if val.startswith('&"') else val.strip('"')


def strings(source, key):
    m = re.search(rf"^{key}\s*=[ \t]*(?:Array\[\w+\]|PackedStringArray)\(\s*(.*?)\)\s*$",
                  source, re.M | re.S)
    return re.findall(r'"((?:[^"\\]|\\.)*)"', m[1]) if m else []


def catalog(folder, key):
    rows = {}
    for path in sorted((DATA / folder).glob("*.tres")):
        source = read(path)
        ident = field(source, key)
        if ident:
            assert ident not in rows, (folder, ident)
            rows[ident] = source
    return rows


def icon_counts(rows):
    paths = Counter(field(s, "icon_path") for s in rows.values())
    explicit = {p: n for p, n in paths.items() if p}
    return {
        "definitions": len(rows), "explicit": sum(explicit.values()),
        "unique_paths": len(explicit), "no_explicit_icon": paths[""],
        "missing_paths": [p for p in explicit if not local(p).is_file()],
        "shared_paths": {p: n for p, n in explicit.items() if n > 1},
    }


def sprite_summary(records, key):
    paths = Counter(r[key] for r in records if r[key] not in ("", "-"))
    return {"placements_with_path": sum(paths.values()), "unique_paths": len(paths),
            "missing_paths": [p for p in paths if not local(p).is_file()],
            "most_reused": paths.most_common(6)}


def enemy_summary(rows):
    result, missing, families = Counter(), [], Counter()
    keys = ("ready", "move", "attack", "hit", "defeat")
    for ident, source in rows.items():
        actor = field(source, "battle_actor_path")
        if actor and local(actor).is_file():
            families[actor] += 1
        else:
            missing.append(ident)
        filled = sum(any(p.startswith("res://") and local(p).is_file()
                         for p in strings(source, f"{key}_frame_paths")) for key in keys)
        result["all_five" if filled == 5 else "no_frames" if filled == 0 else "partial"] += 1
    return {"count": len(rows), "static_actor_paths": len(families),
            "no_valid_static_actor": missing, "frame_slots": result, "top_actor_reuse": families.most_common(6)}


def quote_values(source, *keys):
    return re.findall(r'&?"(?:' + "|".join(keys) + r')"\s*:\s*&?"(res://[^"]+)"', source)


def map_inventory(scenes):
    layouts, backgrounds, terrain, objects, missing, detail = set(), Counter(), Counter(), Counter(), [], {}
    ground_name = re.compile(r"(?:^|[_-])(?:ground|floor|paving|pavement|tile|cobble|roadbed|topsoil|grass|mud|gravel|sand|snow|water)(?:[_\W]|$)", re.I)
    for ident, source in scenes.items():
        bg = field(source, "background_path")
        if bg:
            backgrounds[bg] += 1
        ext_id = re.fullmatch(r'ExtResource\("(.*?)"\)', field(source, "map_layout"))
        if not ext_id:
            continue
        ext = re.search(r'path="(res://[^"]+)"\s+id="' + re.escape(ext_id[1]) + r'"', source)
        if not ext or not local(ext[1]).is_file():
            missing.append(ident)
            continue
        layouts.add(ext[1])
        body = read(local(ext[1]))
        tiles = Counter()
        placements = Counter()
        for key in ("tiles", "travel_routes", "visual_objects"):
            m = re.search(rf"^{key}\s*=.*?(?=^\w+\s*=|\Z)", body, re.M | re.S)
            if m:
                (placements if key == "visual_objects" else tiles).update(
                    quote_values(m[0], "texture", "texture_path", "mask_texture", "material_texture"))
        # A number of native layouts place floor tiles in visual_objects.
        for path in list(placements):
            if ground_name.search(path.rsplit("/", 1)[-1]):
                tiles[path] += placements.pop(path)
        terrain.update(tiles)
        objects.update(placements)
        detail[ident] = {"layout": ext[1], "ground_paths": sorted(tiles),
                         "prop_slots": sum(placements.values()), "prop_paths": len(placements)}
    return {"scene_defs": len(scenes), "scene_layout_bindings": len(detail), "unique_layouts": len(layouts),
            "missing_bindings": missing, "unique_backgrounds": len(backgrounds),
            "ground_route_paths": len(terrain), "top_ground_route_paths": terrain.most_common(8),
            "prop_slots": sum(objects.values()), "unique_prop_paths": len(objects),
            "top_props": objects.most_common(12), "scenes": detail}


def main():
    enemies = catalog("enemies", "enemy_id")
    skills = catalog("skills", "skill_id")
    equipment = catalog("equipment", "item_id")
    items = catalog("items", "item_id")
    quests = catalog("quests", "quest_id")
    scenes = catalog("scenes", "scene_id")
    bounties = catalog("bounties", "bounty_id")
    npc = parse_field_npcs()
    chapters, ids = [], set()
    for n in range(1, 9):
        plan = read(DATA / "chapters" / f"chapter_{n}_content_plan.tres")
        main_ids, side = (strings(plan, key) for key in ("main_quest_ids", "side_quest_ids"))
        ids.update(main_ids + side)
        row = {"chapter": n, "title": field(plan, "title"), "main": main_ids, "side": side,
               "scene_slots": len(strings(plan, "main_scene_ids")),
               "battle_groups": len(re.findall(r'"enemy_ids"\s*:', plan)),
               "design_main_min": int(field(plan, "estimated_main_minutes")),
               "design_completionist_min": int(field(plan, "estimated_completionist_minutes"))}
        for key, selection in (("side", side), ("main", main_ids)):
            row[key + "_details"] = [
                {"id": q, "title": field(quests.get(q, ""), "title"),
                 "triggers": strings(quests.get(q, ""), "completion_triggers"),
                 "objective": field(quests.get(q, ""), "desc_in_progress"),
                 "tracker": field(quests.get(q, ""), "tracker_hint")}
                for q in selection]
        chapters.append(row)

    skill_player, usage = collect_skill_acquisition(set(skills))
    state = read(ROOT / "game/scripts/autoload/game_state.gd")
    evolved = set(re.findall(r'&"([^"]+)"', re.search(r'const LINXI_EVOLVED_ARTS.*?=\s*\[(.*?)\]', state, re.S)[1]))
    manual_skills = {field(source, "study_skill_id") for source in items.values()} & skills.keys()
    player_ids = set(skill_player) | evolved | manual_skills | {
        k for k, v in usage.items() if any(s.startswith("队友固有") for s in v)}
    enemy_ids = {k for k, v in usage.items() if any(s.startswith("敌方使用") for s in v)}
    vfx_text = read(ROOT / "game/scripts/battle/battle_vfx_player.gd")
    unique_ids = re.search(r'const UNIQUE_EFFECT_IDS.*?=\s*\[(.*?)\]', vfx_text, re.S)[1]
    fx = {k: f"res://art/battle_vfx/skill_unique_v1/vfx_{k}_4frame_v1.png"
          for k in re.findall(r'&"([^"]+)"', unique_ids)}
    constants = dict(re.findall(r'^const (\w+)\s*:=\s*"(res://[^"]+)"', vfx_text, re.M))
    for key, path, constant in re.findall(r'&"([^"]+)"\s*:\s*\{\s*"sheet"\s*:\s*(?:"([^"]+)"|(\w+))', vfx_text):
        fx[key] = path or constants.get(constant, "")

    def skill_summary(selected):
        subset = {k: skills[k] for k in sorted(selected)}
        paths = Counter()
        classes = {}
        for k, s in subset.items():
            aid = field(s, "animation_id")
            if bool_value(s, "is_passive"):
                classes[k] = "passive"
            elif k == "basic_attack":
                classes[k] = "weapon_dispatched"
            elif aid in fx and local(fx[aid]).is_file():
                classes[k] = "bound_sheet"
                paths[fx[aid]] += 1
            else:
                classes[k] = "other_or_fallback"
        return {**icon_counts(subset), "fx_classes": Counter(classes.values()),
                "distinct_bound_vfx_sheet_paths": len(paths),
                "other_or_fallback_ids": [k for k, v in classes.items() if v == "other_or_fallback"]}

    item_classes = {}
    for c, label in enumerate(("consumable", "material", "key_item", "equipment")):
        item_classes[label] = icon_counts({k: s for k, s in items.items() if (field(s, "category") or "0") == str(c)})
    for label, match in (("readable", lambda s: bool_value(s, "readable")),
                         ("manual", lambda s: bool(field(s, "study_skill_id")))):
        item_classes[label] = icon_counts({k: s for k, s in items.items() if match(s)})
    acquisition = collect_equipment_acquisition(set(equipment))
    source_types = Counter(method for methods in acquisition.values()
                           for method in {m.split(" · ", 1)[0] for m in methods})
    weapon_types = Counter(infer_weapon_name(k, field(s, "display_name"), field(s, "martial_style") or field(s, "weapon_type"))
                           for k, s in equipment.items() if (field(s, "slot") or "0") == "0")
    enemy_references = set()
    for folder in ("scenes", "dialogs", "chapters", "bounties"):
        for p in (DATA / folder).glob("*.tres"):
            enemy_references.update(re.findall(r'"([a-z][a-z0-9_]+)"', read(p)))
    enemy_references.intersection_update(enemies)
    result = {
        "scope": "authored PC data; static references and documented runtime evidence are separate",
        "chapters": chapters, "quest_definition_count": len(quests), "missing_plan_ids": sorted(ids - quests.keys()),
        "not_in_plans": {q: field(s, "title") for q, s in quests.items() if q not in ids},
        "bounties_by_city": Counter(field(s, "board_city") for s in bounties.values()),
        "npc": {"authored_placements": len(npc), "unique_ids": len({r["npc_id"] for r in npc}),
                "dialog_attached": sum(r["dialog"] != "-" for r in npc),
                "idle": sprite_summary(npc, "idle"), "portrait": sprite_summary(npc, "portrait"),
                "portrait_source": Counter(r["portrait_source"] if r["portrait"] != "-" else "none" for r in npc),
                "generic_portrait_paths": sum(r["portrait"] != "-" and r["portrait_kind"] == "generic" for r in npc),
                "statically_flagged": Counter(k for r in npc for k in r["status"].split(", ") if k != "ok"),
                "dialog_defs": len(catalog("dialogs", "dialog_id"))},
        "enemies": enemy_summary(enemies),
        "enemy_static_id_mentions": enemy_summary({k: enemies[k] for k in sorted(enemy_references)}),
        "skills": {"all": skill_summary(skills), "player_or_companion_source": skill_summary(player_ids),
                   "enemy_referenced": skill_summary(enemy_ids), "both": sorted(player_ids & enemy_ids),
                   "neither_source": sorted(set(skills) - player_ids - enemy_ids)},
        "equipment": {**icon_counts(equipment), "slots": Counter(field(s, "slot") or "0" for s in equipment.values()),
                      "quality": Counter(field(s, "quality") or "0" for s in equipment.values()),
                      "weapon_types": weapon_types, "with_static_source": len(acquisition),
                      "equipment_ids_by_static_source_type": source_types,
                      "no_static_source_ids": sorted(set(equipment) - acquisition.keys())},
        "items": {**icon_counts(items), "classes": item_classes},
        "maps": map_inventory(scenes),
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
