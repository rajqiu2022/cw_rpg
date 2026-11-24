"""Finite byte-overlay check of the new source closure, not a Godot run."""
from pathlib import Path
import hashlib,json,re
BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
OUT=BASE/'field11_READY'
def digest(b):return hashlib.sha256(b).hexdigest()
receipt=json.loads((OUT/'receipt_READY.json').read_bytes())
overlay={}
for row in receipt['targets']:
 b=(ROOT/row['candidate']).read_bytes()
 assert digest(b)==row['new_sha256'] and len(b)==row['bytes']
 old=(ROOT/row['before']).read_bytes();assert digest(old)==row['old_sha256']
 overlay['res://'+row['target'][5:]]=b
snapshot=receipt['required_router_snapshot']
overlay['res://'+snapshot['target'][5:]]=(ROOT/snapshot['candidate']).read_bytes()
def read(p):return overlay[p] if p in overlay else (ROOT/('game/'+p[6:])).read_bytes()
def decoded(p):return json.loads(read(p))
manifest='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
m=decoded(manifest)
module_failures=[]
for path,expected in m['runtime_modules'].items():
 actual=digest(read(path))
 if actual!=expected:module_failures.append({'path':path,'expected':expected,'actual':actual})
assert not module_failures,module_failures
router='res://scripts/autoload/scene_router.gd'
pin=re.search(rb'const REGION27D_AUTHOR_SHA := "([a-f0-9]{64})"',read(router)).group(1).decode()
assert pin==digest(read(manifest))
old_m=json.loads(next((ROOT/r['before']).read_bytes() for r in receipt['targets'] if r['target']=='game/'+manifest[6:]))
for name,binding in m['compiled_bindings'].items():
 assert binding==old_m['compiled_bindings'][name]
 b=read(binding['path']);assert digest(b)==binding['sha256'] and len(b)==int(binding['bytes'])
ex='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
e=decoded(ex);edge=e['owned'][router]['edges'][-1]
assert e['owned'][router]['current_sha256']==digest(read(router))
assert edge['new_sha256']==digest(read(edge['new_snapshot']))
assert edge['old_sha256']==digest(read(edge['old_snapshot']))
inverse=read(edge['new_snapshot']).decode()
for change in edge['replacements']:
 assert inverse.count(change['new'])==1
 inverse=inverse.replace(change['new'],change['old'])
assert inverse.encode()==read(edge['old_snapshot'])
assert edge['new_snapshot'].startswith('res://build/luoyang_')
assert e['source_sha256'][edge['new_snapshot']]==edge['new_sha256']
ei=read('res://scripts/city/luoyang_execution_index_20261022ap.gd')
assert digest(read(ex)).encode() in ei
hunks=json.loads((OUT/'hunks_READY.json').read_bytes())
for row in hunks['targets']:
 path='res://'+row['target'][5:]
 old=next((ROOT/r['before']).read_bytes() for r in receipt['targets'] if r['target']==row['target'])
 result=read(path).decode()
 for change in reversed(row['replacements']):
  assert result.count(change['new'])==1
  result=result.replace(change['new'],change['old'])
 assert result.encode()==old
garden='res://build/luoyang_garden_city_minimap_20261030b_system01/garden_visual.gd'
assert digest(read(garden))==receipt['GardenVisual_unchanged']
proof={'status':'FINITE_NEW_CLOSURE_BYTE_OVERLAY_PASS_NOT_GODOT_OR_ART',
 'receipt_sha256':digest((OUT/'receipt_READY.json').read_bytes()),
 'targets':len(receipt['targets']),'runtime_module_pins_checked':len(m['runtime_modules']),
 'runtime_module_pin_failures':module_failures,'ten_immutable_bins_sha_bytes_exact':True,
 'Router_exact_manifest_pin':pin,'new_EX_edge_byte_inverse':True,
 'new_EX_snapshot_prefix_and_pin':True,'all_GD_target_full_inverse':True,
 'GardenVisual_old_bytes_preserved':True,'native_registry_delta':0,
 'canonical_writes':0,'engine_runs':0,'save_reads':0}
p=OUT/'source_guard_overlay_PROOF.json'
with p.open('xb') as f:f.write((json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'proof_sha256':digest(p.read_bytes()),**proof}))
