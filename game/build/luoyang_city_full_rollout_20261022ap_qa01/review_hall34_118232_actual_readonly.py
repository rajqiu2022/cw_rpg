"""Audit one retained actual. No engine, collector, decode, new test or production write."""
from pathlib import Path
import hashlib
import json
import re

QA = Path(__file__).resolve().parent
GAME = QA.parents[1]
ROOT = GAME / 'build/luoyang_city_full_rollout_20261022ap_root01'
D = QA / 'hall_roundtrip_ROOT34_READY'
R = ROOT / 'integration34'

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def rd(p):
    return json.loads(p.read_text(encoding='utf-8-sig'))

rp = D / 'output/118232_2798/result.json'
assert sha(rp) == '24c8e99dc89be5855388ee9b586e5ea627106b403633f5ba25e106abc7c2d33b'
r = rd(rp)
assert (r['checks'], r['complete'], r['failures'], r['elapsed_ms']) == (3110, False, 2, 27881)
fp = D / 'hall_roundtrip_fixture_ROOT34_READY.json'
assert sha(fp) == '6e0bb85fd73f71cdc22271174831c413023a09e482f756d3cbd52f6b2aa91a93'
f = rd(fp)
assert r['source_before'] == r['source_after'] and len(r['source_before']) == 1298
expected_guard = {**f['source_sha256'], 'res://' + fp.relative_to(GAME).as_posix(): sha(fp)}
assert {k:v['sha256'] for k,v in r['source_before'].items()} == expected_guard
assert r['players_before'] == r['players_after'] and len(r['players_before']) == 15
assert [x['kind'] for x in r['records']] == [
    'HALL_FIRST_HIDDEN_OPERABLE_DRAW_BEFORE_POSTVERIFY',
    'HALL_NATURAL_CITY_SOURCE_OWNER_AFTER_DRAW', 'HALL_REAL_INPUT',
    'HALL_EXIT_SCALARS_BEFORE_UNCHANGED_FILTER', 'HALL_UNCHANGED_EXACT_FILTER_COUNT']
draw, natural, walk, exits, found = r['records']
assert draw['ready']['elapsed_usec'] == 12810946 and draw['draw']['elapsed_usec'] == 12935786
assert draw['draw']['loading_hidden_inactive'] and draw['draw']['can_move']
assert draw['leg'] == 'EXPLICIT_NEAR_DOOR_NOT_DEFAULT_TRAVEL'
assert natural['initial'] and natural['token'] > 0 and natural['source_count'] == 1239
assert natural['sources'] == f['expected_city_sources']
assert walk['label'] == 'street716to660'
w = walk['result']
assert w['ok'] and w['reached'] and w['all_recorded_feet_clear'] and w['physics_samples'] == 8
assert w['start'] == [1536.,716.] and w['target'] == w['actual_end'] == [1536.,660.]
assert exits['portal_layer_child_count'] == len(exits['nodes']) == 3
assert exits['requested_target'] == found['requested_target'] == 'luoyang_yamen_official_hall_20261018t'
assert exits['expected_author_position'] == found['expected_author_position'] == [1536.,660.]
assert found['found_count'] == 0 and exits['no_expected_values_taken_from_observed_nodes']
targets = ['ch4_s0_luoyang_gate','ch4_s3_luoyang_market','ch4_s2_canal_docks']
positions = [[1536.,1860.],[300.,1220.],[2790.,1350.]]
for n, target, position in zip(exits['nodes'], targets, positions):
    assert n['valid'] and n['target_text'] == target and n['target_type'] == 4 and n['position'] == position
    assert n['scriptpath'] == 'res://scripts/field/luoyang_v3_exit_zone.gd'
    assert not n['locked'] and not n['auto_trigger'] and n['monitoring']
    assert n['shape_present'] and n['shape_disabled'] and n['shape_type'] == 'RectangleShape2D'
    assert n['polygon_present'] and not n['polygon_disabled'] and n['polygon_point_count'] == 4
    assert n['polygon_four_local_points'] == [[-48.,-24.],[48.,-24.],[48.,24.],[-48.,24.]]
assert not any(n['target_text'] == found['requested_target'] for n in exits['nodes'])

pp = R / 'hall_roundtrip_once_process_receipt.json'
assert sha(pp) == '192e924b3b3e7e2fea995cd79ede0250272e480c345d68b1b7b9de9185e1a9a5'
pr = rd(pp)
assert pr['actual_natural_console_exit_code'] == -1073741819
assert pr['exit_code_from_retained_process_WaitForExit'] and not pr['process_stopped_by_tool']
kp = D / 'test_hall_roundtrip_ROOT34_READY.gd'
assert sha(kp) == pr['script_sha256'] == pr['script_after_sha256'] == 'b91a2b332c08fdc9e38360cd158a9277e569836f7c6fe5df5129217f0100ef68'
ep, op = R/'hall_roundtrip_once_stderr.log', R/'hall_roundtrip_once_stdout.log'
assert sha(ep) == pr['stderr_sha256'] and sha(op) == pr['stdout_sha256']
err = ep.read_text(encoding='utf-8-sig')
assert 'CITY_LIFE_QA_FAIL One exact authored native target and door foot <null>' in err
counts = {k:len(re.findall(v,err,re.M)) for k,v in {
    'ERROR':r'^ERROR:', 'WARNING':r'^WARNING:', 'SCRIPT_ERROR':r'^SCRIPT ERROR:'}.items()}
