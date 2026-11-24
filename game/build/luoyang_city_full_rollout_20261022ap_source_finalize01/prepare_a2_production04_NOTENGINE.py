"""Prepare NEW production candidates/proposal; never Stage, engine or formal write.

Root must separately authorize the new execution proposal and exact source scope.
New walk import leaves belong to the eventual Quarter source map, not this
binding: no reverse pin to executable candidates or final generated headers.
"""
import copy
import difflib
import hashlib
import json
from pathlib import Path

H=Path(__file__).resolve().parent
G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'a2_production04/'
D=S+'a2_runtime_draft03/'
FAMILY='res://scripts/city/luoyang_quarters_family_20261022ap.gd'
ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
FIELD='res://scripts/field/field_walkable_controller.gd'
ROOMS='res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
COORD='res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'
TEMPLE='res://scripts/city/luoyang_temple_assembly_20261016.gd'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
outputs={}
first={}
def sha(b):return hashlib.sha256(b).hexdigest()
def path(p):
    assert p.startswith('res://') and '..' not in p
    return G/p[6:]
def read(p,s):
    b=path(p).read_bytes();assert sha(b)==s,('PIN_CHANGED',p)
    first[p]=s;return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def emit(name,data):
    p=P+name;assert p not in outputs and not path(p).exists()
    outputs[p]=data if isinstance(data,bytes) else js(data)
    return {'path':p,'sha256':sha(outputs[p]),'bytes':len(outputs[p])}
def apply(raw,hs):
    result=raw
    for h in hs:
        a,b=h['old'].encode(),h['new'].encode()
        assert a!=b and result.count(a)==1,('UNIQUE_OLD',h['old'][:100])
        result=result.replace(a,b,1)
    inverse=result
    for h in reversed(hs):
        a,b=h['old'].encode(),h['new'].encode()
        assert b and inverse.count(b)==1,('UNIQUE_NEW',h['new'][:100])
        inverse=inverse.replace(b,a,1)
    assert inverse==raw
    return result
def hunks(a,b):
    before,after=a.decode().splitlines(True),b.decode().splitlines(True)
    for context in [3,8,20,1000000]:
        rows=[]
        for group in difflib.SequenceMatcher(None,before,after,autojunk=False).get_grouped_opcodes(context):
            i,j=group[0][1],group[-1][2];k,l=group[0][3],group[-1][4]
            rows.append({'old':''.join(before[i:j]),'new':''.join(after[k:l])})
        try:
            if apply(a,rows)==b:return rows
        except AssertionError:pass
    raise AssertionError('UNIQUE_WHOLE_SOURCE_HUNKS_REQUIRED')

hand=json.loads(read(D+'handoff_PUBLICATION_ADMISSION_RUTS_NOTREADY.json','7c5eed8743fbeab63c728c4e717661265344d343fabb6bdcd1fc24b5fa1830e3'))
stage=json.loads(read(S+'outputs/root_finite09_two_domain_stage02/receipt.json','885a813db26487582bc7cb31d02ec89827dc929a9e2653e71137defd8ff8c3a0'))
owner=json.loads(read(S+'finite10_yamen_classification/actual_deployment_review/owner_source_maps_ROOT_DEPLOYED_READY.json','690fba034f8b865e0cbbe31e21a8ee8095ede2471b73235f500fbcb4052c8902'))
stage_targets={r['target']:r for r in stage['targets']}
def parent(target):
    row=stage_targets[target]
    return read(row['candidate_path'],row['candidate_sha256']),{'path':row['candidate_path'],'sha256':row['candidate_sha256']}
