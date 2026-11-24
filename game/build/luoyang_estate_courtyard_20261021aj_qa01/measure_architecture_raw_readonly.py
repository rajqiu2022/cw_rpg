"""Root-only AJ PNG measurement; complete A1 world-width scaling, no image writes."""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import sys

import numpy as np
from PIL import Image

SPEC_PINS = {
    'estate_private_reception_hall_three_bay_v1_render_scale_successor.spec.json':
        ('hall', '9acd82166a6a495e4cd3582c3429611ba6bca28b86411881e7097894cc8bc60d'),
    'estate_low_side_room_two_bay_v1_render_scale_successor.spec.json':
        ('side_room', 'ba324f65fba9af3b9d98d22cfb10e09d1d418b6c78b4da0d3041ac5cc7550233'),
    'estate_open_corridor_four_column_v1_render_scale_successor.spec.json':
        ('corridor', 'b6b6cef9c23e0650105f53ef11540e4ca0be98b337cfa3ab53bb310565bc1d6f'),
}
STATS_HELPER = 'game/build/luoyang_city_completion_20261021ai_qa01/verify_two_frontages_readonly.py'
STATS_SHA = '418637ce7848ca20fb8f01f75a415203374b5f31b203755a505fc685d98b252e'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fact(path):
    stat = path.stat()
    return {'path': str(path), 'sha256': sha(path), 'bytes': stat.st_size, 'mtime_ns': str(stat.st_mtime_ns)}


