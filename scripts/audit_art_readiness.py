"""Read-only art/data inventory; writes an explicitly bounded audit, never saves/game data.

Run: python scripts/audit_art_readiness.py --output docs/audits/art-readiness-20261106.json
Counts describe authored definitions/references, not in-game availability or art acceptance.
"""
import argparse
import collections
import datetime
import hashlib
import json
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[1]


def local(path):
    return ROOT / ("game/" + path[6:] if path.startswith("res://") else path)


def metadata(path):
    p = local(path)
    if not path or not p.is_file():
        return {"exists": False}
    raw = p.read_bytes()
    result = {"exists": True, "sha256": hashlib.sha256(raw).hexdigest()}
    if raw[:8] == b"\x89PNG\r\n\x1a\n":
        result["canvas_px"] = list(struct.unpack(">II", raw[16:24]))
    return result


def definitions(folder, id_key):
    rows = []
    for p in sorted((ROOT / "game/data" / folder).glob("*.tres")):
        text = p.read_text(encoding="utf-8-sig")
        fields = dict(re.findall(r"^(\w+)\s*=\s*(.*?)\s*$", text, re.M))
        fields = {k: v.removeprefix("&").strip('"') for k, v in fields.items()}
        if id_key not in fields:
            raise ValueError(f"Unparsed definition: {p}")
        keep = [id_key, "display_name", "quality", "slot", "weapon_type", "category",
                "icon_path", "animation_id", "study_skill_id", "readable", "kind", "school"]
        row = {k: fields[k] for k in keep if k in fields}
        row.update(path=p.relative_to(ROOT).as_posix(),
                   source_sha256=hashlib.sha256(p.read_bytes()).hexdigest())
        icon = fields.get("icon_path", "")
        row["icon"] = metadata(icon) if icon else {"state": "category_fallback"}
        rows.append(row)
    groups = collections.defaultdict(list)
    for row in rows:
        groups[row.get("icon_path", "")].append(row[id_key])
    return {"definition_count": len(rows),
            "explicit_icon_count": sum(bool(r.get("icon_path")) for r in rows),
            "fallback_count": len(groups.get("", [])),
            "unique_explicit_icon_paths": len([p for p in groups if p]),
            "missing_explicit_icons": [r[id_key] for r in rows if r.get("icon_path") and not r["icon"]["exists"]],
            "shared_explicit_icons": {k: v for k, v in groups.items() if k and len(v) > 1},
            "quality_counts": dict(collections.Counter(r.get("quality", "0_default") for r in rows)),
            "rows": rows}


def audit():
    gallery_path = ROOT / "docs/equipment-skill-catalog.html"
    gallery_raw = gallery_path.read_bytes()
    gallery = json.loads(re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',
                                  gallery_raw.decode("utf-8-sig"), re.S).group(1))
    records = gallery["resources"]["records"]
    categories = {}
    for category in sorted({r["category"] for r in records}):
        subset = [r for r in records if r["category"] == category]
        categories[category] = {"records": len(subset),
            "statuses": dict(collections.Counter(r["status"] for r in subset)),
            "game_path_records": sum(r.get("diskPath", "").startswith("game/") for r in subset),
            "groups": dict(collections.Counter(r.get("group", "") for r in subset))}
    packs = []
    for p in sorted((ROOT / "game/art/modules").glob("*/resource-pack.json")):
        d = json.loads(p.read_text(encoding="utf-8-sig"))
        assets = d.get("assets", [])
        packs.append({"path": p.relative_to(ROOT).as_posix(), "status": d.get("status"),
            "asset_rows": len(assets), "kinds": dict(collections.Counter(a.get("kind", "unspecified") for a in assets)),
            "assets": [{k: a[k] for k in ["key", "label", "kind", "output", "scene", "scenes"] if k in a} for a in assets]})
    data = {f: definitions(f, "skill_id" if f == "skills" else "item_id") for f in ["equipment", "items", "skills"]}
    vfx_path = ROOT / "game/scripts/battle/battle_vfx_player.gd"
    vfx = vfx_path.read_text(encoding="utf-8-sig")
    direct = dict(re.findall(r'&"([^"]+)"\s*:\s*\{\s*"sheet"\s*:\s*"([^"]+)"', vfx))
    unique = re.findall(r'&"([^"]+)"', re.search(r'const UNIQUE_EFFECT_IDS.*?=\s*\[(.*?)\]', vfx, re.S).group(1))
    effects = {k: "res://art/battle_vfx/skill_unique_v1/vfx_%s_4frame_v1.png" % k for k in unique}
    effects.update(direct)  # The real consumer gives explicit entries precedence.
    used = collections.Counter(r.get("animation_id", "") for r in data["skills"]["rows"])
    data["vfx"] = {"consumer": vfx_path.relative_to(ROOT).as_posix(),
        "direct_entries": len(direct), "unique_id_entries": len(unique), "resolved_effect_ids": len(effects),
        "skill_animation_ids": dict(used), "missing_skill_mappings": [k for k in used if k not in effects],
        "missing_mapped_sheets": {k: p for k, p in effects.items() if not local(p).is_file()}, "effects": effects}
    return {"captured_at": datetime.datetime.now().astimezone().isoformat(),
        "scope": "Static authored definitions, catalog snapshot, module manifests and VFX mappings; NOT runtime travel, unlock coverage, visual acceptance or target-device performance.",
        "gallery": {"sha256": hashlib.sha256(gallery_raw).hexdigest(), "embedded_generatedAt": gallery.get("generatedAt"),
                    "record_count": len(records), "categories": categories,
                    "warning": "Raw/processed/runtime, candidates and histories are mixed. Labels are editorial evidence, not proof of current adoption. Embedded date may be stale."},
        "module_packs": packs, **data}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    output = (ROOT / args.output).resolve()
    if not output.is_relative_to(ROOT / "docs/audits"):
        raise ValueError("Output must stay under docs/audits")
    result = audit()
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(str(output))
    for key in ["equipment", "items", "skills"]:
        print(key, {k: v for k, v in result[key].items() if k not in ["rows", "shared_explicit_icons"]})
    print("vfx", {k: v for k, v in result["vfx"].items() if k not in ["effects", "skill_animation_ids"]})
