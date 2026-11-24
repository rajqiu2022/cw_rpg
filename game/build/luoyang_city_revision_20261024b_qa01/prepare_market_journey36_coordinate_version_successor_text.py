"""NEW initial public-call coordinate-version fix only. No engine or data change."""
from pathlib import Path
import hashlib, json, difflib

Q = Path(__file__).resolve().parent
OLD = Q / 'root_market_journey36_READY'
NEW = Q / 'root_market_journey36_coordinate_version_READY'
sha = lambda raw: hashlib.sha256(raw).hexdigest()
old_key = OLD / 'test_READY.gd'
old_raw = old_key.read_bytes()
assert sha(old_raw) == 'a0fa896c7461bbdb2b09c0afdabe17018a04ccea127cc95d88feccedfd0ba425'
fixture = OLD / 'fixture_READY.json'
assert sha(fixture.read_bytes()) == '98aed550ea2313ed17c7c800845828e13bc9dfd85a06abccfe098ad9c1c398d88'
old_call = '''	if not check(root.get_node("SceneRouter").call("go_field_smart",CITY,_v(fixture.near_return_world)/Vector2(3072,2048)),"One public explicit-near apothecary return setup, NOT default/world trip") or not await _arrive(CITY,ENTRY_MS,"EXPLICIT_NEAR_NOT_DEFAULT"): return false
'''
new_call = '''	var accepted: bool=root.get_node("SceneRouter").call("go_field_smart",CITY,_v(fixture.near_return_world)/Vector2(3072,2048),"",-1,C.VERSION)
	if not accepted:
		records.append({"kind":"INITIAL_PUBLIC_REQUEST_REJECTED_BEFORE_FIELD","public_state":root.get_node("SceneRouter").call("get_public_city_preparation_state"),"C_errors":C.errors(),"explicit_local_coordinate_version":C.VERSION,"no_Field_or_firstdraw_credit":true})
	if not check(accepted,"One public explicit-near apothecary return setup, NOT default/world trip") or not await _arrive(CITY,ENTRY_MS,"EXPLICIT_NEAR_NOT_DEFAULT"): return false
'''
nl = b'\r\n' if b'\r\n' in old_raw else b'\n'
native = lambda s: s.replace('\n',nl.decode()).encode('utf-8')
old_output = 'res://build/luoyang_city_revision_20261024b_qa01/root_market_journey36_READY/output_READY'
new_output = 'res://build/luoyang_city_revision_20261024b_qa01/root_market_journey36_coordinate_version_READY/output_READY'
ops = [(native(old_call),native(new_call)),(old_output.encode(),new_output.encode())]
source = old_raw
for before,after in ops:
    assert source.count(before) == 1
    source = source.replace(before,after,1)
inverse = source
for before,after in reversed(ops):
    assert inverse.count(after) == 1
    inverse = inverse.replace(after,before,1)
assert inverse == old_raw
assert source.endswith(b'\n') == old_raw.endswith(b'\n')
assert b',"",-1,C.VERSION)' in source
# Fixture/its1797 map and all other function bytes stay the same. No fixture copy.
assert fixture.as_posix().replace('F:/Code/RPG_GAME/game/','res://').encode() in source
assert b'98aed550ea2313ed17c7c800845828e13bc9dfd85a06abccfe098ad9c1c398d88' in source
result_path = OLD / 'output_READY/103168_2740/result.json'
actual = json.loads(result_path.read_bytes())
assert actual['checks'] == 39 and actual['failures'] == 2 and actual['complete'] is False
assert actual['elapsed_ms'] == 146
last = actual['records'][-1]
assert last['real_INPUT_physics_steps'] == last['body_queries'] == last['local_loaded_mask_samples'] == last['pictures'] == 0
assert not NEW.exists()
NEW.mkdir()
key = NEW / 'test_READY.gd'
key.write_bytes(source)
(NEW / 'complete_vs_A0FA.diff').write_bytes(''.join(difflib.unified_diff(old_raw.decode().splitlines(True),source.decode().splitlines(True),fromfile=str(old_key),tofile=str(key))).encode())
proof = {'status':'ROOT_REQUESTED_MINIMAL_INITIAL_COORDINATE_VERSION_SUCCESSOR_NOT_ENGINE_RUN',
    'key_sha256':sha(source),'old_key_sha256_preserved':sha(old_raw),'wholebyte_inverse_including_EOF':True,
    'fixture_path_reused_unchanged':'res://build/luoyang_city_revision_20261024b_qa01/root_market_journey36_READY/fixture_READY.json',
    'fixture_sha256_unchanged':sha(fixture.read_bytes()),'expected_natural_sources':1797,
    'only_key_changes':['initial go_field_smart explicit pending_action empty/world_version -1/local_version C.VERSION',
                        'same-branch existing public state/C_errors diagnostic if immediate false','NEW output root literal'],
    'cause_source':'SceneRouter _enqueue_public_city: explicit Vector2 spawn + default local -1 reads local_layout_versions default1; public direct request rejects legacy effective version. Caller must specify current C.VERSION.',
    'old_actual':{'path':str(result_path),'sha256':sha(result_path.read_bytes()),'checks':39,'failures':2,'elapsed_ms':146,
                  'Field_INPUT_Physics_PNG':0,'no_new_Field_or_preflight_credit':True,'wholeFAIL_retained':True},
    'whole_ms':60000,'entry_ms':20000,'all_other_logic_paths_UI_labels_and_fixtures_unchanged':True,
    'no_new_source_values_or_observation_backfill':True,'production_changes':0,'QA_engine_calls':0}
raw = (json.dumps(proof,ensure_ascii=True,indent=2)+'\n').encode('ascii')
(NEW / 'coordinate_version_whole_inverse_READY_NOTRUN.json').write_bytes(raw)
print(json.dumps({'key':sha(source),'fixture_unchanged':sha(fixture.read_bytes()),'proof':sha(raw)},indent=2))
