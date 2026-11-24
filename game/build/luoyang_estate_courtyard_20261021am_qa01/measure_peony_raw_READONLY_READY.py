"""Root-only single raw flowerbed measurement; no image edits/import/engine."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image

PNG = 'assets/raw/luoyang_estate_courtyard_20261021am/estate_low_stone_peony_bed_v2.png'
PNG_SHA = 'facd43db0e6bd9e52ef318f4764aa7010f9f5b1e6e418d6778217647c4e6e155'
SPEC = 'prompts/luoyang_estate_courtyard_20261021am/estate_low_stone_peony_bed_v2.spec.json'
SPEC_SHA = 'af0497923babdcde7a7925e0c1f339c2160d4b6bbadb9bdbd37757a5b02a09c4'
HELPER = 'game/build/luoyang_city_completion_20261021ai_qa01/verify_two_frontages_readonly.py'
HELPER_SHA = '418637ce7848ca20fb8f01f75a415203374b5f31b203755a505fc685d98b252e'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fact(path):
    stat = path.stat()
    return dict(path=str(path), sha256=sha(path), bytes=stat.st_size, mtime_ns=str(stat.st_mtime_ns))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', default='F:/Code/RPG_GAME')
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    root = Path(args.workspace).resolve(strict=True)
    output = Path(args.output).resolve()
    if output.parent != Path(__file__).resolve().parent or output.suffix != '.json' or output.exists():
        raise ValueError('NEW_JSON_IN_AM_QA01_ONLY_NO_OVERWRITE')
    paths = [Path(__file__).resolve(), root/PNG, root/SPEC, root/HELPER]
    result = dict(scope='AM_SINGLE_ORIGINAL_RAW_A1_WEAK_ALPHA_RATIO_AND_UNIFORM300_PROBE_NOT_ART_OR_GEOMETRY',
                  passed=False, quality_admitted=False, checks=[], failures=[],
                  source_first=[fact(path) for path in paths], source_final=[],
                  threshold_or_image_modification=False, engine_or_import=False)
    def check(label, passed, detail=None):
        row = dict(check=label, passed=bool(passed), detail=detail)
        result['checks'].append(row)
        if not passed:
            result['failures'].append(row)
    try:
        for relative, expected in ((PNG, PNG_SHA), (SPEC, SPEC_SHA), (HELPER, HELPER_SHA)):
            if sha(root/relative) != expected:
                raise ValueError('FROZEN_ORIGINAL_INPUT_CHANGED:' + relative)
        spec = json.loads((root/SPEC).read_text(encoding='utf-8-sig'))
        contract = spec['measurement_contract']
        loader = importlib.util.spec_from_file_location('am_stats_only', root/HELPER)
        module = importlib.util.module_from_spec(loader)
        loader.loader.exec_module(module)  # Stats only; never invoke old facade policies or CLI.
        with Image.open(root/PNG) as image:
            if image.format != 'PNG' or image.mode != contract['mode'] or image.mode != 'RGBA':
                raise ValueError('NATIVE_RGBA_PNG_REQUIRED')
            image.load()
            rgba = np.array(image, dtype=np.uint8, copy=True)
        measured = module.full_alpha_stats(rgba)
        width, height = measured['a1_width'], measured['a1_height']
        ratio = width/height
        nominal_scale = 300/width
        minimum_scale = max(contract['target_world_complete_A1_width_px'][0]/width,
                            contract['target_world_complete_A1_height_px'][0]/height)
        maximum_scale = min(contract['target_world_complete_A1_width_px'][1]/width,
                            contract['target_world_complete_A1_height_px'][1]/height)
        check('all_complete_A1_four_margins_ge_original15_percent',
              all(value >= contract['minimum_true_transparent_margin_each_side_fraction'] for value in measured['margin_fractions_ltrb']), measured['margin_fractions_ltrb'])
        check('complete_A1_no_edge_touch', measured['edge_A1_counts_tblr'] == [0, 0, 0, 0], measured['edge_A1_counts_tblr'])
        check('complete_A1_width_height_ratio_original2point2_to2point8',
              contract['target_complete_A1_width_to_height_range'][0] <= ratio <= contract['target_complete_A1_width_to_height_range'][1], ratio)
        check('same_uniform_scale_can_meet_original_width280to320_and_height110to160', minimum_scale <= maximum_scale, [minimum_scale, maximum_scale])
        check('nominal_complete_A1_width300_height_meets_original110to160',
              contract['target_world_complete_A1_height_px'][0] <= height*nominal_scale <= contract['target_world_complete_A1_height_px'][1], height*nominal_scale)
        result.update(stats=measured, original_contract=contract,
                      all_A1_used_for_acceptance_including_weak_alpha=True,
                      auxiliary_A16_bbox_not_acceptance=measured['auxiliary_A16_bbox_not_acceptance'],
                      uniform_scale_interval=[minimum_scale, maximum_scale],
                      nominal_world_A1_width300_probe=dict(scale=nominal_scale, complete_A1_world_size=[300, height*nominal_scale],
                                                         full_canvas_render_size=[value*nominal_scale for value in measured['size']]),
                      ground_anchor_and_stone_foot_solid='PENDING_ROOT_ART_ACTUAL_ANNOTATION_NO_AUTOMATIC_SEGMENTATION')
    except Exception as error:
        check('measurement_exception', False, dict(type=type(error).__name__, message=str(error)))
    result['source_final'] = [fact(path) for path in paths]
    check('all_original_raw_spec_helper_and_checker_SHA_bytes_exact_mtime_unchanged', result['source_first'] == result['source_final'])
    result['checks_count'] = len(result['checks'])
    result['passed'] = 'stats' in result and not result['failures']
    with output.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(result, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps(dict(report=str(output), sha256=sha(output), passed=result['passed'],
                          checks=result['checks_count'], failures=len(result['failures']), quality_admitted=False)))
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    sys.dont_write_bytecode = True
    raise SystemExit(main())
