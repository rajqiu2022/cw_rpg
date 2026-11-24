"""Root-only exact31 Docks SOURCE_ONLY compiler; frozen8DE0 gates remain unchanged."""
import argparse,copy,hashlib,importlib.util,json
from pathlib import Path
GAME=Path(__file__).resolve().parents[2]
PREFIX='res://build/luoyang_city_revision_20261024e_source01/'
CORE=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/stage_unified06_04_READY.py'
assert hashlib.sha256(CORE.read_bytes()).hexdigest()=='8de0b1dc9c5f24511947221760c9efb1e48a59fff152c426800b790ec7c26b28'
sp=importlib.util.spec_from_file_location('fixed_docks31_core',CORE);M=importlib.util.module_from_spec(sp);sp.loader.exec_module(M);M.PREFIX=PREFIX
need,same,sha,encode,res=M.need,M.same,M.digest,M.encode,M.res
EXEC='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
ESTATE='res://data/maps/luoyang_estate_courtyard_20261021am/manifest.json'
REGISTRY='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
HELPER='res://build/luoyang_loading_20261024e_perf01/candidate04/gate_source_prewarm04.gd'
HELPER_SHA='d81ecdbb6e333886f50ad19aea8612791d64eee47300088521a9a7dac4b31778'
C='res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd';FIELD='res://scripts/field/field_walkable_controller.gd'

