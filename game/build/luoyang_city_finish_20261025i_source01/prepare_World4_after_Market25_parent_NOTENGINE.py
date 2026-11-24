"""World4 pure expected-parent successor: 4160 ->5D6C ->94A1. Never Stage/deploy."""
from pathlib import Path
import json,hashlib,copy
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def load(p):
 b=(G/p['path'][6:]).read_bytes();assert sha(b)==p['sha256'];return json.loads(b)
def write(name,b):
 p=N/name;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=S+name,sha256=sha(b),bytes=len(b))
oldplanpin=dict(path=S+'world4_READY02/world4_candidates_and_sources_ROOT_REVIEW.json',sha256='c834ab2d4b947e33aefc3575e816c6e5ea5f4089dd80af3a9ee080d1cdb2b55b');old=load(oldplanpin);plan=copy.deepcopy(old)
latestpin=dict(path=S+'market_ground_texture_repair02/Market_ground25_deployed_ROOT_ACTUAL.json',sha256='94a103b720595845fd480793a12a4865d7f433493fc0950de01e63d210587ce3')
latest=load(latestpin);assert latest['passed']and latest['target_count']==25 and latest['status']=='ROOT_MARKET_AE25_DEPLOYED_GD11_PATCH_JSON14_EXACTCOPY'
stagepin=dict(path=S+'outputs/root_Market_AE_texture_exact25_stage01/receipt.json',sha256='e8af175eadaedd299db5e4a25e6b51fb8b8fccb933ad563788aa6b13f3358b89');stage=load(stagepin);assert latest['stage']==stagepin
current={r['target']:copy.deepcopy(r)for r in plan['current_city32_expected']};prior=load(plan['current_city_repair_deployment']);assert len(current)==32
for r in latest['targets']:assert current[r['target']]['sha256']==r['old_sha256'];current[r['target']]=dict(target=r['target'],sha256=r['sha256'],bytes=r['bytes'])
plan['current_city_latest25_deployment']=latestpin;plan['current_city_Stage']=stagepin;plan['current_city32_expected']=list(current.values());plan['city_B_CDE_actual_result_pending']=True
cm=stage['nodes']['expected_ch4_s0_luoyang_gate_true']['value']['source_sha256']
for p in ['res://scripts/field/field_walkable_controller.gd','res://scripts/autoload/scene_router.gd']:plan['expected_world_visual_source_sha256'][p]=cm[p]
assert plan['targets']==old['targets']and plan['ordinary_source_sha256']==old['ordinary_source_sha256']and plan['protected_unchanged']==old['protected_unchanged']and plan['Root_two_backup']==old['Root_two_backup']and plan['unchanged_G_from_base32']==old['unchanged_G_from_base32']
planpin=write('world4_READY03/world4_candidates_and_sources_ROOT_REVIEW.json',enc(plan));parent=(N/'stage_World4_after_repair31_ROOT_ONLY.py').read_bytes();text=parent.decode();hunks=[]
def change(a,b):
 global text
 assert text.count(a)==1;text=text.replace(a,b);hunks.append(dict(old=a,new=b))
start=text.index(" base=load(spec['city_parent_deployment']);city=load(spec['city_deployment'])");end=text.index(" M.need(plan['target_partition']",start);a=text[start:end]
b=""" base=load(spec['city_parent_deployment']);repair=load(spec['city_intermediate_repair_deployment']);city=load(spec['city_deployment'])
 M.need(base['passed']is True and base['target_count']==32 and len(base['targets'])==32 and repair['passed']is True and repair['target_count']==31 and len(repair['targets'])==31 and city['passed']is True and city['target_count']==25 and len(city['targets'])==25,'ROOT_CURRENT_CITY32_PLUS_REPAIR31_PLUS_MARKET25_DEPLOYED')
 current={r['target']:r for r in base['targets']};changed={r['target']for r in repair['targets']}
 M.need(set(current)-changed=={'res://scripts/city/luoyang_assembled_interiors_20261016g.gd'}and plan['current_city_parent_deployment']==spec['city_parent_deployment']and plan['current_city_repair_deployment']==spec['city_intermediate_repair_deployment']and plan['current_city_latest25_deployment']==spec['city_deployment']and plan['current_city_Stage']==spec['city_Stage'],'EXACT_THREE_LAYER_CITY_PARENT')
 for r in repair['targets']:M.need(current[r['target']]['sha256']==r['old_sha256'],'EXACT_REPAIR31_4160_OLD_VALUE');current[r['target']]=r
 latest25={r['target']for r in city['targets']};M.need(latest25<=changed and len(changed-latest25)==6,'ONLY_25_REAL_MARKET_SOURCE_SUCCESSORS')
 for r in city['targets']:M.need(current[r['target']]['sha256']==r['old_sha256'],'EXACT_MARKET25_5D6C_OLD_VALUE');current[r['target']]=r
 expected_city={r['target']:r for r in plan['current_city32_expected']};M.need(set(expected_city)==set(current)and len(current)==32,'CURRENT_CITY32_EXACT_SCOPE')
 for p,r in current.items():M.need(expected_city[p]['sha256']==r['sha256']and expected_city[p]['bytes']==r['bytes']and len(read(p,r['sha256']))==r['bytes'],'CITY32_PRESERVE_CURRENT_CANDIDATES')
"""
change(a,b)
change("cpin=next(r for r in city['targets']if r['target']=='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd')","cpin=current['res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd']")
back=text
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==parent;compile(text,'stage_World4_after_Market25_ROOT_ONLY.py','exec');driver=write('stage_World4_after_Market25_ROOT_ONLY.py',text.encode())
spec=dict(status='ROOT_LOCKED_SEPARATE_WORLD4_VISUAL_STAGE_INPUT',driver=driver,plan=planpin,city_parent_deployment=plan['current_city_parent_deployment'],city_intermediate_repair_deployment=plan['current_city_repair_deployment'],city_deployment=latestpin,city_Stage=stagepin,city_OWNED_or_execution_changes=0,output_root=S+'outputs/root_World_visual_exact4_stage03/',Root_city_B_CDE_result_still_pending=True)
ip=write('source_input_World_visual_exact4_after_Market25_ROOT_REVIEW.json',enc(spec));proof=write('world4_READY03/three_layer_parent_and_Field_expected_successor_READONLY.json',enc(dict(status='WORLD4_THREE_LAYER_PARENT_ONLY_NOT_STAGE_NOT_DEPLOYED',parent_plan=oldplanpin,plan=planpin,driver=driver,input=ip,driver_parent_sha256=sha(parent),driver_hunks=hunks,whole_driver_byte_inverse=True,World4_candidates_hunks_54_media_73AD_backup_all_unchanged=True,Field_expected=cm['res://scripts/field/field_walkable_controller.gd'],current_city32_from_fixed_4160_plus5D6C_plus94A=True,Root_city_B_CDE_actual_pending=True,Stage_calls=0,engine_calls=0,canonical_writes=0)))
print(json.dumps(dict(plan=planpin,driver=driver,input=ip,proof=proof)))
