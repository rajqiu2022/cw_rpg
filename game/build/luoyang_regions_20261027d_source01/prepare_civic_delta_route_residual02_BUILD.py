"""ART11's one safe east approach; original worker and all geometry unchanged."""
from pathlib import Path
import hashlib, json
N = Path(__file__).resolve().parent
G = N.parents[1]
sha = lambda raw: hashlib.sha256(raw).hexdigest()
res = lambda path: 'res://' + path.relative_to(G).as_posix()
patch_path = G / 'build/luoyang_city_rebuild_20261027d_art01/civic_three_building_delta11_BUILD_ONLY.json'
raw = patch_path.read_bytes(); assert sha(raw) == 'e9f27f07c9196eb13ea3186ab4e7afc81554d6075af4d52a987f28b15b20139c'
patch = json.loads(raw)
parent = N / 'civic_three_building_delta_input_ROOT_READY01.json'
prior = parent.read_bytes(); assert sha(prior) == patch['parent_input']['sha256']
data = json.loads(prior)
assert len(patch['patches']) == 1
change = patch['patches'][0]
rows = [row for row in data['new_door_routes'] if row['id'] == change['id']]
assert len(rows) == 1 and rows[0]['points_px'] == change['before']
rows[0]['points_px'] = change['after']
data['output_root'] = res(N / 'civic_three_building_delta_residual_output')
out = N / 'civic_three_building_delta_input_ROOT_READY02.json'
assert not out.exists(); candidate = (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode(); out.write_bytes(candidate)
before = (N / 'civic_three_building_delta_bootstrap_ROOT_READY01.gd').read_bytes()
assert sha(before) == '4b4dd7bfa6907a5a6686ce2add9675258dd75e492cbb99c7b4c4af78daf48cff'
boot = before.replace(parent.name.encode(), out.name.encode()).replace(sha(prior).encode(), sha(candidate).encode())
bootstrap = N / 'civic_three_building_delta_bootstrap_ROOT_READY02.gd'
assert not bootstrap.exists(); bootstrap.write_bytes(boot)
assert sha((N / 'civic_three_building_delta_ROOT_READY.gd').read_bytes()) == '814b64432b90e8a0f5e95348b4f7228af423feaec541a119eda7d84c8ffca29b'
print(json.dumps({'input': res(out), 'input_sha256': sha(candidate), 'bootstrap': res(bootstrap), 'bootstrap_sha256': sha(boot), 'one_route_only': True, 'worker_unchanged': True}))
