"""Root-executed independent AH padding verifier. Never writes an image/import/save."""
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

RAW = 'assets/raw/luoyang_market_frontage_20261021ag/facade_luoyang_narrow_apothecary_single_bay_v1.png'
RAW_SHA = 'b329b4941654194b0f1e69eecdab77a67d08c437526cf589b6c7c857860f2fa9'
RAW_RGBA_SHA = '1a7df54882c2c40a7cfef06aebbd2b6d4f2d8c7c525b9445672f0eaaff1fefe2'
QA_REPORT_ROOT = 'game/build/luoyang_market_frontage_20261021ah_qa01'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def fact(path):
    stat = path.stat()
    return {'path': str(path), 'sha256': digest(path.read_bytes()),
            'bytes': stat.st_size, 'mtime_ns': str(stat.st_mtime_ns)}


def png(path):
    with Image.open(path) as image:
        if image.format != 'PNG' or image.mode != 'RGBA':
            raise ValueError('PNG_MUST_BE_NATIVE_RGBA_NOT_IMPLICIT_CONVERSION:' + str(path))
        image.load()
        return np.array(image, dtype=np.uint8, copy=True)


def alpha_stats(rgba):
    alpha = rgba[:, :, 3]
    mask = alpha > 0
    ys, xs = np.nonzero(mask)
    if xs.size == 0:
        raise ValueError('EMPTY_ALPHA')
    left, top, right, bottom = int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1
    height, width = alpha.shape
    labels, count = ndimage.label(mask, structure=np.ones((3, 3), dtype=np.uint8))
    component_sizes = np.bincount(labels.ravel())[1:]
    components = []
    for label_index, bounds in enumerate(ndimage.find_objects(labels), start=1):
        if bounds is not None:
            components.append({'pixels': int(component_sizes[label_index - 1]),
                               'bbox': [bounds[1].start, bounds[0].start, bounds[1].stop, bounds[0].stop]})
    components.sort(key=lambda row: (-row['pixels'], row['bbox']))
    return {'size': [width, height], 'rgba8_sha256': digest(rgba.tobytes()),
            'bbox_A1': [left, top, right, bottom], 'nonzero_alpha_pixels': int(mask.sum()),
            'alpha_histogram_256': np.bincount(alpha.ravel(), minlength=256).tolist(),
            'component_count_8': int(count), 'components_8': components,
            'margins_ltrb': [left, top, width - right, height - bottom],
            'margin_fractions_ltrb': [left / width, top / height, (width - right) / width, (height - bottom) / height],
            'whole_A1_width_fraction': (right - left) / width,
            'edge_A1_pixels_tblr': [int(mask[0, :].sum()), int(mask[-1, :].sum()),
                                    int(mask[:, 0].sum()), int(mask[:, -1].sum())]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', default='F:/Code/RPG_GAME')
    parser.add_argument('--candidate', required=True)
    parser.add_argument('--candidate-sha256', required=True)
    parser.add_argument('--metadata', required=True)
    parser.add_argument('--metadata-sha256', required=True)
    args = parser.parse_args()
    workspace = Path(args.workspace).resolve(strict=True)
    raw = workspace / RAW
    candidate = Path(args.candidate).resolve(strict=True)
    metadata = Path(args.metadata).resolve(strict=True)
    for value in (args.candidate_sha256, args.metadata_sha256):
        if re.fullmatch(r'[0-9a-fA-F]{64}', value) is None:
            raise ValueError('EXPLICIT_ROOT_FILE_SHA256_REQUIRED')
    if len({raw.resolve(), candidate, metadata}) != 3:
        raise ValueError('DISTINCT_RAW_CANDIDATE_METADATA_REQUIRED')
    report_path = workspace / QA_REPORT_ROOT / ('padding_verify_' + str(os.getpid()) + '.json')
    if report_path.exists():
        raise FileExistsError('PRESERVE_EXISTING_REPORT:' + str(report_path))
    report = {'scope': 'AH_OFFLINE_CANVAS_PADDING_ONLY_NOT_RUNTIME_OR_IMPORT', 'passed': False,
              'checks': [], 'failures': [], 'report_path': str(report_path),
              'source_first': [], 'source_final': [], 'engine_or_image_writes': False,
              'prior_AG_raw_margin_failure_preserved': True,
              'metadata_credit': 'Root-pinned exact JSON payload is retained for traceability; pixel checks are independent of its claims.'}

    def check(name, condition, detail=None):
        entry = {'name': name, 'passed': bool(condition)}
        if detail is not None:
            entry['detail'] = detail
        report['checks'].append(entry)
        if not condition:
            report['failures'].append(entry)

    paths = [raw, candidate, metadata, Path(__file__).resolve()]
    try:
        report['source_first'] = [fact(path) for path in paths]
        check('raw_PNG_fixed_B329', report['source_first'][0]['sha256'] == RAW_SHA)
        check('candidate_explicit_Root_SHA', report['source_first'][1]['sha256'] == args.candidate_sha256.lower())
        check('metadata_explicit_Root_SHA', report['source_first'][2]['sha256'] == args.metadata_sha256.lower())
        metadata_json = json.loads(metadata.read_text(encoding='utf-8-sig'))
        check('metadata_JSON_object', isinstance(metadata_json, dict))
        report['metadata_payload'] = metadata_json
        source_rgba, output_rgba = png(raw), png(candidate)
        source, output = alpha_stats(source_rgba), alpha_stats(output_rgba)
        report['raw'] = source
        report['candidate'] = output
        check('source_1160x1355', source['size'] == [1160, 1355])
        check('source_RGBA_fixed_1A7D', source['rgba8_sha256'] == RAW_RGBA_SHA)
        check('source_complete_A1_original_bbox', source['bbox_A1'] == [0, 9, 1144, 1262])
        check('source_224_components', source['component_count_8'] == 224)
        check('source_846466_nonzero_alpha', source['nonzero_alpha_pixels'] == 846466)
        check('output_1907x1567', output['size'] == [1907, 1567])
        if source['size'] == [1160, 1355] and output['size'] == [1907, 1567]:
            crop = output_rgba[148:1503, 382:1542, :]
            crop_bytes = crop.tobytes()
            report['crop_RGBA_sha256'] = digest(crop_bytes)
            check('all_source_RGBA_bytes_exact_at_offset382148', crop_bytes == source_rgba.tobytes())
            outside = np.ones((1567, 1907), dtype=bool)
            outside[148:1503, 382:1542] = False
            nonzero_outside = int(np.count_nonzero(np.any(output_rgba[outside] != 0, axis=1)))
            check('outside_whole_source_rectangle_all_RGBA_zero', nonzero_outside == 0, {'nonzero_RGBA_pixels': nonzero_outside})
            translated = [{'pixels': row['pixels'], 'bbox': [row['bbox'][0] + 382, row['bbox'][1] + 148,
                           row['bbox'][2] + 382, row['bbox'][3] + 148]} for row in source['components_8']]
            check('all_224_components_exact_translation_no_dust_erasure', output['components_8'] == translated)
            expected_histogram = list(source['alpha_histogram_256'])
            expected_histogram[0] += 1907 * 1567 - 1160 * 1355
            check('entire_alpha_histogram_only_added_zero_canvas', output['alpha_histogram_256'] == expected_histogram)
        check('output_complete_A1_bbox', output['bbox_A1'] == [382, 157, 1526, 1410])
        check('output_all_nonzero_alpha_pixels_retained', output['nonzero_alpha_pixels'] == source['nonzero_alpha_pixels'])
        check('output_each_A1_margin_ge10percent', all(value >= .10 for value in output['margin_fractions_ltrb']), output['margin_fractions_ltrb'])
        check('output_A1_width_50_to60percent', .50 <= output['whole_A1_width_fraction'] <= .60, output['whole_A1_width_fraction'])
        check('output_no_A1_canvas_edge_touch', output['edge_A1_pixels_tblr'] == [0, 0, 0, 0])
    except Exception as error:
        check('measurement_exception', False, {'type': type(error).__name__, 'message': str(error)})
    finally:
        try:
            report['source_final'] = [fact(path) for path in paths]
            check('all_input_and_verifier_SHA_bytes_mtime_ns_unchanged', report['source_first'] == report['source_final'])
        except Exception as error:
            check('final_source_fact_exception', False, str(error))
    report['checks_count'] = len(report['checks'])
    report['passed'] = not report['failures']
    with report_path.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(report, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps({'passed': report['passed'], 'checks_count': report['checks_count'],
                      'failures_count': len(report['failures']), 'report_path': str(report_path),
                      'report_sha256': digest(report_path.read_bytes())}))
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())
