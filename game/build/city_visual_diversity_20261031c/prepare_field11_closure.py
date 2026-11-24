"""Root-approved eleven-target RegionField visual-call closure, no canonical writes."""
from pathlib import Path
import ast,copy,difflib,hashlib,json,re,sys
BASE=Path(__file__).resolve().parent
REPO=BASE.parents[2]
OUT=BASE/'field11_READY'
PREFIX='game/build/city_visual_diversity_20261031c/field11_READY/'
# Reuse pure helper definitions only. Do not execute the withdrawn 24-path plan.
tree=ast.parse((BASE/'prepare_source_closure.py').read_text(encoding='utf-8-sig'))
for function in tree.body:
 if isinstance(function,ast.FunctionDef):
  exec(compile(ast.Module(body=[function],type_ignores=[]),'<pure closure helper>','exec'),globals())
SNAP='res://build/luoyang_city_visual_diversity_20261031c_snapshot01/scene_router.gd'
FIELD='res://build/luoyang_regions_20261027d_source01/region_field.gd'
MANIFEST='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
ROUTER='res://scripts/autoload/scene_router.gd'
EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
EI='res://scripts/city/luoyang_execution_index_20261022ap.gd'
GATE='res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'
DOCK='res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json'
QUARTER='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
paths=[FIELD,MANIFEST,ROUTER,EX,EI,GATE,DOCK,QUARTER,
 'res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd',
 'res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd',
 'res://scripts/city/luoyang_quarters_index_20261022ap.gd']
before={p:read(p) for p in paths};oldsha={p:sha(b) for p,b in before.items()}
domain=json.loads((BASE/'district_manifest_READY.json').read_bytes())
row=next(r for r in domain['targets'] if r['target']=='game/'+FIELD[6:])
assert row['old_sha256']==oldsha[FIELD]
after={FIELD:(REPO/row['candidate']).read_bytes()}
assert sha(after[FIELD])==row['new_sha256']
modules={}
for name in ['district_visuals.gd','district_patches.json','district_ground_edge.gdshader']:
 p='res://build/city_visual_diversity_20261031c/'+name;b=read(p)
 modules[p]={'sha256':sha(b),'bytes':len(b)}
old_manifest=json.loads(before[MANIFEST])
m=edit(before[MANIFEST],[(json.dumps(FIELD)+': '+json.dumps(oldsha[FIELD]),json.dumps(FIELD)+': '+json.dumps(sha(after[FIELD])))])
start=m.index(b'  "runtime_modules": {');end=m.index(b'\n  }',start)
assert all(p not in old_manifest['runtime_modules'] for p in modules)
addition=''.join(',\n    '+json.dumps(p)+': '+json.dumps(f['sha256']) for p,f in modules.items()).encode()
after[MANIFEST]=m[:end]+addition+m[end:];new_manifest=json.loads(after[MANIFEST])
assert len(new_manifest['runtime_modules'])==len(old_manifest['runtime_modules'])+3
assert {k:v for k,v in old_manifest.items() if k!='runtime_modules'}=={k:v for k,v in new_manifest.items() if k!='runtime_modules'}
header=re.search(rb'const REGION27D_AUTHOR_SHA := "[a-f0-9]{64}"',before[ROUTER]).group(0)
assert oldsha[MANIFEST].encode() in header
after[ROUTER]=edit(before[ROUTER],[(header,b'const REGION27D_AUTHOR_SHA := "'+sha(after[MANIFEST]).encode()+b'"')])
old_ex=json.loads(before[EX]);router_row=copy.deepcopy(old_ex['owned'][ROUTER])
assert router_row['current_sha256']==oldsha[ROUTER]
old_snapshot=router_row['edges'][-1]['new_snapshot'];assert read(old_snapshot)==before[ROUTER]
router_row['current_sha256']=sha(after[ROUTER]);router_row['edges'].append({'path':ROUTER,'old_sha256':oldsha[ROUTER],'new_sha256':sha(after[ROUTER]),'old_snapshot':old_snapshot,'new_snapshot':SNAP,'whole_inverse':True,'replacements':hunks(before[ROUTER],after[ROUTER])})
text=before[EX].decode();marker='    '+json.dumps(ROUTER)+': ';start=text.index(marker)+len(marker)
_,used=json.JSONDecoder().raw_decode(text[start:]);new_row=json.dumps(router_row,ensure_ascii=False,indent=2).replace('\n','\n    ')
text=(text[:start]+new_row+text[start+used:]).encode()
start=text.index(b'  "source_sha256": {');end=text.index(b'\n  }',start)
assert SNAP not in old_ex['source_sha256']
after[EX]=text[:end]+b',\n    '+json.dumps(SNAP).encode()+b': '+json.dumps(sha(after[ROUTER])).encode()+text[end:]
after[EI]=edit(before[EI],[(oldsha[EX],sha(after[EX]))])
known={p:sha(b) for p,b in after.items()};pending=[p for p in paths if p not in after]
def deps(p):return {q for q,h in oldsha.items() if q!=p and h.encode() in before[p]}
for _ in paths:
 progress=False
 for p in list(pending):
  if any(q in pending for q in deps(p)):continue
  if p.endswith('.json'):data=source_update(before[p],known)
  else:data=edit(before[p],[(oldsha[q],known[q]) for q in known if oldsha[q]!=known[q] and oldsha[q].encode() in before[p]])
  assert data!=before[p],('UNNECESSARY_TARGET',p)
  after[p]=data;known[p]=sha(data);pending.remove(p);progress=True
 if not pending:break
 assert progress,pending
