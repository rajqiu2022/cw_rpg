"""NEW build-only successor: capture spawn timing owner before any existing await."""
import copy
import difflib
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
S = 'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P = S + 'portal_clone_field_timing01/'
OUT = S + 'portal_clone_field_timing02/'
def path(p):
    assert p.startswith('res://') and '..' not in p
    return GAME / p[6:]
def sha(b): return hashlib.sha256(b).hexdigest()
def fixed(p, s):
    b=path(p).read_bytes(); assert sha(b)==s, ('PIN',p); return b
def encoded(v): return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
base=json.loads(fixed(P+'handoff_CANDIDATES_NOT_DEPLOYED.json','23cb4f1443d543364e155286a42a953a9f320950a6063e46f55a323b7b49524a'))
field=next(r for r in base['candidates'] if r['target'].endswith('field_walkable_controller.gd'))
parent=fixed(field['candidate']['path'],field['candidate']['sha256'])
text=parent.decode(); operations=[]
def change(label,old,new):
    global text
    assert text.count(old)==1 and old!=new,(label,text.count(old))
    operations.append({'label':label,'byte_offset_before_this_change':len(text[:text.index(old)].encode()),'old':old,'new':new})
    text=text.replace(old,new,1)
change('getter_layout_identity',
    'result.get("Field_instance") == get_instance_id()\n\treturn result\n',
    'result.get("Field_instance") == get_instance_id() and result.get("layout_instance") == (_current_scene.map_layout.get_instance_id() if _current_scene.map_layout != null else 0)\n\treturn result\n')
change('phase_record_layout_identity',
    'or _field_loading_profile.phases.has(label): return\n',
    'or _field_loading_profile.get("layout_instance") != (scene.map_layout.get_instance_id() if scene.map_layout != null else 0) or _field_loading_profile.phases.has(label): return\n')
change('capture_spawn_owner_before_any_existing_await',
    '\tvar loading_fade_started: Dictionary = _field_loading_profile_clock()\n',
    '\tvar loading_spawn_revision: int = _city3_motion_revision\n\tvar loading_spawn_scene: SceneScript = _current_scene\n\tvar loading_fade_started: Dictionary = _field_loading_profile_clock()\n')
for label, old in [
    ('fade_uses_captured_owner','_field_loading_profile_record("depth_fade_bootstrap", loading_fade_started, _city3_motion_revision, _current_scene)'),
    ('first_yield_uses_captured_owner','\t\t\t\t_field_loading_profile_record("object_first_batch", loading_first_batch_started, _city3_motion_revision, _current_scene, processed)'),
    ('short_batch_uses_captured_owner','\t\t_field_loading_profile_record("object_first_batch", loading_first_batch_started, _city3_motion_revision, _current_scene, processed)'),
]:
    change(label,old,old.replace('_city3_motion_revision, _current_scene','loading_spawn_revision, loading_spawn_scene'))
change('completed_status_only_for_same_setup_owner',
    '\t_field_loading_profile["status"] = "READY" if _field_loading_complete else "INCOMPLETE"\n',
    '\tif _field_loading_profile.get("motion_revision") == motion_revision and _field_loading_profile.get("scene_instance") == scene.get_instance_id():\n\t\t_field_loading_profile["status"] = "READY" if _field_loading_complete else "INCOMPLETE"\n')
candidate=text.encode(); inverse=text
for row in reversed(operations):
    assert inverse.count(row['new'])==1,row['label']
    inverse=inverse.replace(row['new'],row['old'],1)
assert inverse.encode()==parent
for row in reversed(field['operations']):
    assert inverse.count(row['new'])==1,row['label']
    inverse=inverse.replace(row['new'],row['old'],1)
original=fixed(field['parent']['path'],field['parent']['sha256'])
assert inverse.encode()==original
for token in ['await ','WorkerThreadPool.','FileAccess.','ResourceLoader.','load(','preload(']:
    assert text.count(token)==original.decode().count(token),token
new=copy.deepcopy(base)
new['predecessor_handoff']={'path':P+'handoff_CANDIDATES_NOT_DEPLOYED.json','sha256':'23cb4f1443d543364e155286a42a953a9f320950a6063e46f55a323b7b49524a','preserved':True}
f=next(r for r in new['candidates'] if r['target']==field['target'])
f['candidate']={'path':OUT+'Field_loading_scalar_profile_READY.gd','sha256':sha(candidate),'bytes':len(candidate)}
f['operations']=copy.deepcopy(field['operations'])+operations
f['complete_byte_inverse']=True
f['successor02_wholebyte_inverse_to01']=True
f['successor02_operations_count']=len(operations)
new['Field_semantics']['spawn_scene_and_revision_captured_before_original_awaits']=True
new['Field_semantics']['stale_continuation_cannot_write_new_setup_profile']=True
new['Field_semantics']['layout_instance_checked_by_record_and_getter']=True
new['proof_boundary']='Static byte inverse/call-count review only;02 explicitly fixes timing-owner capture in01 before any runtime use. No GDScript parse, runtime timing or new engine credit.'
outputs={
    OUT+'Field_loading_scalar_profile_READY.gd':candidate,
    OUT+'Field_loading_scalar_profile_READY.gd.diff':''.join(difflib.unified_diff(original.decode().splitlines(True),text.splitlines(True),fromfile=field['target'],tofile=f['candidate']['path'],n=5)).encode(),
    OUT+'Field01_to02_owner_capture.diff':''.join(difflib.unified_diff(parent.decode().splitlines(True),text.splitlines(True),fromfile=field['candidate']['path'],tofile=f['candidate']['path'],n=4)).encode(),
    OUT+'handoff_CANDIDATES_NOT_DEPLOYED.json':encoded(new),
}
assert not path(OUT).exists()
for p,b in outputs.items():
    path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as h:h.write(b)
print(json.dumps({'handoff':{'path':OUT+'handoff_CANDIDATES_NOT_DEPLOYED.json','sha256':sha(encoded(new))},'G':new['candidates'][0]['candidate'],'Field':f['candidate'],'canonical_writes':0}))
