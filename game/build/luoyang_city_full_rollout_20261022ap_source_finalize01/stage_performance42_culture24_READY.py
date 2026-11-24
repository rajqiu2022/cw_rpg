"""Exact24 C-only culture-source repair compiler; Root-only future Stage, never deployment.

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
PARENT='025eff4adb4bf396c5480539316d8efac36c0b435598b6f85b9ed152e4b1330c'
PROPOSAL='bf043ab07d6ecb2c713607753e3ab2c67621923456ed44e7ab3393d9d3e9ed0d'
HAND='7b42c338f2f33e08b9d38b27cc4318ef4be0add9e72b2ae40e9d055c7154cda8'
REQUEST='769422ac4526ca883430531955c551bef75f346d6d36605ef9db3fa46c7c6813'
BEFORE='4e3c18f870c1af9c1a4ee677bfb6e1b653be9ab9f33461eab557fc6af6a68285'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
B='res://scripts/city/luoyang_precomputed_bundle_20261018r.gd'
FROZEN={'registry_final':'f5298b913fbaefda2c5f3679223c014c219292a54df412a8c3f2d96e4f082f28','ap_environment_index':'da57b51fa60cade6e5acf99a1fa32c63b5604e282ac28da5905f5ec61384ab3a'}

class CultureSourceStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'ROOT_LOCKED_B_ONLY_NO_PENDING_BLOCKERS')
        super().__init__(spec)
        self.contract=spec['B_only_contract'];c=self.contract
        self.hand=self.read_json_input(c['production_input']);self.codes=self.read_json_input(c['code_inverse_input'])['records']
        need(self.inputs[c['production_input']]['sha256']==HAND and self.inputs[spec['authority_input']]['sha256']==PROPOSAL and self.inputs[c['code_inverse_input']]['sha256']==self.hand['inverse_proof']['sha256'],'FIXED_CULTURE_ONLY_CODE_DATA_AND_EXECUTION')
        root=self.read_json_input(c['scope_input']);request=self.read_json_input(c['scope_request_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']=='2ecb2f090c26d4ae0f6f03ddfb533c95e6619ce5423fd4e72ddee414e978c0a1' and same(root,c['expected_scope_document']) and root.get('status')=='ROOT_APPROVED_EXACT24_CULTURE_C_SOURCE_SUCCESSOR_PREPARATION_ONLY' and root.get('scope_sha256')==REQUEST and root.get('execution_candidate_sha256')==PROPOSAL and root.get('whole_inverse_sha256')==self.hand['inverse_proof']['sha256'],'EXACT_ROOT_CULTURE24_PREPARATION_SCHEMA')
        need(root.get('existing_targets')==24 and root.get('GD_targets')==10 and root.get('JSON_targets')==14 and root.get('fresh_before_sha256')==BEFORE and root.get('Stage_execution_authorized') is False and root.get('deployment_authorized') is False and root.get('engine_authorized') is False,'ROOT_SCOPE_AND_NO_UNREQUESTED_EXECUTION')
        need(self.inputs[c['backup_input']]['sha256']=='3a817cc0b9205df9909603715f8e077fafef4747bad0731d36788bf041b9bdb9' and root.get('old_full_backups_sha256')==self.inputs[c['backup_input']]['sha256'] and backups.get('target_count')==24 and len(backups.get('targets',[]))==24,'ROOT_FULL24_OLD_BACKUPS')
        need(self.inputs[c['scope_request_input']]['sha256']==REQUEST,'FIXED24_SCOPE_REQUEST')
        self.oldtargets={r['target']:r['old_sha256']for r in request['targets']}
        backup_targets={}
        for r in backups['targets']:
            target_path=Path(r['path']).resolve();backup=Path(r['backup_path']).resolve()
            need(target_path.is_relative_to(M.ROOT) and backup.is_relative_to(M.ROOT),'ROOT_BACKUP_GAME_DOMAIN')
            target='res://'+target_path.relative_to(M.ROOT).as_posix()
            need(target not in backup_targets,'UNIQUE_ROOT_BACKUP_TARGET')
            backup_targets[target]=r['sha256']
            saved=self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['sha256']);current=self.read(target,r['sha256'])
            need(saved==current and len(saved)==r['bytes'],'ALL24_OLD_BYTES_BACKED_UP')
        need(len(self.oldtargets)==24 and [r['target']for r in request['targets']]==spec['root_target_allowlist'] and backup_targets==self.oldtargets,'EXACT24_ORDERED_OLD_VALUES')
        prior=self.read_json_input(c['parent_approval_input'])
        need(self.inputs[c['parent_approval_input']]['sha256']==PARENT and len(prior['owned'])==10 and set(prior['owned'])==set(self.authority['owned']),'ORIGINAL_OWNED_TEN_MEMBERS')
        changed={self.codes[n]['target']for n in ['Coordinator','Temple']};restored=copy.deepcopy(self.authority)
        need({e['path']for e in self.hand['owned_changed_exactly2']}==changed,'ONLY_TWO_OWNED_SUCCESSORS')
        for path,before in prior['owned'].items():
            after=self.authority['owned'][path]
            if path in changed:
                r=next(v for v in self.codes.values()if v.get('target')==path)
                need(len(after['edges'])==len(before['edges'])+1 and same(after['edges'][:-1],before['edges']),'ONE_NEW_EDGE_KEEP_WHOLE_HISTORY')
                e=after['edges'][-1];need(e['old_sha256']==before['current_sha256'] and e['new_sha256']==after['current_sha256']==r['candidate']['sha256'] and e['new_snapshot']==r['candidate']['path'] and same(e['replacements'],r['hunks']),'EXACT_COORDINATOR_AND_TEMPLE_EDGES');restored['owned'][path]=copy.deepcopy(before)
            else:need(same(before,after),'OTHER_EIGHT_OWNED_ROWS_WHOLE_SAME')
        extra={path:s for path,s in self.authority['source_sha256'].items()if path not in prior['source_sha256']}
        need(len(prior['source_sha256'])==80 and len(self.authority['source_sha256'])==85 and all(self.authority['source_sha256'].get(path)==s for path,s in prior['source_sha256'].items()) and same(extra,self.hand['new_exact5_proof_pins']),'OLD80_PINS_AND_ONLY_FIVE_NEW_PINS')
        restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior),'WHOLE_EXECUTION_TYPED_INVERSE_025E')
        for r in self.codes.values():
            before=self.read(r['parent']['path'],r['parent']['sha256']);after=self.read(r['candidate']['path'],r['candidate']['sha256']);forward=before;inverse=after
            for h in r['hunks']:
                a,b=h['old'].encode(),h['new'].encode();need(forward.count(a)==1 and inverse.count(b)==1,'UNIQUE_LITERAL_HUNKS');forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
            need(forward==after and inverse==before,'ALL_FOUR_WHOLE_CODE_DATA_BYTE_INVERSES')
        priorstage=self.read_json_input(c['actual_parent_stage_input']);owner=self.read_json_input(c['prior_owner_input'])
        need(self.inputs[c['actual_parent_stage_input']]['sha256']=='eb875d3aeed4c750d907cacfe8c5b12c93750d8bddc84d63040a25295f082f6f' and self.inputs[c['prior_owner_input']]['sha256']=='b2858260460afe9c655fdd0eca0b2408f11267e1aa313d23b0ee4ccbee0a1d0c' and owner.get('expected_not_derived_from_live_collector_or_canonical_hash_crawl') is True,'FIXED_AP15_EB875_B285_NOT_CURRENT_FILL')
        declared=dict(owner['core_source_sha256'])
        for r in owner['scenes']:declared.update(r['source_sha256'])
        actual={r['target']:r['candidate_sha256']for r in priorstage['targets']}
        need(all(actual.get(path,declared.get(path))==s for path,s in self.oldtargets.items()),'ALL24_OLD_TARGETS_INDEPENDENTLY_DECLARED')

    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT24_CHANGED_TARGETS_NO_NOOP')
        return super().target(target,old,path,expected)

    def build_node(self,row):
        if row['kind']=='culture_frozen_node':
            ident=row['id'];need(ident in FROZEN and self.inputs[row['base_input']]['sha256']==FROZEN[ident] and row['immutable_sha256']==FROZEN[ident],'ONLY_UNCHANGED_REGISTRY_AND_ENV_INDEX')
            raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw)if ident=='registry_final'else None};self.proofs[ident]={'frozen_original_bytes':True,'not_target_or_reformatted_output':True};return
        if row['kind']=='culture_contract_literal':
            target='res://data/luoyang_culture_integration_20261019x/runtime_contract.json';C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'
            oldsha='7ee1224b29184563e59b6a7b3fea7fa5348e264fe765f7a8efda253efc50454e';newsha='59cf1ebdac2f8f17b644b00f36e241b8b4e43275a50ec6a8b1eb7d89632e59c1'
            oldC='8c145ffb7ce25fcbdf59adf59eb1646f91be753246d24d5fe529b6e1b0bca26b';newC='b14a1042421029651fe0283d3daf8f6e52bea96c9047b79095912f1eb45dc9be'
            expected=[{'op':'set','pointer':['source_sha256',C],'existed':True,'old':oldC,'new':newC}]
            need(row.get('target')==target and row.get('old_sha256')==oldsha and self.inputs[row['base_input']]['sha256']==oldsha and same(row['operations'],expected) and not row.get('source_fields') and not row.get('source_bundle'),'SOLE_EXACT_CULTURE_C_SOURCE_METADATA_OPERATION')
            literal=row['literal_candidate_input'];need(self.inputs[literal]['sha256']==newsha,'ONLY_EXACT59CF_LITERAL_CANDIDATE')
            work=copy.deepcopy(row);work['kind']='metadata';del work['literal_candidate_input']
            super().build_node(work) # Original source-only and FULL typed inverse.
            ident=row['id'];node=self.nodes[ident];candidate=self.input_bytes[literal];before=self.input_bytes[row['base_input']]
            need(same(node['value'],self.read_json_input(literal)) and self.proofs[ident].get('whole_typed_inverse') is True,'LITERAL_EXACT_TYPED_MATCH_AFTER_ORIGINAL_WHOLE_INVERSE')
            need(candidate.count(newC.encode())==1 and before.count(oldC.encode())==1 and candidate.replace(newC.encode(),oldC.encode(),1)==before and before.replace(oldC.encode(),newC.encode(),1)==candidate,'CULTURE_LITERAL_FULL_BYTE_FORWARD_INVERSE_ONE_VALUE')
            self.outputs[node['path']]=candidate;node['sha256']=newsha;self.targets[target]['candidate_sha256']=newsha
            self.proofs[ident]['exact59CF_literal_after_original_typed_inverse']=True;self.proofs[ident]['whole_literal_byte_inverse_7EE']=True
            return
        return super().build_node(row)

    def run(self):
        gates=self.spec['required_gates'];need({row['id'] for row in gates}==M.REQUIRED_GATES,'FIVE_ORIGINAL_NATIVE_AND_SCOPE_GATES')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        exact={r['target']:r['candidate']for r in self.codes.values()if 'target'in r and r['target'].endswith('.gd')}
        exact[EXE]={'path':self.inputs[self.spec['authority_input']]['path'],'sha256':PROPOSAL}
        need(len(exact)==3 and len(self.spec['pass_through_targets'])==3,'EXACT_SEVEN_CODE_AND_EXECUTION_PASSTHROUGHS')
        for row in self.spec['pass_through_targets']:
            need(row['target']in exact and row['old_sha256']==self.oldtargets[row['target']] and exact[row['target']]=={'path':row['candidate_path'],'sha256':row['candidate_sha256']},'ONLY_FIXED_SEVEN_CODE_AND_AUTHORITY_BYTES')
            self.read(row['candidate_path'],row['candidate_sha256']);self.read(row['target'],row['old_sha256']);self.target(row['target'],row['old_sha256'],row['candidate_path'],row['candidate_sha256'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[row for row in self.spec['nodes'] if row['kind']=='map']
        need({row['scene_id'] for row in maps}==set(M.BASELINES) and all(self.spec['common_group'] in row['groups'] for row in maps),'FOUR_FROZEN_AO_BASELINES_COMPLETE_GROUPS')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==24,'EXACT24_CHANGED_TARGETS')
        patch=['*** Begin Patch\n'];reconstruction={};copies=[]
        for row in self.targets.values():
            path=row['candidate_path'];candidate=self.outputs[path] if path in self.outputs else self.read(path,row['candidate_sha256']);before=self.read(row['target'],row['old_sha256'])
            need(sha(candidate)==row['candidate_sha256'] and candidate!=before,'FINAL_FIXED_CHANGED_BYTES')
            if row['target'].endswith('.json'):
                if row['target']==EXE:
                    need(sha(before)==PARENT and sha(candidate)==PROPOSAL,'EXACT_025E_TOBF04_EXECUTION_BYTES');proof_id='fixed_Root_025E_toBF04_authority_inverse'
                else:
                    matches=[k for k,v in self.nodes.items() if v['path']==path and v['sha256']==row['candidate_sha256']]
                    need(len(matches)==1 and self.proofs[matches[0]].get('whole_typed_inverse') is True,'ONLY_FULL_TYPED_INVERSE_GENERATED_JSON');proof_id=matches[0]
                copies.append({**row,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION','inverse_proof':proof_id})
                reconstruction[row['target']]={'kind':'ExactMechanicalByteCopy','candidate_sha256':sha(candidate),'candidate_bytes':len(candidate),'original_bytes_preserved':True,'normalized':False,'whole_inverse_proof':proof_id};continue
            need(row['target'].endswith('.gd'),'GD_ONLY_PATCH_PARTITION')
            piece,proof=M._strict_lf_build_file_patch(res(row['target']).as_posix(),before,candidate)
            patch.append(piece);reconstruction[row['target']]=proof
        patch.append('*** End Patch\n')
        need(len(copies)==14 and len(reconstruction)==24 and len([path for path in self.targets if path.endswith('.gd')])==10 and {r['target'] for r in copies}=={path for path in self.targets if path.endswith('.json')},'PATCH10_COPY14_EXACT_DISJOINT_UNION22')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT14_GENERATED_JSON_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(path for path in self.targets if path.endswith('.gd')),'copy_targets':sorted(r['target'] for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}))
        final={path:sha(res(path).read_bytes()) for path in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':14},'target_partition':{'patch_count':10,'copy_count':14,'total':24,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':self.spec['source_baseline'],'runtime_inverse_replayed':False}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for path,b in self.outputs.items():
            dest=res(path);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as f:f.write(b)
        return {'output_root':self.out,'targets':24,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();path=Path(args.input).resolve();need(path.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=path.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+path.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(CultureSourceStage(spec).run()))
if __name__=='__main__':main()
