"""Append only this prototype's byte-identical source/runtime assets to the existing gallery."""
from collections import Counter
from copy import deepcopy
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
path = ROOT / "docs/equipment-skill-catalog.html"
before = path.read_bytes()
text = before.decode("utf-8")
match = re.search(r'(<script id="catalogData" type="application/json">)(.*?)(</script>)', text, re.S)
data = json.loads(match.group(2))
old = deepcopy(data)
records = data["resources"]["records"]
known = {r["diskPath"] for r in records}
directions = "--directions" in sys.argv
generation_file = "directions_generation.json" if directions else "generation.json"
generation = json.loads((ROOT / "assets/raw/layered_actor_20261106" / generation_file).read_text(encoding="utf-8"))
names = {"idle":"无武器人物·待机4帧", "walk":"无武器人物·行走4帧", "attack":"无武器人物·挥击4帧",
         "sword":"七星龙泉剑·独立武器", "blade":"烬河断岳刀·独立武器", "starfx":"七星剑·局部星芒4帧", "emberfx":"断岳刀·局部余烬4帧"}
names.update(idle_down="分层人物·正面待机4帧",idle_up="分层人物·背面待机4帧",
             walk_down="分层人物·正面行走4帧",walk_up="分层人物·背面行走4帧",
             attack_down="分层人物·正面挥击4帧",attack_up="分层人物·背面挥击4帧",
             hit="分层人物·侧向受击4帧",defeat="分层人物·侧向倒地4帧")
names['defeat_v3']="分层人物·侧向倒地4帧·留白修正版"
added = []
for asset in generation["records"]:
    for kind in ["raw", "runtime"]:
        disk = asset[kind]
        if disk in known:
            continue
        blob = (ROOT / disk).read_bytes()
        assert hashlib.sha256(blob).hexdigest() == asset["sha256"]
        category = "player" if kind == "runtime" else "candidate"
        url = "../" + disk
        row = {"id": hashlib.sha1(disk.encode()).hexdigest()[:24], "name": names[asset["key"]],
               "category": category, "categoryLabel":"主角与武器" if kind=="runtime" else "新增候选",
               "group":("分层2D四向续作20261106 / " if directions else "分层2D样板20261106 / ") + ("工程样板" if kind=="runtime" else "原生来源"),
               "path":"res://"+disk[5:] if kind=="runtime" else disk, "diskPath":disk,
               "url":url, "thumbnail":url, "media":"image", "size":asset["size"], "bytes":len(blob),
               "format":"PNG", "duration":None, "status":"candidate", "statusLabel":"分层样板 · 未正式采用",
               "usage":[{"label":"独立分层试验台（非正式主角）", "url":"../game/build/layered_actor_20261106_lab/preview.tscn"}],
               "usageCount":1, "sceneIds":[], "sha256":asset["sha256"],
               "note":"内置生图，原RGBA字节完整保留，无本地重画/裁切/清alpha。右向+左镜像，3动作各4帧；同身体切两武器。样板验证不等于正式地图/战斗接入。详 changes/layered-actor-prototype-20261106.md。",
               "generation":{"backend":"builtin_image_gen", "model":None,"provider":None,"fallback_used":False}}
        records.append(row)
        if directions:
            row["note"]="内置生图，原RGBA字节保留。正背待机/行走/挥击各4帧、侧向受击/倒地各4帧；虎口挂点、独立武器/光效。左向镜像；非完整八帧步态、非正式主角采用。原正面行走v1背景与迈腿不合格，不消费。详 changes/layered-actor-prototype-20261106.md。"
        added.append(disk)
counts = Counter(r["category"] for r in records)
retired_paths = set()
if directions:
    for rejected in generation.get('rejected',[]):
        for kind in ('raw','runtime'):
            if kind in rejected: retired_paths.add(rejected[kind])
    for row in records:
        if row['diskPath'] in retired_paths:
            row.update(status='candidate',statusLabel='已停用候选 · 未消费',usage=[],usageCount=0,
                       note='本轮逐帧检查未通过：旧倒地末两帧贴分格边；保留原图，不再由试验台消费，替换为defeat_v3。')
for category in data["resources"]["categories"]:
    category["count"] = counts[category["id"]]
summary = data["resources"]["summary"]
summary.update(total=len(records), images=sum(r["media"]=="image" for r in records),
               audio=sum(r["media"]=="audio" for r in records), states=dict(Counter(r["status"] for r in records)))
assert [r for r in records[:len(old['resources']['records'])] if r['diskPath'] not in retired_paths] == [r for r in old['resources']['records'] if r['diskPath'] not in retired_paths]
assert {k:v for k,v in data.items() if k!="resources"} == {k:v for k,v in old.items() if k!="resources"}
result = text[:match.start(2)] + json.dumps(data, ensure_ascii=False, separators=(",",":")) + text[match.end(2):]
assert path.read_bytes() == before, "Concurrent gallery edit detected; rerun from fresh file."
path.write_bytes(result.encode("utf-8"))
receipt = {"before_sha256":hashlib.sha256(before).hexdigest(), "after_sha256":hashlib.sha256(path.read_bytes()).hexdigest(),
           "old_records":len(old["resources"]["records"]), "new_records":len(records), "added":added,
           "old_records_preserved_except_retired_usage":sorted(retired_paths & known), "non_resource_sections_preserved":True,
           "thumbnails":"Original PNG URLs rendered by existing thumbnail/lightbox UI; no image pixels transformed."}
receipt_name = "directions_gallery_receipt_final.json" if directions else "gallery_receipt.json"
(ROOT / "game/build/layered_actor_20261106_lab/evidence" / receipt_name).write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps({"before":receipt["old_records"],"after":receipt["new_records"],"added":len(added)}))
