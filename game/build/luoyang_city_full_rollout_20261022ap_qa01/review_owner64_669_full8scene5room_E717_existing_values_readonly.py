"""Full independent owner-table existing-value inheritance only, not collection."""
from pathlib import Path
import copy
import hashlib
import json

Q=Path(__file__).resolve().parent;G=Q.parents[1];S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return set(a)==set(b) and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def union(owner):
    v={}
    for row in owner['scenes']+owner['rooms']:
        for field in ['source_sha256','receipt_source_sha256']:
            for p,h in row[field].items():assert p not in v or v[p]==h;v[p]=h
    return v
op=S/'performance60_market_parent30_actual_independent_review/owner_source_maps_READY.json'
np=S/'performance64_ground8_actual_independent_review/owner_source_maps_READY.json'
vp=np.with_name('source_stage_review_READY.json')
assert sha(op)=='e7177cb8e97e957bab6f0f88bbcbb5bb5d82de4087f2bb45085d4cf06f2a1f03'
assert sha(np)=='669e5d3e4ece06cf33707d6afdced6d65dc5ca7785b8f44ff19698dde741f7c0'
assert sha(vp)=='cfe5264353ede060100454e510ab1088b91a581fb4648d8554382378a0425a2d'
old,new,review=rd(op),rd(np),rd(vp)
rp=S/'outputs/root_market_ground_exact8_stage01/receipt.json'
assert sha(rp)=='1dff38bf897130d74bb6c0d51b4436fa25d97de9bb8e4502ea8490364262ccfe'
r=rd(rp);targets={x['target']:x for x in r['targets']}
assert len(targets)==8 and new['actual_stage_receipt']['sha256']==sha(rp) and new['fixed_prior_owner_sha256']==sha(op)
assert new['expected_not_derived_from_live_collector_or_canonical_hash_crawl'] and new['not_Field_or_runtime_credit']
def migrate(t):
    v=copy.deepcopy(t)
    for p in v:
        if p in targets:assert v[p]==targets[p]['old_sha256'];v[p]=targets[p]['candidate_sha256']
    return v
whole_unchanged=[];counts={}
for domain in ['scenes','rooms']:
    assert len(old[domain])==len(new[domain])==(8 if domain=='scenes' else 5)
    for a,b in zip(old[domain],new[domain]):
        assert a['id']==b['id']
        for field in ['source_sha256','receipt_source_sha256']:
            assert same(b[field],migrate(a[field])) and set(b[field])==set(a[field])
        expected=copy.deepcopy(a);expected['source_sha256']=migrate(a['source_sha256']);expected['receipt_source_sha256']=migrate(a['receipt_source_sha256']);expected['recipe']=b['recipe']
        assert same(expected,b)
        if domain=='rooms' or a['id'] not in ['ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market']:
            assert same(a,b);whole_unchanged.append(a['id'])
        counts[domain+':'+a['id']]={'collector':len(b['source_sha256']),'receipt':len(b['receipt_source_sha256'])}
assert len(whole_unchanged)==9
assert same(new['core_source_sha256'],migrate(old['core_source_sha256'])) and len(new['core_source_sha256'])==47
assert 'res://scripts/city/luoyang_market_ground_20261020ae.gd' not in new['core_source_sha256']
for node in r['nodes'].values():
    value=node.get('value')
    if isinstance(value,dict) and value.get('scene_id') in ['ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market'] and isinstance(value.get('source_sha256'),dict):
        row=next(x for x in new['scenes'] if x['id']==value['scene_id'])
        # Only expected-map nodes carry this exact declaration envelope.
        if set(value)=={'scene_id','source_sha256'}:assert row['source_sha256']==row['receipt_source_sha256']==value['source_sha256']
oldunion,newunion=union(old),union(new)
assert set(oldunion)==set(newunion) and len(newunion)==2977
u={'changed_target_leaves':0,'matched_actual_stage_source_declarations':0,'unchanged_E717_leaves_not_rehashed':0}
for p,h in newunion.items():
    if p in targets:assert h==targets[p]['candidate_sha256'];u['changed_target_leaves']+=1
    elif p in r['source_first']:assert h==r['source_first'][p];u['matched_actual_stage_source_declarations']+=1
    else:assert h==oldunion[p];u['unchanged_E717_leaves_not_rehashed']+=1
assert u=={'changed_target_leaves':6,'matched_actual_stage_source_declarations':2961,'unchanged_E717_leaves_not_rehashed':10}
for k,v in u.items():assert review[k]==v
out=Q/'owner64_669_full8scene5room_core47_fixedE717_existing8value_review_READY.json'
assert not out.exists()
out.write_text(json.dumps({'status':'INDEPENDENT_OWNER64_ALL8SCENE5ROOM_EXISTING_VALUES_ONLY_NO_RUNTIME_CREDIT',
    'pins':{'owner':sha(np),'source_review':sha(vp),'fixed_E717':sha(op),'actual_Stage':sha(rp)},
    'checks':{'all13_collector_receipt_maps_exact_fixedE717_existing8target_value_migration':True,
        'no_source_key_add_remove_or_new95proof':True,'native_and_nonsource_identities_whole_same':True,
        'other4scene5room_whole_typed_unchanged_including_recipe':whole_unchanged,
        'core47_only_existingvalue_changes_ground_not_added':True,'fourcity_counts898_1249_1726_1712_same':True},
    'counts':counts,'union':{'count':2977,**u},
    'limits':['Expected from fixed independent E717+actual exact8, no current collector fill',
        'Wait Root exact8 formal guard/freshguard before new GUI key freeze; no ART/Field pass'],
    'operations':{'engine':0,'collector':0,'Stage':0,'decode':0,'mediahash':0,'canonical':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'owner_blocker':False}))
