"""Fifth fixed city source head for separate World4 candidate. Never Stage/deploy/engine."""
from pathlib import Path
import copy,json,hashlib
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'world4_READY05/'
Y='res://build/luoyang_city_finish_20261025i_system01/world4_after_authority20_04/'
OUT=N/'world4_READY05';assert not OUT.exists();data={}
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(pin):
 raw=(G/pin['path'][6:]).read_bytes();assert sha(raw)==pin['sha256'];return raw
def load(pin):return json.loads(read(pin))
def emit(name,b):
 assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
oldpin=dict(path=Y+'v02_world4_fourth_head_candidates_ROOT_REVIEW.json',sha256='c2bdc8e4de6eeec1ec998cef90453a1be229bb298ea6a2fa9321452d5c9e7ba4');old=load(oldpin);plan=copy.deepcopy(old)
deppin=dict(path=S+'docks_gallery_family_repair01/gallery_family32_deployed_ROOT_ACTUAL.json',sha256='d58160a60473eb962836f603842ef618b357f99c09339d28eaed67091a43797c');dep=load(deppin)
stagepin=dict(path=S+'outputs/root_gallery_family_ferry_exact32_stage01/receipt.json',sha256='ce3e0857f5d13b69153fe0e1e04a79190568285a125da1d51c02f2720c745801');stage=load(stagepin)
assert dep['passed']and dep['stage']==stagepin and dep['target_count']==32 and stage['source_first']==stage['source_final']
current={r['target']:copy.deepcopy(r)for r in old['current_city33_expected']};assert len(current)==33
ROUTER='res://scripts/autoload/scene_router.gd';FIELD='res://scripts/field/field_walkable_controller.gd'
for r in dep['targets']:
 p=r['target']
 if p in current:assert current[p]['sha256']==r['old_sha256']
 else:assert p==ROUTER and r['old_sha256']==old['expected_world_visual_source_sha256'][ROUTER]=='908f2254539010557b7ebfdc1cb77f86f6a05b068d1386741268b39a9cadeb51'
 current[p]=dict(target=p,sha256=r['sha256'],bytes=r['bytes'])
assert len(current)==34
plan['current_city_previous20_deployment']=old['current_city_latest20_deployment'];del plan['current_city_latest20_deployment']
plan['current_city_latest32_deployment']=deppin;plan['current_city_Stage']=stagepin;del plan['current_city33_expected'];plan['current_city34_expected']=list(current.values())
cm=stage['nodes']['expected_ch4_s0_luoyang_gate_true']['value']['source_sha256']
for p in [FIELD,ROUTER]:assert cm[p]==current[p]['sha256'];plan['expected_world_visual_source_sha256'][p]=cm[p]
for k in ['targets','ordinary_source_sha256','protected_unchanged','Root_two_backup','unchanged_G_from_base32'] :assert plan[k]==old[k],k
changed={k:(old['expected_world_visual_source_sha256'][k],h)for k,h in plan['expected_world_visual_source_sha256'].items()if old['expected_world_visual_source_sha256'][k]!=h};assert set(changed)=={FIELD,ROUTER}
assert 'res://scripts/city/luoyang_execution_authority_20261022ap.gd'not in plan['ordinary_source_sha256']and 'res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'not in plan['expected_world_visual_source_sha256']
plan['city_B_CDE_actual_result_pending']=True;plan['source_head_note']='Fifth city head only: current CE3E/D581 gallery retirement, real ferry contract and exact Family direct Router. World4 old hooks/module/manifest/54media/73AD backup unchanged; pending actual city suffixes and explicit Root World deployment.'
planpin=emit('world4_fifth_head_candidates_ROOT_REVIEW.json',enc(plan))
driverparent=dict(path=Y+'v02_stage_World4_fourth_head_ROOT_ONLY.py',sha256='df8e27d04d39ce20bc46e92320842c5c24636a53fa89e64c9358bcdea852f0fd');driverraw=read(driverparent);text=driverraw.decode();hunks=[]
def change(a,b):
 global text
 assert text.count(a)==1,(a[:80],text.count(a));text=text.replace(a,b,1);hunks.append(dict(old=a,new=b))
