"""Root-only execution: two fixed PNG/spec/door-annotation inputs, no image writes."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

KINDS = {'scholar_study', 'mansion_gate'}
POLICY_KEYS = {'min_margin_fraction', 'a1_width_fraction_min', 'a1_width_fraction_max',
               'max_full_a1_width_over_clear_door_height', 'runtime_door_height_min',
               'runtime_door_height_max', 'runtime_full_a1_width_max'}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def fact(path):
    stat = path.stat()
    return {'path': str(path), 'sha256': sha(path.read_bytes()), 'bytes': stat.st_size,
            'mtime_ns': str(stat.st_mtime_ns)}


def require_hash(value):
    if not isinstance(value, str) or re.fullmatch(r'[a-fA-F0-9]{64}', value) is None:
        raise ValueError('EXPLICIT_FINAL_SHA_REQUIRED_NO_PENDING_INPUT')
    return value.lower()


def full_alpha_stats(rgba):
    alpha = rgba[:, :, 3]
    mask = alpha > 0
    ys, xs = np.nonzero(mask)
    if not xs.size:
        raise ValueError('EMPTY_A1')
    left, top, right, bottom = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
    height, width = alpha.shape
    labels, count = ndimage.label(mask, np.ones((3, 3), dtype=np.uint8))
    sizes = np.bincount(labels.ravel())[1:]
    components = []
    for index, bounds in enumerate(ndimage.find_objects(labels), start=1):
        components.append({'pixels': int(sizes[index - 1]), 'bbox':
                           [bounds[1].start, bounds[0].start, bounds[1].stop, bounds[0].stop]})
    components.sort(key=lambda row: (-row['pixels'], row['bbox']))
    return {'size': [width, height], 'rgba8_sha256': sha(rgba.tobytes()),
            'bbox_A1': [left, top, right, bottom], 'a1_width': right - left,
            'a1_height': bottom - top, 'a1_width_fraction': (right - left) / width,
            'margins_ltrb': [left, top, width - right, height - bottom],
            'margin_fractions_ltrb': [left / width, top / height, (width - right) / width, (height - bottom) / height],
            'edge_A1_counts_tblr': [int(mask[0].sum()), int(mask[-1].sum()), int(mask[:, 0].sum()), int(mask[:, -1].sum())],
            'alpha_histogram_256': np.bincount(alpha.ravel(), minlength=256).tolist(),
            'weak_alpha_1_to15_pixels': int(((alpha > 0) & (alpha < 16)).sum()),
            'alpha_zero_hidden_RGB_pixels': int(((alpha == 0) & np.any(rgba[:, :, :3] != 0, axis=2)).sum()),
            'component_count_8': int(count), 'all_components_8': components,
            'auxiliary_A16_bbox_not_acceptance': Image.fromarray(alpha).point(lambda a: 255 if a >= 16 else 0).getbbox()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--input', required=True)
    parser.add_argument('--input-sha256', required=True)
    parser.add_argument('--workspace', default='F:/Code/RPG_GAME')
    args = parser.parse_args()
    workspace = Path(args.workspace).resolve(strict=True)
    input_path = Path(args.input).resolve(strict=True)
    if sha(input_path.read_bytes()) != require_hash(args.input_sha256):
        raise ValueError('ROOT_FIXED_INPUT_CHANGED')
    data = json.loads(input_path.read_text(encoding='utf-8-sig'))
    if data.get('status') != 'READY_TWO_FACADE_READONLY_INPUT' or not isinstance(data.get('assets'), list) or len(data['assets']) != 2:
        raise ValueError('NOT_READY_EXACT_TWO_INPUT')
    if {row.get('kind') for row in data['assets']} != KINDS:
        raise ValueError('EXACT_STUDY_GATE_KINDS')
    report_path = workspace / 'game/build/luoyang_city_completion_20261021ai_qa01' / ('two_frontages_' + str(os.getpid()) + '.json')
    if report_path.exists():
        raise FileExistsError('PRESERVE_EXISTING_REPORT')
    report = {'scope': 'TWO_FACADE_OFFLINE_SOURCE_PIXEL_AND_ROOT_ANNOTATED_DIMENSIONS_NOT_LAYOUT_OR_IMPORT',
              'passed': False, 'checks': [], 'failures': [], 'rows': [],
              'source_first': [], 'source_final': [], 'engine_or_image_writes': False,
              'no_A16_substitute_for_A1': True, 'no_automatic_door_darkness_segmentation': True}

    def check(name, passed, detail=None):
        row = {'name': name, 'passed': bool(passed), 'detail': detail}
        report['checks'].append(row)
        if not passed:
            report['failures'].append(row)

    paths = [input_path, Path(__file__).resolve()]
    try:
        for asset in data['assets']:
            for field in ('png', 'spec', 'door_annotation'):
                path = Path(asset[field]['path']).resolve(strict=True)
                if path not in paths:
                    paths.append(path)
        report['source_first'] = [fact(path) for path in paths]
        for asset in data['assets']:
            kind = asset['kind']
            resolved = {field: Path(asset[field]['path']).resolve(strict=True) for field in ('png', 'spec', 'door_annotation')}
            for field, path in resolved.items():
                check(kind + '_' + field + '_fixed_SHA', sha(path.read_bytes()) == require_hash(asset[field]['sha256']))
            spec = json.loads(resolved['spec'].read_text(encoding='utf-8-sig'))
            policy = spec.get('qa_pixel_policy')
            if not isinstance(policy, dict) or set(policy) != POLICY_KEYS or any(type(value) not in (int, float) or not np.isfinite(value) or value <= 0 for value in policy.values()):
                raise ValueError(kind + '_SPEC_PIXEL_POLICY_MUST_BE_FINAL_EXPLICIT_NUMERIC_EXACT_KEYS')
            check(kind + '_policy_intervals', .10 <= policy['min_margin_fraction'] < .5 and
                  0 < policy['a1_width_fraction_min'] <= policy['a1_width_fraction_max'] < 1 and
                  policy['runtime_door_height_min'] <= policy['runtime_door_height_max'])
            annotation = json.loads(resolved['door_annotation'].read_text(encoding='utf-8-sig'))
            if annotation.get('reviewed_by_root') is not True or annotation.get('source_png_sha256', '').lower() != require_hash(asset['png']['sha256']):
                raise ValueError(kind + '_ACTUAL_PNG_ROOT_REVIEWED_DOOR_ANNOTATION_REQUIRED')
            with Image.open(resolved['png']) as image:
                if image.format != 'PNG' or image.mode != 'RGBA':
                    raise ValueError(kind + '_NATIVE_RGBA_PNG_REQUIRED')
                image.load()
                rgba = np.array(image, dtype=np.uint8, copy=True)
            stats = full_alpha_stats(rgba)
            segment = annotation.get('clear_door_vertical_segment_px')
            if not isinstance(segment, list) or len(segment) != 4 or any(type(value) is not int for value in segment):
                raise ValueError(kind + '_INDEPENDENT_ACTUAL_DOOR_SEGMENT_REQUIRED')
            x1, y1, x2, y2 = segment
            width, height = stats['size']
            if x1 != x2 or not 0 <= x1 < width or not 0 <= y1 < y2 < height:
                raise ValueError(kind + '_VALID_VERTICAL_APERTURE_SEGMENT_REQUIRED')
            uncertainty = annotation.get('measurement_uncertainty_px')
            if type(uncertainty) not in (int, float) or not np.isfinite(uncertainty) or uncertainty < 0 or uncertainty >= y2 - y1:
                raise ValueError(kind + '_EXPLICIT_DOOR_UNCERTAINTY_REQUIRED')
            door_low = y2 - y1 - uncertainty
            door_high = y2 - y1 + uncertainty
            minimum_scale = policy['runtime_door_height_min'] / door_low
            maximum_scale = min(policy['runtime_door_height_max'] / door_high, policy['runtime_full_a1_width_max'] / stats['a1_width'])
            check(kind + '_one_unblocked_principal_entry_visual_annotation', annotation.get('principal_entrance_count') == 1 and annotation.get('unblocked_door_and_threshold') is True)
            check(kind + '_whole_A1_margin', all(value >= policy['min_margin_fraction'] for value in stats['margin_fractions_ltrb']), stats['margin_fractions_ltrb'])
            check(kind + '_whole_A1_width_fraction', policy['a1_width_fraction_min'] <= stats['a1_width_fraction'] <= policy['a1_width_fraction_max'], stats['a1_width_fraction'])
            check(kind + '_no_A1_edge_touch', stats['edge_A1_counts_tblr'] == [0, 0, 0, 0])
            check(kind + '_complete_A1_to_door_ratio_with_uncertainty', stats['a1_width'] / door_low <= policy['max_full_a1_width_over_clear_door_height'], stats['a1_width'] / door_low)
            check(kind + '_uniform_runtime_scale_interval_nonempty', minimum_scale <= maximum_scale, [minimum_scale, maximum_scale])
            report['rows'].append({'kind': kind, 'stats': stats, 'policy': policy, 'door_annotation': annotation,
                                   'uniform_runtime_scale_interval': [minimum_scale, maximum_scale],
                                   'world_A1_size_at_minimum_scale': [stats['a1_width'] * minimum_scale, stats['a1_height'] * minimum_scale],
                                   'not_a_placement_solid_NAV_or_portal_approval': True})
    except Exception as error:
        check('measurement_exception', False, {'type': type(error).__name__, 'message': str(error)})
    finally:
        try:
            report['source_final'] = [fact(path) for path in paths]
            check('all_sources_and_tool_SHA_bytes_mtime_unchanged', report['source_first'] == report['source_final'])
        except Exception as error:
            check('source_final_exception', False, str(error))
    report['checks_count'] = len(report['checks'])
    report['passed'] = len(report['rows']) == 2 and not report['failures']
    with report_path.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps({'passed': report['passed'], 'checks_count': report['checks_count'], 'failures': len(report['failures']),
                      'report_path': str(report_path), 'report_sha256': sha(report_path.read_bytes())}))
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
