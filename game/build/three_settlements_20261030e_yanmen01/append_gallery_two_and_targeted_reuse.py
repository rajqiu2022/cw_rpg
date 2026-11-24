"""Mechanical append of exactly two new rows and a six-source reuse manifest.

No global inventory/build call, source image edit, engine call or old-row update.
"""
from pathlib import Path
from collections import Counter
import copy
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).parent
sys.path.insert(0, str(ROOT / "scripts"))
import build_resource_gallery as gallery

HTML = ROOT / "docs/equipment-skill-catalog.html"
CACHE = ROOT / "docs/assets/resources/thumbnail-index.json"
AUTHOR = "game/build/three_settlements_20261030e_yanmen01/yanmen_author.gd"
AUTHOR_SHA = "b8ab26548498e93c51cd64c537076d8c268a300485970cc87f66fdaf34c122f0"
PNG_SHA = "0143a677757dba7f84a8ec8cef023a2fd5229d0d63efa8f406a95a2f64005419"
RAW = "assets/raw/yanmen_rebuild_20261030e/snow_gravel_v1.png"
GAME = "game/art/modules/yanmen_rebuild_20261030e/snow_gravel.png"


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


assert digest(ROOT / AUTHOR) == AUTHOR_SHA
promotion = json.loads((HERE / "art_promotion_ROOT_ACTUAL.json").read_text())
assert promotion["status"] == "ROOT_EXACT_THREE_LEAVES_PROMOTED"
assert promotion["verifier_natural_exit"] == 0
for leaf in promotion["leaves"]:
    assert digest(Path(leaf["path"])) == leaf["sha256"]

old_html = HTML.read_bytes()
old_cache_bytes = CACHE.read_bytes()
text = old_html.decode("utf-8")
match = re.search(r'<script id="catalogData" type="application/json">(.*?)</script>', text, re.S)
assert match
raw = match[1]
payload = json.loads(raw)
before = copy.deepcopy(payload)
resources = payload["resources"]
cache = json.loads(old_cache_bytes)
old_cache = copy.deepcopy(cache)
updates = {}
paths = [RAW, GAME]
assert not any(row["diskPath"] in paths for row in resources["records"])
note = "Root内置1次薄雪碎砾材质，实际1254×1254RGB，不满足请求1024²尺寸；原生完整字节保留，不缩放/裁切/清边/改色，无processed。原图/工程PNG同SHA，Root125884隔离逐RGBA精确/自然exit0，仅3新导入叶晋升。当前由雁门AuthorB8AB施工引用；北薄雪patch实际周期640、羽化160，灰岩/土底另为512。Root已看材质风格，不据导入或施工引用授整图ART/正式actual完成。RAW为来源追溯，不是引擎直接读取RAW。"
rows = []
for key in paths:
    path = ROOT / key
    assert digest(path) == PNG_SHA
    thumb, size = gallery.thumbnail(path, "map", cache, updates)
    rows.append({
        "id": hashlib.sha256(key.encode()).hexdigest()[:24],
        "name": "雁门关 · 薄雪碎砾地材",
        "category": "map", "categoryLabel": "地图组件",
        "group": "雁门关 / 北雪径地表 / " + ("原图" if key == RAW else "工程图"),
        "path": "res://" + key[5:] if key.startswith("game/") else key,
        "diskPath": key, "url": gallery.href(path), "thumbnail": thumb,
        "media": "image", "size": size, "bytes": path.stat().st_size,
        "format": "PNG", "duration": None, "status": "referenced",
        "statusLabel": "原图保留 · 本轮施工来源" if key == RAW else "工程图 · 雁门施工引用",
        "usage": [{"label": "雁门AuthorB8AB · 当前施工引用", "url": "../" + AUTHOR}],
        "usageCount": 1, "sceneIds": ["openworld_yanmen_pass"], "note": note,
        "sha256": PNG_SHA, "sourcePath": RAW,
        "generation": {"backend": "builtin_image_gen", "model": None, "provider": None, "cost": None},
        "consumerSha256": AUTHOR_SHA, "requestedSize": [1024,1024],
        "requestedSizeContractMet": False, "groundPeriodPx": [640,640],
    })
resources["records"].extend(rows)
for category in resources["categories"]:
    category["count"] = sum(row["category"] == category["id"] for row in resources["records"])
resources["summary"] = {
    "total": len(resources["records"]),
    "images": sum(row["media"] == "image" for row in resources["records"]),
    "audio": sum(row["media"] == "audio" for row in resources["records"]),
    "states": dict(Counter(row["status"] for row in resources["records"])),
}
assert resources["records"][:-2] == before["resources"]["records"]
assert {key:value for key,value in payload.items() if key != "resources"} == {key:value for key,value in before.items() if key != "resources"}
keys = list(re.finditer(r'"resources"\s*:\s*', raw))
assert len(keys) == 1
start = keys[0].end()
old_value, end = json.JSONDecoder().raw_decode(raw, start)
assert old_value == before["resources"]
new_raw = raw[:start] + json.dumps(resources, ensure_ascii=False, separators=(",", ":")) + raw[end:]
assert json.loads(new_raw) == payload
new_html = (text[:match.start(1)] + new_raw + text[match.end(1):]).encode("utf-8")
cache.update(updates)
assert set(updates) == set(paths)
assert {key:value for key,value in cache.items() if key not in paths} == {key:value for key,value in old_cache.items() if key not in paths}

