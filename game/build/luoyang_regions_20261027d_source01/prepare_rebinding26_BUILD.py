"""Necessary Router/CT/Temple and existing metadata successor; no noop target."""
from pathlib import Path
import copy,difflib,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S=G/'build/luoyang_city_finish_20261025i_source01';O=N/'source_rebinding02_BUILD';U=O/'closure26'
sha=lambda b:hashlib.sha256(b).hexdigest();enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode();res=lambda p:'res://'+p.relative_to(G).as_posix()
def read(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'],pin['path'];return b
def load(pin):return json.loads(read(pin))
def pin(p,raw=None):
 raw=p.read_bytes()if raw is None else raw;return dict(path=res(p),sha256=sha(raw),bytes=len(raw))
def emit(name,raw):
 p=U/name;p.parent.mkdir(parents=True,exist_ok=True);assert not p.exists();p.write_bytes(raw);return pin(p,raw)
oldpin=dict(path='res://build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01/unified32_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='ddb955b71625acc92f02d23a896f9f5f306062ee623248a485b1be2e7ef29a47');old=load(oldpin)
stagepin=dict(path='res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_integration_exact32_stage02/receipt.json',sha256='e569f5d85b4679175ff70a1f314d4eff3d8c4b8426471595b07539607a5376c5');stage=load(stagepin)
rebindpin=pin(O/'source_rebinding_whole_binary_inverse_BUILD.json');rebind=load(rebindpin)
assert rebind['manifest_candidate']['sha256']=='77c638a7d229a6dfd2437b9b9374c15af68232899690d2d7dda52e17c44327ff'
assert not U.exists();U.mkdir()
parents={r['target']:r['candidate']for r in old['targets']};refs={};records={};metadata={};indexes={};data={}
R='res://scripts/autoload/scene_router.gd';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
def exact(raw,a,b):
 a=a.encode();b=b.encode();assert a!=b and raw.count(a)==1,(a[:100],raw.count(a));return raw.replace(a,b,1)
def hunks(a,b):
 rows=[];aa=a.decode().splitlines(True);bb=b.decode().splitlines(True)
 for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(12):rows.append(dict(old=''.join(aa[group[0][1]:group[-1][2]]),new=''.join(bb[group[0][3]:group[-1][4]])))
 f=a;back=b
 for row in rows:f=exact(f,row['old'],row['new'])
 for row in reversed(rows):back=exact(back,row['new'],row['old'])
 assert f==b and back==a;return rows
def record(target,name,raw):
 before=read(parents[target]);assert before!=raw
 p=emit(name,raw);refs[target]=p;data[p['path']]=raw
 records[target]=dict(parent=parents[target],candidate=p,hunks=hunks(before,raw),whole_byte_forward_inverse=True)
 return p
record(R,'Router_READY.gd',read(rebind['Router']['candidate']))
ctraw=read(parents[CT]);ct=json.loads(ctraw);ctold=copy.deepcopy(ct);assert len(ct['source_sha256'])==26 and ct['source_sha256'][R]==parents[R]['sha256']
ct['source_sha256'][R]=refs[R]['sha256'];ctnew=exact(ctraw,parents[R]['sha256'],refs[R]['sha256']);assert json.loads(ctnew)==ct
ctpin=emit('runtime_contract_READY.json',ctnew);refs[CT]=ctpin;data[ctpin['path']]=ctnew
contract=dict(parent=parents[CT],candidate=ctpin,changes={R:dict(old=parents[R]['sha256'],new=refs[R]['sha256'])},hunks=hunks(ctraw,ctnew),whole_typed_UTF8_inverse=True)
record(CO,'Coordinator_READY.gd',exact(read(parents[CO]),parents[CT]['sha256'],ctpin['sha256']))
tbparent=old['temple_binding']['candidate'];tbraw=read(tbparent);tb=json.loads(tbraw);tbchanges={};tbnew=tbraw
for target in [R,CO,CT]:
 assert tb['source_delta'][target]==parents[target]['sha256'];tb['source_delta'][target]=refs[target]['sha256'];tbnew=exact(tbnew,json.dumps(target)+': '+json.dumps(parents[target]['sha256']),json.dumps(target)+': '+json.dumps(refs[target]['sha256']));tbchanges[target]=dict(old=parents[target]['sha256'],new=refs[target]['sha256'])
assert json.loads(tbnew)==tb
tbpin=emit('Temple_binding_READY.json',tbnew);data[tbpin['path']]=tbnew
temple_binding=dict(parent=tbparent,candidate=tbpin,changes=tbchanges,hunks=hunks(tbraw,tbnew),whole_typed_UTF8_inverse=True)
traw=read(parents[T]);traw=exact(traw,tbparent['path'],tbpin['path']);traw=exact(traw,tbparent['sha256'],tbpin['sha256']);record(T,'Temple_READY.gd',traw)
exraw=read(parents[EX]);prior=json.loads(exraw);ex=copy.deepcopy(prior);assert len(prior['source_sha256'])==284 and len(prior['owned'])==10
for target in [R,CO,T]:
 row=ex['owned'][target];assert row['current_sha256']==parents[target]['sha256'];current=[e for e in row['edges']if e['new_sha256']==row['current_sha256']];assert len(current)==1
 row['edges'].append(dict(path=target,old_sha256=row['current_sha256'],new_sha256=refs[target]['sha256'],old_snapshot=current[0]['new_snapshot'],new_snapshot=refs[target]['path'],whole_inverse=True,replacements=records[target]['hunks']));row['current_sha256']=refs[target]['sha256'];ex['source_sha256'][refs[target]['path']]=refs[target]['sha256']
for p in [ctpin,tbpin]:ex['source_sha256'][p['path']]=p['sha256']
extra={p:h for p,h in ex['source_sha256'].items()if p not in prior['source_sha256']};assert len(extra)==5 and len(ex['source_sha256'])==289 and all(ex['source_sha256'][p]==h for p,h in prior['source_sha256'].items())
back=copy.deepcopy(ex)
for target in [R,CO,T]:back['owned'][target]=copy.deepcopy(prior['owned'][target])
back['source_sha256']=copy.deepcopy(prior['source_sha256']);assert enc(back)==exraw
expin=emit('execution_successor_READY.json',enc(ex));refs[EX]=expin;data[expin['path']]=enc(ex)
execution=dict(parent=parents[EX],candidate=expin,changed_existing_owned=[R,CO,T],owned_count=10,old_proof_count=284,new_proof_count=289,extra=extra,old_values_all_edges_retained=True,whole_typed_UTF8_inverse=True)
manifest_target=rebind['manifest_target'];manifest_parent=emit('manifest_parent_5497.json',read(rebind['parent_manifest']));parents[manifest_target]=manifest_parent;refs[manifest_target]=rebind['manifest_candidate'];data[refs[manifest_target]['path']]=read(refs[manifest_target])
ordinary={**extra,rebind['author_candidate']['path']:rebind['author_candidate']['sha256']}
for row in rebind['proofs']:ordinary[row['candidate']['path']]=row['candidate']['sha256']
for row in rebind['immutable_source_bindings']:ordinary[row['new']]=row['sha256']
def at(value,ptr):
 for key in ptr:value=value[key]
 return value
def setvalue(value,ptr,new,changes):
 parent=at(value,ptr[:-1]);key=ptr[-1];exists=key in parent;before=copy.deepcopy(parent.get(key))
 if exists and before==new:return
 changes.append(dict(pointer=ptr,existed=exists,old=before,new=copy.deepcopy(new)));parent[key]=copy.deepcopy(new)
def restore(value,changes):
 value=copy.deepcopy(value)
 for c in reversed(changes):
  parent=at(value,c['pointer'][:-1])
  if c['existed']:parent[c['pointer'][-1]]=copy.deepcopy(c['old'])
  else:del parent[c['pointer'][-1]]
 return value
metabyid={v['id']:(p,v)for p,v in old['metadata'].items()}
def meta(id):
 target,prior_meta=metabyid[id];raw=read(parents[target]);value=json.loads(raw);original=copy.deepcopy(value);changes=[];fields=prior_meta['source_fields'];flat={p:h for ptr in fields for p,h in at(value,ptr).items()};assert len(flat)==sum(len(at(value,ptr))for ptr in fields)
 for ptr in fields:
  for path,h in list(at(value,ptr).items()):
   if path in refs:
    assert h==parents[path]['sha256'];setvalue(value,ptr+[path],refs[path]['sha256'],changes)
 default=prior_meta.get('source_bundle',{}).get('default_destination',fields[0])if prior_meta.get('source_bundle')else fields[0]
 additions={**ordinary};forbidden=set(prior_meta.get('forbidden_sources',[]))
 for path,h in additions.items():
  if path in forbidden:continue
  dest=[ptr for ptr in fields if path in at(value,ptr)];assert len(dest)<=1
  if dest:assert at(value,dest[0])[path]==h
  setvalue(value,(dest[0]if dest else default)+[path],h,changes)
 for ptr in prior_meta['protected_pointers']:assert at(value,ptr)==at(original,ptr)
 assert restore(value,changes)==original and enc(restore(value,changes))==raw
 candidate=emit('metadata/'+id+'.json',enc(value));refs[target]=candidate;data[candidate['path']]=enc(value)
 metadata[target]={**prior_meta,'parent':parents[target],'candidate':candidate,'changes':changes,'explicit_new_ordinary':{p:h for p,h in additions.items()if p not in flat and p not in forbidden},'whole_typed_UTF8_inverse':True}
def index(id):
 target,previous=next((p,r)for p,r in old['index_proofs'].items()if r['id']==id);raw=read(parents[target]);new=raw;changes=[]
 for path,p in refs.items():
  if parents[path]['sha256'].encode()in new:
   new=exact(new,parents[path]['sha256'],p['sha256']);changes.append(dict(old=parents[path]['sha256'],new=p['sha256'],target=path))
 assert new!=raw
 candidate=record(target,'indexes/'+id+'.gd',new);disabled=emit('indexes/'+id+'_disabled.gd',exact(new,previous['enabled_literal'],previous['disabled_literal']))
 indexes[target]={**previous,'disabled':disabled,'replacements':changes}
meta('estate_final');meta('quarter_final')
for id in ['legacy_manifest_2','legacy_manifest_3','legacy_manifest_4','legacy_manifest_5','legacy_manifest_6','legacy_manifest_7','legacy_manifest_8']:meta(id)
for id in ['legacy_index_0','legacy_index_1','legacy_index_2','legacy_index_3','legacy_index_4','ap_execution_index','ap_quarter_index']:index(id)
meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')
assert len(records)==11 and len(metadata)==12 and len(refs)==26 and all(read(parents[p])!=read(pin)for p,pin in refs.items())
maps={}
for id,node in stage['nodes'].items():
 if not id.startswith('expected_ch4_'):continue
 value=copy.deepcopy(node['value']);before=copy.deepcopy(value);sources=value['source_sha256']
 for path,p in refs.items():
  if path in sources:assert sources[path]==parents[path]['sha256'];sources[path]=p['sha256']
 for path,h in ordinary.items():assert path not in sources or sources[path]==h;sources[path]=h
 candidate=emit('maps/'+value['scene_id']+'_true.json',enc(value));maps[id]=dict(parent={k:node[k]for k in ['path','sha256']},candidate=candidate,count=len(sources),value=value,explicit_additions={p:h for p,h in sources.items()if p not in before['source_sha256']})
family={}
for id,metaid in [('expected_Family_sources','quarter_final'),('expected_Estate_sources','estate_final')]:
 path=metabyid[metaid][0];value=json.loads(data[refs[path]['path']]);family[id]=emit('maps/'+id+'.json',enc(dict(status='SOURCE_DERIVED_ORIGINAL_FAMILY_RECEIPT_NOT_OBSERVATION',source_sha256=value['source_sha256'])))
targets=[dict(target=p,parent=parents[p],candidate=c,kind='GD'if p.endswith('.gd')else'JSON')for p,c in refs.items()]
proof=dict(status='CURRENT_D9A8_SOURCE_REBIND26_NOT_STAGE',parent_descriptor=oldpin,parent_stage=stagepin,rebind=rebindpin,records=records,contract=contract,temple_binding=temple_binding,execution=execution,metadata=metadata,index_proofs=indexes,targets=targets,maps=maps,expected_family_maps=family,source_additions=ordinary,partition=dict(GD=11,JSON=15,total=26),noops_preserved=[r['target']for r in old['targets']if r['target']not in refs],runtime_Field_BIND_and_geometry_unchanged=True,engine_calls=0,Stage_calls=0,canonical_writes=0)
out=emit('source_rebind26_all_candidates_NOT_STAGE.json',enc(proof))
scope=dict(status='ROOT_BACKUP_EXACT_CHANGED26_PREPARATION',count=26,partition=proof['partition'],parent_descriptor=oldpin,parent_stage=stagepin,targets=[dict(target=r['target'],immutable_old=r['parent']['path'],old_sha256=r['parent']['sha256'],old_bytes=r['parent']['bytes'])for r in targets])
scopepin=emit('current_D9A8_exact26_scope_PREPARATION.json',enc(scope))
print(json.dumps({'descriptor':out,'scope':scopepin,'count':26,'partition':proof['partition'],'proofs':289,'maps':{k:v['count']for k,v in maps.items()},'noops':proof['noops_preserved']}))
