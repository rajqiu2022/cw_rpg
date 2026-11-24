"""Immutable-declaration-only preparation; emits NEW files for apply_patch, never Stage.

No collector/native decoder/canonical crawl. Parents are owner95, actual94 and
the previously admitted immutable code snapshots, not live observations.
"""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent
GAME=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
R=S.replace('_source_finalize01/','_root01/')
Y=S.replace('_source_finalize01/','_system01/')
O=S+'performance100_unified_life_garden_scholar_BUILD/'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
FIELD='res://scripts/field/field_walkable_controller.gd'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
FAMILY='res://scripts/city/luoyang_quarters_family_20261022ap.gd'
ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
NATIVE='res://scripts/city/luoyang_quarter_native_geometry_20261022ap.gd'
COORD='res://scripts/city/luoyang_culture_task_coordinator_20261019x.gd'
TEMPLE='res://scripts/city/luoyang_temple_district_20261019ad.gd'
ARTISAN='luoyang_artisan_residential_20261022ap'
GARDEN='luoyang_riverside_garden_20261022ap'
def path(p):
    assert p.startswith('res://') and '..'not in p
    return GAME/p[6:]
def digest(b):return hashlib.sha256(b).hexdigest()
def raw(p,s=None):
    b=path(p).read_bytes()
    if s:assert digest(b)==s,('PIN_CHANGED',p)
    return b
