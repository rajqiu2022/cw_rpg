"""Small fixed-file static review; never loads native resources or launches engine."""
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
P = BASE.parents[1] / 'build/world_water_bridge_20261024d_system01/native_sample01/project'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


pins = {
    'sample_candidate03_ROOT_READY.gd': '42b05721b36c0057cf921719b8eef5ba4222674083fdce4da955472dd98938e9',
    'input_candidate02_ROOT_READY.json': '2362787b85a58bbc51e2941fd3ab53bac9d5a1256d63afdaba43cb7f7a30e8bc',
    'member_projection02.gd': '7a66176634c7b437a2670267241d4c439e0d3c633cfca9664f0f9d62e9c7994b',
    'wood_member_uv02.gdshader': '0f8aec3bc845c807983187b0e9c3be9361f31f351743c37d4ff184d4133d36e9',
    'project.godot': 'd92e36d4cbdef6815e4a7d1dfcd5d5ae7f36aa3b745352917bd6df0e5e67f9aa',
}
for name, expected in pins.items():
    assert sha(P / name) == expected
before = json.loads((P / 'input_ROOT_READY.json').read_text(encoding='utf-8'))
after = json.loads((P / 'input_candidate02_ROOT_READY.json').read_text(encoding='utf-8'))
delta = sorted(k for k in set(before) | set(after) if before.get(k) != after.get(k))
assert delta == ['deck_successor', 'material', 'output_prefix', 'scope', 'status', 'unresolved']
assert before['source_pins'] == after['source_pins'] and len(after['source_pins']) == 59
assert before['bridge'] == after['bridge'] and len(after['bridge']['parts']) == 17
assert before['camera'] == after['camera'] and before['deadline_ms'] == after['deadline_ms'] == 60000
assert after['scope']['render_png_count'] == 1 and after['scope']['reference_repeated'] is False
assert after['scope']['source_mesh_arrays_and_transforms_unchanged'] is False
assert after['deck_successor']['plank_count'] == len(after['deck_successor']['board_UV_windows']) == 28
assert after['material']['wood_tint'] == [.58, .50, .42] and after['material']['side_multiplier'] == .88
key = (P / 'sample_candidate03_ROOT_READY.gd').read_text(encoding='utf-8')
helper = (P / 'member_projection02.gd').read_text(encoding='utf-8')
shader = (P / 'wood_member_uv02.gdshader').read_text(encoding='utf-8')
assert 'material.set_shader_parameter("warm_tint",Vector3(tint[0],tint[1],tint[2]))' in key
assert 'material.get_shader_parameter("warm_tint")==Vector3(.58,.50,.42)' in key
assert 'uniform vec3 warm_tint=vec3(.58,.50,.42);' in shader
assert 'source[start+3]==p1 and source[start+5]==p2' in helper
assert 'new_source==source' in helper and 'extra.v.size()==840' in helper
assert 'direction<0: normal=-normal' in helper and 'skew.inverse()' in helper
assert 'for state: int in range(2)' not in key
assert '[autoload]' not in (P / 'project.godot').read_text(encoding='utf-8')
report = {
    'status': 'SINGLE_CANDIDATE02_STATIC_DELTA_NO_BLOCKER_NOT_RUNTIME_OR_ART',
    'fixed_files': [{'path': str(P / n), 'sha256': h} for n, h in pins.items()],
    'fixture_changed_top_keys': delta,
    'unchanged': ['59 source pins', '17 original member declarations', 'camera', '60s deadline', 'private no-autoload project', 'two raw v1 art files', 'physical17/land/water/RF/nav source files'],
    'geometry_scope': {
        'old_evidence_correction': 'Expanded VERTEX proof meshes do not establish saved original render NORMAL/UV/INDEX arrays. First-pilot positions are not full original-render reproduction.',
        'top': '28 source quads retain q0,q1,q2,q1,q3,q2 positions/order; actual skew basis supplies UV; authored UP supplies top normals.',
        'other_original_vertices': 'Original72 underbeam and16 Box positions/order retained; missing flat normals derived from face and center-outward sign. Original full render-array equality explicitly not claimed.',
        'new_visual_only': '28 planks gain840 side/bottom vertices, only downward0.06m; originalY0 sequence stays same. No Physics or NAV implementation.',
    },
    'material_scope': 'warm_tint exact vec3 and runtime getter assertion; side .88; water .08; bank texture-dependent discontinuous band up to .38 and rock up to .06; existing alpha/discard code not replaced.',
    'execution_scope': 'Exactly one candidate PNG, no reference repeat, private output; Root alone executes.',
    'QA_engine_import_native_decode_collector_formal_writes': 0,
    'static_blocker_found': False,
    'later_requirement': 'Review sole actual PNG and retained process, then NEW candidate02_post using same acknowledged pre1E8D111 list. Preserve original intermediate post3DA939 and original pre FAIL.',
}
out = BASE / 'candidate02_static_delta_READONLY.json'
assert not out.exists()
out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'path': str(out), 'sha256': sha(out), 'static_blocker_found': False}))
