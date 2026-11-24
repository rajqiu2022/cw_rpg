from collections import Counter
from hashlib import sha256
from pathlib import Path
import json
import re

catalog = Path("docs/equipment-skill-catalog.html")
html = catalog.read_bytes()
embed = re.search(rb'<script id="catalogData" type="application/json">(.*?)</script>', html, re.S)
data = json.loads(embed[1])
resources = data["resources"]
batch = "menu_buttons_20261109"
records = [row for row in resources["records"] if batch not in row["diskPath"]]
if not any(row["id"]=="ui" for row in resources["categories"]):
    resources["categories"].append({"id":"ui","name":"界面按钮","count":0})

ui = {
    "system": ("系统菜单左栏 · 四态玄铁按钮", ["system_menu.gd"]),
    "hud": ("地图快捷菜单 · 四态寒玉按钮", ["field_menu_runtime.gd"]),
    "compact": ("存档与交易操作 · 四态按钮", ["save_slot_panel.gd", "shop_ui.gd"]),
    "action": ("行囊与数量操作 · 四态方形按钮", ["field_menu_runtime.gd", "shop_ui.gd"]),
}
for family,(name,consumers) in ui.items():
    runtime = f"game/art/ui/{batch}/{family}.png"
    source = f"assets/raw/ui/{batch}/{family}.png"
    payload = Path(runtime).read_bytes()
    info = json.loads(Path(source).with_suffix(".meta.json").read_text(encoding="utf-8"))
    assert Path(source).read_bytes() == payload
    assert sha256(payload).hexdigest()==info["sha256"]
    for disk, adopted in ((runtime,True),(source,False)):
        links = [{"label":"正式使用","url":"../game/scripts/ui/"+script} for script in consumers] if adopted else [{"label":"正式图","url":"../"+runtime}]
        records.append({
            "id":sha256(disk.encode()).hexdigest()[:22],"name":name if adopted else name+" · 原图",
            "category":"ui" if adopted else "candidate", "categoryLabel":"界面按钮" if adopted else "新增候选",
            "group":"寒山玄铁 · 菜单按钮",
            "path":"res://"+disk.removeprefix("game/") if adopted else disk,
            "diskPath":disk,"url":"../"+disk,"thumbnail":"../"+disk,
            "media":"image","size":info["size"],"bytes":len(payload),"format":"PNG","duration":None,
            "status":"adopted" if adopted else "candidate","statusLabel":"正式接入" if adopted else "来源原图",
            "usage":links,"usageCount":len(links),"sceneIds":[],
            "sha256":info["sha256"],"generation":{k:info[k] for k in ("backend","model","provider","fallback_used")},
            "note":"普通、悬停、按下和禁用四态。每个状态由图集取框，文字由游戏排版。"
        })
resources["records"]=records
cats=Counter(row["category"] for row in records)
for group in resources["categories"]:
    group["count"]=cats[group["id"]]
resources["summary"].update(total=len(records),images=sum(row["media"]=="image" for row in records),
                            audio=sum(row["media"]=="audio" for row in records),states=dict(Counter(row["status"] for row in records)))
json_data=json.dumps(data,ensure_ascii=False,separators=(",",":")).replace("</",r"<\/").encode()
catalog.write_bytes(html[:embed.start(1)]+json_data+html[embed.end(1):])
print("Added 4 runtime atlases and 4 sources. Total:",len(records))

