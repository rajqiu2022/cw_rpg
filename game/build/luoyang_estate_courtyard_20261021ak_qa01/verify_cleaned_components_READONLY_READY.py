"""Root-only AK pixel audit. Writes one NEW JSON, never images/imports/runtime."""
import argparse
import hashlib
import json
import math
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

BASE = 'game/build/luoyang_estate_components_20261021ak_art01/process_spec.json'
BASE_SHA = 'd6f3693b5c85793b0b5fa59e893dc22387a7b9ff082903180d6a281883c402ae'
CONTROL = 'game/build/luoyang_estate_components_20261021ak_art01/process_spec_root_narrowfix1.json'
CONTROL_SHA = 'a4d7fb3a73cc4017366a9a44f386f272def1ecb3e7c0435921a8c2097204f155'
TARGETS = {
    'main_hall_v2': ('estate_private_reception_hall_three_bay_v2_door_margin_edit.spec.json',
                     'ccf87220db2b1ffeb7a6c96a2b11916f643bf2c295a5326a9d25693b074e0128'),
    'side_room_v1': ('estate_low_side_room_two_bay_v1_render_scale_successor.spec.json',
                     'ba324f65fba9af3b9d98d22cfb10e09d1d418b6c78b4da0d3041ac5cc7550233'),
    'corridor_v1': ('estate_open_corridor_four_column_v1_render_scale_successor.spec.json',
                    'b6b6cef9c23e0650105f53ef11540e4ca0be98b337cfa3ab53bb310565bc1d6f'),
}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def sha(path):
    return digest(path.read_bytes())


def fact(path):
    stat = path.stat()
    return dict(path=str(path), sha256=sha(path), bytes=stat.st_size, mtime_ns=str(stat.st_mtime_ns))


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def image_array(path, mode):
    with Image.open(path) as image:
        if image.format != 'PNG' or image.mode != mode:
            raise ValueError('EXACT_NATIVE_PNG_MODE_REQUIRED:' + str(path))
        image.load()
        return np.array(image, dtype=np.uint8, copy=True)


def box(mask):
    yy, xx = np.nonzero(mask)
    if len(xx) == 0:
        raise ValueError('EMPTY_COMPLETE_A1')
    return [int(xx.min()), int(yy.min()), int(xx.max()) + 1, int(yy.max()) + 1]


def stats(rgba):
    alpha = rgba[:, :, 3]
    height, width = alpha.shape
    left, top, right, bottom = box(alpha > 0)
    margins = [left, top, width-right, height-bottom]
    return dict(size=[width, height], rgba8_sha256=digest(rgba.tobytes()),
                complete_A1_bbox_exclusive=[left, top, right, bottom],
                complete_A1_width=right-left, complete_A1_height=bottom-top,
                nonzero_alpha_pixels=int(np.count_nonzero(alpha)),
                alpha_1_to_15_pixels=int(np.count_nonzero((alpha > 0) & (alpha < 16))),
                alpha_histogram_256=np.bincount(alpha.ravel(), minlength=256).tolist(),
                margins_ltrb=margins,
                margin_fractions_ltrb=[left/width, top/height, (width-right)/width, (height-bottom)/height],
                edge_A1_counts_tblr=[int(np.count_nonzero(alpha[0])), int(np.count_nonzero(alpha[-1])),
                                     int(np.count_nonzero(alpha[:, 0])), int(np.count_nonzero(alpha[:, -1]))])


