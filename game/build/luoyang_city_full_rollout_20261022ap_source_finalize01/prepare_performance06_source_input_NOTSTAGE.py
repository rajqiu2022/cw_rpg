"""Prepare a NEW pending exact26 source input, never execute a Stage."""
import copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/';O=S+'performance06_source_recipe/'
R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
sha=lambda b:hashlib.sha256(b).hexdigest();path=lambda p:G/p.removeprefix('res://')
def fixed(p,s):
    b=path(p).read_bytes();assert sha(b)==s,('PIN_CHANGED',p);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def ptr(v,ks):
    for k in ks:v=v[k]
    return v
old=json.loads(fixed(S+'a2_source_recipe08/source_input_ROOT_LOCKED.json','7481f547419cda9282ae6cb9566421353d21e09c0a23b45ecd6bb919242fa23a'))
stage=json.loads(fixed(S+'outputs/root_artisan_A2_source_stage01/receipt.json','4688cdbb0fa137425cc5964d37d918da9358889e68dc6496f2b4fb6ee1405d8c'))
prod=json.loads(fixed(S+'performance05_dependencies/handoff_PRODUCTION_PROPOSAL.json','2140f39a3c61f87f089256b670f941b11a925c9b30f300e63d56c55a8acec3c7'))
approval=json.loads(fixed(prod['execution_proposal']['path'],prod['execution_proposal']['sha256']))
scope=json.loads(fixed(R+'integration18/scope26_full_old_backups_READY.json','d3eb45666421a4c2ea8b74edc0e1ac7e0dfdf8e4c39a76eca30b2586009060da'))
request=json.loads(fixed(S+'yamen_loading_perf04/exact26_existing_scope_PROPOSAL_NOT_APPROVED.json','203ee55193b8d34ab1e1804c13b78dab85189557141e21f32ec34ecba130796f'))
oldtargets={r['target']:r for r in request['targets']};assert len(oldtargets)==26
pins={r['id']:copy.deepcopy(r) for r in old['pinned_inputs']}
def pin(i,p,s):pins[i]={'id':i,'path':p,'sha256':s};return {'$pin':i}
pin('execution_approval',prod['execution_proposal']['path'],prod['execution_proposal']['sha256'])
pin('performance_parent_approval',prod['execution_parent']['snapshot'],prod['execution_parent']['sha256'])
pin('performance_production',S+'performance05_dependencies/handoff_PRODUCTION_PROPOSAL.json','2140f39a3c61f87f089256b670f941b11a925c9b30f300e63d56c55a8acec3c7')
pin('performance_scope',R+'integration18/scope26_full_old_backups_READY.json','d3eb45666421a4c2ea8b74edc0e1ac7e0dfdf8e4c39a76eca30b2586009060da')
pin('performance_scope_request',S+'yamen_loading_perf04/exact26_existing_scope_PROPOSAL_NOT_APPROVED.json','203ee55193b8d34ab1e1804c13b78dab85189557141e21f32ec34ecba130796f')
pin('performance_admission',R+'performance04_candidate_admission_READY.json','35a64923799596fc799a45d8c04c58ef14608dc7df242cadf1b0d7b60de595a6')
pin('temple_real_binding',prod['temple_binding']['path'],prod['temple_binding']['sha256'])
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
HASH='res://scripts/city/luoyang_parallel_source_hash_20261017k.gd'
DT='res://scripts/city/luoyang_district_life_20261016f.gd'
REG='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
runtime='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
hashrow=next(r for r in prod['consumers'] if r['target']==HASH)
refs={r['target']:r['candidate']['sha256'] for r in prod['consumers']};refs[EXE]={'$pin':'execution_approval'}
cur={}
for n in old['nodes']:
    if n['kind']=='map':continue
    a=stage['nodes'][n['id']];raw=fixed(a['path'],a['sha256'])
    cur[n['id']]={**a,'bytes':raw,'value':json.loads(raw) if not n['kind']=='index' and n['id']!='ap_environment_index' else None}
    if n.get('target') and n['target'] in oldtargets:refs[n['target']]={'$sha':n['id']}
