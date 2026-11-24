"""Root-approved code/literal preparation only; fixed D596 parent, no Stage."""
from pathlib import Path
import json,hashlib,copy,difflib,re
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/';OUT=HERE/'prewarm_profile29_candidates01';P=S+OUT.name+'/'
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';F='res://scripts/field/field_walkable_controller.gd';ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd';CO='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';T='res://scripts/city/luoyang_temple_assembly_20261016.gd'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),p;assert b'tokens truncated' not in b;return b
def load(p,h):return json.loads(read(p,h))
def exact(b,a,c,count=1):
    a,c=a.encode(),c.encode();assert a!=c and b.count(a)==count,(a,b.count(a),count);return b.replace(a,c)
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
        x=''.join(al[group[0][1]:group[-1][2]]);y=''.join(bl[group[0][3]:group[-1][4]])
        assert x and y and a.count(x.encode())==b.count(y.encode())==1;ops.append(dict(old=x,new=y))
    inverse(a,b,ops);assert max(max(len(r['old']),len(r['new'])) for r in ops)<18000;return ops
scopepin=dict(path=S+'prewarm_profile29_scope_PREPARATION.json',sha256='cd4e04275838a9652617ea62204a2e2fa34c124d422a87a05bb2f97dedb1beca')
scope=load(scopepin['path'],scopepin['sha256']);parents={r['target']:dict(path=r['immutable_old'],sha256=r['old_sha256'],bytes=r['old_bytes']) for r in scope['targets']}
priorpin=dict(path=S+'dependencies33_session03_READY/code_execution_whole_inverse_NOT_STAGE.json',sha256='75e1e02ce64de019be6fa544afc62cfb8967370809f45095de952dbfa668997f')
prior=load(priorpin['path'],priorpin['sha256'])
oldhelper='res://build/luoyang_loading_20261024e_perf01/candidate03/gate_source_prewarm02.gd';oldhh='03dec03dbfdd572042e566848d3231de56c1c45583fac4644cfccd99b3a81ed8'
helper='res://build/luoyang_loading_20261024e_perf01/candidate04/gate_source_prewarm04.gd';hh='d81ecdbb6e333886f50ad19aea8612791d64eee47300088521a9a7dac4b31778';read(helper,hh)
prepared={};records={}
def output(name,b):
    assert name not in prepared;prepared[name]=b;return dict(path=P+name,sha256=sha(b),bytes=len(b))
def bytes_for(pin):return prepared[pin['path'][len(P):]] if pin['path'].startswith(P) else read(pin['path'],pin['sha256'])
def record(p,name,b):
    a=read(parents[p]['path'],parents[p]['sha256']);assert a!=b and b.endswith(b'\n') and b'\r' not in b
    pin=output(name,b);records[p]=dict(parent=parents[p],candidate=pin,hunks=hunks(a,b),whole_byte_forward_inverse=True);return pin
for p,name,count in [(C,'C_prewarm8_CANDIDATE.gd',1),(F,'Field_prewarm8_CANDIDATE.gd',2)]:
    record(p,name,exact(read(parents[p]['path'],parents[p]['sha256']),oldhelper,helper,count))
