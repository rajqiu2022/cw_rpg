"""Deterministic source-pin succession candidates. Zero canonical writes/engine runs."""
from pathlib import Path
import copy,difflib,hashlib,json,re,sys
BASE=Path(__file__).resolve().parent;GAME=BASE.parents[1];REPO=GAME.parent
OUT=BASE/'closure01_READY'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return (GAME/p[6:]).read_bytes()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def once(b,o,n):
 o=o.encode() if isinstance(o,str) else o;n=n.encode() if isinstance(n,str) else n
 assert b.count(o)==1,(o[:100],b.count(o));return b.replace(o,n,1)
def edit(b,changes):
 a=b
 for o,n in changes:a=once(a,o,n)
 inverse=a
 for o,n in reversed(changes):inverse=once(inverse,n,o)
 assert inverse==b;return a
def hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True)
 for context in [3,6,12,24,48]:
  rows=[{'old':''.join(aa[g[0][1]:g[-1][2]]),'new':''.join(bb[g[0][3]:g[-1][4]])} for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context)]
  if all(a.count(r['old'].encode())==1 and b.count(r['new'].encode())==1 for r in rows):
   assert edit(a,[(r['old'],r['new']) for r in rows])==b;return rows
 raise AssertionError('Nonunique hunk')
def keys(v):
 if isinstance(v,dict):return {k:keys(m) for k,m in v.items()}
 if isinstance(v,list):return [keys(m) for m in v]
 return None
def put(name,b):
 with (OUT/name).open('xb') as f:f.write(b)

assert not OUT.exists(),'Immutable closure output already exists'
baseline=json.loads((BASE/'baseline_sources_before.json').read_bytes())
paths=['res://'+p[5:] for p in baseline['sources']]
assert len(paths)==28
before={p:read(p) for p in paths};oldsha={p:sha(b) for p,b in before.items()}
for p in paths:assert oldsha[p]==baseline['sources']['game/'+p[6:]]['sha256'],('SOURCE_BASELINE_MOVED',p)
router='res://scripts/autoload/scene_router.gd';ex='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';ei='res://scripts/city/luoyang_execution_index_20261022ap.gd'
manifest='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
native='res://build/three_towns_world_20261029j_system01/native_sources.json';registry='res://build/three_towns_world_20261029j_system01/town_registry.gd'
avatar='res://build/player_portrait_minimap_20261030f_system01/portrait_marker.gd'
snapshot='res://build/luoyang_player_portrait_minimap_20261030f_snapshot01/scene_router.gd'
helpers={
 'res://build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd':'canonical_city_minimap_READY.gd',
 'res://build/three_settlements_20261030e_system01/city_minimap.gd':'three_city_minimap_READY.gd',
 'res://build/four_settlements_20261030e_system01/minimap.gd':'four_minimap_READY02.gd'}
after={p:(BASE/name).read_bytes() for p,name in helpers.items()}
for p,b in list(after.items()):
 # Preserve the actual canonical helper's uniform CRLF, not a whole-file EOL
 # rewrite just because its separately parsed READY template uses LF.
 if before[p].count(b'\r\n')==before[p].count(b'\n') and b'\r\n' in before[p]:
  after[p]=b.replace(b'\r\n',b'\n').replace(b'\n',b'\r\n')
for p,b in after.items():
 assert b!=before[p] and b.count(b'PlayerPortraitMarker')==1
 assert b.count(b'_portrait_marker=PortraitMarker.new()')==1
 assert b.count(b'state["player_portrait_marker"]')==1 and b.count(b'state["legacy_arrow_visible"]')==1
 assert b.count(b'_marker.hide()')==1
 for function in ['_draw','_build_plan']:
  def body(raw):
   text=raw.decode().replace('\r\n','\n');start=text.index('\nfunc '+function+'(');end=text.find('\nfunc ',start+1)
   return text[start:end if end>=0 else None].strip()
  assert body(b)==body(before[p]),('FRAME_OR_CACHE_BODY_CHANGED',p,function)
map_rows=[];map_modules={}
if len(sys.argv)>1:
 map_manifest=Path(sys.argv[1]);value=json.loads(map_manifest.read_bytes())
 map_rows=value['targets'] if isinstance(value,dict) else value
 map_modules=value.get('new_modules',{}) if isinstance(value,dict) else {}
 for row in map_rows:
  p='res://'+row['target'][5:];old=read(p);new=(REPO/row['candidate']).read_bytes()
  assert sha(old)==row['old_sha256'].lower() and sha(new)==row['new_sha256'].lower()
  assert p not in paths and p!=avatar
  paths.append(p);before[p]=old;oldsha[p]=sha(old);after[p]=new
 for target,fact in map_modules.items():
  assert target.startswith('game/build/') and '..' not in target
  p='res://'+target[5:];data=read(p)
  assert sha(data)==fact['sha256'].lower() and len(data)==fact['bytes']

