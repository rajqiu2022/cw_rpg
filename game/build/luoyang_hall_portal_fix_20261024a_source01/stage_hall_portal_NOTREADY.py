"""Root-only, NOTREADY thin source compiler. Never runs upon import.

The unchanged8DE0 core supplies full historical execution inverses, exact old
pointers, metadata class/source guards, all four independent AO baselines,
native-history preservation, and complete runtime media-remap checks. Only the
output namespace is set to the newly approved hall source directory. Root must
provide its exact fresh/backup/preparation schema before any Stage is allowed.
"""
import argparse
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
GAME = HERE.parents[1]
PREFIX = 'res://build/luoyang_hall_portal_fix_20261024a_source01/'
BASE = GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py'
assert hashlib.sha256(BASE.read_bytes()).hexdigest() == '8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
sp = importlib.util.spec_from_file_location('frozen_hall_source_core', BASE)
M = importlib.util.module_from_spec(sp)
sp.loader.exec_module(M)
M.PREFIX = PREFIX  # Output guard only; no source/authority/native gate changed.
need, sha, same, res, encode = M.need, M.digest, M.same, M.res, M.encode
EXECUTION = 'res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
FIELD = 'res://scripts/field/field_walkable_controller.gd'
G = 'res://scripts/city/luoyang_assembled_interiors_20261016g.gd'
COORD = 'res://scripts/city/luoyang_cultural_sidequests_coordinator_20261019x.gd'
TEMPLE = 'res://scripts/city/luoyang_temple_assembly_20261016.gd'
CONTRACT = 'res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
PORTAL = 'res://scripts/field/world_v15_exit_zone.gd'


