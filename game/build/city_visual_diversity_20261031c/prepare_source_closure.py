"""Current exact visual-hook succession. Candidates only; no canonical writes."""
from pathlib import Path
import copy,difflib,hashlib,json,re,sys
BASE=Path(__file__).resolve().parent
REPO=BASE.parents[2]
OUT=BASE/'closure_READY'
PREFIX='game/build/city_visual_diversity_20261031c/closure_READY/'
SNAP='res://build/luoyang_city_visual_diversity_20261031c_snapshot01/scene_router.gd'
HELPER='res://build/luoyang_garden_city_minimap_20261030b_system01/garden_visual.gd'
MANIFEST='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
ROUTER='res://scripts/autoload/scene_router.gd'
EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
EI='res://scripts/city/luoyang_execution_index_20261022ap.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return (REPO/('game/'+p[6:])).read_bytes()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def once(b,o,n):
 o=o.encode() if isinstance(o,str) else o;n=n.encode() if isinstance(n,str) else n
 assert b.count(o)==1,(o[:100],b.count(o));return b.replace(o,n,1)
def edit(b,changes):
 a=b
 for o,n in changes:a=once(a,o,n)
 inverse=a
 for o,n in reversed(changes):inverse=once(inverse,n,o)
 assert inverse==b
 return a
def hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True)
 for context in [3,6,12,24,48]:
  rows=[{'old':''.join(aa[g[0][1]:g[-1][2]]),'new':''.join(bb[g[0][3]:g[-1][4]])} for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context)]
  if all(a.count(r['old'].encode())==1 and b.count(r['new'].encode())==1 for r in rows):
   assert edit(a,[(r['old'],r['new']) for r in rows])==b
   return rows
 raise AssertionError('nonunique inverse')
def shape(v):
 if isinstance(v,dict):return {k:shape(x) for k,x in v.items()}
 if isinstance(v,list):return [shape(x) for x in v]
 return None
prior=json.loads((REPO/'game/build/luoyang_garden_city_minimap_20261030b_system01/residual04/closure_READY/receipt_READY.json').read_bytes())
paths=['res://'+r['target'][5:] for r in prior['targets']]+[HELPER]
assert len(paths)==24 and len(set(paths))==24
before={p:read(p) for p in paths};oldsha={p:sha(b) for p,b in before.items()}
helper=before[HELPER]
eol='\r\n' if helper.count(b'\r\n')==helper.count(b'\n') else '\n'
def line(s):return s.replace('\n',eol)
helper_changes=[
 ('static func handles(region: Dictionary) -> bool: return Old.handles(region)', 'static func handles(region: Dictionary) -> bool: return Old.handles(region) or String(region.get("id", "")) == "luoyang_civic_market_region_27d"'),
 ('return not (handles(region) and String(row.get("id", "")) == "rear_axis")','return not (Old.handles(region) and String(row.get("id", "")) == "rear_axis")'),
 (line('\tvar spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPEC))\n'),line('\tif String(region.get("id", "")) == "luoyang_civic_market_region_27d":\n\t\tfor path: String in ["res://build/city_visual_diversity_20261031c/district_visuals.gd", "res://build/city_visual_diversity_20261031c/district_patches.json", "res://build/city_visual_diversity_20261031c/district_ground_edge.gdshader"]:\n\t\t\tif first.get(path) != FileAccess.get_sha256(path): return false\n\t\treturn preload("res://build/city_visual_diversity_20261031c/district_visuals.gd").install_luoyang(field, region)\n\tvar spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SPEC))\n'))]
after={HELPER:edit(helper,helper_changes)}
modules={}
for name in ['district_visuals.gd','district_patches.json','district_ground_edge.gdshader']:
 p='res://build/city_visual_diversity_20261031c/'+name;b=read(p)
 modules[p]={'sha256':sha(b),'bytes':len(b)}
