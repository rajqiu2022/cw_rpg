"""Eight explicit media records only. No inventory/build, source edit or engine."""
from pathlib import Path
from collections import Counter
import copy
import hashlib
import json
import re
import sys
import wave
from PIL import Image

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).parent
sys.path.insert(0,str(ROOT/"scripts"))
import build_resource_gallery as gallery

CONFIG="game/scripts/life_skills/gathering_actions_20261030l.json"
HELPER="game/build/gather_actions_20261030l_system01/gather_action.gd"
LIFE="game/scripts/life_skills/life_skills.gd"
PRODUCTION="assets/staging/gather_actions_20261030l/production/"
PREPARED="game/build/gather_actions_20261030l_root01/assets_prepared_ACTUAL.json"
PREFLIGHT="game/build/gather_actions_20261030l_root01/art_preflight_ACTUAL.json"
PROMOTION="game/build/gather_actions_20261030l_root01/asset_promote01_ACTUAL.json"
PROCESS="game/build/gather_actions_20261030l_root01/actions02_ACTUAL_process_receipt.json"
STDOUT="game/build/gather_actions_20261030l_root01/actions02_ACTUAL_stdout.log"
HTML=ROOT/"docs/equipment-skill-catalog.html"
CACHE=ROOT/"docs/assets/resources/thumbnail-index.json"
SCANNER=ROOT/"scripts/build_resource_gallery.py"
INDEX=ROOT/"docs/resource-reuse-index.md"


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load(key):return json.loads((ROOT/key).read_text(encoding="utf-8"))
def dump(name,obj):
    path=HERE/name
    assert not path.exists(),path
    path.write_text(json.dumps(obj,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")


config=load(CONFIG)
prepared=load(PREPARED)
promotion=load(PROMOTION)
process=load(PROCESS)
preflight=load(PREFLIGHT)
assert process["actual_natural_console_exit_code"]==0
assert "GATHER_ACTION_RESULT 384 / 0" in (ROOT/STDOUT).read_text(encoding="utf-8")
assert promotion["natural_import_exit"]==0 and not promotion["full_project_import"]
for leaf in promotion["facts"]:assert sha(Path(leaf["path"]))==leaf["sha256"].lower()
assert HELPER[5:] in (ROOT/LIFE).read_text(encoding="utf-8")
helper_text=(ROOT/HELPER).read_text(encoding="utf-8")
assert "res://"+CONFIG[5:] in helper_text
images=[];sounds=[];provenance=[];protected=[CONFIG,HELPER,LIFE,PREPARED,PREFLIGHT,PROMOTION,PROCESS,STDOUT,PRODUCTION+"prompts/tasks.yaml",PRODUCTION+"templates/gather_action_4f.yaml"]
for kind,name in [("herb","gather_herb_right_4f"),("ore","mine_ore_right_4f")]:
    raw="assets/raw/gather_actions_20261030l/"+name+".png"
    meta_key="assets/raw/gather_actions_20261030l/"+name+".meta.json"
    unpadded="game/art/sprites/life_skills_20261030l/"+name+".png"
    runtime="game/art/sprites/life_skills_20261030l/"+name+"_padded.png"
    meta=load(meta_key);prep=next(row for row in prepared["sheets"] if row["name"]==name)
    assert meta["calls"]==1 and all(meta[key] is None for key in ["model","provider","cost"])
    assert sha(ROOT/raw)==meta["raw_sha256"]==prep["raw_sha256"]==sha(ROOT/unpadded)
    assert sha(ROOT/runtime)==prep["processed_sha256"]
    action=config["actions"][kind]
    assert action["sheet"]=="res://"+runtime[5:] and action["left_is_runtime_mirror"] is True
    assert len(action["frames"])==4
    assert not ("res://"+unpadded[5:]) in json.dumps(config)
    assert not ("res://"+unpadded[5:]) in helper_text
    preview="assets/previews/sprite/gather_actions_20261030l/"+kind+"_runtime_anchor_preview.gif"
    contact="assets/previews/sprite/gather_actions_20261030l/"+kind+"_runtime_anchor_contact.png"
    for key in [raw,runtime,unpadded,meta_key,meta["prompt_file"],preview,contact]:protected.append(key)
    p=next(row for row in preflight if row["id"]==name)
    assert sha(ROOT/meta["prompt_file"])==p["prompt_sha256"]
    for frame in action["frames"]:
        assert frame["rect"][2:]==[607,788]
    label="采药" if kind=="herb" else "采矿"
    for key,phase in [(raw,"raw"),(runtime,"runtime"),(unpadded,"unused_copy")]:
        images.append({"path":key,"kind":kind,"name":name,"phase":phase,"label":label,"preview":preview,"contact":contact,"source":raw,"meta":meta_key,"action":action,"processing":prep})
    cue=action["cues"][0]
    sound_key="game/"+cue["path"][6:]
    sound=next(row for row in prepared["audio"] if Path(row["path"]).name==Path(sound_key).name)
    assert sha(ROOT/sound_key)==sound["sha256"]
    sounds.append({"path":sound_key,"kind":kind,"label":label,"source":sound,"cue":cue})
    protected.append(sound_key)
    provenance.append({"kind":kind,"raw_metadata_path":meta_key,"raw_metadata":meta,"processing":prep,
                       "prompt":{**p,"source_file_sha256":sha(ROOT/meta["prompt_file"])},"runtime_action":action,
                       "unused_direct_game_copy":unpadded,"unused_game_copy_not_in_current_config_or_helper":True,
                       "preview_gif":preview,"preview_contact":contact,"audio":sound})
paths=[row["path"] for row in images+sounds]
assert len(paths)==len(set(paths))==8
protected+=['game/build/gather_actions_20261030l_root01/prepare_assets.py']
before_sha={key:sha(ROOT/key) for key in sorted(set(protected))}
scanner_sha=sha(SCANNER);index_sha=sha(INDEX)
old_html=HTML.read_bytes();old_cache_bytes=CACHE.read_bytes()
text=old_html.decode("utf-8")
match=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
raw_data=match[1];payload=json.loads(raw_data);before=copy.deepcopy(payload)
resources=payload["resources"];cache=json.loads(old_cache_bytes);old_cache=copy.deepcopy(cache)
assert not any(row["diskPath"] in paths for row in resources["records"])
assert not any(key in cache for key in paths)
updates={};rows=[]
consumer=[{"label":"采集动作配置（仅padded图与两WAV）","url":gallery.href(ROOT/CONFIG)},
          {"label":"GatherAction → LifeSkills正式消费者","url":gallery.href(ROOT/HELPER)}]
for entry in images:
    key=entry["path"];path=ROOT/key;phase=entry["phase"];kind=entry["kind"]
    token=hashlib.sha256(key.encode()).hexdigest()[:24]
    assert not (ROOT/"docs/assets/resources/player"/(token+".webp")).exists()
    thumb,size=gallery.thumbnail(path,"player",cache,updates)
    raw_source=phase=="raw";unused=phase=="unused_copy"
    stage="原生来源" if raw_source else ("正式运行补白四帧" if not unused else "未消费原图副本")
    prep=entry["processing"]
    note="冷孤云右向四帧"+entry["label"]+"动作，非待机/行走循环；左向由运行时镜像，未新制上下向。原图实际2172×724（请求1536×512，不冒尺寸达标）；内置各1次，model/provider/cost未返回均null。"
    note+=" 仅原四cell保护框外alpha1清理"+str(prep["removed_outside_alpha1_only"])+"点、每cell四边32px透明补白，原RGB/保护框内RGBA保持，无重采样/重画；运行sheet2428×788/四cell607×788，按逐帧原生脚锚播放。"
    if unused:
        note+=" 此game副本与RAW字节同，当前config/helper不消费，不能误认作padded运行图。"
    elif raw_source:
        note+=" 本RAW只是经padded派生的来源，不是引擎当前动作sheet；原尺寸/弱alpha事实保持。"
    else:
        note+=" config→GatherAction→LifeSkills实际消费本图，动作锁定身体、第3帧（索引2）配音效；Root实机384/0自然0为既有执行信用，本图鉴未重跑/不扩全部方向ART。GIF为采集动作，既有UI按钮通称‘行走预览’不改变素材语义；打开原图可查完整sheet。"
    uses=[] if unused else ([{"label":"来源经padded图供正式动作","url":gallery.href(ROOT/CONFIG)}] if raw_source else consumer)
    row={"id":token,"name":"冷孤云 · "+entry["label"]+"右向4帧 · "+stage,"category":"player","categoryLabel":"主角与武器",
         "group":"生活技艺 / "+entry["label"]+"动作 / "+stage,"path":"res://"+key[5:] if key.startswith("game/") else key,
         "diskPath":key,"url":gallery.href(path),"thumbnail":thumb,"media":"image","size":size,"bytes":path.stat().st_size,
         "format":"PNG","duration":None,"status":"unconfirmed" if unused else "referenced",
         "statusLabel":"原图副本 · 本批链未消费" if unused else ("原生来源 · 经派生引用" if raw_source else "已正式消费 · 补白四帧"),
         "usage":uses,"usageCount":len(uses),"sceneIds":[],"note":note,"sha256":sha(path),"sourcePath":entry["source"],
         "metadataPath":entry["meta"],"consumerChain":[CONFIG,HELPER,LIFE] if not unused else [],
         "generation":{"backend":"builtin_image_gen","model":None,"provider":None,"cost":None,"calls":1},
         "requestedSize":[1536,512],"rawActualSize":[2172,724],"requestedSizeContractMet":False,
         "animation":{"direction":"right","frames":4,"duration":entry["action"]["duration"],"leftIsRuntimeMirror":True,"otherDirectionsCreated":False},
         "contactPreview":gallery.href(ROOT/entry["contact"])}
    if phase=="runtime":row["animationPreview"]=gallery.href(ROOT/entry["preview"])
    rows.append(row)
for entry in sounds:
    key=entry["path"];path=ROOT/key
    with wave.open(str(path),"rb") as wav:
        seconds=wav.getnframes()/wav.getframerate();audio={"rate":wav.getframerate(),"channels":wav.getnchannels(),"sample_width":wav.getsampwidth(),"frames":wav.getnframes()}
    assert seconds==entry["source"]["seconds"] and audio["rate"]==48000 and audio["channels"]==1 and audio["sample_width"]==2
    rows.append({"id":hashlib.sha256(key.encode()).hexdigest()[:24],"name":"生活技艺 · "+("草叶摩擦与轻拔" if entry["kind"]=="herb" else "镐击矿石"),
                 "category":"sfx","categoryLabel":"音效与环境音","group":"生活技艺 / "+entry["label"]+"动作音效",
                 "path":"res://"+key[5:],"diskPath":key,"url":gallery.href(path),"thumbnail":"","media":"audio","size":[],
                 "bytes":path.stat().st_size,"format":"WAV","duration":seconds,"status":"referenced","statusLabel":"离线合成 · 第3帧（索引2）消费",
                 "usage":consumer,"usageCount":len(consumer),"sceneIds":[],"sha256":sha(path),
                 "note":"本地确定性离线程序音效设计，非录音/非AI生成，不冒真实采音；48kHz单声道PCM16。配于"+entry["label"]+"动作第3帧（索引2，-3dB）。"+entry["source"]["description"]+" Root已正式接线/实机，本图鉴只提供可试听入口，未自行耳审或引擎复验。",
                 "generation":{"backend":"offline_procedural_sound_design","model":None,"provider":None,"cost":None,"aiGenerated":False,"recorded":False},
                 "sourcePath":"game/build/gather_actions_20261030l_root01/prepare_assets.py","audio":audio,"cue":entry["cue"],"auditionByCatalogAgent":False})
assert len(rows)==8
resources["records"].extend(rows)
for category in resources["categories"]:category["count"]=sum(r["category"]==category["id"] for r in resources["records"])
resources["summary"]={"total":len(resources["records"]),"images":sum(r["media"]=="image" for r in resources["records"]),"audio":sum(r["media"]=="audio" for r in resources["records"]),"states":dict(Counter(r["status"] for r in resources["records"]))}
assert resources["records"][:-8]==before["resources"]["records"]
assert {k:v for k,v in payload.items() if k!="resources"}=={k:v for k,v in before.items() if k!="resources"}
keys=list(re.finditer(r'"resources"\s*:\s*',raw_data));assert len(keys)==1
start=keys[0].end();old_value,end=json.JSONDecoder().raw_decode(raw_data,start);assert old_value==before["resources"]
new_data=raw_data[:start]+json.dumps(resources,ensure_ascii=False,separators=(",",":"))+raw_data[end:]
assert json.loads(new_data)==payload
cache.update(updates)
assert len(updates)==6 and {k:v for k,v in cache.items() if k not in paths}==old_cache
assert HTML.read_bytes()==old_html and CACHE.read_bytes()==old_cache_bytes
assert all(sha(ROOT/k)==digest for k,digest in before_sha.items())
assert sha(SCANNER)==scanner_sha and sha(INDEX)==index_sha
for name,raw in [("gallery_BEFORE.html",old_html),("cache_BEFORE.json",old_cache_bytes)]:
    assert not (HERE/name).exists();(HERE/name).write_bytes(raw)
HTML.write_bytes((text[:match.start(1)]+new_data+text[match.end(1):]).encode("utf-8"))
CACHE.write_text(json.dumps(cache,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
dump("new_records_exact_eight.json",rows)
dump("provenance_exact_eight.json",{"source_chain":[CONFIG,HELPER,LIFE],"kinds":provenance,"protected_sha256":before_sha,"root_import_receipt":PROMOTION,"root_actual_process_receipt":PROCESS,"root_checks":384,"root_failures":0,"root_natural_exit":0,"catalog_engine_calls":0,"catalog_new_generations":0})
receipt={"status":"EXACT_EIGHT_MEDIA_ROWS_SIX_THUMBNAILS_APPENDED","before_total":before["resources"]["summary"]["total"],"new_summary":resources["summary"],
         "paths":paths,"old_records_exact":True,"non_resources_payload_exact":True,"old_cache_entries_exact":True,"old_HTML_outside_resources_value_exact":True,
         "new_thumbnails":[v["thumbnail"] for v in updates.values()],"current_consumed_files":4,"raw_sources":2,"unconsumed_unpadded_game_copies":2,
         "scanner_sha256_unchanged":scanner_sha,"reuse_index_sha256_unchanged":index_sha,"protected_source_sha256":before_sha,
         "inventory_build_calls":0,"engine_calls":0,"source_PNG_WAV_edits":0,"imagegen_calls":0,"audio_synthesis_calls":0}
dump("append_ACTUAL.json",receipt)
print(json.dumps({k:v for k,v in receipt.items() if k!="protected_source_sha256"},ensure_ascii=False))
