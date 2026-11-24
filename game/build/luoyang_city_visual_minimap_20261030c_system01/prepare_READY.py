"""30c candidates only; reuse 30b's bounded source-pin consumer set.
No engine, PNG, canonical, save or geometry writes. All old edges/keys stay.
"""
from pathlib import Path
import hashlib, json, copy, difflib, re, sys
BASE = Path(__file__).resolve().parent
GAME = BASE.parents[1]
OUT = BASE / (sys.argv[1] if len(sys.argv) > 1 else 'ready01')
assert OUT.parent == BASE and OUT.name.startswith('ready')
ROOT = 'res://' + BASE.relative_to(GAME).as_posix() + '/'
PREFIX = ROOT + OUT.name + '/'
def sha(b): return hashlib.sha256(b).hexdigest()
def read(p): return (GAME / p[6:]).read_bytes()
def enc(v): return (json.dumps(v, ensure_ascii=False, indent=2) + '\n').encode()
def once(b, old, new):
    old = old.encode() if isinstance(old, str) else old
    new = new.encode() if isinstance(new, str) else new
    assert b.count(old) == 1, (old[:100], b.count(old))
    return b.replace(old, new, 1)
def edit(b, changes):
    result = b
    for old, new in changes: result = once(result, old, new)
    inverse = result
    for old, new in reversed(changes): inverse = once(inverse, new, old)
    assert inverse == b
    return result
def hunks(a, b):
    aa = a.decode().splitlines(keepends=True); bb = b.decode().splitlines(keepends=True)
    for n in [3, 6, 12, 24, 48]:
        result = [{'old': ''.join(aa[g[0][1]:g[-1][2]]), 'new': ''.join(bb[g[0][3]:g[-1][4]])} for g in difflib.SequenceMatcher(None, aa, bb, autojunk=False).get_grouped_opcodes(n)]
        if all(a.count(r['old'].encode()) == 1 and b.count(r['new'].encode()) == 1 for r in result):
            assert edit(a, [(r['old'], r['new']) for r in result]) == b
            return result
    raise ValueError('nonunique hunk')