def independent_editable(src, policy):
    alpha = src[:, :, 3]
    hidden = (alpha == 0) & np.any(src[:, :, :3] != 0, axis=2)
    if policy['kind'] == 'weak_alpha_far_from_strong_subject':
        if policy['strong_alpha_min'] != 16 or policy['preserve_weak_edge_radius_px'] != 6:
            raise ValueError('EXACT_FROZEN_WEAK_POLICY_REQUIRED')
        # Integral-window counts independently implement Chebyshev distance, not ART MaxFilter.
        strong = np.pad((alpha >= 16).astype(np.int64), ((6, 6), (6, 6)))
        integral = np.pad(strong, ((1, 0), (1, 0))).cumsum(0).cumsum(1)
        counts = integral[13:, 13:] - integral[:-13, 13:] - integral[13:, :-13] + integral[:-13, :-13]
        return hidden | ((alpha > 0) & (alpha < 16) & (counts == 0))
    if policy['kind'] == 'manual_outer_polygon':
        # Rasterize the PREDECLARED polygon, never derive a permitted mask from actual differences.
        polygon = Image.new('L', (src.shape[1], src.shape[0]), 0)
        ImageDraw.Draw(polygon).polygon([tuple(point) for point in policy['keep_polygon_px']], fill=255)
        return hidden | (np.asarray(polygon) == 0)
    raise ValueError('UNKNOWN_EDIT_POLICY')


def translated_annotations(annotation, dx, dy):
    def point(value):
        return [value[0]+dx, value[1]+dy]
    def rect(value):
        return [value[0]+dx, value[1]+dy, value[2], value[3]]
    result = dict(ground_anchor_px=point(annotation['ground_anchor_px']),
                  door_clear_rect_px=rect(annotation['door_clear_rect_px']) if annotation['door_clear_rect_px'] else None,
                  solid_source_rects_px=[rect(value) for value in annotation['solid_source_rects_px']],
                  column_foot_centers_px=[point(value) for value in annotation['column_foot_centers_px']])
    if 'open_gap_clear_vertical_landmarks_y_px' in annotation:
        result['open_gap_clear_vertical_landmarks_y_px'] = [value+dy for value in annotation['open_gap_clear_vertical_landmarks_y_px']]
        result['open_gap_clear_height_px_conservative'] = annotation['open_gap_clear_height_px_conservative']
    return result


