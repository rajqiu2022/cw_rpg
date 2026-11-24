"""Exact four-path append using the established 31d gallery method.

No inventory/build/consumer scan; old record serialization and non-resources
bytes are retained. Only four new thumbnails and thumbnail-cache keys are added.
"""

from collections import Counter
import copy
import hashlib
import json
from pathlib import Path
import re
import sys

from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT / "scripts"))
import build_resource_gallery as gallery

HTML = ROOT / "docs/equipment-skill-catalog.html"
CACHE = ROOT / "docs/assets/resources/thumbnail-index.json"
REGISTRATION = HERE / "asset_registration.json"


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def compact(value):
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def new_json(name, value):
    with (HERE / name).open("x", encoding="utf-8", newline="\n") as output:
        output.write(json.dumps(value, ensure_ascii=False, indent=2) + "\n")


def parse(raw):
    text = raw.decode("utf-8")
    match = re.search(r'<script id="catalogData" type="application/json">(.*?)</script>', text, re.S)
    assert match
    return text, match, json.loads(match[1])


def resources_span(raw):
    matches = list(re.finditer(r'"resources"\s*:\s*', raw))
    assert len(matches) == 1
    start = matches[0].end()
    _, end = json.JSONDecoder().raw_decode(raw, start)
    return start, end


def member_spans(raw):
    decoder = json.JSONDecoder()
    index = 1
    result = {}
    while True:
        while raw[index].isspace() or raw[index] == ",":
            index += 1
        if raw[index] == "}":
            return result
        key, index = decoder.raw_decode(raw, index)
        while raw[index].isspace():
            index += 1
        assert raw[index] == ":"
        index += 1
        while raw[index].isspace():
            index += 1
        start = index
        _, index = decoder.raw_decode(raw, index)
        result[key] = (start, index)


assert not (HERE / "catalog4_append_ACTUAL.json").exists(), "NEW_RUN_ONLY"
registration = json.loads(REGISTRATION.read_bytes())
assert len(registration["assets"]) == 2
before_html = HTML.read_bytes()
before_cache = CACHE.read_bytes()
scanner_sha = sha(ROOT / "scripts/build_resource_gallery.py")
text, match, data = parse(before_html)
before_data = copy.deepcopy(data)
resources = data["resources"]
old_count = len(resources["records"])
old_paths = {item["diskPath"] for item in resources["records"]}
cache = json.loads(before_cache)
updates = {}
rows = []
protected = {"game/build/luoyang_quality_20261101b_art01/asset_registration.json": sha(REGISTRATION)}
consumers = [registration[key] for key in ("runtime_consumer", "runtime_binding", "runtime_host")]
for asset in registration["assets"]:
    for path_key, hash_key in (("prompt_path", "prompt_sha256"), ("raw_path", "raw_sha256"),
                              ("runtime_path", "runtime_sha256"),
                              ("runtime_import_sidecar", "runtime_import_sidecar_sha256"),
                              ("runtime_ctex", "runtime_ctex_sha256")):
        assert sha(ROOT / asset[path_key]) == asset[hash_key], asset[path_key]
        protected[asset[path_key]] = asset[hash_key]
    for phase in ("raw", "runtime"):
        key = asset[phase + "_path"]
        path = ROOT / key
        assert key not in old_paths and key not in cache, ("NEW_PATH_ONLY", key)
        token = hashlib.sha256(key.encode()).hexdigest()[:24]
        thumbnail = "assets/resources/map/" + token + ".webp"
        assert not (ROOT / "docs" / thumbnail).exists(), "NEW_THUMBNAIL_ONLY"
        thumb, size = gallery.thumbnail(path, "map", cache, updates)
        assert thumb == thumbnail and size == asset[phase + "_size"]
        with Image.open(ROOT / "docs" / thumbnail) as preview:
            assert preview.width <= 360 and preview.height <= 220
            preview.verify()
        links = [asset["runtime_path"]] if phase == "raw" else consumers
        usage = [{"label": item, "url": "../" + item} for item in links]
        rows.append({
            "id": token, "name": asset["name"] + (" · 原图" if phase == "raw" else " · 工程图"),
            "category": "map", "categoryLabel": gallery.CATEGORIES["map"],
            "group": "洛阳 / 怡红院31b / " + ("原图来源" if phase == "raw" else "现役完整陈设"),
            "path": "res://" + key[5:] if key.startswith("game/") else key,
            "diskPath": key, "url": gallery.href(path), "thumbnail": thumbnail,
            "media": "image", "size": size, "bytes": path.stat().st_size,
            "format": "PNG", "duration": None, "status": "referenced",
            "statusLabel": "已采用来源 · 氛围待用户接受" if phase == "raw" else "现役局部已显示 · 非整体ART终验",
            "usage": usage, "usageCount": len(usage), "sceneIds": [registration["scene_id"]],
            "currentConsumers": [] if phase == "raw" else consumers,
            "consumerChain": [asset["raw_path"], asset["runtime_path"]] + consumers,
            "sourcePath": asset["raw_path"],
            "metadataPath": "game/build/luoyang_quality_20261101b_art01/asset_registration.json",
            "sha256": asset[phase + "_sha256"], "phase": "raw_selected" if phase == "raw" else "game_selected",
            "generation": {"backend": "builtin_image_gen", "model": None, "provider": None,
                           "cost": None, "modelIdentityVerified": False, "callsForThisRaw": 1,
                           "additionalGenerationForGameCopy": False,
                           "requestedSize": asset["requested_size"], "actualSize": asset["raw_size"]},
            "processing": asset["deterministic_postprocessing"],
            "note": "Root内置生成每原图1次，两图共2次；实际1774×887而非请求1536×1024。RAW原字节保；仅明确保护框外A1清理+四边64RGBA0，原RGB/保护RGBA保持，无裁主体/拉伸/重采样。墙饰一图三用、红毯一图一用。91364正常图已显示、mini同步，接待雅座氛围改善待用户；旧shell/楼上未开放/无新乐师，非整体身份或全ART通过。RAW只作来源，非运行直接加载。",
        })