def create(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('xb') as f: f.write(data)
assert not OUT.exists()
prior = json.loads(read('res://build/luoyang_garden_city_minimap_20261030b_system01/residual04/closure_READY/receipt_READY.json'))
helper = 'res://build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd'
manifest = 'res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json'
router = 'res://scripts/autoload/scene_router.gd'
ex = 'res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
ei = 'res://scripts/city/luoyang_execution_index_20261022ap.gd'
paths = ['res://' + r['target'][5:] for r in prior['targets']]
assert len(paths) == 23
for r in prior['targets']: assert sha((GAME.parent / r['target']).read_bytes()) == r['new_sha256'], r['target']
before = {p: read(p) for p in paths}; oldsha = {p: sha(b) for p, b in before.items()}
assert oldsha[router].startswith('72ef168f') and oldsha[manifest].startswith('f745b2aa')
old_helper = read(helper); new_helper = (BASE / 'city_minimap_READY.gd').read_bytes()
assert sha(old_helper).startswith('841b8dc8')
snapshot_path = BASE / 'legacy_marker_layout_snapshot.gd'
if snapshot_path.exists(): assert snapshot_path.read_bytes() == old_helper
else: create(snapshot_path, old_helper)
new_modules = {ROOT + name: sha(read(ROOT + name)) for name in ['legacy_marker_layout_snapshot.gd', 'visual_cache.gd']}
old_pin = json.dumps(helper) + ': ' + json.dumps(sha(old_helper))
new_pin = json.dumps(helper) + ': ' + json.dumps(sha(new_helper))
new_manifest = edit(before[manifest], [(old_pin, new_pin)])
value = json.loads(new_manifest)
assert not any(p in value['runtime_modules'] for p in new_modules)
text = new_manifest.decode(); start = text.index('  "runtime_modules": {'); end = text.index('\n  }', start)
text = text[:end] + ''.join(',\n    ' + json.dumps(p) + ': ' + json.dumps(h) for p, h in new_modules.items()) + text[end:]
after = {manifest: text.encode()}
old_header = re.search(rb'const REGION27D_AUTHOR_SHA := "[a-f0-9]{64}"', before[router]).group(0)
new_header = b'const REGION27D_AUTHOR_SHA := "' + sha(after[manifest]).encode() + b'"'
after[router] = edit(before[router], [(old_header, new_header)])
old_ex = json.loads(before[ex]); old_row = old_ex['owned'][router]
assert old_row['current_sha256'] == oldsha[router]
old_snapshot = old_row['edges'][-1]['new_snapshot']; assert read(old_snapshot) == before[router]
snapshot = PREFIX + 'scene_router.gd'
row = copy.deepcopy(old_row); row['current_sha256'] = sha(after[router])
row['edges'].append({'path': router, 'old_sha256': oldsha[router], 'new_sha256': sha(after[router]), 'old_snapshot': old_snapshot, 'new_snapshot': snapshot, 'whole_inverse': True, 'replacements': hunks(before[router], after[router])})
text = before[ex].decode(); marker = '    ' + json.dumps(router) + ': '
start = text.index(marker) + len(marker); _, used = json.JSONDecoder().raw_decode(text[start:])
replacement = json.dumps(row, ensure_ascii=False, indent=2).replace('\n', '\n    ')
text = text[:start] + replacement + text[start + used:]
text = edit(text.encode(), [(old_pin, new_pin)]).decode()
start = text.index('  "source_sha256": {'); end = text.index('\n  }', start)
assert snapshot not in old_ex['source_sha256']
text = text[:end] + ',\n    ' + json.dumps(snapshot) + ': ' + json.dumps(sha(after[router])) + text[end:]
after[ex] = text.encode(); current = json.loads(after[ex])
assert current['owned'][router]['edges'][:-1] == old_row['edges']
assert all(current['source_sha256'][p] == h for p, h in old_ex['source_sha256'].items() if p != helper)
assert len(current['source_sha256']) == len(old_ex['source_sha256']) + 1
after[ei] = edit(before[ei], [(oldsha[ex], sha(after[ex]))])
def source_update(raw, known):
    value = json.loads(raw); replacements = {}
    def walk(v):
        if isinstance(v, dict):
            for key, member in v.items():
                if key in ['source_sha256', 'legacy_source_sha256'] and isinstance(member, dict):
                    for p, h in member.items():
                        if p == helper:
                            assert h == sha(old_helper); replacements[old_pin] = new_pin
                        elif p in known and h == oldsha.get(p) and h != known[p]:
                            replacements[json.dumps(p) + ': ' + json.dumps(h)] = json.dumps(p) + ': ' + json.dumps(known[p])
                else: walk(member)
        elif isinstance(v, list):
            for item in v: walk(item)
    walk(value); result = raw
    for old, new in replacements.items():
        assert old.encode() in result; result = result.replace(old.encode(), new.encode())
    def keysets(v):
        if isinstance(v, dict): return {k: keysets(m) for k, m in v.items()}
        if isinstance(v, list): return [keysets(m) for m in v]
        return None
    assert keysets(json.loads(result)) == keysets(value)
    return result
known = {p: sha(b) for p, b in after.items()}; pending = [p for p in paths if p not in after]
def dependencies(p): return {q for q, h in oldsha.items() if q != p and h.encode() in before[p]}
for _ in paths:
    progress = False
    for p in list(pending):
        if any(q in pending for q in dependencies(p)): continue
        if p.endswith('.json'): data = source_update(before[p], known)
        else:
            replacements = [(oldsha[q], known[q]) for q in known if known[q] != oldsha[q] and oldsha[q].encode() in before[p]]
            data = edit(before[p], replacements) if replacements else before[p]
        if data != before[p]: after[p] = data; known[p] = sha(data)
        pending.remove(p); progress = True
    if not pending: break
    assert progress, pending
assert not pending and len(after) == 23
assert json.loads(before[manifest])['compiled_bindings'] == json.loads(after[manifest])['compiled_bindings']
OUT.mkdir(); create(OUT / 'before_city_minimap.gd', old_helper)
targets = []; patches = []
for p, data in after.items():
    name = p[6:].replace('/', '__'); create(OUT / name, data)
    targets.append({'target': 'game/' + p[6:], 'candidate': 'game/' + PREFIX[6:] + name, 'old_sha256': oldsha[p], 'new_sha256': sha(data), 'bytes': len(data)})
    if p.endswith('.gd'): patches.append({'target': 'game/' + p[6:], 'replacements': hunks(before[p], data)})
create(OUT / 'scene_router.gd', after[router])
module_target = {'target': 'game/' + helper[6:], 'candidate': str((BASE / 'city_minimap_READY.gd').relative_to(GAME.parent)).replace('\\', '/'), 'old_sha256': sha(old_helper), 'new_sha256': sha(new_helper), 'bytes': len(new_helper), 'replacements': hunks(old_helper, new_helper)}
patches.append({'target': module_target['target'], 'replacements': module_target['replacements']})
receipt = {'status': '30C_REAL_VISUAL_CACHE_CANDIDATES_NOT_ENGINE_VALIDATED', 'targets': targets, 'module_targets': [module_target], 'source_target_count': 23, 'actual_existing_file_count': 24, 'new_runtime_modules': new_modules, 'old_EX_keys_retained': True, 'Router_edges_before': len(old_row['edges']), 'Router_edges_after': len(row['edges']), 'only_new_EX_key': snapshot, 'old_metadata_keysets_unchanged': True, 'all_ten_bins_unchanged': True, 'Field_CT_garden_native_unchanged': True, 'canonical_writes': 0, 'engine_runs': 0}
auth = {'sources': {r['target']: {'sha256': r['new_sha256'], 'bytes': r['bytes']} for r in targets + [module_target]}, 'new_modules': {'game/' + p[6:]: {'sha256': h, 'bytes': len(read(p))} for p, h in new_modules.items()}}
auth['new_modules']['game/' + snapshot[6:]] = {'sha256': sha(after[router]), 'bytes': len(after[router])}
for name, value in [('receipt_READY.json', receipt), ('hunks_READY.json', {'targets': patches}), ('auth_READY.json', auth)]: create(OUT / name, enc(value))
print(json.dumps({'source_targets': 23, 'helper_targets': 1, 'new_runtime_modules': 2, 'helper_sha256': sha(new_helper), 'receipt_sha256': sha(enc(receipt)), 'canonical_writes': 0, 'engine_runs': 0}))
