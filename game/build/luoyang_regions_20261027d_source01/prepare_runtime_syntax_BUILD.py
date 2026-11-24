"""Freeze one normal-afterautoload parse batch; no permission-dependent media."""
from pathlib import Path
import hashlib, json

N = Path(__file__).resolve().parent
G = N.parents[1]
S = G / 'build/luoyang_city_rectification_20261027d_system01'
sha = lambda raw: hashlib.sha256(raw).hexdigest()
res = lambda p: 'res://' + p.relative_to(G).as_posix()
scripts = [N / name for name in ['region_field.gd', 'region_entry.gd', 'router_region_dispatch.gd', 'region_session.gd', 'region_phase_scope.gd', 'region_actor_visuals.gd', 'region_source_context.gd']]
fixed_system = {'region_render_auxiliary.gd': '9f9564f5979a4b8dc139c0bbf0cf28d5936f15ba2fc86588545353d5de2e2944', 'culture_definition.gd': 'd6f0af1cebe6a7f9f3d9fc664c64f288262657254816c87dd51a17b7251ec12f', 'logical_terminal_projector04_culture_definition.gd': '6a1bdd9133fe5558aaab6a941d1aa188ccc95d4f8baaeaa29699980250bf3705', 'logical_context_bridge_culture03.gd': '232ed6c56ca8e1e9eb116d0cee9802377b33cb115fc770e77c8ad92d646beaf7'}
for name, expected in fixed_system.items():
    path = S / name
    assert sha(path.read_bytes()) == expected, name
    scripts.append(path)
worker = N / 'runtime_syntax_worker_ROOT_READY01.gd'
sources = {res(p): sha(p.read_bytes()) for p in scripts + [worker, N / 'region_compiler.gd', N / 'base_field_business_snapshot01.gd', N / 'culture_business_snapshot01.gd']}
data = {'root_authorized': True, 'authorization_scope': 'Root authorized one consolidated syntax-only load of the new runtime, not execution or adoption.', 'scripts': [{'path': res(p), 'sha256': sources[res(p)]} for p in scripts], 'source_sha256': sources, 'output_root': res(N / 'runtime_syntax_output'), 'scope': 'New Field/Entry/Router helper/session/phase/visual/source context/Atlas helper/Definition/Projector04/bridge03. No Node or owner instance, no old matrix. Transitive immutable business snapshots are load dependencies, not old owner admission.'}
inp = N / 'runtime_syntax_input_ROOT_READY01.json'
assert not inp.exists()
raw = (json.dumps(data, ensure_ascii=False, indent=2) + '\n').encode()
inp.write_bytes(raw)
boot = (N / 'civic_author_compile_bootstrap_ROOT_READY01.gd').read_bytes().replace(b'civic_author_compile_input_ROOT_READY01.json', inp.name.encode()).replace(b'451ee781789758c6d39be967c9a2240db417442efe76cfedb7884584c7c21af1', sha(raw).encode()).replace(b'civic_author_compile_worker_NOTREADY.gd', worker.name.encode()).replace(b'636d1a8a4b4167c2bea9cb9c49bb2457256247715002c6cffeb6e10275ba1f96', sources[res(worker)].encode())
bootstrap = N / 'runtime_syntax_bootstrap_ROOT_READY01.gd'
assert not bootstrap.exists(); bootstrap.write_bytes(boot)
print(json.dumps({'input': res(inp), 'input_sha256': sha(raw), 'bootstrap': res(bootstrap), 'bootstrap_sha256': sha(boot), 'worker_sha256': sources[res(worker)], 'script_count': len(scripts), 'sources': sources}))
