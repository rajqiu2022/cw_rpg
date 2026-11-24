"""Fixed DAD0 World4 parent plus actual0860 city25; no new World function/media, no Stage execution."""
from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'world4_READY08/';O=N/'world4_READY08'
assert not O.exists()
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'],pin;return b
def load(pin):return json.loads(read(pin))
data={}
def emit(name,b):
 assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
oldpin=dict(path=S+'world4_READY07/world4_seventh_head_candidates_ROOT_REVIEW.json',sha256='872d2a8e7a2d362e7989f51e5d84339cfeac71648d3c67f03572ee5dfbeb43db')
dadpin=dict(path=S+'world4_READY07/outputs/root_World_visual_exact4_stage07/receipt.json',sha256='dad0ef44403b90a3759cd8e2cfd1aff8cc331fde923b3f212da67a7ee350eb06')
deppin=dict(path=S+'Temple_actor_receipt_repair01/Temple_actor_receipt25_deployed_ROOT_ACTUAL.json',sha256='0860c9038a537bec69bd0d2091d45dfbdf8c5ef52163103aadfa0c19dc814395')
old=load(oldpin);dad=load(dadpin);dep=load(deppin);plan=copy.deepcopy(old)
assert dad['source_first']==dad['source_final']and dad['target_partition']==dict(patch_count=3,copy_count=1,total=4)and dep['passed']and dep['target_count']==25
assert {r['target']:r['candidate_sha256']for r in dad['targets']}=={r['target']:r['candidate']['sha256']for r in old['targets']}
current={r['target']:copy.deepcopy(r)for r in old['current_city36_expected']}
for r in dep['targets']:
 p=r['target'];assert current[p]['sha256']==r['old_sha256'];current[p]=dict(target=p,sha256=r['sha256'],bytes=r['bytes'])
assert len(current)==36
plan['current_city36_expected']=list(current.values());plan['current_city_protection_overlays'].append(deppin);plan['current_city_necessary_Temple_receipt25_deployment']=deppin;plan['current_city_Stage']=dep['stage'];plan['parent_World_Stage']=dadpin
FIELD='res://scripts/field/field_walkable_controller.gd';before='864bb14b896f4a1654d0d125478a4e2906bdd15d44e7f36092fe3cd3cdae123f';after='3eb013420320ed269f7e983de3cfce2e138b92f815971fef2005b9d39c47577c'
assert plan['expected_world_visual_source_sha256'][FIELD]==before and current[FIELD]['sha256']==after
plan['expected_world_visual_source_sha256'][FIELD]=after
assert set(plan['expected_world_visual_source_sha256'])==set(old['expected_world_visual_source_sha256'])and len(plan['expected_world_visual_source_sha256'])==87
assert {p for p,h in old['expected_world_visual_source_sha256'].items()if plan['expected_world_visual_source_sha256'][p]!=h}=={FIELD}
for key in ['targets','ordinary_source_sha256','protected_unchanged','Root_two_backup','unchanged_G_from_base32']:assert plan[key]==old[key]
plan['source_head_note']='Eighth fixed head only: inherited actual DAD0 World4 with its exact4 functions and54 media unchanged; city protection36 advances E53E->0860 actual25. World87 has only Field864B->3EB0 value replacement; original explicit WorldScene authority remains. No new media/import/geometry/city map/OWNED change. BUILD only, no World Stage/deploy/Field result.'
planpin=emit('world4_eighth_head_candidates_ROOT_REVIEW.json',enc(plan))
parentdriver=dict(path=S+'stage_World4_seventh_head_ROOT_ONLY.py',sha256='990d6c8741167e66291805cd212bfda62e6bdc1dbf9709c744e3b2ba51cbba79');raw=read(parentdriver);text=raw.decode();hunks=[]
def change(a,b):
 global text
 assert text.count(a)==1,(a[:100],text.count(a));text=text.replace(a,b,1);hunks.append(dict(old=a,new=b))
