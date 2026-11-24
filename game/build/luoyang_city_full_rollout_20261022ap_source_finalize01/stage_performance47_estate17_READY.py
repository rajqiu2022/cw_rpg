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
FIXED_AUTHORITY='bf043ab07d6ecb2c713607753e3ab2c67621923456ed44e7ab3393d9d3e9ed0d'
FROZEN={'runtime_contract_final': '59cf1ebdac2f8f17b644b00f36e241b8b4e43275a50ec6a8b1eb7d89632e59c1', 'registry_final': 'f5298b913fbaefda2c5f3679223c014c219292a54df412a8c3f2d96e4f082f28', 'ap_environment_index': 'da57b51fa60cade6e5acf99a1fa32c63b5604e282ac28da5905f5ec61384ab3a', 'ap_execution_index': '3727d55af17cf5cdfdce9600e36cc515e01004026c5efc7ef5a91faabed78570', 'quarter_final': '1cdab2b637d96eb0e4251246c0ed56426a2362515a33f213006b5eb4e22dafd9', 'ap_quarter_index': 'bb9d784e79d26a82b109ff866c084997921d4016c1d37b6d125db73b7c26fff9'}
class EstateScalarStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'LOCKED_ESTATE17_INPUT')
        super().__init__(spec)
        c=spec['B_only_contract'];root=self.read_json_input(c['scope_input']);request=self.read_json_input(c['scope_request_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']=='61696f03de75249a8ce133319106b258e3f78d6efbfae1db52095b7fd0605bf2' and same(root,c['expected_Root_document']) and root.get('status')=='ROOT_APPROVED_EXACT17_ESTATE_REGISTRY_SCALAR_SUCCESSOR_PREPARATION_ONLY','ROOT_EXACT17_APPROVAL_SCHEMA')
        need(root.get('existing_targets')==17 and root.get('GD_targets')==6 and root.get('JSON_targets')==11 and root.get('fresh_before_sha256')=='fc90fc19342eb7c31228165751674ae1af9206bfb6b12e041281a4b3dfd191f1' and root.get('Stage_execution_authorized') is False and root.get('deployment_authorized') is False and root.get('engine_authorized') is False,'ROOT_PREPARATION_ONLY_NO_BROAD_AUTHORITY')
        need(root.get('scope_sha256')==self.inputs[c['scope_request_input']]['sha256']=='a7d5fc152a5740a435d6f8314c825862127fffce1635d97bc7fbacf319695b6a' and root.get('old_full_backups_sha256')==self.inputs[c['backup_input']]['sha256']=='17fb9dc23ec6236a5eaac7183a3e31983ce2c60d3eed0d49e96f19cec679ee1d','FIXED_SCOPE_AND_BACKUPS')
        self.oldtargets={r['target']:r['old_sha256']for r in request['targets']};need(len(self.oldtargets)==17 and list(self.oldtargets)==spec['root_target_allowlist'] and backups.get('target_count')==17 and len(backups['targets'])==17,'EXACT_ORDERED17_TARGETS')
        backed={}
        for r in backups['targets']:
            target_path=Path(r['path']).resolve();backup=Path(r['backup_path']).resolve();need(target_path.is_relative_to(M.ROOT) and backup.is_relative_to(M.ROOT),'BACKUP_GAME_DOMAIN')
            path='res://'+target_path.relative_to(M.ROOT).as_posix();need(path not in backed,'UNIQUE_BACKUP_TARGET');backed[path]=r['sha256']
            before=self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['sha256']);need(len(before)==r['bytes'] and before==self.read(path,r['sha256']),'FULL17_OLD_BYTES_BACKED_UP')
        need(backed==self.oldtargets,'BACKUP_SCOPE_EXACT17')
        need(self.inputs[spec['authority_input']]['sha256']==FIXED_AUTHORITY and not spec['pass_through_targets'] and not spec['prospective_targets'],'UNCHANGED_EXECUTION_NO_NEW_CODE_OR_EDGES')
        stage=self.read_json_input(c['parent_stage_input']);owner=self.read_json_input(c['prior_owner_input'])
        need(self.inputs[c['parent_stage_input']]['sha256']=='5b4552e6751950b8576dadfec211a0b966ffdbe77817571197150347ae96ca5e' and self.inputs[c['prior_owner_input']]['sha256']=='544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0','FIXED_CURRENT_AP15_AND_INDEPENDENT_OWNER')
        prior={r['target']:r['candidate_sha256']for r in stage['targets']};need(all(prior.get(path)==s for path,s in self.oldtargets.items()),'ONLY_FIXED_CURRENT_CANDIDATE_OLD_PINS')
        self.scalar=self.read_json_input(c['scalar_inverse_input']);candidate=self.input_bytes[c['scalar_candidate_input']]
        need(self.inputs[c['scalar_inverse_input']]['sha256']=='9f782008132b157acfd6e33f18c71c70bc6d17cffa3f0491dad0e2efdb83db20' and sha(candidate)==root['scalar_candidate_sha256']=='2410ed000f79c898742106d455f7b79b26fcad7a57acb6d2632e71bc18c521eb','EXACT_SINGLE_SCALAR_CANDIDATE_AND_INVERSE')
        before=self.read(self.scalar['parent']['path'],self.scalar['parent']['sha256']);a,b=self.scalar['operation']['old'],self.scalar['operation']['new'];old=json.loads(before);new=json.loads(candidate)
        need(old['registry_path']=='res://data/maps/luoyang_estate_rooms_20261021am/registry.json' and old['source_sha256'][old['registry_path']]==b,'NEW_SCALAR_FROM_SAME_PARENT_DECLARED_SOURCE_NOT_CURRENT_FILL')
        inverse=copy.deepcopy(new);inverse['registry_sha256']=a;need(same(inverse,old) and encode(inverse)==before and before.replace(('"registry_sha256": "'+a+'"').encode(),('"registry_sha256": "'+b+'"').encode(),1)==candidate,'SCALAR_WHOLE_TYPED_AND_BYTE_INVERSE')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT17_CHANGED_TARGETS')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        if row['kind']=='estate17_frozen':
            ident=row['id'];need(ident in FROZEN and row['immutable_sha256']==self.inputs[row['base_input']]['sha256']==FROZEN[ident] and 'target'not in row,'ONLY_FIXED_UNCHANGED_NODE')
            raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw)if row['is_json']else None};self.proofs[ident]={'frozen_original_bytes':True,'not_target':True};return
        super().build_node(row)
        if row['id']=='estate_final':
            need(same(row['operations'],[self.scalar['operation']]),'ESTATE_ONLY_ONE_SCALAR_OPERATION')
            value=self.nodes[row['id']];candidate=self.input_bytes[self.spec['B_only_contract']['scalar_candidate_input']]
            need(self.proofs[row['id']].get('whole_typed_inverse') is True and self.outputs[value['path']]==candidate,'ORIGINAL_METADATA_INVERSE_AND_ENCODE_EXACT2410')
    def run(self):
        gates=self.spec['required_gates'];need({row['id'] for row in gates}==M.REQUIRED_GATES,'FIVE_ORIGINAL_NATIVE_AND_SCOPE_GATES')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[row for row in self.spec['nodes'] if row['kind']=='map']
        need({row['scene_id'] for row in maps}==set(M.BASELINES) and all(self.spec['common_group'] in row['groups'] for row in maps),'FOUR_FROZEN_AO_BASELINES_COMPLETE_GROUPS')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==17,'EXACT17_CHANGED_TARGETS')
        patch=['*** Begin Patch\n'];reconstruction={};copies=[]
        for row in self.targets.values():
            path=row['candidate_path'];candidate=self.outputs[path] if path in self.outputs else self.read(path,row['candidate_sha256']);before=self.read(row['target'],row['old_sha256'])
            need(sha(candidate)==row['candidate_sha256'] and candidate!=before,'FINAL_FIXED_CHANGED_BYTES')
            if row['target'].endswith('.json'):
                matches=[k for k,v in self.nodes.items() if v['path']==path and v['sha256']==row['candidate_sha256']]
                need(len(matches)==1 and self.proofs[matches[0]].get('whole_typed_inverse') is True,'ONLY_FULL_TYPED_INVERSE_GENERATED_JSON');proof_id=matches[0]
                copies.append({**row,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION','inverse_proof':proof_id})
                reconstruction[row['target']]={'kind':'ExactMechanicalByteCopy','candidate_sha256':sha(candidate),'candidate_bytes':len(candidate),'original_bytes_preserved':True,'normalized':False,'whole_inverse_proof':proof_id};continue
            need(row['target'].endswith('.gd'),'GD_ONLY_PATCH_PARTITION')
            piece,proof=M._strict_lf_build_file_patch(res(row['target']).as_posix(),before,candidate)
            patch.append(piece);reconstruction[row['target']]=proof
        patch.append('*** End Patch\n')
        need(len(copies)==11 and len(reconstruction)==17 and len([path for path in self.targets if path.endswith('.gd')])==6 and {r['target'] for r in copies}=={path for path in self.targets if path.endswith('.json')},'PATCH6_COPY11_EXACT_DISJOINT_UNION17')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT11_GENERATED_JSON_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(path for path in self.targets if path.endswith('.gd')),'copy_targets':sorted(r['target'] for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}))
        final={path:sha(res(path).read_bytes()) for path in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':11},'target_partition':{'patch_count':6,'copy_count':11,'total':17,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':self.spec['source_baseline'],'runtime_inverse_replayed':False}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for path,b in self.outputs.items():
            dest=res(path);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as f:f.write(b)
        return {'output_root':self.out,'targets':17,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();path=Path(args.input).resolve();need(path.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=path.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+path.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(EstateScalarStage(spec).run()))
if __name__=='__main__':main()
