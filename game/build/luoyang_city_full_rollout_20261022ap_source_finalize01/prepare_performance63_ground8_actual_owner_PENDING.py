"""Pending actual62: fixedE717 plus eight existing-value successors, no newkeys.

Root must mechanically freeze the real receipt SHA/output in a NEW successor.
Never Stage/import/collector/current-canonical crawl/native load or fullsource rehash.
"""
import argparse,copy,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
OUT=S+'performance63_ground8_actual_independent_review_PENDING/'
PRIOR=S+'performance60_market_parent30_actual_independent_review/owner_source_maps_READY.json'
PRIOR_SHA='e7177cb8e97e957bab6f0f88bbcbb5bb5d82de4087f2bb45085d4cf06f2a1f03'
PLAN=S+'performance62_ground8_source_recipe/source_input_ROOT_LOCKED.json'
PLAN_SHA='48d8f26e1b16cfde0636feab432a21ec20e137279ac9b1e9c5bae02b2e4ff277'
FIXED_RECEIPT_SHA='PENDING_ROOT_ACTUAL62_RECEIPT_SHA_DO_NOT_RUN'
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
    ap=argparse.ArgumentParser();ap.add_argument('--receipt',required=True);ap.add_argument('--sha256',required=True);args=ap.parse_args()
    assert len(FIXED_RECEIPT_SHA)==64 and all(c in'0123456789abcdef'for c in FIXED_RECEIPT_SHA),'PENDING_NOT_RUNNABLE'
    assert args.receipt==S+'outputs/root_market_ground_exact8_stage01/receipt.json'and args.sha256==FIXED_RECEIPT_SHA
    assert not(G/OUT[6:]).exists()
    actual=read(args.receipt,args.sha256);plan=read(PLAN,PLAN_SHA);old=read(PRIOR,PRIOR_SHA)
    assert actual['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED'and actual['source_first']==actual['source_final']and actual['source_first'][PLAN]==PLAN_SHA
    assert actual['target_partition']=={'patch_count':4,'copy_count':4,'total':8,'intersection_empty':True,'union_exact_targets':True}
    inputs={r['id']:r for r in plan['pinned_inputs']};c=plan['B_only_contract']
    scope=read(inputs[c['scope_input']]['path'],inputs[c['scope_input']]['sha256'])
    backups=read(inputs[c['backup_input']]['path'],inputs[c['backup_input']]['sha256'])
    saved={'res://'+Path(r['path']).resolve().relative_to(G).as_posix():r for r in backups['targets']}
    targets={r['target']:r for r in actual['targets']};expected_old={r['target']:r['old_sha256']for r in scope['targets']}
    assert len(targets)==len(saved)==8 and set(targets)==set(expected_old)==set(plan['root_target_allowlist'])
    for path,row in targets.items():
        assert row['old_sha256']==expected_old[path]==saved[path]['sha256']and row['old_sha256']!=row['candidate_sha256']
        raw(row['candidate_path'],row['candidate_sha256'])
    nodes=actual['nodes'];typed=[];indices=[];ground=[]
    for n in plan['nodes']:
        ident=n['id'];v=nodes[ident]
        if n['kind']=='ground8_frozen':
            assert v['sha256']==inputs[n['base_input']]['sha256']and'target'not in n;continue
        if n['kind']=='map':continue
        data=raw(v['path'],v['sha256'])
        if n['kind']=='metadata':
            parent=read(inputs[n['base_input']]['path'],inputs[n['base_input']]['sha256']);inverse=copy.deepcopy(v['value'])
            for d in reversed(actual['proofs'][ident]['source_delta']):
                holder,key=ptr(inverse,d['pointer'][:-1]),d['pointer'][-1]
                if d['existed']:holder[key]=d['old']
                else:del holder[key]
            assert same(inverse,parent)and same(json.loads(data),v['value']);typed.append(ident)
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
        elif n['kind']=='ground8_code':
            proof=read(inputs[c['proof_input']]['path'],inputs[c['proof_input']]['sha256']);backup=saved[n['target']]
            oldpath='res://'+Path(backup['backup_path']).resolve().relative_to(G).as_posix();before=raw(oldpath,backup['sha256'])
            insert=proof['hunks'][0]['new'].encode();h=proof['hunks'][1];a,b=h['old'].encode(),h['new'].encode();anchor=b'static func prepare('
            assert before.count(anchor)==1 and before.replace(anchor,insert+anchor,1).count(a)==1
            assert before.replace(anchor,insert+anchor,1).replace(a,b,1)==data and data.count(b)==data.count(insert)==1
            assert data.replace(b,a,1).replace(insert,b'',1)==before;ground.append(ident)
        else:raise AssertionError(('UNEXPECTED_CHANGED_KIND',n['kind']))
    assert len(typed)==4 and len(indices)==3 and ground==['ground_code']
    def replace(values):
        result=copy.deepcopy(values)
        for path,row in targets.items():
            if path in result:
                assert result[path]==row['old_sha256'],('FIXED_E717_OLD',path)
                result[path]=row['candidate_sha256']
        assert set(result)==set(values);return result
    owner=copy.deepcopy(old);owner['actual_stage_receipt']={'path':args.receipt,'sha256':args.sha256};owner['fixed_prior_owner_sha256']=PRIOR_SHA
    maps={n['scene_id']:nodes[n['id']]['value']['source_sha256']for n in plan['nodes']if n['kind']=='map'}
    for family in ['scenes','rooms']:
        for row,prior in zip(owner[family],old[family]):
            for field in ['source_sha256','receipt_source_sha256']:row[field]=replace(prior[field])
            if row['id']in maps:assert same(row['source_sha256'],maps[row['id']])and same(row['source_sha256'],row['receipt_source_sha256'])
            else:assert same(row,prior),('NON_C_DOMAIN_WHOLE_TYPED_UNCHANGED',row['id'])
    assert len(owner['scenes'])==8 and len(owner['rooms'])==5
    assert {r['id']:len(r['source_sha256'])for r in owner['scenes']if r['id']in maps}=={'ch4_s0_luoyang_gate':898,'ch4_s1_luoyang_yamen':1249,'ch4_s2_canal_docks':1726,'ch4_s3_luoyang_market':1712}
    owner['core_source_sha256']=replace(old['core_source_sha256']);assert len(owner['core_source_sha256'])==len(old['core_source_sha256'])==47
    groundpath=next(n['target']for n in plan['nodes']if n['kind']=='ground8_code');assert groundpath not in owner['core_source_sha256']
    owner['metadata_fields_not_invented']='FixedE717 full8scene5room/core47 existing source values only. Four C full maps from originalAO rules are checked independently. Ground is nonowned and only Market; no execution/proofkeys/registry/roomreceipt/native changes.'
    oldunion=merge(*(r[f]for r in old['scenes']+old['rooms']for f in ['source_sha256','receipt_source_sha256']))
    union=merge(*(r[f]for r in owner['scenes']+owner['rooms']for f in ['source_sha256','receipt_source_sha256']));assert set(union)==set(oldunion)
    counts={'changed_target_leaves':0,'matched_actual_stage_source_declarations':0,'unchanged_E717_leaves_not_rehashed':0}
    for path,s in union.items():
        if path in targets:assert s==targets[path]['candidate_sha256'];counts['changed_target_leaves']+=1
        elif path in actual['source_first']:assert s==actual['source_first'][path];counts['matched_actual_stage_source_declarations']+=1
        else:assert s==oldunion[path];counts['unchanged_E717_leaves_not_rehashed']+=1
    def emit(name,value):
        dest=G/(OUT+name)[6:];assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True);b=(json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode()
        with dest.open('xb')as f:f.write(b)
        return{'path':OUT+name,'sha256':sha(b)}
    desc=emit('owner_source_maps_READY.json',owner)
    review=emit('source_stage_review_READY.json',{'status':'INDEPENDENT_GROUND8_FIXED_E717_EXISTING_VALUE_INHERITANCE_NOT_RUNTIME_OR_DEPLOYMENT','actual_stage_receipt':owner['actual_stage_receipt'],'owner_source_maps':desc,'target_count':8,'partition':actual['target_partition'],'metadata_typed_inverse':typed,'index_byte_inverse':indices,'ground_byte_inverse':ground,'source_first_final_declaration_same':True,'expected_union_keys_unchanged':True,'expected_union_count':len(union),**counts,'four_C_counts':{r['id']:len(r['source_sha256'])for r in owner['scenes']if r['id']in maps},'other4scene5room_whole_typed_same':True,'core47_keys_unchanged_ground_not_added':True,'engine_Stage_collector_packet_media_calls':0})
    print(json.dumps({'owner':desc,'review':review}))
if __name__=='__main__':main()
