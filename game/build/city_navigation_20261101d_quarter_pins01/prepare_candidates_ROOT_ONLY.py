"""Exact two-target data successors. Generates NEW candidates only; no engine or canonical writes."""
from pathlib import Path
import copy
import hashlib
import json

TASK = Path(__file__).resolve().parent
GAME = TASK.parents[1]
MANIFEST = 'res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
INDEX = 'res://scripts/city/luoyang_quarters_index_20261022ap.gd'
BEFORE = {
    MANIFEST: ('841c9dc0b948326ad249394605a24cf5be6eb5dd2887099e6194a6aee67a9c1e', 218285),
    INDEX: ('ffada93bd159c2f7fd5049219e47d8af9dfe2bb19960db53086a04deea3f9a97', 452),
}
PINS = {
    'res://build/luoyang_regions_20261027d_source01/region_field.gd': (
        '53736563fc853b7a4813c6ad682e91feec877f5a0c9ed224f38ca352cb60efcd',
        'fdb375d92f1590be44288708bc697f2cb780e81584557027c5396508f73de5e5'),
    'res://build/luoyang_regions_20261027d_source01/region_entry.gd': (
        'ed25fb74b5c08e0cb8bbd6a466cd22c820b2f5be3f6b5da917f9789c183cd73d',
        'e35cd056033a89c86a7486c48298ec61d6c828fc884a7741b5d505ee34517e92'),
    'res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json': (
        '749e8d4e3b60f87badc57fd46e21b7122da9804d1f270fe687a2cb5ddde77b3e',
        'af1bb975b0603e2d735890ff89fa60c8e2100ccb0a7565fc1211ca1794d866be'),
}


def need(value, label):
    if not value:
        raise ValueError(label)


def sha(value):
    return hashlib.sha256(value).hexdigest()


def physical(path):
    need(path.startswith('res://') and '..' not in path, ('RES_PATH', path))
    return GAME / path[6:]


def encode(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + '\n').encode('utf-8')


def exact_replace(raw, old, new, reason):
    old, new = old.encode('utf-8'), new.encode('utf-8')
    need(raw.count(old) == 1 and raw.count(new) == 0, ('EXACT_UNIQUE_LITERAL', reason))
    offset = raw.index(old)
    result = raw[:offset] + new + raw[offset + len(old):]
    need(len(old) == len(new), ('FIXED_WIDTH_LITERAL', reason))
    need(result[:offset] + old + result[offset + len(new):] == raw, ('LOCAL_BYTE_INVERSE', reason))
    return result, {'byte_offset': offset, 'old': old.decode(), 'new': new.decode(), 'reason': reason}


def reverse(raw, hunks):
    result = raw
    for hunk in reversed(hunks):
        start = hunk['byte_offset']
        old, new = hunk['old'].encode(), hunk['new'].encode()
        need(result[start:start + len(new)] == new, 'INVERSE_EXPECTED_BYTES')
        result = result[:start] + old + result[start + len(new):]
    return result


original = {path: physical(path).read_bytes() for path in BEFORE}
for path, raw in original.items():
    need((sha(raw), len(raw)) == BEFORE[path], ('ROOT_APPROVED_FRESH_BEFORE', path))
data = json.loads(original[MANIFEST])
need(len(data['source_sha256']) == 1282, 'ORIGINAL_1282_KEYS')
actual = {path: sha(physical(path).read_bytes()) for path in data['source_sha256']}
differences = {path for path, expected in data['source_sha256'].items() if actual[path] != expected}
need(differences == set(PINS), ('EXACT_THREE_ORIGINAL_STALE_PINS', sorted(differences)))
candidate = original[MANIFEST]
manifest_hunks = []
for path, (old, new) in PINS.items():
    need(data['source_sha256'][path] == old and actual[path] == new, ('EXACT_APPROVED_PIN', path))
    candidate, hunk = exact_replace(candidate, '"' + path + '": "' + old + '"',
                                   '"' + path + '": "' + new + '"', 'exact Region source successor: ' + path)
    manifest_hunks.append(hunk)
updated = json.loads(candidate)
inverse_data = copy.deepcopy(updated)
for path, (old, new) in PINS.items():
    need(updated['source_sha256'][path] == new, ('NEW_PIN', path))
    inverse_data['source_sha256'][path] = old
need(inverse_data == data, 'ALL_OTHER_TOP_LEVEL_AND_1279_PIN_VALUES_EXACT')
need(set(updated['source_sha256']) == set(data['source_sha256']), 'EXACT_SOURCE_KEY_SET')
need(all(actual[path] == expected for path, expected in updated['source_sha256'].items()), 'CANDIDATE_ALL_1282_SOURCE_PINS_MATCH')
index_candidate, index_hunk = exact_replace(original[INDEX], 'const MANIFEST_SHA="' + BEFORE[MANIFEST][0] + '"',
                                            'const MANIFEST_SHA="' + sha(candidate) + '"', 'only authority manifest SHA')
outputs = {
    MANIFEST: ('quarters_manifest_CANDIDATE.json', candidate, manifest_hunks),
    INDEX: ('quarters_index_CANDIDATE.gd', index_candidate, [index_hunk]),
}
rows = []
for target, (name, raw, hunks) in outputs.items():
    need(reverse(raw, hunks) == original[target], ('WHOLE_FILE_BYTE_INVERSE', target))
    rows.append({'path': target[6:], 'res_path': target, 'candidate': 'res://' + (TASK / name).relative_to(GAME).as_posix(),
                 'before_sha256': sha(original[target]), 'before_bytes': len(original[target]),
                 'after_sha256': sha(raw), 'after_bytes': len(raw), 'reason': '; '.join(h['reason'] for h in hunks),
                 'whole_file_byte_inverse': True, 'hunks': hunks})
for path in BEFORE:
    need(physical(path).read_bytes() == original[path], ('CANONICAL_UNCHANGED_AT_FINAL', path))
report = {'schema': 'CITY_NAVIGATION_QUARTER_PINS_20261101D_TWO_EXACT_SUCCESSORS_V1',
          'canonical_writes': 0, 'engine_runs': 0, 'save_reads_or_writes': 0, 'owner_validation_bypass': False,
          'original_source_count': 1282, 'source_key_set_identical': True, 'only_three_pin_values_changed': True,
          'other_1279_pin_values_and_all_other_JSON_exact': True, 'original_mismatch_paths': sorted(differences),
          'candidate_all_1282_source_hashes_match': True, 'index_only_MANIFEST_SHA_changed': True,
          'original_native_artifacts_scene_layout_packet_NAV_unchanged': True,
          'runtime_96_leaf_refreeze_required': False, 'targets': rows}
new_files = {name: raw for name, raw, _ in outputs.values()}
new_files['exact_successors_READY.json'] = encode(report)
need(all(not (TASK / name).exists() for name in new_files), 'NO_OUTPUT_OVERWRITE')
for name, raw in new_files.items():
    with (TASK / name).open('xb') as handle:
        handle.write(raw)
print(json.dumps({'passed': True, 'report': str(TASK / 'exact_successors_READY.json'),
                  'targets': [{k: row[k] for k in ('path', 'before_sha256', 'after_sha256', 'before_bytes', 'after_bytes')} for row in rows]}, indent=2))
