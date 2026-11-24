"""Root-approved NEW build candidates only; no source stage or formal writes."""
import copy, difflib, hashlib, json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'performance05_dependencies/'
SYSTEM='res://build/luoyang_city_full_rollout_20261022ap_system01/'
R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
D='res://scripts/city/luoyang_district_life_20261016f.gd'
HASH='res://scripts/city/luoyang_parallel_source_hash_20261017k.gd'
T='res://scripts/city/luoyang_temple_assembly_20261016.gd'
E='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
sha=lambda b:hashlib.sha256(b).hexdigest()
path=lambda p:G/p.removeprefix('res://')
first={};outputs={}
def fixed(p,s):
    b=path(p).read_bytes();assert sha(b)==s,('PIN_CHANGED',p);first[p]=s;return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def emit(n,v):
    p=P+n;assert p not in outputs and not path(p).exists();b=v if isinstance(v,bytes) else js(v);outputs[p]=b
    return {'path':p,'sha256':sha(b),'bytes':len(b)}
def apply(b,hs):
    f=b
    for h in hs:
        x,y=h['old'].encode(),h['new'].encode();assert x!=y and x and f.count(x)==1;f=f.replace(x,y,1)
    inv=f
    for h in reversed(hs):
        x,y=h['old'].encode(),h['new'].encode();assert y and inv.count(y)==1;inv=inv.replace(y,x,1)
    assert inv==b;return f
def hunks(a,b):
    aa,bb=a.decode().splitlines(True),b.decode().splitlines(True)
    for context in [3,8,20,1000000]:
        hs=[]
        for group in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_grouped_opcodes(context):
            hs.append({'old':''.join(aa[group[0][1]:group[-1][2]]),'new':''.join(bb[group[0][3]:group[-1][4]])})
        try:
            if apply(a,hs)==b:return hs
        except AssertionError:pass
    raise AssertionError('NO_UNIQUE_WHOLE_BYTE_HUNKS')
scopepath=R+'integration18/scope26_full_old_backups_READY.json'
scope=json.loads(fixed(scopepath,'d3eb45666421a4c2ea8b74edc0e1ac7e0dfdf8e4c39a76eca30b2586009060da'))
admission=R+'performance04_candidate_admission_READY.json'
root=json.loads(fixed(admission,'35a64923799596fc799a45d8c04c58ef14608dc7df242cadf1b0d7b60de595a6'))
assert root['approved_by_root'] is True and root['formal_version_still']=='AP11'
old={r['target']:r for r in scope['targets']};assert len(old)==26
def parent(p):
    r=old[p];backup=Path(r['backup_path']).resolve();rp='res://'+backup.relative_to(G).as_posix()
    before=fixed(rp,r['old_sha256']);assert before==fixed(p,r['old_sha256']);return before,{'path':rp,'sha256':r['old_sha256']}
oldexec=fixed(S+'a2_production04/execution_successor_PROPOSAL.json','85df6c96670165398e37b4a66627df74cd300bace841e5d064be058e7fd48187')
prior=json.loads(oldexec);assert len(prior['owned'])==10 and len(prior['source_sha256'])==63
consumers=[]
for p,name,cp in [(B,'B',S+'yamen_loading_perf04/Bundle_same_call_bound_READY.gd'),(D,'DT',S+'yamen_loading_perf04/District_scalar_timings_READY.gd'),(HASH,'parallel_hash',SYSTEM+'hash_lanes8_epoch02/parallel_source_hash_lanes8_CANDIDATE.gd')]:
    before,pd=parent(p);after=fixed(cp,root['candidates'][p]);hs=hunks(before,after)
    consumers.append({'domain':name,'target':p,'old_sha256':sha(before),'parent_snapshot':pd,'candidate':{'path':cp,'sha256':sha(after),'bytes':len(after)},'forward_hunks':hs,'inverse_replacements':list(reversed(hs)),'whole_source_byte_inverse':True})
