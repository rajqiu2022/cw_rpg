"""Prepare only explicit bridge records. Never writes catalog/cache/thumbnails."""
from pathlib import Path
import argparse
import hashlib
import json
import re

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
HTML=ROOT/"docs/equipment-skill-catalog.html"
CACHE=ROOT/"docs/assets/resources/thumbnail-index.json"
SCANNER=ROOT/"scripts/build_resource_gallery.py"
BINDING="game/art/modules/world_bridges_20261030m/bridge_bindings.json"
HELPER="game/build/world_bridges_20261030m_system01/bridge_visual_patch.gd"
STREAM="game/scripts/world/world_v15_visible_stream_20261018r.gd"
DECODE="game/build/world_bridges_20261030m_qa01/import_decode02_actual/100424/result.json"

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def save(path,data):
    assert not path.exists(),path
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

parser=argparse.ArgumentParser()
parser.add_argument("--v5-raw-path",default=None,help="Only use exact path explicitly supplied by Root after copying V5")
parser.add_argument("--output-tag",default="PREPARE_01")
args=parser.parse_args()
before_html=HTML.read_bytes();before_cache=CACHE.read_bytes()
text=before_html.decode("utf-8")
match=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
payload=json.loads(match[1]);resources=payload["resources"]
assert len(resources["records"])==5234
oldpaths={r["diskPath"] for r in resources["records"]}
cache=json.loads(before_cache)
decode=json.loads((ROOT/DECODE).read_text(encoding="utf-8-sig"))
assert decode["passed"] is True and decode["checks"]==32 and not decode["errors"]
chosen=json.loads((HERE/"selected_five_V4_SOURCE_READY.json").read_text(encoding="utf-8"))
labels={"bridge_00":"长灰石斜桥","bridge_01":"斜向木桥","bridge_02":"斜向石桥","bridge_03":"南北木桥","bridge_04":"短宽石桥"}
entries=[]
for row in chosen["selected"]:
    id=row["id"];version=row["version"]
    raw=row["raw"]["path"]
    processed=f"assets/processed/world_bridges_20261030m/{id}_v{version}_padded.png"
    for path,phase in [(raw,"raw_selected"),(processed,"processed_selected"),(row["runtime_input"]["path"],"game_selected")]:
        entries.append({"id":id,"version":version,"path":path,"phase":phase,"raw_source":raw,
                        "metadata":str(Path(raw if phase=="raw_selected" else processed).with_suffix(".meta.json")).replace("\\","/"),
                        "processing":row})
for version in [1,2,3]:
    path=f"assets/raw/world_bridges_20261030m/bridge_04_v{version}.png"
    entries.append({"id":"bridge_04","version":version,"path":path,"phase":"raw_discarded",
                    "raw_source":path,"metadata":str(Path(path).with_suffix(".meta.json")).replace("\\","/")})
if args.v5_raw_path:
    assert args.v5_raw_path.startswith("assets/raw/world_bridges_20261030m/")
    path=args.v5_raw_path
    assert (ROOT/path).is_file()
    entries.append({"id":"bridge_04","version":5,"path":path,"phase":"raw_discarded",
                    "raw_source":path,"metadata":str(Path(path).with_suffix(".meta.json")).replace("\\","/")})
