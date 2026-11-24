"""Repair only stale explicit prospective transport declarations; not a Stage run."""
from pathlib import Path
import copy, hashlib, json
G = Path(__file__).resolve().parents[2]
O = G / 'build/luoyang_city_finish_20261025i_source01/region_integration_20261027d01'
old_path = O / 'source_input_region32_ROOT_REVIEW.json'
raw = old_path.read_bytes()
assert hashlib.sha256(raw).hexdigest() == '6a92462cd02acc20dd890e1eac7fe8169ce71a502a088527ad47566cd5a6b167'
old = json.loads(raw); new = copy.deepcopy(old)
authority_pin = next(r for r in old['pinned_inputs'] if r['id'] == 'execution')
authority_raw = (G / authority_pin['path'][6:]).read_bytes()
assert hashlib.sha256(authority_raw).hexdigest() == authority_pin['sha256']
authority = json.loads(authority_raw)
targets = {
    'res://scripts/field/field_walkable_controller.gd',
    'res://scripts/city/luoyang_docks_workyard_20261019ac.gd',
    'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd',
    'res://scripts/city/luoyang_temple_assembly_20261016.gd',
    'res://scripts/autoload/scene_router.gd',
}
changed = []
for row in new['prospective_targets']:
    if row['target'] not in targets: continue
    owned = authority['owned'][row['target']]
    edges = [e for e in owned['edges'] if e['new_sha256'] == owned['current_sha256']]
    assert len(edges) == 1
    edge = edges[0]; candidate = (G / edge['new_snapshot'][6:]).read_bytes()
    assert hashlib.sha256(candidate).hexdigest() == edge['new_sha256']
    declared = old['declared_candidates'][row['target']]
    assert declared['path'] == edge['new_snapshot'] and declared['sha256'] == edge['new_sha256'] and declared['bytes'] == len(candidate)
    before = copy.deepcopy(row)
    row.update(candidate_path=edge['new_snapshot'], sha256=edge['new_sha256'], bytes=len(candidate))
    changed.append({'target': row['target'], 'before': before, 'after': copy.deepcopy(row)})
assert {r['target'] for r in changed} == targets and len(changed) == 5
new['output_root'] = 'res://build/luoyang_city_finish_20261025i_source01/outputs/root_region_integration_exact32_stage02/'
back = copy.deepcopy(new)
for change in changed:
    index = next(i for i, r in enumerate(back['prospective_targets']) if r['target'] == change['target'])
    back['prospective_targets'][index] = change['before']
back['output_root'] = old['output_root']
assert back == old
for row in new['prospective_targets']:
    if row['target'] not in authority['owned']: continue
    owned = authority['owned'][row['target']]
    assert any(e['new_snapshot'] == row['candidate_path'] and e['new_sha256'] == row['sha256'] == owned['current_sha256'] for e in owned['edges'])
out = O / 'source_input_region32_ROOT_REVIEW02.json'
assert not out.exists()
data = (json.dumps(new, ensure_ascii=False, indent=2) + '\n').encode()
out.write_bytes(data)
print(json.dumps({'input': 'res://' + out.relative_to(G).as_posix(), 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data), 'changed_explicit_prospectives': changed, 'driver_unchanged': True, 'inverse_exact': True, 'Stage_executed': False}))
