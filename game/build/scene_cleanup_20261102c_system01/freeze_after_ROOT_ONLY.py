"""Root-only final finite Art60 and CityNav source successor. No engine or save access.

Run after Root adopts cleanup39 + ground1 + the reviewed performance runtime.
Default prepares immutable candidates only. Explicit --apply archives exact old
manifests/runtime, then installs only those three approved successor leaves.
"""
from pathlib import Path
import argparse,hashlib,json,re,copy,difflib
TASK=Path(__file__).resolve().parent;GAME=TASK.parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--apply',action='store_true');args=parser.parse_args()
OUT=TASK/'freeze_after_READY01'
def need(v,s):
 if not v:raise ValueError(s)
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def physical(p):
 need(p.startswith('res://')and'..'not in p,('EXPLICIT_RES',p));return GAME/p[6:]
def read(p):return physical(p).read_bytes()
def res(p):return 'res://'+p.relative_to(GAME).as_posix()
def replace(raw,rows):
 b=raw
 for o,n in rows:
  o=o.encode();n=n.encode();need(b.count(o)==1,('EXACT_ONE_LITERAL',o));b=b.replace(o,n,1)
 inv=b
 for o,n in reversed(rows):need(inv.count(n.encode())==1,'EXACT_INVERSE_LITERAL');inv=inv.replace(n.encode(),o.encode(),1)
 need(inv==raw,'WHOLE_LITERAL_INVERSE');return b
def positional(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True);hs=[]
 for op,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
  if op!='equal':hs.append({'old_offset':len(''.join(aa[:i]).encode()),'new_offset':len(''.join(bb[:k]).encode()),'old':''.join(aa[i:j]),'new':''.join(bb[k:l])})
 inverse=b
 for h in reversed(hs):
  at=h['new_offset'];n=h['new'].encode();need(inverse[at:at+len(n)]==n,'EXACT_POSITIONAL_SLICE');inverse=inverse[:at]+h['old'].encode()+inverse[at+len(n):]
 need(inverse==a,'WHOLE_POSITIONAL_INVERSE');return hs
cleanup=json.loads((TASK/'closure_READY01/receipt_READY.json').read_bytes())
for row in cleanup['targets']:need(sha((GAME.parent/row['target']).read_bytes())==row['new_sha256'],('ROOT_CLEANUP_ADOPTION_REQUIRED',row['target']))
ground=json.loads((TASK/'ground_count_successor_READY.json').read_bytes());need(sha((GAME.parent/ground['target']).read_bytes())==ground['new_sha256'],'ROOT_EXACT22_GROUND_ADOPTION_REQUIRED')
pub=json.loads((TASK/'output/140404/result.json').read_bytes());need(pub['passed']and pub['retired_actual_owners']==28,'ACTUAL_PUBLISHER')
navdir=GAME/'build/city_navigation_20261101d_candidate01'
nav='res://build/city_navigation_20261101d_candidate01/source_pins_READY.json'
art='res://build/luoyang_quality_20261101b_runtime01/source_pins_READY.json'
art_runtime='res://build/luoyang_quality_20261101b_runtime01/scene_art_quality_runtime.gd'
manifest_path='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
runtime='res://build/city_navigation_20261101d_candidate01/city_navigation_runtime.gd'
screen='res://build/transition_latency_20261102c_candidate01/loading_screen_barrier.gd'
screen3={screen:'8335ef1e5777e7167744f280dcbfdc4caef2f49b8e13e5c4c24f29d5f2f2a84e','res://scenes/ui/loading_screen.tscn':'340c4fd57e4a8aabd3be217d479c7361aebdae24d5cc6440ecbeba0efe1c3c01','res://scripts/ui/loading_screen.gd':'60a8bade4696dc3b8d0736561bd0a6c19ccc4637540a0fcca366171d0c9850da'}
need(sha(read(runtime))=='c8f5bb8ad51de0fbcdb6377ace99889c090eb3d87fcda7474560bf9dd3695a49','ROOT_PERFORMANCE_RUNTIME_C8F5_REQUIRED')
for p,h in screen3.items():need(sha(read(p))==h,('REVIEWED_SCREEN3',p))
before={p:read(p)for p in [nav,art,art_runtime]}
need(sha(before[nav])=='c237a45c0de473c2c1d1d613933bfad8e2e4906859177e6a0845e06ab6daf28c','ORIGINAL_C237_COMPLETE_PARENT_REQUIRED')
need(sha(before[art])=='c914c2d96d420a4f946b74aea1b7f6b5d3914b528e66794469d92bbc456fdc09','ORIGINAL_ART60_PARENT_REQUIRED')
oldnav=json.loads(before[nav]);oldart=json.loads(before[art]);need(len(oldnav['source_pins'])==99 and len(oldart['source_pins'])==60,'EXACT99_AND60_PARENT_DOMAINS')
manifest=json.loads(read(manifest_path));newart=copy.deepcopy(oldart)
literal=[('af1bb975b0603e2d735890ff89fa60c8e2100ccb0a7565fc1211ca1794d866be',sha(read(manifest_path)))]
for sid,r in pub['records'].items():
 if r['kind']!='REGION':continue
 need(manifest['compiled_bindings'][sid]==r['payload'],'ACTUAL_REGION_BINDING')
 old=oldart['region_bindings'][sid];need(old==r['before'],'EXACT_OLD_ART_REGION')
 newart['region_bindings'][sid]=copy.deepcopy(r['payload'])
 need(newart['source_pins'].pop(old['path'])==old['sha256'],'EXACT_OLD_ART_BIN_PIN')
 newart['source_pins'][r['payload']['path']]=r['payload']['sha256'];literal.append((old['sha256'],r['payload']['sha256']))
