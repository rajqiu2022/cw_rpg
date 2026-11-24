"""Root-only unified100 source compiler BUILD. No self-run or deployment.

The frozen8DE0 core retains all authority, full source, typed inverse, baseline,
native history and media remap guards. Exact new interfaces: six fixed code
successors, one literal contract, and three Artisan paths plus life declaration.
"""
import argparse,copy,hashlib,importlib.util,json
from pathlib import Path
HERE=Path(__file__).resolve().parent
BASE=HERE/'stage_unified06_04_READY.py'
assert hashlib.sha256(BASE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
mod=importlib.util.spec_from_file_location('frozen_unified100_core',BASE)
M=importlib.util.module_from_spec(mod);mod.loader.exec_module(M)
need,sha,same,res,encode=M.need,M.digest,M.same,M.res,M.encode
S=M.PREFIX
O=S+'performance100_unified_life_garden_scholar_BUILD/'
R=S.replace('_source_finalize01/','_root01/')
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
FIELD='res://scripts/field/field_walkable_controller.gd'
QUARTER='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
ARTISAN='luoyang_artisan_residential_20261022ap'
GARDEN='luoyang_riverside_garden_20261022ap'
PARENT='d184d50821f11bf012bd34baac374c4939fdfa5c51f6c415d31e249bbc8a6f29'
PROPOSAL='a971de4023f2f61fd67738f62608354bf9a1a38173aefa5718e233b5d6174395'
class UnifiedLifeStage(M.Stage):
    def __init__(self,spec):
        c=spec['life_contract']
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT'and spec.get('blockers')==[]and c.get('root_input_freeze_pending')is False and isinstance(c.get('Root_preparation_input'),str),'ROOT_NEW_LOCK_REQUIRED_NOTREADY_CANNOT_RUN')
        super().__init__(spec);self.contract=c
        root=self.read_json_input(c['Root_preparation_input'])
        need(same(root,c['expected_Root_preparation_document'])and root.get('approved_by_root')is True,'EXACT_PINNED_ROOT_PREPARATION_DOCUMENT_SCHEMA')
        self.scope=self.read_json_input(c['scope_input']);self.oldtargets={r['target']:r['old_sha256']for r in self.scope['targets']}
        need(self.inputs[c['scope_input']]['sha256']=='a716540f4c5e710bbd21031677926f33f3e885649653a1501d954f804ab4b616'and len(self.oldtargets)==28 and list(self.oldtargets)==spec['root_target_allowlist'],'EXACT_FROZEN28_SCOPE_AND_ORDER')
        need(self.inputs[c['before_input']]['sha256']=='87db79458b0f7d84862d4cfe9229864d5090636dbdbc6addaba68212fae83f0b'and self.inputs[c['backup_input']]['sha256']=='0481ff09ddacea8c78edb97644af365a8560dd69f4e89e00f9d1a63ece43c705','ROOT62_FRESH_AND_FULL_BACKUPS')
        back=self.read_json_input(c['backup_input']);need(back.get('target_count')==28 and len(back['targets'])==28,'ROOT62_REAL_TARGET_COUNT_SCHEMA')
        backed={}
        for row in back['targets']:
            p=row['res_path'];bp=Path(row['backup_path']).resolve()
            need(p not in backed and p in self.oldtargets and res(p).resolve()==Path(row['path']).resolve()and bp.is_relative_to(res(R+'integration62/full28_backups/').resolve()),'EXACT_ROOT62_RES_PATH_AND_BACKUP_DOMAIN')
            bpres='res://'+bp.relative_to(M.ROOT).as_posix();b=self.read(bpres,row['old_sha256'])
            need(b==self.read(p,row['old_sha256'])and len(b)==row['old_bytes'],'ROOT62_FULL_OLD_BYTES_NOT_ALIASED_SHA_SCHEMA');backed[p]=row['old_sha256']
        need(backed==self.oldtargets,'ROOT62_BACKUP_EXACT28_OLD_DOMAIN')
        self.owner=self.read_json_input(c['prior_owner_input']);self.read_json_input(c['prior_stage_input'])
        need(self.inputs[c['prior_owner_input']]['sha256']=='c3b7c23523fd8d913cb21a57e72e3c07340a7d948017b67139e31d6088ba60cb'and self.inputs[c['prior_stage_input']]['sha256']=='a75b11116797d5e4488e519aa2b1c3d1342fa6b71abec157b8cdb6d310745a85','FIXED_OWNER95_AND_ACTUAL94_ONLY')
        need(all(self.owner['core_source_sha256'].get(p)==s for p,s in self.oldtargets.items()),'OLD28_FROM_FIXED_OWNER95_CORE_NOT_CURRENT_FILL')
        self.proof=self.read_json_input(c['inverse_input']);self.codes=self.proof['records']
        need(self.inputs[c['inverse_input']]['sha256']=='057b5b935bd86b04b5b710de0d3224ff4cba23d98f5d4c1377987f7fe0b71cf3'and len(self.codes)==6,'EXACT_SIX_CODE_INVERSES')
        for p,r in self.codes.items():
            before=self.read(r['parent']['path'],r['parent']['sha256']);after=self.read(r['candidate']['path'],r['candidate']['sha256'])
            need(before==self.read(p,self.oldtargets[p])and len(after)==r['candidate']['bytes']and b'\r'not in after and after.endswith(b'\n'),'EXACT_PARENT_AND_STRICT_CANDIDATE_BYTES')
            forward,inverse=before.decode(),after.decode()
            for h in r['hunks']:
                need(forward.count(h['old'])==inverse.count(h['new'])==1,'UNIQUE_FULL_UTF8_HUNK');forward=forward.replace(h['old'],h['new'],1);inverse=inverse.replace(h['new'],h['old'],1)
            need(forward.encode()==after and inverse.encode()==before,'WHOLE_CODE_BYTE_FORWARD_INVERSE')
        self.binding=self.read_json_input(c['binding_input'])
        need(self.inputs[c['binding_input']]['sha256']=='ff97c27d2660bc45bcd7f526dca4c1d7aca9329510de24e1fe767c959a433333'and self.binding.get('ready')is True and self.binding.get('formal_enabled')is True and self.binding.get('blockers')==[],'ROOT_FIXED_LIFE_BINDING_READY')
        promotion=self.read_json_input(c['promotion_input'])
        need(self.inputs[c['promotion_input']]['sha256']=='1a4ddf823a5ec3767d99428ea0866bd8f18bcfd926522149759df8b068cb53b5'and promotion.get('passed')is True and promotion.get('target_count')==5,'ROOT_ACTUAL_FIVE_MEDIA_PROMOTION')
        prior=self.read_json_input(c['parent_execution_input'])
        need(self.inputs[c['parent_execution_input']]['sha256']==PARENT and self.inputs[spec['authority_input']]['sha256']==PROPOSAL and len(prior['owned'])==len(self.authority['owned'])==10 and set(prior['owned'])==set(self.authority['owned']),'UNCHANGED_ACTIVE10_OWNED_DOMAIN')
        restored=copy.deepcopy(self.authority);changed=set(self.proof['changed_owned'])
        need(len(changed)==3 and FIELD in changed and changed<=set(self.codes),'ONLY_THREE_DECLARED_OWNED_EDGES')
        for p,old in prior['owned'].items():
            new=self.authority['owned'][p]
            if p not in changed:need(same(old,new),'OTHER_SEVEN_OWNED_ROWS_UNCHANGED');continue
            r=self.codes[p];e=new['edges'][-1]
            need(len(new['edges'])==len(old['edges'])+1 and same(new['edges'][:-1],old['edges'])and new['current_sha256']==e['new_sha256']==r['candidate']['sha256']and e['old_sha256']==old['current_sha256']==r['parent']['sha256']and e['new_snapshot']==r['candidate']['path']and same(e['replacements'],r['hunks']),'ONE_EXACT_EDGE_HISTORY_AND_HUNKS')
            restored['owned'][p]=copy.deepcopy(old)
        self.extra={p:s for p,s in self.authority['source_sha256'].items()if p not in prior['source_sha256']}
        need(len(prior['source_sha256'])==96 and len(self.authority['source_sha256'])==101 and same(self.extra,c['proof_extra'])and all(self.authority['source_sha256'].get(p)==s for p,s in prior['source_sha256'].items()),'OLD96_PLUS_EXACT_FIVE_PROOF_LEAVES')
        restored['source_sha256']=copy.deepcopy(prior['source_sha256']);need(same(restored,prior)and encode(restored)==self.input_bytes[c['parent_execution_input']],'WHOLE_EXECUTION_TYPED_UTF8_INVERSE_D184')
        need(same(c['life_sources'],self.groups['life_native_material_sources']['leaves'])and same(c['garden_sources'],self.groups['garden_mask_shader_source']['leaves'])and same(c['scholar_sources'],self.groups['Market_scholar_media_sources']['leaves']),'EXACT_DECLARED_NEW_ORDINARY_SOURCE_DOMAINS')
        expected=copy.deepcopy(self.binding['source_sha256']);expected.update(self.binding['mask_import_source_sha256']);expected[self.inputs[c['binding_input']]['path']]=self.inputs[c['binding_input']]['sha256'];expected[S+'life_production100_READY/material_runtime_life_READY.gd']='7bd26f666035fc45a2f3161cc8df323da5ef6756f758ba16a6ffc1814ee5836a'
        need(same(expected,c['life_sources']),'LIFE_LEAVES_DERIVED_FROM_FIXED_BINDING_ONLY')
    def target(self,target,old,path,expected):
        need(target in self.oldtargets and old==self.oldtargets[target]and old!=expected,'EXACT28_CHANGED_TARGET_ONLY_NO_NOOP')
        return super().target(target,old,path,expected)
    def build_node(self,row):
        ident=row['id'];kind=row['kind'];c=self.contract
        if kind=='life_execution':
            need(ident=='execution_final','SINGLE_EXECUTION_NODE');raw=self.input_bytes[row['base_input']]
            self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':self.authority};self.proofs[ident]={'whole_typed_inverse':True,'old96_plus5':True};return
        if kind in ['life_frozen','life_fixed_code']:
            allowed=c['frozen_nodes']if kind=='life_frozen'else{'ENV_code':self.codes['res://scripts/city/luoyang_environment_layer_20261022ap.gd']['candidate']['sha256']}
            need(ident in allowed and allowed[ident]==row['immutable_sha256']==self.inputs[row['base_input']]['sha256']and'target'not in row,'EXACT_FROZEN_NODE_OR_APPROVED_CODE')
            raw=self.input_bytes[row['base_input']];self.nodes[ident]={'path':self.inputs[row['base_input']]['path'],'sha256':sha(raw),'value':json.loads(raw)if row.get('is_json')else None};self.proofs[ident]={'frozen_original_bytes':True,'not_target':True};return
        if kind=='life_contract':
            need(row['target']==CONTRACT and row['old_sha256']=='d258350b1b72377fb4189918178a1323de9506934d015859a4d5823271961b9b'and len(row['operations'])==1 and row['operations'][0]['pointer']==['source_sha256',FIELD],'ONLY_EXACT_D258_FIELD_LITERAL_SUCCESSOR')
            value=copy.deepcopy(self.read_json_input(row['base_input']));deltas=self.change(value,row['operations'],True)
            literal=self.read_json_input(row['literal_candidate_input']);raw=self.input_bytes[row['literal_candidate_input']]
            need(same(value,literal)and sha(raw)=='239ff4b09862a4a3066462a434b00a7bdba45e830d0eb1d93ff3a2d826914700','EXACT_FULL_TYPED_LITERAL_CONTRACT_NO_NORMALIZATION')
            old=self.input_bytes[row['base_input']];need(old.count(self.oldtargets[FIELD].encode())==1 and old.replace(self.oldtargets[FIELD].encode(),self.codes[FIELD]['candidate']['sha256'].encode(),1)==raw,'WHOLE_BYTE_CONTRACT_SINGLE_LITERAL_INVERSE')
            p,s=self.output(row['file'],raw);self.nodes[ident]={'path':p,'sha256':s,'value':value};self.proofs[ident]={'whole_typed_inverse':True,'source_delta':deltas,'literal_original_bytes':True};self.target(CONTRACT,row['old_sha256'],p,s);return
        if kind=='life_quarter':
            need(row['target']==QUARTER,'ONLY_FIXED_QUARTER_DECLARATION_INTERFACE')
            original=self.read_json_input(row['base_input']);ordinary=copy.deepcopy(row);ordinary['kind']='metadata';ordinary.pop('target');ops=ordinary.pop('life_declaration_operations');ordinary.setdefault('forbidden_source_paths',[]).append(QUARTER)
            super().build_node(ordinary);node=self.nodes[ident];source_only=copy.deepcopy(node['value']);expected=[]
            for field,suffix in [('scene_path','scene.res'),('layout_path','layout.res'),('packet_path','packet.bin')]:expected.append({'op':'set','pointer':['scenes',ARTISAN,field],'existed':True,'old':original['scenes'][ARTISAN][field],'new':self.binding['child'][suffix]['path']})
            expected.append({'op':'set','pointer':['artisan_life_successor'],'existed':False,'old':None,'new':{'binding_path':self.inputs[c['binding_input']]['path'],'binding_sha256':self.inputs[c['binding_input']]['sha256']}})
            need(same(ops,expected),'ONLY_ARTISAN_THREE_PATHS_AND_ONE_LIFE_DECLARATION')
            delta=self.change(node['value'],ops,False)
            need(same(node['value']['scenes'][GARDEN],original['scenes'][GARDEN])and same(node['value']['a2_artisan_successor'],original['a2_artisan_successor']),'GARDEN_ROW_AND_OLD_A2_DECLARATION_UNCHANGED')
            for p,s in c['life_sources'].items():need(node['value']['source_sha256'].get(p)==s,'LIFE_WHOLE_FIXED_HEADER_SOURCE_DECLARATION')
            back=copy.deepcopy(node['value'])
            for d in reversed(delta):
                holder,key=M.pointer(back,d['pointer'][:-1]),d['pointer'][-1]
                if d['existed']:holder[key]=d['old']
                else:del holder[key]
            need(same(back,source_only),'LIFE_DECLARATION_WHOLE_TYPED_INVERSE')
            raw=encode(node['value']);self.outputs[node['path']]=raw;node['sha256']=sha(raw);self.proofs[ident].update(exact_life_declaration_delta=delta,whole_typed_inverse=True,Garden_and_A2_preserved=True)
            self.target(QUARTER,row['old_sha256'],node['path'],node['sha256']);return
        super().build_node(row)
        if kind=='map':
            expected=copy.deepcopy(next(r for r in self.owner['scenes']if r['id']==row['scene_id'])['source_sha256'])
            for p,t in self.targets.items():
                if p in expected:need(expected[p]==t['old_sha256'],'FIXED_OWNER95_OLD_MAP_VALUE');expected[p]=t['candidate_sha256']
            expected.update(self.extra)
            if row['scene_id']=='ch4_s3_luoyang_market':
                expected.update(c['life_sources']);expected.update(c['garden_sources']);expected.update(c['scholar_sources'])
            need(same(expected,self.nodes[ident]['value']['source_sha256']),'FOUR_FULL_MAPS_EXACT_FIXED_OWNER95_PLUS_DECLARED_DELTA')
    def run(self):
        gates=self.spec['required_gates'];need({r['id']for r in gates}==M.REQUIRED_GATES,'FIVE_ORIGINAL_NATIVE_PERMISSION_GATES')
        for gate in gates:need(same(M.pointer(self.read_json_input(gate['input']),gate['pointer']),gate['equals']),'REQUIRED_GATE:'+gate['id'])
        exact={p:{'path':r['candidate']['path'],'sha256':r['candidate']['sha256']}for p,r in self.codes.items()};exact[EXE]={'path':self.inputs[self.spec['authority_input']]['path'],'sha256':PROPOSAL}
        need(len(exact)==len(self.spec['pass_through_targets'])==7,'ONLY_SIX_CODE_AND_EXECUTION_PASSTHROUGH')
        for r in self.spec['pass_through_targets']:
            need(r['target']in exact and exact[r['target']]=={'path':r['candidate_path'],'sha256':r['candidate_sha256']}and r['old_sha256']==self.oldtargets[r['target']],'EXACT_APPROVED_CANDIDATE_IDENTITY')
            self.read(r['target'],r['old_sha256']);self.read(r['candidate_path'],r['candidate_sha256']);self.target(r['target'],r['old_sha256'],r['candidate_path'],r['candidate_sha256'])
        for row in self.spec['nodes']:self.build_node(row)
        maps=[r for r in self.spec['nodes']if r['kind']=='map']
        need({r['scene_id']for r in maps}==set(M.BASELINES)and all(self.spec['common_group']in r['groups']for r in maps),'FOUR_ORIGINAL_AO_BASELINES_FULL_COMMON_SOURCES')
        need(set(self.targets)==set(self.oldtargets)==set(self.spec['root_target_allowlist'])and len(self.targets)==28,'EXACT28_CHANGED_NO_EXTRA_TARGETS')
        patch=['*** Begin Patch\n'];reconstruction={};copies=[]
        for r in self.targets.values():
            p=r['candidate_path'];candidate=self.outputs[p]if p in self.outputs else self.read(p,r['candidate_sha256']);before=self.read(r['target'],r['old_sha256'])
            need(sha(candidate)==r['candidate_sha256']and candidate!=before,'FINAL_EXACT_CHANGED_CANDIDATE_BYTES')
            if r['target'].endswith('.json'):
                matches=[k for k,n in self.nodes.items()if n['path']==p and n['sha256']==r['candidate_sha256']]
                need(len(matches)==1 and self.proofs[matches[0]].get('whole_typed_inverse')is True,'ONLY_FULL_INVERSE_GENERATED_JSON_COPY')
                copies.append({**r,'candidate_bytes':len(candidate),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION','inverse_proof':matches[0]});reconstruction[r['target']]={'kind':'ExactMechanicalByteCopy','candidate_sha256':sha(candidate),'candidate_bytes':len(candidate),'whole_inverse_proof':matches[0]};continue
            need(r['target'].endswith('.gd'),'GD_ONLY_PATCH_PARTITION');piece,proof=M._strict_lf_build_file_patch(res(r['target']).as_posix(),before,candidate);patch.append(piece);reconstruction[r['target']]=proof
        patch.append('*** End Patch\n');need(len(copies)==14 and len(reconstruction)==28 and len([p for p in self.targets if p.endswith('.gd')])==14,'PATCH14_COPY14_EXACT_DISJOINT28')
        pp,ps=self.output('canonical_deployment.apply_patch',''.join(patch).encode());bp,bs=self.output('canonical_byte_copy_plan.json',encode({'status':'ROOT_ONLY_EXACT14_GENERATED_JSON_COPY_NOT_EXECUTED','rows':copies,'patch_targets':sorted(p for p in self.targets if p.endswith('.gd')),'copy_targets':sorted(r['target']for r in copies),'patch_copy_disjoint':True,'patch_copy_union_exact_targets':True,'no_GD_copy_or_native_write':True}))
        final={p:sha(res(p).read_bytes())for p in self.first};need(final==self.first,'ALL_PINNED_SOURCE_FIRST_FINAL_SAME')
        receipt={'status':'AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED','targets':list(self.targets.values()),'nodes':self.nodes,'proofs':self.proofs,'source_first':self.first,'source_final':final,'patch_path':pp,'patch_sha256':ps,'patch_reconstruction':reconstruction,'byte_copy_plan':{'path':bp,'sha256':bs,'target_count':14},'target_partition':{'patch_count':14,'copy_count':14,'total':28,'intersection_empty':True,'union_exact_targets':True},'no_engine_import_collector_or_canonical_write':True,'source_baseline':self.spec['source_baseline'],'runtime_inverse_replayed':False,'single_root_atomic_epoch_required':True}
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'ALL_BUFFERED_UNTIL_FULL_PREFLIGHT_PASSED')
        for p,b in self.outputs.items():
            dest=res(p);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb')as f:f.write(b)
        return {'output_root':self.out,'targets':28,'map_nodes':4,'receipt_sha256':sha(self.outputs[self.out+'receipt.json'])}
def main():
    p=argparse.ArgumentParser();p.add_argument('input');p.add_argument('--input-sha256',required=True);a=p.parse_args();path=Path(a.input).resolve();need(path.is_relative_to(M.ROOT),'INPUT_GAME_DOMAIN');raw=path.read_bytes();need(M.valid_sha(a.input_sha256)and sha(raw)==a.input_sha256,'ROOT_EXTERNAL_INPUT_PIN');spec=json.loads(raw);spec['_locked_plan']={'path':'res://'+path.relative_to(M.ROOT).as_posix(),'sha256':a.input_sha256};print(json.dumps(UnifiedLifeStage(spec).run()))
if __name__=='__main__':main()
