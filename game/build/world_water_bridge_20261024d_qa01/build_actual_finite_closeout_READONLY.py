"""Review existing small receipts and PNG file hashes; no image/native decoding."""
import hashlib
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent
GAME = BASE.parents[1]
SYSTEM = GAME / 'build/world_water_bridge_20261024d_system01/native_sample01'
PROJECT = SYSTEM / 'project'
ACTUAL = PROJECT / 'output/106820_1070953'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fixed_json(path, expected):
    assert digest(path) == expected.lower(), path
    return json.loads(path.read_text(encoding='utf-8'))


def ref(path):
    return {'path': str(path), 'sha256': digest(path)}


result_path = ACTUAL / 'result.json'
result = fixed_json(result_path, 'BDE4DB6A45753BEDF280AD578F77242C386476C58568BE1DC63FEA61DD3DE252')
process_path = SYSTEM / 'root_gpu01_process_receipt.json'
process = fixed_json(process_path, '67F941830A429A27F11B6D0B9E02F1CB532077DB17E1AF6FCF55D5EC5A200F97')
pre_path = BASE / 'pre_sample_guard_current_epoch_READY.json'
post_path = BASE / 'post_sample_guard_actual.json'
pre = fixed_json(pre_path, '1E8D5811C1CA5C747BA134A094C0E174F50BC06662787D87D6BDFF61E5AEEC70')
post = fixed_json(post_path, '3DA93989135ACFD92FD0DA40FFC289ED83B16FA42B897C4D07FB0446F1668A51')
original_pre = fixed_json(BASE / 'pre_sample_guard_actual.json', 'C730E7210B17CF976C203ECB3C18B9771DC8BC6779EA109B0ADEE4267D41F2F3')

assert result['passed'] is True and len(result['checks']) == 234
assert all(row['passed'] is True for row in result['checks'])
assert result['elapsed_ms'] == 8292 and result['NOT_FORMAL_FIELD'] is True
assert result['sources_before'] == result['sources_after'] and len(result['sources_before']) == 64
assert len(result['native_geometry_before']) == 19
assert len(result['member_sampling']) == 17 and all(row['repeat'] is False for row in result['member_sampling'])
labels = {row['label'] for row in result['checks']}
assert all('SAME_NATIVE_ARRAYS_TRANSFORMS_CAMERA_STATE:' + str(i) in labels for i in range(2))
assert result['materials']['same_RF_instance'] is True
assert result['materials']['water_alpha_discard_code_not_replaced'] is True
assert result['materials']['no_PNG_background_or_shadow_overlay'] is True
assert process['actual_natural_console_exit_code'] == 0
assert process['exit_code_from_retained_process_WaitForExit'] is True
assert process['process_stopped_by_tool'] is False and process['elapsed_wall_ms'] == 10353
assert process['script_sha256'] == process['script_after_sha256']
stdout = Path(process['stdout_path']); stderr = Path(process['stderr_path'])
assert digest(stdout) == process['stdout_sha256'] and digest(stderr) == process['stderr_sha256']
assert stderr.read_bytes() == b''
assert pre['passed'] is True and post['passed'] is True and original_pre['passed'] is False
assert len(pre['facts']) == len(post['facts']) == 111 and pre['facts'] == post['facts']
assert post['unexpected'] == [] and post['no_source_list_expansion'] is True
save_facts = [row for row in post['facts'] if any('save15' in x for x in row['origins'])]
assert len(save_facts) == 15
images = []
for row in result['images']:
    path = PROJECT / row['path'].removeprefix('res://')
    assert digest(path) == row['sha256']
    assert row['old_grain_phase_exact'] is False
    images.append(dict(path=str(path), sha256=row['sha256'], RGBA_sha256_from_engine=row['RGBA_sha256']))
assert len(images) == 2 and images[0]['RGBA_sha256_from_engine'] != images[1]['RGBA_sha256_from_engine']

report = {
    'status': 'LIMITED_ISOLATED_GPU_COMPONENT_PASS_FINAL_ART_NOT_ADMITTED',
    'actual': ref(result_path), 'retained_process': ref(process_path),
    'technical_component': {
        'passed': True, 'checks': 234, 'failures': 0, 'elapsed_ms_internal': 8292,
        'elapsed_ms_retained_process': 10353, 'natural_OS_exit': 0,
        'stderr_empty': True, 'stderr_ERROR_WARNING_SCRIPT_count': 0,
        'script_before_after_SHA_same': True, 'source_first_final_count': 64,
        'native_geometry_entries': 19, 'bridge_members': 17,
        'both_states_same_surface_arrays_transforms_camera': True,
        'same_water_RF_instance': True, 'water_alpha_discard_not_replaced': True,
        'water_bitmap_weight': 0.08, 'bank_color_weight': 0.18,
        'clamped_member_sampling_no_repeat': True,
        'no_Physics_NAV_Field_or_formal_game_credit': True,
    },
    'images_viewed': images,
    'visual_inspection': {
        'method': 'Both existing original output PNGs viewed through image viewer; displayed resized, not a new pixel/raster measurement.',
        'reference_boundary': 'Same native geometry reprojected with program materials, not a pixel-exact current-game or old baked-PNG before. Original grain phase is not exact.',
        'candidate_water': 'Fine restrained ripple detail makes the river less blank without introducing coarse bright-blue waves; limited improvement.',
        'candidate_wood': 'Grain and timber edges are easier to read than the very dark, uniformly striped reference, but pale beige timber looks washed out against the dark teal water.',
        'remaining_bridge_issue': 'Regular narrow cross-lines and thin straight rail/post geometry still read as evenly spaced flat board/grid strips. Material substitution alone has not resolved the rigid segmentation.',
        'remaining_bank_issue': 'Broad almost-parallel straight banks and repetitive flat land remain; the subtle brown tint does not establish a convincing shallow-water/wet-earth/shore hierarchy.',
        'visible_join_only': 'Visible bridge ends appear aligned with the approaches; this is not a walkability, collision, or navigation result.',
        'final_ART_admitted': False, 'deployment_admitted': False,
        'v1_seamless_certified': False, 'v2_seamFAIL_used': False,
    },
    'protection': {
        'pre_current_epoch': ref(pre_path), 'post': ref(post_path),
        'fresh_post_paths': 111, 'post_bytes_hashed': post['bytes_hashed'],
        'post_elapsed_ms': post['elapsed_ms'], 'SHA_bytes_Exactticks_all_same': True,
        'save15_current_epoch_all_same': True,
        'original_pre_FAIL_preserved': ref(BASE / 'pre_sample_guard_actual.json'),
        'prior_epoch_boundary': 'Two save files had already changed externally before this sample. Root explicitly acknowledged their freshly captured current facts as this epoch baseline. No rollback, no retroactive old-24c save equality, original FAIL retained.',
        'formal_world_source_art_deck_r1c2visual_walk_and_24c_targets_unchanged': True,
        'System_mutable_test_key_not_treated_as_canonical_source': True,
    },
    'QA_actions': {'engine': 0, 'import': 0, 'collector': 0, 'native_or_image_decode_in_this_helper': 0,
                   'production_write': 0, 'save_write': 0, 'repeat_test': 0},
    'scope_end': 'One isolated material comparison only. No whole-world ART, formal deployment, walk/physics change, seamless certification, or game-before pixel identity claim. Stop after this receipt.'
}
out = BASE / 'actual_gpu_limited_ART_and_post111_closeout_READONLY.json'
assert not out.exists(), 'NEW receipt only'
out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'path': str(out), 'sha256': digest(out), 'technical_component_pass': True, 'final_ART_admitted': False, 'post111_pass': True}))
