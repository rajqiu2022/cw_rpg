"""NEW hardfalse successor for two proven UI test-contract mistakes only."""
from pathlib import Path
import copy, difflib, hashlib, json

Q = Path(__file__).resolve().parent
GAME = Q.parent.parent
OLD = Q / 'market_apothecary_vendor_journey_NOTREADY'
NEW = Q / 'market_apothecary_vendor_journey_ui_successor01_NOTREADY'
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def emit(p, value):
    assert not p.exists(), p
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes((json.dumps(value, ensure_ascii=True, indent=2) + '\n').encode('ascii'))
    return sha(p)
def put(p, value):
    assert not p.exists(), p
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_bytes(value)
    return sha(p)

old_key = OLD / 'test_NOTREADY.gd'
old_fixture_path = OLD / 'fixture_NOTREADY.json'
assert sha(old_key) == 'c62ac9e77c4045f4baae7ddd3eba5a2624eb3d3ece67d1526ac5c91c03a6aa85'
assert sha(old_fixture_path) == '81975697ab7486ca2914228f2c611fbcd54a888d607aea371e6ae78402f70bf0'
fixture = json.loads(old_fixture_path.read_bytes())
original_fixture = copy.deepcopy(fixture)
ui = GAME / 'build/luoyang_city_revision_20261024b_dialog01/fallback_successor02/stage_CANDIDATE/DialogBox_CANDIDATE.gd'
assert sha(ui) == 'fe8165682670f7bcc5689d963b456f5d9503ba7f6abece575ad4f04e82c9c337'
scene = GAME / 'scenes/ui/dialog_box.tscn'
assert sha(scene) == '3433f23ec71e43623fbec32982ae2411e72ee194eddf2e62fc95af2379919bca'
scene_text = scene.read_text(encoding='utf-8')
assert '[node name="DialogLayer" type="CanvasLayer"]' in scene_text
assert '[node name="DialogBox" type="Control" parent="."' in scene_text
ui_text = ui.read_text(encoding='utf-8')
assert 'lbl.text = "  %d. %s" % [i + 1, String(c.get("text", "..."))]' in ui_text
fixture['task']['offer_ui_labels'] = ['  %d. %s' % (i + 1, text) for i, text in enumerate(fixture['task']['offer_labels'])]
canonical = 'res://scripts/ui/dialog_box.gd'
old_ui_hash = fixture['source_sha256'][canonical]
assert old_ui_hash.startswith('02c')
fixture['ui_parent_provenance'] = {'path': canonical, 'old_sha256': old_ui_hash,
    'meaning': 'Historical parent only; not the future runtime hash. Canonical FE816 expectation remains NOTREADY until Root formal deployment.'}
fixture['source_sha256'][canonical] = sha(ui)
new_ui_res = 'res://' + ui.relative_to(GAME).as_posix()
scene_res = 'res://' + scene.relative_to(GAME).as_posix()
assert new_ui_res not in fixture['source_sha256'] and scene_res not in fixture['source_sha256']
fixture['source_sha256'][new_ui_res] = sha(ui)
fixture['source_sha256'][scene_res] = sha(scene)
fixture_sha = emit(NEW / 'fixture_NOTREADY.json', fixture)
inverse_fixture = copy.deepcopy(fixture)
del inverse_fixture['task']['offer_ui_labels']
del inverse_fixture['ui_parent_provenance']
inverse_fixture['source_sha256'][canonical] = old_ui_hash
del inverse_fixture['source_sha256'][new_ui_res]
del inverse_fixture['source_sha256'][scene_res]
assert inverse_fixture == original_fixture

