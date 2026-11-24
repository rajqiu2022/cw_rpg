"""30h minimal source-pin candidate; immutable outputs, no canonical/engine/save IO."""
from pathlib import Path
import difflib,hashlib,json,sys

HERE=Path(__file__).resolve().parent
GAME=HERE.parents[1]
REPO=GAME.parent
OUT=HERE/'closure01_READY'
NATIVE='game/build/three_towns_world_20261029j_system01/native_sources.json'
REGISTRY='game/build/three_towns_world_20261029j_system01/town_registry.gd'
FIELD='game/build/four_settlements_20261030e_system01/field.gd'
BASE_NATIVE='068f3e619494118d724e4b1e151196c54e9bb8c7d155500967ff919ec27501be'
BASE_REGISTRY='e704506480fbd20c4b14feb2f13deafa80d626fd93249d419622cda3918c6ead'

def sha(b):return hashlib.sha256(b).hexdigest()
def data(p):return (REPO/p).read_bytes()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def resource(p):assert p.startswith('game/');return 'res://'+p[5:]
def once(b,a,z):
 a=a.encode() if isinstance(a,str) else a;z=z.encode() if isinstance(z,str) else z
 assert b.count(a)==1,('EXACT_REPLACEMENT',a[:120],b.count(a))
 return b.replace(a,z,1)
def hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True)
 for context in [3,6,12,24,48,10000]:
  rows=[{'old':''.join(aa[g[0][1]:g[-1][2]]),'new':''.join(bb[g[0][3]:g[-1][4]])} for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context)]
  if all(a.count(r['old'].encode())==1 and b.count(r['new'].encode())==1 for r in rows):
   forward=a
   for row in rows:forward=once(forward,row['old'],row['new'])
   assert forward==b
   for row in reversed(rows):forward=once(forward,row['new'],row['old'])
   assert forward==a
   return rows
 raise AssertionError('NONUNIQUE_HUNK')
def fact(p):return {'sha256':sha(data(p)),'bytes':len(data(p))}
def validate(p,expected):
 got=fact(p)
 assert got=={'sha256':expected['sha256'].lower(),'bytes':expected['bytes']},('INPUT_CHANGED',p,got,expected)
 return got

assert len(sys.argv) in [2,3],'Require h building manifest; optional exact Root road-visual manifest'
assert not OUT.exists(),'Immutable closure output exists; never overwrite'
before={FIELD:data(FIELD),NATIVE:data(NATIVE),REGISTRY:data(REGISTRY)}
assert sha(before[NATIVE])==BASE_NATIVE and sha(before[REGISTRY])==BASE_REGISTRY,'FORMAL_HEAD_MOVED'
old_native=json.loads(before[NATIVE]);assert len(old_native['sources'])==151
old_field=before[FIELD];ready=(HERE/'field_READY.gd').read_bytes()
assert old_field.count(b'\r\n')==old_field.count(b'\n') and b'\r\n' in old_field
after={FIELD:ready.replace(b'\r\n',b'\n').replace(b'\n',b'\r\n')}
new_modules={'game/'+(HERE/'adult_visual.gd').relative_to(GAME).as_posix():fact('game/'+(HERE/'adult_visual.gd').relative_to(GAME).as_posix())}
runtime_inputs={};manifest_inputs={}
for argument in sys.argv[1:]:
 path=Path(argument).resolve();assert path.is_relative_to(REPO)
 manifest_inputs[path.relative_to(REPO).as_posix()]={'sha256':sha(path.read_bytes()),'bytes':len(path.read_bytes())}
 manifest=json.loads(path.read_bytes())
 for row in manifest.get('targets',[]):
  target=row['target'];assert target not in before and target.startswith('game/')
  old=data(target);new=data(row['candidate'])
  assert sha(old)==row['old_sha256'].lower() and sha(new)==row['new_sha256'].lower()
  assert len(new)==row['bytes']
  before[target]=old;after[target]=new
 for target,expected in manifest.get('new_modules',{}).items():
  assert target not in new_modules and target.startswith(('game/build/','game/art/')) and '..' not in target
  new_modules[target]=validate(target,expected)
 for target,expected in manifest.get('runtime_inputs',{}).items():
  runtime_inputs[target]=validate(target,expected)

# Update only actual changed existing consumers; append genuine runtime inputs.
ntext=before[NATIVE]
for target,new in after.items():
 p=resource(target);assert p in old_native['sources'] and old_native['sources'][p]==sha(before[target])
 ntext=once(ntext,json.dumps(p)+': '+json.dumps(sha(before[target])),json.dumps(p)+': '+json.dumps(sha(new)))