refs[REG]={'$sha':'registry_final'}
def known(ref):
    if isinstance(ref,dict) and set(ref)=={'$pin'}:return pins[ref['$pin']]['sha256']
    if isinstance(ref,dict) and set(ref)=={'$owned'}:return approval['owned'][ref['$owned']]['current_sha256']
    if isinstance(ref,dict) and '$sha' in ref:return None
    return ref
def source_ops(base,fields):
    ops=[]
    for f in fields:
        values=ptr(base,f)
        for p,ref in refs.items():
            if p in values and (known(ref) is None or values[p]!=known(ref)):
                ops.append({'op':'set','pointer':f+[p],'existed':True,'old':values[p],'new':ref})
    return ops
nodes=[]
for oldn in old['nodes']:
    n=copy.deepcopy(oldn);i=n['id']
    if n['kind']=='map':
        for op in n['operations']:
            key=op['pointer'][-1]
            if key in refs:op['new']=refs[key]
        assert not any(op['pointer'][-1] in approval['owned'] for op in n['operations'])
        baseline=next(x for x in old['pinned_inputs'] if x['id']==n['base_input'])
        values=json.loads(fixed(baseline['path'],baseline['sha256']))['source_sha256']
        assert values[HASH]==hashrow['old_sha256'] and not any(op['pointer'][-1]==HASH for op in n['operations'])
        n['operations'].append({'op':'set','pointer':['source_sha256',HASH],'existed':True,'old':values[HASH],'new':hashrow['candidate']['sha256']})
        nodes.append(n);continue
    c=cur[i];base=c['value'];inputid='perf_parent_'+i;pin(inputid,c['path'],c['sha256']);n['base_input']=inputid
    if n.get('target'):n['old_sha256']=c['sha256']
    if i in ['runtime_contract_final','ap_environment_index']:
        nodes.append({'id':i,'kind':'performance_frozen_node','base_input':inputid,'immutable_sha256':c['sha256']});continue
    if i=='registry_final':
        ids=json.loads(fixed(REG,'04c83409719062ebb56aef84e4f116d8a352556c187b39906ce3e44ba9d6fdc3'))['ap_return_successor']['room_ids']
        assert len(ids)==5
        ops=[{'op':'set','pointer':['rooms',room,'source_sha256',DT],'existed':True,'old':base['rooms'][room]['source_sha256'][DT],'new':refs[DT]} for room in ids]
        assert all(op['old']=='185b51ff7b9256657424ba0681660d6d335f890f6c919260b3f467384d03ac16' for op in ops)
        nodes.append({'id':i,'kind':'metadata','base_input':inputid,'target':REG,'old_sha256':c['sha256'],'file':'registry_source_successor.json','source_policy':'old_city_or_market','operations':ops,'protected_pointers':[['ap_return_successor'],['history']]});continue
    if n['kind']=='index':
        rs=[]
        for rep in n['replacements']:
            if rep['old']=='const FORMAL_ENABLED=true':rs.append(rep);continue
            ref=rep['new']
            prior=cur[ref['$sha']]['sha256'] if isinstance(ref,dict) and '$sha' in ref else prod['execution_parent']['sha256'] if ref=={'$pin':'execution_approval'} else rep['old']
            assert c['bytes'].decode().count(prior)==1,(i,prior)
            rs.append({'old':prior,'new':ref})
        n['replacements']=rs;nodes.append(n);continue
    if n['kind']=='a2_quarter':n['kind']='metadata';n.pop('a2_geometry_declaration_operations',None)
    n.pop('literal_candidate_input',None)
    fields=[f['pointer'] for f in n.get('source_fields',[])]+n.get('source_bundle',{}).get('fields',[])
    n['operations']=source_ops(base,fields)
    if i=='estate_final':n['operations'].append({'op':'set','pointer':['registry_sha256'],'existed':True,'old':base['registry_sha256'],'new':{'$sha':'registry_final'}})
    nodes.append(n)
