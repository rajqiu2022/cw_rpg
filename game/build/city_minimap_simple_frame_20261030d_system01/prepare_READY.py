"""Frame-only candidate and existing source-pin successors, no engine/formal writes."""
from pathlib import Path
import hashlib,json,copy,difflib,re,sys
BASE=Path(__file__).resolve().parent; GAME=BASE.parents[1]; OUT=BASE/(sys.argv[1]if len(sys.argv)>1 else 'ready01')
assert OUT.parent==BASE and OUT.name.startswith('ready')
PREFIX='res://'+OUT.relative_to(GAME).as_posix()+'/'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p):return (GAME/p[6:]).read_bytes()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def once(b,o,n):
 o=o.encode()if isinstance(o,str)else o;n=n.encode()if isinstance(n,str)else n
 assert b.count(o)==1,(o[:100],b.count(o));return b.replace(o,n,1)
def edit(b,changes):
 result=b
 for o,n in changes:result=once(result,o,n)
 inverse=result
 for o,n in reversed(changes):inverse=once(inverse,n,o)
 assert inverse==b;return result
def hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True)
 for n in [3,6,12,24,48]:
  result=[{'old':''.join(aa[g[0][1]:g[-1][2]]),'new':''.join(bb[g[0][3]:g[-1][4]])}for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(n)]
  if all(a.count(r['old'].encode())==1 and b.count(r['new'].encode())==1 for r in result):
   assert edit(a,[(r['old'],r['new'])for r in result])==b;return result
 raise ValueError('nonunique hunk')
def create(name,data):
 with (OUT/name).open('xb')as f:f.write(data)
assert not OUT.exists()
prior=json.loads(read('res://build/luoyang_city_visual_minimap_20261030c_system01/ready02/receipt_READY.json'))
paths=['res://'+r['target'][5:]for r in prior['targets']];assert len(paths)==23
helper='res://build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd'
manifest='res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
router='res://scripts/autoload/scene_router.gd'
ex='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
ei='res://scripts/city/luoyang_execution_index_20261022ap.gd'
before={p:read(p)for p in paths};oldsha={p:sha(b)for p,b in before.items()}
assert oldsha[router].startswith('dfbd8dcd')and oldsha[manifest].startswith('09e6e032')
old_helper=read(helper);new_helper=(BASE/'city_minimap_READY.gd').read_bytes()
assert sha(old_helper).startswith('c125b513')
assert new_helper.split(b'\nfunc _draw() -> void:')[0]==old_helper
assert sha(read('res://build/luoyang_city_visual_minimap_20261030c_system01/visual_cache.gd')).startswith('e700d251')
old_pin=json.dumps(helper)+': '+json.dumps(sha(old_helper));new_pin=json.dumps(helper)+': '+json.dumps(sha(new_helper))
after={manifest:edit(before[manifest],[(old_pin,new_pin)])}
old_header=re.search(rb'const REGION27D_AUTHOR_SHA := "[a-f0-9]{64}"',before[router]).group(0)
new_header=b'const REGION27D_AUTHOR_SHA := "'+sha(after[manifest]).encode()+b'"'
after[router]=edit(before[router],[(old_header,new_header)])
old_ex=json.loads(before[ex]);row=copy.deepcopy(old_ex['owned'][router]);old_count=len(row['edges'])
assert row['current_sha256']==oldsha[router]
old_snapshot=row['edges'][-1]['new_snapshot'];assert read(old_snapshot)==before[router]
snapshot='res://build/luoyang_city_minimap_simple_frame_20261030d_snapshot01/scene_router.gd';row['current_sha256']=sha(after[router])
snapshot_file=GAME/snapshot[6:]
if snapshot_file.exists():assert snapshot_file.read_bytes()==after[router]
else:
 snapshot_file.parent.mkdir(parents=True,exist_ok=True)
 with snapshot_file.open('xb')as f:f.write(after[router])
