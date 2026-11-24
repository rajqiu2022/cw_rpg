"""Prepare a blocked, explicit A2 source DAG and exact scope request, not a stage.

All parents are immutable885A outputs plus deployed ED4C/DB9D snapshots.
The two new mask imports are fixed by78528, still requiring Root promotion.
No current collector, native decode, canonical hash crawl, Stage or engine.
"""
import copy
import hashlib
import json
from pathlib import Path

H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'a2_source_recipe05/'
ROOT='res://build/luoyang_city_full_rollout_20261022ap_root01/'
SYSTEM='res://build/luoyang_city_full_rollout_20261022ap_system01/'
ARTISAN='luoyang_artisan_residential_20261022ap'
FAMILY='res://scripts/city/luoyang_quarters_family_20261022ap.gd'
ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def path(p):
    assert p.startswith('res://') and '..' not in p
    return G/p[6:]
def fixed(p,s):
    b=path(p).read_bytes();assert sha(b)==s,('PIN_CHANGED',p);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def pointer(v,ks):
    for k in ks:v=v[k]
    return v

old=json.loads(fixed(S+'finite09_input02_ROOT_LOCKED.json','eaed904ce017d9e801b51165e0be2598c8646df53c5938d91eba54b36e908972'))
stage=json.loads(fixed(S+'outputs/root_finite09_two_domain_stage02/receipt.json','885a813db26487582bc7cb31d02ec89827dc929a9e2653e71137defd8ff8c3a0'))
prod=json.loads(fixed(S+'a2_production04/handoff_PRODUCTION_PROPOSAL.json','258cde4cb62b3f5fa2e1ac01cb08a322ffc6b8eca3d63c11c34b2add161f7085'))
binding=json.loads(fixed(prod['binding']['path'],prod['binding']['sha256']))
approval=json.loads(fixed(prod['execution_proposal']['path'],prod['execution_proposal']['sha256']))
rootexecution=ROOT+'artisan_A2_production04_execution_scope_READY.json'
auth=json.loads(fixed(rootexecution,'89f6fb928ce90475c67a32dd75a68c6aa3a974769b3e10d38d2059c159b7febf'))
assert auth['approved_by_root'] is True and auth['proposal']['sha256']==prod['execution_proposal']['sha256']
maskreport=SYSTEM+'a2mi01/single_walk_import_result_78528.json'
fixed(maskreport,'299fcadbe84424197f095d737ecdbca8740612779176578fbbb5ddf249de0b3f')
spec=copy.deepcopy(old)
pins={r['id']:r for r in spec['pinned_inputs']}
def pin(ident,p,s):pins[ident]={'id':ident,'path':p,'sha256':s};return {'$pin':ident}
pin('a2_production_handoff',S+'a2_production04/handoff_PRODUCTION_PROPOSAL.json','258cde4cb62b3f5fa2e1ac01cb08a322ffc6b8eca3d63c11c34b2add161f7085')
pin('a2_binding',prod['binding']['path'],prod['binding']['sha256'])
pin('a2_root_execution',rootexecution,'89f6fb928ce90475c67a32dd75a68c6aa3a974769b3e10d38d2059c159b7febf')
pin('a2_mask_actual',maskreport,'299fcadbe84424197f095d737ecdbca8740612779176578fbbb5ddf249de0b3f')
pin('a2_root_code',ROOT+'artisan_A2_runtime03_code_scope_admission_READY.json','bbbd2ff11077f66940c5159326631e98bcc73527ab198b090b1305520d6d62cd')
pin('execution_approval',prod['execution_proposal']['path'],prod['execution_proposal']['sha256'])
pin('a2_execution_parent',prod['execution_parent']['snapshot'],prod['execution_parent']['sha256'])
pin('runtime_contract_candidate',prod['contract']['path'],prod['contract']['sha256'])
pin('temple_real_binding',prod['temple_binding']['path'],prod['temple_binding']['sha256'])
env=next(r for r in prod['consumers'] if r['target']==ENV)
pin('environment_helper',env['candidate']['path'],env['candidate']['sha256'])
spec['status']='PENDING_ROOT_EXACT_A2_SCOPE_MASK_PROMOTION_AND_LOCK'
spec['output_root']=S+'outputs/root_artisan_A2_source_stage01/'
spec['blockers']=['Root exact target scope and full backups','Root exact two mask leaf promotion actual','Root full stager/input read and external SHA lock']
spec['required_generator']={'path':S+'stage_a2_source05_READY.py','sha256':'PENDING_TOOL_NOT_EXECUTABLE'}
spec.pop('finite08_contract',None)
spec.pop('root_lock_scope',None)
spec['pass_through_targets']=[];spec['prospective_targets']=[]
for r in prod['consumers']:
    d=r['candidate']
    spec['prospective_targets'].append({'target':r['target'],'candidate_path':d['path'],'sha256':d['sha256']})
    spec['pass_through_targets'].append({'target':r['target'],'old_sha256':r['old_sha256'],'candidate_path':d['path'],'candidate_sha256':d['sha256'],'exact_replacements':r['inverse_replacements']})
