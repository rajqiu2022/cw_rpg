"""Root-approved exact REVIEW02 install after preimages and all inverses agree."""
from hashlib import sha256
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PLAN = BASE / 'keepalive_prefix_REVIEW02'
REPORT = BASE / 'keepalive_prefix_install_receipt.json'
sha = lambda data: sha256(data).hexdigest()
plan_bytes = (PLAN / 'receipt.json').read_bytes()
assert sha(plan_bytes) == '7bd95874f7a1108524dbe2648fc8488fc9b6be31d42e69d2fd4fa833508cafc3'
plan = json.loads(plan_bytes)
assert not REPORT.exists() and len(plan['targets']) == 23
leaf = plan['leaf']
assert leaf['new'].startswith('res://build/luoyang_') and '..' not in leaf['new']
leaf_dst = (ROOT / ('game/' + leaf['new'][6:])).resolve()
assert leaf_dst.is_relative_to(ROOT / 'game/build') and not leaf_dst.parent.exists()
leaf_bytes = (PLAN / 'scene_router.gd.snapshot.txt').read_bytes()
assert leaf_bytes == (ROOT / ('game/' + leaf['old'][6:])).read_bytes() and sha(leaf_bytes) == leaf['sha256']
staged = []
for row in plan['targets']:
    path = (ROOT / row['target']).resolve()
    candidate = (ROOT / row['candidate']).resolve()
    assert path.is_relative_to(ROOT / 'game') and candidate.is_relative_to(PLAN) and path not in [r[1] for r in staged]
    old, new = path.read_bytes(), candidate.read_bytes()
    assert sha(old) == row['before_sha256'], ('CURRENT_DRIFT_STOP', row['target'])
    assert sha(new) == row['after_sha256'], ('CANDIDATE_DRIFT_STOP', row['target'])
    inverse = new
    for h in reversed(row['inverse']):
        i = h['new_offset']
        n, o = h['new'].encode(), h['old'].encode()
        assert inverse[i:i + len(n)] == n, ('INVERSE_SLICE_STOP', row['target'])
        inverse = inverse[:i] + o + inverse[i + len(n):]
    assert inverse == old, ('WHOLE_INVERSE_STOP', row['target'])
    staged.append((row, path, old, new))
for row, path, old, new in staged:
    assert path.read_bytes() == old, ('LATE_DRIFT_STOP', row['target'])
leaf_dst.parent.mkdir()
(leaf_dst.parent / '.gdignore').touch()
with leaf_dst.open('xb') as f:
    f.write(leaf_bytes)
for row, path, old, new in staged:
    path.write_bytes(new)
assert leaf_dst.read_bytes() == leaf_bytes
for row, path, old, new in staged:
    assert path.read_bytes() == new, ('FINAL_EXACT_STOP', row['target'])
result = {'status': 'REVIEW02_EXACT_23_INSTALLED_AWAITING_ROOT_ENGINE_CHECK', 'formal': [{'target': row['target'], 'before': sha(old), 'after': sha(new)} for row, _, old, new in staged], 'full_inverse_count': 23, 'immutable_leaf': leaf, 'engine_started': False, 'real_save_contents_accessed': False}
REPORT.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'status': result['status'], 'targets': len(staged), 'receipt_sha256': sha(REPORT.read_bytes())}))
