"""Actual3 artifact audit only; no compiler import, source collector or image read."""
from pathlib import Path
import copy,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1];S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(p):return GAME/p[6:]
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def same(a,b):return type(a)is type(b)and(a.keys()==b.keys()and all(same(a[k],b[k])for k in a)if isinstance(a,dict)else len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))if isinstance(a,list)else a==b)
def at(v,keys):
    for k in keys:v=v[k]
    return v
rp=S/'outputs/root_market_source_only_tuple3_stage01/receipt.json'
assert sha(rp)=='4c6121af07069bd98b115763ab5e02d7cd8cc2206810b8f9340430708f43a999'
r=rd(rp);spec=rd(S/'performance51_market_tuple3_source_recipe/source_input_ROOT_LOCKED.json')
pins={x['id']:x for x in spec['pinned_inputs']};rows={x['id']:x for x in spec['nodes']};targets={x['target']:x for x in r['targets']}
assert len(targets)==3 and list(targets)==spec['root_target_allowlist']
assert r['source_first']==r['source_final'] and len(r['source_first'])==3004
assert r['target_partition']=={'patch_count':1,'copy_count':2,'total':3,'intersection_empty':True,'union_exact_targets':True}
admission=rd(res(pins[spec['B_only_contract']['admission_input']]['path']));leaves=admission['source_leaves'];assert len(leaves)==2
metadata=indexcount=frozencount=0
for k,row in rows.items():
    v=r['nodes'][k];proof=r['proofs'][k]
    if row['kind']=='tuple3_frozen':
        frozencount+=1;assert v['sha256']==row['immutable_sha256']==pins[row['base_input']]['sha256'] and proof=={'frozen_original_bytes':True,'not_target':True}
        assert sha(res(v['path']))==v['sha256']
        continue
    assert sha(res(v['path']))==v['sha256']
    if 'target'in row:assert targets[row['target']]['candidate_path']==v['path'] and targets[row['target']]['candidate_sha256']==v['sha256']
    if row['kind']=='metadata':
        metadata+=1;original=res(pins[row['base_input']]['path']).read_bytes();before=json.loads(original);after=rd(res(v['path']))
        inverse=copy.deepcopy(after)
        for d in reversed(proof['source_delta']):
            holder=at(inverse,d['pointer'][:-1]);key=d['pointer'][-1]
            if d['existed']:holder[key]=copy.deepcopy(d['old'])
            else:del holder[key]
        assert same(before,inverse)and enc(inverse)==original and same(after,v['value'])and enc(after)==res(v['path']).read_bytes()
        expected=copy.deepcopy(before)
        for field in ['legacy_source_sha256','runtime_authority_sha256','artifacts']:
            for path,tr in targets.items():
                if path in expected[field]:assert expected[field][path]==tr['old_sha256'];expected[field][path]=tr['candidate_sha256']
        for path,digest in leaves.items():
            assert all(path not in before[field]for field in ['legacy_source_sha256','runtime_authority_sha256','artifacts'])
            expected['legacy_source_sha256'][path]=digest
        assert same(expected,after)and proof['whole_typed_inverse']and proof['geometry_native_history_unchanged']
        for pointer in row['protected_pointers']:assert same(at(before,pointer),at(after,pointer))
    elif row['kind']=='index':
        indexcount+=1;before=res(pins[row['base_input']]['path']).read_bytes();disabled=before.decode();resolved=[]
        for h in row['replacements']:
            new=h['new'];new=r['nodes'][new['$sha']]['sha256']if isinstance(new,dict)else new
            assert disabled.count(h['old'])==1;disabled=disabled.replace(h['old'],new,1);resolved.append((h['old'],new))
        assert disabled.encode()==res(v['disabled_path']).read_bytes()
        assert disabled.replace(row['disabled_literal'],row['enabled_literal'],1).encode()==res(v['path']).read_bytes()
        back=disabled
        for a,b in reversed(resolved):assert back.count(b)==1;back=back.replace(b,a,1)
        assert back.encode()==before and proof['disabled_to_enabled_sole_bool_whole_inverse']