spec['pass_through_targets'].append({'target':EXE,'old_sha256':prod['execution_parent']['sha256'],'candidate_path':prod['execution_proposal']['path'],'candidate_sha256':prod['execution_proposal']['sha256']})
refs={r['target']:r['candidate']['sha256'] for r in prod['consumers']}
refs[EXE]={'$pin':'execution_approval'};refs[CONTRACT]={'$pin':'runtime_contract_candidate'}
original_nodes={r['id']:r for r in old['nodes']}
for node in old['nodes']:
    if node.get('target') and node['id'] not in ['registry_final','ap_environment_index','runtime_contract_final']:
        refs[node['target']]={'$sha':node['id']}
refs[CONTRACT]={'$pin':'runtime_contract_candidate'}
# The finite manifests are now existing authoritative targets. Rebase their
# source classes in place; never rerun the old constructor from a T parent.
runtime_targets={d:S+'finite_adapter_production08/runtime_'+d+'_manifest_READY.json' for d in ['market','yamen']}
for d,t in runtime_targets.items():refs[t]={'$sha':'finite08_'+d}
current={}
for node in old['nodes']:
    if node['kind']=='map':continue
    record=stage['nodes'][node['id']]
    if node['id']=='ap_city_index':record={'path':S+'finite10_yamen_classification/FullCityIndex_yamen_classification_READY.gd','sha256':'db9d5e277d7e86e58e799804822d83959833c3700d24444f5fe48d359d9bd088'}
    if node['id']=='finite08_yamen':record={'path':S+'finite10_yamen_classification/runtime_yamen_manifest_classification_READY.json','sha256':'ed4cee9e730f96af624354dd08ad6d8875259ba38827fc96df0c493da44c1794'}
    raw=fixed(record['path'],record['sha256'])
    current[node['id']]={**record,'value':json.loads(raw) if node['kind'] not in ['index','finite_index'] else None,'bytes':raw}

def known(v):
    if isinstance(v,dict) and set(v)=={'$pin'}:return pins[v['$pin']]['sha256']
    if isinstance(v,dict) and set(v)=={'$owned'}:return approval['owned'][v['$owned']]['current_sha256']
    if isinstance(v,dict) and set(v)=={'$sha'}:return None
    return v
def source_ops(base,fields):
    ops=[]
    for field in fields:
        values=pointer(base,field)
        for p,ref in refs.items():
            if p in values and (known(ref) is None or values[p]!=known(ref)):
                ops.append({'op':'set','pointer':field+[p],'existed':True,'old':values[p],'new':ref})
    return ops

