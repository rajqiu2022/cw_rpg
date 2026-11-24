"""Exact18 selected A1 ENV source compiler; Root-only future Stage, never deployment."""
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
FROZEN={'ground_code': 'c1ef10bce6ef1b4b8ff4e50f7a00a7e409b80e8c36cfed9d4eea33fedcce05ce', 'runtime_contract_final': 'd258350b1b72377fb4189918178a1323de9506934d015859a4d5823271961b9b', 'registry_final': '56c5bd39f02f32b45a606c84e22a8784be4900c616b7ec20c7547e497ce49f12', 'estate_final': '3b898beb44d4ac7979d406aa62e3ccbd6874bde0606a6c050b9850713cbe1c02', 'legacy_index_0': '01334e035d9371cd43b69b0f5fdffebb34a11187893c21ef120ce48f5173c08f', 'ap_environment_index': 'da57b51fa60cade6e5acf99a1fa32c63b5604e282ac28da5905f5ec61384ab3a', 'ap_execution_index': 'ee6d36433c5ebc51cc09622d58116e8b63ed21a0f9059a69339237440c661fec'}
ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
OLD_ENV='cf945cab9ab689c87364fa477f22f0f326a70f2bb64f2d7e38d699ccdb42c26a'
NEW_ENV='c21586df883bfa96706f254823fa5952c1bd6fffb9807f2e0d1a12d00862847b'
SHADER='res://build/luoyang_city_full_rollout_20261022ap_system01/market_L_continuous_material_epoch01/market_L_continuous_candidate.gdshader'
SHADER_SHA='f1d01c7d63ba62b5c9883f4976f3b73da96e5b54243e4431d5ba5b61787c4d06'
class A1EnvironmentStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'LOCKED_A1_EXACT18')
        super().__init__(spec);c=spec['B_only_contract'];request=self.read_json_input(c['scope_input']);root=self.read_json_input(c['admission_input']);backups=self.read_json_input(c['backup_input'])
        need(self.inputs[c['scope_input']]['sha256']==root['scope_sha256']=='f9366efd437e41f85cc6f0802f3373b2525e142a5336f0456ab142e71e447979' and self.inputs[c['admission_input']]['sha256']=='c97b0e91f0856f8c8840ccd1a3035087da465f36b4d12cbf033300efe9daa3e7' and root['status']=='ROOT_ENV_NONOWNED_A1_PLUS_TONE_EXACT18_PREPARATION_APPROVED_NOT_STAGE_OR_DEPLOYMENT','EXACT_ROOT_SELECTED_A1_ENV18')
        need(self.inputs[c['backup_input']]['sha256']==root['old18_full_backups_sha256']=='316af8888619590a9f28eeee09cd6b8a349a381ab448fbe4e1827cbef3eea914' and self.inputs[c['before_input']]['sha256']==root['root48_before_sha256']=='e6265c42b67b46f47b7c6d2ddaa60bb7877dcaed0019016ce6936e9fd761089e' and backups['target_count']==18 and backups['scope_sha256']==self.inputs[c['scope_input']]['sha256'],'EXACT18_BACKUPS_ROOT48_FRESH')
        self.oldtargets={r['target']:r['old_sha256']for r in request['existing_targets']};need(len(self.oldtargets)==18 and list(self.oldtargets)==spec['root_target_allowlist'],'EXACT18_ORDERED_EXISTING_TARGETS')
        backed={}
        for r in backups['targets']:
            target=Path(r['path']).resolve();backup=Path(r['backup_path']).resolve();need(target.is_relative_to(M.ROOT) and backup.is_relative_to(M.ROOT),'EXACT_BACKUP_GAME_PATHS')
            path='res://'+target.relative_to(M.ROOT).as_posix();need(path not in backed,'UNIQUE_BACKUP');backed[path]=r['sha256'];saved=self.read('res://'+backup.relative_to(M.ROOT).as_posix(),r['sha256']);need(saved==self.read(path,r['sha256']) and len(saved)==r['bytes'],'COMPLETE_EIGHTEEN_OLD_BYTE_BACKUPS')
        need(backed==self.oldtargets and self.inputs[spec['authority_input']]['sha256']==FIXED_AUTHORITY and len(self.authority['owned'])==10 and len(self.authority['source_sha256'])==95 and ENV not in self.authority['owned'] and ENV not in self.authority['source_sha256'] and not spec['pass_through_targets'] and not spec['prospective_targets'],'UNCHANGED_EXECUTION647949_OWNED10_PROOF95_NONOWNED_ENV')
        stage=self.read_json_input(c['parent_stage_input']);self.owner=self.read_json_input(c['prior_owner_input']);need(self.inputs[c['parent_stage_input']]['sha256']=='1dff38bf897130d74bb6c0d51b4436fa25d97de9bb8e4502ea8490364262ccfe' and self.inputs[c['prior_owner_input']]['sha256']==root['current_owner_sha256']=='669e5d3e4ece06cf33707d6afdced6d65dc5ca7785b8f44ff19698dde741f7c0','FIXED1DFF_OWNER669_NOT_CURRENT_FILL')
        need(all(self.owner['core_source_sha256'].get(path)==old for path,old in self.oldtargets.items()) and self.oldtargets[ENV]==OLD_ENV,'ALL18_OLD_VALUES_FROM_FIXED669_CORE')
        self.baseproof=self.read_json_input(c['proof_input']);self.toneproof=self.read_json_input(c['tone_input']);author=self.read_json_input(c['author_input']);review=self.read_json_input(c['review_input'])
        need(self.inputs[c['proof_input']]['sha256']==root['A1_full_inverse_sha256']=='1091f241c877fa5d4ce575f3e2bf56165539de7a55305f43d832c447e03a7e95' and self.inputs[c['tone_input']]['sha256']==root['tone_single_hunk_inverse_sha256']=='fa9d5e131c4ae4b12e1ceb27e4a13db0b6a02e1e91543ba85e1e982e428de548' and self.inputs[c['author_input']]['sha256']==root['A1_author_sha256']=='1183eda4f35cc8eea176a53797d0c3ed9d63d232940b245cd39dfae9e8268caa','EXACT_TWO_SELECTED_ENV_INVERSE_PROOFS')
        need(self.inputs[c['candidate_input']]['sha256']==root['selected_ENV_sha256']==NEW_ENV and self.inputs[c['candidate_input']]['path']==root['selected_ENV_path'] and self.inputs[c['shader_input']]['sha256']==root['new_Market_only_shader_sha256']==SHADER_SHA and self.inputs[c['shader_input']]['path']==root['new_Market_only_shader_path']==SHADER,'ONE_SELECTED_C215_AND_F1D0_RUNTIME_SHADER')
        need(self.inputs[c['review_input']]['sha256']=='72d566463948d3e128b60fca6f0c93d9674c97c528d9da46adc8f05ff5b77774' and review['findings']==[] and review['selected_single_ENV_candidate']['sha256']==NEW_ENV and author['runtime_ready'] is False,'INDEPENDENT_STATIC_NOT_GPU_OR_ART_CREDIT')
        group=[r for r in spec['source_groups']if r['id']=='A1_Market_runtime_shader'];need(len(group)==1 and same(group[0],{'id':'A1_Market_runtime_shader','kind':'explicit','leaves':{SHADER:{'$pin':c['shader_input']}}}),'EXACT_ONE_ORDINARY_MARKET_SHADER_GROUP')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'ONLY_EXACT18_CHANGED_TARGETS')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        if row['kind']=='a1_code':
            need(row['id']=='ENV_code' and row['target']==ENV and row['old_sha256']==OLD_ENV,'EXACT_NONOWNED_ENV_ONLY')
            raw=self.input_bytes[row['base_input']];before=self.read(ENV,OLD_ENV);ops=self.baseproof['operations_in_order'];tone=self.toneproof['one_hunk'];need(len(ops)==10 and sha(raw)==NEW_ENV,'TEN_A1_OPERATIONS_PLUS_ONE_RGB')
            forward=before
            for h in ops:
                a,b=h['old'].encode(),h['new'].encode();need(forward.count(a)==1,'UNIQUE_A1_OLD_HUNK');forward=forward.replace(a,b,1)
            need(sha(forward)==self.baseproof['candidate']['sha256'].lower()==self.toneproof['parent_A1_ENV']['sha256'].lower(),'FIXED047B_INTERMEDIATE')
            a,b=tone['old'].encode(),tone['new'].encode();need(forward.count(a)==1 and raw.count(b)==1 and forward.replace(a,b,1)==raw,'EXACT_ONE_RGB_FORWARD')
            inverse=raw.replace(b,a,1)
            for h in reversed(ops):
                a,b=h['old'].encode(),h['new'].encode();need(inverse.count(b)==1,'UNIQUE_A1_NEW_HUNK');inverse=inverse.replace(b,a,1)
            need(inverse==before and b'\r'not in raw and raw.endswith(b'\n'),'WHOLE_ENV_BYTE_INVERSE_STRICT_LF_NO_NORMALIZATION')
            path=self.inputs[row['base_input']]['path'];self.nodes[row['id']]={'path':path,'sha256':sha(raw),'value':None};self.proofs[row['id']]={'whole_byte_forward_inverse':True,'A1_operations':10,'RGB_operations':1,'nonowned_no_execution_change':True};self.target(ENV,OLD_ENV,path,sha(raw));return
        if row['kind']=='a1_frozen':
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
            if row['id']in ['market_final','finite08_market']:
                need(all(SHADER not in M.pointer(before,k)for k in fields),'ONE_NEW_MARKET_SHADER_ABSENT_BEFORE');expected['legacy_source_sha256'][SHADER]=SHADER_SHA
            need(same(expected,value) and self.proofs[row['id']]['whole_typed_inverse'] is True,'ONLY_ENV_EXISTING_HEADER_VALUES_AND_ONE_MARKET_SHADER')
        if row['kind']=='map':
            old=next(r for r in self.owner['scenes']if r['id']==row['scene_id'])['source_sha256'];expected=copy.deepcopy(old)
            for path,target in self.targets.items():
                if path in expected:need(expected[path]==target['old_sha256'],'FIXED669_OLD_VALUE');expected[path]=target['candidate_sha256']
            if row['scene_id']=='ch4_s3_luoyang_market':need(len(old)==1712 and SHADER not in old,'FIXED669_MARKET1712');expected[SHADER]=SHADER_SHA
            need(same(expected,self.nodes[row['id']]['value']['source_sha256']),'FOUR_FULL_FIXED669_MAPS_EXACT18_VALUES_ONLY_MARKET_PLUS1')
    def run(self):
        gates=self.spec['required_gates'];need({row['id'] for row in gates}==M.REQUIRED_GATES,'FIVE_ORIGINAL_NATIVE_AND_SCOPE_GATES')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[row for row in self.spec['nodes'] if row['kind']=='map']
        need({row['scene_id'] for row in maps}==set(M.BASELINES) and all(self.spec['common_group'] in row['groups'] for row in maps),'FOUR_FROZEN_AO_BASELINES_COMPLETE_GROUPS')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==18,'EXACT18_CHANGED_TARGETS')
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
        need(len(copies)==11 and len(reconstruction)==18 and len([path for path in self.targets if path.endswith('.gd')])==7 and {r['target'] for r in copies}=={path for path in self.targets if path.endswith('.json')},'PATCH7_COPY11_EXACT_DISJOINT_UNION18')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT11_GENERATED_JSON_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(path for path in self.targets if path.endswith('.gd')),'copy_targets':sorted(r['target'] for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}))
        final={path:sha(res(path).read_bytes()) for path in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':11},'target_partition':{'patch_count':7,'copy_count':11,'total':18,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':self.spec['source_baseline'],'runtime_inverse_replayed':False}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for path,b in self.outputs.items():
            dest=res(path);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as f:f.write(b)
        return {'output_root':self.out,'targets':18,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();path=Path(args.input).resolve();need(path.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=path.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+path.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(A1EnvironmentStage(spec).run()))
if __name__=='__main__':main()
