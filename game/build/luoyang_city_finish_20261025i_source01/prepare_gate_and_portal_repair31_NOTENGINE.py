"""Actual one-row payload plus Gate Field bridge -> exact current4160 source successors only."""
from pathlib import Path
import json,hashlib,copy,difflib
N=Path(__file__).resolve().parent;G=N.parents[1];NS='res://build/luoyang_city_finish_20261025i_source01/';OUT=N/'gate_texture_repair01/closure_READY01';PREFIX=NS+'gate_texture_repair01/closure_READY01/'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
 b=(G/p[6:]).read_bytes();assert sha(b)==h,(p,h,sha(b));return b
def load(pin):return json.loads(read(pin['path'],pin['sha256']))
dp=dict(path=NS+'exact32_deployed_ROOT_ACTUAL.json',sha256='4160b4c149a71bd0e6dfa8975b0fc5f463f782f0fcff50acd630335b5ccd3142');dep=load(dp)
backup=dict(path=NS+'gate_texture_repair01/current4160_backup32_ROOT_ACTUAL.json',sha256='392b00f8fb19e36d58c7f2207ba6ad34f31c7f4f04991d7c05f295e39e962431');bk=load(backup);assert bk['passed']is True and len(bk['new_backups'])==32 and bk['total_backups']==240 and not bk['unexpected32_code_drift']and not bk['external_save_changes']
priorpin=dict(path=NS+'unified32_READY03/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='be3aa94f1b6eae760888803076f80062ad4a25b3aabb349ea46e43e223099254');prior=load(priorpin)
prepared={};records={};parents={r['target']:dict(path=r['candidate_path'],sha256=r['sha256'],bytes=r['bytes'])for r in dep['targets']}
def out(name,b):
 assert name not in prepared;prepared[name]=b;return dict(path=PREFIX+name,sha256=sha(b),bytes=len(b))
def value(pin):return prepared[pin['path'][len(PREFIX):]]if pin['path'].startswith(PREFIX)else read(pin['path'],pin['sha256'])
def exact(b,a,c):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a[:100],b.count(a));return b.replace(a,c,1)
def hunks(a,b):
 al,bl=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True);ops=[]
 for group in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_grouped_opcodes(2):ops.append(dict(old=''.join(al[group[0][1]:group[-1][2]]),new=''.join(bl[group[0][3]:group[-1][4]])))
 f,v=a,b
 for h in ops:f=exact(f,h['old'],h['new'])
 for h in reversed(ops):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return ops
def record(p,pin):
 a=read(parents[p]['path'],parents[p]['sha256']);b=value(pin);assert a!=b;records[p]=dict(parent=parents[p],candidate=pin,hunks=hunks(a,b),whole_byte_forward_inverse=True)
sealold=load(prior['seal']);binding=load(sealold['binding']);oldbinding=copy.deepcopy(binding)
actual=dict(path=NS+'gate_texture_repair01/market_portal_payload_ROOT_READY/output/30240/result.json',sha256='3e54f379d90e4a38ce81ec19a741d53df1da45fe3bf5a077d0cef8a6c6af20db');actualv=load(actual);assert actualv['passed']is True and actualv['checks']==43 and actualv['Scene_loads']==actualv['PNG_decodes']==actualv['raster_calls']==actualv['collector_calls']==0 and actualv['source_first']==actualv['source_final']
assert actualv['payload']['sha256']=='5cd1a103bd2ce0e6e6936da963b82f61afdf1ef5e58c044bfa910c6730b89559'and actualv['payload']['bytes']==220476
row=binding['scenes']['ch4_s3_luoyang_market'];assert row['payload']['sha256']=='f0cb7a2298922d7286b7eb1b6e6709d1b56a0d74a5fe90bc93d052c48f49dd62'
allowed={'portal_before','portal_after','new_route_contracts'}
for key,h in row['fingerprints'].items():
 if key not in allowed:assert actualv['fingerprints'][key]==h,(key,h,actualv['fingerprints'][key])
