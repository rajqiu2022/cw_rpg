"""Future actual29 review and source-only owner successor to fixed65BE.

Do not execute until Root supplies the real stage receipt SHA. No Stage import,
collector, engine, canonical crawl, geometry or source-FIRST reread is involved.
"""
import argparse,copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
OUT=S+'performance36_merged_actual_independent_review/'
PRIOR=S+'performance26_canonical_B_actual_independent_review/owner_source_maps_READY.json'
PRIOR_SHA='65be3de4b1b8d120d76e9f2f62208642a89c12ca6c0331fbebf9d498d688f9be'
PLAN=S+'performance35_merged_source_recipe/source_input_ROOT_LOCKED.json'
PLAN_SHA='e90077daf5c95a22559b6fd82ceff31cf9974cc42be0021e4bbf2e5b1e654d6b'
HAND=S+'performance34_merged_DT_subspan_dependencies/handoff_EXECUTION_AND_SCOPE_PROPOSAL.json'
HAND_SHA='32eef713b78b4bc1595e5b29637b67ee71cecc437303bfcb44b830c831e1283f'
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
    assert args.receipt==S+'outputs/root_merged_G_parentcopy_DT_source_stage01/receipt.json'
    assert not (G/OUT[6:]).exists()
    actual=read(args.receipt,args.sha256);plan=read(PLAN,PLAN_SHA);old=read(PRIOR,PRIOR_SHA);hand=read(HAND,HAND_SHA)
    assert actual['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED' and actual['source_first']==actual['source_final']
    assert actual['source_first'][PLAN]==PLAN_SHA
    assert actual['target_partition']=={'patch_count':15,'copy_count':14,'total':29,'intersection_empty':True,'union_exact_targets':True}
    inputs={r['id']:r for r in plan['pinned_inputs']};c=plan['B_only_contract']
    request=read(inputs[c['scope_request_input']]['path'],inputs[c['scope_request_input']]['sha256'])
    targets={r['target']:r for r in actual['targets']};expected_old={r['target']:r['old_sha256'] for r in request['targets']}
    assert len(targets)==29 and set(targets)==set(plan['root_target_allowlist'])==set(expected_old)
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
        elif n['kind']=='B_only_frozen_node':assert v['sha256']==inputs[n['base_input']]['sha256'] and 'target'not in n
    code=read(hand['whole_inverse_proof']['path'],hand['whole_inverse_proof']['sha256'])
    for record in code['records'].values():
        before=raw(record['parent']['path'],record['parent']['sha256']);candidate=raw(record['candidate']['path'],record['candidate']['sha256']);forward=before;inverse=candidate
        for h in record['hunks']:
            a,b=h['old'].encode(),h['new'].encode();assert forward.count(a)==1 and inverse.count(b)==1;forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
        assert forward==candidate and inverse==before
    # Existing E43B binding remains an execution-history source. NEW binding
    # enters exactly through the nine final execution-proof declarations.
    assert code['records']['temple_binding']['candidate']['path']in hand['new_proof_sources_exact9']
    def replace(values):
        result=copy.deepcopy(values)
        for path,row in targets.items():
            if path in result:
                assert result[path]==row['old_sha256'],('EXACT_INHERITED65BE_OLD_VALUE',path,result[path],row['old_sha256'])
                result[path]=row['candidate_sha256']
        return result
    previous={r['id']:r for r in old['scenes']};scenes=[]
    for n in plan['nodes']:
        if n['kind']=='map':
            row=copy.deepcopy(previous[n['scene_id']]);src=copy.deepcopy(nodes[n['id']]['value']['source_sha256'])
            row.update(source_sha256=src,receipt_source_sha256=copy.deepcopy(src),recipe='Original frozen AO independent map through unchanged validators; actualAP14_35FF plus exact29 merged target/header succession and9 declared proof leaves. Never collector-derived.')
            scenes.append(row)
    quarter=nodes['quarter_final'];header_paths=['res://scripts/city/luoyang_quarters_family_20261022ap.gd','res://scripts/city/luoyang_quarters_index_20261022ap.gd','res://data/maps/luoyang_full_city_20261022ap/quarters/revision4/manifest.json']
    for ident,native in quarter['value']['scenes'].items():
        row=copy.deepcopy(previous[ident]);headers=replace({path:row['source_sha256'][path] for path in header_paths})
        row.update(source_sha256=merge(quarter['value']['source_sha256'],headers),receipt_source_sha256=copy.deepcopy(quarter['value']['source_sha256']),recipe='Fixed65BE Quarter identity/native plus merged source and80 execution-proof/header successor; receipt domain excludes collector header.')
        assert row['scene_path']==native['scene_path'] and row['layout_path']==native['layout_path'];scenes.append(row)
    row=copy.deepcopy(previous['luoyang_estate_riverside_20261021ai']);estate=nodes['estate_final']
    headers=replace({path:s for path,s in row['source_sha256'].items() if path not in row['receipt_source_sha256']})
    assert len(estate['value']['source_sha256'])==len(row['receipt_source_sha256'])==331
    row.update(source_sha256=merge(estate['value']['source_sha256'],headers),receipt_source_sha256=copy.deepcopy(estate['value']['source_sha256']),recipe='Fixed331 Estate keyset only necessary target values and new registry header; native unchanged; no shared new proof group.')
    scenes.append(row)
    row=copy.deepcopy(previous['ch4_s4_ancient_temple']);src=merge(replace(row['source_sha256']),hand['new_proof_sources_exact9'])
    row.update(source_sha256=src,receipt_source_sha256=copy.deepcopy(src),recipe='Fixed65BE complete Temple source domain plus necessary target/header replacements and9 execution proof leaves including NEW C-only binding; native/other188 binding source values unchanged.')
    scenes.append(row)
    registry=nodes['registry_final']['value'];rooms=[]
    for original in old['rooms']:
        row=copy.deepcopy(original);src=merge(replace(row['source_sha256']),hand['new_proof_sources_exact9']);receipt=copy.deepcopy(registry['rooms'][row['id']]['source_sha256'])
        assert same(receipt,replace(row['receipt_source_sha256'])),('REGISTRY_FIVE_DT_ONLY_RECEIPT_SUCCESSION',row['id'])
        row.update(source_sha256=src,receipt_source_sha256=receipt,recipe='Fixed65BE G-family full collector with exact29 target/header and9 proof leaves; per-room receipt only DT source value successor, no native/return mutation.');rooms.append(row)
    assert len(scenes)==8 and len(rooms)==5
    oldunion=merge(*(r[f] for r in old['scenes']+old['rooms'] for f in ['source_sha256','receipt_source_sha256']))
    union=merge(*(r[f] for r in scenes+rooms for f in ['source_sha256','receipt_source_sha256']))
    counts={'changed_target_leaves':0,'matched_actual_stage_source_declarations':0,'unchanged_inherited65BE_leaves_not_rehashed':0}
    for path,s in union.items():
        if path in targets:assert targets[path]['candidate_sha256']==s;counts['changed_target_leaves']+=1
        elif path in actual['source_first']:assert actual['source_first'][path]==s;counts['matched_actual_stage_source_declarations']+=1
        else:assert oldunion.get(path)==s,('UNDECLARED_NEW_EXPECTATION',path);counts['unchanged_inherited65BE_leaves_not_rehashed']+=1
    core=copy.deepcopy(old['core_source_sha256']);core.update({path:r['candidate_sha256'] for path,r in targets.items()})
    owner={'status':'ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS','actual_stage_receipt':{'path':args.receipt,'sha256':args.sha256},'core_source_sha256':core,'scenes':scenes,'rooms':rooms,'fixed_prior_owner_sha256':PRIOR_SHA,'expected_not_derived_from_live_collector_or_canonical_hash_crawl':True,'not_Field_or_runtime_credit':True,'metadata_fields_not_invented':'All65BE scene/layout/worldsize/native identities inherited.29-source successor only,5room DT declarations and new registry header, C-only Temple binding; hash/Family/ENV/Field/Router/Coordinator unchanged.'}
    def emit(name,value):
        dest=G/(OUT+name)[6:];assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True);b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
        with dest.open('xb')as f:f.write(b)
        return {'path':OUT+name,'sha256':sha(b)}
    desc=emit('owner_source_maps_READY.json',owner)
    review=emit('source_stage_review_READY.json',{'status':'INDEPENDENT29_BYTE_TYPED_FIXED65BE_SOURCE_RECIPE_REVIEW_NOT_RUNTIME_OR_DEPLOYMENT','actual_stage_receipt':owner['actual_stage_receipt'],'owner_source_maps':desc,'source_first_final_same':True,'actual_stage_source_count':len(actual['source_first']),'target_count':29,'partition':actual['target_partition'],'typed_inverse_nodes':typed,'index_byte_inverse_nodes':indices,'expected_union_count':len(union),**counts,'scene_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}for r in scenes},'room_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}for r in rooms},'engine_collector_Stage_native_decode_calls':0})
    print(json.dumps({'owner':desc,'review':review}))
if __name__=='__main__':main()
