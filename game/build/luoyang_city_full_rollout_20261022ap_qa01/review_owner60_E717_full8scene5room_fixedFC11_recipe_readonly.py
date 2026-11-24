"""Independent expected source recipe, never runtime source collection."""
from pathlib import Path
import copy
import hashlib
import json

Q=Path(__file__).resolve().parent;G=Q.parents[1];S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def res(p):return G/p[6:]
def strict(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return set(a)==set(b) and all(strict(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(strict(x,y) for x,y in zip(a,b))
    return a==b
def merge(*tables):
    v={}
    for t in tables:
        for p,h in t.items():assert p not in v or v[p]==h;v[p]=h
    return v
op=S/'performance54_market_tuple3_actual_independent_review/owner_source_maps_READY.json'
np=S/'performance60_market_parent30_actual_independent_review/owner_source_maps_READY.json'
vp=np.with_name('source_stage_review_READY.json')
assert sha(op)=='fc11a02989c4e9d57628dccaa82c08cd11df6767c954f4ed4829b5dcdffc0f02'
assert sha(np)=='e7177cb8e97e957bab6f0f88bbcbb5bb5d82de4087f2bb45085d4cf06f2a1f03'
assert sha(vp)=='8b03177179bc07f83a26e1af168895bc8fbfb0ac4f0f79a815246a05ddf6beec'
old,new,review=rd(op),rd(np),rd(vp)
rp=S/'outputs/root_market_complete_parent30_stage01/receipt.json'
assert sha(rp)=='464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f'
r=rd(rp);targets={x['target']:x for x in r['targets']}
assert new['actual_stage_receipt']['sha256']==sha(rp) and new['fixed_prior_owner_sha256']==sha(op)
assert new['expected_not_derived_from_live_collector_or_canonical_hash_crawl'] and new['not_Field_or_runtime_credit']
hand=rd(S/'performance57_market_receipt_dependencies/handoff_EXECUTION_PROPOSAL_READY_NOT_STAGED.json')
proofs=hand['new_exact10_proof_pins'];assert len(proofs)==10
def migrate(t):
    v=copy.deepcopy(t)
    for p in v:
        if p in targets:assert v[p]==targets[p]['old_sha256'];v[p]=targets[p]['candidate_sha256']
    return v
a={x['id']:x for x in old['scenes']};b={x['id']:x for x in new['scenes']}
assert len(a)==len(b)==8 and list(a)==list(b)
for ident,prior in a.items():
    row=b[ident]
    for field in ['source_sha256','receipt_source_sha256']:
        expected=migrate(prior[field])
        if ident!='luoyang_estate_riverside_20261021ai':
            assert not set(expected)&set(proofs);expected=merge(expected,proofs)
        assert strict(row[field],expected),(ident,field)
    assert {k:v for k,v in prior.items() if k not in ['source_sha256','receipt_source_sha256','recipe']}=={k:v for k,v in row.items() if k not in ['source_sha256','receipt_source_sha256','recipe']}
for ident in ['ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market']:
    values=next(v['value']['source_sha256'] for k,v in r['nodes'].items() if k.startswith('expected_') and v['value']['scene_id']==ident)
    assert b[ident]['source_sha256']==b[ident]['receipt_source_sha256']==values
quarter=r['nodes']['quarter_final']['value']['source_sha256']
for ident in ['luoyang_artisan_residential_20261022ap','luoyang_riverside_garden_20261022ap']:
    assert b[ident]['receipt_source_sha256']==quarter and len(quarter)==302
assert b['luoyang_estate_riverside_20261021ai']['receipt_source_sha256']==r['nodes']['estate_final']['value']['source_sha256']
rooms={x['id']:x for x in old['rooms']};assert len(rooms)==len(new['rooms'])==5
for row in new['rooms']:
    prior=rooms[row['id']]
    assert strict(row['source_sha256'],merge(migrate(prior['source_sha256']),proofs)) and len(row['source_sha256'])==567
    assert strict(row['receipt_source_sha256'],migrate(prior['receipt_source_sha256']))
    assert row['receipt_source_sha256']==r['nodes']['registry_final']['value']['rooms'][row['id']]['source_sha256']
    assert set(row['receipt_source_sha256'])==set(prior['receipt_source_sha256'])
    assert [p for p in prior['receipt_source_sha256'] if prior['receipt_source_sha256'][p]!=row['receipt_source_sha256'][p]]==['res://scripts/city/luoyang_district_life_20261016f.gd']
    assert {k:v for k,v in prior.items() if k not in ['source_sha256','receipt_source_sha256','recipe']}=={k:v for k,v in row.items() if k not in ['source_sha256','receipt_source_sha256','recipe']}
assert new['core_source_sha256']=={**old['core_source_sha256'],**{p:t['candidate_sha256'] for p,t in targets.items()}} and len(new['core_source_sha256'])==47
union=merge(*(row[f] for row in new['scenes']+new['rooms'] for f in ['source_sha256','receipt_source_sha256']))
oldunion=merge(*(row[f] for row in old['scenes']+old['rooms'] for f in ['source_sha256','receipt_source_sha256']))
counts={'targets':0,'Stage_declared':0,'FC11_inherited_not_rehashed':0}
for p,h in union.items():
    if p in targets:assert h==targets[p]['candidate_sha256'];counts['targets']+=1
    elif p in r['source_first']:assert h==r['source_first'][p];counts['Stage_declared']+=1
    else:assert h==oldunion[p];counts['FC11_inherited_not_rehashed']+=1
assert len(union)==2977 and counts=={'targets':26,'Stage_declared':2945,'FC11_inherited_not_rehashed':6}
scene_counts={row['id']:{'collector':len(row['source_sha256']),'receipt':len(row['receipt_source_sha256'])} for row in new['scenes']}
room_counts={row['id']:{'collector':len(row['source_sha256']),'receipt':len(row['receipt_source_sha256'])} for row in new['rooms']}
assert scene_counts==review['scene_counts'] and room_counts==review['room_counts']
two={'res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision4/publication_assets/walk.png.import','res://.godot/imported/walk.png-eb63fda1eba65c60ad6a24b15599ec76.ctex'}
for row in new['scenes']:
    assert set(row['source_sha256'])&two==(two if row['id']=='ch4_s3_luoyang_market' else set())
out=Q/'owner60_E717_full8scene5room_core47_independent_recipe_admission_READY.json'
assert not out.exists()
out.write_text(json.dumps({
    'status':'INDEPENDENT_OWNER60_FIXED_FC11_PLUS30_EXISTING_VALUES_AND_EXACT10PROOFS_NO_RUNTIME_CREDIT',
    'pins':{'owner':sha(np),'source_review':sha(vp),'fixed_prior_FC11':sha(op),'Stage':sha(rp)},
    'checks':{'all8scene_5room_collector_and_receipt_maps_independently_reconstructed':True,
        'scene_and_room_non_source_identities_whole_same':True,'Estate_no_added_proof_and333_331_source_domain':True,
        'Quarter304collector302receipt_not_mixed':True,'G567_full_source_not_natural_session_source_table':True,
        'five_historical_room_receipt_keysets_same_only_DT_value_migrates':True,
        'core47_oldplus30_existing_values_no_newkeys':True,'Root39SOURCE_ONLY_exact2_only_Market_preserved':True},
    'scene_counts':scene_counts,'room_counts':room_counts,'union':{'count':len(union),**counts},
    'limits':['Expected tables derived from immutable FC11 and actual authorized Stage, not observed collector or current fill',
        'Root deployment guard and exact EOF formatter remain required before runtime test',
        'No Field entrance/ART/wholecity pass; failures remain unchanged'],
    'operations':{'Stage':0,'engine':0,'collector':0,'decode':0,'large_media_hash':0,'canonical':0}
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'expectedMarket':1712,'union':counts}))
