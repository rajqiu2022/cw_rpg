"""Exact21 ordinary AA/AC source compiler BUILD; Root-only later Stage, never deployment."""
import argparse,copy,hashlib,importlib.util,json
from pathlib import Path
HERE=Path(__file__).resolve().parent
BASE=HERE/'stage_unified06_04_READY.py'
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
module=importlib.util.spec_from_file_location('frozen_B_only_source_base06',BASE)
M=importlib.util.module_from_spec(module);module.loader.exec_module(M)
need,sha,same,res,encode=M.need,M.digest,M.same,M.res,M.encode
S=M.PREFIX
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
PARENT='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3'
PROPOSAL='d184d50821f11bf012bd34baac374c4939fdfa5c51f6c415d31e249bbc8a6f29'
AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd'
AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
FROZEN={'ENV_code':'c21586df883bfa96706f254823fa5952c1bd6fffb9807f2e0d1a12d00862847b','ground_code':'c1ef10bce6ef1b4b8ff4e50f7a00a7e409b80e8c36cfed9d4eea33fedcce05ce','runtime_contract_final':'d258350b1b72377fb4189918178a1323de9506934d015859a4d5823271961b9b','registry_final':'56c5bd39f02f32b45a606c84e22a8784be4900c616b7ec20c7547e497ce49f12','estate_final':'3b898beb44d4ac7979d406aa62e3ccbd6874bde0606a6c050b9850713cbe1c02','legacy_index_0':'01334e035d9371cd43b69b0f5fdffebb34a11187893c21ef120ce48f5173c08f','ap_environment_index':'da57b51fa60cade6e5acf99a1fa32c63b5604e282ac28da5905f5ec61384ab3a'}
class DocksOrdinaryStage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[],'ROOT_NEW_READINESS_LOCK_REQUIRED_BUILD_FALSE_CANNOT_RUN')
        super().__init__(spec);c=spec['B_only_contract'];self.contract=c
        root=self.read_json_input(c['admission_input']);scope=self.read_json_input(c['scope_input']);back=self.read_json_input(c['backup_input'])
        need(self.inputs[c['admission_input']]['sha256']=='ec1e49d5cca161ccbd23e459c863f7c1df5e55b2f4c53cb682645f3364661a17' and same(root,c['expected_Root_document']) and root.get('approved_by_root') is True and root.get('status')=='ROOT_APPROVES_EXACT_AC_EXECUTION_CANDIDATE_AND_21_TARGET_PREPARATION_NOT_STAGE_OR_DEPLOY','EXACT_ROOT57_PREPARATION_DOCUMENT')
        need(self.inputs[c['scope_input']]['sha256']==root['scope_sha256']=='838a2b435653a29efd4b4e9cba826835db3d47d562aec3ddd56e741da411bccb' and self.inputs[c['backup_input']]['sha256']==root['full21_backup_receipt_sha256']=='8242633f6f02452630c4ccf06311e176cb91c7ad30919018e9a37a77654b7d17' and self.inputs[c['before_input']]['sha256']==root['before_sha256']=='bbce7ebb9baa5b1b2d8eb56a7a35f430e3005d93b298c48651b227b1e2f71ed7','FIXED_SCOPE_BACKUPS_FRESH')
        self.oldtargets={r['path']:r['old_sha256']for r in scope['proposed_targets']}
        need(len(self.oldtargets)==21 and list(self.oldtargets)==spec['root_target_allowlist'] and same(back['counts'],{'targets':21,'GD':9,'JSON':12}) and back['scope_sha256']==root['scope_sha256'] and back['before_sha256']==root['before_sha256'],'EXACT_ROOT57_BACKUP_SCHEMA')
        backed={}
        for r in back['targets']:
            path=r['path'];backup=r['backup'];need(path in self.oldtargets and path not in backed and backup.startswith(S.replace('_source_finalize01/','_root01/')+'integration57/full21_backups/'),'EXACT_UNIQUE_ROOT57_BACKUP_PATH')
            saved=self.read(backup,r['sha256']);need(saved==self.read(path,r['sha256']) and len(saved)==r['bytes'],'FULL21_ORIGINAL_BYTE_BACKUPS');backed[path]=r['sha256']
        need(backed==self.oldtargets,'FULL_BACKUP_EXACT21')
        self.owner=self.read_json_input(c['prior_owner_input']);self.read_json_input(c['parent_stage_input'])
        need(self.inputs[c['prior_owner_input']]['sha256']=='3715a958d0f9ee71d1ffdbe823ddcbd066d7613e2f5748d0e96e4bd25ed7e666' and self.inputs[c['parent_stage_input']]['sha256']=='e4beb20d93cd00b91933f7879fc63edf5a173b3a3a772b5293fb56896f055468','FIXED_OWNER72_STAGE_E4BE_NO_CURRENT_FILL')
        docks=next(r for r in self.owner['scenes']if r['id']=='ch4_s2_canal_docks')['source_sha256']
        need(all((docks.get(path)if path==AA else self.owner['core_source_sha256'].get(path))==old for path,old in self.oldtargets.items()),'ALL21_OLD_VALUES_FROM_FIXED_OWNER72')
        self.codes=self.read_json_input(c['inverse_input'])['records']
        need(self.inputs[c['inverse_input']]['sha256']=='d463e772039113c30852db2445b5756ed5dc85282c35957ac7d7a20eecfd6c5c' and set(self.codes)=={'AA','AC'},'EXACT_TWO_CODE_RECORDS')
        for name,r in self.codes.items():
            before=self.read(r['target'],r['parent_sha256']);after=self.read(r['candidate']['path'],r['candidate']['sha256']);forward=before;inverse=after
            for h in r['hunks']:
                a,b=h['old'].encode(),h['new'].encode();need(forward.count(a)==1 and inverse.count(b)==1,'UNIQUE_ORDINARY_CODE_HUNKS');forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
            need(forward==after and inverse==before and len(after)==r['candidate']['bytes'] and b'\r'not in after and after.endswith(b'\n'),'TWO_WHOLE_BYTE_CODE_INVERSES_STRICT_LF')
        prior=self.read_json_input(c['parent_execution_input'])
        need(self.inputs[c['parent_execution_input']]['sha256']==PARENT and self.inputs[spec['authority_input']]['sha256']==root['execution_candidate_sha256']==PROPOSAL and len(prior['owned'])==len(self.authority['owned'])==10 and set(prior['owned'])==set(self.authority['owned']) and AA not in self.authority['owned'],'ACTIVE10_C_AA_NOT_ADDED')
        restored=copy.deepcopy(self.authority);r=self.codes['AC'];old=prior['owned'][AC];new=self.authority['owned'][AC]
        need(len(new['edges'])==len(old['edges'])+1 and same(new['edges'][:-1],old['edges']) and new['current_sha256']==r['candidate']['sha256'],'AC_ONLY_ONE_APPEND_KEEP_ALL_HISTORY')
        e=new['edges'][-1];need(e['old_sha256']==old['current_sha256']==r['parent_sha256'] and e['new_sha256']==new['current_sha256'] and e['new_snapshot']==r['candidate']['path'] and same(e['replacements'],r['hunks']) and prior['source_sha256'].get(e['old_snapshot'])==e['old_sha256'],'EXACT_AC_EDGE_AND_EXISTING_OLD_SNAPSHOT')
        need(all(same(row,self.authority['owned'][path])for path,row in prior['owned'].items()if path!=AC),'NINE_OTHER_ROWS_WHOLE_TYPED_SAME')
        extra={p:s for p,s in self.authority['source_sha256'].items()if p not in prior['source_sha256']}
        need(len(prior['source_sha256'])==95 and len(self.authority['source_sha256'])==96 and same(extra,{r['candidate']['path']:r['candidate']['sha256']}) and all(self.authority['source_sha256'].get(p)==s for p,s in prior['source_sha256'].items()),'OLD95_PLUS_ONLY_NEW_AC_SNAPSHOT')
        restored['owned'][AC]=copy.deepcopy(old);restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior) and encode(restored)==self.input_bytes[c['parent_execution_input']],'WHOLE_EXECUTION_TYPED_AND_UTF8_BYTE_INVERSE_647949')
        self.extra=extra;self.ordinary=c['ordinary_Docks_only_pins']
        group=[g for g in spec['source_groups']if g['id']=='Docks_exact_ordinary_C_AA_proofs']
        need(len(group)==1 and len(self.ordinary)==2 and self.value(group[0]['leaves'])==self.ordinary and group[0]['kind']=='explicit','EXACT_TWO_DOCKS_ORDINARY_PROOFS_NOT_EXECUTION')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'EXACT21_CHANGED_ONLY_NO_NOOP')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        if row['kind']=='ordinary_execution':
            need(row['id']=='execution_final' and self.inputs[row['base_input']]['sha256']==PROPOSAL,'ONLY_VALIDATED_EXECUTION_NODE')
            raw=self.input_bytes[row['base_input']];self.nodes[row['id']]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':self.authority};self.proofs[row['id']]={'whole_typed_inverse':True,'old95_plus1':True};return
        if row['kind']=='ordinary_frozen':
            ident=row['id'];need(ident in FROZEN and row['immutable_sha256']==self.inputs[row['base_input']]['sha256']==FROZEN[ident] and 'target'not in row,'EXACT_FROZEN_OTHER_DOMAINS')
            raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw)if row['is_json']else None};self.proofs[ident]={'frozen_original_bytes':True,'not_target':True};return
        super().build_node(row)
        if row['kind']=='metadata':
            before=self.read_json_input(row['base_input']);value=self.nodes[row['id']]['value'];expected=copy.deepcopy(before)
            fields=row['source_bundle']['fields']if'source_bundle'in row else[f['pointer']for f in row.get('source_fields',[])]
            for ks in fields:
                values=M.pointer(expected,ks)
                for path,t in self.targets.items():
                    if path in values:need(values[path]==t['old_sha256'],'EXACT_EXISTING_SOURCE_OLD');values[path]=t['candidate_sha256']
            destination='source_sha256'if row['id']=='quarter_final'else'legacy_source_sha256'
            need(all(path not in M.pointer(before,ks)for path in self.extra for ks in fields),'NEW_AC_SNAPSHOT_ABSENT_BEFORE')
            expected[destination].update(self.extra)
            if row['id']in ['legacy_manifest_4','legacy_manifest_6','legacy_manifest_7']:
                need(all(path not in M.pointer(before,ks)for path in self.ordinary for ks in fields),'ORDINARY_PROOFS_ABSENT_BEFORE');expected['legacy_source_sha256'].update(self.ordinary)
            need(same(expected,value) and self.proofs[row['id']]['whole_typed_inverse']is True,'ONLY21_VALUES_AND_EXACT_NEW_SOURCE_LEAVES')
        if row['kind']=='map':
            old=next(r for r in self.owner['scenes']if r['id']==row['scene_id'])['source_sha256'];expected=copy.deepcopy(old)
            for path,t in self.targets.items():
                if path in expected:need(expected[path]==t['old_sha256'],'FIXED72_MAP_OLD');expected[path]=t['candidate_sha256']
            expected.update(self.extra)
            if row['scene_id']=='ch4_s2_canal_docks':expected.update(self.ordinary)
            need(same(expected,self.nodes[row['id']]['value']['source_sha256']),'FOUR_FULL_FIXED72_MAPS_EXACT_VALUE_AND_KEY_DELTA')
    def run(self):
        gates=self.spec['required_gates'];need({row['id'] for row in gates}==M.REQUIRED_GATES,'FIVE_ORIGINAL_NATIVE_AND_SCOPE_GATES')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        exact={r['target']:{'path':r['candidate']['path'],'sha256':r['candidate']['sha256']}for r in self.codes.values()};exact[EXE]={'path':self.inputs[self.spec['authority_input']]['path'],'sha256':PROPOSAL}
        need(len(exact)==len(self.spec['pass_through_targets'])==3,'ONLY_AA_AC_EXECUTION_PASSTHROUGH')
        for row in self.spec['pass_through_targets']:
            need(row['target']in exact and row['old_sha256']==self.oldtargets[row['target']] and exact[row['target']]=={'path':row['candidate_path'],'sha256':row['candidate_sha256']},'EXACT_APPROVED_CANDIDATE_BYTES_ONLY')
            self.read(row['target'],row['old_sha256']);self.read(row['candidate_path'],row['candidate_sha256']);self.target(row['target'],row['old_sha256'],row['candidate_path'],row['candidate_sha256'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[row for row in self.spec['nodes'] if row['kind']=='map']
        need({row['scene_id'] for row in maps}==set(M.BASELINES) and all(self.spec['common_group'] in row['groups'] for row in maps),'FOUR_FROZEN_AO_BASELINES_COMPLETE_GROUPS')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==21,'EXACT21_CHANGED_TARGETS')
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
        need(len(copies)==12 and len(reconstruction)==21 and len([path for path in self.targets if path.endswith('.gd')])==9 and {r['target'] for r in copies}=={path for path in self.targets if path.endswith('.json')},'PATCH9_COPY12_EXACT_DISJOINT_UNION21')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT12_GENERATED_JSON_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(path for path in self.targets if path.endswith('.gd')),'copy_targets':sorted(r['target'] for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}))
        final={path:sha(res(path).read_bytes()) for path in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':12},'target_partition':{'patch_count':9,'copy_count':12,'total':21,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':self.spec['source_baseline'],'runtime_inverse_replayed':False}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for path,b in self.outputs.items():
            dest=res(path);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as f:f.write(b)
        return {'output_root':self.out,'targets':21,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();path=Path(args.input).resolve();need(path.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=path.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+path.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(DocksOrdinaryStage(spec).run()))
if __name__=='__main__':main()
