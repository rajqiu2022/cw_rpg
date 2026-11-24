"""Pinned current25h maps plus exact live consumer additions. No collector or Stage."""
from pathlib import Path
import json,copy,hashlib,re,difflib
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/';OUT=N/'unified32_READY01';PREFIX=NS+OUT.name+'/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,(p,h,sha(b));return b
def load(pin):return json.loads(read(pin['path'],pin['sha256']))
scopepin=dict(path=NS+'finish8_existing_target_scope32_PREPARATION.json',sha256='2b74b371ea336b4725a76d4b23fce46d4c1e6cd26d987c515c6791016a9c6589');scope=load(scopepin)
parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']}
parentstage=load(scope['parent_stage']);authority={}
def merge(dst,src):
 for p,h in src.items():assert p not in dst or dst[p]==h,(p,dst.get(p),h);dst[p]=h
for k,r in parentstage['nodes'].items():
 if k.startswith('expected_')and isinstance(r.get('value'),dict):merge(authority,r['value'].get('source_sha256',{}))
for r in parentstage['targets']:authority[r['target']]=r['candidate_sha256']
oldpin=dict(path='res://build/luoyang_city_revision_20261025h_source01/external_projection_residual05b/unified28_candidates_EXTERNAL_fixed.json',sha256='43b729f67f17c29bf5278da44f6981c49798ba27c5f0283b4dc0ac3d906e5e7e');oldbundle=load(oldpin)
codepin=dict(path=NS+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200');code=load(codepin)
sealpin=dict(path=NS+'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json',sha256='bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa');seal=load(sealpin)
binding=load(seal['binding']);records=copy.deepcopy(code['records']);refs={p:r['candidate']for p,r in records.items()};prepared={};metadata={};indexproof={};nodepins={}
EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';Q='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json';EST='res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json'
refs[EX]=code['execution']['candidate'];refs[CT]=code['contract']['candidate'];nodepins['execution_final']=refs[EX];nodepins['runtime_contract_final']=refs[CT]
def out(name,b):
 assert name not in prepared;prepared[name]=b;return dict(path=PREFIX+name,sha256=sha(b),bytes=len(b))
def val(pin):return prepared[pin['path'][len(PREFIX):]]if pin['path'].startswith(PREFIX)else read(pin['path'],pin['sha256'])
def exact(b,a,c):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a[:100],b.count(a));return b.replace(a,c,1)
def hunks(a,b):
 aa,bb=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True);ops=[]
 for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):ops.append(dict(old=''.join(aa[group[0][1]:group[-1][2]]),new=''.join(bb[group[0][3]:group[-1][4]])))
 f,v=a,b
 for h in ops:f=exact(f,h['old'],h['new'])
 for h in reversed(ops):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return ops