assert not pending and len(after)==11
names={p:p[6:].replace('/','__') for p in paths}
if sys.argv[-1]=='--emit-patch':
 print('*** Begin Patch')
 for p,data in after.items():
  if p.endswith('.gd'):
   print('*** Add File: '+(OUT/names[p]).as_posix())
   # Preserve exact mixed EOL by writing each original line to patch output.
   for s in data.decode().splitlines(keepends=True):sys.stdout.write('+'+s)
   if not data.endswith(b'\n'):print()
 print('*** End Patch')
 sys.exit()
if sys.argv[-1]=='--restore-eol-only':
 for p,data in after.items():
  if p.endswith('.gd'):
   candidate=OUT/names[p];actual=candidate.read_bytes()
   assert actual.replace(b'\r\n',b'\n')==data.replace(b'\r\n',b'\n'),('NON_FORMAT_DIFFERENCE',p)
   if actual!=data:candidate.write_bytes(data)
 print('Only exact source-template line endings restored; no source text changes.')
 sys.exit()
assert sys.argv[-1]=='--seal' and OUT.is_dir()
def put(name,b):
 if (OUT/name).exists():
  assert (OUT/name).read_bytes()==b
  return
 with (OUT/name).open('xb') as f:f.write(b)
targets=[]
for p,data in after.items():
 name=names[p]
 if p.endswith('.gd'):assert (OUT/name).read_bytes()==data,('PATCH_BYTES_DIFFER',p)
 else:put(name,data)
 put(name+'.BEFORE',before[p])
 put(name+'.diff',''.join(difflib.unified_diff(before[p].decode().splitlines(keepends=True),data.decode().splitlines(keepends=True),fromfile='a/'+p,tofile='b/'+p)).encode())
 targets.append({'target':'game/'+p[6:],'candidate':PREFIX+name,'old_sha256':oldsha[p],'new_sha256':sha(data),'bytes':len(data),'before':PREFIX+name+'.BEFORE'})
new_ex=json.loads(after[EX]);assert new_ex['owned'][ROUTER]['edges'][:-1]==old_ex['owned'][ROUTER]['edges']
assert set(new_ex['source_sha256'])==set(old_ex['source_sha256'])|{SNAP}
for p,h in old_ex['source_sha256'].items():assert new_ex['source_sha256'][p]==h
water=json.loads((BASE/'npc_water_manifest_READY.json').read_bytes());final={r['target']:r for r in water['targets']}
for r in domain['targets']:
 if r['target']!='game/'+FIELD[6:]:final[r['target']]=r
native=json.loads(read('res://build/three_towns_world_20261029j_system01/native_sources.json'))
for p,r in final.items():
 resource='res://'+p[5:];assert resource not in native['sources'] and resource not in old_manifest['runtime_modules']
receipt={'status':'ROOT_APPROVED_FIELD11_EXACT_CLOSURE_CANDIDATES_NOT_DEPLOYED','targets':targets,
 'source_target_count':11,'new_modules':{'game/'+p[6:]:f for p,f in modules.items()},
 'required_router_snapshot':{'target':'game/'+SNAP[6:],'candidate':PREFIX+names[ROUTER],'sha256':sha(after[ROUTER]),'bytes':len(after[ROUTER])},
 'other_final_domain_targets':list(final.values()),'native_required_existing_updates':{},'native_required_new_keys':{},
 'native_note':'No changed path exists in native202. Separate Xiang/Jinling dispatch does not call town source_valid. No town_registry/native update required.',
 'region_modules_before':len(old_manifest['runtime_modules']),'region_modules_after':len(new_manifest['runtime_modules']),
 'EX_edges_before':len(old_ex['owned'][ROUTER]['edges']),'EX_edges_after':len(router_row['edges']),
 'old_EX_keys_retained':True,'all_ten_bin_bindings_exact':True,'GardenVisual_unchanged':sha(read('res://build/luoyang_garden_city_minimap_20261030b_system01/garden_visual.gd')),
 'withdrawn_unexecuted_plan':'prepare_source_closure.py / 24-path Garden hook plan',
 'canonical_writes':0,'engine_runs':0,'save_reads':0}
put('receipt_READY.json',enc(receipt));put('hunks_READY.json',enc({'targets':[{'target':'game/'+p[6:],'replacements':hunks(before[p],after[p])} for p in paths if p.endswith('.gd')]}))
print(json.dumps({'receipt_sha256':sha(enc(receipt)),'targets':len(targets),'manifest_sha256':sha(after[MANIFEST]),'router_sha256':sha(after[ROUTER]),'field_sha256':sha(after[FIELD]),'native_delta':0,'engine_runs':0}))
