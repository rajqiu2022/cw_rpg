"""Read-only exact Gate manifest candidate audit; not actual engine collector admission."""
from concurrent.futures import ThreadPoolExecutor
from hashlib import sha256
import json
from pathlib import Path
import re

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PLAN = BASE / 'keepalive_prefix_REVIEW02'
receipt = json.loads((PLAN / 'receipt.json').read_bytes())
rows = {r['target']: r for r in receipt['targets']}
gate_path = 'game/data/maps/luoyang_layout_bundle_20261018t_retry2/ch4_s0_luoyang_gate/manifest.json'
gate_index = 'game/scripts/city/luoyang_precomputed_bundle_index_20261018r.gd'
ex_path = 'game/data/maps/luoyang_full_city_20261022ap/execution_successor.json'


def overlay(path):
    if path == 'game/' + receipt['leaf']['new'][6:]:
        return PLAN / 'scene_router.gd.snapshot.txt'
    if path in rows:
        return ROOT / rows[path]['candidate']
    return ROOT / path


def load(path):
    return json.loads(path.read_bytes())


def match(item):
    path, pin = item
    assert path.startswith('res://') and '..' not in path and '\\' not in path
    target = overlay('game/' + path[6:]).resolve()
    assert target.is_relative_to(ROOT / 'game') and all(p.lower() not in {'app_userdata', 'save', 'saves', 'appdata', 'localappdata'} for p in target.parts)
    assert not re.fullmatch(r'save_\d+\.json(?:\.bak|\.tmp)?', target.name, re.I), path
    if not target.is_file():
        return (path, pin, None)
    with target.open('rb') as f:
        actual = sha256()
        for data in iter(lambda: f.read(1024 * 1024), b''):
            actual.update(data)
    if actual.hexdigest() != pin:
        return (path, pin, actual.hexdigest())
    return None


before, gate = load(ROOT / gate_path), load(overlay(gate_path))
leaf = receipt['leaf']['new']
authority = load(overlay(ex_path))
legacy = gate['legacy_source_sha256']
assert set(legacy) == set(before['legacy_source_sha256']) | {leaf}
assert receipt['leaf']['old'] not in legacy
assert legacy[leaf] == authority['source_sha256'][leaf] == receipt['leaf']['sha256']
assert not set(authority['source_sha256']) - set(legacy)
assert gate['runtime_authority_sha256'] == before['runtime_authority_sha256']
assert gate['artifacts'] == before['artifacts']
assert all(gate[k] == before[k] for k in before if k != 'legacy_source_sha256')
gate_sha = sha256(overlay(gate_path).read_bytes()).hexdigest()
assert ('"manifest_sha256": "' + gate_sha + '"').encode() in overlay(gate_index).read_bytes()
expected = gate['artifacts'] | gate['runtime_authority_sha256'] | legacy
with ThreadPoolExecutor(max_workers=4) as pool:
    diffs = [row for row in pool.map(match, expected.items()) if row is not None]
print(json.dumps({'scope': 'offline expected Gate manifest leaf hashes, not actual collector', 'legacy_before': len(before['legacy_source_sha256']), 'legacy_after': len(legacy), 'expected_without_dynamic_indices': len(expected), 'only_added_key': leaf, 'changed_legacy_pins': [p for p, old in before['legacy_source_sha256'].items() if legacy[p] != old], 'diffs': diffs}, ensure_ascii=False))
raise SystemExit(bool(diffs))
