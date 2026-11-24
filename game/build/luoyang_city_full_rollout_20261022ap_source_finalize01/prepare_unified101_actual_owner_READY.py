"""Root-only future actual100 output review and fixed-owner95 derivation.

NOT RUN. Only the actual receipt SHA/readiness/output headers await Root freeze.
No Stage import, collector, native/packet/image decoder, canonical crawl or
media/source payload rehash. Only exact generated candidates and old backups.
"""
import argparse,copy,hashlib,importlib.util,json,re
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
R=S.replace('_source_finalize01/','_root01/')
HELPER=H/'prepare_performance95_Docks_ordinary_actual_owner_NOTRUN.py'
assert hashlib.sha256(HELPER.read_bytes()).hexdigest()=='9f0b98381451b9767e8d252d2eb0245103e0a7278921c7ade0836985ec304f12'
module=importlib.util.spec_from_file_location('fixed95_pure_text_utilities',HELPER)
U=importlib.util.module_from_spec(module);module.loader.exec_module(U)
raw,read,sha,same,ptr,encode,merge,replay,literal_patch_sections=(getattr(U,k)for k in ['raw','read','sha','same','ptr','encode','merge','replay','literal_patch_sections'])
PRIOR=S+'performance95_Docks_ordinary21_actual_independent_review/owner_source_maps_READY.json'
PRIOR_SHA='c3b7c23523fd8d913cb21a57e72e3c07340a7d948017b67139e31d6088ba60cb'
PLAN=R+'integration62/source_input100_READY.json'
PLAN_SHA='f432b6fc25a06e8be2b510b9ef2523972aaf6da2ef5e824b987a3aa8ca257fcc'
RECEIPT=S+'outputs/root_unified_life_garden_scholar28_stage01/receipt.json'
ACTUAL_SHA='4ce21902185a78f6c441f8ee8d63d30b30a7c31c61f135b5df13322bc266d945'
READY=True
OUT=S+'unified101_actual_owner_READY/'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
CONTRACT='res://data/luoyang_culture_integration_20261019x/runtime_contract.json'
QUARTER='res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json'
ARTISAN='luoyang_artisan_residential_20261022ap'
GARDEN='luoyang_riverside_garden_20261022ap'
MARKET='ch4_s3_luoyang_market'
ESTATE='luoyang_estate_riverside_20261021ai'
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--receipt',default=RECEIPT);parser.add_argument('--sha256',required=True);args=parser.parse_args()
    assert READY is True and re.fullmatch('[0-9a-f]{64}',ACTUAL_SHA)and args.sha256==ACTUAL_SHA and args.receipt==RECEIPT and not(G/OUT[6:]).exists(),'ROOT_NEW_ACTUAL_HEADER_FREEZE_REQUIRED'
    actual=read(RECEIPT,ACTUAL_SHA);plan=read(PLAN,PLAN_SHA);old=read(PRIOR,PRIOR_SHA);inputs={r['id']:r for r in plan['pinned_inputs']};c=plan['life_contract']
    assert actual['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED'and actual['source_first']==actual['source_final']and actual['source_first'][PLAN]==PLAN_SHA
    assert actual['target_partition']=={'patch_count':14,'copy_count':14,'total':28,'intersection_empty':True,'union_exact_targets':True}
    def inputdoc(ident):return read(inputs[ident]['path'],inputs[ident]['sha256'])
    scope=inputdoc(c['scope_input']);back=inputdoc(c['backup_input']);proof=inputdoc(c['inverse_input']);binding=inputdoc(c['binding_input'])
    targets={r['target']:r for r in actual['targets']};expected_old={r['target']:r['old_sha256']for r in scope['targets']};saved={r['res_path']:r for r in back['targets']}
    assert len(targets)==len(saved)==back['target_count']==28 and set(targets)==set(saved)==set(expected_old)==set(plan['root_target_allowlist'])
    before_bytes={};candidate_bytes={}
    for p,t in targets.items():
        r=saved[p];assert t['old_sha256']==expected_old[p]==r['old_sha256']==old['core_source_sha256'][p]and t['old_sha256']!=t['candidate_sha256']
        bp=Path(r['backup_path']).resolve();assert bp.is_relative_to(G)and Path(r['path']).resolve()==(G/p[6:]).resolve()
        before_bytes[p]=raw('res://'+bp.relative_to(G).as_posix(),r['old_sha256']);assert len(before_bytes[p])==r['old_bytes'];candidate_bytes[p]=raw(t['candidate_path'],t['candidate_sha256'])
    parent=inputdoc(c['parent_execution_input']);authority=inputdoc(plan['authority_input']);extra={p:s for p,s in authority['source_sha256'].items()if p not in parent['source_sha256']}
    assert len(parent['owned'])==len(authority['owned'])==10 and parent['owned'].keys()==authority['owned'].keys()and same(extra,c['proof_extra'])and len(extra)==5 and len(parent['source_sha256'])==96 and len(authority['source_sha256'])==101
    restored=copy.deepcopy(authority)
    for p,row in parent['owned'].items():
        if p not in proof['changed_owned']:assert same(row,authority['owned'][p]);continue
        new=authority['owned'][p];r=proof['records'][p];e=new['edges'][-1]
        assert len(new['edges'])==len(row['edges'])+1 and same(new['edges'][:-1],row['edges'])and e['old_sha256']==row['current_sha256']and e['new_sha256']==new['current_sha256']==r['candidate']['sha256']and same(e['replacements'],r['hunks'])
        restored['owned'][p]=copy.deepcopy(row)
    restored['source_sha256']=copy.deepcopy(parent['source_sha256']);assert same(restored,parent)and encode(restored)==raw(inputs[c['parent_execution_input']]['path'],inputs[c['parent_execution_input']]['sha256'])and candidate_bytes[EXE]==encode(authority)
    code_inverse=[]
    for p,r in proof['records'].items():
        before,after=before_bytes[p],candidate_bytes[p];assert sha(before)==r['parent']['sha256']and sha(after)==r['candidate']['sha256']and len(after)==r['candidate']['bytes']
        f,v=before.decode(),after.decode()
        for h in r['hunks']:
            assert f.count(h['old'])==v.count(h['new'])==1;f=f.replace(h['old'],h['new'],1);v=v.replace(h['new'],h['old'],1)
        assert f.encode()==after and v.encode()==before;code_inverse.append(p)
    assert len(code_inverse)==6
    nodes=actual['nodes'];typed=[];indices=[]
    def replace(values):
        result=copy.deepcopy(values)
        for p,t in targets.items():
            if p in result:assert result[p]==t['old_sha256'];result[p]=t['candidate_sha256']
        assert result.keys()==values.keys();return result
    def additions(ident):
        result={}if ident=='estate_final'else copy.deepcopy(extra)
        if ident in ['quarter_final','market_final','finite08_market']:result=merge(result,c['life_sources'],c['garden_sources'])
        if ident in ['market_final','finite08_market']:result=merge(result,c['scholar_sources'])
        return result
    for n in plan['nodes']:
        ident,kind=n['id'],n['kind'];v=nodes[ident]
        if kind in ['life_frozen','life_fixed_code']:
            assert v['sha256']==inputs[n['base_input']]['sha256']and'target'not in n;continue
        if kind in ['map','life_execution']:continue
        data=raw(v['path'],v['sha256'])
        if kind in ['metadata','life_quarter','life_contract']:
            before=inputdoc(n['base_input']);inverse=copy.deepcopy(v['value'])
            for d in reversed(actual['proofs'][ident].get('exact_life_declaration_delta',[])+[]):
                holder,key=ptr(inverse,d['pointer'][:-1]),d['pointer'][-1]
                if d['existed']:holder[key]=d['old']
                else:del holder[key]
            for d in reversed(actual['proofs'][ident]['source_delta']):
                holder,key=ptr(inverse,d['pointer'][:-1]),d['pointer'][-1]
                if d['existed']:holder[key]=d['old']
                else:del holder[key]
            assert same(inverse,before)and same(json.loads(data),v['value']);typed.append(ident)
            if kind=='life_contract':
                expected=copy.deepcopy(before);field='res://scripts/field/field_walkable_controller.gd';expected['source_sha256'][field]=targets[field]['candidate_sha256'];assert same(expected,v['value'])and before_bytes[CONTRACT].replace(targets[field]['old_sha256'].encode(),targets[field]['candidate_sha256'].encode(),1)==data;continue
            expected=copy.deepcopy(before);fields=n['source_bundle']['fields']if'source_bundle'in n else[f['pointer']for f in n.get('source_fields',[])]
            for keys in fields:ptr(expected,keys).update(replace(ptr(expected,keys)))
            for p,s in additions(ident).items():
                present=[ks for ks in fields if p in ptr(expected,ks)];assert len(present)<=1
                if present:assert ptr(expected,present[0])[p]==s
                else:
                    destination=['source_sha256']if ident=='quarter_final'else['legacy_source_sha256']
                    for route in n.get('source_bundle',{}).get('new_source_routes',[]):
                        if p.startswith(route['prefix']):destination=route['destination'];break
                    ptr(expected,destination)[p]=s
            if kind=='life_quarter':
                for field,suffix in [('scene_path','scene.res'),('layout_path','layout.res'),('packet_path','packet.bin')]:expected['scenes'][ARTISAN][field]=binding['child'][suffix]['path']
                expected['artisan_life_successor']={'binding_path':inputs[c['binding_input']]['path'],'binding_sha256':inputs[c['binding_input']]['sha256']}
                assert same(expected['scenes'][GARDEN],before['scenes'][GARDEN])and same(expected['a2_artisan_successor'],before['a2_artisan_successor'])
            assert same(expected,v['value']),('EXACT28_INDEPENDENT_METADATA_DECLARATION',ident)
            if ident=='estate_final':assert v['value']['registry_sha256']==v['value']['source_sha256'][v['value']['registry_path']]=='56c5bd39f02f32b45a606c84e22a8784be4900c616b7ec20c7547e497ce49f12'
        elif kind=='index':
            before=raw(inputs[n['base_input']]['path'],inputs[n['base_input']]['sha256']);disabled=before.decode();resolved=[]
            for h in n['replacements']:
                literal=h['new']
                if isinstance(literal,dict)and'$sha'in literal:literal=nodes[literal['$sha']]['sha256']
                elif isinstance(literal,dict)and'$pin'in literal:literal=inputs[literal['$pin']]['sha256']
                assert isinstance(literal,str)and disabled.count(h['old'])==1;disabled=disabled.replace(h['old'],literal,1);resolved.append((h['old'],literal))
            assert sha(disabled.encode())==actual['proofs'][ident]['disabled_sha256']and disabled.count(n['disabled_literal'])==1 and disabled.replace(n['disabled_literal'],n['enabled_literal'],1).encode()==data
            inverse=disabled
            for a,b in reversed(resolved):assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
            assert inverse.encode()==before;indices.append(ident)
        else:raise AssertionError(kind)
    assert len(typed)==13 and len(indices)==8
    sections=literal_patch_sections(raw(actual['patch_path'],actual['patch_sha256']));gd={p for p in targets if p.endswith('.gd')};assert len(gd)==14 and set(sections)==gd
    for p,chunks in sections.items():assert replay(before_bytes[p].decode(),chunks).encode()==candidate_bytes[p]and replay(candidate_bytes[p].decode(),[(b,a)for a,b in chunks]).encode()==before_bytes[p]
    copies=read(actual['byte_copy_plan']['path'],actual['byte_copy_plan']['sha256'])['rows'];assert len(copies)==14 and{r['target']for r in copies}=={p for p in targets if p.endswith('.json')}
    for r in copies:assert r['candidate_sha256']==targets[r['target']]['candidate_sha256']and r['candidate_path']==targets[r['target']]['candidate_path']and r['candidate_bytes']==len(candidate_bytes[r['target']])
    owner=copy.deepcopy(old);owner['actual_stage_receipt']={'path':RECEIPT,'sha256':ACTUAL_SHA};owner['fixed_prior_owner_sha256']=PRIOR_SHA
    maps={n['scene_id']:nodes[n['id']]['value']['source_sha256']for n in plan['nodes']if n['kind']=='map'}
    for family in ['scenes','rooms']:
        for row,prior in zip(owner[family],old[family]):
            assert row['id']==prior['id']
            for field in ['source_sha256','receipt_source_sha256']:
                expected=replace(prior[field]);added={}
                if EXE in prior[field]:added.update(extra)
                if row['id']in [ARTISAN,GARDEN,MARKET]:added=merge(added,c['life_sources'],c['garden_sources'])
                if row['id']==MARKET:added=merge(added,c['scholar_sources'])
                for p,s in added.items():assert p not in expected or expected[p]==s;expected[p]=s
                row[field]=expected
            if row['id']in maps:assert same(row['source_sha256'],maps[row['id']])and same(row['receipt_source_sha256'],maps[row['id']])
            if row['id']==ARTISAN:
                row['scene_path']=binding['child']['scene.res']['path'];row['layout_path']=binding['child']['layout.res']['path']
            if family=='rooms':assert same(row['receipt_source_sha256'],prior['receipt_source_sha256'])and len(row['source_sha256'])==573
    assert len(owner['scenes'])==8 and len(owner['rooms'])==5
    assert{r['id']:len(r['source_sha256'])for r in owner['scenes']if r['id']in maps}=={'ch4_s0_luoyang_gate':904,'ch4_s1_luoyang_yamen':1255,'ch4_s2_canal_docks':1734,MARKET:1741}
    for ident,a,b in [(ARTISAN,341,339),(GARDEN,341,339),(ESTATE,333,331),('ch4_s4_ancient_temple',398,398)]:
        row=next(r for r in owner['scenes']if r['id']==ident);assert len(row['source_sha256'])==a and len(row['receipt_source_sha256'])==b
    owner['core_source_sha256']=replace(old['core_source_sha256']);assert len(owner['core_source_sha256'])==47
    owner['metadata_fields_not_invented']='Fixed owner95+exact28 candidate values; execution API consumers add only five fixed proof keys; shared Quarter/Market additionally inherit fixed life binding source leaves and Garden shader; scholar three leaves Market-only. Artisan scene/layout paths move to fixed Root59 published child; old A2/Garden/other native history and all five room receipt dictionaries unchanged. No collector/current fill.'
    oldunion=merge(*(r[f]for r in old['scenes']+old['rooms']for f in ['source_sha256','receipt_source_sha256']));union=merge(*(r[f]for r in owner['scenes']+owner['rooms']for f in ['source_sha256','receipt_source_sha256']))
    assert union.keys()==oldunion.keys()|extra.keys()|c['life_sources'].keys()|c['garden_sources'].keys()|c['scholar_sources'].keys()
    counts={'changed_target_leaves':0,'matched_actual_stage_source_declarations':0,'unchanged_fixed95_leaves_not_rehashed':0}
    for p,s in union.items():
        if p in targets:assert s==targets[p]['candidate_sha256'];counts['changed_target_leaves']+=1
        elif p in actual['source_first']:assert s==actual['source_first'][p];counts['matched_actual_stage_source_declarations']+=1
        else:assert s==oldunion[p];counts['unchanged_fixed95_leaves_not_rehashed']+=1
    def emit(name,value):
        dest=G/(OUT+name)[6:];assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True);data=encode(value)
        with dest.open('xb')as stream:stream.write(data)
        return{'path':OUT+name,'sha256':sha(data)}
    result=emit('owner_source_maps_READY.json',owner)
    review=emit('source_stage_review_READY.json',{'status':'INDEPENDENT_ACTUAL100_EXACT28_FIXED_OWNER95_RECIPE_NOT_RUNTIME','actual_stage_receipt':owner['actual_stage_receipt'],'owner_source_maps':result,'partition':actual['target_partition'],'execution_whole_typed_byte_inverse':True,'only_three_owned_edges_old96_plus5':True,'metadata_full_typed_inverse':typed,'index_full_byte_inverse':indices,'six_code_whole_byte_inverse':code_inverse,'all_fourteen_patch_sections_forward_inverse':True,'all_fourteen_exact_JSON_copy_rows':True,'source_first_final_declarations_same':True,'expected_union_old_count':len(oldunion),'expected_union_count':len(union),**counts,'scene_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}for r in owner['scenes']},'G_full_source_count':573,'five_room_receipts_unchanged':True,'registry_DT_C_AA_AC_Router_unchanged':True,'Garden_original_native_A2_ancestor_preserved':True,'engine_Stage_collector_native_media_calls':0})
    print(json.dumps({'owner':result,'review':review}))
if __name__=='__main__':main()
