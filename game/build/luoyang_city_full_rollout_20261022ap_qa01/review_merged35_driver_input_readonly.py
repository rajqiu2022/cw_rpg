import copy
import hashlib
import json
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).parent
SF = GAME / 'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
DIR = SF / 'performance35_merged_source_recipe'
OUT = QA / 'merged35_71C6_E900_independent_final_DAG_static_admission_READY.json'
assert not OUT.exists()
res = lambda p: GAME / p.removeprefix('res://')
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
def at(value, path):
    for k in path:
        value = value[k]
    return value
def strict(a, b):
    return type(a) is type(b) and (set(a) == set(b) and all(strict(a[k], b[k]) for k in a) if isinstance(a, dict) else len(a) == len(b) and all(strict(x, y) for x, y in zip(a, b)) if isinstance(a, list) else a == b)

tool = SF / 'stage_performance35_merged_copy_READY.py'
inputfile = DIR / 'source_input_ROOT_LOCKED.json'
proofile = DIR / 'driver_and_input_whole_inverse_READY.json'
assert sha(tool) == '71c6f60e9bad794f650398b7c2221a2ba8716d2c9ffc46e760502c78b0fb5c62'
assert sha(inputfile) == 'e90077daf5c95a22559b6fd82ceff31cf9974cc42be0021e4bbf2e5b1e654d6b'
assert sha(proofile) == '2a35f74bb0ce56a38b45e66619dde08dc12eefef9b17eb84c2070174238d455b1'
p, d = read(proofile), read(inputfile)
assert sha(SF / 'stage_unified06_04_READY.py') == '8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
parent_tool, new_tool = res(p['parent_tool']['path']).read_bytes(), tool.read_bytes()
segments, inverse = [], []
old_cursor = new_cursor = 0
for h in p['tool_hunks']:
    a, b, c, e = h['old_byte_start'], h['old_byte_end'], h['new_byte_start'], h['new_byte_end']
    assert parent_tool[a:b] == h['old'].encode() and new_tool[c:e] == h['new'].encode()
    assert parent_tool[old_cursor:a] == new_tool[new_cursor:c]
    segments += [parent_tool[old_cursor:a], h['new'].encode()]
    inverse += [new_tool[new_cursor:c], h['old'].encode()]
    old_cursor, new_cursor = b, e
segments.append(parent_tool[old_cursor:]); inverse.append(new_tool[new_cursor:])
assert b''.join(segments) == new_tool and b''.join(inverse) == parent_tool and len(p['tool_hunks']) == 21
parentfile = res(p['parent_input']['path'])
parent = read(parentfile)
back = copy.deepcopy(d)
for change in reversed(p['input_deltas']):
    path = change['pointer']
    assert strict(at(back, path), change['new'])
    at(back, path[:-1])[path[-1]] = copy.deepcopy(change['old'])
assert strict(back, parent) and (json.dumps(back, ensure_ascii=False, indent=2) + '\n').encode() == parentfile.read_bytes()
assert len(p['input_deltas']) == 70
pins = {x['id']: x for x in d['pinned_inputs']}
assert len(pins) == len(d['pinned_inputs']) == 49
for pin in pins.values():
    assert sha(res(pin['path'])) == pin['sha256'], pin['id']
assert len(d['source_groups']) == 48 and len(d['nodes']) == 27 and len(d['pass_through_targets']) == 8
scope = read(res(pins[d['B_only_contract']['scope_request_input']]['path']))
assert d['root_target_allowlist'] == [x['target'] for x in scope['targets']] and len(set(d['root_target_allowlist'])) == 29
c = d['B_only_contract']
assert strict(read(res(pins[c['execution_root_input']]['path'])), c['expected_root_execution_document'])
assert pins[c['execution_root_input']]['sha256'] == c['expected_root_execution_sha256'] == '7298a5e2cfa2e0cae7222f18c36bf9a5c3ae936697cf8a851273725611d2c2d9'
assert strict(read(res(pins[c['scope_input']]['path'])), c['expected_scope_document'])
assert c['expected_scope_document']['allowed_existing_targets'] == 29
assert pins[c['diagnostic_root_input']]['sha256'] == '5bc5e44c2b40084b5934d1aa83d84ce48eae5420f91abea87f30bb056e9bf547'
code = read(res(pins[c['code_inverse_input']]['path']))
expected_pass = {v['target']: v['candidate'] for v in code['records'].values() if 'target' in v}
expected_pass['res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'] = {'path': pins[d['authority_input']]['path'], 'sha256': pins[d['authority_input']]['sha256']}
assert len(expected_pass) == 8
for row in d['pass_through_targets']:
    assert expected_pass[row['target']] == {'path': row['candidate_path'], 'sha256': row['candidate_sha256']}
nodes = {x['id']: x for x in d['nodes']}
reg = nodes['registry_final']
assert reg['kind'] == 'metadata' and len(reg['operations']) == 5
for op in reg['operations']:
    assert op['op'] == 'set' and op['pointer'][0] == 'rooms' and op['pointer'][2:] == ['source_sha256', 'res://scripts/city/luoyang_district_life_20261016f.gd']
    assert op['old'] == '39242c343d2e4981c2773b39fd79d84a451aab923a173a099eb8fb9b290acbe2' and op['new'] == 'cfb49f34d0bf68ebb6494b5c2e2a5dc3d98c127940d22c8acccc4c6bd680f0d5'
