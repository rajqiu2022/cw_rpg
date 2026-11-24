"""Fixed actual71/E4BE + owner669 independent18 successor, Root-only execution.

No Stage import/collector/currentcanonical crawl/native decode/large source rehash.
OnlyMarket adds the single ordinary F1D0 shader; execution95/core47 domains stay.
"""
import argparse,copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
OUT=S+'performance72_A1_ENV18_actual_independent_review/'
PRIOR=S+'performance64_ground8_actual_independent_review/owner_source_maps_READY.json'
PRIOR_SHA='669e5d3e4ece06cf33707d6afdced6d65dc5ca7785b8f44ff19698dde741f7c0'
PLAN=S+'performance71_A1_ENV18_source_recipe/source_input_ROOT_LOCKED.json'
PLAN_SHA='65de85b1f037526bf8905712fe66d8075c95b0e6b039e500ba2116d2795797b9'
RECEIPT=S+'outputs/root_A1_ENV18_stage01/receipt.json'
FIXED_RECEIPT_SHA='e4beb20d93cd00b91933f7879fc63edf5a173b3a3a772b5293fb56896f055468'
ENV='res://scripts/city/luoyang_environment_layer_20261022ap.gd'
SHADER='res://build/luoyang_city_full_rollout_20261022ap_system01/market_L_continuous_material_epoch01/market_L_continuous_candidate.gdshader'
SHADER_SHA='f1d01c7d63ba62b5c9883f4976f3b73da96e5b54243e4431d5ba5b61787c4d06'
def sha(b):return hashlib.sha256(b).hexdigest()
def raw(path,s):
    assert path.startswith('res://')and'..'not in path
    b=(G/path[6:]).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def read(path,s):return json.loads(raw(path,s))
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
def ptr(v,keys):
    for k in keys:v=v[k]
    return v
