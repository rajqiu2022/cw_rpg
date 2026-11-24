"""Blocked pending actual58: exact30 Market complete-parent independent owner successor to fixedFC11.

Do not execute until Root supplies the real stage receipt SHA. No Stage import,
collector, engine, canonical crawl, geometry or source-FIRST reread is involved.
"""
import argparse,copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
OUT=S+'performance59_market_parent30_actual_independent_review/'
PRIOR=S+'performance54_market_tuple3_actual_independent_review/owner_source_maps_READY.json'
PRIOR_SHA='fc11a02989c4e9d57628dccaa82c08cd11df6767c954f4ed4829b5dcdffc0f02'
PLAN=S+'performance58_market_parent30_source_recipe/source_input_ROOT_LOCKED.json'
PLAN_SHA='a29f32c01dcac22c4a1289e5bd5084c4cb76195d7666ee021165d6aba98dd140'
FIXED_RECEIPT_SHA='PENDING_ROOT_ACTUAL58_RECEIPT_SHA'
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
    assert args.receipt==S+'outputs/root_market_complete_parent30_stage01/receipt.json'
    assert not (G/OUT[6:]).exists()
    assert args.sha256==FIXED_RECEIPT_SHA
    actual=read(args.receipt,args.sha256);plan=read(PLAN,PLAN_SHA);old=read(PRIOR,PRIOR_SHA)
    assert actual['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED' and actual['source_first']==actual['source_final']
    assert actual['source_first'][PLAN]==PLAN_SHA
    assert actual['target_partition']=={'patch_count':15,'copy_count':15,'total':30,'intersection_empty':True,'union_exact_targets':True}
    inputs={r['id']:r for r in plan['pinned_inputs']};c=plan['B_only_contract']
    request=read(inputs[c['scope_input']]['path'],inputs[c['scope_input']]['sha256'])
    targets={r['target']:r for r in actual['targets']};expected_old={r['target']:r['old_sha256'] for r in request['targets']}
    assert len(targets)==30 and set(targets)==set(plan['root_target_allowlist'])==set(expected_old)
    for path,row in targets.items():
        assert row['old_sha256']==expected_old[path] and row['old_sha256']!=row['candidate_sha256'];raw(row['candidate_path'],row['candidate_sha256'])
    nodes=actual['nodes'];typed=[];indices=[]
    for n in plan['nodes']:
        ident=n['id'];v=nodes[ident];data=raw(v['path'],v['sha256'])
        if n['kind']in ['metadata','repair30_contract_literal']:
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
        elif n['kind']=='repair30_frozen':assert v['sha256']==inputs[n['base_input']]['sha256'] and 'target'not in n
    assert len(typed)==14 and len(indices)==8
    hand=read(inputs[c['production_input']]['path'],inputs[c['production_input']]['sha256'])
    assert inputs[c['production_input']]['sha256']=='e12394b9f9f47524f5118c3fb4ddad9a38306d042289eaddbe9f830a7398d953'
    leaves=hand['new_exact10_proof_pins'];assert len(leaves)==10
    code=read(hand['whole_inverse_proof']['path'],hand['whole_inverse_proof']['sha256'])
    for r in code['records'].values():
        before=raw(r['parent']['path'],r['parent']['sha256']);candidate=raw(r['candidate']['path'],r['candidate']['sha256']);forward=before;inverse=candidate
        for h in r['hunks']:
            a,b=h['old'].encode(),h['new'].encode();assert forward.count(a)==1 and inverse.count(b)==1;forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
        assert forward==candidate and inverse==before
    scalar=nodes['estate_final']['value'];registry_path='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
    assert scalar['registry_path']==registry_path and scalar['registry_sha256']==scalar['source_sha256'][registry_path]==nodes['registry_final']['sha256']
    def replace(values):
        result=copy.deepcopy(values)
        for path,row in targets.items():
            if path in result:
                assert result[path]==row['old_sha256'],('EXACT_INHERITEDFC11_OLD_VALUE',path,result[path],row['old_sha256'])
                result[path]=row['candidate_sha256']
        return result
    # Independent declaration-derived consumers, never actual collector fill:
    # C complete maps, both Quarter shared receipts, G fullfamily collectors,
    # Temple consume execution source_paths95; Estate331 and roomreceipts do not.
    maps={n['scene_id']:nodes[n['id']]['value']['source_sha256']for n in plan['nodes']if n['kind']=='map'}
    scenes=[]
    for original in old['scenes']:
        row=copy.deepcopy(original);is_estate=row['id']=='luoyang_estate_riverside_20261021ai'
        for field in ['source_sha256','receipt_source_sha256']:
            row[field]=replace(original[field])
            if not is_estate:
                assert not(set(row[field])&set(leaves));row[field].update(leaves)
            assert set(row[field])==set(original[field])|(set()if is_estate else set(leaves))
        if row['id']in maps:
            assert same(maps[row['id']],row['source_sha256']) and same(row['source_sha256'],row['receipt_source_sha256']),('FOUR_COMPLETE_AO_MAPS_FIXED_FC11_PLUS30_AND10',row['id'])
        elif row['id']in nodes['quarter_final']['value']['scenes']:
            native=nodes['quarter_final']['value']['scenes'][row['id']]
            assert same(nodes['quarter_final']['value']['source_sha256'],row['receipt_source_sha256']) and row['scene_path']==native['scene_path']and row['layout_path']==native['layout_path']
            assert len(row['source_sha256'])==304 and len(row['receipt_source_sha256'])==302
        elif is_estate:
            assert len(row['source_sha256'])==333 and len(row['receipt_source_sha256'])==331 and same(scalar['source_sha256'],row['receipt_source_sha256'])
        elif row['id']=='ch4_s4_ancient_temple':
            assert len(row['source_sha256'])==len(row['receipt_source_sha256'])==392
        else:raise AssertionError(('UNKNOWN_SCENE_OWNER',row['id']))
        row['recipe']='FixedFC11 independent fulltable plus exact30 existing-source value substitutions; execution API consumers acquire only the10 approved snapshots. Estate331 keyset/native identity fixed. No collector observation.'
        scenes.append(row)
    registry=nodes['registry_final']['value'];assert len(registry['rooms'])==12;rooms=[];dt='res://scripts/city/luoyang_district_life_20261016f.gd'
    for original in old['rooms']:
        row=copy.deepcopy(original);row['source_sha256']=replace(original['source_sha256']);assert not(set(row['source_sha256'])&set(leaves));row['source_sha256'].update(leaves)
        row['receipt_source_sha256']=replace(original['receipt_source_sha256'])
        assert len(row['source_sha256'])==567 and set(row['source_sha256'])==set(original['source_sha256'])|set(leaves)
        assert set(row['receipt_source_sha256'])==set(original['receipt_source_sha256'])and {path for path in row['receipt_source_sha256']if row['receipt_source_sha256'][path]!=original['receipt_source_sha256'][path]}=={dt}
        assert same(registry['rooms'][row['id']]['source_sha256'],row['receipt_source_sha256'])
        row['recipe']='FixedFC11 G557 complete source API consumes execution95, hence567 with10new snapshotkeys. Per-room receipt has no newkey and only one DT source value successor; original native/return/door fields retained.'
        rooms.append(row)
    assert len(scenes)==8 and len(rooms)==5
    assert {r['id']:len(r['source_sha256'])for r in scenes if r['id']in maps}=={'ch4_s0_luoyang_gate':898,'ch4_s1_luoyang_yamen':1249,'ch4_s2_canal_docks':1726,'ch4_s3_luoyang_market':1712}
    sourceonly={path for path in old['scenes'][3]['source_sha256']if path.endswith('walk.png-eb63fda1eba65c60ad6a24b15599ec76.ctex')}
    for r in scenes+rooms:
        if r['id']!='ch4_s3_luoyang_market':assert not(set(r['source_sha256'])&sourceonly)
    oldunion=merge(*(r[f] for r in old['scenes']+old['rooms'] for f in ['source_sha256','receipt_source_sha256']))
    union=merge(*(r[f] for r in scenes+rooms for f in ['source_sha256','receipt_source_sha256']))
    counts={'changed_target_leaves':0,'matched_actual_stage_source_declarations':0,'unchanged_inheritedFC11_leaves_not_rehashed':0}
    for path,s in union.items():
        if path in targets:assert targets[path]['candidate_sha256']==s;counts['changed_target_leaves']+=1
        elif path in actual['source_first']:assert actual['source_first'][path]==s;counts['matched_actual_stage_source_declarations']+=1
        else:assert oldunion.get(path)==s,('UNDECLARED_NEW_EXPECTATION',path);counts['unchanged_inheritedFC11_leaves_not_rehashed']+=1
    core=copy.deepcopy(old['core_source_sha256']);core.update({path:r['candidate_sha256'] for path,r in targets.items()})
    owner={'status':'ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS','actual_stage_receipt':{'path':args.receipt,'sha256':args.sha256},'core_source_sha256':core,'scenes':scenes,'rooms':rooms,'fixed_prior_owner_sha256':PRIOR_SHA,'expected_not_derived_from_live_collector_or_canonical_hash_crawl':True,'not_Field_or_runtime_credit':True,'metadata_fields_not_invented':'FixedFC11 identities/native preserved.Exact30 source value successors; execution-source API consumers add only approved10snapshotkeys.Estate331 and five roomreceipt keysets fixed; roomreceipts only DT values migrate.Root39two SOURCE_ONLY leaves remain Market-only; no collector observed expectations.'}
    def emit(name,value):
        dest=G/(OUT+name)[6:];assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True);b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
        with dest.open('xb')as f:f.write(b)
        return {'path':OUT+name,'sha256':sha(b)}
    desc=emit('owner_source_maps_READY.json',owner)
    review=emit('source_stage_review_READY.json',{'status':'INDEPENDENT30_BYTE_TYPED_FIXEDFC11_COMPLETE_PARENT_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT','actual_stage_receipt':owner['actual_stage_receipt'],'owner_source_maps':desc,'source_first_final_same':True,'actual_stage_source_count':len(actual['source_first']),'target_count':30,'partition':actual['target_partition'],'typed_inverse_nodes':typed,'index_byte_inverse_nodes':indices,'expected_union_count':len(union),**counts,'scene_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}for r in scenes},'room_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}for r in rooms},'engine_collector_Stage_native_decode_calls':0})
    print(json.dumps({'owner':desc,'review':review}))
if __name__=='__main__':main()
