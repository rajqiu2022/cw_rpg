"""Root-approved exact Temple signed-IID domain only; BIND/payload/masks unchanged."""
from pathlib import Path
import json,copy,hashlib,difflib
N=Path(__file__).resolve().parent;G=N.parents[1]
S='res://build/luoyang_city_finish_20261025i_source01/'
Y='res://build/luoyang_city_finish_20261025i_system01/'
OLD=S+'family_visual_material_loading_repair01/closure_READY01/'
BASE=S+'temple_signed_iid_repair01/'
P=BASE+'closure_READY01/';OUT=N/'temple_signed_iid_repair01/closure_READY01'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def read(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'].lower(),pin;return b
def load(pin):return json.loads(read(pin))
def exact(b,a,c):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a[:120],b.count(a));return b.replace(a,c,1)
def hunks(a,b):
 aa,bb=a.decode().splitlines(True),b.decode().splitlines(True);out=[]
 for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):out.append(dict(old=''.join(aa[group[0][1]:group[-1][2]]),new=''.join(bb[group[0][3]:group[-1][4]])))
 f,v=a,b
 for h in out:f=exact(f,h['old'],h['new'])
 for h in reversed(out):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return out

parent_descriptor=dict(path=S+'family_visual_material_loading_repair01/unified31_READY01/unified32_all_candidates_and_inverse_NOT_STAGE.json',sha256='75ce628d299b772f95f05065b9cb6490106130b2aaac1e26205ebe4b5f0c78ea')
oldbundle=load(parent_descriptor)
parentstage=dict(path=S+'outputs/root_family_visual_material_loading_exact31_stage01/receipt.json',sha256='2b0959ea276b0798c8fa3a68fe3d6e0bb81cc7957af7eb4f98f26692d8967a9d')
stage=load(parentstage);assert len(stage['targets'])==31
parents={r['target']:r['candidate']for r in oldbundle['targets']}
for target,pin in parents.items():assert(G/target[6:]).read_bytes()==read(pin),('CURRENT_377B_PARENT_DRIFT',target)
priorcode=load(oldbundle['code_proof']);sealold=load(oldbundle['seal'])
data={};records={}
def out(name,b):
 assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
def value(pin):return data[pin['path'][len(P):]]if pin['path'].startswith(P)else read(pin)
def record(target,name,b):
 old=read(parents[target]);assert old!=b;pin=out(name,b);records[target]=dict(parent=parents[target],candidate=pin,hunks=hunks(old,b),whole_byte_forward_inverse=True);return pin

proofpin=dict(path=Y+'temple_signed_iid_fix01_NOTREADY/three_single_hunk_whole_inverse_BUILD.json',sha256='6e828746952d12fe7e7662dc1f3466a9afb53cf21901d7ea37005f3febedb9cd')
proof=load(proofpin);assert proof['physical_whole_byte_forward_inverse'] is True
functions=[]
for row in proof['records'][:2]:
 old=read(dict(path=row['parent'],sha256=row['parent_sha256']));new=read(dict(path=row['candidate'],sha256=row['candidate_sha256']))
 f=old;back=new;assert len(row['hunks'])==1
 for h in row['hunks']:f=exact(f,h['old'],h['new'])
 for h in reversed(row['hunks']):back=exact(back,h['new'],h['old'])
 assert f==new and back==old;functions.append((row,new))
adapterold=dict(path=functions[0][0]['parent'],sha256=functions[0][0]['parent_sha256'])
adapter=out('original_owner_receipts_READY.gd',functions[0][1])
assert adapter['sha256']=='c9b0ea604faf4e7ae63c2100e8b49e6a5b5f035fe73da8b514013d92dc4e3c86'
assert functions[1][0]['parent']==sealold['runtime']['path'] and functions[1][0]['parent_sha256']==sealold['runtime']['sha256']
rb=exact(functions[1][1],sealold['runtime']['path'],P+'finish8_runtime_READY.gd')
runtime=out('finish8_runtime_READY.gd',rb);bind=sealold['binding'];assert read(bind)==read(dict(path=OLD+'finish8_binding_READY.json',sha256='26b8b652aaa73a93c3123ff4287be63d6952124a6ce9b424c27aa2a30d316ff5'))
runtime_header_changes=[dict(old=sealold['runtime']['path'],new=runtime['path'])]
runtime_edits=[(sealold['runtime']['path'],runtime['path']),(sealold['runtime']['sha256'],runtime['sha256'])]
adapter_edits=[(adapterold['path'],adapter['path']),(adapterold['sha256'],adapter['sha256'])]
def seal_pointers(b,include_adapter=False):
 for a,c in runtime_edits:b=exact(b,a,c)
 if include_adapter:
  assert adapterold['path'].encode()in b
  for a,c in adapter_edits:
   if a.encode()in b:b=exact(b,a,c)
 return b