# Preserve every one of the latest 125 source paths. Update only changed files
# from this shared closure; add the one newly consumed portrait implementation.
old_native=json.loads(before[native]);assert len(old_native['sources'])==125
assert old_native['sources']==baseline['old_native_sources']
ntext=before[native]
for p,b in after.items():
 if p in old_native['sources']:
  assert old_native['sources'][p]==oldsha[p]
  ntext=once(ntext,json.dumps(p)+': '+json.dumps(oldsha[p]),json.dumps(p)+': '+json.dumps(sha(b)))
for row in map_rows:
 p='res://'+row['target'][5:];assert p in old_native['sources'],('MAP_TARGET_NOT_IN_NATIVE125',p)
assert avatar not in old_native['sources']
new_native_modules={avatar:{'sha256':sha(read(avatar)),'bytes':len(read(avatar))}}
for target,fact in map_modules.items():
 p='res://'+target[5:];assert p not in old_native['sources']
 new_native_modules[p]={'sha256':fact['sha256'].lower(),'bytes':fact['bytes']}
nstart=ntext.index(b'  "sources": {');nend=ntext.index(b'\n  }',nstart)
addition=''.join(',\n    '+json.dumps(p)+': '+json.dumps(fact['sha256']) for p,fact in new_native_modules.items()).encode()
ntext=ntext[:nend]+addition+ntext[nend:]
after[native]=ntext;new_native=json.loads(ntext)
assert len(new_native['sources'])==125+len(new_native_modules) and set(new_native['sources'])==set(old_native['sources'])|set(new_native_modules)
for p,h in old_native['sources'].items():
 assert new_native['sources'][p]==(sha(after[p]) if p in after else h)
after[registry]=edit(before[registry],[(oldsha[native],sha(ntext))])

# The canonical minimap is already in this exact module map. New avatar code is
# sealed there, not sprayed into legacy_source_sha256 or immutable old packets.
canonical=next(iter(helpers))
mtext=edit(before[manifest],[(json.dumps(canonical)+': '+json.dumps(oldsha[canonical]),json.dumps(canonical)+': '+json.dumps(sha(after[canonical])))])
old_manifest=json.loads(before[manifest]);assert avatar not in old_manifest['runtime_modules']
start=mtext.index(b'  "runtime_modules": {');end=mtext.index(b'\n  }',start)
mtext=mtext[:end]+b',\n    '+json.dumps(avatar).encode()+b': '+json.dumps(sha(read(avatar))).encode()+mtext[end:]
after[manifest]=mtext
assert json.loads(mtext)['compiled_bindings']==old_manifest['compiled_bindings']
old_header=re.search(rb'const REGION27D_AUTHOR_SHA := "[a-f0-9]{64}"',before[router]).group(0)
after[router]=edit(before[router],[(old_header,b'const REGION27D_AUTHOR_SHA := "'+sha(mtext).encode()+b'"')])
old_ex=json.loads(before[ex]);row=copy.deepcopy(old_ex['owned'][router]);old_count=len(row['edges'])
assert old_count==25 and row['current_sha256']==oldsha[router] and read(row['edges'][-1]['new_snapshot'])==before[router]
row['current_sha256']=sha(after[router])
row['edges'].append({'path':router,'old_sha256':oldsha[router],'new_sha256':sha(after[router]),'old_snapshot':row['edges'][-1]['new_snapshot'],'new_snapshot':snapshot,'whole_inverse':True,'replacements':hunks(before[router],after[router])})
text=before[ex].decode();marker='    '+json.dumps(router)+': ';start=text.index(marker)+len(marker)
_,used=json.JSONDecoder().raw_decode(text[start:]);replacement=json.dumps(row,ensure_ascii=False,indent=2).replace('\n','\n    ')
text=text[:start]+replacement+text[start+used:]
text=edit(text.encode(),[(json.dumps(canonical)+': '+json.dumps(oldsha[canonical]),json.dumps(canonical)+': '+json.dumps(sha(after[canonical])))])
start=text.index(b'  "source_sha256": {');end=text.index(b'\n  }',start);assert snapshot not in old_ex['source_sha256']
text=text[:end]+b',\n    '+json.dumps(snapshot).encode()+b': '+json.dumps(sha(after[router])).encode()+text[end:]
after[ex]=text;new_ex=json.loads(text)
assert new_ex['owned'][router]['edges'][:-1]==old_ex['owned'][router]['edges']
assert set(new_ex['source_sha256'])==set(old_ex['source_sha256'])|{snapshot}
for p,h in old_ex['source_sha256'].items():assert new_ex['source_sha256'][p]==(sha(after[canonical]) if p==canonical else h)
after[ei]=edit(before[ei],[(oldsha[ex],sha(after[ex]))])
def source_update(raw,known):
 original=json.loads(raw);changes={}
 def walk(v):
  if isinstance(v,dict):
   for key,member in v.items():
    if key in ['source_sha256','legacy_source_sha256'] and isinstance(member,dict):
     for p,h in member.items():
      if p in known and h==oldsha.get(p) and h!=known[p]:changes[json.dumps(p)+': '+json.dumps(h)]=json.dumps(p)+': '+json.dumps(known[p])
    else:walk(member)
  elif isinstance(v,list):
   for member in v:walk(member)
 walk(original);result=raw
 for old,new in changes.items():
  assert old.encode() in result;result=result.replace(old.encode(),new.encode())
 assert keys(original)==keys(json.loads(result));return result
