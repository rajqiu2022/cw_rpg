"""NEW scalar metadata successor: setup identity is not transition freshness."""
import copy
import difflib
import hashlib
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'portal_clone_field_timing02/'
OUT=S+'portal_clone_field_timing03/'
def path(p):
    assert p.startswith('res://') and '..' not in p
    return GAME/p[6:]
def sha(b): return hashlib.sha256(b).hexdigest()
def fixed(p,s):
    b=path(p).read_bytes(); assert sha(b)==s,('PIN_CHANGED',p); return b
def encoded(v): return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
base=json.loads(fixed(P+'handoff_CANDIDATES_NOT_DEPLOYED.json','80033a25f699dd417b3466661686103eb4fef3ac18ad0656839130e0981eb961'))
field=next(r for r in base['candidates'] if r['target'].endswith('field_walkable_controller.gd'))
parent=fixed(field['candidate']['path'],'a5bf375ead0c6717eca9ddc12d64e1d60274124d69b8c152898de7f5fb358515')
text=parent.decode(); ops=[]
def change(label,old,new):
    global text
    assert text.count(old)==1 and old!=new,(label,text.count(old))
    ops.append({'label':label,'byte_offset_before_this_change':len(text[:text.index(old)].encode()),'old':old,'new':new})
    text=text.replace(old,new,1)
old_getter='''func get_field_loading_profile() -> Dictionary:
	var result: Dictionary = _field_loading_profile.duplicate(true)
	if result.is_empty(): return result
	result["owner_current"] = _current_scene != null and result.get("scene_instance") == _current_scene.get_instance_id() and result.get("motion_revision") == _city3_motion_revision and result.get("Field_instance") == get_instance_id() and result.get("layout_instance") == (_current_scene.map_layout.get_instance_id() if _current_scene.map_layout != null else 0)
	return result
'''
new_getter='''func get_field_loading_profile() -> Dictionary:
	var result: Dictionary = _field_loading_profile.duplicate(true)
	if result.is_empty(): return result
	result["setup_identity_current"] = _current_scene != null and result.get("scene_instance") == _current_scene.get_instance_id() and result.get("motion_revision") == _city3_motion_revision and result.get("Field_instance") == get_instance_id() and result.get("layout_instance") == (_current_scene.map_layout.get_instance_id() if _current_scene.map_layout != null else 0)
	result["same_live_transition"] = false
	if result.setup_identity_current:
		var live_token: int = SceneRouter.live_field_transition_token(_current_scene.scene_id)
		result["observed_live_transition_token"] = live_token
		result["same_live_transition"] = live_token > 0 and int(result.get("transition_token", 0)) > 0 and live_token == int(result.transition_token)
	result["fresh_source_validation_credit"] = false
	return result
'''
change('separate_setup_identity_from_positive_same_live_transition',old_getter,new_getter)
change('explicit_setup_origin_not_warm_resume',
    '_field_loading_profile = {"status":"COLLECTING", "Field_instance":get_instance_id(),',
    '_field_loading_profile = {"status":"COLLECTING", "profile_origin":"FIELD_SCENE_SETUP_NOT_WARM_RESUME", "records_warm_resume":false, "completed_setup_preserved_when_live_token_zero_not_relabelled_fresh":true, "Field_instance":get_instance_id(),')
candidate=text.encode(); inverse=candidate
for row in reversed(ops):
    offset=row['byte_offset_before_this_change']; newer=row['new'].encode(); older=row['old'].encode()
    assert inverse[offset:offset+len(newer)]==newer,row['label']
    inverse=inverse[:offset]+older+inverse[offset+len(newer):]
assert inverse==parent
for row in reversed(field['operations']):
    offset=row['byte_offset_before_this_change']; newer=row['new'].encode(); older=row['old'].encode()
    assert inverse[offset:offset+len(newer)]==newer,row['label']
    inverse=inverse[:offset]+older+inverse[offset+len(newer):]
original=fixed(field['parent']['path'],'0c9db5be0536c8438b892b0065a25b1ea352762180524be13da52cef534540cb')
assert inverse==original
for token in ['await ','WorkerThreadPool.','FileAccess.','ResourceLoader.','load(','preload(']:
    assert text.count(token)==original.decode().count(token),token
assert text.count('SceneRouter.live_field_transition_token(')==original.decode().count('SceneRouter.live_field_transition_token(')+1
assert '"owner_current"' not in text
handoff=copy.deepcopy(base)
handoff['predecessor_handoff']={'path':P+'handoff_CANDIDATES_NOT_DEPLOYED.json','sha256':'80033a25f699dd417b3466661686103eb4fef3ac18ad0656839130e0981eb961','preserved':True}
f=next(r for r in handoff['candidates'] if r['target']==field['target'])
f['candidate']={'path':OUT+'Field_loading_scalar_profile_READY.gd','sha256':sha(candidate),'bytes':len(candidate)}
f['operations']=copy.deepcopy(field['operations'])+ops
f['successor03_wholebyte_inverse_to02']=True
f['successor03_operations_count']=2
handoff['Field_semantics']['getter_current_owner_label_removed']=True
handoff['Field_semantics']['profile_origin']='FIELD_SCENE_SETUP_NOT_WARM_RESUME'
handoff['Field_semantics']['setup_identity_current_does_not_claim_live_transition_freshness']=True
handoff['Field_semantics']['same_live_transition_requires_positive_saved_and_observed_equal_token']=True
handoff['Field_semantics']['completed_token_zero_or_same_Field_warm_return_keeps_original_setup_not_fresh']=True
handoff['Field_semantics']['getter_one_existing_readonly_SceneRouter_token_query_no_collector']=True
handoff['Field_semantics']['timing_never_source_validation_credit']=True
handoff['proof_boundary']='Static whole-byte inverse through03->02->01->fixed0C9 and readonly metadata review only; no parse/runtime/engine or source-author update. G7B195 unchanged. Await A2 final source authority.'
outputs={
    f['candidate']['path']:candidate,
    OUT+'Field02_to03_origin.diff':''.join(difflib.unified_diff(parent.decode().splitlines(True),text.splitlines(True),fromfile=field['candidate']['path'],tofile=f['candidate']['path'],n=5)).encode(),
    OUT+'Field_loading_scalar_profile_READY.gd.diff':''.join(difflib.unified_diff(original.decode().splitlines(True),text.splitlines(True),fromfile=field['target'],tofile=f['candidate']['path'],n=5)).encode(),
    OUT+'handoff_CANDIDATES_NOT_DEPLOYED.json':encoded(handoff),
}
assert not path(OUT).exists()
for p,b in outputs.items():
    path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as handle:handle.write(b)
print(json.dumps({'handoff':{'path':OUT+'handoff_CANDIDATES_NOT_DEPLOYED.json','sha256':sha(encoded(handoff))},'Field':f['candidate'],'G_unchanged':handoff['candidates'][0]['candidate'],'canonical_writes':0}))
