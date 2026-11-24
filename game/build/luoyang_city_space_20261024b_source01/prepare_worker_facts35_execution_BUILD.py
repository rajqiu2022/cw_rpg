"""Exact deployed516C succession; seven old members, nine new proof leaves."""
from pathlib import Path
import json,hashlib,copy,difflib
GAME=Path(__file__).resolve().parents[2];HERE=Path(__file__).resolve().parent
S='res://build/luoyang_city_space_20261024b_source01/';R='res://build/luoyang_city_revision_20261024b_root01/'
D='res://build/luoyang_docks_ordinary_space_20261024b_system01/READY04/'
OUT=HERE/'worker_facts_closure35';OUT.mkdir(exist_ok=False)
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h=None):
    b=(GAME/p[6:]).read_bytes();assert h is None or sha(b)==h;assert b'tokens truncated' not in b;return b
def encode(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def output(name,b):
    with (OUT/name).open('xb') as stream:stream.write(b)
    return dict(path=S+'worker_facts_closure35/'+name,sha256=sha(b),bytes=len(b))
def hunks(a,b):
    left,right=a.decode('utf8').splitlines(keepends=True),b.decode('utf8').splitlines(keepends=True)
    for ctx in [3,6,12,24,48,96,max(len(left),len(right))]:
        rows=[dict(old=''.join(left[g[0][1]:g[-1][2]]),new=''.join(right[g[0][3]:g[-1][4]])) for g in difflib.SequenceMatcher(None,left,right,autojunk=False).get_grouped_opcodes(ctx)]
        f,i=a.decode('utf8'),b.decode('utf8');ok=True
        for r in rows:
            if f.count(r['old'])!=1 or i.count(r['new'])!=1:ok=False;break
            f=f.replace(r['old'],r['new'],1);i=i.replace(r['new'],r['old'],1)
        if ok and f.encode()==b and i.encode()==a:return rows
    raise AssertionError('WHOLE_BYTE_INVERSE')
old=json.loads(read(S+'source_closure36_BUILD/code_execution_full_inverse_NOT_STAGE.json','bbc7378da85b93716345739de9d574dfe6d05b508bedab10721595bf82de595e'))
literal=json.loads(read(S+'worker_facts03/literal_candidates_and_four_facts_inverse_BUILD.json','e9c703aefb6de7290fdc8f66688399a1b3685d769a6356a835207eb8c52adbfb'))
dep=json.loads(read(S+'worker_facts_dependencies03/dependency_literal_inverse_BUILD.json','cc9ea6a8ee0089b4d04e5d12133ef83c2014f837e93d3c0a40fa58f1a214b98e'))
backup=json.loads(read(R+'worker_facts_predeploy35/backup_receipt.json','6c47b16fe01b6c71ace9fef922ff8e35e2658c3fc8400c1a709624cc4d394459'))
backed={r['target']:r for r in backup['records']};assert len(backed)==35
candidates={k:r['candidate'] for k,r in literal['records'].items() if k not in ['runtime','adapter']}
candidates['Coordinator']=dep['coordinator']['candidate'];candidates['Temple']=dep['temple']['candidate']
candidates['AA']=dict(path=D+'AA_ordinary_C_READY_CANDIDATE.gd',sha256='e15efc8679f58b4ddb927f39d86e705c12fa76569ab5851617019599961e3556')
candidates['AC']=dict(path=D+'AC_ordinary_AA_READY_CANDIDATE.gd',sha256='f7993c4021c0d05ded8ef3136c0755c6c6117d190349b7866beedf976b400406')
records={}
for p,row in old['records'].items():
    name=row['name']
    if name=='UI':continue
    parent=row['candidate'];a=read(parent['path'],parent['sha256']);r=backed[p]
    assert sha(a)==r['sha256']==r['backup_sha256'] and len(a)==r['bytes']
    assert Path(r['backup_path']).read_bytes()==a
    candidate=candidates[name];b=read(candidate['path'],candidate['sha256']);candidate['bytes']=len(b)
    assert b.endswith(b'\n') and b'\r' not in b
    records[p]=dict(name=name,parent=parent,candidate=candidate,hunks=hunks(a,b),wholebyte_forward_inverse=True)
assert len(records)==12
prior=old['execution']['candidate'];before=read(prior['path'],prior['sha256']);parent=json.loads(before);assert encode(parent)==before
authority=copy.deepcopy(parent);changed=old['execution']['changed_existing_owned'];assert len(changed)==7
for p in changed:
    current=authority['owned'][p];r=records[p]
    assert current['current_sha256']==r['parent']['sha256']
    snap=next(e['new_snapshot'] for e in current['edges'] if e['new_sha256']==current['current_sha256'])
    assert read(snap,current['current_sha256'])==read(r['parent']['path'],r['parent']['sha256'])
    current['edges'].append(dict(path=p,old_sha256=current['current_sha256'],new_sha256=r['candidate']['sha256'],old_snapshot=snap,new_snapshot=r['candidate']['path'],whole_inverse=True,replacements=r['hunks']))
    current['current_sha256']=r['candidate']['sha256'];authority['source_sha256'][r['candidate']['path']]=r['candidate']['sha256']
for r in [dep['contract']['candidate'],dep['temple_binding']['candidate']]:authority['source_sha256'][r['path']]=r['sha256']
assert len(parent['source_sha256'])==118 and len(authority['source_sha256'])==127 and len(authority['owned'])==10
restored=copy.deepcopy(authority)
for p in changed:restored['owned'][p]=copy.deepcopy(parent['owned'][p])
restored['source_sha256']=copy.deepcopy(parent['source_sha256'])
assert restored==parent and encode(restored)==before
execution=output('execution_successor_PREPARATION.json',encode(authority))
proof=dict(status='WORKER_FACTS35_EXACT_DEPENDENCY_AND_EXECUTION_INVERSE_NOT_STAGE',ready=False,records=records,
    execution=dict(parent=prior,candidate=execution,changed_existing_owned=changed,owned_count=10,prior_proof_count=118,new_proof_count=127,
        extra={p:h for p,h in authority['source_sha256'].items() if p not in parent['source_sha256']},whole_typed_and_serialized_UTF8_inverse=True,other_three_owned_rows_unchanged=True),
    contract=dep['contract'],temple_binding=dep['temple_binding'],root_backup=dict(path=R+'worker_facts_predeploy35/backup_receipt.json',sha256='6c47b16fe01b6c71ace9fef922ff8e35e2658c3fc8400c1a709624cc4d394459'),
    sole_functional_helper_proof=dict(path=S+'worker_facts03/literal_candidates_and_four_facts_inverse_BUILD.json',sha256='e9c703aefb6de7290fdc8f66688399a1b3685d769a6356a835207eb8c52adbfb'),
    no_new_owned_members=True,UI_native_binding_and_geometry_unchanged=True,engine_calls=0,collector_calls=0,canonical_writes=0)
review=output('code_execution_full_inverse_NOT_STAGE.json',encode(proof))
print(json.dumps(dict(proof=review,execution=execution,codes=12,owned=10,changed=7,proofs=127)))
