"""World fourth-target package, sixth current city protection head only. Never runs Stage."""
from pathlib import Path
import json,hashlib,copy
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'world4_READY06/';OUT=N/'world4_READY06';assert not OUT.exists()
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(pin):
 raw=(G/pin['path'][6:]).read_bytes();assert sha(raw)==pin['sha256'];return raw
def load(pin):return json.loads(read(pin))
data={}
def emit(name,b):
 assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
oldpin=dict(path=S+'world4_READY05/world4_fifth_head_candidates_ROOT_REVIEW.json',sha256='a54ed65f4fe138d3e3cb9398fa7ca6581bfcf67b451a4825025148d2951271d7');old=load(oldpin);plan=copy.deepcopy(old)
dp=dict(path=S+'culture_Router_pin_repair01/culture_Router24_deployed_ROOT_ACTUAL.json',sha256='f67e767260e80ea5d1e8ce9d715e7e2dec015212f041d851559cc60add56619a');dep=load(dp)
stagepin=dict(path=S+'outputs/root_culture_Router_pin_exact24_stage01/receipt.json',sha256='6a56f22333aa7988c35567fc2d06dea025e68dbe352318b7078eeaeeed50fd47');stage=load(stagepin);assert dep['passed']and dep['stage']==stagepin and dep['target_count']==24 and stage['source_first']==stage['source_final']
current={r['target']:copy.deepcopy(r)for r in old['current_city34_expected']};assert len(current)==34
for r in dep['targets']:
 p=r['target'];assert current[p]['sha256']==r['old_sha256'];current[p]=dict(target=p,sha256=r['sha256'],bytes=r['bytes'])
plan['current_city34_expected']=list(current.values());plan['current_city_previous32_deployment']=old['current_city_latest32_deployment'];del plan['current_city_latest32_deployment'];plan['current_city_latest24_deployment']=dp;plan['current_city_Stage']=stagepin
cm=stage['nodes']['expected_ch4_s0_luoyang_gate_true']['value']['source_sha256']
for p in ['res://scripts/field/field_walkable_controller.gd','res://scripts/autoload/scene_router.gd']:assert plan['expected_world_visual_source_sha256'][p]==cm[p]
for k in ['targets','ordinary_source_sha256','expected_world_visual_source_sha256','protected_unchanged','Root_two_backup','unchanged_G_from_base32']:assert plan[k]==old[k],k
assert len(plan['expected_world_visual_source_sha256'])==87
plan['city_B_CDE_actual_result_pending']=True;plan['source_head_note']='Sixth fixed city head only. CT Router semantic pin repair changes24 current-city counters, not World87 values/keys. World4 targets,54 media,73AD backup,Field3069/RouterE983 unchanged. City actual suffixes/World activation remain pending.'
pp=emit('world4_sixth_head_candidates_ROOT_REVIEW.json',enc(plan))
parent=dict(path=S+'stage_World4_fifth_head_ROOT_ONLY.py',sha256='ec5ca700596d2991ea93acaa0f1209598d59a755c90f0dcb65878241ba090987');raw=read(parent);text=raw.decode();hunks=[]
def change(a,b):
 global text
 assert text.count(a)==1,(a[:70],text.count(a));text=text.replace(a,b,1);hunks.append(dict(old=a,new=b))
change("PREFIX='"+S+"world4_READY05/'","PREFIX='"+P+"'")
change("latest=load(spec['city_deployment'])","latest=load(spec['city_previous_gallery32_deployment']);culture=load(spec['city_deployment'])")
change("latest['target_count']==32,'ROOT_FIVE_FIXED_DEPLOYMENT_LAYERS'","latest['target_count']==32 and culture['passed']is True and culture['target_count']==24,'ROOT_SIX_FIXED_DEPLOYMENT_LAYERS'")
change("plan['current_city_latest32_deployment']==spec['city_deployment']","plan['current_city_previous32_deployment']==spec['city_previous_gallery32_deployment']and plan['current_city_latest24_deployment']==spec['city_deployment']")
marker=" expected_city={r['target']:r for r in plan['current_city34_expected']};M.need(set(expected_city)==set(current)and len(current)==34,'CURRENT34_EXACT_FIXED_SCOPE')"
change(marker,""" for r in culture['targets']:
  p=r['target'];M.need(p in current and current[p]['sha256']==r['old_sha256'],'EXACT_ONLY_EXISTING_CT24_COUNTER_OVERLAY');current[p]=r
"""+marker)
back=text
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==raw;compile(text,'stage_World4_sixth_head_ROOT_ONLY.py','exec');db=text.encode();driver=dict(path=S+'stage_World4_sixth_head_ROOT_ONLY.py',sha256=sha(db),bytes=len(db))
isrc=dict(path=S+'world4_READY05/source_input_World4_fifth_head_ROOT_REVIEW.json',sha256='7a112005e1da47d4b699eb8f58f7805c9e7a8d6da05b462679e35ea90bd1da00');spec=load(isrc);spec.update(driver=driver,plan=pp,city_previous_gallery32_deployment=old['current_city_latest32_deployment'],city_deployment=dp,city_Stage=stagepin,output_root=P+'outputs/root_World_visual_exact4_stage06/');ip=emit('source_input_World4_sixth_head_ROOT_REVIEW.json',enc(spec))
delta=[dict(key=k,existed=k in old,old=old.get(k),new=v)for k,v in plan.items()if k not in old or old[k]!=v]+[dict(key=k,existed=True,old=v,deleted=True)for k,v in old.items()if k not in plan];r=copy.deepcopy(plan)
for c in reversed(delta):
 if c['existed']:r[c['key']]=c['old']
 else:del r[c['key']]
assert r==old;r={k:r[k]for k in old};assert enc(r)==read(oldpin)
proof=emit('World4_sixth_head_full_inverse_READONLY.json',enc(dict(status='WORLD4_SIXTH_CITY_HEAD_ONLY_NOT_STAGE_DEPLOYED',parent_plan=oldpin,plan=pp,input=ip,driver=driver,driver_parent=parent,driver_literal_hunks=hunks,whole_driver_byte_inverse=True,plan_top_level_delta=delta,restore_original_top_level_key_order=list(old),whole_plan_typed_UTF8_inverse=True,all_World87_keys_values_unchanged=True,World4_targets54media73ADbackup_unchanged=True,only_fixed_city24_counters_overlay=True,Stage_calls=0,engine_calls=0,canonical_writes=0)))
OUT.mkdir()
for name,b in data.items():
 with(OUT/name).open('xb')as f:f.write(b)
dest=N/'stage_World4_sixth_head_ROOT_ONLY.py';assert not dest.exists()
with dest.open('xb')as f:f.write(db)
print(json.dumps(dict(plan=pp,input=ip,driver=driver,proof=proof)))
