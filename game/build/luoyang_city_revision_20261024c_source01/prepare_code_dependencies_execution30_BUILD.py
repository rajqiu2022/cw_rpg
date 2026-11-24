"""Final seven code successors, exact culture/Temple literals and five old owned edges."""
from pathlib import Path
import hashlib,json,copy
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_revision_20261024c_source01/'
Y='res://build/luoyang_yamen_courts_20261024c_system01/'
OUT=HERE/'code_dependencies30_READY';OUT.mkdir(exist_ok=False);PREFIX=S+'code_dependencies30_READY/'
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';DT='res://scripts/city/luoyang_district_life_20261016f.gd';FIELD='res://scripts/field/field_walkable_controller.gd'
AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd';AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
COORD='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd';TEMPLE='res://scripts/city/luoyang_temple_assembly_20261016.gd'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h and b'tokens truncated' not in b,(p,sha(b));return b
def load(p,h):return json.loads(read(p,h))
def out(name,b):
    p=OUT/name
    with p.open('xb') as f:f.write(b)
    assert p.read_bytes()==b
    return dict(path=PREFIX+name,sha256=sha(b),bytes=len(b))
def exact(b,a,c):
    a,c=a.encode(),c.encode();assert a!=c and b.count(a)==1;return b.replace(a,c,1)
def inverse(before,after,hunks):
    f,i=before.decode(),after.decode()
    for h in hunks:
        assert f.count(h['old'])==1;f=f.replace(h['old'],h['new'],1)
    for h in reversed(hunks):
        assert i.count(h['new'])==1;i=i.replace(h['new'],h['old'],1)
    assert f.encode()==after and i.encode()==before
baseline=load(S+'current24b_formal_target_declarations_READONLY.json','4b591c8043820fd4ccc0d614a33dce6b3c9a53ae28f30de6937751e9e38c7fb7')
parents={r['target']:dict(path=r['immutable_snapshot'],sha256=r['old_sha256']) for r in baseline['targets']}
sys=load(Y+'runtime02/whole_byte_inverse_NOTREADY.json','7421707e7a78ea98bafc3da6ba74931461be6a18be3f978651f9bb65e8cb77c3')
handoff=load(Y+'runtime04_READY/handoff_READY.json','e882ad1ff64bd784abb45dc87b34e79c1f7a5c9d75e4eb523dfdda7c0ea520a8')
ordinary=load(S+'ordinary_layers02_READY/layered_ordinary_whole_byte_inverse_NOTREADY.json','706ef2e8ce3dd5094fcb89870ad3eee889e96855248e917b2d84dddb99847523')
field=load(S+'Field_courts_scholar_wholebyte_inverse_NOTREADY.json','431d92a9480e8cd138d415efe080a720fb6b86adad174e0d654edf504255189c')
records={}
def record(p,name,candidate,hunks):
    a=read(parents[p]['path'],parents[p]['sha256']);b=read(candidate['path'],candidate['sha256']);inverse(a,b,hunks)
    assert b.endswith(b'\n') and b'\r' not in b
    records[p]=dict(name=name,parent=parents[p],candidate={**candidate,'bytes':len(b)},hunks=hunks,wholebyte_forward_inverse=True)
for name,p,filename,h in [('C',C,'C_READY.gd','f389b2e12e839d9005c3ac7643b69921ea31d9b7cc66d9194be0ab18c0d8b5d1'),('DT',DT,'DT_READY_exactEOL.gd','67308668f0667d5807446f56f7953f63be87a49d78bc77a1e5ef3c61c5dd29b0')]:
    hunks=copy.deepcopy(sys['candidates'][name]['replacements'])
    for r in hunks:r['new']=r['new'].replace(Y+'runtime02/courts_session_NOTREADY.gd',Y+'runtime04_READY/courts_session_READY.gd').replace('ab031d7c6f9630a91f2e2c8ba705d1eb753d3c5df04f7c421d8fcbd0ee70ed49','791ae73e97623e71c0a0445f7a60cd14b6bf8f17453e7fa77dd9d0a89a873c4a')
    record(p,name,dict(path=Y+'runtime04_READY/'+filename,sha256=h),hunks)
assert len(records[C]['hunks'])==3 and max(len(r['new']) for r in records[C]['hunks'])<2500
# The portrait proof retains the two System Field hooks, then its one exact-ID portrait line.
field_hunks=field['combined_replacements']
record(FIELD,'Field',dict(path=S+'Field_courts_scholar_CANDIDATE.gd',sha256='ad2a3569f8fc0b570dc288dff6da7a7b3222c103ede041c7de54d781900bb575'),field_hunks)
for name,p in [('AA',AA),('AC',AC)]:record(p,name,ordinary[name]['candidate'],ordinary[name]['hunks'])
before=read(parents[CONTRACT]['path'],parents[CONTRACT]['sha256']);original=json.loads(before);typed=copy.deepcopy(original);raw=before
changes={}
for p in [C,FIELD]:
    a=original['source_sha256'][p];b=records[p]['candidate']['sha256'];assert a==parents[p]['sha256']
    raw=exact(raw,a,b);typed['source_sha256'][p]=b;changes[p]=dict(old_sha256=a,new_sha256=b)
