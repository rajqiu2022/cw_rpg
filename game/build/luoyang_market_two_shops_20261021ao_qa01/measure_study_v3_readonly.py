"""Root executes: fixed AO study-v3 PNG/spec, optional Root-reviewed aperture note.
Reads original pixels only; emits one NEW JSON, no image/engine/import writes.
"""
import argparse
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import sys

sys.dont_write_bytecode = True
import numpy as np
from PIL import Image

RAW = 'assets/raw/luoyang_market_two_shops_20261021ao/facade_luoyang_narrow_scholar_study_single_bay_v3_ratio_margin_edit.png'
RAW_SHA = 'ab92ed6cb3f4e8ea15e4a9914a8c12c4bb7b7f8ba1793576f541eb1019b27d26'
SPEC = 'prompts/luoyang_market_two_shops_20261021ao/scholar_study_single_bay_v3_ratio_margin_edit.spec.json'
SPEC_SHA = '7d57b060a04ee89f0ff80dd4d6aca4c057f45e67fa4da8b16e56d9da19188fec'
HELPER = 'game/build/luoyang_city_completion_20261021ai_qa01/verify_two_frontages_readonly.py'
HELPER_SHA = '418637ce7848ca20fb8f01f75a415203374b5f31b203755a505fc685d98b252e'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fact(path):
    st = path.stat()
    return {'path': str(path), 'sha256': sha(path), 'bytes': st.st_size,
            'mtime_ns': str(st.st_mtime_ns)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', default='F:/Code/RPG_GAME')
    parser.add_argument('--annotation')
    parser.add_argument('--annotation-sha256')
    parser.add_argument('--output')
    args = parser.parse_args()
    workspace = Path(args.workspace).resolve(strict=True)
    own = Path(__file__).resolve(strict=True)
    raw, spec_path, helper = [(workspace / name).resolve(strict=True) for name in (RAW, SPEC, HELPER)]
    output = Path(args.output).resolve() if args.output else own.with_name(f'study_v3_readonly_{os.getpid()}.json')
    if output.parent != own.parent or output.exists() or output.suffix != '.json':
        raise ValueError('NEW_AO_QA01_JSON_ONLY_REFUSE_OVERWRITE')
    if bool(args.annotation) != bool(args.annotation_sha256):
        raise ValueError('ANNOTATION_REQUIRES_EXPLICIT_SHA_PAIR')
    paths = [own, raw, spec_path, helper]
    annotation_path = Path(args.annotation).resolve(strict=True) if args.annotation else None
    if annotation_path:
        paths.append(annotation_path)
    report = {'scope': 'AO_STUDY_V3_FIXED_RAW_READONLY_A1_AND_MANUAL_DOOR_NOT_LAYOUT_OR_RUNTIME',
              'passed': False, 'measurement_complete': False, 'quality_admitted': False,
              'checks': [], 'failures': [], 'source_first': [fact(p) for p in paths],
              'source_final': [], 'door_status': 'PENDING_ROOT_ACTUAL_IMAGE_ANNOTATION',
              'all_alpha1_to15_included': True, 'no_A16_substitution': True,
              'image_engine_import_or_production_writes': False}

    def check(name, passed, detail=None):
        row = {'name': name, 'passed': bool(passed), 'detail': detail}
        report['checks'].append(row)
        if not passed:
            report['failures'].append(row)

    try:
        if sha(raw) != RAW_SHA or sha(spec_path) != SPEC_SHA or sha(helper) != HELPER_SHA:
            raise ValueError('FIXED_PNG_SPEC_OR_STATS_HELPER_CHANGED')
        loader = importlib.util.spec_from_file_location('ao_a1_stats', helper)
        module = importlib.util.module_from_spec(loader)
        loader.loader.exec_module(module)  # Definitions only; no helper __main__.
        spec = json.loads(spec_path.read_text(encoding='utf-8-sig'))
        policy = spec['acceptance']
        if policy['complete_a1_margin_each_side_min_fraction'] != .10 or policy['complete_a1_canvas_width_fraction'] != [.50, .60] or policy['complete_a1_world_width_max_px'] != 260 or policy['complete_a1_world_height_max_px'] != 245 or policy['conservative_clear_door_height_world_px_min'] != 128 or policy['complete_a1_width_over_conservative_clear_door_height_max'] != 1.8:
            raise ValueError('EXACT_FROZEN_ACCEPTANCE_CONTRACT')
        with Image.open(raw) as image:
            if image.format != 'PNG' or image.mode != 'RGBA':
                raise ValueError('ORIGINAL_RGBA_PNG_REQUIRED_NO_CONVERSION')
            image.load()
            stats = module.full_alpha_stats(np.array(image, dtype=np.uint8, copy=True))
        report['stats'] = stats
        check('complete_A1_each_margin_at_least10_percent', all(v >= .10 for v in stats['margin_fractions_ltrb']), stats['margin_fractions_ltrb'])
        check('complete_A1_width_fraction50_to60_percent', .50 <= stats['a1_width_fraction'] <= .60, stats['a1_width_fraction'])
        check('no_nonzero_alpha_canvas_edge_contact', stats['edge_A1_counts_tblr'] == [0, 0, 0, 0], stats['edge_A1_counts_tblr'])
        report['generation_target15_percent_margins_met'] = all(v >= .15 for v in stats['margin_fractions_ltrb'])
        report['pixel_gates_passed'] = not report['failures']
        if annotation_path:
            if sha(annotation_path) != module.require_hash(args.annotation_sha256):
                raise ValueError('ROOT_FIXED_MANUAL_ANNOTATION_CHANGED')
            note = json.loads(annotation_path.read_text(encoding='utf-8-sig'))
            if note.get('reviewed_by_root') is not True or note.get('source_png_sha256', '').lower() != RAW_SHA:
                raise ValueError('ROOT_REVIEWED_ACTUAL_V3_APERTURE_REQUIRED')
            segment = note.get('clear_door_vertical_segment_px')
            anchor = note.get('ground_anchor_px')
            if not isinstance(segment, list) or len(segment) != 4 or any(type(v) is not int for v in segment):
                raise ValueError('EXPLICIT_MANUAL_VERTICAL_CLEAR_SEGMENT')
            x1, y1, x2, y2 = segment
            width, height = stats['size']
            if x1 != x2 or not 0 <= x1 < width or not 0 <= y1 < y2 < height:
                raise ValueError('CLEAR_SEGMENT_OUTSIDE_SOURCE')
            uncertainty = note.get('measurement_uncertainty_px')
            if type(uncertainty) not in (int, float) or not math.isfinite(uncertainty) or not 0 <= uncertainty < y2-y1:
                raise ValueError('EXPLICIT_FINITE_DOOR_UNCERTAINTY')
            if not isinstance(anchor, list) or len(anchor) != 2 or any(type(v) is not int for v in anchor) or not 0 <= anchor[0] < width or not 0 <= anchor[1] < height:
                raise ValueError('SOURCE_THRESHOLD_FOOT_ANCHOR_REQUIRED_NOT_ALPHA_BOTTOM')
            low = y2-y1-uncertainty
            min_scale = 128 / low
            max_scale = min(260 / stats['a1_width'], 245 / stats['a1_height'])
            ratio = stats['a1_width'] / low
            target_min = max(min_scale, 240 / stats['a1_width'])
            target_max = min(max_scale, 250 / stats['a1_width'])
            check('one_principal_opening_unblocked_manual_review', note.get('principal_entrance_count') == 1 and note.get('unblocked_door_and_threshold') is True)
            check('complete_A1_over_conservative_door_max1_8', ratio <= 1.8, ratio)
            check('uniform_scale_hardmax260x245_and_conservative_door_min128_feasible', min_scale <= max_scale, [min_scale, max_scale])
            report['door_status'] = 'MEASURED_MANUAL_SOURCE_CLEAR_SEGMENT_WITH_UNCERTAINTY'
            report['door_and_scale'] = {'annotation': note, 'conservative_source_door_px': low,
                                      'hard_uniform_scale_interval': [min_scale, max_scale],
                                      'target240_to250_width_scale_interval': [target_min, target_max],
                                      'target240_to250_feasible': target_min <= target_max,
                                      'target140_door_feasible_under_hard_max': 140 / low <= max_scale,
                                      'samples_by_complete_A1_world_width': [
                                          {'world_A1_width': w, 'uniform_scale': w/stats['a1_width'],
                                           'world_A1_height': stats['a1_height']*w/stats['a1_width'],
                                           'conservative_world_door': low*w/stats['a1_width']}
                                          for w in [240, 250, 260]],
                                      'placement_or_collision_or_portal_approved': False}
        report['measurement_complete'] = True
    except Exception as error:
        check('measurement_exception', False, {'type': type(error).__name__, 'message': str(error)})
    report['source_final'] = [fact(p) for p in paths]
    check('all_tool_raw_spec_note_SHA_bytes_mtime_unchanged', report['source_first'] == report['source_final'])
    report['checks_count'] = len(report['checks'])
    report['passed'] = report['measurement_complete'] and annotation_path is not None and not report['failures']
    with output.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps({'report_path': str(output), 'report_sha256': sha(output),
                      'measurement_complete': report['measurement_complete'], 'passed': report['passed'],
                      'checks_count': report['checks_count'], 'failures': len(report['failures']),
                      'door_status': report['door_status'], 'quality_admitted': False}))
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
