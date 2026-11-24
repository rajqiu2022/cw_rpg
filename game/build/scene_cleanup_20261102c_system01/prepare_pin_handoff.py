"""Finite direct-pin handoff; emits advice only, canonical manifests are not changed."""
from pathlib import Path
import json,hashlib
TASK=Path(__file__).resolve().parent;GAME=TASK.parents[1]
def read(p):
 q=GAME/p[6:]
 if not q.exists():q=TASK/'mask_import_ROOT'/p[6:]
 return q.read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
receipt=json.loads((TASK/'closure_READY01/receipt_READY.json').read_bytes())
pub=json.loads((TASK/'output/140404/result.json').read_bytes())
changed={'res://'+r['target'][5:]:r for r in receipt['targets']}
binding='res://build/luoyang_gate_front_walls_20261101c_system01/closure_READY01/finish8_binding_READY.json'
new_binding='res://build/scene_cleanup_20261102c_system01/closure_READY01/finish8_binding_READY.json'
relocations={binding:{'path':new_binding,'sha256':sha(read(new_binding))}}
for r in pub['records'].values():
 relocations[r['before']['path']]=r['payload']
 if r['kind']=='LEGACY':
  old=r['previous_mask'];new=r['mask'];side=new['path']+'.import'
  import re
  gpu=re.search(r'^path="([^"]+)"',read(side).decode(),re.M).group(1)
  relocations[old['path']]={'path':new['path'],'sha256':new['sha256']}
  relocations[old['import_path']]={'path':side,'sha256':sha(read(side))}
  relocations[old['compiled_path']]={'path':gpu,'sha256':sha(read(gpu))}
reports=[]
for path in ['res://build/city_navigation_20261101d_candidate01/source_pins_READY.json','res://build/luoyang_quality_20261101b_runtime01/source_pins_READY.json']:
 v=json.loads(read(path));rows=[]
 for p,h in v['source_pins'].items():
  if p in changed:rows.append({'old_path':p,'old_sha256':h,'new_path':p,'new_sha256':changed[p]['new_sha256'],'reason':'same canonical consumer exact successor'})
  elif p in relocations:rows.append({'old_path':p,'old_sha256':h,'new_path':relocations[p]['path'],'new_sha256':relocations[p]['sha256'],'reason':'new immutable binding/data leaf'})
 regions=[]
 for sid,r in pub['records'].items():
  if r['kind']=='REGION' and sid in v.get('region_bindings',{}):regions.append({'scene':sid,'old':v['region_bindings'][sid],'new':r['payload']})
 reports.append({'manifest':path,'before_sha256':sha(read(path)),'old_pin_count':len(v['source_pins']),'required_exact_pin_successors':rows,'region_bindings_successors':regions})
out={'status':'ROOT_FINAL_PIN_SEAL_HANDOFF_ONLY','reports':reports,'other_UI_perf_Project_changes_not_included':True,'no_old_pin_history_deleted':True,'canonical_writes':0}
(TASK/'direct_pin_handoff_READY.json').write_bytes((json.dumps(out,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'manifests':[(r['old_pin_count'],len(r['required_exact_pin_successors']),len(r['region_bindings_successors']))for r in reports]}))
