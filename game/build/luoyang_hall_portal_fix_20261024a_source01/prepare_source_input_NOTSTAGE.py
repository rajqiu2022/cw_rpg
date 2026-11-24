"""Mechanical Root64-parent hall/portal recipe constructor; not a Stage runner.

Only immutable declarations and fixed JSON/source inputs are read. Outputs are
returned as bytes for apply_patch. No runtime API, source collector, media/native
decoder, canonical write, Stage instantiation, or filesystem traversal occurs.
"""
import copy
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
sp = importlib.util.spec_from_file_location('hall_dependency_preparer', HERE/'prepare_dependency_successors_NOTSTAGE.py')
D = importlib.util.module_from_spec(sp)
sp.loader.exec_module(D)
read, sha, encode, strict = D.read, D.sha, D.encode, D.strict
S, R, O = D.SOURCE, D.ROOT, D.OUT
EXE, CONTRACT, FIELD, G, COORD, TEMPLE = D.EXECUTION, D.CONTRACT, D.FIELD, D.G, D.COORD, D.TEMPLE
OWNER = S+'unified101_actual_owner_READY/owner_source_maps_READY.json'
OWNER_SHA = 'fd58f7c2dbd3372d6adbb6f9a39ba7c70568125e4f843c11dc546e750fdfd61c'
TEMPLATE = S+'performance100_unified_life_garden_scholar_BUILD/source_input_NOTREADY.json'
TEMPLATE_SHA = '573b9e6640260169f70f9c2e89d066005ce6cacba812068a7ab8ebe7c52b57b3'
HELPER = 'res://build/luoyang_hall_portal_fix_20261024a_system01/mainhall_fixed_columns_CANDIDATE.gd'
HELPER_SHA = '60949742f626bcff53ff8af74de9aecd5626b8d3f50b3984419cf8d022b4ee87'
PORTAL = D.PORTAL
PORTAL_CANDIDATE = 'res://build/luoyang_hall_portal_fix_20261024a_system01/world_v15_exit_zone_CANDIDATE.gd'
PORTAL_SHA = '689a200292091c384e533455db82c81463eac198a9fc89bb48cc409311d042e0'
PORTAL_SHADER = 'res://build/luoyang_hall_portal_fix_20261024a_system01/portal_interaction_outline_CANDIDATE.gdshader'
PORTAL_SHADER_SHA = 'b8c19760623f931e7efcd3864dbf19e51a62fbf159d6330f01ceb1fc3a73ccbc'
PROOF = O+'dependency_wholebyte_and_execution_inverse_NOTREADY.json'
PROOF_SHA = 'd775c8dfa4a878d45acd3cc84626172215cba7b84a82c64a4c8c27cfc537d26c'
EXECUTION_PATH = O+'execution_successor_PROPOSAL_NOT_APPROVED.json'
EXECUTION_SHA = '106f167abc855967876443123f0d151c3ee285a68d51609dbc3e4fdc42a4de1e'
SYSTEM_PROOF = 'res://build/luoyang_hall_portal_fix_20261024a_system01/whole_byte_inverse_BUILD_ONLY.json'
SYSTEM_PROOF_SHA = '12d1f5832fa7203bb99aeecf412a4d8f08601dd8cf5f662b985c7e085d5ed472'


def load(resource, expected):
    return json.loads(read(resource, expected))


def pointer(value, keys):
    for k in keys:
        value = value[k]
    return value


