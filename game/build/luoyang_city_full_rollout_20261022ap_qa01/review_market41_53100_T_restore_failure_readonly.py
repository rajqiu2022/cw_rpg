"""One completed actual, small-source/read-only audit; no engine or collectors."""
from pathlib import Path
import hashlib
import json
import re

QA = Path(__file__).resolve().parent
GAME = QA.parents[1]
D = QA / 'market_pawn_single_visual_ROOT41_READY'
R = GAME / 'build/luoyang_city_full_rollout_20261022ap_root01/integration41'

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def rd(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))

rp = D / 'output/53100_2667/result.json'
assert sha(rp) == '714320d9600c8bfb719429c16b30963a2a55385f9c786b566648cb22783eb0a6'
r = rd(rp)
assert (r['checks'], r['failures'], r['complete'], r['elapsed_ms']) == (3447, 2, False, 23479)
fp = D / 'market_pawn_single_visual_fixture_ROOT41_READY.json'
assert sha(fp) == 'eac1f55debb3b5e5bb08d69666663323b4db6a67b394b94a4743862a9f948301'
f = rd(fp)
assert len(f['expected_sources']) == 1702 and len(f['source_sha256']) == 1735
assert len(r['source_before']) == 1736 and r['source_before'] == r['source_after']
expected = {**f['source_sha256'], 'res://' + fp.relative_to(GAME).as_posix(): sha(fp)}
assert {k: v['sha256'] for k, v in r['source_before'].items()} == expected
assert len(r['players_before']) == 15 and r['players_before'] == r['players_after']
assert len(r['records']) == 2
failure, counters = r['records']
assert failure['kind'] == 'MARKET_FIELD_FAILURE'
loading = failure['loading']
assert loading['scene_id'] == 'ch4_s3_luoyang_market'
assert loading['failed'] is True and loading['complete'] is False and loading['progress'] == 0.1
assert counters['kind'] == 'MARKET_FINITE_OBSERVATION_COUNTS'
for k in ['Space_calls', 'actual_body_queries', 'already_loaded_mask_samples', 'collector_calls', 'new_geometry', 'room_or_crossdistrict_trips']:
    assert counters[k] == 0
assert not list(rp.parent.glob('*.png'))
pp = R / 'market_pawn_once_process_receipt.json'
assert sha(pp) == '76b4aa7493262cee1387f7ecb6e45508851e012e19f7a2b32ebc6504bb71acb1'
pr = rd(pp)
assert pr['actual_natural_console_exit_code'] == -1073741819
assert pr['exit_code_from_retained_process_WaitForExit'] and not pr['process_stopped_by_tool']
kp = D / 'test_market_pawn_single_visual_ROOT41_READY.gd'
assert sha(kp) == pr['script_sha256'] == pr['script_after_sha256'] == '303d54c3430d978c0d93f235b2d715107261f7df500ae539448dd5bd31435db6'
ep, op = R / 'market_pawn_once_stderr.log', R / 'market_pawn_once_stdout.log'
assert sha(ep) == pr['stderr_sha256'] and sha(op) == pr['stdout_sha256']
err = ep.read_text(encoding='utf-8-sig')
counts = {k: len(re.findall(v, err, re.M)) for k, v in {'ERROR': r'^ERROR:', 'WARNING': r'^WARNING:', 'SCRIPT_ERROR': r'^SCRIPT ERROR:'}.items()}
assert counts == {'ERROR': 9, 'WARNING': 1, 'SCRIPT_ERROR': 0}
assert '[Field] District life refused: T_COMPLETE_REVERSIBLE_PARENT_RECORD' in err
assert 'CITY_LIFE_QA_FAIL Matching Field failure before draw' in err
assert 'CITY_LIFE_QA_FAIL Predeclared whole finite scope' in err
gp, bp = R / 'final_guard.json', R / 'guard_before.json'
assert sha(gp) == '9c2f29f0aad496fe1a50b8b93eccf2d8df6444ecd6d9332e969edbfec4309258'
assert sha(bp) == 'a56c7db8f6825c5341beeb402fa239406100cae7acc8b1f105cdcbcdf36b5697'
g, b = rd(gp), rd(bp)
assert g['passed'] and g['checked'] == g['exact_unchanged'] == 2118
assert g['authorized_change_count'] == g['unexpected_change_count'] == g['save_change_count'] == 0
assert g['save_count'] == 15 and g['facts'] == b['facts']
tbp, tap = R / 'source_only_three_facts_before.json', R / 'source_only_three_facts_after.json'
assert sha(tap) == '521789e555e1c05c689b963119d27789aeaa7ee5134cfdd7a1a4cf322be439f3'
tb, ta = rd(tbp), rd(tap)
prior = rd(GAME / 'build/luoyang_city_full_rollout_20261022ap_root01/integration39/proof_autoimport_tuple_before_retry1.json')
assert tb['facts'] == ta['facts'] == prior['facts']
assert tb['runtime_texture_credit'] is False and ta['runtime_texture_credit'] is False
for row in ta['facts']:
    p = Path(row['path'])
    assert p.stat().st_size == row['bytes'] and sha(p) == row['sha256']
