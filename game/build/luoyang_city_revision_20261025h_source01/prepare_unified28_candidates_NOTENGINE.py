"""Finite25g declaration delta. Generates candidates, not Stage or canonical files."""
from pathlib import Path
import copy,json,hashlib,difflib
P=Path(__file__).resolve().parent;GAME=P.parents[1]
S='res://build/luoyang_city_revision_20261025h_source01/';N='res://build/luoyang_garden_river_20261025h_source01/'
OUT=P/'unified28_candidates01';PREFIX=S+OUT.name+'/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
 b=(GAME/p[6:]).read_bytes();assert sha(b)==h,(p,sha(b));assert b'tokens truncated'not in b;return b
def load(pin):return json.loads(read(pin['path'],pin['sha256']))
prepared={};records={};refs={};nodepins={};metadata={};indexproof={}
def out(name,b):
 assert name not in prepared;prepared[name]=b;return dict(path=PREFIX+name,sha256=sha(b),bytes=len(b))
def val(pin):return prepared[pin['path'][len(PREFIX):]]if pin['path'].startswith(PREFIX)else read(pin['path'],pin['sha256'])
def exact(b,a,c):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a[:100],b.count(a));return b.replace(a,c,1)
def hunks(a,b):
 aa,bb=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True);r=[]
 for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):r.append(dict(old=''.join(aa[group[0][1]:group[-1][2]]),new=''.join(bb[group[0][3]:group[-1][4]])))
 f,v=a,b
 for h in r:f=exact(f,h['old'],h['new'])
 for h in reversed(r):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return r
scopepin=dict(path=S+'service_garden_exact28_scope_PREPARATION.json',sha256='a249b542308b2173133d3c868980465a8b90eee7042daa9e509fdb4f3cc9a19f');scope=load(scopepin)
parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']}
stage=load(scope['parent_stage']);assert stage['source_first']==stage['source_final']
old_input='res://build/luoyang_city_revision_20261025g_source01/source_input_courtyard45_exact32_residual02_ROOT_REVIEW.json'
old_input_sha='dc94fb946b4fef1e3913fa31190880a52a3abf6dce9ba1d834e80969f94f01e'
# Parent actual records the immutable input pin among source_first.
assert old_input in stage['source_first'];old_input_sha=stage['source_first'][old_input]
recipe=json.loads(read(old_input,old_input_sha));templates={n['id']:n for n in recipe['nodes']}
proofpin=dict(path=S+'owned4_service_READY02/four_owned_code_execution_whole_inverse_NOT_STAGE.json',sha256='2f1da0b1193e820af4424af0acad409329a454dd8f6262ff644362f7eee2d1c7');owned=load(proofpin)
records.update(copy.deepcopy(owned['records']))
for p,r in records.items():refs[p]=r['candidate']
familyproof=load(dict(path=N+'runtime02_READY/family_binding_mechanical_full_inverse_READY.json',sha256='10ef5e85618d13a422d3ba3e47a0644d1d53d407376261908e222e6bdf8841c8'))
for p,pin in [('res://scripts/city/luoyang_quarters_family_20261022ap.gd',familyproof['Family']),('res://scripts/city/luoyang_quarters_native_geometry_20261022ap.gd',familyproof['NativeGeometry'])]:
 a=read(parents[p]['path'],parents[p]['sha256']);b=val(pin);records[p]=dict(parent=parents[p],candidate=pin,hunks=hunks(a,b),whole_byte_forward_inverse=True);refs[p]=pin
EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
ROOM='res://scripts/city/luoyang_assembled_interiors_20261016g.gd';QUARTER='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
ESTATE='res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json'
refs[EX]=owned['execution']['candidate'];refs[CT]=owned['contract']['candidate'];nodepins['execution_final']=refs[EX];nodepins['runtime_contract_final']=refs[CT]
authority=load(refs[EX]);assert len(authority['owned'])==10 and len(authority['source_sha256'])==176
newproof=owned['execution']['extra'];assert len(newproof)==6
services={'res://build/luoyang_indoor_services_20261025h_system01/runtime_READY02/services_runtime_READY.gd':'f898f4b3860dda07bdfc95d62c1b08e30889b89b93843bf9a24d808e8a433fc8','res://build/luoyang_indoor_services_20261025h_system01/services_author05_CANDIDATE.json':'7706e07c00a8a318673fd496448f5a48e7005fa8998b9d16f7520615bd3effd8'}
bindingpin=familyproof['binding'];binding=load(bindingpin);assert binding['ready']is True and binding['limited_Field_trial_admission']==dict(path='res://build/luoyang_city_revision_20261025h_root01/garden_finite_trial_authorization.json',sha256='2b897810f0bf7f93c155882ada5e4276f6b2a8ff57204622170ee441c07ec52c')
garden={**binding['required_sources'],bindingpin['path']:bindingpin['sha256']};assert len(garden)==47
def at(v,ptr):
 for k in ptr:v=v[k]
 return v