groups=copy.deepcopy(old['source_groups'])
for group in groups:
    if group['kind']=='explicit':
        for p,ref in refs.items():
            if p in group['leaves']:group['leaves'][p]=ref
passes=[{'target':r['target'],'old_sha256':r['old_sha256'],'candidate_path':r['candidate']['path'],'candidate_sha256':r['candidate']['sha256'],'exact_replacements':r['forward_hunks']} for r in prod['consumers']]
passes.append({'target':EXE,'old_sha256':prod['execution_parent']['sha256'],'candidate_path':prod['execution_proposal']['path'],'candidate_sha256':prod['execution_proposal']['sha256']})
targets={r['target'] for r in passes}|{n['target'] for n in nodes if 'target' in n}
assert targets==set(oldtargets) and len(targets)==26
gates=copy.deepcopy(old['required_gates'])
for gate in gates:
    if gate['id']=='root_target_preauthorization':gate['input']='performance_scope'
spec={k:copy.deepcopy(old[k]) for k in ['schema_version','authority_input','authority_helper_input','common_group']}
spec.update(status='PENDING_ROOT_EXACT_PERFORMANCE_EXECUTION_APPROVAL_AND_EXTERNAL_LOCK',output_root=S+'outputs/root_performance05_source_stage01/',blockers=['Root exact85DF-to428A execution approval must be pinned; driver/input full review and external lock'],prospective_targets=[{'target':r['target'],'candidate_path':r['candidate']['path'],'sha256':r['candidate']['sha256']} for r in prod['consumers']],source_groups=groups,required_gates=gates,pass_through_targets=passes,nodes=nodes,root_target_allowlist=[r['target'] for r in request['targets']],required_generator={'path':S+'stage_performance06_READY.py','sha256':'PENDING_FIXED_NEW_TOOL'},performance_contract={'production_input':'performance_production','parent_approval_input':'performance_parent_approval','scope_input':'performance_scope','scope_request_input':'performance_scope_request','candidate_admission_input':'performance_admission','execution_root_input':'PENDING_ROOT_FIXED_EXECUTION_APPROVAL','target_count':26,'partition':{'GD_apply_patch':12,'generated_JSON_exact_copy':14},'actual_parent_stage_sha256':'4688cdbb0fa137425cc5964d37d918da9358889e68dc6496f2b4fb6ee1405d8c','current_AP11_classification_kept':True,'original63_proof_pins_exact':True,'new_proof_pin_count':67,'no_geometry_native_or_media_delta':True},source_baseline='Frozen AO maps + actual4688 AP11 metadata; exact three owned succession and one nonowned hash successor; no observed collector values')
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,x in v.items():
            if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input'] and isinstance(x,str) and x in pins:used.add(x)
            if k=='$pin':used.add(x)
            collect(x)
    elif isinstance(v,list):
        for x in v:collect(x)
collect(spec['nodes']);collect(groups);collect(gates)
used.update(x for x in spec['performance_contract'].values() if isinstance(x,str) and x in pins)
spec['pinned_inputs']=[r for r in pins.values() if r['id'] in used]
for row in spec['pinned_inputs']:fixed(row['path'],row['sha256'])
summary={'status':'EXACT26_SOURCE_RECIPE_PREPARED_NOT_STAGED','targets':26,'GD':12,'JSON':14,'metadata_parents_from_actual4688':True,'original_four_maps_from_AO_not_current_collector':True,'registry_only_five_DT_sources':True,'runtime_contract_ENV_Family_Field_Coordinator_G_unchanged':True,'native_geometry_media_unchanged':True,'source_stage_engine_collector_calls':0,'missing_Root_execution_approval_explicit_blocker':True}
out={O+'source_input_PENDING_ROOT.json':js(spec),O+'preparation_summary_NOT_STAGE.json':js(summary)}
assert not path(O).exists()
for p,b in out.items():
    path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as f:f.write(b)
print(json.dumps({'input':{'path':O+'source_input_PENDING_ROOT.json','sha256':sha(out[O+'source_input_PENDING_ROOT.json'])},'target_count':26,'stage_runs':0}))