records=[]
protected={}
for entry in entries:
    path=ROOT/entry["path"];key=entry["path"]
    assert key not in oldpaths and key not in cache and path.is_file()
    from PIL import Image
    with Image.open(path) as image:size=list(image.size)
    token=hashlib.sha256(key.encode()).hexdigest()[:24]
    planned_thumb="assets/resources/map/"+token+".webp"
    assert not (ROOT/"docs"/planned_thumb).exists()
    discarded=entry["phase"]=="raw_discarded"
    raw_phase=entry["phase"].startswith("raw_")
    stages={"raw_selected":"入选原生来源","raw_discarded":"弃用原稿","processed_selected":"许可清边留白派生","game_selected":"工程运行候选"}
    note="本批每个RAW版本内置1次；model/provider/cost未知null。reference_only本地合成仅作几何参考，不是原生生成物、不登记。"
    if discarded:
        note+=" 此04版本未采用，usage=0，不将历史raw/processed存在误当current消费者。"
        note+= {1:"V1桥面宽长比被Root拒绝。",2:"V2等比长度适配宽差超过15px被拒绝。",3:"V3按当时可见踏面测量判宽不足，旧失败完整保留，不回写为通过。",5:"V5是Root在收到V4 alpha0证据前已调用的一次builtin去背景编辑，结果弃用；V4隐藏RGB不需处理，未采用该V5。"}[entry["version"]]
    else:
        row=entry["processing"]
        note+=f" 仅保护框外alpha1清{row['actual_a1_edits']}点、四边256px RGBA0补白；全部原RGB（含A0隐藏RGB）、保护框RGBA与alpha≥2RGBA精同，未缩放/重画/去背景/alpha归一。"
        note+=" RAW完整A1四边留白FAIL原样保留，不倒改历史结果。Root100424隔离decode02自然0/32检查0、fullRGBA exact/mip0，信用来自Root，本图鉴不重跑。"
        if entry["id"]=="bridge_04":
            note+=" 入选V4原1536×1024/maxAlpha254保；灰halo抽样为alpha0隐藏RGB。外support平面与无遮挡内踏面分开，约93对原100仅几何参考，不授35×25实体或World ART。"
        note+=" 当前正式binding尚未合入，消费者仅列待合路径，不能标已采用。"
    generation={"backend":"builtin_image_gen" if raw_phase else "authorized_local_alpha1_and_padding_derivative",
                "model":None,"provider":None,"cost":None,"callsForThisFile":1 if raw_phase else 0,
                "rawSourceBuiltinCalls":1,"additionalGenerationForDerivedCopy":False}
    records.append({"id":token,"name":"世界桥 · "+labels[entry["id"]]+f" · V{entry['version']} · "+stages[entry["phase"]],
                    "category":"map","categoryLabel":"地图组件","group":"江湖世界 / 原生桥重绘30m / "+entry["id"]+" / "+stages[entry["phase"]],
                    "path":"res://"+key[5:] if key.startswith("game/") else key,"diskPath":key,"url":"../"+key,
                    "thumbnail":planned_thumb,"media":"image","size":size,"bytes":path.stat().st_size,"format":"PNG","duration":None,
                    "status":"rejected" if discarded else "candidate","statusLabel":"弃用历史 · 未采用" if discarded else "入选候选 · 消费者待正式合入",
                    "usage":[],"usageCount":0,"sceneIds":[] if discarded else ["world_map_jianghu","world_map_jianghu_v15"],
                    "note":note,"sha256":sha(path),"sourcePath":entry["raw_source"],"metadataPath":entry["metadata"],
                    "generation":generation,"consumerPending":[] if discarded else [BINDING,HELPER,STREAM],
                    "consumerBridgeId":None if discarded else entry["id"],"phase":entry["phase"],"rawVersion":entry["version"]})
    protected[key]=sha(path)
    protected[entry["metadata"]]=sha(ROOT/entry["metadata"])
assert len(records)==(19 if args.v5_raw_path else 18)
res_keys=list(re.finditer(r'"resources"\s*:\s*',match[1]));assert len(res_keys)==1
start=res_keys[0].end();_,end=json.JSONDecoder().raw_decode(match[1],start)
outside=text[:match.start(1)+start]+text[match.start(1)+end:]
plan={"schema_version":1,"status":"PREPARED_ONLY_NO_CATALOG_CACHE_THUMBNAIL_WRITES",
      "baseline":{"total":5234,"html_sha256":hashlib.sha256(before_html).hexdigest(),"cache_sha256":hashlib.sha256(before_cache).hexdigest(),
                  "old_records_json_sha256":hashlib.sha256(json.dumps(resources["records"],ensure_ascii=False,separators=(",",":")).encode()).hexdigest(),
                  "non_resources_payload_sha256":hashlib.sha256(json.dumps({k:v for k,v in payload.items() if k!="resources"},ensure_ascii=False,separators=(",",":")).encode()).hexdigest(),
                  "html_outside_resources_value_sha256":hashlib.sha256(outside.encode()).hexdigest(),"scanner_sha256":sha(SCANNER)},
      "planned_total_after_all19":5253,"known_records":len(records),"expected_records":19,
      "known_raw_versions":sum(r["phase"].startswith("raw_") for r in records),"processed_selected":5,"game_selected":5,
      "v5_pending":None if args.v5_raw_path else {"path":None,"required":"Wait for exact copied RAW path and SHA from Root; no fake record or thumbnail for unavailable V5"},
      "consumer_paths_pending":[BINDING,HELPER,STREAM],
      "consumer_rows": [{"id":r["id"],"texture_path":"res://"+r["runtime_input"]["path"][5:],"binding_json":BINDING,"binding_member":"bridges[id="+r["id"]+"].resource.path"} for r in chosen["selected"]],
      "source_import_evidence":{"path":DECODE,"sha256":sha(ROOT/DECODE),"checks":32,"errors":0,"engine_calls_by_art":0},
      "protected_source_sha256":protected,"records_file":f"catalog_records_{args.output_tag}.json",
      "execution_gate":"Root supplies V5 exact copied raw path + formal binding head; re-read final consumer and only then append all19 once using gallery.thumbnail helper, no inventory/build call.",
      "old_thumbnail_safety":"Only absent deterministic new map/<sha24>.webp targets; no old thumbnail path is written, no all-library scan/rebuild.",
      "no_reference_only_record":True,"official_catalog_writes":0,"new_thumbnail_writes":0}
save(HERE/f"catalog_records_{args.output_tag}.json",records)
save(HERE/f"catalog_patch_list_{args.output_tag}.json",plan)
assert HTML.read_bytes()==before_html and CACHE.read_bytes()==before_cache
print(json.dumps({"known_records":len(records),"expected_records":19,"v5_pending":not bool(args.v5_raw_path),"plan_sha256":sha(HERE/f"catalog_patch_list_{args.output_tag}.json"),"official_writes":0}))
