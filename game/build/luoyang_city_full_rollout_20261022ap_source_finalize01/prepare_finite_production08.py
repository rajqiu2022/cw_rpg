"""NEW fixed production proposals only; no stage, engine or canonical writes."""
import copy
import difflib
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
S = 'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P = S + 'finite_adapter_production08/'
OLD = S + 'finite_adapter_implementation07/'
outputs, first = {}, {}

def sha(b): return hashlib.sha256(b).hexdigest()
def path(p):
    assert p.startswith('res://') and '..' not in p
    return GAME / p[6:]
def read(p, s):
    b = path(p).read_bytes(); assert sha(b) == s, ('PIN_CHANGED', p)
    first[p] = s; return b
def same(a, b):
    if type(a) is not type(b): return False
    if isinstance(a, dict): return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list): return len(a) == len(b) and all(same(x, y) for x, y in zip(a,b))
    return a == b
def js(v): return (json.dumps(v, ensure_ascii=False, indent=2)+'\n').encode()
def emit(name, b):
    p = P + name; assert p not in outputs and not path(p).exists()
    outputs[p] = b if isinstance(b, bytes) else js(b)
    return {'path':p, 'sha256':sha(outputs[p]), 'bytes':len(outputs[p])}
def changes(raw, hs):
    out = raw
    for h in hs:
        a,b = h['old'].encode(),h['new'].encode()
        assert a != b and out.count(a)==1, ('UNIQUE_OLD', h['old'][:90])
        out = out.replace(a,b,1)
    inv = out
    for h in reversed(hs):
        a,b=h['old'].encode(),h['new'].encode()
        assert b and inv.count(b)==1, ('UNIQUE_NEW',h['new'][:90])
        inv=inv.replace(b,a,1)
    assert inv==raw
    return out
def diff_hunks(before,after):
    # Whole-source line hunks, with enough immutable context to be unique.
    a,b=before.decode().splitlines(keepends=True),after.decode().splitlines(keepends=True)
    for context in [2,4,8,16,32,1000000]:
        hs=[]
        for group in difflib.SequenceMatcher(None,a,b,autojunk=False).get_grouped_opcodes(context):
            i,j=group[0][1],group[-1][2];k,l=group[0][3],group[-1][4]
            hs.append({'old':''.join(a[i:j]),'new':''.join(b[k:l])})
        try:
            if changes(before,hs)==after: return hs
        except AssertionError: pass
    raise AssertionError('NO_UNIQUE_WHOLE_SOURCE_DIFF')

hand=json.loads(read(OLD+'handoff_PENDING.json','ad35db6e0ecaf04a9636ddd82dabe98f994ada3201971495b3818170192e7e32'))
codeauth='res://build/luoyang_city_full_rollout_20261022ap_root01/finite_adapter07_code_scope_review_READY.json'
codeauthraw=path(codeauth).read_bytes()
codeauthvalue=json.loads(codeauthraw)
assert codeauthvalue['approved_by_root'] is True and codeauthvalue['handoff_sha256']==sha(read(OLD+'handoff_PENDING.json','ad35db6e0ecaf04a9636ddd82dabe98f994ada3201971495b3818170192e7e32'))
first[codeauth]=sha(codeauthraw)
groundauth='res://build/luoyang_city_full_rollout_20261022ap_root01/ground_five_rect_visual_admission_READY.json'
groundauthsha='657722693680f15564aecc55a3e75929204400e3badcb509abb076259a31d8fe'
ground=json.loads(read(groundauth,groundauthsha)); assert ground['approved_by_root'] is True
assert ground['candidate_ENV_sha256']=='a751dbd4ce014abd2e808d7c9a947dc0e4a314d4b42930a6392a1d6eb7c20a7d'

binding=json.loads(read(hand['binding']['path'],hand['binding']['sha256']))
oldbinding=copy.deepcopy(binding)
binding['source_closure_ready']=True
for domain,d in binding['domains'].items():
    d['runtime_manifest_path']=P+'runtime_'+domain+'_manifest_READY.json'
bindingdesc=emit('adapter_binding_READY.json',binding)
restore=copy.deepcopy(binding);restore['source_closure_ready']=False
for domain in restore['domains']:
    restore['domains'][domain]['runtime_manifest_path']=oldbinding['domains'][domain]['runtime_manifest_path']
assert same(restore,oldbinding)

oldadapter=read(hand['adapter']['path'],hand['adapter']['sha256'])
adapterhs=[{'old':'const READY := false','new':'const READY := true'},
 {'old':hand['binding']['path'],'new':bindingdesc['path']},
 {'old':hand['binding']['sha256'],'new':bindingdesc['sha256']},
 {'old':hand['adapter']['path'],'new':P+'finite_adapter_READY.gd'}]
