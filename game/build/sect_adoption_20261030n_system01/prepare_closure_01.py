"""Only registry/native candidate successors. Original14IDs/166keys retained.
No engine, save contents, old source/art/draft edits or global source scanning.
"""
from pathlib import Path
import difflib,hashlib,json,re
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
REG=GAME/'build/three_towns_world_20261029j_system01/town_registry.gd'
NATIVE=GAME/'build/three_towns_world_20261029j_system01/native_sources.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def fact(p):return {'sha256':sha(p.read_bytes()),'bytes':p.stat().st_size}
def encoded(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def put(name,b):
 with (HERE/name).open('xb') as f:f.write(b)
def once(s,a,b):assert s.count(a)==1,(a,s.count(a));return s.replace(a,b,1)
def hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True)
 for context in [4,8,16,32,10000]:
  result=[{'old':''.join(aa[g[0][1]:g[-1][2]]),'new':''.join(bb[g[0][3]:g[-1][4]])} for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context)]
  if all(a.count(r['old'].encode())==1 and b.count(r['new'].encode())==1 for r in result):
   proof=a
   for r in result:proof=proof.replace(r['old'].encode(),r['new'].encode(),1)
   assert proof==b
   for r in reversed(result):proof=proof.replace(r['new'].encode(),r['old'].encode(),1)
   assert proof==a
   return result
 raise AssertionError('NONUNIQUE_HUNK')
before_reg=REG.read_bytes();before_native=NATIVE.read_bytes()
assert sha(before_reg)=='4a3b814aeea172abc7f3a56072474ff9ad35ebef76b39a43e4099360441cbc39'
assert sha(before_native)=='ccc1d7a8beedeec8f694c79a380a7bf0b7da520c79886ab6b4decbd49da65a6a'
native=json.loads(before_native.decode('utf-8-sig'));original=native['sources'].copy()
assert len(original)==166
new_runtime=['adoption_contract.gd','router_entry.gd','sect_adoption_field.gd','sect_adoption_field.tscn','adoption_data.json']
leaves={('res://build/sect_adoption_20261030n_system01/'+name):'NEW30N_RUNTIME' for name in new_runtime}
drafts=['scenes/drafts/sect_maps_20261029k/wudang.tscn','scenes/drafts/huashan_map_20261029m/huashan.tscn']
for rel in drafts:
 leaves['res://'+rel]='ADOPTED_UNCHANGED_DRAFT_SCENE'
 source=(GAME/rel).read_text(encoding='utf-8-sig')
 for kind,path in re.findall(r'\[ext_resource type="([^"]+)" path="(res://[^"]+)"',source):
  # Shared Player already serves all native166 scenes; do not expand its
  # pre-existing project-level dependency policy for this two-map adoption.
  if kind=='PackedScene' and path=='res://scenes/player.tscn':continue
  leaves[path]='ACTUAL_DRAFT_DIRECT_RESOURCE'
for rel in ['scripts/drafts/sect_maps_20261029k/controller.gd','scripts/drafts/sect_maps_20261029k/terrain.gd','scripts/drafts/huashan_map_20261029m/controller.gd','scripts/drafts/huashan_map_20261029m/terrain.gd','art/modules/sect_maps_20261029k/wudang.json','art/modules/huashan_map_20261029m/huashan.json']:
 leaves['res://'+rel]='ACTUAL_UNCHANGED_NATIVE_LAYOUT_CONTROLLER_TERRAIN'
for id,mapname in [('openworld_wudang_gate','openworld_wudang_gate_layout_v1'),('openworld_wudang_taiji_court','openworld_wudang_taiji_court_layout_v1'),('openworld_huashan_forecourt','openworld_huashan_forecourt_layout_v2'),('openworld_huashan_sword_terrace','openworld_huashan_sword_terrace_layout_v1')]:
 leaves['res://data/scenes/'+id+'.tres']='ORIGINAL_BUSINESS_SCENE'
 leaves['res://data/maps/'+mapname+'.tres']='ORIGINAL_BUSINESS_PORTALS_AND_LEGACY_UV'