def prepare():
    # Template syntax is inherited, but no old target value/classification is
    # authoritative: all current metadata bases come from the Root64 overlay.
    template_bytes = D.path(TEMPLATE).read_bytes()
    assert sha(template_bytes) == TEMPLATE_SHA, 'EXACT_PHYSICAL_TEMPLATE_REQUIRED'
    old = json.loads(template_bytes)
    scope = D.parent_scope(O+'world_v15_exit_zone_PARENT_19665.source')
    current = {r['target']: {'path': r['old_snapshot'], 'sha256': r['old_sha256']} for r in scope['targets']}
    proof = load(PROOF, PROOF_SHA)
    codes = proof['records']
    assert set(codes) == {G, FIELD, COORD, TEMPLE}
    authority = load(EXECUTION_PATH, EXECUTION_SHA)
    prior_authority = load(D.PRIOR_EXECUTION, D.PRIOR_EXECUTION_SHA)
    extra = {p: h for p, h in authority['source_sha256'].items() if p not in prior_authority['source_sha256']}
    assert len(extra) == 6
    read(HELPER, HELPER_SHA)
    read(PORTAL_SHADER, PORTAL_SHADER_SHA)
    read(PORTAL_CANDIDATE, PORTAL_SHA)
    system_proof = load(SYSTEM_PROOF, SYSTEM_PROOF_SHA)
    assert system_proof['ready'] is False
    # Derive Root64's parent full tables from ownerFD58 + the fifteen already
    # formally deployed declarations, never from current runtime observation.
    owner = load(OWNER, OWNER_SHA)
    classified = load(D.ROOT64_PLAN, D.ROOT64_PLAN_SHA)
    overlay = {'res://'+Path(r['path']).relative_to(D.GAME).as_posix(): r for r in classified['targets']}
    parent_owner = copy.deepcopy(owner)
    maps = [parent_owner['core_source_sha256']]
    for row in parent_owner['scenes']+parent_owner['rooms']:
        maps += [row['source_sha256'], row['receipt_source_sha256']]
    for values in maps:
        for p, r in overlay.items():
            if p in values:
                assert values[p] == r['old_sha256'], ('OWNER_ROOT64_PARENT_VALUE', p)
                values[p] = r['new_sha256']
    expected_counts = {'ch4_s0_luoyang_gate': 904, 'ch4_s1_luoyang_yamen': 1255,
                       'ch4_s2_canal_docks': 1734, 'ch4_s3_luoyang_market': 1741}
    assert all(len(r['source_sha256']) == expected_counts.get(r['id'], len(r['source_sha256'])) for r in parent_owner['scenes'])
    pins = {r['id']: copy.deepcopy(r) for r in old['pinned_inputs']}
    def pin(ident, p, h):
        pins[ident] = {'id': ident, 'path': p, 'sha256': h}
        return {'$pin': ident}
    pin('execution_approval', EXECUTION_PATH, EXECUTION_SHA)
    pin('hall_parent_execution', D.PRIOR_EXECUTION, D.PRIOR_EXECUTION_SHA)
    pin('hall_prior_owner', OWNER, OWNER_SHA)
    pin('hall_Root64_parent', D.ROOT64_PLAN, D.ROOT64_PLAN_SHA)
    pin('hall_Root64_final', D.ROOT64_FINAL, D.ROOT64_FINAL_SHA)
    pin('hall_code_inverse', PROOF, PROOF_SHA)
    pin('hall_System_inverse', SYSTEM_PROOF, SYSTEM_PROOF_SHA)
    pin('hall_scope', O+'exact27_scope_PROPOSAL_NOT_APPROVED.json', sha(encode(scope)))
    pin('hall_helper', HELPER, HELPER_SHA)
    pin('hall_portal_shader', PORTAL_SHADER, PORTAL_SHADER_SHA)
    refs = {p: pin('hall_code_'+str(i), r['candidate']['path'], r['candidate']['sha256']) for i, (p, r) in enumerate(codes.items())}
    refs[PORTAL] = pin('hall_portal', PORTAL_CANDIDATE, PORTAL_SHA)
    refs[EXE] = {'$pin': 'execution_approval'}
    refs[CONTRACT] = {'$sha': 'runtime_contract_final'}
    pin('life_runtime_contract', proof['contract']['candidate_path'], proof['contract']['candidate_sha256'])
    pin('life_temple_binding', proof['binding']['candidate_path'], proof['binding']['candidate_sha256'])
    for n in old['nodes']:
        if n.get('target') in current:
            refs[n['target']] = {'$sha': n['id']}
    # Code/contract references are direct approved candidate inputs, not a
    # circular reference to their own later node outputs.
    refs.update({p: {'$pin': 'hall_code_'+str(i)} for i, p in enumerate(codes)})
    refs[EXE] = {'$pin': 'execution_approval'}
    refs[CONTRACT] = {'$sha': 'runtime_contract_final'}
    groups = {r['id']: copy.deepcopy(r) for r in old['source_groups']}
    for group in groups.values():
        if group['kind'] == 'explicit':
            for p in list(group['leaves']):
                if p in refs:
                    group['leaves'][p] = refs[p]
    groups['hall_G_ordinary_helper'] = {'id': 'hall_G_ordinary_helper', 'kind': 'explicit', 'leaves': {HELPER: HELPER_SHA}}
    nodes, frozen = [], {}
    old_current = load(D.PRIOR_STAGE, D.PRIOR_STAGE_SHA)
    old_nodes = old_current['nodes']
    scope_by_target = {r['target']: r for r in scope['targets']}
    def source_operations(base, fields):
        operations = []
        for ks in fields:
            values = pointer(base, ks)
            for p, new in refs.items():
                if p in values:
                    operations.append({'op': 'set', 'pointer': ks+[p], 'existed': True, 'old': values[p], 'new': new})
        return operations
    def seed_node(ident, p, h):
        key = 'hall_parent_'+ident
        pin(key, p, h)
        return key
    for original in old['nodes']:
        n = copy.deepcopy(original)
        ident, kind = n['id'], n['kind']
        if ident == 'execution_final':
            nodes.append({'id': ident, 'kind': 'hall_execution', 'base_input': 'execution_approval'})
            continue
        if kind == 'map':
            row = next(r for r in parent_owner['scenes'] if r['id'] == n['scene_id'])
            seed = load(pins[n['base_input']]['path'], pins[n['base_input']]['sha256'])['source_sha256']
            promoted = copy.deepcopy(seed)
            for p in promoted:
                if p in authority['owned']:
                    promoted[p] = authority['owned'][p]['current_sha256']
            wanted = copy.deepcopy(row['source_sha256'])
            operations = []
            for p, h in wanted.items():
                new = refs.get(p, h)
                if p not in promoted or not isinstance(new, str) or promoted[p] != new:
                    operations.append({'op': 'set', 'pointer': ['source_sha256', p], 'existed': p in promoted,
                                       'old': promoted.get(p), 'new': new})
            for p in set(promoted)-set(wanted):
                operations.append({'op': 'remove', 'pointer': ['source_sha256', p], 'existed': True, 'old': promoted[p], 'new': None})
            n['operations'] = operations
            if G in wanted:
                n['groups'].append('hall_G_ordinary_helper')
            nodes.append(n)
            continue
        if ident == 'runtime_contract_final':
            base = seed_node(ident, D.PRIOR_CONTRACT, D.PRIOR_CONTRACT_SHA)
            nodes.append({'id': ident, 'kind': 'hall_contract', 'base_input': base, 'target': CONTRACT,
                          'old_sha256': D.PRIOR_CONTRACT_SHA, 'literal_candidate_input': 'life_runtime_contract',
                          'file': 'runtime_contract_Field_successor.json', 'operations': [
                              {'op': 'set', 'pointer': ['source_sha256', FIELD], 'existed': True,
                               'old': codes[FIELD]['parent']['sha256'], 'new': refs[FIELD]}]})
            continue
        target = n.get('target')
        if target in current:
            c = current[target]
        else:
            previous = old_nodes[ident]
            c = {'path': previous['path'], 'sha256': previous['sha256']}
        n['base_input'] = seed_node(ident, c['path'], c['sha256'])
        if ident in ['ENV_code', 'ground_code', 'registry_final', 'ap_environment_index']:
            frozen[ident] = c['sha256']
            nodes.append({'id': ident, 'kind': 'hall_frozen', 'base_input': n['base_input'],
                          'immutable_sha256': c['sha256'], 'is_json': ident == 'registry_final'})
            continue
        assert target in scope_by_target, ('NO_UNPLANNED_METADATA_TARGET', ident, target)
        n['old_sha256'] = c['sha256']
        if kind == 'index':
            for replacement in n['replacements']:
                ref = replacement['new']
                if isinstance(ref, dict) and '$sha' in ref:
                    dependency = next(x['target'] for x in old['nodes'] if x['id'] == ref['$sha'])
                    replacement['old'] = current[dependency]['sha256']
                elif ref == {'$pin': 'execution_approval'}:
                    replacement['old'] = D.PRIOR_EXECUTION_SHA
            nodes.append(n)
            continue
        if ident == 'quarter_final':
            n['kind'] = 'metadata'
            n.pop('life_declaration_operations', None)
            n['protected_pointers'] += [['scenes'], ['artisan_life_successor'], ['a2_artisan_successor']]
        base = load(c['path'], c['sha256'])
        fields = n.get('source_bundle', {}).get('fields', [])+[f['pointer'] for f in n.get('source_fields', [])]
        n['operations'] = source_operations(base, fields)
        if n.get('source_bundle'):
            # Preserve Root64 ordinary classification. No broad Root-build or
            # helper-prefix migration into the finite authority whitelist.
            n['source_bundle']['new_source_routes'] = [r for r in n['source_bundle']['new_source_routes'] if r['prefix'] != R]
            if any(G in pointer(base, ks) for ks in fields):
                n['source_bundle']['groups'].append('hall_G_ordinary_helper')
        nodes.append(n)
    # Ordinary helper is collected by G.source_paths, not by Estate/Quarter
    # family source_paths. Their original fixed metadata keysets stay unchanged.
    assert len([n for n in nodes if n['kind'] == 'map']) == 4
    pass_through = [{'target': p, 'old_sha256': r['parent']['sha256'], 'candidate_path': r['candidate']['path'],
                     'candidate_sha256': r['candidate']['sha256']} for p, r in codes.items()]
    pass_through += [{'target': PORTAL, 'old_sha256': D.PORTAL_OLD_SHA, 'candidate_path': PORTAL_CANDIDATE, 'candidate_sha256': PORTAL_SHA},
                     {'target': EXE, 'old_sha256': D.PRIOR_EXECUTION_SHA, 'candidate_path': EXECUTION_PATH, 'candidate_sha256': EXECUTION_SHA}]
    spec = copy.deepcopy(old)
    spec.pop('life_contract')
    spec.update(status='HALL_PORTAL_NOTREADY_WAIT_ROOT_EXACT_APPROVAL_AND_LOCK',
                blockers=['Root exact27 fresh backup, execution preparation approval, and unique Stage authorization'],
                output_root=O+'outputs/root_hall_portal_exact27_stage01/', nodes=nodes, source_groups=list(groups.values()),
                pass_through_targets=pass_through,
                prospective_targets=[{'target': r['target'], 'candidate_path': r['candidate_path'], 'sha256': r['candidate_sha256']} for r in pass_through],
                root_target_allowlist=[r['target'] for r in scope['targets']],
                source_baseline='Fixed ownerFD58 plus Root64 formally deployed classification15; explicit hall helper and execution107; never live source fill')
    spec['hall_contract'] = {'scope_input': 'hall_scope', 'prior_owner_input': 'hall_prior_owner',
                             'original_owner_input': 'hall_prior_owner', 'Root64_parent_input': 'hall_Root64_parent',
                             'inverse_input': 'hall_code_inverse', 'System_inverse_input': 'hall_System_inverse',
                             'parent_execution_input': 'hall_parent_execution', 'proof_extra': extra, 'frozen_nodes': frozen,
                             'helper_source': {HELPER: HELPER_SHA}, 'portal_shader': {PORTAL_SHADER: PORTAL_SHADER_SHA},
                             'expected_parent_counts': expected_counts, 'Root_preparation_input': None,
                             'Root_before_input': None, 'Root_backups_input': None,
                             'expected_Root_preparation_document': None, 'root_input_freeze_pending': True}
    driver = O+'stage_hall_portal_NOTREADY.py'
    spec['required_generator'] = {'path': driver, 'sha256': sha(D.path(driver).read_bytes())}
    used = {spec['authority_input'], spec['authority_helper_input']}
    def collect(v):
        if isinstance(v, dict):
            for k, w in v.items():
                if k in ['input', 'base_input', 'literal_candidate_input', 'predecessor_input', 'proof_input'] and isinstance(w, str) and w in pins:
                    used.add(w)
                if k == '$pin':
                    used.add(w)
                collect(w)
        elif isinstance(v, list):
            for w in v:
                collect(w)
    collect(nodes)
    collect(spec['source_groups'])
    collect(spec['required_gates'])
    used.update(w for w in spec['hall_contract'].values() if isinstance(w, str) and w in pins)
    spec['pinned_inputs'] = [r for k, r in pins.items() if k in used]
    return {O+'source_input_NOTREADY.json': encode(spec)}


if __name__ == '__main__':
    import argparse
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--file-index', type=int)
    p.add_argument('--start', type=int, default=0)
    p.add_argument('--length', type=int, default=12000)
    a = p.parse_args()
    outputs = prepare()
    if a.file_index is None:
        print(json.dumps([{'path': k, 'sha256': sha(v), 'bytes': len(v)} for k, v in outputs.items()]))
    else:
        k = list(outputs)[a.file_index]
        print(json.dumps({'path': k, 'text': outputs[k].decode('utf8')[a.start:a.start+a.length]}, ensure_ascii=True))
