"""Only the remaining Temple paper route; inherit all eight successful bins."""
from pathlib import Path
import copy, hashlib, json

N = Path(__file__).resolve().parent
G = N.parents[1]
sha = lambda raw: hashlib.sha256(raw).hexdigest()
res = lambda p: 'res://' + p.relative_to(G).as_posix()

def fixed(path, expected):
    raw = path.read_bytes(); assert sha(raw) == expected.lower(), str(path)
    return json.loads(raw)

def create(path, raw):
    assert not path.exists(), str(path)
    path.write_bytes(raw)
    return sha(raw)

patch = fixed(G / 'build/luoyang_city_rebuild_20261027d_art01/temple_remaining_routes09_BUILD_ONLY.json', 'f121a07bbb88101275863cfb9e9afbfc8fb3c2bd956818959ee1926f84807080')
parent = G / patch['parent_author']['path'][6:]
author = fixed(parent, patch['parent_author']['sha256'])
assert len(patch['patches']) == 1
change = patch['patches'][0]
rows = [r for r in author['regions'][change['region_id']]['routes'] if r['id'] == change['id']]
assert len(rows) == 1 and rows[0]['points_px'] == change['before']
rows[0]['points_px'] = change['after']
author_raw = (json.dumps(author, ensure_ascii=False, indent=2) + '\n').encode()
author_path = N / 'regions_author05_temple_route_residual_BUILD.json'
author_sha = create(author_path, author_raw)
rows[0]['points_px'] = change['before']
assert (json.dumps(author, ensure_ascii=False, indent=2) + '\n').encode() == parent.read_bytes()

actual = fixed(G / patch['actual_failure_result']['path'][6:], patch['actual_failure_result']['sha256'])
assert actual['passed'] is False and len(actual['errors']) == 1 and len(actual['rows']) == 8
inherited = copy.deepcopy(actual['rows'])
for row in inherited:
    binding = row['compiled']; raw = (G / binding['path'][6:]).read_bytes()
    assert sha(raw) == binding['sha256'] and len(raw) == binding['bytes']
    row['inherited'] = True
    row['credit'] = 'Prior successful compiled component only; whole prior failure retained. No recomputation or Field credit.'
worker0 = N / 'two_courts_residual_worker_ROOT_READY02.gd'
before = worker0.read_bytes()
assert sha(before) == '03abc009ef97d49994ba9dab32d72196636d5e23589bf58eeedd44b0c0693ba7'
new = before.replace(b'var ids: Array = ["luoyang_estate_region_27d", "luoyang_temple_region_27d"]', b'var ids: Array = ["luoyang_temple_region_27d"]')
new = new.replace(b'## Only two outdoor residuals. Seven successful compiled bins are inherited;', b'## Only Temple paper-route residual. Eight successful compiled bins inherited;')
worker = N / 'temple_last_route_worker_ROOT_READY03.gd'
worker_sha = create(worker, new)
input0 = N / 'two_courts_residual_input_ROOT_READY02.json'
data = fixed(input0, 'a4d63c5895e7e9e228f9601f2957b4904967654bd75beb3826bad23b27b52e1b')
data['author'] = {'path': res(author_path), 'sha256': author_sha, 'bytes': len(author_raw)}
data['inherited_rows'] = inherited
data['module_sources'].pop(res(worker0)); data['module_sources'][res(worker)] = worker_sha
data['output_root'] = res(N / 'temple_last_route_compile_output')
data['scope'] = 'Only ART09 Temple paper-turnin route. Eight successful components inherited. No owner, geometry, body, ground, interaction or media alteration.'
inp = N / 'temple_last_route_input_ROOT_READY03.json'
input_sha = create(inp, (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode())
boot = (N / 'two_courts_residual_bootstrap_ROOT_READY02.gd').read_bytes().replace(input0.name.encode(), inp.name.encode()).replace('a4d63c5895e7e9e228f9601f2957b4904967654bd75beb3826bad23b27b52e1b'.encode(), input_sha.encode()).replace(worker0.name.encode(), worker.name.encode()).replace(sha(before).encode(), worker_sha.encode())
bootstrap = N / 'temple_last_route_bootstrap_ROOT_READY03.gd'
bootstrap_sha = create(bootstrap, boot)
print(json.dumps({'author_sha256': author_sha, 'whole_author_inverse': True, 'input': res(inp), 'input_sha256': input_sha, 'worker_sha256': worker_sha, 'bootstrap': res(bootstrap), 'bootstrap_sha256': bootstrap_sha, 'inherited': 8, 'residuals': 1}))
