"""Run only after visual_READY.json/2final Scenes exist. Exactly4old targets."""
from pathlib import Path
import json,hashlib,re,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def emit(name,b):
 p=HERE/name
 if p.exists():assert p.read_bytes()==b,p
 else:
  with p.open('xb') as f:f.write(b)
 return {'path':str(p.relative_to(GAME.parent)).replace('\\','/'),'sha256':sha(b),'bytes':len(b)}
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
visual=json.loads((HERE/'visual_READY.json').read_text(encoding='utf8'))
assert visual['status']=='VISUAL_STATIC_READY_NOT_ENGINE'
scenes={'scenes/drafts/sect_maps_20261029k/wudang.tscn':'wudang_READY.tscn','scenes/drafts/huashan_map_20261029m/huashan.tscn':'huashan_READY.tscn'}
native=GAME/'build/three_towns_world_20261029j_system01/native_sources.json';registry=GAME/'build/three_towns_world_20261029j_system01/town_registry.gd'
before={p:p.read_bytes() for p in [native,registry]+[GAME/p for p in scenes]}
assert sha(before[native])=='c38bfc9c52d5f12419aadeffbbf18a574c9b7109fc7c86f3b8a2ddf78340d654','Native head changed: reread and explicitly rebase, never rollback.'
assert sha(before[registry])=='9da1cf4f403e9f5be9848da6feac8f89bfad78d618a94e85edb5f328b545bf79','Registry head changed: explicitly rebase.'
manifest=json.loads(before[native]);old_sources=manifest['sources'].copy();assert len(old_sources)==202
after={GAME/path:(HERE/candidate).read_bytes() for path,candidate in scenes.items()}
for p,b in after.items():manifest['sources']['res://'+str(p.relative_to(GAME)).replace('\\','/')]=sha(b)
modules=['actor_ghost.gd','wudang_controller.gd','huashan_controller.gd','adoption_contract.gd','router_entry.gd','sect_field.gd','sect_field.tscn','adoption_data.json']
new_modules=[]
for name in modules:
 p=HERE/name;b=p.read_bytes()
 if name.endswith('.gd'):assert b.endswith(b'\n') and not b.endswith(b'\n\n'),p
 uri='res://'+str(p.relative_to(GAME)).replace('\\','/');assert uri not in old_sources
 manifest['sources'][uri]=sha(b);new_modules.append({'path':str(p.relative_to(GAME.parent)).replace('\\','/'),'sha256':sha(b),'bytes':len(b)})
for row in visual['runtime_inputs']:
 p=GAME/row['path'].removeprefix('res://');b=p.read_bytes();assert sha(b)==row['sha256'],p
 if row['path'] not in manifest['sources']:manifest['sources'][row['path']]=sha(b)
 else:assert manifest['sources'][row['path']]==sha(b)
changed_old={k for k,v in old_sources.items() if manifest['sources'][k]!=v}
assert changed_old=={'res://'+p for p in scenes}
after[native]=(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n').encode()
r=before[registry]
old_entry=b'res://build/sect_adoption_20261030n_system01/router_entry.gd';assert r.count(old_entry)==1
r=r.replace(old_entry,b'res://build/sect_repair_20261031c_system01/router_entry.gd')
old_tail=b'&"openworld_wudang_gate",&"openworld_huashan_forecourt"]';assert r.count(old_tail)==1
r=r.replace(old_tail,b'&"openworld_wudang_gate",&"openworld_huashan_forecourt",&"openworld_wudang_taiji_court"]')
r=r.replace(sha(before[native]).encode(),sha(after[native]).encode());after[registry]=r
records=[];forward_all=[];inverse_all=[]
for p,b in after.items():
 label=p.name;before_fact=emit(label+'.FINAL_BEFORE',before[p]);candidate=emit(label+'.FINAL_READY',b)
 path=str(p.relative_to(GAME.parent)).replace('\\','/')
 f=''.join(difflib.unified_diff(before[p].decode().splitlines(True),b.decode().splitlines(True),fromfile=path,tofile=path))
 inv=''.join(difflib.unified_diff(b.decode().splitlines(True),before[p].decode().splitlines(True),fromfile=path,tofile=path))
 assert apply_delta(before[p],f)==b and apply_delta(b,inv)==before[p]
 emit(label+'.FINAL_FORWARD.diff',f.encode());emit(label+'.FINAL_INVERSE.diff',inv.encode());forward_all.append(f);inverse_all.append(inv)
 records.append({'target':path,'before':before_fact,'candidate':candidate,'byte_inverse_applied_exact':True})
forward=emit('combined_FINAL_FORWARD.diff',''.join(forward_all).encode());inverse=emit('combined_FINAL_INVERSE.diff',''.join(inverse_all).encode())
receipt={'status':'FROZEN_CANDIDATE_ONLY_ROOT_DEPLOYS_AND_RUNS','targets':records,'new_modules':new_modules,'runtime_inputs':visual['runtime_inputs'],'source_count_before':len(old_sources),'source_count_after':len(manifest['sources']),'old_source_keys_retained':True,'old_source_changed':sorted(changed_old),'old_registry16_IDs_retained':True,'added_existing_ID':'openworld_wudang_taiji_court','Router_change':False,'Player_change':False,'original_4_and_5_slope_physics':'byte-exact in the two final Scenes; verified by visual author proof','forward':forward,'inverse':inverse,'visual_proof_sha256':sha((HERE/'visual_READY.json').read_bytes()),'business_proof_sha256':sha((HERE/'business_STATIC_READY_01.json').read_bytes()),'engine_runs':0,'formal_writes':0,'save_content_access':False}
print(json.dumps(emit('replacement_receipt_FINAL_READY.json',(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode()),ensure_ascii=False))
