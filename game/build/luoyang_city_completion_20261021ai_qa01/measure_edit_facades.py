"""Root executes once per raw/edit cohort; reads PNGs/specs, writes only a NEW JSON."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image

HELPER_SHA = '418637ce7848ca20fb8f01f75a415203374b5f31b203755a505fc685d98b252e'

EDIT_SPEC_PINS = {
    'facade_luoyang_narrow_scholar_study_single_bay_v2_roof_identity_margin_edit.spec.json':
        '3c8e71cd2f535499e9a191c1c9172ea05853f2b9f54f0add53229ea3cf5d9dc0',
    'facade_luoyang_independent_mansion_gate_single_bay_v2_edge_margin_edit.spec.json':
        'f63644210fb44d2f052cbbd7b6d8b4a28a622ac722f5891bd81622c15967c48b',
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fact(path):
    stat = path.stat()
    return {'path': str(path), 'sha256': sha(path), 'bytes': stat.st_size, 'mtime_ns': str(stat.st_mtime_ns)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--png', action='append', required=True)
    parser.add_argument('--sha256', action='append', required=True)
    parser.add_argument('--spec', action='append', required=True)
    parser.add_argument('--spec-sha256', action='append', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    if any(len(items) != 2 for items in (args.png, args.sha256, args.spec, args.spec_sha256)):
        raise ValueError('EXACT_TWO_PNG_AND_SPEC_INPUTS')
    helper = Path(__file__).with_name('verify_two_frontages_readonly.py').resolve(strict=True)
    if sha(helper) != HELPER_SHA:
        raise ValueError('PINNED_READONLY_STATS_HELPER_CHANGED')
    loader = importlib.util.spec_from_file_location('ai_png_stats', helper)
    module = importlib.util.module_from_spec(loader)
    loader.loader.exec_module(module)  # Definitions only; its __main__ is not invoked.
    output = Path(args.output).resolve()
    if output.parent != Path(__file__).resolve().parent or output.exists() or output.suffix != '.json':
        raise ValueError('NEW_JSON_OUTPUT_MUST_BE_IN_AI_QA01_NO_OVERWRITE')
    paths = [Path(__file__).resolve(), helper]
    images = [Path(value).resolve(strict=True) for value in args.png]
    specs = [Path(value).resolve(strict=True) for value in args.spec]
    if len(set(images)) != 2 or len(set(specs)) != 2:
        raise ValueError('DISTINCT_TWO_IMAGE_AND_SPEC_PATHS')
    paths += images + specs
    first = [fact(path) for path in paths]
    report = {'scope': 'FROZEN_EDIT_COHORT_READONLY_A1_SCHEMA_SUCCESSOR_NOT_ART_RUNTIME_APPROVAL',
              'measurement_complete': False, 'passed': False, 'rows': [], 'failures': [],
              'source_first': first, 'source_final': [], 'quality_admitted': False,
              'metadata_required': False, 'image_or_engine_or_import_writes': False,
              'door_and_role_visual_review': 'PENDING_INDEPENDENT_ACTUAL_IMAGE_ANNOTATION_NO_AUTOMATIC_DARKNESS_SEGMENTATION'}
    try:
        for index, (image_path, spec_path) in enumerate(zip(images, specs)):
            if sha(image_path) != module.require_hash(args.sha256[index]) or sha(spec_path) != module.require_hash(args.spec_sha256[index]):
                raise ValueError('FIXED_PNG_OR_SPEC_SHA_CHANGED')
            spec = json.loads(spec_path.read_text(encoding='utf-8-sig'))
            if spec_path.name not in EDIT_SPEC_PINS or sha(spec_path) != EDIT_SPEC_PINS[spec_path.name]:
                raise ValueError('EXACT_FROZEN_TWO_EDIT_SPEC_SHA_REQUIRED')
            policy = spec['required_actual_checks'].copy()
            targeted = spec['required_targeted_changes']
            policy['transparent_margin_each_side_min_fraction_at_a1'] = targeted['true_transparent_margin_each_side_min_fraction_at_a1']
            policy['a1_bbox_canvas_width_fraction_range'] = targeted['a1_bbox_canvas_width_fraction_range']
            with Image.open(image_path) as image:
                if image.format != 'PNG' or image.mode != 'RGBA':
                    raise ValueError('NATIVE_RGBA_PNG_REQUIRED')
                image.load()
                stats = module.full_alpha_stats(np.array(image, dtype=np.uint8, copy=True))
            gates = {
                'all_A1_margins': all(value >= policy['transparent_margin_each_side_min_fraction_at_a1'] for value in stats['margin_fractions_ltrb']),
                'all_A1_width_fraction': policy['a1_bbox_canvas_width_fraction_range'][0] <= stats['a1_width_fraction'] <= policy['a1_bbox_canvas_width_fraction_range'][1],
                'no_A1_edge_contact': stats['edge_A1_counts_tblr'] == [0, 0, 0, 0]}
            row = {'png': str(image_path), 'spec': str(spec_path), 'task_id': spec.get('task_id'),
                   'stats': stats, 'pixel_gates': gates, 'pixel_gate_passed': all(gates.values()),
                   'door_height_and_ratio_not_inferred': True,
                   'door_contract_preserved_pending_actual_annotation': {
                       'max_full_A1_width_to_door_height': policy['complete_a1_bbox_width_over_clear_door_height_max'],
                       'runtime_door_height_range': policy['runtime_feasible_clear_door_height_px_range'],
                       'runtime_complete_width_max': policy['runtime_complete_width_px_max']}}
            report['rows'].append(row)
            for name, passed in gates.items():
                if not passed:
                    report['failures'].append({'png': str(image_path), 'check': name})
        report['measurement_complete'] = True
    except Exception as error:
        report['failures'].append({'measurement_exception': type(error).__name__, 'message': str(error)})
    report['source_final'] = [fact(path) for path in paths]
    if report['source_final'] != first:
        report['failures'].append({'check': 'all_inputs_and_tool_SHA_bytes_mtime_unchanged'})
    report['passed'] = report['measurement_complete'] and not report['failures']
    with output.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps({'measurement_complete': report['measurement_complete'], 'pixel_gates_passed': report['passed'],
                      'quality_admitted': False, 'report_path': str(output), 'report_sha256': sha(output)}))
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.dont_write_bytecode = True
    sys.exit(main())
