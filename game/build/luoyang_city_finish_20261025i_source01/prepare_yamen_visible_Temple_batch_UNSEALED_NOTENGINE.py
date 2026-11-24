"""Fixed-source preparation only. No engine, Stage, backup, or canonical writes."""
from pathlib import Path
import hashlib
import json

N = Path(__file__).resolve().parent
G = N.parents[1]
S = 'res://build/luoyang_city_finish_20261025i_source01/'
Y = 'res://build/luoyang_city_finish_20261025i_system01/'
P = S + 'yamen_visible_Temple_art_batch01_UNSEALED/'
OUT = N / 'yamen_visible_Temple_art_batch01_UNSEALED'

def sha(data):
    return hashlib.sha256(data).hexdigest()

def read_pin(path, expected):
    data = (G / path[6:]).read_bytes()
    assert sha(data) == expected.lower(), ('FIXED_INPUT_SHA', path)
    return {'path': path, 'sha256': sha(data), 'bytes': len(data)}

def load_pin(path, expected):
    pin = read_pin(path, expected)
    return pin, json.loads((G / path[6:]).read_bytes())

descriptor_pin, descriptor = load_pin(
    S + 'temple_signed_iid_repair01/unified31_READY01/unified31_ROOT_BACKUP_FIXED_NOT_STAGE.json',
    'c7896af45a53d8eb45f6bc0f5f6fd794fa40c8999af1757906fa8ec7812a8aa7')
deployed_pin, deployed = load_pin(
    S + 'temple_signed_iid_repair01/signed_Temple31_deployed_ROOT_ACTUAL.json',
    '53b5956a004e62a2d91eeab685cc02c5d26dad896801e86e148349327ad72612')
natural_pin, natural = load_pin(
    S + 'temple_signed_iid_repair01/expected_Temple_natural_sources_READONLY.json',
    'a0c525ed72fbb2d30617c8074087bc9f20c8d5a27210afba2f879ad2730bbf8b')
assert len(descriptor['targets']) == 31 and natural['count'] == 541

tp_pin, temple = load_pin(
    S + 'Temple_visible_arrival_local02_ROOT_READY/output_ROOT_READY/33324/result.json',
    '612a47485d338095a26eb9cf2ff1262ca2f6ee84cab685bd54d2784c32c52ed5')
yp_pin, yamen = load_pin(
    S + 'street_edges_yamen02_local03_ROOT_READY/output_ROOT_READY/30628/result.json',
    '98a268ebd389ab5b5c8ca1ecef20870e0b22f7d6c0389e49ec5ecf2f72a0345e')
promotion_pin, promotion = load_pin(
    Y + 'qa_role_new/yamen_boundaries_mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json',
    '22bc906dbfcedab8bea8e0ceab83e29d7a0f23f6068686e96dbba6247ed961ff')
assert temple['passed'] and temple['checks'] == 219 and not temple['actual_Field_pass']
assert yamen['passed'] and yamen['checks'] == 282 and not yamen['actual_Field_pass']
assert promotion['passed'] and len(promotion['written']) == 2
payloads = dict(temple['components']['payloads'])
yr = yamen['components']['scenes']['ch4_s1_luoyang_yamen']
payloads['ch4_s1_luoyang_yamen'] = yr['payload']
for pin in payloads.values():
    assert read_pin(pin['path'], pin['sha256']) == pin
for pin in [yr['mask'], temple['components']['whole_inverse'], yamen['components']['inverse']]:
    assert read_pin(pin['path'], pin['sha256']) == pin
for row in promotion['written']:
    assert read_pin(row['path'], row['sha256'])['bytes'] == row['bytes']

function_inputs = {
    'runtime_two_UV_only': read_pin(
        Y + 'Temple_visible_arrival03_NOTREADY/finish8_runtime_visible_Temple_CANDIDATE.gd',
        '74be6359fa36e7699b5e8ba2f3832c11241e1c1b873649590d8aac65775b5f99'),
    'runtime_whole_inverse': read_pin(
        Y + 'Temple_visible_arrival03_NOTREADY/runtime_two_arrival_hunks_whole_inverse_BUILD.json',
        '028ed4400eb941444fccacb517cde044fbf35c024aff1023c7de8d09affe2153'),
    'wing_helper_pre_monk': read_pin(
        Y + 'wing_door_children02_NOTREADY/wing_door_depth_children_CANDIDATE.gd',
        '2bb4ba8c95208fd7e6eb8879ab4a5c3e4bbbd115df338193e238879ed462f179'),
    'Field_pre_monk': read_pin(
        Y + 'wing_door_children02_NOTREADY/Field_wing_door_children_CANDIDATE.gd',
        'ec16de7d762c2a3d9fd63d614fec4bdf71a2bf0cc89768311341273b99a47fc7'),
    'wing_whole_inverse': read_pin(
        Y + 'wing_door_children02_NOTREADY/two_scene_shared_helper_and_Field_whole_inverse_BUILD.json',
        '0c77c597d1befca86266e31085dc75545258eb504aE2114240da4996a4b318c7'),
}
cart_pin = read_pin(
    S + 'cart_ruts_center_visual01_BUILD/environment_cart_ruts_center_only_CANDIDATE.json',
    '51f203d144ebdb0e1acbe9fdd994690a8f9e53f421f0d75ee4aaa16bd171ac12')