# ENV current READY boundaries/runtime remain unchanged; only four approved source literals.
profilepin=dict(path='res://build/luoyang_city_blocks_20261024e_system01/profile04_ENV05_whole_inverse_BUILD.json',sha256='e7306b8f16aef5afd9bb865f1f1a1f0ecf40abb3666f456d01d87a8cd008b78e')
profile=load(profilepin['path'],profilepin['sha256']);envrow=profile['entries'][2];b=read(parents[ENV]['path'],parents[ENV]['sha256'])
for r in envrow['replacements']:b=exact(b,r['old'],r['new'])
record(ENV,'ENV_profile04_CANDIDATE.gd',b)
purpose={r['candidate']:r['candidate_sha256'] for r in profile['entries'][:2]}
for p,h in purpose.items():read(p,h)
# New exact documents reuse the existing strict outer-layer shape/counts.
oldordinary=load(S+'ordinary_outer03_READY/whole_inverse_NOT_STAGE.json','538e17ab90051c5712b134a9de76a8284f3112d9f95924bfe228d1a53ee49bc1')
cp0=load(oldordinary['C_layer']['path'],oldordinary['C_layer']['sha256']);cp=copy.deepcopy(cp0)
cbase=read('res://build/luoyang_yamen_courts_20261024c_system01/runtime04_READY/C_READY.gd',cp['old_sha256'])
cp['new_sha256']=records[C]['candidate']['sha256'];cp['replacements']=hunks(cbase,bytes_for(records[C]['candidate']));assert len(cp['replacements'])==len(cp0['replacements'])==8
cpin=output('C_to_fixed24c_proof_READY.json',enc(cp))
b=read(parents[AA]['path'],parents[AA]['sha256'])
for a,c in [(records[C]['parent']['sha256'],records[C]['candidate']['sha256']),(oldordinary['C_layer']['path'],cpin['path']),(oldordinary['C_layer']['sha256'],cpin['sha256'])]:b=exact(b,a,c)
record(AA,'AA_prewarm8_CANDIDATE.gd',b)
ap0=load(oldordinary['AA_layer']['path'],oldordinary['AA_layer']['sha256']);ap=copy.deepcopy(ap0)
abase=read(oldordinary['records'][AA]['parent']['path'],ap['old_sha256']);ap['new_sha256']=records[AA]['candidate']['sha256'];ap['replacements']=hunks(abase,b);assert len(ap['replacements'])==len(ap0['replacements'])==3
apin=output('AA_to_fixed24c_proof_READY.json',enc(ap))
b=read(parents[AC]['path'],parents[AC]['sha256'])
for a,c in [(records[AA]['parent']['sha256'],records[AA]['candidate']['sha256']),(oldordinary['AA_layer']['path'],apin['path']),(oldordinary['AA_layer']['sha256'],apin['sha256'])]:b=exact(b,a,c)
record(AC,'AC_prewarm8_CANDIDATE.gd',b)
# Existing C2/AA3/24c layers are untouched; only existing outer proof3 literals change.
original=read(parents[CONTRACT]['path'],parents[CONTRACT]['sha256']);contractv=json.loads(original);b=original;changes={}
for p in [C,F]:
    before=contractv['source_sha256'][p];after=records[p]['candidate']['sha256'];assert before==parents[p]['sha256'];contractv['source_sha256'][p]=after;b=exact(b,before,after);changes[p]=dict(old=before,new=after)
assert json.loads(b)==contractv;contract=output('runtime_contract_C_Field_prewarm8_CANDIDATE.json',b)
record(CO,'Coordinator_prewarm8_CANDIDATE.gd',exact(read(parents[CO]['path'],parents[CO]['sha256']),parents[CONTRACT]['sha256'],contract['sha256']))
oldbind=prior['temple_binding']['candidate'];original=read(oldbind['path'],oldbind['sha256']);v=json.loads(original);binding=copy.deepcopy(v);b=original;bindchanges={}
refs={p:r['candidate']['sha256'] for p,r in records.items()};refs[CONTRACT]=contract['sha256']
for p,a in v['source_delta'].items():
    if p in refs:
        assert a==parents[p]['sha256'];binding['source_delta'][p]=refs[p];bindchanges[p]=dict(old=a,new=refs[p]);b=exact(b,json.dumps(p)+': '+json.dumps(a),json.dumps(p)+': '+json.dumps(refs[p]))
