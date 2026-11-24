"""Add the three fixed native source NPC anchors to the finite influence recipe.

Six DG roles are not the whole Yamen cast; hidden original flags remain intact.
"""
from pathlib import Path
import copy
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[3]
GAME = ROOT / "game"
QA = Path(__file__).resolve().parent
OUT = QA / "wall_yamen_independent_delta_recipe03_PREPARED_NOT_ACTUAL.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed(path, expected):
    assert sha(path) == expected, str(path)
    return json.loads(path.read_bytes())


def local(path):
    assert path.startswith("res://") and ".." not in path
    return GAME / path[6:]


def overlap(a, b):
    return a[0] <= b[2] and a[2] >= b[0] and a[1] <= b[3] and a[3] >= b[1]


assert not OUT.exists()
parent_path = QA / "wall_yamen_independent_delta_recipe02_PREPARED_NOT_ACTUAL.json"
plan = fixed(parent_path, "fb0b30220380773f50fc9a40b88c31664af4bb3e4abee8c21b3ca63bec47114f")
native_path = GAME / "build/luoyang_city_assembled_publication_20261016b/78428_1686/ch4_s1_luoyang_yamen/manifest.json"
native = fixed(native_path, "517a0e68c01dd2ff27a648f72736a100c8523780d5f49423b682c3452b94a32f")
owner_path = GAME / "build/luoyang_city_full_rollout_20261022ap_source_finalize01/unified06_06_independent_qa_owner_source_maps_READY.json"
owners = fixed(owner_path, "3f8d04fde11e7a64b1f1364510cee817466a853c31ae3a98375ca8bcc7283ac8")
source_map = next(r for r in owners["scenes"] if r["id"] == "ch4_s1_luoyang_yamen")["source_sha256"]
paths = ["res://data/scenes/ch4_s1_luoyang_yamen.tres", "res://data/npcs/npc_catalog.tres", "res://scripts/field/field_walkable_controller.gd", "res://scripts/field/npc_node.gd"]
texts = {}
for path in paths:
    assert sha(local(path)) == source_map[path]
    plan["fixed_input_sha256"][path] = source_map[path]
    texts[path] = local(path).read_text(encoding="utf-8")
scene_text = texts[paths[0]]
catalog_text = texts[paths[1]]
assert 'npc.movement_mode = String(d.get("movement_mode", "idle"))' in texts[paths[2]]
assert '@export_enum("idle", "patrol", "seated") var movement_mode: String = "idle"' in texts[paths[3]]
expected = {"spar_yamen_patrol": [1170, 1000], "spar_yamen_captain": [1790, 870], "ch8_luoyang_final_clerk": [1980, 1180]}
slots = native["record"]["gameplay_slots"]["npcs"]
assert {r["source_id"]: r["foot_px"] for r in slots} == expected
rows = []
for slot in slots:
    identity = slot["source_id"]
    assert ('npc_id = &"' + identity + '"') not in catalog_text
    blocks = [b for b in scene_text.split('}, {') if ('"npc_id": "' + identity + '"') in b]
    assert len(blocks) == 1
    block = blocks[0]
    assert '"movement_mode"' not in block and '"patrol_axis"' not in block and '"patrol_distance"' not in block
    x, y = slot["foot_px"]
    influence = [x-17, y-15, x+17, y+15]
    candidates = []
    for poly in plan["Yamen"]["new_native_source_polygons"]:
        points = poly["points_px"]
        box = [min(p[0] for p in points), min(p[1] for p in points), max(p[0] for p in points), max(p[1] for p in points)]
        if overlap(influence, box):
            candidates.append(poly["id"])
    conditions = {key: re.search('"' + key + '": "([^"]+)"', block).group(1) for key in ("require_flag", "require_quest_active", "hide_flag") if re.search('"' + key + '": "([^"]+)"', block)}
    rows.append({"id": identity, "source_foot_px": slot["foot_px"], "source_movement_mode": "idle", "source_lane_points_px": [slot["foot_px"], slot["foot_px"]], "reason": "Frozen native scene has no movement_mode; exact catalog contains no matching profile; original Field/NPC default is idle, despite role name patrol.", "existing_visibility_conditions_unchanged": conditions, "do_not_force_visibility_flags_or_quests": True, "conservative_new_prop_influence_rect_xyxy": influence, "new_prop_AABB_candidates_selection_only": candidates, "unchanged_source_anchor_inheritance_not_fresh_all_actor_runtime_credit": True})
plan["inherited_prepared_recipe02"] = {"path": "res://" + parent_path.relative_to(GAME).as_posix(), "sha256": sha(parent_path)}
plan["Yamen"]["three_additional_native_source_actors"] = rows
plan["Yamen"]["actor_population_boundary"] = {"DG_source_rows": 6, "native_source_slots": 3, "total_source_actor_definitions": 9, "not_claimed_simultaneously_visible": True, "native_conditional_flags_not_changed": True, "old_source_anchor_inheritance_and_new_prop_influence_selection_only": True}
plan["status"] = "INDEPENDENT_FINITE_PREPARATION03_NATIVE1135_ROUTES_AND_NINE_SOURCE_ACTOR_DEFINITIONS_NOT_ACTUAL_PASS"
OUT.write_text(json.dumps(plan, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"path": str(OUT), "sha256": sha(OUT), "native_actor_slots": len(rows), "DG_source_rows": 6, "native_actor_new_prop_candidates": sum(len(r["new_prop_AABB_candidates_selection_only"]) for r in rows), "engine_runs": 0, "accepted": False}))