# Read only these three authors and their explicitly selected shared dependencies.
authors = {
    "openworld_xiangzhou_city": "game/build/three_settlements_20261030e_system01/xiangzhou_author.gd",
    "openworld_qinghe_town": "game/build/three_settlements_20261030e_qinghe01/qinghe_author.gd",
    "openworld_yanmen_pass": AUTHOR,
}
common = "game/build/three_settlements_20261030e_system01/common_author.gd"
river = "game/build/jinling_city_20261029_system01/city_author.gd"
binding = "game/build/jinling_city_20261029_system01/river_binding_BUILD.json"
source_keys = list(authors.values()) + [common, river, binding]
source_texts = {key:(ROOT/key).read_text(encoding="utf-8-sig") for key in source_keys}
source_hashes = {key:digest(ROOT/key) for key in source_keys}


def literal_constants(value):
    return dict(re.findall(r'const\s+(\w+)\s*(?::\s*String)?\s*(?::=|=)\s*"(res://[^"\n]+)"', value))


common_values = literal_constants(source_texts[common])
river_values = literal_constants(source_texts[river])
binding_value = json.loads(source_texts[binding])
reuse = []
for scene_id, author in authors.items():
    source = source_texts[author]
    values = literal_constants(source)
    for name, owner, field in re.findall(r'const\s+(\w+)\s*:?=\s*(Common|C|River)\.(\w+)', source):
        resolved = (river_values if owner == "River" else common_values).get(field)
        if resolved:
            values[name] = resolved
    for name, path in re.findall(r'var\s+(\w+)(?::\s*String)?\s*:?=\s*"(res://[^"\n]+)"', source):
        values[name] = path
    sources = set(re.findall(r'"(res://[^"\n]+\.(?:png|jpg|jpeg|wav))"', source))
    sources.update(path for path in values.values() if Path(path).suffix.lower() in {".png", ".jpg", ".jpeg", ".wav"})
    for name, suffix in re.findall(r'(\w+)\s*\+\s*"([^"\n]+\.(?:png|jpg|jpeg|wav))"', source):
        if name in values:
            sources.add(values[name] + suffix)
    if scene_id == "openworld_yanmen_pass":
        sources.update(values["HUA"] + name + ".png" for name in re.findall(r'_house\("[^"]+","([^"]+)"', source))
    if "river_binding()" in source:
        for section in ["objects", "ground", "foreground"]:
            sources.update(row["texture"] for row in binding_value.get(section, []) if "texture" in row)
    # Qinghe uses only approved bridge foreground UVs, not Jinling ship objects.
    if scene_id == "openworld_qinghe_town":
        sources.update(row["texture"] for row in binding_value.get("foreground", []) if str(row.get("id", "")).startswith("west_bridge_") and "texture" in row)
    assets = []
    for resource in sorted(sources):
        path = ROOT / "game" / resource[6:]
        assert path.is_file(), resource
        assets.append({"resource":resource, "sha256":digest(path), "bytes":path.stat().st_size})
    reuse.append({"scene_id":scene_id, "author":author, "author_sha256":source_hashes[author], "status":"CURRENT_AUTHOR_CONSTRUCTION_REFERENCES_NOT_NEW_ART_ACCEPTANCE", "assets":assets})
assert source_hashes[AUTHOR] == AUTHOR_SHA
assert all(digest(ROOT/key) == value for key,value in source_hashes.items())
manifest = {"status":"TARGETED_THREE_AUTHORS_DIRECT_MEDIA_AND_EXPLICIT_BINDINGS_ONLY", "source_count":len(source_keys), "sources":source_hashes, "scope_note":"Only these three authors and Common/Jinling author/explicit river binding read. Constant concatenations and named house variants resolved; not a full inventory or claimed exhaustive runtime dependency graph. Old gallery rows are not updated or re-accepted.", "authors":reuse, "new_image_paths":[RAW,GAME], "processed_paths":[], "inventory_build_calls":0, "engine_calls":0}

assert not (HERE / "gallery_before_exact_two.html").exists()
assert HTML.read_bytes() == old_html and CACHE.read_bytes() == old_cache_bytes
(HERE / "gallery_before_exact_two.html").write_bytes(old_html)
(HERE / "gallery_cache_before_exact_two.json").write_bytes(old_cache_bytes)
HTML.write_bytes(new_html)
CACHE.write_text(json.dumps(cache, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
(HERE / "reuse_index_three_authors_TARGETED.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
(HERE / "gallery_two_records.json").write_text(json.dumps(rows, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
receipt = {"status":"EXACT_TWO_GALLERY_ROWS_AND_TARGETED_REUSE_MANIFEST_WRITTEN", "old_total":before["resources"]["summary"]["total"], "new_summary":resources["summary"], "paths":paths, "old_records_preserved":True, "non_resources_equal":True, "old_cache_entries_preserved":True, "html_outside_catalogData_preserved":True, "thumbnail_paths":[entry["thumbnail"] for entry in updates.values()], "reuse_source_count":len(source_keys), "reuse_assets_per_author":{row["scene_id"]:len(row["assets"]) for row in reuse}, "source_asset_png_writes":0, "engine_calls":0, "inventory_build_calls":0}
(HERE / "gallery_two_actual.json").write_text(json.dumps(receipt, ensure_ascii=False, indent=2)+"\n", encoding="utf-8")
print(json.dumps(receipt, ensure_ascii=False))