class HallStage(M.Stage):
    def __init__(self, spec):
        c = spec['hall_contract']
        need(spec.get('status') == 'ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers') == []
             and c.get('root_input_freeze_pending') is False and all(isinstance(c.get(k), str) for k in
             ['Root_preparation_input', 'Root_before_input', 'Root_backups_input']), 'ROOT_FRESH_EXACT27_APPROVAL_REQUIRED_NOTREADY')
        super().__init__(spec)
        self.contract = c
        approval = self.read_json_input(c['Root_preparation_input'])
        need(same(approval, c['expected_Root_preparation_document']) and approval.get('approved_by_root') is True,
             'EXACT_ROOT_PREPARATION_DOCUMENT_NOT_INFERRED')
        self.scope = self.read_json_input(c['scope_input'])
        self.oldtargets = {r['target']: r['old_sha256'] for r in self.scope['targets']}
        need(len(self.oldtargets) == 27 and list(self.oldtargets) == spec['root_target_allowlist']
             and sum(p.endswith('.gd') for p in self.oldtargets) == 13, 'EXACT27_SCOPE_13GD14JSON')
        before = self.read_json_input(c['Root_before_input'])
        backups = self.read_json_input(c['Root_backups_input'])
        need(same(before, c['expected_Root_before_document']) and same(backups, c['expected_Root_backup_document']),
             'ROOT_FRESH_AND_FULL_BACKUP_DOCUMENTS_FIXED_BY_EXTERNAL_INPUT')
        # Root chooses these fields from its actual frozen receipt, not guessed
        # aliases. No defaults or schema fallback are permitted.
        schema = c['Root_backup_schema']
        rows = M.pointer(backups, schema['rows_pointer'])
        need(M.pointer(backups, schema['count_pointer']) == 27 and len(rows) == 27, 'ROOT_BACKUP_EXACT27_COUNT')
        backed = {}
        for row in rows:
            target_value = row[schema['target_field']]
            p = ('res://'+Path(target_value).resolve().relative_to(M.ROOT).as_posix()) if schema['target_is_absolute'] else target_value
            old_sha = row[schema['sha256_field']]
            backup = Path(row[schema['backup_field']]).resolve()
            need(p in self.oldtargets and p not in backed and old_sha == self.oldtargets[p]
                 and backup.is_relative_to(res(c['Root_backup_prefix']).resolve()), 'ROOT_FULL_BACKUP_PATH_AND_OLD_PIN')
            bp = 'res://'+backup.relative_to(M.ROOT).as_posix()
            b = self.read(bp, old_sha)
            need(b == self.read(p, old_sha) and len(b) == row[schema['bytes_field']], 'ROOT_FULL_BACKUP_BYTES_EXACT')
            backed[p] = old_sha
        need(backed == self.oldtargets, 'ROOT_FULL27_BACKUP_DOMAIN')
        self.owner = copy.deepcopy(self.read_json_input(c['prior_owner_input']))
        # Root64 changed metadata classes/headers, not any key domain. Preserve
        # its real fifteen successors on top of the immutable ownerFD58 rather
        # than duplicating a three-megabyte parent-owner artifact.
        classified = self.read_json_input(c['Root64_parent_input'])
        tables = [self.owner['core_source_sha256']]
        for row in self.owner['scenes']+self.owner['rooms']:
            tables += [row['source_sha256'], row['receipt_source_sha256']]
        for row in classified['targets']:
            p = 'res://'+Path(row['path']).resolve().relative_to(M.ROOT).as_posix()
            for values in tables:
                if p in values:
                    need(values[p] == row['old_sha256'], 'FIXED_OWNERFD58_ROOT64_CLASSIFICATION_PREDECESSOR')
                    values[p] = row['new_sha256']
        self.proof = self.read_json_input(c['inverse_input'])
        self.codes = self.proof['records']
        need(set(self.codes) == {G, FIELD, COORD, TEMPLE}, 'ONLY_FOUR_RUNTIME_OWNED_CODE_SUCCESSORS')
        for p, record in self.codes.items():
            a = self.read(record['parent']['path'], record['parent']['sha256'])
            b = self.read(record['candidate']['path'], record['candidate']['sha256'])
            need(a == self.read(p, self.oldtargets[p]) and len(b) == record['candidate']['bytes'], 'EXACT_CODE_PARENT_AND_CANDIDATE_BYTES')
            forward, inverse = a.decode('utf8'), b.decode('utf8')
            for h in record['hunks']:
                need(forward.count(h['old']) == inverse.count(h['new']) == 1, 'UNIQUE_EXACT_CODE_HUNK')
                forward = forward.replace(h['old'], h['new'], 1)
                inverse = inverse.replace(h['new'], h['old'], 1)
            need(forward.encode('utf8') == b and inverse.encode('utf8') == a, 'WHOLE_UTF8_CODE_BYTE_INVERSE')
        system = self.read_json_input(c['System_inverse_input'])
        self.portal = next(r for r in system['existing_file_inverses'] if r['parent']['path'] == PORTAL)
        a, b = self.read(PORTAL, self.oldtargets[PORTAL]), self.read(self.portal['candidate']['path'], self.portal['candidate']['sha256'].lower())
        inverse = b.decode('utf8')
        for h in self.portal['operations']:
            need(inverse.count(h['new']) == 1, 'PORTAL_SOLE_SHADER_CONSTANT_INVERSE')
            inverse = inverse.replace(h['new'], h['old'], 1)
        need(inverse.encode('utf8') == a and len(self.portal['operations']) == 1, 'PORTAL_NO_OTHER_BEHAVIOR_CHANGE')
        prior = self.read_json_input(c['parent_execution_input'])
        need(len(prior['owned']) == len(self.authority['owned']) == 10 and set(prior['owned']) == set(self.authority['owned']), 'OWNED_DOMAIN_UNCHANGED')
        restored = copy.deepcopy(self.authority)
        for p, old in prior['owned'].items():
            new = self.authority['owned'][p]
            if p not in self.codes:
                need(same(old, new), 'OTHER_SIX_OWNED_ROWS_UNCHANGED')
                continue
            r, edge = self.codes[p], new['edges'][-1]
            need(len(new['edges']) == len(old['edges'])+1 and same(new['edges'][:-1], old['edges'])
                 and edge['old_sha256'] == old['current_sha256'] == r['parent']['sha256']
                 and edge['new_sha256'] == new['current_sha256'] == r['candidate']['sha256']
                 and edge['new_snapshot'] == r['candidate']['path'] and same(edge['replacements'], r['hunks']), 'FOUR_ONLY_EXACT_APPENDED_BYTE_EDGES')
            restored['owned'][p] = copy.deepcopy(old)
        self.extra = {p: h for p, h in self.authority['source_sha256'].items() if p not in prior['source_sha256']}
        need(len(prior['source_sha256']) == 101 and len(self.authority['source_sha256']) == 107 and same(self.extra, c['proof_extra'])
             and all(self.authority['source_sha256'].get(p) == h for p, h in prior['source_sha256'].items()), 'OLD101_PRESERVED_PLUS_EXACT6')
        restored['source_sha256'] = copy.deepcopy(prior['source_sha256'])
        need(same(restored, prior) and encode(restored) == self.input_bytes[c['parent_execution_input']], 'WHOLE_EXECUTION_TYPED_AND_UTF8_INVERSE_A971')

    def target(self, target, old, candidate, expected):
        need(target in self.oldtargets and old == self.oldtargets[target] and old != expected, 'EXACT27_NO_NOOP_OR_NEW_CANONICAL_TARGET')
        return super().target(target, old, candidate, expected)

    def build_node(self, row):
        ident, kind = row['id'], row['kind']
        if kind in ['hall_execution', 'hall_frozen']:
            raw = self.input_bytes[row['base_input']]
            if kind == 'hall_execution':
                need(ident == 'execution_final' and sha(raw) == self.inputs[self.spec['authority_input']]['sha256'], 'SINGLE_VALIDATED_EXECUTION_NODE')
                value = self.authority
            else:
                need('target' not in row and self.contract['frozen_nodes'][ident] == row['immutable_sha256'] == sha(raw), 'EXACT_FROZEN_NON_TARGET_NODE')
                value = json.loads(raw) if row.get('is_json') else None
            self.nodes[ident] = {'path': self.inputs[row['base_input']]['path'], 'sha256': sha(raw), 'value': value}
            self.proofs[ident] = {'whole_typed_inverse': kind == 'hall_execution', 'fixed_frozen_non_target': kind == 'hall_frozen'}
            return
        if kind == 'hall_contract':
            need(row['target'] == CONTRACT and len(row['operations']) == 1
                 and row['operations'][0]['pointer'] == ['source_sha256', FIELD], 'CONTRACT_FIELD_LITERAL_ONLY')
            value = copy.deepcopy(self.read_json_input(row['base_input']))
            delta = self.change(value, row['operations'], True)
            literal = self.read_json_input(row['literal_candidate_input'])
            raw = self.input_bytes[row['literal_candidate_input']]
            old = self.input_bytes[row['base_input']]
            old_field, new_field = self.codes[FIELD]['parent']['sha256'], self.codes[FIELD]['candidate']['sha256']
            need(same(value, literal) and old.count(old_field.encode()) == 1
                 and old.replace(old_field.encode(), new_field.encode(), 1) == raw, 'WHOLE_TYPED_AND_EXACT_BYTE_SINGLE_FIELD_LITERAL')
            p, h = self.output(row['file'], raw)
            self.nodes[ident] = {'path': p, 'sha256': h, 'value': value}
            self.proofs[ident] = {'whole_typed_inverse': True, 'source_delta': delta, 'byte_literal_inverse': True}
            self.target(CONTRACT, row['old_sha256'], p, h)
            return
        super().build_node(row)
        if kind == 'map':
            expected = copy.deepcopy(next(r for r in self.owner['scenes'] if r['id'] == row['scene_id'])['source_sha256'])
            for p, target in self.targets.items():
                if p in expected:
                    need(expected[p] == target['old_sha256'], 'FIXED_ROOT64_PARENT_MAP_OLD_PIN')
                    expected[p] = target['candidate_sha256']
            expected.update(self.extra)
            if G in expected:
                expected.update(self.contract['helper_source'])
            need(same(expected, self.nodes[ident]['value']['source_sha256']), 'FOUR_MAPS_FIXED_ROOT64_PLUS_EXACT_DECLARED_SUCCESSOR')

    def run(self):
        need({r['id'] for r in self.spec['required_gates']} == M.REQUIRED_GATES, 'ALL_FIVE_ORIGINAL_NATIVE_PERMISSION_GATES')
        for gate in self.spec['required_gates']:
            need(same(M.pointer(self.read_json_input(gate['input']), gate['pointer']), gate['equals']), 'REQUIRED_GATE:'+gate['id'])
        expected = {p: {'path': r['candidate']['path'], 'sha256': r['candidate']['sha256']} for p, r in self.codes.items()}
        expected[PORTAL] = {'path': self.portal['candidate']['path'], 'sha256': self.portal['candidate']['sha256'].lower()}
        expected[EXECUTION] = {k: self.inputs[self.spec['authority_input']][k] for k in ['path', 'sha256']}
        need(len(expected) == len(self.spec['pass_through_targets']) == 6, 'EXACT_FOUR_RUNTIME_PORTAL_AND_EXECUTION_PASSTHROUGH')
        for row in self.spec['pass_through_targets']:
            need(row['target'] in expected and expected[row['target']] == {'path': row['candidate_path'], 'sha256': row['candidate_sha256']}, 'EXACT_APPROVED_CANDIDATE_IDENTITY')
            self.read(row['candidate_path'], row['candidate_sha256'])
            self.target(row['target'], row['old_sha256'], row['candidate_path'], row['candidate_sha256'])
        for row in self.spec['nodes']:
            self.build_node(row)
        maps = [r for r in self.spec['nodes'] if r['kind'] == 'map']
        need({r['scene_id'] for r in maps} == set(M.BASELINES) and all(self.spec['common_group'] in r['groups'] for r in maps), 'FOUR_INDEPENDENT_AO_BASELINES_AND_COMMON_SOURCE_GROUP')
        need(set(self.targets) == set(self.oldtargets) and len(self.targets) == 27, 'EXACT27_NO_EXTRA_TARGET')
        patch, reconstruction, copies = ['*** Begin Patch\n'], {}, []
        for target in self.targets.values():
            p = target['candidate_path']
            candidate = self.outputs[p] if p in self.outputs else self.read(p, target['candidate_sha256'])
            before = self.read(target['target'], target['old_sha256'])
            need(sha(candidate) == target['candidate_sha256'] and candidate != before, 'FINAL_CHANGED_CANDIDATE_BYTES')
            if target['target'].endswith('.json'):
                matches = [k for k, n in self.nodes.items() if n['path'] == p and n['sha256'] == target['candidate_sha256']]
                need(len(matches) == 1 and self.proofs[matches[0]].get('whole_typed_inverse') is True, 'GENERATED_JSON_FULL_INVERSE_BEFORE_EXACT_COPY')
                copies.append({**target, 'candidate_bytes': len(candidate), 'mechanism': 'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION', 'inverse_proof': matches[0]})
                reconstruction[target['target']] = {'kind': 'ExactMechanicalByteCopy', 'candidate_sha256': sha(candidate), 'candidate_bytes': len(candidate), 'whole_inverse_proof': matches[0]}
            else:
                piece, proof = M._strict_lf_build_file_patch(res(target['target']).as_posix(), before, candidate)
                patch.append(piece)
                reconstruction[target['target']] = proof
        patch.append('*** End Patch\n')
        need(len(copies) == 14 and len(reconstruction) == 27, 'PATCH13_COPY14_DISJOINT_EXACT27')
        pp, ph = self.output('canonical_deployment.apply_patch', ''.join(patch).encode('utf8'))
        cp, ch = self.output('canonical_byte_copy_plan.json', encode({'rows': copies, 'patch_copy_disjoint': True, 'patch_copy_union_exact_targets': True, 'no_GD_copy_or_native_write': True}))
        final = {p: sha(res(p).read_bytes()) for p in self.first}
        need(final == self.first, 'ALL_SOURCE_FIRST_FINAL_SAME')
        receipt = {'status': 'HALL_PORTAL_SOURCE_METADATA_STAGED_NOT_DEPLOYED', 'targets': list(self.targets.values()),
                   'nodes': self.nodes, 'proofs': self.proofs, 'source_first': self.first, 'source_final': final,
                   'patch_path': pp, 'patch_sha256': ph, 'patch_reconstruction': reconstruction,
                   'byte_copy_plan': {'path': cp, 'sha256': ch, 'target_count': 14},
                   'target_partition': {'patch_count': 13, 'copy_count': 14, 'total': 27, 'intersection_empty': True, 'union_exact_targets': True},
                   'no_engine_import_collector_or_canonical_write': True, 'source_baseline': self.spec['source_baseline'],
                   'single_root_atomic_epoch_required': True}
        self.output('receipt.json', encode(receipt))
        need(not res(self.out).exists(), 'ALL_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for p, b in self.outputs.items():
            dest = res(p)
            need(not dest.exists(), 'NEW_OUTPUT_ONLY')
            dest.parent.mkdir(parents=True, exist_ok=True)
            with dest.open('xb') as stream:
                stream.write(b)
        return {'output_root': self.out, 'targets': 27, 'map_nodes': 4, 'receipt_sha256': sha(self.outputs[self.out+'receipt.json'])}


if __name__ == '__main__':
    p = argparse.ArgumentParser()
    p.add_argument('input')
    p.add_argument('--input-sha256', required=True)
    a = p.parse_args()
    path = Path(a.input).resolve()
    need(path.is_relative_to(M.ROOT), 'ROOT_LOCKED_INPUT_GAME_DOMAIN')
    raw = path.read_bytes()
    need(M.valid_sha(a.input_sha256) and sha(raw) == a.input_sha256, 'ROOT_EXTERNAL_INPUT_PIN')
    spec = json.loads(raw)
    spec['_locked_plan'] = {'path': 'res://'+path.relative_to(M.ROOT).as_posix(), 'sha256': a.input_sha256}
    print(json.dumps(HallStage(spec).run()))
