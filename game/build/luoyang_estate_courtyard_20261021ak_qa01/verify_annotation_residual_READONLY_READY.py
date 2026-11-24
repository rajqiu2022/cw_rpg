"""Root-only residual: two complete annotation dictionaries; no PNG decoding or writes."""
import argparse
import hashlib
import json
from pathlib import Path

PRIOR = 'game/build/luoyang_estate_courtyard_20261021ak_qa01/cleaned_components_independent_result.json'
PRIOR_SHA = '10a850454d59a296bb349e8713f37f526c9ea77a0ac59cd5438872e4b124250e'
BASE = 'game/build/luoyang_estate_components_20261021ak_art01/process_spec.json'
BASE_SHA = 'd6f3693b5c85793b0b5fa59e893dc22387a7b9ff082903180d6a281883c402ae'
CONTROL = 'game/build/luoyang_estate_components_20261021ak_art01/process_spec_root_narrowfix1.json'
CONTROL_SHA = 'a4d7fb3a73cc4017366a9a44f386f272def1ecb3e7c0435921a8c2097204f155'
PROCESSOR = 'game/build/luoyang_estate_components_20261021ak_art01/process_estate_components.py'
PROCESSOR_SHA = 'deeaa71b3d60c9dd5413f09f4c27d528148c14d29187e350364f0076176ff15e'
FAILED_LABEL = 'GROUND_DOOR_SOLIDS_FOUR_COLUMN_ANNOTATION_EXACT_TRANSLATION'
SCALARS_CARRIED_BY_FROZEN_PROCESSOR = (
    'door_clear_height_px_approx', 'door_clear_height_uncertainty_px',
    'door_clear_height_px_conservative_lower',
    'door_world_height_at_target_width_px_conservative_lower',
)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def fact(path):
    stat = path.stat()
    return dict(path=str(path), sha256=sha(path), bytes=stat.st_size, mtime_ns=str(stat.st_mtime_ns))


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def expected_translated(source, offset):
    dx, dy = offset
    if any(type(value) is not int for value in offset) or len(offset) != 2:
        raise ValueError('EXACT_INTEGER_OFFSET_FROM_INHERITED_PIXEL_COMPONENT_REQUIRED')
    def point(value):
        return [value[0]+dx, value[1]+dy]
    def rect(value):
        return [value[0]+dx, value[1]+dy, value[2], value[3]]
    expected = dict(ground_anchor_px=point(source['ground_anchor_px']),
                    door_clear_rect_px=rect(source['door_clear_rect_px']),
                    solid_source_rects_px=[rect(value) for value in source['solid_source_rects_px']],
                    column_foot_centers_px=[point(value) for value in source['column_foot_centers_px']])
    for key in SCALARS_CARRIED_BY_FROZEN_PROCESSOR:
        if key in source:
            expected[key] = source[key]
    return expected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--workspace', default='F:/Code/RPG_GAME')
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    root = Path(args.workspace).resolve(strict=True)
    output = Path(args.output).resolve()
    if output.parent != Path(__file__).resolve().parent or output.suffix != '.json' or output.exists():
        raise ValueError('NEW_RESIDUAL_JSON_ONLY_NO_OVERWRITE')
    for relative, expected in ((PRIOR, PRIOR_SHA), (BASE, BASE_SHA), (CONTROL, CONTROL_SHA), (PROCESSOR, PROCESSOR_SHA)):
        if sha(root/relative) != expected:
            raise ValueError('PINNED_PRIOR_OR_AUTHOR_OR_PROCESSOR_CHANGED:' + relative)
    prior, base, control = read(root/PRIOR), read(root/BASE), read(root/CONTROL)
    prior_paths = [Path(value['path']) for value in prior['source_first']]
    if len(prior_paths) != len(set(prior_paths)):
        raise ValueError('PRIOR_UNIQUE_SOURCE_PATHS_REQUIRED')
    paths = list(dict.fromkeys(prior_paths + [Path(__file__).resolve(), root/PRIOR, root/PROCESSOR]))
    result = dict(scope='AK_TWO_ANNOTATION_RESIDUAL_PLUS_PRIOR41_PIXEL_COMPONENTS_ONLY_NOT_OLD_WHOLE_PASS_OR_FIELD',
                  passed=False, checks=0, failures=[], rows=[], quality_admitted=False,
                  prior_report=str(root/PRIOR), prior_sha256=PRIOR_SHA,
                  inherited_component_checks=41, prior_whole_passed=False,
                  png_decodes=0, image_processing_or_generation_or_engine=False,
                  source_first=[fact(path) for path in paths], source_final=[])
    def check(condition, label, detail=None):
        result['checks'] += 1
        if not bool(condition):
            result['failures'].append(dict(check=label, detail=detail))
    check(prior['passed'] is False and prior['quality_admitted'] is False and prior['checks'] == 43,
          'ORIGINAL43_CHECK_REPORT_STILL_WHOLE_FAIL')
    check(prior['failures'] == [dict(asset='main_hall_v2', check=FAILED_LABEL), dict(asset='side_room_v1', check=FAILED_LABEL)],
          'EXACT_TWO_KNOWN_ANNOTATION_FAILURES_ONLY')
    check([row['id'] for row in prior['rows']] == ['main_hall_v2', 'side_room_v1', 'corridor_v1'], 'PRIOR_THREE_COMPLETED_ROWS')
    check(prior['source_first'] == prior['source_final'], 'PRIOR_ALL_SOURCE_FACTS_FIRST_FINAL_EQUAL')
    current_prior_facts = [fact(path) for path in prior_paths]
    check(current_prior_facts == prior['source_first'], 'EVERY_PRIOR_SOURCE_CURRENT_SHA_BYTES_EXACT_MTIME_NS_EQUAL')
    check(control['base_spec_path'] == BASE and control['base_spec_sha256'].lower() == BASE_SHA, 'EXACT_BASE_CONTROL_ANCESTRY')
    assets = {row['id']: row for row in base['assets']}
    prior_rows = {row['id']: row for row in prior['rows']}
    for asset_id in ('main_hall_v2', 'side_room_v1'):
        asset = assets[asset_id]
        annotation = dict(asset['source_annotations'])
        annotation.update(control['asset_source_annotation_overrides'][asset_id])
        metadata = read(root/asset['metadata_path'])
        # Offset is inherited from the verified full-RGBA reconstruction, NOT read back from metadata.
        offset = prior_rows[asset_id]['translation']
        expected = expected_translated(annotation, offset)
        check(metadata['source_annotations'] == annotation, asset_id + '_WHOLE_SOURCE_ANNOTATION_EQUALS_FROZEN_BASE_PLUS_CONTROL')
        check(metadata['output_annotations'] == expected, asset_id + '_WHOLE_OUTPUT_ANNOTATION_EXACT_KEYS_GEOMETRY_TRANSLATED_SCALARS_UNCHANGED',
              dict(expected=expected, actual=metadata['output_annotations']))
        check(annotation['door_clear_rect_px'][3] - annotation['door_clear_height_uncertainty_px'] == annotation['door_clear_height_px_conservative_lower'],
              asset_id + '_CONSERVATIVE_DOOR_SOURCE_ARITHMETIC')
        check(metadata['output']['source_to_output_translation_px'] == offset, asset_id + '_OFFSET_SAME_PRIOR_PIXEL_COMPONENT')
        check(prior_rows[asset_id]['source_annotations'] == annotation, asset_id + '_PRIOR_SOURCE_ANNOTATION_SAME_FROZEN_AUTHORITY')
        check(prior_rows[asset_id]['output_annotations'] == expected, asset_id + '_PRIOR_RECORDED_OUTPUT_SAME_CORRECT_EXPECTATION')
        result['rows'].append(dict(id=asset_id, offset=offset, expected=expected, actual=metadata['output_annotations']))
    result['source_final'] = [fact(path) for path in paths]
    check(result['source_first'] == result['source_final'], 'ALL_RESIDUAL_AND_INHERITED_SOURCES_FIRST_FINAL_EXACT')
    check(sha(root/PRIOR) == PRIOR_SHA, 'ORIGINAL_WHOLE_FAIL_REPORT_UNMODIFIED')
    result['passed'] = not result['failures']
    result['adult_scope_from_prior_not_recomputed'] = {
        'original_AJ_all_three_adult120_scale_feasible': prior['all_three_adult120_scale_feasible'],
        'authorized_AK_all_three_adult120_scale_feasible': prior['authorized_AK_all_three_adult120_scale_feasible'],
    }
    with output.open('x', encoding='utf-8', newline='\n') as stream:
        json.dump(result, stream, ensure_ascii=False, indent=2)
        stream.write('\n')
    print(json.dumps(dict(report=str(output), sha256=sha(output), passed=result['passed'], checks=result['checks'],
                          failures=len(result['failures']), inherited_components=41, prior_whole_passed=False, png_decodes=0)))
    return 0 if result['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
