"""Compare actual owner output against fixed544819+explicit17; no collector."""
from pathlib import Path
import copy,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1];S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def same(a,b):return type(a)is type(b)and(a.keys()==b.keys()and all(same(a[k],b[k])for k in a)if isinstance(a,dict)else len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))if isinstance(a,list)else a==b)
priorp=S/'performance43_culture_actual_independent_review/owner_source_maps_READY.json'
newp=S/'performance49_estate17_actual_independent_review/owner_source_maps_READY.json'
revp=newp.with_name('source_stage_review_READY.json')
assert sha(priorp)=='544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0'
assert sha(newp)=='585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f'
assert sha(revp)=='9d366c621019cd4e0230849dd2a21e1baba6ab0618762fea96572c033e6334c0'
old,new,review=rd(priorp),rd(newp),rd(revp)
actual=rd(S/'outputs/root_estate_registry_scalar17_stage01/receipt.json')
assert new['actual_stage_receipt']['sha256']=='96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7'
assert new['fixed_prior_owner_sha256']==sha(priorp)and new['expected_not_derived_from_live_collector_or_canonical_hash_crawl']and new['not_Field_or_runtime_credit']
targets={r['target']:r for r in actual['targets']};assert len(targets)==17
changes={}
for domain in ['scenes','rooms']:
    assert len(new[domain])==len(old[domain])
    for a,b in zip(old[domain],new[domain]):
        assert a['id']==b['id'];inverse=copy.deepcopy(b);inverse['recipe']=a['recipe']
        n=0
        for field in ['source_sha256','receipt_source_sha256']:
            expected=copy.deepcopy(a[field])
            for path,row in targets.items():
                if path in expected:
                    assert expected[path]==row['old_sha256'];expected[path]=row['candidate_sha256']
            assert same(expected,b[field])and set(b[field])==set(a[field])
            n+=sum(a[field][p]!=b[field][p]for p in a[field]);inverse[field]=a[field]
        assert same(a,inverse);changes[domain+':'+a['id']]=n
        if domain=='rooms':assert same(a['receipt_source_sha256'],b['receipt_source_sha256'])and len(b['source_sha256'])==557
    assert len(new[domain])==(8 if domain=='scenes'else 5)
core=copy.deepcopy(old['core_source_sha256']);core.update({p:r['candidate_sha256']for p,r in targets.items()})
assert same(core,new['core_source_sha256'])
assert review['expected_union_count']==2965and review['changed_target_leaves']==13and review['matched_actual_stage_source_declarations']==2942and review['unchanged_inherited544819_leaves_not_rehashed']==10
assert review['actual_stage_source_count']==3017 and review['engine_collector_Stage_native_decode_calls']==0
yamen=next(x for x in new['scenes']if x['id']=='ch4_s1_luoyang_yamen')
assert len(yamen['source_sha256'])==len(yamen['receipt_source_sha256'])==1239
for row in new['scenes']:
    if row['id']in ['luoyang_artisan_residential_20261022ap','luoyang_riverside_garden_20261022ap','ch4_s4_ancient_temple']:
        assert changes['scenes:'+row['id']]==0
    if row['id']=='luoyang_estate_riverside_20261021ai':assert len(row['receipt_source_sha256'])==331
out=QA/'estate49_owner5857_independent_fixed5448_plus17_review_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'ESTATE49_OWNER5857_INDEPENDENT_FIXED544819_PLUS17_APPROVED_RECIPE_NOT_RUNTIME','owner':{'path':str(newp),'sha256':sha(newp)},'source_review_sha256':sha(revp),'checks':{'all8scene5room_native_identity_and_non_source_fields_same':True,'whole_expected_maps_fixed544819_plus17_existing_values_only':True,'source_keysets_unchanged_newproof0':True,'core_exact_prior_plus17':True,'Yamen1239':True,'G557_independent_intended_global_guard_not_old_runtime_receipt':True,'all5_room_receipt_maps_whole_same':True,'QuarterTemple_maps_whole_same':True,'Estate331_receipt_whole_same':True,'union2965_13changed2942Stage10inherited_not_rehashed':True},'value_changes_both_collector_receipt_counted':changes,'boundaries':['No collector/G/catalogue/session method invoked.','Hall34FAIL and missingdoor retained; metadata publication does not give runtimeadmission credit.','Root36 deployment/Root37 fresh authority still required before test freeze.'],'operations':{'engine':0,'collector':0,'Stage':0,'native_or_image_decode':0,'big_media_hash':0,'canonical_write':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out)}))