change("PREFIX='"+S+"world4_READY07/'","PREFIX='"+P+"'")
change("plan=load(spec['plan']);backup=load(plan['Root_two_backup']);", "plan=load(spec['plan']);dad=load(plan['parent_World_Stage']);M.need(dad['source_first']==dad['source_final']and dad['target_partition']==dict(patch_count=3,copy_count=1,total=4)and {r['target']:r['candidate_sha256']for r in dad['targets']}=={r['target']:r['candidate']['sha256']for r in plan['targets']},'EXACT_DAD0_PARENT_WORLD4_FUNCTIONS');backup=load(plan['Root_two_backup']);")
change("[row['target_count']for row in overlays]==[31,31,33]", "[row['target_count']for row in overlays]==[31,31,33,25]")
change('ROOT_SIX_OLD_PLUS_THREE_EXACT_OVERLAYS','ROOT_SIX_OLD_PLUS_FOUR_EXACT_OVERLAYS')
change("plan['current_city_latest33_deployment']==spec['city_deployment']", "plan['current_city_latest33_deployment']==spec['city_protection_overlays'][-2]and plan['current_city_necessary_Temple_receipt25_deployment']==spec['city_deployment']")
change('CURRENT33_FIXED_CANDIDATES_PRESERVED','CURRENT36_FIXED_CANDIDATES_PRESERVED')
back=text
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==raw;compile(text,'stage_World4_eighth_head_ROOT_ONLY.py','exec')
driver=dict(path=S+'stage_World4_eighth_head_ROOT_ONLY.py',sha256=sha(text.encode()),bytes=len(text.encode()))
oldinput=dict(path=S+'world4_READY07/source_input_World4_seventh_head_ROOT_REVIEW.json',sha256='b8944604b8071b425690f0a9566f54dedb7616e4129e1b09991d19d1884ba46e');spec=load(oldinput);oldspec=copy.deepcopy(spec)
spec.update(driver=driver,plan=planpin,city_deployment=deppin,city_Stage=dep['stage'],city_protection_overlays=plan['current_city_protection_overlays'],output_root=P+'outputs/root_World_visual_exact4_stage08/')
inputpin=emit('source_input_World4_eighth_head_ROOT_REVIEW.json',enc(spec))
def delta(a,b):return[dict(key=k,existed=k in a,old=a.get(k),new=v)for k,v in b.items()if k not in a or a[k]!=v]
pd,idelta=delta(old,plan),delta(oldspec,spec)
for a,b,changes in [(old,plan,pd),(oldspec,spec,idelta)]:
 v=copy.deepcopy(b)
 for r in reversed(changes):
  if r['existed']:v[r['key']]=r['old']
  else:del v[r['key']]
 assert v==a and enc({k:v[k]for k in a})==enc(a)
# Reuse the reviewed single JSON1 transport plus pre/post guard; Root supplies the future actual Stage08 SHA externally.
toolparent=dict(path=S+'transport_guard_World4_stage07_ROOT_ONLY.py',sha256='bbf898f55645e0542a4bdd1f5901c42a47a31c88d216ba9d011f658f669e882b');traw=read(toolparent);tool=traw.decode();ths=[]
def tc(a,b):
 global tool
 assert a in tool,a;tool=tool.replace(a,b);ths.append(dict(old=a,new=b))
