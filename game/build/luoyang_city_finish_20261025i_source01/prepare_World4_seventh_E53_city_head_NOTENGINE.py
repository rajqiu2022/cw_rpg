"""Existing World4 functions unchanged; fixed E53 city protection/source head only."""
from pathlib import Path
import copy,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/'
P=S+'world4_READY07/';OUT=N/'world4_READY07';assert not OUT.exists()
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def read(pin):
    b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return b
def load(pin):return json.loads(read(pin))
data={}
def emit(name,b):
    assert name not in data;data[name]=b
    return dict(path=P+name,sha256=sha(b),bytes=len(b))
oldpin=dict(path=S+'world4_READY06/world4_sixth_head_candidates_ROOT_REVIEW.json',sha256='38ec41f0fee422092c03d5ba722c05c5a92be63d2a1fc57abc9ef5ce3f768289')
old=load(oldpin);plan=copy.deepcopy(old)
overlays=[
    dict(path=S+'family_visual_material_loading_repair01/visual_material_loading31_deployed_ROOT_ACTUAL.json',sha256='377b507b76264258335df71331208bed0d54182105d7713aa6229f1b20c4c2f1'),
    dict(path=S+'temple_signed_iid_repair01/signed_Temple31_deployed_ROOT_ACTUAL.json',sha256='53b5956a004e62a2d91eeab685cc02c5d26dad896801e86e148349327ad72612'),
    dict(path=S+'visible_doors_boundaries33_repair01/visible_doors_boundaries33_deployed_ROOT_ACTUAL.json',sha256='e53e6d557a60dc93e00120ed9541938cb51e54c5effd01383a086866ec8db6b2'),
]
current={r['target']:copy.deepcopy(r)for r in old['current_city34_expected']}
need_new={
    'res://data/maps/luoyang_full_city_20261022ap/environment.json':'64a7efc81a2d37c588c4d63b302324ff9b2eb90cea932de543e85177e8a4afd2',
}
scopepin=dict(path=S+'visible_doors_boundaries33_repair01/closure_READY01/current_signed31_exact33_scope_PREPARATION.json',sha256='0bf33b2c8c103d44a1db7e7056bb56b049a0327f0c9d62087848172c97397efa')
scope=load(scopepin)
index='res://scripts/city/luoyang_environment_index_20261022ap.gd'
need_new[index]=next(r['old_sha256']for r in scope['targets']if r['target']==index)
applied=[]
for pin,count in zip(overlays,[31,31,33]):
    dep=load(pin);assert dep['passed'] and dep['target_count']==count
    for r in dep['targets']:
        p=r['target']
        if p in current:assert current[p]['sha256']==r['old_sha256'],('DECLARED_OLD_OVERLAY',p)
        else:assert need_new.get(p)==r['old_sha256'],('ONLY_EXISTING_ENV_TWO_NEW_PROTECTION_KEYS',p)
        current[p]=dict(target=p,sha256=r['sha256'],bytes=r['bytes'])
    applied.append(dep)
assert len(current)==36 and set(current)-{r['target']for r in old['current_city34_expected']}==set(need_new)
newest=applied[-1]
plan['current_city36_expected']=list(current.values());del plan['current_city34_expected']
plan['current_city_protection_overlays']=overlays
plan['current_city_new_protection_old_sha256']=need_new
plan['current_city_latest33_deployment']=overlays[-1]
plan['current_city_Stage']=newest['stage']
FIELD='res://scripts/field/field_walkable_controller.gd'
field=next(r for r in newest['targets']if r['target']==FIELD)
assert old['expected_world_visual_source_sha256'][FIELD]=='306941a8f477e4ae0ea9926cb799808cc7fb41abcde213226838067475f12f98'
assert field['sha256']=='864bb14b896f4a1654d0d125478a4e2906bdd15d44e7f36092fe3cd3cdae123f'
plan['expected_world_visual_source_sha256'][FIELD]=field['sha256']
changed_world_values={p:dict(old=h,new=plan['expected_world_visual_source_sha256'][p])for p,h in old['expected_world_visual_source_sha256'].items()if plan['expected_world_visual_source_sha256'][p]!=h}
assert set(changed_world_values)=={FIELD} and len(plan['expected_world_visual_source_sha256'])==87
for key in ['targets','ordinary_source_sha256','protected_unchanged','Root_two_backup','unchanged_G_from_base32']:
    assert plan[key]==old[key],key
plan['source_head_note']='Seventh city protection head: exact F67E->377B31->signed31->E53E33 declared overlays. Existing World4 functions/media54/73AD backup/source/layout/stream/farmland/64walks unchanged. World87 changes only the fixed Field SHA; Router E983 remains unchanged. Guard domain34->36 adds only the two already-deployed ENV author/index targets. This is preparation, not World Stage/deployment/actual or city pass.'
planpin=emit('world4_seventh_head_candidates_ROOT_REVIEW.json',enc(plan))
driver_parent=dict(path=S+'stage_World4_sixth_head_ROOT_ONLY.py',sha256='d360f6df7aea8c8692dc3f9e00e065a15c60829d12aa6c62379f70204e6f5de4')
before=read(driver_parent);text=before.decode();hunks=[]
def change(a,b):
    global text
    assert text.count(a)==1,(a[:100],text.count(a));text=text.replace(a,b,1);hunks.append(dict(old=a,new=b))
