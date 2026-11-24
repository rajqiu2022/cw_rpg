"""Propose an explicit Root-review manifest; stdout only, no save content or writes."""
from pathlib import Path
import hashlib,json,sys
R=Path('F:/Code/RPG_GAME');Q=R/'game/build/world_sects_cities_20261031c_qa01'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def data(p):return json.loads((R/p).read_text(encoding='utf-8-sig'))
def fact(p):
 p=Path(p);return {'sha256':sha(p),'bytes':p.stat().st_size}
baseline=data('game/build/world_sects_cities_20261031c_qa01/baseline_NOW_ACTUAL.json')
receipts=[
 'game/build/city_visual_diversity_20261031c/npc_water_manifest_READY.json',
 'game/build/city_visual_diversity_20261031c/district_manifest_READY.json',
 'game/build/city_visual_diversity_20261031c/field11_READY/receipt_READY.json',
 'game/build/sect_repair_20261031c_system01/replacement_receipt_ROOT_MERGE_READY.json',
 'game/build/sect_repair_20261031c_system01/native_dependencies_ROOT_MERGE_READY.json']
targets={};chains={};new={}
for name in receipts[:3]:
 d=data(name)
 for row in d['targets']:
  path=row['target'];chains.setdefault(path,[]).append({'receipt':name,'old_sha256':row['old_sha256'],'new_sha256':row['new_sha256'],'candidate':row['candidate'],'before':row.get('before','')})
  targets[path]={'after_sha256':row['new_sha256'],'after_bytes':row['bytes']}
 for p,v in d.get('new_modules',{}).items():new[p]=v
 snapshot=d.get('required_router_snapshot')
 if snapshot:new[snapshot['target']]={'sha256':snapshot['sha256'],'bytes':snapshot['bytes']}
sect=data(receipts[3]);dep=data(receipts[4])
for row in sect['scene_targets']:
 path=row['target'];targets[path]={'after_sha256':row['candidate']['sha256'],'after_bytes':row['candidate']['bytes']}
 chains[path]=[{'receipt':receipts[3],'old_sha256':row['before_sha256'],'new_sha256':row['candidate']['sha256'],'candidate':row['candidate']['path'],'before':'game/build/sect_repair_20261031c_system01/'+('wudang.tscn.BEFORE' if 'wudang' in path else 'huashan.tscn.BEFORE')}]
for p,h in dep['added_sources'].items():
 path='game/'+p[6:];new[path]={'sha256':h,'bytes':(R/path).stat().st_size}
for path in ['game/build/three_towns_world_20261029j_system01/native_sources.json','game/build/three_towns_world_20261029j_system01/town_registry.gd']:
 targets[path]={'after_sha256':sha(R/path),'after_bytes':(R/path).stat().st_size};chains[path]=[{'receipt':'ROOT_EXPLICIT_MERGED_HEAD','new_sha256':sha(R/path)}]
missing=[]
for path in targets:
 absolute=str(R/path).replace('\\','/')
 if absolute not in baseline['facts']:
  missing.append({'path':path,'historical_chain':chains[path]});continue
 targets[path].update(before_sha256=baseline['facts'][absolute]['sha256'],before_bytes=baseline['facts'][absolute]['bytes'],evidence_chain=chains[path])
 assert sha(R/path)==targets[path]['after_sha256'],('formal_head_not_receipt',path)
assert len(targets)==19,len(targets)
if '--missing-only' in sys.argv:
 print(json.dumps({'formal_targets':len(targets),'missing_fresh_baseline':missing},ensure_ascii=False));raise SystemExit(0)
historical={}
for row in missing:
 path=row['path'];chain=row['historical_chain'];before=chain[0]['before']
 historical[path]={**targets.pop(path),'historical_before_sha256':chain[0]['old_sha256'],'historical_before_bytes':(R/before).stat().st_size,'before_snapshot':before,'evidence_chain':chain,'fresh_baseline_included':False,'old_mtime_claimed':False}
 assert sha(R/before)==historical[path]['historical_before_sha256']
tasks='prompts/tasks.yaml';absolute=str(R/tasks).replace('\\','/')
if absolute in baseline['facts']:
 targets[tasks]={'before_sha256':baseline['facts'][absolute]['sha256'],'before_bytes':baseline['facts'][absolute]['bytes'],'after_sha256':sha(R/tasks),'after_bytes':(R/tasks).stat().st_size,'evidence_chain':[{'receipt':'ROOT_AUTHORIZED_SIX_IMAGE_TASK_REGISTRATION'}]}
for path in ['game/build/world_landmarks_20261031c/refinement.gd','game/build/world_landmarks_20261031c/path_blend.gdshader','game/art/modules/environment_repair_20261031c/lanxi_world_landmark_v1.png']:
 new[path]=fact(R/path)
watch='game/build/three_towns_world_20261029j_system01/world_watcher.gd'
proof='game/build/world_landmarks_20261031c/inverse_world_watcher_READONLY.py'
native='game/build/three_towns_world_20261029j_system01/native_sources.json'
registry='game/build/three_towns_world_20261029j_system01/town_registry.gd'
out={
 'schema_version':1,'status':'ROOT_MUST_REVIEW_AND_SUPPLY_EXPLICIT_MANIFEST_SHA_NOT_AUTO_ACCEPT_CURRENT',
 'baseline_sha256':'59b75d6bdd34fb4dfe82ffff189f38140a0beacac0b3839b3a5491c68913e127','baseline_source_count':1770,'save_count':171,'expected_absent_count':9,
 'allowed_old_targets':targets,'historical_authorized_targets':historical,'new_runtime_pins':new,
 'receipt_pins':{p:fact(R/p) for p in receipts},
 'native_path':native,'native_count':len(data(native)['sources']),'native_before':{'path':'game/build/world_sects_cities_20261031c_root01/native_sources.BEFORE.json',**fact(R/'game/build/world_sects_cities_20261031c_root01/native_sources.BEFORE.json')},
 'old_native_updated_source_keys':dep['updated_existing_sources'],
 'registry_path':registry,'registry_count':17,'registry_before':{'path':'game/build/sect_repair_20261031c_system01/town_registry.MERGE_BASE_BEFORE',**fact(R/'game/build/sect_repair_20261031c_system01/town_registry.MERGE_BASE_BEFORE')},
 'unseeded_authorized_old':{'path':watch,**fact(R/watch),'historical_before_sha256':'4039dc896fa152890bc828761d748a9d1da8e94bc73b1abe9170f213d1a48986','historical_before_bytes':8312,'proof_script':{'path':proof,**fact(R/proof)},'fresh_baseline_included':False,'old_mtime_claimed':False},
 'guard_policy':'Root explicit expected manifest and SHA required; later tiny visual residual gets a distinct manifest, never rebase fresh metadata or silently accept current heads',
 'engine_runs':0,'source_writes':0,'save_content_reads':0
}
print(json.dumps(out,ensure_ascii=False,separators=(',',':')))
