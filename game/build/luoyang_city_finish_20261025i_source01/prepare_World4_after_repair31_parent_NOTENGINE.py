"""Separate World4 prospective Stage parent update only; no Stage/engine/deployment."""
from pathlib import Path
import json,hashlib,copy
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def load(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h;return json.loads(b)
def write(name,b):
 p=N/name;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=S+name,sha256=sha(b),bytes=len(b))
basepin=dict(path=S+'exact32_deployed_ROOT_ACTUAL.json',sha256='4160b4c149a71bd0e6dfa8975b0fc5f463f782f0fcff50acd630335b5ccd3142')
repairpin=dict(path=S+'repair31_Field11_deployed_ROOT_ACTUAL.json',sha256='5d6c2f7aa10d5c4763ade8d3eb7ce60983f011bbb677ed0e6b5e4e5148dc29a1')
stagepin=dict(path=S+'outputs/root_gate_texture_market_portal_exact31_stage02/receipt.json',sha256='275c361814da7d130957d14b524be1daa07940291e615ba01ad36d70e6bccb74')
base=load(**dict(p=basepin['path'],h=basepin['sha256']));repair=load(repairpin['path'],repairpin['sha256']);stage=load(stagepin['path'],stagepin['sha256'])
assert base['passed']and repair['passed']and repair['stage']==stagepin and base['target_count']==32 and repair['target_count']==31
current={r['target']:copy.deepcopy(r)for r in base['targets']};GID='res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
assert set(current)-{r['target']for r in repair['targets']}=={GID}
for r in repair['targets']:assert current[r['target']]['sha256']==r['old_sha256'];current[r['target']]=copy.deepcopy(r)
oldplanpin=dict(path=S+'world4_READY01/world4_candidates_and_sources_ROOT_REVIEW.json',sha256='db13a08ffd1c27c45900d55d8b8366b2009f2273b53d77e20695673b7f4b70d4');oldplan=load(oldplanpin['path'],oldplanpin['sha256']);plan=copy.deepcopy(oldplan)
plan['current_city_parent_deployment']=basepin;plan['current_city_repair_deployment']=repairpin;plan['current_city_Stage']=stagepin
plan['current_city32_expected']=[dict(target=p,sha256=r['sha256'],bytes=r['bytes'])for p,r in current.items()]
plan['unchanged_G_from_base32']=dict(target=GID,sha256=current[GID]['sha256'],bytes=current[GID]['bytes'])
cm=stage['nodes']['expected_ch4_s0_luoyang_gate_true']['value']['source_sha256']
for p in ['res://scripts/field/field_walkable_controller.gd','res://scripts/autoload/scene_router.gd']:plan['expected_world_visual_source_sha256'][p]=cm[p]
assert plan['targets']==oldplan['targets']and plan['ordinary_source_sha256']==oldplan['ordinary_source_sha256']and plan['protected_unchanged']==oldplan['protected_unchanged']and plan['Root_two_backup']==oldplan['Root_two_backup']
plan['city_A_B_actual_result_pending']=True;planpin=write('world4_READY02/world4_candidates_and_sources_ROOT_REVIEW.json',enc(plan))
parent=(N/'stage_World4_visual_ROOT_ONLY.py').read_bytes();text=parent.decode();hunks=[]
def change(a,b):
 global text
 assert text.count(a)==1;text=text.replace(a,b);hunks.append(dict(old=a,new=b))
change(" city=load(spec['city_deployment']);M.need(city['passed']is True and city['target_count']==32 and len(city['targets'])==32,'ROOT_CURRENT_CITY32_DEPLOYED')\n for r in city['targets']:M.need(len(read(r['target'],r['sha256']))==r['bytes'],'CITY32_PRESERVE_CURRENT_CANDIDATES')", """ base=load(spec['city_parent_deployment']);city=load(spec['city_deployment'])
 M.need(base['passed']is True and base['target_count']==32 and len(base['targets'])==32 and city['passed']is True and city['target_count']==31 and len(city['targets'])==31,'ROOT_CURRENT_CITY32_PLUS_REPAIR31_DEPLOYED')
 current={r['target']:r for r in base['targets']};changed={r['target']for r in city['targets']}
 M.need(set(current)-changed=={'res://scripts/city/luoyang_assembled_interiors_20261016g.gd'}and plan['current_city_parent_deployment']==spec['city_parent_deployment']and plan['current_city_repair_deployment']==spec['city_deployment']and plan['current_city_Stage']==spec['city_Stage'],'EXACT_REPAIR31_PLUS_UNCHANGED_G_PARENT')
 for r in city['targets']:M.need(current[r['target']]['sha256']==r['old_sha256'],'EXACT_REPAIR_4160_OLD_VALUE');current[r['target']]=r
 expected_city={r['target']:r for r in plan['current_city32_expected']};M.need(set(expected_city)==set(current)and len(current)==32,'CURRENT_CITY32_EXACT_SCOPE')
 for p,r in current.items():M.need(expected_city[p]['sha256']==r['sha256']and expected_city[p]['bytes']==r['bytes']and len(read(p,r['sha256']))==r['bytes'],'CITY32_PRESERVE_CURRENT_CANDIDATES')""")
change("for p in ['res://scripts/field/field_walkable_controller.gd','res://scripts/autoload/scene_router.gd']:M.need(p in cm,'FIXED_CITY_CURRENT_AUTHORITY');expected[p]=cm[p];read(p,cm[p])","for p in ['res://scripts/field/field_walkable_controller.gd','res://scripts/autoload/scene_router.gd']:M.need(p in cm and expected.get(p)==cm[p],'FIXED_CITY_CURRENT_AUTHORITY');read(p,cm[p])")
back=text
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==parent;compile(text,'stage_World4_after_repair31_ROOT_ONLY.py','exec');driver=write('stage_World4_after_repair31_ROOT_ONLY.py',text.encode())
spec=dict(status='ROOT_LOCKED_SEPARATE_WORLD4_VISUAL_STAGE_INPUT',driver=driver,plan=planpin,city_parent_deployment=basepin,city_deployment=repairpin,city_Stage=stagepin,city_OWNED_or_execution_changes=0,output_root=S+'outputs/root_World_visual_exact4_stage02/',Root_city_A_B_result_still_pending=True)
ip=write('source_input_World_visual_exact4_after_repair31_ROOT_REVIEW.json',enc(spec))
proof=write('world4_READY02/parent_and_Field_expected_exact_successor_READONLY.json',enc(dict(status='WORLD4_PARENT_ONLY_SUCCESSOR_NOT_STAGE_NOT_DEPLOYED',parent_plan=oldplanpin,plan=planpin,driver=driver,input=ip,driver_parent_sha256=sha(parent),driver_hunks=hunks,whole_driver_byte_inverse=True,World4_target_candidates_and_hunks_unchanged=True,World2_old_backup_73AD_unchanged=True,city32_scope_from_fixed_base32_plus_actual31=True,unchanged_G=plan['unchanged_G_from_base32'],new_Field_expected=cm['res://scripts/field/field_walkable_controller.gd'],Root_city_A_B_result_still_pending=True,engine_calls=0,Stage_calls=0,canonical_writes=0)))
print(json.dumps(dict(plan=planpin,driver=driver,input=ip,proof=proof)))