assert snapshot.startswith('res://build/luoyang_')
row['edges'].append({'path':router,'old_sha256':oldsha[router],'new_sha256':sha(after[router]),'old_snapshot':old_snapshot,'new_snapshot':snapshot,'whole_inverse':True,'replacements':hunks(before[router],after[router])})
text=before[ex].decode();marker='    '+json.dumps(router)+': ';start=text.index(marker)+len(marker)
_,used=json.JSONDecoder().raw_decode(text[start:]);replacement=json.dumps(row,ensure_ascii=False,indent=2).replace('\n','\n    ')
text=text[:start]+replacement+text[start+used:];text=edit(text.encode(),[(old_pin,new_pin)]).decode()
start=text.index('  "source_sha256": {');end=text.index('\n  }',start);assert snapshot not in old_ex['source_sha256']
text=text[:end]+',\n    '+json.dumps(snapshot)+': '+json.dumps(sha(after[router]))+text[end:]
after[ex]=text.encode();current=json.loads(after[ex])
assert current['owned'][router]['edges'][:-1]==old_ex['owned'][router]['edges']
assert all(current['source_sha256'][p]==h for p,h in old_ex['source_sha256'].items()if p!=helper)
assert len(current['source_sha256'])==len(old_ex['source_sha256'])+1
after[ei]=edit(before[ei],[(oldsha[ex],sha(after[ex]))])
def source_update(raw,known):
 value=json.loads(raw);changes={}
 def walk(v):
  if isinstance(v,dict):
   for key,member in v.items():
    if key in ['source_sha256','legacy_source_sha256']and isinstance(member,dict):
     for p,h in member.items():
      if p==helper:assert h==sha(old_helper);changes[old_pin]=new_pin
      elif p in known and h==oldsha.get(p)and h!=known[p]:changes[json.dumps(p)+': '+json.dumps(h)]=json.dumps(p)+': '+json.dumps(known[p])
    else:walk(member)
  elif isinstance(v,list):
   for item in v:walk(item)
 walk(value);result=raw
 for o,n in changes.items():assert o.encode()in result;result=result.replace(o.encode(),n.encode())
 def keys(v):
  if isinstance(v,dict):return {k:keys(m)for k,m in v.items()}
  if isinstance(v,list):return [keys(m)for m in v]
  return None
 assert keys(value)==keys(json.loads(result));return result
known={p:sha(b)for p,b in after.items()};pending=[p for p in paths if p not in after]
def deps(p):return {q for q,h in oldsha.items()if q!=p and h.encode()in before[p]}
for _ in paths:
 progress=False
 for p in list(pending):
  if any(q in pending for q in deps(p)):continue
  if p.endswith('.json'):data=source_update(before[p],known)
  else:
   changes=[(oldsha[q],known[q])for q in known if known[q]!=oldsha[q]and oldsha[q].encode()in before[p]]
   data=edit(before[p],changes)if changes else before[p]
  if data!=before[p]:after[p]=data;known[p]=sha(data)
  pending.remove(p);progress=True
 if not pending:break
 assert progress,pending
assert not pending and len(after)==23
assert json.loads(before[manifest])['compiled_bindings']==json.loads(after[manifest])['compiled_bindings']
OUT.mkdir();create('before_city_minimap.gd',old_helper);create('scene_router.gd',after[router])
targets=[];patches=[]
for p,data in after.items():
 name=p[6:].replace('/','__');create(name,data)
 targets.append({'target':'game/'+p[6:],'candidate':'game/'+PREFIX[6:]+name,'old_sha256':oldsha[p],'new_sha256':sha(data),'bytes':len(data)})
 if p.endswith('.gd'):patches.append({'target':'game/'+p[6:],'replacements':hunks(before[p],data)})
module={'target':'game/'+helper[6:],'candidate':str((BASE/'city_minimap_READY.gd').relative_to(GAME.parent)).replace('\\','/'),'old_sha256':sha(old_helper),'new_sha256':sha(new_helper),'bytes':len(new_helper),'replacements':hunks(old_helper,new_helper)}
patches.append({'target':module['target'],'replacements':module['replacements']})
receipt={'status':'30D_SIMPLE_TRANSLUCENT_FRAME_CANDIDATES_NOT_DEPLOYED','targets':targets,'module_targets':[module],'source_target_count':23,'actual_existing_file_count':24,'Router_edges_before':old_count,'Router_edges_after':old_count+1,'old_EX_keys_retained':True,'only_new_EX_key':snapshot,'old_metadata_keysets_unchanged':True,'cache_Field_CT_garden_native_World_minimap_unchanged':True,'all_ten_bins_unchanged':True,'only_helper_change':'APPEND_LOCAL_DRAW_OVERRIDE','frame_fill_rgba':[0.035,0.07,0.085,0.5],'frame_border_rgba':[0.43,0.57,0.60,0.26],'frame_border_width_px':1,'frame_inset_grow_px':8,'canonical_writes':0,'engine_runs':0}
auth={'sources':{r['target']:{'sha256':r['new_sha256'],'bytes':r['bytes']}for r in targets+[module]},'new_modules':{'game/'+snapshot[6:]:{'sha256':sha(after[router]),'bytes':len(after[router])}}}
for name,value in [('receipt_READY.json',receipt),('hunks_READY.json',{'targets':patches}),('auth_READY.json',auth)]:create(name,enc(value))
print(json.dumps({'source_targets':23,'helper_targets':1,'actual_existing_file_count':24,'helper_sha256':sha(new_helper),'receipt_sha256':sha(enc(receipt)),'canonical_writes':0,'engine_runs':0}))
