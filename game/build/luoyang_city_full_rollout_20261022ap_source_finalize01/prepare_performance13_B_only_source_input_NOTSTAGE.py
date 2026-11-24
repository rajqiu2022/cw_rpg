"""Prepare NEW pending exact22 source recipe from immutable D058/AP12; no Stage."""
import copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance13_B_only_source_recipe/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def ptr(v,keys):
    for k in keys:v=v[k]
    return v
old=json.loads(fixed(S+'performance07_source_recipe/source_input_ROOT_LOCKED.json','1e40d5b252afd5246f78cc14a00ea541cdd940cb31011077d26105cf12842d95'))
stagepath=S+'outputs/root_performance05_source_stage01/receipt.json';stagesha='d0583b4ca4b6ef8703d73efb1e5487ea7a62866cb738d756eb262d6e0419a282'
stage=json.loads(fixed(stagepath,stagesha))
handpath=S+'performance12_B_only_dependencies/handoff_PRODUCTION_PROPOSAL.json';handsha='0b475ef75769431cb02b46a2a6e3daab6312ab3a7289b837d361ad2bdedfb79c'
hand=json.loads(fixed(handpath,handsha));approval=json.loads(fixed(hand['execution_proposal']['path'],hand['execution_proposal']['sha256']))
request=json.loads(fixed(hand['scope_request']['path'],hand['scope_request']['sha256']))
oldtargets={r['target']:r for r in request['targets']};assert len(oldtargets)==22
pins={r['id']:copy.deepcopy(r) for r in old['pinned_inputs']}
def pin(i,path,s):pins[i]={'id':i,'path':path,'sha256':s};return {'$pin':i}
pin('execution_approval',hand['execution_proposal']['path'],hand['execution_proposal']['sha256'])
pin('B_only_parent_approval',hand['execution_parent']['snapshot'],hand['execution_parent']['sha256'])
pin('B_only_production',handpath,handsha)
pin('B_only_scope_request',hand['scope_request']['path'],hand['scope_request']['sha256'])
pin('B_only_actual_parent_stage',stagepath,stagesha)
B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd';EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
edge=hand['owned_changed_exactly1'][0]
refs={B:edge['new_sha256'],EXE:{'$pin':'execution_approval'}}
cur={}
for n in old['nodes']:
    if n['kind']=='map':continue
    a=stage['nodes'][n['id']];raw=fixed(a['path'],a['sha256'])
    cur[n['id']]={**a,'bytes':raw,'value':json.loads(raw) if n['kind']!='index' and n['id']!='ap_environment_index' else None}
    if n.get('target') in oldtargets:refs[n['target']]={'$sha':n['id']}
def known(ref):
    if isinstance(ref,dict) and set(ref)=={'$pin'}:return pins[ref['$pin']]['sha256']
    if isinstance(ref,dict) and set(ref)=={'$owned'}:return approval['owned'][ref['$owned']]['current_sha256']
    if isinstance(ref,dict) and '$sha' in ref:return None
    return ref
def source_ops(base,fields):
    ops=[]
    for f in fields:
        values=ptr(base,f)
        for path,ref in refs.items():
            if path in values and (known(ref) is None or values[path]!=known(ref)):
                ops.append({'op':'set','pointer':f+[path],'existed':True,'old':values[path],'new':ref})
    return ops
nodes=[]
for oldn in old['nodes']:
    n=copy.deepcopy(oldn);i=n['id']
    if n['kind']=='map':
        for op in n['operations']:
            path=op['pointer'][-1]
            if path in refs:op['new']=refs[path]
        assert not any(op['pointer'][-1] in approval['owned'] for op in n['operations'])
        nodes.append(n);continue
    c=cur[i];inputid='B_parent_'+i;pin(inputid,c['path'],c['sha256']);n['base_input']=inputid
    if n.get('target'):n['old_sha256']=c['sha256']
    if i in ['runtime_contract_final','ap_environment_index','registry_final']:
        nodes.append({'id':i,'kind':'B_only_frozen_node','base_input':inputid,'immutable_sha256':c['sha256']});continue
    if n['kind']=='index':
        rs=[]
        for rep in n['replacements']:
            if rep['old']=='const FORMAL_ENABLED=true':rs.append(rep);continue
            ref=rep['new']
            prior=cur[ref['$sha']]['sha256'] if isinstance(ref,dict) and '$sha' in ref else hand['execution_parent']['sha256'] if ref=={'$pin':'execution_approval'} else rep['old']
            assert c['bytes'].decode().count(prior)==1,(i,prior)
            rs.append({'old':prior,'new':ref})
        n['replacements']=rs;nodes.append(n);continue
    fields=[f['pointer'] for f in n.get('source_fields',[])]+n.get('source_bundle',{}).get('fields',[])
    n['operations']=source_ops(c['value'],fields)
    assert all(op['pointer'][-1] in refs for op in n['operations'])
    nodes.append(n)