def finite_point(point, width, height):
    return (isinstance(point, list) and len(point) == 2
            and all(type(value) in (int, float) and np.isfinite(value) for value in point)
            and 0 <= point[0] < width and 0 <= point[1] < height)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', default='F:/Code/RPG_GAME')
    for key in ('png', 'sha256', 'spec', 'spec-sha256'):
        parser.add_argument('--' + key, action='append', required=True)
    parser.add_argument('--annotations')
    parser.add_argument('--annotations-sha256')
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    if not 1 <= len(args.png) <= 3 or any(len(values) != len(args.png) for values in (args.sha256, args.spec, args.spec_sha256)):
        raise ValueError('ONE_TO_THREE_EXPLICIT_PNG_SPEC_PAIRS')
    workspace = Path(args.workspace).resolve(strict=True)
    helper = (workspace / STATS_HELPER).resolve(strict=True)
    if sha(helper) != STATS_SHA:
        raise ValueError('PINNED_STATS_ONLY_HELPER_CHANGED')
    loader = importlib.util.spec_from_file_location('aj_alpha_stats', helper)
    module = importlib.util.module_from_spec(loader)
    loader.loader.exec_module(module)  # Its CLI and narrow-facade policy are never invoked.
    output = Path(args.output).resolve()
    if output.parent != Path(__file__).resolve().parent or output.exists() or output.suffix != '.json':
        raise ValueError('NEW_JSON_ONLY_IN_AJ_QA01_NO_OVERWRITE')
    images = [Path(path).resolve(strict=True) for path in args.png]
    specs = [Path(path).resolve(strict=True) for path in args.spec]
    if len(set(images)) != len(images) or len(set(specs)) != len(specs):
        raise ValueError('NO_DUPLICATE_INPUTS')
    paths = [Path(__file__).resolve(), helper] + images + specs
    annotations = {}
    if args.annotations:
        annotation_path = Path(args.annotations).resolve(strict=True)
        if sha(annotation_path) != module.require_hash(args.annotations_sha256):
            raise ValueError('EXPLICIT_ROOT_ANNOTATION_SHA_REQUIRED')
        annotations = json.loads(annotation_path.read_text(encoding='utf-8-sig'))
        paths.append(annotation_path)
    report = {'scope': 'AJ_RAW_COMPLETE_A1_PIXELS_AND_ANNOTATED_DIMENSIONS_NOT_GEOMETRY_OR_ART_ADMISSION',
              'passed': False, 'measurement_complete': False, 'quality_admitted': False,
              'rows': [], 'failures': [], 'source_first': [fact(path) for path in paths], 'source_final': [],
              'old_50to60_width_fraction_or2point3_ratio_applied': False,
              'width_basis': 'complete_A1_world_bbox', 'image_or_import_or_engine_writes': False}
    try:
        for index, (image_path, spec_path) in enumerate(zip(images, specs)):
            if spec_path.name not in SPEC_PINS:
                raise ValueError('ONLY_FROZEN_AJ_ROLE_SPEC_ALLOWED')
            kind, expected_spec_sha = SPEC_PINS[spec_path.name]
            if sha(spec_path) != expected_spec_sha or sha(spec_path) != module.require_hash(args.spec_sha256[index]) or sha(image_path) != module.require_hash(args.sha256[index]):
                raise ValueError('FIXED_ROLE_SPEC_OR_IMAGE_SHA_CHANGED')
            spec = json.loads(spec_path.read_text(encoding='utf-8-sig'))
            contract = spec['render_scale_contract']
            if contract['width_basis'] != 'complete_A1_world_bbox' or contract['uniform_scale_source'] != 'world_A1_width/source_A1_width' or not contract['weak_alpha_must_not_be_discarded_or_thresholded']:
                raise ValueError('ROOT_COMPLETE_A1_SCALE_CONTRACT_REQUIRED')
            with Image.open(image_path) as image:
                if image.format != 'PNG' or image.mode != 'RGBA':
                    raise ValueError('NATIVE_RGBA_PNG_REQUIRED')
                image.load()
                rgba = np.array(image, dtype=np.uint8, copy=True)
            stats = module.full_alpha_stats(rgba)
            target = spec['runtime_target']
            minimum_width = target.get('complete_A1_world_width_px_min', target.get('complete_A1_world_width_px_approx'))
            maximum_width = target.get('complete_A1_world_width_px_max', target.get('complete_A1_world_width_px_approx'))
            minimum_scale = minimum_width / stats['a1_width']
            maximum_scale = min(maximum_width / stats['a1_width'], target['complete_A1_world_height_px_max'] / stats['a1_height'])
            gates = {'all_A1_margin_ge_spec': all(value >= spec['alpha_acceptance']['minimum_true_transparent_margin_fraction_each_side'] for value in stats['margin_fractions_ltrb']),
                     'no_A1_edge_touch': stats['edge_A1_counts_tblr'] == [0, 0, 0, 0],
                     'full_A1_width_height_uniform_scale_feasible': minimum_scale <= maximum_scale}
            row = {'kind': kind, 'task_id': spec['task_id'], 'png': str(image_path), 'stats': stats,
                   'pixel_gates': gates, 'runtime_target': target, 'width_basis': contract['width_basis'],
                   'main_hall_approx760_is_nominal_probe_not_invented_tolerance': kind == 'hall',
                   'door_foot_or_columns_status': 'PENDING_ROOT_ACTUAL_PNG_ANNOTATION',
                   'uniform_scale_interval_before_manual_aperture': [minimum_scale, maximum_scale]}
            annotation = annotations.get(kind) if isinstance(annotations, dict) else None
            if annotation is not None:
                if annotation.get('reviewed_by_root') is not True or annotation.get('png_sha256', '').lower() != sha(image_path):
                    raise ValueError('INDEPENDENT_ACTUAL_PNG_ROOT_ANNOTATION_REQUIRED')
                width, height = stats['size']
                ground = annotation.get('ground_anchor_px')
                if not finite_point(ground, width, height):
                    raise ValueError('EXPLICIT_ACTUAL_SOURCE_GROUND_ANCHOR_REQUIRED')
                row['ground_anchor_px'] = ground
                if kind != 'corridor':
                    segment = annotation.get('clear_door_vertical_segment_px')
                    uncertainty = annotation.get('measurement_uncertainty_px')
                    if not isinstance(segment, list) or len(segment) != 4 or not finite_point(segment[:2], width, height) or not finite_point(segment[2:], width, height) or segment[0] != segment[2] or segment[3] <= segment[1]:
                        raise ValueError('ACTUAL_NET_DOOR_VERTICAL_SEGMENT_REQUIRED')
                    if type(uncertainty) not in (int, float) or not np.isfinite(uncertainty) or uncertainty < 0 or uncertainty >= segment[3] - segment[1]:
                        raise ValueError('EXPLICIT_NONNEGATIVE_SOURCE_DOOR_UNCERTAINTY_REQUIRED')
                    conservative_door = segment[3] - segment[1] - uncertainty
                    minimum_scale = max(minimum_scale, target['clear_door_world_height_px_min'] / conservative_door)
                    gates['conservative_door_and_complete_A1_height_same_scale_feasible'] = minimum_scale <= maximum_scale
                    row['conservative_source_door_height_px'] = conservative_door
                    row['conservative_world_door_height_at_min_scale'] = conservative_door * minimum_scale
                else:
                    feet = annotation.get('column_feet_px')
                    gaps = annotation.get('transparent_intercolumn_rects_px')
                    if not isinstance(feet, list) or len(feet) != 4 or not all(finite_point(point, width, height) for point in feet) or not all(feet[i][0] < feet[i + 1][0] for i in range(3)):
                        raise ValueError('FOUR_DISTINCT_ORDERED_ACTUAL_COLUMN_FEET_REQUIRED')
                    if not isinstance(gaps, list) or len(gaps) != 3:
                        raise ValueError('THREE_ACTUAL_INTERCOLUMN_INTERIOR_RECTANGLES_REQUIRED')
                    gap_stats = []
                    for gap_index, box in enumerate(gaps):
                        if not isinstance(box, list) or len(box) != 4 or any(type(value) is not int for value in box):
                            raise ValueError('INTEGER_INTERCOLUMN_RECT_XYWH_REQUIRED')
                        x, y, box_width, box_height = box
                        if box_width <= 0 or box_height <= 0 or not 0 <= x < x + box_width <= width or not 0 <= y < y + box_height <= height or not feet[gap_index][0] < x < x + box_width < feet[gap_index + 1][0] or y < stats['bbox_A1'][1] or y + box_height > min(feet[gap_index][1], feet[gap_index + 1][1]):
                            raise ValueError('GAP_MUST_BE_INSIDE_ACTUAL_ADJACENT_COLUMNS_NOT_OUTSIDE_BACKGROUND')
                        count = int(np.count_nonzero(rgba[y:y + box_height, x:x + box_width, 3]))
                        gap_stats.append({'rect_xywh': box, 'nonzero_alpha_pixels': count})
                    gates['three_annotated_intercolumn_interiors_fully_transparent_A1'] = all(value['nonzero_alpha_pixels'] == 0 for value in gap_stats)
                    row['column_feet_px'] = feet
                    row['intercolumn_stats'] = gap_stats
                    row['corridor_opening_height_not_an_invented120px_spec'] = True
                row['door_foot_or_columns_status'] = 'MEASURED_FROM_PINNED_ROOT_ANNOTATION_NOT_FIELD_APPROVAL'
            row['uniform_scale_interval_with_manual_measurement_if_present'] = [minimum_scale, maximum_scale]
            row['render_canvas_size_at_min_scale'] = [stats['size'][0] * minimum_scale, stats['size'][1] * minimum_scale]
            row['complete_A1_world_size_at_min_scale'] = [stats['a1_width'] * minimum_scale, stats['a1_height'] * minimum_scale]
            if annotation is not None:
                left, top, right, bottom = stats['bbox_A1']
                row['complete_A1_bounds_relative_to_ground_at_min_scale'] = [(left-ground[0])*minimum_scale, (top-ground[1])*minimum_scale, (right-ground[0])*minimum_scale, (bottom-ground[1])*minimum_scale]
            report['rows'].append(row)
            for label, passed in gates.items():
                if not passed:
                    report['failures'].append({'kind': kind, 'check': label})
        report['measurement_complete'] = True
    except Exception as error:
        report['failures'].append({'measurement_exception': type(error).__name__, 'message': str(error)})
    report['source_final'] = [fact(path) for path in paths]
    if report['source_first'] != report['source_final']:
        report['failures'].append({'check': 'all_sources_and_tool_SHA_bytes_mtime_unchanged'})
    report['passed'] = report['measurement_complete'] and not report['failures']
    with output.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps({'measurement_complete': report['measurement_complete'], 'pixel_and_supplied_annotation_gates_passed': report['passed'],
                      'quality_admitted': False, 'report_path': str(output), 'report_sha256': sha(output)}))
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.dont_write_bytecode = True
    sys.exit(main())
