"""Independent strict 31b ground host-pin successor; stage by default."""
import hashlib
import json
import sys
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
OUT = BASE / 'yihong_ground_guard_REVIEW01'
FIELD = 'game/build/luoyang_regions_20261027d_source01/region_field.gd'
GROUND = 'game/build/luoyang_quality_20261101b_ground01/ground_visual.gd'
PINS = 'game/build/luoyang_quality_20261101b_runtime01/source_pins_READY.json'
OLD_FIELD = 'fdb375d92f1590be44288708bc697f2cb780e81584557027c5396508f73de5e5'
NEW_FIELD = 'fadacfa277fe19fab06f8e1d21583394b1dd98c6ed1b632dac709e5f4bf2eec2'
OLD_GROUND = '32243aa7c3728eba64f527384176fd84c4618510f8c886b2fab7d3d1d38f9bbf'
OLD_PINS = '6341e0412e74018fbc0415097070e5486e8509ad79e381dbea2119ce95f11e9d'
KEY = 'res://' + GROUND[5:]
sha = lambda data: hashlib.sha256(data).hexdigest()
enc = lambda data: (json.dumps(data, indent=2, ensure_ascii=False) + '\n').encode()
read = lambda p: (ROOT / p).read_bytes()


def exact_swap(data, old, new):
    a, b = old.encode(), new.encode()
    assert data.count(a) == 1
    result = data.replace(a, b, 1)
    assert result.count(b) == 1 and result.replace(b, a, 1) == data
    return result


assert sha(read(FIELD)) == NEW_FIELD
base_ground, base_pins = read(GROUND), read(PINS)
assert sha(base_ground) == OLD_GROUND and sha(base_pins) == OLD_PINS
new_ground = exact_swap(base_ground, f'const FIELD_SHA := "{OLD_FIELD}"', f'const FIELD_SHA := "{NEW_FIELD}"')
new_sha = sha(new_ground)
new_pins = exact_swap(base_pins, f'"{KEY}": "{OLD_GROUND}"', f'"{KEY}": "{new_sha}"')
expected_pins = json.loads(base_pins)
assert expected_pins['source_pins'][KEY] == OLD_GROUND
expected_pins['source_pins'][KEY] = new_sha
assert json.loads(new_pins) == expected_pins
staged = [(GROUND, base_ground, new_ground), (PINS, base_pins, new_pins)]

if sys.argv[1:] == ['--prepare']:
    assert not OUT.exists()
    OUT.mkdir()
    (OUT / '.gdignore').touch()
    rows = []
    for p, old, new in staged:
        candidate = OUT / (Path(p).name + '.after.txt')
        old_proof = OUT / (Path(p).name + '.before.txt')
        candidate.write_bytes(new)
        old_proof.write_bytes(old)
        rows.append({'target': p, 'candidate': candidate.relative_to(ROOT).as_posix(), 'preimage': old_proof.relative_to(ROOT).as_posix(), 'before_sha256': sha(old), 'after_sha256': sha(new), 'whole_inverse': True})
    report = {'status': 'STAGED_TWO_NO_FORMAL_WRITES', 'targets': rows, 'proof': 'Only old ground FIELD_SHA constant (existing strict host), and this helper key in existing 31b source_pins. No Region/Culture/EX/Gate closure changes.', 'failed_pid': 63892}
    (OUT / 'receipt.json').write_bytes(enc(report))
    print(json.dumps({'status': report['status'], 'receipt_sha256': sha(enc(report)), 'ground_sha256': new_sha, 'quality_pins_sha256': sha(new_pins)}))
else:
    assert len(sys.argv) == 3 and sys.argv[1] == '--install', 'Expected explicit prepare or Root-approved install with exact receipt SHA'
    approved = (OUT / 'receipt.json').read_bytes()
    assert sha(approved) == sys.argv[2]
    rows = json.loads(approved)['targets']
    assert [r['target'] for r in rows] == [p for p, _, _ in staged]
    report = OUT / 'installed.json'
    assert not report.exists()
    for row, (p, old, new) in zip(rows, staged, strict=True):
        assert sha(old) == row['before_sha256'] and sha(new) == row['after_sha256']
        assert read(row['preimage']) == old and read(row['candidate']) == new and read(p) == old
    for p, old, new in staged:
        assert read(p) == old
        (ROOT / p).write_bytes(new)
    assert all(read(p) == new for p, _, new in staged)
    installed = {'status': 'INSTALLED_EXACT_TWO_NO_ENGINE_RUN', 'targets': rows, 'real_save_content_access': 0}
    report.write_bytes(enc(installed))
    print(json.dumps({'status': installed['status'], 'receipt_sha256': sha(enc(installed))}))
