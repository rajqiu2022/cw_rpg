"""Fixed owner72 + future actual94 exact21 outputs. Root-only, NOT RUN here.

No Stage import, collector, native/image decoding, canonical crawl, or large
source rehash. Receipt SHA is a required Root argument, never fabricated.
"""
import argparse,copy,hashlib,json,re
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
OUT=S+'performance95_Docks_ordinary21_actual_independent_review/'
PRIOR=S+'performance72_A1_ENV18_actual_independent_review/owner_source_maps_READY.json'
PRIOR_SHA='3715a958d0f9ee71d1ffdbe823ddcbd066d7613e2f5748d0e96e4bd25ed7e666'
PLAN=R+'integration57/source_input94_ROOT_LOCKED.json'
PLAN_SHA='4e148220acecb59624c32401981431d1cf341db705ed0635f9c2222a981d0a2d'
RECEIPT=S+'outputs/root_Docks_ordinary21_stage02/receipt.json'
AA='res://scripts/city/luoyang_docks_district08_20261019aa.gd'
AC='res://scripts/city/luoyang_docks_workyard_20261019ac.gd'
EXE='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
DOCKS='ch4_s2_canal_docks'
def sha(b):return hashlib.sha256(b).hexdigest()
def raw(path,expected):
    assert path.startswith('res://')and'..'not in path
    b=(G/path[6:]).read_bytes();assert sha(b)==expected,('PIN_CHANGED',path);return b
def read(path,expected):return json.loads(raw(path,expected))
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
def ptr(v,keys):
    for k in keys:v=v[k]
    return v
def encode(v):return(json.dumps(v,ensure_ascii=False,indent=2,allow_nan=False)+'\n').encode()
def merge(*tables):
    result={}
    for table in tables:
        for p,s in table.items():assert p not in result or result[p]==s;result[p]=s
    return result
def replay(text,chunks):
    cursor=0;out=[]
    for old,new in chunks:
        found=text.find(old,cursor);assert found>=0
        out.extend([text[cursor:found],new]);cursor=found+len(old)
    return ''.join(out)+text[cursor:]
def literal_patch_sections(data):
    lines=data.decode('utf-8').splitlines(True)
    assert lines[0]=='*** Begin Patch\n'and lines[-1]=='*** End Patch\n'
    sections={};target=None;body=[]
    for line in lines[1:-1]:
        if line.startswith('*** Update File: '):
            if target is not None:sections[target]=body
            p=Path(line[len('*** Update File: '):].strip()).resolve();assert p.is_relative_to(G)
            target='res://'+p.relative_to(G).as_posix();assert target not in sections;body=[]
        else:assert target is not None and not line.startswith('***');body.append(line)
    if target is not None:sections[target]=body
    result={}
    for target,body in sections.items():
        chunks=[];left=[];right=[]
        for line in body:
            if line=='@@\n':
                if left or right:chunks.append((''.join(left),''.join(right)))
                left=[];right=[];continue
            assert line and line[0]in' +-'
            if line[0]in' -':left.append(line[1:])
            if line[0]in' +':right.append(line[1:])
        if left or right:chunks.append((''.join(left),''.join(right)))
        result[target]=chunks
    return result
