"""Eleven necessary headers for Entry+one immutable Civic binding. No canonical writes."""
from pathlib import Path
import ast,copy,difflib,hashlib,json,re,sys
BASE=Path(__file__).resolve().parent
REPO=BASE.parents[2]
OUT=BASE/'closure_READY'
PREFIX=OUT.relative_to(REPO).as_posix()+'/'
tree=ast.parse((REPO/'game/build/city_visual_diversity_20261031c/prepare_source_closure.py').read_text(encoding='utf-8-sig'))
for node in tree.body:
 if isinstance(node,ast.FunctionDef):exec(compile(ast.Module(body=[node],type_ignores=[]),'<pure existing closure helpers>','exec'),globals())
ENTRY='res://build/luoyang_regions_20261027d_source01/region_entry.gd'
MANIFEST='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
ROUTER='res://scripts/autoload/scene_router.gd'
EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
EI='res://scripts/city/luoyang_execution_index_20261022ap.gd'
SNAP='res://build/luoyang_city_neighborhoods_20261031d_snapshot01/scene_router.gd'
RESTORE='res://build/luoyang_city_neighborhoods_20261031d_system01/courts_restore.gd'
paths=[ENTRY,MANIFEST,ROUTER,EX,EI,
 'res://data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json',
 'res://data/maps/luoyang_docks_workyard_20261019ac/runtime/ch4_s2_canal_docks/manifest.json',
 'res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json',
 'res://scripts/city/luoyang_precomputed_bundle_index_20261018r.gd',
 'res://scripts/city/luoyang_docks_workyard_index_20261019ac.gd',
 'res://scripts/city/luoyang_quarters_index_20261022ap.gd']
assert len(sys.argv)==3,'binding.json --emit-patch|--restore-eol-only|--seal'
binding_path=Path(sys.argv[1]);binding=json.loads(binding_path.read_bytes())
binding={k:binding[k] for k in ['bytes','path','sha256']}
assert sha(read(binding['path']))==binding['sha256'] and len(read(binding['path']))==binding['bytes']
before={p:read(p) for p in paths};oldsha={p:sha(b) for p,b in before.items()}
entry=before[ENTRY];eol=b'\r\n' if entry.count(b'\r\n')==entry.count(b'\n') else b'\n'
def lines(text):return text.replace('\n',eol.decode())
changes=[
 ('const GardenRestore = preload("res://build/luoyang_estate_garden_20261029q_system01/garden_restore.gd")','const GardenRestore = preload("res://build/luoyang_estate_garden_20261029q_system01/garden_restore.gd")'+eol.decode()+'const Courts31dRestore = preload("'+RESTORE+'")'),
 (lines('\t\tentry = GardenRestore.arrive(compiled, String(id), extension, entry)\n'),lines('\t\tentry = GardenRestore.arrive(compiled, String(id), extension, entry)\n\tif entry.get("ok") != true and entry.get("error") == "REGION_SAVED_FOOT_BLOCKED":\n\t\tentry = Courts31dRestore.arrive(compiled, String(id), extension, entry)\n'))]
after={ENTRY:edit(entry,changes)}
old_manifest=json.loads(before[MANIFEST]);m=edit(before[MANIFEST],[(json.dumps(ENTRY)+': '+json.dumps(oldsha[ENTRY]),json.dumps(ENTRY)+': '+json.dumps(sha(after[ENTRY])))])
assert RESTORE not in old_manifest['runtime_modules']
start=m.index(b'  "runtime_modules": {');end=m.index(b'\n  }',start)
m=m[:end]+b',\n    '+json.dumps(RESTORE).encode()+b': '+json.dumps(sha(read(RESTORE))).encode()+m[end:]
tag='    "luoyang_civic_market_region_27d": '
text=m.decode();start=text.index(tag,text.index('"compiled_bindings"'))+len(tag)
old_binding,used=json.JSONDecoder().raw_decode(text[start:])
assert old_binding['sha256']=='c0a84079257b5bb2e5f8001144b5fbdf1067b2463c705eb0d4d8badfcb67d4a4'
new_binding=json.dumps(binding,ensure_ascii=False,indent=2).replace('\n','\n    ')
after[MANIFEST]=(text[:start]+new_binding+text[start+used:]).encode()
new_manifest=json.loads(after[MANIFEST]);assert len(new_manifest['runtime_modules'])==len(old_manifest['runtime_modules'])+1
for key,value in old_manifest['compiled_bindings'].items():
 if key!='luoyang_civic_market_region_27d':assert new_manifest['compiled_bindings'][key]==value
