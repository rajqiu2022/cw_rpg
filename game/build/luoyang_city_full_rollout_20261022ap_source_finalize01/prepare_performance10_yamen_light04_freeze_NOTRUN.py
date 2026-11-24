"""Freeze NEW performance04 text against Root18 actual deployment; never run engine."""
import copy
import difflib
import hashlib
import json
from pathlib import Path

H = Path(__file__).resolve().parent
G = H.parents[1]
S = 'res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P = S + 'performance09_yamen_light04/'
O = S + 'performance10_yamen_light04_ROOT18/'
R = 'res://build/luoyang_city_full_rollout_20261022ap_root01/integration18/'

def sha(b): return hashlib.sha256(b).hexdigest()
def path(p): return G / p.removeprefix('res://')
def js(v): return (json.dumps(v, ensure_ascii=False, indent=2) + '\n').encode()
def fixed(p, s):
    b = path(p).read_bytes()
    assert sha(b) == s, ('PIN_CHANGED', p)
    return b

pending_key = P + 'test_yamen_performance04_PENDING_ROOT.gd'
pending_key_sha = '75d0e7a3649b806ed7240f53bef995faf5513f7c9754424aa21860670ca2c728'
pending_fixture = P + 'yamen_performance04_fixture_PENDING_ROOT.json'
pending_fixture_sha = 'b6e0fc2764359fb553b92d54cbaa4553d0cc9f443f787c3fa2f4475c0a6b4086'
pending_handoff = P + 'handoff_PENDING_ROOT_NOT_RUN.json'
pending_handoff_sha = 'a6b5dd62576a7cc48f0140b5777ae7b7912c2e53f85273a573be00671dc310f4'
guard_path = R + 'final_guard.json'
guard_sha = 'ea3d7b5fd359dedab0d253cee4c59ca9d89144935bbf3b98032249f0c7b9f999'
actual_path = R + 'generated_json_deployment_actual.json'
actual_sha = '439f840359889b317bd9dcfd6c9908dc460c529b9a6ddcfe7e3f31d03b1118ff'
kb = fixed(pending_key, pending_key_sha)
fb = fixed(pending_fixture, pending_fixture_sha)
hb = fixed(pending_handoff, pending_handoff_sha)
old = json.loads(fb)
ph = json.loads(hb)
guard = json.loads(fixed(guard_path, guard_sha))
actual = json.loads(fixed(actual_path, actual_sha))
assert guard['passed'] is True and guard['checked'] == 2117
assert guard['authorized_change_count'] == 26 and guard['exact_unchanged'] == 2091
assert guard['unexpected_change_count'] == 0 and guard['save_change_count'] == 0 and guard['save_count'] == 15
assert actual['status'] == 'ACTUAL12_GD_APPLY_PATCH_AND14_GENERATED_JSON_EXACT_COPY_COMPLETED'
assert actual['all26_exact'] is True and actual['GD_apply_patch_count'] == 12 and actual['JSON_exact_copy_count'] == 14
assert len(actual['facts']) == 26 and actual['save_writes'] == 0
assert guard['authorization_sha256'] == actual['authorization_sha256']
assert old['ready'] is False and len(old['expected_city_source_sha256']) == 1221 and len(old['source_sha256']) == 1242
owner_ref = old['authority']['independent_owner']
owner = json.loads(fixed(owner_ref['path'], owner_ref['sha256']))
owner_row = next(r for r in owner['scenes'] if r['id'] == 'ch4_s1_luoyang_yamen')
assert old['expected_city_source_sha256'] == owner_row['source_sha256'] == owner_row['receipt_source_sha256']

new = copy.deepcopy(old)
new['status'] = 'ROOT18_DEPLOYED_PERFORMANCE04_ONE_DEFAULT_ENTRY_ONLY_READY_NOT_RUN'
new['ready'] = True
new['blockers'] = []
new['authority']['actual_Root_deployment_guard'] = {'path': guard_path, 'sha256': guard_sha, 'pending': False}
new['authority']['actual_Root_deployment_copy'] = {'path': actual_path, 'sha256': actual_sha}
new['pending_authority_not_in_source_guard_until_real_freeze'] = False
for p, s in [(guard_path, guard_sha), (actual_path, actual_sha)]:
    assert p not in new['source_sha256']
    new['source_sha256'][p] = s
assert len(new['source_sha256']) == 1244
inverse = copy.deepcopy(new)
for p in [guard_path, actual_path]: del inverse['source_sha256'][p]
for k in ['status', 'ready', 'blockers', 'authority', 'pending_authority_not_in_source_guard_until_real_freeze']:
    inverse[k] = copy.deepcopy(old[k])