C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';Q='res://scripts/city/luoyang_quarters_family_20261022ap.gd';EST='res://scripts/city/luoyang_estate_family_20261021am.gd';ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd';F='res://scripts/field/field_walkable_controller.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
for target,name in [(C,'C_READY.gd'),(Q,'luoyang_quarters_family_20261022ap.gd'),(EST,'luoyang_estate_family_20261021am.gd'),(F,'Field_READY.gd')]:record(target,name,seal_pointers(read(parents[target]),True))
material_parent=sealold['material_helper'];mb=read(material_parent);sealed_material=seal_pointers(mb)
material=out('material_runtime_finish139_READY.gd',sealed_material)
for unchanged in [bind['path'],bind['sha256']]:assert mb.count(unchanged.encode())==1 and sealed_material.count(unchanged.encode())==1
eb=seal_pointers(read(parents[ENV]))
for a,b in [(material_parent['path'],material['path']),(material_parent['sha256'],material['sha256'])]:eb=exact(eb,a,b)
record(ENV,'ENV_READY.gd',eb)
material_seal=dict(parent=material_parent,candidate=material,hunks=hunks(mb,sealed_material),whole_byte_inverse=True,only_runtime_two_literals_changed=True,BIND_two_literals_byte_identical=True,all_functions_unchanged=True,source_entrypoint='ENV exact Artisan only; never BIND, no cycle')

