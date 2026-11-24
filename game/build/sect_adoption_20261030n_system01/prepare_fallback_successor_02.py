"""Producer-authorized neutral fallback only + two mandatory SHA headers.
No original draft, geometry, engine/save/formal edits. Three exact inverse hunks.
"""
from pathlib import Path
import difflib,hashlib,json
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
FIELD=HERE/'sect_adoption_field.gd'
NATIVE=GAME/'build/three_towns_world_20261029j_system01/native_sources.json'
REG=GAME/'build/three_towns_world_20261029j_system01/town_registry.gd'
def sha(b):return hashlib.sha256(b).hexdigest()
def put(name,b):
 with (HERE/name).open('xb') as f:f.write(b)
def once(b,old,new):assert b.count(old)==1;return b.replace(old,new,1)
def hunks(a,b):
 aa=a.decode().splitlines(keepends=True);bb=b.decode().splitlines(keepends=True)
 for context in [3,5,10,10000]:
  rows=[{'old':''.join(aa[g[0][1]:g[-1][2]]),'new':''.join(bb[g[0][3]:g[-1][4]])} for g in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context)]
  if all(a.count(r['old'].encode())==1 and b.count(r['new'].encode())==1 for r in rows):
   proof=a
   for r in rows:proof=proof.replace(r['old'].encode(),r['new'].encode(),1)
   assert proof==b
   for r in reversed(rows):proof=proof.replace(r['new'].encode(),r['old'].encode(),1)
   assert proof==a
   return rows
 raise AssertionError('NONUNIQUE_HUNK')
field=FIELD.read_bytes();native=NATIVE.read_bytes();reg=REG.read_bytes()
assert sha(field)=='c7af8219cb35ff6cfb9a4cd81da1c7326197afa243a18957dbd4ab5d9ed075b1'
assert sha(native)=='7cd9ca0556ee0e9c9e3b40b4dd08d7e466c2e062dffbfa779a9ff365e7b1e73b'
assert sha(reg)=='f3c241a47492f8429bad0c6638665dfa38b78956d5e4e86bc9f3fee78d5e8ec0'
old=b'text=str(nearest.get_meta("label")) if nearest!=null else str(native_town.layout.description)'
new='text=str(nearest.get_meta("label")) if nearest!=null else "WASD移动，靠近人物或出入口按空格交互。"'.encode()
new_field=once(field,old,new)
new_native=once(native,sha(field).encode(),sha(new_field).encode())
new_reg=once(reg,sha(native).encode(),sha(new_native).encode())
old_dict=json.loads(native);new_dict=json.loads(new_native)
field_uri='res://build/sect_adoption_20261030n_system01/sect_adoption_field.gd'
assert len(old_dict['sources'])==len(new_dict['sources'])==200
assert [k for k in old_dict['sources'] if old_dict['sources'][k]!=new_dict['sources'][k]]==[field_uri]
targets=[]
for path,before,after,name in [(FIELD,field,new_field,'FALLBACK_02_field_READY.gd'),(NATIVE,native,new_native,'FALLBACK_02_native_sources_READY.json'),(REG,reg,new_reg,'FALLBACK_02_town_registry_READY.gd')]:
 put(name,after)
 targets.append({'target':path.relative_to(GAME.parent).as_posix(),'candidate':'game/build/sect_adoption_20261030n_system01/'+name,'old_sha256':sha(before),'new_sha256':sha(after),'bytes':len(after),'replacements':hunks(before,after),'whole_byte_inverse':True})
receipt={'schema_version':1,'status':'ROOT_AUTHORIZED_NEUTRAL_FALLBACK_SOURCE_CANDIDATE_NOT_ENGINE_RUN','targets':targets,'new_modules':{},'only_runtime_change':'No-nearest-object fallback becomes WASD移动，靠近人物或出入口按空格交互。','original_nearest_object_text_unchanged':True,'original_draft_description_and_sources_unchanged':True,'native200_keys_preserved_only_Field_hash_changed':True,'registry16_IDs_preserved_only_native_SHA_changed':True,'all_geometry_business_entry_contract_data_old166_sources_unchanged':True,'engine_runs':0,'canonical_writes':0,'save_access':False,'supersedes_receipt_sha256':'67d0eba75b76ac2f2350c87431f2da63cf700aae6901034663785ff0711a10e4'}
b=(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n').encode();put('fallback02_receipt_READY.json',b)
print(json.dumps({'receipt_sha256':sha(b),'bytes':len(b),'hunks':sum(len(r['replacements']) for r in targets),'targets':[{k:r[k] for k in ['target','new_sha256','bytes']} for r in targets]},ensure_ascii=False))