def dimensions(asset_id, output_stats, annotation, target):
    width = output_stats['complete_A1_width']
    height = output_stats['complete_A1_height']
    minimum = target.get('complete_A1_world_width_px_min', target.get('complete_A1_world_width_px'))
    maximum = target.get('complete_A1_world_width_px_max', target.get('complete_A1_world_width_px'))
    low = minimum/width
    high = min(maximum/width, target['complete_A1_world_height_px_max']/height)
    if asset_id == 'corridor_v1':
        aperture = annotation['open_gap_clear_height_px_conservative']
    else:
        aperture = annotation['door_clear_rect_px'][3] - annotation['door_clear_height_uncertainty_px']
        if aperture != annotation['door_clear_height_px_conservative_lower']:
            raise ValueError('MANUAL_CONSERVATIVE_DOOR_ARITHMETIC_MISMATCH')
    adult_low = max(low, 120/aperture)
    ratio_limit = target.get('complete_A1_width_over_clear_door_height_max')
    ratio = width/aperture
    return dict(width_basis='COMPLETE_A1_NOT_CANVAS', scale_interval_width_and_height=[low, high],
                conservative_source_aperture_px=aperture, adult120_scale_interval=[adult_low, high],
                adult120_width_height_feasible=adult_low <= high,
                conservative_world_aperture_at_width_min=aperture*low,
                conservative_world_aperture_at_allowed_max_scale=aperture*high,
                conservative_width_aperture_ratio=ratio, additional_ratio_limit=ratio_limit,
                additional_ratio_pass=(None if ratio_limit is None else ratio <= ratio_limit),
                full_canvas_render_size_at_min_scale=[v*low for v in output_stats['size']],
                adult120_corridor_is_explicit_comparison_not_original_corridor_spec_assertion=asset_id == 'corridor_v1',
                manual_landmarks_not_runtime_geometry_credit=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', default='F:/Code/RPG_GAME')
    parser.add_argument('--processing-report-sha256', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    root = Path(args.workspace).resolve(strict=True)
    output = Path(args.output).resolve()
    if output.parent != Path(__file__).resolve().parent or output.suffix != '.json' or output.exists():
        raise ValueError('NEW_JSON_ONLY_IN_AK_QA01_NO_OVERWRITE')
    base_path, control_path = root/BASE, root/CONTROL
    if sha(base_path) != BASE_SHA or sha(control_path) != CONTROL_SHA:
        raise ValueError('FROZEN_PREDECLARED_MASK_SPEC_CHANGED')
    spec, control = read_json(base_path), read_json(control_path)
    report_path = root/control['combined_report_path']
    if len(args.processing_report_sha256) != 64 or sha(report_path) != args.processing_report_sha256.lower():
        raise ValueError('ROOT_ACTUAL_PROCESSING_REPORT_SHA_REQUIRED')
    actual = read_json(report_path)
    if [value['id'] for value in actual['rows']] != list(TARGETS) or [value['id'] for value in spec['assets']] != list(TARGETS):
        raise ValueError('EXACT_THREE_ASSET_ORDER_REQUIRED')
    paths = [Path(__file__).resolve(), base_path, control_path, report_path]
    for asset in spec['assets']:
        for key in ('source_path', 'output_path', 'editable_mask_path', 'metadata_path'):
            paths.append(root/asset[key])
        name, expected = TARGETS[asset['id']]
        target_path = root/'prompts/luoyang_estate_components_20261021aj'/name
        if sha(target_path) != expected:
            raise ValueError('ORIGINAL_DIMENSION_SPEC_CHANGED')
        paths.append(target_path)
    result = dict(scope='AK_INDEPENDENT_MASK_AND_PROTECTED_RGBA_MECHANICAL_ONLY_NOT_ART_GEOMETRY_OR_FIELD',
                  passed=False, quality_admitted=False, checks=0, failures=[], rows=[],
                  source_first=[fact(path) for path in paths], source_final=[])
    def check(condition, label, asset_id):
        result['checks'] += 1
        if not bool(condition):
            result['failures'].append(dict(asset=asset_id, check=label))
    try:
        for asset, claimed in zip(spec['assets'], actual['rows']):
            asset_id = asset['id']
            annotation = dict(asset['source_annotations'])
            annotation.update(control['asset_source_annotation_overrides'][asset_id])
            source_path, derived_path = root/asset['source_path'], root/asset['output_path']
            src, derived = image_array(source_path, 'RGBA'), image_array(derived_path, 'RGBA')
            mask = image_array(root/asset['editable_mask_path'], 'L')
            metadata_path = root/asset['metadata_path']
            meta = read_json(metadata_path)
            check(sha(source_path) == asset['source_png_sha256'].lower(), 'ORIGINAL_RAW_PNG_EXACT_SHA', asset_id)
            check(digest(src.tobytes()) == asset['source_rgba8_sha256'].lower(), 'ORIGINAL_DECODED_RGBA_EXACT_SHA', asset_id)
            check(list(src.shape[1::-1]) == asset['source_size_px'], 'RAW_EXACT_CANVAS', asset_id)
            editable = independent_editable(src, asset['cleanup_policy'])
            check(mask.shape == editable.shape and np.array_equal(mask, editable.astype(np.uint8)*255), 'MASK_EQUALS_PREDECLARED_POLICY_INDEPENDENT_RECOMPUTE', asset_id)
            cleaned = src.copy()
            cleaned[editable] = 0
            left, top, right, bottom = box(cleaned[:, :, 3] > 0)
            ww, hh = right-left, bottom-top
            px, py = math.ceil(ww*asset['padding_margin_as_fraction_of_subject_extent']), math.ceil(hh*asset['padding_margin_as_fraction_of_subject_extent'])
            dx, dy = px-left, py-top
            expected = np.zeros((hh+2*py, ww+2*px, 4), dtype=np.uint8)
            expected[py:py+hh, px:px+ww] = cleaned[top:bottom, left:right]
            check(derived.shape == expected.shape and np.array_equal(derived, expected), 'EVERY_OUTPUT_RGBA_BYTE_EQUALS_ONLY_MASK_ZERO_AND_EMPTY_CANVAS_REFRAME', asset_id)
            # Reconstruct the source coordinate image including cropped EMPTY canvas.
            restored = np.zeros_like(src)
            restored[top:bottom, left:right] = derived[py:py+hh, px:px+ww]
            changed = np.any(restored != src, axis=2)
            check(np.array_equal(restored[~editable], src[~editable]), 'ALL_PROTECTED_SOURCE_RGBA_BYTES_UNCHANGED', asset_id)
            check(not np.any(changed & ~editable), 'ALL_CHANGED_PIXELS_INSIDE_PRIOR_MASK', asset_id)
            check(not np.any(restored[editable]), 'EDITABLE_PIXELS_ONLY_ZERO_NOT_REPAINTED', asset_id)
            check(not np.any(derived[derived[:, :, 3] == 0]), 'ALL_FINAL_TRANSPARENT_PIXELS_ZERO_RGBA', asset_id)
            check(meta['source_annotations'] == annotation and meta['output_annotations'] == translated_annotations(annotation, dx, dy), 'GROUND_DOOR_SOLIDS_FOUR_COLUMN_ANNOTATION_EXACT_TRANSLATION', asset_id)
            check(meta['output']['source_to_output_translation_px'] == [dx, dy] and meta['output']['subject_resize_crop_rotate_recolor'] is False and meta['output']['transparent_canvas_reframed'] is True, 'ONLY_TRANSPARENT_CANVAS_REFRAME_NO_SUBJECT_SCALE_ROTATE_CROP', asset_id)
            check(meta['output']['png_sha256'].lower() == sha(derived_path) and meta['output']['rgba8_sha256'].lower() == digest(derived.tobytes()) and claimed['metadata']['sha256'].lower() == sha(metadata_path), 'ACTUAL_OUTPUT_AND_METADATA_HASHES_MATCH_INDEPENDENT_READ', asset_id)
            check(meta == {key: value for key, value in claimed.items() if key != 'metadata'}, 'COMBINED_REPORT_ROW_EXACT_METADATA', asset_id)
            out_stats = stats(derived)
            check(min(out_stats['margin_fractions_ltrb']) >= asset['minimum_final_canvas_margin_fraction'] and out_stats['edge_A1_counts_tblr'] == [0, 0, 0, 0], 'COMPLETE_A1_MARGIN_GE10_PERCENT_AND_NO_EDGE_TOUCH', asset_id)
            target_name, _ = TARGETS[asset_id]
            target = read_json(root/'prompts/luoyang_estate_components_20261021aj'/target_name)['runtime_target']
            dim = dimensions(asset_id, out_stats, annotation, target)
            result['rows'].append(dict(id=asset_id, source_stats=stats(src), output_stats=out_stats,
                                       mask_pixels=int(editable.sum()), protected_pixels=int((~editable).sum()),
                                       changed_source_pixels=int(changed.sum()), translation=[dx, dy],
                                       source_annotations=annotation, output_annotations=meta['output_annotations'], dimensions=dim))
    except Exception as error:
        result['failures'].append(dict(exception=type(error).__name__, message=str(error)))
    result['source_final'] = [fact(path) for path in paths]
    check(result['source_first'] == result['source_final'], 'ALL_INPUT_RAW_DERIVED_MASK_METADATA_AND_TOOL_FACTS_UNCHANGED', 'all')
    result['passed'] = len(result['rows']) == 3 and not result['failures']
    result['all_three_adult120_scale_feasible'] = len(result['rows']) == 3 and all(row['dimensions']['adult120_width_height_feasible'] for row in result['rows'])
    result['old_AJ_raw_failure_reports_unchanged_not_relabelled'] = True
    with output.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(result, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps(dict(report=str(output), sha256=sha(output), mechanical_passed=result['passed'],
                          checks=result['checks'], failures=len(result['failures']),
                          all_three_adult120_scale_feasible=result['all_three_adult120_scale_feasible'], quality_admitted=False)))
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
