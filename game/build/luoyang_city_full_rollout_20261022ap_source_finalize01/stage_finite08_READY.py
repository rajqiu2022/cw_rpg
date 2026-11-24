"""Root-only exact28 finite08 source compiler. No engine or canonical writes.

All original authority/typed metadata/group/map validators remain imported
byte-frozen. New branches are limited to two fixed89216 manifests, their
external index, the fixed contract, and the new Root-approved C668 edge set.
"""
import argparse,copy,importlib.util,json
from pathlib import Path
HERE=Path(__file__).resolve().parent
BASE=HERE/'stage_unified06_04_READY.py'
import hashlib
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
module=importlib.util.spec_from_file_location('frozen_source_stage06',BASE)
M=importlib.util.module_from_spec(module);module.loader.exec_module(M)
need,sha,same,res,encode=M.need,M.digest,M.same,M.res,M.encode
S=M.PREFIX
HAND=S+'finite_adapter_production08/handoff_PRODUCTION_PROPOSAL.json'
HAND_SHA='8fd3b3b04b1ce33837aa60e1ae41e8a91d86939b08cf30b15421c546aa706e6c'
PARENT='a3880503360b0aa8ef745928e3f5f0effc452fc28cba773e3001122e30315a75'
NEXT='c668a0be6bc051237857dc4d2822308077a808a800f51a27f04f8b75c75f8405'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'