leaves['res://data/dialogs/openworld_wudang_gate_disciple.tres']='ONLY_ORIGINAL_OUTDOOR_NPC_DIALOG'
leaves['res://art/characters/street_expansion_v1/npc_escort_guard_idle_down_4f_v2_runtime.png']='ONLY_ORIGINAL_OUTDOOR_NPC_BODY'
added={};inputs={}
for path,kind in sorted(leaves.items()):
 file=GAME/path[6:];assert file.is_file(),path
 value=fact(file);inputs[path]={**value,'role':kind}
 if path in original:assert original[path]==value['sha256'],'EXTERNAL_NATIVE_INPUT_MOVED:'+path
 else:added[path]=value['sha256'];native['sources'][path]=value['sha256']
assert all(native['sources'][k]==v for k,v in original.items())
new_native=encoded(native);native_sha=sha(new_native)
eol='\r\n' if before_reg.count(b'\r\n')==before_reg.count(b'\n') and b'\r\n' in before_reg else '\n'
reg=before_reg.decode().replace('\r\n','\n')
old_ids=re.search(r'^const IDS := (.+)$',reg,re.M).group(1)
assert len(re.findall(r'&"([^"]+)"',old_ids))==14
reg=once(reg,'const ROAD=preload("res://build/linxi_mountain_road_20261030g_system01/road_entry.gd")\n','const ROAD=preload("res://build/linxi_mountain_road_20261030g_system01/road_entry.gd")\nconst ADOPTION30N=preload("res://build/sect_adoption_20261030n_system01/router_entry.gd")\n')
reg=once(reg,sha(before_native),native_sha)
reg=once(reg,'const IDS := '+old_ids,'const IDS := '+old_ids[:-1]+',&"openworld_wudang_gate",&"openworld_huashan_forecourt"]')
reg=once(reg,'static func town(id: StringName) -> Dictionary:\n','static func town(id: StringName) -> Dictionary:\n\tif ADOPTION30N.IDS.has(id):return ADOPTION30N.town(id)\n')
reg=once(reg,'static func start(router: Node,id: StringName,requested: Variant,action: String,version: int) -> bool:\n','static func start(router: Node,id: StringName,requested: Variant,action: String,version: int) -> bool:\n\tif ADOPTION30N.IDS.has(id):return ADOPTION30N.start(router,id,requested,action,version) if source_valid() else false\n')
new_reg=reg.replace('\n',eol).encode()
old_line=old_ids
new_ids=re.findall(r'&"([^"]+)"',re.search(r'^const IDS := (.+)$',reg,re.M).group(1))
assert new_ids[:14]==re.findall(r'&"([^"]+)"',old_line) and len(new_ids)==16
targets=[]
for target,old,new,name in [(REG,before_reg,new_reg,'town_registry_READY.gd'),(NATIVE,before_native,new_native,'native_sources_READY.json')]:
 put(target.name+'.BEFORE',old);put(name,new)
 targets.append({'target':target.relative_to(GAME.parent).as_posix(),'candidate':'game/build/sect_adoption_20261030n_system01/'+name,'old_sha256':sha(old),'new_sha256':sha(new),'bytes':len(new),'replacements':hunks(old,new),'whole_byte_inverse':True})
runtime={('game/build/sect_adoption_20261030n_system01/'+name):fact(HERE/name) for name in new_runtime}
receipt={'schema_version':1,'status':'SOURCE_CANDIDATE_NO_ENGINE_OR_PHYSICS_RUN','targets':targets,'new_modules':runtime,'native_sources_old_count':166,'native_sources_new_count':len(native['sources']),'native_sources_all_old_keys_values_preserved':True,'native_added':added,'immutable_required_inputs':inputs,'registry_old14_IDs_preserved_order':new_ids[:14],'registry_added_IDs':new_ids[14:],'original_SECT_IDS_3_unchanged':True,'source_valid_logic_unchanged':True,'no_dependency_cycle':'REGISTRY->ENTRY->CONTRACT; FIELD->OLD_SECT_HOST->REGISTRY; ENTRY_FIELD_IS_STRING_ONLY','Root_only_formal_and_engine':True,'engine_runs':0,'save_content_reads':0,'save_writes':0,'canonical_writes':0,'Router_MainField_original30a_drafts_PNG_World_bridges_unchanged':True}
b=encoded(receipt);put('closure_receipt_READY.json',b)
print(json.dumps({'receipt_sha256':sha(b),'bytes':len(b),'native_count':len(native['sources']),'native_added':len(added),'targets':[{k:r[k] for k in ['target','new_sha256','bytes']} for r in targets],'new_modules':runtime},ensure_ascii=False))
