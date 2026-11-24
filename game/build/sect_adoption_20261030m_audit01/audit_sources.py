"""Read-only sect adoption audit; writes evidence only beside this script."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent

def read(path):
    return (ROOT / path).read_text(encoding="utf-8-sig")

def digest(path):
    data = (ROOT / path).read_bytes()
    return {"path": path, "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)}

def matches(path, needles):
    return [{"line": i, "text": line} for i, line in enumerate(read(path).splitlines(), 1)
            if any(needle in line for needle in needles)]

ROUTER = "game/scripts/autoload/scene_router.gd"
REG = "game/build/three_towns_world_20261029j_system01/town_registry.gd"
NATIVE = "game/build/three_towns_world_20261029j_system01/native_sources.json"
HOST = "game/build/sect_completion_20261030a_system01/sect_field.gd"
WORLD = "game/data/maps/world_map_jianghu_layout_v15.tres"
IDS = ["openworld_wudang_gate", "openworld_wudang_taiji_court", "openworld_wudang_purple_cloud_court",
       "openworld_huashan_forecourt", "openworld_huashan_sword_terrace", "openworld_huashan_waterfall_terrace",
       "ch2_s4_lingyue_gate", "openworld_lingyue_inner_court"]
SCENES = [f"game/data/scenes/{id}.tres" for id in IDS]
DRAFTS = ["game/scenes/drafts/sect_maps_20261029k/wudang.tscn",
          "game/scenes/drafts/huashan_map_20261029m/huashan.tscn"]
CONTROLLERS = ["game/scripts/drafts/sect_maps_20261029k/controller.gd",
               "game/scripts/drafts/huashan_map_20261029m/controller.gd"]
LAYOUTS = []
for scene in SCENES:
    LAYOUTS.extend("game/" + p for p in re.findall(r'path="res://(data/maps/[^\"]+)"', read(scene)))
DOCS = ["docs/changes/town-layout-and-sect-entries-20261030a.md",
        "docs/changes/sect-maps-20261029k.md", "docs/changes/huashan-map-20261029m.md",
        "docs/changes/sect-remaining-designs-20261029l.md"]
EXTRA = ["game/data/scenes/world_map_jianghu.tres", "game/data/scenes/world_map_jianghu_v15.tres",
         "game/scenes/field_walkable.tscn", "game/scripts/field/field_walkable_controller.gd",
         "game/scenes/drafts/sect_completion_20261030a/lingyue.tscn",
         "game/art/modules/sect_maps_20261029k/wudang.json", "game/art/modules/huashan_map_20261029m/huashan.json",
         "assets/raw/sect_redesign_20261029j/wudang_masterplan_v2.png",
         "assets/raw/sect_remaining_designs_20261029l/huashan_masterplan_v1.png",
         "assets/raw/sect_remaining_designs_20261029l/lingyue_masterplan_v1.png"]
FILES = list(dict.fromkeys([ROUTER, REG, NATIVE, HOST, WORLD] + SCENES + LAYOUTS + DRAFTS + CONTROLLERS + DOCS + EXTRA))
before = {p: digest(p) for p in FILES}
native = json.loads(read(NATIVE))["sources"]
registry_ids = re.findall(r'&"([^"]+)"', re.search(r'^const IDS := (.+)$', read(REG), re.M).group(1))
scene_facts = []
for scene in SCENES:
    text = read(scene)
    values = {}
    for key in ["scene_id", "display_name", "background_path", "is_walkable", "player_visual_scale", "player_spawn"]:
        m = re.search(r'^' + key + r' = (.+)$', text, re.M)
        values[key] = m.group(1) if m else None
    scene_facts.append({**before[scene], "fields": values,
                        "evidence": matches(scene, ["scene_id =", "display_name =", "background_path =", "data/maps/"])})
world_evidence = []
world_lines = read(WORLD).splitlines()
for i, line in enumerate(world_lines):
    if any(f'"target_scene": "{id}"' in line for id in [IDS[0], IDS[3], IDS[6]]):
        world_evidence.append({"line": i + 1, "context": [{"line": n+1, "text": world_lines[n]}
                                for n in range(max(0, i-19), min(len(world_lines), i+7))]})
consumer_search = {}
for draft in DRAFTS:
    needle = "res://" + draft[5:]
    found = []
    for scope in ["game/scripts", "game/scenes", "game/build/three_towns_world_20261029j_system01", "game/build/sect_completion_20261030a_system01", "game/build/four_settlements_20261030e_system01"]:
        for path in (ROOT / scope).rglob("*"):
            if path.is_file() and path.suffix in [".gd", ".tscn", ".json", ".tres"]:
                for i, line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
                    if needle in line:
                        found.append({"path": path.relative_to(ROOT).as_posix(), "line": i, "text": line})
    consumer_search[draft] = {"literal_reference_hits": found, "formal_native_pin": native.get(needle),
                             "scope": "scripts/scenes + current town/sect/four-settlement owners; not all historical build/QA"}
draft_facts = []
for draft, controller, layout in zip(DRAFTS, CONTROLLERS, EXTRA[5:7]):
    data = json.loads(read(layout))
    draft_facts.append({"scene": draft, "controller": controller, "layout": layout,
                        "title": data["title"], "size": data["size"], "spawn": data["spawn"],
                        "elevations": data["terrain"]["heights"],
                        "controller_has_examine_method": bool(re.search(r'^func examine\(', read(controller), re.M)),
                        "standalone_input_evidence": matches(controller, ["func _ready", "func _physics_process", "KEY_SPACE", "KEY_R", "UI/Detail/Text"]),
                        "scene_binding_evidence": matches(draft, ["layout_path =", 'id="controller"', 'id="player"'])})
after = {p: digest(p) for p in FILES}
evidence = {
    "audit_kind": "read-only current-source trace; no engine, physics, screenshot re-review, save API, or formal writes",
    "registry_ids": registry_ids,
    "unadopted_formal_ids": [id for id in IDS if id not in registry_ids],
    "world_portals": world_evidence,
    "router_evidence": matches(ROUTER, ["towns29j.IDS.has", "func get_field_scene_path", "func _go_field_smart_prepared", "const SCENE_FIELD_WALKABLE", "func _normalize_field_id", 'return &"ch1_s2_qingfeng"']),
    "registry_evidence": matches(REG, ["const IDS", "const SECT_IDS", '"ch2_s4_lingyue_gate"', "inner_source", "current==row.inner_source", "sect_field.tscn"]),
    "host_evidence": matches(HOST, ["REG.SECT_IDS", "source.duplicate", "background.hide", "load(row.scene)", "portal_rows=scene.map_layout.portals", '"ch2_s4_lingyue_gate"', "portal_feet=", "native_town.examine"]),
    "scenes": scene_facts,
    "map_evidence": {p: matches(p, ["design_size =", "display_at_native_size =", "target_scene", '"action":"world_map"']) for p in LAYOUTS},
    "drafts": draft_facts, "draft_consumer_checks": consumer_search,
    "related_pinned_assets_not_adoption": {p: sha for p, sha in native.items() if "wudang" in p or "huashan" in p},
    "background_draw_evidence": matches(EXTRA[3], ["var path := scene.background_path", '_world_background.name = "WorldBackground"', "_world_background.texture = texture", "var uniform_scale := _world_size.x"]),
    "source_inventory": list(before.values()),
    "all_audited_source_bytes_unchanged": before == after,
    "scope_note": "No claim that untested standalone drafts are current production-ready or that title-only identity substitutes for seeing an unavailable user screenshot. Parent identified screenshot2 as Lingyue; exact current display_name independently agrees."
}
assert before == after
(OUT / "current_source_evidence.json").write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"sources": len(FILES), "unchanged": True, "drafts": draft_facts, "output": str(OUT / "current_source_evidence.json")}, ensure_ascii=False))
