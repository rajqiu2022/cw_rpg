"""Root-only exact36 compiler. Frozen8DE0 core; no execution on import.

Canonical writes, engine, runtime collectors, geometry, and imports are absent.
All candidates remain buffered until exact old/new/source/type checks succeed.
"""
import argparse
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

GAME = Path(__file__).resolve().parents[2]
PREFIX = 'res://build/luoyang_city_space_20261024b_source01/'
CORE = GAME / 'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py'
assert hashlib.sha256(CORE.read_bytes()).hexdigest() == '8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
sp = importlib.util.spec_from_file_location('frozen_space36_core', CORE)
M = importlib.util.module_from_spec(sp)
sp.loader.exec_module(M)
M.PREFIX = PREFIX
need, same, sha, encode, res = M.need, M.same, M.digest, M.encode, M.res
EXEC = 'res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
CONTRACT = 'res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
REGISTRY = 'res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
ESTATE = 'res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json'


class SpaceStage(M.Stage):
    def __init__(self, spec):
        c = spec['space_contract']
        need(spec.get('status') == 'ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and not spec.get('blockers')
             and c.get('root_input_freeze_pending') is False, 'ROOT_EXACT27_EXTERNAL_LOCK_REQUIRED')
        super().__init__(spec)
        self.contract = c
        scope = self.read_json_input(c['scope_input'])
        self.oldtargets = {r['target']: r['old_sha256'] for r in scope['targets']}
        need(len(self.oldtargets) == 18 and list(self.oldtargets) == spec['root_target_allowlist']
             and sum(p.endswith('.gd') for p in self.oldtargets) == 7, 'EXACT27_21GD15JSON')
        backup = self.read_json_input(c['Root_backup_input'])
        need(backup['count'] == len(backup['records']) == 18 and backup['scope_sha256'] == self.inputs[c['scope_input']]['sha256'], 'ROOT2090_COUNT_RECORDS_SCHEMA')
        backed = {}
        for row in backup['records']:
            p, h, bp = row['target'], row['sha256'], Path(row['backup_path']).resolve()
            need(p in self.oldtargets and p not in backed and h == self.oldtargets[p] == row['backup_sha256']
                 and bp.is_relative_to(res(c['Root_backup_prefix']).resolve()), 'EXACT27_BACKUP_PATH_DOMAIN')
            b = self.read('res://' + bp.relative_to(M.ROOT).as_posix(), h)
            need(b == self.read(p, h) and len(b) == row['bytes'], 'EXACT27_FULL_OLD_BYTES')
            backed[p] = h
        need(backed == self.oldtargets, 'EXACT27_FULL_BACKUP_COVERAGE')
        approval = self.read_json_input(c['Root_preparation_input'])
        need(same(approval, c['expected_Root_preparation_document']), 'EXACT_ROOT_PREPARATION_DOCUMENT')
        proof = self.read_json_input(c['code_inverse_input'])
        p = 'res://scripts/city/luoyang_environment_layer_20261022ap.gd'
        before = self.read(p, self.oldtargets[p])
        after = self.read(proof['candidate']['path'], proof['candidate']['sha256'])
        forward, inverse = before.decode('utf8'), after.decode('utf8')
        for h in proof['replacements']:
            need(forward.count(h['old']) == inverse.count(h['new']) == 1, 'UNIQUE_ENV_WHOLEBYTE_HUNK')
            forward = forward.replace(h['old'], h['new'], 1)
            inverse = inverse.replace(h['new'], h['old'], 1)
        need(forward.encode('utf8') == after and inverse.encode('utf8') == before
             and proof['parent']['sha256'] == self.oldtargets[p], 'ENV_FULL_FORWARD_AND_INVERSE')
        self.codes = {p:dict(candidate=proof['candidate'])}
        need(len(self.authority['owned']) == 10 and len(self.authority['source_sha256']) == 132
             and self.read(EXEC, self.inputs[spec['authority_input']]['sha256']) == self.input_bytes[spec['authority_input']], 'EXECUTION_10_MEMBERS132_PROOFS_ENTIRE_BYTES_UNCHANGED')
        self.parent_stage = self.read_json_input(c['parent_stage_input'])
        self.binding = self.read_json_input(c['space_binding_input'])
        pub = self.read_json_input(c['space_publication_input'])
        need(pub.get('passed') is True and pub.get('source_first_final_same') is True
             and self.binding['publication_sha256'] == self.inputs[c['space_publication_input']]['sha256']
             and self.binding['ready'] is True and self.binding['whole_street_GPU_ART'] is False
             and self.binding['whole_city_ART'] is False, 'FIXED86ED_SOURCE_NATIVE_NOT_WHOLE_STREET_ART')

    def target(self, target, old, candidate, expected):
        need(target in self.oldtargets and old == self.oldtargets[target] and old != expected, 'NO_UNPLANNED_OR_NOOP_TARGET')
        return super().target(target, old, candidate, expected)

    def verify_leaf(self, path, expected):
        if path in self.outputs:
            allowed = {self.out + r['file'] for r in self.spec['nodes'] if r['id'] in ['finite08_market','finite08_yamen']}
            need(path in allowed and sha(self.outputs[path]) == expected, 'ONLY_TWO_COMPLETED_BUFFERED_FINITE_HEADERS')
            return
        return super().verify_leaf(path, expected)

    def leaf_bytes(self, path, expected):
        if path in self.outputs:
            self.verify_leaf(path, expected)
            return self.outputs[path]
        return super().leaf_bytes(path, expected)

    def build_node(self, row):
        ident, kind = row['id'], row['kind']
        if kind in ['space_execution', 'space_frozen', 'space_code']:
            raw = self.input_bytes[row['base_input']]
            if kind == 'space_execution':
                need(ident == 'execution_final' and sha(raw) == self.inputs[self.spec['authority_input']]['sha256'], 'EXACT_VALIDATED_EXECUTION_NODE')
                value = self.authority
            else:
                need(sha(raw) == row['immutable_sha256'], 'EXACT_CODE_OR_FROZEN_NODE')
                value = json.loads(raw) if row.get('is_json') else None
            self.nodes[ident] = dict(path=self.inputs[row['base_input']]['path'], sha256=sha(raw), value=value)
            self.proofs[ident] = dict(whole_typed_inverse=kind == 'space_execution', exact_candidate_or_frozen=True)
            return
        if kind == 'space_contract':
            need(row['target'] == CONTRACT and self.inputs[row['base_input']]['sha256'] == self.oldtargets[CONTRACT], 'ONLY_FIXED_CULTURE_TWO_SOURCE_LITERAL_SUCCESSOR')
            base = self.read_json_input(row['base_input'])
            value = copy.deepcopy(base)
            delta = self.change(value, row['operations'], True)
            need(len(delta) == 1 and same(value, self.read_json_input(row['literal_candidate_input'])), 'CULTURE_EXACT_C_ONLY_TYPED_INVERSE')
            path, h = self.output(row['file'], self.input_bytes[row['literal_candidate_input']])
            self.nodes[ident] = dict(path=path, sha256=h, value=value)
            self.proofs[ident] = dict(whole_typed_inverse=True, source_delta=delta, exact_original_literal_bytes=True)
            self.target(CONTRACT, row['old_sha256'], path, h)
            return
        if kind == 'space_estate_registry':
            need(row['target'] == ESTATE and row['source_policy'] == 'estate_legacy', 'ONLY_ESTATE_EXACT_REGISTRY_SCALAR_SUCCESSOR')
            original = self.read_json_input(row['base_input'])
            shadow = copy.deepcopy(original)
            registry_ops = [op for op in row['operations'] if op['pointer'] == ['registry_sha256']]
            need(len(registry_ops) == 1 and registry_ops[0] == dict(op='set',pointer=['registry_sha256'],existed=True,
                 old=original['registry_sha256'],new={'$sha':'registry_final'})
                 and original['registry_sha256'] == original['source_sha256'][REGISTRY], 'ONLY_DECLARED_OLD_ESTATE_REGISTRY_SCALAR')
            shadow['registry_sha256'] = self.nodes['registry_final']['sha256']
            temp = '__fixed_Estate_registry_scalar_shadow'
            self.input_bytes[temp] = encode(shadow)
            self.inputs[temp] = dict(path=self.inputs[row['base_input']]['path'],sha256=sha(self.input_bytes[temp]))
            ordinary = copy.deepcopy(row)
            ordinary.update(kind='metadata',base_input=temp)
            ordinary.pop('target'); ordinary.pop('old_sha256')
            ordinary['operations'] = [op for op in ordinary['operations'] if op['pointer'] != ['registry_sha256']]
            ordinary['forbidden_source_paths'] = ordinary.get('forbidden_source_paths',[]) + [ESTATE]
            super().build_node(ordinary)
            value = self.nodes[ident]['value']
            need(set(value['source_sha256']) == set(original['source_sha256']), 'ESTATE_SOURCE_KEYSET_ENTIRELY_UNCHANGED')
            inverse = copy.deepcopy(value)
            for delta in reversed(self.proofs[ident]['source_delta']):
                holder = M.pointer(inverse,delta['pointer'][:-1]); key = delta['pointer'][-1]
                if delta['existed']: holder[key] = delta['old']
                else: del holder[key]
            need(same(inverse,shadow),'ESTATE_ORIGINAL_SOURCE_INVERSE')
            inverse['registry_sha256'] = original['registry_sha256']
            need(same(inverse,original) and encode(inverse) == self.input_bytes[row['base_input']], 'ESTATE_FULL_TYPED_SERIALIZED_PARENT_INVERSE')
            need(value['registry_path'] == REGISTRY and value['registry_sha256'] == value['source_sha256'][REGISTRY]
                 == self.nodes['registry_final']['sha256'], 'ESTATE_REGISTRY_THREE_EQUAL_SEMANTIC_GUARD')
            self.proofs[ident].update(whole_typed_inverse=True,exact_registry_scalar_successor=True,whole_serialized_parent_inverse=True)
            self.target(ESTATE,row['old_sha256'],self.nodes[ident]['path'],self.nodes[ident]['sha256'])
            del self.inputs[temp]; del self.input_bytes[temp]
            return
        if kind == 'space_finite_market':
            need(ident == 'finite08_market' and row['target'] == self.contract['finite_market_target'], 'ONLY_EXACT_NEW_MARKET_CHILD_HEADER')
            original = self.read_json_input(row['base_input'])
            immutable = self.binding['domain_overrides']['manifest_immutable']
            shadow = copy.deepcopy(original)
            for key, value in immutable.items():
                shadow[key] = copy.deepcopy(value)
            # All original source/classification/native guards run on the exact
            # approved immutable child header. No generic geometry exemption.
            temp = '__fixed_space_market_immutable_shadow'
            self.input_bytes[temp] = encode(shadow)
            self.inputs[temp] = dict(path=self.inputs[row['base_input']]['path'], sha256=sha(self.input_bytes[temp]))
            ordinary = copy.deepcopy(row)
            ordinary.update(kind='metadata', base_input=temp)
            ordinary.pop('target')
            ordinary.pop('old_sha256')
            ordinary['forbidden_source_paths'] = ordinary.get('forbidden_source_paths', []) + [row['target']]
            super().build_node(ordinary)
            value = self.nodes[ident]['value']
            need(all(same(value.get(k),v) for k,v in immutable.items()), 'EXACT_BINDING_IMMUTABLE_CHILD_FIELDS')
            # Undo source deltas first, then every exact immutable field; no
            # undeclared key, geometry, parent history or classification survives.
            inverse = copy.deepcopy(value)
            for delta in reversed(self.proofs[ident]['source_delta']):
                holder = M.pointer(inverse, delta['pointer'][:-1]); key = delta['pointer'][-1]
                if delta['existed']: holder[key] = delta['old']
                else: del holder[key]
            need(same(inverse, shadow), 'MARKET_SOURCE_WHOLE_INVERSE_TO_IMMUTABLE_SHADOW')
            for key in immutable:
                if key in original: inverse[key] = copy.deepcopy(original[key])
                else: inverse.pop(key, None)
            need(same(inverse, original), 'MARKET_FULL_TYPED_INVERSE_INCLUDING_OLD_NATIVE_PARENT')
            need(same(value['parent_publication'], original['parent_publication']), 'ORIGINAL_COMPLETE_PARENT_PUBLICATION_PRESERVED')
            self.proofs[ident].update(whole_typed_inverse=True, exact_binding_immutable_exception=True,
                approved_binding_sha256=self.inputs[self.contract['space_binding_input']]['sha256'], whole_old_native_history_inverse=True)
            self.target(row['target'], row['old_sha256'], self.nodes[ident]['path'], self.nodes[ident]['sha256'])
            del self.inputs[temp]; del self.input_bytes[temp]
            return
        super().build_node(row)
        if ident == 'estate_final':
            value = self.nodes[ident]['value']
            need(value['registry_path'] == REGISTRY and value['registry_sha256'] == value['source_sha256'][REGISTRY]
                 == self.nodes['registry_final']['sha256'], 'ESTATE_REGISTRY_THREE_EQUAL_SEMANTIC_GUARD')
        if kind == 'map':
            expected = copy.deepcopy(self.parent_stage['nodes'][ident]['value']['source_sha256'])
            for p, target in self.targets.items():
                if p in expected:
                    need(expected[p] == target['old_sha256'], 'PARENT805791_SOURCE_OLD_VALUE')
                    expected[p] = target['candidate_sha256']
            for group in row['declared_new_groups']:
                self.merge(expected, self.group(group))
            need(same(expected, self.nodes[ident]['value']['source_sha256']) and set(expected) == set(self.parent_stage['nodes'][ident]['value']['source_sha256']), 'INDEPENDENT_FORMAL91A1_PLUS_EXACT18_SAME_KEYS')

    def run(self):
        need({r['id'] for r in self.spec['required_gates']} == M.REQUIRED_GATES, 'ALL_FIVE_NATIVE_PERMISSION_GATES_RETAINED')
        for row in self.spec['required_gates']:
            need(same(M.pointer(self.read_json_input(row['input']),row['pointer']),row['equals']), 'REQUIRED_GATE:' + row['id'])
        expected = {p: {k:r['candidate'][k] for k in ['path','sha256']} for p,r in self.codes.items()}
        need(len(expected) == len(self.spec['pass_through_targets']) == 1, 'EXACT5_CODE_PLUS_EXECUTION_PASSTHROUGH')
        for row in self.spec['pass_through_targets']:
            need(expected.get(row['target']) == dict(path=row['candidate_path'],sha256=row['candidate_sha256']), 'EXACT_APPROVED_CANDIDATE_IDENTITY')
            self.read(row['candidate_path'],row['candidate_sha256'])
            self.target(row['target'],row['old_sha256'],row['candidate_path'],row['candidate_sha256'])
        for row in self.spec['nodes']: self.build_node(row)
        maps = [r for r in self.spec['nodes'] if r['kind'] == 'map']
        need({r['scene_id'] for r in maps} == set(M.BASELINES) and all(self.spec['common_group'] in r['groups'] for r in maps), 'FOUR_ORIGINAL_INDEPENDENT_AO_BASELINES')
        need(set(self.targets) == set(self.oldtargets) and len(self.targets) == 18, 'EXACT27_TARGET_SET')
        patch, reconstruction, copies = ['*** Begin Patch\n'], {}, []
        for target in self.targets.values():
            p = target['candidate_path']
            candidate = self.outputs[p] if p in self.outputs else self.read(p,target['candidate_sha256'])
            before = self.read(target['target'],target['old_sha256'])
            need(sha(candidate) == target['candidate_sha256'] and candidate != before, 'CHANGED_EXACT_CANDIDATE')
            if target['target'].endswith('.json'):
                match = [k for k,n in self.nodes.items() if n['path'] == p and n['sha256'] == target['candidate_sha256']]
                need(len(match) == 1 and self.proofs[match[0]].get('whole_typed_inverse') is True, 'FULL_TYPED_JSON_INVERSE_BEFORE_COPY')
                copies.append({**target,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION','inverse_proof':match[0]})
                reconstruction[target['target']] = dict(kind='ExactMechanicalByteCopy',candidate_sha256=sha(candidate),candidate_bytes=len(candidate),whole_inverse_proof=match[0])
            else:
                part, proof = M._strict_lf_build_file_patch(res(target['target']).as_posix(),before,candidate)
                patch.append(part); reconstruction[target['target']] = proof
        patch.append('*** End Patch\n')
        need(len(copies) == 11 and len(reconstruction) == 18, 'STRICT_PATCH13_EXACT_COPY14')
        pp, ph = self.output('canonical_deployment.apply_patch',''.join(patch).encode('utf8'))
        cp, ch = self.output('canonical_byte_copy_plan.json',encode(dict(rows=copies,patch_copy_disjoint=True,union_exact_targets=True,no_GD_copy_or_native_write=True)))
        final = {p:sha(res(p).read_bytes()) for p in self.first}
        need(final == self.first, 'ALL_SOURCE_FIRST_FINAL_SAME')
        receipt = dict(status='ENV_TEXTURE_UNION_EXACT18_STAGED_NOT_DEPLOYED',targets=list(self.targets.values()),nodes=self.nodes,proofs=self.proofs,
                       source_first=self.first,source_final=final,patch_path=pp,patch_sha256=ph,patch_reconstruction=reconstruction,
                       byte_copy_plan=dict(path=cp,sha256=ch,target_count=11),target_partition=dict(patch_count=7,copy_count=11,total=18),
                       no_engine_import_collector_or_canonical_write=True,source_baseline=self.spec['source_baseline'])
        self.output('receipt.json',encode(receipt))
        need(not res(self.out).exists(), 'NO_OUTPUT_BEFORE_COMPLETE_PREFLIGHT')
        for p,b in self.outputs.items():
            dest=res(p); need(not dest.exists(),'NEW_OUTPUT_ONLY'); dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as stream: stream.write(b)
        return dict(output_root=self.out,targets=18,map_nodes=4,receipt_sha256=sha(self.outputs[self.out+'receipt.json']))


if __name__ == '__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('input'); parser.add_argument('--input-sha256',required=True); args=parser.parse_args()
    path=Path(args.input).resolve(); need(path.is_relative_to(M.ROOT),'EXACT_INPUT_GAME_DOMAIN'); raw=path.read_bytes()
    need(M.valid_sha(args.input_sha256) and sha(raw) == args.input_sha256,'ROOT_EXTERNAL_INPUT_LOCK')
    spec=json.loads(raw); spec['_locked_plan']=dict(path='res://'+path.relative_to(M.ROOT).as_posix(),sha256=args.input_sha256)
    print(json.dumps(SpaceStage(spec).run()))