groups=copy.deepcopy(old['source_groups'])
for group in groups:
    if group['kind']=='explicit':
        for path,ref in refs.items():
            if path in group['leaves']:group['leaves'][path]=ref
passes=[{'target':B,'old_sha256':edge['old_sha256'],'candidate_path':edge['new_snapshot'],'candidate_sha256':edge['new_sha256']},
        {'target':EXE,'old_sha256':hand['execution_parent']['sha256'],'candidate_path':hand['execution_proposal']['path'],'candidate_sha256':hand['execution_proposal']['sha256']}]
targets={r['target'] for r in passes}|{n['target'] for n in nodes if 'target'in n}
assert targets==set(oldtargets) and len(targets)==22
gates=copy.deepcopy(old['required_gates'])
for gate in gates:
    if gate['id']=='root_target_preauthorization':gate['input']='B_only_scope'
spec={k:copy.deepcopy(old[k]) for k in ['schema_version','authority_input','authority_helper_input','common_group']}
spec.update(status='PENDING_ROOT_B_ONLY_EXECUTION_APPROVAL_SCOPE_AND_EXTERNAL_LOCK',output_root=S+'outputs/root_B_only_symmetric_wire_stage01/',
 blockers=['Root exact428A-toA816 execution approval and exact22 full-old backup scope must be pinned before NEW lock; no Stage preparation authorization implies execution'],
 prospective_targets=[{'target':B,'candidate_path':edge['new_snapshot'],'sha256':edge['new_sha256']}],
 source_groups=groups,required_gates=gates,pass_through_targets=passes,nodes=nodes,
 root_target_allowlist=[r['target'] for r in request['targets']],required_generator={'path':S+'stage_performance13_B_only_PREPARATION_ONLY.py','sha256':'PENDING_FIXED_NEW_DRIVER'},
 B_only_contract={'production_input':'B_only_production','parent_approval_input':'B_only_parent_approval','scope_input':'B_only_scope','scope_request_input':'B_only_scope_request','execution_root_input':'B_only_root_execution','actual_parent_stage_input':'B_only_actual_parent_stage','target_count':22,'partition':{'GD_apply_patch':9,'generated_JSON_exact_copy':13},'actual_parent_stage_sha256':stagesha,'current_AP12_four_parent_classification_kept':True,'original67_proof_pins_exact':True,'new_proof_pin_count':69,'no_geometry_native_media_or_gameplay_delta':True,'frozen_registry_sha256':cur['registry_final']['sha256']},
 source_baseline='Frozen AO maps + actual D058 AP12 metadata/9D004 independent owners; only B77-to7123 owned successor, no current collector values')
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,x in v.items():
            if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input'] and isinstance(x,str) and x in pins:used.add(x)
            if k=='$pin':used.add(x)
            collect(x)
    elif isinstance(v,list):
        for x in v:collect(x)
collect(nodes);collect(groups);collect(gates)
used.update(x for x in spec['B_only_contract'].values() if isinstance(x,str) and x in pins)
spec['pinned_inputs']=[r for r in pins.values() if r['id'] in used]
for row in spec['pinned_inputs']:fixed(row['path'],row['sha256'])
summary={'status':'EXACT22_PENDING_SOURCE_INPUT_PREPARED_NO_STAGE','targets':22,'GD':9,'JSON':13,'metadata_parents_from_actual_D058':True,'maps_rebuilt_from_original_frozen_AO_not_current_collector':True,'registry_contract_ENV_index_frozen_original_bytes':True,'Root_scope_and_execution_pins_explicit_pending':True,'source_stage_engine_collector_calls':0}
files={'source_input_PENDING_ROOT.json':js(spec),'preparation_summary_NOT_STAGE.json':js(summary)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({k:sha(v) for k,v in files.items()},indent=2))