after={art_runtime:replace(before[art_runtime],literal)}
newart['source_pins'][manifest_path]=sha(read(manifest_path));newart['source_pins']['res://'+ground['target'][5:]]=ground['new_sha256'];newart['source_pins'][art_runtime]=sha(after[art_runtime])
need(len(newart['source_pins'])==60,'ART60_CARDINALITY_PRESERVED')
test=copy.deepcopy(newart);test['source_pins']=oldart['source_pins'];test['region_bindings']=oldart['region_bindings'];need(test==oldart,'OTHER_ART_FIELDS_TYPED_IDENTICAL')
for p,h in newart['source_pins'].items():
 if p=='res://project.godot':continue # feature owns one autoload line, original runtime contract skips full project
 need((sha(after[p])if p in after else sha(read(p)))==h,('EXACT_FINAL_ART_PIN',p))
after[art]=enc(newart)
# Same finite direct-dependency algorithm as original freeze, but FINISH_BIND is
# read from the actual reviewed Geo constant rather than a stale hardcoded path.
paths=set()
def add(p):
 need(isinstance(p,str)and p.startswith('res://')and'..'not in p,('BAD_DIRECT_SOURCE',p))
 if p=='res://project.godot':return
 f=physical(p);need(f.is_file(),('MISSING_DIRECT_SOURCE',p));paths.add(p)
 if f.suffix.lower()in('.png','.jpg','.jpeg','.svg'):
  side=p+'.import';need(physical(side).is_file(),('ACTUAL_IMPORT_REQUIRED',p));paths.add(side)
  gpu=re.findall(r'path(?:\.[A-Za-z0-9_]+)?\s*=\s*"(res://[^"\r\n]+\.ctex)"',read(side).decode('utf-8-sig'));need(gpu,('ACTUAL_GPU_REMAP',p))
  for g in gpu:need(physical(g).is_file(),('ACTUAL_GPU_REQUIRED',g));paths.add(g)
leaves=sorted(navdir.glob('*.gd'))+sorted(navdir.glob('*.gdshader'))
helpers=[GAME/'build/luoyang_temple_adult_20261101d_art01/live_art_view.gd',GAME/'build/city_navigation_minimap_20261101d_candidate01/mini_marker_overlay.gd',GAME/'build/city_navigation_minimap_20261101d_candidate01/service_semantics.gd']
for f in leaves+helpers:add(res(f))
for f in sorted(navdir.glob('*.gd'))+helpers:
 for p in re.findall(r'"(res://[^"\r\n]+)"',f.read_text(encoding='utf-8-sig')):
  if not p.endswith('/'):add(p)
geo='res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd'
finish_path=re.search(r'const FINISH_BIND := "([^"]+)"',read(geo).decode()).group(1)
need(finish_path=='res://build/scene_cleanup_20261102c_system01/closure_READY01/finish8_binding_READY.json','ACTUAL_GEO_NEW_FINISH_BINDING_REQUIRED')
finish=json.loads(read(finish_path));add('res://build/luoyang_temple_adult_20261101d_art01/art_binding_CANDIDATE.json')
for sid in ('luoyang_civic_market_region_27d','luoyang_estate_region_27d','luoyang_temple_region_27d'):
 r=manifest['compiled_bindings'][sid];add(r['path']);need(sha(read(r['path']))==r['sha256'],('ACTUAL_REGION_BIN',sid))
