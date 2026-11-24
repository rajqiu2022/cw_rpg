#!/usr/bin/env python3
"""Audit configured field NPCs and battle enemies, then write a roster report.

This deliberately reads Godot .tres source as data rather than importing the
project: it remains usable in CI and on machines without the Godot editor.
"""

from __future__ import annotations

import argparse
import re
from collections import Counter
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
GAME = ROOT / "game"
SCENE_DIR = GAME / "data" / "scenes"
DIALOG_DIR = GAME / "data" / "dialogs"
ENEMY_DIR = GAME / "data" / "enemies"
CATALOG = GAME / "data" / "npcs" / "npc_catalog.tres"
REPORT = ROOT / "docs" / "npc-roster-and-asset-audit-v1.md"

# IDs that intentionally represent the same named character in another state or map.
CANONICAL_NPC_IDS = {
    "crying_woman_waiting": "crying_woman",
    "duqingshan_ready": "duqingshan",
    "duqingshan_after_sword": "duqingshan",
    "inn_waiter_inside": "inn_waiter",
    "linxi_south_farmer": "linxi_farmer",
    "xingfantian_after_farewell": "xingfantian",
    "xingfantian_return": "xingfantian",
    "yuewuxing_after": "yuewuxing",
}


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def get_value(block: str, key: str) -> str:
    match = re.search(r'"%s"\s*:\s*"([^"]*)"' % re.escape(key), block)
    return match.group(1) if match else ""


def get_scene_id(text: str) -> str:
    match = re.search(r'scene_id\s*=\s*&"([^"]+)"', text)
    return match.group(1) if match else "unknown_scene"


def resource_exists(res_path: str) -> bool:
    if not res_path.startswith("res://"):
        return False
    return (GAME / res_path.removeprefix("res://")).exists()


def texture_frames(res_path: str) -> int:
    if not resource_exists(res_path):
        return 0
    try:
        with Image.open(GAME / res_path.removeprefix("res://")) as image:
            if image.height <= 0:
                return 0
            return max(1, round(image.width / image.height))
    except OSError:
        return 0


def catalog_overrides() -> dict[str, dict[str, str]]:
    if not CATALOG.exists():
        return {}
    text = read_text(CATALOG)
    overrides: dict[str, dict[str, str]] = {}
    for block in re.findall(r'\[sub_resource.*?\](.*?)(?=\n\[|\Z)', text, re.S):
        npc_id_match = re.search(r'npc_id\s*=\s*&"([^"]+)"', block)
        if not npc_id_match:
            continue
        npc_id = npc_id_match.group(1)
        overrides[npc_id] = {
            "sprite_path": _assignment(block, "sprite_path"),
            "portrait_path": _assignment(block, "portrait_path"),
            "dialog_id": _assignment(block, "default_dialog_id"),
            "movement_mode": _assignment(block, "movement_mode"),
        }
    return overrides


def _assignment(block: str, key: str) -> str:
    match = re.search(r'%s\s*=\s*(?:&)?"([^"]*)"' % re.escape(key), block)
    return match.group(1) if match else ""


def parse_field_npcs() -> list[dict[str, str]]:
    overrides = catalog_overrides()
    records: list[dict[str, str]] = []
    for path in sorted(SCENE_DIR.glob("*.tres")):
        text = read_text(path)
        scene_id = get_scene_id(text)
        for block in re.findall(r'\{(.*?)\}', text, re.S):
            npc_id = get_value(block, "npc_id")
            if not npc_id:
                continue
            override = overrides.get(npc_id, {})
            sprite_path = override.get("sprite_path") or get_value(block, "sprite_path")
            configured_portrait = override.get("portrait_path") or get_value(block, "portrait_path")
            dialog_id = override.get("dialog_id") or get_value(block, "dialog_id")
            movement_mode = override.get("movement_mode") or get_value(block, "movement_mode") or "idle"
            walk_sprite_path = get_value(block, "walk_sprite_path")
            frames = texture_frames(sprite_path)
            status: list[str] = []
            if not resource_exists(sprite_path):
                status.append("missing-idle")
            elif frames < 4:
                status.append("needs-idle-motion")
            if movement_mode == "patrol" and not resource_exists(walk_sprite_path):
                status.append("missing-walk")
            npc_name = get_value(block, "npc_name") or npc_id
            dialog_portraits = speaker_portraits(dialog_id, npc_name)
            portrait_path = configured_portrait
            portrait_source = "scene/catalog"
            if not portrait_path and len(dialog_portraits) == 1:
                portrait_path = next(iter(dialog_portraits))
                portrait_source = "dialog"
            if not portrait_path and dialog_id:
                portrait_path = generic_portrait_for(npc_id, npc_name)
                portrait_source = "runtime-fallback"
            if not dialog_id:
                status.append("no-dialog")
            elif not resource_exists(portrait_path):
                status.append("missing-portrait")
            if configured_portrait and dialog_portraits and configured_portrait not in dialog_portraits:
                status.append("dialog-portrait-mismatch")
            records.append(
                {
                    "scene": scene_id,
                    "npc_id": npc_id,
                    "name": npc_name,
                    "dialog": dialog_id or "-",
                    "portrait": portrait_path or "-",
                    "portrait_kind": "generic" if "/generic/" in portrait_path else "dedicated",
                    "portrait_source": portrait_source,
                    "mode": movement_mode,
                    "idle": sprite_path or "-",
                    "walk": walk_sprite_path or "-",
                    "frames": str(frames),
                    "status": ", ".join(status) if status else "ok",
                }
            )
    # A story variant may reuse an NPC ID and sprite, but unrelated IDs sharing
    # one visual identity are release debt even when every referenced file exists.
    sprite_owners: dict[str, set[str]] = {}
    for record in records:
        if record["idle"] != "-":
            canonical_id = CANONICAL_NPC_IDS.get(record["npc_id"], record["npc_id"])
            sprite_owners.setdefault(record["idle"], set()).add(canonical_id)
    for record in records:
        if len(sprite_owners.get(record["idle"], set())) > 1:
            record["status"] = _append_status(record["status"], "identity-reuse")
    return records