binding0=json.loads(read(hand['binding']['path'],hand['binding']['sha256']))
binding=copy.deepcopy(binding0)
binding['status']='ROOT_FIXED_A2_ARTISAN_NATIVE_AND_ART_BINDING'
binding['ready']=True
binding['pending_source_leaves']=[]
binding['runtime_spec_requires_Root_actual_schema_and_status_binding_before_READY']=False
# Closure carries code identities externally; binding never reverses to them.
assert all(not p.endswith('/luoyang_quarters_family_20261022ap.gd') and not p.endswith('/luoyang_environment_layer_20261022ap.gd') and not p.endswith('/field_walkable_controller.gd') and not p.endswith('/luoyang_assembled_interiors_20261016g.gd') for p in binding['source_sha256'])
bindingdesc=emit('a2_binding_READY.json',binding)
inverse=copy.deepcopy(binding)
for key in ['status','ready','pending_source_leaves','runtime_spec_requires_Root_actual_schema_and_status_binding_before_READY']:inverse[key]=copy.deepcopy(binding0[key])
assert same(inverse,binding0)
oldhelper=hand['unchanged_false_material_helper']
helperraw=read(oldhelper['path'],oldhelper['sha256'])
helperhs=[{'old':'const READY=false','new':'const READY=true'}]
helper=emit('material_runtime_READY.gd',apply(helperraw,helperhs))
consumers=[]
for domain,target,name in [('Family',FAMILY,'Family_A2_READY.gd'),('ENV',ENV,'ENV_A2_READY.gd')]:
    row=next(r for r in hand['candidates'] if r['target']==target)
    raw=read(row['candidate']['path'],row['candidate']['sha256'])
    hs=([{'old':'const A2_READY=false','new':'const A2_READY=true'},
         {'old':hand['binding']['path'],'new':bindingdesc['path']},
         {'old':hand['binding']['sha256'],'new':bindingdesc['sha256']}]
        if domain=='Family' else
        [{'old':'const A2_MATERIAL_READY=false','new':'const A2_MATERIAL_READY=true'},
         {'old':oldhelper['path'],'new':helper['path']},
         {'old':oldhelper['sha256'],'new':helper['sha256']}])
    candidate=apply(raw,hs);desc=emit(name,candidate)
    # Family was not a formal target in885A. Its exact deployed source is pinned
    # by the draft's formal parent and every immutable690F Quarter source row.
    if target==FAMILY:
        before=read(row['formal_parent']['path'],row['formal_parent']['sha256']);parentdesc=row['formal_parent']
    else:before,parentdesc=parent(target)
    finalhunks=hunks(before,candidate)
    consumers.append({'domain':domain,'target':target,'old_sha256':sha(before),'parent_snapshot':parentdesc,'candidate':desc,'forward_hunks':finalhunks,'inverse_replacements':list(reversed(finalhunks)),'whole_source_byte_inverse':True,'flags_only_successor_from03':hs})

performance=json.loads(read(S+'portal_clone_field_timing03/handoff_CANDIDATES_NOT_DEPLOYED.json','ebb4695b05ad9acc029205b4cfef10888f66e9dcaf5a52265adabe25ff0f59ee'))
for domain,target,candidate_path,candidate_sha in [
    ('G',ROOMS,S+'portal_clone_field_timing01/G_local_catalogue_READY.gd','7b1954f9b44fb8e56fc69c29d09d99a66f3730c62a73ec5af692fa475d38e6e5'),
    ('Field_TIMING_ONLY',FIELD,S+'portal_clone_field_timing03/Field_loading_scalar_profile_READY.gd','67a83fb081f34b9fcea4c2045a1d36fb7fea04ef1405d51a78bc946337529b82')]:
    after=read(candidate_path,candidate_sha)
    if target in stage_targets:before,parentdesc=parent(target)
    else:
        # G stayed unmodified in the last deployment. Its frozen current edge
        # snapshot, not a live hash, is selected below from C668.
        execution0=json.loads(read(S+'finite_adapter_production08/execution_successor_PROPOSAL.json','c668a0be6bc051237857dc4d2822308077a808a800f51a27f04f8b75c75f8405'))
        oldrow=execution0['owned'][target]
        snapshots={e['new_snapshot'] for e in oldrow['edges'] if e['new_sha256']==oldrow['current_sha256']}
        assert len(snapshots)==1
        parentdesc={'path':next(iter(snapshots)),'sha256':oldrow['current_sha256']};before=read(parentdesc['path'],parentdesc['sha256'])
    hs=hunks(before,after)
    consumers.append({'domain':domain,'target':target,'old_sha256':sha(before),'parent_snapshot':parentdesc,'candidate':{'path':candidate_path,'sha256':candidate_sha,'bytes':len(after)},'forward_hunks':hs,'inverse_replacements':list(reversed(hs)),'whole_source_byte_inverse':True})

