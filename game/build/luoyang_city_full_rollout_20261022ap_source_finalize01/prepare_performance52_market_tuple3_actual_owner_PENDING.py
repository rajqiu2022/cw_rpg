"""Blocked pending actual51: SOURCE_ONLY exact3 independent owner successor to fixed585717.

Do not execute until Root supplies the real stage receipt SHA. No Stage import,
collector, engine, canonical crawl, geometry or source-FIRST reread is involved.
"""
import argparse,copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
OUT=S+'performance52_market_tuple3_actual_independent_review/'
PRIOR=S+'performance49_estate17_actual_independent_review/owner_source_maps_READY.json'
PRIOR_SHA='585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f'
PLAN=S+'performance51_market_tuple3_source_recipe/source_input_ROOT_LOCKED.json'
PLAN_SHA='30254627510d38509c900b00402c29c7c5d1e45691b0a704e0544addf4808b0c'
FIXED_RECEIPT_SHA='PENDING_ROOT_ACTUAL_51_RECEIPT_SHA'
def sha(b):return hashlib.sha256(b).hexdigest()
def raw(path,s):
    assert path.startswith('res://') and '..'not in path
    b=(G/path[6:]).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def read(path,s):return json.loads(raw(path,s))
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def ptr(v,keys):
    for k in keys:v=v[k]
    return v
def restore(v,deltas):
    for d in reversed(deltas):
        holder,key=ptr(v,d['pointer'][:-1]),d['pointer'][-1]
        if d['existed']:holder[key]=d['old']
        else:del holder[key]
def merge(*tables):
    result={}
    for table in tables:
        for path,s in table.items():assert path not in result or result[path]==s;result[path]=s
    return result
