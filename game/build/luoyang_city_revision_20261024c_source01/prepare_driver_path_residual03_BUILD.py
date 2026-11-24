"""Only nested driver GAME ancestor and input generator/output successor."""
from pathlib import Path
import hashlib,json,copy
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1];S='res://build/luoyang_city_revision_20261024c_source01/'
OUT=HERE/'driver_path_residual03';OUT.mkdir(exist_ok=False);PREFIX=S+'driver_path_residual03/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h;return b
def out(name,b):
    with (OUT/name).open('xb') as f:f.write(b)
    return dict(path=PREFIX+name,sha256=sha(b),bytes=len(b))
oldp=S+'temple_depth_residual02/stage_courts_scholar30_residual02_NOTREADY.py';oldh='bb72c2c0839f3497bf464306db4548fae8918029824b86339feb58e6b7b377b9';old=read(oldp,oldh)
a=b'GAME = Path(__file__).resolve().parents[2]';b=b'GAME = Path(__file__).resolve().parents[3]';assert old.count(a)==1
candidate=old.replace(a,b,1);assert candidate.replace(b,a,1)==old
driver=out('stage_courts_scholar30_residual03_NOTREADY.py',candidate);compile(candidate,driver['path'],'exec')
resolved=(OUT/'stage_courts_scholar30_residual03_NOTREADY.py').resolve().parents[3]/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py'
core=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py'
assert resolved==core and sha(resolved.read_bytes())=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
ip=S+'temple_depth_residual02/source_input_courts_scholar30_residual02_ROOT_REVIEW.json';ih='a6b859bc44968ee1dc53a7d49b093baf6ca981e577dbacacd277fe7fafabac57';raw=read(ip,ih);original=json.loads(raw);v=copy.deepcopy(original)
v['required_generator']={k:driver[k] for k in ['path','sha256']};v['output_root']=S+'outputs/root_courts_scholar_exact30_stage03/'
inp=out('source_input_courts_scholar30_residual03_ROOT_REVIEW.json',enc(v));back=copy.deepcopy(v);back['required_generator']=original['required_generator'];back['output_root']=original['output_root'];assert back==original and enc(back)==raw
proof=out('one_hunk_two_field_whole_inverse_BUILD.json',enc(dict(status='NESTED_DRIVER_ANCESTOR_ONLY_RESIDUAL03_NOT_RUN',parent_driver=dict(path=oldp,sha256=oldh),driver=driver,replacements=[dict(old=a.decode(),new=b.decode())],driver_wholebyte_inverse=True,CORE_resolved_absolute=str(resolved),CORE_sha256=sha(core.read_bytes()),static_CORE_resolve_exact=True,parent_input=dict(path=ip,sha256=ih),input=inp,input_changed_fields=['required_generator','output_root'],input_whole_typed_and_serialized_UTF8_inverse=True,all_other_code_execution_DAG_scope_unchanged=True,engine_calls=0,Stage_calls=0,canonical_writes=0)))
print(json.dumps(dict(driver=driver,input=inp,proof=proof,static_CORE_resolve_exact=True)))