adapter=dict(path=NS+'original_owner_receipts03_family_weak_snapshot_NOTREADY.gd',sha256='9ed1b1166bd1e7b700925e18a55337bb7d2fdb321b00cd3d6ae7cea685ae78d5')
def scope_for(id):return {**binding['scenes'][id]['required_source_sha256'],seal['runtime']['path']:seal['runtime']['sha256'],seal['binding']['path']:seal['binding']['sha256'],adapter['path']:adapter['sha256']}
ids=dict(gate='ch4_s0_luoyang_gate',yamen='ch4_s1_luoyang_yamen',docks='ch4_s2_canal_docks',market='ch4_s3_luoyang_market',temple='ch4_s4_ancient_temple',artisan='luoyang_artisan_residential_20261022ap',garden='luoyang_riverside_garden_20261022ap',estate='luoyang_estate_riverside_20261021ai')
scopes={k:scope_for(v)for k,v in ids.items()}
ambient={seal['ambient']['path']:seal['ambient']['sha256']}
for path,h in re.findall(r'const (?:VISUAL|AUTHOR|CONTRACT) := "([^"]+)"\r?\nconst (?:VISUAL|AUTHOR|CONTRACT)_SHA := "([^"]+)"',read(seal['ambient']['path'],seal['ambient']['sha256']).decode()):merge(ambient,{path:h})
assert len(ambient)==4
vispath=next(p for p in ambient if 'visual_contract' in p);merge(ambient,load(dict(path=vispath,sha256=ambient[vispath]))['required_source_sha256'])
envtext=read(next(r['candidate']['path']for p,r in records.items()if 'environment_layer' in p),next(r['candidate']['sha256']for p,r in records.items()if 'environment_layer' in p)).decode();env=json.loads(re.search(r'const FINISH25I_PURPOSE_PINS: Dictionary=(\{[^\n]+\})',envtext).group(1))
roomhelper=dict(path=NS+'artisan_existing_rooms_return_projection01_NOTREADY.gd',sha256='952b7d48b4e9eadceee8d512feac03c7e45138a203d3e69b6b57ce80d759ccb8')
rt=read(roomhelper['path'],roomhelper['sha256']).decode();room={roomhelper['path']:roomhelper['sha256']}
for p,h in re.findall(r'const AUTHOR(?:: String)?="([^"]+)"\r?\nconst AUTHOR_SHA(?:: String)?="([^"]+)"',rt):merge(room,{p:h})
assert len(room)==2
extra=code['execution']['extra'];ordinary={r['proof']['path']:r['proof']['sha256']for r in code['ordinary']}
for table in [ambient,env,room,extra,ordinary,*scopes.values()]:
 for p,h in table.items():read(p,h);authority.setdefault(p,h);assert authority[p]==h
# Natural C import expansion, using only already fixed parent/publication/Root tuple declarations.
for p,h in load(seal['publication'])['source_first'].items():authority.setdefault(p,h)
media30=load(dict(path='res://build/luoyang_city_finish_20261025i_art01/ten_media30_promotion_ROOT_EXECUTED.json',sha256='43289bd6757cb470cdafb955658a386b04faea0143a91d18916fd76461d798a1'))
for r in media30['written']:authority['res://'+Path(r['path']).resolve().relative_to(G.resolve()).as_posix()]=r['sha256']
def import_expand(src):
 dst=dict(src)
 for p in list(src):
  side=p+'.import'
  if not(G/side[6:]).exists():continue
  assert side in authority,('UNDECLARED_EXISTING_IMPORT_AUTHORITY',side)
  merge(dst,{side:authority[side]});text=read(side,authority[side]).decode()
  remaps=re.findall(r'^path(?:\.[A-Za-z0-9_]+)?="(res://[^"\r\n]+)"\r?$',text,re.M);assert remaps
  for cp in remaps:assert cp in authority,('UNDECLARED_CTEX_AUTHORITY',cp);merge(dst,{cp:authority[cp]})
 return dst
base={}
for k in ids:
 v={};merge(v,extra);merge(v,env);merge(v,scopes[k])
 if k in ['gate','yamen','docks','market','estate']:merge(v,ambient)
 if k!='gate':merge(v,room)
 if k in ['docks','market']:merge(v,scopes['temple']);merge(v,{code['temple_binding']['candidate']['path']:code['temple_binding']['candidate']['sha256']})
 if k=='docks':merge(v,ordinary)
 base[k]=import_expand(v)
quarter={};merge(quarter,base['artisan']);merge(quarter,base['garden'])
def at(v,ptr):
 for key in ptr:v=v[key]
 return v
def setvalue(v,ptr,new,changes):
 d=at(v,ptr[:-1]);k=ptr[-1];exists=k in d;old=copy.deepcopy(d.get(k))
 if exists and old==new:return
 changes.append(dict(pointer=ptr,existed=exists,old=old,new=copy.deepcopy(new)));d[k]=copy.deepcopy(new)
def restore(v,changes):
 b=copy.deepcopy(v)
 for c in reversed(changes):
  d=at(b,c['pointer'][:-1]);k=c['pointer'][-1]
  if c['existed']:d[k]=copy.deepcopy(c['old'])
  else:del d[k]
 return b
