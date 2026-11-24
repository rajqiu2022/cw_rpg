"""Fixed-parent actual27 output review and owner derivation, never a collector.

Default is read-only/in-memory. Root alone may use --write-new to materialize
the two NEW generated JSON artifacts after reviewing this complete recipe.
No Stage, Godot, native decoder, canonical read/write or media/source crawl.
"""
import argparse
import copy
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
sp = importlib.util.spec_from_file_location('hall_dependencies', HERE/'prepare_dependency_successors_NOTSTAGE.py')
D = importlib.util.module_from_spec(sp)
sp.loader.exec_module(D)
O = D.OUT
PLAN = O+'source_input_ROOT_READY.json'
PLAN_SHA = '779467ec15f00e29095c9625473a3a8d5d9e4cf10f003a7de3ba0fcdb165fd0a'
RECEIPT = O+'outputs/root_hall_portal_exact27_stage01/receipt.json'
RECEIPT_SHA = 'f085977a59f3a31de20bf1910e1822ff1ad20154f75d97c4c141a3826523a235'
OWNER_PARENT = D.SOURCE+'unified101_actual_owner_READY/owner_source_maps_READY.json'
OWNER_PARENT_SHA = 'fd58f7c2dbd3372d6adbb6f9a39ba7c70568125e4f843c11dc546e750fdfd61c'
DEST = O+'actual_owner27_READY/'
AUTHORITY = 'res://scripts/city/luoyang_execution_authority_20261022ap.gd'
HELPER = 'res://build/luoyang_hall_portal_fix_20261024a_system01/mainhall_fixed_columns_CANDIDATE.gd'
HELPER_SHA = '60949742f626bcff53ff8af74de9aecd5626b8d3f50b3984419cf8d022b4ee87'
PORTAL_SHADER = 'res://build/luoyang_hall_portal_fix_20261024a_system01/portal_interaction_outline_CANDIDATE.gdshader'
PORTAL_SHADER_SHA = 'b8c19760623f931e7efcd3864dbf19e51a62fbf159d6330f01ceb1fc3a73ccbc'
G_CITY_IDS = {'ch4_s1_luoyang_yamen', 'ch4_s2_canal_docks', 'ch4_s3_luoyang_market'}


def load(p, h):
    return json.loads(D.read(p, h))


def pointer(v, ks):
    for k in ks:
        v = v[k]
    return v