def main():
    ap=argparse.ArgumentParser();ap.add_argument('--receipt',required=True);ap.add_argument('--sha256',required=True);args=ap.parse_args()
    assert args.receipt==S+'outputs/root_market_source_only_tuple3_stage01/receipt.json'
    assert not (G/OUT[6:]).exists()
    assert args.sha256==FIXED_RECEIPT_SHA
    actual=read(args.receipt,args.sha256);plan=read(PLAN,PLAN_SHA);old=read(PRIOR,PRIOR_SHA)
    assert actual['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED' and actual['source_first']==actual['source_final']
    assert actual['source_first'][PLAN]==PLAN_SHA
    assert actual['target_partition']=={'patch_count':1,'copy_count':2,'total':3,'intersection_empty':True,'union_exact_targets':True}
    inputs={r['id']:r for r in plan['pinned_inputs']};c=plan['B_only_contract']
    request=read(inputs[c['scope_request_input']]['path'],inputs[c['scope_request_input']]['sha256'])
    targets={r['target']:r for r in actual['targets']};expected_old={r['target']:r['old_sha256'] for r in request['targets']}
    assert len(targets)==3 and set(targets)==set(plan['root_target_allowlist'])==set(expected_old)
    for path,row in targets.items():
        assert row['old_sha256']==expected_old[path] and row['old_sha256']!=row['candidate_sha256'];raw(row['candidate_path'],row['candidate_sha256'])
    nodes=actual['nodes'];typed=[];indices=[]
    for n in plan['nodes']:
        ident=n['id'];v=nodes[ident];data=raw(v['path'],v['sha256'])
        if n['kind']=='metadata':
            prior=read(inputs[n['base_input']]['path'],inputs[n['base_input']]['sha256'])
            inverse=copy.deepcopy(v['value']);restore(inverse,actual['proofs'][ident]['source_delta'])
            assert same(inverse,prior) and same(json.loads(data),v['value']),('WHOLE_TYPED_METADATA_INVERSE',ident);typed.append(ident)
        elif n['kind']=='index':
            proof=actual['proofs'][ident];assert proof['disabled_to_enabled_sole_bool_whole_inverse'] is True
            before=raw(inputs[n['base_input']]['path'],inputs[n['base_input']]['sha256']);disabled=before.decode();resolved=[]
            for h in n['replacements']:
                literal=h['new']
                if isinstance(literal,dict) and '$sha'in literal:literal=nodes[literal['$sha']]['sha256']
                elif isinstance(literal,dict) and '$pin'in literal:literal=inputs[literal['$pin']]['sha256']
                assert isinstance(literal,str) and disabled.count(h['old'])==1
                disabled=disabled.replace(h['old'],literal,1);resolved.append((h['old'],literal))
            assert sha(disabled.encode())==proof['disabled_sha256'] and disabled.count(n['disabled_literal'])==1
            assert disabled.replace(n['disabled_literal'],n['enabled_literal'],1).encode()==data
            inverse=disabled
            for a,b in reversed(resolved):assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
            assert inverse.encode()==before;indices.append(ident)
        elif n['kind']=='tuple3_frozen':assert v['sha256']==inputs[n['base_input']]['sha256'] and 'target'not in n
    assert len(typed)==2 and len(indices)==1
    admission=read(inputs[c['admission_input']]['path'],inputs[c['admission_input']]['sha256'])
    assert inputs[c['admission_input']]['sha256']=='b1bb3a2ce1067f0d5029f052fe59631e785ca114a591dff5de07150e52d368e4'
    leaves=admission['source_leaves'];assert len(leaves)==2
    assert admission['status']=='ROOT_EXPLICIT_NEW_SOURCE_ONLY_TWO_LEAF_ADMISSION'and admission['approved_by_root']is True
    def replace(values):
        result=copy.deepcopy(values)
        for path,row in targets.items():
            if path in result:
                assert result[path]==row['old_sha256'],('EXACT_INHERITED585717_OLD_VALUE',path,result[path],row['old_sha256'])
                result[path]=row['candidate_sha256']
        return result
    # Expected maps come only from fixed544819 plus the exact17 approved target
    # values. The Stage's four independent AO maps are verification, not input.
    maps={n['scene_id']:nodes[n['id']]['value']['source_sha256']for n in plan['nodes']if n['kind']=='map'}
    scenes=[]
    for original in old['scenes']:
        row=copy.deepcopy(original)
        for field in ['source_sha256','receipt_source_sha256']:
            row[field]=replace(original[field])
            if row['id']=='ch4_s3_luoyang_market':
                assert not(set(row[field])&set(leaves));row[field].update(leaves)
            assert set(row[field])==set(original[field])|(set(leaves)if row['id']=='ch4_s3_luoyang_market'else set())
        if row['id']in maps:
            assert same(maps[row['id']],row['source_sha256']) and same(row['receipt_source_sha256'],row['source_sha256']),('FOUR_INDEPENDENT_MAPS_EXACT_FIXED5857_THREE_HEADERS_AND_ONLY_MARKET_TWO_LEAVES',row['id'])
        elif row['id']in nodes['quarter_final']['value']['scenes']:
            native=nodes['quarter_final']['value']['scenes'][row['id']]
            assert same(nodes['quarter_final']['value']['source_sha256'],row['receipt_source_sha256']) and row['scene_path']==native['scene_path'] and row['layout_path']==native['layout_path']
            assert same(row['source_sha256'],original['source_sha256']) and same(row['receipt_source_sha256'],original['receipt_source_sha256'])
        elif row['id']=='luoyang_estate_riverside_20261021ai':
            assert len(row['receipt_source_sha256'])==331 and same(nodes['estate_final']['value']['source_sha256'],row['receipt_source_sha256'])
            assert same(row['source_sha256'],original['source_sha256']) and same(row['receipt_source_sha256'],original['receipt_source_sha256'])
        elif row['id']=='ch4_s4_ancient_temple':
            assert same(row['source_sha256'],original['source_sha256']) and same(row['receipt_source_sha256'],original['receipt_source_sha256'])
        else:raise AssertionError(('UNKNOWN_OWNER_SCENE',row['id']))
        row['recipe']='Fixed585717 independent map plus exact3 current header values; only Market adds the Root39 admitted2 SOURCE_ONLY leaves. Other scene keysets/native/receipt contracts unchanged; no collector observation.'
        scenes.append(row)
    registry=nodes['registry_final']['value'];rooms=[]
    for original in old['rooms']:
        row=copy.deepcopy(original);row['source_sha256']=replace(original['source_sha256'])
        assert set(row['source_sha256'])==set(original['source_sha256'])
        assert same(registry['rooms'][row['id']]['source_sha256'],original['receipt_source_sha256'])
        assert same(row['receipt_source_sha256'],original['receipt_source_sha256'])
        row['recipe']='Fixed585717 G complete source and per-room receipt dictionaries remain whole unchanged; no Market proof imports are inherited through this API.'
        assert same(row['source_sha256'],original['source_sha256'])
        rooms.append(row)
    assert len(scenes)==8 and len(rooms)==5
    assert {r['id']:len(r['source_sha256'])for r in scenes if r['id'].startswith('ch4_s')and r['id']!='ch4_s4_ancient_temple'}=={'ch4_s0_luoyang_gate':888,'ch4_s1_luoyang_yamen':1239,'ch4_s2_canal_docks':1716,'ch4_s3_luoyang_market':1702}
    assert all(len(r['source_sha256'])==557 for r in rooms)
    oldunion=merge(*(r[f] for r in old['scenes']+old['rooms'] for f in ['source_sha256','receipt_source_sha256']))
    union=merge(*(r[f] for r in scenes+rooms for f in ['source_sha256','receipt_source_sha256']))
    counts={'changed_target_leaves':0,'matched_actual_stage_source_declarations':0,'unchanged_inherited585717_leaves_not_rehashed':0}
    for path,s in union.items():
        if path in targets:assert targets[path]['candidate_sha256']==s;counts['changed_target_leaves']+=1
        elif path in actual['source_first']:assert actual['source_first'][path]==s;counts['matched_actual_stage_source_declarations']+=1
        else:assert oldunion.get(path)==s,('UNDECLARED_NEW_EXPECTATION',path);counts['unchanged_inherited585717_leaves_not_rehashed']+=1
    core=copy.deepcopy(old['core_source_sha256']);core.update({path:r['candidate_sha256'] for path,r in targets.items()})
    owner={'status':'ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS','actual_stage_receipt':{'path':args.receipt,'sha256':args.sha256},'core_source_sha256':core,'scenes':scenes,'rooms':rooms,'fixed_prior_owner_sha256':PRIOR_SHA,'expected_not_derived_from_live_collector_or_canonical_hash_crawl':True,'not_Field_or_runtime_credit':True,'metadata_fields_not_invented':'All585717 identity/native/receipt contracts inherited.Only3 existing header values change; Market only gains2 Root39 SOURCE_ONLY leaves.Other3C keysets and all G/Quarter/Estate/Temple maps/registry/roomreceipt remain unchanged except the shared3headers where actually declared.No runtime/import credit.'}
    def emit(name,value):
        dest=G/(OUT+name)[6:];assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True);b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
        with dest.open('xb')as f:f.write(b)
        return {'path':OUT+name,'sha256':sha(b)}
    desc=emit('owner_source_maps_READY.json',owner)
    review=emit('source_stage_review_READY.json',{'status':'INDEPENDENT3_BYTE_TYPED_FIXED585717_SOURCE_ONLY_TUPLE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT','actual_stage_receipt':owner['actual_stage_receipt'],'owner_source_maps':desc,'source_first_final_same':True,'actual_stage_source_count':len(actual['source_first']),'target_count':3,'partition':actual['target_partition'],'typed_inverse_nodes':typed,'index_byte_inverse_nodes':indices,'expected_union_count':len(union),**counts,'scene_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}for r in scenes},'room_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}for r in rooms},'engine_collector_Stage_native_decode_calls':0})
    print(json.dumps({'owner':desc,'review':review}))
if __name__=='__main__':main()
