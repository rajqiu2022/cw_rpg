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
FROZEN={'runtime_contract_final': '59cf1ebdac2f8f17b644b00f36e241b8b4e43275a50ec6a8b1eb7d89632e59c1', 'registry_final': 'f5298b913fbaefda2c5f3679223c014c219292a54df412a8c3f2d96e4f082f28', 'estate_final': '2410ed000f79c898742106d455f7b79b26fcad7a57acb6d2632e71bc18c521eb', 'legacy_manifest_2': '3b17d3cd502ba3035acd41692cd501e62ee305c4833f566f2b8ff2d086dd4be6', 'legacy_manifest_3': '42ebcf37a0656b36bae694f32fc246aa391ee2707ed38191bf1c6decc0217e89', 'legacy_manifest_4': '414426e375927729f16e2f192570750044ad1bccec368635008e532e278f3cbd', 'legacy_manifest_5': '7cc5e27be4c367f125cbf33f005c59bc2a95ade119efa8cad8314e9b79445a0d', 'legacy_manifest_6': 'f72edd1944f2dd1fe58cb32f7ff7de8a8aa579c592cd401204d66ed26e493d75', 'legacy_manifest_7': '3f3f0895e2ae57d9938b6f20d48a630eee651b295471c175dbf28cb8e765befd', 'legacy_manifest_8': '5f67cb7a60637a685524aa19bae568581e1be6a230c296bba84ec46a626f723a', 'legacy_index_0': '079cb15872b215bdc2678aedb328adc05877c6c35ecc1d2f789e79549e3f3470', 'legacy_index_1': '834f418bfa8cc99e05e966601eb964c139ba27d498764bb8de0800e19cade195', 'legacy_index_2': '9357f7500e17f7893038ce8d65fd9ab7ee1f8b4ce6417199be2478b143bcb6f0', 'legacy_index_3': '5ccbfbf3a8019f27d965153d2b27160feeb6794688d4eab75a6a9e67ea12fb53', 'legacy_index_4': '6afca19aa9ef236400282c734e8bae357b74a30434928d7b255c65ffca1a88a3', 'ap_environment_index': 'da57b51fa60cade6e5acf99a1fa32c63b5604e282ac28da5905f5ec61384ab3a', 'ap_execution_index': '3727d55af17cf5cdfdce9600e36cc515e01004026c5efc7ef5a91faabed78570', 'quarter_final': '1cdab2b637d96eb0e4251246c0ed56426a2362515a33f213006b5eb4e22dafd9', 'ap_quarter_index': 'bb9d784e79d26a82b109ff866c084997921d4016c1d37b6d125db73b7c26fff9', 'finite08_yamen': '8e2c0bb5d432b861f5e60101b50e7c280e6f23b70d45470ee250453f0657550d'}
NEW_LEAVES={'res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision4/publication_assets/walk.png.import': '0640e6c6584447940c6e961486a92809a0e9aaa4fd12b85f5ee55a7c636b14e6', 'res://.godot/imported/walk.png-eb63fda1eba65c60ad6a24b15599ec76.ctex': '93c55bdd37077b51b3eb835c57950d6f62ca81bad45ee3f3c4cbac3cea1505bb'}
class MarketSourceTupleStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'LOCKED_SOURCE_ONLY_TUPLE3')
        super().__init__(spec);c=spec['B_only_contract'];request=self.read_json_input(c['scope_input']);root=self.read_json_input(c['admission_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']=='cba12cace9f6ffb44be694ce6a27ccc9152793e460c2e03e79c109b8fa151342' and self.inputs[c['admission_input']]['sha256']=='b1bb3a2ce1067f0d5029f052fe59631e785ca114a591dff5de07150e52d368e4' and root.get('status')=='ROOT_EXPLICIT_NEW_SOURCE_ONLY_TWO_LEAF_ADMISSION' and root.get('approved_by_root') is True and same(root['source_leaves'],NEW_LEAVES),'EXACT_ROOT_SOURCE_ONLY_TWO_LEAF_ADMISSION')
        need(self.inputs[c['backup_input']]['sha256']=='c36a4468c463554402fdb1d3a8e7e363a7fb974e30ee8e50da9929bc3177611f' and self.inputs[c['before_input']]['sha256']=='43c680af9d180b0e7c8330d28ad5671faaa24da2329129d74307bb8f9ee98987' and backups.get('target_count')==3 and backups['scope_sha256']==self.inputs[c['scope_input']]['sha256'],'EXACT3_OLD_BACKUP_AND_ROOT40_FRESH')
        self.oldtargets={r['target']:r['old_sha256']for r in request['targets']};need(len(self.oldtargets)==3 and list(self.oldtargets)==spec['root_target_allowlist'] and len(backups['targets'])==3,'EXACT3_ORDERED_TARGETS')
        backed={}
        for r in backups['targets']:
            target=Path(r['path']).resolve();backup=Path(r['backup_path']).resolve();need(target.is_relative_to(M.ROOT) and backup.is_relative_to(M.ROOT),'EXACT_BACKUP_GAME_PATHS')
            path='res://'+target.relative_to(M.ROOT).as_posix();need(path not in backed,'UNIQUE_BACKUP');backed[path]=r['sha256'];saved=self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['sha256']);need(saved==self.read(path,r['sha256']) and len(saved)==r['bytes'],'COMPLETE_THREE_OLD_BYTE_BACKUPS')
        need(backed==self.oldtargets and self.inputs[spec['authority_input']]['sha256']==FIXED_AUTHORITY and not spec['pass_through_targets'] and not spec['prospective_targets'],'NO_CODE_EXECUTION_NATIVE_SUCCESSOR')
        stage=self.read_json_input(c['parent_stage_input']);self.owner=self.read_json_input(c['prior_owner_input']);need(self.inputs[c['parent_stage_input']]['sha256']=='96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7' and self.inputs[c['prior_owner_input']]['sha256']=='585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f','FIXED96CA_AND5857_NOT_CURRENT_FILL')
        prior={r['target']:r['candidate_sha256']for r in stage['targets']};need(all(prior.get(path)==s for path,s in self.oldtargets.items()),'CURRENT_OLD3_FROM_FIXED_STAGE_CANDIDATES')
        qa=self.read_json_input(c['qa_input']);actual=self.read_json_input(c['actual_input']);capture=self.read_json_input(c['capture_input']);after=self.read_json_input(c['after_input'])
        need(self.inputs[c['qa_input']]['sha256']==root['independent_review_sha256']=='e935cede7865d93a98b67919872609d1db1ef19682fd154d008c9c5a9f08c202' and self.inputs[c['actual_input']]['sha256']==root['actual_report_sha256']=='7477cdb2826f96d0d915bf51ab5da534f1fb24729e0d2f1c145c776c645dccc7','NEW_PIXEL_ACTUAL_AND_INDEPENDENT_REVIEW_PINS')
        need(actual.get('complete') is True and actual.get('failures')==[] and actual.get('import_calls')==0 and actual.get('collector_Field_Scene_geometry_calls')==0 and qa['checks']['complete'] is True and qa['checks']['failures']==0 and qa['checks']['23currentparams_fixalpha_true_detect1_unchanged'] is True,'SOURCE_ONLY_FULL_RGBA_ACTUAL_NO_RUNTIME_IMPORT_CREDIT')
        need(self.inputs[c['capture_input']]['sha256']==root['facts_before_sha256']=='19d3a71b39266c1baf97beb960f3e9987e1ea0e0e60c94ac2193961b6718d296' and self.inputs[c['after_input']]['sha256']==root['facts_after_sha256']=='2d30691c5ceaf6b4b5657c445d147d13985c30edef24dbf0d882f25d207bec05' and qa['guard']['new3facts_before_after_exactticks_same'] is True,'CAPTURE_AND_AFTER_FACTS_BOUND_TO_NEW_PIXEL_PROOF')
        facts={'res://'+Path(r['path']).resolve().relative_to(M.ROOT).as_posix():r['sha256']for r in capture['facts']};need(all(facts.get(path)==s for path,s in NEW_LEAVES.items()) and root['raw_rgba_sha256']=='6e72541153449e571516c340838794ff44fdf96dfc8b601b93733b3d4ff4c6da','EXACT_NEW_TWO_LEAVES_NOT_BORROWED_OLD_TUPLE')
        groups=[r for r in spec['source_groups']if r['id']==c['literal_group']];need(len(groups)==1 and same(groups[0],{'id':c['literal_group'],'kind':'explicit','leaves':NEW_LEAVES}),'EXACT_TWO_LITERAL_MEDIA_GROUP')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT3_CHANGED_TARGETS')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        if row['kind']=='tuple3_frozen':
            ident=row['id'];need(ident in FROZEN and row['immutable_sha256']==self.inputs[row['base_input']]['sha256']==FROZEN[ident] and 'target'not in row,'EXACT_FROZEN_OTHER_DOMAINS')
            raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw)if row['is_json']else None};self.proofs[ident]={'frozen_original_bytes':True,'not_target':True};return
        super().build_node(row)
        if row['id']in ['market_final','finite08_market']:
            before=self.read_json_input(row['base_input']);value=self.nodes[row['id']]['value'];expected=copy.deepcopy(before)
            for field in ['legacy_source_sha256','runtime_authority_sha256','artifacts']:
                for path,target in self.targets.items():
                    if path in expected[field]:need(expected[field][path]==target['old_sha256'],'EXACT_HEADER_OLD');expected[field][path]=target['candidate_sha256']
            for path,s in NEW_LEAVES.items():
                need(all(path not in before[field]for field in ['legacy_source_sha256','runtime_authority_sha256','artifacts']),'ONLY_TWO_NEW_LEAVES');expected['legacy_source_sha256'][path]=s
            need(same(expected,value) and self.proofs[row['id']]['whole_typed_inverse'] is True,'ONLY_LEGACY_TWO_AND_EXISTING_HEADER_SUCCESSION_FULL_TYPED_INVERSE')
        if row['kind']=='map':
            old=next(r for r in self.owner['scenes']if r['id']==row['scene_id'])['source_sha256'];expected=copy.deepcopy(old)
            for path,target in self.targets.items():
                if path in expected:need(expected[path]==target['old_sha256'],'FIXED5857_HEADER_OLD');expected[path]=target['candidate_sha256']
            if row['scene_id']=='ch4_s3_luoyang_market':
                need(len(old)==1700 and not(set(old)&set(NEW_LEAVES)),'FIXED_MARKET1700');expected.update(NEW_LEAVES)
            need(same(expected,self.nodes[row['id']]['value']['source_sha256']),'FOUR_INDEPENDENT_AO_MAPS_EXACT_FIXED5857_PLUS3HEADERS_MARKET2_NO_COLLECTOR_FILL')
    def run(self):
        gates=self.spec['required_gates'];need({row['id'] for row in gates}==M.REQUIRED_GATES,'FIVE_ORIGINAL_NATIVE_AND_SCOPE_GATES')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[row for row in self.spec['nodes'] if row['kind']=='map']
        need({row['scene_id'] for row in maps}==set(M.BASELINES) and all(self.spec['common_group'] in row['groups'] for row in maps),'FOUR_FROZEN_AO_BASELINES_COMPLETE_GROUPS')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==3,'EXACT3_CHANGED_TARGETS')
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
        need(len(copies)==2 and len(reconstruction)==3 and len([path for path in self.targets if path.endswith('.gd')])==1 and {r['target'] for r in copies}=={path for path in self.targets if path.endswith('.json')},'PATCH1_COPY2_EXACT_DISJOINT_UNION3')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT2_GENERATED_JSON_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(path for path in self.targets if path.endswith('.gd')),'copy_targets':sorted(r['target'] for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}))
        final={path:sha(res(path).read_bytes()) for path in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':2},'target_partition':{'patch_count':1,'copy_count':2,'total':3,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':self.spec['source_baseline'],'runtime_inverse_replayed':False}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for path,b in self.outputs.items():
            dest=res(path);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as f:f.write(b)
        return {'output_root':self.out,'targets':3,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();path=Path(args.input).resolve();need(path.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=path.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+path.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(MarketSourceTupleStage(spec).run()))
if __name__=='__main__':main()
