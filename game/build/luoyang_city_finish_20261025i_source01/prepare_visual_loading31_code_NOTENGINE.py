"""Approved three visual bridges + one actual NPC delta, exact current F67E parents."""
from pathlib import Path
import copy,difflib,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/';Y='res://build/luoyang_city_finish_20261025i_system01/'
P=S+'family_visual_material_loading_repair01/closure_READY01/';OUT=N/'family_visual_material_loading_repair01/closure_READY01'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf-8')
def read(p):
 b=(G/p['path'][6:]).read_bytes();assert sha(b)==p['sha256'].lower(),p;return b
def load(p):return json.loads(read(p))
def exact(b,a,c):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a[:150],b.count(a));return b.replace(a,c,1)
def hunks(a,b):
 aa,bb=a.decode().splitlines(True),b.decode().splitlines(True);hs=[]
 for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[group[0][1]:group[-1][2]]),new=''.join(bb[group[0][3]:group[-1][4]])))
 f,v=a,b
 for h in hs:f=exact(f,h['old'],h['new'])
 for h in reversed(hs):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return hs
scope=load(dict(path=S+'family_visual_material_loading_repair01/current_F67E_exact31_scope_PREPARATION.json',sha256='b9a60746fe3ed3e12144d88746512b6e609b6262bd7784a4b68421a22654ba07'))
parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']}
oldbundle=load(scope['parent_descriptor']);sealold=load(oldbundle['seal'])
priorcode=load(dict(path=S+'docks_gallery_family_repair01/closure_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='140dc257de79d36db80c25cb3ce1f42d374a5408f5a49311dea55dde837aee25'))
data={};records={}
def out(name,b):
 assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
def value(p):return data[p['path'][len(P):]]if p['path'].startswith(P)else read(p)
def record(target,name,b):
 old=read(parents[target]);assert old!=b;pin=out(name,b);records[target]=dict(parent=parents[target],candidate=pin,hunks=hunks(old,b),whole_byte_forward_inverse=True);return pin
actual=dict(path=S+'docks_loading08_local01_NOTREADY/ROOT_READY01/output_ROOT_READY/114200/result.json',sha256='ec6e808ce32c1253f43ded5a6ff864edf6112aebfb4d55fd17b210090f97ef28')
av=load(actual);assert av['passed'] and av['checks']==314 and av['source_first']==av['source_final'] and av['save_first']==av['save_final']
c=av['components'];assert c['changed_NPC_id']=='harbour_life_docks_loading_attendant' and c['only_changed_payload_key']=='npc_migrations' and c['route_samples']==136
assert c['payload']['sha256']=='6a9448ad86c5100f47d5893290a1a90573c376c5f11f3751892f710282361108' and c['payload']['bytes']==262392
binding=load(sealold['binding']);beforebinding=copy.deepcopy(binding);row=binding['scenes']['ch4_s2_canal_docks'];oldrow=copy.deepcopy(row)
assert row['payload']['sha256']=='76577ebe4246926124973aba0adcd014226f4a1c2f3afede6837294ab969154d'
row['payload']=c['payload'];row['fingerprints']['npc_migrations']=c['npc_migrations_var_sha256']
newsource={actual['path']:actual['sha256'],c['payload']['path']:c['payload']['sha256'],c['migration_inverse']['path']:c['migration_inverse']['sha256']}
for path,fact in av['source_first'].items():
 assert fact['exists'] is True
 if path in row['required_source_sha256']:assert row['required_source_sha256'][path]==fact['sha256']
 else:newsource[path]=fact['sha256']
for path,h in newsource.items():read(dict(path=path,sha256=h));assert path not in row['required_source_sha256'];row['required_source_sha256'][path]=h
row['loading_station08_source_successor']=dict(actual=actual,parent_payload=oldrow['payload'],only_changed_payload_key='npc_migrations',NPC_id=c['changed_NPC_id'],old_foot_px=[2060,1840],new_foot_px=[1940,1840],local_samples=136,mask_NAV43_solids39_portal_contract_unchanged=True,actual_Field_pass=False)
for scene_id in binding['scenes']:
 if scene_id!='ch4_s2_canal_docks':assert binding['scenes'][scene_id]==beforebinding['scenes'][scene_id]
bind=out('finish8_binding_READY.json',enc(binding))
rb=read(sealold['runtime']);runtime_header_changes=[]
for a,b in [(sealold['runtime']['path'],P+'finish8_runtime_READY.gd'),(sealold['binding']['path'],bind['path']),(sealold['binding']['sha256'],bind['sha256'])]:rb=exact(rb,a,b);runtime_header_changes.append(dict(old=a,new=b))
runtime=out('finish8_runtime_READY.gd',rb)
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';Q='res://scripts/city/luoyang_quarters_family_20261022ap.gd';EST='res://scripts/city/luoyang_estate_family_20261021am.gd';ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd';F='res://scripts/field/field_walkable_controller.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
def seal_runtime(b):
 for a,candidate in [(sealold['runtime']['path'],runtime['path']),(sealold['runtime']['sha256'],runtime['sha256'])]:b=exact(b,a,candidate)
 return b
functional_proofs=[]
fieldproof=dict(path=Y+'family_visual_bridges02_exactEOL_NOTREADY/whole_byte_inverse_and_scope_BUILD.json',sha256='46bb6172b003127a0b5e209a4438611e69ef0e9b761512c52b8e3e09f1c5c580')
fp=load(fieldproof);fb=read(fp['candidate']);f=read(parents[F]);assert f==read(fp['parent'])
for h in fp['hunks']:f=exact(f,h['old'],h['new'])
assert f==fb;functional_proofs.append(fieldproof);record(F,'Field_READY.gd',seal_runtime(fb))
materialproof=dict(path=Y+'artisan_finish_material_bridge03_NOTREADY/full_prefix_ENV_inverse_and_boundary_review_BUILD.json',sha256='636433ad751c30c28bc1f767a7f2538c705294c226abe40e101a41631d586806')
mp=load(materialproof);functional_proofs.append(materialproof)
material_parent=dict(path=Y+'artisan_finish_material_bridge03_NOTREADY/material_runtime_finish139_CANDIDATE.gd',sha256='ce8427c0419e29750842cd886fa2707144b6c15beedfd9558b80bf51e759196e')
mb=read(material_parent);sealed_material=seal_runtime(mb)
for a,b in [(sealold['binding']['path'],bind['path']),(sealold['binding']['sha256'],bind['sha256'])]:sealed_material=exact(sealed_material,a,b)
material=out('material_runtime_finish139_READY.gd',sealed_material)
env=mp['ENV'];eb=read(env['candidate']);f=read(parents[ENV]);assert f==read(env['parent'])
for h in env['hunks']:f=exact(f,h['old'],h['new'])
assert f==eb;eb=seal_runtime(eb)
for a,b in [(material_parent['path'],material['path']),(material_parent['sha256'],material['sha256'])]:eb=exact(eb,a,b)
record(ENV,'ENV_READY.gd',eb)
assert material['path']not in row['required_source_sha256'],'NO_HELPER_BINDING_HASH_CYCLE'
material_seal=dict(parent=material_parent,candidate=material,hunks=hunks(mb,sealed_material),whole_byte_inverse=True,only_four_runtime_BIND_literals=True,source_entrypoint='ENV.source_paths_for only exactArtisan; not in BIND.required_sources to avoid a hash cycle')
for target,name in [(C,'C_READY.gd'),(Q,'luoyang_quarters_family_20261022ap.gd'),(EST,'luoyang_estate_family_20261021am.gd')]:record(target,name,seal_runtime(read(parents[target])))
original=load(dict(path=S+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200'))
ordinary=[]
def ordinary_successor(consumer,target,stem,edits):
 prior=next(r['proof']for r in priorcode['ordinary']if r['target']==target);proof=load(prior);v=copy.deepcopy(proof)
 for step in v['replacements']:
  for a,b in edits:
   if a in step['new']:step['new']=step['new'].replace(a,b)
 v['new_sha256']=records[target]['candidate']['sha256'];fixed=read(original['records'][target]['parent']);f=fixed;back=value(records[target]['candidate'])
 for h in v['replacements']:f=exact(f,h['old'],h['new'])
 for h in reversed(v['replacements']):back=exact(back,h['new'],h['old'])
 assert f==value(records[target]['candidate']) and back==fixed and len(v['replacements'])==len(proof['replacements'])
 np=out(stem+'_ordinary_to_fixed25h_READY.json',enc(v));b=read(parents[consumer]);ed=[]
 for x,y in [(proof['new_sha256'],v['new_sha256']),(prior['path'],np['path']),(prior['sha256'],np['sha256'])]:b=exact(b,x,y);ed.append((x,y))
 record(consumer,stem+'_consumer_READY.gd',b);ordinary.append(dict(consumer=consumer,target=target,proof=np,parent=prior,inner_gate_replacement_counts_unchanged=True,old_inner_chain_unchanged=True));return ed
ed=ordinary_successor(AA,C,'C',[(sealold['runtime']['path'],runtime['path']),(sealold['runtime']['sha256'],runtime['sha256'])]);ordinary_successor(AC,AA,'AA',ed)
raw=read(parents[CT]);v=json.loads(raw);b=raw;ctchanges={}
for target in [C,F]:
 old=v['source_sha256'][target];assert old==parents[target]['sha256'];new=records[target]['candidate']['sha256'];v['source_sha256'][target]=new;b=exact(b,old,new);ctchanges[target]=dict(old=old,new=new)
assert json.loads(b)==v
contract=dict(parent=parents[CT],candidate=out('runtime_contract_C_Field_READY.json',b),changes=ctchanges,hunks=hunks(raw,b),whole_typed_UTF8_inverse=True)
record(CO,'Coordinator_READY.gd',exact(read(parents[CO]),parents[CT]['sha256'],contract['candidate']['sha256']))
tbparent=oldbundle['temple_binding']['candidate'];raw=read(tbparent);v=json.loads(raw);b=raw;tbchanges={}
for target,pin in [(C,records[C]['candidate']),(F,records[F]['candidate']),(CO,records[CO]['candidate']),(CT,contract['candidate'])]:
 old=v['source_delta'][target];assert old==parents[target]['sha256'];v['source_delta'][target]=pin['sha256'];b=exact(b,json.dumps(target)+': '+json.dumps(old),json.dumps(target)+': '+json.dumps(pin['sha256']));tbchanges[target]=dict(old=old,new=pin['sha256'])
assert json.loads(b)==v;tb=dict(parent=tbparent,candidate=out('Temple_binding_READY.json',b),changes=tbchanges,hunks=hunks(raw,b),whole_typed_UTF8_inverse=True)
b=seal_runtime(read(parents[T]))
for a,new in [(tbparent['path'],tb['candidate']['path']),(tbparent['sha256'],tb['candidate']['sha256'])]:b=exact(b,a,new)
record(T,'Temple_READY.gd',b)
prior=load(parents[EX]);assert len(prior['owned'])==10 and len(prior['source_sha256'])==206;new=copy.deepcopy(prior);changed=[F,CO,T,AC]
for target in changed:
 owner=new['owned'][target];r=records[target];assert owner['current_sha256']==parents[target]['sha256'];snapshot=next(e['new_snapshot']for e in reversed(owner['edges'])if e['new_sha256']==owner['current_sha256']);assert read(dict(path=snapshot,sha256=owner['current_sha256']))==read(parents[target])
 owner['edges'].append(dict(path=target,old_sha256=owner['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snapshot,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));owner['current_sha256']=r['candidate']['sha256'];new['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for pin in [contract['candidate'],tb['candidate']]:new['source_sha256'][pin['path']]=pin['sha256']
extra={p:h for p,h in new['source_sha256'].items()if p not in prior['source_sha256']};assert len(extra)==6 and len(new['source_sha256'])==212 and all(new['source_sha256'][p]==h for p,h in prior['source_sha256'].items())
back=copy.deepcopy(new)
for target in changed:back['owned'][target]=copy.deepcopy(prior['owned'][target])
back['source_sha256']=copy.deepcopy(prior['source_sha256']);assert enc(back)==read(parents[EX])
execution=dict(parent=parents[EX],candidate=out('execution_successor_READY.json',enc(new)),changed_existing_owned=changed,owned_count=10,old_proof_count=206,new_proof_count=212,extra=extra,old206_values_all_edges_retained=True,authority_F120_unchanged=True,no_shortcut=True,whole_typed_UTF8_inverse=True)
seal=copy.deepcopy(sealold);seal.update(status='F67E_THREE_STRICT_VISUAL_BRIDGES_AND_ONE_LOADING_NPC_SOURCE_SUCCESSOR',runtime=runtime,binding=bind,Field=records[F]['candidate'],records={p:r for p,r in records.items()if p in [C,Q,EST,ENV,T]},functional_proofs=functional_proofs,local_actual=actual,new_mask_promotion=None,material_helper=material,material_helper_seal=material_seal,runtime_function_bytes_unchanged=True,runtime_header_changes=runtime_header_changes)
seal['binding_inverse']=dict(parent=sealold['binding'],changed_scene_only='ch4_s2_canal_docks',old_scene=oldrow,new_scene=row,new_source_leaves=newsource,all_other_scenes_whole_typed_unchanged=True)
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal))
cp=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='F67E_FOUR_EXISTING_OWNED_SUCCESSORS_NO_ROUTER_OR_GEOMETRY_CHANGE_NOT_STAGE',seal=sealpin,records=records,ordinary=ordinary,contract=contract,temple_binding=tb,execution=execution,functional_proofs=functional_proofs,material_helper_seal=material_seal,local_actual=actual,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)))
assert len(records)==9 and not OUT.exists();OUT.mkdir()
for name,raw in data.items():
 with(OUT/name).open('xb')as f:f.write(raw)
print(json.dumps(dict(code=cp,seal=sealpin,runtime=runtime,binding=bind,Field=records[F]['candidate'],material=material,ENV=records[ENV]['candidate'],Coordinator=records[CO]['candidate'],Temple=records[T]['candidate'],execution=execution['candidate'])))
