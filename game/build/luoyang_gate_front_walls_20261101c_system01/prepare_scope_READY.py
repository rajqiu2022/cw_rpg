"""Read-only bounded source inspection; writes only this new task's capture list."""
from pathlib import Path
import hashlib,json
TASK=Path(__file__).resolve().parent
GAME=TASK.parents[1]
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return (GAME/p.removeprefix('res://')).read_bytes()
def need(v,s):
 if not v:raise ValueError(s)
old='res://build/luoyang_gate_short_walls_20261029m_system01/closure_READY01/'
scope=json.loads(read('res://build/luoyang_city_finish_20261025i_source01/seven_fields_layout_repair01/current_DFCF_exact31_scope_PREPARATION.json'))
targets=[r['target']for r in scope['targets']]+[old+'finish8_runtime_READY.gd',old+'material_runtime_finish139_READY.gd']
need(len(targets)==len(set(targets))==33,'EXPLICIT_33_POTENTIAL_TARGETS')
region_path='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
region=json.loads(read(region_path))
pins_path='res://build/luoyang_quality_20261101b_runtime01/source_pins_READY.json'
pins=json.loads(read(pins_path))['source_pins']
need(len(pins)==60,'EXACT_11B_60_PIN_SET')
protected={p:h for p,h in pins.items()if p!='res://project.godot'}
protected[pins_path]=sha(read(pins_path))
protected[region_path]='af1bb975b0603e2d735890ff89fa60c8e2100ccb0a7565fc1211ca1794d866be'
protected['res://build/luoyang_regions_20261027d_source01/region_field.gd']='fdb375d92f1590be44288708bc697f2cb780e81584557027c5396508f73de5e5'
for row in region['compiled_bindings'].values():protected[row['path']]=row['sha256']
need(len(region['compiled_bindings'])==10,'TEN_CURRENT_BINS')
need(not set(targets)&set(protected),'NO_PROTECTED_TARGET')
need(not set(targets)&set(region['runtime_modules']),'NO_REGION_RUNTIME_MODULE_TARGET')
for p,h in protected.items():need(sha(read(p))==h,('PROTECTED_SHA',p))
for row in region['compiled_bindings'].values():
 data=read(row['path'])
 for p in targets:need(p.encode()not in data,('COMPILED_SOURCE_REFERENCE',row['path'],p))
result={'status':'POTENTIAL_CAPTURE_DOMAIN_NOT_AFTER_AUTHORIZATION','targets':[{'target':'game/'+p[6:],'sha256':sha(read(p)),'bytes':len(read(p))}for p in targets], 'protected_region_10bin_11b_sourcepins':protected,'project_exception':'Root may append NPCGaitRuntime one autoload line; SceneArtQualityRuntime own registration must stay exact','no_runtime_modules_or_compiled_source_key_overlap':True,'canonical_writes':0,'engine_runs':0}
output=TASK/'capture_targets_READY.json'
with output.open('xb')as f:f.write((json.dumps(result,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'capture_targets':len(targets),'protected':len(protected),'path':str(output),'sha256':sha(output.read_bytes())}))