def merge(*tables):
    result={}
    for table in tables:
        for path,s in table.items():assert path not in result or result[path]==s;result[path]=s
    return result
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--receipt',default=RECEIPT);ap.add_argument('--sha256',default=FIXED_RECEIPT_SHA);args=ap.parse_args()
    assert args.receipt==RECEIPT and args.sha256==FIXED_RECEIPT_SHA and not(G/OUT[6:]).exists()
    actual=read(RECEIPT,FIXED_RECEIPT_SHA);plan=read(PLAN,PLAN_SHA);old=read(PRIOR,PRIOR_SHA)
    assert actual['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED'and actual['source_first']==actual['source_final']and actual['source_first'][PLAN]==PLAN_SHA
    assert actual['target_partition']=={'patch_count':7,'copy_count':11,'total':18,'intersection_empty':True,'union_exact_targets':True}
    inputs={r['id']:r for r in plan['pinned_inputs']};c=plan['B_only_contract']
    scope=read(inputs[c['scope_input']]['path'],inputs[c['scope_input']]['sha256']);back=read(inputs[c['backup_input']]['path'],inputs[c['backup_input']]['sha256'])
    saved={'res://'+Path(r['path']).resolve().relative_to(G).as_posix():r for r in back['targets']}
    targets={r['target']:r for r in actual['targets']};expected_old={r['target']:r['old_sha256']for r in scope['existing_targets']}
    assert len(targets)==len(saved)==18 and set(targets)==set(expected_old)==set(plan['root_target_allowlist'])
    for path,row in targets.items():
        assert row['old_sha256']==expected_old[path]==saved[path]['sha256']==old['core_source_sha256'][path]and row['old_sha256']!=row['candidate_sha256']
        raw(row['candidate_path'],row['candidate_sha256'])
    authority=read(inputs[plan['authority_input']]['path'],inputs[plan['authority_input']]['sha256'])
    assert inputs[plan['authority_input']]['sha256']=='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3'and len(authority['owned'])==10 and len(authority['source_sha256'])==95 and ENV not in authority['owned']and ENV not in authority['source_sha256']
    assert inputs[c['shader_input']]['path']==SHADER and inputs[c['shader_input']]['sha256']==SHADER_SHA
    nodes=actual['nodes'];typed=[];indices=[];env_inverse=[]
    for n in plan['nodes']:
        ident=n['id'];v=nodes[ident]
        if n['kind']=='a1_frozen':assert v['sha256']==inputs[n['base_input']]['sha256']and'target'not in n;continue
        if n['kind']=='map':continue
        data=raw(v['path'],v['sha256'])
        if n['kind']=='metadata':
            before=read(inputs[n['base_input']]['path'],inputs[n['base_input']]['sha256']);inverse=copy.deepcopy(v['value'])
            for d in reversed(actual['proofs'][ident]['source_delta']):
                holder,key=ptr(inverse,d['pointer'][:-1]),d['pointer'][-1]
                if d['existed']:holder[key]=d['old']
                else:del holder[key]
            assert same(inverse,before)and same(json.loads(data),v['value']);typed.append(ident)
            fields=n['source_bundle']['fields']if'source_bundle'in n else[f['pointer']for f in n.get('source_fields',[])]
            expected=copy.deepcopy(before)
            for keys in fields:
                values=ptr(expected,keys)
                for path,r in targets.items():
                    if path in values:assert values[path]==r['old_sha256'];values[path]=r['candidate_sha256']
            if ident in ['market_final','finite08_market']:
                assert all(SHADER not in ptr(before,k)for k in fields);expected['legacy_source_sha256'][SHADER]=SHADER_SHA
            assert same(expected,v['value']),('ONLY_EXISTING_VALUES_AND_MARKET_SHADER',ident)
        elif n['kind']=='index':
            proof=actual['proofs'][ident];assert proof['disabled_to_enabled_sole_bool_whole_inverse']is True
            before=raw(inputs[n['base_input']]['path'],inputs[n['base_input']]['sha256']);disabled=before.decode();resolved=[]
            for h in n['replacements']:
                literal=h['new']
                if isinstance(literal,dict)and'$sha'in literal:literal=nodes[literal['$sha']]['sha256']
                elif isinstance(literal,dict)and'$pin'in literal:literal=inputs[literal['$pin']]['sha256']
                assert isinstance(literal,str)and disabled.count(h['old'])==1
                disabled=disabled.replace(h['old'],literal,1);resolved.append((h['old'],literal))
            assert sha(disabled.encode())==proof['disabled_sha256']and disabled.count(n['disabled_literal'])==1
            assert disabled.replace(n['disabled_literal'],n['enabled_literal'],1).encode()==data
            inverse=disabled
            for a,b in reversed(resolved):assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
            assert inverse.encode()==before;indices.append(ident)
        elif n['kind']=='a1_code':
            proof=read(inputs[c['proof_input']]['path'],inputs[c['proof_input']]['sha256']);tone=read(inputs[c['tone_input']]['path'],inputs[c['tone_input']]['sha256'])
            backup=saved[ENV];before=raw('res://'+Path(backup['backup_path']).resolve().relative_to(G).as_posix(),backup['sha256']);forward=before
            assert len(proof['operations_in_order'])==10
            for h in proof['operations_in_order']:
                a,b=h['old'].encode(),h['new'].encode();assert forward.count(a)==1;forward=forward.replace(a,b,1)
            assert sha(forward)==proof['candidate']['sha256'].lower()==tone['parent_A1_ENV']['sha256'].lower()
            a,b=tone['one_hunk']['old'].encode(),tone['one_hunk']['new'].encode();assert forward.count(a)==1 and data.count(b)==1 and forward.replace(a,b,1)==data
            inverse=data.replace(b,a,1)
            for h in reversed(proof['operations_in_order']):
                a,b=h['old'].encode(),h['new'].encode();assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
            assert inverse==before and sha(data)=='c21586df883bfa96706f254823fa5952c1bd6fffb9807f2e0d1a12d00862847b';env_inverse.append(ident)
        else:raise AssertionError(('UNEXPECTED_CHANGED_KIND',n['kind']))
    assert len(typed)==11 and len(indices)==6 and env_inverse==['ENV_code']
    def replace(values):
        result=copy.deepcopy(values)
        for path,row in targets.items():
            if path in result:assert result[path]==row['old_sha256'],('FIXED669_OLD',path);result[path]=row['candidate_sha256']
        assert set(result)==set(values);return result
    owner=copy.deepcopy(old);owner['actual_stage_receipt']={'path':RECEIPT,'sha256':FIXED_RECEIPT_SHA};owner['fixed_prior_owner_sha256']=PRIOR_SHA
    maps={n['scene_id']:nodes[n['id']]['value']['source_sha256']for n in plan['nodes']if n['kind']=='map'}
    for family in ['scenes','rooms']:
        for row,prior in zip(owner[family],old[family]):
            is_market=row['id']=='ch4_s3_luoyang_market'
            for field in ['source_sha256','receipt_source_sha256']:
                row[field]=replace(prior[field]);assert SHADER not in row[field]
                if is_market:row[field][SHADER]=SHADER_SHA
                assert set(row[field])==set(prior[field])|({SHADER}if is_market else set())
            if row['id']in maps:assert same(row['source_sha256'],maps[row['id']])and same(row['source_sha256'],row['receipt_source_sha256'])
            if family=='rooms':assert same(row,prior),('ALL_FIVE_ROOM_DOMAINS_WHOLE_TYPED_UNCHANGED',row['id'])
    assert len(owner['scenes'])==8 and len(owner['rooms'])==5
    assert {r['id']:len(r['source_sha256'])for r in owner['scenes']if r['id']in maps}=={'ch4_s0_luoyang_gate':898,'ch4_s1_luoyang_yamen':1249,'ch4_s2_canal_docks':1726,'ch4_s3_luoyang_market':1713}
    assert same(next(r for r in owner['scenes']if r['id']=='luoyang_estate_riverside_20261021ai'),next(r for r in old['scenes']if r['id']=='luoyang_estate_riverside_20261021ai'))
    owner['core_source_sha256']=replace(old['core_source_sha256']);assert len(owner['core_source_sha256'])==47 and SHADER not in owner['core_source_sha256']
    owner['metadata_fields_not_invented']='Fixed669 complete8scene5room/core47 plus exact18 existing-value substitutions. OnlyMarket fullcollector and receipt add ordinary F1D0shader. Other7scene/five room keysets unchanged, five room tables whole typed unchanged; execution647949 owned10/95proof frozen. Existing native/geometry/registry/doors/tasks/Root39SOURCE_ONLY2 preserved.'
    oldunion=merge(*(r[f]for r in old['scenes']+old['rooms']for f in ['source_sha256','receipt_source_sha256']))
    union=merge(*(r[f]for r in owner['scenes']+owner['rooms']for f in ['source_sha256','receipt_source_sha256']));assert set(union)==set(oldunion)|{SHADER}
    counts={'changed_target_leaves':0,'matched_actual_stage_source_declarations':0,'unchanged669_leaves_not_rehashed':0}
    for path,s in union.items():
        if path in targets:assert s==targets[path]['candidate_sha256'];counts['changed_target_leaves']+=1
        elif path in actual['source_first']:assert s==actual['source_first'][path];counts['matched_actual_stage_source_declarations']+=1
        else:assert s==oldunion[path];counts['unchanged669_leaves_not_rehashed']+=1
    def emit(name,value):
        dest=G/(OUT+name)[6:];assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True);b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
        with dest.open('xb')as f:f.write(b)
        return{'path':OUT+name,'sha256':sha(b)}
    desc=emit('owner_source_maps_READY.json',owner)
    review=emit('source_stage_review_READY.json',{'status':'INDEPENDENT_A1_ENV18_FIXED669_ACTUAL_EXISTING_VALUES_ONLY_MARKET_SHADER_NOT_RUNTIME_OR_ART','actual_stage_receipt':owner['actual_stage_receipt'],'owner_source_maps':desc,'target_count':18,'partition':actual['target_partition'],'metadata_typed_inverse':typed,'index_byte_inverse':indices,'ENV_byte_inverse':env_inverse,'source_first_final_declaration_same':True,'expected_union_old_count':len(oldunion),'expected_union_count':len(union),**counts,'scene_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}for r in owner['scenes']},'all_five_room_tables_whole_typed_same':True,'core47_keys_unchanged_shader_not_added':True,'execution95_unchanged':True,'engine_Stage_collector_packet_media_calls':0})
    print(json.dumps({'owner':desc,'review':review}))
if __name__=='__main__':main()