small = 0
for path, digest in f['source_sha256'].items():
    if path.startswith('res://scripts/'):
        p = GAME / path[6:]
        assert p.stat().st_size < 1048576 and sha(p) == digest
        small += 1
savebase = Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for path, row in r['players_after'].items():
    p = savebase / path.removeprefix('user://')
    assert p.exists() == row['exists']
    if row['exists']:
        assert p.stat().st_size == row['bytes'] and sha(p) == row['sha256']
dt = (GAME / 'scripts/city/luoyang_district_life_20261016f.gd').read_text(encoding='utf-8-sig')
field = (GAME / 'scripts/field/field_walkable_controller.gd').read_text(encoding='utf-8-sig')
assert 'if current.is_empty(): return _reject("T_COMPLETE_REVERSIBLE_PARENT_RECORD")' in dt
assert 'projected.clear(); parent_render.clear(); _sources.clear(); _config.clear()' in dt
assert 'func state() -> Dictionary: return _receipt.duplicate(true)' in dt
assert '_district_last_receipt=_district_session.state()' in field and '_district_session=null' in field
out = QA / 'market41_53100_Field_T_restore_wholeFAIL_independent_readonly_review_READY.json'
assert not out.exists()
out.write_text(json.dumps({
    'status': 'MARKET41_WHOLEFAIL_FIELD10_PERCENT_T_REVERSIBLE_PARENT_NO_IMAGE_NO_RETRY',
    'report': {'path': str(rp), 'sha256': sha(rp), 'checks': 3447, 'failures': 2, 'complete': False, 'elapsed_ms': 23479},
    'actual_boundary': {
        'Field_failure_snapshot': failure,
        'specific_stderr_error': 'T_COMPLETE_REVERSIBLE_PARENT_RECORD',
        'past_previous_source_set_rejection_to_Field_district_prepare': True,
        'no_successful_ready_draw_INPUT_picture_or_naturalFINAL1702_record': True,
        'expected1702_is_fixed_FC11_not_observed_FINAL': True,
        'all_body_mask_Space_room_collector_geometry_counters_zero': True,
        'records_only_loading_failure_and_counters': True,
        'no_record_pair_C_proof_or_DT_source_dictionary_saved': True,
        'static_DT183_reports_only_empty_B_restore_not_specific_inner_gate': True,
        'static_reject_releases_projected_and_sources_before_Field_last_receipt_copy': True,
        'no_cause_inferred_from_missing_inner_comparison_details': True
    },
    'protection': {'report1736_FIRSTFINAL_exact': True, 'fixture1735_plus_fixture_exact': True,
        'current_small_script_SHA_count': small, '15save_report_and_currentSHAbytes_exact': True,
        'Root2118_facts_exactticks_same': True, 'Root_guard_sha256': sha(gp),
        'three_SOURCE_ONLY_facts_exact_to_ROOT39_and_current': True, 'three_fact_after_sha256': sha(tap),
        'no_large_media_or_full_source_scan': True},
    'exit': {'process_receipt_sha256': sha(pp), 'true_console': -1073741819, 'hex': '0xC0000005',
        'wall_ms': pr['elapsed_wall_ms'], 'log_counts': counts, 'nonclean': True, 'rootcause_of_exit_not_claimed': True},
    'preserved': ['ROOT38 source refusal', 'ROOT41 wholeFAIL and exit crash', 'all prior failures and SOURCE_ONLY-only limits'],
    'operations': {'engine': 0, 'collector': 0, 'newGUIkey': 0, 'decode': 0, 'Stage': 0, 'canonical_or_oldreport_writes': 0}
}, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'receipt': str(out), 'sha256': sha(out), 'small_script_count': small, 'logs': counts, 'true_exit': -1073741819}))