def speaker_portraits(dialog_id: str, speaker: str) -> set[str]:
    """Return explicit portraits used by this NPC's own lines in a dialog."""
    if not dialog_id:
        return set()
    path = DIALOG_DIR / f"{dialog_id}.tres"
    if not path.exists():
        return set()
    text = read_text(path)
    portraits: set[str] = set()
    for block in re.findall(r'\[sub_resource.*?\](.*?)(?=\n\[|\Z)', text, re.S):
        if _assignment(block, "speaker") != speaker:
            continue
        portrait = _assignment(block, "portrait_path")
        if portrait:
            portraits.add(portrait)
    return portraits


def generic_portrait_for(npc_id: str, npc_name: str) -> str:
    identity = f"{npc_id} {npc_name}".lower()
    if any(token in identity for token in ("woman", "wife", "妇", "婆", "婶", "大娘", "女子")):
        if any(token in identity for token in ("old", "elder", "婆", "大娘")):
            return "res://art/characters/portraits/generic/portrait_generic_older_woman_v1.png"
        return "res://art/characters/portraits/generic/portrait_generic_young_woman_v1.png"
    if any(token in identity for token in ("old", "elder", "master", "keeper", "师傅", "掌柜", "教头", "猎户")):
        return "res://art/characters/portraits/generic/portrait_generic_older_man_v1.png"
    return "res://art/characters/portraits/generic/portrait_generic_young_man_v1.png"


def _append_status(current: str, addition: str) -> str:
    if current == "ok":
        return addition
    return current if addition in current.split(", ") else current + ", " + addition


def parse_enemies() -> list[dict[str, str]]:
    records: list[dict[str, str]] = []
    for path in sorted(ENEMY_DIR.glob("*.tres")):
        text = read_text(path)
        enemy_id = _assignment(text, "enemy_id")
        if not enemy_id:
            continue
        actor = _assignment(text, "battle_actor_path")
        attacks = len(re.findall(r'"res://[^"]+"', _packed_array(text, "attack_frame_paths")))
        hits = len(re.findall(r'"res://[^"]+"', _packed_array(text, "hit_frame_paths")))
        defeats = len(re.findall(r'"res://[^"]+"', _packed_array(text, "defeat_frame_paths")))
        status: list[str] = []
        if not resource_exists(actor):
            status.append("missing-actor")
        if attacks < 3:
            status.append("needs-attack-frames")
        if hits < 1:
            status.append("needs-hit-frame")
        records.append(
            {
                "enemy_id": enemy_id,
                "name": _assignment(text, "display_name") or enemy_id,
                "actor": actor or "-",
                "attacks": str(attacks),
                "hits": str(hits),
                "defeats": str(defeats),
                "status": ", ".join(status) if status else "ok",
            }
        )
    return records


def _packed_array(text: str, key: str) -> str:
    match = re.search(r'%s\s*=\s*PackedStringArray\((.*?)\)' % re.escape(key), text, re.S)
    return match.group(1) if match else ""


def table(headers: list[str], rows: list[list[str]]) -> str:
    result = ["| " + " | ".join(headers) + " |", "| " + " | ".join(["---"] * len(headers)) + " |"]
    for row in rows:
        result.append("| " + " | ".join(value.replace("|", "\\|") for value in row) + " |")
    return "\n".join(result)


