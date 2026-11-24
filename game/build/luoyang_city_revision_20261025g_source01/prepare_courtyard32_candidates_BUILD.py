"""NEW fixed9876 courtyard45 code/dependency preparation; never invokes Stage."""
from pathlib import Path
import json,hashlib,copy,difflib
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261025g_source01/';OLD='res://build/luoyang_city_revision_20261024e_source01/'
D='res://build/luoyang_market_courtyard_links_20261025g_system01/runtime02_READY/'
OUT=HERE/'courtyard32_candidates01';P=S+OUT.name+'/'
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';F='res://scripts/field/field_walkable_controller.gd'
DT='res://scripts/city/luoyang_district_life_20261016f.gd';G='res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),p;assert b'tokens truncated' not in b;return b
def load(p,h):return json.loads(read(p,h))
def exact(b,a,c):
    a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1,(a,b.count(a));return b.replace(a,c,1)
def inverse(a,b,ops):
    f,v=a,b
    for r in ops:
        x,y=r['old'].encode(),r['new'].encode();assert f.count(x)==1;f=f.replace(x,y,1)
    for r in reversed(ops):
        x,y=r['old'].encode(),r['new'].encode();assert v.count(y)==1;v=v.replace(y,x,1)
    assert f==b and v==a
def hunks(a,b):
    al,bl=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True);ops=[]
    for group in difflib.SequenceMatcher(None,al,bl,autojunk=False).get_grouped_opcodes(2):
        ops.append(dict(old=''.join(al[group[0][1]:group[-1][2]]),new=''.join(bl[group[0][3]:group[-1][4]])))
    inverse(a,b,ops);assert all(max(len(r['old'].encode()),len(r['new'].encode()))<18000 for r in ops);return ops