old_manifest=json.loads(before[MANIFEST]);m=edit(before[MANIFEST],[(json.dumps(HELPER)+': '+json.dumps(oldsha[HELPER]),json.dumps(HELPER)+': '+json.dumps(sha(after[HELPER])))])
start=m.index(b'  "runtime_modules": {');end=m.index(b'\n  }',start)
assert all(p not in old_manifest['runtime_modules'] for p in modules)
addition=''.join(',\n    '+json.dumps(p)+': '+json.dumps(f['sha256']) for p,f in modules.items()).encode()
m=m[:end]+addition+m[end:];after[MANIFEST]=m
new_manifest=json.loads(m)
assert len(new_manifest['runtime_modules'])==len(old_manifest['runtime_modules'])+3
assert {k:v for k,v in old_manifest.items() if k!='runtime_modules'}=={k:v for k,v in new_manifest.items() if k!='runtime_modules'}
header=re.search(rb'const REGION27D_AUTHOR_SHA := "[a-f0-9]{64}"',before[ROUTER]).group(0)
assert oldsha[MANIFEST].encode() in header
after[ROUTER]=edit(before[ROUTER],[(header,b'const REGION27D_AUTHOR_SHA := "'+sha(m).encode()+b'"')])
old_ex=json.loads(before[EX]);row=copy.deepcopy(old_ex['owned'][ROUTER])
assert row['current_sha256']==oldsha[ROUTER]
old_snapshot=row['edges'][-1]['new_snapshot'];assert read(old_snapshot)==before[ROUTER]
row['current_sha256']=sha(after[ROUTER]);row['edges'].append({'path':ROUTER,'old_sha256':oldsha[ROUTER],'new_sha256':sha(after[ROUTER]),'old_snapshot':old_snapshot,'new_snapshot':SNAP,'whole_inverse':True,'replacements':hunks(before[ROUTER],after[ROUTER])})
text=before[EX].decode();marker='    '+json.dumps(ROUTER)+': ';start=text.index(marker)+len(marker)
_,used=json.JSONDecoder().raw_decode(text[start:]);new_row=json.dumps(row,ensure_ascii=False,indent=2).replace('\n','\n    ')
text=text[:start]+new_row+text[start+used:]
text=edit(text.encode(),[(json.dumps(HELPER)+': '+json.dumps(oldsha[HELPER]),json.dumps(HELPER)+': '+json.dumps(sha(after[HELPER])))])
start=text.index(b'  "source_sha256": {');end=text.index(b'\n  }',start)
assert SNAP not in old_ex['source_sha256']
after[EX]=text[:end]+b',\n    '+json.dumps(SNAP).encode()+b': '+json.dumps(sha(after[ROUTER])).encode()+text[end:]
after[EI]=edit(before[EI],[(oldsha[EX],sha(after[EX]))])
def source_update(raw,known):
 value=json.loads(raw);changes={}
 def walk(v):
  if isinstance(v,dict):
   for k,member in v.items():
    if k in ['source_sha256','legacy_source_sha256'] and isinstance(member,dict):
     for p,h in member.items():
      if p in known and h==oldsha.get(p) and h!=known[p]:changes[json.dumps(p)+': '+json.dumps(h)]=json.dumps(p)+': '+json.dumps(known[p])
    else:walk(member)
  elif isinstance(v,list):
   for x in v:walk(x)
 walk(value);result=raw
 for o,n in changes.items():
  assert o.encode() in result;result=result.replace(o.encode(),n.encode())
 assert shape(value)==shape(json.loads(result))
 return result
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
assert not pending and len(after)==24
names={p:p[6:].replace('/','__') for p in paths}
if sys.argv[-1]=='--emit-patch':
 print('*** Begin Patch')
 for p,data in after.items():
  if p.endswith('.gd'):
   print('*** Add File: '+(OUT/names[p]).as_posix())
   for s in data.decode().splitlines():print('+'+s)
   print('+')
 print('*** End Patch')
 sys.exit()
assert sys.argv[-1]=='--seal' and OUT.is_dir()
def put(name,b):
 with (OUT/name).open('xb') as f:f.write(b)
targets=[]
for p,data in after.items():
 name=names[p]
 if p.endswith('.gd'):
  assert (OUT/name).read_bytes()==data,('PATCH_BYTES_DIFFER',p)
 else:put(name,data)
 put(name+'.BEFORE',before[p])
 put(name+'.diff',''.join(difflib.unified_diff(before[p].decode().splitlines(keepends=True),data.decode().splitlines(keepends=True),fromfile='a/'+p,tofile='b/'+p)).encode())
 targets.append({'target':'game/'+p[6:],'candidate':PREFIX+name,'old_sha256':oldsha[p],'new_sha256':sha(data),'bytes':len(data),'before':PREFIX+name+'.BEFORE'})
new_ex=json.loads(after[EX]);assert new_ex['owned'][ROUTER]['edges'][:-1]==old_ex['owned'][ROUTER]['edges']
assert set(new_ex['source_sha256'])==set(old_ex['source_sha256'])|{SNAP}
for p,h in old_ex['source_sha256'].items():assert new_ex['source_sha256'][p]==(sha(after[HELPER]) if p==HELPER else h)
native=json.loads(read('res://build/three_towns_world_20261029j_system01/native_sources.json'))
domain=json.loads((BASE/'district_manifest_READY.json').read_bytes());water=json.loads((BASE/'npc_water_manifest_READY.json').read_bytes())
final={r['target']:r for r in water['targets']}
for r in domain['targets']:
 if r['target'].endswith('/region_field.gd'):continue
 final[r['target']]=r
for p,r in final.items():
 resource='res://'+p[5:]
 assert resource not in native['sources'] and resource not in old_manifest['runtime_modules']
receipt={'status':'CURRENT_EXACT_GARDEN_HOOK_CLOSURE_CANDIDATES_NOT_DEPLOYED','targets':targets,
 'source_target_count':24,'new_modules':{'game/'+p[6:]:f for p,f in modules.items()},
 'required_router_snapshot':{'target':'game/'+SNAP[6:],'candidate':PREFIX+names[ROUTER],'sha256':sha(after[ROUTER]),'bytes':len(after[ROUTER])},
 'superseded_do_not_apply':'game/build/city_visual_diversity_20261031c/luoyang_region_field_DISTRICT_READY.gd',
 'other_final_domain_targets':list(final.values()),'native_required_existing_updates':{},'native_required_new_keys':{},
 'native_note':'Existing town source_valid is not called on the separate Xiang/Jinling dispatch. No changed path exists in current 202-key native map. No town_registry/native change is required for this closure.',
 'region_modules_before':len(old_manifest['runtime_modules']),'region_modules_after':len(new_manifest['runtime_modules']),
 'EX_edges_before':len(old_ex['owned'][ROUTER]['edges']),'EX_edges_after':len(row['edges']),
 'old_EX_keys_retained':True,'all_ten_bin_bindings_exact':True,'RegionField_exact':sha(read('res://build/luoyang_regions_20261027d_source01/region_field.gd')),
 'canonical_writes':0,'engine_runs':0,'save_reads':0}
put('receipt_READY.json',enc(receipt));put('hunks_READY.json',enc({'targets':[{'target':'game/'+p[6:],'replacements':hunks(before[p],after[p])} for p in paths if p.endswith('.gd')]}))
print(json.dumps({'receipt_sha256':sha(enc(receipt)),'targets':len(targets),'manifest_sha256':sha(after[MANIFEST]),'router_sha256':sha(after[ROUTER]),'helper_sha256':sha(after[HELPER]),'native_delta':0,'engine_runs':0}))
