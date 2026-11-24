"""Existing World4 candidates unchanged; fixed47CC city protection/source head only. No Stage/guard execution."""
from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'world4_READY09/';O=N/'world4_READY09';assert not O.exists()
sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'],pin;return b
def load(pin):return json.loads(read(pin))
data={}
def emit(name,b):
 assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
oldpin=dict(path=S+'world4_READY08/world4_eighth_head_candidates_ROOT_REVIEW.json',sha256='febe84f68222fd82d87c33a2bd855370e4df88f9f65f49c260986165a4b8fd74');old=load(oldpin);plan=copy.deepcopy(old)
deppin=dict(path=S+'Estate_wall_source_repair01/Estate_wall_source31_deployed_ROOT_ACTUAL.json',sha256='47cc68861ae8165dd1517cf77787165d4f48d708faa10e587a062c3193860583');dep=load(deppin);assert dep['passed']and dep['target_count']==31
current={r['target']:copy.deepcopy(r)for r in old['current_city36_expected']};world_changes={}
for r in dep['targets']:
 p=r['target'];assert current[p]['sha256']==r['old_sha256'];current[p]=dict(target=p,sha256=r['sha256'],bytes=r['bytes'])
 if p in plan['expected_world_visual_source_sha256']:
  assert plan['expected_world_visual_source_sha256'][p]==r['old_sha256'];world_changes[p]=dict(old=r['old_sha256'],new=r['sha256']);plan['expected_world_visual_source_sha256'][p]=r['sha256']
assert len(current)==36 and len(plan['expected_world_visual_source_sha256'])==87
assert set(world_changes)=={'res://scripts/field/field_walkable_controller.gd'}
for k in ['targets','ordinary_source_sha256','protected_unchanged','Root_two_backup','unchanged_G_from_base32','parent_World_Stage']:assert plan[k]==old[k]
plan.update(current_city36_expected=list(current.values()),current_city_necessary_Estate_wall_source31_deployment=deppin,current_city_Stage=dep['stage'])
plan['current_city_protection_overlays'].append(deppin)
plan['source_head_note']='Ninth fixed head only: World08 candidate plus actual47CC city31 exact oldSHA overlay. Only Field3EB0->BDDA intersects the fixed World87 table; other86 values and original explicit WorldScene authority remain. Existing World4 functions54 media73AD backup unchanged; city36 protected492 backups125+54 media15save. BUILD only, no World Stage/deploy/actual claim.'
planpin=emit('world4_ninth_head_candidates_ROOT_REVIEW.json',enc(plan))
dp=dict(path=S+'stage_World4_eighth_head_ROOT_ONLY.py',sha256='f820a4c599141eab4315d0b8ec2f8db4ba01030d4a90f9dafadb5d62ee25fc6f');parent=read(dp);text=parent.decode();hs=[]
def change(a,b):
 global text
 assert text.count(a)==1,(a[:90],text.count(a));text=text.replace(a,b,1);hs.append(dict(old=a,new=b))
for a,b in [("PREFIX='"+S+"world4_READY08/'","PREFIX='"+P+"'"),('[row[\'target_count\']for row in overlays]==[31,31,33,25]',"[row['target_count']for row in overlays]==[31,31,33,25,31]"),('ROOT_SIX_OLD_PLUS_FOUR_EXACT_OVERLAYS','ROOT_SIX_OLD_PLUS_FIVE_EXACT_OVERLAYS'),("plan['current_city_latest33_deployment']==spec['city_protection_overlays'][-2]","plan['current_city_latest33_deployment']==spec['city_protection_overlays'][-3]"),("plan['current_city_necessary_Temple_receipt25_deployment']==spec['city_deployment']","plan['current_city_necessary_Temple_receipt25_deployment']==spec['city_protection_overlays'][-2]and plan['current_city_necessary_Estate_wall_source31_deployment']==spec['city_deployment']")]:change(a,b)
back=text
for h in reversed(hs):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==parent;compile(text,'stage_World4_ninth_head_ROOT_ONLY.py','exec');driver=dict(path=S+'stage_World4_ninth_head_ROOT_ONLY.py',sha256=sha(text.encode()),bytes=len(text.encode()))
ip=dict(path=S+'world4_READY08/source_input_World4_eighth_head_ROOT_REVIEW.json',sha256='d8dfb1c621a5242641eb7def5384d1ba2b193fbc8df1767337a3aa6f47c5293e');oldspec=load(ip);spec=copy.deepcopy(oldspec)
spec.update(driver=driver,plan=planpin,city_deployment=deppin,city_Stage=dep['stage'],city_protection_overlays=plan['current_city_protection_overlays'],output_root=P+'outputs/root_World_visual_exact4_stage09/')
inputpin=emit('source_input_World4_ninth_head_ROOT_REVIEW.json',enc(spec))
def delta(a,b):return[dict(key=k,existed=k in a,old=a.get(k),new=v)for k,v in b.items()if k not in a or a[k]!=v]
pd,idelta=delta(old,plan),delta(oldspec,spec)
for a,b,changes in [(old,plan,pd),(oldspec,spec,idelta)]:
 v=copy.deepcopy(b)
 for r in reversed(changes):
  if r['existed']:v[r['key']]=r['old']
  else:del v[r['key']]
 assert v==a and enc({k:v[k]for k in a})==enc(a)
