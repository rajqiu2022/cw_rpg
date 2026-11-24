"""Only the six newly extracted business consumers; prior twelve not retargeted."""
from pathlib import Path
import hashlib, json
N = Path(__file__).resolve().parent
G = N.parents[1]
T = G / 'build/luoyang_city_rectification_20261027d_system01'
sha = lambda raw: hashlib.sha256(raw).hexdigest()
res = lambda path: 'res://' + path.relative_to(G).as_posix()
names = {
    'presentation_definition.gd': '7435e9cb97eda3f5c27ac79af75aa2dd26efab645350a1c04bcd54371fb7931e',
    'logical_terminal_projector05_pure_presentation.gd': '944dfaffa18f43a4d52d737c4549603779490a274090b498b730a5cd0c434250',
    'logical_context_bridge04_pure_presentation.gd': '0d979c22aea7e90999ba4c86a2558893869c3526f5814a1a6be18c6e176bc71e',
    'temple_source_business_snapshot01.gd': '277da185ac9284446aec5b180d426b3a592745566500a2dc57f45bb39d0c87f0',
    'temple_paper_task_business_snapshot01.gd': '760b3c061fcb2133354c46ffb2443b93935766527fa9968be4c58652ffb08e1d',
    'temple_task_business_snapshot01.gd': 'd13f2bb9bd592ce8002764368dbf9054506cc39613f156de24849fee6fe72c29',
}
parent = N / 'runtime_syntax_input_ROOT_READY03.json'
raw = parent.read_bytes(); assert sha(raw) == '926efa34a4dd267d5b03fb982385c5e284d5de3398ca7c7eaa82aa105e7fd8ad'
data = json.loads(raw); data['scripts'] = []
for name, expected in names.items():
    path = T / name; assert sha(path.read_bytes()) == expected, name
    data['scripts'].append({'path': res(path), 'sha256': expected})
    data['source_sha256'][res(path)] = expected
data['output_root'] = res(N / 'pure_business6_syntax_output')
data['scope'] = 'Only six new pure-presentation/Temple business scripts from Root08 scope. Twelve prior scripts inherited; no old owner/Scene/Field instance, no definition readiness execution, no original asset/projection/geometry matrix.'
out = N / 'pure_business6_syntax_input_ROOT_READY01.json'
assert not out.exists()
candidate = (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode(); out.write_bytes(candidate)
before = (N / 'runtime_syntax_bootstrap_ROOT_READY03.gd').read_bytes()
assert sha(before) == '4fd668d6a69006a2bb40b8bc6471ced9b7c3fd7d88bc81f9bc75cba1ad4378e5'
boot = before.replace(parent.name.encode(), out.name.encode()).replace(sha(raw).encode(), sha(candidate).encode())
bootstrap = N / 'pure_business6_syntax_bootstrap_ROOT_READY01.gd'
assert not bootstrap.exists(); bootstrap.write_bytes(boot)
print(json.dumps({'input': res(out), 'input_sha256': sha(candidate), 'bootstrap': res(bootstrap), 'bootstrap_sha256': sha(boot), 'worker_unchanged': 'a6ac5de71527f6ea94c93160fbe6be1f2eef2315ccd96befc7697b3c1951f461', 'targets': names}))