updates={r['target']:r['candidate']['sha256'] for r in consumers}
contractraw,contractparent=parent(CONTRACT);contract0=json.loads(contractraw)
assert contract0['source_sha256'][FIELD]==stage_targets[FIELD]['candidate_sha256']
contracths=[{'old':json.dumps(FIELD)+': '+json.dumps(contract0['source_sha256'][FIELD]),'new':json.dumps(FIELD)+': '+json.dumps(updates[FIELD])}]
contract=emit('runtime_contract_READY.json',apply(contractraw,contracths))
contractinv=json.loads(outputs[contract['path']]);contractinv['source_sha256'][FIELD]=contract0['source_sha256'][FIELD]
assert same(contractinv,contract0)
coordraw,coordparent=parent(COORD)
coordhs=[{'old':contractparent['sha256'],'new':contract['sha256']}]
coord=emit('Coordinator_contract_READY.gd',apply(coordraw,coordhs))
bindparent={'path':S+'finite_adapter_production08/temple_binding_READY.json','sha256':'96ec2e4ff6e3b7e911ce6b13bea96a4a88b6f7bdf9b5d680c3a23b7aac2120da'}
bindraw=read(bindparent['path'],bindparent['sha256']);bind0=json.loads(bindraw)
bindupdates={FIELD:updates[FIELD],COORD:coord['sha256'],CONTRACT:contract['sha256']}
bindhs=[{'old':json.dumps(p)+': '+json.dumps(bind0['source_delta'][p]),'new':json.dumps(p)+': '+json.dumps(s)} for p,s in bindupdates.items()]
templebind=emit('temple_binding_READY.json',apply(bindraw,bindhs))
bindinv=json.loads(outputs[templebind['path']])
for p in bindupdates:bindinv['source_delta'][p]=bind0['source_delta'][p]
assert same(bindinv,bind0)
templeraw,templeparent=parent(TEMPLE)
templehs=[{'old':bindparent['path'],'new':templebind['path']},{'old':bindparent['sha256'],'new':templebind['sha256']}]
temple=emit('Temple_binding_READY.gd',apply(templeraw,templehs))
for domain,target,parentdesc,before,desc,hs in [('Coordinator',COORD,coordparent,coordraw,coord,coordhs),('Temple',TEMPLE,templeparent,templeraw,temple,templehs)]:
    consumers.append({'domain':domain,'target':target,'old_sha256':sha(before),'parent_snapshot':parentdesc,'candidate':desc,'forward_hunks':hs,'inverse_replacements':list(reversed(hs)),'whole_source_byte_inverse':True})

execution0=json.loads(read(S+'finite_adapter_production08/execution_successor_PROPOSAL.json','c668a0be6bc051237857dc4d2822308077a808a800f51a27f04f8b75c75f8405'))
execution=copy.deepcopy(execution0);changed=[];newpins={}
assert len(execution0['owned'])==10 and len(execution0['source_sha256'])==57
for row in consumers:
    target=row['target']
    if target not in execution0['owned']:continue
    oldrow=execution0['owned'][target];assert oldrow['current_sha256']==row['old_sha256']
    snapshots={e['new_snapshot'] for e in oldrow['edges'] if e['new_sha256']==row['old_sha256']};assert len(snapshots)==1
    oldsnapshot=next(iter(snapshots));before=read(oldsnapshot,row['old_sha256'])
    desc=row['candidate'];after=outputs.get(desc['path']) or read(desc['path'],desc['sha256'])
    inv=after
    for h in row['inverse_replacements']:
        a,b=h['old'].encode(),h['new'].encode();assert inv.count(b)==1;inv=inv.replace(b,a,1)
    assert inv==before
    edge={'path':target,'old_sha256':row['old_sha256'],'new_sha256':desc['sha256'],'old_snapshot':oldsnapshot,'new_snapshot':desc['path'],'whole_inverse':True,'replacements':row['inverse_replacements']}
    execution['owned'][target]['current_sha256']=desc['sha256'];execution['owned'][target]['edges'].append(edge)
    for p,s in [(oldsnapshot,row['old_sha256']),(desc['path'],desc['sha256'])]:
        assert p not in execution['source_sha256'] or execution['source_sha256'][p]==s
        if p not in execution['source_sha256']:newpins[p]=s
        execution['source_sha256'][p]=s
    changed.append({'target':target,'old_sha256':row['old_sha256'],'candidate':desc,'edge':edge})