assert json.loads(raw)==typed
back=raw
for d in reversed(list(changes.values())):back=exact(back,d['new_sha256'],d['old_sha256'])
assert back==before
contract=out('runtime_contract_C_Field_CANDIDATE.json',raw)
a=read(parents[COORD]['path'],parents[COORD]['sha256']);b=exact(a,parents[CONTRACT]['sha256'],contract['sha256']);coord=out('Coordinator_CANDIDATE.gd',b)
record(COORD,'Coordinator',coord,[dict(old=parents[CONTRACT]['sha256'],new=contract['sha256'])])
oldbp='res://build/luoyang_city_space_20261024b_source01/packed_dependencies04/temple_binding_C_Coord_contract_CANDIDATE.json';oldbh='31d93061ff74ad0fcaafe0cd62f145b5ca89d85b8c36e69a4607d5a7658145a5'
before=read(oldbp,oldbh);oldbind=json.loads(before);binding=copy.deepcopy(oldbind);raw=before
binding_changes={}
for p,h in [(C,records[C]['candidate']['sha256']),(FIELD,records[FIELD]['candidate']['sha256']),(COORD,coord['sha256']),(CONTRACT,contract['sha256'])]:
    a=oldbind['source_delta'][p];raw=exact(raw,a,h);binding['source_delta'][p]=h;binding_changes[p]=dict(old_sha256=a,new_sha256=h)
assert json.loads(raw)==binding and set(binding['source_delta'])==set(oldbind['source_delta'])
back=raw
for d in reversed(list(binding_changes.values())):back=exact(back,d['new_sha256'],d['old_sha256'])
assert back==before
bind=out('temple_binding_C_Field_Coord_contract_CANDIDATE.json',raw)
a=read(parents[TEMPLE]['path'],parents[TEMPLE]['sha256']);b=exact(exact(a,oldbp,bind['path']),oldbh,bind['sha256']);temple=out('Temple_CANDIDATE.gd',b)
record(TEMPLE,'Temple',temple,[dict(old=oldbp,new=bind['path']),dict(old=oldbh,new=bind['sha256'])])
before=read(parents[EXEC]['path'],parents[EXEC]['sha256']);original=json.loads(before);assert enc(original)==before
authority=copy.deepcopy(original);changed=[DT,FIELD,AC,COORD,TEMPLE]
assert len(authority['owned'])==10 and C not in authority['owned'] and AA not in authority['owned'] and len(authority['source_sha256'])==132
for p in changed:
    row=authority['owned'][p];r=records[p];assert row['current_sha256']==r['parent']['sha256']
    snap=next(e['new_snapshot'] for e in row['edges'] if e['new_sha256']==row['current_sha256'])
    assert read(snap,row['current_sha256'])==read(r['parent']['path'],r['parent']['sha256'])
    row['edges'].append(dict(path=p,old_sha256=row['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snap,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']))
    row['current_sha256']=r['candidate']['sha256'];authority['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for r in [contract,bind]:authority['source_sha256'][r['path']]=r['sha256']
assert len(authority['source_sha256'])==139
restored=copy.deepcopy(authority)
for p in changed:restored['owned'][p]=copy.deepcopy(original['owned'][p])
restored['source_sha256']=copy.deepcopy(original['source_sha256']);assert restored==original and enc(restored)==before
execution=out('execution_successor_PREPARATION.json',enc(authority))
report=dict(status='24C_EXACT30_SEVEN_CODE_FIVE_OWNED_SOURCE_PREPARATION_NOT_STAGE',ready=False,records=records,
 execution=dict(parent=parents[EXEC],candidate=execution,changed_existing_owned=changed,owned_count=10,prior_proof_count=132,new_proof_count=139,extra={p:h for p,h in authority['source_sha256'].items() if p not in original['source_sha256']},whole_typed_and_serialized_UTF8_inverse=True,other_five_owned_rows_unchanged=True),
 contract=dict(target=CONTRACT,parent=parents[CONTRACT],candidate=contract,changed=changes,wholebyte_and_typed_inverse=True),
 temple_binding=dict(parent=dict(path=oldbp,sha256=oldbh),candidate=bind,changed=binding_changes,no_new_source_keys=True,wholebyte_and_typed_inverse=True),
 courts_handoff=dict(path=Y+'runtime04_READY/handoff_READY.json',sha256='e882ad1ff64bd784abb45dc87b34e79c1f7a5c9d75e4eb523dfdda7c0ea520a8'),
 ordinary_layers=dict(path=S+'ordinary_layers02_READY/layered_ordinary_whole_byte_inverse_NOTREADY.json',sha256='706ef2e8ce3dd5094fcb89870ad3eee889e96855248e917b2d84dddb99847523'),
 no_C_AA_ownership=True,original_native_artifacts_and_record_unchanged=True,engine_calls=0,Stage_calls=0,collector_calls=0,canonical_writes=0)
proof=out('seven_code_execution_whole_inverse_NOT_STAGE.json',enc(report))
print(json.dumps(dict(proof=proof,execution=execution,contract=contract,temple_binding=bind,codes=7,owned_edges=5,proofs=139)))
