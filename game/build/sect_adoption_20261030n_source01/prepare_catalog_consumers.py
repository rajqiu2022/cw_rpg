"""Trace only two native scene resource graphs and existing catalog rows; prepare, no writes outside this folder."""
from pathlib import Path
import hashlib
import json
import re

ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
HTML=ROOT/"docs/equipment-skill-catalog.html"
CACHE=ROOT/"docs/assets/resources/thumbnail-index.json"
SCENES={"openworld_wudang_gate":"game/scenes/drafts/sect_maps_20261029k/wudang.tscn",
        "openworld_huashan_forecourt":"game/scenes/drafts/huashan_map_20261029m/huashan.tscn"}
PACKS=["game/art/modules/sect_maps_20261029k/resource-pack.json","game/art/modules/huashan_map_20261029m/resource-pack.json"]
ADOPTION="game/build/sect_adoption_20261030n_system01/"
PINS={"game/build/three_towns_world_20261029j_system01/town_registry.gd":"229d6b68",
      "game/build/three_towns_world_20261029j_system01/native_sources.json":"44e291a2",
      ADOPTION+"sect_adoption_field.gd":"720f0512"}

def text(key):return (ROOT/key).read_text(encoding="utf-8-sig")
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def fact(key):return {"path":key,"sha256":sha(ROOT/key),"bytes":(ROOT/key).stat().st_size}
def href(key):return "../"+key

before_html=HTML.read_bytes();before_cache=CACHE.read_bytes()
markup=before_html.decode("utf-8")
m=re.search(r'<script id="catalogData" type="application/json">(.*?)</script>',markup,re.S)
payload=json.loads(m[1]);records=payload["resources"]["records"]
for key,pin in PINS.items():assert sha(ROOT/key).startswith(pin)
evidence={};texture_owners={};declared_unused={}
for id,scene in SCENES.items():
    raw=text(scene)
    ext={}
    for x in re.finditer(r'^\[ext_resource ([^\]]+)\]',raw,re.M):
        attrs=dict(re.findall(r'(\w+)="([^"]*)"',x[1]));ext[attrs["id"]]=attrs
    sections=[]
    for x in re.finditer(r'^\[(sub_resource|node) ([^\]]+)\]\r?\n([\s\S]*?)(?=^\[(?:sub_resource|node) |\Z)',raw,re.M):
        attrs=dict(re.findall(r'(\w+)="([^"]*)"',x[2]))
        sections.append({"kind":x[1],"attrs":attrs,"body":x[3],"line":raw.count("\n",0,x.start())+1})
    subs={s["attrs"]["id"]:s for s in sections if s["kind"]=="sub_resource"}
    reachable=set();used_ext=set();references=[]
    pending=[s for s in sections if s["kind"]=="node"]
    while pending:
        section=pending.pop()
        for rid in re.findall(r'ExtResource\("([^"]+)"\)',section["body"]):
            used_ext.add(rid)
            if ext[rid].get("type")=="Texture2D":
                references.append({"path":"game/"+ext[rid]["path"][6:],"owner_kind":section["kind"],"owner":section["attrs"],"line":section["line"]})
        for rid in re.findall(r'SubResource\("([^"]+)"\)',section["body"]):
            if rid not in reachable:reachable.add(rid);pending.append(subs[rid])
    used={"game/"+ext[rid]["path"][6:] for rid in used_ext if ext[rid].get("type")=="Texture2D"}
    declared={"game/"+v["path"][6:] for v in ext.values() if v.get("type")=="Texture2D"}
    declared_unused[id]=sorted(declared-used)
    evidence[id]={"scene":scene,"textures":sorted(used),"references":references,"packed_player_not_recursively_scanned":True}
    for path in used:texture_owners.setdefault(path,[]).append(id)

parent_paths={};dedicated_rows=[]
for pack in PACKS:
    for row in json.loads(text(pack))["assets"]:
        if row["output"] not in texture_owners:continue
        owners=texture_owners[row["output"]]
        for phase in ["source","processed","output"]:
            parent_paths[row[phase]]={"output":row["output"],"owners":owners,"phase":phase,"pack":pack,"key":row["key"]}
        dedicated_rows.append(row["output"])

