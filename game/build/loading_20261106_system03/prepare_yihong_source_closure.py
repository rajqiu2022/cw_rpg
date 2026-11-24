"""Offline bounded Yihong successor. Stage candidates only; never writes live files."""
import base64
import copy
import difflib
import hashlib
import json
import re
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
KEEPLIVE = BASE / 'keepalive_prefix_REVIEW02'
PROOF = BASE / 'formal_residual02/actual/37116/result.json'
REGION_ROOT = 'game/build/luoyang_regions_20261027d_source01/'
MANIFEST = REGION_ROOT + 'region_runtime_manifest_BUILD.json'
FIELD = REGION_ROOT + 'region_field.gd'
ENTRY = REGION_ROOT + 'region_entry.gd'
ROOM_ROOT = 'game/build/interior_identity_20261107_runtime01/'
HELPERS = (ROOM_ROOT + 'room_runtime.gd', ROOM_ROOT + 'native_actor.gd', ROOM_ROOT + 'native_actor.tscn')
SEAT_HELPER = 'game/build/luoyang_quality_20261101b_seated01/live_seated_view.gd'
PAYLOAD = ROOM_ROOT + 'yihongyuan27n_interior.bin'
EX = 'game/data/maps/luoyang_full_city_20261022ap/execution_successor.json'
EX_IDX = 'game/scripts/city/luoyang_execution_index_20261022ap.gd'
AUTHORITY = 'game/scripts/city/luoyang_execution_authority_20261022ap.gd'
CULTURE_CONTRACT = 'game/data/luoyang_culture_integration_20261019x/runtime_contract.json'
ROUTER = 'game/scripts/autoload/scene_router.gd'
GATE = 'game/data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'
SNAP = 'res://build/luoyang_yihong_identity_20261107_source01/scene_router.gd.snapshot.txt'
FIXED_BEFORE = {MANIFEST: '91533bb8714a613eb6534657e71a650f6d519b1fa73dd1d33ff9907dc28ddec5', FIELD: 'fdb375d92f1590be44288708bc697f2cb780e81584557027c5396508f73de5e5', ENTRY: 'e35cd056033a89c86a7486c48298ec61d6c828fc884a7741b5d505ee34517e92'}
ROOM_ID = 'yihongyuan27n_interior'
MAP_KEYS = {'source_sha256', 'legacy_source_sha256', 'runtime_authority_sha256', 'source_pins'}
sha = lambda data: hashlib.sha256(data).hexdigest()
enc = lambda obj: (json.dumps(obj, ensure_ascii=False, indent=2) + '\n').encode()


def fail(ok, label, *data):
    if not ok:
        raise ValueError(label, *data)


def root_path(path, sub='game'):
    fail(isinstance(path, str) and '/' in path and not any(p in {'.', '..'} for p in path.split('/')) and '\\' not in path, 'PATH_DOMAIN', path)
    root = (ROOT / sub).resolve()
    target = (ROOT / path).resolve()
    fail(target.is_relative_to(root) and all(p.lower() not in {'app_userdata', 'save', 'saves', 'appdata', 'localappdata'} for p in target.parts) and not re.fullmatch(r'save_\d+\.json(?:\.bak|\.tmp)?', target.name, re.I), 'OUTSIDE_GAME_OR_SAVE', path)
    return target


def res(path):
    fail(path.startswith('game/'), 'GAME_PATH', path)
    return 'res://' + path[5:]


def rel(path):
    fail(path.startswith('res://'), 'RESOURCE_PATH', path)
    return 'game/' + path[6:]


def read(path):
    return root_path(path).read_bytes()


def once(blob, old, new):
    old = old.encode() if isinstance(old, str) else old
    new = new.encode() if isinstance(new, str) else new
    fail(blob.count(old) == 1, 'ONE_LITERAL', old[:170], blob.count(old))
    return blob.replace(old, new, 1)


