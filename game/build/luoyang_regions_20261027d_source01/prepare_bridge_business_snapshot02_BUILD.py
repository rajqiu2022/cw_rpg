"""Only the actual pure Culture dependency and SELF change; all functions same."""
from pathlib import Path
import hashlib, json

N = Path(__file__).resolve().parent
sha = lambda b: hashlib.sha256(b).hexdigest()
parent = N / 'logical_context_bridge_projector03_SELF_BUILD.gd'
raw = parent.read_bytes()
assert sha(raw) == '4f68822a9476b542e76271e6b7cfbd7d1fb192d0db3cc37b2dd8c0607555b2ca'
before = 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'
after = 'res://build/luoyang_regions_20261027d_source01/culture_business_snapshot01.gd'
assert raw.count(before.encode()) == 2
target = N / 'logical_context_bridge_business02.gd'
assert not target.exists()
new = raw.replace(before.encode(), after.encode()).replace(parent.name.encode(), target.name.encode())
assert new.replace(after.encode(), before.encode()).replace(target.name.encode(), parent.name.encode()) == raw
target.write_bytes(new)
proof = {'parent': parent.name, 'parent_sha256': sha(raw), 'candidate': target.name, 'sha256': sha(new), 'changes': ['SELF path', 'pure Culture preload', 'same pure Culture dependency path'], 'all_functions_unchanged': True, 'whole_utf8_inverse': True, 'canonical_writes': 0, 'engine_runs': 0}
out = N / 'bridge_business_snapshot02_whole_inverse_BUILD.json'
assert not out.exists()
out.write_text(json.dumps(proof, indent=2) + '\n', encoding='utf8', newline='\n')
print(json.dumps(proof))
