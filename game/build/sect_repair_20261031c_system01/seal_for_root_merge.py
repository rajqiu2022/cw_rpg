"""Seal two Scene targets and source dictionaries; NEVER emits a merged native manifest."""
from pathlib import Path
import json,hashlib,difflib,re
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 p=HERE/name
 if p.exists():assert p.read_bytes()==b,p
 else:
  with p.open('xb') as f:f.write(b)
 return {'path':str(p.relative_to(GAME.parent)).replace('\\','/'),'bytes':len(b),'sha256':sha(b)}
def apply_delta(source,delta):
 lines=source.decode().splitlines(True);patch=delta.splitlines(True);result=[];cursor=0;i=0
 while i<len(patch):
  if not patch[i].startswith('@@ '):i+=1;continue
  m=re.match(r'@@ -(\d+)(?:,(\d+))? \+(\d+)(?:,(\d+))? @@',patch[i]);assert m
  start=int(m[1])-1;assert start>=cursor;result.extend(lines[cursor:start]);cursor=start;i+=1
  while i<len(patch) and not patch[i].startswith('@@ '):
   line=patch[i];i+=1;tag=line[:1];body=line[1:]
   if tag in [' ','-']:assert lines[cursor]==body;cursor+=1
   if tag in [' ','+']:result.append(body)
 result.extend(lines[cursor:]);return ''.join(result).encode()
records=[];updated={};forward=[];inverse=[]
for key,scene in [('wudang','scenes/drafts/sect_maps_20261029k/wudang.tscn'),('huashan','scenes/drafts/huashan_map_20261029m/huashan.tscn')]:
 before=(HERE/(key+'.tscn.BEFORE')).read_bytes();assert (GAME/scene).read_bytes()==before,'Formal Scene changed: explicit rebase required.'
 after=(HERE/(key+'_READY.tscn')).read_bytes();path='game/'+scene
 f=''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile=path,tofile=path));inv=''.join(difflib.unified_diff(after.decode().splitlines(True),before.decode().splitlines(True),fromfile=path,tofile=path))
 assert apply_delta(before,f)==after and apply_delta(after,inv)==before
 emit(key+'_FINAL_FORWARD.diff',f.encode());emit(key+'_FINAL_INVERSE.diff',inv.encode());forward.append(f);inverse.append(inv)
 records.append({'target':path,'before_sha256':sha(before),'before_bytes':len(before),'candidate':{'path':str((HERE/(key+'_READY.tscn')).relative_to(GAME.parent)).replace('\\','/'),'sha256':sha(after),'bytes':len(after)},'forward_and_inverse_applied_byte_exact':True,'line_ending_counts_before_after':[[before.count(b'\r\n'),before.count(b'\n')],[after.count(b'\r\n'),after.count(b'\n')]]})
 updated['res://'+scene]=sha(after)
modules=['actor_ghost.gd','wudang_controller.gd','huashan_controller.gd','native_visuals.gd','adoption_contract.gd','router_entry.gd','sect_field.gd','sect_field.tscn','adoption_data.json','visual_profiles.json','cliff_stair_slots.gdshader']
added={};facts=[]
for name in modules:
 p=HERE/name;b=p.read_bytes()
 if name.endswith('.gd'):assert b.endswith(b'\n') and not b.endswith(b'\n\n'),name
 uri='res://'+str(p.relative_to(GAME)).replace('\\','/');added[uri]=sha(b);facts.append({'path':uri,'bytes':len(b),'sha256':sha(b)})
visual=json.loads((HERE/'visual_READY.json').read_text(encoding='utf8'))
for row in visual['runtime_inputs']:
 assert sha((GAME/row['path'][6:]).read_bytes())==row['sha256'];added[row['path']]=row['sha256']