additions={};oldmeta={r['id']:(p,r)for p,r in oldbundle['metadata'].items()}
scene_by_meta={'legacy_manifest_2':'gate','legacy_manifest_3':'yamen','legacy_manifest_4':'docks','legacy_manifest_5':'market','legacy_manifest_6':'docks','legacy_manifest_7':'docks','legacy_manifest_8':'market','finite08_yamen':'yamen','finite08_market':'market','market_final':'market','estate_final':'estate'}
EXTERNAL={'res://scripts/city/luoyang_environment_index_20261022ap.gd','res://scripts/city/luoyang_execution_index_20261022ap.gd'}
def meta(ident):
 p,n=oldmeta[ident];old=read(parents[p]['path'],parents[p]['sha256']);v=json.loads(old);assert enc(v)==old,('NONCANONICAL_META',ident);original=copy.deepcopy(v);changes=[];fields=n['source_fields'];flat={}
 for ptr in fields:
  for key,h in at(v,ptr).items():assert key not in flat,('OLD_CLASS_DUPLICATE',ident,key);flat[key]=h
 for ptr in fields:
  for key,h in list(at(v,ptr).items()):
   if key in refs:
    assert h==parents[key]['sha256'],('NOT_CURRENT_PARENT',ident,key,h,parents[key]['sha256']);setvalue(v,ptr+[key],refs[key]['sha256'],changes)
 added=dict(quarter if ident=='quarter_final'else base[scene_by_meta[ident]])
 if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:
  merge(added,json.loads(val(nodepins['quarter_final']))['source_sha256']);merge(added,json.loads(val(nodepins['estate_final']))['source_sha256'])
 forbidden=set(n.get('forbidden_sources',[]))
 if ident in ['market_final','finite08_market']:forbidden|=EXTERNAL-set(flat)
 default=n.get('source_bundle',{}).get('default_destination',fields[0])if n.get('source_bundle')else fields[0]
 applied={}
 for key,h in added.items():
  if key in forbidden:continue
  dest=[ptr for ptr in fields if key in at(v,ptr)];assert len(dest)<=1
  if key in refs:h=refs[key]['sha256']
  if dest:
   current=at(v,dest[0])[key];assert current==h or key in refs,('FIXED_SOURCE_CONFLICT',ident,key,current,h)
  setvalue(v,(dest[0]if dest else default)+[key],h,changes);applied[key]=h
 for ptr in n['protected_pointers']:assert at(v,ptr)==at(original,ptr),('PROTECTED',ident,ptr)
 assert restore(v,changes)==original and enc(restore(v,changes))==old
 b=enc(v);assert b!=old;pin=out('metadata/'+ident+'.json',b);refs[p]=pin;nodepins[ident]=pin
 additions[ident]={key:h for key,h in applied.items()if key not in flat}
 metadata[p]=dict(id=ident,parent=parents[p],candidate=pin,changes=changes,source_fields=fields,source_bundle=n.get('source_bundle'),protected_pointers=n['protected_pointers'],forbidden_sources=sorted(forbidden),explicit_new_ordinary=additions[ident],whole_typed_UTF8_inverse=True)
def index(ident):
 p,n=next((p,r)for p,r in oldbundle['index_proofs'].items()if r['id']==ident);old=read(parents[p]['path'],parents[p]['sha256']);b=old;changes=[]
 for target,pin in refs.items():
  a=parents[target]['sha256'];h=pin['sha256']
  if a.encode()in b:assert b.count(a.encode())==1;b=exact(b,a,h);changes.append(dict(old=a,new=h,target=target))
 assert b!=old and b.count(n['enabled_literal'].encode())==1 and n['disabled_literal'].encode()not in b
 off=out('indexes/'+ident+'_disabled.gd',exact(b,n['enabled_literal'],n['disabled_literal']));pin=out('indexes/'+ident+'.gd',b);refs[p]=pin;nodepins[ident]=pin;records[p]=dict(parent=parents[p],candidate=pin,hunks=hunks(old,b),whole_byte_forward_inverse=True)
 indexproof[p]=dict(id=ident,disabled=off,disabled_literal=n['disabled_literal'],enabled_literal=n['enabled_literal'],replacements=changes,only_disabled_bool_transition=True)
