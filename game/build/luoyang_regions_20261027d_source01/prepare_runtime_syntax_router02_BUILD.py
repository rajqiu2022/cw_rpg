"""Root-requested transport only: append existing Router template to eleven."""
from pathlib import Path
import hashlib, json

N = Path(__file__).resolve().parent
G = N.parents[1]
sha = lambda raw: hashlib.sha256(raw).hexdigest()
res = lambda p: 'res://' + p.relative_to(G).as_posix()
parent = N / 'runtime_syntax_input_ROOT_READY01.json'
raw = parent.read_bytes()
assert sha(raw) == 'e15ab28b77355d2260c2b9f55a131634e20d4fab23dc729ccf02bdcf6c620b2d'
data = json.loads(raw)
router = N / 'Router_region_CANDIDATE02.gd'
router_bytes = router.read_bytes()
assert sha(router_bytes) == '3b93c208dfe7d362474927c9c8604c5ac8af237e9e0cd377fe650b99789a6545'
data['scripts'].append({'path': res(router), 'sha256': sha(router_bytes)})
data['source_sha256'][res(router)] = sha(router_bytes)
data['output_root'] = res(N / 'runtime_syntax12_output')
data['scope'] += ' Plus existing Router template only; PENDING manifest constant remains, no final seal or adoption credit.'
inp = N / 'runtime_syntax_input_ROOT_READY02.json'
assert not inp.exists()
candidate = (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode()
inp.write_bytes(candidate)
bootstrap0 = N / 'runtime_syntax_bootstrap_ROOT_READY01.gd'
boot = bootstrap0.read_bytes().replace(parent.name.encode(), inp.name.encode()).replace(sha(raw).encode(), sha(candidate).encode())
bootstrap = N / 'runtime_syntax_bootstrap_ROOT_READY02.gd'
assert not bootstrap.exists(); bootstrap.write_bytes(boot)
assert len(data['scripts']) == 12
print(json.dumps({'input': res(inp), 'input_sha256': sha(candidate), 'bootstrap': res(bootstrap), 'bootstrap_sha256': sha(boot), 'worker_unchanged_sha256': data['source_sha256']['res://build/luoyang_regions_20261027d_source01/runtime_syntax_worker_ROOT_READY01.gd'], 'appended_router_sha256': sha(router_bytes)}))
