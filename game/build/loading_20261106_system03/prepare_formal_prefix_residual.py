"""Build second isolated QA fixture; no engine or formal writes."""
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
SRC = BASE / 'formal_residual01'
OUT = BASE / 'formal_residual02'
PLAN = BASE / 'keepalive_prefix_REVIEW02'
sha = lambda data: hashlib.sha256(data).hexdigest()
enc = lambda obj: (json.dumps(obj, ensure_ascii=False, indent=2) + '\n').encode('utf-8')
receipt_bytes = (PLAN / 'receipt.json').read_bytes()
assert sha(receipt_bytes) == '7bd95874f7a1108524dbe2648fc8488fc9b6be31d42e69d2fd4fa833508cafc3'
plan = json.loads(receipt_bytes)
original = (SRC / 'formal_pair_probe.gd').read_bytes()
probe = original
for old, new in [
    ('loading_20261106_system03/formal_residual01/', 'loading_20261106_system03/formal_residual02/'),
    ('../keepalive_closure_READY01/receipt.json', '../keepalive_prefix_REVIEW02/receipt.json'),
    ('row.new_sha256', 'row.after_sha256'),
    ('receipt.new_runtime_leaf', 'receipt.leaf'),
    ('get_sha256(leaf.path)', 'get_sha256(leaf.new)'),
    ('b.AP_EXEC_INDEX,b.AP_QUARTER_INDEX,b.MG_INDEX]', 'b.AP_EXEC_INDEX,b.AP_QUARTER_INDEX]'),
    ('\tgate_admission = check_gate_sources()', '\tvar culture: GDScript = load("res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd")\n\tvar culture_state: Dictionary = culture.call("readiness")\n\tneed(culture_state.get("ok", false) == true, "CULTURE_REAL_READINESS:" + String(culture_state.get("error", "")))\n\tgate_admission = check_gate_sources()'),
]:
    a, b = old.encode(), new.encode()
    assert probe.count(a) == 1, old
    probe = probe.replace(a, b, 1)
old_inventory = (SRC / 'source_inventory.json').read_bytes()
assert sha(old_inventory) == '3d7e34578b3cc3d70054fd16102da52824c622f43b1d3eb2ec2ff72d5ade5d69'
inventory = json.loads(old_inventory)
changes = {
    'res://build/loading_20261106_system03/keepalive_closure_READY01/receipt.json': 'res://build/loading_20261106_system03/keepalive_prefix_REVIEW02/receipt.json',
    plan['leaf']['old']: plan['leaf']['new'],
    'res://build/loading_20261106_system03/formal_residual01/formal_pair_probe.gd': 'res://build/loading_20261106_system03/formal_residual02/formal_pair_probe.gd',
    'res://build/loading_20261106_system03/formal_residual01/launch_ROOT_ONLY.ps1': 'res://build/loading_20261106_system03/formal_residual02/launch_ROOT_ONLY.ps1',
}
assert set(changes) <= set(inventory['source_paths'])
inventory['source_paths'] = [changes.get(p, p) for p in inventory['source_paths']] + [
    'res://scripts/city/luoyang_execution_authority_20261022ap.gd',
    'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd',
    'res://data/luoyang_culture_integration_20261019x/runtime_contract.json',
]
assert len(set(inventory['source_paths'])) == len(inventory['source_paths'])
inv = enc(inventory)
launch = (SRC / 'launch_ROOT_ONLY.ps1').read_bytes()
for old, new in [
    ('formal_residual01', 'formal_residual02'),
    ('run05_formal_scoped_keepalive', 'run06_formal_keepalive_prefix'),
    (sha(old_inventory), sha(inv)),
]:
    assert old.encode() in launch
    launch = launch.replace(old.encode(), new.encode())
assert not OUT.exists()
OUT.mkdir()
(OUT / '.gdignore').touch()
(OUT / 'formal_pair_probe.gd').write_bytes(probe)
(OUT / 'source_inventory.json').write_bytes(inv)
(OUT / 'launch_ROOT_ONLY.ps1').write_bytes(launch)
print(json.dumps({'old_probe_sha256': sha(original), 'new_probe_sha256': sha(probe), 'inventory_sha256': sha(inv), 'inventory_count': len(inventory['source_paths'])}))
