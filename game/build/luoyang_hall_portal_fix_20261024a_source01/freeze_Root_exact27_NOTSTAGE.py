"""Root-authorized mechanical input freeze only; never instantiate/run Stage."""
import argparse
import copy
import importlib.util
import json
from pathlib import Path

p = Path(__file__).with_name('prepare_source_input_shaderpin_NOTSTAGE.py')
sp = importlib.util.spec_from_file_location('hall_pending_recipe', p)
P = importlib.util.module_from_spec(sp)
sp.loader.exec_module(P)
D = P.P.D
R = 'res://build/luoyang_hall_portal_fix_20261024a_root01/'
ROOT_INPUTS = [
    ('hall_Root_before', 'scope_before27.json', 'bd0d4e76bb7724eec7331cd65e7be7b7e8774748a4b20afe4a6081ec6f1ac253'),
    ('hall_Root_backups', 'backups27.json', 'b49ed6c43b9a0356884de78f10961b344fc57969deedf4a711809479e3cdd62c'),
    ('hall_Root_preparation', 'stage_preparation_approval.json', 'f4e0cceed7b8aef34ea5801568e9766789cccba8949aee14e8d94d182323f7d2')]


def prepare():
    outputs = P.prepare()
    parent_raw = next(iter(outputs.values()))
    assert D.sha(parent_raw) == '6c2df61dea384804d656d692fc959732693e302541e4df6210c37f617f3c4cfa'
    parent = json.loads(parent_raw)
    value = copy.deepcopy(parent)
    documents = {}
    for ident, name, h in ROOT_INPUTS:
        raw = D.read(R+name, h)
        documents[ident] = json.loads(raw)
        assert not any(r['id'] == ident for r in value['pinned_inputs'])
        value['pinned_inputs'].append({'id': ident, 'path': R+name, 'sha256': h})
    scope = D.parent_scope(D.OUT+'world_v15_exit_zone_PARENT_19665.source')
    old = {r['target']: r['old_sha256'] for r in scope['targets']}
    before, backups, approval = (documents[k] for k in ['hall_Root_before', 'hall_Root_backups', 'hall_Root_preparation'])
    assert before['target_count'] == backups['count'] == 27
    assert {r['target']: r['sha256'] for r in before['facts']} == old
    assert {r['target']: r['sha256'] for r in backups['rows']} == old
    assert approval['approved_by_root'] is True and approval['formal_deployment_approved'] is False
    assert approval['geometry_failures'] == approval['shader_failures'] == 0
    assert approval['scope_sha256'] == before['scope_sha256'] == D.sha(D.encode(scope))
    value['status'] = 'ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT'
    value['blockers'] = []
    c = value['hall_contract']
    c.update(Root_preparation_input='hall_Root_preparation', Root_before_input='hall_Root_before',
             Root_backups_input='hall_Root_backups', expected_Root_preparation_document=approval,
             expected_Root_before_document=before, expected_Root_backup_document=backups,
             Root_backup_schema={'rows_pointer': ['rows'], 'count_pointer': ['count'], 'target_field': 'target',
                                 'target_is_absolute': False, 'sha256_field': 'sha256', 'bytes_field': 'bytes', 'backup_field': 'backup'},
             Root_backup_prefix=R+'backups27/', root_input_freeze_pending=False)
    generator = value['required_generator']
    D.read(generator['path'], generator['sha256'])
    inverse = copy.deepcopy(value)
    inverse['pinned_inputs'] = inverse['pinned_inputs'][:-3]
    inverse['status'], inverse['blockers'] = parent['status'], parent['blockers']
    inverse['hall_contract'] = copy.deepcopy(parent['hall_contract'])
    assert D.strict(inverse, parent) and D.encode(inverse) == parent_raw
    raw = D.encode(value)
    outputs[D.OUT+'source_input_ROOT_READY.json'] = raw
    proof = {'status': 'ROOT_EXACT27_INPUT_ONLY_MECHANICAL_FREEZE_NOT_STAGE',
             'parent': {'path': D.OUT+'source_input_shaderpin_NOTREADY.json', 'sha256': D.sha(parent_raw)},
             'ready': {'path': D.OUT+'source_input_ROOT_READY.json', 'sha256': D.sha(raw)},
             'unchanged_driver': generator, 'root_inputs': value['pinned_inputs'][-3:],
             'changes_only': ['three Root document pins', 'status/blockers', 'hall_contract Root facts/schema/readiness'],
             'all_nodes_groups_operations_media_and_candidate_declarations_unchanged': True,
             'whole_ordered_typed_and_serialized_UTF8_inverse': True,
             'no_Stage_engine_collector_or_canonical_write': True}
    outputs[D.OUT+'Root_READY_freeze_inverse.json'] = D.encode(proof)
    return outputs


if __name__ == '__main__':
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--file-index', type=int)
    ap.add_argument('--start', type=int, default=0)
    ap.add_argument('--length', type=int, default=12000)
    a = ap.parse_args()
    outputs = prepare()
    if a.file_index is None:
        print(json.dumps([{'path': k, 'sha256': D.sha(v), 'bytes': len(v)} for k, v in outputs.items()]))
    else:
        k = list(outputs)[a.file_index]
        print(json.dumps({'path': k, 'text': outputs[k].decode('utf8')[a.start:a.start+a.length]}, ensure_ascii=True))