row['payload']=actualv['payload'];row['fingerprints']=actualv['fingerprints']
source_additions={actual['path']:actual['sha256'],actualv['payload']['path']:actualv['payload']['sha256'],actualv['inverse']['path']:actualv['inverse']['sha256'],NS+'gate_texture_repair01/market_portal_payload_ROOT_READY/rebuild_payload_pinned_ROOT_READY.gd':'faae26c1c2d32180234049259251df120010c3062dfdfb84ad44af0d9f411084',NS+'gate_texture_repair01/market_portal_payload_ROOT_READY/input_ROOT_READY.json':'6715011f264d8e62b9a8296707193bb6d943a4e0a57996e818023e047f3ccbef'}
for p,h in source_additions.items():read(p,h);assert p not in row['required_source_sha256'];row['required_source_sha256'][p]=h
row['portal_source_successor']=dict(actual,scope='one target row plus exact repeated route source_portal_row; all geometry/mask/NAV fingerprints unchanged',actual_Field_pass=False)
for id in binding['scenes']:
 if id!='ch4_s3_luoyang_market':assert binding['scenes'][id]==oldbinding['scenes'][id]
bind=out('finish8_binding_READY.json',enc(binding))
runtime_old=read(sealold['runtime']['path'],sealold['runtime']['sha256']);runtime_bytes=runtime_old
runtime_changes=[]
for a,b in [(sealold['runtime']['path'],PREFIX+'finish8_runtime_READY.gd'),(sealold['binding']['path'],bind['path']),(sealold['binding']['sha256'],bind['sha256'])]:runtime_bytes=exact(runtime_bytes,a,b);runtime_changes.append(dict(old=a,new=b))
runtime=out('finish8_runtime_READY.gd',runtime_bytes)
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';Q='res://scripts/city/luoyang_quarters_family_20261022ap.gd';EST='res://scripts/city/luoyang_estate_family_20261021am.gd';ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd';F='res://scripts/field/field_walkable_controller.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd';ROOM='res://scripts/city/luoyang_assembled_interiors_20261016g.gd';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
for p in [C,Q,EST,ENV]:
 b=read(parents[p]['path'],parents[p]['sha256']);b=exact(exact(b,sealold['runtime']['path'],runtime['path']),sealold['runtime']['sha256'],runtime['sha256']);record(p,out(p.split('/')[-1],b))