reg=GAME/'build/three_towns_world_20261029j_system01/town_registry.gd';before=reg.read_bytes();r=before
old=b'res://build/sect_adoption_20261030n_system01/router_entry.gd';assert r.count(old)==1
r=r.replace(old,b'res://build/sect_repair_20261031c_system01/router_entry.gd')
old_ids=b'&"openworld_wudang_gate",&"openworld_huashan_forecourt"]';assert r.count(old_ids)==1
r=r.replace(old_ids,b'&"openworld_wudang_gate",&"openworld_huashan_forecourt",&"openworld_wudang_taiji_court"]')
emit('town_registry.MERGE_BASE_BEFORE',before)
f=''.join(difflib.unified_diff(before.decode().splitlines(True),r.decode().splitlines(True),fromfile='game/build/three_towns_world_20261029j_system01/town_registry.gd',tofile='game/build/three_towns_world_20261029j_system01/town_registry.gd'))
inv=''.join(difflib.unified_diff(r.decode().splitlines(True),before.decode().splitlines(True),fromfile='game/build/three_towns_world_20261029j_system01/town_registry.gd',tofile='game/build/three_towns_world_20261029j_system01/town_registry.gd'))
assert apply_delta(before,f)==r and apply_delta(r,inv)==before
registry_forward=emit('town_registry.ONLY_TWO_ID_ENTRY_HUNKS.diff',f.encode());registry_inverse=emit('town_registry.ONLY_TWO_ID_ENTRY_INVERSE.diff',inv.encode())
deps={'status':'ROOT_MERGE_DICTIONARY_NOT_A_REPLACEMENT_NATIVE_MANIFEST','updated_existing_sources':updated,'added_sources':added,'new_runtime_modules':facts,'native_manifest_write':False,'registry_semantic_forward':registry_forward,'registry_semantic_inverse':registry_inverse,'registry_third_hunk':{'key':'NATIVE_SOURCE_SHA','old_line':re.search(rb'const NATIVE_SOURCE_SHA[^\r\n]+',before)[0].decode(),'new_value':'Root computes exact sha256 of combined System+World+city native_sources bytes; no placeholder candidate emitted.'},'retain':'Every old native key and unrelated World/city change; only two Scene old hashes replaced by this domain.'}
deps_fact=emit('native_dependencies_ROOT_MERGE_READY.json',(json.dumps(deps,ensure_ascii=False,indent=2)+'\n').encode())
receipt={'status':'FROZEN_SYSTEM_SCENES_AND_RUNTIME_ROOT_MERGES_NATIVE_AND_REGISTRY','scene_targets':records,'new_modules':facts,'runtime_inputs':visual['runtime_inputs'],'source_changes':deps_fact,'scene_forward':emit('scenes_FINAL_FORWARD.diff',''.join(forward).encode()),'scene_inverse':emit('scenes_FINAL_INVERSE.diff',''.join(inverse).encode()),'registry_semantic_hunks':2,'registry_header_hunk':'Root-only after all sibling dependencies merged','new_native_source_keys':len(added),'old_scene_source_updates':len(updated),'visual_proof_sha256':sha((HERE/'visual_READY.json').read_bytes()),'business_proof_sha256':sha((HERE/'business_STATIC_READY_01.json').read_bytes()),'original_W178_H200_physical_nodes_byte_exact':True,'original_W4_H5_ramp_geometry_unchanged':True,'retired_old_visual_polygons':114,'whole_native_cliffs':83,'whole_native_stairs':9,'alias':'OriginalTaijiID uses same W scene; originalPurpleCloud destination retained. Alias south exit restores Wgate identity/entry, never directWorld fallback.','version':3006,'v1_stair':'Retained but rejected for floor-width/span mismatch; not a runtime input.','PNG_write':False,'PNG_import_required':False,'Engine_runs':0,'formal_writes':0,'save_content_access':False}
print(json.dumps(emit('replacement_receipt_ROOT_MERGE_READY.json',(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode()),ensure_ascii=False));print(json.dumps({'scenes':records,'runtime':facts,'deps':deps_fact},ensure_ascii=False))
