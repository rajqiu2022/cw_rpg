"""Exact8 ground finite35 source compiler; Root-only future Stage, never deployment."""
import argparse,copy,hashlib,importlib.util,json
from pathlib import Path
HERE=Path(__file__).resolve().parent
BASE=HERE/'stage_unified06_04_READY.py'
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
module=importlib.util.spec_from_file_location('frozen_B_only_source_base06',BASE)
M=importlib.util.module_from_spec(module);module.loader.exec_module(M)
need,sha,same,res,encode=M.need,M.digest,M.same,M.res,M.encode
S=M.PREFIX
FIXED_AUTHORITY='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3'
FROZEN={'runtime_contract_final': 'd258350b1b72377fb4189918178a1323de9506934d015859a4d5823271961b9b', 'registry_final': '56c5bd39f02f32b45a606c84e22a8784be4900c616b7ec20c7547e497ce49f12', 'estate_final': '3b898beb44d4ac7979d406aa62e3ccbd6874bde0606a6c050b9850713cbe1c02', 'legacy_manifest_2': '5400bd3d821bc236cfa385476462591d61fe30217f986245142da9d612e9fe11', 'legacy_manifest_3': '3b31a066c085386794e946e6fe68b9e670db675bc39ca83ed8f6a1e316344b2e', 'legacy_manifest_4': '502f5c952cb4ee7c1b38dd1e4b43124020b2dcd7143db9778d0aeaa6ce4fd10b', 'legacy_manifest_6': '19d9c426485844132bba861c7669dbc98b0d5bc8545b6edb29e7b63f4556f881', 'legacy_manifest_7': '0d4919c33a56cd65ad00b03642ff343aab33a0b5eff2eda6953ac974675fa16e', 'legacy_index_0': '01334e035d9371cd43b69b0f5fdffebb34a11187893c21ef120ce48f5173c08f', 'legacy_index_3': '3fe0d66970370ae88a3f65abe258d50d2fc0b7cef3f2f21027f7072e11737662', 'legacy_index_4': '07160ce48f7ba294b8e50b383c8bd7426d154f07f69ae95908507bc52b1e6bf4', 'ap_environment_index': 'da57b51fa60cade6e5acf99a1fa32c63b5604e282ac28da5905f5ec61384ab3a', 'ap_execution_index': 'ee6d36433c5ebc51cc09622d58116e8b63ed21a0f9059a69339237440c661fec', 'quarter_final': '72838a6846c2ad5b455bca45c866138d41fe78137341679552d792eee7a37bea', 'ap_quarter_index': 'e2132315778c2fbe2c0b89ba4fc720b2e741f6b18bb531f75ce147bcfe05e531', 'finite08_yamen': 'fbb7d151e15dc9177e111855317b7f600d3f8992dea866c2af4cb6d014bd5d89'}
GROUND='res://scripts/city/luoyang_market_ground_20261020ae.gd'
OLD_GROUND='02a43e66bee985eaf67b6184d43270454ba3d648fbee8ae2789e0e188fabafd3'
NEW_GROUND='c1ef10bce6ef1b4b8ff4e50f7a00a7e409b80e8c36cfed9d4eea33fedcce05ce'
class GroundSourceStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'LOCKED_GROUND_EXACT8')
        super().__init__(spec);c=spec['B_only_contract'];request=self.read_json_input(c['scope_input']);root=self.read_json_input(c['admission_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']=='ceaab710ea5aba573cb892e06acd21c6549c67e1f0b9e1a136f2d22496119deb' and self.inputs[c['admission_input']]['sha256']=='53150c2d09c80ca4ba3388e7392f4710acc0a94989c5f568de97ee0de41c5487' and root.get('status')=='ROOT_EXACT8_GROUND_FINITE35_PREPARATION_APPROVED_NOT_STAGE_OR_DEPLOYMENT','EXACT_ROOT_GROUND_PREPARATION')
        need(self.inputs[c['backup_input']]['sha256']==root['old_full_backups_sha256']=='e488247289964b59af23f794c90946054b51ce452c498900e27e5c4700419aef' and self.inputs[c['before_input']]['sha256']==root['before_sha256']=='c168a30baf8a4d9435468e276810f6220d445864813bdecfb795e065b3d2e355' and backups['target_count']==8 and root['scope_sha256']==self.inputs[c['scope_input']]['sha256'],'EXACT8_BACKUPS_AND_ROOT45_FRESH')
        self.oldtargets={r['target']:r['old_sha256']for r in request['targets']};need(len(self.oldtargets)==8 and list(self.oldtargets)==spec['root_target_allowlist'],'EXACT8_ORDERED_TARGETS')
        backed={}
        for r in backups['targets']:
            target=Path(r['path']).resolve();backup=Path(r['backup_path']).resolve();need(target.is_relative_to(M.ROOT) and backup.is_relative_to(M.ROOT),'EXACT_BACKUP_GAME_PATHS')
            path='res://'+target.relative_to(M.ROOT).as_posix();need(path not in backed,'UNIQUE_BACKUP');backed[path]=r['sha256'];saved=self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['sha256']);need(saved==self.read(path,r['sha256']) and len(saved)==r['bytes'],'COMPLETE_EIGHT_OLD_BYTE_BACKUPS')
        need(backed==self.oldtargets and self.inputs[spec['authority_input']]['sha256']==FIXED_AUTHORITY and len(self.authority['owned'])==10 and len(self.authority['source_sha256'])==95 and GROUND not in self.authority['owned'] and GROUND not in self.authority['source_sha256'] and not spec['pass_through_targets'] and not spec['prospective_targets'],'UNCHANGED647949_OWNED10_PROOF95_GROUND_NONOWNED')
        stage=self.read_json_input(c['parent_stage_input']);self.owner=self.read_json_input(c['prior_owner_input']);need(self.inputs[c['parent_stage_input']]['sha256']=='464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f' and self.inputs[c['prior_owner_input']]['sha256']=='e7177cb8e97e957bab6f0f88bbcbb5bb5d82de4087f2bb45085d4cf06f2a1f03','FIXED464BA_E717_NOT_CURRENT_FILL')
        prior={r['target']:r['candidate_sha256']for r in stage['targets']};prior[GROUND]=next(r for r in self.owner['scenes']if r['id']=='ch4_s3_luoyang_market')['source_sha256'][GROUND]
        need(all(prior.get(path)==s for path,s in self.oldtargets.items()) and prior[GROUND]==OLD_GROUND,'EXACT8_OLD_FROM_FIXED_PRIOR_DECLARATIONS')
        self.authorproof=self.read_json_input(c['proof_input']);need(self.inputs[c['proof_input']]['sha256']==root['authorproof_sha256']=='2cb284c359ece3eff07efe379d02a1ea7f88fa6f1e717896b821b184eb20d00d' and self.inputs[c['candidate_input']]['sha256']==root['ground_candidate_sha256']==NEW_GROUND and self.authorproof['parent']['path']==GROUND and self.authorproof['parent']['sha256'].lower()==OLD_GROUND and self.authorproof['candidate']['sha256'].lower()==NEW_GROUND and self.authorproof['wholebyte_inverse'] is True,'EXACT_GROUND_TWO_HUNK_CANDIDATE_AND_ROOT_PIN')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT8_CHANGED_TARGETS')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        if row['kind']=='ground8_code':
            need(row['id']=='ground_code' and row['target']==GROUND and row['old_sha256']==OLD_GROUND,'EXACT_NONOWNED_GROUND_ONLY')
            raw=self.input_bytes[row['base_input']];before=self.read(GROUND,OLD_GROUND);hunks=self.authorproof['hunks'];need(len(hunks)==2 and sha(raw)==NEW_GROUND,'EXACT_TWO_GROUND_HUNKS')
            insertion=hunks[0]['new'].encode();anchor=b'static func prepare(';need(before.count(anchor)==1 and insertion and raw.count(insertion)==1,'GROUND_INSERTION_UNIQUE')
            forward=before.replace(anchor,insertion+anchor,1);old=hunks[1]['old'].encode();new=hunks[1]['new'].encode();need(forward.count(old)==1 and raw.count(new)==1,'GROUND_COUNT_CONDITION_UNIQUE')
            need(forward.replace(old,new,1)==raw and raw.replace(new,old,1).replace(insertion,b'',1)==before and b'\r'not in raw and raw.endswith(b'\n'),'WHOLE_GROUND_BYTE_FORWARD_INVERSE_STRICT_LF')
            path=self.inputs[row['base_input']]['path'];self.nodes[row['id']]={'path':path,'sha256':sha(raw),'value':None};self.proofs[row['id']]={'whole_byte_forward_inverse':True,'nonowned_no_execution_change':True};self.target(GROUND,OLD_GROUND,path,sha(raw));return
        if row['kind']=='ground8_frozen':
            ident=row['id'];need(ident in FROZEN and row['immutable_sha256']==self.inputs[row['base_input']]['sha256']==FROZEN[ident] and 'target'not in row,'EXACT_FROZEN_OTHER_DOMAINS')
            raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw)if row['is_json']else None};self.proofs[ident]={'frozen_original_bytes':True,'not_target':True};return
        super().build_node(row)
        if row['kind']=='metadata':
            before=self.read_json_input(row['base_input']);value=self.nodes[row['id']]['value'];expected=copy.deepcopy(before)
            fields=row['source_bundle']['fields']if'source_bundle'in row else[f['pointer']for f in row.get('source_fields',[])]
            for keys in fields:
                values=M.pointer(expected,keys)
                for path,target in self.targets.items():
                    if path in values:need(values[path]==target['old_sha256'],'EXACT_EXISTING_SOURCE_OLD');values[path]=target['candidate_sha256']
            need(same(expected,value) and self.proofs[row['id']]['whole_typed_inverse'] is True,'ONLY_GROUND_AND_EXISTING_DECLARED_HEADER_VALUE_SUCCESSION')
        if row['kind']=='map':
            old=next(r for r in self.owner['scenes']if r['id']==row['scene_id'])['source_sha256'];expected=copy.deepcopy(old)
            for path,target in self.targets.items():
                if path in expected:need(expected[path]==target['old_sha256'],'FIXED_E717_OLD_VALUE');expected[path]=target['candidate_sha256']
            need(same(expected,self.nodes[row['id']]['value']['source_sha256']),'FOUR_FULL_FIXED_E717_MAPS_EXACT8_VALUES_KEYS_COUNTS_UNCHANGED')
    def run(self):
        gates=self.spec['required_gates'];need({row['id'] for row in gates}==M.REQUIRED_GATES,'FIVE_ORIGINAL_NATIVE_AND_SCOPE_GATES')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[row for row in self.spec['nodes'] if row['kind']=='map']
        need({row['scene_id'] for row in maps}==set(M.BASELINES) and all(self.spec['common_group'] in row['groups'] for row in maps),'FOUR_FROZEN_AO_BASELINES_COMPLETE_GROUPS')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==8,'EXACT8_CHANGED_TARGETS')
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
        need(len(copies)==4 and len(reconstruction)==8 and len([path for path in self.targets if path.endswith('.gd')])==4 and {r['target'] for r in copies}=={path for path in self.targets if path.endswith('.json')},'PATCH4_COPY4_EXACT_DISJOINT_UNION8')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT4_GENERATED_JSON_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(path for path in self.targets if path.endswith('.gd')),'copy_targets':sorted(r['target'] for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}))
        final={path:sha(res(path).read_bytes()) for path in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':4},'target_partition':{'patch_count':4,'copy_count':4,'total':8,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':self.spec['source_baseline'],'runtime_inverse_replayed':False}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for path,b in self.outputs.items():
            dest=res(path);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as f:f.write(b)
        return {'output_root':self.out,'targets':8,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();path=Path(args.input).resolve();need(path.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=path.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+path.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(GroundSourceStage(spec).run()))
if __name__=='__main__':main()