for a,b in [('world4_READY07/','world4_READY08/'),('root_World_visual_exact4_stage07/','root_World_visual_exact4_stage08/'),('world4_seventh_head_candidates_ROOT_REVIEW.json','world4_eighth_head_candidates_ROOT_REVIEW.json'),('872d2a8e7a2d362e7989f51e5d84339cfeac71648d3c67f03572ee5dfbeb43db',planpin['sha256']),('visible_doors_boundaries33_repair01/visible_doors_boundaries33_deployed_ROOT_ACTUAL.json','Temple_actor_receipt_repair01/Temple_actor_receipt25_deployed_ROOT_ACTUAL.json'),('e53e6d557a60dc93e00120ed9541938cb51e54c5effd01383a086866ec8db6b2',deppin['sha256']),('visible_doors_boundaries33_repair01/current_signed31_backup33_ROOT_ACTUAL.json','Temple_actor_receipt_repair01/current_E53E_backup25_ROOT_ACTUAL.json'),('2b2be04ce2ee27e8f9d6782181a5f6999921a416ada094b9cafadb043742bff3','6cbdb68683733bc819978936225476bf4bf5ff16b2efb7f01b05a7af23b9e6bf'),("city['target_count']==33 and len(city['JSON15_written'])==15","city['target_count']==25 and len(city['JSON14_written'])==14"),("backup['total_backups']==436","backup['total_backups']==461"),('old403_backup_facts','old436_backup_facts'),("'old403_backups'","'old436_backups'"),("'new33_backups'","'new25_backups'"),("backup['current34']","backup['current36']"),('city_backups=436','city_backups=461')]:tc(a,b)
tc("ap.add_argument('--mode',choices=", "ap.add_argument('--stage-sha256',required=True);ap.add_argument('--mode',choices=")
tc("a=ap.parse_args()\n assert a.root_authorized_apply", "a=ap.parse_args()\n global STAGE\n assert len(a.stage_sha256)==64 and all(c in '0123456789abcdef'for c in a.stage_sha256),'EXACT_ROOT_ACTUAL_STAGE08_SHA_REQUIRED'\n STAGE=(STAGE[0],a.stage_sha256)\n assert a.root_authorized_apply")
tc("and len(stage['source_first'])==203", "and stage['city_Stage']==plan['current_city_Stage']and stage['city_deployment']==plan['current_city_necessary_Temple_receipt25_deployment']")
tb=tool
for h in reversed(ths):tb=tb.replace(h['new'],h['old'])
assert tb.encode()==traw;compile(tool,'transport_guard_World4_stage08_ROOT_ONLY.py','exec')
toolpin=dict(path=S+'transport_guard_World4_stage08_ROOT_ONLY.py',sha256=sha(tool.encode()),bytes=len(tool.encode()))
proof=emit('World4_eighth_head_full_inverse_READONLY.json',enc(dict(status='WORLD4_DAD0_PLUS_ACTUAL0860_HEAD_NOT_STAGE_NOT_DEPLOYED',parent_plan=oldpin,parent_World_Stage=dadpin,city_actual25=deppin,plan=planpin,input=inputpin,driver=driver,driver_parent=parentdriver,driver_hunks=hunks,whole_driver_byte_inverse=True,plan_top_level_delta=pd,input_top_level_delta=idelta,restore_plan_key_order=list(old),restore_input_key_order=list(oldspec),whole_plan_input_typed_UTF8_inverse=True,World_expected87_one_Field_value_change=dict(path=FIELD,old=before,new=after),World4_functions54media73ADbackup_unchanged=True,WorldScene_authority_unchanged=True,city_protection36_fixed=True,city_C4map_OWNED_execution_changes=0,transport=toolpin,transport_parent=toolparent,transport_hunks=ths,whole_transport_byte_inverse=True,Root_actual_future_Stage08_sha_required=True,no_new_backup_or_media_or_import=True,city_backup_total=461,Stage_calls=0,engine_calls=0,canonical_writes=0)))
O.mkdir()
for name,b in data.items():
 with(O/name).open('xb')as f:f.write(b)
for pin,b in [(driver,text.encode()),(toolpin,tool.encode())]:
 dest=G/pin['path'][6:];assert not dest.exists()
 with dest.open('xb')as f:f.write(b)
print(json.dumps(dict(plan=planpin,input=inputpin,driver=driver,transport=toolpin,proof=proof,Stage_calls=0)))