assert v['source_delta'][oldhelper]==oldhh and helper not in v['source_delta'];binding['source_delta'][helper]=hh
marker=re.search(rb'  "source_delta": \{(\r?\n)',original);assert marker;token=marker.group(0);line=('    '+json.dumps(helper)+': '+json.dumps(hh)+',').encode()+marker.group(1)
assert b.count(token)==1;b=b.replace(token,token+line,1);assert json.loads(b)==binding
back=copy.deepcopy(binding)
for p,d in bindchanges.items():back['source_delta'][p]=d['old']
del back['source_delta'][helper];assert back==v
bind=output('Temple_binding_prewarm8_profile04_CANDIDATE.json',b)
record(T,'Temple_prewarm8_profile04_CANDIDATE.gd',exact(exact(read(parents[T]['path'],parents[T]['sha256']),oldbind['path'],bind['path']),oldbind['sha256'],bind['sha256']))
original_raw=read(parents[EXEC]['path'],parents[EXEC]['sha256']);original=json.loads(original_raw);assert enc(original)==original_raw
authority=copy.deepcopy(original);changed=[F,AC,CO,T];assert len(original['owned'])==10 and len(original['source_sha256'])==148
for p in changed:
    row=authority['owned'][p];r=records[p];assert row['current_sha256']==parents[p]['sha256']
    snap=next(e['new_snapshot'] for e in row['edges'] if e['new_sha256']==row['current_sha256']);assert read(snap,row['current_sha256'])==read(r['parent']['path'],r['parent']['sha256'])
    row['edges'].append(dict(path=p,old_sha256=row['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snap,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']));row['current_sha256']=r['candidate']['sha256'];authority['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for r in [contract,bind]:authority['source_sha256'][r['path']]=r['sha256']
assert len(authority['source_sha256'])==154 and C not in authority['owned'] and AA not in authority['owned'] and ENV not in authority['owned']
restored=copy.deepcopy(authority)
for p in changed:restored['owned'][p]=copy.deepcopy(original['owned'][p])
restored['source_sha256']=copy.deepcopy(original['source_sha256']);assert restored==original and enc(restored)==original_raw
assert all(authority['source_sha256'][p]==h for p,h in original['source_sha256'].items())
execution=output('execution_successor_prewarm8_profile04_PREPARATION.json',enc(authority))
for p in authority['owned']:
    if p not in changed:assert authority['owned'][p]==original['owned'][p]
assert len(authority['owned'][T]['edges'])==19
result=dict(status='EXACT29_SEVEN_CODE_LITERALS_FOUR_OWNED_PREPARATION_NOT_STAGE',scope=scopepin,records=records,contract=dict(target=CONTRACT,parent=parents[CONTRACT],candidate=contract,changed=changes,whole_typed_UTF8_inverse=True,byte_hunks=hunks(read(parents[CONTRACT]['path'],parents[CONTRACT]['sha256']),bytes_for(contract))),temple_binding=dict(parent=oldbind,candidate=bind,changed=bindchanges,ordinary_additions={helper:hh},old_helper_retained=True,whole_typed_UTF8_inverse=True,byte_hunks=hunks(read(oldbind['path'],oldbind['sha256']),bytes_for(bind))),ordinary=dict(C_layer=cpin,AA_layer=apin,C_hunks=8,AA_hunks=3,all_inner_layers_byte_unchanged=True,Docks_only_source_additions={cpin['path']:cpin['sha256'],apin['path']:apin['sha256']}),execution=dict(parent=parents[EXEC],candidate=execution,changed_existing_owned=changed,owned_count=10,old_proof_count=148,new_proof_count=154,extra={p:h for p,h in authority['source_sha256'].items() if p not in original['source_sha256']},all_old148_key_values_and_all_old_edges_retained=True,other6_owned_rows_whole_typed_same=True,whole_typed_serialized_UTF8_inverse=True,no_Temple_shortcut=True,actual_required_Temple_depth_max=3),helper=dict(path=helper,sha256=hh,old_helper=dict(path=oldhelper,sha256=oldhh),ordinary=True),purpose_ordinary_sources=purpose,profile_proof=profilepin,no_new_functional_hunks_beyond_approved_helper_worker8_and_profile4=True,C_AA_ENV_nonowned=True,geometry_native_mask_registry_DT_G_Router_UI_frozen=True,Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)
pr=output('code_execution_whole_inverse_NOT_STAGE.json',enc(result))
assert not OUT.exists();OUT.mkdir()
for name,b in prepared.items():
    with (OUT/name).open('xb') as f:f.write(b)
    assert (OUT/name).read_bytes()==b
print(json.dumps(dict(proof=pr,execution=execution,contract=contract,temple_binding=bind,codes={p:r['candidate'] for p,r in records.items()},ordinary_proofs=[cpin,apin],no_Stage=True)))