class FiniteStage(M.Stage):
    def __init__(self,spec):
        super().__init__(spec)
        contract=spec['finite08_contract']
        need(self.inputs[contract['handoff_input']]['path']==HAND and self.inputs[contract['handoff_input']]['sha256']==HAND_SHA,'EXACT08_HANDOFF')
        self.hand=self.read_json_input(contract['handoff_input'])
        self.binding=self.read_json_input(contract['binding_input'])
        need(self.binding.get('source_closure_ready') is True and self.hand['adapter_ready_candidate'] is True,'NEW08_PRODUCTION_FLAGS_ONLY')
        self.check_new_authority()

    def check_new_authority(self):
        c=self.spec['finite08_contract']
        root=self.read_json_input(c['execution_root_input'])
        need(self.inputs[c['execution_root_input']]['sha256']=='14c550115dd24b5b2ed5ce71211db9bc882a72f736b05e27ab153d78196a0ac6','ROOT_EXACT_NEW_EXECUTION_AUTHORITY_PIN')
        need(root.get('approved_by_root') is True and root.get('status')=='ROOT_APPROVED_SOLE_A388_FINITE08_EXECUTION_SUCCESSOR' and root.get('parent_sha256')==PARENT and root.get('candidate_sha256')==NEXT and root.get('candidate_path')==self.inputs[self.spec['authority_input']]['path'],'ROOT_APPROVED_EXACT_A388_C668')
        need(self.inputs[self.spec['authority_input']]['sha256']==NEXT,'AUTHORITY_INPUT_C668')
        prior=json.loads(self.read(EXE,PARENT))
        changed={r['target'] for r in self.hand['owned_changed_exactly5']}
        need(len(changed)==5 and set(prior['owned'])==set(self.authority['owned']) and len(prior['owned'])==10,'SAME_TEN_OWNED_NO_NEW_DOMAIN')
        back=copy.deepcopy(self.authority)
        for path,row in prior['owned'].items():
            after=self.authority['owned'][path]
            if path in changed:
                need(len(after['edges'])==len(row['edges'])+1 and same(after['edges'][:-1],row['edges']),'EXACT_ONE_APPENDED_EDGE')
                need(after['edges'][-1]['old_sha256']==row['current_sha256'] and after['edges'][-1]['new_sha256']==after['current_sha256'],'EDGE_FROM_DEPLOYED_PARENT_CURRENT')
                need(root['exact_five_final_owned_hashes'][path]==after['current_sha256'],'ROOT_EXACT_FINAL_FIVE_HASHES')
                back['owned'][path]=copy.deepcopy(row)
            else:need(same(after,row),'OTHER_FIVE_OWNED_UNCHANGED')
        need(len(prior['source_sha256'])==50 and len(self.authority['source_sha256'])==57 and all(self.authority['source_sha256'].get(p)==s for p,s in prior['source_sha256'].items()),'OLD50_EXACT_PLUS7')
        need({p:s for p,s in self.authority['source_sha256'].items() if p not in prior['source_sha256']}==self.hand['new_proof_pins'],'EXACT_DECLARED_SEVEN_NEW_PINS')
        back['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(back,prior),'COMPLETE_EXECUTION_TYPED_INVERSE_A388')
        scope=self.read_json_input(c['scope_root_input'])
        need(self.inputs[c['scope_root_input']]['sha256']=='0442c193acde18e358fa11fe3b820083023c0245f6001a7f3c616b57227f163a' and scope.get('approved_by_root') is True and scope.get('target_count')==28 and scope.get('scope_sha256')=='15f54447d64b4cb4048654aec64e9a1a634c36468358822818b335a634e2b672','ROOT_EXACT28_SCOPE_APPROVAL')
        finite_scope=self.read_json_input(c['scope_request_input'])
        need([r['target'] for r in finite_scope['targets']]==self.spec['root_target_allowlist'] and len(self.spec['root_target_allowlist'])==28,'ORDERED_EXACT28_SCOPE_ROWS')
        self.oldtargets={r['target']:r['old_sha256'] for r in finite_scope['targets']}
        for r in finite_scope['targets']:
            need(self.read(r['target'],r['old_sha256'])==self.read(r['old_snapshot'],r['old_sha256']),'SCOPE_PARENT_SNAPSHOT_EXACT')
        ground=self.read_json_input(c['ground_root_input'])
        need(self.inputs[c['ground_root_input']]['sha256']=='657722693680f15564aecc55a3e75929204400e3badcb509abb076259a31d8fe' and ground.get('approved_by_root') is True and ground.get('candidate_ENV_sha256')=='a751dbd4ce014abd2e808d7c9a947dc0e4a314d4b42930a6392a1d6eb7c20a7d' and ground.get('candidate_shader_sha256')=='e80916d7fa99218e3dc36ee1a83efd49f544ed426739941499c8500f23da14f1','EXACT_FIVE_RECT_ART_PERMISSION')
        code=self.read_json_input(c['code_root_input'])
        need(code.get('approved_by_root') is True and code.get('handoff_sha256')=='ad35db6e0ecaf04a9636ddd82dabe98f994ada3201971495b3818170192e7e32','ROOT07_CODE_SCOPE_PREDECESSOR_EXACT')

    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target],'EXACT28_OLD_TARGET_SHA')
        need(old!=expected,'NO_UNCHANGED_TARGET_REWRITE')
        return super().target(target,old,path,expected)

    def build_node(self,row):
        if row['kind']=='finite_contract':
            need(row['target']==CONTRACT and row['old_sha256']=='16b381c113ebfd0cb89f382eb99366bb703cda6baa40142cc1fbf97343ed74d8','FIXED08_CONTRACT_PARENT')
            base=self.read_json_input(row['base_input']);value=copy.deepcopy(base)
            need({tuple(o['pointer']) for o in row['operations']}=={('source_sha256','res://scripts/field/field_walkable_controller.gd'),('source_sha256','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd')},'CONTRACT_ONLY_FIELD_AND_C')
            deltas=self.change(value,row['operations'],True)
            literal=self.read_json_input(row['literal_candidate_input']);need(same(value,literal),'EXACT_LITERAL_CONTRACT_FULL_TYPED_SUCCESSOR')
            raw=self.input_bytes[row['literal_candidate_input']]
            need(sha(raw)==self.hand['contract']['sha256'],'08_CONTRACT_CANDIDATE_PIN')
            path,expected=self.output(row['file'],raw)
            self.nodes[row['id']]={'path':path,'sha256':expected,'value':value}
            self.proofs[row['id']]={'whole_typed_inverse':True,'source_delta':deltas,'literal_original_bytes':True}
            self.target(row['target'],row['old_sha256'],path,expected);return
        if row['kind']=='finite_manifest':
            domain=row['domain'];need(domain in ['market','yamen'],'EXACT_TWO_FINITE_DOMAINS')
            d=self.binding['domains'][domain]
            need(row['file']==d['runtime_manifest_path'] and not res(row['file']).exists(),'FIXED_NEW_RUNTIME_MANIFEST_ABSENT')
            parent=self.nodes[row['parent_node']];value=copy.deepcopy(parent['value'])
            oldvalue=copy.deepcopy(value);oldartifacts=copy.deepcopy(value['artifacts'])
            # Keep old native parent facts in legacy; new fixed child artifacts
            # are disjoint from every legacy/runtime-authority source class.
            for path,expected in oldartifacts.items():
                if path not in d['manifest_immutable']['artifacts']:
                    if path in value['legacy_source_sha256']:need(value['legacy_source_sha256'][path]==expected,'UNCHANGED_OLD_NATIVE_PARENT_LEAF')
                    value['legacy_source_sha256'][path]=expected
            for path in d['manifest_immutable']['artifacts']:
                value['legacy_source_sha256'].pop(path,None);value['runtime_authority_sha256'].pop(path,None)
            for key,expected in d['manifest_immutable'].items():value[key]=copy.deepcopy(expected)
            value['formal_enabled']=True;value['publication_full_source_finalized']=True;value['finite_source_closure_pending']=False
            for path,expected in self.group('finite08_'+domain+'_sources').items():
                if path in value['artifacts']:
                    need(value['artifacts'][path]==expected,'EXACT_FIXED_NATIVE_CHILD_LEAF');continue
                existing=[field for field in ['legacy_source_sha256','runtime_authority_sha256'] if path in value[field]]
                need(len(existing)<=1,'FINITE_SOURCE_CLASSES_DISJOINT')
                if existing:need(value[existing[0]][path]==expected,'FINITE_DECLARED_SOURCE_EXPECTATION_MATCH')
                else:value['legacy_source_sha256'][path]=expected
            value['legacy_source_sha256'][row['parent_header_path']]=parent['sha256']
            for forbidden in M.EXTERNAL|{row['file']}:
                need(forbidden not in value['legacy_source_sha256'] and forbidden not in value['runtime_authority_sha256'],'FINITE_NO_SELF_OR_EXTERNAL_REVERSE_PIN')
            for key in d['manifest_immutable']:need(same(value[key],d['manifest_immutable'][key]),'FIXED89216_IMMUTABLE_FIELD')
            need(same(value['parent_publication'],oldvalue['parent_publication']),'R3_WHOLE_PARENT_SUBTREE_UNCHANGED')
            union={}
            for field in ['legacy_source_sha256','runtime_authority_sha256','artifacts']:
                need(not(set(union)&set(value[field])),'FINAL_FINITE_SOURCE_MAPS_DISJOINT');union.update(value[field])
            for path,expected in union.items():self.verify_leaf(path,expected)
            raw=encode(value);need(row['file'] not in self.outputs,'NEW_FINITE_OUTPUT_ONLY')
            self.outputs[row['file']]=raw
            self.nodes[row['id']]={'path':row['file'],'sha256':sha(raw),'value':value}
            self.proofs[row['id']]={'fixed_cpu_actual89216':True,'fixed_binding_immutable_fields':list(d['manifest_immutable']),'geometry_replayed':False,'old_native_parent_artifacts_retained':oldartifacts,'parent_source_only_header':{'path':row['parent_header_path'],'sha256':parent['sha256']},'complete_source_count':len(union),'source_class_disjoint':True,'not_canonical_target':True}
            return
        if row['kind']=='finite_index':
            ordinary=copy.deepcopy(row);ordinary['kind']='index';ordinary.pop('target')
            super().build_node(ordinary)
            before=self.nodes[row['id']];raw=self.outputs[before['path']]
            entries={self.binding['domains'][d]['scene_id']:{'manifest_path':self.nodes['finite08_'+d]['path'],'manifest_sha256':self.nodes['finite08_'+d]['sha256']} for d in ['market','yamen']}
            extra=('\nstatic func finite_geometry_enabled() -> bool: return true\nstatic func finite_geometry_entries() -> Dictionary:\n\treturn '+json.dumps(entries,separators=(',',':'))+'\n').encode()
            need(b'finite_geometry_enabled' not in raw and b'finite_geometry_entries' not in raw,'ONLY_NEW_EXACT_TWO_INDEX_METHODS')
            after=raw+extra;path,expected=self.output('indices/ap_finite_index_true.gd',after)
            need(after[:-len(extra)]==raw,'INDEX_APPEND_WHOLE_BYTE_INVERSE')
            before.update(path=path,sha256=expected)
            self.proofs[row['id']]['append_exact_bytes']=extra.decode()
            self.proofs[row['id']]['old_methods_preserved_except_declared_manifest_sha_literal']=True
            self.target(row['target'],row['old_sha256'],path,expected);return
        return super().build_node(row)

    def run(self):
        need(self.spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and self.spec.get('blockers')==[],'ROOT_LOCKED_NO_PENDING_BLOCKERS')
        gates=self.spec.get('required_gates',[])
        need({r['id'] for r in gates}==M.REQUIRED_GATES,'ORIGINAL_FIVE_GATES_PRESERVED')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        for row in self.spec['pass_through_targets']:
            after=self.read(row['candidate_path'],row['candidate_sha256']);before=self.read(row['target'],row['old_sha256'])
            if row['target'] in M.OWNED:
                need(self.authority['owned'][row['target']]['current_sha256']==row['candidate_sha256'],'OWNED_FINAL_EXACT_C668')
            elif row['target']==EXE:
                need(row['old_sha256']==PARENT and row['candidate_sha256']==NEXT and row['candidate_path']==self.inputs[self.spec['authority_input']]['path'],'SOLE_ROOT_APPROVED_EXECUTION_COPY')
            else:
                need(row['target'].endswith('.gd') and row.get('exact_replacements'),'EXACT_NONOWNED_SOURCE_ONLY')
                inv=after.decode()
                for h in row['exact_replacements']:
                    need(h['new'] and inv.count(h['new'])==1,'UNIQUE_NONOWNED_INVERSE_HUNK');inv=inv.replace(h['new'],h['old'],1)
                need(inv.encode()==before,'NONOWNED_COMPLETE_BYTE_INVERSE')
            self.target(row['target'],row['old_sha256'],row['candidate_path'],row['candidate_sha256'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[r for r in self.spec['nodes'] if r['kind']=='map']
        need({r['scene_id'] for r in maps}==set(M.BASELINES),'ALL_FOUR_ORIGINAL_FIXED_AO_BASELINES')
        need(all(self.spec['common_group'] in r['groups'] for r in maps),'FOUR_COMPLETE_COMMON_SOURCE_GROUPS')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist']) and len(self.targets)==28,'EXACT28_COMPLETE_TARGET_SET')
        patch=['*** Begin Patch\n'];reconstruction={};copyrows=[]
        for row in self.targets.values():
            candidate=self.outputs[row['candidate_path']] if row['candidate_path'] in self.outputs else self.read(row['candidate_path'],row['candidate_sha256'])
            before=self.read(row['target'],row['old_sha256'])
            need(sha(candidate)==row['candidate_sha256'] and before!=candidate,'FINAL_CANDIDATE_EXACT_NONNOOP')
            if row['target']==EXE:
                need(sha(before)==PARENT and sha(candidate)==NEXT,'EXACT_EXECUTION_COPY_DOMAIN')
                copyrows.append({**row,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION'})
                reconstruction[row['target']]={'kind':'ExactMechanicalByteCopy','candidate_sha256':NEXT,'candidate_bytes':len(candidate),'original_bytes_preserved':True};continue
            # All08 GD and generated metadata candidates are genuine LF. No
            # Router/HUD/EOL exception or formatting plan is inherited here.
            need(b'\r' not in candidate and candidate.endswith(b'\n'),'STRICT_LF_CANDIDATES_NO_FORMAT_EXCEPTION')
            piece,proof=M._strict_lf_build_file_patch(res(row['target']).as_posix(),before,candidate)
            patch.append(piece);reconstruction[row['target']]=proof
        patch.append('*** End Patch\n')
        need(len(copyrows)==1 and copyrows[0]['target']==EXE and len(reconstruction)==28,'PATCH27_COPY1_EXACT_PARTITION')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode())
        bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT_C668_EXECUTION_COPY_NOT_EXECUTED','rows':copyrows,'patch_targets':sorted(set(self.targets)-{EXE}),'copy_targets':[EXE],'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True}))
        final={p:sha(res(p).read_bytes()) for p in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':1},'target_partition':{'patch_count':27,'copy_count':1,'total':28,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'single_root_atomic_epoch_required':True,'source_baseline':'Original fixed AO maps, explicit inherited typed recipes and bounded89216 domain leaves; no actual collector fill','no_EOL_formatting_or_GD_copy':True}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'NO_OUTPUT_CREATED_DURING_PREFLIGHT')
        for p,b in self.outputs.items():
            dest=res(p);need(not dest.exists(),'NEW_STAGE_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as f:f.write(b)
        return {'output_root':self.out,'targets':28,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}

def main():
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True)
    args=parser.parse_args();p=Path(args.input).resolve();need(p.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN')
    raw=p.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_SHA')
    spec=json.loads(raw);need(spec.get('schema_version')==1,'SCHEMA_VERSION')
    spec['_locked_plan']={'path':'res://'+p.relative_to(M.ROOT).as_posix(),'sha256':args.input_sha256}
    print(json.dumps(FiniteStage(spec).run()))
if __name__=='__main__':main()
