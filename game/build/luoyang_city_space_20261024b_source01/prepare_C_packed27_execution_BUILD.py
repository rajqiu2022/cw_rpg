"""Five exact code successors, only AC/Coordinator/Temple owned edges."""
from pathlib import Path
import json,hashlib,copy,difflib
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/';R='res://build/luoyang_city_revision_20261024b_root01/';D='res://build/luoyang_docks_ordinary_space_20261024b_system01/READY05/'
OUT=HERE/'packed_closure27';OUT.mkdir(exist_ok=False)
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=(GAME/p[6:]).read_bytes();assert h is None or sha(b)==h;assert b'tokens truncated' not in b;return b
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def output(name,b):
    with (OUT/name).open('xb') as f:f.write(b)
    return dict(path=S+'packed_closure27/'+name,sha256=sha(b),bytes=len(b))
def hunks(a,b):
    x,y=a.decode().splitlines(keepends=True),b.decode().splitlines(keepends=True)
    for context in [3,6,12,24,48,96,max(len(x),len(y))]:
        rows=[dict(old=''.join(x[g[0][1]:g[-1][2]]),new=''.join(y[g[0][3]:g[-1][4]])) for g in difflib.SequenceMatcher(None,x,y,autojunk=False).get_grouped_opcodes(context)]
        f,i=a.decode(),b.decode();good=True
        for r in rows:
            if f.count(r['old'])!=1 or i.count(r['new'])!=1:good=False;break
            f=f.replace(r['old'],r['new'],1);i=i.replace(r['new'],r['old'],1)
        if good and f.encode()==b and i.encode()==a:return rows
    raise AssertionError('WHOLE_BYTE_INVERSE')
old=json.loads(read(S+'worker_facts_closure35/code_execution_full_inverse_NOT_STAGE.json','ab2e5b657d465407c8375d6b060b1510162fb426a6387acd6ac11934386225db'))
dep=json.loads(read(S+'packed_dependencies04/dependency_literal_inverse_BUILD.json','71bd2a710974a2ddbd15ceb9d3b2d3ab37261b5a97441f28c327322429433ca4'))
backup=json.loads(read(R+'packed_predeploy27/backup_receipt.json','e35d93961b34bf321dcd0790c1afa58697efa5c1f34667afeb03cf4ff2d685ce'))
backed={r['target']:r for r in backup['records']};assert len(backed)==27
candidates=dict(C=dict(path=S+'C_finite_packed_polygon_CANDIDATE.gd',sha256='b9b68f2e1daddc7dd8f19c683bd932048fda3b547e475001c854d23bfd7965b5'),
    AA=dict(path=D+'AA_ordinary_C_READY_CANDIDATE.gd',sha256='0fa220574ada95916f7e89cd0bb4a725c07810d4a5b50d35b2069363cb24e612'),
    AC=dict(path=D+'AC_ordinary_AA_READY_CANDIDATE.gd',sha256='9b99cddf16b108c20cd487d77d00f07fe5c72398a776642f3eaaab65442f421e'),
    Coordinator=dep['coordinator']['candidate'],Temple=dep['temple']['candidate'])
records={}
for p,row in old['records'].items():
    name=row['name']
    if name not in candidates:continue
    parent=row['candidate'];a=read(parent['path'],parent['sha256']);r=backed[p];assert sha(a)==r['sha256']==r['backup_sha256'] and len(a)==r['bytes'] and Path(r['backup_path']).read_bytes()==a
    c=candidates[name];b=read(c['path'],c['sha256']);c['bytes']=len(b);assert b.endswith(b'\n') and b'\r' not in b
    records[p]=dict(name=name,parent=parent,candidate=c,hunks=hunks(a,b),wholebyte_forward_inverse=True)
assert len(records)==5
prior=old['execution']['candidate'];before=read(prior['path'],prior['sha256']);original=json.loads(before);assert enc(original)==before
authority=copy.deepcopy(original);changed=[p for p,r in records.items() if r['name'] in ['AC','Coordinator','Temple']];assert len(changed)==3
for p in changed:
    row=authority['owned'][p];r=records[p];assert row['current_sha256']==r['parent']['sha256']
    snap=next(e['new_snapshot'] for e in row['edges'] if e['new_sha256']==row['current_sha256'])
    assert read(snap,row['current_sha256'])==read(r['parent']['path'],r['parent']['sha256'])
    row['edges'].append(dict(path=p,old_sha256=row['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snap,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']))
    row['current_sha256']=r['candidate']['sha256'];authority['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for r in [dep['contract']['candidate'],dep['temple_binding']['candidate']]:authority['source_sha256'][r['path']]=r['sha256']
assert len(original['source_sha256'])==127 and len(authority['source_sha256'])==132 and len(authority['owned'])==10
restored=copy.deepcopy(authority)
for p in changed:restored['owned'][p]=copy.deepcopy(original['owned'][p])
restored['source_sha256']=copy.deepcopy(original['source_sha256']);assert restored==original and enc(restored)==before
execution=output('execution_successor_PREPARATION.json',enc(authority))
proof=dict(status='C_PACKED27_EXACT_CODE_EXECUTION_INVERSE_NOT_STAGE',ready=False,records=records,
    execution=dict(parent=prior,candidate=execution,changed_existing_owned=changed,owned_count=10,prior_proof_count=127,new_proof_count=132,
        extra={p:h for p,h in authority['source_sha256'].items() if p not in original['source_sha256']},whole_typed_and_serialized_UTF8_inverse=True,other_seven_owned_rows_unchanged=True),
    contract=dep['contract'],temple_binding=dep['temple_binding'],root_backup=dict(path=R+'packed_predeploy27/backup_receipt.json',sha256='e35d93961b34bf321dcd0790c1afa58697efa5c1f34667afeb03cf4ff2d685ce'),
    C_AA_nonowned=True,native_media_runtime_adapter_Field_and_UI_unchanged=True,
    CPU_actual=dict(path='res://build/luoyang_city_revision_20261024b_qa01/packed_polygon_aggregate_ROOT_READY/output_READY/45048_1820/result.json',sha256='43c07cd6563973614aae3aad81c17a9b45740ff8d53e7742bc057667b1d28e4d',checks=239,failures=0),
    Stage_calls=0,engine_calls=0,collector_calls=0,canonical_writes=0)
review=output('code_execution_full_inverse_NOT_STAGE.json',enc(proof));print(json.dumps(dict(proof=review,execution=execution,codes=5,changed_owned=3,proofs=132)))
