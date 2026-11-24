"""Pure source review only. Never imports or runs the stage compiler."""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QA = Path(__file__).resolve().parent
S = ROOT / 'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
OUT = QA / 'finite08_input01_preexecution_independent_blockers_READY.json'

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def fact(p):
    return {'path': 'res://' + p.relative_to(ROOT).as_posix(), 'sha256': sha(p)}

p = S / 'finite08_input01_ROOT_LOCKED.json'
assert sha(p) == '18fd1b4f97de05a28612fa206c402e84dc0ede6deec9b7b9c60ca74e5aca850e'
j = json.loads(p.read_bytes())
nodes = {r['id']: r for r in j['nodes']}
groups = {r['id']: r for r in j['source_groups']}
registry = nodes['registry_final']
registry_path = 'res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
assert len(registry['operations']) == 5
assert 'target' not in registry
assert registry_path not in j['root_target_allowlist']
assert registry_path not in {r['target'] for r in j['prospective_targets']}
for op in registry['operations']:
    assert op['old'] == 'd274d1fcd8f846e6fe8250092d4f83d720b632b174889cfcb1a3b9bacc5752d5'
    assert op['new'] == '185b51ff7b9256657424ba0681660d6d335f890f6c919260b3f467384d03ac16'
maps = [r for r in j['nodes'] if r['kind'] == 'map']
assert len(maps) == 4
for row in maps:
    assert any(op['pointer'] == ['source_sha256', registry_path] and op['new'] == {'$sha': 'registry_final'} for op in row['operations'])
base = S / 'stage_unified06_04_READY.py'
text = base.read_text(encoding='utf-8')
leaf = text.split('    def verify_leaf(self, path, expected):\n', 1)[1].split('    def leaf_bytes', 1)[0]
assert 'self.outputs' not in leaf and 'self.read(path, expected)' in leaf
read = text.split('    def read(self, path, expected):\n', 1)[1].split('    def read_json_input', 1)[0]
assert 'data = res(path).read_bytes()' in read
tool = S / 'stage_finite08_READY.py'
t = tool.read_text(encoding='utf-8')
assert 'def verify_leaf' not in t and 'def read(' not in t
for domain in ['market', 'yamen']:
    row = nodes['finite08_' + domain]
    assert row['kind'] == 'finite_manifest' and 'target' not in row
    assert row['file'] in groups['finite08_' + domain + '_header']['leaves']
    assert groups['finite08_' + domain + '_header']['leaves'][row['file']] == {'$sha': row['id']}
    assert 'finite08_' + domain + '_complete' in next(m for m in maps if m['scene_id'].endswith(domain))['groups']
assert 'not res(row[\'file\']).exists()' in t
assert "self.outputs[row['file']]=raw" in t
assert not OUT.exists()
result = {
    'status': 'INDEPENDENT_STATIC_BLOCKERS_NOT_STAGE_ACTUAL',
    'sources': [fact(p), fact(tool), fact(base), fact(S / 'stage_finite08_scope01_READY.py')],
    'findings': [
        {'id': 'REGISTRY_CHANGED_WITHOUT_CANONICAL_TARGET', 'severity': 'blocking',
         'changed_room_source_values': 5, 'affected_independent_maps': 4,
         'detail': 'Four maps use the new registry node hash for canonical registry; without a target/prospective binding verify_leaf reads old canonical bytes. A prospective-only workaround would still omit necessary deployment.'},
        {'id': 'NEW_FINITE_HEADER_UNRECOGNIZED_BY_VERIFY_LEAF', 'severity': 'blocking',
         'domains': ['market', 'yamen'],
         'detail': 'Finite manifest outputs are declared ABSENT and held only in outputs; map source groups reference their headers, but original verify_leaf/read never checks outputs. Limit any successor memory-leaf branch to the two exact declared finite outputs with full SHA equality.'}
    ],
    'old_input_execution_observed_here': False,
    'does_not_claim_actual_failure': True,
    'engine_runs': 0, 'compiler_runs': 0, 'collector_calls': 0,
    'native_or_png_decode': 0, 'canonical_writes': 0,
    'ready_for_stage': False
}
OUT.write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'review': fact(OUT), 'blockers': 2, 'stage_executed': False}))
