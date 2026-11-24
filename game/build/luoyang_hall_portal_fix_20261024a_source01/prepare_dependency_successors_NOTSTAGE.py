"""BUILD-only exact hall/portal dependency preparation, never Stage or write.

Parents are the immutable Root62 executable release and Root64 classification
deployment declarations. Runtime implementations are supplied by System. This
module returns bytes for apply_patch; it does not write candidates or call a
collector, native decoder, Godot, Stage, or source/media hashing traversal.
"""
import copy
import difflib
import hashlib
import json
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
OUT = 'res://build/luoyang_hall_portal_fix_20261024a_source01/'
SOURCE = 'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
ROOT = SOURCE.replace('_source_finalize01/', '_root01/')
EXECUTION = 'res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
FIELD = 'res://scripts/field/field_walkable_controller.gd'
G = 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
COORD = 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'
TEMPLE = 'res://scripts/city/luoyang_temple_assembly_20261016.gd'
CONTRACT = 'res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
PRIOR_EXECUTION = SOURCE+'performance100_unified_life_garden_scholar_BUILD/execution_successor_PROPOSAL_NOT_APPROVED.json'
PRIOR_EXECUTION_SHA = 'a971de4023f2f61fd67738f62608354bf9a1a38173aefa5718e233b5d6174395'
PRIOR_CONTRACT = SOURCE+'performance100_unified_life_garden_scholar_BUILD/runtime_contract_Field_literal_READY_NOTAPPROVED.json'
PRIOR_CONTRACT_SHA = '239ff4b09862a4a3066462a434b00a7bdba45e830d0eb1d93ff3a2d826914700'
PRIOR_BINDING = SOURCE+'performance100_unified_life_garden_scholar_BUILD/temple_binding_READY_NOTAPPROVED.json'
PRIOR_BINDING_SHA = 'b5d5be7e75d90f091779c505f0883f3f90050181a5bacd3170f72d3580a5631d'
ROOT64_PLAN = ROOT+'integration64/predeploy_plan_READY.json'
ROOT64_PLAN_SHA = '54d3cc5bb624a9141e6cdca28555792f921186cd619da1bfc81631a2b28bca1d'
ROOT64_FINAL = ROOT+'integration64/final_guard.json'
ROOT64_FINAL_SHA = 'd081f80929aaf85026c7fce6456ecdda9f9b1883106ed5e66316f27a6745c368'
PRIOR_STAGE = SOURCE+'outputs/root_unified_life_garden_scholar28_stage01/receipt.json'
PRIOR_STAGE_SHA = '4ce21902185a78f6c441f8ee8d63d30b30a7c31c61f135b5df13322bc266d945'
PORTAL = 'res://scripts/field/world_v15_exit_zone.gd'
PORTAL_OLD_SHA = '19665f50731eb90286372cbd0ebf55b43bf6edf1694e85885d50bb59cbe9e8ef'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def path(resource):
    assert resource.startswith('res://') and '..' not in resource
    return GAME/resource[6:]


def read(resource, expected):
    data = path(resource).read_bytes()
    assert sha(data) == expected, ('FIXED_SMALL_INPUT_CHANGED', resource)
    return data


