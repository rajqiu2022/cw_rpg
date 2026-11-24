"""One NEW NOTREADY observer predicate successor; preserves original draft."""
from pathlib import Path
import hashlib,json,difflib,copy
Q=Path(__file__).resolve().parent
GAME=Q.parent.parent
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def r(p): return 'res://'+p.relative_to(GAME).as_posix()
def emit(p,v):
    assert not p.exists()
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_bytes((json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode())
    return sha(p)
old=Q/'mainhall_ActorLayer_fixed_viewport_suffix_NOTREADY'
new=Q/'mainhall_ActorLayer_fixed_viewport_suffix_retry1_NOTREADY'
oldkey=old/'test_NOTREADY.gd';oldfx=old/'fixture_NOTREADY.json'
assert sha(oldkey)=='8a3306fd70105aec73a9c649b84e020750fbf46a74c25dd374af433cda617abf'
assert sha(oldfx)=='e19d761cb95706c0bf50c78e0ca61d61c146f3101c854e3a06d672fa24f9d7da'
fx=json.loads(oldfx.read_bytes())
fx['source_sha256'][r(oldkey)]=sha(oldkey)
fx['scope']+=' Natural snapshot and existing READY_ENCLOSURE_RUNTIME plus no invalid debug reason are mandatory; zero pixel count alone is not success evidence.'
fxsha=emit(new/'fixture_NOTREADY.json',fx)
source=oldkey.read_bytes()
ops=[
 (r(oldfx).encode(),r(new/'fixture_NOTREADY.json').encode()),
 (sha(oldfx).encode(),fxsha.encode()),
 (r(old/'output_NOTREADY').encode(),r(new/'output_NOTREADY').encode()),
 (b'\tvar native_snapshot_valid: bool=fade!=null and fade.get("_native_snapshot_valid")==true\n',b'\tvar native_snapshot_valid: bool=fade!=null and fade.get("_native_snapshot_valid")==true\n\tvar preview_valid: bool=not debug.has("fade_preview_invalid") and debug.get("invalid_depth_snapshot",false)!=true and debug.get("invalid_actor_frame",false)!=true and fade_state.get("status")=="READY_ENCLOSURE_RUNTIME" and fade_state.get("production_hooked")==true\n'),
 (b'"native_snapshot_valid":native_snapshot_valid,"columns":rows',b'"native_snapshot_valid":native_snapshot_valid,"preview_valid":preview_valid,"columns":rows'),
 (b'good and native_snapshot_valid and actor_rows==1,',b'good and native_snapshot_valid and preview_valid and actor_rows==1,')]
for a,b in ops:
    assert source.count(a)==1,(a,source.count(a))
    source=source.replace(a,b,1)
restored=source
for a,b in reversed(ops):
    assert restored.count(b)==1
    restored=restored.replace(b,a,1)
assert restored==oldkey.read_bytes()
new.mkdir(parents=True,exist_ok=True)
key=new/'test_NOTREADY.gd';assert not key.exists();key.write_bytes(source)
diff=''.join(difflib.unified_diff(oldkey.read_text().splitlines(True),source.decode().splitlines(True),fromfile=r(oldkey),tofile=r(key)))
dp=new/'complete_vs_initial_NOTREADY.diff';dp.write_bytes(diff.encode())
proof={'status':'NOTREADY_OBSERVER_VALIDITY_SMALL_SUCCESSOR','key':{'path':r(key),'sha256':sha(key)},'fixture':{'path':r(new/'fixture_NOTREADY.json'),'sha256':fxsha},'old_key_preserved':sha(oldkey),'old_fixture_preserved':sha(oldfx),'exact6_replacements_wholebyte_inverse':True,'functional_delta':'One readonly preview_valid scalar requiring existing READY_ENCLOSURE_RUNTIME/production_hooked and no invalid debug reason; reported and included in existing complete natural snapshot check. No new refresh/frame/yield/production method or pixel assertion. Other3 replacements are new path/SHA/output.','fixture_delta':'Only adds old draft guard and explicit strict diagnostic validity scope, all remaining path/pose/time/source expectations unchanged.','complete_diff_sha256':sha(dp),'READY':False,'engine_or_parse':0}
print('key',sha(key),'fixture',fxsha,'proof',emit(new/'wholebyte_inverse_NOTREADY.json',proof))
