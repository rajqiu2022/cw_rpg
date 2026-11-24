"""Root-only actual17 Estate scalar review and independent owner successor to fixed544819.

Do not execute until Root supplies the real stage receipt SHA. No Stage import,
collector, engine, canonical crawl, geometry or source-FIRST reread is involved.
"""
import argparse,copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
OUT=S+'performance49_estate17_actual_independent_review/'
PRIOR=S+'performance43_culture_actual_independent_review/owner_source_maps_READY.json'
PRIOR_SHA='544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0'
PLAN=S+'performance48_estate17_source_recipe/source_input_ROOT_LOCKED.json'
PLAN_SHA='c16d31254944fc7b8a4fc0c20cc49dfa4b1e2a1ec4e01058240c4fc02db2e03a'
FIXED_RECEIPT_SHA='96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7'
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
    assert args.receipt==S+'outputs/root_estate_registry_scalar17_stage01/receipt.json'
    assert not (G/OUT[6:]).exists()
    assert args.sha256==FIXED_RECEIPT_SHA
    actual=read(args.receipt,args.sha256);plan=read(PLAN,PLAN_SHA);old=read(PRIOR,PRIOR_SHA)
    assert actual['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED' and actual['source_first']==actual['source_final']
    assert actual['source_first'][PLAN]==PLAN_SHA
    assert actual['target_partition']=={'patch_count':6,'copy_count':11,'total':17,'intersection_empty':True,'union_exact_targets':True}
    inputs={r['id']:r for r in plan['pinned_inputs']};c=plan['B_only_contract']
    request=read(inputs[c['scope_request_input']]['path'],inputs[c['scope_request_input']]['sha256'])
    targets={r['target']:r for r in actual['targets']};expected_old={r['target']:r['old_sha256'] for r in request['targets']}
    assert len(targets)==17 and set(targets)==set(plan['root_target_allowlist'])==set(expected_old)
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
        elif n['kind']=='estate17_frozen':assert v['sha256']==inputs[n['base_input']]['sha256'] and 'target'not in n
    scalar=nodes['estate_final']['value'];registry_path='res://data/maps/luoyang_estate_rooms_20261021am/registry.json'
    assert scalar['registry_path']==registry_path and scalar['registry_sha256']==scalar['source_sha256'][registry_path]=='f5298b913fbaefda2c5f3679223c014c219292a54df412a8c3f2d96e4f082f28'
    assert len(typed)==11 and len(indices)==6
    def replace(values):
        result=copy.deepcopy(values)
        for path,row in targets.items():
            if path in result:
                assert result[path]==row['old_sha256'],('EXACT_INHERITED544819_OLD_VALUE',path,result[path],row['old_sha256'])
                result[path]=row['candidate_sha256']
        return result
    # Expected maps come only from fixed544819 plus the exact17 approved target
    # values. The Stage's four independent AO maps are verification, not input.
    maps={n['scene_id']:nodes[n['id']]['value']['source_sha256']for n in plan['nodes']if n['kind']=='map'}
    scenes=[]
    for original in old['scenes']:
        row=copy.deepcopy(original)
        for field in ['source_sha256','receipt_source_sha256']:
            row[field]=replace(original[field]);assert set(row[field])==set(original[field])
        if row['id']in maps:
            assert same(maps[row['id']],row['source_sha256']) and same(row['receipt_source_sha256'],row['source_sha256']),('FOUR_INDEPENDENT_MAPS_EXACT_FIXED5448_SUCCESSION',row['id'])
        elif row['id']in nodes['quarter_final']['value']['scenes']:
            native=nodes['quarter_final']['value']['scenes'][row['id']]
            assert same(nodes['quarter_final']['value']['source_sha256'],row['receipt_source_sha256']) and row['scene_path']==native['scene_path'] and row['layout_path']==native['layout_path']
            assert same(row['source_sha256'],original['source_sha256']) and same(row['receipt_source_sha256'],original['receipt_source_sha256'])
        elif row['id']=='luoyang_estate_riverside_20261021ai':
            assert len(row['receipt_source_sha256'])==331 and same(scalar['source_sha256'],row['receipt_source_sha256'])
        elif row['id']=='ch4_s4_ancient_temple':
            assert same(row['source_sha256'],original['source_sha256']) and same(row['receipt_source_sha256'],original['receipt_source_sha256'])
        else:raise AssertionError(('UNKNOWN_OWNER_SCENE',row['id']))
        row['recipe']='Fixed544819 independent complete map plus exact17 existing metadata/header value substitutions only; all source keys, native identity and receipt semantics unchanged. No collector observation.'
        scenes.append(row)
    registry=nodes['registry_final']['value'];rooms=[]
    for original in old['rooms']:
        row=copy.deepcopy(original);row['source_sha256']=replace(original['source_sha256'])
        assert set(row['source_sha256'])==set(original['source_sha256'])
        assert same(registry['rooms'][row['id']]['source_sha256'],original['receipt_source_sha256'])
        assert same(row['receipt_source_sha256'],original['receipt_source_sha256'])
        row['recipe']='Fixed544819 G complete source domain, only existing exact17 header values replaced. Registry and full per-room receipt dictionaries stay byte-equivalent in typed value; no geometry/door/return/source key additions.'
        rooms.append(row)
    assert len(scenes)==8 and len(rooms)==5
    oldunion=merge(*(r[f] for r in old['scenes']+old['rooms'] for f in ['source_sha256','receipt_source_sha256']))
    union=merge(*(r[f] for r in scenes+rooms for f in ['source_sha256','receipt_source_sha256']))
    counts={'changed_target_leaves':0,'matched_actual_stage_source_declarations':0,'unchanged_inherited544819_leaves_not_rehashed':0}
    for path,s in union.items():
        if path in targets:assert targets[path]['candidate_sha256']==s;counts['changed_target_leaves']+=1
        elif path in actual['source_first']:assert actual['source_first'][path]==s;counts['matched_actual_stage_source_declarations']+=1
        else:assert oldunion.get(path)==s,('UNDECLARED_NEW_EXPECTATION',path);counts['unchanged_inherited544819_leaves_not_rehashed']+=1
    core=copy.deepcopy(old['core_source_sha256']);core.update({path:r['candidate_sha256'] for path,r in targets.items()})
    owner={'status':'ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS','actual_stage_receipt':{'path':args.receipt,'sha256':args.sha256},'core_source_sha256':core,'scenes':scenes,'rooms':rooms,'fixed_prior_owner_sha256':PRIOR_SHA,'expected_not_derived_from_live_collector_or_canonical_hash_crawl':True,'not_Field_or_runtime_credit':True,'metadata_fields_not_invented':'All544819 scene/layout/worldsize/native identities inherited.17 Estate registry scalar and metadata/header successors only. Quarter/Temple tables, registry and five whole room receipt maps unchanged; no code/native/door/return/source key changes.'}
    def emit(name,value):
        dest=G/(OUT+name)[6:];assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True);b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
        with dest.open('xb')as f:f.write(b)
        return {'path':OUT+name,'sha256':sha(b)}
    desc=emit('owner_source_maps_READY.json',owner)
    review=emit('source_stage_review_READY.json',{'status':'INDEPENDENT17_BYTE_TYPED_FIXED544819_ESTATE_SCALAR_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT','actual_stage_receipt':owner['actual_stage_receipt'],'owner_source_maps':desc,'source_first_final_same':True,'actual_stage_source_count':len(actual['source_first']),'target_count':17,'partition':actual['target_partition'],'typed_inverse_nodes':typed,'index_byte_inverse_nodes':indices,'expected_union_count':len(union),**counts,'scene_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}for r in scenes},'room_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}for r in rooms},'engine_collector_Stage_native_decode_calls':0})
    print(json.dumps({'owner':desc,'review':review}))
if __name__=='__main__':main()
