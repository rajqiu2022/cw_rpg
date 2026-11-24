"""Only with Root approval: revert exact 30 active Yihong edits, preserve 5 inert leaves and evidence."""
import base64
import hashlib
import json
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
DEPLOY = BASE / 'yihong_composite_DEPLOY01'
REPORT = DEPLOY / 'rollback_receipt.json'
GROUND_PATCH = BASE / 'yihong_ground_guard_REVIEW01/installed.json'
GROUND_PATCH_SHA = 'ca49196fb0e778a836cd3daceadbafa76b47a52f691e6da2d31efa5a3908630f'
PINS = 'game/build/luoyang_quality_20261101b_runtime01/source_pins_READY.json'
GROUND = 'game/build/luoyang_quality_20261101b_ground01/ground_visual.gd'
sha = lambda value: hashlib.sha256(value).hexdigest()

assert len(sys.argv) == 3 and sys.argv[2] in {'--preflight', '--rollback'}
receipt_bytes = (DEPLOY / 'after.json').read_bytes()
assert sha(receipt_bytes) == sys.argv[1] and not REPORT.exists()
receipt = json.loads(receipt_bytes)
assert receipt['status'] == 'EXACT_29_OLD_5_NEW_INSTALLED_AWAITING_FORMAL_QA'
preimages = json.loads((DEPLOY / 'preimages.json').read_bytes())
ground_bytes = GROUND_PATCH.read_bytes()
assert sha(ground_bytes) == GROUND_PATCH_SHA
ground_rows = {r['target']: r for r in json.loads(ground_bytes)['targets']}
assert set(ground_rows) == {PINS, GROUND}
staged = {}
retained = []
for row in receipt['targets']:
    p = row['target']
    target = (ROOT / p).resolve()
    assert target.is_relative_to(ROOT / 'game') and '..' not in p and not any(part.lower() in {'save', 'saves', 'app_userdata', 'appdata', 'localappdata'} for part in target.parts)
    actual = target.read_bytes()
    expected_after = row['after']
    if p == PINS:
        assert ground_rows[p]['before_sha256'] == expected_after
        expected_after = ground_rows[p]['after_sha256']
    assert sha(actual) == expected_after, ('CURRENT_DRIFT_STOP', p)
    if row['before'] is None:
        assert p not in preimages
        retained.append(p)
        continue
    old = base64.b64decode(preimages[p]['base64'], validate=True)
    assert sha(old) == row['before'] == preimages[p]['sha256'], ('BEFORE_DRIFT_STOP', p)
    staged[p] = (target, actual, old)
assert set(staged) == set(preimages) and len(staged) == 29 and len(retained) == 5
ground_path = (ROOT / GROUND).resolve()
ground_before_path = (ROOT / ground_rows[GROUND]['preimage']).resolve()
assert ground_before_path.is_relative_to(GROUND_PATCH.parent) and ground_path.is_relative_to(ROOT / 'game')
ground_after, ground_old = ground_path.read_bytes(), ground_before_path.read_bytes()
assert sha(ground_after) == ground_rows[GROUND]['after_sha256'] and sha(ground_old) == ground_rows[GROUND]['before_sha256']
staged[GROUND] = (ground_path, ground_after, ground_old)
assert all(path.read_bytes() == after for path, after, _ in staged.values())
if sys.argv[2] == '--preflight':
    print(json.dumps({'status': 'ROLLBACK_READY_ZERO_WRITES', 'would_restore': len(staged), 'would_preserve': retained}))
    raise SystemExit(0)
router = 'game/scripts/autoload/scene_router.gd'
for key in [router] + [p for p in staged if p != router]:
    target, after, old = staged[key]
    assert target.read_bytes() == after, ('LATE_DRIFT_STOP', key)
    target.write_bytes(old)
assert all(target.read_bytes() == old for target, _, old in staged.values())
report = {'status': 'RESTORED_EXACT_30_ACTIVE_PREIMAGES', 'restored': {p: sha(row[2]) for p, row in staged.items()}, 'retained_new_inert_leaves': retained, 'engine_started': False, 'real_save_content_access': 0}
REPORT.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'status': report['status'], 'restored': 30, 'preserved': 5, 'receipt_sha256': sha(REPORT.read_bytes())}))