def strict(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return list(a) == list(b) and all(strict(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(strict(x, y) for x, y in zip(a, b))
    return a == b


def encode(value):
    return (json.dumps(value, ensure_ascii=False, indent=2)+'\n').encode('utf8')


def replacements(before, after):
    a, b = before.decode('utf8'), after.decode('utf8')
    al, bl = a.splitlines(keepends=True), b.splitlines(keepends=True)
    result = []
    for group in difflib.SequenceMatcher(None, al, bl, autojunk=False).get_grouped_opcodes(3):
        first, last = group[0], group[-1]
        old = ''.join(al[first[1]:last[2]])
        new = ''.join(bl[first[3]:last[4]])
        assert old and new and a.count(old) == b.count(new) == 1
        result.append({'old': old, 'new': new})
    forward, inverse = a, b
    for h in result:
        forward = forward.replace(h['old'], h['new'], 1)
        inverse = inverse.replace(h['new'], h['old'], 1)
    assert forward.encode('utf8') == after and inverse.encode('utf8') == before
    assert result, 'NO_NOOP_CODE_SUCCESSOR'
    return result


def exact_replace(data, old, new):
    old, new = old.encode('ascii'), new.encode('ascii')
    assert old != new and data.count(old) == 1
    result = data.replace(old, new, 1)
    assert result.count(new) == 1 and result.replace(new, old, 1) == data
    return result


def parent_scope(portal_snapshot):
    """Exact27 old declarations; no canonical source table or source crawl.

    portal_snapshot is a preserved System byte-exact old file. Root64's fifteen
    metadata/index successors override the old Stage100 rows, never vice versa.
    Every other old row stays the immutable Stage100 candidate declaration.
    """
    stage = json.loads(read(PRIOR_STAGE, PRIOR_STAGE_SHA))
    current = {r['target']: {'path': r['candidate_path'], 'sha256': r['candidate_sha256']}
               for r in stage['targets']}
    classified = json.loads(read(ROOT64_PLAN, ROOT64_PLAN_SHA))
    assert classified['target_count'] == 15 and classified['approved_by_root'] is True
    for row in classified['targets']:
        target = 'res://'+Path(row['path']).relative_to(GAME).as_posix()
        candidate = 'res://'+Path(row['candidate_path']).relative_to(GAME).as_posix()
        assert target in current and current[target]['sha256'] == row['old_sha256']
        current[target] = {'path': candidate, 'sha256': row['new_sha256']}
    excluded = {'res://scripts/city/luoyang_quarters_family_20261022ap.gd',
                'res://scripts/city/luoyang_environment_layer_20261022ap.gd',
                'res://scripts/city/luoyang_quarters_native_geometry_20261022ap.gd'}
    assert excluded <= set(current) and len(current) == 28
    for target in excluded:
        del current[target]
    prior = json.loads(read(PRIOR_EXECUTION, PRIOR_EXECUTION_SHA))
    old_g = prior['owned'][G]['current_sha256']
    snapshots = [p for p, h in prior['source_sha256'].items() if h == old_g]
    assert len(snapshots) == 1
    current[G] = {'path': snapshots[0], 'sha256': old_g}
    read(portal_snapshot, PORTAL_OLD_SHA)
    current[PORTAL] = {'path': portal_snapshot, 'sha256': PORTAL_OLD_SHA}
    assert len(current) == 27
    rows = [{'target': p, 'old_sha256': r['sha256'], 'old_snapshot': r['path'],
             'kind': 'GD' if p.endswith('.gd') else 'JSON'} for p, r in current.items()]
    assert sum(r['kind'] == 'GD' for r in rows) == 13
    assert sum(r['kind'] == 'JSON' for r in rows) == 14
    return {'status': 'HALL_PORTAL_EXACT27_EXISTING_SCOPE_PROPOSAL_NOT_STAGE_AUTHORIZED',
            'target_count': 27, 'partition': {'GD': 13, 'JSON': 14}, 'targets': rows,
            'parent_Stage100': {'path': PRIOR_STAGE, 'sha256': PRIOR_STAGE_SHA},
            'Root64_classification_parent': {'path': ROOT64_PLAN, 'sha256': ROOT64_PLAN_SHA},
            'Root64_formal_final': {'path': ROOT64_FINAL, 'sha256': ROOT64_FINAL_SHA},
            'ordinary_build_sources_stay_legacy_not_runtime_authority': True,
            'registry_twelve_rows_and_five_room_receipts_not_targets': True,
            'frozen_original_geometry_and_all_room_native_publication_not_targets': True,
            'extra_new_helper_and_portal_shader_are_build_sources_not_owned_members': True,
            'fresh_guard_backups_stage_and_deployment_approval_remain_required': True}


def prepare(runtime_records):
    """runtime_records contains exactly G and Field fixed candidate descriptors.

    Each descriptor has {path,sha256,bytes}; it must be an already authored
    immutable System candidate. New helper/shader source domains are handled by
    the subsequent source recipe, not added as arbitrary execution proof keys.
    """
    assert set(runtime_records) == {G, FIELD}
    prior_bytes = read(PRIOR_EXECUTION, PRIOR_EXECUTION_SHA)
    prior = json.loads(prior_bytes)
    assert len(prior['owned']) == 10 and len(prior['source_sha256']) == 101
    records, outputs = {}, {}
    for target, candidate in runtime_records.items():
        old = prior['owned'][target]['current_sha256']
        parents = [(p, h) for p, h in prior['source_sha256'].items() if h == old]
        assert len(parents) == 1, ('EXACT_SINGLE_OLD_SNAPSHOT', target)
        parent, old_sha = parents[0]
        before, after = read(parent, old_sha), read(candidate['path'], candidate['sha256'])
        assert len(after) == candidate['bytes']
        records[target] = {'target': target, 'parent': {'path': parent, 'sha256': old_sha, 'bytes': len(before)},
                           'candidate': copy.deepcopy(candidate), 'hunks': replacements(before, after),
                           'whole_byte_inverse': True}
    contract_before = read(PRIOR_CONTRACT, PRIOR_CONTRACT_SHA)
    contract_after = exact_replace(contract_before, records[FIELD]['parent']['sha256'], records[FIELD]['candidate']['sha256'])
    contract_path = OUT+'runtime_contract_Field_literal_CANDIDATE.json'
    outputs[contract_path] = contract_after
    expected = json.loads(contract_before)
    expected['source_sha256'][FIELD] = records[FIELD]['candidate']['sha256']
    assert strict(expected, json.loads(contract_after))
    for target, name, old, new in [(COORD, 'Coordinator_CANDIDATE.gd', PRIOR_CONTRACT_SHA, sha(contract_after))]:
        old_sha = prior['owned'][target]['current_sha256']
        parents = [(p, h) for p, h in prior['source_sha256'].items() if h == old_sha]
        assert len(parents) == 1
        parent = parents[0][0]
        before = read(parent, old_sha)
        after = exact_replace(before, old, new)
        candidate = OUT+name
        outputs[candidate] = after
        records[target] = {'target': target, 'parent': {'path': parent, 'sha256': old_sha, 'bytes': len(before)},
                           'candidate': {'path': candidate, 'sha256': sha(after), 'bytes': len(after)},
                           'hunks': replacements(before, after), 'whole_byte_inverse': True}
    binding_before = read(PRIOR_BINDING, PRIOR_BINDING_SHA)
    binding = json.loads(binding_before)
    parent_binding = json.loads(read(binding['parent_binding_path'], binding['parent_binding_sha256']))
    merged = {**parent_binding['source_sha256'], **binding['source_delta']}
    assert len(merged) == 189
    next_binding = copy.deepcopy(binding)
    binding_after = binding_before
    for target, old, new in [(FIELD, records[FIELD]['parent']['sha256'], records[FIELD]['candidate']['sha256']),
                             (COORD, records[COORD]['parent']['sha256'], records[COORD]['candidate']['sha256']),
                             (CONTRACT, PRIOR_CONTRACT_SHA, sha(contract_after))]:
        assert next_binding['source_delta'][target] == old
        next_binding['source_delta'][target] = new
        binding_after = exact_replace(binding_after, old, new)
    assert strict(json.loads(binding_after), next_binding)
    assert len({**parent_binding['source_sha256'], **next_binding['source_delta']}) == 189
    assert sum(merged[p] != {**parent_binding['source_sha256'], **next_binding['source_delta']}[p] for p in merged) == 3
    binding_path = OUT+'temple_binding_three_literals_CANDIDATE.json'
    outputs[binding_path] = binding_after
    old_sha = prior['owned'][TEMPLE]['current_sha256']
    parents = [(p, h) for p, h in prior['source_sha256'].items() if h == old_sha]
    assert len(parents) == 1
    parent = parents[0][0]
    before = read(parent, old_sha)
    after = before.replace(PRIOR_BINDING.encode('utf8'), binding_path.encode('utf8'), 1)
    assert before.count(PRIOR_BINDING.encode('utf8')) == 1
    after = exact_replace(after, PRIOR_BINDING_SHA, sha(binding_after))
    candidate = OUT+'Temple_CANDIDATE.gd'
    outputs[candidate] = after
    records[TEMPLE] = {'target': TEMPLE, 'parent': {'path': parent, 'sha256': old_sha, 'bytes': len(before)},
                       'candidate': {'path': candidate, 'sha256': sha(after), 'bytes': len(after)},
                       'hunks': replacements(before, after), 'whole_byte_inverse': True}
    execution = copy.deepcopy(prior)
    for target, record in records.items():
        row = execution['owned'][target]
        candidate = record['candidate']
        assert prior['source_sha256'][record['parent']['path']] == record['parent']['sha256'] == row['current_sha256']
        row['edges'].append({'path': target, 'old_sha256': row['current_sha256'], 'new_sha256': candidate['sha256'],
                             'old_snapshot': record['parent']['path'], 'new_snapshot': candidate['path'],
                             'whole_inverse': True, 'replacements': record['hunks']})
        row['current_sha256'] = candidate['sha256']
        assert candidate['path'] not in execution['source_sha256']
        execution['source_sha256'][candidate['path']] = candidate['sha256']
    for p in [contract_path, binding_path]:
        assert p not in execution['source_sha256']
        execution['source_sha256'][p] = sha(outputs[p])
    assert len(execution['owned']) == 10 and len(execution['source_sha256']) == 107
    inverse = copy.deepcopy(execution)
    for target in records:
        inverse['owned'][target] = copy.deepcopy(prior['owned'][target])
    inverse['source_sha256'] = copy.deepcopy(prior['source_sha256'])
    assert strict(inverse, prior) and encode(inverse) == prior_bytes
    execution_path = OUT+'execution_successor_PROPOSAL_NOT_APPROVED.json'
    outputs[execution_path] = encode(execution)
    proof = {'status': 'HALL_PORTAL_EXACT_DEPENDENCY_CANDIDATES_NOT_STAGE_AUTHORIZED', 'records': records,
             'parent_execution': {'path': PRIOR_EXECUTION, 'sha256': PRIOR_EXECUTION_SHA},
             'execution_candidate': {'path': execution_path, 'sha256': sha(outputs[execution_path])},
             'old_owned_count': 10, 'new_owned_count': 10, 'changed_owned': list(records),
             'old_proof_count': 101, 'new_proof_count': 107,
             'other_six_owned_rows_wholetyped_unchanged': True,
             'execution_entire_typed_and_serialized_UTF8_inverse': True,
             'contract': {'parent_path': PRIOR_CONTRACT, 'parent_sha256': PRIOR_CONTRACT_SHA, 'candidate_path': contract_path,
                          'candidate_sha256': sha(contract_after), 'only_pointer': ['source_sha256', FIELD],
                          'hunks': replacements(contract_before, contract_after)},
             'binding': {'parent_path': PRIOR_BINDING, 'parent_sha256': PRIOR_BINDING_SHA, 'candidate_path': binding_path,
                         'candidate_sha256': sha(binding_after), 'merged_count': 189, 'changed_leaves': [FIELD, COORD, CONTRACT],
                         'other_186_leaves_unchanged': True, 'hunks': replacements(binding_before, binding_after)},
             'Root64_classification_and_all_native_registry_room_receipts_remain_parent': True,
             'Stage_or_engine_or_collector_or_current_source_table_fill': False}
    outputs[OUT+'dependency_wholebyte_and_execution_inverse_NOTREADY.json'] = encode(proof)
    return outputs


if __name__ == '__main__':
    import argparse
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('runtime_candidates', help='Two fixed System candidate descriptors, not live observations')
    p.add_argument('--file-index', type=int)
    p.add_argument('--start', type=int, default=0)
    p.add_argument('--length', type=int, default=12000)
    a = p.parse_args()
    outputs = prepare(json.loads(Path(a.runtime_candidates).read_text(encoding='utf8')))
    if a.file_index is None:
        print(json.dumps([{'path': k, 'sha256': sha(v), 'bytes': len(v)} for k, v in outputs.items()]))
    else:
        k = list(outputs)[a.file_index]
        print(json.dumps({'path': k, 'text': outputs[k].decode('utf8')[a.start:a.start+a.length]}, ensure_ascii=True))