header=re.search(rb'const REGION27D_AUTHOR_SHA := "[a-f0-9]{64}"',before[ROUTER]).group(0)
assert oldsha[MANIFEST].encode() in header
after[ROUTER]=edit(before[ROUTER],[(header,b'const REGION27D_AUTHOR_SHA := "'+sha(after[MANIFEST]).encode()+b'"')])
old_ex=json.loads(before[EX]);row=copy.deepcopy(old_ex['owned'][ROUTER])
assert row['current_sha256']==oldsha[ROUTER]
old_snapshot=row['edges'][-1]['new_snapshot'];assert read(old_snapshot)==before[ROUTER]
row['current_sha256']=sha(after[ROUTER]);row['edges'].append({'path':ROUTER,'old_sha256':oldsha[ROUTER],'new_sha256':sha(after[ROUTER]),'old_snapshot':old_snapshot,'new_snapshot':SNAP,'whole_inverse':True,'replacements':hunks(before[ROUTER],after[ROUTER])})
text=before[EX].decode();marker='    '+json.dumps(ROUTER)+': ';start=text.index(marker)+len(marker)
_,used=json.JSONDecoder().raw_decode(text[start:]);new_row=json.dumps(row,ensure_ascii=False,indent=2).replace('\n','\n    ')
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
  data=source_update(before[p],known) if p.endswith('.json') else edit(before[p],[(oldsha[q],known[q]) for q in known if oldsha[q]!=known[q] and oldsha[q].encode() in before[p]])
  assert data!=before[p],('UNNECESSARY_TARGET',p)
  after[p]=data;known[p]=sha(data);pending.remove(p);progress=True
 if not pending:break
 assert progress,pending
assert len(after)==11 and not pending
names={p:p[6:].replace('/','__') for p in paths}
mode=sys.argv[-1]
if mode=='--emit-patch':
 print('*** Begin Patch')
 for p,data in after.items():
  if p.endswith('.gd'):
   print('*** Add File: '+(OUT/names[p]).as_posix())
   for line in data.decode().splitlines():print('+'+line)
 print('*** End Patch');sys.exit()
if mode=='--restore-eol-only':
 for p,data in after.items():
  if p.endswith('.gd'):
   target=OUT/names[p];actual=target.read_bytes()
   assert actual.replace(b'\r\n',b'\n')==data.replace(b'\r\n',b'\n')
   if actual!=data:target.write_bytes(data)
 print('Only source-template EOL restoration.');sys.exit()
assert mode=='--seal'
def put(name,data):
 target=OUT/name
 if target.exists():assert target.read_bytes()==data;return
 with target.open('xb') as file:file.write(data)
targets=[]
for p,data in after.items():
 name=names[p]
 if p.endswith('.gd'):assert (OUT/name).read_bytes()==data
 else:put(name,data)
 put(name+'.BEFORE',before[p]);put(name+'.diff',''.join(difflib.unified_diff(before[p].decode().splitlines(True),data.decode().splitlines(True),fromfile='a/'+p,tofile='b/'+p)).encode())
 targets.append({'target':'game/'+p[6:],'candidate':PREFIX+name,'before':PREFIX+name+'.BEFORE','old_sha256':oldsha[p],'new_sha256':sha(data),'before_bytes':len(before[p]),'bytes':len(data)})
new_ex=json.loads(after[EX]);assert new_ex['owned'][ROUTER]['edges'][:-1]==old_ex['owned'][ROUTER]['edges']
assert set(new_ex['source_sha256'])==set(old_ex['source_sha256'])|{SNAP}
for p,h in old_ex['source_sha256'].items():assert new_ex['source_sha256'][p]==h
modules={p:{'sha256':sha(read(p)),'bytes':len(read(p))} for p in [RESTORE,'res://build/city_neighborhoods_20261031d/luoyang_courts.json',binding['path']]}
receipt={'status':'FROZEN_ROOT_ONLY_ENTRY_CIVIC_DELTA11_NOT_DEPLOYED','targets':targets,'source_target_count':11,'new_runtime_sources':modules,'Civic_binding':binding,'original_other9_bindings_exact':True,'required_router_snapshot':{'target':'game/'+SNAP[6:],'candidate':PREFIX+names[ROUTER],'sha256':sha(after[ROUTER]),'bytes':len(after[ROUTER])},'region_modules_before':len(old_manifest['runtime_modules']),'region_modules_after':len(new_manifest['runtime_modules']),'old_EX_keys_and_edges_preserved':True,'new_EX_edges':1,'canonical_writes':0,'engine_runs':0,'save_API_calls':0}
put('receipt_READY.json',enc(receipt));put('hunks_READY.json',enc({'targets':[{'target':'game/'+p[6:],'replacements':hunks(before[p],after[p])}for p in paths if p.endswith('.gd')]}))
print(json.dumps({'receipt_sha256':sha(enc(receipt)),'Router':sha(after[ROUTER]),'RegionEntry':sha(after[ENTRY]),'Manifest':sha(after[MANIFEST]),'target_count':11}))
