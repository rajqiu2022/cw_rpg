"""Root-only verification AFTER explicit user authorization and actual processing.
Independent NumPy mask reconstruction; no processor import and no PNG writes.
"""
import argparse
import hashlib
import json
from fractions import Fraction
from pathlib import Path
import re
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image

RAW = 'assets/raw/luoyang_market_two_shops_20261021ao/facade_luoyang_narrow_scholar_study_single_bay_v3_ratio_margin_edit.png'
PROCESSED = 'assets/processed/luoyang_market_two_shops_20261021ao/facade_luoyang_narrow_scholar_study_single_bay_v3_local_cleanup_padded.png'
ART = 'game/build/luoyang_market_two_shops_20261021ao_art01/'
QA = 'game/build/luoyang_market_two_shops_20261021ao_qa01/'
FIXED = {
    RAW: 'ab92ed6cb3f4e8ea15e4a9914a8c12c4bb7b7f8ba1793576f541eb1019b27d26',
    ART+'book_v3_local_cleanup_padding.spec.json': 'c4545ca55b414df00a68a33ee739a67a023410ff5073883ef416e774da9f9af5',
    ART+'expanded_window_whole_sprite_successor_feasibility.json': '0e0181052f1cd13675846f39f5500cd94c51426a2ac2847773029786d0362c77',
    QA+'study_v3_readonly_original_contract.json': '607cf320c32746a824c6f5ec0632603350e608f2aaefe0d46c6c40a6f2ccfa1e',
    'game/build/luoyang_market_two_shops_20261021ao_root01/study_v3_manual_annotation.json': '74a25467784426dc59f342d12d3e14592cba9b91e2b9e87c399ee6205df8558b',
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fact(path):
    stat = path.stat()
    return {'path': str(path), 'sha256': sha(path), 'bytes': stat.st_size,
            'mtime_ns': str(stat.st_mtime_ns)}


def hash_arg(value):
    if not isinstance(value, str) or re.fullmatch(r'[0-9a-fA-F]{64}', value) is None:
        raise ValueError('ROOT_ACTUAL_OUTPUT_SHA_REQUIRED_NOT_PENDING')
    return value.lower()


def rgba(path, size):
    with Image.open(path) as image:
        if image.format != 'PNG' or image.mode != 'RGBA' or image.size != size:
            raise ValueError('EXACT_ORIGINAL_RGBA_PNG_AND_CANVAS_REQUIRED')
        image.load()
        return np.array(image, dtype=np.uint8, copy=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', default='F:/Code/RPG_GAME')
    parser.add_argument('--root-confirms-user-authorized-processing', action='store_true')
    parser.add_argument('--processed-sha256', required=True)
    parser.add_argument('--meta-sha256', required=True)
    parser.add_argument('--processing-report-sha256', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    if not args.root_confirms_user_authorized_processing:
        raise ValueError('STOP_UNTIL_ROOT_HAS_ACTUAL_USER_AUTHORIZATION_AND_DERIVATIVE')
    workspace = Path(args.workspace).resolve(strict=True)
    own = Path(__file__).resolve(strict=True)
    output = Path(args.output).resolve()
    if output.parent != own.parent or output.exists() or output.suffix != '.json':
        raise ValueError('NEW_AO_QA_JSON_ONLY_NO_OVERWRITE')
    bindings = dict(FIXED)
    bindings[PROCESSED] = hash_arg(args.processed_sha256)
    bindings[PROCESSED.replace('.png', '.meta.json')] = hash_arg(args.meta_sha256)
    bindings[ART+'book_v3_local_cleanup_padding_report.json'] = hash_arg(args.processing_report_sha256)
    paths = [own] + [(workspace/name).resolve(strict=True) for name in bindings]
    first = [fact(path) for path in paths]
    report = {'scope': 'AO_V3_AUTHORIZED_CLEANUP_PIXEL_IDENTITY_AND_EXPLICIT_NEW_TARGET_ONLY_NOT_LAYOUT_OR_FORMAL',
              'passed': False, 'checks': [], 'failures': [], 'source_first': first,
              'source_final': [], 'old_original_contract_pass': False,
              'quality_or_placement_or_runtime_admitted': False,
              'image_engine_import_or_production_writes': False,
              'user_authorization_attested_by_root_not_granted_by_verifier': True}

    def check(name, condition, detail=None):
        row = {'name': name, 'passed': bool(condition), 'detail': detail}
        report['checks'].append(row)
        if not condition:
            report['failures'].append(row)

    try:
        for name, expected in bindings.items():
            if sha(workspace/name) != expected:
                raise ValueError('FROZEN_RAW_CONTRACT_OR_ROOT_ACTUAL_OUTPUT_CHANGED:'+name)
        old = json.loads((workspace/(QA+'study_v3_readonly_original_contract.json')).read_text(encoding='utf-8-sig'))
        check('original607CF_wholeFAIL_preserved_not_relabelled', old.get('passed') is False and old.get('checks_count') == 7 and len(old.get('failures', [])) == 4)
        source = rgba(workspace/RAW, (1374, 1145))
        processed = rgba(workspace/PROCESSED, (1374, 1153))
        yy, xx = np.indices((1145, 1374))
        protected = (xx >= 282) & (xx < 1092) & (yy >= 174) & (yy < 1042)
        allowed = (~protected) & (source[:, :, 3] >= 1) & (source[:, :, 3] <= 15)
        check('exact245_predeclared_outside_weak_alpha_pixels', int(allowed.sum()) == 245, int(allowed.sum()))
        expected = np.zeros((1153, 1374, 4), dtype=np.uint8)
        expected[:1145] = source
        expected[:1145][allowed] = 0  # Reconstruct only in memory, never save a PNG.
        actual_changed = np.any(processed[:1145] != source, axis=2)
        check('changed_pixel_set_exactly_allowed_mask_not_hidden_RGB_or_protected_core', np.array_equal(actual_changed, allowed))
        check('protected_rectangle_full_RGBA_byte_exact', np.array_equal(processed[:1145][protected], source[protected]))
        check('all_allowed_pixels_RGBA_zero_no_threshold_edit_inside_core', np.all(processed[:1145][allowed] == 0))
        check('entire_processed_RGBA_equals_independent_reconstruction', np.array_equal(processed, expected))
        check('eight_new_bottom_rows_all_RGBA_zero_origin_unchanged', np.all(processed[1145:] == 0))
        alpha = processed[:, :, 3]
        ys, xs = np.nonzero(alpha > 0)
        if not xs.size:
            raise ValueError('EMPTY_COMPLETE_A1')
        box = [int(xs.min()), int(ys.min()), int(xs.max())+1, int(ys.max())+1]
        extent = [box[2]-box[0], box[3]-box[1]]
        margins = [box[0], box[1], 1374-box[2], 1153-box[3]]
        check('actual_complete_A1_bbox_not_A16_proxy', box == [290, 182, 1084, 1034], box)
        check('actual_complete_A1_extent794x852', extent == [794, 852], extent)
        check('all_complete_A1_margins_at_least10_percent', all(Fraction(margins[i], [1374,1153,1374,1153][i]) >= Fraction(1,10) for i in range(4)), margins)
        check('complete_A1_width_fraction50_to60_percent', Fraction(1,2) <= Fraction(extent[0],1374) <= Fraction(3,5))
        note = json.loads((workspace/'game/build/luoyang_market_two_shops_20261021ao_root01/study_v3_manual_annotation.json').read_text(encoding='utf-8-sig'))
        check('unchanged_manual_door440_uncertainty10_and_threshold_anchor', note.get('reviewed_by_root') is True and note.get('clear_door_vertical_segment_px') == [650,480,650,920] and note.get('measurement_uncertainty_px') == 10 and note.get('ground_anchor_px') == [650,930])
        scale = Fraction(268,852)
        conservative = Fraction(440-10)*scale
        ratio = Fraction(extent[0],440-10)
        check('explicit_NEW_complete_A1_worldmax250x268', extent[0]*scale <= 250 and extent[1]*scale <= 268)
        check('explicit_NEW_conservative_door_at_least135', conservative >= 135, float(conservative))
        check('explicit_NEW_width_over_conservative_door_at_most1_85', ratio <= Fraction(185,100), float(ratio))
        old_max_scale = min(Fraction(260,extent[0]), Fraction(245,extent[1]))
        check('old245_128_1_8_contract_still_FAIL_not_relabelled', Fraction(430)*old_max_scale < 128 and ratio > Fraction(18,10))
        for suffix in [PROCESSED.replace('.png','.meta.json'), ART+'book_v3_local_cleanup_padding_report.json']:
            metadata = json.loads((workspace/suffix).read_text(encoding='utf-8-sig'))
            check('processing_metadata_matches_actual_pixels_'+Path(suffix).name,
                  metadata.get('status') == 'PASS_LOCAL_CLEANUP_PADDING_DERIVATIVE_ONLY'
                  and metadata['source']['png_sha256_before'].lower() == FIXED[RAW]
                  and metadata['source']['png_sha256_after'].lower() == FIXED[RAW]
                  and metadata['output']['png_sha256'].lower() == bindings[PROCESSED]
                  and metadata['output']['rgba8_sha256'].lower() == hashlib.sha256(processed.tobytes()).hexdigest()
                  and metadata['output']['a1_bbox_exclusive'] == box
                  and metadata['mechanical_transform']['protected_rect_xyxy'] == [282,174,1092,1042]
                  and metadata['mechanical_transform']['outside_weak_alpha_pixels_zeroed'] == 245
                  and metadata['mechanical_transform']['bottom_transparent_rows_added'] == 8
                  and metadata['mechanical_transform']['original_pixels_moved'] is False
                  and metadata['mechanical_transform']['subject_resized_cropped_rotated_recolored'] is False)
        report['actual_pixels'] = {'canvas':[1374,1153], 'complete_A1_bbox':box, 'complete_A1_extent':extent,
                                   'margins_ltrb':margins, 'alpha_histogram256':np.bincount(alpha.ravel(),minlength=256).tolist(),
                                   'remaining_alpha1_to15_pixels':int(((alpha>0)&(alpha<16)).sum()),
                                   'rgba_sha256':hashlib.sha256(processed.tobytes()).hexdigest(),
                                   'protected_RGBA_sha256':hashlib.sha256(source[protected].tobytes()).hexdigest()}
        report['new_target_only'] = {'uniform_scale_fraction':[268,852], 'world_complete_A1_extent':[float(v*scale) for v in extent],
                                     'conservative_door_px':float(conservative), 'uncertainty_source_px':10,
                                     'ratio':float(ratio), 'source_ground_anchor_unchanged':[650,930],
                                     'expanded_window_side_alley_NPC_threshold_to_return_to_plus24_still_pending':True}
    except Exception as error:
        check('verification_exception', False, {'type':type(error).__name__, 'message':str(error)})
    report['source_final'] = [fact(path) for path in paths]
    check('all_raw_output_contract_metadata_and_tool_SHA_bytes_mtime_unchanged', first == report['source_final'])
    report['checks_count'] = len(report['checks'])
    report['passed'] = not report['failures']
    with output.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps({'passed':report['passed'], 'checks_count':report['checks_count'], 'failures':len(report['failures']),
                      'report_path':str(output), 'report_sha256':sha(output), 'quality_or_runtime_admitted':False}))
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