resolver = '''func _dialog_box() -> Control:
	# DP owns the instantiated CanvasLayer, not the scripted Control child.
	var layer: CanvasLayer=_dp().get("_box") as CanvasLayer
	return layer.get_node_or_null("DialogBox") as Control if layer!=null else null
'''
changes = [
    ('func _node() -> DialogNode:', resolver + 'func _node() -> DialogNode:'),
    ('var box: Control=_dp().get("_box") as Control', 'var box: Control=_dialog_box()'),
    ('\tvar box: Control=_dialog_box();var choice_labels: Array=[]\n',
     '\tvar box: Control=_dialog_box();var choice_labels: Array=[]\n\tif not check(box!=null,"Actual CanvasLayer DialogBox Control before task labels"): return false\n'),
    ('choice_labels==fixture.task.offer_labels', 'choice_labels==fixture.task.offer_ui_labels'),
]
source = old_key.read_bytes()
assert b'\r\n' not in source  # Exact original test EOF/LF bytes retained, no implicit normalization.
ops = []
for before, after in changes:
    old, new = before.encode(), after.encode()
    expected_count = 2 if before == 'var box: Control=_dp().get("_box") as Control' else 1
    assert source.count(old) == expected_count, (before, source.count(old))
    source = source.replace(old, new)
    ops.append((old, new, expected_count))
old_res = 'res://' + old_fixture_path.relative_to(GAME).as_posix()
new_res = 'res://' + (NEW / 'fixture_NOTREADY.json').relative_to(GAME).as_posix()
for before, after in [(old_res, new_res), (sha(old_fixture_path), fixture_sha),
                      ('res://' + (OLD / 'output_NOTREADY').relative_to(GAME).as_posix(),
                       'res://' + (NEW / 'output_NOTREADY').relative_to(GAME).as_posix())]:
    old, new = before.encode(), after.encode()
    assert source.count(old) == 1
    source = source.replace(old, new, 1);ops.append((old, new, 1))
inverse = source
for old, new, count in reversed(ops):
    assert inverse.count(new) == count, (new[:80], inverse.count(new), count)
    inverse = inverse.replace(new, old)
assert inverse == old_key.read_bytes()
assert source.endswith(b'\n') == old_key.read_bytes().endswith(b'\n')
assert b'const JOURNEY_READY=false' in source
key = NEW / 'test_NOTREADY.gd'
put(key, source)
put(NEW / 'complete_vs_C62AC9.diff', ''.join(difflib.unified_diff(old_key.read_text(encoding='utf-8').splitlines(True), source.decode().splitlines(True), fromfile=str(old_key), tofile=str(key))).encode('utf-8'))
proof = {'status': 'NEW_TWO_UI_TEST_CONTRACT_FIXES_ONLY_NOTREADY_NOT_RUN',
    'key_sha256': sha(key), 'fixture_sha256': fixture_sha,
    'old_key_sha256_preserved': sha(old_key), 'old_fixture_sha256_preserved': sha(old_fixture_path),
    'key_wholebyte_inverse_including_EOF': True, 'fixture_wholetyped_inverse': True,
    'exact_key_edits': ['three fixture/output literals', 'one CanvasLayer-to-DialogBox typed resolver and its two original callsites',
                       'one task-label nonnull check', 'one comparison to source-derived numbered UI labels'],
    'fixture_only_edits': ['offer_ui_labels from FE816 two-space numbering expression', 'canonical DialogBox expected hash old02C to future FE816',
                          'old02C parent provenance descriptor', 'fixed candidate FE816 and unchanged DialogBox scene proof pins'],
    'canonical_runtime_UI_expected': {'path': canonical, 'sha256': sha(ui), 'not_claimed_deployed_yet': True},
    'source_scene_CanvasLayer_child_proof': {'path': scene_res, 'sha256': sha(scene)},
    'budgets_routes_owner_sources_other_than_UI_unchanged': True,
    'no_delay_or_yield_added': True, 'raw_task_choice_semantics_unchanged': True,
    'fixed_whole_ms': 60000, 'fixed_entry_ms': 20000, 'PNG_max': 3,
    'hardfalse_formalfalse_and_future_empty_routes_owner_preserved': True,
    'engine_Stage_collector_PNG_packet_calls_by_QA': 0}
proof_sha = emit(NEW / 'ui_contract_whole_inverse_NOTREADY.json', proof)
print(json.dumps({'key': sha(key), 'fixture': fixture_sha, 'proof': proof_sha}, indent=2))