fieldpin=dict(path='res://build/luoyang_city_finish_20261025i_system01/Field10_gate_texture_bridge_exactEOL_CANDIDATE.gd',sha256='bb8ace3f0dd93bff7bb0e0b01eeb8f5812ad6270055cf348f08e5e536613529e')
fieldproof=load(dict(path='res://build/luoyang_city_finish_20261025i_system01/Field10_gate_texture_bridge_full_inverse_BUILD.json',sha256='1486216370d331001cee13727a91a3fb4ae3bde56b6bd93d1323d5d411fc10f9'));a=read(parents[F]['path'],parents[F]['sha256']);b=read(fieldpin['path'],fieldpin['sha256']);forward=a
for h in fieldproof['replacements']:forward=exact(forward,h['old'],h['new'])
assert forward==b
b=exact(exact(b,sealold['runtime']['path'],runtime['path']),sealold['runtime']['sha256'],runtime['sha256']);record(F,out('Field_READY.gd',b))
oldcode=load(prior['code_proof']);original=load(dict(path=NS+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200'));ordinary=[]
def update_ordinary(consumer,target,stem):
 oldproof=next(r['proof']for r in oldcode['ordinary']if r['target']==target);proof=load(oldproof);newproof=copy.deepcopy(proof);parent_bytes=read(original['records'][target]['parent']['path'],original['records'][target]['parent']['sha256'])
 if target==C:
  edits=[dict(old=sealold['runtime']['path'],new=runtime['path']),dict(old=sealold['runtime']['sha256'],new=runtime['sha256'])]
 else:edits=records[AA]['literal_changes']
 for h in newproof['replacements']:
  for e in edits:
   if e['old']in h['new']:h['new']=h['new'].replace(e['old'],e['new'])
 newproof['new_sha256']=records[target]['candidate']['sha256'];f,v=parent_bytes,value(records[target]['candidate'])
 for h in newproof['replacements']:f=exact(f,h['old'],h['new'])
 for h in reversed(newproof['replacements']):v=exact(v,h['new'],h['old'])
 assert f==value(records[target]['candidate'])and v==parent_bytes and len(newproof['replacements'])==len(proof['replacements'])
 np=out(stem+'_ordinary_to_fixed25h_READY.json',enc(newproof));b=read(parents[consumer]['path'],parents[consumer]['sha256']);edits=[]
 for a,c in [(proof['new_sha256'],newproof['new_sha256']),(oldproof['path'],np['path']),(oldproof['sha256'],np['sha256'])]:b=exact(b,a,c);edits.append(dict(old=a,new=c))
 record(consumer,out(stem+'_consumer_READY.gd',b));records[consumer]['literal_changes']=edits;ordinary.append(dict(consumer=consumer,target=target,proof=np,parent=oldproof,inner_gate_replacement_counts_unchanged=True,old_inner_chain_unchanged=True))
update_ordinary(AA,C,'C');update_ordinary(AC,AA,'AA')
old=read(parents[CT]['path'],parents[CT]['sha256']);v=json.loads(old);b=old;changes={}
for p in [C,F]:
 h=v['source_sha256'][p];assert h==parents[p]['sha256'];new=records[p]['candidate']['sha256'];v['source_sha256'][p]=new;b=exact(b,h,new);changes[p]=dict(old=h,new=new)
assert json.loads(b)==v;contract=out('runtime_contract_C_Field_READY.json',b);contractinfo=dict(parent=parents[CT],candidate=contract,changes=changes,hunks=hunks(old,b),whole_typed_UTF8_inverse=True)
record(CO,out('Coordinator_READY.gd',exact(read(parents[CO]['path'],parents[CO]['sha256']),parents[CT]['sha256'],contract['sha256'])))
oldtb=oldcode['temple_binding']['candidate'];old=read(oldtb['path'],oldtb['sha256']);v=json.loads(old);b=old;changes={}
refs={p:r['candidate']['sha256']for p,r in records.items()};refs[CT]=contract['sha256']
for p in [C,F,CO,CT]:
 h=v['source_delta'][p];assert h==parents[p]['sha256'];v['source_delta'][p]=refs[p];b=exact(b,json.dumps(p)+': '+json.dumps(h),json.dumps(p)+': '+json.dumps(refs[p]));changes[p]=dict(old=h,new=refs[p])
assert json.loads(b)==v;tb=out('Temple_binding_READY.json',b);tbinfo=dict(parent=oldtb,candidate=tb,changes=changes,hunks=hunks(old,b),whole_typed_UTF8_inverse=True)
b=read(parents[T]['path'],parents[T]['sha256'])
for a,c in [(sealold['runtime']['path'],runtime['path']),(sealold['runtime']['sha256'],runtime['sha256']),(oldtb['path'],tb['path']),(oldtb['sha256'],tb['sha256'])]:b=exact(b,a,c)
record(T,out('Temple_READY.gd',b))
old=read(parents[EX]['path'],parents[EX]['sha256']);execution=json.loads(old);assert enc(execution)==old and len(execution['owned'])==10 and len(execution['source_sha256'])==183;new=copy.deepcopy(execution);changed=[F,CO,T,AC]
for p in changed:
 r=records[p];owner=new['owned'][p];assert owner['current_sha256']==parents[p]['sha256'];snapshot=next(e['new_snapshot']for e in reversed(owner['edges'])if e['new_sha256']==owner['current_sha256']);assert read(snapshot,owner['current_sha256'])==read(parents[p]['path'],parents[p]['sha256']);owner['edges'].append(dict(path=p,old_sha256=owner['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snapshot,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));owner['current_sha256']=r['candidate']['sha256'];new['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for p in [contract,tb]:new['source_sha256'][p['path']]=p['sha256']
extra={p:h for p,h in new['source_sha256'].items()if p not in execution['source_sha256']};assert len(extra)==6 and len(new['source_sha256'])==189 and all(new['source_sha256'][p]==h for p,h in execution['source_sha256'].items())
back=copy.deepcopy(new)
for p in changed:back['owned'][p]=copy.deepcopy(execution['owned'][p])
back['source_sha256']=copy.deepcopy(execution['source_sha256']);assert enc(back)==old
ex=out('execution_successor_READY.json',enc(new))
seal=copy.deepcopy(sealold);seal.update(binding=bind,runtime=runtime,Field=records[F]['candidate'],records={p:r for p,r in records.items()if p in [C,Q,EST,ENV,T]},status='ONE_MARKET_PORTAL_SOURCE_AND_GATE_FIELD_BRIDGE_READY_NOT_STAGE')
seal['repair_actual']=actual;seal['runtime_function_bytes_unchanged']=True;seal['runtime_header_changes']=runtime_changes;seal['old_runtime']=sealold['runtime'];seal['binding_inverse']=dict(parent=sealold['binding'],changed_scene_only='ch4_s3_luoyang_market',old_payload=oldbinding['scenes']['ch4_s3_luoyang_market']['payload'],new_payload=actualv['payload'],new_source_leaves=source_additions)
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal))
scope_rows=[dict(target=r['target'],old_sha256=r['sha256'],old_bytes=r['bytes'],immutable_old=r['candidate_path'],kind='GD'if r['target'].endswith('.gd')else'JSON')for r in dep['targets']if r['target']!=ROOM];assert len(scope_rows)==31
scope=out('current4160_repair31_scope_PREPARATION.json',enc(dict(status='EXACT_CURRENT4160_REPAIR31_SCOPE_NOT_BACKUP_NOT_DEPLOYED',count=31,partition=dict(GD=17,JSON=14),parent_stage=dep['stage'],parent_deployment=dp,Root_current32_backup=backup,targets=scope_rows,excluded_noop_G=ROOM)))
cp=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='CURRENT4160_FOUR_REAL_OWNED_REPAIR_SUCCESSORS_NOT_STAGE',seal=sealpin,records=records,ordinary=ordinary,contract=contractinfo,temple_binding=tbinfo,execution=dict(parent=parents[EX],candidate=ex,changed_existing_owned=changed,owned_count=10,old_proof_count=183,new_proof_count=189,extra=extra,old183_values_all_edges_retained=True,depth_limit=16,no_shortcut=True,whole_typed_UTF8_inverse=True),actual_source_payload=actual,canonical_writes=0,engine_calls=0,Stage_calls=0)))
assert len(records)==9 and not OUT.exists();OUT.mkdir()
for name,b in prepared.items():
 with(OUT/name).open('xb')as f:f.write(b)