new_pins={}
for target,expected in {**new_modules,**runtime_inputs}.items():
 p=resource(target)
 if p in old_native['sources']:
  assert old_native['sources'][p]==expected['sha256'],('UNDECLARED_EXISTING_MUTATION',target)
 else:new_pins[p]=expected['sha256']
start=ntext.index(b'  "sources": {');end=ntext.index(b'\n  }',start)
addition=''.join(',\n    '+json.dumps(p)+': '+json.dumps(h) for p,h in new_pins.items()).encode()
ntext=ntext[:end]+addition+ntext[end:]
after[NATIVE]=ntext
new_native=json.loads(ntext)
assert set(new_native['sources'])==set(old_native['sources'])|set(new_pins)
for p,h in old_native['sources'].items():
 target='game/'+p[6:]
 assert new_native['sources'][p]==(sha(after[target]) if target in after else h)
after[REGISTRY]=once(before[REGISTRY],BASE_NATIVE,sha(ntext))
assert once(after[REGISTRY],sha(ntext),BASE_NATIVE)==before[REGISTRY]

protected=[
 'game/scripts/field/npc_node.gd','game/data/npcs/npc_catalog.tres',
 'game/data/scenes/linxi_tutorial.tres','game/data/scenes/linxi_village_center.tres',
 'game/data/scenes/linxi_village_scrollmap.tres','game/scripts/autoload/scene_router.gd',
 'game/data/scenes/ch1_s1_road.tres','game/data/maps/ch1_s1_road_layout_v5.tres',
 'game/build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json',
 'game/build/four_settlements_20261030e_system01/minimap.gd',
 'game/build/linxi_road_portrait_20261030g_source01/road_minimap.gd']
protected={p:fact(p) for p in protected}
OUT.mkdir()
targets=[];patches=[];baseline={}
for target,new in after.items():
 old=before[target];assert old!=new,('UNNECESSARY_TARGET',target)
 name=target[5:].replace('/','__');candidate=OUT/name;backup=OUT/'before'/target
 backup.parent.mkdir(parents=True,exist_ok=True)
 with backup.open('xb') as f:f.write(old)
 with candidate.open('xb') as f:f.write(new)
 assert backup.read_bytes()==old and candidate.read_bytes()==new
 targets.append({'target':target,'candidate':candidate.relative_to(REPO).as_posix(),'old_sha256':sha(old),'new_sha256':sha(new),'bytes':len(new),'whole_byte_inverse':True})
 patches.append({'target':target,'replacements':hunks(old,new)})
 baseline[target]={'sha256':sha(old),'bytes':len(old),'mtime_ns':str((REPO/target).stat().st_mtime_ns),'backup':backup.relative_to(REPO).as_posix()}
receipt={'status':'30H_CANDIDATE_ONLY_ROOT_DEPLOYS_AND_RUNS_ENGINE','targets':targets,'actual_existing_file_count':len(targets),'new_modules':new_modules,'runtime_inputs':runtime_inputs,'manifest_inputs':manifest_inputs,'native_sources_before':151,'native_sources_after':len(new_native['sources']),'all_151_old_paths_retained':True,'old_native_untargeted_values_retained':True,'only_registry_sha_constant_changed':True,'Router_and_legacy_source_packets_unchanged':True,'existing_NPCNode_and_original_scene_data_unchanged':True,'source_before':baseline,'immutable_inputs':protected,'canonical_writes':0,'engine_runs':0,'save_contents_read':False,'save_writes':0}
auth={'sources':{r['target']:{'sha256':r['new_sha256'],'bytes':r['bytes']} for r in targets},'new_modules':new_modules,'runtime_inputs':runtime_inputs,'immutable_inputs':protected}
for name,value in [('receipt_READY.json',receipt),('hunks_READY.json',{'targets':patches}),('auth_READY.json',auth)]:
 with (OUT/name).open('xb') as f:f.write(enc(value))
print(json.dumps({'targets':len(targets),'native_before':151,'native_after':len(new_native['sources']),'new_modules':len(new_modules),'native_sha256':sha(ntext),'registry_sha256':sha(after[REGISTRY]),'field_sha256':sha(after[FIELD]),'receipt_sha256':sha(enc(receipt)),'hunks_sha256':sha(enc({'targets':patches})),'auth_sha256':sha(enc(auth)),'canonical_writes':0,'engine_runs':0}))
