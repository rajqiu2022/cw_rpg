"""Root-only finite new-runtime freeze. No engine, old source, QA or save writes."""
from pathlib import Path
import argparse,hashlib,json,re
TASK=Path(__file__).resolve().parent
GAME=TASK.parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--refreeze',action='store_true',help='Explicitly archive a previous ready freeze before replacement')
parser.add_argument('--list-only',action='store_true',help='Read-only finite dependency union; do not freeze or archive')
args=parser.parse_args()
def need(v,s):
 if not v:raise ValueError(s)
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):return 'res://'+p.relative_to(GAME).as_posix()
def physical(p):
 need(p.startswith('res://')and'..'not in p,'EXPLICIT_RES_PATH')
 return GAME/p[6:]
paths=set()
def add(p):
 need(isinstance(p,str)and p.startswith('res://')and'..'not in p,('BAD_SOURCE',p))
 if p=='res://project.godot':return # exact one-line mutation belongs to Root's separate guard
 f=physical(p);need(f.is_file(),('MISSING_SOURCE',p));paths.add(p)
 if f.suffix.lower()in('.png','.jpg','.jpeg','.svg'):
  imp=Path(str(f)+'.import');need(imp.is_file(),('IMPORT_REQUIRED',p));paths.add(p+'.import')
  gpu=re.findall(r'path(?:\.[A-Za-z0-9_]+)?\s*=\s*"(res://[^"\r\n]+\.ctex)"',imp.read_text(encoding='utf-8-sig'))
  need(bool(gpu),('ACTUAL_GPU_REMAP_REQUIRED',p))
  for item in gpu:need(physical(item).is_file(),('GPU_REQUIRED',item));paths.add(item)
# New executable leaves only. QA configurations and the freeze itself are not
# runtime dependencies and must not become a circular approval graph.
for f in sorted(TASK.glob('*.gd'))+sorted(TASK.glob('*.gdshader')):add(res(f))
helpers=[GAME/'build/luoyang_temple_adult_20261101d_art01/live_art_view.gd',GAME/'build/city_navigation_minimap_20261101d_candidate01/mini_marker_overlay.gd',GAME/'build/city_navigation_minimap_20261101d_candidate01/service_semantics.gd']
for helper in helpers:add(res(helper))
# These are the literal direct dependencies declared by the reviewed new APIs.
# Do not recursively sweep old source graphs or any historical /before folder.
for f in sorted(TASK.glob('*.gd'))+helpers:
 for p in re.findall(r'"(res://[^"\r\n]+)"',f.read_text(encoding='utf-8-sig')):
  if not p.endswith('/'):add(p)
add('res://build/luoyang_temple_adult_20261101d_art01/art_binding_CANDIDATE.json')
manifest_path='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
finish_path='res://build/luoyang_gate_front_walls_20261101c_system01/closure_READY01/finish8_binding_READY.json'
manifest=json.loads(physical(manifest_path).read_bytes());finish=json.loads(physical(finish_path).read_bytes())
for id in ('luoyang_civic_market_region_27d','luoyang_estate_region_27d','luoyang_temple_region_27d'):
 row=manifest['compiled_bindings'][id];add(row['path']);need(sha(physical(row['path']).read_bytes())==row['sha256'],('REGION_BIN_BINDING',id))
for id in ('ch4_s0_luoyang_gate','ch4_s2_canal_docks','luoyang_artisan_residential_20261022ap','luoyang_riverside_garden_20261022ap'):
 row=finish['scenes'][id];add(row['payload']['path']);need(sha(physical(row['payload']['path']).read_bytes())==row['payload']['sha256'],('LEGACY_OVERLAY_BINDING',id))
 if row['mask']['kind']=='IMPORTED_RGBA8':add(row['mask']['path'])
# HOME+constant composition is intentionally explicit rather than guessed.
for p in ('res://scripts/adventure/adventure_runtime.gd','res://build/adventure_world_20261031f_system01/world_links.gd','res://data/maps/adventure_20261030k/luoyang_adventure_config.json','res://data/scenes/adventure_luoyang_riverside_route.tres','res://data/maps/adventure_20261030k/luoyang_riverside_layout.tres','res://data/maps/adventure_20261030k/luoyang_walk.svg'):
 add(p)
need(not any('/qa' in p.lower()or'_qa' in p.lower()or'joint_inputs' in p.lower()or'/before/' in p.lower()for p in paths),'NO_QA_OR_ARCHIVE_PIN_CYCLE')
if args.list_only:
 print(json.dumps({'source_count':len(paths),'source_paths':sorted(paths),'manifest_writes':0,'engine_runs':0},ensure_ascii=False));raise SystemExit(0)
target=TASK/'source_pins_READY.json';before=target.read_bytes();old=json.loads(before)
need(old.get('ready')is not True or args.refreeze,'EXPLICIT_REFREEZE_REQUIRED')
first={p:sha(physical(p).read_bytes())for p in sorted(paths)}
rows={p:{'sha256':h,'bytes':physical(p).stat().st_size}for p,h in first.items()}
last={p:sha(physical(p).read_bytes())for p in sorted(paths)};need(first==last,'FINITE_SOURCE_FIRST_FINAL')
value={'schema':'CITY_NAVIGATION_20261101D_FROZEN_V1','ready':True,'autoload_registration':'*res://build/city_navigation_20261101d_candidate01/city_navigation_runtime.gd','project_exact_one_line_owned_by_root_guard':True,'source_pins':first,'source_facts':rows,'pair_count':11,'end_count':22,'runtime_dependency_scope':'Reviewed new code, exact original geometry/direct APIs/media only; no QA or old full matrix','canonical_old_source_writes':0,'engine_runs':0}
archive=TASK/('source_pins_BEFORE_'+sha(before)+'.json')
if archive.exists():need(archive.read_bytes()==before,'EXACT_EXISTING_ARCHIVE')
else:
 with archive.open('xb')as f:f.write(before)
target.write_bytes((json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode())
print(json.dumps({'ready':True,'source_count':len(first),'manifest_sha256':sha(target.read_bytes()),'autoload_line':'CityNavigationRuntime="*res://build/city_navigation_20261101d_candidate01/city_navigation_runtime.gd"','old_source_writes':0,'engine_runs':0}))