def write_report(field: list[dict[str, str]], enemies: list[dict[str, str]]) -> None:
    dialog_npcs = [record for record in field if record["dialog"] != "-"]
    field_status = Counter(record["status"] for record in field)
    enemy_status = Counter(record["status"] for record in enemies)
    shared_sprites: dict[str, list[dict[str, str]]] = {}
    for record in field:
        if record["idle"] != "-":
            shared_sprites.setdefault(record["idle"], []).append(record)
    shared_sprites = {
        path: records
        for path, records in shared_sprites.items()
        if len({record["npc_id"] for record in records}) > 1
    }
    generic_portraits = [record for record in field if record["portrait_kind"] == "generic" and record["dialog"] != "-"]
    report = [
        "# NPC Roster And Asset Audit",
        "",
        "Generated by `python scripts/audit_npc_resources.py --write-report`. Do not edit generated tables by hand.",
        "",
        "## Query Sources",
        "",
        "- Scene placement and per-map dialogue: `game/data/scenes/*.tres` -> `npcs`.",
        "- Central overrides for a small cross-scene subset: `game/data/npcs/npc_catalog.tres`.",
        "- Dialogue content: `game/data/dialogs/<dialog_id>.tres`.",
        "- Combat enemies and battle animation paths: `game/data/enemies/*.tres`.",
        "",
        "## Coverage Summary",
        "",
        "| Category | Configured | Fully ready | Needs work |",
        "| --- | ---: | ---: | ---: |",
        "| Field NPC placements | %d | %d | %d |" % (len(field), sum(x["status"] == "ok" for x in field), sum(x["status"] != "ok" for x in field)),
        "| NPC placements with dialogue | %d | %d | %d |" % (len(dialog_npcs), sum(x["status"] == "ok" for x in dialog_npcs), sum(x["status"] != "ok" for x in dialog_npcs)),
        "| Battle enemy definitions | %d | %d | %d |" % (len(enemies), sum(x["status"] == "ok" for x in enemies), sum(x["status"] != "ok" for x in enemies)),
        "",
        "## Field NPC Roster",
        "",
        table(
            ["Scene", "NPC ID", "Name", "Dialog ID", "Portrait", "Portrait source", "Mode", "Idle frames", "Idle resource", "Walk resource", "Audit"],
            [[x["scene"], x["npc_id"], x["name"], x["dialog"], x["portrait"], x["portrait_source"], x["mode"], x["frames"], x["idle"], x["walk"], x["status"]] for x in field],
        ),
        "",
        "## Shared Field Sprite Review",
        "",
        "The following resources serve multiple NPC IDs. Same-character story variants may intentionally share a resource; different roles must receive their own sprite before release.",
        "",
        table(
            ["Idle resource", "NPC IDs currently sharing it"],
            [[path, ", ".join("%s (%s)" % (record["npc_id"], record["scene"]) for record in records)] for path, records in sorted(shared_sprites.items())],
        ),
        "",
        "## Generic Portrait Review",
        "",
        "Generic portraits are valid for minor residents, but this list is the manual visual-consistency queue. Promote recurring or visually distinctive NPCs to a dedicated portrait when the field sprite no longer matches the generic age, clothing, or role.",
        "",
        table(
            ["Scene", "NPC ID", "Name", "Portrait", "Source", "Idle resource"],
            [[x["scene"], x["npc_id"], x["name"], x["portrait"], x["portrait_source"], x["idle"]] for x in generic_portraits],
        ),
        "",
        "## Battle Enemy Roster",
        "",
        table(
            ["Enemy ID", "Name", "Battle actor", "Attack frames", "Hit frames", "Defeat frames", "Audit"],
            [[x["enemy_id"], x["name"], x["actor"], x["attacks"], x["hits"], x["defeats"], x["status"]] for x in enemies],
        ),
        "",
        "## Audit Rules",
        "",
        "- A field NPC must have a real idle sprite. Patrol NPCs additionally require a walk strip.",
        "- A talking NPC must have an existing portrait. If that NPC's own dialog nodes explicitly override the portrait, the scene and dialog bindings must match.",
        "- `identity-reuse` means unrelated NPC IDs share one idle resource; same-character story variants may share, unrelated roles must be replaced before release.",
        "- A dialog ID is required only for interactable NPCs; purely decorative actors may intentionally show `no-dialog`.",
        "- A battle enemy is production-ready only with its own battle actor, at least three attack frames, and a hit frame. See `docs/battle-enemy-asset-contract-v1.md` for the per-enemy contract.",
    ]
    REPORT.write_text("\n".join(report) + "\n", encoding="utf-8")
    print("Wrote", REPORT.relative_to(ROOT))
    print("Field status:", dict(field_status))
    print("Enemy status:", dict(enemy_status))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-report", action="store_true")
    args = parser.parse_args()
    field = parse_field_npcs()
    enemies = parse_enemies()
    if args.write_report:
        write_report(field, enemies)
        return
    for entry in field:
        print("FIELD", entry)
    for entry in enemies:
        print("ENEMY", entry)


if __name__ == "__main__":
    main()