def replace_dict_row(blob, key, obj, indent):
    t = blob.decode()
    marker = ' ' * indent + json.dumps(key) + ': {'
    matches = list(re.finditer(r'^' + re.escape(marker), t, flags=re.M))
    fail(len(matches) == 1, 'ONE_JSON_ROW', key)
    at = matches[0].end() - 1
    _, size = json.JSONDecoder().raw_decode(t[at:])
    lines = json.dumps(obj, ensure_ascii=False, indent=2).splitlines()
    content = lines[0] + ''.join('\n' + ' ' * indent + line for line in lines[1:])
    return (t[:at] + content + t[at + size:]).encode()


def append_map_pins(blob, key, pins):
    s = blob.decode()
    marker = '  ' + json.dumps(key) + ': {'
    matches = list(re.finditer(r'^' + re.escape(marker), s, flags=re.M))
    fail(len(matches) == 1 and bool(pins), 'ONE_JSON_MAP', key)
    at = matches[0].end() - 1
    _, size = json.JSONDecoder().raw_decode(s[at:])
    end = at + size - 1
    fail(s[end-3:end] == '\n  ', 'MAP_SPACING', key)
    insert = ''.join(',\n    ' + json.dumps(p) + ': ' + json.dumps(h) for p, h in pins.items())
    return (s[:end-3] + insert + s[end-3:]).encode()


def change_source_maps(blob, pins):
    expected = json.loads(blob)

    def walk(obj):
        nonlocal blob
        if isinstance(obj, dict):
            for k, v in obj.items():
                if k in MAP_KEYS and isinstance(v, dict):
                    for path in v.keys() & pins.keys():
                        old, new = pins[path]
                        if v[path] == old and old != new:
                            p = json.dumps(path) + ': '
                            blob = once(blob, p + json.dumps(old), p + json.dumps(new))
                            v[path] = new
                else:
                    walk(v)
        elif isinstance(obj, list):
            for row in obj:
                walk(row)

    walk(expected)
    fail(json.loads(blob) == expected, 'ONLY_SOURCE_MAP_VALUES')
    return blob


def diff(old, new):
    a, b = old.splitlines(keepends=True), new.splitlines(keepends=True)
    hunks = []
    for op, i, j, k, l in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes():
        if op != 'equal':
            hunks.append({'new_offset': sum(map(len, b[:k])), 'old': b''.join(a[i:j]).decode(), 'new': b''.join(b[k:l]).decode()})
    inverse = new
    for h in reversed(hunks):
        at, old_span, new_span = h['new_offset'], h['old'].encode(), h['new'].encode()
        fail(inverse[at:at+len(new_span)] == new_span, 'INVERSE_SLICE')
        inverse = inverse[:at] + old_span + inverse[at+len(new_span):]
    fail(inverse == old, 'WHOLE_INVERSE')
    return hunks


def base_pins():
    keep = (KEEPLIVE / 'receipt.json').read_bytes()
    fail(sha(keep) == '7bd95874f7a1108524dbe2648fc8488fc9b6be31d42e69d2fd4fa833508cafc3', 'KEEPALIVE_APPROVAL_CHANGED')
    keep = json.loads(keep)
    scope = {r['target']: r['after_sha256'] for r in keep['targets']} | FIXED_BEFORE
    before = {p: read(p) for p in scope}
    for p, h in scope.items():
        fail(sha(before[p]) == h, 'FRESH_BASELINE_DRIFT', p)
    region = json.loads(before[MANIFEST])
    for name, binding in region['compiled_bindings'].items():
        payload = read(rel(binding['path']))
        fail(sha(payload) == binding['sha256'] and len(payload) == int(binding['bytes']), 'EXISTING_REGION_BIN_DRIFT', name)
        fail(not any(FIXED_BEFORE[p].encode() in payload for p in FIXED_BEFORE), 'EXISTING_REGION_BIN_PINS_CHANGED_SHARED_SOURCE', name)
    author = json.loads(read(rel(region['author']['path'])))
    for name, binding in author['terminal_bindings'].items():
        payload = read(rel(binding['path']))
        fail(sha(payload) == binding['sha256'] and len(payload) == int(binding['bytes']), 'EXISTING_TERMINAL_BIN_DRIFT', name)
        fail(not any(FIXED_BEFORE[p].encode() in payload for p in FIXED_BEFORE), 'EXISTING_TERMINAL_BIN_PINS_CHANGED_SHARED_SOURCE', name)
    return keep, scope, before, region