change("PREFIX='"+S+"world4_READY06/'","PREFIX='"+P+"'")
change("culture=load(spec['city_deployment'])","culture=load(spec['city_previous_culture24_deployment']);overlays=[load(pin)for pin in spec['city_protection_overlays']]")
change("culture['target_count']==24,'ROOT_SIX_FIXED_DEPLOYMENT_LAYERS'","culture['target_count']==24 and [row['target_count']for row in overlays]==[31,31,33]and all(row['passed']is True for row in overlays),'ROOT_SIX_OLD_PLUS_THREE_EXACT_OVERLAYS'")
change("plan['current_city_latest24_deployment']==spec['city_deployment']","plan['current_city_latest24_deployment']==spec['city_previous_culture24_deployment']and plan['current_city_protection_overlays']==spec['city_protection_overlays']and plan['current_city_latest33_deployment']==spec['city_deployment']and spec['city_deployment']==spec['city_protection_overlays'][-1]")
marker=" expected_city={r['target']:r for r in plan['current_city34_expected']};M.need(set(expected_city)==set(current)and len(current)==34,'CURRENT34_EXACT_FIXED_SCOPE')"
replacement=""" M.need(set(plan['current_city_new_protection_old_sha256'])=={'res://data/maps/luoyang_full_city_20261022ap/environment.json','res://scripts/city/luoyang_environment_index_20261022ap.gd'},'ONLY_TWO_EXISTING_ENV_PROTECTION_TARGETS')
 for overlay in overlays:
  for r in overlay['targets']:
   p=r['target']
   if p in current:M.need(current[p]['sha256']==r['old_sha256'],'EXACT_POST_F67E_CURRENT_PARENT_OVERLAY')
   else:M.need(plan['current_city_new_protection_old_sha256'].get(p)==r['old_sha256'],'EXACT_TWO_EXISTING_ENV_OLD_SHA')
   current[p]=r
 expected_city={r['target']:r for r in plan['current_city36_expected']};M.need(set(expected_city)==set(current)and len(current)==36,'CURRENT36_EXACT_FIXED_SCOPE')"""
change(marker,replacement)
back=text
for h in reversed(hunks):assert back.count(h['new'])==1;back=back.replace(h['new'],h['old'],1)
assert back.encode()==before
compile(text,'stage_World4_seventh_head_ROOT_ONLY.py','exec')
driver=dict(path=S+'stage_World4_seventh_head_ROOT_ONLY.py',sha256=sha(text.encode()),bytes=len(text.encode()))
oldinput=dict(path=S+'world4_READY06/source_input_World4_sixth_head_ROOT_REVIEW.json',sha256='7355d2004bf09a40ea64583af6d4906070d94397dce3a35650fc7afd50365aaf')
spec=load(oldinput);oldspec=copy.deepcopy(spec)
spec.update(driver=driver,plan=planpin,city_previous_culture24_deployment=oldspec['city_deployment'],city_deployment=overlays[-1],city_protection_overlays=overlays,city_Stage=newest['stage'],output_root=P+'outputs/root_World_visual_exact4_stage07/')
inputpin=emit('source_input_World4_seventh_head_ROOT_REVIEW.json',enc(spec))
def delta(a,b):return [dict(key=k,existed=k in a,old=a.get(k),new=v)for k,v in b.items()if k not in a or a[k]!=v]+[dict(key=k,existed=True,old=v,deleted=True)for k,v in a.items()if k not in b]
def reverse(a,b,changes):
    result=copy.deepcopy(b)
    for r in reversed(changes):
        if r['existed']:result[r['key']]=r['old']
        else:del result[r['key']]
    assert result==a
    result={k:result[k]for k in a};assert enc(result)==enc(a)
plan_delta=delta(old,plan);reverse(old,plan,plan_delta)
input_delta=delta(oldspec,spec);reverse(oldspec,spec,input_delta)
proof=emit('World4_seventh_head_full_inverse_READONLY.json',enc(dict(status='WORLD4_SEVENTH_E53_HEAD_ONLY_NOT_STAGE_DEPLOYED',parent_plan=oldpin,plan=planpin,input=inputpin,driver=driver,driver_parent=driver_parent,driver_literal_hunks=hunks,whole_driver_byte_inverse=True,plan_top_level_delta=plan_delta,input_top_level_delta=input_delta,restore_original_plan_key_order=list(old),restore_original_input_key_order=list(oldspec),whole_plan_input_typed_UTF8_inverse=True,World_expected87_value_changes=changed_world_values,World4_target_scope_unchanged=plan['targets'],World4_targets54media73ADbackup_unchanged=True,old_world_source_layout_stream_farmland64walks_unchanged=True,no_new_media_or_import=True,current_city_guard_domain=36,current_city_actual_overlays=overlays,city_C4_maps_not_changed=True,city_OWNED_execution_changes=0,Stage_calls=0,engine_calls=0,canonical_writes=0)))
OUT.mkdir()
for name,b in data.items():
    with(OUT/name).open('xb')as stream:stream.write(b)
dest=N/'stage_World4_seventh_head_ROOT_ONLY.py';assert not dest.exists()
with dest.open('xb')as stream:stream.write(text.encode())
print(json.dumps(dict(plan=planpin,input=inputpin,driver=driver,proof=proof,World_expected87_value_changes=changed_world_values,World_targets=4,current_city_protection=36,Stage_calls=0)))
