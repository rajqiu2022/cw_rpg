"""ROOT-authorized mechanical READY freeze only; never launches any process."""
from pathlib import Path
import copy,difflib,hashlib,json
Q=Path(__file__).resolve().parent
GAME=Q.parent.parent
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def r(p): return 'res://'+p.relative_to(GAME).as_posix()
def emit(p,v):
    assert not p.exists(),str(p)
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_bytes((json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
    return sha(p)
old=Q/'mainhall_ActorLayer_fixed_viewport_suffix_retry1_NOTREADY'
new=Q/'mainhall_ActorLayer_fixed_viewport_suffix_READY'
okey=old/'test_NOTREADY.gd';ofx=old/'fixture_NOTREADY.json'
assert sha(okey)=='b7568c30462a616943daab8d069b765e36b2d58548482e2595e189a5817078fe'
assert sha(ofx)=='a1869938acffec2fb7111523db5ff044dc6c7ccc09deb950cb96ca76a5efb2e6'
base=GAME/'build/luoyang_hall_portal_fix_20261024a_root01/parent02'
docs={
 'deployment_plan':(base/'deployment_plan.json','766e0946a3ee8bd5efae532f931459674d5876899630483069bfd1a4f727af3b'),
 'deployment_actual':(base/'deployment_actual.json','e6dc8c571b03e79b4f8845904848bde139950f7bb20d6d2c73f2f62477520d7e'),
 'current_guard':(base/'current_before_suffix.json','5af8a68d7f63954d94c536b816fda830995d1461199d8d460ebced9dc763ce89')}
for path,expected in docs.values(): assert sha(path)==expected
actual=json.loads(docs['deployment_actual'][0].read_bytes())
guard=json.loads(docs['current_guard'][0].read_bytes())
assert len(actual['targets'])==22 and actual['GD_apply_patch']==9 and actual['JSON_exact_copy']==13
assert actual['stage_receipt_sha256']=='8057916a71eaf433393593abad59b02bcdcec212ed213710231289e64b275392'
assert guard['checked']==2120 and guard['save_count']==15 and guard['save_changes']==0 and guard['runtime_changes']==0
original=json.loads(ofx.read_bytes());fx=copy.deepcopy(original)
assert fx['source_sha256']['res://scripts/city/luoyang_assembled_interiors_20261016g.gd']=='1078ce7fd48ee9cdae91fd56fedfa20ff26cc80f5c3273d8ff3b0b479dd128e6'
assert sha(GAME/'scripts/city/luoyang_assembled_interiors_20261016g.gd')==fx['source_sha256']['res://scripts/city/luoyang_assembled_interiors_20261016g.gd']
helper='res://build/luoyang_hall_portal_fix_20261024a_system01/parent_successor02/mainhall_fixed_columns_ActorLayer_CANDIDATE.gd'
assert sha(GAME/helper[6:])==fx['source_sha256'][helper]=='a5b024dc49a339ce56df0b236e60e009e442dc4c7453defe12989aa1e20f5ac0'
fx.update(ready=True,status='FORMAL_ACTORLAYER22_FIXED_VIEWPORT_REMAINING_SUFFIX_READY_NOT_RUN',blockers=[])
fx['formal_ActorLayer_successor']={k:{'path':r(path),'sha256':expected} for k,(path,expected) in docs.items()}
fx['formal_ActorLayer_successor']['large_stage_receipt_not_rehashed_in_runtime']=True
for path,expected in docs.values():
    assert r(path) not in fx['source_sha256']
    fx['source_sha256'][r(path)]=expected
restored=copy.deepcopy(fx)
for key in ['ready','status','blockers','formal_ActorLayer_successor']: restored[key]=original[key]
for path,_ in docs.values(): restored['source_sha256'].pop(r(path))
assert restored==original
assert json.dumps(restored,ensure_ascii=False,indent=2)==json.dumps(original,ensure_ascii=False,indent=2)
fxpath=new/'fixture_READY.json';fxsha=emit(fxpath,fx)
source=okey.read_bytes()
ops=[(b'const SUFFIX_READY=false',b'const SUFFIX_READY=true'),(r(ofx).encode(),r(fxpath).encode()),(sha(ofx).encode(),fxsha.encode()),(r(old/'output_NOTREADY').encode(),r(new/'output_READY').encode())]
for before,after in ops:
    assert source.count(before)==1
    source=source.replace(before,after,1)
inverse=source
for before,after in reversed(ops):
    assert inverse.count(after)==1
    inverse=inverse.replace(after,before,1)
assert inverse==okey.read_bytes()
key=new/'test_READY.gd';assert not key.exists();key.write_bytes(source)
assert source.endswith(b'\n')==okey.read_bytes().endswith(b'\n')
for name,left,right in [('key_complete_freeze.diff',okey.read_text(),source.decode()),('fixture_complete_freeze.diff',ofx.read_text(),fxpath.read_text())]:
    p=new/name;assert not p.exists();p.write_bytes(''.join(difflib.unified_diff(left.splitlines(True),right.splitlines(True),fromfile=r(okey if name.startswith('key') else ofx),tofile=r(key if name.startswith('key') else fxpath))).encode())
launcher=GAME/'build/luoyang_city_full_rollout_20261022ap_root01/run_frozen_godot_once.ps1'
assert sha(launcher)=='85c5ed4594ad71a89c598a4d5b02f2a6e8a1bc652d66de6056038e6dd92380da'
command="& '"+launcher.as_posix()+"' -ScriptResPath '"+r(key)+"' -ScriptSHA '"+sha(key)+"' -LogStem '"+(new/'suffix_once').as_posix()+"'"
receipt={'status':'ROOT_FORMAL_PARENT22_MECHANICAL_READY_NOT_RUN','key':{'path':r(key),'sha256':sha(key),'bytes':key.stat().st_size},'fixture':{'path':r(fxpath),'sha256':fxsha,'source_guard_count':len(fx['source_sha256'])},'hardfalse_original_preserved':{'key_sha256':sha(okey),'fixture_sha256':sha(ofx)},'key_exact4literal_wholebyte_inverse_including_EOF':True,'fixture_exact_readiness_formal3doc_assignment_plus3guards_ordered_inverse':True,'formal_source':{'G':'1078ce7fd48ee9cdae91fd56fedfa20ff26cc80f5c3273d8ff3b0b479dd128e6','helper':'a5b024dc49a339ce56df0b236e60e009e442dc4c7453defe12989aa1e20f5ac0','stage':actual['stage_receipt_sha256'],'deployment':docs['deployment_actual'][1],'guard':docs['current_guard'][1],'guard_count':2120,'save15_changes':0},'scope':'One room public directsetup, one Root-authorized637.5,525 inspection Player pose, original fixed viewport onePNG, remaining trueINPUT637.5->812.5->450. Full actual debug/reasons/depth; exact ActorLayer and natural snapshot/preview validity, no forced hit/refresh. No Yamen/arrow/firstleg/compile/format/base/collector replay.60swhole20sentry.','no_default_or_same_journey_or_wholecity_credit':True,'engine_parse_by_QA':0,'production_writes':0,'ROOT_only_command':command}
print('key',sha(key),'fixture',fxsha)
print('handoff',emit(new/'handoff_READY_NOT_RUN.json',receipt))
print(command)
