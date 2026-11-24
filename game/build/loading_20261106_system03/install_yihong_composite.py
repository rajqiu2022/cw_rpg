"""Preflight approved Room + exact source closure; run install only on explicit Root approval."""
import base64
import hashlib
import json
import re
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
SOURCE_PLAN = BASE / 'yihong_source_REVIEW01'
DEPLOY = BASE / 'yihong_composite_DEPLOY01'
SOURCE_PLAN_SHA = '1ec20d03fbd74d594249152ef232765815b9471508ce4708079ebd845cc493bb'
BIN_SHA = '649075ce491953d63013f9f4ca0fe7d6eb3e6451e28980ff5865e451d9c004d9'
FIELD = 'game/build/luoyang_regions_20261027d_source01/region_field.gd'
ENTRY = 'game/build/luoyang_regions_20261027d_source01/region_entry.gd'
ROUTER = 'game/scripts/autoload/scene_router.gd'
SEAT = 'game/build/luoyang_quality_20261101b_seated01/live_seated_view.gd'
QUALITY_ROOT = 'game/build/luoyang_quality_20261101b_runtime01/'
QUALITY = QUALITY_ROOT + 'scene_art_quality_runtime.gd'
QUALITY_PINS = QUALITY_ROOT + 'source_pins_READY.json'
BIN = 'game/build/interior_identity_20261107_runtime01/yihongyuan27n_interior.bin'
MEDIA = 'game/build/interior_identity_20261106_art01/yihong_media_formal_install_receipt.json'
sha = lambda value: hashlib.sha256(value).hexdigest()
enc = lambda obj: (json.dumps(obj, indent=2, ensure_ascii=False) + '\n').encode()


def check(flag, *message):
    if not flag:
        raise ValueError(*message)


def resolve(path, base='game'):
    check(isinstance(path, str) and not any(p in {'.', '..'} for p in path.split('/')) and '\\' not in path, 'PATH_FORM', path)
    full = (ROOT / path).resolve()
    check(full.is_relative_to(ROOT / base) and all(p.lower() not in {'save', 'saves', 'app_userdata', 'appdata', 'localappdata'} for p in full.parts) and not re.fullmatch(r'save_\d+\.json(?:\.bak|\.tmp)?', full.name, re.I), 'OUTSIDE_GAME_OR_SAVE', path)
    return full


def rel(path):
    check(path.startswith('res://'), 'RESOURCE_PATH', path)
    return 'game/' + path[6:]


check(len(sys.argv) == 4 and sys.argv[3] in {'--preflight', '--install'}, 'USAGE', 'install_yihong_composite.py game/build/.../stage_full.json SHA256 --preflight|--install')
mode = sys.argv[3]
stage = resolve(sys.argv[1], 'game/build')
stage_bytes = stage.read_bytes()
check(sha(stage_bytes) == sys.argv[2], 'ROOT_REVIEWED_STAGE_RECEIPT_CHANGED')
room_rows = json.loads(stage_bytes)
source_bytes = (SOURCE_PLAN / 'receipt.json').read_bytes()
check(sha(source_bytes) == SOURCE_PLAN_SHA, 'ROOT_REVIEWED_SOURCE_RECEIPT_CHANGED')
source = json.loads(source_bytes)
source_rows = {r['target']: r for r in source['targets']}
expected_room = set(source['inputs_owned_by_room_agent']) | {SEAT, QUALITY, QUALITY_PINS}
check(set(room_rows) == expected_room, 'EXACT_ROOM_STAGE_TARGETS', sorted(set(room_rows) ^ expected_room))
check(len(source_rows) == 24 and not set(room_rows) & set(source_rows), 'NO_SCOPE_OVERLAP')
check(not DEPLOY.exists(), 'DEPLOY_HISTORY_ALREADY_EXISTS')
media_bytes = resolve(MEDIA).read_bytes()
check(sha(media_bytes) == '78378c1615fed152453e2e98505c0ad24b3f73e0e93b6ce4a382f42f43b3addc', 'ADOPTED_MEDIA_RECEIPT_DRIFT')
media_rows = json.loads(media_bytes)['targets']
check(len(media_rows) == 15, 'EXACT_15_MEDIA')
for row in media_rows:
    path = Path(row['target']).resolve().relative_to(ROOT).as_posix()
    check(sha(resolve(path).read_bytes()) == row['after_sha256'], 'FORMAL_MEDIA_DRIFT', path)

