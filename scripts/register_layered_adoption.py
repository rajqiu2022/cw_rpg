"""Update the gallery's resource records for the formal named weapon appearances."""
from collections import Counter
from hashlib import sha1, sha256
import json
from pathlib import Path
import re
import sys

root = Path(__file__).resolve().parents[1]
gallery = root / "docs/equipment-skill-catalog.html"
runtime = root / "game/art/characters/layered_actor_adoption_20261106"
manifest = json.loads((runtime / "appearance.json").read_text(encoding="utf-8"))
raw = root / "assets/raw/layered_actor_adoption_20261106"
new = {r["name"]: r for r in json.loads((raw / "generation.json").read_text(encoding="utf-8")) if r["accepted"]}
names = {"walk_mid_clean": "侧向行走补间 · 4帧", "walk_down_mid": "正面行走补间 · 4帧",
         "walk_up_mid": "背面行走补间 · 4帧", "attack_dao": "烬河断岳刀专属挥击 · 4帧"}
carry_source = root / "assets/raw/layered_actor_carry_20261107/generation.json"
if carry_source.exists():
    carry = json.loads(carry_source.read_text(encoding="utf-8"))
    manifest["textures"]["carry_atlas"] = carry["res_path"]
    manifest["sha256"]["carry_atlas"] = carry["sha256"]
    new["carry_atlas"] = carry
    names["carry_atlas"] = "普通剑刀棍与七星剑腰挂剑鞘"
batch02 = "--legendary-batch02" in sys.argv
field_sheaths = "--field-sheaths" in sys.argv
legendary = batch02 or "--legendary" in sys.argv
if legendary or field_sheaths:
    if field_sheaths:
        source_dir = "weapon_field_carry_20261108"
    elif batch02:
        source_dir = "legendary_weapons_batch02_20261108"
    else:
        source_dir = "legendary_weapons_20261108"
    sources = json.loads((root / "assets/raw" / source_dir / "generation.json").read_text(encoding="utf-8"))
    manifest = {"textures": {r["key"]: r["res_path"] for r in sources},
                "sha256": {r["key"]: r["sha256"] for r in sources}}
    new = {r["key"]: r for r in sources}
    names = {r["key"]: r["name"] for r in sources}

before = gallery.read_bytes()
html = before.decode("utf-8")
block = re.search(r'(<script id="catalogData" type="application/json">)(.*?)(</script>)', html, re.S)
data = json.loads(block.group(2))
resources = data["resources"]
records = resources["records"]
by_path = {r["diskPath"]: r for r in records}
count_before = len(records)
changed = []
uses = {
    "field": {"label": "正式地图 · 名器外显", "url": "../game/scenes/field_walkable.tscn"},
    "battle": {"label": "正式战斗 · 名器外显", "url": "../game/scenes/battle.tscn"},
}
for key, res_path in manifest["textures"].items():
    disk = "game/" + res_path.removeprefix("res://")
    original = (new[key]["raw"].replace("\\", "/") if key in new else
                "assets/raw/layered_actor_20261106/" + key + ".png")
    for is_runtime, path in ((True, disk), (False, original)):
        file = root / path
        assert sha256(file.read_bytes()).hexdigest() == manifest["sha256"][key]
        row = by_path.get(path)
        if row is None:
            url = "../" + path
            row = {
                "id": sha1(path.encode()).hexdigest()[:24], "name": names[key],
                "category": "player" if is_runtime else "candidate",
                "categoryLabel": "主角与武器" if is_runtime else "新增候选",
                "path": res_path if is_runtime else path, "diskPath": path, "url": url,
                "thumbnail": url, "media": "image", "size": new[key]["size"],
                "bytes": file.stat().st_size, "format": "PNG", "duration": None, "sceneIds": [],
                "sha256": manifest["sha256"][key],
                "generation": {"backend": "builtin_image_gen", "model": None, "provider": None, "fallback_used": False},
            }
            records.append(row)
        if is_runtime:
            consumers = [uses["battle"]] if key in {"attack", "attack_dao", "hit", "defeat_v3", "suwusheng_teapot"} else (
                [uses["field"]] if "_up" in key or "_down" in key or key == "field_sheaths" else list(uses.values()))
        else:
            consumers = [{"label": "正式外显使用的原图", "url": "../" + disk}]
        group = "分层2D神兵首批 / " if legendary else "分层2D主角与武器 / "
        if batch02:
            group = "分层2D神兵第二批 / "
        note = ("独立武器外显，按现有装备ID接入地图与战斗。详 changes/legendary-weapons-20261108.md。" if legendary else
                "冷孤云高清分层外观。普通剑刀棍按类型显示，七星剑按装备 ID 使用腰挂剑鞘和专属刃光。详 changes/layered-actor-carry-20261107.md。")
        if batch02:
            note = "现役装备的分层2D外显素材。详 changes/legendary-weapons-batch02-20261108.md。"
        if field_sheaths:
            note = "普通剑、普通刀与烬河断岳刀的非战斗腰佩图集。详 changes/weapon-field-carry-20261108.md。"
        row.update(group=group + ("正式工程素材" if is_runtime else "原生来源"),
                   status="adopted" if is_runtime else "referenced", statusLabel="正式接入" if is_runtime else "正式素材来源",
                   usage=consumers, usageCount=len(consumers),
                   note=note)
        changed.append(path)

counts = Counter(r["category"] for r in records)
for category in resources["categories"]:
    category["count"] = counts[category["id"]]
resources["summary"].update(total=len(records), images=sum(r["media"] == "image" for r in records),
                            audio=sum(r["media"] == "audio" for r in records),
                            states=dict(Counter(r["status"] for r in records)))
updated = html[:block.start(2)] + json.dumps(data, ensure_ascii=False, separators=(",", ":")) + html[block.end(2):]
assert gallery.read_bytes() == before, "Concurrent gallery update"
gallery.write_bytes(updated.encode("utf-8"))
print(json.dumps({"before": count_before, "after": len(records), "updated_paths": changed}, ensure_ascii=False))