assert(metadata,indexcount,frozencount)==(2,1,20)
prior=rd(res(pins[spec['B_only_contract']['prior_owner_input']]['path']))
counts={}
for ident,row in rows.items():
    if row['kind']!='map':continue
    before=next(x for x in prior['scenes']if x['id']==row['scene_id'])['source_sha256'];expected=copy.deepcopy(before)
    for path,tr in targets.items():
        if path in expected:assert expected[path]==tr['old_sha256'];expected[path]=tr['candidate_sha256']
    if row['scene_id']=='ch4_s3_luoyang_market':expected.update(leaves)
    actual=r['nodes'][ident]['value']['source_sha256']
    assert same(actual,expected)and same(rd(res(r['nodes'][ident]['path']))['source_sha256'],expected)
    assert set(actual)-set(before)==(set(leaves)if row['scene_id']=='ch4_s3_luoyang_market'else set())
    counts[row['scene_id']]=len(actual)
assert counts=={'ch4_s0_luoyang_gate':888,'ch4_s1_luoyang_yamen':1239,'ch4_s2_canal_docks':1716,'ch4_s3_luoyang_market':1702}
registry=r['nodes']['registry_final']['value']
for room in prior['rooms']:assert same(registry['rooms'][room['id']]['source_sha256'],room['receipt_source_sha256'])
pp=res(r['patch_path']);assert sha(pp)==r['patch_sha256'];patch=pp.read_text(encoding='utf-8').splitlines(True)
index_target=next(k for k in targets if k.endswith('.gd'));before=res(pins[rows['ap_city_index']['base_input']]['path']).read_text(encoding='utf-8');rebuilt=before
assert sum(x.startswith('*** Update File: ')for x in patch)==1
hunks=[]
for line in patch:
    if line.startswith('@@'):hunks.append([])
    elif line.startswith('***'):continue
    else:assert hunks and line[0]in ' +-';hunks[-1].append(line)
for h in hunks:
    old=''.join(x[1:]for x in h if x[0]in ' -');new=''.join(x[1:]for x in h if x[0]in ' +')
    assert rebuilt.count(old)==1;rebuilt=rebuilt.replace(old,new,1)
assert rebuilt.encode()==res(targets[index_target]['candidate_path']).read_bytes()
cp=res(r['byte_copy_plan']['path']);assert sha(cp)==r['byte_copy_plan']['sha256'];copyplan=rd(cp)
assert len(copyplan['rows'])==2 and set(copyplan['copy_targets']).isdisjoint(copyplan['patch_targets'])and set(copyplan['copy_targets'])|set(copyplan['patch_targets'])==set(targets)
for x in copyplan['rows']:assert x['candidate_sha256']==sha(res(x['candidate_path']))and x['candidate_bytes']==res(x['candidate_path']).stat().st_size
out=QA/'market51_actual4C612_SOURCE_ONLY3_independent_output_admission_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'SOURCE51_ACTUAL_EXACT3_OUTPUTS_INDEPENDENT_NO_MERGE_BLOCKER_NOT_RUNTIME','receipt':{'path':str(rp),'sha256':sha(rp)},'checks':{'3candidateSHAs_exact':True,'2metadata_wholetyped_serialized_inverse_and_only_legacy2_plus_existingheaders':True,'1index_wholebyte_inverse_and_actualpatch_reconstruction':True,'1GD_2JSON_copy_partition_exact':True,'3004_SOURCE_FIRST_FINAL_tables_same_not_rehashed':True,'4maps_fixed5857_plus3headers_onlyMarketnew2_no_observedfill':counts,'20othernodes_frozen_native_geometry_4T_classification_unchanged':True,'registry_and_5whole_roomreceiptmaps_same':True,'RootB1BB_SOURCE_ONLY_exact2_no_runtime_texture_credit':True},'boundaries':['No Stage/recollector/mediahash/decode/engine repeated.','Newowner53 not yet audited; Marketpendingkey staysfalse until independentowner and formaldeployment.','No Market admission/draw/ART/performance claim; Root38FAIL retained.'],'operations':{'Stage':0,'engine':0,'collector':0,'pixel_or_native_decode':0,'large_media_hash':0,'canonical_write':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'counts':counts}))