keep, scope, before, region = base_pins()
if sys.argv[1:] == ['--baseline-only']:
    print(json.dumps({'baseline_sources': len(scope), 'compiled_bindings_checked': len(region['compiled_bindings']), 'existing_modules': len(region['runtime_modules']), 'scope': 'No candidate files written; no engine or real-save reads.'}))
    raise SystemExit(0)
fail(len(sys.argv) == 5 and (sys.argv[4] == '--dry-run' or re.fullmatch(r'(?i)yihong_source_REVIEW\d+', sys.argv[4])), 'USAGE', 'prepare_yihong_source_closure.py game/build/.../stage_core.json game/build/.../candidate.bin bin_sha256 yihong_source_REVIEW01')
input_file = root_path(sys.argv[1], 'game/build')
input_bytes = input_file.read_bytes()
inputs = json.loads(input_bytes)
fail(set(inputs) == {ENTRY, FIELD, *HELPERS, SEAT_HELPER}, 'EXACT_CORE_STAGE_TARGETS')
del inputs[SEAT_HELPER]  # Separate 31b owner; intentionally not in Region manifest.
inputs[PAYLOAD] = {'candidate': sys.argv[2], 'sha256': sys.argv[3]}
dry_run = sys.argv[4] == '--dry-run'
if not dry_run:
    fail('publish_candidate_actual' not in sys.argv[2] and 'preview_actual' not in sys.argv[2], 'NO_INERT_PREVIEW_BIN_IN_FORMAL_PLAN')
assets = {}
for target, row in inputs.items():
    candidate = root_path(row['candidate'], 'game/build')
    fail(candidate != root_path(target) and not candidate.samefile(input_file), 'DISTINCT_STAGE', target)
    assets[target] = candidate.read_bytes()
    fail(sha(assets[target]) == row['sha256'], 'CANDIDATE_INPUT_DRIFT', target)
for p in (*HELPERS, PAYLOAD, rel(SNAP)):
    fail(not root_path(p).exists(), 'NEW_LEAF_ALREADY_EXISTS', p)

out = BASE / sys.argv[4]
fail(dry_run or not out.exists(), 'IMMUTABLE_OUTPUT_EXISTS', out)
after = {}
after[MANIFEST] = before[MANIFEST]
expected_region = copy.deepcopy(region)
new_binding = {'bytes': len(assets[PAYLOAD]), 'path': res(PAYLOAD), 'sha256': sha(assets[PAYLOAD])}
after[MANIFEST] = replace_dict_row(after[MANIFEST], ROOM_ID, new_binding, 4)
expected_region['compiled_bindings'][ROOM_ID] = new_binding
for p in (FIELD, ENTRY):
    fail(expected_region['runtime_modules'][res(p)] == scope[p], 'REGION_MODULE_PREIMAGE', p)
    expected_region['runtime_modules'][res(p)] = sha(assets[p])
    prefix = json.dumps(res(p)) + ': '
    after[MANIFEST] = once(after[MANIFEST], prefix + json.dumps(scope[p]), prefix + json.dumps(sha(assets[p])))
new_helpers = {res(p): sha(assets[p]) for p in HELPERS}
expected_region['runtime_modules'].update(new_helpers)
after[MANIFEST] = append_map_pins(after[MANIFEST], 'runtime_modules', new_helpers)
fail(json.loads(after[MANIFEST]) == expected_region, 'ONE_ROOM_AND_FIVE_EXACT_MODULE_KEYS_ONLY')

