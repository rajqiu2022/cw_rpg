"""Mechanical 27c Root CreateNew32 transport; no backup/engine/Stage execution."""
from pathlib import Path
import hashlib, json
N = Path(__file__).resolve().parent
G = N.parents[1]
S = G / 'build/luoyang_city_finish_20261025i_source01'
O = S / 'region_integration_20261027d01'
P = 'res://build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01/'
sha = lambda raw: hashlib.sha256(raw).hexdigest()
enc = lambda value: (json.dumps(value, ensure_ascii=False, indent=2, allow_nan=False) + '\n').encode()
res = lambda path: 'res://' + path.relative_to(G).as_posix()
def fixed(path, expected):
    raw = path.read_bytes(); assert sha(raw) == expected.lower(), str(path)
    return json.loads(raw)
def pin(path):
    raw = path.read_bytes(); return {'path': res(path), 'sha256': sha(raw), 'bytes': len(raw)}
def emit(name, raw):
    path = O / name; assert not path.exists(), str(path)
    path.parent.mkdir(parents=True, exist_ok=True); path.write_bytes(raw)
    return {'path': res(path), 'sha256': sha(raw), 'bytes': len(raw)}

old_dir = S / 'garden_estate_exit_repair_20261027c01'
deployment_path = old_dir / 'garden_estate32_deployed_ROOT_ACTUAL.json'
deployment = fixed(deployment_path, '01656f8ca04ebac2eb7cca6019a8687a72d111022c2829964d855edfa5259daf')
stage_path = G / deployment['stage']['path'][6:]
stage = fixed(stage_path, '956f16b0321dc8b29415ec390d4a1ba113aa4db27cd4b85e7fc57df5d00ca1c3')
old_input = json.loads((old_dir / 'source_input_garden_estate32_ROOT_REVIEW02.json').read_bytes())
descriptor_pin = next(p for p in old_input['pinned_inputs'] if p['id'] == 'candidates')
descriptor = fixed(G / descriptor_pin['path'][6:], descriptor_pin['sha256'])
back = fixed(old_dir / 'current_CE38_backup32_ROOT_ACTUAL.json', '5137bc82f3a2aee973e47eac2127d4e00c2e310cffe5d83c7a1910dd5359f148')
by_target = {r['target']: r for r in descriptor['targets']}
rows = []
for target, record in by_target.items():
    candidate = record['candidate']; raw = (G / candidate['path'][6:]).read_bytes()
    assert sha(raw) == candidate['sha256'] and len(raw) == candidate['bytes']
    # Source only verifies the 32 precise parents here, not old full inventories.
    assert (G / target[6:]).read_bytes() == raw, target
    rows.append({'target': target, 'immutable_old': candidate['path'], 'old_sha256': candidate['sha256'], 'old_bytes': len(raw), 'backup': P + 'root_only_current32_backup/' + target[6:]})
assert len(rows) == 32 and sum(r['target'].endswith('.gd') for r in rows) == 18
scope = emit('current_01656_exact32_scope_PREPARATION.json', enc({'status': 'CURRENT_01656_REGION_INTEGRATION_SCOPE_NOT_SEALED', 'count': 32, 'partition': {'GD': 18, 'JSON': 14}, 'parent_stage': deployment['stage'], 'parent_deployment': pin(deployment_path), 'parent_descriptor': {k: descriptor_pin[k] for k in ['path', 'sha256']}, 'targets': rows, 'content_pending': ['Gate exact rear/child', 'Region manifest/entry Router successor', 'necessary strict source pointers only'], 'candidate_EOF_single_LF': True, 'canonical_writes': 0, 'engine_calls': 0}))
written = {r['target']: r for r in deployment['targets']}
absolute = {str((G / p[6:]).resolve()).casefold(): r for p, r in written.items()}
facts = {r['path']: {k: v for k, v in r.items() if k != 'path'} for r in back['frozen2121_current_facts']}
for path in facts:
    key = str((G / path[6:] if path.startswith('res://') else Path(path)).resolve()).casefold()
    if key in absolute:
        row = absolute[key]; facts[path] = {'exists': True, 'sha256': row['sha256'], 'bytes': row['bytes'], 'ticks': row['ticks']}
