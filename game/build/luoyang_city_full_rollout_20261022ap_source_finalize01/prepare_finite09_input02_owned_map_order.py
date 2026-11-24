"""Preserve actual498F failure; remove redundant map-owned writes only.

Proof follows the real M.map order: promote_owned(raw AO), explicit nonowned
operations, unchanged source groups. No Stage invocation or current collector.
"""
import copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,s):
 b=(G/p[6:]).read_bytes();assert sha(b)==s;return json.loads(b)
def emit(name,b):
 p=H/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
 if not isinstance(b,bytes):b=(json.dumps(b,ensure_ascii=False,indent=2)+'\n').encode()
 with p.open('xb') as f:f.write(b)
 return {'path':S+name,'sha256':sha(b)}
def same(a,b):
 if type(a) is not type(b):return False
 if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
 if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
 return a==b
parentpath=S+'finite09_input01_ROOT_LOCKED.json';parentsha='498fc80eeedb9e443631b3e01d196491acacda5101eadc15fe0b9f5cd22d21cb'
plan=read(parentpath,parentsha);before=copy.deepcopy(plan);pins={r['id']:r for r in plan['pinned_inputs']}
a=pins[plan['authority_input']];authority=read(a['path'],a['sha256']);assert a['sha256']=='c668a0be6bc051237857dc4d2822308077a808a800f51a27f04f8b75c75f8405'
def current(p):return authority['owned'][p]['current_sha256']
def approved(p,old):
 frontier=[current(p)];seen=set()
 for _ in range(16):
  nxt=[]
  for s in frontier:
   if s==old:return True
   if s in seen:continue
   seen.add(s);nxt.extend(e['old_sha256'] for e in authority['owned'][p]['edges'] if e['new_sha256']==s)
  frontier=nxt
 return False
def promote(src):
 out=copy.deepcopy(src)
 for p,s in list(out.items()):
  if p in authority['owned']:
   assert approved(p,s),(p,s);out[p]=current(p)
 return out
def symbolic(v):
 if isinstance(v,dict) and set(v)=={'$owned'}:return current(v['$owned'])
 if isinstance(v,dict) and set(v)=={'$pin'}:return pins[v['$pin']]['sha256']
 return copy.deepcopy(v)
def apply(src,ops):
 out=copy.deepcopy(src)
 for op in ops:
  assert len(op['pointer'])==2 and op['pointer'][0]=='source_sha256'
  p=op['pointer'][1]
  assert (p in out)==op['existed']
  if op['existed']:assert same(out[p],op['old']),('EXACT_REAL_ORDER_OLD',p,out[p],op['old'])
  if op['op']=='remove':del out[p]
  else:out[p]=symbolic(op['new'])
 return out
proofs=[]
for n in plan['nodes']:
 if n['kind']!='map':continue
 b=pins[n['base_input']];base=read(b['path'],b['sha256'])['source_sha256']
 oldops=copy.deepcopy(n['operations']);removed=[];keep=[]
 for op in oldops:
  p=op['pointer'][1]
  if p in authority['owned']:
   assert op['op']=='set' and op['existed'] and op['old']==base[p]
   assert symbolic(op['new'])==current(p) and approved(p,base[p])
   removed.append(op)
  else:keep.append(op)
 # Intended old recipe (raw operations, then identical approved promotion)
 # versus actual M.map order with redundant owned operations removed.
 intended=promote(apply(base,oldops));real=apply(promote(base),keep)
 assert same(intended,real)
 assert all(op['pointer'][1] not in authority['owned'] for op in keep)
 n['operations']=keep
 proofs.append({'scene_id':n['scene_id'],'baseline':{'path':b['path'],'sha256':b['sha256']},'removed_exact_redundant_owned_sets':removed,'removed_count':len(removed),'remaining_operation_count':len(keep),'real_promote_first_order_exact_old_checks_passed':True,'whole_pre_group_source_dictionary_typed_equal_to_intended_recipe':True,'source_groups_whole_unchanged':n['groups']})
assert len(proofs)==4
plan['output_root']=S+'outputs/root_finite09_two_domain_stage02/'
plan['finite09_actual01_failure_preserved']={'input_path':parentpath,'input_sha256':parentsha,'cause':'Original inherited M.map promotes all owned baseline leaves before explicit operations; redundant owned sets asserted obsolete raw old values','production_tool_scope_code_and_source_groups_unchanged':True}
# Everything except the exact four map-operation lists, output epoch and this
# explicit failure note is a whole typed copy of the failed input.
back=copy.deepcopy(plan);back['output_root']=before['output_root'];del back['finite09_actual01_failure_preserved']
for n,old in zip(back['nodes'],before['nodes']):
 if n['kind']=='map':n['operations']=copy.deepcopy(old['operations'])
assert same(back,before)
desc=emit('finite09_input02_ROOT_LOCKED.json',plan)
proof=emit('finite09_tool_review/input02_real_map_order_proof_READY.json',{'status':'EXACT_REAL_PROMOTE_FIRST_MAP_ORDER_REPAIR_NOT_STAGE','parent_input_sha256':parentsha,'candidate_input':desc,'four_maps':proofs,'whole_other_input_typed_identical':True,'removed_total':sum(p['removed_count'] for p in proofs),'nonowned_C_Fade_Resident_retained':True,'no_tool_or_production_candidate_change':True,'stage_runs':0,'engine_calls':0})
oldrecipe=H/'review_finite09_actual_stage_and_prepare_owners_READY.py';raw=oldrecipe.read_bytes();assert sha(raw)=='71716a6af5a4ca4f7deb7b79ad307b3f17b7fbb0efc270388e3e51fd0d049d44'
text=raw.decode()
for x,y in [('root_finite09_two_domain_stage01','root_finite09_two_domain_stage02'),('finite09_input01_ROOT_LOCKED.json','finite09_input02_ROOT_LOCKED.json'),(parentsha,desc['sha256']),('finite09_independent_review','finite09_stage02_independent_review')]:
 assert text.count(x)==1,(x,text.count(x));text=text.replace(x,y,1)
recipe=emit('review_finite09_stage02_and_prepare_owners_READY.py',text.encode())
print(json.dumps({'input':desc,'proof':proof,'owner_recipe':recipe,'removed_total':sum(p['removed_count'] for p in proofs),'tool_unchanged':'4b03f35031ac978ffba7dfba25e2dea104f080e502adbbdeef1b5c3ad90ba0fb','stage_runs':0}))