nodes=[]
for oldnode in old['nodes']:
    node=copy.deepcopy(oldnode);ident=node['id']
    if node['kind']=='map':
        # Preserve frozen AO baseline and original genuine nonowned operations.
        # M.map promotes owned first, so never introduce redundant owned sets.
        ops=[]
        for op in node['operations']:
            ks=op['pointer'];leaf=ks[-1]
            if leaf in approval['owned'] and ks[0]=='source_sha256':continue
            if leaf in refs:op['new']=refs[leaf]
            ops.append(op)
        node['operations']=ops
        nodes.append(node);continue
    c=current[ident];base=c['value']
    inputid='a2_parent_'+ident;pin(inputid,c['path'],c['sha256']);node['base_input']=inputid
    if node.get('target'):node['old_sha256']=c['sha256']
    if ident in ['registry_final','ap_environment_index']:
        # Genuine unchanged data/index nodes: keep exact frozen bytes and SHA,
        # not a no-op target and not a newly reformatted generated JSON.
        node={'id':ident,'kind':'a2_frozen_node','base_input':inputid,'immutable_sha256':c['sha256']}
        nodes.append(node);continue
    if ident=='runtime_contract_final':
        node['kind']='a2_contract'
        field='res://scripts/field/field_walkable_controller.gd'
        node['operations']=[{'op':'set','pointer':['source_sha256',field],'existed':True,'old':base['source_sha256'][field],'new':refs[field]}]
        node['literal_candidate_input']='runtime_contract_candidate'
        nodes.append(node);continue
    if ident in ['finite08_market','finite08_yamen']:
        d='market' if ident.endswith('market') else 'yamen'
        fields=[['legacy_source_sha256'],['runtime_authority_sha256'],['artifacts']]
        node={'id':ident,'kind':'metadata','base_input':inputid,'target':runtime_targets[d],'old_sha256':c['sha256'],'file':'runtime_'+d+'_source_successor.json','source_policy':'old_city_or_market','source_bundle':{'fields':fields,'default_destination':['legacy_source_sha256'],'new_source_routes':[{'prefix':'res://data/maps/luoyang_layout_bundle_20261018t_retry2/','destination':['runtime_authority_sha256']},{'prefix':'res://data/maps/luoyang_layout_rooms_20261018t/','destination':['runtime_authority_sha256']}],'groups':['common_four_city']+(['quarter_final_sources','quarter_final_header','G_new_return_header_only'] if d=='market' else [])},'protected_pointers':[[k] for k in ['geometry_proof_basis','artifacts','mask_sha256','parent_publication'] if k in base]}
        node['operations']=source_ops(base,fields)
        nodes.append(node);continue
    if node['kind'] in ['index','finite_index']:
        node['kind']='index';replacements=[]
        for r in oldnode['replacements']:
            if r['old']=='const FORMAL_ENABLED=true':replacements.append(r);continue
            if isinstance(r['new'],dict) and '$sha' in r['new']:oldsha=current[r['new']['$sha']]['sha256']
            elif r['new']=={'$pin':'execution_approval'}:oldsha=prod['execution_parent']['sha256']
            else:oldsha=r['old']
            assert c['bytes'].decode().count(oldsha)==1,(ident,oldsha)
            replacements.append({'old':oldsha,'new':r['new']})
        if ident=='ap_city_index':
            for d in ['market','yamen']:
                oldsha=current['finite08_'+d]['sha256'];assert c['bytes'].decode().count(oldsha)==1
                replacements.append({'old':oldsha,'new':{'$sha':'finite08_'+d}})
        node['replacements']=replacements
        nodes.append(node);continue
    fields=[f['pointer'] for f in node.get('source_fields',[])]+node.get('source_bundle',{}).get('fields',[])
    node['operations']=source_ops(base,fields)
    if ident=='quarter_final':
        node['kind']='a2_quarter'
        node['a2_geometry_declaration_operations']=[]
        for field,suffix in [('scene_path','scene.res'),('layout_path','layout.res'),('packet_path','packet.bin')]:
            node['a2_geometry_declaration_operations'].append({'op':'set','pointer':['scenes',ARTISAN,field],'existed':True,'old':base['scenes'][ARTISAN][field],'new':binding['child'][suffix]['path']})
        assert 'a2_artisan_successor' not in base
        node['a2_geometry_declaration_operations'].append({'op':'set','pointer':['a2_artisan_successor'],'existed':False,'old':None,'new':{'binding_path':prod['binding']['path'],'binding_sha256':prod['binding']['sha256']}})
        node['source_fields'][0]['groups'].append('a2_declared_native_material_proofs')
    nodes.append(node)

groups={r['id']:copy.deepcopy(r) for r in old['source_groups']}
for group in groups.values():
    if group['kind']=='explicit':
        for p,ref in refs.items():
            if p in group['leaves']:group['leaves'][p]=ref
# Only Quarter shared proof (+Market transitive) gains the A2 artifacts and
# material leaves; other four-city common source groups do not gain A2 media.
newleaves=copy.deepcopy(binding['source_sha256'])
newleaves[prod['binding']['path']]=prod['binding']['sha256']
newleaves[prod['runtime_material_helper']['path']]=prod['runtime_material_helper']['sha256']
for key in ['A2_MATERIAL_CONTRACT','A2_MATERIAL_SHADER']:
    # Fixed literals were source-reviewed in03, never extracted from live code.
    suffix='ground_contract_READY.json' if key.endswith('CONTRACT') else 'ground_use_candidate.gdshader'
    p=SYSTEM+'artisan_a2_publication_epoch01/'+suffix
    newleaves[p]='87abb71b03de83e2d5c14434b52d56a8be51dfe940ed85478fc34b029a4ed5af' if key.endswith('CONTRACT') else '11b32bb0efbc9b1317c2ad06d028742d9bfce899e2d9b9467874c28898c2eb1e'
png=binding['child']['walk.png']['path']
newleaves[png+'.import']='b72003ea99c91ebe744bee65218c5d37f72ff87a3a28668cc7f576bcd430b7f2'
compiled='res://.godot/imported/walk.png-aa86f43aaf14f1c61fc40a8827e9e3f1.ctex'
newleaves[compiled]='f583203a326a4750428a0a6689c7d35dadd749408eb051c8bb1d6200cb9293a8'
groups['a2_declared_native_material_proofs']={'id':'a2_declared_native_material_proofs','kind':'explicit','leaves':newleaves}
for n in nodes:
    if n['kind']=='map' and n['scene_id']=='ch4_s3_luoyang_market':n['runtime_media_roots'].append({'path':png,'compiled_paths':[compiled]})
