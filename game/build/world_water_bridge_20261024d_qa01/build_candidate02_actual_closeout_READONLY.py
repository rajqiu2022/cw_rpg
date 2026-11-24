"""Existing one-frame receipt review only; no engine/native/image decode."""
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
SYSTEM = BASE.parents[1] / 'build/world_water_bridge_20261024d_system01/native_sample01'
PROJECT = SYSTEM / 'project'


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def fixed(p, h):
    assert sha(p) == h.lower(), p
    return json.loads(p.read_text(encoding='utf-8'))


def ref(p):
    return {'path': str(p), 'sha256': sha(p)}


rp = PROJECT / 'candidate02_output/112220_965201/result.json'
r = fixed(rp, 'AFFDCFFC9E6169D72CC85608D27CA4BF28484200938FE1857C61853F90C0671B')
pp = SYSTEM / 'root_gpu02_process_receipt.json'
p = fixed(pp, '38E3BE50703AEF53FF402FE2927E428024AEC34B902B042E0471E0847F3E28BD')
gp = BASE / 'candidate02_post_sample_guard_actual.json'
g = fixed(gp, '665586858D98971A63ECF8621CDAD1C8CB6ECC38701F5FB713722FCD5BC23B89')
pre_path = BASE / 'pre_sample_guard_current_epoch_READY.json'
pre = fixed(pre_path, '1E8D5811C1CA5C747BA134A094C0E174F50BC06662787D87D6BDFF61E5AEEC70')
static_path = BASE / 'candidate02_static_delta_READONLY.json'
fixed(static_path, '768CE966762AE3BCAA0E46968F3B6EC4FFF6803C838C8CF44C3C5D336590E022')
assert r['passed'] is True and len(r['checks']) == 1688 and all(x['passed'] for x in r['checks'])
assert r['elapsed_ms'] == 5585 and r['NOT_FORMAL_FIELD'] is True
assert r['sources_before'] == r['sources_after'] and len(r['sources_before']) == 64
assert len(r['images']) == 1 and len(r['member_projection']) == 17
image = r['images'][0]
image_path = PROJECT / image['path'].removeprefix('res://')
assert sha(image_path) == image['sha256'] == '599e6ce24db41d10be6a1b5a889c7fc49649fbfcbed2d6058f919563e11951e5'
for row in r['member_projection']:
    proof = row['proof']
    assert proof['original_vertex_triangle_order_exact'] is True
    assert proof['source_vertex_SHA'] == proof['child_original_vertex_SHA']
    assert proof['source_saved_NORMAL_present'] is False
    assert proof['NORMAL_restored_from_author_UP_or_outward_Box'] is True
    assert proof['not_unchanged_full_render_array_claim'] is True
assert r['member_projection'][0]['proof']['source_vertices'] == 240
assert r['member_projection'][0]['proof']['additional_visual_side_vertices'] == 840
assert all(x['proof']['source_vertices'] == 36 and x['proof']['additional_visual_side_vertices'] == 0 for x in r['member_projection'][1:])
assert r['materials']['same_RF_instance'] is True and r['materials']['water_alpha_discard_code_not_replaced'] is True
assert r['materials']['wood_tint'] == [.58, .50, .42]
assert p['actual_natural_console_exit_code'] == 0 and p['exit_code_from_retained_process_WaitForExit'] is True
assert p['elapsed_wall_ms'] == 7426 and p['process_stopped_by_tool'] is False
assert p['script_sha256'] == p['script_after_sha256'] == '42b05721b36c0057cf921719b8eef5ba4222674083fdce4da955472dd98938e9'
for kind in ('stdout', 'stderr'):
    assert sha(Path(p[kind + '_path'])) == p[kind + '_sha256']
assert Path(p['stderr_path']).read_bytes() == b''
assert g['passed'] is True and g['unexpected'] == [] and len(g['facts']) == 111
assert pre['facts'] == g['facts']
assert len([x for x in g['facts'] if any('save15' in origin for origin in x['origins'])]) == 15