def load(p,s=None):return json.loads(raw(p,s))
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def jsref(p,s=None):return {'path':p,'sha256':s or digest(raw(p))}
def strict(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(strict(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(strict(x,y)for x,y in zip(a,b))
    return a==b
def hunks(before,after):
    a,b=before.decode().splitlines(keepends=True),after.decode().splitlines(keepends=True)
    sm=difflib.SequenceMatcher(None,a,b,autojunk=False)
    result=[]
    for group in sm.get_grouped_opcodes(3):
        x,y=group[0],group[-1]
        old=''.join(a[x[1]:y[2]]);new=''.join(b[x[3]:y[4]])
        if not old or not new or before.decode().count(old)!=1 or after.decode().count(new)!=1:
            return [{'old':before.decode(),'new':after.decode()}]
        result.append({'old':old,'new':new})
    f=before.decode();v=after.decode()
    for h in result:f=f.replace(h['old'],h['new'],1);v=v.replace(h['new'],h['old'],1)
    assert f.encode()==after and v.encode()==before
    return result
def ptr(v,ks):
    for k in ks:v=v[k]
    return v

def prepare():
    outputs={}
    ownerpath=S+'performance95_Docks_ordinary21_actual_independent_review/owner_source_maps_READY.json'
    owner=load(ownerpath,'c3b7c23523fd8d913cb21a57e72e3c07340a7d948017b67139e31d6088ba60cb')
    core=owner['core_source_sha256']
    # Recover exact canonical spellings from the fixed core; never a file scan.
    coord=next(p for p in core if 'coordinator' in p)
    temple=next(p for p in core if 'temple' in p and p.endswith('.gd'))
    native=next(p for p,s in core.items()if s=='3efaeff0d0fd6c24e3056e034f25350961730ba98826918baeeffa6962c6257b')
    priorpath=S+'performance91_Docks_AC_execution_BUILD/execution_successor_PROPOSAL_NOT_APPROVED.json'
    prior=load(priorpath,'d184d50821f11bf012bd34baac374c4939fdfa5c51f6c415d31e249bbc8a6f29')
    planpath=S+'performance94_Docks_candidate_identity_repair/source_input_NOTREADY.json'
    oldplan=load(planpath)
    stagepath=S+'outputs/root_Docks_ordinary21_stage02/receipt.json'
    stage=load(stagepath) # Root actual A75B is inherited, no 3GB source rehash.
    assert stage['target_partition']=={'patch_count':9,'copy_count':12,'total':21,'intersection_empty':True,'union_exact_targets':True}
    actual={r['target']:r for r in stage['targets']}
    bindingpath=S+'life_production100_READY/life_binding_READY.json'
    binding=load(bindingpath,'ff97c27d2660bc45bcd7f526dca4c1d7aca9329510de24e1fe767c959a433333')
    candidates={
      FAMILY:(S+'a2_production04/Family_A2_READY.gd',S+'life_production100_READY/Family_life_READY.gd','0f461e1094ad506b4ec3749ee546e4a174d50f68863c1a80b06f7e916805c6ff'),
      ENV:(Y+'market_L_continuous_material_epoch01/environment_A1_plus_OPTIONAL_forecourt_tone_CANDIDATE.gd',O+'ENV_life_scholar_CANDIDATE.gd','013bdb3a0f570a1aeecf977e2e3681f35beb37463396bc6c7bbd3a3eadb033d9'),
      native:(next(r['path']for r in oldplan['pinned_inputs']if r['id']=='quarter_native_geometry_helper'),Y+'garden_bridge_mouth_fit_epoch01/native_geometry_mouth_fit_CANDIDATE.gd','2f1decf00af028213c720135c9f5d96ca2aaaf9d344af71f8f9ff1b4f8d5ee9d'),
      FIELD:(next(e['new_snapshot']for e in prior['owned'][FIELD]['edges']if e['new_sha256']==core[FIELD]),R+'scholar_binding_CANDIDATE/field_walkable_controller_CANDIDATE.gd','f98b22cd600f3d09dbb153db5baac9d0dcc22c3658803d30f23b2ae9b7df47a4'),
      coord:(S+'performance57_market_receipt_dependencies/Coordinator_CANDIDATE.gd',O+'Coordinator_Field_contract_UTF8_CANDIDATE.gd','589f18c8095970888b346f2a3de4fa381ae53a7226c9da168c43653e443f474b'),
      temple:(S+'performance57_market_receipt_dependencies/Temple_CANDIDATE.gd',O+'Temple_Field_contract_UTF8_CANDIDATE.gd','d328a5ef1ff9f5adf7c8dc215b42fe5bd2f806ca420c3b4aaf9f47a713037f3f')}
    records={}
    for target,(parent,candidate,pin)in candidates.items():
        before=raw(parent,core[target]);after=raw(candidate,pin)
        assert b'\r'not in after and after.endswith(b'\n')
        records[target]={'target':target,'parent':jsref(parent,core[target]),'candidate':{'path':candidate,'sha256':pin,'bytes':len(after)},'hunks':hunks(before,after),'whole_byte_inverse':True}
    execution=copy.deepcopy(prior)
    for target in [FIELD,coord,temple]:
        r=records[target];row=execution['owned'][target]
        edge={'path':target,'old_sha256':row['current_sha256'],'new_sha256':r['candidate']['sha256'],'old_snapshot':r['parent']['path'],'new_snapshot':r['candidate']['path'],'whole_inverse':True,'replacements':r['hunks']}
        assert prior['source_sha256'][edge['old_snapshot']]==edge['old_sha256']
        row['edges'].append(edge);row['current_sha256']=edge['new_sha256']
        execution['source_sha256'][edge['new_snapshot']]=edge['new_sha256']
    contractpath=O+'runtime_contract_Field_literal_READY_NOTAPPROVED.json'
    bindingnewpath=O+'temple_binding_READY_NOTAPPROVED.json'
    for p,s in [(contractpath,'239ff4b09862a4a3066462a434b00a7bdba45e830d0eb1d93ff3a2d826914700'),(bindingnewpath,'b5d5be7e75d90f091779c505f0883f3f90050181a5bacd3170f72d3580a5631d')]:
        raw(p,s);execution['source_sha256'][p]=s
    assert len(prior['owned'])==len(execution['owned'])==10 and len(prior['source_sha256'])==96 and len(execution['source_sha256'])==101
    inverse=copy.deepcopy(execution)
    for target in [FIELD,coord,temple]:inverse['owned'][target]=copy.deepcopy(prior['owned'][target])
    inverse['source_sha256']=copy.deepcopy(prior['source_sha256'])
    assert strict(inverse,prior)and enc(inverse)==raw(priorpath)
    execpath=O+'execution_successor_PROPOSAL_NOT_APPROVED.json'
    outputs[execpath]=enc(execution)
    proof={'status':'UNIFIED_LIFE_GARDEN_SCHOLAR_CODE_AND_DATA_INVERSE_BUILD_NOT_RUNTIME','records':records,'execution_parent':jsref(priorpath),'execution_candidate':{'path':execpath,'sha256':digest(outputs[execpath])},'changed_owned':[FIELD,coord,temple],'old_owned':10,'new_owned':10,'old_proof_count':96,'new_proof_count':101,'added_proof_pins':{p:s for p,s in execution['source_sha256'].items()if p not in prior['source_sha256']},'whole_execution_typed_and_serialized_UTF8_inverse':True,'bad_first_Coordinator_and_Temple_preserved_not_consumed':True,'native_geometry_or_packet_decoded':False}
    for target,parent,candidate,keys in [(CONTRACT,S+'performance57_market_receipt_dependencies/runtime_contract_C_literal_READY.json',contractpath,['source_sha256',FIELD]),('temple_binding',S+'performance57_market_receipt_dependencies/temple_binding_three_literals_READY.json',bindingnewpath,None)]:
        before=raw(parent);after=raw(candidate);r={'parent':jsref(parent),'candidate':jsref(candidate),'hunks':hunks(before,after),'whole_byte_inverse':True,'parent_CRLF':before.count(b'\r\n'),'candidate_CRLF':after.count(b'\r\n')}
        a,b=json.loads(before),json.loads(after)
        if keys:
            expected=copy.deepcopy(a);expected['source_sha256'][FIELD]=records[FIELD]['candidate']['sha256'];assert strict(expected,b)
        else:
            expected=copy.deepcopy(a)
            for p,new in [(FIELD,records[FIELD]['candidate']['sha256']),(coord,records[coord]['candidate']['sha256']),(CONTRACT,digest(raw(contractpath)))]:expected['source_delta'][p]=new
            assert strict(expected,b)
        proof[target]=r
    outputs[O+'whole_code_data_execution_inverse_BUILD.json']=enc(proof)
    # Current node snapshots come from actual94 candidate declarations, except
    # unchanged frozen nodes which retain their already-fixed immutable inputs.
    pins={r['id']:copy.deepcopy(r)for r in oldplan['pinned_inputs']}
    current={}
    for n in oldplan['nodes']:
        if n['kind']=='map':continue
        ident=n['id']
        if ident=='execution_final':continue
        t=n.get('target')
        if t in actual:r={'path':actual[t]['candidate_path'],'sha256':actual[t]['candidate_sha256']}
        else:r={k:pins[n['base_input']][k]for k in ['path','sha256']}
        current[ident]=r
    scopes=[]
    for target,r in records.items():scopes.append({'target':target,'old_sha256':r['parent']['sha256'],'old_snapshot':r['parent']['path'],'kind':'GD','role':'exact_runtime_successor'})
    scopes.append({'target':EXE,'old_sha256':core[EXE],'old_snapshot':priorpath,'kind':'JSON','role':'three_owned_edges_only'})
    scopes.append({'target':CONTRACT,'old_sha256':core[CONTRACT],'old_snapshot':current['runtime_contract_final']['path'],'kind':'JSON','role':'one_Field_source_literal'})
    for n in oldplan['nodes']:
        if n['kind']in ['metadata','index']:
            scopes.append({'target':n['target'],'old_sha256':current[n['id']]['sha256'],'old_snapshot':current[n['id']]['path'],'kind':'GD'if n['kind']=='index'else'JSON','role':n['id']})
        elif n['id']=='estate_final':scopes.append({'target':'res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json','old_sha256':core['res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json'],'old_snapshot':current[n['id']]['path'],'kind':'JSON','role':'estate_final'})
        elif n['id']=='legacy_index_0':scopes.append({'target':'res://scripts/city/luoyang_estate_index_20261021am.gd','old_sha256':current[n['id']]['sha256'],'old_snapshot':current[n['id']]['path'],'kind':'GD','role':'legacy_index_0'})
    assert len(scopes)==28 and len({r['target']for r in scopes})==28
    for r in scopes:assert core[r['target']]==r['old_sha256'],r['target']
    scope={'status':'UNIFIED100_EXACT28_SCOPE_PROPOSAL_NOT_STAGE_AUTHORIZED','target_count':28,'counts':{'GD':14,'JSON':14},'targets':scopes,'prior_owner':jsref(ownerpath),'prior_stage':{'path':stagepath,'sha256':'a75b11116797d5e4488e519aa2b1c3d1342fa6b71abec157b8cdb6d310745a85'},'Root62_before_sha256':'87db79458b0f7d84862d4cfe9229864d5090636dbdbc6addaba68212fae83f0b','no_registry_DT_G_C_AA_AC_Router_or_native_artifact_target':True,'new_build_helper_not_overwrite_old_material_helper':True,'five_room_receipts_unchanged':True,'expected_tables_from_fixed_owner95_only':True}
    outputs[O+'exact28_scope_PROPOSAL_NOT_APPROVED.json']=enc(scope)
    return outputs,locals()

def prepare_dag(outputs,v):
    owner,core,prior,execution,records,current,binding,scope,oldplan=(v[k]for k in ['owner','core','prior','execution','records','current','binding','scope','oldplan'])
    pins={r['id']:copy.deepcopy(r)for r in oldplan['pinned_inputs']}
    def pin(ident,p,s=None):pins[ident]={'id':ident,'path':p,'sha256':s or digest(raw(p))};return {'$pin':ident}
    spec=copy.deepcopy(oldplan)
    spec.pop('B_only_contract')
    spec.update(status='UNIFIED100_NOTREADY_WAIT_ROOT_EXACT_EXECUTION_AND_STAGE_LOCK',blockers=['Root exact execution/source preparation approval and external input lock'],output_root=S+'outputs/root_unified_life_garden_scholar28_stage01/',source_baseline='Fixed owner95 and actual94 candidate bytes; fixed AO four baseline maps; explicit approved life/Garden/scholar declarations only; no live collector or current hash fill')
    spec['required_generator']={'path':S+'stage_unified100_BUILD.py','sha256':digest(raw(S+'stage_unified100_BUILD.py'))}
    pin('execution_approval',v['execpath'],digest(outputs[v['execpath']]))
    pin('life_parent_execution',v['priorpath'])
    pin('life_prior_owner',v['ownerpath'],'c3b7c23523fd8d913cb21a57e72e3c07340a7d948017b67139e31d6088ba60cb')
    pin('life_prior_stage',v['stagepath'],'a75b11116797d5e4488e519aa2b1c3d1342fa6b71abec157b8cdb6d310745a85')
    pin('life_code_inverse',O+'whole_code_data_execution_inverse_BUILD.json',digest(outputs[O+'whole_code_data_execution_inverse_BUILD.json']))
    pin('life_binding',v['bindingpath'],'ff97c27d2660bc45bcd7f526dca4c1d7aca9329510de24e1fe767c959a433333')
    pin('life_scope',O+'exact28_scope_PROPOSAL_NOT_APPROVED.json',digest(outputs[O+'exact28_scope_PROPOSAL_NOT_APPROVED.json']))
    pin('life_backups',R+'integration62/full28_backup_receipt.json','0481ff09ddacea8c78edb97644af365a8560dd69f4e89e00f9d1a63ece43c705')
    pin('life_before',R+'integration62/guard_before.json','87db79458b0f7d84862d4cfe9229864d5090636dbdbc6addaba68212fae83f0b')
    pin('life_media_promotion',R+'integration61/media_five_promotion_actual.json','1a4ddf823a5ec3767d99428ea0866bd8f18bcfd926522149759df8b068cb53b5')
    pin('life_runtime_contract',v['contractpath'],'239ff4b09862a4a3066462a434b00a7bdba45e830d0eb1d93ff3a2d826914700')
    pin('life_temple_binding',v['bindingnewpath'],'b5d5be7e75d90f091779c505f0883f3f90050181a5bacd3170f72d3580a5631d')
    refs={p:pin('life_code_'+str(i),r['candidate']['path'],r['candidate']['sha256'])for i,(p,r)in enumerate(records.items())}
    pin('a1_candidate',records[ENV]['candidate']['path'],records[ENV]['candidate']['sha256'])
    pin('quarter_native_geometry_helper',records[v['native']]['candidate']['path'],records[v['native']]['candidate']['sha256'])
    refs[EXE]={'$pin':'execution_approval'};refs[CONTRACT]={'$sha':'runtime_contract_final'}
    for r in scope['targets']:
        if r['role']not in ['exact_runtime_successor','three_owned_edges_only','one_Field_source_literal']:refs[r['target']]={'$sha':r['role']}
    oldscope={r['target']:r for r in scope['targets']}
    # Frozen registry/ENVindex/ground are actual immutable nodes, not no-op targets.
    frozen={k:current[k]['sha256']for k in ['registry_final','ap_environment_index','ground_code']}
    groups={r['id']:copy.deepcopy(r)for r in oldplan['source_groups']}
    for g in groups.values():
        if g['kind']=='explicit':
            for p in list(g['leaves']):
                if p in refs:g['leaves'][p]=refs[p]
    lifeleaves=copy.deepcopy(binding['source_sha256'])
    lifeleaves.update(binding['mask_import_source_sha256'])
    lifeleaves[v['bindingpath']]=pins['life_binding']['sha256']
    material=S+'life_production100_READY/material_runtime_life_READY.gd'
    lifeleaves[material]='7bd26f666035fc45a2f3161cc8df323da5ef6756f758ba16a6ffc1814ee5836a'
    shorepath=Y+'garden_shore_fragment_mask_epoch01/native_water_polygon_mask.gdshader'
    shore={shorepath:'899c66b5e8ee1141ae8a0556168b46ff9c5ce05630b167d1e7b1593fa2d531b0'}
    scholar={
      'res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png':'b1a4df81e9519bb02537a90ca683d67ffea60feb64e348e1f22ccc4a274b0fa7',
      'res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png.import':'b0b43881897d0c5d776993940d03ff4112abf93bf5f4bf10496efae0c05a4c6a',
      'res://.godot/imported/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png-20c042a9774f2c6ac7ad1dfff49d229e.ctex':'257f7af837370bd7723fba1ef9760d7fd0f25b4f0259ce4a571ee61b4be2ca2f'}
    for ident,leaves in [('life_native_material_sources',lifeleaves),('garden_mask_shader_source',shore),('Market_scholar_media_sources',scholar)]:groups[ident]={'id':ident,'kind':'explicit','leaves':leaves}
    # Input_dictionary groups remain immutable. Prohibit a hidden nonowned
    # replacement conflict instead of inventing a relaxed merge policy.
    for g in groups.values():
        if g['kind']=='input_dictionary'and g['input']!='execution_approval':
            values=ptr(load(pins[g['input']]['path'],pins[g['input']]['sha256']),g['pointer'])
            assert not(set(values)&(set(records)-set(execution['owned']))),('UNDECLARED_OLD_NONOWNED_DICTIONARY',g['id'])
    def known(ref):
        if isinstance(ref,dict)and'$pin'in ref:return pins[ref['$pin']]['sha256']
        if isinstance(ref,dict)and'$sha'in ref:return None
        return ref
    def sourceops(base,fields):
        operations=[]
        for ks in fields:
            values=ptr(base,ks)
            for p,ref in refs.items():
                if p in values and (known(ref)is None or values[p]!=known(ref)):
                    operations.append({'op':'set','pointer':ks+[p],'existed':True,'old':values[p],'new':ref})
        return operations
    nodes=[]
    for oldnode in oldplan['nodes']:
        node=copy.deepcopy(oldnode);ident=node['id']
        if node['kind']=='map':
            for op in node['operations']:
                p=op['pointer'][-1]
                if op['op']=='set'and p in refs:op['new']=refs[p]
            if node['scene_id']=='ch4_s3_luoyang_market':
                node['groups'].append('Market_scholar_media_sources')
                node['runtime_media_roots'] += [{'path':binding['child']['walk.png']['path'],'compiled_paths':[p for p in binding['mask_import_source_sha256']if p.endswith('.ctex')]},{'path':next(p for p in scholar if p.endswith('.png')),'compiled_paths':[p for p in scholar if p.endswith('.ctex')]}]
            nodes.append(node);continue
        if ident=='execution_final':nodes.append({'id':ident,'kind':'life_execution','base_input':'execution_approval'});continue
        c=current[ident];baseid='life_parent_'+ident;pin(baseid,c['path'],c['sha256'])
        node['base_input']=baseid
        if ident=='ENV_code':
            nodes.append({'id':ident,'kind':'life_fixed_code','base_input':'a1_candidate','immutable_sha256':pins['a1_candidate']['sha256']});continue
        if ident in frozen:
            nodes.append({'id':ident,'kind':'life_frozen','base_input':baseid,'immutable_sha256':c['sha256'],'is_json':ident=='registry_final'});continue
        if ident=='runtime_contract_final':
            nodes.append({'id':ident,'kind':'life_contract','base_input':baseid,'target':CONTRACT,'old_sha256':core[CONTRACT],'file':'runtime_contract_source_successor.json','literal_candidate_input':'life_runtime_contract','operations':[{'op':'set','pointer':['source_sha256',FIELD],'existed':True,'old':core[FIELD],'new':refs[FIELD]}]});continue
        if ident=='estate_final':
            target=next(r['target']for r in scope['targets']if r['role']==ident)
            node={'id':ident,'kind':'metadata','base_input':baseid,'target':target,'old_sha256':core[target],'file':'estate_source_successor.json','source_policy':'estate_legacy','source_fields':[{'pointer':['source_sha256'],'promote_owned':True,'groups':[]}],'protected_pointers':[['registry_path'],['registry_sha256'],['geometry_receipt'],['publication_receipt']]}
        if ident=='legacy_index_0':
            target=next(r['target']for r in scope['targets']if r['role']==ident)
            node={'id':ident,'kind':'index','base_input':baseid,'target':target,'old_sha256':core[target],'file':'indices/legacy_0_true.gd','disabled_file':'indices/legacy_0_false.gd','disabled_literal':'const FORMAL_ENABLED=false','enabled_literal':'const FORMAL_ENABLED=true','replacements':[{'old':current['estate_final']['sha256'],'new':{'$sha':'estate_final'}},{'old':'const FORMAL_ENABLED=true','new':'const FORMAL_ENABLED=false'}]}
            nodes.append(node);continue
        if node.get('target'):node['old_sha256']=oldscope[node['target']]['old_sha256']
        if node['kind']=='index':
            for r in node['replacements']:
                if isinstance(r['new'],dict)and'$sha'in r['new']:r['old']=current[r['new']['$sha']]['sha256']
                elif r['new']=={'$pin':'execution_approval'}:r['old']=core[EXE]
            text=raw(c['path'],c['sha256']).decode()
            assert all(text.count(r['old'])==1 for r in node['replacements']),ident
            nodes.append(node);continue
        base=load(c['path'],c['sha256'])
        fields=node.get('source_bundle',{}).get('fields',[])+[f['pointer']for f in node.get('source_fields',[])]
        node['operations']=sourceops(base,fields)
        if node.get('source_bundle'):
            # Root actual life children/report/promotion are independent runtime
            # authority leaves. B's legacy ROOT prohibition remains unchanged.
            node['source_bundle']['new_source_routes'].append({'prefix':R,'destination':['runtime_authority_sha256']})
        if ident=='quarter_final':
            node['kind']='life_quarter'
            node['protected_pointers']=[ks for ks in node.get('protected_pointers',[])if ks!=['scenes']]
            node['source_fields'][0]['groups']+=['life_native_material_sources','garden_mask_shader_source']
            changes=[]
            for field,suffix in [('scene_path','scene.res'),('layout_path','layout.res'),('packet_path','packet.bin')]:changes.append({'op':'set','pointer':['scenes',ARTISAN,field],'existed':True,'old':base['scenes'][ARTISAN][field],'new':binding['child'][suffix]['path']})
            assert 'artisan_life_successor'not in base
            changes.append({'op':'set','pointer':['artisan_life_successor'],'existed':False,'old':None,'new':{'binding_path':v['bindingpath'],'binding_sha256':pins['life_binding']['sha256']}})
            node['life_declaration_operations']=changes
        if ident in ['market_final','finite08_market']:node['source_bundle']['groups'].append('Market_scholar_media_sources')
        nodes.append(node)
    spec['nodes']=nodes;spec['source_groups']=list(groups.values())
    spec['pass_through_targets']=[{'target':p,'old_sha256':r['parent']['sha256'],'candidate_path':r['candidate']['path'],'candidate_sha256':r['candidate']['sha256']}for p,r in records.items()]
    spec['pass_through_targets'].append({'target':EXE,'old_sha256':core[EXE],'candidate_path':v['execpath'],'candidate_sha256':pins['execution_approval']['sha256']})
    spec['prospective_targets']=[{'target':r['target'],'candidate_path':r['candidate_path'],'sha256':r['candidate_sha256']}for r in spec['pass_through_targets']]
    spec['root_target_allowlist']=[r['target']for r in scope['targets']]
    spec['life_contract']={'prior_owner_input':'life_prior_owner','prior_stage_input':'life_prior_stage','scope_input':'life_scope','backup_input':'life_backups','before_input':'life_before','inverse_input':'life_code_inverse','parent_execution_input':'life_parent_execution','binding_input':'life_binding','promotion_input':'life_media_promotion','exact_target_count':28,'frozen_nodes':frozen,'proof_extra':v['proof']['added_proof_pins'],'life_sources':lifeleaves,'garden_sources':shore,'scholar_sources':scholar,'Root_preparation_input':None,'expected_Root_preparation_document':None,'root_input_freeze_pending':True}
    # Keep only genuinely referenced immutable inputs, not stale prior scope or
    # obsolete current metadata pins. No recursive filesystem traversal occurs.
    used={spec['authority_input'],spec['authority_helper_input']}
    def collect(x):
        if isinstance(x,dict):
            for k,val in x.items():
                if k in ['input','base_input','literal_candidate_input','predecessor_input','proof_input']and isinstance(val,str)and val in pins:used.add(val)
                if k=='$pin':used.add(val)
                collect(val)
        elif isinstance(x,list):
            for val in x:collect(val)
    collect(nodes);collect(spec['source_groups']);collect(spec['required_gates'])
    used.update(val for val in spec['life_contract'].values()if isinstance(val,str)and val in pins)
    spec['pinned_inputs']=[r for k,r in pins.items()if k in used]
    outputs[O+'source_input_NOTREADY.json']=enc(spec)
    outputs[O+'DAG_preparation_handoff_NOTREADY.json']=enc({'status':'UNIFIED100_COMPLETE_THIN_DAG_BUILD_NOT_EXECUTED','driver':jsref(S+'stage_unified100_BUILD.py'),'input':{'path':O+'source_input_NOTREADY.json','sha256':digest(outputs[O+'source_input_NOTREADY.json'])},'scope':{'path':O+'exact28_scope_PROPOSAL_NOT_APPROVED.json','sha256':digest(outputs[O+'exact28_scope_PROPOSAL_NOT_APPROVED.json'])},'code_and_data_proof':{'path':O+'whole_code_data_execution_inverse_BUILD.json','sha256':digest(outputs[O+'whole_code_data_execution_inverse_BUILD.json'])},'base_core_unchanged_sha256':'8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28','candidate_partition':{'GD':14,'JSON':14},'new_owned_edges':3,'old96_proof_keys_preserved':True,'new_proof_keys':5,'new_life_shared_Quarter_declarations':len(lifeleaves),'new_Garden_shared_proof_shader':1,'new_Market_only_scholar_media':3,'registry_and_five_room_receipts_frozen':True,'no_collector_current_fill_or_engine':True,'remaining_blockers':spec['blockers']})
    return outputs

if __name__=='__main__':
    import argparse
    p=argparse.ArgumentParser();p.add_argument('--file-index',type=int);p.add_argument('--start',type=int,default=0);p.add_argument('--length',type=int,default=16000);p.add_argument('--dag',action='store_true');a=p.parse_args()
    outputs,v=prepare()
    if a.dag:outputs=prepare_dag(outputs,v)
    if a.file_index is None:print(json.dumps([{'path':p,'sha256':digest(b),'length':len(b.decode())}for p,b in outputs.items()],ensure_ascii=True))
    else:
        key=list(outputs)[a.file_index];print(json.dumps({'chunk':outputs[key].decode()[a.start:a.start+a.length]},ensure_ascii=True))
