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
PARENT='bf043ab07d6ecb2c713607753e3ab2c67621923456ed44e7ab3393d9d3e9ed0d'
PROPOSAL='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
FROZEN={'ap_environment_index': 'da57b51fa60cade6e5acf99a1fa32c63b5604e282ac28da5905f5ec61384ab3a'}
class MarketCompleteParentStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'LOCKED_EXACT30')
        super().__init__(spec);self.contract=spec['B_only_contract'];c=self.contract
        self.hand=self.read_json_input(c['production_input']);self.codes=self.read_json_input(c['inverse_input'])['records']
        need(self.inputs[c['production_input']]['sha256']=='e12394b9f9f47524f5118c3fb4ddad9a38306d042289eaddbe9f830a7398d953' and self.inputs[spec['authority_input']]['sha256']==PROPOSAL,'FIXED57_CODE_AND_PROPOSAL')
        root=self.read_json_input(c['Root_input']);request=self.read_json_input(c['scope_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['Root_input']]['sha256']=='93e5b14e78f070a5c035fbe5a06d4477c9c622967ff3adb0b8788a18f71708e7' and root.get('approved_by_root') is True and root.get('status')=='ROOT_APPROVES_EXACT30_MARKET_COMPLETE_FROZEN_PARENT_SOURCE_PREPARATION_ONLY' and root.get('existing_targets')==30 and root.get('GD_targets')==15 and root.get('JSON_targets')==15 and root.get('Stage_execution_authorized') is False and root.get('deployment_authorized') is False,'EXACT_ROOT43_PREPARATION_SCOPE')
        need(self.inputs[c['scope_input']]['sha256']==root['scope_sha256']=='5fdf8409e6866feb7f9306889446310c756c23951dc3313dccfbca992fedd311' and root['fresh_before_sha256']=='25374fe35efa1d64f7efeadb8ccaec28e6e0574b53e471d77af837a48fc75c20' and self.inputs[c['backup_input']]['sha256']==root['old_full_backups_sha256']=='447052f129c1e9fde1e06788cc6e12c09e038a78aee733befe293c1740630769','FIXED_SCOPE_FRESH_AND_BACKUPS')
        approval=self.read_json_input(c['execution_Root_input']);need(self.inputs[c['execution_Root_input']]['sha256']==c['expected_execution_Root_sha256'] and same(approval,c['expected_execution_Root_document']) and approval.get('approved_by_root') is True,'FINAL_FIXED_EXECUTION_ROOT_APPROVAL')
        need(c['exact_execution_pointer_fields'] and {str(r['value']).lower()for r in c['exact_execution_pointer_fields']}=={PARENT,PROPOSAL} and all(same(M.pointer(approval,r['pointer']),r['value'])for r in c['exact_execution_pointer_fields']),'ROOT_EXPLICIT_PARENT_AND_PROPOSAL_IDENTITY')
        self.oldtargets={r['target']:r['old_sha256']for r in request['targets']};need(len(self.oldtargets)==30 and list(self.oldtargets)==spec['root_target_allowlist'] and backups.get('target_count')==30 and len(backups['targets'])==30,'EXACT30_TARGETSET')
        backed={}
        for r in backups['targets']:
            q=Path(r['path']).resolve();b=Path(r['backup_path']).resolve();need(q.is_relative_to(M.ROOT) and b.is_relative_to(M.ROOT),'BACKUP_GAME_DOMAIN')
            path='res://'+q.relative_to(M.ROOT).as_posix();need(path not in backed,'UNIQUE_BACKUP');backed[path]=r['sha256'];old=self.read('res://'+b.relative_to(M.ROOT).as_posix(),r['sha256']);need(len(old)==r['bytes'] and old==self.read(path,r['sha256']),'ALL30_FULL_OLD_BYTES_BACKED_UP')
        need(backed==self.oldtargets,'BACKUP_EXACT_SCOPE')
        owner=self.read_json_input(c['prior_owner_input']);need(self.inputs[c['prior_owner_input']]['sha256']=='fc11a02989c4e9d57628dccaa82c08cd11df6767c954f4ed4829b5dcdffc0f02' and all(owner['core_source_sha256'].get(path)==s for path,s in self.oldtargets.items()),'EXACT_CURRENT_FC11_NOT_CURRENT_FILL')
        prior=self.read_json_input(c['parent_execution_input']);need(self.inputs[c['parent_execution_input']]['sha256']==PARENT and len(prior['owned'])==10 and set(prior['owned'])==set(self.authority['owned']),'TEN_ORIGINAL_OWNED_MEMBERS')
        changed={self.codes[name]['target']for name in ['B','DT','Coordinator','Temple']};restored=copy.deepcopy(self.authority)
        for path,before in prior['owned'].items():
            after=self.authority['owned'][path]
            if path in changed:
                r=next(r for r in self.codes.values()if r.get('target')==path);need(len(after['edges'])==len(before['edges'])+1 and same(after['edges'][:-1],before['edges']),'ONLY_ONE_EDGE_KEEP_HISTORY');e=after['edges'][-1]
                need(e['old_sha256']==before['current_sha256']==r['parent']['sha256'] and e['new_sha256']==after['current_sha256']==r['candidate']['sha256'] and e['new_snapshot']==r['candidate']['path'] and same(e['replacements'],r['hunks']),'EXACT_FOUR_LITERAL_WHOLE_BYTE_EDGES');restored['owned'][path]=copy.deepcopy(before)
            else:need(same(before,after),'OTHER_SIX_WHOLE_ROWS_SAME')
        extra={path:s for path,s in self.authority['source_sha256'].items()if path not in prior['source_sha256']};need(len(prior['source_sha256'])==85 and len(self.authority['source_sha256'])==95 and all(self.authority['source_sha256'].get(path)==s for path,s in prior['source_sha256'].items()) and same(extra,self.hand['new_exact10_proof_pins']),'OLD85_AND_EXACT10_PROOF_SNAPSHOTS')
        restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior),'WHOLE_EXECUTION_TYPED_INVERSE_BF043')
        for r in self.codes.values():
            before=self.read(r['parent']['path'],r['parent']['sha256']);after=self.read(r['candidate']['path'],r['candidate']['sha256']);forward=before;inverse=after
            for h in r['hunks']:
                a,b=h['old'].encode(),h['new'].encode();need(forward.count(a)==1 and inverse.count(b)==1,'UNIQUE_WHOLE_LITERAL_HUNKS');forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
            need(forward==after and inverse==before,'ALL_NINE_CODE_DATA_WHOLE_BYTE_INVERSES')
        self.eof_approval=self.read_json_input(c['eof_transport_input']);eof=self.eof_approval
        need(self.inputs[c['eof_transport_input']]['sha256']=='25ff1b9474bb50ccc149e75a68959ccb0211c139d15f96c023983ba093ed2387' and eof.get('approved_by_root') is True and eof.get('old_sha256')=='5709468d76c2fb4a930fd44d63c14629003b5bc085df8fa5167b009546c2eb84' and eof.get('candidate_sha256')=='cf2aa3da4f8dbafd30d48d9310d69d7eacb9f17d25e47ce02ca221835eff3736' and eof.get('patch_intermediate_sha256')=='9fc421182b8143f3fe0711322fe51788b443b5a5132dd7c524d961562b0f0025','EXACT_NEW_SINGLE_EOF_AUTHORITY')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY30_CHANGED_TARGETS_NO_NOOP')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        if row['kind']=='repair30_frozen':
            ident=row['id'];need(ident in FROZEN and self.inputs[row['base_input']]['sha256']==row['immutable_sha256']==FROZEN[ident] and 'target'not in row,'ONLY_UNCHANGED_ENV_INDEX');raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':None};self.proofs[ident]={'frozen_original_bytes':True};return
        if row['kind']=='repair30_contract_literal':
            work=copy.deepcopy(row);work['kind']='metadata';literal=work.pop('literal_candidate_input');need(row['target']=='res://data/luoyang_culture_integration_20261019x/runtime_contract.json' and row['old_sha256']=='59cf1ebdac2f8f17b644b00f36e241b8b4e43275a50ec6a8b1eb7d89632e59c1' and self.inputs[literal]['sha256']=='d258350b1b72377fb4189918178a1323de9506934d015859a4d5823271961b9b','ONLY_EXACT_CULTURE_C_LITERAL_SUCCESSOR')
            super().build_node(work);ident=row['id'];node=self.nodes[ident];before=self.input_bytes[row['base_input']];candidate=self.input_bytes[literal];need(same(node['value'],self.read_json_input(literal)) and self.proofs[ident]['whole_typed_inverse'] is True,'ORIGINAL_SOURCE_ONLY_WHOLE_TYPED_INVERSE_BEFORE_LITERAL')
            oldC='b14a1042421029651fe0283d3daf8f6e52bea96c9047b79095912f1eb45dc9be';newC='1dbd8c1357608a96c04a602f2c0a3c5f4478928bbc969c43963c6f430ef2c2b7';need(candidate.count(newC.encode())==1 and before.count(oldC.encode())==1 and candidate.replace(newC.encode(),oldC.encode(),1)==before and before.replace(oldC.encode(),newC.encode(),1)==candidate,'CONTRACT_SINGLE_C_VALUE_FULL_BYTE_INVERSE')
            self.outputs[node['path']]=candidate;node['sha256']=sha(candidate);self.targets[row['target']]['candidate_sha256']=sha(candidate);self.proofs[ident]['exact_literal_bytes_after_original_typed_inverse']=True;return
        super().build_node(row)
        if row['id']=='registry_final':
            before=self.read_json_input(row['base_input']);after=self.nodes[row['id']]['value'];inverse=copy.deepcopy(after);need(len(row['operations'])==5,'ONLY_FIVE_DT_REGISTRY_VALUES')
            for op in row['operations']:need(len(op['pointer'])==4 and op['pointer'][0]=='rooms' and op['pointer'][2]=='source_sha256' and op['pointer'][3]=='res://scripts/city/luoyang_district_life_20261016f.gd','ONLY_DT_ROOM_SOURCE_OP');M.pointer(inverse,op['pointer'][:-1])[op['pointer'][-1]]=op['old']
            need(same(inverse,before),'FULL_REGISTRY_OTHER_FIELDS_UNCHANGED')
        if row['id']=='estate_final':
            value=self.nodes[row['id']]['value'];registry='res://data/maps/luoyang_estate_rooms_20261021am/registry.json';need(value.get('registry_path')==registry and value.get('registry_sha256')==value.get('source_sha256',{}).get(registry)==self.nodes['registry_final']['sha256'],'ESTATE_REGISTRY_PATH_SCALAR_SOURCE_TRIPLE_EQUALITY')
    def _exact_eof_transport_patch(self,target,before,after):
        eof=self.eof_approval
        if target!=res(eof['target']).as_posix():
            return M._strict_lf_build_file_patch(target,before,after)
        need(sha(before)==eof['old_sha256'] and sha(after)==eof['candidate_sha256'] and len(before)==30746 and len(after)==31206,'ONLY_EXACT_5709_TOCF2AA_EOF_PAIR')
        need(before and after and not before.endswith(b'\n') and not after.endswith(b'\n') and b'\r'not in before and b'\r'not in after and not before.startswith(b'\xef\xbb\xbf') and not after.startswith(b'\xef\xbb\xbf'),'SOLE_MISSING_FINAL_LF_NOT_GENERAL_EOL_NORMALIZATION')
        old_shadow=before+b'\n';new_shadow=after+b'\n'
        need(sha(new_shadow)==eof['patch_intermediate_sha256'] and len(new_shadow)==31207 and new_shadow[:-1]==after and new_shadow[-1:]==b'\n' and old_shadow[:-1]==before,'EXACT_IN_MEMORY_SINGLE_LF_SHADOWS')
        piece,proof=M._strict_lf_build_file_patch(target,old_shadow,new_shadow)
        need(proof.get('forward_exact_bytes') is True and proof.get('whole_inverse_exact_bytes') is True and proof.get('reconstructed_sha256')==eof['patch_intermediate_sha256'],'ORIGINAL_STRICT_WHOLE_SHADOW_FORWARD_AND_INVERSE')
        proof.update(candidate_sha256=sha(after),forward_exact_bytes=False,whole_inverse_exact_bytes=False,
                     forward_exact_intermediate_bytes=True,whole_shadow_inverse_exact_bytes=True,
                     original_before_sha256=sha(before),original_before_bytes=len(before),
                     old_shadow_sha256=sha(old_shadow),old_shadow_bytes=len(old_shadow),
                     patch_intermediate_sha256=sha(new_shadow),patch_intermediate_bytes=len(new_shadow),
                     final_requires_exact_root_authorized_EOF_formatting=True,
                     exact_original_before_and_after_recovered_by_removing_only_shadow_final_0A=True,
                     eof_format={'path':eof['target'],'approval_path':self.inputs[self.contract['eof_transport_input']]['path'],'approval_sha256':'25ff1b9474bb50ccc149e75a68959ccb0211c139d15f96c023983ba093ed2387','required_deployed_intermediate_sha256':sha(new_shadow),'required_deployed_intermediate_bytes':31207,'only_remove_exact_final_byte_hex':'0a','required_final_sha256':sha(after),'required_final_bytes':31206,'must_first_apply_patch_then_mechanically_remove_one_final_byte_from_deployed_characters':True,'never_copy_GD_candidate_or_strip_general_whitespace':True})
        return piece,proof

    def run(self):
        gates=self.spec['required_gates'];need({row['id'] for row in gates}==M.REQUIRED_GATES,'FIVE_ORIGINAL_NATIVE_AND_SCOPE_GATES')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        exact={r['target']:r['candidate']for r in self.codes.values()if r.get('target','').endswith('.gd')};exact[EXE]={'path':self.inputs[self.spec['authority_input']]['path'],'sha256':PROPOSAL}
        need(len(exact)==8 and len(self.spec['pass_through_targets'])==8,'EXACT_SEVEN_GD_PLUS_EXECUTION_PASSTHROUGHS')
        for row in self.spec['pass_through_targets']:
            need(row['target']in exact and row['old_sha256']==self.oldtargets[row['target']] and exact[row['target']]=={'path':row['candidate_path'],'sha256':row['candidate_sha256']},'ONLY_FIXED_RUNTIME_CANDIDATE_BYTES');self.read(row['candidate_path'],row['candidate_sha256']);self.read(row['target'],row['old_sha256']);self.target(row['target'],row['old_sha256'],row['candidate_path'],row['candidate_sha256'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[row for row in self.spec['nodes'] if row['kind']=='map']
        need({row['scene_id'] for row in maps}==set(M.BASELINES) and all(self.spec['common_group'] in row['groups'] for row in maps),'FOUR_FROZEN_AO_BASELINES_COMPLETE_GROUPS')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==30,'EXACT30_CHANGED_TARGETS')
        patch=['*** Begin Patch\n'];reconstruction={};copies=[]
        for row in self.targets.values():
            path=row['candidate_path'];candidate=self.outputs[path] if path in self.outputs else self.read(path,row['candidate_sha256']);before=self.read(row['target'],row['old_sha256'])
            need(sha(candidate)==row['candidate_sha256'] and candidate!=before,'FINAL_FIXED_CHANGED_BYTES')
            if row['target'].endswith('.json'):
                if row['target']==EXE:
                    need(sha(before)==PARENT and sha(candidate)==PROPOSAL,'EXACT_BF043_TO647949_EXECUTION_BYTES');proof_id='fixed_Root_execution_whole_inverse'
                else:
                    matches=[k for k,v in self.nodes.items()if v['path']==path and v['sha256']==row['candidate_sha256']];need(len(matches)==1 and self.proofs[matches[0]].get('whole_typed_inverse') is True,'ONLY_FULL_TYPED_INVERSE_GENERATED_JSON');proof_id=matches[0]
                copies.append({**row,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION','inverse_proof':proof_id})
                reconstruction[row['target']]={'kind':'ExactMechanicalByteCopy','candidate_sha256':sha(candidate),'candidate_bytes':len(candidate),'original_bytes_preserved':True,'normalized':False,'whole_inverse_proof':proof_id};continue
            need(row['target'].endswith('.gd'),'GD_ONLY_PATCH_PARTITION')
            piece,proof=self._exact_eof_transport_patch(res(row['target']).as_posix(),before,candidate)
            patch.append(piece);reconstruction[row['target']]=proof
        patch.append('*** End Patch\n')
        need(len(copies)==15 and len(reconstruction)==30 and len([path for path in self.targets if path.endswith('.gd')])==15 and {r['target'] for r in copies}=={path for path in self.targets if path.endswith('.json')},'PATCH15_COPY15_EXACT_DISJOINT_UNION30')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT15_GENERATED_JSON_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(path for path in self.targets if path.endswith('.gd')),'copy_targets':sorted(r['target'] for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}))
        final={path:sha(res(path).read_bytes()) for path in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':15},'target_partition':{'patch_count':15,'copy_count':15,'total':30,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':self.spec['source_baseline'],'runtime_inverse_replayed':False}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for path,b in self.outputs.items():
            dest=res(path);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as f:f.write(b)
        return {'output_root':self.out,'targets':30,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();path=Path(args.input).resolve();need(path.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=path.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+path.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(MarketCompleteParentStage(spec).run()))
if __name__=='__main__':main()