assert js(inverse) == fb
fixture_path = O + 'yamen_performance04_fixture_ROOT18_READY.json'
fixture_bytes = js(new)
fixture_sha = sha(fixture_bytes)
key_path = O + 'test_yamen_performance04_ROOT18_READY.gd'
key = kb
hunks = [
    {'old': 'const FIXTURE="' + pending_fixture + '"', 'new': 'const FIXTURE="' + fixture_path + '"'},
    {'old': 'const FIXTURE_SHA="' + pending_fixture_sha + '"', 'new': 'const FIXTURE_SHA="' + fixture_sha + '"'},
]
for h in hunks:
    a, b = h['old'].encode(), h['new'].encode()
    assert key.count(a) == 1
    key = key.replace(a, b, 1)
back = key
for h in reversed(hunks): back = back.replace(h['new'].encode(), h['old'].encode(), 1)
assert back == kb
assert key.count(b'district.call("loading_timing_state")') == 1
parent = fixed(ph['parent_script']['path'], ph['parent_script']['sha256'])
pending_inverse = kb
for h in reversed(ph['hunks']):
    assert pending_inverse.count(h['new'].encode()) == 1
    pending_inverse = pending_inverse.replace(h['new'].encode(), h['old'].encode(), 1)
assert pending_inverse == parent

def diff(a, b, ap, bp):
    return ''.join(difflib.unified_diff(a.decode().splitlines(True), b.decode().splitlines(True), fromfile=ap, tofile=bp)).encode()

freeze_diff = diff(kb, key, pending_key, key_path)
fixture_diff = diff(fb, fixture_bytes, pending_fixture, fixture_path)
complete_diff = diff(parent, key, ph['parent_script']['path'], key_path)
files = {
    'yamen_performance04_fixture_ROOT18_READY.json': fixture_bytes,
    'test_yamen_performance04_ROOT18_READY.gd': key,
    'freeze_vs_PENDING_key.diff': freeze_diff,
    'freeze_vs_PENDING_fixture.diff': fixture_diff,
    'complete_vs_2EDD.diff': complete_diff,
}
handoff = {
    'status': 'ROOT18_ACTUAL_DEPLOYMENT_BOUND_PERFORMANCE04_READY_NOT_PARSED_NOT_RUN',
    'ready': True,
    'script': {'path': key_path, 'sha256': sha(key)},
    'fixture': {'path': fixture_path, 'sha256': fixture_sha, 'expected_city_sources': 1221, 'source_guard': 1244},
    'pending_parent': {'script': {'path': pending_key, 'sha256': pending_key_sha}, 'fixture': {'path': pending_fixture, 'sha256': pending_fixture_sha}, 'handoff': {'path': pending_handoff, 'sha256': pending_handoff_sha}},
    'actual_Root_deployment_guard': {'path': guard_path, 'sha256': guard_sha},
    'actual_Root_deployment_copy': {'path': actual_path, 'sha256': actual_sha},
    'mechanical_key_hunks_only': hunks,
    'whole_pending_key_byte_inverse': back == kb,
    'whole_fixture_serialized_inverse_to_fixed_pending_bytes': js(inverse) == fb,
    'whole_2EDD_parent_key_byte_inverse': pending_inverse == parent,
    'expected_1221_city_and_other_1242_guard_values_unchanged': True,
    'only_two_real_deployment_source_leaves_added': True,
    'output_path_retained_from_unrun_pending_key': True,
    'original_cadence_60s_zeroINPUT_picture_geometry_collector_behavior_unchanged': True,
    'DT_getter_once_after_frozen_draw_and_natural_owner_only': True,
    'stage_engine_parse_collector_public_request_executions': 0,
    'performance_or_runtime_pass_claim': False,
    'copy_outer_stale_LASTEXITCODE_throw_not_copy_failure': 'Root actual copy all26_exact true and independent final guard passed; no copy rerun.',
    'diffs': {n: {'path': O + n, 'sha256': sha(v)} for n, v in files.items() if n.endswith('.diff')},
    'Root_only_command_not_executed': 'godot --path F:/Code/RPG_GAME/game --script ' + key_path,
}
files['handoff_ROOT18_READY_NOT_RUN.json'] = js(handoff)
assert not path(O).exists(), 'NEW_OUTPUT_REQUIRED'
path(O).mkdir()
for n, b in files.items(): (path(O) / n).write_bytes(b)
assert fixed(pending_key, pending_key_sha) == kb and fixed(pending_fixture, pending_fixture_sha) == fb and fixed(pending_handoff, pending_handoff_sha) == hb
print(json.dumps({n: sha(v) for n, v in files.items()}, indent=2))