for desc in [contract,templebind]:
    assert desc['path'] not in execution['source_sha256'];execution['source_sha256'][desc['path']]=desc['sha256'];newpins[desc['path']]=desc['sha256']
restored=copy.deepcopy(execution)
for row in changed:restored['owned'][row['target']]=copy.deepcopy(execution0['owned'][row['target']])
for p in newpins:del restored['source_sha256'][p]
assert same(restored,execution0) and len(changed)==4 and len(newpins)==6
proposal=emit('execution_successor_PROPOSAL.json',execution)
proofdesc=emit('dependency_byte_typed_inverse_READY.json',{'status':'C668_PLUS_EXACT_FOUR_EXISTING_OWNED_EDGES_NOT_ROOT_APPROVAL','contract_parent':contractparent,'contract':contract,'contract_hunks':contracths,'binding_parent':bindparent,'temple_binding':templebind,'binding_hunks':bindhs,'coordinator_hunks':coordhs,'temple_hunks':templehs,'old57_pins_unchanged':True,'new6_pins':newpins,'unchanged_other6_owned_rows':True,'whole_execution_typed_inverse':True,'whole_dependency_byte_and_typed_inverses':True})
handoff=emit('handoff_PRODUCTION_PROPOSAL.json',{
    'status':'A2_PRODUCTION_CANDIDATES_PENDING_ROOT_EXECUTION_APPROVAL_COMPLETE_SOURCE_SCOPE_AND_STAGE',
    'draft03':{'path':D+'handoff_PUBLICATION_ADMISSION_RUTS_NOTREADY.json','sha256':'7c5eed8743fbeab63c728c4e717661265344d343fabb6bdcd1fc24b5fa1830e3'},
    'baseline_owner690F':'690fba034f8b865e0cbbe31e21a8ee8095ede2471b73235f500fbcb4052c8902',
    'baseline_actual885A':'885a813db26487582bc7cb31d02ec89827dc929a9e2653e71137defd8ff8c3a0',
    'Yamen_ED4C_and_APINDEX_DB9D_classification_must_inherit':True,
    'binding':bindingdesc,'binding_whole_typed_inverse_to03':True,'runtime_material_helper':helper,'runtime_helper_exact_flag_hunk':helperhs,
    'consumers':consumers,'contract':contract,'temple_binding':templebind,
    'execution_parent':{'path':EXE,'snapshot':S+'finite_adapter_production08/execution_successor_PROPOSAL.json','sha256':'c668a0be6bc051237857dc4d2822308077a808a800f51a27f04f8b75c75f8405'},
    'execution_proposal':proposal,'owned_changed_exactly4':changed,'new_proof_pins':newpins,'old57_proof_pins_unchanged':True,'final_proof_pin_count':len(execution['source_sha256']),
    'dependency_proof':proofdesc,'publication_and_limited_ART':{'publisher':binding['publisher_report'],'Root':binding['root_art_admission'],'independent_review':binding['independent_publication_review']},
    'remaining_DAG':['fixed new walk remap2leaf source declaration pending System/Root exact import admission','Quarter exact Artisan row4path + source map + index','registry/Estate/legacy/Market/finite-runtime existing source-only target successors and exact consumer indices','four maps from frozen AO bases with original promote_owned first, explicit nonowned diffs, complete recipe sources','Root exact new execution and final target scope approvals'],
    'no_binding_reverse_to_code_or_final_manifest':True,'whole_district_ART_or_city_complete':False,
    'source_stage_engine_collector_decode_or_canonical_writes':0,
})
assert not path(P).exists()
assert all(sha(path(p).read_bytes())==s for p,s in first.items())
for p,b in outputs.items():
    path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as f:f.write(b)
print(json.dumps({'handoff':handoff,'execution_proposal':proposal,'owned_changed':len(changed),'new_proof_count':len(newpins),'stage_runs':0,'canonical_writes':0}))