for sid in ('ch4_s0_luoyang_gate','ch4_s2_canal_docks','luoyang_artisan_residential_20261022ap','luoyang_riverside_garden_20261022ap'):
 r=finish['scenes'][sid];add(r['payload']['path']);need(sha(read(r['payload']['path']))==r['payload']['sha256'],('ACTUAL_LEGACY_BIN',sid))
 if r['mask']['kind']=='IMPORTED_RGBA8':add(r['mask']['path'])
for p in ('res://scripts/adventure/adventure_runtime.gd','res://build/adventure_world_20261031f_system01/world_links.gd','res://data/maps/adventure_20261030k/luoyang_adventure_config.json','res://data/scenes/adventure_luoyang_riverside_route.tres','res://data/maps/adventure_20261030k/luoyang_riverside_layout.tres','res://data/maps/adventure_20261030k/luoyang_walk.svg'):add(p)
need(set(screen3)<=paths,'THREE_SCREEN_DIRECT_LEAVES_INCLUDED')
need(not any('/qa'in p.lower()or'_qa'in p.lower()or'joint_inputs'in p.lower()or'/before/'in p.lower()for p in paths),'NO_QA_OR_ARCHIVE_PIN_CYCLE')
first={p:sha(read(p))for p in sorted(paths)};facts={p:{'sha256':h,'bytes':physical(p).stat().st_size}for p,h in first.items()};last={p:sha(read(p))for p in sorted(paths)};need(first==last,'FINITE_DIRECT_FIRST_FINAL')
newnav=copy.deepcopy(oldnav);newnav['source_pins']=first;newnav['source_facts']=facts
test=copy.deepcopy(newnav);test['source_pins']=oldnav['source_pins'];test['source_facts']=oldnav['source_facts'];need(test==oldnav,'OTHER_CITYNAV_FIELDS_TYPED_IDENTICAL')
need(len(first)==102,'EXACT_ORIGINAL99_GEOMETRY_REPLACEMENTS_PLUS_SCREEN3')
after[nav]=enc(newnav)
need(not OUT.exists(),'EXCLUSIVE_NEW_FINAL_FREEZE_OUTPUT_REQUIRED');OUT.mkdir()
targets=[]
for p,b in after.items():
 archive=OUT/('BEFORE_'+physical(p).parent.name+'__'+physical(p).name)
 with archive.open('xb')as f:f.write(before[p])
 candidate=OUT/('AFTER_'+physical(p).parent.name+'__'+physical(p).name)
 with candidate.open('xb')as f:f.write(b)
 targets.append({'target':p,'candidate':res(candidate),'archive':res(archive),'old_sha256':sha(before[p]),'new_sha256':sha(b),'old_bytes':len(before[p]),'bytes':len(b),'whole_inverse_exact':True,'hunks':positional(before[p],b)})
receipt={'status':'ROOT_APPLIED'if args.apply else 'CANDIDATE_ONLY_NOT_DEPLOYED','targets':targets,'Art60_count':60,'Art_bindings_changed':3,'Art_runtime_only_four_exact_SHA_literals':True,'CityNav_before_count':99,'CityNav_after_count':102,'CityNav_old_C237_complete_archive':True,'Geo_FINISH_BIND':finish_path,'new_screen_direct3':screen3,'other_manifest_top_fields_identical':True,'first_final':True,'engine_runs':0,'save_reads':0,'save_writes':0}
with (OUT/'receipt.json').open('xb')as f:f.write(enc(receipt))
for p,b in before.items():need(read(p)==b,('FORMAL_SOURCE_STILL_SAME',p))
if args.apply:
 # Explicit Root invocation only. No other old source is written.
 for p,b in after.items():physical(p).write_bytes(b)
 for p,b in after.items():need(read(p)==b,('FINAL_EXACT_AFTER',p))
print(json.dumps({'status':receipt['status'],'sources':len(targets),'Art60':60,'CityNav102':102,'receipt':res(OUT/'receipt.json'),'manifest_sha256':{p:sha(b)for p,b in after.items()}}))
