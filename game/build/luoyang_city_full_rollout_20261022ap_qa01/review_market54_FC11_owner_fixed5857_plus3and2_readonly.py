"""Compare every independent owner table; never collect runtime sources."""
from pathlib import Path
import copy,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1];S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def same(a,b):return type(a)is type(b)and(a.keys()==b.keys()and all(same(a[k],b[k])for k in a)if isinstance(a,dict)else len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))if isinstance(a,list)else a==b)
op=S/'performance49_estate17_actual_independent_review/owner_source_maps_READY.json';np=S/'performance54_market_tuple3_actual_independent_review/owner_source_maps_READY.json';vp=np.with_name('source_stage_review_READY.json')
assert sha(op)=='585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f'
assert sha(np)=='fc11a02989c4e9d57628dccaa82c08cd11df6767c954f4ed4829b5dcdffc0f02'
assert sha(vp)=='b09ada8b5d0f2c8949ff6c069a3d0bc4b13bdbdecdb107bdf9a74d80eda07d48'
old,new,review=rd(op),rd(np),rd(vp)
stage=rd(S/'outputs/root_market_source_only_tuple3_stage01/receipt.json');tr={r['target']:r for r in stage['targets']}
admission=rd(GAME/'build/luoyang_city_full_rollout_20261022ap_root01/integration39/source_only_two_leaf_admission.json');leaves=admission['source_leaves']
assert len(tr)==3 and len(leaves)==2 and new['actual_stage_receipt']['sha256']=='4c6121af07069bd98b115763ab5e02d7cd8cc2206810b8f9340430708f43a999'
assert new['fixed_prior_owner_sha256']==sha(op)and new['expected_not_derived_from_live_collector_or_canonical_hash_crawl']and new['not_Field_or_runtime_credit']
domainchanges={}
for domain in ['scenes','rooms']:
    assert len(old[domain])==len(new[domain])==(8 if domain=='scenes'else 5)
    for a,b in zip(old[domain],new[domain]):
        assert a['id']==b['id'];back=copy.deepcopy(b);back['recipe']=a['recipe'];n=0
        for field in ['source_sha256','receipt_source_sha256']:
            expected=copy.deepcopy(a[field])
            for p,row in tr.items():
                if p in expected:assert expected[p]==row['old_sha256'];expected[p]=row['candidate_sha256']
            if domain=='scenes'and a['id']=='ch4_s3_luoyang_market':assert not set(expected)&set(leaves);expected.update(leaves)
            assert same(b[field],expected)
            assert set(b[field])-set(a[field])==(set(leaves)if domain=='scenes'and a['id']=='ch4_s3_luoyang_market'else set())
            n+=sum(a[field].get(p)!=h for p,h in b[field].items());back[field]=a[field]
        assert same(a,back);domainchanges[domain+':'+a['id']]=n
        if domain=='rooms':assert same(a['receipt_source_sha256'],b['receipt_source_sha256'])and len(b['source_sha256'])==557
core=copy.deepcopy(old['core_source_sha256']);core.update({p:r['candidate_sha256']for p,r in tr.items()})
assert same(new['core_source_sha256'],core)and len(core)==47
assert review['expected_union_count']==2967 and review['changed_target_leaves']==3 and review['matched_actual_stage_source_declarations']==2954 and review['unchanged_inherited585717_leaves_not_rehashed']==10
assert review['actual_stage_source_count']==3004 and review['engine_collector_Stage_native_decode_calls']==0
assert review['scene_counts']['ch4_s3_luoyang_market']=={'collector':1702,'receipt':1702}
out=QA/'market54_FC11_owner_independent_full8scene5room_recipe_review_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'OWNER54_FC11_FULL8SCENE5ROOM_FIXED5857_PLUS3HEADER_MARKET2_RECIPE_APPROVED_NOT_RUNTIME','owner_sha256':sha(np),'review_sha256':sha(vp),'checks':{'all8scene5room_source_and_receipt_tables_exact_explicit_recipe':True,'non_source_identity_and_native_fields_whole_same':True,'onlyMarket_keyset_plus2_SOURCE_ONLY_B1BB_no_otherkeys':True,'all5whole_roomreceiptmaps_same':True,'core47_exactprior_plus3headers_no_newproof':True,'union2967_3changed2954Stage10inherited_not_rehashed':True,'no_collector_or_currentfill':True},'table_value_changes_both_domains_counted':domainchanges,'operations':{'engine':0,'collector':0,'Stage':0,'decode':0,'canonical_write':0},'limits':['53selectorbug was caught beforeexecution;54metadata output reviewed, no53runtimefailure invented.','No Marketload/ART/performance evidence yet; Root38FAIL retained.']},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out)}))