bindparent={'path':S+'a2_production04/temple_binding_READY.json','sha256':'e69ab0694b66e133eed3f19dd277140f2f2c4dca4aa24974082ef4888c65d72a'}
bindraw=fixed(bindparent['path'],bindparent['sha256']);bind0=json.loads(bindraw)
original=json.loads(fixed(bind0['parent_binding_path'],bind0['parent_binding_sha256']))
merged=original['source_sha256']|bind0['source_delta']
hashrow=next(r for r in consumers if r['target']==HASH)
assert len(merged)==189 and HASH not in bind0['source_delta'] and merged[HASH]==hashrow['old_sha256']
bindh=[{'old':'"source_delta": {\n','new':'"source_delta": {\n    '+json.dumps(HASH)+': '+json.dumps(hashrow['candidate']['sha256'])+',\n'}]
bind=emit('temple_binding_READY.json',apply(bindraw,bindh))
newbinding=json.loads(outputs[bind['path']]);inv=copy.deepcopy(newbinding);del inv['source_delta'][HASH];assert same(inv,bind0)
newmerged=original['source_sha256']|newbinding['source_delta'];assert len(newmerged)==189 and all(newmerged[p]==s for p,s in merged.items() if p!=HASH)
before,pd=parent(T)
ths=[{'old':bindparent['path'],'new':bind['path']},{'old':bindparent['sha256'],'new':bind['sha256']}]
td=emit('Temple_hash_binding_READY.gd',apply(before,ths))
consumers.append({'domain':'Temple_binding_only','target':T,'old_sha256':sha(before),'parent_snapshot':pd,'candidate':td,'forward_hunks':ths,'inverse_replacements':list(reversed(ths)),'whole_source_byte_inverse':True})
execution=copy.deepcopy(prior);newpins={};changed=[]
for row in consumers:
    p=row['target']
    if p not in prior['owned']:continue
    oldrow=prior['owned'][p];assert row['old_sha256']==oldrow['current_sha256']
    snaps={e['new_snapshot'] for e in oldrow['edges'] if e['new_sha256']==oldrow['current_sha256']};assert len(snaps)==1
    snapshot=next(iter(snaps));fixed(snapshot,row['old_sha256'])
    desc=row['candidate'];edge={'path':p,'old_sha256':row['old_sha256'],'new_sha256':desc['sha256'],'old_snapshot':snapshot,'new_snapshot':desc['path'],'whole_inverse':True,'replacements':row['inverse_replacements']}
    execution['owned'][p]['current_sha256']=desc['sha256'];execution['owned'][p]['edges'].append(edge)
    for q,s in [(snapshot,row['old_sha256']),(desc['path'],desc['sha256'])]:
        assert q not in execution['source_sha256'] or execution['source_sha256'][q]==s
        if q not in execution['source_sha256']:newpins[q]=s
        execution['source_sha256'][q]=s
    changed.append(edge)
assert bind['path'] not in execution['source_sha256'];execution['source_sha256'][bind['path']]=bind['sha256'];newpins[bind['path']]=bind['sha256']
assert {r['path'] for r in changed}=={B,D,T} and len(newpins)==4
inv=copy.deepcopy(execution)
for e in changed:inv['owned'][e['path']]=copy.deepcopy(prior['owned'][e['path']])
for q in newpins:del inv['source_sha256'][q]
assert same(inv,prior) and len(execution['source_sha256'])==67 and HASH not in execution['owned']
proposal=emit('execution_successor_PROPOSAL.json',execution)
proof=emit('dependency_inverse_READY.json',{'status':'EXACT85DF_PLUS_THREE_OWNED_EDGES_PENDING_ROOT_APPROVAL','whole_execution_typed_inverse':True,'original63_pins_exact':True,'new4_pins':newpins,'other7_owned_exact':True,'hash_nonowned':True,'binding_only_one_new_hash_source_delta':True,'merged189_other188_exact':True,'binding_parent':bindparent,'binding':bind,'binding_byte_hunks':bindh,'Temple_byte_hunks':ths,'consumers':consumers})
hand=emit('handoff_PRODUCTION_PROPOSAL.json',{'status':'PERFORMANCE05_BUILD_CANDIDATES_PENDING_ROOT_EXECUTION_APPROVAL_AND_EXACT26_SOURCE_STAGE_LOCK','root_scope':{'path':scopepath,'sha256':'d3eb45666421a4c2ea8b74edc0e1ac7e0dfdf8e4c39a76eca30b2586009060da'},'root_candidate_admission':{'path':admission,'sha256':'35a64923799596fc799a45d8c04c58ef14608dc7df242cadf1b0d7b60de595a6'},'consumers':consumers,'temple_binding':bind,'execution_parent':{'path':E,'snapshot':S+'a2_production04/execution_successor_PROPOSAL.json','sha256':sha(oldexec)},'execution_proposal':proposal,'owned_changed_exactly3':changed,'new_proof_pins':newpins,'original63_proof_pins_unchanged':True,'final_proof_pin_count':67,'dependency_proof':proof,'source_stage_engine_collector_canonical_writes':0,'measured_city_performance_improvement':None})
assert not path(P).exists() and all(sha(path(p).read_bytes())==s for p,s in first.items())
for p,b in outputs.items():
    path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as f:f.write(b)
print(json.dumps({'handoff':hand,'execution_proposal':proposal,'proof':proof,'stage_runs':0,'canonical_writes':0}))
