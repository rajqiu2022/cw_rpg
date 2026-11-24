"""Minimal approved Estate type/scale repair and Yamen three-leaf texture admission, source propagation only."""
from pathlib import Path
import copy,difflib,hashlib,json
N=Path(__file__).resolve().parent;G=N.parents[1];S='res://build/luoyang_city_finish_20261025i_source01/';B=S+'Estate_wall_source_repair01/';P=B+'closure_READY01/';O=N/'Estate_wall_source_repair01/closure_READY01'
sha=lambda b:hashlib.sha256(b).hexdigest()
enc=lambda v:(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(pin):
 b=(G/pin['path'][6:]).read_bytes();assert sha(b)==pin['sha256'],pin;return b
def load(pin):return json.loads(read(pin))
def exact(b,a,c,n=1):
 a,c=a.encode(),c.encode();assert a!=c and b.count(a)==n,(a[:100],b.count(a),n);return b.replace(a,c)
def hunks(a,b):
 aa,bb=a.decode().splitlines(True),b.decode().splitlines(True);hs=[]
 for z in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(2):hs.append(dict(old=''.join(aa[z[0][1]:z[-1][2]]),new=''.join(bb[z[0][3]:z[-1][4]])))
 f,v=a,b
 for h in hs:f=exact(f,h['old'],h['new'])
 for h in reversed(hs):v=exact(v,h['new'],h['old'])
 assert f==b and v==a;return hs
scopepin=dict(path=B+'current_0860_exact31_scope_PREPARATION.json',sha256='3282faaa05a467ddf11315b78001c84705a036d9eb015802488882fd720ea957');scope=load(scopepin);old=load(scope['parent_descriptor']);sealold=load(old['seal']);parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes'])for r in scope['targets']};data={};records={}
def out(name,b):
 assert name not in data;data[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
def value(pin):return data[pin['path'][len(P):]]if pin['path'].startswith(P)else read(pin)
def record(p,name,b):
 a=read(parents[p]);assert a!=b;records[p]=dict(parent=parents[p],candidate=out(name,b),hunks=hunks(a,b),whole_byte_forward_inverse=True)
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';Q='res://scripts/city/luoyang_quarters_family_20261022ap.gd';E='res://scripts/city/luoyang_estate_family_20261021am.gd';ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd';F='res://scripts/field/field_walkable_controller.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd';AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd';CT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EX='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
tuplepin=dict(path=B+'Yamen_existing_wall_tuple_source_proposal_READONLY.json',sha256='694c335c32bdfbcffef8e11ab195c21b07d11d986a0ae8798a387e19f24bdb04');tuple3=load(tuplepin)['required_ordinary'];binding=load(sealold['binding']);priorbinding=copy.deepcopy(binding);row=binding['scenes']['ch4_s1_luoyang_yamen']
for p,h in tuple3.items():assert p not in row['required_source_sha256'];read(dict(path=p,sha256=h));row['required_source_sha256'][p]=h
for id in binding['scenes']:
 if id!='ch4_s1_luoyang_yamen':assert binding['scenes'][id]==priorbinding['scenes'][id]
back=copy.deepcopy(binding)
for p in tuple3:del back['scenes']['ch4_s1_luoyang_yamen']['required_source_sha256'][p]
assert enc(back)==read(sealold['binding']);bind=out('finish8_binding_READY.json',enc(binding))
rb=read(sealold['runtime'])
for a,b in [(sealold['runtime']['path'],P+'finish8_runtime_READY.gd'),(sealold['binding']['path'],bind['path']),(sealold['binding']['sha256'],bind['sha256'])]:rb=exact(rb,a,b)
runtime=out('finish8_runtime_READY.gd',rb);runtime_edits=[(sealold['runtime']['path'],runtime['path']),(sealold['runtime']['sha256'],runtime['sha256'])]
def runtime_head(b):
 for a,c in runtime_edits:b=exact(b,a,c)
 return b
helperparent=dict(path='res://build/luoyang_city_finish_20261025i_system01/estate_door_source_type_repair01_NOTREADY/wing_door_depth_children_CANDIDATE.gd',sha256='8420804f4400be2b5edffb554c40b61f19f3ad4c26fa9828879ef2297b717008')
helperproof=dict(path='res://build/luoyang_city_finish_20261025i_system01/estate_door_source_type_repair01_NOTREADY/estate_door_type_scale_whole_inverse_BUILD.json',sha256='d9b28111bb6a7593f1855a28d6748004d65ee69a5f224520b145a711d86c5add');load(helperproof)
hb=exact(read(helperparent),sealold['wing_helper']['path'],P+'wing_door_depth_children_READY.gd');helper=out('wing_door_depth_children_READY.gd',hb)
def helper_head(b,n=1):
 for a,c in [(sealold['wing_helper']['path'],helper['path']),(sealold['wing_helper']['sha256'],helper['sha256'])]:b=exact(b,a,c,n)
 return b
fparent=read(parents[F]);fb=helper_head(runtime_head(fparent),2);assert b'\t\tif temple_session!=null and scene.scene_id==&"ch4_s4_ancient_temple":'in fparent and b'_city_tasks_receipt["matched"]'in fb;record(F,'Field_READY.gd',fb)
record(C,'C_READY.gd',runtime_head(read(parents[C])));record(Q,'luoyang_quarters_family_20261022ap.gd',runtime_head(read(parents[Q])));record(E,'luoyang_estate_family_20261021am.gd',helper_head(runtime_head(read(parents[E]))))
materialold=sealold['material_helper'];mb=runtime_head(read(materialold))
for a,c in [(sealold['binding']['path'],bind['path']),(sealold['binding']['sha256'],bind['sha256'])]:mb=exact(mb,a,c)
material=out('material_runtime_finish139_READY.gd',mb);eb=runtime_head(read(parents[ENV]))
for a,c in [(materialold['path'],material['path']),(materialold['sha256'],material['sha256'])]:eb=exact(eb,a,c)
record(ENV,'ENV_READY.gd',eb)
e53code=load(dict(path=S+'visible_doors_boundaries33_repair01/closure_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='e39fe38edd9c84955c04ff66904f5ccec1f1fd61ab852133c3b0def41b92f5cd'));origin=load(dict(path=S+'code_execution_READY01/code_execution_all_whole_inverse_NOT_STAGE.json',sha256='fcf9aa53021e201e0f2d6334149750a595cd14b89d61f1c81713572a141c6200'));ordinary=[]
def ordinary_successor(consumer,target,stem,edits):
 prior=next(r['proof']for r in e53code['ordinary']if r['target']==target);oldproof=load(prior);v=copy.deepcopy(oldproof)
 for step in v['replacements']:
  for a,c in edits:
   if a in step['new']:step['new']=step['new'].replace(a,c)
 v['new_sha256']=records[target]['candidate']['sha256'];fixed=read(origin['records'][target]['parent']);f=fixed;back=value(records[target]['candidate'])
 for h in v['replacements']:f=exact(f,h['old'],h['new'])
 for h in reversed(v['replacements']):back=exact(back,h['new'],h['old'])
 assert f==value(records[target]['candidate'])and back==fixed and len(v['replacements'])==len(oldproof['replacements'])
 pin=out(stem+'_ordinary_to_fixed25h_READY.json',enc(v));b=read(parents[consumer]);changed=[]
 for a,c in [(oldproof['new_sha256'],v['new_sha256']),(prior['path'],pin['path']),(prior['sha256'],pin['sha256'])]:b=exact(b,a,c);changed.append((a,c))
 record(consumer,stem+'_consumer_READY.gd',b);ordinary.append(dict(consumer=consumer,target=target,proof=pin,parent=prior,inner_gate_replacement_counts_unchanged=True,old_inner_chain_unchanged=True));return changed
ed=ordinary_successor(AA,C,'C',runtime_edits);ordinary_successor(AC,AA,'AA',ed)
raw=read(parents[CT]);v=json.loads(raw);b=raw;ctchanges={}
for p,h in list(v['source_sha256'].items()):
 if p not in records:continue
 assert h==parents[p]['sha256'];nh=records[p]['candidate']['sha256'];v['source_sha256'][p]=nh;b=exact(b,h,nh);ctchanges[p]=dict(old=h,new=nh)
assert set(ctchanges)=={C,F}and json.loads(b)==v;contract=dict(parent=parents[CT],candidate=out('runtime_contract_READY.json',b),changes=ctchanges,hunks=hunks(raw,b),whole_typed_UTF8_inverse=True)
record(CO,'Coordinator_READY.gd',exact(read(parents[CO]),parents[CT]['sha256'],contract['candidate']['sha256']))
tbparent=old['temple_binding']['candidate'];raw=read(tbparent);v=json.loads(raw);b=raw;tbchanges={};refs={p:r['candidate']for p,r in records.items()};refs[CT]=contract['candidate']
for p,h in list(v['source_delta'].items()):
 if p not in refs:continue
 assert h==parents[p]['sha256'];nh=refs[p]['sha256'];v['source_delta'][p]=nh;b=exact(b,json.dumps(p)+': '+json.dumps(h),json.dumps(p)+': '+json.dumps(nh));tbchanges[p]=dict(old=h,new=nh)
assert json.loads(b)==v;tb=dict(parent=tbparent,candidate=out('Temple_binding_READY.json',b),changes=tbchanges,hunks=hunks(raw,b),whole_typed_UTF8_inverse=True)
b=helper_head(runtime_head(read(parents[T])))
for a,c in [(tbparent['path'],tb['candidate']['path']),(tbparent['sha256'],tb['candidate']['sha256'])]:b=exact(b,a,c)
record(T,'Temple_READY.gd',b)
prior=load(parents[EX]);assert len(prior['owned'])==10 and len(prior['source_sha256'])==229;new=copy.deepcopy(prior);changed=[F,CO,T,AC]
for p in changed:
 owner=new['owned'][p];r=records[p];assert owner['current_sha256']==parents[p]['sha256'];snap=next(e['new_snapshot']for e in reversed(owner['edges'])if e['new_sha256']==owner['current_sha256']);assert read(dict(path=snap,sha256=owner['current_sha256']))==read(parents[p]);owner['edges'].append(dict(path=p,old_sha256=owner['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snap,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));owner['current_sha256']=r['candidate']['sha256'];new['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for pin in [contract['candidate'],tb['candidate']]:new['source_sha256'][pin['path']]=pin['sha256']
extra={p:h for p,h in new['source_sha256'].items()if p not in prior['source_sha256']};assert len(extra)==6 and len(new['source_sha256'])==235 and all(new['source_sha256'][p]==h for p,h in prior['source_sha256'].items());back=copy.deepcopy(new)
for p in changed:back['owned'][p]=copy.deepcopy(prior['owned'][p])
back['source_sha256']=copy.deepcopy(prior['source_sha256']);assert enc(back)==read(parents[EX]);execution=dict(parent=parents[EX],candidate=out('execution_successor_READY.json',enc(new)),changed_existing_owned=changed,owned_count=10,old_proof_count=229,new_proof_count=235,extra=extra,old229_values_all_edges_retained=True,authority_F120_unchanged=True,no_shortcut=True,whole_typed_UTF8_inverse=True)
seal=copy.deepcopy(sealold);hsources=copy.deepcopy(sealold['wing_source_entrypoints'])
for k,table in hsources.items():assert table.pop(sealold['wing_helper']['path'])==sealold['wing_helper']['sha256'];table[helper['path']]=helper['sha256']
seal.update(status='ROOT_APPROVED_ESTATE_TWO_HUNKS_YAMEN_EXISTING_TUPLE_NOT_FIELD_RESULT',runtime=runtime,binding=bind,Field=records[F]['candidate'],material_helper=material,wing_helper=helper,wing_source_entrypoints=hsources,records={p:r for p,r in records.items()if p in [C,Q,E,ENV,T]},binding_inverse=dict(parent=sealold['binding'],candidate=bind,only_Yamen_required_source_three_added=tuple3,all_other_rows_and_all_payload_mask_fingerprints_unchanged=True),runtime_seal=dict(parent=sealold['runtime'],candidate=runtime,hunks=hunks(read(sealold['runtime']),rb),only_SELF_BIND_path_SHA_headers=True,all_functions_unchanged=True),wing_helper_seal=dict(parent=helperparent,candidate=helper,hunks=hunks(read(helperparent),hb),only_SELF_path=True,all_functions_identical_to_approved_8420=True),Estate_functional_source_proof=helperproof,Field_receipt_0860_two_lines_retained=True)
sealpin=out('runtime_consumers_mechanical_seal_whole_inverse_READY.json',enc(seal));codepin=out('code_execution_all_whole_inverse_NOT_STAGE.json',enc(dict(status='CURRENT0860_ONLY_ESTATE_TWO_HUNKS_YAMEN_TUPLE_CLOSURE_NOT_STAGE',seal=sealpin,records=records,ordinary=ordinary,contract=contract,temple_binding=tb,execution=execution,parent_descriptor=scope['parent_descriptor'],helper_proof=helperproof,Yamen_three_existing_ordinary_source_proposal=tuplepin,engine_calls=0,Stage_calls=0,canonical_writes=0)))
assert len(records)==9 and not O.exists();O.mkdir()
for name,b in data.items():
 with(O/name).open('xb')as f:f.write(b)
print(json.dumps(dict(code=codepin,seal=sealpin,helper=helper,Field=records[F]['candidate'],runtime=runtime,binding=bind,execution=execution['candidate'],CT_changes=ctchanges,Temple_delta_changes=tbchanges,scope=scopepin)))