def change(v,ptr,new,changes):
 holder=at(v,ptr[:-1]);key=ptr[-1];exists=key in holder;old=copy.deepcopy(holder.get(key))
 if exists and old==new:return
 changes.append(dict(pointer=ptr,existed=exists,old=old,new=copy.deepcopy(new)));holder[key]=copy.deepcopy(new)
def restore(v,changes):
 v=copy.deepcopy(v)
 for c in reversed(changes):
  holder=at(v,c['pointer'][:-1]);key=c['pointer'][-1]
  if c['existed']:holder[key]=copy.deepcopy(c['old'])
  else:del holder[key]
 return v
def merge_fields(v,fields,leaves,default,changes,forbidden):
 for p,h in leaves.items():
  if p in forbidden:continue
  destinations=[f for f in fields if p in at(v,f)];assert len(destinations)<=1,(p,destinations)
  dest=destinations[0]if destinations else default
  # Existing source class never changes. All new leaves here are explicit ordinary.
  change(v,dest+[p],h,changes)
def meta(ident):
 n=templates[ident];p=n['target'];base=json.loads(read(parents[p]['path'],parents[p]['sha256']));v=copy.deepcopy(base);changes=[]
 fields=n.get('source_bundle',{}).get('fields')or[f['pointer']for f in n.get('source_fields',[])]
 assert fields
 for field in fields:
  for key,h in list(at(v,field).items()):
   if key in refs:
    assert h==parents[key]['sha256'],(ident,key,h,parents[key]['sha256']);change(v,field+[key],refs[key]['sha256'],changes)
 default=n.get('source_bundle',{}).get('default_destination',fields[0]);forbidden=set(n.get('forbidden_sources',[]))
 if p!=ESTATE:
  merge_fields(v,fields,newproof,default,changes,forbidden)
  if ident!='legacy_manifest_2':merge_fields(v,fields,services,default,changes,forbidden)
  if ident in ['legacy_manifest_5','legacy_manifest_8','quarter_final','market_final','finite08_market']:merge_fields(v,fields,garden,default,changes,forbidden)
 if ident=='quarter_final':
  for key,suffix in [('scene_path','scene.res'),('layout_path','layout.res'),('packet_path','packet.bin')]:change(v,['scenes','luoyang_riverside_garden_20261022ap',key],binding['child'][suffix]['path'],changes)
  change(v,['garden_river_successor'],dict(binding_path=bindingpin['path'],binding_sha256=bindingpin['sha256']),changes)
 if ident in ['market_final','finite08_market']:
  merge_fields(v,fields,json.loads(val(nodepins['quarter_final']))['source_sha256'],default,changes,forbidden)
 for protected in n.get('protected_pointers',[]):
  if ident=='quarter_final'and protected==['scenes']:
   assert v['scenes']['luoyang_artisan_residential_20261022ap']==base['scenes']['luoyang_artisan_residential_20261022ap']
  else:assert at(v,protected)==at(base,protected),(ident,protected)
 for k in ['artifacts','layout_proof','mask_sha256','geometry_proof_basis','native_artifacts']:
  if k in base:assert v[k]==base[k]
 if p==ESTATE:assert set(v['source_sha256'])==set(base['source_sha256'])and v['registry_sha256']==base['registry_sha256']
 assert restore(v,changes)==base and enc(restore(v,changes))==enc(base)
 b=enc(v);assert b!=read(parents[p]['path'],parents[p]['sha256']),p
 pin=out('metadata/'+ident+'.json',b);refs[p]=pin;nodepins[ident]=pin
 metadata[p]=dict(id=ident,parent=parents[p],candidate=pin,changes=changes,source_fields=fields,source_bundle=copy.deepcopy(n.get('source_bundle')),protected_pointers=n.get('protected_pointers',[]),forbidden_sources=list(forbidden),whole_typed_UTF8_inverse=True,estate_keyset_unchanged=p==ESTATE,only_Garden_three_scene_paths_exception=ident=='quarter_final')
