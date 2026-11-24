"""Root-authorized existing55 consumer/note update; no media/cache/source writes."""
from pathlib import Path
import copy
import hashlib
import json
import re

ROOT=Path(__file__).resolve().parents[3]
HERE=Path(__file__).resolve().parent
HTML=ROOT/"docs/equipment-skill-catalog.html"
CACHE=ROOT/"docs/assets/resources/thumbnail-index.json"
PLAN=HERE/"catalog_consumers_PREPARE_01.json"
ACTUAL="game/build/sect_adoption_20261030n_qa01/actual/109820/result.json"
ALLOWED={"usage","usageCount","sceneIds","currentConsumers","note"}

def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def packed(value):return json.dumps(value,ensure_ascii=False,separators=(",",":"))
def parse(text):
    m=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',text,re.S)
    return json.loads(m[1])
def dump(name,data):
    path=HERE/name;assert not path.exists()
    path.write_text(json.dumps(data,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")

plan=json.loads(PLAN.read_text(encoding="utf-8"))
actual=json.loads((ROOT/ACTUAL).read_text(encoding="utf-8-sig"))
assert actual["passed"] is True and actual["checks"]==54 and actual["input_events"]==20 and not actual["errors"]
for source in plan["current_source_pins"]:assert sha(ROOT/source["path"])==source["sha256"]
before=HTML.read_bytes();cache_before=CACHE.read_bytes()
assert hashlib.sha256(before).hexdigest()==plan["baseline_html_sha256"]
assert hashlib.sha256(cache_before).hexdigest()==plan["baseline_cache_sha256"]
text=before.decode("utf-8");old=parse(text);records=old["resources"]["records"]
assert len(records)==plan["baseline_catalog_records"]==5253
plans=plan["plans"];assert len(plans)==55
ids={p["diskPath"] for p in plans};lookup={r["diskPath"]:r for r in records}
new_text=text;changes=[];newrows=[];oldrows=[]
for proposal in plans:
    key=proposal["diskPath"];row=lookup[key]
    assert hashlib.sha256(packed(row).encode()).hexdigest()==proposal["old_record_sha256"]
    changed=copy.deepcopy(row)
    usage=copy.deepcopy(row.get("usage",[]))
    for entry in proposal["usage_additions_proposed"]:
        if entry not in usage:usage.append(entry)
    changed["usage"]=usage;changed["usageCount"]=len(usage)
    sceneids=list(row.get("sceneIds",[]))
    consumers=copy.deepcopy(row.get("currentConsumers") or [])
    assert isinstance(consumers,list)
    for source in proposal["currentConsumers_proposed"]:
        source=copy.deepcopy(source)
        source["status"]="FORMAL_OUTDOOR_ADOPTED_ROOT_ACTUAL109820_ACCEPTED_ENTRY_SCOPE"
        source["root_actual_receipt"]=ACTUAL
        source["scope"]="Original World outdoor adopted; original subsequent inner areas preserved; not full sect interior/ART completion"
        if source not in consumers:consumers.append(source)
        if source["scene_id"] not in sceneids:sceneids.append(source["scene_id"])
    changed["sceneIds"]=sceneids;changed["currentConsumers"]=consumers
    if proposal["phase"] in ["source","processed"]:
        lineage="本记录为既有原图/许可派生的间接来源，实际绘制仍读取其对应工程PNG。"
    else:lineage="本工程PNG按所列native Scene实际节点/材质引用，既有其他消费者继续保留。"
    current="当前30n：武当/华山中本记录所列的两原World外场已采用既有原生室外，原后续内区保留，凌月内庭未改。"+lineage
    current+="Root109820自然0、54检查0/20输入，两派首内区与World进返、武当原弟子对白及主阶通过；仅本批室外采用范围，不冒整派内景/全ART。"
    changed["note"]=current+" 以下为历史制作说明（历史‘未接线’字样描述当时阶段，并非30n当前外场状态；原文保留）："+row.get("note","")
    changedkeys={k for k in set(row)|set(changed) if row.get(k)!=changed.get(k)}
    assert changedkeys<=ALLOWED
    assert {k:v for k,v in changed.items() if k not in ALLOWED}=={k:v for k,v in row.items() if k not in ALLOWED}
    assert changed["usage"][:len(row.get("usage",[]))]==row.get("usage",[])
    assert changed["note"].endswith(row.get("note",""))
    a=packed(row);b=packed(changed);assert new_text.count(a)==1
    new_text=new_text.replace(a,b,1)
    oldrows.append(row);newrows.append(changed)
    changes.append({"diskPath":key,"changed_keys":sorted(changedkeys),"old_usage_count":row.get("usageCount"),
                    "new_usage_count":changed["usageCount"],"current_scene_ids":[c["scene_id"] for c in proposal["currentConsumers_proposed"]]})
new=parse(new_text)
assert len(new["resources"]["records"])==5253
assert [r for r in new["resources"]["records"] if r["diskPath"] not in ids]==[r for r in records if r["diskPath"] not in ids]
assert {k:v for k,v in new.items() if k!="resources"}=={k:v for k,v in old.items() if k!="resources"}
assert {k:v for k,v in new["resources"].items() if k!="records"}=={k:v for k,v in old["resources"].items() if k!="records"}
restore=new_text
for a,b in zip(oldrows,newrows):
    assert restore.count(packed(b))==1
    restore=restore.replace(packed(b),packed(a),1)
assert restore.encode("utf-8")==before
assert HTML.read_bytes()==before and CACHE.read_bytes()==cache_before
for source in plan["current_source_pins"]:assert sha(ROOT/source["path"])==source["sha256"]
backup=HERE/"catalog55_BEFORE.html";assert not backup.exists();backup.write_bytes(before)
HTML.write_bytes(new_text.encode("utf-8"))
assert HTML.read_bytes()==new_text.encode("utf-8") and CACHE.read_bytes()==cache_before
dump("catalog55_records_BEFORE.json",oldrows)
dump("catalog55_records_AFTER.json",newrows)
proof={"status":"EXACT55_EXISTING_RECORDS_CONSUMER_AND_CURRENT_HISTORY_NOTE_UPDATED",
       "total_records_unchanged":5253,"targets":55,"non_target_records_exact":5198,
       "new_records":0,"new_thumbnails":0,"cache_bytes_exact":True,"cache_sha256":sha(CACHE),
       "non_resources_payload_exact":True,"resources_summary_categories_and_other_fields_exact":True,
       "all_HTML_bytes_outside55_record_replacements_exact":True,
       "only_allowed_keys_changed":sorted(ALLOWED),"existing_consumers_preserved_as_exact_usage_prefix":True,
       "all_old_notes_preserved_exactly_as_history":True,"historical_unwired_language_not_presented_as_current":True,
       "old_backgrounds_lingyue_and_original_inner_areas_not_rejected_or_rewritten":True,
       "all55_media_sha_thumbnail_source_generation_and_status_fields_exact":True,
       "current_source_pins":plan["current_source_pins"],"root_actual_receipt":{"path":ACTUAL,"sha256":sha(ROOT/ACTUAL),"checks":54,"errors":0,"input_events":20,"natural_exit_credit":"Root report"},
       "PNG_or_thumbnail_reads_or_writes":0,"engine_calls":0,"imagegen_calls":0,"inventory_build_calls":0,
       "no_new_engine_validation":True,"html_before_sha256":hashlib.sha256(before).hexdigest(),"html_after_sha256":sha(HTML),"changes":changes}
dump("catalog55_final_PROOF.json",proof)
print(json.dumps({"targets":55,"non_targets_exact":5198,"total_unchanged":5253,"html_sha256":sha(HTML),"cache_sha256":sha(CACHE),"proof_sha256":sha(HERE/"catalog55_final_PROOF.json")}))