assert counts == {'ERROR':10,'WARNING':1,'SCRIPT_ERROR':0}
gp, bp = R/'final_guard.json', R/'guard_before.json'
assert sha(gp) == '298336610cfd9c97a80f7c22395d3810e8e8e1f6372dfdd3b09910061dac5832'
assert sha(bp) == '15449672a4fa00f77eab5825c4a00d6baec1c9e4a0e82590d74320f9abc6304b'
g, b = rd(gp), rd(bp)
assert g['passed'] and g['checked'] == g['exact_unchanged'] == 2118
assert g['authorized_change_count'] == g['unexpected_change_count'] == g['save_change_count'] == 0
assert g['save_count'] == 15 and g['before_sha256'] == sha(bp)
assert g['facts'] == b['facts']
task = [x for x in g['facts'] if Path(x['path']).name == 'tasks.yaml']
assert len(task) == 1 and task[0]['sha256'] == '9c27ffc9f97a9ba2c238f6da8a7bdab193027e1622445d086be8b727d7b56544'
assert task[0]['bytes'] == 769954

# Current small scripts/authorities and saves only: no media/full guard rehash.
current_script_count = 0
for path, digest in f['source_sha256'].items():
    if path.startswith('res://scripts/'):
        p = GAME / path.removeprefix('res://')
        assert p.stat().st_size < 1048576 and sha(p) == digest
        current_script_count += 1
assert current_script_count == 97
for authority in f['authority'].values():
    p = GAME / authority['path'].removeprefix('res://')
    assert sha(p) == authority['sha256']
savebase = Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for path, row in r['players_after'].items():
    p = savebase / path.removeprefix('user://')
    assert p.exists() == row['exists']
    if row['exists']:
        assert p.stat().st_size == row['bytes'] and sha(p) == row['sha256']

out = QA / 'hall34_118232_actual_absent_hall_independent_readonly_review_READY.json'
assert not out.exists()
receipt = {
    'status':'HALL34_ACTUAL_WHOLEFAIL_AND_C0000005_PRESERVED_NO_RETEST',
    'report':{'path':str(rp),'sha256':sha(rp)},
    'process':{'path':str(pp),'sha256':sha(pp),'true_console_exit':-1073741819,'hex':'C0000005','wall_ms':pr['elapsed_wall_ms'],'root_cause_not_inferred':True,'nonclean':True,'log_counts':counts},
    'actual':{'checks':3110,'failures':2,'complete':False,'elapsed_ms':27881,'near_ready_usec':12810946,'near_hidden_operable_draw_usec':12935786,'near_entry20s_component':True,'under10s':False,'explicit_near_not_default_or_world_travel':True,'natural_C_FINAL1239_exact_fixed_expected':True,'INPUT716to660_8physics_allclear':True},
    'diagnosis':{'observed_native_exit_targets':targets,'positions':positions,'portal_layer_children':3,'exact_hall_filter_count':0,'hall_target_absent_at_all_observed_positions':True,'not_StringName_or_subpixel_position_filter_mismatch':True,'three_existing_city_shapes_disabledRectangle_enabled4pointPolygon':True,'observed_96x48_city_polygons_not_substituted_for_expected40x32_hall':True,'corrected_hall_shape_predicate_not_reached':True,'missing_hall_projection_cause_not_established_by_this_actual':True},
    'unexecuted':['Space','hall room entry','room session/finalized identity','parked exterior identity/memory','room exit INPUT/Space','warm return hit/RESUMED/same objects/author foot','warm hidden draw<10s'],
    'source_save_guard':{'1298_report_FIRST_FINAL_exact':True,'1297_fixed_guard_plus_fixture_exact':True,'natural1239_exact_fixture':True,'97_current_small_script_SHA_exact':True,'fixture_authority_current_SHA_exact':True,'15save_report_and_currentSHAbytes_exact':True,'Root34_2118facts_before_after_exactticks_same':True,'Root34_guard_sha256':sha(gp),'external_tasks9C27_preserved_as_fresh34_baseline':True,'Root33_failed_guard_9944_not_erased_or_retroauthorized':True,'no_whole_media_current_rehash_claim':True},
    'operations':{'engine':0,'collector':0,'packet_or_image_decode':0,'new_test':0,'old_report_or_production_writes':0}}
out.write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'complete':False,'found_count':0,'draw_usec':12935786,'log_counts':counts}))
