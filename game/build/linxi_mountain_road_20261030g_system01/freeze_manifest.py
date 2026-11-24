"""Emit exact handoff metadata only; never launch Godot or alter runtime sources."""
from pathlib import Path
import hashlib
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DATA = json.loads((HERE / "road_layout.json").read_text(encoding="utf-8"))


def fact(path):
    raw = (ROOT / path).read_bytes()
    return {"sha256": hashlib.sha256(raw).hexdigest(), "bytes": len(raw)}


def relative(path):
    return path.relative_to(ROOT).as_posix()


def dump(name, value):
    (HERE / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


modules = {relative(HERE / name): fact(relative(HERE / name)) for name in
           ["road_author.gd", "road_entry.gd", "road_field.gd", "road_field.tscn", "road_layout.json"]}
textures = {row["texture"] for row in DATA["specs"] + DATA["ground"] + DATA["roads"]}
textures.add(DATA["cave_module"]["spec"]["texture"])
textures.update([
    "res://art/modules/prop/linxi_stone_tablet_v2.png",
    "res://art/characters/prop_corpse_v2.png",
    "res://art/modules/prop/chest_normal_closed_v1.png",
    "res://art/modules/veg/veg_grass_tuft_a.png",
])
# Existing true consumers are pinned, never byte-modified or background-cropped.
inputs = {"game/" + path.removeprefix("res://"): fact("game/" + path.removeprefix("res://"))
          for path in sorted(textures)}
for path in ["game/data/scenes/ch1_s1_road.tres", "game/data/maps/ch1_s1_road_layout_v5.tres",
             "game/scenes/field_walkable.tscn", "game/scripts/field/field_walkable_controller.gd"]:
    inputs[path] = fact(path)
before = json.loads((HERE / "source_before.json").read_text(encoding="utf-8"))
protected = {path: {"before": old, "current": fact(path),
                    "bytes_sha_equal": old["sha256"] == fact(path)["sha256"] and old["bytes"] == fact(path)["bytes"]}
             for path, old in before.items()}
manifest = {"id": "ch1_s1_road", "layout_version": 3003, "size": DATA["size"],
            "status": "CANDIDATE_STATIC_ONLY_NOT_ENGINE_OR_FORMAL", "targets": [],
            "new_modules": modules, "runtime_inputs": inputs,
            "shared_owner": "xiangzhou30e", "mini_owned_by_shared_not_duplicated":
            ["game/build/linxi_road_portrait_20261030g_source01/road_minimap.gd",
             "game/build/linxi_road_portrait_20261030g_source01/road_minimap_base.gd"],
            "original_business_sources": ["game/data/scenes/ch1_s1_road.tres", "game/data/maps/ch1_s1_road_layout_v5.tres"],
            "formal_writes": 0, "engine_calls": 0}
dump("g_manifest_READY.json", manifest)
dump("candidate_facts_READY.json", {
    "id": "ch1_s1_road", "version": 3003, "size": DATA["size"], "formal_writes": 0, "engine_calls": 0,
    "protected_before_fulltext_dir": relative(HERE / "before"), "protected_sources": protected,
    "field": relative(HERE / "road_field.tscn"), "entry": relative(HERE / "road_entry.gd"),
    "returns": {"linxi_village_center": [420, 3150], "ch1_s2_qingfeng": [4080, 470], "interior_bandit_cave": [2400, 1610]},
    "cave_portal": [2420, 1530], "business_geometry": DATA["business"],
    "static_native_specs": len(DATA["specs"]) + 1, "cave_native_scale": .65,
    "maximum_native_scale": max(row["native_scale"] for row in DATA["specs"]),
    "cave": {"png": "game/art/modules/linxi_mountain_road_20261030g/cave_mouth.png",
             "size": [1792, 1280], "source_threshold": [1008, 960], "map_foot": [2420, 1460],
             "solid_polygons": 3, "whole_rect_sealing_mouth": False},
    "static_geometry_evidence": {"main": ["geometry_attempt01.json", 928, 0],
                                 "west_bamboo_loop": ["geometry_attempt03.json", 771, 0],
                                 "herb_loop": ["geometry_attempt02.json", 139, 0],
                                 "cave_actual_native": ["geometry_attempt04.json", 181, 0],
                                 "failed_attempts_preserved": ["geometry_attempt01.json", "geometry_attempt02.json"],
                                 "scope": "Independent full 34x24 footprint intersection. Not engine physics, locks, encounter execution or ART acceptance."},
    "business_preserved": {"portals": 5, "destinations": 3, "interactions": 4, "dynamic_visuals": 4,
                           "original_npcs": 1, "encounter_step": 620, "encounter_chance": .16,
                           "encounter_require_flag": "master_training_done", "is_settlement": False,
                           "legacy_auto_corpse_not_reactivated": True, "intro_once_original": True},
    "dynamic_refresh": {"new_road_override_only": True, "preserves": ["Player", "camera", "mini cache", "RoadGround", "native static Sprite", "static collision"],
                        "refreshes": ["four original visual objects with gates", "dynamic object collisions", "interactions", "portals", "original NPC and Bounty NPC"],
                        "no_setup_scene_call": True, "no_encounter_algorithm_override": True,
                        "restore_dynamic_presence_same_require_hide_quest_predicate": True},
    "normal_camera_feet": [[1200, 2700], [2230, 2450], [2400, 1610]],
    "short_route": {"start": [2400, 1610], "end": [2400, 1560], "distance_px": 50,
                    "note": "Actual physics pending. Keep original encounter enabled; route length only avoids crossing620 threshold from clean setup."},
    "not_claimed": ["Godot parse", "real gameplay", "3 destination round trips", "random encounter execution", "ART acceptance", "formal integration"]})
dump("HANDOFF_READY.json", {"scope": "30g road candidate only; 30f frozen and unpublished remains untouched",
     "manifest": relative(HERE / "g_manifest_READY.json"), "manifest_fact": fact(relative(HERE / "g_manifest_READY.json")),
     "facts": relative(HERE / "candidate_facts_READY.json"), "facts_fact": fact(relative(HERE / "candidate_facts_READY.json")),
     "integration": "Shared owner adds exact ch1_s1_road Registry special dispatch to ROAD.town/start; Entry and row version3003. Preserve existing Linxi World landmark. No 30f locations edits by this author.",
     "next_authority": "Root only const-preload --check-only and formal/engine work; no SceneTree initialize or user process control by this author.",
     "native_modules": modules})
print(json.dumps({"manifest": fact(relative(HERE / "g_manifest_READY.json")), "modules": modules}, indent=2))
