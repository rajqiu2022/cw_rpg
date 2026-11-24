"""Frozen finite ordinary actors only, no engine/collector/image processing."""
from pathlib import Path
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
NPC = ROOT / "game/build/luoyang_city_full_rollout_20261022ap_npc01/author.json"
PEOPLE = ROOT / "game/build/luoyang_city_full_rollout_20261022ap_npc01/quarter_people.json"
PINS = {
    str(NPC): "d51fa9ffce334601ecad4d114b39db78b24bbc71fef99ab3cfb10b5189720ed2",
    str(PEOPLE): "74759592d13ae8dade98e8b44daed34d62ca0acd00387b1ee654d9d300609b9b",
}
for path, expected in PINS.items():
    if hashlib.sha256(Path(path).read_bytes()).hexdigest() != expected:
        raise ValueError("Frozen input changed")
npc = json.loads(NPC.read_text(encoding="utf-8"))
people = json.loads(PEOPLE.read_text(encoding="utf-8"))
def f32(v):
    return struct.unpack("<f", struct.pack("<f", v))[0]
out = {"status": "ROOT_APPROVED_FINITE_ORDINARY_6_VISUAL_8_QUARTER_12_DAILY_NOT_ACTUAL", "source_sha256": PINS, "scenes": {}, "excluded_visible": [{"id": "spar_yamen_captain", "reason": "Original require_flag luoyang_case_found_clue; no story flag forced for ordinary pictures. Static source projection only, not visible credit."}]}
for visual in npc["visual_rows"]:
    if visual["npc_id"] == "spar_yamen_captain":
        continue
    declared = dict(visual["expected"])
    declared.update(visual["patch"])
    scale = {"luoyang_gate_sergeant": .96, "canal_old_soldier": .94}.get(visual["npc_id"], 1.)
    row = {"id": visual["npc_id"], "npc_name": visual["npc_name"], "sprite_path": declared["sprite_path"], "portrait_path": declared["portrait_path"], "walk_sprite_path": "", "movement_mode": "idle", "ground_anchored": True, "body_size_px": [f32(160.*scale*.14), f32(160.*scale*.18)], "body_basis": "Original160px frame times unchanged scale %.2f times .14/.18, final Vector2 encoding; no runtime measurement backfill" % scale}
    out["scenes"].setdefault(visual["scene_id"], {"npc_rows": [], "daily_identities": []})["npc_rows"].append(row)
for resident in people["people"]:
    family = people["families"][resident["family"]]
    row = {"id": resident["npc_id"], "npc_name": resident["npc_name"], "sprite_path": family["sprite_path"], "portrait_path": family["portrait_path"], "walk_sprite_path": "", "movement_mode": "idle", "ground_anchored": True, "body_size_px": [f32(160.*.14), f32(160.*.18)], "quarter_daily": True, "body_basis": "Authored district_life_ground_anchored scale1.0, original160px native22.4x28.8 body"}
    out["scenes"].setdefault(resident["scene_id"], {"npc_rows": [], "daily_identities": []})["npc_rows"].append(row)
for daily in npc["daily_rows"]:
    out["scenes"].setdefault(daily["scene_id"], {"npc_rows": [], "daily_identities": []})["daily_identities"].append({"id": daily["npc_id"], "name": daily["npc_name"]})
assert sum(len(r["npc_rows"]) for r in out["scenes"].values()) == 14
assert sum(len(r["daily_identities"]) for r in out["scenes"].values()) == 12
target = QA / "finite_actor_expectations_READY.json"
if target.exists():
    raise ValueError("NEW output only")
raw = (json.dumps(out, ensure_ascii=False, indent=2) + "\n").encode()
target.write_bytes(raw)
print(json.dumps({"path": str(target), "sha256": hashlib.sha256(raw).hexdigest(), "finite_actor_rows": 14, "daily_metadata": 12, "actual_dialogue_representatives": 2, "engine": False}))
