"""Reconstruct expected source ownership from frozen1292 plus approved deltas."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01';QA=Path(__file__).parent
def sha(b):return hashlib.sha256(b).hexdigest()
def res(p):
    assert p.startswith('res://');q=(ROOT/p[6:]).resolve();assert q.is_relative_to(ROOT);return q
def load(p,h):
    b=p.read_bytes();assert sha(b)==h;return json.loads(b)
def same(a,b):
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
op=SF/'performance08_actual_independent_review/owner_source_maps_READY.json'
o=load(op,'9d004ac904f42807af3bc5dda757430200f7bebbdaa1ef29487911417e282551')
review=load(op.with_name('source_stage_review_READY.json'),'89ee91312743f60e8810ca24eb4cd7def0af9e43a0c911892222b36a74e20152')
old=load(SF/'a2_source_recipe08/actual_independent_review/owner_source_maps_READY.json','12924be9ea2c6a081b4865354d40075caa10e3804ad6c942e972f0270bd5219a')
stage=load(SF/'outputs/root_performance05_source_stage01/receipt.json','d0583b4ca4b6ef8703d73efb1e5487ea7a62866cb738d756eb262d6e0419a282')
authority=load(SF/'performance05_dependencies/execution_successor_PROPOSAL.json','428a3484e0a995803d95677dbd36f545313c622142605fce292ffd493b6bea03')
spec=load(SF/'performance07_source_recipe/source_input_ROOT_LOCKED.json','1e40d5b252afd5246f78cc14a00ea541cdd940cb31011077d26105cf12842d95')
pins={r['id']:r for r in spec['pinned_inputs']};p=pins[spec['performance_contract']['parent_approval_input']]
prior=load(res(p['path']),p['sha256']);proofs={p:h for p,h in authority['source_sha256'].items()if p not in prior['source_sha256']};assert len(proofs)==4
targets={r['target']:r for r in stage['targets']};assert len(targets)==26
def migrate(src,add=False):
    v=copy.deepcopy(src)
    for p in v:
        if p in targets:assert v[p]==targets[p]['old_sha256'];v[p]=targets[p]['candidate_sha256']
    if add:
        for p,h in proofs.items():assert p not in v;v[p]=h
    return v
assert o['status']=='ROOT_ACTUAL_STAGE_INDEPENDENT_QA_SOURCE_MAPS' and o['fixed_prior_owner_sha256']==sha((SF/'a2_source_recipe08/actual_independent_review/owner_source_maps_READY.json').read_bytes())
assert o['actual_stage_receipt']==review['actual_stage_receipt'] and o['actual_stage_receipt']['sha256']=='d0583b4ca4b6ef8703d73efb1e5487ea7a62866cb738d756eb262d6e0419a282'
assert o['expected_not_derived_from_live_collector_or_canonical_hash_crawl'] and o['not_Field_or_runtime_credit']
rows={r['id']:r for r in o['scenes']};bases={r['id']:r for r in old['scenes']};assert len(rows)==8 and rows.keys()==bases.keys()
estate='luoyang_estate_riverside_20261021ai'
for sid,row in rows.items():
    base=bases[sid]
    for key in base:
        if key not in ('source_sha256','receipt_source_sha256','recipe'):assert same(row[key],base[key]),(sid,key)
    add=sid!=estate
    assert same(row['source_sha256'],migrate(base['source_sha256'],add)),(sid,'collector')
    assert same(row['receipt_source_sha256'],migrate(base['receipt_source_sha256'],add)),(sid,'receipt')
    if sid.startswith('ch4_s')and sid!='ch4_s4_ancient_temple':
        node=next(n for n in stage['nodes'].values()if isinstance(n.get('value'),dict)and n['value'].get('scene_id')==sid)
        assert same(row['source_sha256'],node['value']['source_sha256'])
for sid in ['luoyang_artisan_residential_20261022ap','luoyang_riverside_garden_20261022ap']:
    assert same(rows[sid]['receipt_source_sha256'],stage['nodes']['quarter_final']['value']['source_sha256'])
assert same(rows[estate]['receipt_source_sha256'],stage['nodes']['estate_final']['value']['source_sha256'])
rooms={r['id']:r for r in o['rooms']};oldrooms={r['id']:r for r in old['rooms']};assert len(rooms)==5 and rooms.keys()==oldrooms.keys()
dt='res://scripts/city/luoyang_district_life_20261016f.gd'
for sid,row in rooms.items():
    base=oldrooms[sid]
    assert same(row['source_sha256'],migrate(base['source_sha256'],True))
    assert same(row['receipt_source_sha256'],migrate(base['receipt_source_sha256']))
    changed=[p for p in base['receipt_source_sha256']if base['receipt_source_sha256'][p]!=row['receipt_source_sha256'][p]]
    assert changed==[dt] and len(row['source_sha256'])==539
    for key in base:
        if key not in ('source_sha256','receipt_source_sha256','recipe'):assert same(row[key],base[key])
core=copy.deepcopy(old['core_source_sha256']);core.update({p:r['candidate_sha256']for p,r in targets.items()});assert same(core,o['core_source_sha256'])
union={}
for row in list(rows.values())+list(rooms.values()):
    for table in ('source_sha256','receipt_source_sha256'):
        for p,h in row[table].items():assert p not in union or union[p]==h;union[p]=h
classified={'targets':0,'stage_declared':0,'unchanged1292':0}
oldunion={p:h for row in old['scenes']+old['rooms']for field in ('source_sha256','receipt_source_sha256')for p,h in row[field].items()}
for p,h in union.items():
    if p in targets:assert h==targets[p]['candidate_sha256'];classified['targets']+=1
    elif p in stage['source_first']:assert h==stage['source_first'][p];classified['stage_declared']+=1
    else:assert oldunion[p]==h;classified['unchanged1292']+=1
assert classified=={'targets':22,'stage_declared':2918,'unchanged1292':7} and len(union)==2947
counts={sid:{'collector':len(row['source_sha256']),'receipt':len(row['receipt_source_sha256'])}for sid,row in rows.items()}
assert counts==review['scene_counts']
out=QA/'performance08_owner9D00_independent_fixed1292_recipe_review_READY.json'
result={'status':'INDEPENDENT_PERFORMANCE08_EXPECTED_OWNER_RECIPE_NO_BLOCKER_NOT_DEPLOYED','owner_sha256':sha(op.read_bytes()),'source_review_sha256':'89ee91312743f60e8810ca24eb4cd7def0af9e43a0c911892222b36a74e20152','stage_sha256':o['actual_stage_receipt']['sha256'],'fixed_prior_owner_sha256':o['fixed_prior_owner_sha256'],'all8scene5room_source_and_receipt_tables_reconstructed':True,'scene_counts':counts,'room_collector':539,'room_receipt_counts':[len(r['receipt_source_sha256'])for r in o['rooms']],'five_room_receipts_only_DT_hash_migrated':True,'core_fixed1292_plus26_candidates_exact':True,'expected_union':len(union),'union_basis_counts':classified,'current_source_crawl_or_collector':False,'engine_stage_decode_canonical_writes':0,'blocking_findings':[]}
assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes())}))