current = []
for row in back['current37']:
    value = {k: v for k, v in row.items() if k != 'current'}
    if value['target'] in written:
        target = written[value['target']]; value.update(sha256=target['sha256'], bytes=target['bytes'])
    current.append(value)
old_backups = back['old705_backup_facts'] + [{'path': r['backup'], 'exists': True, 'sha256': r['sha256'], 'bytes': r['bytes'], 'ticks': r['backup_ticks']} for r in back['new_backups']]
assert len(old_backups) == 737
media = list(back['media_facts'])
garden_pub = json.loads((G / 'build/luoyang_garden_estate_exit_20261027c_system01/ROOT_READY01/output/109852/result.json').read_bytes())
garden_promotion = fixed(G / 'build/luoyang_garden_estate_exit_20261027c_system01/mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json', '37019eb81f4573c2a2d40aebb8cce4dedab974a98c4e67f523ee2ee9b5d6a2bb')
gate_pub = json.loads((G / 'build/luoyang_city_rectification_20261027d_system01/GATE_REAR_ROOT_READY01/output/82020/result.json').read_bytes())
gate_promotion_path = G / 'build/luoyang_city_rectification_20261027d_system01/gate_mask_import01_ROOT_ONLY/promotion_ROOT_EXECUTED.json'
gate_promotion = json.loads(gate_promotion_path.read_bytes())
assert gate_promotion['passed'] is True and pin(gate_promotion_path)['sha256'].startswith('c2ac8fdf')
new_rows = [garden_pub['mask'], gate_pub['mask']] + garden_promotion['written'] + gate_promotion['written']
for row in new_rows:
    path = G / row['path'][6:]; raw = path.read_bytes(); stat = path.stat()
    assert sha(raw) == row['sha256']
    if 'bytes' in row: assert len(raw) == row['bytes']
    assert row['path'] not in {r['path'] for r in media}
    media.append({'path': row['path'], 'exists': True, 'sha256': row['sha256'], 'bytes': len(raw), 'ticks': str(stat.st_mtime_ns // 100 + 621355968000000000)})
assert len(media) == 158
plan = emit('current_01656_backup32_ROOT_PLAN.json', enc({'status': 'ROOT_ONLY_CURRENT_01656_CREATE_NEW32_BACKUP_PLAN_NOT_EXECUTED', 'scope': scope, 'parent_deployment': pin(deployment_path), 'current32': rows, 'current37': current, 'frozen2121_expected': facts, 'prior_save15': back['save15'], 'old737_backup_facts': old_backups, 'media158': media, 'World54': back['World54_facts'], 'ui': back['ui'], 'Root_only_backup_prefix': P + 'root_only_current32_backup/', 'expected_old_backup_total': 737, 'expected_after_backup_total': 769, 'media_timestamp_policy': 'FIXED_SHA_BYTES_REQUIRED_CAPTURE_CURRENT_TICKS_AT_ROOT_EXECUTION_NEVER_RESTORE_OLD_MTIME', 'new_three_building_media': 'Root-owned separate import/promotion receipt; not yet canonical adopted by Source', 'canonical_writes': 0, 'engine_calls': 0}))
parent_tool = old_dir / 'backup_current_CE38_32_ROOT_ONLY.py'
before = parent_tool.read_bytes(); text = before.decode()
for old, new in [('garden_estate_exit_repair_20261027c01/current_CE38_backup32_ROOT_PLAN.json', 'region_integration_20261027d01/current_01656_backup32_ROOT_PLAN.json'), ('old705_backup_facts', 'old737_backup_facts'), ('705+len(rows)', '737+len(rows)'), ('media152', 'media158'), ('fresh_media[:152]', 'fresh_media[:158]'), ('fresh_media[152:]', 'fresh_media[158:]'), ('CURRENT_CE38', 'CURRENT_01656')]:
    assert old in text, old; text = text.replace(old, new)
compile(text, 'backup_current_01656_32_ROOT_ONLY.py', 'exec')
tool = emit('backup_current_01656_32_ROOT_ONLY.py', text.encode())
print(json.dumps({'scope': scope, 'plan': plan, 'tool': tool, 'old_backups': 737, 'Root_new_if_executed': 32, 'total_if_executed': 769, 'source_executed_backup': False, 'same_backup_contract': True}))
