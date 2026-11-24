import hashlib
import json
import re
from collections import Counter
from pathlib import Path
from PIL import Image

path = Path("docs/equipment-skill-catalog.html")
html = path.read_bytes()
match = re.search(rb'<script id="catalogData" type="application/json">(.*?)</script>', html, re.S)
data = json.loads(match[1])
catalog = data["resources"]
records = catalog["records"]
labels = {category["id"]: category["name"] for category in catalog["categories"]}
batch = "story_enemies_20261109"
records[:] = [entry for entry in records if batch not in entry["diskPath"]]
added = []

def publish(name, category, raw_path, live_path, usages, scene_ids, note, group):
    source = Path(raw_path).read_bytes()
    runtime = Path(live_path).read_bytes()
    assert source == runtime, live_path
    digest = hashlib.sha256(runtime).hexdigest()
    with Image.open(live_path) as image:
        size = list(image.size)
    for disk, is_live in [(live_path, True), (raw_path, False)]:
        label = category if is_live else "candidate"
        entries = usages if is_live else [("正式图", live_path)]
        record = {
            "id": hashlib.sha256(disk.encode()).hexdigest()[:22],
            "name": name if is_live else name + " · 原图",
            "category": label, "categoryLabel": labels[label], "group": group,
            "path": "res://" + disk.removeprefix("game/") if is_live else disk,
            "diskPath": disk, "url": "../" + disk, "thumbnail": "../" + disk,
            "media": "image", "size": size, "bytes": len(runtime), "format": "PNG",
            "duration": None, "status": "adopted" if is_live else "candidate",
            "statusLabel": "正式接入" if is_live else "来源原图",
            "usage": [{"label": title, "url": "../" + link} for title,link in entries],
            "usageCount": len(entries), "sceneIds": scene_ids if is_live else [],
            "sha256": digest,
            "generation": {"backend":"builtin_image_gen","model":None,"provider":None,"fallback_used":False},
            "note": note + " 原图与运行 PNG 字节一致。"
        }
        added.append(record)
        records.append(record)

publish("山贼洞窟 · 成人木床", "map",
        f"assets/raw/{batch}/cave_adult_bed.png",
        f"game/art/modules/{batch}/cave_adult_bed.png",
        [("洞窟布局", "game/data/maps/interior_bandit_cave_layout_v2.tres")],
        ["interior_bandit_cave"], "木床、薄被与枕头为一个场景组件，床底设置碰撞。", "山贼洞窟")
names = {
    "bandit_cave_guard": ("留守山贼", ["interior_bandit_cave"], "interior_bandit_cave_guard"),
    "ch5_relief_road_raider": ("雪路劫粮客", ["ch5_s1_relief_road", "ch5_s2_grain_convoy_camp"], None),
    "openworld_snow_raider": ("关外刀匪", ["openworld_yanmen_pass", "openworld_yanmen_hidden_cave"], None),
    "openworld_yanmen_cave_guard": ("寒岭守藏人", ["openworld_yanmen_hidden_cave"], "openworld_yanmen_cave_guard"),
}
for id, (name, scene_ids, dialog) in names.items():
    for kind, title, category, detail in (
        ("ready", "备战待机四帧", "npc" if dialog else "battle", "同向待机序列，按脚底对齐。"),
        ("attack", "挥刀四帧", "battle", "起势、举刀、出刀、收势。"),
        ("reaction", "步进与受击四帧", "battle", "供步进、受击、跪倒和倒地状态调用。"),
        ("portrait", "独立对白立绘", "portrait", "按同角色精灵造型制作。"),
    ):
        if kind == "portrait" and dialog is None: continue
        usages = [("战斗配置", f"game/data/enemies/{id}.tres")]
        if dialog and kind == "ready":
            usages.append(("地图待机",f"game/data/scenes/{scene_ids[0]}.tres"))
        if kind == "portrait":
            usages.append(("剧情对白",f"game/data/dialogs/{dialog}.tres"))
        publish(name + " · " + title, category, f"assets/raw/{batch}/{id}/{kind}.png",
                f"game/art/characters/{batch}/{id}/{kind}.png", usages, scene_ids, detail, name)

counts = Counter(entry["category"] for entry in records)
for category in catalog["categories"]:
    category["count"] = counts[category["id"]]
catalog["summary"].update(total=len(records), images=sum(entry["media"]=="image" for entry in records),
                          audio=sum(entry["media"]=="audio" for entry in records),
                          states=dict(Counter(entry["status"] for entry in records)))
payload = json.dumps(data, ensure_ascii=False, separators=(",",":")).replace("</",r"<\/").encode()
path.write_bytes(html[:match.start(1)]+payload+html[match.end(1):])
print("New records:", len(added), "Total:", len(records))