targets = {}
for p, row in source_rows.items():
    candidate = resolve(row['candidate'], 'game/build')
    check(candidate.is_relative_to(SOURCE_PLAN), 'SOURCE_CANDIDATE_DOMAIN', p)
    target = resolve(p)
    old, new = target.read_bytes(), candidate.read_bytes()
    check(sha(old) == row['before_sha256'] and sha(new) == row['after_sha256'], 'SOURCE_CURRENT_OR_CANDIDATE_DRIFT', p)
    inverse = new
    for h in reversed(row['whole_inverse']):
        i, n, o = h['new_offset'], h['new'].encode(), h['old'].encode()
        check(inverse[i:i+len(n)] == n, 'SOURCE_INVERSE_SPAN_DRIFT', p)
        inverse = inverse[:i] + o + inverse[i+len(n):]
    check(inverse == old, 'SOURCE_WHOLE_INVERSE', p)
    targets[p] = (target, old, new)

for p, row in room_rows.items():
    candidate = resolve(row['candidate'], 'game/build')
    target = resolve(p)
    check(candidate != target, 'ROOM_STAGE_IS_LIVE_TARGET', p)
    new = candidate.read_bytes()
    check(sha(new) == row['sha256'], 'ROOM_CANDIDATE_DRIFT', p)
    if p in source['inputs_owned_by_room_agent']:
        bound = source['inputs_owned_by_room_agent'][p]
        check(row['candidate'] == bound['candidate'] and row['sha256'] == bound['sha256'], 'ROOM_BOUND_CANDIDATE_CHANGED', p)
    if row['before_sha256'] is None:
        check(row.get('new_leaf') is True and not target.exists(), 'ROOM_NEW_TARGET_EXISTS', p)
        old = None
    else:
        old = target.read_bytes()
        check(sha(old) == row['before_sha256'], 'ROOM_CURRENT_DRIFT', p)
        if p == QUALITY_PINS:
            check(row.get('whole_json_inverse') is True, 'ROOM_QUALITY_JSON_PROOF')
            old_obj = json.loads(old)
            expected = old_obj
            old_binding = expected['region_bindings']['yihongyuan27n_interior']
            check(expected['source_pins'].pop(old_binding['path']) == old_binding['sha256'], 'OLD_BIN_PIN')
            expected['region_bindings']['yihongyuan27n_interior'] = source['region_binding']
            expected['source_pins'][source['region_binding']['path']] = BIN_SHA
            for k in (FIELD, SEAT, QUALITY):
                check('res://' + k[5:] in expected['source_pins'], 'QUALITY_EXISTING_KEY', k)
                expected['source_pins']['res://' + k[5:]] = room_rows[k]['sha256']
            region_manifest = 'res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
            check(region_manifest in expected['source_pins'], 'QUALITY_EXISTING_MANIFEST')
            expected['source_pins'][region_manifest] = source['region_manifest_sha256']
            check(json.loads(new) == expected, 'ONLY_QUALITY_FIVE_PINS_ONE_BINDING')
        else:
            check(row.get('whole_inverse') is True, 'ROOM_BYTE_PROOF', p)
            # Room offsets are UTF-8 bytes into each sequential preimage.
            rewritten = old
            for h in row['hunks']:
                i, n, o = h['offset'], h['new'].encode(), h['old'].encode()
                check(rewritten[i:i+len(o)] == o, 'ROOM_FORWARD_EXACT_SPAN_DRIFT', p)
                rewritten = rewritten[:i] + n + rewritten[i+len(o):]
            check(rewritten == new, 'ROOM_WHOLE_FORWARD_FAIL', p)
            inverse = new
            for h in reversed(row['hunks']):
                i, n, o = h['offset'], h['new'].encode(), h['old'].encode()
                check(inverse[i:i+len(n)] == n, 'ROOM_INVERSE_EXACT_SPAN_DRIFT', p)
                inverse = inverse[:i] + o + inverse[i+len(n):]
            check(inverse == old, 'ROOM_WHOLE_INVERSE_FAIL', p)
    targets[p] = (target, old, new)

