"""Exact two-target read-only review; emit NEW owner provenance, no source crawl."""
import copy
import hashlib
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
SOURCE = 'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P = SOURCE + 'finite10_yamen_classification/'
ROOT = 'res://build/luoyang_city_full_rollout_20261022ap_root01/integration13/'
OUT = P + 'actual_deployment_review/'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def path(value):
    assert value.startswith('res://') and '..' not in value
    return GAME / value[6:]

def fixed(value, expected):
    raw = path(value).read_bytes()
    assert sha(raw) == expected, ('PIN_CHANGED', value)
    return raw

def load(value, expected):
    raw = fixed(value, expected)
    return json.loads(raw)

def same(a, b):
    if type(a) is not type(b):
        return False
    if isinstance(a, dict):
        return a.keys() == b.keys() and all(same(a[k], b[k]) for k in a)
    if isinstance(a, list):
        return len(a) == len(b) and all(same(x, y) for x, y in zip(a, b))
    return a == b

def pin(value, expected):
    return {'path': value, 'sha256': expected}

handoff_pin = pin(P + 'handoff02_CANDIDATES_READY_NOT_DEPLOYED.json', 'b812325c48c7dceac50bbb170b233a019bfc59c8d0c1d0dd3374142578110c1e')
proof_pin = pin(P + 'four_leaf_classification_and_two_owner_headers_proof02_READY.json', '8130436f2e87cecb6bf4fe6dd98c4e5b8312147144118aa4c3fdeb094d590001')
expected_pin = pin(P + 'owner_source_maps_EXPECTED_NOT_DEPLOYED.json', '1302cdb19aa57f7d8d65cb7e9e307b8212e3777093e915fdb23441f75f58fca9')
plan_pin = pin(ROOT + 'predeploy_plan_READY.json', '946610a1099ab3ac4f69568fab818f205d936f884dc4cdccf0b01f6b51db113c')
auth_pin = pin(ROOT + 'deployment_authorization.json', 'dbb6d927d6bf46af83d9eba59fb3fa32721813e4a3ee63df22a5ffc30d3ca190')
guard_pin = pin(ROOT + 'final_guard.json', 'e5e524144f5340f5367808f5452f347b230f14484e655b1ed16dded531c389c4')
objects = [load(d['path'], d['sha256']) for d in [handoff_pin, proof_pin, expected_pin, plan_pin, auth_pin, guard_pin]]
handoff, proof, expected, plan, auth, guard = objects
assert plan['approved_by_root'] is True and plan['target_count'] == 2
assert auth['passed'] is True and auth['plan_sha256'] == plan_pin['sha256'] and auth['target_count'] == 2
assert guard['passed'] is True and guard['authorization_sha256'] == auth_pin['sha256']
assert guard['unexpected_change_count'] == 0 and guard['save_change_count'] == 0
assert guard['authorized_change_count'] == 2 and guard['save_count'] == 15
assert guard['before_sha256'] == auth['before_sha256'] == plan['before_sha256']
assert plan['handoff_sha256'] == handoff_pin['sha256']
assert handoff['proof']['sha256'] == proof_pin['sha256']
assert handoff['owner_candidate']['sha256'] == expected_pin['sha256']
bytarget = {r['target']: r for r in plan['targets']}
assert len(bytarget) == 2 and set(bytarget) == {r['target'] for r in handoff['targets']}
review_rows = []
for row in handoff['targets']:
    t = bytarget[row['target']]
    assert t['old_sha256'] == row['old_sha256'] == row['old_snapshot']['sha256']
    assert t['new_sha256'] == row['candidate']['sha256'] and t['new_bytes'] == row['candidate']['bytes']
    old = fixed(row['old_snapshot']['path'], row['old_sha256'])
    new = fixed(row['candidate']['path'], row['candidate']['sha256'])
    backup = Path(t['backup_path']).read_bytes()
    current = fixed(row['target'], row['candidate']['sha256'])
    assert backup == old and current == new and len(current) == t['new_bytes']
    changes = [r for r in guard['authorized_changes'] if Path(r['path']) == path(row['target'])]
    assert len(changes) == 1
    assert changes[0]['before']['sha256'] == row['old_sha256'] and changes[0]['after']['sha256'] == row['candidate']['sha256']
    review_rows.append({'target': row['target'], 'old_sha256': row['old_sha256'], 'new_sha256': row['candidate']['sha256'], 'complete_old_backup_matches': True, 'current_bytes_equal_fixed_candidate': True})