old_line = 'const REGION27D_AUTHOR_SHA := "' + scope[MANIFEST] + '"'
new_line = 'const REGION27D_AUTHOR_SHA := "' + sha(after[MANIFEST]) + '"'
after[ROUTER] = once(before[ROUTER], old_line, new_line)
prior = keep['leaf']['new']
fail(sha(read(rel(prior))) == scope[ROUTER], 'LAST_APPROVED_SNAPSHOT_DRIFT')
fail(SNAP.startswith('res://build/luoyang_'), 'EXEC_NEW_LEAF_PREFIX')
known = {res(p): (scope[p], sha(data)) for p, data in (after | {p: assets[p] for p in (FIELD, ENTRY)}).items()}
auth_base = json.loads(before[EX])
router = res(ROUTER)
auth_row = copy.deepcopy(auth_base['owned'][router])
fail(auth_row['current_sha256'] == scope[ROUTER] and auth_base['source_sha256'][prior] == scope[ROUTER], 'EXEC_CURRENT_ROUTER_PARENT')
auth_row['current_sha256'] = sha(after[ROUTER])
auth_row['edges'].append({'path': router, 'old_sha256': scope[ROUTER], 'new_sha256': sha(after[ROUTER]), 'old_snapshot': prior, 'new_snapshot': SNAP, 'whole_inverse': True, 'replacements': [{'old': old_line, 'new': new_line}]})
after[EX] = replace_dict_row(before[EX], router, auth_row, 4)
after[EX] = change_source_maps(after[EX], known)
after[EX] = append_map_pins(after[EX], 'source_sha256', {SNAP: sha(after[ROUTER])})
actual_auth = json.loads(after[EX])
fail(actual_auth['owned'] == auth_base['owned'] | {router: auth_row}, 'PRESERVE_ALL_OTHER_OWNED')
fail(once(after[ROUTER], new_line, old_line) == read(rel(prior)), 'EX_ACTUAL_INVERSE')
fail(read(AUTHORITY).count(b'not next_path.begins_with("res://build/luoyang_")') == 1, 'RUNTIME_PREFIX_GUARD_CHANGED')
fail(sha(read(CULTURE_CONTRACT)) == 'deadf17e6f2d8a8362725c4ee78d23f8713364e38d2da5f1a9af77d713bd609e', 'CULTURE_CONTRACT_DRIFT')
known[res(EX)] = (scope[EX], sha(after[EX]))
after[EX_IDX] = once(before[EX_IDX], scope[EX], sha(after[EX]))
known[res(EX_IDX)] = (scope[EX_IDX], sha(after[EX_IDX]))

pending = [r['target'] for r in keep['targets'] if r['target'] not in after]
snapshot_bound = []
while pending:
    start_count = len(pending)
    for p in list(pending):
        if any(q != p and scope[q].encode() in before[p] for q in pending):
            continue
        data = before[p]
        if p.endswith('.json'):
            data = change_source_maps(data, known)
            obj = json.loads(data)
            keys = [k for k in ('source_sha256', 'legacy_source_sha256') if prior in obj.get(k, {})]
            fail(len(keys) <= 1, 'ONE_OLD_SNAPSHOT_COLLECTION', p)
            if keys:
                data = append_map_pins(data, keys[0], {SNAP: sha(after[ROUTER])})
                obj[keys[0]][SNAP] = sha(after[ROUTER])
                fail(json.loads(data) == obj, 'ONLY_ONE_APPENDED_SNAPSHOT', p)
                snapshot_bound.append(p)
        else:
            for path, (old, new) in known.items():
                if old.encode() in data:
                    data = once(data, old, new)
        fail(data != before[p], 'MANDATORY_PREVIOUS_SCOPE_CHANGE_NOT_PROPAGATED', p)
        after[p] = data
        known[res(p)] = (scope[p], sha(data))
        pending.remove(p)
    fail(len(pending) < start_count, 'SOURCE_CLOSURE_DEPENDENCY_CYCLE', pending)
fail(set(after) == {r['target'] for r in keep['targets']} | {MANIFEST}, 'EXACT_24_SOLVER_TARGETS')

proof_data = PROOF.read_bytes()
fail(sha(proof_data) == '22dd15f77926563c5642c30a499be330c22169d95f2c93edf5e29de782d4a4fd', 'GATE_ACTUAL37116_DRIFT')
gate_proof = json.loads(proof_data)['gate_source_admission']
actual_gate = gate_proof['actual_sources']
fail(gate_proof['passed'] and actual_gate == gate_proof['expected_sources'] and len(actual_gate) == 1757, 'GATE_ACTUAL_BASELINE_NOT_ACCEPTED')
old_gate = json.loads(before[GATE]); new_gate = json.loads(after[GATE])
def pins(g):
    return g['artifacts'] | g['runtime_authority_sha256'] | g['legacy_source_sha256']


