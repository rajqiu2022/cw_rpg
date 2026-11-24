"""Root-approved exact 23-target mechanical byte successor, no engine/save access."""
from pathlib import Path
import base64, hashlib, json

ROOT = Path(__file__).resolve().parents[3]
BASE = Path(__file__).resolve().parent
READY = BASE / 'keepalive_closure_READY01'
RECEIPT = READY / 'receipt.json'
digest = lambda b: hashlib.sha256(b).hexdigest()
assert digest(RECEIPT.read_bytes()) == '3446e13005849054dfd674a13038a7b553ecaf05dd9239d212458c99421bf729'
receipt = json.loads(RECEIPT.read_text(encoding='utf-8'))
hunks = {r['target']: r['hunks'] for r in json.loads((READY/'all_hunks.json').read_text(encoding='utf-8'))}
rows = receipt['targets']
assert len(rows) == 23
staged = []
for row in rows:
    target, candidate = ROOT/row['target'], ROOT/row['candidate']
    old, new = target.read_bytes(), candidate.read_bytes()
    assert digest(old) == row['old_sha256'], ('FORMAL_CHANGED_STOP', row['target'])
    assert digest(new) == row['new_sha256'], ('CANDIDATE_CHANGED_STOP', row['target'])
    inverse = new
    for h in reversed(hunks[row['target']]):
        p = h['new_offset']
        new_span = h['new'].encode('utf-8')
        old_span = h['old'].encode('utf-8')
        assert inverse[p:p+len(new_span)] == new_span, ('INVERSE_SLICE_STOP', row['target'], p)
        inverse = inverse[:p]+old_span+inverse[p+len(new_span):]
    assert inverse == old, ('INVERSE_FAILED_STOP', row['target'])
    staged.append((row,target,old,new))
for row,target,old,new in staged:
    assert target.read_bytes() == old, ('LATE_CHANGE_STOP', row['target'])
for row,target,old,new in staged:
    target.write_bytes(new)
report = {'status':'ROOT_APPROVED_EXACT_23_INSTALLED_NOT_ENGINE_VALIDATED','count':23,'whole_inverse_count':23,'formal':[],'engine_started':False,'real_save_contents_accessed':False}
for row,target,old,new in staged:
    actual = digest(target.read_bytes())
    assert actual == row['new_sha256']
    report['formal'].append({'target':row['target'],'before':row['old_sha256'],'after':actual})
(BASE/'keepalive_install_receipt.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'status':report['status'],'exact':len(report['formal']),'inverse':23}))
