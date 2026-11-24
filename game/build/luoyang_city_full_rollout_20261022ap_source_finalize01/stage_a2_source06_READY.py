"""Root-only A2 source compiler. NEW outputs only; no engine or formal writes.

Original source/typed/group/media/map/authority validators are imported exactly.
The only new data interfaces are frozen nodes, exact Field contract bytes and
the fixed Artisan three-path declaration plus binding metadata after source-only
validation. Existing finite Market/Yamen headers use ordinary source metadata.
"""
import argparse
import copy
import hashlib
import importlib.util
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent
BASE=HERE/'stage_unified06_04_READY.py'
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
module=importlib.util.spec_from_file_location('frozen_a2_source_base06',BASE)
M=importlib.util.module_from_spec(module);module.loader.exec_module(M)
need,sha,same,res,encode=M.need,M.digest,M.same,M.res,M.encode
S=M.PREFIX
PROPOSAL='85df6c96670165398e37b4a66627df74cd300bace841e5d064be058e7fd48187'
PARENT='c668a0be6bc051237857dc4d2822308077a808a800f51a27f04f8b75c75f8405'
HAND='258cde4cb62b3f5fa2e1ac01cb08a322ffc6b8eca3d63c11c34b2add161f7085'
REQUEST='b2e0ef8625e93198d48086030d0a1832bcc932d8c821a946a3490592adaca219'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
FIELD='res://scripts/field/field_walkable_controller.gd'
QUARTER='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
ARTISAN='luoyang_artisan_residential_20261022ap'
GARDEN='luoyang_riverside_garden_20261022ap'