class DocksFrontageStage(M.Stage):
    def __init__(self,spec):
        c=spec['docks_contract']
        need(spec.get('status')=='ROOT_LOCKED_AP_SOURCE_FINALIZATION_INPUT' and not spec.get('blockers') and c.get('root_input_freeze_pending') is False,'ROOT31_EXACT_LOCK_REQUIRED')
        super().__init__(spec);self.contract=c
        generator=spec['required_generator']
        need(generator['path']=='res://'+Path(__file__).resolve().relative_to(M.ROOT).as_posix() and sha(Path(__file__).read_bytes())==generator['sha256'],'EXACT_LOCKED_DRIVER_IDENTITY')
        self.read(generator['path'],generator['sha256'])
        scope=self.read_json_input(c['scope_input']);self.oldtargets={r['target']:r['old_sha256'] for r in scope['targets']}
        need(len(self.oldtargets)==31 and list(self.oldtargets)==spec['root_target_allowlist'] and sum(p.endswith('.gd') for p in self.oldtargets)==16,'EXACT31_16GD15JSON_DOMAIN')
        backup=self.read_json_input(c['Root_backup_input'])
        need(backup['status']=='EXACT31_CURRENT_FE154_PARENT_BACKED_UP_NO_CANONICAL_WRITES' and backup['count']==len(backup['targets'])==31 and backup['scope_sha256'].lower()==self.inputs[c['scope_input']]['sha256'].lower(),'ROOT_745E_ACTUAL_SCHEMA')
        backed={}
        for r in backup['targets']:
            p,h,bp=r['target'],r['sha256'].lower(),Path(r['backup']).resolve()
            need(p in self.oldtargets and p not in backed and h==self.oldtargets[p] and bp.is_relative_to(res(c['Root_backup_prefix']).resolve()),'EXACT31_BACKUP_TARGET_AND_PREFIX')
            raw=self.read('res://'+bp.relative_to(M.ROOT).as_posix(),h)
            need(raw==self.read(p,h) and len(raw)==r['bytes'],'EXACT31_FULL_OLD_BYTES');backed[p]=h
        need(backed==self.oldtargets,'EXACT31_FULL_BACKUP_COVERAGE')
        need(same(self.read_json_input(c['Root_preparation_input']),c['expected_Root_preparation_document']),'EXACT_ROOT_PREPARATION_DOCUMENT')
        self.proof=self.read_json_input(c['code_inverse_input']);self.codes=self.proof['records']
        need(len(self.codes)==8,'EXACT8_APPROVED_FUNCTIONAL_AND_LITERAL_SUCCESSORS')
        for p,r in self.codes.items():
            before=self.read(r['parent']['path'],r['parent']['sha256']);after=self.read(r['candidate']['path'],r['candidate']['sha256'])
            need(before==self.read(p,self.oldtargets[p]) and len(after)==r['candidate']['bytes'],'EXACT_CODE_SNAPSHOT_LENGTH')
            f,v=before.decode('utf8'),after.decode('utf8')
            for h in r['hunks']:need(f.count(h['old'])==1,'UNIQUE_FORWARD_HUNK');f=f.replace(h['old'],h['new'],1)
            for h in reversed(r['hunks']):need(v.count(h['new'])==1,'UNIQUE_INVERSE_HUNK');v=v.replace(h['new'],h['old'],1)
            need(f.encode()==after and v.encode()==before,'CODE_WHOLE_BYTE_FORWARD_INVERSE')
        prior=self.read_json_input(c['parent_execution_input']);changed=set(self.proof['execution']['changed_existing_owned']);restored=copy.deepcopy(self.authority)
        need(len(changed)==6 and len(prior['owned'])==len(self.authority['owned'])==10 and set(prior['owned'])==set(self.authority['owned']),'ONLY6_EXISTING_OWNED_MEMBERS_CHANGE')
        for p,old in prior['owned'].items():
            new=self.authority['owned'][p]
            if p not in changed:need(same(old,new),'OTHER4_OWNED_ROWS_WHOLE_TYPED_SAME');continue
            r=self.codes[p];edge=new['edges'][-1]
            need(len(new['edges'])==len(old['edges'])+1 and same(new['edges'][:-1],old['edges']) and edge['old_sha256']==old['current_sha256']==r['parent']['sha256'] and edge['new_sha256']==new['current_sha256']==r['candidate']['sha256'] and edge['new_snapshot']==r['candidate']['path'] and same(edge['replacements'],r['hunks']),'EXACT_SINGLE_APPENDED_EDGE_NO_SHORTCUT')
            restored['owned'][p]=copy.deepcopy(old)
        extra={p:h for p,h in self.authority['source_sha256'].items() if p not in prior['source_sha256']}
        need(len(prior['source_sha256'])==154 and len(self.authority['source_sha256'])==162 and len(extra)==8 and same(extra,self.proof['execution']['extra']) and all(self.authority['source_sha256'].get(p)==h for p,h in prior['source_sha256'].items()),'OLD154_EXACT8_NEW_PROOF_LEAVES')
        restored['source_sha256']=copy.deepcopy(prior['source_sha256'])
        need(same(restored,prior) and encode(restored)==self.input_bytes[c['parent_execution_input']],'WHOLE_EXECUTION_TYPED_UTF8_INVERSE')
        self.parent_maps={ident:self.read_json_input(pin)['source_sha256'] for ident,pin in c['parent_map_inputs'].items()}
        need(len(self.parent_maps)==4 and len(self.parent_maps['expected_ch4_s3_luoyang_market_true'])==1862,'FIXED_FE154_FOUR_PARENT_MAPS')
        self.read(HELPER,HELPER_SHA)

    def target(self,target,old,candidate,expected):
        need(target in self.oldtargets and old==self.oldtargets[target] and old!=expected,'NO_UNPLANNED_OR_NOOP_TARGET')
        return super().target(target,old,candidate,expected)

    def verify_leaf(self,path,expected):
        if path in self.outputs:
            allowed={self.out+r['file'] for r in self.spec['nodes'] if r['id'] in ['finite08_market','finite08_yamen']}
            need(path in allowed and sha(self.outputs[path])==expected,'ONLY_TWO_BUFFERED_FINITE_HEADERS');return
        return super().verify_leaf(path,expected)

    def leaf_bytes(self,path,expected):
        if path in self.outputs:self.verify_leaf(path,expected);return self.outputs[path]
        return super().leaf_bytes(path,expected)

    def build_node(self,row):
        ident,kind=row['id'],row['kind']
        if kind in ['space_execution','space_frozen','space_code']:
            raw=self.input_bytes[row['base_input']]
            if kind=='space_execution':need(ident=='execution_final' and sha(raw)==self.inputs[self.spec['authority_input']]['sha256'],'EXACT_EXECUTION_NODE');value=self.authority
            else:need(sha(raw)==row['immutable_sha256'],'EXACT_FROZEN_NODE');value=json.loads(raw) if row.get('is_json') else None
            self.nodes[ident]=dict(path=self.inputs[row['base_input']]['path'],sha256=sha(raw),value=value);self.proofs[ident]=dict(whole_typed_inverse=kind=='space_execution',exact_candidate_or_frozen=True);return
        if kind=='space_contract':
            need(row['target']==CONTRACT and self.inputs[row['base_input']]['sha256']==self.oldtargets[CONTRACT],'ONLY_CURRENT_CULTURE_CONTRACT')
            original=self.read_json_input(row['base_input']);value=copy.deepcopy(original);delta=self.change(value,row['operations'],True)
            need(len(delta)==2 and {tuple(d['pointer']) for d in delta}=={('source_sha256',C),('source_sha256',FIELD)} and same(value,self.read_json_input(row['literal_candidate_input'])),'EXACT_C_FIELD_TWO_LITERAL_TYPED_INVERSE')
            p,h=self.output(row['file'],self.input_bytes[row['literal_candidate_input']]);self.nodes[ident]=dict(path=p,sha256=h,value=value);self.proofs[ident]=dict(whole_typed_inverse=True,source_delta=delta,exact_original_literal_bytes=True);self.target(CONTRACT,row['old_sha256'],p,h);return
        if kind=='docks_incremental_map':
            need(ident not in self.nodes and row['scene_id'] in M.BASELINES,'INCREMENTAL_FOUR_FIXED_SCENES_ONLY')
            scene=row['scene_id'];baseline_sha,baseline_count=M.BASELINES[scene]
            ancestor_pin=self.inputs[row['ancestor_base_input']]
            need(ancestor_pin['path']==M.BASE_ROOT+scene+'_true.json' and ancestor_pin['sha256']==baseline_sha,'ORIGINAL_AO_BASELINE_LITERAL_UNCHANGED')
            ancestor=self.read_json_input(row['ancestor_base_input'])['source_sha256']
            need(len(ancestor)==baseline_count,'ORIGINAL_AO_BASELINE_COUNT_UNCHANGED')
            parent=self.read_json_input(row['base_input'])
            need(row['base_input']==self.contract['parent_map_inputs'][ident] and parent['scene_id']==scene and parent['baseline_path']==ancestor_pin['path'] and parent['baseline_sha256']==baseline_sha and same(parent['source_sha256'],self.parent_maps[ident]),'FIXED_FE154_PARENT_MAP_IDENTITY')
            old=parent['source_sha256'];value={'source_sha256':self.promote_owned(old)}
            need(all(len(op['pointer'])==2 and op['pointer'][0]=='source_sha256' and op['op']=='set' and op['existed'] is True and op['pointer'][1] in self.oldtargets for op in row['operations']),'INCREMENTAL_ONLY_EXISTING_31_TARGET_VALUES')
            deltas=self.change(value,row['operations'])
            for group in row['groups']:self.merge(value['source_sha256'],self.group(group))
            # This independent mathematical model is equality evidence only.
            # It does NOT authorize or replace approved() for historical hashes.
            declared={'source_sha256':copy.deepcopy(ancestor)}
            for path in declared['source_sha256']:
                if path in self.authority['owned']:declared['source_sha256'][path]=self.authority['owned'][path]['current_sha256']
            self.change(declared,row['ancestor_operations'])
            for group in row['groups']:self.merge(declared['source_sha256'],self.group(group))
            need(same(declared,value),'WHOLE_TYPED_EQUAL_ORIGINAL_DECLARED_AO_MODEL')
            expected=copy.deepcopy(old)
            for path,target in self.targets.items():
                if path in expected:
                    need(expected[path]==target['old_sha256'],'FE154_EXACT_OLD_TARGET_MAP_VALUE');expected[path]=target['candidate_sha256']
            for group in row['declared_new_groups']:self.merge(expected,self.group(group))
            need(same(expected,value['source_sha256']) and set(old)<=set(expected),'FE154_PLUS_ONLY_APPROVED_31_DELTAS_AND_DECLARED_ADDITIONS')
            added=set(expected)-set(ancestor)
            if scene!='ch4_s3_luoyang_market':need(not any(p.startswith('res://data/maps/luoyang_full_city_20261022ap/quarters/') for p in added),'ONLY_MARKET_ACQUIRES_NEW_QUARTER_NATIVE_CLOSURE')
            if scene=='ch4_s0_luoyang_gate':need(not any('/rooms/' in p or '/luoyang_layout_rooms_' in p for p in added),'GATE_MUST_NOT_ACQUIRE_ROOM253')
            removed=set(ancestor)-set(expected);retired={r['path']:r for r in row.get('retired_runtime_authorities',[])}
            need(removed==set(retired),'NO_UNDECLARED_OLD_MAP_SOURCE_REMOVAL')
            for path in removed:need(path.endswith('/manifest.json') and retired[path]['old_sha256']==ancestor[path] and retired[path]['replacement'] in expected,'ONLY_EXPLICIT_REPLACED_RUNTIME_AUTHORITY')
            for path,h in expected.items():self.verify_leaf(path,h)
            output=dict(status='AP_INDEPENDENT_EXPECTED_NOT_ACTUAL_COLLECTOR',baseline_path=ancestor_pin['path'],baseline_sha256=baseline_sha,scene_id=scene,source_sha256=expected)
            media=self.media_closure(expected,row.get('runtime_media_roots',[]));p,h=self.output(row['file'],encode(output))
            self.nodes[ident]=dict(path=p,sha256=h,value=output)
            self.proofs[ident]=dict(baseline_count=baseline_count,parent_FE154_input=row['base_input'],parent_count=len(old),count=len(expected),explicit_delta=deltas,retired_runtime_authorities=list(removed),runtime_media_closure=media,no_collector_or_current_disk_derivation=True,original_declared_AO_model_whole_typed_equal=True,mathematical_model_not_historical_permission=True,approved_unchanged_on_fixed_current_parent_owned_values=True)
            return
        super().build_node(row)
        if ident=='registry_final':
            dt='res://scripts/city/luoyang_district_life_20261016f.gd'
            ops=row['operations'];base=self.read_json_input(row['base_input'])
            need(len(ops)==5 and len({tuple(op['pointer']) for op in ops})==5 and all(op['op']=='set' and op['existed'] is True and len(op['pointer'])==4 and op['pointer'][0]=='rooms' and op['pointer'][2:]==['source_sha256',dt] and op['old']==self.oldtargets[dt] and self.value(op['new'])==self.codes[dt]['candidate']['sha256'] for op in ops),'REGISTRY_EXACT_FIVE_EXISTING_DT_VALUES_ONLY')
            need(len(base['rooms'])==len(self.nodes[ident]['value']['rooms'])==12,'REGISTRY_TWELVE_ROWS_UNCHANGED')
        if ident=='estate_final':
            base=self.read_json_input(row['base_input']);value=self.nodes[ident]['value']
            need(row['kind']=='metadata' and row['source_policy']=='estate_legacy' and row['protected_pointers']==[['registry_path'],['geometry_receipt'],['publication_receipt']],'ESTATE_ONLY_FIXED_REGISTRY_SHA_NOT_PROTECTED')
            need(set(value['source_sha256'])==set(base['source_sha256']) and value['registry_path']==REGISTRY and value['registry_sha256']==value['source_sha256'][REGISTRY]==self.nodes['registry_final']['sha256'],'ESTATE_FIXED_KEYS_AND_THREE_EQUAL_NEW_REGISTRY')
        if kind=='map':
            expected=copy.deepcopy(self.parent_maps[ident])
            for p,r in self.targets.items():
                if p in expected:need(expected[p]==r['old_sha256'],'FIXED_FE154_MAP_OLD_VALUE');expected[p]=r['candidate_sha256']
            for group in row['declared_new_groups']:self.merge(expected,self.group(group))
            need(same(expected,self.nodes[ident]['value']['source_sha256']),'INDEPENDENT_FE154_PLUS_EXACT_DECLARED_DELTAS')

    def run(self):
        need({r['id'] for r in self.spec['required_gates']}==M.REQUIRED_GATES,'ALL_FIVE_ORIGINAL_NATIVE_PERMISSION_GATES')
        for r in self.spec['required_gates']:need(same(M.pointer(self.read_json_input(r['input']),r['pointer']),r['equals']),'REQUIRED_GATE:'+r['id'])
        expected={p:{k:r['candidate'][k] for k in ['path','sha256']} for p,r in self.codes.items()};expected[EXEC]={k:self.inputs[self.spec['authority_input']][k] for k in ['path','sha256']}
        need(len(expected)==len(self.spec['pass_through_targets'])==9,'EXACT8_CODE_PLUS_EXEC_PASSTHROUGH')
        for r in self.spec['pass_through_targets']:
            need(expected.get(r['target'])==dict(path=r['candidate_path'],sha256=r['candidate_sha256']),'EXACT_APPROVED_CANDIDATE_IDENTITY');self.read(r['candidate_path'],r['candidate_sha256']);self.target(r['target'],r['old_sha256'],r['candidate_path'],r['candidate_sha256'])
        for r in self.spec['nodes']:self.build_node(r)
        maps=[r for r in self.spec['nodes'] if r['kind']=='docks_incremental_map']
        need({r['scene_id'] for r in maps}==set(M.BASELINES) and all(self.spec['common_group'] in r['groups'] for r in maps),'FOUR_ORIGINAL_AO_MAP_BASELINES')
        need(set(self.targets)==set(self.oldtargets) and len(self.targets)==31,'EXACT31_TARGET_SET')
        patch,reconstruction,copies=['*** Begin Patch\n'],{},[]
        for r in self.targets.values():
            p=r['candidate_path'];after=self.outputs[p] if p in self.outputs else self.read(p,r['candidate_sha256']);before=self.read(r['target'],r['old_sha256']);need(sha(after)==r['candidate_sha256'] and before!=after,'CHANGED_EXACT_CANDIDATE')
            if r['target'].endswith('.json'):
                match=[k for k,n in self.nodes.items() if n['path']==p and n['sha256']==r['candidate_sha256']];need(len(match)==1 and self.proofs[match[0]].get('whole_typed_inverse') is True,'FULL_TYPED_JSON_INVERSE_BEFORE_COPY')
                copies.append({**r,'candidate_bytes':len(after),'mechanism':'EXACT_MECHANICAL_BYTE_COPY_NO_NORMALIZATION','inverse_proof':match[0]});reconstruction[r['target']]=dict(kind='ExactMechanicalByteCopy',candidate_sha256=sha(after),candidate_bytes=len(after),whole_inverse_proof=match[0])
            else:
                part,proof=M._strict_lf_build_file_patch(res(r['target']).as_posix(),before,after);patch.append(part);reconstruction[r['target']]=proof
        patch.append('*** End Patch\n');need(len(copies)==15 and len(reconstruction)==31,'STRICT16_GD_PATCH_EXACT15_JSON_COPY')
        pp,ph=self.output('canonical_deployment.apply_patch',''.join(patch).encode());cp,ch=self.output('canonical_byte_copy_plan.json',encode(dict(rows=copies,patch_copy_disjoint=True,union_exact_targets=True,no_GD_copy_or_native_write=True)))
        final={p:sha(res(p).read_bytes()) for p in self.first};need(final==self.first,'ALL_SOURCE_FIRST_FINAL_SAME')
        receipt=dict(status='DOCKS_FRONTAGES_EXACT31_STAGED_NOT_DEPLOYED',targets=list(self.targets.values()),nodes=self.nodes,proofs=self.proofs,source_first=self.first,source_final=final,patch_path=pp,patch_sha256=ph,patch_reconstruction=reconstruction,byte_copy_plan=dict(path=cp,sha256=ch,target_count=15),target_partition=dict(patch_count=16,copy_count=15,total=31),no_engine_import_collector_or_canonical_write=True,source_baseline=self.spec['source_baseline'])
        self.output('receipt.json',encode(receipt));need(not res(self.out).exists(),'NO_OUTPUT_BEFORE_COMPLETE_PREFLIGHT')
        for p,b in self.outputs.items():
            dest=res(p);need(not dest.exists(),'NEW_OUTPUT_ONLY');dest.parent.mkdir(parents=True,exist_ok=True)
            with dest.open('xb') as stream:stream.write(b)
        return dict(output_root=self.out,targets=31,map_nodes=4,receipt_sha256=sha(self.outputs[self.out+'receipt.json']))

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('input');parser.add_argument('--input-sha256',required=True);args=parser.parse_args()
    path=Path(args.input).resolve();need(path.is_relative_to(M.ROOT),'EXACT_GAME_INPUT_DOMAIN');raw=path.read_bytes();need(M.valid_sha(args.input_sha256) and sha(raw)==args.input_sha256,'ROOT_EXTERNAL_INPUT_LOCK');spec=json.loads(raw);spec['_locked_plan']=dict(path='res://'+path.relative_to(M.ROOT).as_posix(),sha256=args.input_sha256);print(json.dumps(DocksFrontageStage(spec).run()))
