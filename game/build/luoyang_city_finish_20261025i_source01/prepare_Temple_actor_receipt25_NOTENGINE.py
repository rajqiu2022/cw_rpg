"""One necessary Field receipt bridge, reusing reviewed Field-only metadata/backup/Stage machinery. BUILD only."""
from pathlib import Path
import argparse,copy,difflib,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';B=S+'Temple_actor_receipt_repair01/';O=N/'Temple_actor_receipt_repair01';P=B+'closure_READY01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'],pin;return b
def load(pin):return json.loads(read(pin))
def emit(path,b):
 p=N/path;assert not p.exists(),p;p.parent.mkdir(parents=True,exist_ok=True)
 with p.open('xb')as f:f.write(b)
 return dict(path=S+path,sha256=sha(b),bytes=len(b))
def exact(b,a,c):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a[:150],b.count(a));return b.replace(a,c,1)
def hunks(a,b):
 aa,bb=a.decode().splitlines(True),b.decode().splitlines(True);hs=[]
 for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
 f,v=a,b
 for h in hs:f=exact(f,h['old'],h['new'])
 for h in reversed(hs):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return hs
DEP=dict(path=S+'visible_doors_boundaries33_repair01/visible_doors_boundaries33_deployed_ROOT_ACTUAL.json',sha256='e53e6d557a60dc93e00120ed9541938cb51e54c5effd01383a086866ec8db6b2')
STAGE=dict(path=S+'outputs/root_visible_doors_boundaries_exact33_stage01/receipt.json',sha256='dc811f8f114769cad5f7c60369aa47cfd3197f30b11a529154daf4bdaf0c1f11')
OLD=dict(path=S+'visible_doors_boundaries33_repair01/unified33_READY02/unified33_ROOT_BACKUP_FIXED_NOT_STAGE.json',sha256='86282dad5be672f76cb54f383e32a2c4e2a12fe3aad2377c65eade7c59e6e4c9')
BACK=dict(path=S+'visible_doors_boundaries33_repair01/current_signed31_backup33_ROOT_ACTUAL.json',sha256='2b2be04ce2ee27e8f9d6782181a5f6999921a416ada094b9cafadb043742bff3')
F='res://scripts/field/field_walkable_controller.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
def prepare():
 dep=load(DEP);old=load(OLD);priorback=load(BACK);assert dep['passed']and dep['target_count']==33 and priorback['total_backups']==436
 allparents={r['target']:dict(path=r['candidate_path'],sha256=r['sha256'],bytes=r['bytes'])for r in dep['targets']}
 selected={F,CO,T,CT,EX}|set(old['metadata'])|{p for p,r in old['index_proofs'].items()if r['id']!='ap_environment_index'}
 assert len(selected)==25 and selected<=set(allparents);parents={p:allparents[p]for p in allparents if p in selected}
 rows=[dict(target=p,immutable_old=r['path'],old_sha256=r['sha256'],old_bytes=r['bytes'],kind='GD'if p.endswith('.gd')else'JSON')for p,r in parents.items()]
 scope=dict(status='CURRENT_E53E_EXACT25_FIELD_RECEIPT_BRIDGE_SCOPE_NOT_DEPLOYED',count=25,partition=dict(GD=11,JSON=14),parent_actual=DEP,parent_stage=STAGE,parent_descriptor=OLD,targets=rows,unchanged33_targets=[p for p in allparents if p not in selected],engine_calls=0,Stage_calls=0,canonical_writes=0)
 scopepin=emit('Temple_actor_receipt_repair01/current_E53E_exact25_scope_PREPARATION.json',enc(scope))
 data={};records={}
 def out(name,b):
  assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
 def record(p,name,b):
  a=read(parents[p]);assert a!=b;records[p]=dict(parent=parents[p],candidate=out(name,b),hunks=hunks(a,b),whole_byte_forward_inverse=True)
 fp=dict(path='res://build/luoyang_city_finish_20261025i_system01/temple_actor_receipt_bridge01_NOTREADY/Field_receipt_bridge_CANDIDATE.gd',sha256='3eb013420320ed269f7e983de3cfce2e138b92f815971fef2005b9d39c47577c')
 proofpin=dict(path='res://build/luoyang_city_finish_20261025i_system01/temple_actor_receipt_bridge01_NOTREADY/Field_receipt_bridge_whole_inverse_BUILD.json',sha256='6815356aa83a03c2a245d0e8ae3deea05103f85bcfab72b12ea4f7f64ab677bc')
 load(proofpin);record(F,'Field_READY.gd',read(fp));assert len(records[F]['hunks'])==1
 a=read(parents[CT]);v=json.loads(a);oldhash=v['source_sha256'][F];assert oldhash==parents[F]['sha256'];newhash=records[F]['candidate']['sha256'];v['source_sha256'][F]=newhash;b=exact(a,oldhash,newhash);assert json.loads(b)==v
 contract=dict(parent=parents[CT],candidate=out('runtime_contract_Field_READY.json',b),changes={F:dict(old=oldhash,new=newhash)},hunks=hunks(a,b),whole_typed_UTF8_inverse=True)
 record(CO,'Coordinator_READY.gd',exact(read(parents[CO]),parents[CT]['sha256'],contract['candidate']['sha256']))
 tbparent=old['temple_binding']['candidate'];a=read(tbparent);v=json.loads(a);b=a;changes={}
 for p,h in [(F,newhash),(CT,contract['candidate']['sha256']),(CO,records[CO]['candidate']['sha256'])]:
  before=v['source_delta'][p];assert before==parents[p]['sha256'];v['source_delta'][p]=h;b=exact(b,json.dumps(p)+': '+json.dumps(before),json.dumps(p)+': '+json.dumps(h));changes[p]=dict(old=before,new=h)
 assert json.loads(b)==v;tb=dict(parent=tbparent,candidate=out('Temple_binding_READY.json',b),changes=changes,hunks=hunks(a,b),whole_typed_UTF8_inverse=True)
 b=read(parents[T]);b=exact(b,tbparent['path'],tb['candidate']['path']);b=exact(b,tbparent['sha256'],tb['candidate']['sha256']);record(T,'Temple_READY.gd',b)
 prior=load(parents[EX]);assert len(prior['owned'])==10 and len(prior['source_sha256'])==224;new=copy.deepcopy(prior)
 for p in [F,CO,T]:
  r=records[p];owner=new['owned'][p];assert owner['current_sha256']==parents[p]['sha256'];snap=next(e['new_snapshot']for e in reversed(owner['edges'])if e['new_sha256']==owner['current_sha256']);assert read(dict(path=snap,sha256=owner['current_sha256']))==read(parents[p]);owner['edges'].append(dict(path=p,old_sha256=owner['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snap,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));owner['current_sha256']=r['candidate']['sha256'];new['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
 for pin in [contract['candidate'],tb['candidate']]:new['source_sha256'][pin['path']]=pin['sha256']
 extra={p:h for p,h in new['source_sha256'].items()if p not in prior['source_sha256']};assert len(extra)==5 and len(new['source_sha256'])==229 and all(new['source_sha256'][p]==h for p,h in prior['source_sha256'].items())
 back=copy.deepcopy(new)
 for p in [F,CO,T]:back['owned'][p]=copy.deepcopy(prior['owned'][p])
 back['source_sha256']=copy.deepcopy(prior['source_sha256']);assert enc(back)==read(parents[EX])
 ex=dict(parent=parents[EX],candidate=out('execution_successor_READY.json',enc(new)),changed_existing_owned=[F,CO,T],owned_count=10,old_proof_count=224,new_proof_count=229,extra=extra,old224_values_all_edges_retained=True,authority_F120_unchanged=True,no_shortcut=True,whole_typed_UTF8_inverse=True)
 seal=load(old['seal']);seal['Field']=records[F]['candidate'];seal['records'][T]=records[T];seal.update(Field_receipt_source_proof=proofpin,runtime_binding_helper_ENV_payload_mask_media_unchanged_from_E53E=True)
 sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal))
 codepin=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='E53E_FIELD_TWO_LINE_RECEIPT_BRIDGE_ONLY_NOT_STAGE',seal=sealpin,records=records,ordinary=[],contract=contract,temple_binding=tb,execution=ex,Field_bridge_source_proof=proofpin,engine_calls=0,Stage_calls=0,canonical_writes=0)))
 for name,b in data.items():emit('Temple_actor_receipt_repair01/closure_READY01/'+name,b)
 # The same reviewed incremental expression, with no new runtime/ambient/ENV sources.
 text=(N/'prepare_finish8_metadata32_NOTENGINE.py').read_text(encoding='utf8')
 changes=[('unified32_READY01','Temple_actor_receipt_repair01/unified25_READY01'),("PREFIX=NS+OUT.name+'/'","PREFIX=NS+'Temple_actor_receipt_repair01/unified25_READY01/'"),("NS+'finish8_existing_target_scope32_PREPARATION.json'",repr(scopepin['path'])),('2b74b371ea336b4725a76d4b23fce46d4c1e6cd26d987c515c6791016a9c6589',scopepin['sha256']),('res://build/luoyang_city_revision_20261025h_source01/external_projection_residual05b/unified28_candidates_EXTERNAL_fixed.json',OLD['path']),('43b729f67f17c29bf5278da44f6981c49798ba27c5f0283b4dc0ac3d906e5e7e',OLD['sha256']),("NS+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json'",repr(codepin['path'])),('fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200',codepin['sha256']),("NS+'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json'",repr(sealpin['path'])),('bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa',sealpin['sha256']),("adapter=dict(path=NS+'original_owner_receipts03_family_weak_snapshot_NOTREADY.gd',sha256='9ed1b1166bd1e7b700925e18a55337bb7d2fdb321b00cd3d6ae7cea685ae78d5')","adapter=seal['adapter']"),("envtext=read(next(r['candidate']['path']for p,r in records.items()if 'environment_layer' in p),next(r['candidate']['sha256']for p,r in records.items()if 'environment_layer' in p)).decode()","envpin=oldbundle['records']['res://scripts/city/luoyang_environment_layer_20261022ap.gd']['candidate'];envtext=read(envpin['path'],envpin['sha256']).decode()"),("for table in [ambient,env,room,extra,ordinary,*scopes.values()]:","for table in [ambient,env,room,extra,ordinary,*scopes.values(),*seal['wing_source_entrypoints'].values()]:"),("if k!='gate':merge(v,room)","if k!='gate':merge(v,room)\n if k=='artisan':merge(v,{seal['material_helper']['path']:seal['material_helper']['sha256']})\n if k in seal['wing_source_entrypoints']:merge(v,seal['wing_source_entrypoints'][k])"),("if k in ['docks','market']:merge(v,scopes['temple']);merge(v,{code['temple_binding']['candidate']['path']:code['temple_binding']['candidate']['sha256']})","if k in ['docks','market']:merge(v,scopes['temple']);merge(v,seal['wing_source_entrypoints']['temple']);merge(v,{code['temple_binding']['candidate']['path']:code['temple_binding']['candidate']['sha256']})"),("meta('estate_final');meta('quarter_final')","meta('estate_final')"),("'ap_execution_index','ap_quarter_index']","'ap_execution_index']"),("meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')","meta('quarter_final');index('ap_quarter_index');meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')"),("if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:","if ident in ['market_final','finite08_market']:"),('len(records)==18','len(records)==11'),('dict(GD=18,JSON=14,total=32)','dict(GD=11,JSON=14,total=25)'),("root_backup=dict(path=NS+'immutable_current32_ROOT_EXECUTED.json',sha256='d11ebf3713b0a3fde47c335e6c37a8d367bcb7388c484efd3275e352f8e1ef1f')","root_backup=dict(status='ROOT_CURRENT_E53E_NEW25_BACKUP_PENDING_OLD436_PRESERVED')"),('EIGHT_EXTERIORS_EXACT32_PREPARED_NOT_STAGE','CURRENT_E53E_TEMPLE_ACTOR_RECEIPT_EXACT25_NOT_STAGE')]
 for a,b in changes:assert a in text,a;text=text.replace(a,b)
 exec(compile(text,str(N/'prepare_Temple_actor_receipt25_metadata_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_Temple_actor_receipt25_metadata_DERIVED_NOTENGINE.py')})
 print(json.dumps(dict(scope=scopepin,code=codepin,seal=sealpin,Field=records[F]['candidate'],execution=ex['candidate'],code_only_new_owned_edges=3,old224_preserved=True)))
if __name__=='__main__':prepare()