def main():
    parser=argparse.ArgumentParser();parser.add_argument('--receipt',default=RECEIPT);parser.add_argument('--sha256',required=True);args=parser.parse_args()
    assert args.receipt==RECEIPT and re.fullmatch('[0-9a-f]{64}',args.sha256)and not(G/OUT[6:]).exists()
    actual=read(RECEIPT,args.sha256);plan=read(PLAN,PLAN_SHA);old=read(PRIOR,PRIOR_SHA)
    assert actual['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED'and actual['source_first']==actual['source_final']and actual['source_first'][PLAN]==PLAN_SHA
    assert actual['target_partition']=={'patch_count':9,'copy_count':12,'total':21,'intersection_empty':True,'union_exact_targets':True}
    inputs={r['id']:r for r in plan['pinned_inputs']};c=plan['B_only_contract'];scope=read(inputs[c['scope_input']]['path'],inputs[c['scope_input']]['sha256']);back=read(inputs[c['backup_input']]['path'],inputs[c['backup_input']]['sha256'])
    saved={r['path']:r for r in back['targets']};expected_old={r['path']:r['old_sha256']for r in scope['proposed_targets']};targets={r['target']:r for r in actual['targets']}
    assert len(targets)==len(saved)==21 and set(targets)==set(expected_old)==set(plan['root_target_allowlist'])and back['counts']=={'targets':21,'GD':9,'JSON':12}
    oldDocks=next(r for r in old['scenes']if r['id']==DOCKS)['source_sha256'];before_bytes={};candidate_bytes={}
    for path,row in targets.items():
        assert row['old_sha256']==expected_old[path]==saved[path]['sha256']==(oldDocks[path]if path==AA else old['core_source_sha256'][path])and row['old_sha256']!=row['candidate_sha256']
        before_bytes[path]=raw(saved[path]['backup'],row['old_sha256']);assert len(before_bytes[path])==saved[path]['bytes'];candidate_bytes[path]=raw(row['candidate_path'],row['candidate_sha256'])
    parent=read(inputs[c['parent_execution_input']]['path'],inputs[c['parent_execution_input']]['sha256']);authority=read(inputs[plan['authority_input']]['path'],inputs[plan['authority_input']]['sha256']);codes=read(inputs[c['inverse_input']]['path'],inputs[c['inverse_input']]['sha256'])['records']
    assert inputs[c['parent_execution_input']]['sha256']=='6479498491300cc6563deb8a107dc5450c024c2809d0126ace05a0a85a59b2a3'and inputs[plan['authority_input']]['sha256']=='d184d50821f11bf012bd34baac374c4939fdfa5c51f6c415d31e249bbc8a6f29'
    assert len(parent['owned'])==len(authority['owned'])==10 and set(parent['owned'])==set(authority['owned'])and AA not in authority['owned']and 'res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd'not in authority['owned']
    edge=authority['owned'][AC]['edges'][-1];assert same(authority['owned'][AC]['edges'][:-1],parent['owned'][AC]['edges'])and edge['old_sha256']==parent['owned'][AC]['current_sha256']and edge['new_sha256']==authority['owned'][AC]['current_sha256']==codes['AC']['candidate']['sha256']and same(edge['replacements'],codes['AC']['hunks'])
    assert all(same(row,authority['owned'][path])for path,row in parent['owned'].items()if path!=AC)
    extra={p:s for p,s in authority['source_sha256'].items()if p not in parent['source_sha256']};assert extra=={codes['AC']['candidate']['path']:codes['AC']['candidate']['sha256']}and len(parent['source_sha256'])==95 and len(authority['source_sha256'])==96
    restored=copy.deepcopy(authority);restored['owned'][AC]=copy.deepcopy(parent['owned'][AC]);restored['source_sha256']=copy.deepcopy(parent['source_sha256']);assert same(restored,parent)and encode(restored)==raw(inputs[c['parent_execution_input']]['path'],inputs[c['parent_execution_input']]['sha256'])
    assert candidate_bytes[EXE]==encode(authority)
    ordinary=c['ordinary_Docks_only_pins'];assert len(ordinary)==2
    for p,s in ordinary.items():raw(p,s)
    code_inverse=[]
    for name,r in codes.items():
        before=before_bytes[r['target']];after=candidate_bytes[r['target']];assert sha(after)==r['candidate']['sha256']and len(after)==r['candidate']['bytes'];forward=before;inverse=after
        for h in r['hunks']:
            a,b=h['old'].encode(),h['new'].encode();assert forward.count(a)==inverse.count(b)==1;forward=forward.replace(a,b,1);inverse=inverse.replace(b,a,1)
        assert forward==after and inverse==before;code_inverse.append(name)
    nodes=actual['nodes'];typed=[];indices=[]
    for n in plan['nodes']:
        ident=n['id'];v=nodes[ident]
        if n['kind']=='ordinary_frozen':assert v['sha256']==inputs[n['base_input']]['sha256']and'target'not in n;continue
        if n['kind']in['map','ordinary_execution']:continue
        data=raw(v['path'],v['sha256'])
        if n['kind']=='metadata':
            before=read(inputs[n['base_input']]['path'],inputs[n['base_input']]['sha256']);inverse=copy.deepcopy(v['value'])
            for d in reversed(actual['proofs'][ident]['source_delta']):
                holder,key=ptr(inverse,d['pointer'][:-1]),d['pointer'][-1]
                if d['existed']:holder[key]=d['old']
                else:del holder[key]
            assert same(inverse,before)and same(json.loads(data),v['value']);typed.append(ident)
            expected=copy.deepcopy(before);fields=n['source_bundle']['fields']if'source_bundle'in n else[f['pointer']for f in n.get('source_fields',[])]
            for keys in fields:
                values=ptr(expected,keys)
                for path,row in targets.items():
                    if path in values:assert values[path]==row['old_sha256'];values[path]=row['candidate_sha256']
            expected['source_sha256'if ident=='quarter_final'else'legacy_source_sha256'].update(extra)
            if ident in['legacy_manifest_4','legacy_manifest_6','legacy_manifest_7']:expected['legacy_source_sha256'].update(ordinary)
            assert same(expected,v['value']),('EXACT21_METADATA_DOMAIN',ident)
        elif n['kind']=='index':
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
        else:raise AssertionError(n['kind'])
    assert len(typed)==11 and len(indices)==7 and set(code_inverse)=={'AA','AC'}
    sections=literal_patch_sections(raw(actual['patch_path'],actual['patch_sha256']));gd={p for p in targets if p.endswith('.gd')};assert set(sections)==gd and len(gd)==9
    for p,chunks in sections.items():assert replay(before_bytes[p].decode(),chunks).encode()==candidate_bytes[p]and replay(candidate_bytes[p].decode(),[(b,a)for a,b in chunks]).encode()==before_bytes[p]
    copies=read(actual['byte_copy_plan']['path'],actual['byte_copy_plan']['sha256'])['rows'];assert len(copies)==12 and {r['target']for r in copies}=={p for p in targets if p.endswith('.json')}
    for row in copies:assert row['candidate_sha256']==targets[row['target']]['candidate_sha256']and row['candidate_path']==targets[row['target']]['candidate_path']and row['candidate_bytes']==len(candidate_bytes[row['target']])
    def replace(values):
        result=copy.deepcopy(values)
        for p,row in targets.items():
            if p in result:assert result[p]==row['old_sha256'];result[p]=row['candidate_sha256']
        assert result.keys()==values.keys();return result
    owner=copy.deepcopy(old);owner['actual_stage_receipt']={'path':RECEIPT,'sha256':args.sha256};owner['fixed_prior_owner_sha256']=PRIOR_SHA;maps={n['scene_id']:nodes[n['id']]['value']['source_sha256']for n in plan['nodes']if n['kind']=='map'}
    for family in['scenes','rooms']:
        for row,prior in zip(owner[family],old[family]):
            for field in['source_sha256','receipt_source_sha256']:
                row[field]=replace(prior[field]);added={}
                if EXE in prior[field]:added.update(extra)
                if row['id']==DOCKS:added.update(ordinary)
                assert not(set(added)&set(prior[field]));row[field].update(added);assert set(row[field])==set(prior[field])|set(added)
            if row['id']in maps:assert same(row['source_sha256'],maps[row['id']])and same(row['source_sha256'],row['receipt_source_sha256'])
            if family=='rooms':assert same(row['receipt_source_sha256'],prior['receipt_source_sha256'])and len(row['source_sha256'])==568
    assert len(owner['scenes'])==8 and len(owner['rooms'])==5
    assert {r['id']:len(r['source_sha256'])for r in owner['scenes']if r['id']in maps}=={'ch4_s0_luoyang_gate':899,'ch4_s1_luoyang_yamen':1250,DOCKS:1729,'ch4_s3_luoyang_market':1714}
    for ident,a,b in[('luoyang_artisan_residential_20261022ap',305,303),('luoyang_riverside_garden_20261022ap',305,303),('ch4_s4_ancient_temple',393,393)]:
        row=next(r for r in owner['scenes']if r['id']==ident);assert len(row['source_sha256'])==a and len(row['receipt_source_sha256'])==b
    assert same(next(r for r in owner['scenes']if r['id']=='luoyang_estate_riverside_20261021ai'),next(r for r in old['scenes']if r['id']=='luoyang_estate_riverside_20261021ai'))
    owner['core_source_sha256']=replace(old['core_source_sha256']);assert len(owner['core_source_sha256'])==47 and AA not in owner['core_source_sha256']and not(set(extra)|set(ordinary))&set(owner['core_source_sha256'])
    owner['metadata_fields_not_invented']='Fixed owner72 complete8scene5room/core47 plus exact21 existing source values. Execution API consumers acquire only one new AC snapshot; onlyDocks additionally acquires two ordinary source proofs. Estate333/331,registry and five room receipts unchanged; C/AA nonowned; original authors/native/doors/tasks/MarketSOURCE_ONLY2 retained.'
    oldunion=merge(*(r[f]for r in old['scenes']+old['rooms']for f in['source_sha256','receipt_source_sha256']));union=merge(*(r[f]for r in owner['scenes']+owner['rooms']for f in['source_sha256','receipt_source_sha256']));assert set(union)==set(oldunion)|set(extra)|set(ordinary)
    counts={'changed_target_leaves':0,'matched_actual_stage_source_declarations':0,'unchanged_fixed72_leaves_not_rehashed':0}
    for p,s in union.items():
        if p in targets:assert s==targets[p]['candidate_sha256'];counts['changed_target_leaves']+=1
        elif p in actual['source_first']:assert s==actual['source_first'][p];counts['matched_actual_stage_source_declarations']+=1
        else:assert s==oldunion[p];counts['unchanged_fixed72_leaves_not_rehashed']+=1
    def emit(name,value):
        dest=G/(OUT+name)[6:];assert not dest.exists();dest.parent.mkdir(parents=True,exist_ok=True);data=encode(value)
        with dest.open('xb')as f:f.write(data)
        return{'path':OUT+name,'sha256':sha(data)}
    description=emit('owner_source_maps_READY.json',owner)
    review=emit('source_stage_review_READY.json',{'status':'INDEPENDENT_ACTUAL94_EXACT21_FIXED_OWNER72_SOURCE_MAPS_NOT_RUNTIME','actual_stage_receipt':owner['actual_stage_receipt'],'owner_source_maps':description,'partition':actual['target_partition'],'execution_whole_typed_byte_inverse':True,'execution95to96_onlyACedge':True,'metadata_typed_inverse':typed,'index_byte_inverse':indices,'code_whole_byte_inverse':code_inverse,'all_nine_actual_patch_sections_forward_inverse':True,'all_twelve_exact_JSON_copy_rows':True,'source_first_final_declaration_same':True,'expected_union_old_count':len(oldunion),'expected_union_count':len(union),**counts,'scene_counts':{r['id']:{'collector':len(r['source_sha256']),'receipt':len(r['receipt_source_sha256'])}for r in owner['scenes']},'five_room_receipts_unchanged':True,'Estate_registry_Temple_binding_frozen':True,'core47_keys_no_new_AA_or_proof':True,'engine_Stage_collector_native_media_calls':0})
    print(json.dumps({'owner':description,'review':review}))
if __name__=='__main__':main()
