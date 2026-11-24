"""Root-authorized 19-record resources-only append using existing thumbnail helper."""
from pathlib import Path
from collections import Counter
import copy
import hashlib
import json
import re
import sys
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/"scripts"))
import build_resource_gallery as gallery

HTML=ROOT/"docs/equipment-skill-catalog.html"
CACHE=ROOT/"docs/assets/resources/thumbnail-index.json"
PLAN=HERE/"catalog_patch_list_READY_02.json"
RECORDS=HERE/"catalog_records_READY_02.json"
BINDING="game/art/modules/world_bridges_20261030m/bridge_bindings.json"
HELPER="game/build/world_bridges_20261030m_system01/bridge_visual_patch.gd"
STREAM="game/scripts/world/world_v15_visible_stream_20261018r.gd"
OVERLAP="game/scripts/world/world_v15_stream_overlap_20261018r.gd"
PINS={BINDING:"9a5a767a8a71c80b25d44d4630e2fa4d714a446141edc4aa8592435ca3f3082e",
      HELPER:"ef10cc93e67373f963fd459299a27adc89638491e607a6bdb100a687a9f21256",
      STREAM:"06108350bc7be28287453cd706a368a7d3078626778af4fb38004f9826b50eb8",
      OVERLAP:"5803cdaf0056645d63f6ba35feb0af8c48089ddd7a859c63a18b5354785a0d77"}

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load(path):return json.loads(path.read_text(encoding="utf-8-sig"))
def dump(name,data):
    path=HERE/name;assert not path.exists()
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
def parse(raw):
    text=raw.decode("utf-8")
    m=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
    return text,m,json.loads(m[1])
def split_resources(text,m):
    raw=m[1];keys=list(re.finditer(r'"resources"\s*:\s*',raw));assert len(keys)==1
    start=keys[0].end();_,end=json.JSONDecoder().raw_decode(raw,start)
    return start,end,text[:m.start(1)+start]+text[m.start(1)+end:]

plan=load(PLAN);rows=load(RECORDS)
assert plan["known_records"]==plan["expected_records"]==len(rows)==19 and plan["v5_pending"] is None
for key,pin in PINS.items():assert sha(ROOT/key)==pin,key
binding=load(ROOT/BINDING)
assert binding["approved"] is True
by_id={row["id"]:row for row in binding["bridges"]}
assert len(by_id)==5
for raw in by_id.values():
    image=raw["resource"]
    assert image["full_RGBA_exact"] is True and image["mipmap_count"]==0
    assert sha(ROOT/"game"/image["path"][6:])==image["sha256"]
assert PINS[BINDING] in (ROOT/STREAM).read_text(encoding="utf-8")
assert "world_bridges_20261030m_system01/bridge_visual_patch.gd" in (ROOT/STREAM).read_text(encoding="utf-8")
assert "res://art/modules/world_bridges_20261030m/bridge_bindings.json" in (ROOT/HELPER).read_text(encoding="utf-8")

before_html=HTML.read_bytes();before_cache=CACHE.read_bytes()
assert hashlib.sha256(before_html).hexdigest()==plan["baseline"]["html_sha256"]
assert hashlib.sha256(before_cache).hexdigest()==plan["baseline"]["cache_sha256"]
text,m,data=parse(before_html);old=copy.deepcopy(data);resources=data["resources"]
assert len(resources["records"])==5234
cache=json.loads(before_cache);old_cache=copy.deepcopy(cache)
paths=[row["diskPath"] for row in rows]
assert len(set(paths))==19
assert all(r["diskPath"] not in paths for r in resources["records"])
assert not any(path in cache for path in paths)
protected={**plan["protected_source_sha256"],**PINS,
           "scripts/build_resource_gallery.py":plan["baseline"]["scanner_sha256"]}
for path in ["assets/staging/world_bridges_20261030m/production/prompts/tasks.yaml",
             "assets/staging/world_bridges_20261030m/production/templates/world_bridge.yaml",
             "game/build/world_bridges_20261030m_qa01/import_decode02_actual/100424/result.json"]:
    protected[path]=sha(ROOT/path)
