"""Only text/JSON checks; prior shell-quoted one-liner failed before any output."""
from pathlib import Path
import hashlib, json
q = Path(__file__).resolve().parent
d = q / 'market_apothecary_vendor_journey_NOTREADY'
k = (d / 'test_NOTREADY.gd').read_text(encoding='utf-8')
f = json.loads((d / 'fixture_NOTREADY.json').read_bytes())
assert 'const JOURNEY_READY=false' in k and f['ready'] is False and f['formal_deployed'] is False
assert all(v == [] for v in f['paths'].values())
assert f['expected_city_sources'] == {} and f['expected_city_count'] is None
assert f['whole_ms'] == 60000 and f['entry_ms'] == 20000 and f['max_pictures'] == 3
assert k.count('call("go_field_smart"') == 1
for forbidden in ['DialogPlayer.play(', '.call("play"', '.choose(', 'source_paths(',
                  'validation_begin(', 'validation_finish(', 'C.safe_body(', 'driver.plan(',
                  '_player().position=']:
    assert forbidden not in k, forbidden
assert 'KEY_2' in k and '.call("set_checkpoint_saves_suspended",true)' in k
assert '_gameplay()==gameplay' in k and 'driver.release()' in k
assert k.count('await _picture(') == 3
assert f['vendor']['first_expected_node_ids'] == ['npc_opening_20261024b_hero', 'start', 'reply']
assert f['vendor']['second_expected_node_ids'] == ['npc_opening_20261024b_hero', 'npc_opening_20261024b_rumor']
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
report = {
    'status': 'FUTURE_FIELD_NOTREADY_SOURCE_DERIVED_DIALOG_AND_SCOPE_TEXT_REVIEW_ONLY',
    'key_sha256': sha(d / 'test_NOTREADY.gd'), 'fixture_sha256': sha(d / 'fixture_NOTREADY.json'),
    'hardfalse_and_empty_future_owner_routes': True,
    'source_derived_dialog_expectations': 'AP exact daily row/build_dynamic_menu + original2lines + 535F helper; no guessed static3node TRES',
    'finite_source_guard_provenance_count': len(f['source_sha256']),
    'whole_ms': 60000, 'entry_ms': 20000, 'room_ms': 10000, 'return_ms': 10000, 'PNG_max': 3,
    'new_Godot_key_lines': len(k.splitlines()),
    'no_direct_DP_play_choose_source_collector_validator_or_Player_position_write_in_key': True,
    'real_Input_only_and_explicit_task_decline': True,
    'natural_C_complete_map_once_from_future_independent_owner_not_observation_fill': True,
    'pending_blockers': f['blockers'],
    'static_review_not_parse_or_runtime': True,
    'QA_engine_Image_packet_Stage_or_production_calls': 0,
    'retained_predecessor_failure': 'First shell-quoted Python one-liner SyntaxError before evaluation/output; retry1 uses saved script only. No test/fixture was modified.'}
p = d / 'static_text_scope_review_NOTREADY.json'
assert not p.exists()
p.write_bytes((json.dumps(report, ensure_ascii=True, indent=2) + '\n').encode('ascii'))
print(json.dumps({'review': sha(p), 'key': report['key_sha256'], 'guard_count': len(f['source_sha256'])}, indent=2))