tp=dict(path=S+'transport_guard_World4_stage08_ROOT_ONLY.py',sha256='b7c1f4e80920a893dc698d62df8e13c567ac844ddd0cadb616bb8ab4c9f09ede');traw=read(tp);tool=traw.decode();ths=[]
def tc(a,b):
 global tool
 assert a in tool,a;tool=tool.replace(a,b);ths.append(dict(old=a,new=b))
for a,b in [('world4_READY08/','world4_READY09/'),('root_World_visual_exact4_stage08/','root_World_visual_exact4_stage09/'),('world4_eighth_head_candidates_ROOT_REVIEW.json','world4_ninth_head_candidates_ROOT_REVIEW.json'),('febe84f68222fd82d87c33a2bd855370e4df88f9f65f49c260986165a4b8fd74',planpin['sha256']),('Temple_actor_receipt_repair01/Temple_actor_receipt25_deployed_ROOT_ACTUAL.json','Estate_wall_source_repair01/Estate_wall_source31_deployed_ROOT_ACTUAL.json'),('0860c9038a537bec69bd0d2091d45dfbdf8c5ef52163103aadfa0c19dc814395',deppin['sha256']),('Temple_actor_receipt_repair01/current_E53E_backup25_ROOT_ACTUAL.json','Estate_wall_source_repair01/current_0860_backup31_ROOT_ACTUAL.json'),('6cbdb68683733bc819978936225476bf4bf5ff16b2efb7f01b05a7af23b9e6bf','ad48454d8798b51b1076fe1482f842373ed78cd2b96a29a7053caaa90c6a631e'),("city['target_count']==25 and len(city['JSON14_written'])==14","city['target_count']==31 and len(city['JSON14_written'])==14"),("backup['total_backups']==461","backup['total_backups']==492"),('old436_backup_facts','old461_backup_facts'),("'old436_backups'","'old461_backups'"),("'new25_backups'","'new31_backups'"),('city_backups=461','city_backups=492'),("plan['current_city_necessary_Temple_receipt25_deployment']","plan['current_city_necessary_Estate_wall_source31_deployment']"),('EXACT_ROOT_ACTUAL_STAGE08_SHA_REQUIRED','EXACT_ROOT_ACTUAL_STAGE09_SHA_REQUIRED')]:tc(a,b)
back=tool
for h in reversed(ths):back=back.replace(h['new'],h['old'])
assert back.encode()==traw;compile(tool,'transport_guard_World4_stage09_ROOT_ONLY.py','exec');toolpin=dict(path=S+'transport_guard_World4_stage09_ROOT_ONLY.py',sha256=sha(tool.encode()),bytes=len(tool.encode()))
proof=emit('World4_ninth_head_full_inverse_READONLY.json',enc(dict(status='WORLD4_ACTUAL47CC_HEAD_ONLY_NOT_STAGE_DEPLOYED',parent_plan=oldpin,original_actual_World_Stage=plan['parent_World_Stage'],city_actual31=deppin,plan=planpin,input=inputpin,driver=driver,driver_parent=dp,driver_hunks=hs,whole_driver_byte_inverse=True,plan_top_level_delta=pd,input_top_level_delta=idelta,restore_plan_key_order=list(old),restore_input_key_order=list(oldspec),whole_plan_input_typed_UTF8_inverse=True,World_expected87_value_changes=world_changes,other86_fixed_values_unchanged=True,World4_functions54media73ADbackup_unchanged=True,original_WorldScene_authority_unchanged=True,city_current36_fixed=True,city_C4map_OWNED_execution_changes=0,transport=toolpin,transport_parent=tp,transport_hunks=ths,whole_transport_byte_inverse=True,Root_actual_future_Stage09_sha_required=True,city_backups_total=492,new_backups=0,engine_calls=0,Stage_calls=0,guard_calls=0,canonical_writes=0)))
O.mkdir()
for name,b in data.items():
 with(O/name).open('xb')as f:f.write(b)
for pin,b in [(driver,text.encode()),(toolpin,tool.encode())]:
 dest=G/pin['path'][6:];assert not dest.exists()
 with dest.open('xb')as f:f.write(b)
print(json.dumps(dict(plan=planpin,input=inputpin,driver=driver,transport=toolpin,proof=proof,World87_changes=world_changes,Stage_calls=0)))