assert {n['id'] for n in d['nodes'] if n['kind'] == 'B_only_frozen_node'} == {'runtime_contract_final', 'ap_environment_index'}
T = 'res://data/maps/luoyang_layout_bundle_20261018t_retry2/'
for nodeid in ['finite08_yamen', 'finite08_market']:
    n = nodes[nodeid]
    assert n['source_bundle']['new_source_routes'][0] == {'prefix': T, 'destination': ['runtime_authority_sha256']}
    assert n['protected_pointers'] == [['geometry_proof_basis'], ['artifacts'], ['mask_sha256'], ['parent_publication']]
    original = read(res(pins[n['base_input']]['path']))
    assert all(not path.startswith(T) for path in original['legacy_source_sha256'])
    for op in n['operations']:
        if op['pointer'][0] == 'runtime_authority_sha256':
            assert op['pointer'][1].startswith(T)
            assert op['pointer'][1] in original['runtime_authority_sha256']
fade = 'res://scripts/city/luoyang_district_life_fade_20261016f.gd'
histories = []
for n in d['nodes']:
    for op in n.get('operations', []):
        if op['pointer'] == ['source_migration', 'source_delta', fade]:
            old, new = op['old'], op['new']
            assert new['current_before_sha256'] == '55de6f3c7ca77b5c1dd756b723d32b06f0381eb43a022334bff403d70840d6f6'
            assert new['new_sha256'] == '58462561e7db2b3f26fd6e5a55b891fc85002d86c51228a771f354b3ca9311a8'
            assert set(old['historical_sha256']).issubset(new['historical_sha256']) and new['current_before_sha256'] in new['historical_sha256']
            assert new['candidate_path'].endswith('performance33_merged_code_dependencies/Fade_adapter_pin_CANDIDATE.gd')
            histories.append(n['id'])
assert {'legacy_manifest_2', 'legacy_manifest_3', 'legacy_manifest_4', 'legacy_manifest_5'}.issubset(histories)
nonowned = ['res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd', fade, 'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/finite_adapter_READY.gd']
immutable_groups = []
for group in d['source_groups']:
    if group['kind'] != 'input_dictionary':
        continue
    value = at(read(res(pins[group['input']]['path'])), group['pointer'])
    if group['id'] != 'authority_before_and_candidate_proofs':
        assert all(k not in value for k in nonowned), group['id']
    immutable_groups.append(group['id'])
assert len(immutable_groups) == 9
assert len(d['required_gates']) == 5 and d['status'] == 'ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and not d['blockers']
out = {
    'status': 'NO_STATIC_BLOCKER_FOR_ROOT_SINGLE_NEW_MERGED29_STAGE_NOT_DEPLOYMENT_OR_FIELD_ADMISSION',
    'tool_sha256': sha(tool), 'input_sha256': sha(inputfile), 'inverse_proof_sha256': sha(proofile),
    'mechanical_independent_checks': {'tool_offset_hunks': 21, 'tool_whole_forward_reverse_toB717': True, 'input_typed_deltas': 70, 'input_whole_strict_typed_and_UTF8_byte_inverse_to706C': True, 'pinned_input_count': 49, 'all49_fixed_current_SHA_exact': True, 'fixed_input_bytes_hashed_no_media': sum(res(x['path']).stat().st_size for x in pins.values()), 'frozen_core8DE0_exact_not_imported_or_executed': True},
    'DAG': {'exact_targets': 29, 'GD_patch': 15, 'JSON_exactcopy': 14, 'pass_through': 8, 'source_groups': 48, 'nodes': 27, 'registry_exact_five_DT_ops': True, 'registry_not_frozen_or_noop': True, 'runtime_contract_and_ENVindex_only_frozen_nodes': True, 'Root7298_and09C7_inline_documents_full_typed_same': True, 'Root5BC5_diagnostic_scope_explicit': True, 'finite_T_native_and_manifest_runtime_classification_preserved': True, 'Fade_history_updated_nodes': histories, 'immutable_input_dictionary_groups_checked_for_nonowned_conflicts': immutable_groups},
    'sourceflow_review': 'Original8DE0 metadata ops-before-owned-promotion and maps owned-promotion-before-explicit-nonowned-ops retained. All original native/scope five gates and full group/media/authority/typed/source-first-final validators delegated unchanged. No new group kind, broad merge/fallback or current-observed expected fill. NonownedC/Fade/adapter explicit successor source rows are not resurrected by immutable input tables.',
    'driver_review': 'Full thin driver read. Eight code/authority pass-throughs exact; original10owned/four append edges/old71+9 checks, complete old29 backups, no-noop target guard, perJSON inverse,15GD exact patch reconstruction,14JSON exact copy partition, original final fresh pinned-source pass, all output writes buffered until successful preflight. Historical Exact22/B_only/UNION22 labels do not change the actual29 assertions; not a scope expansion.',
    'inherited_code_admission': ['Stable7:1CA16B84', 'PassiveDT:B096E102', 'Final025E:20A3A03C'],
    'limits': 'Only Root may execute one exact externally input-SHA-locked Stage. No engine, collector, production deployment or loading success credit. Original furniture/A2/06 failures and crashes retained. Future Field remains one default public Yamen entry/60s with passive subspans, no warm expansion.',
    'local_audit_note': 'First summary inspection assumed a historical inputs field and failed KeyError before any output; corrected actual pinned_inputs/source_groups schema. No Source file changes or Stage import/run.',
    'operations': {'engine': 0, 'sourceStage_or_stager_import': 0, 'collector': 0, 'packet_decode': 0, 'large_media_hash': 0, 'canonical_writes': 0, 'NEW_QA_receipt_only': True}
}
OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'receipt': str(OUT), 'sha256': sha(OUT)}))
