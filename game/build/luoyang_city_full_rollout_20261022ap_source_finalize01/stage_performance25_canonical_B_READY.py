"""Exact22 B-only source compiler; Root-only future Stage, never deployment.

The unchanged frozen M owns authority inverses and typed metadata/group/map/media
validation. A pending input cannot run; Root must pin exact scope and execution
documents in a NEW externally SHA-locked input after independent review.
"""
import argparse,copy,hashlib,importlib.util,json
from pathlib import Path
HERE=Path(__file__).resolve().parent
BASE=HERE/'stage_unified06_04_READY.py'
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
module=importlib.util.spec_from_file_location('frozen_B_only_source_base06',BASE)
M=importlib.util.module_from_spec(module);module.loader.exec_module(M)
need,sha,same,res,encode=M.need,M.digest,M.same,M.res,M.encode
S=M.PREFIX
PARENT='a816d4b7c4ed1aa44014490dea6bede3036468f4942f4c10370ad45db45de283'
PROPOSAL='03c4bfe7cecb4928846a300a77ec63de2ccd813f9f444506f3ad87bd5faf105b'
HAND='3a6200e99bd2a9c2e9ce19aa47eb06f4bb84ba15099e2058bd21de2117f2ce7d'
REQUEST='8e23624053a9b6c317ccbe39cd6415c0e5455d96e1340a0a0b48f1b2491b4b50'
BEFORE='3b12823c4ca9d47397faa78e93b3f918bd6efba8729e79342c761cf6dbd957e5'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
FROZEN={'runtime_contract_final':'7ee1224b29184563e59b6a7b3fea7fa5348e264fe765f7a8efda253efc50454e','ap_environment_index':'da57b51fa60cade6e5acf99a1fa32c63b5604e282ac28da5905f5ec61384ab3a','registry_final':'040664f7a2c73087b6c47e5f4d000cb4955648dd61b830d76d2a7ce54cafd95c'}

class BOnlyStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'ROOT_LOCKED_B_ONLY_NO_PENDING_BLOCKERS')
        super().__init__(spec)
        self.contract=spec['B_only_contract'];c=self.contract
        self.hand=self.read_json_input(c['production_input'])
        need(self.inputs[c['production_input']]['sha256']==HAND and self.inputs[spec['authority_input']]['sha256']==PROPOSAL,'FIXED_B_ONLY_CANDIDATE_AND_EXECUTION_PROPOSAL')
        root=self.read_json_input(c['execution_root_input'])
        need(M.valid_sha(c.get('expected_root_execution_sha256')) and self.inputs[c['execution_root_input']]['sha256']==c['expected_root_execution_sha256'] and same(root,c['expected_root_execution_document']) and root.get('approved_by_root') is True,'EXACT_ROOT_EXECUTION_APPROVAL_DOCUMENT_EXTERNAL_LOCK_REQUIRED')
        prior=self.read_json_input(c['parent_approval_input'])
        need(self.inputs[c['parent_approval_input']]['sha256']==PARENT and len(prior['owned'])==10 and set(prior['owned'])==set(self.authority['owned']),'SAME_ACTUAL_TEN_OWNED_MEMBERS')
        need(len(self.hand['owned_changed_exactly1'])==1 and self.hand['owned_changed_exactly1'][0]['path']==B,'ONLY_B_EXISTING_OWNED_SUCCESSOR')
        restored=copy.deepcopy(self.authority)
        for path,before in prior['owned'].items():
            after=self.authority['owned'][path]
            if path==B:
                need(len(after['edges'])==len(before['edges'])+1 and same(after['edges'][:-1],before['edges']),'ONE_APPENDED_B_EDGE_WHOLE_OLD_GRAPH')
                edge=after['edges'][-1]
                need(edge['old_sha256']==before['current_sha256'] and edge['new_sha256']==after['current_sha256'] and same(edge,self.hand['owned_changed_exactly1'][0]),'EXACT_DEPLOYED_AP13_B7123_TO9D5B_EDGE')
                restored['owned'][path]=copy.deepcopy(before)
            else:need(same(before,after),'OTHER_NINE_OWNED_ROWS_EXACT')
        need(len(prior['source_sha256'])==69 and len(self.authority['source_sha256'])==71 and all(self.authority['source_sha256'].get(path)==s for path,s in prior['source_sha256'].items()),'ALL_OLD69_PINS_UNCHANGED')
        extra={path:s for path,s in self.authority['source_sha256'].items() if path not in prior['source_sha256']}
        need(same(extra,self.hand['new_proof_pins']) and len(extra)==2,'ONLY_B_CANDIDATE_AND_WHOLE_INVERSE_TWO_NEW_PINS')
        restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior),'WHOLE_EXECUTION_TYPED_INVERSE_A816')
        scope=self.read_json_input(c['scope_input']);request=self.read_json_input(c['scope_request_input'])
        need(M.valid_sha(c.get('expected_scope_sha256')) and self.inputs[c['scope_input']]['sha256']==c['expected_scope_sha256'] and same(scope,c['expected_scope_document']) and scope.get('approved_by_root') is True,'EXACT_ROOT_SCOPE_DOCUMENT_EXTERNAL_LOCK_REQUIRED')
        need(self.inputs[c['scope_request_input']]['sha256']==REQUEST and scope.get('target_count')==22 and scope.get('proposal_sha256')==REQUEST and scope.get('GD_count')==9 and scope.get('JSON_count')==13,'ROOT_EXACT22_SCOPE_AND_FULL_BACKUPS')
        need(scope.get('before_sha256')==BEFORE,'ROOT25_FRESH_SCOPE_BASELINE')
        self.oldtargets={row['target']:row['old_sha256'] for row in request['targets']}
        need(len(self.oldtargets)==22 and [row['target'] for row in request['targets']]==spec['root_target_allowlist'] and {row['target']:row['old_sha256'] for row in scope['targets']}==self.oldtargets,'EXACT22_ORDERED_ALLOWLIST')
        for row in scope['targets']:
            backup=Path(row['backup_path']).resolve()
            need(backup.is_relative_to(M.ROOT) and row['backup_sha256']==row['old_sha256'],'ROOT_FULL_BACKUP_DOMAIN_AND_SHA')
            rp='res://'+backup.relative_to(M.ROOT).as_posix()
            need(self.read(rp,row['old_sha256'])==self.read(row['target'],row['old_sha256']),'ALL22_OLD_BYTES_PRECISELY_BACKED_UP')
        parent_stage=self.read_json_input(c['actual_parent_stage_input'])
        need(self.inputs[c['actual_parent_stage_input']]['sha256']=='7912fdd9a540b06c1d4804976a0fe582dcea9387daf2077ff20aca98c84617cf','FIXED_ACTUAL_AP13_7912_PARENT_NOT_CURRENT_COLLECTOR')
        need(all(any(r['target']==path and r['candidate_sha256']==s for r in parent_stage['targets']) for path,s in self.oldtargets.items()),'ALL22_PARENT_VALUES_FROM_ACTUAL_AP13_7912')
        prior_owner=self.read_json_input(c['prior_owner_input'])
        need(self.inputs[c['prior_owner_input']]['sha256']=='5050ba8038aa1fbdf5c07f086427f5230171a93819ca5a6dd8ebb8da30d54e4e' and prior_owner.get('actual_stage_receipt',{}).get('sha256')=='7912fdd9a540b06c1d4804976a0fe582dcea9387daf2077ff20aca98c84617cf' and prior_owner.get('expected_not_derived_from_live_collector_or_canonical_hash_crawl') is True,'FIXED_AP13_INDEPENDENT_OWNER5050_NOT_OBSERVED_FILL')

    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT22_CHANGED_TARGETS_NO_NOOP')
        return super().target(target,old,path,expected)

    def build_node(self,row):
        if row['kind']=='B_only_frozen_node':
            ident=row['id'];need(ident in FROZEN and self.inputs[row['base_input']]['sha256']==FROZEN[ident],'ONLY_UNCHANGED_CONTRACT_ENV_INDEX_AND_REGISTRY')
            raw=self.input_bytes[row['base_input']]
            self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw) if ident!='ap_environment_index' else None}
            self.proofs[ident]={'frozen_original_bytes':True,'not_target_or_reformatted_output':True};return
        return super().build_node(row)

    def run(self):
        gates=self.spec['required_gates'];need({row['id'] for row in gates}==M.REQUIRED_GATES,'FIVE_ORIGINAL_NATIVE_AND_SCOPE_GATES')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        for row in self.spec['pass_through_targets']:
            self.read(row['candidate_path'],row['candidate_sha256']);self.read(row['target'],row['old_sha256'])
            if row['target']==B:
                need(self.authority['owned'][B]['current_sha256']==row['candidate_sha256'] and row['old_sha256']=='71231a35e8026dd6269038d7b991a80f25b0667e45fab0772075fe89d930ac57','SOLE_B_AUTHORITY_CURRENT_CODE')
            else:
                need(row['target']==EXE and row['old_sha256']==PARENT and row['candidate_sha256']==PROPOSAL and row['candidate_path']==self.inputs[self.spec['authority_input']]['path'],'SOLE_ROOT_FIXED_EXECUTION_ORIGINAL_BYTES')
            self.target(row['target'],row['old_sha256'],row['candidate_path'],row['candidate_sha256'])
        need(len(self.spec['pass_through_targets'])==2,'ONLY_B_AND_APPROVAL_PASSTHROUGH')
        for row in self.spec['nodes']:self.build_node(row)
        maps=[row for row in self.spec['nodes'] if row['kind']=='map']
        need({row['scene_id'] for row in maps}==set(M.BASELINES) and all(self.spec['common_group'] in row['groups'] for row in maps),'FOUR_FROZEN_AO_BASELINES_COMPLETE_GROUPS')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==22,'EXACT22_CHANGED_TARGETS')
        patch=['*** Begin Patch\n'];reconstruction={};copies=[]
        for row in self.targets.values():
            path=row['candidate_path'];candidate=self.outputs[path] if path in self.outputs else self.read(path,row['candidate_sha256']);before=self.read(row['target'],row['old_sha256'])
            need(sha(candidate)==row['candidate_sha256'] and candidate!=before,'FINAL_FIXED_CHANGED_BYTES')
            if row['target'].endswith('.json'):
                if row['target']==EXE:
                    need(sha(before)==PARENT and sha(candidate)==PROPOSAL,'EXACT_A816_TO03C4_EXECUTION_BYTES');proof_id='fixed_Root_A816_to03C4_authority_inverse'
                else:
                    matches=[k for k,v in self.nodes.items() if v['path']==path and v['sha256']==row['candidate_sha256']]
                    need(len(matches)==1 and self.proofs[matches[0]].get('whole_typed_inverse') is True,'ONLY_FULL_TYPED_INVERSE_GENERATED_JSON');proof_id=matches[0]
                copies.append({**row,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION','inverse_proof':proof_id})
                reconstruction[row['target']]={'kind':'ExactMechanicalByteCopy','candidate_sha256':sha(candidate),'candidate_bytes':len(candidate),'original_bytes_preserved':True,'normalized':False,'whole_inverse_proof':proof_id};continue
            need(row['target'].endswith('.gd'),'GD_ONLY_PATCH_PARTITION')
            piece,proof=M._strict_lf_build_file_patch(res(row['target']).as_posix(),before,candidate)
            patch.append(piece);reconstruction[row['target']]=proof
        patch.append('*** End Patch\n')
        need(len(copies)==13 and len(reconstruction)==22 and len([path for path in self.targets if path.endswith('.gd')])==9 and {r['target'] for r in copies}=={path for path in self.targets if path.endswith('.json')},'PATCH9_COPY13_EXACT_DISJOINT_UNION22')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT13_GENERATED_JSON_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(path for path in self.targets if path.endswith('.gd')),'copy_targets':sorted(r['target'] for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}))
        final={path:sha(res(path).read_bytes()) for path in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':13},'target_partition':{'patch_count':9,'copy_count':13,'total':22,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':self.spec['source_baseline'],'runtime_inverse_replayed':False}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for path,b in self.outputs.items():
            dest=res(path);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as f:f.write(b)
        return {'output_root':self.out,'targets':22,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();path=Path(args.input).resolve();need(path.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=path.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+path.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(BOnlyStage(spec).run()))
if __name__=='__main__':main()