adapter=emit('finite_adapter_READY.gd',changes(oldadapter,adapterhs))
consumers=[]
for domain in ['Fade','DT','C','Field_TEXT_ONLY','B']:
    row=next(r for r in hand['consumers'] if r['domain']==domain)
    raw=read(row['target'],row['old_sha256'])
    hs=copy.deepcopy(row['hunks'])
    for h in hs:
        h['new']=h['new'].replace(hand['adapter']['path'],adapter['path']).replace(hand['adapter']['sha256'],adapter['sha256'])
        if domain=='B':
            oldfade=next(r for r in hand['consumers'] if r['domain']=='Fade')
            h['new']=h['new'].replace(oldfade['candidate_path'],fade['path']).replace(oldfade['candidate_sha256'],fade['sha256'])
    after=changes(raw,hs)
    desc=emit(domain+'_consumer_READY.gd',after)
    if domain=='Fade': fade=desc
    # Authority inverse order is application-reversed, not hunk ordinal.
    consumers.append({'domain':domain,'target':row['target'],'old_sha256':row['old_sha256'],
      'candidate':desc,'forward_hunks':hs,'inverse_replacements':list(reversed(hs)),
      'whole_source_byte_inverse':True,'crlf_count':after.count(b'\r\n')})

envtarget='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
envold=read(envtarget,'455aa5b2d2b170491f67294ea11cae8ec6c6e23806eb83563cbc49e6fe7f7983')
envpath='res://build/luoyang_city_full_rollout_20261022ap_system01/ground_purpose_preview_epoch01/ENV_metadata_retry2_candidate.gd'
envsha=ground['candidate_ENV_sha256'];envbytes=read(envpath,envsha)
envhunks=diff_hunks(envold,envbytes)
consumers.append({'domain':'ENV','target':envtarget,'old_sha256':sha(envold),
 'candidate':{'path':envpath,'sha256':envsha,'bytes':len(envbytes)},'forward_hunks':envhunks,
 'inverse_replacements':list(reversed(envhunks)),'whole_source_byte_inverse':True,'crlf_count':envbytes.count(b'\r\n')})
shaderpath='res://build/luoyang_city_full_rollout_20261022ap_system01/ground_purpose_visual_epoch01/rect_ground_purpose_candidate.gdshader'
shader=read(shaderpath,ground['candidate_shader_sha256'])
shaderdesc={'path':shaderpath,'sha256':sha(shader),'bytes':len(shader)}

FIELD='res://scripts/field/field_walkable_controller.gd'
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'
COORD='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
TEMPLE='res://scripts/city/luoyang_temple_assembly_20261016.gd'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
contractsha='16b381c113ebfd0cb89f382eb99366bb703cda6baa40142cc1fbf97343ed74d8'
coordsha='71beb2e1181d8e9fe337dcd50571628c289304f3a38e7d054973eaee4e812a87'
templesha='8e8f8e3c2b1c3f8715c7d7ddaf48f3b14e5c5abcf5b8818ecdb7ee29c1958ff8'
bindpath=S+'unified06_dependencies03/temple_binding_READY.json'
bindsha='1724624c6f85b9c8daa3593d259089ed1b9b8f1e60106f0dff67582d6686d840'
exesha='a3880503360b0aa8ef745928e3f5f0effc452fc28cba773e3001122e30315a75'
updates={r['target']:r['candidate']['sha256'] for r in consumers}
contractraw=read(CONTRACT,contractsha);contract0=json.loads(contractraw)
contractupdates={p:updates[p] for p in [FIELD,C]}
contracths=[{'old':contract0['source_sha256'][p],'new':s} for p,s in contractupdates.items()]
contract=emit('runtime_contract_READY.json',changes(contractraw,contracths))
contractinv=json.loads(outputs[contract['path']])
for p in contractupdates:contractinv['source_sha256'][p]=contract0['source_sha256'][p]
assert same(contractinv,contract0)
coordraw=read(COORD,coordsha);coordhs=[{'old':contractsha,'new':contract['sha256']}]
coord=emit('Coordinator_contract_READY.gd',changes(coordraw,coordhs))
bindraw=read(bindpath,bindsha);bind0=json.loads(bindraw)
bindupdates={p:updates[p] for p in [FIELD,C]};bindupdates.update({COORD:coord['sha256'],CONTRACT:contract['sha256']})
bindhs=[{'old':bind0['source_delta'][p],'new':s} for p,s in bindupdates.items()]
templebind=emit('temple_binding_READY.json',changes(bindraw,bindhs))
bindinv=json.loads(outputs[templebind['path']])
for p in bindupdates:bindinv['source_delta'][p]=bind0['source_delta'][p]
assert same(bindinv,bind0)
templeraw=read(TEMPLE,templesha)
templehs=[{'old':bindpath,'new':templebind['path']},{'old':bindsha,'new':templebind['sha256']}]
temple=emit('Temple_binding_READY.gd',changes(templeraw,templehs))
for domain,target,oldsha,desc,hs in [('Coordinator',COORD,coordsha,coord,coordhs),('Temple',TEMPLE,templesha,temple,templehs)]:
    consumers.append({'domain':domain,'target':target,'old_sha256':oldsha,'candidate':desc,
      'forward_hunks':hs,'inverse_replacements':list(reversed(hs)),'whole_source_byte_inverse':True})