report = {
    'status': 'CANDIDATE02_SINGLE_FRAME_COMPONENT_PASS_LOCAL_BUILD_VISUAL_DIRECTION_ACCEPTABLE_NOT_FORMAL_ART',
    'actual': ref(rp), 'retained_process': ref(pp), 'static_delta_review': ref(static_path),
    'actual_summary': {
        'checks': 1688, 'failures': 0, 'passed': True, 'internal_ms': 5585,
        'retained_process_ms': 7426, 'natural_OS_exit': 0, 'empty_stderr': True,
        'source_first_final_count': 64, 'source_first_final_same': True,
        'shader_script_before_after_SHA_same': True, 'reference_repeated': False,
        'output_PNG_count': 1, 'not_formal_Field_Physics_NAV': True,
    },
    'geometry_evidence': {
        'all17_original_VERTEX_sequences_exact': True,
        'deck_original_top_vertices': 168, 'underbeam_original_vertices': 72,
        'new_visual_side_bottom_vertices': 840, 'downward_visual_depth_m': 0.06,
        'other16_members_original_vertices_each': 36,
        'all17_source_NORMAL_absent': True,
        'new_NORMAL_UV_authored_or_reconstructed': True,
        'whole_original_render_arrays_equal_claim': False,
        'correction_to_first_review': 'Saved draw evidence meshes establish expanded VERTEX positions, not the original renderer NORMAL/UV/INDEX. First-pilot identical loaded arrays do not prove exact original-game render normals or original before pixels. Previous review file remains retained with this explicit boundary correction.',
        'land_water_RF_and_physical_source_files_unchanged': True,
        'actual_Physics_NAV_travel_test': False,
    },
    'image': {**ref(image_path), 'RGBA_SHA_from_engine': image['RGBA_sha256'],
              'viewed_once': True, 'view_method': 'Original3072x1728 PNG through viewer displayed at2048x1152; no1:1 pixel measurement or QA image re-decode.'},
    'independent_visual_judgment': {
        'local_BUILD_visual_baseline_acceptable': True,
        'timber': 'Warm brown timber reads as a coherent wooden structure rather than the first candidate pale flat strip field. Grain follows the planks, board seams are legible, and the visible deck edge plus rail/post shading gives credible local depth.',
        'remaining_bridge_limits': 'Regular narrow board repetition and thin straight rails/posts remain somewhat mechanical; both landings still meet the path abruptly without a developed local abutment treatment.',
        'water': 'Dark restrained water with fine ripples remains compatible with the bridge; this single frame does not certify animation, scale across the world, or shoreline behavior elsewhere.',
        'shore': 'Near-parallel soft straight bank bands and broad homogeneous grass remain prominent. The mud tint has not produced convincing authored irregular shallow-water/wet-earth/shore transitions.',
        'causality_boundary': 'This is a combined UV/normal reconstruction, visual deck-thickness and material successor. Improved appearance cannot be attributed to texture/tint alone.',
        'formal_or_whole_world_ART_admitted': False,
        'deployment_admitted': False, 'seamless_v1_certified': False,
        'old_game_before_pixel_exact_claim': False,
    },
    'final_protection': {
        'pre': ref(pre_path), 'candidate02_post': ref(gp),
        'path_count': 111, 'bytes_hashed': g['bytes_hashed'], 'post_ms': g['elapsed_ms'],
        'SHA_bytes_Exactticks_all_same': True, 'save15_current_epoch_same': True,
        'first_post3DA939_retained': ref(BASE / 'post_sample_guard_actual.json'),
        'original_preFAIL_C730_retained': ref(BASE / 'pre_sample_guard_actual.json'),
        'epoch_boundary': 'Two save files had changed externally before first sample; Root approved current captured1E8D baseline. No retroactive24c save-equality claim or rollback.',
    },
    'QA_actions': {'engine': 0, 'import': 0, 'collector': 0, 'production_or_save_write': 0,
                   'reference_view_repeat': 0, 'candidate_view_count': 1, 'new_post111_count': 1},
    'end_state': 'This sole concentrated successor is closed. Retain as local BUILD visual direction only; no next render loop, whole-world regression, or production deployment authorized.'
}
out = BASE / 'candidate02_actual_limited_ART_final_closeout_READONLY.json'
assert not out.exists()
out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'path': str(out), 'sha256': sha(out), 'local_BUILD_visual_baseline_acceptable': True, 'formal_ART_admitted': False, 'post111_pass': True}))
