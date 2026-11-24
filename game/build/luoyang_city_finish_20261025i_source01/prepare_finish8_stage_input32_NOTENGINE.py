from pathlib import Path
import json,hashlib,copy,importlib.util
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def load(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'];return json.loads(b)
bp=dict(path=NS+'unified32_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='be3aa94f1b6eae760888803076f80062ad4a25b3aabb349ea46e43e223099254');b=load(bp)
driverpath=NS+'stage_finish8_exact32_ROOT_ONLY.py';dh=sha((N/'stage_finish8_exact32_ROOT_ONLY.py').read_bytes())
pins=[dict(id='driver',path=driverpath,sha256=dh),dict(id='candidates',**bp),dict(id='scope',**b['scope']),dict(id='backup',**b['root_backup']),dict(id='code',**b['code_proof']),dict(id='execution',**{k:b['execution']['candidate'][k]for k in ['path','sha256']}),dict(id='authority_helper',**b['authority_helper']),dict(id='publication',**b['publication']),dict(id='trial',**{k:b['trial'][k]for k in ['path','sha256']}),dict(id='parent_stage',**b['parent_stage'])]
gates=[]
for i,gate in enumerate(b['old_required_gates']):
 ident='gate_'+str(i);pins.append(dict(id=ident,**gate['pin']));gates.append(dict(id=gate['id'],input=ident,pointer=gate['pointer'],equals=gate['equals']))
gates.append(dict(id='root_target_preauthorization',input='trial',pointer=['admitted'],equals=True));assert len(gates)==5
spec=dict(schema_version=1,status='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT',blockers=[],output_root=NS+'outputs/root_finish8_exact32_stage01/',pinned_inputs=pins,authority_input='execution',authority_helper_input='authority_helper',prospective_targets=[dict(target=r['target'],candidate_path=r['candidate']['path'],sha256=r['candidate']['sha256'])for r in b['targets']],declared_candidates={r['target']:r['candidate']for r in b['targets']},five_owned_targets=b['execution']['changed_existing_owned'],required_gates=gates,source_groups=[],nodes=[])
# Finite offline data audit, not Stage.run or collector. Validate every declared difference and patch transport.
core=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py';assert sha(core.read_bytes())=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
module_spec=importlib.util.spec_from_file_location('fixed_patch_format_only',core);M=importlib.util.module_from_spec(module_spec);module_spec.loader.exec_module(M)
targets={r['target']:r for r in b['targets']};assert len(targets)==32;patchproof={};oldcode={};newcode={}
def raw(pin):
 x=(G/pin['path'][6:]).read_bytes();assert sha(x)==pin['sha256']and len(x)==pin['bytes'];return x
for p,r in targets.items():
 old,new=raw(r['parent']),raw(r['candidate']);assert old!=new and (G/p[6:]).read_bytes()==old;oldcode[p]=old;newcode[p]=new
 if p.endswith('.gd'):_,proof=M._strict_lf_build_file_patch((G/p[6:]).resolve().as_posix(),old,new);patchproof[p]=proof
 else:json.loads(old);json.loads(new)
assert len(patchproof)==18
for p,r in b['records'].items():
 f,v=oldcode[p].decode(),newcode[p].decode()
 for h in r['hunks']:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
 for h in reversed(r['hunks']):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
 assert f.encode()==newcode[p]and v.encode()==oldcode[p]
def at(v,path):
 for k in path:v=v[k]
 return v
for p,r in b['metadata'].items():
 old,new=json.loads(oldcode[p]),json.loads(newcode[p]);oldset={};newset={};f=copy.deepcopy(old)
 for ptr in r['source_fields']:
  for key,h in at(old,ptr).items():assert key not in oldset;oldset[key]=h
  for key,h in at(new,ptr).items():assert key not in newset;newset[key]=h
  assert set(at(old,ptr))<=set(at(new,ptr))
 assert set(oldset)<=set(newset)and {key:newset[key]for key in set(newset)-set(oldset)}==r['explicit_new_ordinary']==b['source_additions_by_metadata'][r['id']]
 for c in r['changes']:
  d=at(f,c['pointer'][:-1]);key=c['pointer'][-1];assert (key in d)==c['existed']and(not c['existed']or d[key]==c['old']);d[key]=copy.deepcopy(c['new'])
 assert f==new
 for ptr in r['protected_pointers']:assert at(old,ptr)==at(new,ptr)
 for key,h in newset.items():
  if key in targets:assert h==targets[key]['candidate']['sha256'],('STALE_CURRENT_CANDIDATE',r['id'],key,h)
 for forbidden in r['forbidden_sources']:assert forbidden not in newset
 back=copy.deepcopy(new)
 for c in reversed(r['changes']):
  d=at(back,c['pointer'][:-1]);key=c['pointer'][-1]
  if c['existed']:d[key]=copy.deepcopy(c['old'])
  else:del d[key]
 assert back==old and enc(back)==oldcode[p]
for ident,r in b['maps'].items():
 old=load(r['parent']);new=load(r['candidate']);s=dict(old['source_sha256'])
 for p,t in targets.items():
  if p in s:assert s[p]==t['parent']['sha256'];s[p]=t['candidate']['sha256']
 for p,h in r['explicit_additions'].items():assert p not in s;s[p]=h
 assert s==new['source_sha256']and r['count']==len(s)
 for p,h in s.items():
  if p in targets:assert h==targets[p]['candidate']['sha256']
  elif p in b['execution']['extra']:assert h==b['execution']['extra'][p]
audit=dict(status='EXACT32_OFFLINE_FINITE_DECLARATION_AND_PATCH_AUDIT_NOT_STAGE',passed=True,count=32,partition=dict(GD=18,JSON=14),all_metadata_fields_disjoint=True,all_old_keys_classification_retained=True,all_existing_target_source_values_exact_final=True,all32_fullbytes_inverse=True,patch_format=patchproof,map_counts={k:r['count']for k,r in b['maps'].items()},Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)
ib=enc(spec);ab=enc(audit)
for name,content in [('source_input_finish8_exact32_ROOT_REVIEW.json',ib),('finite_preStage32_declaration_audit_READONLY.json',ab)]:
 p=N/name;assert not p.exists()
 with p.open('xb')as f:f.write(content)
print(json.dumps(dict(driver=dict(path=driverpath,sha256=dh),input=dict(path=NS+'source_input_finish8_exact32_ROOT_REVIEW.json',sha256=sha(ib)),audit=dict(path=NS+'finite_preStage32_declaration_audit_READONLY.json',sha256=sha(ab)),counts=audit['map_counts'])))