bin_row = source['inputs_owned_by_room_agent'][BIN]
bin_bytes = targets[BIN][2]
check(sha(bin_bytes) == BIN_SHA == bin_row['sha256'] and len(bin_bytes) == 65272, 'EXACT_REBOUND_BIN_DRIFT')
snapshot = source['router_snapshot']
snap_path = rel(snapshot['path'])
snap_bytes = (SOURCE_PLAN / 'scene_router.gd.snapshot.txt').read_bytes()
check(sha(snap_bytes) == snapshot['sha256'] and snap_bytes == targets[ROUTER][2] and snapshot['path'].startswith('res://build/luoyang_'), 'EXACT_ROUTER_SNAPSHOT_DRIFT')
targets[snap_path] = (resolve(snap_path), None, snap_bytes)

existing = {p: target for p, target in targets.items() if target[1] is not None}
new_only = {p: target for p, target in targets.items() if target[1] is None}
check(len(existing) == 29 and len(new_only) == 5, 'COMPOSITE_EXACT_29_EXISTING_5_NEW', len(existing), len(new_only))
for p, (path, old, _) in targets.items():
    check((old is None and not path.exists()) or (old is not None and path.read_bytes() == old), 'LAST_PREFLIGHT_DRIFT', p)

rows = [{'target': p, 'before': sha(old) if old is not None else None, 'after': sha(new), 'bytes': len(new)} for p, (_, old, new) in targets.items()]
if mode == '--preflight':
    print(json.dumps({'status': 'PRECHECK_ONLY_ZERO_CANONICAL_WRITES', 'existing': len(existing), 'new_leaves': len(new_only), 'source_receipt_sha256': SOURCE_PLAN_SHA, 'room_receipt_sha256': sha(stage_bytes), 'targets': rows}))
    raise SystemExit(0)

# Evidence written before first live write. Root owns exclusive launch window.
DEPLOY.mkdir()
(DEPLOY / '.gdignore').touch()
(DEPLOY / 'preimages.json').write_bytes(enc({p: {'sha256': sha(old), 'base64': base64.b64encode(old).decode()} for p, (_, old, _) in existing.items()}))
(DEPLOY / 'ordered_install.json').write_bytes(enc(rows))
room_dir = resolve(BIN).parent
snap_dir = resolve(snap_path).parent
check(not room_dir.exists() and not snap_dir.exists(), 'EXPECTED_NEW_RUNTIME_DIRECTORIES')
room_dir.mkdir()
snap_dir.mkdir()
(snap_dir / '.gdignore').touch()
for p, (path, _, new) in new_only.items():
    with path.open('xb') as handle:
        handle.write(new)
# Activate Router's master manifest pin last; no engine launch in this window.
for p in [key for key in existing if key != ROUTER] + [ROUTER]:
    path, old, new = existing[p]
    check(path.read_bytes() == old, 'LATE_DRIFT_DURING_INSTALL_STOP', p)
    path.write_bytes(new)
for p, (path, _, new) in targets.items():
    check(path.read_bytes() == new, 'FINAL_EXACT_MISMATCH', p)
receipt = {'status': 'EXACT_29_OLD_5_NEW_INSTALLED_AWAITING_FORMAL_QA', 'targets': rows, 'source_receipt_sha256': SOURCE_PLAN_SHA, 'room_receipt_sha256': sha(stage_bytes), 'engine_started': False, 'real_save_content_accessed': False}
(DEPLOY / 'after.json').write_bytes(enc(receipt))
print(json.dumps({'status': receipt['status'], 'existing': len(existing), 'new_leaves': len(new_only), 'receipt_sha256': sha(enc(receipt))}))