def index(ident):
 n=templates[ident];p=n['target'];old=read(parents[p]['path'],parents[p]['sha256']);new=old;changes=[]
 for h in n['replacements']:
  spec=h['new']
  if not isinstance(spec,dict):continue
  if '$sha'in spec:
   dep=spec['$sha'];pin=nodepins[dep];target=templates[dep].get('target',EX if dep=='execution_final'else None)
   assert target in parents;before=parents[target]['sha256'];after=pin['sha256']
  else:
   assert spec=={'$pin':'execution_approval'};before=parents[EX]['sha256'];after=refs[EX]['sha256']
  if before==after:continue
  new=exact(new,before,after);changes.append(dict(old=before,new=after))
 assert new!=old and new.count(n['enabled_literal'].encode())==1 and n['disabled_literal'].encode()not in new
 disabled=exact(new,n['enabled_literal'],n['disabled_literal']);assert exact(disabled,n['disabled_literal'],n['enabled_literal'])==new
 pin=out('indexes/'+ident+'.gd',new);off=out('indexes/'+ident+'_disabled.gd',disabled);refs[p]=pin;nodepins[ident]=pin
 records[p]=dict(parent=parents[p],candidate=pin,hunks=hunks(old,new),whole_byte_forward_inverse=True)
 indexproof[p]=dict(id=ident,disabled=off,disabled_literal=n['disabled_literal'],enabled_literal=n['enabled_literal'],replacements=changes,only_disabled_bool_transition=True)
for ident in ['estate_final','legacy_manifest_2','legacy_manifest_3','legacy_manifest_4','legacy_manifest_5','legacy_manifest_6','legacy_manifest_7','legacy_manifest_8']:meta(ident)
for ident in ['legacy_index_0','legacy_index_1','legacy_index_2','legacy_index_3','legacy_index_4','ap_execution_index']:index(ident)
meta('quarter_final');meta('market_final');index('ap_quarter_index');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')
assert set(refs)==set(parents) and len(records)==14 and len(metadata)==12
maps={}
for ident,node in stage['nodes'].items():
 if not ident.startswith('expected_'):continue
 base=load(dict(path=node['path'],sha256=node['sha256']));assert base==node['value'];v=copy.deepcopy(base);sources=v['source_sha256']
 for p,pin in refs.items():
  if p in sources:assert sources[p]==parents[p]['sha256'];sources[p]=pin['sha256']
 for p,h in newproof.items():assert p not in sources;sources[p]=h
 if ident!='expected_ch4_s0_luoyang_gate_true':
  for p,h in services.items():assert p not in sources;sources[p]=h
 if ident=='expected_ch4_s3_luoyang_market_true':
  for p,h in garden.items():assert p not in sources or sources[p]==h;sources[p]=h
  for p,h in json.loads(val(nodepins['quarter_final']))['source_sha256'].items():assert p not in sources or sources[p]==h;sources[p]=h
 pin=out('maps/'+base['scene_id']+'_true.json',enc(v));maps[ident]=dict(parent=dict(path=node['path'],sha256=node['sha256']),candidate=pin,count=len(sources),value=v)
quarter=json.loads(val(nodepins['quarter_final']));familymap=out('maps/expected_Family_source_receipt.json',enc(dict(status='SOURCE_DERIVED_QUARTER_FAMILY_RECEIPT_NOT_ACTUAL',source_sha256=quarter['source_sha256'])))
authorityhelper=next(r for r in recipe['pinned_inputs']if r['id']==recipe['authority_helper_input'])
gates=[]
for gate in recipe['required_gates']:
 if gate['id']=='root_target_preauthorization':continue
 pin=next(r for r in recipe['pinned_inputs']if r['id']==gate['input']);gates.append(dict(id=gate['id'],pin={k:pin[k]for k in ['path','sha256']},pointer=gate['pointer'],equals=gate['equals']))
targets=[dict(target=p,parent=parents[p],candidate=refs[p],kind='GD'if p.endswith('.gd')else'JSON')for p in parents]
proof=out('unified28_all_candidates_and_inverse_NOT_STAGE.json',enc(dict(status='SERVICE_GARDEN_EXACT28_PREPARED_NOT_STAGE',scope=scopepin,parent_stage=scope['parent_stage'],owned_proof=proofpin,execution=owned['execution'],contract=owned['contract'],temple_binding=owned['temple_binding'],records=records,metadata=metadata,index_proofs=indexproof,targets=targets,maps=maps,expected_Family_sources=familymap,source_additions=dict(services_flat2=services,Garden_full47=garden,new_execution_proof6=newproof),old_required_gates=gates,authority_helper={k:authorityhelper[k]for k in ['path','sha256']},root_backup=dict(path='res://build/luoyang_city_revision_20261025h_root01/exact28_backup_actual.json',sha256='e173e63f85e29df84edba04a6326ce54762eeddd397afc545475d8c133ff1e50'),partition=dict(GD=14,JSON=14,total=28),C_AA_AC_DT_ENV_Router_UI_registry_and_room_native_unchanged=True,source_classification_inherited=True,stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)))
assert not OUT.exists();OUT.mkdir()
for name,b in prepared.items():
 if name.endswith('.json'):json.loads(b)
 p=OUT/name;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
print(json.dumps(dict(proof=proof,target_count=28,map_counts={k:v['count']for k,v in maps.items()},Family_sources=familymap,source_keys=len(quarter['source_sha256']))))
