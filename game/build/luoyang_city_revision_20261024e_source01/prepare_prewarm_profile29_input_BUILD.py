"""Mechanical new29 source DAG from fixed D596 tables and approved candidates."""
from pathlib import Path
import json,hashlib,copy,difflib,ast
HERE=Path(__file__).resolve().parent;GAME=HERE.parents[1]
S='res://build/luoyang_city_revision_20261024e_source01/';R='res://build/luoyang_city_revision_20261024e_root01/'
EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json';CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
REGISTRY='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=(GAME/p[6:]).read_bytes();assert sha(b)==h.lower(),p;assert b'tokens truncated' not in b;return b
def load(p,h):return json.loads(read(p,h))
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def at(v,p):
    for k in p:v=v[k]
    return v
def op(p,a,b,exists=True):return dict(op='set',pointer=p,existed=exists,old=copy.deepcopy(a),new=copy.deepcopy(b))
oldpath=S+'source_input_market_blocks33_session03_ROOT_REVIEW.json';oldsha='afd712afd624d26d24320d258497f0bafba3c2979d38b2b369ab0f48f3a1ee65';oldraw=read(oldpath,oldsha);old=json.loads(oldraw)
stage=load(S+'outputs/root_market_blocks_prewarm_exact33_stage03/receipt.json','ea657a57c4a884cd3f645b6de7f8fb2010c8920b737b2ab6b9f3c998288c2abc')
scopepath=S+'prewarm_profile29_scope_PREPARATION.json';scopehash='cd4e04275838a9652617ea62204a2e2fa34c124d422a87a05bb2f97dedb1beca';scope=load(scopepath,scopehash);targets={r['target']:r for r in scope['targets']}
proofpath=S+'prewarm_profile29_candidates01/code_execution_whole_inverse_NOT_STAGE.json';proofhash='a32ab44edd0a8d3e72409f40ae89a118691b73398cf184761e59f0cf103e6982';proof=load(proofpath,proofhash)
priorproof=load(S+'dependencies33_session03_READY/code_execution_whole_inverse_NOT_STAGE.json','75e1e02ce64de019be6fa544afc62cfb8967370809f45095de952dbfa668997f')
authority=load(proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256'])
mapsproof=load(S+'finite_AP_header2_candidate02/whole_inverse_and_expected_maps_NOT_DEPLOYED.json','1b2d7ae17f5ff290e5b0858ab57c6699a0f081d977c3dae585aa9246e26161d8')
approvalpath=R+'prewarm_profile29_preparation_authorization.json';approvalsha='1aa419947f6f712f26d56a46125df22a07d7aee15def920b56ce5c29caaeb0aa';approval=load(approvalpath,approvalsha)
pins={r['id']:copy.deepcopy(r) for r in old['pinned_inputs']}
def pin(i,p,h):pins[i]=dict(id=i,path=p,sha256=h.lower());return {'$pin':i}
pin('execution_approval',proof['execution']['candidate']['path'],proof['execution']['candidate']['sha256']);pin('space_parent_execution',proof['execution']['parent']['path'],proof['execution']['parent']['sha256'])
pin('space_scope',scopepath,scopehash);pin('space_code_inverse',proofpath,proofhash)
pin('space_Root_backup',R+'prewarm_profile29_backup_receipt.json','a235b1d4fb261b1f61329312b3b051ee7409355c779820c558f9958cbef7f56e')
pin('space_Root_preparation',approvalpath,approvalsha);pin('space_contract_literal',proof['contract']['candidate']['path'],proof['contract']['candidate']['sha256']);pin('space_temple_binding',proof['temple_binding']['candidate']['path'],proof['temple_binding']['candidate']['sha256'])
# Replace only fixed existing code pin records; other current DT/G/Router pins stay.
refs={}
for p,r in proof['records'].items():
    oldcandidate=priorproof['records'][p]['candidate'];found=[]
    for ident,row in pins.items():
        if row['path']==oldcandidate['path'] and row['sha256']==oldcandidate['sha256']:
            row.update(path=r['candidate']['path'],sha256=r['candidate']['sha256']);found.append(ident)
    assert found,(p,'CODE_PIN_NOT_FOUND');refs[p]={'$pin':next((i for i in found if i.startswith('blocks_code_')),found[0])}
refs[EXEC]={'$pin':'execution_approval'};refs[CONTRACT]={'$sha':'runtime_contract_final'}
for n in old['nodes']:
    if n.get('target') in targets and n['target'] not in refs:refs[n['target']]={'$sha':n['id']}
groups={g['id']:copy.deepcopy(g) for g in old['source_groups']}
# Existing groups keep all prior literal keys; pin references resolve only the
# exact newly approved current code/header values. New ordinary leaves append.
helper={proof['helper']['path']:proof['helper']['sha256']}
for ident,leaves in [('prewarm8_Field_helper1',helper),('prewarm8_Docks_ordinary2',proof['ordinary']['Docks_only_source_additions']),('profile04_Market_purpose2',proof['purpose_ordinary_sources'])]:groups[ident]=dict(id=ident,kind='explicit',leaves=leaves)
groups['common_four_city']['groups'].append('prewarm8_Field_helper1')
def additions(ident):
    result=[]
    if ident in ['legacy_manifest_2','legacy_manifest_3','legacy_manifest_4','legacy_manifest_5','legacy_manifest_6','legacy_manifest_7','legacy_manifest_8','finite08_market','finite08_yamen','market_final','quarter_final','expected_ch4_s0_luoyang_gate_true','expected_ch4_s1_luoyang_yamen_true','expected_ch4_s2_canal_docks_true','expected_ch4_s3_luoyang_market_true']:result.append('prewarm8_Field_helper1')
    if ident in ['legacy_manifest_4','legacy_manifest_6','legacy_manifest_7','expected_ch4_s2_canal_docks_true']:result.append('prewarm8_Docks_ordinary2')
    if ident in ['legacy_manifest_5','legacy_manifest_8','finite08_market','market_final','expected_ch4_s3_luoyang_market_true']:result.append('profile04_Market_purpose2')
    return result
parentmaps={};nodes=[];old_value_checks=0
for original in old['nodes']:
    n=copy.deepcopy(original);ident,kind=n['id'],n['kind']
    if ident=='execution_final':nodes.append(dict(id=ident,kind='space_execution',base_input='execution_approval'));continue
    if ident=='registry_final':
        prior=stage['nodes'][ident];pi='prewarm_frozen_registry';pin(pi,prior['path'],prior['sha256']);nodes.append(dict(id=ident,kind='space_frozen',base_input=pi,immutable_sha256=prior['sha256'],is_json=True));continue
    if kind in ['space_frozen','space_code']:nodes.append(n);continue
    if kind=='map':
        maprow=mapsproof['maps'][ident];mi='prewarm_parent_'+ident;pin(mi,maprow['path'],maprow['sha256']);parentmaps[ident]=mi
        wanted=load(maprow['path'],maprow['sha256'])['source_sha256'];seed=load(pins[n['base_input']]['path'],pins[n['base_input']]['sha256'])['source_sha256'];promoted=copy.deepcopy(seed)
        for p in promoted:
            if p in authority['owned']:promoted[p]=authority['owned'][p]['current_sha256']
        n['operations']=[op(['source_sha256',p],promoted.get(p),refs.get(p,h),p in promoted) for p,h in wanted.items() if p not in promoted or p in refs or promoted[p]!=h]
        n['operations']+=[dict(op='remove',pointer=['source_sha256',p],existed=True,old=promoted[p],new=None) for p in set(promoted)-set(wanted)]
        n['groups']+=additions(ident)
        n['declared_new_groups']=['authority_before_and_candidate_proofs']+additions(ident);nodes.append(n);continue
    target=n['target'];assert target in targets,(ident,target)
    parent=targets[target];base=load(parent['immutable_old'],parent['old_sha256']) if target.endswith('.json') else None
    pi='prewarm_parent_'+ident;pin(pi,parent['immutable_old'],parent['old_sha256']);n['base_input']=pi;n['old_sha256']=parent['old_sha256']
    if kind=='index':
        edits=[]
        for h in n['replacements']:
            val=h['new']
            if val=={'$pin':'execution_approval'}:edits.append(dict(old=proof['execution']['parent']['sha256'],new=val))
            elif isinstance(val,dict) and '$sha' in val:
                dest=next(x for x in old['nodes'] if x['id']==val['$sha']);t=dest.get('target');assert t in targets
                edits.append(dict(old=targets[t]['old_sha256'],new=val))
            elif h['old']=='const FORMAL_ENABLED=true' and val=='const FORMAL_ENABLED=false':edits.append(h)
            else:raise AssertionError((ident,h))
        n['replacements']=edits;nodes.append(n);continue
    if ident=='runtime_contract_final':
        n['kind']='space_contract';n['file']='runtime_contract_C_Field_prewarm8_successor.json';n['literal_candidate_input']='space_contract_literal';n['operations']=[op(['source_sha256',p],d['old'],refs[p]) for p,d in proof['contract']['changed'].items()];nodes.append(n);continue
    fields=n.get('source_bundle',{}).get('fields',[])+[r['pointer'] for r in n.get('source_fields',[])]
    n['operations']=[op(ptr+[p],h,refs[p]) for ptr in fields for p,h in at(base,ptr).items() if p in refs]
    if ident=='estate_final':
        n['kind']='prewarm_estate_one';assert len(n['source_fields'])==1;n['source_fields'][0]['groups']=['prewarm8_Field_helper1']
        if ['registry_sha256'] not in n['protected_pointers']:n['protected_pointers'].append(['registry_sha256'])
    elif n.get('source_bundle'):n['source_bundle']['groups']+=additions(ident)
    elif additions(ident):
        assert len(n['source_fields'])==1;n['source_fields'][0]['groups']+=additions(ident)
    for operation in n['operations']:
        holder=at(base,operation['pointer'][:-1]);k=operation['pointer'][-1];assert holder[k]==operation['old'];old_value_checks+=1
    nodes.append(n)
passed=[dict(target=p,old_sha256=r['parent']['sha256'],candidate_path=r['candidate']['path'],candidate_sha256=r['candidate']['sha256']) for p,r in proof['records'].items()]
ex=proof['execution'];passed.append(dict(target=EXEC,old_sha256=ex['parent']['sha256'],candidate_path=ex['candidate']['path'],candidate_sha256=ex['candidate']['sha256']))
spec=copy.deepcopy(old);spec.update(nodes=nodes,source_groups=list(groups.values()),root_target_allowlist=list(targets),pass_through_targets=passed,prospective_targets=[dict(target=r['target'],candidate_path=r['candidate_path'],sha256=r['candidate_sha256']) for r in passed],output_root=S+'outputs/root_prewarm8_profile04_exact29_stage01/',source_baseline='Fixed D596 after EA657/3550; old1853 Market exact closure and AP-parent header edge retained. New helper04 ordinary1, old03 history retained; profile04 purpose2 Market only; ordinary proof2 Docks only; four existing owned edges/old148 plus6. No geometry/native/mask/room/registry/DT/G/Router/UI writes.')
spec.pop('space_contract');spec['prewarm_contract']=dict(scope_input='space_scope',Root_backup_input='space_Root_backup',Root_backup_prefix=R+'prewarm_profile29_predeploy_backup/',Root_preparation_input='space_Root_preparation',expected_Root_preparation_document=approval,code_inverse_input='space_code_inverse',parent_execution_input='space_parent_execution',parent_map_inputs=parentmaps,root_input_freeze_pending=False)
spec['status']='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT';spec['blockers']=[]
for gate in spec['required_gates']:
    if gate['id']=='root_target_preauthorization':gate.update(input='space_Root_backup',pointer=['count'],equals=29)
driver=S+'stage_prewarm_profile29_NOTREADY.py';driverraw=(GAME/driver[6:]).read_bytes();ast.parse(driverraw.decode());spec['required_generator']=dict(path=driver,sha256=sha(driverraw))
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,w in v.items():
            if (k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input'] or k.endswith('_input')) and isinstance(w,str) and w in pins:used.add(w)
            if k=='$pin':used.add(w)
            collect(w)
    elif isinstance(v,list):
        for w in v:collect(w)
collect(spec);used.update(parentmaps.values());spec['pinned_inputs']=[r for i,r in pins.items() if i in used]
assert sum('target' in n for n in nodes)+len(passed)==29 and len(passed)==8 and len(parentmaps)==4
known=set()
def check(v):
    if isinstance(v,dict):
        if '$sha' in v:assert v['$sha'] in known,('EARLY_NODE',v)
        if '$pin' in v:assert v['$pin'] in used
        for w in v.values():check(w)
    elif isinstance(v,list):
        for w in v:check(w)
def groupcheck(i,stack):
    assert i not in stack;g=groups[i];check(g)
    if g['kind']=='node_dictionary':assert g['node'] in known
    if g['kind']=='union':
        for child in g['groups']:groupcheck(child,stack+[i])
for n in nodes:
    check(n.get('operations',[]));check(n.get('replacements',[]))
    for i in n.get('groups',[])+n.get('source_bundle',{}).get('groups',[])+[i for f in n.get('source_fields',[]) for i in f.get('groups',[])]:groupcheck(i,[])
    known.add(n['id'])
# Lossless offsets carry the entire input delta without displaying or retyping large JSON.
raw=enc(spec);dest=HERE/'source_input_prewarm_profile29_ROOT_REVIEW.json';assert not dest.exists()
with dest.open('xb') as stream:stream.write(raw)
aa=oldraw.decode().splitlines(keepends=True);bb=raw.decode().splitlines(keepends=True);patch=[]
for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
    if tag!='equal':patch.append(dict(old_offset=len(''.join(aa[:i]).encode()),new_offset=len(''.join(bb[:k]).encode()),old=''.join(aa[i:j]),new=''.join(bb[k:l])))
f,b=oldraw,raw
for d in reversed(patch):
    i=d['old_offset'];a,c=d['old'].encode(),d['new'].encode();assert f[i:i+len(a)]==a;f=f[:i]+c+f[i+len(a):]
    i=d['new_offset'];assert b[i:i+len(c)]==c;b=b[:i]+a+b[i+len(c):]
assert f==raw and b==oldraw
pr=dict(status='EXACT29_DRIVER_INPUT_READY_FOR_ROOT_FULL_READ_NOT_EXECUTED',driver=spec['required_generator'],input=dict(path=S+dest.name,sha256=sha(raw),bytes=len(raw)),parent_input=dict(path=oldpath,sha256=oldsha),input_offset_byte_patch=patch,whole_input_byte_forward_inverse=True,strict_JSON_parse=True,Root_backup_actual_schema='count29/targets(target,backup,sha256,bytes,source_ticks)',old_value_pointer_checks=old_value_checks,pin_count=len(spec['pinned_inputs']),group_count=len(groups),target_count=29,partition=dict(GD=15,JSON=14),code_proof=dict(path=proofpath,sha256=proofhash),four_parent_maps_from_D596=True,all_five_old_native_permission_gates_retained=True,old_two_wall_tuple_and_AP_parent_header_edge_retained=True,Stage_executions=0,engine_calls=0,collector_calls=0,canonical_writes=0)
pb=enc(pr);pp=HERE/'prewarm_profile29_driver_input_whole_inverse_NOT_EXECUTED.json'
with pp.open('xb') as stream:stream.write(pb)
print(json.dumps(dict(driver=pr['driver'],input=pr['input'],proof=dict(path=S+pp.name,sha256=sha(pb),bytes=len(pb)),pins=pr['pin_count'],groups=len(groups),old_pointer_checks=old_value_checks,Stage_executions=0)))
