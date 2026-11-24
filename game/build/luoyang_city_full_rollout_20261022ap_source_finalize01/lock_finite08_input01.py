"""NEW exact Root-reviewed authorities attached; external Root SHA still required."""
import ast,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def sha(b):return hashlib.sha256(b).hexdigest()
raw=(H/'finite08_input_PENDING.json').read_bytes();assert sha(raw)=='32ba4e30836b9229c55600ac8a32200b434a21dd5dd8388cfe3d136044b6d1cb'
v=json.loads(raw)
tool=(H/'stage_finite08_scope01_READY.py').read_bytes();ast.parse(tool.decode())
v['required_generator']={'path':S+'stage_finite08_scope01_READY.py','sha256':sha(tool),'root_must_read_before_execution':True}
v['status']='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT';v['blockers']=[]
v['pinned_inputs'].append({'id':'root_finite08_actual_backups','path':'res://build/luoyang_city_full_rollout_20261022ap_root01/integration12/root_target_scope_READY.json','sha256':'44cfe6d81a6aff79431def1a3026199219f0a63083931de636577efa633841a0'})
for r in v['pinned_inputs']:
 b=(G/r['path'][6:]).read_bytes();assert sha(b)==r['sha256'],r['path']
# Pure syntax/recipe graph and every concrete old-value preflight only. Do not
# instantiate or run either Stage: Root owns the unique buffered compilation.
ids=set();allids={n['id'] for n in v['nodes']}
for n in v['nodes']:
 assert n['id'] not in ids
 def refs(x):
  if isinstance(x,dict):
   if '$sha' in x:assert x['$sha'] in allids
   for y in x.values():refs(y)
  elif isinstance(x,list):
   for y in x:refs(y)
 refs(n);ids.add(n['id'])
out=H/'finite08_input01_ROOT_LOCKED.json';assert not out.exists()
b=(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
with out.open('xb') as f:f.write(b)
print(json.dumps({'input':S+out.name,'input_sha256':sha(b),'tool':v['required_generator'],'targets':len(v['root_target_allowlist']),'pinned_input_count':len(v['pinned_inputs']),'stage_runs':0}))
