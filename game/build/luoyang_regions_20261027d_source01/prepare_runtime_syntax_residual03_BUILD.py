"""Only Entry's local source key rename plus the four failed syntax targets."""
from pathlib import Path
import hashlib
import json

N = Path(__file__).resolve().parent
G = N.parents[1]
sha = lambda raw: hashlib.sha256(raw).hexdigest()
res = lambda p: 'res://' + p.relative_to(G).as_posix()
parent_input = N / 'runtime_syntax_input_ROOT_READY02.json'
parent_raw = parent_input.read_bytes()
assert sha(parent_raw) == 'f4c4dac05ee96b4ca1916d4803e14518bece50bb156cb0978818e58b8f849e56'
entry = N / 'region_entry.gd'
candidate = entry.read_bytes()
new = b'\tfor source_path: String in compiled.sources:\n\t\tif sources.has(source_path) and sources[source_path] != compiled.sources[source_path]: return {"matched": true, "ok": false, "error": "REGION_COMPILED_SOURCE_CONFLICT:" + source_path}\n\t\tsources[source_path] = compiled.sources[source_path]\n'
old = new.replace(b'source_path', b'path')
assert candidate.count(new) == 1
prior = candidate.replace(new, old)
assert sha(prior) == 'd02efc408e27efe7db34904bb69f494671f1393cbaeeabb422ab10155777602e'
assert prior.replace(old, new) == candidate
snapshot = N / 'region_entry_syntax12_failed_snapshot.gd'
assert not snapshot.exists()
snapshot.write_bytes(prior)
data = json.loads(parent_raw)
keep = {'region_field.gd', 'region_entry.gd', 'router_region_dispatch.gd', 'Router_region_CANDIDATE02.gd'}
data['scripts'] = [item for item in data['scripts'] if item['path'].rsplit('/', 1)[-1] in keep]
assert len(data['scripts']) == 4
for item in data['scripts']:
    if item['path'] == res(entry):
        item['sha256'] = sha(candidate)
data['source_sha256'][res(entry)] = sha(candidate)
data['output_root'] = res(N / 'runtime_syntax4_residual_output')
data['scope'] = 'Only four failed syntax targets from Root actual syntax12; Entry renames one conflicting local source key. Eight successful scripts are inherited, not targets. Original worker unchanged; no runtime admission or final manifest seal.'
out = N / 'runtime_syntax_input_ROOT_READY03.json'
assert not out.exists()
out_raw = (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode()
out.write_bytes(out_raw)
parent_bootstrap = N / 'runtime_syntax_bootstrap_ROOT_READY02.gd'
boot_raw = parent_bootstrap.read_bytes()
assert sha(boot_raw) == '6efd5b6d510e57d14720e18815808723d55675ff73f79df7eea7035f09babd33'
boot = boot_raw.replace(parent_input.name.encode(), out.name.encode()).replace(sha(parent_raw).encode(), sha(out_raw).encode())
bootstrap = N / 'runtime_syntax_bootstrap_ROOT_READY03.gd'
assert not bootstrap.exists()
bootstrap.write_bytes(boot)
worker = N / 'runtime_syntax_worker_ROOT_READY01.gd'
assert sha(worker.read_bytes()) == 'a6ac5de71527f6ea94c93160fbe6be1f2eef2315ccd96befc7697b3c1951f461'
print(json.dumps({'entry_sha256': sha(candidate), 'entry_parent_inverse_sha256': sha(prior), 'input': res(out), 'input_sha256': sha(out_raw), 'bootstrap': res(bootstrap), 'bootstrap_sha256': sha(boot), 'worker_unchanged_sha256': sha(worker.read_bytes()), 'targets': data['scripts'], 'whole_entry_inverse': True}))