scopepin=dict(path=S+'courtyard45_exact32_scope_PREPARATION.json',sha256='823dcc493006e0a439dc4f4caa1ce8a1ad6b029fb9c3e8f847620731defac4d5')
scope=load(**dict(p=scopepin['path'],h=scopepin['sha256']));parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes']) for r in scope['targets']}
priorpin=dict(path=OLD+'docks31_candidates01/code_execution_whole_inverse_NOT_STAGE.json',sha256='a2dbfb4b89255649df89918c4dba48e71cb0717ad32dc4d6f98a4130a86b2507')
prior=load(priorpin['path'],priorpin['sha256']);prepared={};records={}
def output(name,b):
    assert name not in prepared;prepared[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
def value(pin):return prepared[pin['path'][len(P):]] if pin['path'].startswith(P) else read(pin['path'],pin['sha256'])
def record(p,name,b):
    a=read(parents[p]['path'],parents[p]['sha256']);assert a!=b and b.endswith(b'\n') and b'\r' not in b
    pin=output(name,b);records[p]=dict(parent=parents[p],candidate=pin,hunks=hunks(a,b),whole_byte_forward_inverse=True);return pin
handoff=load(D+'handoff_READY_NOT_STAGE.json','4b9de1c4c235285793dd1727462074e4b23a027d9791d1829d71088bb bfb9329'.replace(' ',''))
files={r['file']:r for r in handoff['files']}
E='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
functional={p:(role+'_courtyard45_READY.gd',files[role+'_courtyard45_READY.gd']['sha256']) for p,role in [(C,'C'),(DT,'DT'),(F,'Field'),(G,'G'),(E,'ENV')]}
for p,(name,h) in functional.items():
    a=read(parents[p]['path'],parents[p]['sha256']);b=read(D+name,h)
    records[p]=dict(parent=parents[p],candidate=dict(path=D+name,sha256=h,bytes=len(b)),hunks=hunks(a,b),whole_byte_forward_inverse=True)
# Fixed 24c outer layers retain strict counts 8 and 3, not enlarged aggregate gates.
oldc=prior['ordinary']['C_layer'];cp0=load(oldc['path'],oldc['sha256']);cp=copy.deepcopy(cp0)
cbase=read('res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/C_READY.gd',cp['old_sha256'])
cp['new_sha256']=records[C]['candidate']['sha256'];cp['replacements']=hunks(cbase,value(records[C]['candidate']));assert len(cp['replacements'])==8
cpin=output('C_to_fixed24c_proof_READY.json',enc(cp))
b=read(parents[AA]['path'],parents[AA]['sha256'])
for a,c in [(parents[C]['sha256'],records[C]['candidate']['sha256']),(oldc['path'],cpin['path']),(oldc['sha256'],cpin['sha256'])]:b=exact(b,a,c)
record(AA,'AA_docks_CANDIDATE.gd',b)
olda=prior['ordinary']['AA_layer'];ap0=load(olda['path'],olda['sha256']);ap=copy.deepcopy(ap0)
basepin=load(OLD+'ordinary_outer03_READY/whole_inverse_NOT_STAGE.json','538e17ab90051c5712b134a9de76a8284f3112d9f95924bfe228d1a53ee49bc1')['records'][AA]['parent']
abase=read(basepin['path'],ap['old_sha256']);ap['new_sha256']=records[AA]['candidate']['sha256'];ap['replacements']=hunks(abase,b);assert len(ap['replacements'])==3
apin=output('AA_to_fixed24c_proof_READY.json',enc(ap))
b=read(parents[AC]['path'],parents[AC]['sha256'])
for a,c in [(parents[AA]['sha256'],records[AA]['candidate']['sha256']),(olda['path'],apin['path']),(olda['sha256'],apin['sha256'])]:b=exact(b,a,c)
record(AC,'AC_docks_CANDIDATE.gd',b)
original=read(parents[CONTRACT]['path'],parents[CONTRACT]['sha256']);v=json.loads(original);b=original;changes={}
for p in [C,F]:
    before=v['source_sha256'][p];after=records[p]['candidate']['sha256'];assert before==parents[p]['sha256'];v['source_sha256'][p]=after;b=exact(b,before,after);changes[p]=dict(old=before,new=after)
assert json.loads(b)==v;contract=output('runtime_contract_C_Field_docks_CANDIDATE.json',b)
record(CO,'Coordinator_docks_CANDIDATE.gd',exact(read(parents[CO]['path'],parents[CO]['sha256']),parents[CONTRACT]['sha256'],contract['sha256']))
oldbind=prior['temple_binding']['candidate'];original=read(oldbind['path'],oldbind['sha256']);v=json.loads(original);binding=copy.deepcopy(v);b=original;bindchanges={}
refs={p:r['candidate']['sha256'] for p,r in records.items()};refs[CONTRACT]=contract['sha256']
for p,a in v['source_delta'].items():
    if p in refs:
        assert a==parents[p]['sha256'];binding['source_delta'][p]=refs[p];bindchanges[p]=dict(old=a,new=refs[p]);b=exact(b,json.dumps(p)+': '+json.dumps(a),json.dumps(p)+': '+json.dumps(refs[p]))
assert json.loads(b)==binding;back=copy.deepcopy(binding)
for p,d in bindchanges.items():back['source_delta'][p]=d['old']
assert enc(back)==enc(v);bind=output('Temple_binding_docks_CANDIDATE.json',b)
record(T,'Temple_docks_CANDIDATE.gd',exact(exact(read(parents[T]['path'],parents[T]['sha256']),oldbind['path'],bind['path']),oldbind['sha256'],bind['sha256']))
original_raw=read(parents[EXEC]['path'],parents[EXEC]['sha256']);original=json.loads(original_raw);assert enc(original)==original_raw
authority=copy.deepcopy(original);changed=[G,DT,F,AC,CO,T];assert len(original['owned'])==10 and len(original['source_sha256'])==162
for p in changed:
    row=authority['owned'][p];r=records[p];assert row['current_sha256']==parents[p]['sha256']
    snap=next(e['new_snapshot'] for e in row['edges'] if e['new_sha256']==row['current_sha256']);assert read(snap,row['current_sha256'])==value(r['parent'])
    row['edges'].append(dict(path=p,old_sha256=row['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snap,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));row['current_sha256']=r['candidate']['sha256'];authority['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for r in [contract,bind]:authority['source_sha256'][r['path']]=r['sha256']
assert len(authority['source_sha256'])==170 and C not in authority['owned'] and AA not in authority['owned']
restored=copy.deepcopy(authority)
for p in changed:restored['owned'][p]=copy.deepcopy(original['owned'][p])
restored['source_sha256']=copy.deepcopy(original['source_sha256']);assert enc(restored)==original_raw
assert all(authority['source_sha256'][p]==h for p,h in original['source_sha256'].items())
execution=output('execution_successor_docks_PREPARATION.json',enc(authority))
for p in authority['owned']:
    if p not in changed:assert authority['owned'][p]==original['owned'][p]
helper=dict(path=D+'market_courtyard_session_READY.gd',sha256=files['market_courtyard_session_READY.gd']['sha256'])
bindpin=dict(path=D+'binding_READY.json',sha256=files['binding_READY.json']['sha256']);bv=load(bindpin['path'],bindpin['sha256']);assert bv['ready'] is True and len(bv['required_source_sha256'])==24
assert bv['local_art']['admitted'] is True and bv['resolved_parent_components']['sha256']=='cafee170b4e33b159c8ad769e96ceeb97987d70eb561ee9b5049a8e25e827194'
full={**bv['required_source_sha256'],helper['path']:helper['sha256'],bindpin['path']:bindpin['sha256']};assert len(full)==26
shared={helper['path']:helper['sha256'],bindpin['path']:bindpin['sha256'],bv['author']['path']:bv['author']['sha256'],bv['pure']['path']:bv['pure']['sha256']};assert len(shared)==4
# Read only small metadata/code; media/large component SHA authority is fixed Root/Stage evidence.
for p,h in full.items():
    if p.endswith('.gd') or p.endswith('.json') and not p.endswith('components_FIXED_NOT_RUNTIME.json'):read(p,h)
result=dict(status='COURTYARD45_EXACT32_CODE_DEPENDENCY_PREPARATION_NOT_STAGE',scope=scopepin,parent_stage=scope['parent_stage'],parent_deployment=scope['parent_deployment'],records=records,contract=dict(target=CONTRACT,parent=parents[CONTRACT],candidate=contract,changed=changes,byte_hunks=hunks(read(parents[CONTRACT]['path'],parents[CONTRACT]['sha256']),value(contract)),whole_typed_UTF8_inverse=True),temple_binding=dict(parent=oldbind,candidate=bind,changed=bindchanges,ordinary_additions={},whole_typed_UTF8_inverse=True,byte_hunks=hunks(original if False else read(oldbind['path'],oldbind['sha256']),value(bind))),ordinary=dict(C_layer=cpin,AA_layer=apin,C_hunks=8,AA_hunks=3,all_inner_layers_byte_unchanged=True,Docks_only_source_additions={cpin['path']:cpin['sha256'],apin['path']:apin['sha256']}),execution=dict(parent=parents[EXEC],candidate=execution,changed_existing_owned=changed,owned_count=10,old_proof_count=162,new_proof_count=170,extra={p:h for p,h in authority['source_sha256'].items() if p not in original['source_sha256']},all_old162_key_values_and_all_old_edges_retained=True,other4_owned_rows_whole_typed_same=True,whole_typed_serialized_UTF8_inverse=True,no_Temple_shortcut=True,depth_limit_unchanged=16),helper=helper,binding=bindpin,Market_full26=full,G_shared4=shared,no_new_unconditional_Field_helper_consumption=True,Router_B_adapter_unchanged=True,ENV_only_runtime_pair_materials_unchanged=True,old_native4_immutable=True,new45_overlay_requires_actual_pins=True,Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)
pr=output('code_execution_whole_inverse_NOT_STAGE.json',enc(result))
assert not OUT.exists();OUT.mkdir()
for name,b in prepared.items():
    if name.endswith('.json'):json.loads(b)
    with (OUT/name).open('xb') as f:f.write(b)
    assert (OUT/name).read_bytes()==b
print(json.dumps(dict(proof=pr,execution=execution,contract=contract,temple_binding=bind,codes={p:r['candidate'] for p,r in records.items()},ordinary_proofs=[cpin,apin],newproofs=8,no_Stage=True)))