cart_inverse = read_pin(
    S + 'cart_ruts_center_visual01_BUILD/center_only_whole_byte_inverse_BUILD.json',
    'e66046f940facd7753a189648dc4dc8f5654326a2080824cf4a23fc19becaed2')

scope = []
for row in descriptor['targets']:
    candidate = read_pin(row['candidate']['path'], row['candidate']['sha256'])
    assert candidate == row['candidate']
    scope.append({'target': row['target'], 'immutable_parent': candidate, 'kind': row['kind']})
for target in [
    'res://data/maps/luoyang_full_city_20261022ap/environment.json',
    'res://scripts/city/luoyang_environment_index_20261022ap.gd',
]:
    expected = natural['source_sha256'][target]
    source = read_pin(target, expected)
    scope.append({'target': target, 'declared_current_parent': source,
                  'parent_authority': natural_pin, 'kind': 'JSON' if target.endswith('.json') else 'GD',
                  'Root_CreateNew_backup_required': True})
assert len(scope) == len({r['target'] for r in scope}) == 33

recipe = {
    'status': 'UNSEALED_SOURCE_RECIPE_ONLY_NOT_STAGE_NOT_DEPLOYABLE',
    'ready': False, 'parent_actual': deployed_pin, 'parent_descriptor': descriptor_pin,
    'old_backups': 403, 'proposed_existing_target_superset': scope,
    'target_count_before_noop_prune': 33,
    'actual_components_not_replayed': {'Temple_three_payloads': tp_pin, 'Yamen_two_walls': yp_pin,
                                     'Yamen_two_media_promoted': promotion_pin},
    'four_replacement_payloads': payloads,
    'Yamen_mask': dict(yr['mask'], RGBA_sha256=yr['full_RGBA_sha256'],
                       media_written=promotion['written'], NAV_count=41, solid_count=47),
    'function_inputs_before_optional_monk_projection': function_inputs,
    'cart_center_only': {'candidate': cart_pin, 'inverse': cart_inverse,
                        'old_center': [610, 1535], 'new_center': [1180, 1810],
                        'uniform_scale': 0.16, 'body_NAV_changes': 0},
    'binding_recipe': {
        'parent': descriptor['seal'],
        'replace_exact_scene_rows_only': sorted(payloads),
        'Yamen_mask_raw_import_ctex_only': True,
        'other_four_scene_rows_whole_bytes_retained': True,
        'Root_new_trial_permission_required': 'TRIAL_PERMISSION_NOT_RESULT; actual_Field_pass=false',
        'no_runtime_hash_cycle': 'binding excludes new runtime/Field own SHA; runtime pins BIND then consumers pin runtime',
    },
    'strict_prospective_recipe': {
        'CT': 'For all 26 source_sha256 keys: expected = frozen parent value overridden only by exact candidate target SHA. Full table equality required.',
        'Temple': 'Merge frozen parent binding source table plus source_delta, then apply all exact changed-target intersections across effective 196. Full table equality required.',
        'maps': 'Apply parent fixed consumer expression incrementally per-domain; preserve all old keys/classification; no observed current sources backfill.',
        'execution': 'Preserve all 10 owned records and all old218 source proof values/edges; append only truly changed owned edges and necessary contract proofs; F120 registered finite traversal unchanged.',
        'ordinary': 'C->AA->AC fixed historical UTF8 whole-byte inverse chain stays strict; no shortcut or owned expansion.',
        'final_guards': 'No noop targets; complete typed and raw byte inverse; all source FIRST/FINAL identical; Root sole Stage and deployment.',
    },
    'unsealed_blockers': [
        'Final System exact-two-Temple-actor visual projection and native-format contract, if admitted in this same batch.',
        'Elder image-specific cleanup/padding permission and final eligible raw/native/tuple Root receipts; no processing inferred.',
        'Root narrow trial supplement for new payload/mask/children before binding can be ready.',
    ],
    'monk_preservation_contract': {
        'source_T_Task_storage_unchanged': True,
        'projection_stage': 'Field post original task projection, after scale/position, before actor add_child; exact2IDs only',
        'calibrate_adult_body': False, 'original_authored_scale': 140 / 148,
        'original_frame': [160, 160], 'original_visible_core_height': 148,
        'whole_RGBA_160_proposal_core_height': 91.875,
        'cannot_assume_core148_or_raise_body_scale': True,
        'new_media_pins_sealed': False,
    },
    'excluded': ['Gate two moat-overlap walls', 'Inn return wall', 'old87517/global geometry replay',
                 'old Scene.hotspots/native Temple builder changes', 'new monk task/body/foot/flags changes',
                 'World head refresh'],
    'engine_calls': 0, 'collector_calls': 0, 'Stage_calls': 0,
    'backup_writes': 0, 'canonical_writes': 0, 'actual_Field_pass': False,
}
assert not OUT.exists(), 'CREATE_NEW_OUTPUT_ONLY'
OUT.mkdir()
raw = (json.dumps(recipe, ensure_ascii=False, indent=2, allow_nan=False) + '\n').encode()
with (OUT / 'recipe33_UNSEALED_NOT_STAGE.json').open('xb') as stream:
    stream.write(raw)
print(json.dumps({'path': P + 'recipe33_UNSEALED_NOT_STAGE.json', 'sha256': sha(raw),
                  'bytes': len(raw), 'ready': False, 'proposed_existing_targets': 33}))
