"""Root-approved inverse of this install only; never changes archives or save data."""
import base64
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
PLAN = BASE / 'keepalive_closure_READY01'
RECEIPT = BASE / 'keepalive_rollback_receipt.json'
sha = lambda data: hashlib.sha256(data).hexdigest()
receipt_bytes = (PLAN / 'receipt.json').read_bytes()
assert sha(receipt_bytes) == '3446e13005849054dfd674a13038a7b553ecaf05dd9239d212458c99421bf729'
plan = json.loads(receipt_bytes)
originals = json.loads((PLAN / 'original_bytes.json').read_bytes())
assert len(plan['targets']) == len(originals) == 23
assert not RECEIPT.exists()
staged = []
for row in plan['targets']:
    target = (ROOT / row['target']).resolve()
    assert target.is_relative_to(ROOT / 'game') and row['target'].startswith('game/')
    current = target.read_bytes()
    original = originals['res://' + row['target'][5:]]
    restore = base64.b64decode(original['base64'], validate=True)
    assert sha(current) == row['new_sha256'], ('CURRENT_DRIFT_STOP', row['target'])
    assert sha(restore) == row['old_sha256'] == original['sha256'], ('ORIGINAL_DRIFT_STOP', row['target'])
    assert len(restore) == row['old_bytes']
    staged.append((row, target, current, restore))
for row, target, current, restore in staged:
    assert target.read_bytes() == current, ('LATE_DRIFT_STOP', row['target'])
for row, target, current, restore in staged:
    target.write_bytes(restore)
for row, target, current, restore in staged:
    assert target.read_bytes() == restore, ('RESTORE_VERIFICATION_FAILED', row['target'])
report = {
    'status': 'ROLLED_BACK_EXACT_23_AFTER_FORMAL_39272_REJECTION',
    'formal_fail_result': 'formal_residual01/actual/39272/result.json',
    'approved_snapshot_preserved': plan['new_runtime_leaf'],
    'target_sha256': {row['target']: {'rejected': row['new_sha256'], 'restored': row['old_sha256']} for row, _, _, _ in staged},
    'real_save_contents_accessed': False,
    'engine_started': False,
}
RECEIPT.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'status': report['status'], 'restored_exact': len(staged), 'receipt_sha256': sha(RECEIPT.read_bytes())}))