meta('estate_final');meta('quarter_final')
for ident in ['legacy_manifest_2','legacy_manifest_3','legacy_manifest_4','legacy_manifest_5','legacy_manifest_6','legacy_manifest_7','legacy_manifest_8']:meta(ident)
for ident in ['legacy_index_0','legacy_index_1','legacy_index_2','legacy_index_3','legacy_index_4','ap_execution_index','ap_quarter_index']:index(ident)
meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')
assert set(refs)==set(parents) and len(records)==18 and len(metadata)==12
# Immutable current maps plus only actual source entrypoints. Existing all key/value domains retained.
maps={}
for ident,row in parentstage['nodes'].items():
 if not ident.startswith('expected_ch4_'):continue
 old=load(row);assert old==row['value'];v=copy.deepcopy(old);sources=v['source_sha256'];key=next(k for k,id in ids.items()if id==old['scene_id']);added=dict(base[key])
 if key=='market':merge(added,json.loads(val(nodepins['quarter_final']))['source_sha256']);merge(added,json.loads(val(nodepins['estate_final']))['source_sha256'])
 for p,pin in refs.items():
  if p in sources:assert sources[p]==parents[p]['sha256'];sources[p]=pin['sha256']
 for p,h in added.items():
  if p in refs:h=refs[p]['sha256']
  assert p not in sources or sources[p]==h,('MAP_CONFLICT',ident,p,sources.get(p),h);sources[p]=h
 pin=out('maps/'+old['scene_id']+'_true.json',enc(v));maps[ident]=dict(parent={k:row[k]for k in ['path','sha256']},candidate=pin,count=len(sources),value=v,explicit_additions={p:h for p,h in sources.items()if p not in old['source_sha256']})
familymaps={}
for name,ident in [('expected_Family_sources','quarter_final'),('expected_Estate_sources','estate_final')]:
 source=json.loads(val(nodepins[ident]))['source_sha256'];pin=out('maps/'+name+'.json',enc(dict(status='SOURCE_DERIVED_ORIGINAL_FAMILY_RECEIPT_NOT_OBSERVATION',source_sha256=source)));familymaps[name]=pin
targets=[dict(target=p,parent=parents[p],candidate=refs[p],kind='GD'if p.endswith('.gd')else'JSON')for p in parents]
proof=out('unified32_all_candidates_and_inverse_NOT_STAGE.json',enc(dict(status='EIGHT_EXTERIORS_EXACT32_PREPARED_NOT_STAGE',scope=scopepin,parent_stage=scope['parent_stage'],code_proof=codepin,seal=sealpin,execution=code['execution'],contract=code['contract'],temple_binding=code['temple_binding'],records=records,metadata=metadata,index_proofs=indexproof,targets=targets,maps=maps,expected_family_maps=familymaps,source_additions_by_metadata=additions,source_entrypoint_additions=base,old_required_gates=oldbundle['old_required_gates'],authority_helper=oldbundle['authority_helper'],root_backup=dict(path=NS+'immutable_current32_ROOT_EXECUTED.json',sha256='d11ebf3713b0a3fde47c335e6c37a8d367bcb7388c484efd3275e352f8e1ef1f'),publication=seal['publication'],trial=load(seal['binding'])['scenes'][ids['gate']]['trial'],partition=dict(GD=18,JSON=14,total=32),old_classification_all_source_keys_preserved=True,original_native_registry_Router_DT_unchanged=True,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)))
assert not OUT.exists();OUT.mkdir()
for name,b in prepared.items():
 p=OUT/name;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
print(json.dumps(dict(proof=proof,counts={k:r['count']for k,r in maps.items()},family=familymaps,new_by_metadata={k:len(v)for k,v in additions.items()})))
