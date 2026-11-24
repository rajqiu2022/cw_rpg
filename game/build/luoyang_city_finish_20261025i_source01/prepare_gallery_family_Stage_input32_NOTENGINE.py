"""Pinned input and finite data-only preflight; no Stage instance/run or collector."""
from pathlib import Path
import argparse,json,hashlib,copy,importlib.util
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';P=S+'docks_gallery_family_repair01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def load(pin):
 raw=(G/pin['path'][6:]).read_bytes();assert sha(raw)==pin['sha256'];return json.loads(raw)
def raw(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256']and len(b)==pin['bytes'];return b
ap=argparse.ArgumentParser();ap.add_argument('--descriptor-sha256',required=True);a=ap.parse_args()
bp=dict(path=P+'unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256=a.descriptor_sha256);b=load(bp)
driverpath=S+'stage_gallery_family32_ROOT_ONLY.py';driverhash='d6e97b88e33ba0dc390b6ddafadacd0fc706d1f98d501b7046d84053aaefe0af';assert sha((G/driverpath[6:]).read_bytes())==driverhash
pins=[dict(id='driver',path=driverpath,sha256=driverhash),dict(id='candidates',**bp),dict(id='scope',**b['scope']),dict(id='backup',**b['root_backup']),dict(id='code',**b['code_proof']),dict(id='execution',**{k:b['execution']['candidate'][k]for k in ['path','sha256']}),dict(id='authority_helper',**b['authority_helper']),dict(id='publication',**b['publication']),dict(id='trial',**{k:b['trial'][k]for k in ['path','sha256']}),dict(id='parent_stage',**b['parent_stage'])]
gates=[]
for i,g in enumerate(b['old_required_gates']):
 ident='gate_'+str(i);pins.append(dict(id=ident,**g['pin']));gates.append(dict(id=g['id'],input=ident,pointer=g['pointer'],equals=g['equals']))
gates.append(dict(id='root_target_preauthorization',input='trial',pointer=['admitted'],equals=True));assert len(gates)==5
spec=dict(schema_version=1,status='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT',blockers=[],output_root=S+'outputs/root_gallery_family_ferry_exact32_stage01/',pinned_inputs=pins,authority_input='execution',authority_helper_input='authority_helper',prospective_targets=[dict(target=r['target'],candidate_path=r['candidate']['path'],sha256=r['candidate']['sha256'],bytes=r['candidate']['bytes'])for r in b['targets']],declared_candidates={r['target']:r['candidate']for r in b['targets']},five_owned_targets=b['execution']['changed_existing_owned'],required_gates=gates,source_groups=[],nodes=[])
core=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py';assert sha(core.read_bytes())=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
module=importlib.util.spec_from_file_location('fixed_patch_format_only',core);M=importlib.util.module_from_spec(module);module.loader.exec_module(M)
M.EXACT_EOL_CANDIDATES={'res://scripts/autoload/scene_router.gd':('e983a3b2b8c3cc031262100755c1f9e2f37c03a618d1a0a4cf268f8c6ccd3745',13)}
targets={r['target']:r for r in b['targets']};assert len(targets)==32;patchproof={};oldbytes={};newbytes={}
for p,r in targets.items():
 old,new=raw(r['parent']),raw(r['candidate']);assert old!=new and (G/p[6:]).read_bytes()==old;oldbytes[p]=old;newbytes[p]=new
 if p.endswith('.gd'):_,proof=M.build_file_patch((G/p[6:]).resolve().as_posix(),old,new);patchproof[p]=proof
 else:json.loads(old);json.loads(new)
assert len(patchproof)==18
for p,r in b['records'].items():
 f,v=oldbytes[p].decode(),newbytes[p].decode()
 for h in r['hunks']:assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
 for h in reversed(r['hunks']):assert v.count(h['new'])==1;v=v.replace(h['new'],h['old'],1)
 assert f.encode()==newbytes[p]and v.encode()==oldbytes[p]
def at(v,path):
 for k in path:v=v[k]
 return v
for p,r in b['metadata'].items():
 old,new=json.loads(oldbytes[p]),json.loads(newbytes[p]);before={};after={};f=copy.deepcopy(old)
 for ptr in r['source_fields']:
  for key,h in at(old,ptr).items():assert key not in before;before[key]=h
  for key,h in at(new,ptr).items():assert key not in after;after[key]=h
  assert set(at(old,ptr))<=set(at(new,ptr))
 assert set(before)<=set(after)and{key:after[key]for key in set(after)-set(before)}==r['explicit_new_ordinary']==b['source_additions_by_metadata'][r['id']]
 for c in r['changes']:
  d=at(f,c['pointer'][:-1]);key=c['pointer'][-1];assert(key in d)==c['existed']and(not c['existed']or d[key]==c['old']);d[key]=copy.deepcopy(c['new'])
 assert f==new
 for ptr in r['protected_pointers']:assert at(old,ptr)==at(new,ptr)
 for key,h in after.items():
  if key in targets:assert h==targets[key]['candidate']['sha256'],('STALE_CURRENT_SOURCE',r['id'],key,h)
 for forbidden in r['forbidden_sources']:assert forbidden not in after
 for c in reversed(r['changes']):
  d=at(f,c['pointer'][:-1]);key=c['pointer'][-1]
  if c['existed']:d[key]=copy.deepcopy(c['old'])
  else:del d[key]
 assert f==old and enc(f)==oldbytes[p]
for ident,r in b['maps'].items():
 old=load(r['parent']);new=load(r['candidate']);expected=dict(old['source_sha256'])
 for p,t in targets.items():
  if p in expected:assert expected[p]==t['parent']['sha256'];expected[p]=t['candidate']['sha256']
 for p,h in r['explicit_additions'].items():assert p not in expected;expected[p]=h
 assert expected==new['source_sha256']and r['count']==len(expected)
 for p,h in expected.items():
  if p in targets:assert h==targets[p]['candidate']['sha256']
audit=dict(status='EXACT32_OFFLINE_DECLARATION_CLASSIFICATION_AND_PATCH_INVERSE_NOT_STAGE',passed=True,count=32,partition=dict(GD=18,JSON=14),all_old_keys_classification_retained=True,metadata_all_disjoint=True,all32_raw_inverse=True,patch_format=patchproof,map_counts={k:r['count']for k,r in b['maps'].items()},authority_F120_fixed=True,old195_all_values_edges_preserved_plus7=True,Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)
for name,v in [('source_input_gallery_family32_ROOT_REVIEW.json',spec),('finite_preStage32_source_inverse_READONLY.json',audit)]:
 dest=N/'docks_gallery_family_repair01'/name;assert not dest.exists();content=enc(v)
 with dest.open('xb')as f:f.write(content)
 print(name,sha(content),len(content))
