"""Reviewed Root exact-copy transport of three ABSENT verified media leaves only."""
from pathlib import Path
import hashlib, json

A = Path(__file__).resolve().parent
GAME = A.parents[1]
ISO = A / 'monks17_single_sprite_isolate_ROOT_PREPARED'
PINS = {
    ISO / 'prepared_READY.json': '06fb0a7d9a7980964e9db4cdf47c086381f0d9e18dd5e66793bbe9f5d73e8f3a',
    ISO / 'elder_sprite_import_result_101744.json': '2d0c9f3cebef02f9785918a5d366d298d8841627defdb4d07a89912b99ffdc18',
    A / 'monks18_import_actual_process_receipt.json': 'e0ed2dedf4b5ddf0255ff5ef72317ec5c625d1c03ca8c98b104e98bfa334c961',
    A / 'monks18_verify_actual_process_receipt.json': '8abade4d9553914dee091e5a2a92de559fefb2cd3270858dceaee2742dc3440c',
}
LEAVES = {
    'art/characters/luoyang_city_finish_20261025i/cave_keeper_elder_idle_v1_runtime.png': 'e0f043d80a1f89f8e982cc07fdcabb3bf390b259490da4df6fec9bab969b2e67',
    'art/characters/luoyang_city_finish_20261025i/cave_keeper_elder_idle_v1_runtime.png.import': '7d6b1d76a8d67f5703c2aaebcd7417871789aca18f9ae9626a88526bb6b3d14a',
    '.godot/imported/cave_keeper_elder_idle_v1_runtime.png-e26b959eaf31788a4b4b83b999444343.ctex': 'adf90ec4fa79503a2acf804d56d793c385f6e1f576aaed9812d240e6646f3baa',
}
def sha(b): return hashlib.sha256(b).hexdigest()
def load(p): return json.loads(p.read_text(encoding='utf-8-sig'))
def fact(p):
    p = Path(p)
    if not p.exists(): return {'exists': False}
    s = p.stat(); b = p.read_bytes(); z = p.stat()
    assert (s.st_size, s.st_mtime_ns) == (z.st_size, z.st_mtime_ns)
    return dict(exists=True, sha256=sha(b), bytes=len(b), ticks=str(z.st_mtime_ns // 100 + 621355968000000000))
def guard(spec):
    for p, wanted in spec['protection_full_exactticks'].items(): assert fact(p) == wanted, p
def main():
    receipt = A / 'monks19_three_media_promoted_ROOT_ACTUAL.json'
    assert not receipt.exists()
    for p, h in PINS.items(): assert sha(p.read_bytes()) == h, p
    prepared = load(ISO / 'prepared_READY.json')
    report = load(ISO / 'elder_sprite_import_result_101744.json')
    assert report['passed'] is True and not report['failures'] and report['checks'] == 8342
    assert report['source_first'] == report['source_final'] and len(report['rows']) == 1
    assert report['rows'][0]['full_RGBA_exact'] and report['rows'][0]['params23']
    for p in [A/'monks18_import_actual_process_receipt.json', A/'monks18_verify_actual_process_receipt.json']:
        process = load(p)
        assert process['actual_natural_console_exit_code'] == 0 and process.get('process_stopped_by_tool', process.get('stopped_by_tool')) is False
    guard(prepared)
    for rel, h in LEAVES.items():
        assert not (GAME/rel).exists(), rel
        assert sha((ISO/rel).read_bytes()) == h, rel
    copied = []
    for rel, h in LEAVES.items():
        target = GAME/rel
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open('xb') as f: f.write((ISO/rel).read_bytes())
        row = fact(target); assert row['sha256'] == h
        copied.append(dict(path='res://'+rel, **row))
    guard(prepared)
    for p, h in PINS.items(): assert sha(p.read_bytes()) == h
    data = dict(status='ROOT_THREE_ABSENT_ELDER_MEDIA_EXACT_COPY_NOT_NPC_BINDING', passed=True,
        copied=copied, protected_unique=len(prepared['protection_full_exactticks']),
        exactticks_before_after=True, old_FAIL_preserved=True, save_writes=0,
        import_calls=0, canonical_script_writes=0, actual_Field_pass=False,
        inputs={str(p):h for p,h in PINS.items()})
    raw = (json.dumps(data, ensure_ascii=False, indent=2)+'\n').encode()
    with receipt.open('xb') as f: f.write(raw)
    print(json.dumps(dict(receipt=str(receipt), sha256=sha(raw), passed=True, promoted=3)))
if __name__ == '__main__': main()
