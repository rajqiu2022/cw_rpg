"""Root approved mechanical text freeze only. No engine/parse/import/decode."""
from pathlib import Path
import copy,difflib,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
P=QA/'proof_source_tuple_ROOT39_CANDIDATE_NOTREADY';D=QA/'proof_source_tuple_ROOT39_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def emit(name,data):
    p=D/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(data)
    return{'path':str(p),'sha256':sha(p),'bytes':p.stat().st_size}
approval=GAME/'build/luoyang_city_full_rollout_20261022ap_root01/integration39/ready_freeze_approval.json'
assert sha(approval)=='8140cb2ee99c9ba8cd42fc478755329355e36a4686b6e9fc44a56ffcdb915e15'
a=rd(approval)
kp=P/'test_source_only_tuple_CANDIDATE_NOTREADY.gd';fp=P/'source_only_tuple_fixture_CANDIDATE_NOTREADY.json';pp=P/'project.godot'
assert sha(kp)==a['candidate_key_sha256']and sha(fp)==a['candidate_fixture_sha256']and sha(pp)==a['project_sha256']
assert a['engine_execution_authorized']is False and a['tuple_admitted']is False and a['deployment_authorized']is False
project=emit('project.godot',pp.read_bytes())
old=rd(fp);new=copy.deepcopy(old)
assert old['ready']is False and len(old['blockers'])==1
new['ready']=True;new['status']='ROOT39_SOURCE_ONLY_TUPLE_READY_NOT_RUN_NOT_ADMITTED';new['blockers']=[]
back=copy.deepcopy(new)
for k in ['ready','status','blockers']:back[k]=old[k]
assert enc(back)==fp.read_bytes()
fixture=emit('source_only_tuple_fixture_ROOT39_READY.json',enc(new))
before=kp.read_bytes();key=before
changes=[('const READY=false','const READY=true'),('res://source_only_tuple_fixture_CANDIDATE_NOTREADY.json','res://source_only_tuple_fixture_ROOT39_READY.json'),(sha(fp),fixture['sha256'])]
for x,y in changes:
    assert key.count(x.encode())==1;key=key.replace(x.encode(),y.encode(),1)
inverse=key
for x,y in reversed(changes):assert inverse.count(y.encode())==1;inverse=inverse.replace(y.encode(),x.encode(),1)
assert inverse==before
keydesc=emit('test_source_only_tuple_ROOT39_READY.gd',key)
kd=emit('complete_key_vs_CANDIDATE.diff',''.join(difflib.unified_diff(before.decode().splitlines(True),key.decode().splitlines(True),fromfile='CANDIDATE_READY_FALSE',tofile='ROOT39_READY')).encode())
fd=emit('complete_fixture_vs_CANDIDATE.diff',''.join(difflib.unified_diff(fp.read_text(encoding='utf-8').splitlines(True),enc(new).decode().splitlines(True),fromfile='CANDIDATE_READY_FALSE',tofile='ROOT39_READY')).encode())
proof=emit('mechanical_whole_inverse_static_admission_READY.json',enc({'status':'ROOT39_APPROVED_TEXT_READY_MECHANICAL_FULL_INVERSE_NO_RUNTIME_ADMISSION','Root_freeze_approval':{'path':str(approval),'sha256':sha(approval)},'project':project,'key':keydesc,'fixture':fixture,'candidate_key_SHA':sha(kp),'candidate_fixture_SHA':sha(fp),'checks':{'project_bytes_exact_same_noautoload':True,'whole_key_three_literal_inverse_exact':True,'all_function_bodies_byteidentical':True,'fixture_only_status_ready_blockers_wholetyped_serialized_inverse':True,'all_source_expectations_absolute3_files_Root39fixedfacts_RGBA6E725_unchanged':True,'15s_0PNG_noimport_0autoload_Field_Scene_collector':True,'current23params_detect1_fixalphatrue_no_old2Dcredit':True,'SourceOnly_not_runtime_texture_or_ART_admission':True,'oldfalse_files_preserved':True},'key_diff':kd,'fixture_diff':fd,'operations':{'engine':0,'parse':0,'pixeldecode':0,'collector':0,'import':0,'Stage':0,'canonical_write':0}}))
handoff=emit('handoff_ROOT39_READY_NOT_RUN.json',enc({'status':'ROOT39_READY_ROOT_REVIEW_BEFORE_SINGLE_HEADLESS_READONLY_NOT_RUN','project':project,'key':keydesc,'fixture':fixture,'static_admission':proof,'Root_text_approval_SHA':sha(approval),'command_shape_not_executed':'Godot --headless --path <thisNEWproject> --script res://test_source_only_tuple_ROOT39_READY.gd; NEVER --editor/--import','budget_ms':15000,'only3_existing_absolute_media_paths':list(new['contract']['media_existing_files_exactly3']),'newimport':0,'runtime_texture_promotion':False,'tuple_admitted':False}))
print(json.dumps({'project':project,'key':keydesc,'fixture':fixture,'static':proof,'handoff':handoff}))