print(json.dumps(dict(scope=scope,seal=sealpin,code_proof=cp,Field=records[F]['candidate'],runtime=runtime,binding=bind,execution=ex,counts=dict(targets=31,GD=17,JSON=14,oldproof=183,newproof=189))))
# Derive the same reviewed metadata/map model against current4160, not any older baseline.
text=(N/'prepare_finish8_metadata32_NOTENGINE.py').read_text(encoding='utf-8')
changes=[('unified32_READY01','gate_texture_repair01/unified31_READY01'),("NS+'finish8_existing_target_scope32_PREPARATION.json'","'"+scope['path']+"'"),('2b74b371ea336b4725a76d4b23fce46d4c1e6cd26d987c515c6791016a9c6589',scope['sha256']),('res://build/luoyang_city_revision_20261025h_source01/external_projection_residual05b/unified28_candidates_EXTERNAL_fixed.json',priorpin['path']),('43b729f67f17c29bf5278da44f6981c49798ba27c5f0283b4dc0ac3d906e5e7e',priorpin['sha256']),("NS+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json'","'"+cp['path']+"'"),('fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200',cp['sha256']),("NS+'runtime_READY01/runtime_consumers_mechanical_seal_whole_inverse_READY.json'","'"+sealpin['path']+"'"),('bf29047eb15d69af815578eac2b3720cb2df3fbb34090fc84de1f204c0ba0daa',sealpin['sha256']),("meta('estate_final');meta('quarter_final')","meta('estate_final')"),("'ap_execution_index','ap_quarter_index']","'ap_execution_index']"),("meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')","meta('quarter_final');index('ap_quarter_index');meta('market_final');meta('finite08_market');meta('finite08_yamen');index('ap_city_index')"),("if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:","if ident in ['market_final','finite08_market']:"),('len(records)==18','len(records)==17'),('dict(GD=18,JSON=14,total=32)','dict(GD=17,JSON=14,total=31)'),("NS+'immutable_current32_ROOT_EXECUTED.json'","'"+backup['path']+"'"),('d11ebf3713b0a3fde47c335e6c37a8d367bcb7388c484efd3275e352f8e1ef1f',backup['sha256']),('EIGHT_EXTERIORS_EXACT32_PREPARED_NOT_STAGE','TWO_ACTUAL_FAILURES_EXACT31_SOURCE_REPAIR_NOT_STAGE')]
for a,c in changes:assert a in text,a;text=text.replace(a,c)
exec(compile(text,str(N/'prepare_gate_repair_metadata31_DERIVED_NOTENGINE.py'),'exec'),{'__file__':str(N/'prepare_gate_repair_metadata31_DERIVED_NOTENGINE.py')})
