import hashlib
import json
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
QA = Path(__file__).parent
SF = GAME / 'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
RT = GAME / 'build/luoyang_city_full_rollout_20261022ap_root01/integration28'
BASE = SF / 'performance31_domain_parent_copy_ROOT28_READY'
REPORT = BASE / 'output/119340_3032406/result.json'
OUT = QA / 'parentcopy119340_independent_actual_component_review_READY.json'
assert not OUT.exists()
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest().upper()
load = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
d = load(REPORT)
assert sha(REPORT) == '5FBEFFC4F782900F407AAD155BD1993E67C18C4104E10B0B1E50DC37330D8567'
assert d['passed'] and not d['errors'] and d['checks'] == 39 and d['binary_packet_decodes'] == 1 and d['Field_Scene_geometry_image_collector_calls'] == 0
assert [(x['domain'], x['old_four_copy_wall_usec'], x['candidate_two_copy_wall_usec']) for x in d['rows']] == [('yamen', 7, 4), ('market', 4, 3), ('yamen', 103302, 52091)]
assert all(x['all_checks_and_mutations_outside_timers'] and x['no_Field_or_stable_speed_claim'] for x in d['rows'])
pfile = RT / 'parent_copy_once_process_receipt.json'
p = load(pfile)
assert p['actual_natural_console_exit_code'] == 0 and p['exit_code_from_retained_process_WaitForExit'] and not p['process_stopped_by_tool']
assert p['script_sha256'] == p['script_after_sha256'] == 'd1e70c2c78ba0ae1958f75e889c89ca7c66e2f2670bc94300a5edf7a1e3d34d0'
key = BASE / 'test_domain_parent_copy_ROOT28_READY.gd'
fixture = BASE / 'parent_copy_comparison_fixture_ROOT28_READY.json'
assert sha(key).lower() == p['script_sha256'] and sha(fixture) == '69ED1FEB1131BC1CF9F6E11E16B2FAEE72FD62AE827683ECCE8C46B915D8277B'
f = load(fixture)
assert f['ready'] and len(f['source_sha256']) == 5
small_checked = {}
for path, expected in f['source_sha256'].items():
    if path == f['fixed_T_packet_path']:
        assert expected == '04f2d7f253b229e924211a0e241750bd5013ef96dd63794f2ce8b7380d9da7df'
        continue
    file = GAME / path.removeprefix('res://')
    assert sha(file).lower() == expected
    small_checked[path] = expected
logs = {}
for label in ('stdout', 'stderr'):
    file = Path(p[label + '_path'])
    assert sha(file).lower() == p[label + '_sha256']
    logs[label] = file.read_text(encoding='utf-8-sig')
text = '\n'.join(logs.values())
assert text.count('WARNING:') == 1 and 'ObjectDB instances leaked at exit' in text and 'ERROR:' not in text and 'SCRIPT ERROR:' not in text
gf = RT / 'final_guard.json'
g = load(gf)
assert sha(gf) == '7E74D55557684F2A414E643B84EC9E55B6BE63D039F7110A2F196BBDB8C6F650'
assert g['passed'] and g['checked'] == g['exact_unchanged'] == 2117 and g['save_count'] == 15 and g['save_change_count'] == g['unexpected_change_count'] == g['authorized_change_count'] == 0
save_rows = [x for x in g['facts'] if x['path'] in g['save_paths']]
assert len(save_rows) == 15
for row in save_rows:
    file = Path(row['path'])
    if row['sha256'] == 'ABSENT':
        assert not file.exists()
    else:
        assert file.stat().st_size == row['bytes'] and sha(file).lower() == row['sha256']
out = {
    'status': 'INDEPENDENT_ACTUAL_PURE_PARENT_COPY_COMPONENT_CONFIRMED_NOT_FIELD_OR_B_BRANCH_ADMISSION',
    'report_sha256': sha(REPORT), 'process_receipt_sha256': sha(pfile), 'checks': 39, 'failures': 0,
    'exit': {'true_console_exit': 0, 'wall_ms': p['elapsed_wall_ms'], 'warnings': 1, 'errors': 0, 'script_errors': 0, 'warning_clean': False},
    'source_protection': {'key_before_after_current_sha': p['script_sha256'], 'fixture_sha256': sha(fixture), 'actual_five_pin_before_after_checks_credit_from_fixed_key_and_39_passed_assertions': True, 'report_does_not_store_individual_source_observation_maps': True, 'four_small_code_pins_current_rechecked': small_checked, 'fixed04F2_packet_not_rehashed_or_decoded_by_QA': True, 'root_guard_sha256': sha(gf), 'root_guard_2117_exactticks_nochange_inherited_not_rehashed': True, 'fifteen_save_current_SHA_bytes_checked': True, 'exact_save_ticks_scope_from_Root_not_reinvented': True},
    'copy_and_isolation': {'rows': d['rows'], 'single_packet_decode': 1, 'large_case': 'fixed native T record Yamen only', 'native_Market_shape_credit': False, 'accepted_isolation_credit': ['Both retained whole trees match original four-copy reference and source before mutation', 'Current/frozen root insertion cannot affect sibling or source', 'Large material_binding_evidence nested markers isolated in both directions and removed values restored', 'Tiny current nested dictionary/array/PackedInt32Array and frozen Vector2 mutation isolated', 'Unknown domain returns empty'], 'checks_and_mutations_outside_copy_clock': True},
    'timing_limit': 'Single fixed old-four-copy then new-two-copy order; 103302 versus52091us is one isolated large-record copy observation, not a B/DT/Field saving, stable benchmark or number to multiply by assumed calls. Tiny Market is shape-independent only.',
    'not_covered': ['B deferred-child branch is only a SHA leaf; neither formal nor candidate B loaded/called by this key', '_map_parent original state/owner/inverse gates not called or forged', 'No production integrated adapter pin closure, FIRST/FINAL freshness, collector, real Scene/Field, geometry or ART credit', 'G candidate remains unpromoted; no standalone Stage or repeated component run authorized'],
    'review_operations': {'engine': 0, 'collector': 0, 'packet_decode': 0, 'large_packet_or_media_hash': 0, 'canonical_writes': 0, 'NEW_QA_receipt_only': True}
}
OUT.write_text(json.dumps(out, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'receipt': str(OUT), 'sha256': sha(OUT), 'process_receipt_sha256': sha(pfile)}))
