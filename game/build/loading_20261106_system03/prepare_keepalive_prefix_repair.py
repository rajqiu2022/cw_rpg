"""Prepare precise Culture snapshot-prefix correction; never writes canonical files."""
import base64
import copy
import difflib
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OLD = BASE / 'keepalive_closure_READY01'
OUT = BASE / 'keepalive_prefix_REVIEW02'
EX = 'game/data/maps/luoyang_full_city_20261022ap/execution_successor.json'
ROUTER = 'game/scripts/autoload/scene_router.gd'
CULTURE = ROOT / 'game/data/luoyang_culture_integration_20261019x/runtime_contract.json'
NEW_LEAF = 'res://build/luoyang_loading_keepalive_20261107_source01/scene_router.gd.snapshot.txt'


def sha(data):
    return hashlib.sha256(data).hexdigest()


def enc(data):
    return (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode('utf-8')


def read_json(path):
    return json.loads(path.read_bytes())


def as_game_path(path):
    assert path.startswith('res://') and '..' not in path
    return 'game/' + path[6:]


def whole_inverse(old, new):
    a = old.splitlines(keepends=True)
    b = new.splitlines(keepends=True)
    hunks = []
    for tag, i, j, k, l in difflib.SequenceMatcher(None, a, b, autojunk=False).get_opcodes():
        if tag != 'equal':
            hunks.append({'new_offset': sum(map(len, b[:k])), 'old': b''.join(a[i:j]).decode(), 'new': b''.join(b[k:l]).decode()})
    reverted = new
    for h in reversed(hunks):
        pos = h['new_offset']
        old_span = h['old'].encode()
        new_span = h['new'].encode()
        assert reverted[pos:pos + len(new_span)] == new_span
        reverted = reverted[:pos] + old_span + reverted[pos + len(new_span):]
    assert reverted == old
    return hunks


receipt_bytes = (OLD / 'receipt.json').read_bytes()
assert sha(receipt_bytes) == '3446e13005849054dfd674a13038a7b553ecaf05dd9239d212458c99421bf729'
receipt = json.loads(receipt_bytes)
previous_leaf = receipt['new_runtime_leaf']['path']
leaf_data = (ROOT / as_game_path(previous_leaf)).read_bytes()
assert sha(leaf_data) == receipt['new_runtime_leaf']['sha256']
assert NEW_LEAF.startswith('res://build/luoyang_') and not (ROOT / as_game_path(NEW_LEAF)).exists()
targets = {r['target']: r for r in receipt['targets']}
originals = read_json(OLD / 'original_bytes.json')
before = {}
rejected = {}
rollback = {}
for path, row in targets.items():
    content = (ROOT / path).read_bytes()
    rejected_data = (ROOT / row['candidate']).read_bytes()
    assert sha(rejected_data) == row['new_sha256'], ('REJECTED_EVIDENCE_DRIFT', path)
    original = originals['res://' + path[5:]]
    old_bytes = base64.b64decode(original['base64'], validate=True)
    assert sha(old_bytes) == original['sha256'] == row['old_sha256']
    assert content == old_bytes, ('CURRENT_DRIFT', path)
    before[path] = content
    rejected[path] = rejected_data
    rollback[path] = {'rejected_sha256': sha(rejected_data), 'restored_sha256': sha(old_bytes), 'bytes': len(old_bytes)}

deps = {p: {q for q, r in targets.items() if q != p and r['new_sha256'].encode() in rejected[p]} for p in targets}
pending = list(targets)
changed = {}
for _ in range(len(targets)):
    if not pending:
        break
    progressed = False
    for path in list(pending):
        if any(q in pending for q in deps[path]):
            continue
        data = rejected[path]
        if previous_leaf.encode() in data:
            assert path.endswith('.json'), ('NON_JSON_LEAF_REF', path)
            assert data.count(previous_leaf.encode()) == (2 if path == EX else 1), ('UNEXPECTED_LEAF_REFS', path)
            data = data.replace(previous_leaf.encode(), NEW_LEAF.encode())
        for dep in sorted(deps[path]):
            if dep in changed:
                data = data.replace(targets[dep]['new_sha256'].encode(), sha(changed[dep]).encode())
        if data != rejected[path]:
            changed[path] = data
        pending.remove(path)
        progressed = True
    assert progressed, ('DEPENDENCY_CYCLE', pending)
assert EX in changed and ROUTER not in changed

old_auth = json.loads(rejected[EX])
auth = json.loads(changed[EX])
router = 'res://scripts/autoload/scene_router.gd'
old_auth['owned'][router]['edges'][-1]['new_snapshot'] = NEW_LEAF
old_auth['source_sha256'][NEW_LEAF] = old_auth['source_sha256'].pop(previous_leaf)
assert old_auth == auth, 'EX_ONLY_RELOCATE_EXISTING_LEAF'
assert auth['source_sha256'][NEW_LEAF] == sha(leaf_data)
historical = read_json(CULTURE)['source_sha256'][router]
current = auth['owned'][router]['current_sha256']
edges = auth['owned'][router]['edges']
frontier, visited = [current], set()
checked_edges = 0
accepted = False
for _ in range(len(edges)):
    nxt = []
    for head in frontier:
        if head in visited:
            continue
        visited.add(head)
        for e in edges:
            if e['new_sha256'] != head:
                continue
            a, b = e['old_snapshot'], e['new_snapshot']
            assert e['path'] == router and e['whole_inverse'] is True and a != router
            assert b == router or b.startswith('res://build/luoyang_')
            assert auth['source_sha256'][a] == e['old_sha256']
            assert b == router or auth['source_sha256'][b] == head
            old_data = (ROOT / as_game_path(a)).read_bytes()
            new_data = leaf_data if b in (NEW_LEAF, router) and head == current else (ROOT / as_game_path(b)).read_bytes()
            assert sha(old_data) == e['old_sha256'] and sha(new_data) == head
            inverse = new_data
            for row in e['replacements']:
                n, o = row['new'].encode(), row['old'].encode()
                assert n != o and n and inverse.count(n) == 1
                inverse = inverse.replace(n, o, 1)
            assert inverse == old_data
            if 'navigation_source' in e:
                nav = e['navigation_source'].encode()
                assert nav and new_data.count(nav) == old_data.count(nav) == 1
            checked_edges += 1
            if e['old_sha256'] == historical:
                accepted = True
                break
            nxt.append(e['old_sha256'])
        if accepted:
            break
    if accepted:
        break
    frontier = nxt
assert accepted, 'CULTURE_ROUTER_HISTORICAL_SHA_NOT_REACHABLE'

full = rejected | changed
assert all(data != before[path] for path, data in full.items())
hunks = {p: whole_inverse(before[p], new) for p, new in full.items()}
assert all((ROOT / p).read_bytes() == data for p, data in before.items())
assert not OUT.exists()
OUT.mkdir()
(OUT / '.gdignore').touch()
(OUT / 'scene_router.gd.snapshot.txt').write_bytes(leaf_data)
rows = []
for path, data in full.items():
    candidate = OUT / path.replace('/', '__')
    candidate.write_bytes(data)
    rows.append({'target': path, 'candidate': candidate.relative_to(ROOT).as_posix(), 'before_sha256': sha(before[path]), 'after_sha256': sha(data), 'inverse': hunks[path]})
report = {'status': 'PROPOSAL_ONLY_NO_CANONICAL_WRITES', 'targets': rows, 'leaf': {'old': previous_leaf, 'new': NEW_LEAF, 'sha256': sha(leaf_data)}, 'culture_historical_sha256': historical, 'culture_router_offline_checked_edges': checked_edges, 'changed_vs_rejected_install': list(changed), 'rejected_install_rollback': rollback}
(OUT / 'receipt.json').write_bytes(enc(report))
print(json.dumps({'count': len(rows), 'offline_culture_edges': checked_edges, 'receipt_sha256': sha(enc(report)), 'paths': list(changed)}))
