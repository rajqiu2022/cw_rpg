"""Finite offline review only. No Stage imports, collector, media decode or live fill."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
SYS = GAME / 'build/luoyang_market_courtyard_links_20261025g_system01'
SELF = 'res://build/luoyang_city_revision_20261025g_source01/'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def read(pin):
    raw = (GAME / pin['path'][6:]).read_bytes()
    assert sha(raw) == pin['sha256'].lower(), pin['path']
    return raw

def doc(pin):
    return json.loads(read(pin))

def put(name, value):
    raw = (json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + '\n').encode()
    path = HERE / name
    assert not path.exists(), path
    with path.open('xb') as out:
        out.write(raw)
    assert json.loads(path.read_bytes()) == value
    return dict(path=SELF + name, sha256=sha(raw), bytes=len(raw))

proof_pin = dict(path='res://build/luoyang_market_courtyard_links_20261025g_system01/runtime01_NOTREADY/five_literal_pairs_whole_inverse_BUILD.json', sha256='cb1ef34c9ecee2e48aba6ae5b49d0070dca21946172871aca82d3103a1677852')
proof = doc(proof_pin)
physical = {}
for row in proof['physical_files']:
    raw = (SYS / 'runtime01_NOTREADY' / row['file']).read_bytes()
    assert sha(raw) == row['sha256'] and len(raw) == row['bytes']
    assert b'tokens truncated' not in raw and b'\xe2\x80\xa612306' not in raw
    if row['file'].endswith('.json'):
        json.loads(raw)
    physical[row['file']] = dict(sha256=sha(raw), bytes=len(raw))

pairs = []
role_target = {
    'C': 'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd',
    'DT': 'res://scripts/city/luoyang_district_life_20261016f.gd',
    'Field': 'res://scripts/field/field_walkable_controller.gd',
    'G': 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd',
    'ENV': 'res://scripts/city/luoyang_environment_layer_20261022ap.gd',
}
for row in proof['consumers']:
    before = (GAME.parent / row['parent']).read_bytes()
    after = (SYS / row['child']).read_bytes()
    expected = before
    for change in row['replacements']:
        old, new = change['old'].encode(), change['new'].encode()
        assert expected.count(old) == 1, (row['role'], change['old'])
        expected = expected.replace(old, new, 1)
    assert expected == after
    restored = after
    for change in reversed(row['replacements']):
        old, new = change['old'].encode(), change['new'].encode()
        assert restored.count(new) == 1
        restored = restored.replace(new, old, 1)
    assert restored == before and before != after
    pairs.append(dict(role=row['role'], target=role_target[row['role']], old_sha256=sha(before), candidate_sha256=sha(after), two_literals_only=True, whole_forward_and_inverse=True, parent_CR=before.count(b'\r'), candidate_CR=after.count(b'\r')))

parent_pin = dict(path='res://build/luoyang_city_revision_20261024e_source01/runtime_ready03/market_block_session_READY.gd', sha256='d29602487f69e0dd5a82dcdb2bf76fb9928f64319e0bae0c0d06cc806f4775ea')
parent = read(parent_pin).decode()
runtime = read(proof['new_runtime']).decode()
parent_api = set(re.findall(r'^static func ([A-Za-z_0-9]+)', parent, re.M))
child_api = set(re.findall(r'^static func ([A-Za-z_0-9]+)', runtime, re.M))
assert not {x for x in parent_api - child_api if not x.startswith('_')}
assert 'const READY = false' in runtime
assert 'parent.ensure(scene)' in runtime and 'parent.acquire(scene,field,district,owner,sources,proof,before)' in runtime
assert 'parent.validate_cached_boundary(scene,district)' in runtime
assert 'parent.source_paths_for(id).duplicate()' in runtime and 'parent.room_source_paths().duplicate()' in runtime
binding = doc(proof['binding'])
assert binding['ready'] is False and binding['local_art']['admitted'] is False
assert len(binding['required_source_sha256']) == 13

template_pin = dict(path=SELF+'current_map_inheritance_TEMPLATE_NOTREADY.json', sha256='7c3c9e7005161ee88b4a3549b45161eec9ea4657362b50a1e3ed4b60c246fc12')
template = doc(template_pin)
maps = {key: doc(row)['source_sha256'] for key, row in template['parent_maps'].items()}
market = maps['expected_ch4_s3_luoyang_market_true']
assert len(market) == 1877
tuples = []
for term in ('corridor.png', 'cloth_roll_rack_v1.png', 'medicine_worktable_v1.png'):
    pngs = [p for p in market if p.startswith('res://art/') and p.endswith('/'+term)]
    assert len(pngs) == 1
    png = pngs[0]
    compiled = [p for p in market if p.startswith('res://.godot/imported/'+term+'-') and p.endswith('.ctex')]
    assert len(compiled) == 1 and png+'.import' in market
    rows = {p: market[p] for p in (png,png+'.import',compiled[0])}
    assert binding['required_source_sha256'][png] == rows[png]
    tuples.append(dict(asset=term, authority=template['parent_maps']['expected_ch4_s3_luoyang_market_true'], existing_ordinary_tuple=rows, extra_keys_required=0, media_hashed_or_decoded=False))

scope_pin = dict(path=SELF+'courtyard45_source_domain_DRAFT_NOTREADY.json', sha256='64728a809d86f5fe473d62d55deb a59f2aa93a969c298f161a3507d9b250aa59'.replace(' ',''))
scope = doc(scope_pin)
rows = scope['targets']
assert len(rows) == 32 and sum(r['target'].endswith('.gd') for r in rows) == 17
blobs = {}
for row in rows:
    raw = read(dict(path=row['immutable_old'], sha256=row['old_sha256']))
    assert len(raw) == row['old_bytes']
    blobs[row['target']] = raw.lower()
    if row['target'].endswith('.json'):
        json.loads(raw)
for row in pairs:
    assert next(r for r in rows if r['target'] == row['target'])['old_sha256'] == row['old_sha256']

exec_pin = dict(path=template['current_execution']['immutable'], sha256=template['current_execution']['sha256'])
execution = doc(exec_pin)
assert len(execution['owned']) == 10 and len(execution['source_sha256']) == 162
seed = set(role_target.values())
sha_by_target = {r['target']:r['old_sha256'] for r in rows}
virtual_binding = 'res://build/luoyang_city_revision_20261024e_source01/docks31_candidates01/Temple_binding_docks_CANDIDATE.json'
virtual_pin = dict(path=virtual_binding, sha256='bae18c26edef19b0a04041da38437d9553ee5ab88ba593dc16fb966de257bc06')
blobs[virtual_binding] = read(virtual_pin).lower()
sha_by_target[virtual_binding] = virtual_pin['sha256']
seen = set(seed)
causes = {p:['direct approved runtime path/SHA consumer'] for p in seed}
while True:
    additional = {}
    for path, raw in blobs.items():
        if path in seen:
            continue
        dependencies = [p for p in sorted(seen) if sha_by_target[p].encode() in raw]
        if dependencies:
            additional[path] = dependencies
    if not additional:
        break
    seen.update(additional)
    causes.update(additional)
assert set(r['target'] for r in rows).issubset(seen)
owned_targets = [r['target'] for r in rows if r['target'] in execution['owned']]
assert len(owned_targets) == 6
unaffected_owned = {p:r['current_sha256'] for p,r in execution['owned'].items() if p not in owned_targets}
assert all(p not in role_target.values() for p in unaffected_owned)
new_known = {p:h for p,h in binding['required_source_sha256'].items() if p not in market}
donor_author = 'res://build/luoyang_estate_courtyard_20261021ak_system01/author_READY.json'
assert set(new_known) == {binding['author']['path'], binding['pure']['path'], donor_author}
assert new_known[donor_author] == 'c21097071d8a13ee9e427309a9203fe74ae28250eb36d067c2a101e08185de55'
assert all(market[p] == h for p,h in binding['required_source_sha256'].items() if p in market)
prior_pin = dict(path='res://build/luoyang_city_revision_20261025g_qa01/prior01_output/33724/prior.json',sha256='4fe0b510d4200243a9f7f935888c5b97e98122439de30d4aafac28d92501f8c5')
prior = doc(prior_pin)
assert prior['source_first'] == prior['source_final'] and prior['failures'] == 0 and prior['checks'] == 154
donor_absolute = str(GAME / donor_author[6:]).replace('\\','/')
assert prior['source_first'][donor_absolute] == new_known[donor_author]

out = dict(
    status='25G_RUNTIME45_STATIC_REVIEW_AND_CURRENT9876_DEPENDENCY_PLAN_NOT_STAGE',
    ready=False, verdict='NO_DEFINITE_STATIC_BLOCKER_FOUND_NOT_ENGINE_OR_PARSE_APPROVAL',
    reviewed_package=proof_pin, independent_prior=prior_pin,
    prior_claim='Root actual154/0 only; this script does not repeat pixel prior or native decode',
    five_physical_byte_inverses=pairs, checked_physical_files=physical,
    public_parent_API_all_retained=True,
    static_review=dict(parent37_to43_gates_first=True, independent45_same_scene_layout_token_lease=True, parent_original_cache_not_modified=True, final_and_warm_check_both_parent_and_child_fingerprints=True, room_only_parent4_plus_child_SELF_BIND_AUTHOR_PURE=True, new_mask_payload_not_expanded_to_rooms=True, materials_purpose_delegates_parent_DE191=True, fade_configure_before_actual_sprite_spawn=True, new_stall_texture_given_to_add_prop_not_old_sprite_cache=True, changed7_and_new2_only_source_whitelist=True),
    existing_media_tuples=tuples,
    current_map_template=template_pin,
    known_new_ordinary_Market_only_before_actual=dict(new_author_pure_and_historical_corridor_donor_author=new_known, historical_donor_author_authority=prior_pin, SELF=proof['new_runtime'], BIND=proof['binding'], publication_header_mask2imports_trial_and_artifacts='PENDING: fixed actual evidence only, no fabricated path/hash'),
    scope=dict(old_domain=scope_pin, existing_targets=32, partition=dict(GD=17,JSON=15), all_fixed_old_SHA_bytes_validated=True, all32_have_existing_value_dependency_path=True, dependencies=causes, immutable_virtual_Temple_binding=virtual_pin, direct5_noops=0, propagated27_final_noop_test='Before final freeze require every candidate byte differs from its fixed old bytes; no final candidate values fabricated now', final_scope_frozen=False),
    existing_owned_plan=dict(changed_members=owned_targets, proposed_real_edges=6, unchanged_members=unaffected_owned, member_count=10, depth_limit=16, old162_all_values_kept=True, candidate_new_proof_minimum='6 exact new snapshots plus culture contract and Temple binding, final count requires actual declaration review', shortcuts=0, authorization='No edge appended by this review; explicit Root approval remains required'),
    protection='Use already frozen25g fresh4B8B fixed parents; no rehash current full protection or media',
    pending=['Root actual publication and overview acceptance','mask two-leaf import/promotion actual','System single final READY SHA package','exact new proof/member paths and no-op elimination','Root backup authorization and final input/driver review'],
    Stage_calls=0,engine_calls=0,collector_calls=0,media_hashes=0,media_decodes=0,canonical_writes=0)
pin = put('runtime45_static_review_and_incremental_scope_READONLY.json', out)
print(json.dumps(pin))
