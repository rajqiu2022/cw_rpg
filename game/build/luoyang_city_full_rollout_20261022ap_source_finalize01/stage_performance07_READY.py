"""Exact26 performance-source compiler; Root-only future Stage, not deployment.

Frozen M supplies all authority byte inverses, typed metadata/group/map/media
validators and exact LF patch reconstruction. No engine/collector/native writes.
Root alone may invoke this NEW driver after independent review and an external
final-input SHA lock. It never grants formal deployment authorization.
"""
import argparse,copy,hashlib,importlib.util,json
from pathlib import Path
HERE=Path(__file__).resolve().parent
BASE=HERE/'stage_unified06_04_READY.py'
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
module=importlib.util.spec_from_file_location('frozen_performance_source_base06',BASE)
M=importlib.util.module_from_spec(module);module.loader.exec_module(M)
need,sha,same,res,encode=M.need,M.digest,M.same,M.res,M.encode
S=M.PREFIX
PARENT='85df6c96670165398e37b4a66627df74cd300bace841e5d064be058e7fd48187'
PROPOSAL='428a3484e0a995803d95677dbd36f545313c622142605fce292ffd493b6bea03'
HAND='2140f39a3c61f87f089256b670f941b11a925c9b30f300e63d56c55a8acec3c7'
SCOPE='d3eb45666421a4c2ea8b74edc0e1ac7e0dfdf8e4c39a76eca30b2586009060da'
REQUEST='203ee55193b8d34ab1e1804c13b78dab85189557141e21f32ec34ecba130796f'
ROOT_EXECUTION_SHA='f934dff214d96eb1cc9dbe45914db90a8094d8be0d9560fc9a9cbe5f907b878b'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
HASH='res://scripts/city/luoyang_parallel_source_hash_20261017k.gd'
B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
DT='res://scripts/city/luoyang_district_life_20261016f.gd'
TEMPLE='res://scripts/city/luoyang_temple_assembly_20261016.gd'
FROZEN={'runtime_contract_final':'7ee1224b29184563e59b6a7b3fea7fa5348e264fe765f7a8efda253efc50454e','ap_environment_index':'da57b51fa60cade6e5acf99a1fa32c63b5604e282ac28da5905f5ec61384ab3a'}

class PerformanceStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'ROOT_LOCKED_PERFORMANCE_NO_PENDING_BLOCKERS')
        need(M.valid_sha(ROOT_EXECUTION_SHA),'PENDING_ROOT_EXECUTION_APPROVAL_CANNOT_EXECUTE')
        super().__init__(spec)
        self.contract=spec['performance_contract'];c=self.contract
        self.hand=self.read_json_input(c['production_input'])
        need(self.inputs[c['production_input']]['sha256']==HAND and self.inputs[spec['authority_input']]['sha256']==PROPOSAL,'FIXED_PERFORMANCE_CANDIDATES_AND_PROPOSAL')
        root=self.read_json_input(c['execution_root_input'])
        need(self.inputs[c['execution_root_input']]['sha256']==ROOT_EXECUTION_SHA and same(root,c['expected_root_execution_document']),'EXACT_FIXED_ROOT_EXECUTION_DOCUMENT_NO_SCHEMA_GUESS')
        need(root.get('status')=='ROOT_APPROVED_PERFORMANCE05_EXACT_EXECUTION_SUCCESSOR_FOR_SOURCE_PREPARATION_ONLY' and root.get('approved_by_root') is True and root['parent']['sha256']==PARENT and root['proposal']=={'path':self.inputs[spec['authority_input']]['path'],'sha256':PROPOSAL} and root['scope']['sha256']==SCOPE and root['candidate_admission']['sha256']=='35a64923799596fc799a45d8c04c58ef14608dc7df242cadf1b0d7b60de595a6','EXACT_ROOT_APPROVAL_ACTUAL_SCHEMA_AND_FIXED_EDGES')
        prior=self.read_json_input(c['parent_approval_input'])
        need(self.inputs[c['parent_approval_input']]['sha256']==PARENT and len(prior['owned'])==10 and set(prior['owned'])==set(self.authority['owned']),'SAME_ACTUAL_TEN_OWNED_MEMBERS')
        changed={B,DT,TEMPLE};need({r['path'] for r in self.hand['owned_changed_exactly3']}==changed,'EXACT_THREE_EXISTING_OWNED_SUCCESSORS')
        restored=copy.deepcopy(self.authority)
        for p,before in prior['owned'].items():
            after=self.authority['owned'][p]
            if p in changed:
                need(len(after['edges'])==len(before['edges'])+1 and same(after['edges'][:-1],before['edges']),'ONE_APPENDED_EDGE_WHOLE_OLD_GRAPH')
                edge=after['edges'][-1]
                need(edge['old_sha256']==before['current_sha256'] and edge['new_sha256']==after['current_sha256'] and any(same(edge,e) for e in self.hand['owned_changed_exactly3']),'EXACT_DEPLOYED_CURRENT_TO_NEW_EDGE')
                restored['owned'][p]=copy.deepcopy(before)
            else:need(same(before,after),'OTHER_SEVEN_OWNED_ROWS_EXACT')
        need(HASH not in self.authority['owned'],'HASH_NOT_ADDED_TO_OWNED')
        need(len(prior['source_sha256'])==63 and len(self.authority['source_sha256'])==67 and all(self.authority['source_sha256'].get(p)==s for p,s in prior['source_sha256'].items()),'ALL_OLD63_PINS_UNCHANGED')
        extra={p:s for p,s in self.authority['source_sha256'].items() if p not in prior['source_sha256']}
        need(same(extra,self.hand['new_proof_pins']) and len(extra)==4,'EXACT_FOUR_NEW_PROOF_PINS')
        restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior),'WHOLE_EXECUTION_TYPED_INVERSE85DF')
        scope=self.read_json_input(c['scope_input']);request=self.read_json_input(c['scope_request_input'])
        need(self.inputs[c['scope_input']]['sha256']==SCOPE and scope.get('approved_by_root') is True and scope.get('target_count')==26 and scope.get('proposal_sha256')==REQUEST and scope.get('GD_count')==12 and scope.get('JSON_count')==14,'ROOT_EXACT26_SCOPE_AND_FULL_BACKUPS')
        need(scope.get('before_sha256')=='f71d06b09d48201bd690dec0417d5d52b17a6e96cf946d22f286e2d2d44c38e5','ROOT18_FRESH_SCOPE_BASELINE')
        need(self.inputs[c['scope_request_input']]['sha256']==REQUEST,'FIXED26_SCOPE_REQUEST')
        self.oldtargets={r['target']:r['old_sha256'] for r in request['targets']}
        need(len(self.oldtargets)==26 and [r['target'] for r in request['targets']]==spec['root_target_allowlist'] and {r['target']:r['old_sha256'] for r in scope['targets']}==self.oldtargets,'EXACT26_ORDERED_ALLOWLIST')
        for row in scope['targets']:
            backup=Path(row['backup_path']).resolve()
            need(backup.is_relative_to(M.ROOT) and row['backup_sha256']==row['old_sha256'],'ROOT_FULL_BACKUP_DOMAIN_AND_SHA')
            rp='res://'+backup.relative_to(M.ROOT).as_posix()
            need(self.read(rp,row['old_sha256'])==self.read(row['target'],row['old_sha256']),'ALL26_OLD_BYTES_PRECISELY_BACKED_UP')
        admission=self.read_json_input(c['candidate_admission_input'])
        need(self.inputs[c['candidate_admission_input']]['sha256']=='35a64923799596fc799a45d8c04c58ef14608dc7df242cadf1b0d7b60de595a6' and admission.get('approved_by_root') is True,'ROOT_CANDIDATE_PREPARATION_SCOPE')
        for p,s in admission['candidates'].items():need(self.prospective[p]['sha256']==s,'EXACT_THREE_ADMITTED_PERFORMANCE_CANDIDATES')

    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT26_CHANGED_TARGETS_NO_NOOP')
        return super().target(target,old,path,expected)

    def build_node(self,row):
        if row['kind']=='performance_frozen_node':
            ident=row['id'];need(ident in FROZEN and self.inputs[row['base_input']]['sha256']==FROZEN[ident],'ONLY_UNCHANGED_CONTRACT_AND_ENV_INDEX')
            raw=self.input_bytes[row['base_input']]
            self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw) if ident=='runtime_contract_final' else None}
            self.proofs[ident]={'frozen_original_bytes':True,'not_target_or_reformatted_output':True};return
        return super().build_node(row)

    def run(self):
        gates=self.spec['required_gates'];need({r['id'] for r in gates}==M.REQUIRED_GATES,'FIVE_ORIGINAL_NATIVE_AND_SCOPE_GATES')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        for row in self.spec['pass_through_targets']:
            after=self.read(row['candidate_path'],row['candidate_sha256']);before=self.read(row['target'],row['old_sha256'])
            if row['target'] in self.authority['owned']:
                need(self.authority['owned'][row['target']]['current_sha256']==row['candidate_sha256'],'EXACT_THREE_AUTHORITY_CURRENT_CODES')
            elif row['target']==EXE:
                need(row['old_sha256']==PARENT and row['candidate_sha256']==PROPOSAL and row['candidate_path']==self.inputs[self.spec['authority_input']]['path'],'SOLE_ROOT_FIXED_EXECUTION_ORIGINAL_BYTES')
            else:
                need(row['target']==HASH and row.get('exact_replacements'),'SOLE_NONOWNED_HASH_EXACT_SOURCE_INVERSE')
                inverse=after.decode()
                for h in reversed(row['exact_replacements']):
                    need(h['new'] and inverse.count(h['new'])==1,'NONOWNED_HASH_UNIQUE_INVERSE');inverse=inverse.replace(h['new'],h['old'],1)
                need(inverse.encode()==before,'NONOWNED_HASH_COMPLETE_BYTE_INVERSE')
            self.target(row['target'],row['old_sha256'],row['candidate_path'],row['candidate_sha256'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[r for r in self.spec['nodes'] if r['kind']=='map']
        need({r['scene_id'] for r in maps}==set(M.BASELINES) and all(self.spec['common_group'] in r['groups'] for r in maps),'FOUR_FROZEN_AO_BASELINES_COMPLETE_GROUPS')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==26,'EXACT26_CHANGED_TARGETS')
        patch=['*** Begin Patch\n'];reconstruction={};copies=[]
        for row in self.targets.values():
            p=row['candidate_path'];candidate=self.outputs[p] if p in self.outputs else self.read(p,row['candidate_sha256']);before=self.read(row['target'],row['old_sha256'])
            need(sha(candidate)==row['candidate_sha256'] and candidate!=before,'FINAL_FIXED_CHANGED_BYTES')
            if row['target'].endswith('.json'):
                if row['target']==EXE:
                    need(sha(before)==PARENT and sha(candidate)==PROPOSAL,'EXACT85DF_TO428A_EXECUTION_BYTES');proof_id='fixed_Root_85DF_to428A_authority_inverse'
                else:
                    matches=[k for k,v in self.nodes.items() if v['path']==p and v['sha256']==row['candidate_sha256']]
                    need(len(matches)==1 and self.proofs[matches[0]].get('whole_typed_inverse') is True,'ONLY_FULL_TYPED_INVERSE_GENERATED_JSON');proof_id=matches[0]
                copies.append({**row,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION','inverse_proof':proof_id})
                reconstruction[row['target']]={'kind':'ExactMechanicalByteCopy','candidate_sha256':sha(candidate),'candidate_bytes':len(candidate),'original_bytes_preserved':True,'normalized':False,'whole_inverse_proof':proof_id};continue
            need(row['target'].endswith('.gd'),'GD_ONLY_PATCH_PARTITION')
            piece,proof=M._strict_lf_build_file_patch(res(row['target']).as_posix(),before,candidate)
            patch.append(piece);reconstruction[row['target']]=proof
        patch.append('*** End Patch\n')
        need(len(copies)==14 and len(reconstruction)==26 and len([p for p in self.targets if p.endswith('.gd')])==12 and {r['target'] for r in copies}=={p for p in self.targets if p.endswith('.json')},'PATCH12_COPY14_EXACT_DISJOINT_UNION26')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT14_GENERATED_JSON_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(p for p in self.targets if p.endswith('.gd')),'copy_targets':sorted(r['target'] for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}))
        final={p:sha(res(p).read_bytes()) for p in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':14},'target_partition':{'patch_count':12,'copy_count':14,'total':26,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':self.spec['source_baseline'],'runtime_inverse_replayed':False}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for p,b in self.outputs.items():
            dest=res(p);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as f:f.write(b)
        return {'output_root':self.out,'targets':26,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();p=Path(args.input).resolve();need(p.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=p.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+p.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(PerformanceStage(spec).run()))
if __name__=='__main__':main()