known={p:sha(b) for p,b in after.items()};pending=[p for p in paths if p not in after]
def deps(p):return {q for q,h in oldsha.items() if q!=p and h.encode() in before[p]}
for _ in paths:
 progress=False
 for p in list(pending):
  if any(q in pending for q in deps(p)):continue
  if p.endswith('.json'):data=source_update(before[p],known)
  else:
   changes=[(oldsha[q],known[q]) for q in known if known[q]!=oldsha[q] and oldsha[q].encode() in before[p]]
   data=edit(before[p],changes) if changes else before[p]
  assert data!=before[p],('UNNECESSARY_TARGET',p)
  after[p]=data;known[p]=sha(data);pending.remove(p);progress=True
 if not pending:break
 assert progress,pending
assert not pending and len(after)==28+len(map_rows)

OUT.mkdir();snapshot_path=GAME/snapshot[6:]
if snapshot_path.exists():assert snapshot_path.read_bytes()==after[router]
else:
 snapshot_path.parent.mkdir(parents=True,exist_ok=True)
 with snapshot_path.open('xb') as f:f.write(after[router])
targets=[];patches=[]
for p,b in after.items():
 name=p[6:].replace('/','__');put(name,b)
 targets.append({'target':'game/'+p[6:],'candidate':'game/'+OUT.relative_to(GAME).as_posix()+'/'+name,'old_sha256':oldsha[p],'new_sha256':sha(b),'bytes':len(b),'whole_byte_inverse':True})
 patches.append({'target':'game/'+p[6:],'replacements':hunks(before[p],b)})
new_modules={'game/'+p[6:]:fact for p,fact in new_native_modules.items()}
new_modules['game/'+snapshot[6:]]={'sha256':sha(after[router]),'bytes':len(after[router])}
receipt={'status':'30F_PORTRAIT_AND_AUTHORIZED_MAP_CANDIDATES_NOT_DEPLOYED','targets':targets,'actual_existing_file_count':len(targets),'new_modules':new_modules,'Router_edges_before':25,'Router_edges_after':26,'old_EX_edges_and_keys_retained':True,'only_new_EX_key':snapshot,'old_legacy_metadata_keysets_unchanged':True,'native_sources_before':125,'native_sources_after':len(new_native['sources']),'all_125_paths_retained':True,'new_native_sources':new_native_modules,'old_Luoyang_bins_cache_World_unchanged':True,'portrait_only_helpers':list(helpers),'map_targets':[r['target'] for r in map_rows],'canonical_writes':0,'engine_runs':0,'save_contents_read':False,'save_writes':0}
auth={'sources':{r['target']:{'sha256':r['new_sha256'],'bytes':r['bytes']} for r in targets},'new_modules':receipt['new_modules']}
for name,value in [('receipt_READY.json',receipt),('hunks_READY.json',{'targets':patches}),('auth_READY.json',auth)]:put(name,enc(value))
print(json.dumps({'targets':len(targets),'native':len(new_native['sources']),'router_sha256':sha(after[router]),'native_sha256':sha(after[native]),'registry_sha256':sha(after[registry]),'receipt_sha256':sha(enc(receipt)),'hunks_sha256':sha(enc({'targets':patches})),'auth_sha256':sha(enc(auth)),'canonical_writes':0,'engine_runs':0}))
