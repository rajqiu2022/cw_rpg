"""Root-only separate World visual4 Stage. No city DAG/OWNED changes and no engine/import."""
import json,hashlib,argparse,importlib.util
from pathlib import Path
GAME=Path(__file__).resolve().parents[2];PREFIX='res://build/luoyang_city_finish_20261025i_source01/world4_READY07/'
CORE=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py';assert hashlib.sha256(CORE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
sp=importlib.util.spec_from_file_location('fixed_patch_only',CORE);M=importlib.util.module_from_spec(sp);sp.loader.exec_module(M)
def run(spec):
 first={}
 def read(p,h):
  raw=M.res(p).read_bytes();M.need(M.digest(raw)==h,'FIXED_SOURCE_SHA:'+p);first[p]=h;return raw
 def load(pin):return json.loads(read(pin['path'],pin['sha256']))
 M.need(spec['status']=='ROOT_LOCKED_SEPARATE_WORLD4_VISUAL_STAGE_INPUT'and spec['city_OWNED_or_execution_changes']==0,'WORLD_ONLY_SCOPE')
 M.need(spec['driver']['path']=='res://'+Path(__file__).resolve().relative_to(GAME).as_posix()and spec['driver']['sha256']==M.digest(Path(__file__).read_bytes()),'DRIVER_EXACT_PIN')
 read(spec['driver']['path'],spec['driver']['sha256']);load(spec['_locked_input'])
 plan=load(spec['plan']);backup=load(plan['Root_two_backup']);M.need(backup['count']==2 and backup['canonical_writes']==0,'ROOT_TWO_BACKUP')
 base=load(spec['city_parent_deployment']);repair=load(spec['city_intermediate_repair_deployment']);market=load(spec['city_previous_market25_deployment']);city=load(spec['city_previous_authority20_deployment']);latest=load(spec['city_previous_gallery32_deployment']);culture=load(spec['city_previous_culture24_deployment']);overlays=[load(pin)for pin in spec['city_protection_overlays']]
 M.need(base['passed']is True and base['target_count']==32 and repair['passed']is True and repair['target_count']==31 and market['passed']is True and market['target_count']==25 and city['passed']is True and city['target_count']==20 and latest['passed']is True and latest['target_count']==32 and culture['passed']is True and culture['target_count']==24 and [row['target_count']for row in overlays]==[31,31,33]and all(row['passed']is True for row in overlays),'ROOT_SIX_OLD_PLUS_THREE_EXACT_OVERLAYS')
 current={r['target']:r for r in base['targets']};changed={r['target']for r in repair['targets']}
 M.need(set(current)-changed=={'res://scripts/city/luoyang_assembled_interiors_20261016g.gd'}and plan['current_city_parent_deployment']==spec['city_parent_deployment']and plan['current_city_repair_deployment']==spec['city_intermediate_repair_deployment']and plan['current_city_previous25_deployment']==spec['city_previous_market25_deployment']and plan['current_city_previous20_deployment']==spec['city_previous_authority20_deployment']and plan['current_city_previous32_deployment']==spec['city_previous_gallery32_deployment']and plan['current_city_latest24_deployment']==spec['city_previous_culture24_deployment']and plan['current_city_protection_overlays']==spec['city_protection_overlays']and plan['current_city_latest33_deployment']==spec['city_deployment']and spec['city_deployment']==spec['city_protection_overlays'][-1]and plan['current_city_Stage']==spec['city_Stage'],'EXACT_FOUR_LAYER_PARENT')
 for r in repair['targets']:M.need(current[r['target']]['sha256']==r['old_sha256'],'EXACT_REPAIR_OLD');current[r['target']]=r
 for r in market['targets']:M.need(current[r['target']]['sha256']==r['old_sha256'],'EXACT_MARKET_OLD');current[r['target']]=r
 for r in city['targets']:
  p=r['target']
  if p in current:M.need(current[p]['sha256']==r['old_sha256'],'EXACT_DECLARED20_OLD')
  else:M.need(p=='res://scripts/city/luoyang_execution_authority_20261022ap.gd'and r['old_sha256']=='621343ea4bc1486dcd0ff16405d92ed0ec08747d10a5c503f4cd5e2507db30fd','ONLY_33RD_ORDINARY_AUTHORITY_SOURCE')
  current[p]=r
 for r in latest['targets']:
  p=r['target']
  if p in current:M.need(current[p]['sha256']==r['old_sha256'],'EXACT_LATEST32_OLD')
  else:M.need(p=='res://scripts/autoload/scene_router.gd'and r['old_sha256']=='908f2254539010557b7ebfdc1cb77f86f6a05b068d1386741268b39a9cadeb51','ONLY_SEPARATE_ROUTER_JOINS_FIXED_CITY_SCOPE')
  current[p]=r
 for r in culture['targets']:
  p=r['target'];M.need(p in current and current[p]['sha256']==r['old_sha256'],'EXACT_ONLY_EXISTING_CT24_COUNTER_OVERLAY');current[p]=r
 M.need(set(plan['current_city_new_protection_old_sha256'])=={'res://data/maps/luoyang_full_city_20261022ap/environment.json','res://scripts/city/luoyang_environment_index_20261022ap.gd'},'ONLY_TWO_EXISTING_ENV_PROTECTION_TARGETS')
 for overlay in overlays:
  for r in overlay['targets']:
   p=r['target']
   if p in current:M.need(current[p]['sha256']==r['old_sha256'],'EXACT_POST_F67E_CURRENT_PARENT_OVERLAY')
   else:M.need(plan['current_city_new_protection_old_sha256'].get(p)==r['old_sha256'],'EXACT_TWO_EXISTING_ENV_OLD_SHA')
   current[p]=r
 expected_city={r['target']:r for r in plan['current_city36_expected']};M.need(set(expected_city)==set(current)and len(current)==36,'CURRENT36_EXACT_FIXED_SCOPE')
 for p,r in current.items():M.need(expected_city[p]['sha256']==r['sha256']and expected_city[p]['bytes']==r['bytes']and len(read(p,r['sha256']))==r['bytes'],'CURRENT33_FIXED_CANDIDATES_PRESERVED')
 M.need(plan['target_partition']==dict(GD=3,JSON=1,total=4)and plan['no_city_OWNED_or_execution_change']is True and plan['trial_permission_not_result']is True,'EXACT_WORLD4_3GD1JSON')
 M.need(len(plan['targets'])==4 and len({r['target']for r in plan['targets']})==4,'EXACT_FOUR_UNIQUE_TARGETS')
 for p,h in plan['ordinary_source_sha256'].items():read(p,h)
 for p,h in plan['protected_unchanged'].items():read(p,h)
 targets=[];pieces=['*** Begin Patch\n'];jsonplan=[];patchproof={}
 for r in plan['targets']:
  p=r['target'];pin=r['candidate'];after=read(pin['path'],pin['sha256']);M.need(len(after)==pin['bytes'],'CANDIDATE_BYTES')
  if r['old_sha256']=='ABSENT':M.need(not M.res(p).exists(),'EXACT_NEW_TARGET_ABSENT:'+p);before=None
  else:
   b=next(row for row in backup['rows']if row['target']==p);M.need(b['expected_sha256']==r['old_sha256'],'ROOT_FIXED_OLD_HOOK');before=read(p,r['old_sha256']);M.need(Path(b['backup']).read_bytes()==before and len(before)==b['bytes'],'ROOT_WHOLE_BACKUP_EXACT');f,v=before.decode(),after.decode()
   for h in r['hunks']:M.need(f.count(h['old'])==1,'UNIQUE_HOOK_FORWARD');f=f.replace(h['old'],h['new'],1)
   for h in reversed(r['hunks']):M.need(v.count(h['new'])==1,'UNIQUE_HOOK_REVERSE');v=v.replace(h['new'],h['old'],1)
   M.need(f.encode()==after and v.encode()==before,'EXACT_HOOK_WHOLE_BYTE_INVERSE')
  t=dict(target=p,old_sha256=r['old_sha256'],candidate_path=pin['path'],candidate_sha256=pin['sha256']);targets.append(t)
  if p.endswith('.gd'):
   part,pf=M._strict_lf_build_file_patch(M.res(p).as_posix(),before,after);pieces.append(part);patchproof[p]=pf
  else:M.need(p.endswith('.json')and before is None,'ONLY_NEW_MANIFEST_JSON');json.loads(after);jsonplan.append({**t,'candidate_bytes':len(after),'mechanism':'CREATE_NEW_EXACT_BYTES_ABSENT_ONLY'})
 M.need(len(patchproof)==3 and len(jsonplan)==1,'ONLY_3GD_PATCH_1_NEW_JSON')
 out=spec['output_root'];M.need(out.startswith(PREFIX+'outputs/')and out.endswith('/')and not M.res(out).exists(),'NEW_WORLD_STAGE_OUTPUT_ONLY');outputs={}
 def output(name,data):
  p=out+name;M.need(p not in outputs,'UNIQUE_OUTPUT');outputs[p]=data;return dict(path=p,sha256=M.digest(data))
 pieces.append('*** End Patch\n');patch=output('world4_canonical.apply_patch',''.join(pieces).encode());copies=output('world4_NEW_JSON_CreateNew_plan.json',M.encode(dict(rows=jsonplan,GD_writes=0,overwrite_existing=False)))
 expected=dict(plan['expected_world_visual_source_sha256']);city_stage=load(spec['city_Stage']);cm=city_stage['nodes']['expected_ch4_s0_luoyang_gate_true']['value']['source_sha256']
 for p in ['res://scripts/field/field_walkable_controller.gd','res://scripts/autoload/scene_router.gd']:M.need(p in cm and expected.get(p)==cm[p],'FIXED_CITY_CURRENT_AUTHORITY');read(p,cm[p])
 # Existing C's explicit v15 source contract pins the real world Scene, not a made-up alias.
 cpin=current['res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'];ctext=read(cpin['target'],cpin['sha256']).decode();literal='const FRESH_WORLD_V15_SOURCE := {"scene":"res://data/scenes/world_map_jianghu.tres","scene_sha":"685876ac86cb3b739f9b51be12da60e4a125480c715da2d08f9b486d76e5a046"';M.need(literal in ctext,'ORIGINAL_EXPLICIT_WORLD_SCENE_AUTHORITY');expected['res://data/scenes/world_map_jianghu.tres']='685876ac86cb3b739f9b51be12da60e4a125480c715da2d08f9b486d76e5a046';read('res://data/scenes/world_map_jianghu.tres',expected['res://data/scenes/world_map_jianghu.tres'])
 ep=output('expected_World_visual_sources.json',M.encode(dict(status='SOURCE_DERIVED_WORLD_VISUAL_TRIAL_EXPECTATIONS_NOT_OBSERVATION',source_sha256=expected)))
 final={p:M.digest(M.res(p).read_bytes())for p in first};M.need(first==final,'ALL_WORLD_SOURCE_FIRST_FINAL_SAME')
 receipt=dict(status='SEPARATE_WORLD_EXACT4_STAGED_NOT_DEPLOYED_NOT_RESULT',targets=targets,target_partition=dict(patch_count=3,copy_count=1,total=4),source_first=first,source_final=final,patch_path=patch['path'],patch_sha256=patch['sha256'],patch_reconstruction=patchproof,byte_copy_plan={**copies,'target_count':1},nodes=dict(expected_World_visual_sources={**ep,'value':dict(source_sha256=expected)}),city_Stage=spec['city_Stage'],city_deployment=spec['city_deployment'],no_city_DAG_or_OWNED_or_execution_change=True,old_source_layout_stream_and64walks_unchanged=True,no_engine_import_geometry_collector_or_canonical_write=True,actual_World_Field_pass=False)
 rp=output('receipt.json',M.encode(receipt))
 for p,b in outputs.items():
  dest=M.res(p);M.need(not dest.exists(),'PRESERVE_OLD_OUTPUT');dest.parent.mkdir(parents=True,exist_ok=True)
  with dest.open('xb')as f:f.write(b)
 return dict(receipt=rp,targets=4,source_count=len(first))
if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('input');ap.add_argument('--input-sha256',required=True);a=ap.parse_args();p=Path(a.input).resolve();b=p.read_bytes();M.need(M.digest(b)==a.input_sha256,'EXTERNAL_INPUT_SHA');v=json.loads(b);v['_locked_input']=dict(path='res://'+p.relative_to(GAME).as_posix(),sha256=a.input_sha256);print(json.dumps(run(v)))