ordinary=[]
def ordinary_successor(consumer,target,stem,edits):
 prior=next(r['proof']for r in priorcode['ordinary']if r['target']==target);oldproof=load(prior);v=copy.deepcopy(oldproof)
 for step in v['replacements']:
  for a,b in edits:
   if a in step['new']:step['new']=step['new'].replace(a,b)
 v['new_sha256']=records[target]['candidate']['sha256']
 # Exact fixed historical source named by the already-approved prior proof.
 firstcode=load(dict(path=S+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200'))
 fixed=read(firstcode['records'][target]['parent']);f=fixed;back=value(records[target]['candidate'])
 for h in v['replacements']:f=exact(f,h['old'],h['new'])
 for h in reversed(v['replacements']):back=exact(back,h['new'],h['old'])
 assert f==value(records[target]['candidate']) and back==fixed and len(v['replacements'])==len(oldproof['replacements'])
 np=out(stem+'_ordinary_to_fixed25h_READY.json',enc(v));b=read(parents[consumer]);ed=[]
 for a,c in [(oldproof['new_sha256'],v['new_sha256']),(prior['path'],np['path']),(prior['sha256'],np['sha256'])]:b=exact(b,a,c);ed.append((a,c))
 record(consumer,stem+'_consumer_READY.gd',b);ordinary.append(dict(consumer=consumer,target=target,proof=np,parent=prior,inner_gate_replacement_counts_unchanged=True,old_inner_chain_unchanged=True));return ed
ed=ordinary_successor(AA,C,'C',runtime_edits+adapter_edits);ordinary_successor(AC,AA,'AA',ed)

raw=read(parents[CT]);v=json.loads(raw);b=raw;ctchanges={}
for target in [C,F]:
 old=v['source_sha256'][target];assert old==parents[target]['sha256'];new=records[target]['candidate']['sha256'];v['source_sha256'][target]=new;b=exact(b,old,new);ctchanges[target]=dict(old=old,new=new)
assert json.loads(b)==v
contract=dict(parent=parents[CT],candidate=out('runtime_contract_C_Field_READY.json',b),changes=ctchanges,hunks=hunks(raw,b),whole_typed_UTF8_inverse=True)
record(CO,'Coordinator_READY.gd',exact(read(parents[CO]),parents[CT]['sha256'],contract['candidate']['sha256']))
tbparent=oldbundle['temple_binding']['candidate'];raw=read(tbparent);v=json.loads(raw);b=raw;tbchanges={}
for target,pin in [(C,records[C]['candidate']),(F,records[F]['candidate']),(CO,records[CO]['candidate']),(CT,contract['candidate'])]:
 old=v['source_delta'][target];assert old==parents[target]['sha256'];v['source_delta'][target]=pin['sha256'];b=exact(b,json.dumps(target)+': '+json.dumps(old),json.dumps(target)+': '+json.dumps(pin['sha256']));tbchanges[target]=dict(old=old,new=pin['sha256'])
assert json.loads(b)==v
tb=dict(parent=tbparent,candidate=out('Temple_binding_READY.json',b),changes=tbchanges,hunks=hunks(raw,b),whole_typed_UTF8_inverse=True)
b=seal_pointers(read(parents[T]),True)
for a,c in [(tbparent['path'],tb['candidate']['path']),(tbparent['sha256'],tb['candidate']['sha256'])]:b=exact(b,a,c)
record(T,'Temple_READY.gd',b)

prior=load(parents[EX]);assert len(prior['owned'])==10 and len(prior['source_sha256'])==212;new=copy.deepcopy(prior);changed=[F,CO,T,AC]
for target in changed:
 owner=new['owned'][target];r=records[target];assert owner['current_sha256']==parents[target]['sha256'];snapshot=next(e['new_snapshot']for e in reversed(owner['edges'])if e['new_sha256']==owner['current_sha256']);assert read(dict(path=snapshot,sha256=owner['current_sha256']))==read(parents[target])
 owner['edges'].append(dict(path=target,old_sha256=owner['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snapshot,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));owner['current_sha256']=r['candidate']['sha256'];new['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for pin in [contract['candidate'],tb['candidate']]:new['source_sha256'][pin['path']]=pin['sha256']
extra={p:h for p,h in new['source_sha256'].items()if p not in prior['source_sha256']};assert len(extra)==6 and len(new['source_sha256'])==218 and all(new['source_sha256'][p]==h for p,h in prior['source_sha256'].items())
back=copy.deepcopy(new)
for target in changed:back['owned'][target]=copy.deepcopy(prior['owned'][target])
back['source_sha256']=copy.deepcopy(prior['source_sha256']);assert enc(back)==read(parents[EX])
execution=dict(parent=parents[EX],candidate=out('execution_successor_READY.json',enc(new)),changed_existing_owned=changed,owned_count=10,old_proof_count=212,new_proof_count=218,extra=extra,old212_values_all_edges_retained=True,authority_F120_unchanged=True,no_shortcut=True,whole_typed_UTF8_inverse=True)
seal=copy.deepcopy(sealold)
seal.update(status='ROOT_APPROVED_EXACT_TEMPLE_SIGNED_RAW_IID_ONLY',runtime=runtime,binding=bind,adapter=adapter,Field=records[F]['candidate'],records={p:r for p,r in records.items()if p in [C,Q,EST,ENV,T]},functional_proofs=[proofpin],material_helper=material,material_helper_seal=material_seal,runtime_function_bytes_unchanged=False,runtime_header_changes=runtime_header_changes,old_runtime=sealold['runtime'],binding_whole_bytes_path_SHA_unchanged=True,all_payloads_masks_actors_portals_geometry_unchanged=True,optional_ART_excluded=True)
seal['binding_inverse']=dict(parent=bind,candidate=bind,changed_scene_only=None,all_eight_rows_whole_typed_unchanged=True)
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal))
cp=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='CURRENT_377B_EXACT_SIGNED_TEMPLE_DOMAIN_ONLY_NOT_STAGE',seal=sealpin,records=records,ordinary=ordinary,contract=contract,temple_binding=tb,execution=execution,functional_proofs=[proofpin],adapter=adapter,adapter_parent=adapterold,material_helper_seal=material_seal,engine_calls=0,collector_calls=0,Stage_calls=0,canonical_writes=0)))
scope=dict(status='CURRENT_377B_EXISTING31_SCOPE_PREPARATION_NOT_BACKUP',parent_stage=parentstage,parent_descriptor=parent_descriptor,parent_post_guard=dict(path=S+'family_visual_material_loading_repair01/post_377B_four_actual_guard_ROOT_ACTUAL.json',sha256='51464e26dac88f25917b8abac02af898ca471722837b29b32b6c433f35159117'),count=31,partition=dict(GD=17,JSON=14),targets=[dict(target=t,immutable_old=p['path'],old_sha256=p['sha256'],old_bytes=p['bytes'])for t,p in parents.items()],old_backups=372,Root_new_backup_pending=True,no_canonical_writes=True)
assert len(records)==9 and not OUT.exists();OUT.mkdir(parents=True)
for name,b in data.items():
 with(OUT/name).open('xb')as stream:stream.write(b)
dest=OUT.parent/'current_377B_exact31_scope_PREPARATION.json'
with dest.open('xb')as stream:stream.write(enc(scope))
print(json.dumps(dict(code=cp,seal=sealpin,runtime=runtime,adapter=adapter,Field=records[F]['candidate'],material=material,ENV=records[ENV]['candidate'],Coordinator=records[CO]['candidate'],Temple=records[T]['candidate'],execution=execution['candidate'],scope=dict(path=respath if False else BASE+dest.name,sha256=sha(enc(scope)),bytes=len(enc(scope))),BIND_unchanged=bind)))
