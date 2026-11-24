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
PARENT='03c4bfe7cecb4928846a300a77ec63de2ccd813f9f444506f3ad87bd5faf105b'
PROPOSAL='025eff4adb4bf396c5480539316d8efac36c0b435598b6f85b9ed152e4b1330c'
HAND='32eef713b78b4bc1595e5b29637b67ee71cecc437303bfcb44b830c831e1283f'
REQUEST='c431b9725252268cffbe9fead091bc0230e491b85dfbcddd912bc21983983c4f'
BEFORE='c2633e5dc77bd69a7821351fa288e01e1110556fc5fd20922ce53bdf08e7ea3d'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
FROZEN={'runtime_contract_final':'7ee1224b29184563e59b6a7b3fea7fa5348e264fe765f7a8efda253efc50454e','ap_environment_index':'da57b51fa60cade6e5acf99a1fa32c63b5604e282ac28da5905f5ec61384ab3a'}

class MergedCopyStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'ROOT_LOCKED_B_ONLY_NO_PENDING_BLOCKERS')
        super().__init__(spec)
        self.contract=spec['B_only_contract'];c=self.contract
        self.hand=self.read_json_input(c['production_input'])
        need(self.inputs[c['production_input']]['sha256']==HAND and self.inputs[spec['authority_input']]['sha256']==PROPOSAL,'FIXED_MERGED_CODE_AND_FINAL_EXECUTION')
        code=self.read_json_input(c['code_inverse_input']);self.codes=code['records']
        need(self.inputs[c['code_inverse_input']]['sha256']==self.hand['whole_inverse_proof']['sha256'],'FIXED_ALL_CODE_INVERSE_DOCUMENT')
        root=self.read_json_input(c['execution_root_input'])
        need(self.inputs[c['execution_root_input']]['sha256']==c['expected_root_execution_sha256'] and same(root,c['expected_root_execution_document']) and root.get('approved_by_root') is True,'EXACT_FINAL_ROOT_EXECUTION_DIAGNOSTIC_APPROVAL')
        need(root.get('status')=='ROOT_APPROVES_AP14_EXACT29_MERGED_COPY_AND_PASSIVE_DT_SOURCE_PREPARATION_NOT_STAGE_OR_DEPLOYMENT' and root.get('execution_proposal_sha256')==PROPOSAL and root.get('parent_execution_sha256')==PARENT and root.get('scope_proposal_sha256')==REQUEST and root.get('full29_old_backup_sha256')=='60385352065794b9e503c552e4ddc4232e96477576cc8794f05c2a5fbd9bf54c' and root.get('DT_diagnostic_approval_sha256')=='5bc5e44c2b40084b5934d1aa83d84ce48eae5420f91abea87f30bb056e9bf547' and root.get('target_count')==29 and root.get('GD_count')==15 and root.get('JSON_count')==14 and root.get('stage_or_engine_or_formal_write_authorized') is False,'ROOT_FINAL_EXACT_EXECUTION_DIAGNOSTIC_PREPARATION_SCHEMA')
        diag=self.read_json_input(c['diagnostic_root_input'])
        need(self.inputs[c['diagnostic_root_input']]['sha256']=='5bc5e44c2b40084b5934d1aa83d84ce48eae5420f91abea87f30bb056e9bf547' and diag.get('approved_by_root') is True and diag.get('candidate_sha256')==self.codes['DT']['candidate']['sha256'],'EXPLICIT_DT_PASSIVE_DIAGNOSTIC_APPROVAL_NOT_OLD_SCOPE_TEXT')
        self.eof_approval=self.read_json_input(c['eof_transport_input'])
        eof=self.eof_approval
        need(self.inputs[c['eof_transport_input']]['sha256']=='184a3de7e1bea07f547826508e1273275bde1e4f8b14bd25eae53af40e356b97' and eof.get('status')=='ROOT_APPROVES_ONE_EXACT_ADAPTER_EOF_TRANSPORT_PREPARATION_NOT_STAGE_OR_DEPLOYMENT' and eof.get('approved_by_root') is True,'EXACT_ROOT_SINGLE_ADAPTER_EOF_TRANSPORT_APPROVAL')
        need(eof.get('target')==S+'finite_adapter_production08/finite_adapter_READY.gd' and eof.get('old_sha256')=='999a687a1c6ed70a010e9b46c4c1fe4ce2a86b7cb2ca51b3a745c7e153a15e90' and eof.get('candidate_sha256')=='5709468d76c2fb4a930fd44d63c14629003b5bc085df8fa5167b009546c2eb84' and eof.get('candidate_bytes')==30746 and eof.get('patch_intermediate_sha256')=='5676455a1a40646dadd9832fe27f124596e0624a58b137ff052b729cd6d88216' and eof.get('patch_intermediate_bytes')==30747,'FIXED_EOF_OLD_NEW_INTERMEDIATE_DOMAIN')
        prior=self.read_json_input(c['parent_approval_input'])
        need(self.inputs[c['parent_approval_input']]['sha256']==PARENT and len(prior['owned'])==10 and set(prior['owned'])==set(self.authority['owned']),'ORIGINAL_TEN_OWNED_MEMBERS')
        changed={self.codes[n]['target'] for n in ['B','G','DT','Temple']}
        need(set(self.hand['owned_changed_exactly4'])==changed,'EXACT_FOUR_OWNED_SUCCESSORS')
        restored=copy.deepcopy(self.authority)
        for path,before in prior['owned'].items():
            after=self.authority['owned'][path]
            if path in changed:
                need(len(after['edges'])==len(before['edges'])+1 and same(after['edges'][:-1],before['edges']),'APPEND_ONE_KEEP_COMPLETE_OLD_GRAPH')
                edge=after['edges'][-1]
                record=next(r for r in self.codes.values() if r.get('target')==path)
                need(edge['old_sha256']==before['current_sha256'] and edge['new_sha256']==after['current_sha256']==record['candidate']['sha256'] and edge['new_snapshot']==record['candidate']['path'] and same(edge['replacements'],record['hunks']),'EXACT_FOUR_WHOLE_BYTE_EDGES')
                restored['owned'][path]=copy.deepcopy(before)
            else:need(same(before,after),'OTHER_SIX_ROWS_WHOLE_UNCHANGED')
        need(len(prior['source_sha256'])==71 and len(self.authority['source_sha256'])==80 and all(self.authority['source_sha256'].get(path)==s for path,s in prior['source_sha256'].items()),'KEEP_OLD71_PROOF_PINS')
        extra={path:s for path,s in self.authority['source_sha256'].items() if path not in prior['source_sha256']}
        need(same(extra,self.hand['new_proof_sources_exact9']) and len(extra)==9,'EXACT_EIGHT_SOURCE_PLUS_ONE_WHOLE_PROOF_ADDITIONS')
        restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior),'WHOLE_EXECUTION_TYPED_INVERSE_03C4')
        for name,record in self.codes.items():
            before=self.read(record['parent']['path'],record['parent']['sha256']);candidate=self.read(record['candidate']['path'],record['candidate']['sha256'])
            forward=before;inverse=candidate
            for h in record['hunks']:
                a,b=h['old'].encode(),h['new'].encode();need(forward.count(a)==1 and inverse.count(b)==1,'EXACT_UNIQUE_CODE_HUNK');forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
            need(forward==candidate and inverse==before,'ALL_EIGHT_CODE_BINDING_BYTE_INVERSES')
        scope=self.read_json_input(c['scope_input']);request=self.read_json_input(c['scope_request_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']=='09c745e69fb7bdffabb35faf86374005a198f494beca063f07638f0d0f3fbf48' and same(scope,c['expected_scope_document']) and scope.get('status')=='ROOT_APPROVED_PREPARATION_ONLY_EXACT29_MERGED_SOURCE_SUCCESSOR','EXACT_ROOT29_SCOPE_PREPARATION_DOCUMENT')
        need(self.inputs[c['scope_request_input']]['sha256']==REQUEST and scope.get('scope_sha256')==REQUEST and scope.get('allowed_existing_targets')==29 and scope.get('GD_count')==15 and scope.get('JSON_count')==14 and scope.get('fresh_before_sha256')==BEFORE,'ROOT29_FIXED_PATH_SCOPE_AND_FRESH_BASELINE')
        need(self.inputs[c['backup_input']]['sha256']=='60385352065794b9e503c552e4ddc4232e96477576cc8794f05c2a5fbd9bf54c' and backups.get('count')==29,'ROOT29_ALL_FULL_OLD_BACKUPS')
        self.oldtargets={r['target']:r['old_sha256'] for r in request['targets']}
        need(len(self.oldtargets)==29 and [r['target'] for r in request['targets']]==spec['root_target_allowlist'] and {r['target']:r['old_sha256'] for r in backups['targets']}==self.oldtargets,'EXACT29_ORDERED_TARGETS_AND_OLD_HASHES')
        for row in backups['targets']:
            backup=Path(row['backup_path']).resolve();need(backup.is_relative_to(M.ROOT),'ROOT_BACKUP_GAME_DOMAIN')
            rp='res://'+backup.relative_to(M.ROOT).as_posix()
            need(self.read(rp,row['old_sha256'])==self.read(row['target'],row['old_sha256']),'ALL29_OLD_BYTES_PRECISELY_BACKED_UP')
        parent_stage=self.read_json_input(c['actual_parent_stage_input']);prior_owner=self.read_json_input(c['prior_owner_input'])
        need(self.inputs[c['actual_parent_stage_input']]['sha256']=='35ffd126b0ac5292c91e9ed0bd4ea97d8e7c0a4caa16ea36ddcc6ed0e587fa36' and self.inputs[c['prior_owner_input']]['sha256']=='65be3de4b1b8d120d76e9f2f62208642a89c12ca6c0331fbebf9d498d688f9be','FIXED_AP14_35FF_AND_INDEPENDENT65BE')
        need(prior_owner.get('expected_not_derived_from_live_collector_or_canonical_hash_crawl') is True and prior_owner.get('actual_stage_receipt',{}).get('sha256')=='35ffd126b0ac5292c91e9ed0bd4ea97d8e7c0a4caa16ea36ddcc6ed0e587fa36','NO_CURRENT_COLLECTOR_EXPECTED_FILL')
        native_old={r['target']:r['candidate_sha256']for r in parent_stage['targets']}
        declared=dict(prior_owner['core_source_sha256'])
        for row in prior_owner['scenes']:declared.update(row['source_sha256'])
        need(all(native_old.get(path,declared.get(path))==s for path,s in self.oldtargets.items()),'ALL29_OLDS_FROM_FROZEN_ACTUAL_OR_INDEPENDENT_DECLARATION')

    def _exact_eof_transport_patch(self,target,before,after):
        eof=self.eof_approval
        if target!=res(eof['target']).as_posix():
            return M._strict_lf_build_file_patch(target,before,after)
        need(sha(before)==eof['old_sha256'] and sha(after)==eof['candidate_sha256'] and len(before)==30356 and len(after)==30746,'ONLY_EXACT_999A_TO5709_EOF_PAIR')
        need(before and after and not before.endswith(b'\n') and not after.endswith(b'\n') and b'\r'not in before and b'\r'not in after and not before.startswith(b'\xef\xbb\xbf') and not after.startswith(b'\xef\xbb\xbf'),'SOLE_MISSING_FINAL_LF_NOT_GENERAL_EOL_NORMALIZATION')
        old_shadow=before+b'\n';new_shadow=after+b'\n'
        need(sha(new_shadow)==eof['patch_intermediate_sha256'] and len(new_shadow)==30747 and new_shadow[:-1]==after and new_shadow[-1:]==b'\n' and old_shadow[:-1]==before,'EXACT_IN_MEMORY_SINGLE_LF_SHADOWS')
        piece,proof=M._strict_lf_build_file_patch(target,old_shadow,new_shadow)
        need(proof.get('forward_exact_bytes') is True and proof.get('whole_inverse_exact_bytes') is True and proof.get('reconstructed_sha256')==eof['patch_intermediate_sha256'],'ORIGINAL_STRICT_WHOLE_SHADOW_FORWARD_AND_INVERSE')
        proof.update(candidate_sha256=sha(after),forward_exact_bytes=False,whole_inverse_exact_bytes=False,
                     forward_exact_intermediate_bytes=True,whole_shadow_inverse_exact_bytes=True,
                     original_before_sha256=sha(before),original_before_bytes=len(before),
                     old_shadow_sha256=sha(old_shadow),old_shadow_bytes=len(old_shadow),
                     patch_intermediate_sha256=sha(new_shadow),patch_intermediate_bytes=len(new_shadow),
                     final_requires_exact_root_authorized_EOF_formatting=True,
                     exact_original_before_and_after_recovered_by_removing_only_shadow_final_0A=True,
                     eof_format={'path':eof['target'],'approval_path':self.inputs[self.contract['eof_transport_input']]['path'],'approval_sha256':'184a3de7e1bea07f547826508e1273275bde1e4f8b14bd25eae53af40e356b97','required_deployed_intermediate_sha256':sha(new_shadow),'required_deployed_intermediate_bytes':30747,'only_remove_exact_final_byte_hex':'0a','required_final_sha256':sha(after),'required_final_bytes':30746,'must_first_apply_patch_then_mechanically_remove_one_final_byte_from_deployed_characters':True,'never_copy_GD_candidate_or_strip_general_whitespace':True})
        return piece,proof

    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT29_CHANGED_TARGETS_NO_NOOP')
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
        exact={r['target']:r['candidate']for r in self.codes.values()if 'target'in r}
        exact[EXE]={'path':self.inputs[self.spec['authority_input']]['path'],'sha256':PROPOSAL}
        need(len(exact)==8 and len(self.spec['pass_through_targets'])==8,'EXACT_SEVEN_CODE_AND_EXECUTION_PASSTHROUGHS')
        for row in self.spec['pass_through_targets']:
            need(row['target']in exact and row['old_sha256']==self.oldtargets[row['target']] and exact[row['target']]=={'path':row['candidate_path'],'sha256':row['candidate_sha256']},'ONLY_FIXED_SEVEN_CODE_AND_AUTHORITY_BYTES')
            self.read(row['candidate_path'],row['candidate_sha256']);self.read(row['target'],row['old_sha256']);self.target(row['target'],row['old_sha256'],row['candidate_path'],row['candidate_sha256'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[row for row in self.spec['nodes'] if row['kind']=='map']
        need({row['scene_id'] for row in maps}==set(M.BASELINES) and all(self.spec['common_group'] in row['groups'] for row in maps),'FOUR_FROZEN_AO_BASELINES_COMPLETE_GROUPS')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==29,'EXACT29_CHANGED_TARGETS')
        patch=['*** Begin Patch\n'];reconstruction={};copies=[]
        for row in self.targets.values():
            path=row['candidate_path'];candidate=self.outputs[path] if path in self.outputs else self.read(path,row['candidate_sha256']);before=self.read(row['target'],row['old_sha256'])
            need(sha(candidate)==row['candidate_sha256'] and candidate!=before,'FINAL_FIXED_CHANGED_BYTES')
            if row['target'].endswith('.json'):
                if row['target']==EXE:
                    need(sha(before)==PARENT and sha(candidate)==PROPOSAL,'EXACT_03C4_TO025E_EXECUTION_BYTES');proof_id='fixed_Root_03C4_to025E_authority_inverse'
                else:
                    matches=[k for k,v in self.nodes.items() if v['path']==path and v['sha256']==row['candidate_sha256']]
                    need(len(matches)==1 and self.proofs[matches[0]].get('whole_typed_inverse') is True,'ONLY_FULL_TYPED_INVERSE_GENERATED_JSON');proof_id=matches[0]
                copies.append({**row,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION','inverse_proof':proof_id})
                reconstruction[row['target']]={'kind':'ExactMechanicalByteCopy','candidate_sha256':sha(candidate),'candidate_bytes':len(candidate),'original_bytes_preserved':True,'normalized':False,'whole_inverse_proof':proof_id};continue
            need(row['target'].endswith('.gd'),'GD_ONLY_PATCH_PARTITION')
            piece,proof=self._exact_eof_transport_patch(res(row['target']).as_posix(),before,candidate)
            patch.append(piece);reconstruction[row['target']]=proof
        patch.append('*** End Patch\n')
        need(len(copies)==14 and len(reconstruction)==29 and len([path for path in self.targets if path.endswith('.gd')])==15 and {r['target'] for r in copies}=={path for path in self.targets if path.endswith('.json')},'PATCH15_COPY14_EXACT_DISJOINT_UNION22')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT14_GENERATED_JSON_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(path for path in self.targets if path.endswith('.gd')),'copy_targets':sorted(r['target'] for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}))
        final={path:sha(res(path).read_bytes()) for path in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':14},'target_partition':{'patch_count':15,'copy_count':14,'total':29,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':self.spec['source_baseline'],'runtime_inverse_replayed':False}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for path,b in self.outputs.items():
            dest=res(path);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as f:f.write(b)
        return {'output_root':self.out,'targets':29,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();path=Path(args.input).resolve();need(path.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=path.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+path.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(MergedCopyStage(spec).run()))
if __name__=='__main__':main()