assert all(sha(ROOT/path)==pin for path,pin in protected.items())
updates={}
for row in rows:
    key=row["diskPath"];path=ROOT/key
    token=hashlib.sha256(key.encode()).hexdigest()[:24]
    destination=ROOT/"docs/assets/resources/map"/(token+".webp")
    assert not destination.exists()
    thumb,size=gallery.thumbnail(path,"map",cache,updates)
    assert size==row["size"] and thumb==row["thumbnail"]
    row["thumbnail"]=thumb;row["url"]=gallery.href(path)
    phase=row["phase"];discarded=phase=="raw_discarded"
    if discarded:
        assert row["status"]=="rejected" and not row["usage"] and not row["consumerPending"]
        row["consumerChain"]=[]
        continue
    id=row["consumerBridgeId"];resource=by_id[id]["resource"]
    assert resource["path"]=="res://art/modules/world_bridges_20261030m/"+id+".png"
    source_chain=["game/"+resource["path"][6:],BINDING,HELPER,STREAM]
    row["status"]="referenced"
    row["statusLabel"]={"raw_selected":"入选原生来源 · 经派生正式引用",
                        "processed_selected":"许可派生 · 工程图正式引用",
                        "game_selected":"已正式引用 · World桥视觉"}[phase]
    row["name"]=row["name"].replace("工程运行候选","工程运行图")
    row["group"]=row["group"].replace("工程运行候选","工程运行图")
    row["note"]=row["note"].replace(" 当前正式binding尚未合入，消费者仅列待合路径，不能标已采用。",
        " Root已正式合入当前binding/helper与World流式绘制接线，原NPC/任务/门户/physics源保持。本记录只证明当前消费者与隔离RGBA导入，不授完整World实景ART或Physics验收；本图鉴0引擎复验。")
    uses=[{"label":"正式桥绑定 · "+id,"url":gallery.href(ROOT/BINDING)},
          {"label":"World桥原生视觉消费者","url":gallery.href(ROOT/HELPER)}]
    if phase=="game_selected":
        assert row["path"]==resource["path"] and row["sha256"]==resource["sha256"]
        uses.append({"label":"正式World15流式绘制","url":gallery.href(ROOT/STREAM)})
    else:
        uses.insert(0,{"label":"来源/派生经此工程图消费（非直接读取RAW）","url":gallery.href(ROOT/source_chain[0])})
    row.update({"usage":uses,"usageCount":len(uses),"consumerChain":source_chain,
                "currentBindingSHA256":PINS[BINDING],"currentBridgeResourcePath":resource["path"]})
    del row["consumerPending"]
    with Image.open(destination) as thumb_image:
        assert thumb_image.width<=360 and thumb_image.height<=220
        thumb_image.verify()
assert len(updates)==19
resources["records"].extend(rows)
for category in resources["categories"]:
    category["count"]=sum(r["category"]==category["id"] for r in resources["records"])
resources["summary"]={"total":len(resources["records"]),"images":sum(r["media"]=="image" for r in resources["records"]),
                      "audio":sum(r["media"]=="audio" for r in resources["records"]),"states":dict(Counter(r["status"] for r in resources["records"]))}
assert resources["summary"]["total"]==5253
assert resources["records"][:-19]==old["resources"]["records"]
assert {k:v for k,v in data.items() if k!="resources"}=={k:v for k,v in old.items() if k!="resources"}
start,end,old_outside=split_resources(text,m)
raw=m[1];replacement=raw[:start]+json.dumps(resources,ensure_ascii=False,separators=(",",":"))+raw[end:]
new_html=(text[:m.start(1)]+replacement+text[m.end(1):]).encode("utf-8")
new_text,new_m,new_data=parse(new_html)
assert split_resources(new_text,new_m)[2]==old_outside
cache.update(updates)
assert {k:v for k,v in cache.items() if k not in paths}==old_cache
assert all(sha(ROOT/path)==pin for path,pin in protected.items())
assert HTML.read_bytes()==before_html and CACHE.read_bytes()==before_cache
for name,raw_bytes in [("catalog19_gallery_BEFORE.html",before_html),("catalog19_cache_BEFORE.json",before_cache)]:
    target=HERE/name;assert not target.exists();target.write_bytes(raw_bytes)
HTML.write_bytes(new_html)
CACHE.write_text(json.dumps(cache,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
dump("catalog19_new_records_ACTUAL.json",rows)
dump("catalog19_append_ACTUAL.json",{"status":"EXACT19_RESOURCES_ONLY_APPENDED",
     "before_total":5234,"new_summary":resources["summary"],"raw_versions":9,"selected_processed":5,"selected_game":5,
     "discarded_raws_not_adopted":4,"raw_selected_indirect_consumers":5,"selected_game_current_resource_paths":[r["currentBridgeResourcePath"] for r in rows if r["phase"]=="game_selected"],
     "old_records_exact":True,"non_resources_payload_exact":True,"HTML_outside_resources_value_exact":True,
     "old_cache_entries_exact":True,"new_thumbnails":19,"new_thumbnail_paths":[v["thumbnail"] for v in updates.values()],
     "protected_source_sha256":protected,"current_pins":PINS,"reference_only_registered":False,
     "source_PNG_pixel_writes":0,"engine_calls":0,"imagegen_calls":0,"inventory_build_calls":0,
     "html_sha256":sha(HTML),"cache_sha256":sha(CACHE)})
print(json.dumps({"total":resources["summary"],"new_thumbnails":19,"new_records":19,"old_records_preserved":5234,"official_binding_sha256":PINS[BINDING]}))