spec['nodes']=nodes;spec['source_groups']=list(groups.values())
scoperows=[]
for r in spec['pass_through_targets']:
    snapshot=prod['execution_parent']['snapshot'] if r['target']==EXE else next(v['parent_snapshot']['path'] for v in prod['consumers'] if v['target']==r['target'])
    scoperows.append({'target':r['target'],'old_sha256':r['old_sha256'],'old_snapshot':snapshot})
for n in nodes:
    if n.get('target'):
        scoperows.append({'target':n['target'],'old_sha256':n['old_sha256'],'old_snapshot':pins[n['base_input']]['path']})
assert len(scoperows)==28 and len({r['target'] for r in scoperows})==28
assert not any(r['target'].endswith('/registry.json') or r['target'].endswith('/luoyang_environment_index_20261022ap.gd') for r in scoperows)
spec['root_target_allowlist']=[r['target'] for r in scoperows]
scope={'status':'A2_EXACT28_SOURCE_SUCCESSOR_SCOPE_REQUEST_NOT_APPROVED','target_count':28,'targets':scoperows,'new_media_targets':[{'path':png+'.import','old_sha256':'ABSENT','candidate_sha256':newleaves[png+'.import']},{'path':compiled,'old_sha256':'ABSENT','candidate_sha256':newleaves[compiled]}],'unchanged_registry_historical_G_and_ENVindex':True,'Yamen_ED4C_and_APINDEX_DB9D_parents':True,'no_native_copy_or_geometry_replay':True}
spec['a2_contract']={'production_handoff_input':'a2_production_handoff','binding_input':'a2_binding','execution_root_input':'a2_root_execution','execution_parent_input':'a2_execution_parent','mask_actual_input':'a2_mask_actual','code_root_input':'a2_root_code','scope_input':'PENDING_ROOT_SCOPE','scope_request_input':'a2_scope_request','mask_promotion_input':'PENDING_ROOT_PROMOTION_ACTUAL','exact_target_count':28,'old_owned_count':10,'old_proof_pin_count':57,'new_proof_pin_count':63,'runtime_inverse_replay':False}
spec['repair_epoch_contract']={'parent885A_actual':True,'classification_ED4C_DB9D_inherited':True,'no_full29_replay':True,'no_collector_expected_fill':True,'first_promote_owned_then_exact_nonowned_map_operations':True}
scopepath=O+'exact28_scope_request_NOT_APPROVED.json'
pin('a2_scope_request',scopepath,sha(js(scope)))
used={spec['authority_input'],spec['authority_helper_input']}
def collect(v):
    if isinstance(v,dict):
        for k,x in v.items():
            if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input'] and isinstance(x,str) and x in pins:used.add(x)
            if k=='$pin':used.add(x)
            collect(x)
    elif isinstance(v,list):
        for x in v:collect(x)
collect(nodes);collect(spec['source_groups']);collect(spec['required_gates'])
used.update(v for v in spec['a2_contract'].values() if isinstance(v,str) and v in pins)
spec['pinned_inputs']=[r for r in pins.values() if r['id'] in used]
for r in spec['pinned_inputs']:
    if r['id']!='a2_scope_request':fixed(r['path'],r['sha256'])
outputs={scopepath:js(scope),O+'source_input_PENDING_ROOT.json':js(spec)}
summary={'status':'A2_SOURCE_DAG_PREPARED_NOT_EXECUTED','exact_targets':28,'metadata_and_indices_rebased_on_frozen885A_plus_ED4C_DB9D':True,'registry_and_ENVindex_frozen_nodes_not_targets':True,'scenes_and_only_Artisan_row_paths_plus_fixed_A2_declaration':True,'two_mask_expected_pins_from78528_not_yet_promoted':True,'four_expected_maps_from_frozen_AO_baselines_not_observed_hashes':True,'new_group_proof_leaf_count':len(newleaves),'stage_engine_collector_decode_canonical_write_calls':0}
outputs[O+'preparation_summary_NOT_STAGE.json']=js(summary)
assert not path(O).exists()
for p,b in outputs.items():
    path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as f:f.write(b)
print(json.dumps({'input':{'path':O+'source_input_PENDING_ROOT.json','sha256':sha(outputs[O+'source_input_PENDING_ROOT.json'])},'scope':{'path':scopepath,'sha256':sha(js(scope))},'target_count':28,'stage_calls':0}))