lookup={r["diskPath"]:r for r in records}
targets=set(texture_owners)|set(parent_paths)
assert all(path in lookup for path in targets),sorted(targets-set(lookup))
plans=[]
stale=[]
for path in sorted(targets):
    row=lookup[path]
    assert (ROOT/"docs"/row["thumbnail"]).is_file()
    linkage=parent_paths.get(path)
    owners=texture_owners.get(path,linkage["owners"] if linkage else [])
    relation="direct_native_texture" if path in texture_owners else "source_or_processed_lineage_not_direct_engine_load"
    current=[]
    additions=[]
    for id in owners:
        scene=SCENES[id]
        current.append({"scene_id":id,"scene_path":scene,"host":ADOPTION+"sect_adoption_field.gd",
                        "entry":ADOPTION+"router_entry.gd","data":ADOPTION+"adoption_data.json",
                        "relation":relation,"runtime_texture":path if path in texture_owners else linkage["output"],
                        "status":"FORMAL_SOURCE_ADOPTED_ACTUAL_ACCEPTANCE_PENDING_ROOT"})
        additions.append({"label":"30n正式采用 · "+id,"url":href(ADOPTION+"sect_adoption_field.gd")})
    if any(term in row.get("note","") for term in ["世界入口未接","正式世界未接","正式世界入口尚未","正式世界/剧情","NPC/内景/正式世界未接"]):stale.append(path)
    plans.append({"diskPath":path,"record_id":row["id"],"category":row["category"],"phase":linkage["phase"] if linkage else "reused_game_texture",
                  "old_record_sha256":hashlib.sha256(json.dumps(row,ensure_ascii=False,separators=(",",":")).encode()).hexdigest(),
                  "thumbnail_preserved":row["thumbnail"],"old_status":row.get("status"),"old_statusLabel":row.get("statusLabel"),
                  "old_usage":row.get("usage",[]),"old_sceneIds":row.get("sceneIds",[]),
                  "currentConsumers_proposed":current,"usage_additions_proposed":additions,
                  "allowed_minimal_consumer_fields":["usage","usageCount","sceneIds","currentConsumers"],
                  "do_not_remove_existing_consumers":True})

facts=[fact(key) for key in list(PINS)+[ADOPTION+"router_entry.gd",ADOPTION+"adoption_contract.gd",ADOPTION+"adoption_data.json"]+list(SCENES.values())+PACKS]
result={"schema_version":1,"status":"PREPARE_ONLY_WAIT_ROOT_ACTUAL_AUTHORIZATION_NO_CATALOG_WRITES",
        "baseline_catalog_records":len(records),"baseline_html_sha256":hashlib.sha256(before_html).hexdigest(),
        "baseline_cache_sha256":hashlib.sha256(before_cache).hexdigest(),
        "current_source_pins":facts,"scene_graphs":evidence,"declared_but_unused_texture_extresources_excluded":declared_unused,
        "actual_unique_runtime_texture_paths":len(texture_owners),"current_runtime_textures_per_scene":{id:len(e["textures"]) for id,e in evidence.items()},
        "dedicated_module_outputs_from_packs":len(set(dedicated_rows)),"source_processed_game_lineage_paths":len(parent_paths),
        "existing_records_to_update":len(plans),"new_records":0,"new_thumbnails":0,"cache_writes":0,
        "field_only_feasibility":"Yes: update only four consumer fields in these existing rows; do not touch bytes/sha/thumbnail/sourcePath/media/generation. Existing usage consumers must be retained.",
        "historical_note_warning":{"records_with_historical_unwired_language":stale,"count":len(stale),
             "proposal":"Optional after actual: same-row note gains a concise30n current-adoption prefix while retaining all history, statusLabel may gain current outdoor consumer qualifier; not authorized or executed in this prepare-only pass."},
        "not_in_scope":["Lingyue innercourt","old painted gate backgrounds and all remaining inner areas","any unrelated gallery row","reference designs not directly instantiated","Player/NPC shared art beyond twoScene own texture graph"],
        "plans":plans,"official_gallery_writes":0,"PNG_writes":0,"old_thumbnail_reads_for_decode":0,"engine_calls":0,
        "scan_scope":"Two exact tscn resource graphs, two explicit resource-packs, existing catalog in-memory index; no filesystem asset or source-library inventory scan."}
target=OUT/"catalog_consumers_PREPARE_01.json";assert not target.exists()
target.write_text(json.dumps(result,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
assert HTML.read_bytes()==before_html and CACHE.read_bytes()==before_cache
print(json.dumps({"records":len(plans),"runtime_texture_count":len(texture_owners),"dedicated_outputs":len(set(dedicated_rows)),"lineage_paths":len(parent_paths),"per_scene":result["current_runtime_textures_per_scene"],"historical_notes":len(stale),"sha256":sha(target),"official_writes":0}))