# Expected values remain inherited exclusively from the independently frozen recipe.
assert expected['status'] == 'INDEPENDENT_EXPECTED_OWNER_EXACT_TWO_METADATA_SUCCESSOR_PENDING_ROOT_DEPLOYMENT'
assert expected['actual_stage_receipt']['sha256'] == '885a813db26487582bc7cb31d02ec89827dc929a9e2653e71137defd8ff8c3a0'
assert len(expected['scenes']) == 8 and len(expected['rooms']) == 5
owners = copy.deepcopy(expected)
owners['status'] = 'ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS_WITH_EXACT_TWO_DEPLOYED_METADATA_SUCCESSOR'
successor = owners['bounded_runtime_metadata_successor']
successor['status'] = 'ROOT_EXACT_TWO_TARGET_DEPLOYMENT_AND_FINAL_GUARD_VERIFIED'
successor['actual_deployment'] = {'predeploy_plan': plan_pin, 'predeploy_authorization': auth_pin, 'final_guard': guard_pin}
successor['independent_expected_owner_before_deployment'] = expected_pin
successor['current_two_target_bytes_equal_frozen_candidates'] = True
successor['source_maps_not_populated_from_current_targets_or_observed_collectors'] = True
owners['actual_metadata_deployment_receipt'] = guard_pin
owners['prior_actual_stage_receipt_is_preserved_885A_not_relabelled'] = True
owners['not_Field_or_runtime_credit'] = True
inverse = copy.deepcopy(owners)
inverse['status'] = expected['status']
inverse['bounded_runtime_metadata_successor'] = copy.deepcopy(expected['bounded_runtime_metadata_successor'])
del inverse['actual_metadata_deployment_receipt']
del inverse['prior_actual_stage_receipt_is_preserved_885A_not_relabelled']
assert same(inverse, expected)
assert all(same(owners[key], expected[key]) for key in ['core_source_sha256', 'scenes', 'rooms', 'actual_stage_receipt'])
assert next(r for r in owners['scenes'] if r['id'] == 'ch4_s1_luoyang_yamen')['source_sha256'].__len__() == 1211

def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode('utf-8')

owner_path = OUT + 'owner_source_maps_ROOT_DEPLOYED_READY.json'
owner_raw = encoded(owners)
owner_pin = {'path': owner_path, 'sha256': sha(owner_raw), 'bytes': len(owner_raw)}
review = {
    'status': 'EXACT_TWO_METADATA_ROOT_DEPLOYMENT_INDEPENDENT_REVIEW_NO_ENGINE_OR_COLLECTOR',
    'fixed_handoff': handoff_pin, 'classification_and_owner_inverse_proof': proof_pin,
    'independent_expected_owner': expected_pin, 'predeploy_plan': plan_pin,
    'predeploy_authorization': auth_pin, 'final_guard': guard_pin,
    'exact_targets': review_rows, 'target_count': 2,
    'eight_scene_five_room_and_core_source_maps_typed_identical_to_frozen_expected': True,
    'new_owner_only_status_and_actual_receipt_provenance_changes': True,
    'prior_actual_stage_885A_and_expected1302_preserved': True,
    'yamen_source_count': 1211, 'no_new_source_keys_or_source_class_value_changes': True,
    'root_guard_checked': guard['checked'], 'root_guard_exact_unchanged': guard['exact_unchanged'],
    'root_guard_unexpected_changes': 0, 'root_guard_save_changes': 0,
    'owner_source_maps': owner_pin, 'canonical_writes': 0,
    'engine_collector_or_native_decode_calls': 0,
    'complete_2979_source_hash_crawl_performed': False, 'not_Field_or_runtime_credit': True,
}
assert not path(OUT).exists()
path(OUT).mkdir(parents=True)
for name, raw in [(owner_path, owner_raw), (OUT + 'deployment_source_review_READY.json', encoded(review))]:
    with path(name).open('xb') as handle:
        handle.write(raw)
print(json.dumps({'owner': owner_pin, 'review': {'path': OUT + 'deployment_source_review_READY.json', 'sha256': sha(encoded(review))}, 'source_maps_changed_from_expected': False, 'canonical_writes': 0}))