overlay = after | assets | {rel(SNAP): after[ROUTER]}
def overlay_sha(path):
    return sha(overlay[path]) if path in overlay else sha(read(path))


dynamic = actual_gate.keys() - pins(old_gate).keys()
fail(len(dynamic) == 8 and res(GATE) in dynamic, 'ACTUAL_GATE_7_DYNAMIC_INDICES_AND_MANIFEST', dynamic)
expected_gate = pins(new_gate) | {path: overlay_sha(rel(path)) for path in dynamic}
predicted_gate = {path: sha(overlay[rel(path)]) if rel(path) in overlay else pin for path, pin in actual_gate.items()} | {SNAP: sha(after[ROUTER])}
fail(expected_gate == predicted_gate and len(expected_gate) == 1758, 'EXACT_GATE_PREDICTED_COLLECTOR_SET', sorted(expected_gate.keys() ^ predicted_gate.keys()), sorted(p for p in expected_gate.keys() & predicted_gate.keys() if expected_gate[p] != predicted_gate[p]))
with ThreadPoolExecutor(max_workers=4) as pool:
    checked = list(pool.map(lambda item: (item[0], item[1], overlay_sha(rel(item[0]))), expected_gate.items()))
gate_diff = [(p, h, actual) for p, h, actual in checked if h != actual]
fail(not gate_diff, 'GATE_CURRENT_DISK_OR_OVERLAY_DIFF', gate_diff)

for p, data in before.items():
    fail(read(p) == data, 'LATE_SOURCE_DRIFT_STOP', p)
if dry_run:
    for p, data in after.items():
        diff(before[p], data)
    print(json.dumps({'status': 'MECHANICAL_DRY_RUN_NO_WRITES_NOT_AN_ADOPTION_PLAN', 'count': len(after), 'gate_predicted_count': len(expected_gate), 'gate_existing_delta': sorted(p for p in actual_gate if actual_gate[p] != expected_gate[p]), 'gate_added': SNAP}))
    raise SystemExit(0)
output_rows = []
out.mkdir()
(out / '.gdignore').touch()
for p, data in after.items():
    path = out / p.replace('/', '__')
    path.write_bytes(data)
    output_rows.append({'target': p, 'candidate': path.relative_to(ROOT).as_posix(), 'before_sha256': scope[p], 'after_sha256': sha(data), 'whole_inverse': diff(before[p], data)})
(out / 'scene_router.gd.snapshot.txt').write_bytes(after[ROUTER])
(out / 'original_bytes.json').write_bytes(enc({p: base64.b64encode(before[p]).decode() for p in after}))
receipt = {
    'status': 'STAGED_EXACT_24_NO_CANONICAL_WRITES',
    'targets': output_rows,
    'router_snapshot': {'path': SNAP, 'sha256': sha(after[ROUTER])},
    'snapshot_appended_to': [EX, *snapshot_bound],
    'input_file': input_file.relative_to(ROOT).as_posix(),
    'input_file_sha256': sha(input_bytes),
    'inputs_owned_by_room_agent': inputs,
    'region_binding': new_binding,
    'region_manifest_sha256': sha(after[MANIFEST]),
    'gate_offline': {'actual_baseline_pid': 37116, 'actual_baseline_count': len(actual_gate), 'predicted_count': len(expected_gate), 'changed_existing_pins': sorted(p for p in actual_gate if expected_gate[p] != actual_gate[p]), 'added_only': SNAP, 'real_collector_must_recheck': True},
    'non_yihong_bin_republished': 0,
    'real_save_content_access': 0,
    'engine_runs': 0,
}
(out / 'receipt.json').write_bytes(enc(receipt))
print(json.dumps({'status': receipt['status'], 'receipt_sha256': sha(enc(receipt)), 'region_manifest_sha256': sha(after[MANIFEST]), 'gate_offline': receipt['gate_offline']}))