def prepare():
    spec = load(PLAN, PLAN_SHA)
    stage = load(RECEIPT, RECEIPT_SHA)
    assert stage['target_partition'] == {'patch_count': 13, 'copy_count': 14, 'total': 27,
                                        'intersection_empty': True, 'union_exact_targets': True}
    assert len(stage['source_first']) == 3089 and stage['source_first'] == stage['source_final']
    assert stage['source_first'][PORTAL_SHADER] == PORTAL_SHADER_SHA
    assert stage['source_first'][HELPER] == HELPER_SHA
    actual = {r['target']: r for r in stage['targets']}
    assert len(actual) == 27 and set(actual) == set(spec['root_target_allowlist'])
    scope = D.parent_scope(O+'world_v15_exit_zone_PARENT_19665.source')
    assert {p: r['old_sha256'] for p, r in actual.items()} == {r['target']: r['old_sha256'] for r in scope['targets']}
    pins = {r['id']: r for r in spec['pinned_inputs']}
    records = load(pins['hall_code_inverse']['path'], pins['hall_code_inverse']['sha256'])['records']
    system = load(pins['hall_System_inverse']['path'], pins['hall_System_inverse']['sha256'])
    portal = next(r for r in system['existing_file_inverses'] if r['parent']['path'] == D.PORTAL)
    candidates = {p: D.read(r['candidate_path'], r['candidate_sha256']) for p, r in actual.items()}
    def resolved(x):
        if isinstance(x, dict):
            if '$pin' in x:
                return pins[x['$pin']]['sha256']
            if '$sha' in x:
                n = stage['nodes'][x['$sha']]
                return n['disabled_sha256'] if x.get('variant') == 'disabled' else n['sha256']
            if '$owned' in x:
                return stage['nodes']['execution_final']['value']['owned'][x['$owned']]['current_sha256']
            return {k: resolved(v) for k, v in x.items()}
        if isinstance(x, list):
            return [resolved(v) for v in x]
        return x
    checked = {'code_byte_inverse': 0, 'index_byte_inverse': 0, 'metadata_whole_typed_inverse': 0}
    for p, r in records.items():
        parent = D.read(r['parent']['path'], r['parent']['sha256'])
        after = candidates[p]
        assert D.sha(after) == r['candidate']['sha256'] and len(after) == r['candidate']['bytes']
        before_text, after_text = parent.decode('utf8'), after.decode('utf8')
        forward, inverse = before_text, after_text
        for h in r['hunks']:
            assert forward.count(h['old']) == inverse.count(h['new']) == 1
            forward = forward.replace(h['old'], h['new'], 1)
            inverse = inverse.replace(h['new'], h['old'], 1)
        assert forward.encode('utf8') == after and inverse.encode('utf8') == parent
        checked['code_byte_inverse'] += 1
    before = D.read(O+'world_v15_exit_zone_PARENT_19665.source', D.PORTAL_OLD_SHA)
    text = candidates[D.PORTAL].decode('utf8')
    for h in portal['operations']:
        assert text.count(h['new']) == 1
        text = text.replace(h['new'], h['old'], 1)
    assert text.encode('utf8') == before
    checked['code_byte_inverse'] += 1
    for n in spec['nodes']:
        kind, ident = n['kind'], n['id']
        if kind == 'index':
            parent = D.read(pins[n['base_input']]['path'], pins[n['base_input']]['sha256'])
            text = parent.decode('utf8')
            for r in n['replacements']:
                assert text.count(r['old']) == 1
                text = text.replace(r['old'], resolved(r['new']), 1)
            assert text.count(n['disabled_literal']) == 1
            text = text.replace(n['disabled_literal'], n['enabled_literal'], 1)
            assert text.encode('utf8') == candidates[n['target']]
            checked['index_byte_inverse'] += 1
        elif kind in ['metadata', 'hall_contract']:
            parent = load(pins[n['base_input']]['path'], pins[n['base_input']]['sha256'])
            child = json.loads(candidates[n['target']])
            assert D.strict(child, stage['nodes'][ident]['value'])
            inverse = copy.deepcopy(child)
            for delta in reversed(stage['proofs'][ident]['source_delta']):
                holder, key = pointer(inverse, delta['pointer'][:-1]), delta['pointer'][-1]
                if delta['existed']:
                    holder[key] = copy.deepcopy(delta['old'])
                else:
                    del holder[key]
            assert D.strict(inverse, parent), ('METADATA_WHOLE_TYPED_INVERSE', ident)
            checked['metadata_whole_typed_inverse'] += 1
    prior = load(D.PRIOR_EXECUTION, D.PRIOR_EXECUTION_SHA)
    execution = json.loads(candidates[D.EXECUTION])
    extra = {p: h for p, h in execution['source_sha256'].items() if p not in prior['source_sha256']}
    assert len(extra) == 6 and len(prior['source_sha256']) == 101 and len(execution['source_sha256']) == 107
    inverse = copy.deepcopy(execution)
    for p in records:
        inverse['owned'][p] = copy.deepcopy(prior['owned'][p])
    inverse['source_sha256'] = copy.deepcopy(prior['source_sha256'])
    assert D.strict(inverse, prior) and D.encode(inverse) == D.read(D.PRIOR_EXECUTION, D.PRIOR_EXECUTION_SHA)
    assert checked == {'code_byte_inverse': 5, 'index_byte_inverse': 8, 'metadata_whole_typed_inverse': 13}
    owner = load(OWNER_PARENT, OWNER_PARENT_SHA)
    classified = load(D.ROOT64_PLAN, D.ROOT64_PLAN_SHA)
    tables = [owner['core_source_sha256']]
    for row in owner['scenes']+owner['rooms']:
        tables += [row['source_sha256'], row['receipt_source_sha256']]
    for r in classified['targets']:
        p = 'res://'+Path(r['path']).relative_to(D.GAME).as_posix()
        for values in tables:
            if p in values:
                assert values[p] == r['old_sha256']
                values[p] = r['new_sha256']
    parent_owner = copy.deepcopy(owner)
    for values in tables:
        for p, r in actual.items():
            if p in values:
                assert values[p] == r['old_sha256'], ('FIXED_PARENT_OWNER_TARGET_OLD_VALUE', p)
                values[p] = r['candidate_sha256']
    # Execution.source_paths is actually consumed by every domain listed here;
    # core47 is an inventory, not a complete-source API, and does not grow.
    for row in owner['scenes']+owner['rooms']:
        for field in ['source_sha256', 'receipt_source_sha256']:
            values = row[field]
            assert (D.EXECUTION in values) == (AUTHORITY in values)
            if D.EXECUTION in values:
                assert not (set(values) & set(extra))
                values.update(extra)
            uses_helper = ((row in owner['rooms'] and field == 'source_sha256') or row['id'] in G_CITY_IDS)
            if uses_helper:
                assert D.G in values and HELPER not in values
                values[HELPER] = HELPER_SHA
    assert len(owner['core_source_sha256']) == 47
    for before_row, after_row in zip(parent_owner['rooms'], owner['rooms']):
        assert D.strict(before_row['receipt_source_sha256'], after_row['receipt_source_sha256'])
    expected_counts = {'ch4_s0_luoyang_gate': 910, 'ch4_s1_luoyang_yamen': 1262,
                       'ch4_s2_canal_docks': 1741, 'ch4_s3_luoyang_market': 1748,
                       'luoyang_artisan_residential_20261022ap': 347, 'luoyang_riverside_garden_20261022ap': 347,
                       'luoyang_estate_riverside_20261021ai': 333, 'ch4_s4_ancient_temple': 404}
    assert {r['id']: len(r['source_sha256']) for r in owner['scenes']} == expected_counts
    assert all(len(r['source_sha256']) == 580 for r in owner['rooms'])
    for n in spec['nodes']:
        if n['kind'] == 'map':
            row = next(r for r in owner['scenes'] if r['id'] == n['scene_id'])
            assert D.strict(row['source_sha256'], stage['nodes'][n['id']]['value']['source_sha256'])
    quarter = stage['nodes']['quarter_final']['value']['source_sha256']
    estate = stage['nodes']['estate_final']['value']['source_sha256']
    for row in owner['scenes']:
        if row['owner'] == 'Quarter':
            assert D.strict(row['receipt_source_sha256'], quarter)
        if row['owner'] == 'Estate':
            assert D.strict(row['receipt_source_sha256'], estate)
    owner['status'] = 'HALL_PORTAL_ACTUAL27_INDEPENDENT_EXPECTED_SOURCE_MAPS_NOT_RUNTIME_CREDIT'
    owner['actual_stage_receipt'] = {'path': RECEIPT, 'sha256': RECEIPT_SHA}
    owner['fixed_prior_owner_sha256'] = OWNER_PARENT_SHA
    owner['hall_portal_successor'] = {'Root64_classification_parent': {'path': D.ROOT64_PLAN, 'sha256': D.ROOT64_PLAN_SHA},
                                     'actual_targets': 27, 'extra_execution_proofs': extra,
                                     'helper_only_G_full_and_Yamen_Docks_Market': {HELPER: HELPER_SHA},
                                     'portal_shader_not_a_natural_city_source_key': True,
                                     'five_room_receipts_and_all_native_publication_unchanged': True}
    owner_bytes = D.encode(owner)
    output = DEST+'owner_source_maps_READY.json'
    review = {'status': 'HALL_PORTAL_ACTUAL27_FIXED_PARENT_OWNER_AND_OUTPUT_READONLY_REVIEW',
              'receipt': {'path': RECEIPT, 'sha256': RECEIPT_SHA}, 'plan': {'path': PLAN, 'sha256': PLAN_SHA},
              'owner': {'path': output, 'sha256': D.sha(owner_bytes)}, 'physical_candidate_sha_bytes_checked': 27,
              'partition': stage['target_partition'], 'inverse_checks': checked, 'execution_entire_typed_UTF8_inverse': True,
              'stage_first_final_dictionary_equal': True, 'stage_source_count': 3089,
              'stage_source_files_not_rehashed': True, 'eight_scene_counts': expected_counts,
              'G_full_count': 580, 'five_room_receipts_wholetyped_unchanged': True,
              'four_complete_map_tables_independently_match': True, 'core_keys': 47,
              'no_collector_current_fill_engine_native_media_decode_or_canonical_write': True}
    return {output: owner_bytes, DEST+'independent_owner_and_actual_output_review_READY.json': D.encode(review)}


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--receipt-sha256', required=True)
    ap.add_argument('--write-new', action='store_true', help='Root-only generated NEW JSON artifacts')
    args = ap.parse_args()
    assert args.receipt_sha256 == RECEIPT_SHA
    outputs = prepare()
    if args.write_new:
        assert all(not D.path(p).exists() for p in outputs), 'NEW_OUTPUTS_ONLY'
        for p, b in outputs.items():
            target = D.path(p)
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open('xb') as stream:
                stream.write(b)
    print(json.dumps([{'path': p, 'sha256': D.sha(b), 'bytes': len(b)} for p, b in outputs.items()]))