change("GAME=Path(__file__).resolve().parents[3];PREFIX='"+Y+"'","GAME=Path(__file__).resolve().parents[2];PREFIX='"+P+"'")
change("city=load(spec['city_deployment'])","city=load(spec['city_previous_authority20_deployment']);latest=load(spec['city_deployment'])")
change("city['target_count']==20,'ROOT_FOUR_FIXED_DEPLOYMENT_LAYERS'","city['target_count']==20 and latest['passed']is True and latest['target_count']==32,'ROOT_FIVE_FIXED_DEPLOYMENT_LAYERS'")
change("plan['current_city_latest20_deployment']==spec['city_deployment']","plan['current_city_previous20_deployment']==spec['city_previous_authority20_deployment']and plan['current_city_latest32_deployment']==spec['city_deployment']")
before=" expected_city={r['target']:r for r in plan['current_city33_expected']};M.need(set(expected_city)==set(current)and len(current)==33,'CURRENT33_EXACT_FIXED_SCOPE')"
after=""" for r in latest['targets']:
  p=r['target']
  if p in current:M.need(current[p]['sha256']==r['old_sha256'],'EXACT_LATEST32_OLD')
  else:M.need(p=='res://scripts/autoload/scene_router.gd'and r['old_sha256']=='908f2254539010557b7ebfdc1cb77f86f6a05b068d1386741268b39a9cadeb51','ONLY_SEPARATE_ROUTER_JOINS_FIXED_CITY_SCOPE')
  current[p]=r
 expected_city={r['target']:r for r in plan['current_city34_expected']};M.need(set(expected_city)==set(current)and len(current)==34,'CURRENT34_EXACT_FIXED_SCOPE')"""
change(before,after)
back=text
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==driverraw;compile(text,'stage_World4_fifth_head_ROOT_ONLY.py','exec')
driverbytes=text.encode();driver=dict(path=S+'stage_World4_fifth_head_ROOT_ONLY.py',sha256=sha(driverbytes),bytes=len(driverbytes))
iparent=dict(path=Y+'v02_source_input_World4_fourth_head_ROOT_REVIEW.json',sha256='4c3d51b949cba0224940f94a098d33364201854e4763f9949b73a1030954c4aa');spec=load(iparent)
spec.update(driver=driver,plan=planpin,city_previous_authority20_deployment=old['current_city_latest20_deployment'],city_deployment=deppin,city_Stage=stagepin,output_root=P+'outputs/root_World_visual_exact4_stage05/')
inp=emit('source_input_World4_fifth_head_ROOT_REVIEW.json',enc(spec))
delta=[dict(key=k,existed=k in old,old=old.get(k),new=v)for k,v in plan.items()if k not in old or old[k]!=v]+[dict(key=k,existed=True,old=v,deleted=True)for k,v in old.items()if k not in plan]
r=copy.deepcopy(plan)
for c in reversed(delta):
 if c['existed']:r[c['key']]=c['old']
 else:del r[c['key']]
assert r==old;r={k:r[k]for k in old};assert enc(r)==read(oldpin)
proof=emit('World4_fifth_head_full_inverse_READONLY.json',enc(dict(status='WORLD4_FIFTH_CITY_SOURCE_HEAD_ONLY_NOT_STAGE_DEPLOYED',parent_plan=oldpin,plan=planpin,input=inp,driver=driver,driver_parent=driverparent,driver_literal_hunks=hunks,whole_driver_byte_inverse=True,plan_top_level_delta=delta,restore_original_top_level_key_order=list(old),whole_plan_typed_UTF8_inverse=True,World4_candidates54media73ADbackup_all_unchanged=True,World_source_formula_no_authority_EX=True,only_World_expected_source_value_changes=changed,current_city34_from_five_fixed_actual_layers=True,Stage_calls=0,engine_calls=0,canonical_writes=0)))
OUT.mkdir()
for name,raw in data.items():
 with(OUT/name).open('xb')as f:f.write(raw)
dp=N/'stage_World4_fifth_head_ROOT_ONLY.py';assert not dp.exists()
with dp.open('xb')as f:f.write(driverbytes)
print(json.dumps(dict(plan=planpin,driver=driver,input=inp,proof=proof,World_source_expected_count=len(plan['expected_world_visual_source_sha256']))))