approval0=json.loads(read(EXE,exesha));approval=copy.deepcopy(approval0)
assert len(approval0['owned'])==10 and len(approval0['source_sha256'])==50
ownedrows=[];newpins={}
for row in consumers:
    target=row['target']
    if target not in approval0['owned']:continue
    oldrow=approval0['owned'][target];assert oldrow['current_sha256']==row['old_sha256']
    predecessors={e['new_snapshot'] for e in oldrow['edges'] if e['new_sha256']==row['old_sha256']};assert len(predecessors)==1
    before=read(next(iter(predecessors)),row['old_sha256'])
    desc=row['candidate'];after=outputs[desc['path']] if desc['path'] in outputs else read(desc['path'],desc['sha256'])
    inv=after.decode()
    for h in row['inverse_replacements']:
        assert inv.count(h['new'])==1;inv=inv.replace(h['new'],h['old'],1)
    assert inv.encode()==before
    edge={'path':target,'old_sha256':row['old_sha256'],'new_sha256':desc['sha256'],
      'old_snapshot':next(iter(predecessors)),'new_snapshot':desc['path'],'whole_inverse':True,
      'replacements':row['inverse_replacements']}
    approval['owned'][target]['current_sha256']=desc['sha256'];approval['owned'][target]['edges'].append(edge)
    for p,s in [(edge['old_snapshot'],edge['old_sha256']),(desc['path'],desc['sha256'])]:
        assert p not in approval['source_sha256'] or approval['source_sha256'][p]==s
        if p not in approval['source_sha256']:newpins[p]=s
        approval['source_sha256'][p]=s
    ownedrows.append({'target':target,'old_sha256':row['old_sha256'],'candidate':desc,'edge':edge})
for desc in [contract,templebind]:
    assert desc['path'] not in approval['source_sha256'];approval['source_sha256'][desc['path']]=desc['sha256'];newpins[desc['path']]=desc['sha256']
restored=copy.deepcopy(approval)
for row in ownedrows:restored['owned'][row['target']]=copy.deepcopy(approval0['owned'][row['target']])
for p in newpins:del restored['source_sha256'][p]
assert same(restored,approval0) and len(ownedrows)==5
proposal=emit('execution_successor_PROPOSAL.json',approval)
proof=emit('dependency_exact_inverse_READY.json',{
 'status':'EXACT_A388_DEPENDENCY_SUCCESSORS_NOT_ROOT_EXECUTION_APPROVAL',
 'contract':{'parent':{'path':CONTRACT,'sha256':contractsha},'candidate':contract,'changed_source_paths':list(contractupdates),'hunks':contracths},
 'coordinator':{'parent':{'path':COORD,'sha256':coordsha},'candidate':coord,'hunks':coordhs},
 'temple_binding':{'parent':{'path':bindpath,'sha256':bindsha},'candidate':templebind,'changed_source_paths':list(bindupdates),'hunks':bindhs},
 'temple':{'parent':{'path':TEMPLE,'sha256':templesha},'candidate':temple,'hunks':templehs},
 'whole_byte_and_typed_inverses':True,'original50_proof_pins_unchanged':True,'owned_domain_unchanged':True})

handout=emit('handoff_PRODUCTION_PROPOSAL.json',{
 'status':'ROOT_CODE_SCOPE_AUTHORIZED_PRODUCTION_CANDIDATES_PENDING_EXACT_EXECUTION_APPROVAL_AND_SOURCE_STAGE',
 'code_scope_authority':{'path':codeauth,'sha256':sha(codeauthraw)},
 'ground_authority':{'path':groundauth,'sha256':groundauthsha},
 'predecessor07_handoff':{'path':OLD+'handoff_PENDING.json','sha256':'ad35db6e0ecaf04a9636ddd82dabe98f994ada3201971495b3818170192e7e32'},
 'adapter':adapter,'binding':bindingdesc,'adapter_ready_candidate':True,'binding_source_closure_ready_candidate':True,
 'adapter_exact_inverse_to07':adapterhs,'binding_whole_typed_inverse_to07':True,
 'consumers':consumers,'ground_shader':shaderdesc,'contract':contract,'temple_binding':templebind,
 'execution_parent':{'path':EXE,'sha256':exesha},'execution_proposal':proposal,
 'owned_changed_exactly5':ownedrows,'other5_owned_rows_whole_typed_identical':True,
 'old50_proof_pins_exact':True,'new_proof_pins':newpins,'final_proof_pin_count':len(approval['source_sha256']),
 'whole_execution_typed_inverse_to_A388':True,'dependency_proof':proof,
 'remaining_generated_DAG':['source metadata/registry','execution+ENV indices','Quarter metadata/index','Market+Yamen finite manifests','external AP index exact entries','4 independent expected maps'],
 'production_flags_not_deployment_authority':True,'stage_runs':0,'engine_calls':0,'canonical_writes':0})
assert not path(P).exists()
assert all(sha(path(p).read_bytes())==s for p,s in first.items())
for p,b in outputs.items():
    path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as f:f.write(b)
print(json.dumps({'handoff':handout,'execution_proposal':proposal,'owned_changed':len(ownedrows),'proof_count':len(approval['source_sha256']),'source_first_final_equal':True}))