class A2Stage(M.Stage):
    def __init__(self,spec):
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and spec.get('blockers')==[], 'ROOT_LOCKED_A2_NO_PENDING_BLOCKERS')
        super().__init__(spec)
        self.contract=spec['a2_contract']
        self.hand=self.read_json_input(self.contract['production_handoff_input'])
        self.binding=self.read_json_input(self.contract['binding_input'])
        need(self.inputs[self.contract['production_handoff_input']]['sha256']==HAND and self.inputs[self.spec['authority_input']]['sha256']==PROPOSAL,'FIXED_A2_PRODUCTION04_AND_PROPOSAL')
        need(self.binding.get('ready') is True and self.binding.get('status')=='ROOT_FIXED_A2_ARTISAN_NATIVE_AND_ART_BINDING','EXACT_A2_CANDIDATE_FLAGS')
        self.check_authority_and_scope()

    def check_authority_and_scope(self):
        c=self.contract
        root=self.read_json_input(c['execution_root_input'])
        need(self.inputs[c['execution_root_input']]['sha256']=='89f6fb928ce90475c67a32dd75a68c6aa3a974769b3e10d38d2059c159b7febf' and root.get('approved_by_root') is True and root.get('status')=='ROOT_APPROVED_A2_PRODUCTION04_EXACT_EXECUTION_AND_DEPENDENCY_SCOPE_NOT_DEPLOYMENT','ROOT_A2_EXACT_EXECUTION_SCOPE_AUTHORITY')
        need(root['proposal']=={'path':self.inputs[self.spec['authority_input']]['path'],'sha256':PROPOSAL} and root['parent']=={'path':EXE,'sha256':PARENT},'ROOT_C668_TO_EXACT85DF')
        prior=self.read_json_input(c['execution_parent_input'])
        need(self.inputs[c['execution_parent_input']]['sha256']==PARENT and len(prior['owned'])==10 and set(prior['owned'])==set(self.authority['owned']),'SAME_ACTUAL_TEN_OWNED_MEMBERS')
        changed={r['target'] for r in self.hand['owned_changed_exactly4']}
        need(changed=={r['path'] for r in root['new_edges']} and len(changed)==4,'ONLY_EXACT_ROOT_FOUR_OWNED_ROWS')
        restored=copy.deepcopy(self.authority)
        for p,before in prior['owned'].items():
            after=self.authority['owned'][p]
            if p in changed:
                need(len(after['edges'])==len(before['edges'])+1 and same(after['edges'][:-1],before['edges']),'ONE_APPENDED_EDGE_OLD_GRAPH_PRESERVED')
                last=after['edges'][-1]
                need(last['old_sha256']==before['current_sha256'] and last['new_sha256']==after['current_sha256'],'EXACT_DEPLOYED_CURRENT_TO_NEW_CURRENT')
                need(any(r['path']==p and r['old_sha256']==last['old_sha256'] and r['new_sha256']==last['new_sha256'] for r in root['new_edges']),'ROOT_MATCHED_EXACT_EDGE')
                restored['owned'][p]=copy.deepcopy(before)
            else:need(same(before,after),'OTHER_SIX_OWNED_ROWS_IDENTICAL')
        need(len(prior['source_sha256'])==57 and len(self.authority['source_sha256'])==63 and all(self.authority['source_sha256'].get(p)==s for p,s in prior['source_sha256'].items()),'OLD57_UNCHANGED_PLUS_EXACT6')
        need({p:s for p,s in self.authority['source_sha256'].items() if p not in prior['source_sha256']}==self.hand['new_proof_pins'],'EXACT_SIX_DECLARED_NEW_PROOF_PINS')
        restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior),'WHOLE_EXECUTION_TYPED_INVERSE_C668')
        scope=self.read_json_input(c['scope_input']);request=self.read_json_input(c['scope_request_input'])
        need(self.inputs[c['scope_request_input']]['sha256']==REQUEST and scope.get('approved_by_root') is True and scope.get('request_sha256')==REQUEST and self.inputs[c['scope_input']]['sha256']=='350d22e9d57a1622b6d08e0b3d18ab127ecbab9e740c2baa04f67ebb7dee4892' and scope.get('target_count')==28,'ROOT_FRESH_EXACT28_SCOPE')
        need(scope.get('before_sha256')==self.spec['root_lock_scope']['before_sha256'] and self.inputs[c['scope_input']]['sha256']==self.spec['root_lock_scope']['sha256'],'EXACT_FRESH_ROOT_SCOPE_PIN')
        self.oldtargets={r['target']:r['old_sha256'] for r in request['targets']}
        need(len(self.oldtargets)==28 and [r['target'] for r in request['targets']]==self.spec['root_target_allowlist'],'ORDERED_EXACT28_TARGET_REQUEST')
        need({r['target']:r['old_sha256'] for r in scope['targets']}==self.oldtargets,'ROOT_BACKUP_SCOPE_PARENT_HASHES')
        for row in request['targets']:
            need(self.read(row['target'],row['old_sha256'])==self.read(row['old_snapshot'],row['old_sha256']),'ROOT_SCOPE_FROZEN_OLD_BYTES')
        for row in scope['targets']:
            backup=Path(row['backup_path']).resolve()
            need(backup.is_relative_to(M.ROOT) and row['backup_sha256']==row['old_sha256'],'ROOT_EXACT28_BACKUP_DOMAIN_AND_SHA')
            backup_resource='res://'+backup.relative_to(M.ROOT).as_posix()
            need(self.read(backup_resource,row['backup_sha256'])==self.read(row['target'],row['old_sha256']),'ALL28_COMPLETE_ROOT_OLD_BYTE_BACKUPS')
        lineage=self.read_json_input(c['docks22_lineage_input'])['source_sha256']
        family='res://scripts/city/luoyang_quarters_family_20261022ap.gd'
        expected=copy.deepcopy(lineage)
        family_row=next(r for r in self.hand['consumers'] if r['target']==family)
        need(len(expected)==22 and expected.get(family)==family_row['old_sha256'],'EXACT_FROZEN22_FAMILY_PREDECESSOR')
        expected[family]=family_row['candidate']['sha256']
        group=self.groups['unified_docks22']
        need(group['kind']=='explicit' and same(self.value(group['leaves']),expected),'ONLY_FAMILY_SUCCESSOR_IN_FROZEN22_OTHERS_IDENTICAL')
        gate=c['mask_promotion_gate']
        need(gate['input']==c['mask_promotion_input'] and same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'ROOT_MASK_PROMOTION_ACTUAL_GATE')
        # Actual78528 establishes media identity. Promotion only copies the two
        # fixed new imports; exact current bytes are also verified by groups.
        need(self.inputs[c['mask_actual_input']]['sha256']=='299fcadbe84424197f095d737ecdbca8740612779176578fbbb5ddf249de0b3f','FIXED94_CHECK_SINGLE_MASK_IMPORT_ACTUAL')
        need(len(request['new_media_targets'])==2 and all(r['old_sha256']=='ABSENT' for r in request['new_media_targets']),'ONLY_TWO_ABSENT_MASK_PROMOTION_TARGETS')
        for row in request['new_media_targets']:self.read(row['path'],row['candidate_sha256'])
        need(self.inputs[c['code_root_input']]['sha256']=='bbbd2ff11077f66940c5159326631e98bcc73527ab198b090b1305520d6d62cd','EXACT03_CODE_SCOPE_AUTHORITY')

    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'EXACT28_CHANGED_TARGET_ONLY')
        return super().target(target,old,path,expected)

    def build_node(self,row):
        ident=row['id']
        if row['kind']=='a2_frozen_node':
            need(ident in ['registry_final','ap_environment_index'] and self.inputs[row['base_input']]['sha256']==row['immutable_sha256'],'ONLY_EXACT_UNCHANGED_REGISTRY_AND_ENVINDEX')
            raw=self.input_bytes[row['base_input']]
            self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw) if ident=='registry_final' else None}
            self.proofs[ident]={'frozen_original_bytes':True,'not_target_or_reformatted_output':True};return
        if row['kind']=='a2_contract':
            need(row['target']==CONTRACT and row['old_sha256']=='d1dc0d9e8e797e8b791eed2c445c99ff7dfd1c9be141e0a9f9ed0b7401255974','EXACT_DEPLOYED_D1DC_CONTRACT_PARENT')
            need(len(row['operations'])==1 and row['operations'][0]['pointer']==['source_sha256',FIELD],'CONTRACT_ONLY_FIELD_TIMING_SOURCE_PIN')
            value=copy.deepcopy(self.read_json_input(row['base_input']))
            deltas=self.change(value,row['operations'],True)
            literal=self.read_json_input(row['literal_candidate_input'])
            need(same(value,literal) and self.inputs[row['literal_candidate_input']]['sha256']==self.hand['contract']['sha256'],'EXACT_FULL_TYPED_CHECKED_LITERAL_CONTRACT')
            raw=self.input_bytes[row['literal_candidate_input']];p,s=self.output(row['file'],raw)
            self.nodes[ident]={'path':p,'sha256':s,'value':value};self.proofs[ident]={'whole_typed_inverse':True,'source_delta':deltas,'literal_original_bytes':True}
            self.target(row['target'],row['old_sha256'],p,s);return
        if row['kind']=='a2_quarter':
            need(row['target']==QUARTER,'ONLY_FIXED_QUARTER_DECLARATION_SUCCESSOR')
            original=self.read_json_input(row['base_input'])
            ordinary=copy.deepcopy(row);ordinary['kind']='metadata';ordinary.pop('target')
            ordinary.setdefault('forbidden_source_paths',[]).append(QUARTER)
            operations=ordinary.pop('a2_geometry_declaration_operations')
            super().build_node(ordinary)
            node=self.nodes[ident];source_only=copy.deepcopy(node['value'])
            expected=[]
            for field,suffix in [('scene_path','scene.res'),('layout_path','layout.res'),('packet_path','packet.bin')]:
                expected.append({'op':'set','pointer':['scenes',ARTISAN,field],'existed':True,'old':original['scenes'][ARTISAN][field],'new':self.binding['child'][suffix]['path']})
            expected.append({'op':'set','pointer':['a2_artisan_successor'],'existed':False,'old':None,'new':{'binding_path':self.hand['binding']['path'],'binding_sha256':self.hand['binding']['sha256']}})
            need(same(operations,expected),'EXACT_ARTISAN_THREE_PATHS_AND_ONE_DECLARATION_ONLY')
            deltas=self.change(node['value'],operations,False)
            need(same(node['value']['scenes'][GARDEN],original['scenes'][GARDEN]) and same(node['value']['connections'],original['connections']) and same(node['value']['seed_provenance'],original['seed_provenance']),'GARDEN_ALL_PATHS_CONNECTIONS_SEED_UNCHANGED')
            for p,s in self.binding['source_sha256'].items():need(node['value']['source_sha256'].get(p)==s,'FIXED_A2_BINDING_DECLARED_SOURCE_LEAF')
            need(node['value']['source_sha256'].get(self.hand['binding']['path'])==self.hand['binding']['sha256'],'A2_BINDING_EXTERNAL_SOURCE_NOT_REVERSE_MANIFEST_PIN')
            raw=encode(node['value']);self.outputs[node['path']]=raw;node['sha256']=sha(raw)
            self.proofs[ident].update({'exact_A2_declaration_delta':deltas,'source_only_before_exact_A2_declaration':True,'runtime_parent_inverse_replay':False,'fixed_publisher_inverse_inherited':True,'Garden_native_and_connections_unchanged':True})
            back=copy.deepcopy(node['value'])
            for delta in reversed(deltas):
                holder,key=M.pointer(back,delta['pointer'][:-1]),delta['pointer'][-1]
                if delta['existed']:holder[key]=delta['old']
                else:del holder[key]
            need(same(back,source_only),'A2_DECLARATION_WHOLE_TYPED_INVERSE')
            self.target(QUARTER,row['old_sha256'],node['path'],node['sha256']);return
        return super().build_node(row)

    def run(self):
        gates=self.spec['required_gates']
        need({r['id'] for r in gates}==M.REQUIRED_GATES,'FIVE_ORIGINAL_NATIVE_PERMISSION_GATES_PRESERVED')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        for row in self.spec['pass_through_targets']:
            after=self.read(row['candidate_path'],row['candidate_sha256']);before=self.read(row['target'],row['old_sha256'])
            if row['target'] in M.OWNED:
                need(self.authority['owned'][row['target']]['current_sha256']==row['candidate_sha256'],'EXACT_FOUR_AUTHORITY_CURRENT_CODE')
            elif row['target']==EXE:
                need(row['old_sha256']==PARENT and row['candidate_sha256']==PROPOSAL and row['candidate_path']==self.inputs[self.spec['authority_input']]['path'],'SOLE_ROOT_APPROVED_EXECUTION_RAW_COPY')
            else:
                need(row['target'].endswith('.gd') and row.get('exact_replacements'),'NONOWNED_CODE_WHOLE_BYTE_INVERSE_REQUIRED')
                inverse=after.decode()
                for h in row['exact_replacements']:
                    need(h['new'] and inverse.count(h['new'])==1,'UNIQUE_NONOWNED_INVERSE_HUNK');inverse=inverse.replace(h['new'],h['old'],1)
                need(inverse.encode()==before,'COMPLETE_NONOWNED_FORMAL_PARENT_BYTE_INVERSE')
            self.target(row['target'],row['old_sha256'],row['candidate_path'],row['candidate_sha256'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[r for r in self.spec['nodes'] if r['kind']=='map']
        need({r['scene_id'] for r in maps}==set(M.BASELINES) and all(self.spec['common_group'] in r['groups'] for r in maps),'FOUR_ORIGINAL_BASELINES_AND_COMPLETE_COMMON_SOURCE_GROUP')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==28,'EXACT28_NO_NOOP_TARGETS')
        patch=['*** Begin Patch\n'];reconstruction={};copies=[]
        for row in self.targets.values():
            p=row['candidate_path'];candidate=self.outputs[p] if p in self.outputs else self.read(p,row['candidate_sha256'])
            before=self.read(row['target'],row['old_sha256'])
            need(sha(candidate)==row['candidate_sha256'] and candidate!=before,'FINAL_EXACT_CHANGED_CANDIDATE')
            if row['target']==EXE:
                need(sha(before)==PARENT and sha(candidate)==PROPOSAL,'EXACT_C668_TO85DF_COPY_ONLY')
                copies.append({**row,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION'})
                reconstruction[row['target']]={'kind':'ExactMechanicalByteCopy','candidate_sha256':PROPOSAL,'original_bytes_preserved':True};continue
            piece,proof=M._strict_lf_build_file_patch(res(row['target']).as_posix(),before,candidate)
            patch.append(piece);reconstruction[row['target']]=proof
        patch.append('*** End Patch\n')
        need(len(copies)==1 and copies[0]['target']==EXE and len(reconstruction)==28,'PATCH27_COPY1_EXACT_DISJOINT_UNION28')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT_C668_TO85DF_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(set(self.targets)-{EXE}),'copy_targets':[EXE],'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True}))
        final={p:sha(res(p).read_bytes()) for p in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':1},'target_partition':{'patch_count':27,'copy_count':1,'total':28,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':'Frozen AO4maps +885A metadata +deployed ED4C/DB9D; explicit A2 publication and media proofs; no observed collector fill','runtime_inverse_replayed':False}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_OUTPUTS_BUFFERED_UNTIL_PREFLIGHT_PASSED')
        for p,b in self.outputs.items():
            dest=res(p);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as stream:stream.write(b)
        return {'output_root':self.out,'targets':28,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();p=Path(args.input).resolve();need(p.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=p.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+p.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(A2Stage(spec).run()))
if __name__=='__main__':main()
