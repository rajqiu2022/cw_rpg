"""Root-only read-only pre/post guard. No collectors, engine, imports or canonical writes."""
from pathlib import Path
import argparse, datetime, hashlib, json, re, subprocess

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
S = 'res://build/luoyang_city_revision_20261025h_source01/'
R = 'res://build/luoyang_city_revision_20261025h_root01/'
PINS = {
    'fresh': (S+'fresh_current25h_READONLY.json', '7b26d75eaad7d95b7d7ab33e572d0ab10c52d02e6b5e07f4ecb8609fa6ed1dcb'),
    'stage': (S+'outputs/root_services_garden_exact28_stage05/receipt.json', 'ebe06a49d65b93102b746688168202efed227ab90a0834fe7bdbc76443bcfef5'),
    'deployment': (R+'service_garden28_deployed_actual.json', '7761350ba5a49ebeb94789fcc104d7310c204f28674a499bd9f6b4d2f9ad98ac'),
    'backup': (R+'exact28_backup_actual.json', 'e173e63f85e29df84edba04a6326ce54762eeddd397afc545475d8c133ff1e50'),
    'binding': ('res://build/luoyang_garden_river_20261025h_source01/runtime02_READY/garden_river_binding_READY.json', '7ecb31c6adde123f7b365ba6596dc1eed3b1e795c3b4a6baa3162992e3bf5cdf'),
    'services': ('res://build/luoyang_indoor_services_20261025h_system01/services_author05_CANDIDATE.json', '7706e07c00a8a318673fd496448f5a48e7005fa8998b9d16f7520615bd3effd8'),
}
TASKS_FINAL = '6a294ed9a07419745b7c6ccee5c0f04bfbe7218e938a66ea6d5c7392949ad8ad'

def sha(raw): return hashlib.sha256(raw).hexdigest()
def res(path): return (GAME/path[6:]).resolve() if path.startswith('res://') else Path(path).resolve()
def load(path, digest):
    raw = res(path).read_bytes()
    assert sha(raw) == digest, ('FIXED_DOCUMENT_PIN', path)
    return json.loads(raw)