assert len(rows) == 4 and len(updates) == 4
resources["records"].extend(rows)
for category in resources["categories"]:
    category["count"] = sum(row["category"] == category["id"] for row in resources["records"])
resources["summary"] = {
    "total": len(resources["records"]),
    "images": sum(row["media"] == "image" for row in resources["records"]),
    "audio": sum(row["media"] == "audio" for row in resources["records"]),
    "states": dict(Counter(row["status"] for row in resources["records"])),
}
assert resources["records"][:-4] == before_data["resources"]["records"]
assert {k: v for k, v in data.items() if k != "resources"} == {k: v for k, v in before_data.items() if k != "resources"}
start, end = resources_span(match[1])
old_resource_text = match[1][start:end]
spans = member_spans(old_resource_text)
new_resource_text = old_resource_text
for member in sorted(("records", "categories", "summary"), key=lambda key: spans[key][0], reverse=True):
    left, right = spans[member]
    if member == "records":
        old_array = old_resource_text[left:right]
        assert old_array.endswith("]")
        replacement = old_array[:-1] + "," + ",".join(compact(row) for row in rows) + "]"
    else:
        replacement = compact(resources[member])
    new_resource_text = new_resource_text[:left] + replacement + new_resource_text[right:]
new_payload = match[1][:start] + new_resource_text + match[1][end:]
new_html = (text[:match.start(1)] + new_payload + text[match.end(1):]).encode("utf-8")
after_text, after_match, after_data = parse(new_html)
assert after_data == data
after_start, after_end = resources_span(after_match[1])
assert text[:match.start(1) + start] + text[match.start(1) + end:] == after_text[:after_match.start(1) + after_start] + after_text[after_match.start(1) + after_end:]
new_spans = member_spans(new_resource_text)
left, right = new_spans["records"]
old_left, old_right = spans["records"]
assert new_resource_text[left:right].startswith(old_resource_text[old_left:old_right - 1] + ",")
cache_text = before_cache.decode("utf-8").rstrip()
assert cache_text.endswith("}")
new_cache = (cache_text[:-1].rstrip() + ",\n" + ",\n".join(
    "  " + json.dumps(key, ensure_ascii=False) + ": " + json.dumps(value, ensure_ascii=False, indent=2).replace("\n", "\n  ")
    for key, value in updates.items()) + "\n}\n").encode("utf-8")
assert json.loads(new_cache) == {**cache, **updates}
for key, expected in protected.items():
    assert sha(ROOT / key) == expected, key
assert scanner_sha == sha(ROOT / "scripts/build_resource_gallery.py")
assert HTML.read_bytes() == before_html and CACHE.read_bytes() == before_cache
for name, raw in (("catalog4_gallery_BEFORE.html", before_html), ("catalog4_cache_BEFORE.json", before_cache)):
    with (HERE / name).open("xb") as output:
        output.write(raw)
HTML.write_bytes(new_html)
CACHE.write_bytes(new_cache)
assert parse(HTML.read_bytes())[2] == data and json.loads(CACHE.read_bytes()) == {**cache, **updates}
new_json("catalog4_records_ACTUAL.json", rows)
proof = {
    "status": "EXACT_FOUR_RESOURCES_APPENDED_NO_INVENTORY_SCAN",
    "old_records": old_count, "new_records": old_count + 4, "new_raw_paths": 2, "new_runtime_paths": 2,
    "new_thumbnail_paths": ["docs/" + row["thumbnail"] for row in rows],
    "old_records_semantically_and_serialized_prefix_exact": True,
    "nonresources_and_HTML_outside_resources_exact": True,
    "old_cache_entries_exact": True, "cache_old_member_serialization_preserved": True,
    "old_cache_and_html_exact_backups": True, "protected_source_sha256": protected,
    "shared_scanner_sha256_unchanged": scanner_sha,
    "before_html_sha256": hashlib.sha256(before_html).hexdigest(), "after_html_sha256": sha(HTML),
    "before_cache_sha256": hashlib.sha256(before_cache).hexdigest(), "after_cache_sha256": sha(CACHE),
    "inventory_build_calls": 0, "source_scan_calls": 0, "engine_runs": 0,
    "asset_PNG_writes": 0, "imagegen_calls": 0,
}
new_json("catalog4_append_ACTUAL.json", proof)
print(json.dumps(proof, ensure_ascii=False, indent=2))
