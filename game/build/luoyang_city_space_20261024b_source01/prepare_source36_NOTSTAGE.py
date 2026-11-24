"""Declarative finite recipe constructor; never imports/runs the Stage compiler.

Parents are formal805791 metadata/maps and Root2090 backups. No live collector,
runtime observation, packet/image decode, media hashing or canonical write.
"""
from pathlib import Path
import argparse
import copy
import json
import hashlib

GAME = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
S = 'res://build/luoyang_city_space_20261024b_source01/'
H = 'res://build/luoyang_hall_portal_fix_20261024a_source01/'
R = 'res://build/luoyang_city_revision_20261024b_root01/'
D = 'res://build/luoyang_docks_ordinary_space_20261024b_system01/READY03/'
P = 'res://build/luoyang_market_use_20261024b_system01/'
PARENT = H + 'outputs/root_hall_ActorParent_exact22_stage01/receipt.json'
PARENT_SHA = '8057916a71eaf433393593abad59b02bcdcec212ed213710231289e64b275392'
EXEC = 'res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
CONTRACT = 'res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
REGISTRY = 'res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
G = 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
DT = 'res://scripts/city/luoyang_district_life_20261016f.gd'
FADE = 'res://scripts/city/luoyang_district_life_fade_20261016f.gd'

def sha(raw): return hashlib.sha256(raw).hexdigest()
def encode(value): return (json.dumps(value,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode('utf8')
def data(path,expected=None):
    raw=(GAME/path[6:]).read_bytes()
    assert expected is None or sha(raw)==expected,(path,sha(raw),expected)
    assert b'tokens truncated' not in raw
    return raw
def load(path,expected=None): return json.loads(data(path,expected))
def pointer(value,keys):
    for key in keys: value=value[key]
    return value

def prepare(root_approval=None,root_approval_sha=None):
    old=load(H+'actor_parent_successor02/source_input_ROOT_READY.json','79d0b29ce1aa17215937fbbca3c60df1574497b366b76485b1193b58355561dc')
    stage=load(PARENT,PARENT_SHA)
    scope_path=S+'exact36_existing_scope_PREPARATION_NOT_STAGE.json'
    scope_sha='42d08025cc285ae41685798836c48ec7b4f536461a1d562ea0ab9109489484e4'
    scope=load(scope_path,scope_sha)
    oldtargets={r['target']:r['old_sha256'] for r in scope['targets']}
    proof_path=S+'source_closure36_BUILD/code_execution_full_inverse_NOT_STAGE.json'
    proof_sha='bbc7378da85b93716345739de9d574dfe6d05b508bedab10721595bf82de595e'
    proof=load(proof_path,proof_sha)
    execution=proof['execution']['candidate']; authority=load(execution['path'],execution['sha256'])
    ready=load(S+'runtime_READY02/mechanical_READY_freeze_inverse.json','c522cdd1b1388b5fa8a5361cab8cd7046057d38bdfa9f2fb032b74a4d1502454')
    binding=load(ready['binding']['path'],ready['binding']['sha256'])
    pins={r['id']:copy.deepcopy(r) for r in old['pinned_inputs']}
    def pin(ident,path,h):
        pins[ident]=dict(id=ident,path=path,sha256=h)
        return {'$pin':ident}
    pin('execution_approval',execution['path'],execution['sha256'])
    pin('space_parent_execution',proof['execution']['parent']['path'],proof['execution']['parent']['sha256'])
    pin('space_parent_stage',PARENT,PARENT_SHA)
    pin('space_scope',scope_path,scope_sha)
    pin('space_code_inverse',proof_path,proof_sha)
    pin('space_Root_backup',R+'predeploy36/backup_receipt.json','2090fb309bf20a81413d167199dfd623f6ced607845c269f4c5e4a0aec8d650f')
    pin('space_binding',ready['binding']['path'],ready['binding']['sha256'])
    pin('space_publication',binding['publication_path'],binding['publication_sha256'])
    pin('space_dialogue_admission',R+'dialogue_interface_admission.json','f2199c78f03966597fa115b431d260257f6ca2d7b1a946c99cb812d36080ba5b')
    dialogue=load(pins['space_dialogue_admission']['path'],pins['space_dialogue_admission']['sha256'])
    ordinary5={dialogue['helper']['path']:dialogue['helper']['sha256'],**dialogue['canonical_UI_expected_after_deploy'],**dialogue['unchanged_existing_hero_media_explicitly_frozen']}
    assert len(ordinary5)==5
    if root_approval:
        approval=load(root_approval,root_approval_sha)
        pin('space_Root_preparation',root_approval,root_approval_sha)
    else: approval=None
    refs={p:pin('space_code_'+str(i),r['candidate']['path'],r['candidate']['sha256']) for i,(p,r) in enumerate(proof['records'].items())}
    refs[EXEC]={'$pin':'execution_approval'}
    refs[CONTRACT]={'$sha':'runtime_contract_final'}
    refs[REGISTRY]={'$sha':'registry_final'}
    pin('space_contract_literal',proof['contract']['candidate']['path'],proof['contract']['candidate']['sha256'])
    pin('space_temple_binding',proof['temple_binding']['candidate']['path'],proof['temple_binding']['candidate']['sha256'])
    for node in old['nodes']:
        if node.get('target') in oldtargets and node['target'] not in refs:
            refs[node['target']]={'$sha':node['id']}
    def rewrite_leaves(values):
        return {p:copy.deepcopy(refs.get(p,h)) for p,h in values.items()}
    groups={g['id']:copy.deepcopy(g) for g in old['source_groups']}
    group_inverses=[]
    for group in groups.values():
        if group['kind']=='explicit': group['leaves']=rewrite_leaves(group['leaves'])
        elif group['kind']=='input_dictionary' and group['id']!='authority_before_and_candidate_proofs':
            source=pins[group['input']]
            original=pointer(load(source['path'],source['sha256']),group['pointer'])
            if any(p in refs for p in original):
                group_inverses.append(dict(id=group['id'],parent=copy.deepcopy(group),only_existing_source_values=list(set(original)&set(refs))))
                group.clear();group.update(id=group_inverses[-1]['id'],kind='explicit',leaves=rewrite_leaves(original))
    groups['space_dialogue5']=dict(id='space_dialogue5',kind='explicit',leaves=ordinary5)
    controls={ready['adapter']['path']:ready['adapter']['sha256']}
    groups['space_adapter_control']=dict(id='space_adapter_control',kind='explicit',leaves=controls)
    groups['common_four_city']['groups']+=['space_dialogue5','space_adapter_control']
    shared={ready['runtime']['path']:ready['runtime']['sha256'],ready['binding']['path']:ready['binding']['sha256'],
            binding['purpose_ancestor_path']:binding['purpose_ancestor_sha256'],
            binding['author_path']:binding['author_sha256'],binding['publication_path']:binding['publication_sha256'],
            binding['local_ART_path']:binding['local_ART_sha256'],
            S+'market_replan_geometry_interaction_successor03_CANDIDATE.gd':'25be67db002ceb1db1990cde55b5b237bcec0bbfbee70aea7e4d7c4b193744ec'}
    for room in binding['room_returns'].values(): shared[room['author_path']]=room['author_sha256']
    groups['space_shared_room_sources']=dict(id='space_shared_room_sources',kind='explicit',leaves=shared)
    market={**binding['source_sha256'],**shared,**controls}
    market.update({r['path']:r['sha256'] for r in binding['artifacts'].values()})
    market.update({P+'market_purpose_layer_CANDIDATE.gd':'e6d09a9bffc987e96162ce24ab2b90b6ae445259b04bd693fe453b52aa6ca68d',
                   P+'market_five_use_spec_NOTREADY.json':'9143c3e5d0e7efb55b531b42aafe33b10b043dec6d7996aba6a60067d10a47bd',
                   P+'market_use_union_CANDIDATE.gdshader':'cdaae0a2ac6ba9d403c3d3459e3b54cb74df75a0f220fa381f7baf5933ad83ad'})
    groups['space_market_sources']=dict(id='space_market_sources',kind='explicit',leaves=rewrite_leaves(market))
    ordinaryproofs={D+'C_ordinary_source_wholebyte_proof_READY.json':'6e7207bff7dcc31e7edac135afb89e586e53deb29ecff45ebe56f1072441826f',
                    D+'AA_ordinary_source_wholebyte_proof_READY.json':'30197deed7935b2c65d16ee64270a21655c73103bac2d04e279d2bb33b916d00'}
    groups['space_Docks_ordinary_proofs']=dict(id='space_Docks_ordinary_proofs',kind='explicit',leaves=ordinaryproofs)
    def op(keys,old,new,exists=True):return dict(op='set',pointer=keys,existed=exists,old=copy.deepcopy(old),new=copy.deepcopy(new))
    def source_ops(base,fields):
        result=[]
        for keys in fields:
            values=pointer(base,keys)
            for p,h in values.items():
                if p in refs: result.append(op(keys+[p],h,refs[p]))
        return result
    # Current formal declarations, not canonical reads or previous proposal oldSHA.
    current={r['target']:dict(path=r['candidate_path'],sha256=r['candidate_sha256']) for r in stage['targets']}
    backups=load(pins['space_Root_backup']['path'],pins['space_Root_backup']['sha256'])
    assert backups['count']==len(backups['records'])==36
    for row in backups['records']:
        if row['target'] not in current:
            current[row['target']]=dict(path='res://'+Path(row['backup_path']).relative_to(GAME).as_posix(),sha256=row['sha256'])
    nodes=[];frozen={}
    for original in old['nodes']:
        n=copy.deepcopy(original); ident,kind=n['id'],n['kind']
        if ident=='execution_final': nodes.append(dict(id=ident,kind='space_execution',base_input='execution_approval'));continue
        if ident in ['ENV_code','ground_code']:
            key='ENV' if ident=='ENV_code' else 'ground'
            cand=ready['candidates'][key];i='space_'+ident
            pin(i,cand['path'],cand['sha256']);nodes.append(dict(id=ident,kind='space_code',base_input=i,immutable_sha256=cand['sha256'],is_json=False));continue
        if ident=='runtime_contract_final':
            source=current[CONTRACT];i='space_parent_'+ident;pin(i,source['path'],source['sha256'])
            before=load(source['path'],source['sha256'])
            ops=[op(['source_sha256',p],change['old_sha256'],refs[p]) for p,change in proof['contract']['changed'].items()]
            nodes.append(dict(id=ident,kind='space_contract',base_input=i,target=CONTRACT,old_sha256=oldtargets[CONTRACT],file='runtime_contract_C_Field_source_successor.json',literal_candidate_input='space_contract_literal',operations=ops));continue
        if ident=='registry_final':
            source=current[REGISTRY];i='space_parent_'+ident;pin(i,source['path'],source['sha256']);base=load(source['path'],source['sha256'])
            ops=[]
            for room_id,row in base['rooms'].items():
                if row.get('source_sha256',{}).get(DT)==oldtargets[DT]:ops.append(op(['rooms',room_id,'source_sha256',DT],row['source_sha256'][DT],refs[DT]))
            assert len(ops)==5
            nodes.append(dict(id=ident,kind='metadata',base_input=i,target=REGISTRY,old_sha256=oldtargets[REGISTRY],file='registry_DT_five_source_successor.json',source_policy='old_city_or_market',operations=ops,protected_pointers=[['history'],['coordinate_contract']]));continue
        if kind=='map':
            wanted=stage['nodes'][ident]['value']['source_sha256'];seed=load(pins[n['base_input']]['path'],pins[n['base_input']]['sha256'])['source_sha256']
            promoted=copy.deepcopy(seed)
            for p in promoted:
                if p in authority['owned']:promoted[p]=authority['owned'][p]['current_sha256']
            ops=[]
            for p,h in wanted.items():
                new=refs.get(p,h)
                if p not in promoted or not isinstance(new,str) or promoted[p]!=new:ops.append(op(['source_sha256',p],promoted.get(p),new,p in promoted))
            for p in set(promoted)-set(wanted):ops.append(dict(op='remove',pointer=['source_sha256',p],existed=True,old=promoted[p],new=None))
            n['operations']=ops
            newgroups=['space_dialogue5','space_adapter_control']
            if G in wanted:newgroups.append('space_shared_room_sources')
            if n['scene_id']=='ch4_s2_canal_docks':newgroups.append('space_Docks_ordinary_proofs')
            if n['scene_id']=='ch4_s3_luoyang_market':newgroups.append('space_market_sources')
            n['groups']+=newgroups;n['declared_new_groups']=['authority_before_and_candidate_proofs']+newgroups
            nodes.append(n);continue
        if ident=='ap_environment_index':
            source=stage['nodes'][ident];i='space_parent_'+ident;pin(i,source['path'],source['sha256']);frozen[ident]=source['sha256']
            nodes.append(dict(id=ident,kind='space_frozen',base_input=i,immutable_sha256=source['sha256'],is_json=False));continue
        target=n['target'];source=current[target]
        assert source['sha256']==oldtargets[target]
        i='space_parent_'+ident;pin(i,source['path'],source['sha256']);n['base_input']=i;n['old_sha256']=source['sha256']
        if kind=='index':
            for replacement in n['replacements']:
                value=replacement['new']
                if isinstance(value,dict) and '$sha' in value:replacement['old']=stage['nodes'][value['$sha']]['sha256']
                elif value=={'$pin':'execution_approval'}:replacement['old']=proof['execution']['parent']['sha256']
            nodes.append(n);continue
        base=load(source['path'],source['sha256'])
        fields=n.get('source_bundle',{}).get('fields',[])+[r['pointer'] for r in n.get('source_fields',[])]
        n['operations']=source_ops(base,fields)
        if ident=='estate_final':
            n['operations'].append(op(['registry_sha256'],base['registry_sha256'],refs[REGISTRY]))
            n['kind']='space_estate_dialogue'
        if base.get('source_migration',{}).get('source_delta',{}).get(FADE):
            previous=base['source_migration']['source_delta'][FADE];updated=copy.deepcopy(previous)
            history=updated['historical_sha256'];current_fade=proof['records'][FADE]['parent']['sha256']
            if current_fade not in history:history.append(current_fade)
            updated.update(current_before_sha256=current_fade,new_sha256=proof['records'][FADE]['candidate']['sha256'],candidate_path=proof['records'][FADE]['candidate']['path'])
            n['operations'].append(op(['source_migration','source_delta',FADE],previous,updated))
        bundle=n.get('source_bundle')
        if bundle:
            # Only the two pre-existing canonical T/room prefixes may route
            # to runtime_authority. New BUILD paths remain ordinary legacy.
            bundle['new_source_routes']=[r for r in bundle['new_source_routes'] if r['prefix'] in ['res://data/maps/luoyang_layout_bundle_20261018t_retry2/','res://data/maps/luoyang_layout_rooms_20261018t/']]
            bundle['groups']+=['space_dialogue5','space_adapter_control']
            if any(G in pointer(base,keys) for keys in fields):bundle['groups'].append('space_shared_room_sources')
            if ident in ['legacy_manifest_4','legacy_manifest_6','legacy_manifest_7']:bundle['groups'].append('space_Docks_ordinary_proofs')
            if ident in ['legacy_manifest_5','legacy_manifest_8','market_final','finite08_market']:bundle['groups'].append('space_market_sources')
        if ident=='quarter_final':
            n['source_fields'][0]['groups'].append('space_dialogue5')
        if ident=='finite08_market':
            n['kind']='space_finite_market'
            n['protected_pointers']=[keys for keys in n['protected_pointers'] if keys[0] not in binding['domain_overrides']['manifest_immutable']]
        nodes.append(n)
    spec=copy.deepcopy(old);spec.pop('hall_contract')
    spec.update(status='MARKET_DIALOGUE_EXACT36_NOTREADY_ROOT_LOCK_PENDING',blockers=['Root exact36 preparation approval and external input lock pending'],
                output_root=S+'outputs/root_market_dialogue_exact36_stage01/',nodes=nodes,source_groups=list(groups.values()),
                root_target_allowlist=list(oldtargets),source_baseline='Formal805791 plus exact36 current-old Root2090 backups; Root64 source classification retained; F219 ordinary5 all domains; fixed86ED Market child only; no live collector/current fill')
    passed=[dict(target=p,old_sha256=r['parent']['sha256'],candidate_path=r['candidate']['path'],candidate_sha256=r['candidate']['sha256']) for p,r in proof['records'].items()]
    passed.append(dict(target=EXEC,old_sha256=proof['execution']['parent']['sha256'],candidate_path=execution['path'],candidate_sha256=execution['sha256']))
    spec['pass_through_targets']=passed
    spec['prospective_targets']=[dict(target=r['target'],candidate_path=r['candidate_path'],sha256=r['candidate_sha256']) for r in passed]
    for gate in spec['required_gates']:
        if gate['id']=='root_target_preauthorization':gate.update(input='space_Root_backup',pointer=['count'],equals=36)
    spec['space_contract']=dict(scope_input='space_scope',Root_backup_input='space_Root_backup',Root_backup_prefix=R+'predeploy36/backups/',
        Root_preparation_input='space_Root_preparation' if approval else None,expected_Root_preparation_document=approval,root_input_freeze_pending=True,
        parent_execution_input='space_parent_execution',parent_stage_input='space_parent_stage',code_inverse_input='space_code_inverse',
        space_binding_input='space_binding',space_publication_input='space_publication',dialogue5=ordinary5,
        finite_market_target=next(n['target'] for n in nodes if n['id']=='finite08_market'),frozen_nodes=frozen,
        expected_owned_count=10,expected_proofs=118,immutable_input_group_exact_source_successors=group_inverses)
    if approval:
        spec.update(status='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT',blockers=[])
        spec['space_contract']['root_input_freeze_pending']=False
    driver=S+'stage_market_dialogue36_NOTREADY.py'
    spec['required_generator']=dict(path=driver,sha256=sha(data(driver)))
    # Keep only explicit referenced immutable pins; no new filesystem crawl.
    used={spec['authority_input'],spec['authority_helper_input']}
    def collect(value):
        if isinstance(value,dict):
            for key,v in value.items():
                if key in ['input','base_input','literal_candidate_input','predecessor_input','proof_input'] and isinstance(v,str) and v in pins:used.add(v)
                if key=='$pin':used.add(v)
                collect(v)
        elif isinstance(value,list):
            for v in value:collect(v)
    collect(spec)
    for key in ['space_parent_execution','space_parent_stage','space_scope','space_code_inverse','space_Root_backup','space_binding','space_publication','space_dialogue_admission','space_temple_binding']:
        used.add(key)
    if approval:used.add('space_Root_preparation')
    spec['pinned_inputs']=[row for key,row in pins.items() if key in used]
    assert len(spec['root_target_allowlist'])==36 and len(spec['pass_through_targets'])==14
    assert sum(n.get('target') is not None for n in nodes)+14==36
    assert len([n for n in nodes if n['kind']=='map'])==4
    return spec

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--root-approval');parser.add_argument('--root-approval-sha');parser.add_argument('--output',default='source_input36_NOTREADY.json');args=parser.parse_args()
    value=prepare(args.root_approval,args.root_approval_sha);raw=encode(value);out=HERE/args.output
    with out.open('xb') as stream:stream.write(raw)
    assert json.loads(out.read_bytes())==value
    print(json.dumps(dict(path='res://'+out.relative_to(GAME).as_posix(),sha256=sha(raw),bytes=len(raw),targets=36,nodes=len(value['nodes']),groups=len(value['source_groups']),pins=len(value['pinned_inputs']),ready=not value['blockers'])))