def sig(row): return {k: row[k] for k in ('exists', 'sha256', 'bytes', 'ticks') if k in row}
def fact(path):
    path = res(path)
    if not path.exists(): return {'exists': False}
    a = path.stat()
    with path.open('rb') as stream: digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    b = path.stat()
    assert (a.st_size, a.st_mtime_ns) == (b.st_size, b.st_mtime_ns), ('CHANGED_DURING_READ', str(path))
    return {'exists': True, 'sha256': digest, 'bytes': b.st_size, 'ticks': str(b.st_mtime_ns//100+621355968000000000)}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', required=True)
    parser.add_argument('--previous')
    parser.add_argument('--previous-sha256')
    args = parser.parse_args()
    dest = res(args.out)
    assert dest.is_relative_to(HERE) and not dest.exists(), 'NEW_SOURCE_REPORT_ONLY'
    docs = {name: load(*pin) for name, pin in PINS.items()}
    fresh, stage, dep, backup = (docs[k] for k in ('fresh', 'stage', 'deployment', 'backup'))
    assert stage['status'] == 'SERVICE_GARDEN_EXACT28_STAGED_NOT_DEPLOYED'
    assert stage['source_first'] == stage['source_final'] and len(stage['source_first']) == 3323
    assert stage['target_partition'] == dep['target_partition'] == {'patch_count': 14, 'copy_count': 14, 'total': 28}
    assert dep['passed'] and dep['stage_sha256'] == PINS['stage'][1]
    targets = {row['target']: row for row in stage['targets']}
    deployed = {row['target']: row for row in dep['targets']}
    assert len(targets) == len(deployed) == len(backup['rows']) == 28 and set(targets) == set(deployed) == {r['target'] for r in backup['rows']}
    for p, row in targets.items(): assert row['candidate_sha256'] == deployed[p]['sha256'] and row['old_sha256'] == deployed[p]['old_sha256']
    errors = []
    def compare(path, expected, label):
        now = fact(path)
        bad = {k: {'expected': v, 'actual': now.get(k)} for k, v in expected.items() if now.get(k) != v}
        if bad: errors.append({'path': path, 'kind': label, 'differences': bad})
        return {'path': path, **now}
    absolute_targets = {str(res(p)): p for p in targets}
    observed = []
    allowed_changes = []
    task_changes = []
    for old in fresh['current_facts']:
        p = old['path']
        if str(res(p)) in absolute_targets:
            target = absolute_targets[str(res(p))]
            d = deployed[target]
            assert old['sha256'] == targets[target]['old_sha256']
            now = compare(p, {'exists': True, 'sha256': d['sha256'], 'bytes': d['bytes'], 'ticks': d['ticks']}, 'AUTHORIZED_TARGET_MUST_EQUAL_ROOT_DEPLOYMENT')
            allowed_changes.append({'path': p, 'old_sha256': old['sha256'], 'sha256': d['sha256']})
        elif str(res(p)).replace('\\', '/').endswith('/prompts/tasks.yaml'):
            raw = res(p).read_bytes()
            prefix_preserved = sha(raw[:old['bytes']]) == old['sha256']
            now = compare(p, {'exists': True, 'sha256': TASKS_FINAL}, 'ONLY_TWO_AUTHORIZED_TASK_APPENDICES')
            if not prefix_preserved: errors.append({'path': p, 'kind': 'ORIGINAL_TASK_PREFIX_NOT_BYTE_IDENTICAL'})
            task_changes.append({'path': p, 'old': sig(old), 'current': sig(now), 'original_prefix_byte_identical': prefix_preserved, 'scope': 'Root authorized innkeeper v1 plus text-only v2 task appendices; no other task change authorized'})
        else: now = compare(p, sig(old), 'UNCHANGED_FRESH2121_EXACT_TICKS')
        observed.append(now)
    assert len(observed) == 2121 and len(allowed_changes) == 28 and len(task_changes) == 1
    old_saves = fresh['current_save_protection_start15']
    saves = [compare(r['path'], sig(r), 'SAVE15_EXACT_TICKS_NO_ROLLBACK') for r in old_saves]
    assert len(saves) == 15
    current33 = []
    for row in fresh['current33_fixed_target_checks']:
        p = row['target']
        if p in deployed:
            d = deployed[p]
            expect = {'exists': True, 'sha256': d['sha256'], 'bytes': d['bytes'], 'ticks': d['ticks']}
        else: expect = sig(row['current'])
        current33.append(compare(p, expect, 'CURRENT33_PLUS_FAMILY_NATIVE_GEOMETRY'))
    assert len(current33) == 33
    backups = [compare(r['path'], sig(r), 'ORIGINAL148_BACKUPS_EXACT_TICKS') for r in fresh['backups_current148']]
    for row in backup['rows']:
        backups.append(compare(row['backup'], {'exists': True, 'sha256': row['sha256'], 'bytes': row['bytes'], 'ticks': row['backup_ticks']}, 'NEW28_WHOLE_BACKUPS_EXACT_TICKS'))
    assert len(backups) == 176
    old_media = [compare(r['path'], sig(r), 'ORIGINAL_MEDIA8_EXACT_TICKS') for r in fresh['new_media_current8']]
    assert len(old_media) == 8
    binding, author = docs['binding'], docs['services']
    # These hashes come from immutable approved author/binding, never live discovery.
    def hash_maps(value):
        if isinstance(value, dict):
            for key, item in value.items():
                if key.startswith('res://') and isinstance(item, str) and re.fullmatch('[a-fA-F0-9]{64}', item): yield key, item.lower()
                yield from hash_maps(item)
        elif isinstance(value, list):
            for item in value: yield from hash_maps(item)
    authored = dict(hash_maps(author))
    inn = {p: h for p, h in authored.items() if '/portrait_innkeeper_v1.png' in p}
    assert len(inn) == 3
    new_media_pins = {**inn, **binding['mask_import_and_direct_ctex']}
    assert len(new_media_pins) == 5
    new_media = [compare(p, {'exists': True, 'sha256': h}, 'NEW_MEDIA_APPROVED_FIXED_HASH') for p, h in new_media_pins.items()]
    garden_native = [compare(row['path'], {'exists': True, 'sha256': row['sha256']}, 'PUBLISHED_GARDEN_NATIVE_NO_RECOMPUTATION') for row in binding['child'].values()]
    shop_pins = {p: h for p, h in authored.items() if p.startswith('res://data/shops/luoyang_services_20261025h/')}
    assert len(shop_pins) == 3
    shops = [compare(p, {'exists': True, 'sha256': h}, 'EXCLUSIVE_NEW_SHOPDEF_FIXED_HASH') for p, h in shop_pins.items()]
    maps = []
    for node in ('expected_ch4_s0_luoyang_gate_true', 'expected_ch4_s1_luoyang_yamen_true', 'expected_ch4_s2_canal_docks_true', 'expected_ch4_s3_luoyang_market_true', 'expected_Family_sources'):
        row = stage['nodes'][node]
        value = load(row['path'], row['sha256'])
        assert value == row['value'], ('FIXED_INDEPENDENT_MAP_VALUE', node)
        maps.append({'node': node, 'path': row['path'], 'sha256': row['sha256'], 'count': len(value['source_sha256'])})
    extra = new_media + garden_native + shops
    if args.previous:
        assert args.previous_sha256
        previous = load(args.previous, args.previous_sha256)
        assert previous['passed'] and previous['stage']['sha256'] == PINS['stage'][1] and previous['deployment']['sha256'] == PINS['deployment'][1]
        for old in previous['new_resource_ticks_observed_first_guard']:
            compare(old['path'], sig(old), 'NEW_RESOURCE_POST_VS_PRE_EXACT_TICKS')
        for old in previous['tasks_authorized_changes']:
            compare(old['path'], old['current'], 'APPROVED_TASK_POST_VS_PRE_EXACT_TICKS')
    else: assert not args.previous_sha256
    ps = "@(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^Godot.*\\.exe$' } | ForEach-Object { [pscustomobject]@{pid=$_.ProcessId;name=$_.Name;command_line=$_.CommandLine} }) | ConvertTo-Json -Depth 3 -Compress"
    proc = subprocess.run(['powershell', '-NoProfile', '-Command', ps], capture_output=True, text=True, check=True)
    processes = json.loads(proc.stdout) if proc.stdout.strip() else []
    if isinstance(processes, dict): processes = [processes]
    for p in processes: p['role_observation'] = 'EDITOR_KEEP' if re.search(r'(^|\s)(--editor|-e)(\s|$)', p.get('command_line') or '') else 'USER_OR_OTHER_GODOT_KEEP_NO_STOP'
    report = dict(status='SERVICE_GARDEN28_FULL_PROTECTION_READONLY', passed=not errors, observed_count=2121, save_count=15, full_backup_count=176, old_media_count=8, new_media_count=5, new_shop_count=3, stage=dict(zip(('path','sha256'), PINS['stage'])), deployment=dict(zip(('path','sha256'), PINS['deployment'])), current_facts=observed, saves=saves, current33=current33, authorized_target_changes=allowed_changes, tasks_authorized_changes=task_changes, backups_current=backups, old_media_current=old_media, new_resource_ticks_observed_first_guard=extra, fixed_maps=maps, failures=errors, previous_guard=None if not args.previous else {'path': args.previous, 'sha256': args.previous_sha256}, running_Godot_readonly_inventory=processes, OWNED=10, proof_count=176, depth_limit=16, actual_Field_pass_claim=False, whole_city_or_loading_10s_claim=False, no_rollback=True, collector_calls=0, engine_calls=0, imports=0, canonical_writes=0, save_writes=0, processes_stopped=0, finished_utc=datetime.datetime.now(datetime.timezone.utc).isoformat())
    raw = (json.dumps(report, ensure_ascii=False, indent=2, allow_nan=False)+'\n').encode()
    with dest.open('xb') as stream: stream.write(raw)
    print(json.dumps({'path': 'res://'+dest.relative_to(GAME).as_posix(), 'sha256': sha(raw), 'passed': report['passed'], 'failures': len(errors), 'observed': 2121, 'backups': 176}))
    if errors: raise SystemExit(1)

if __name__ == '__main__': main()
