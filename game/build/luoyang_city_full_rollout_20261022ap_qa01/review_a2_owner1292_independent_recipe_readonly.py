"""Check final expected owner recipes from fixed parents, not live collectors."""
import copy
import hashlib
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
OUT=Path(__file__).with_name('artisan_a2_owner1292_independent_expected_recipe_review_READY.json')
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,s=None):
    b=p.read_bytes()
    if s:assert sha(b)==s
    return json.loads(b)
def same(a,b):
    if type(a)!=type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
op=SF/'a2_source_recipe08/actual_independent_review/owner_source_maps_READY.json'
owner=load(op,'12924be9ea2c6a081b4865354d40075caa10e3804ad6c942e972f0270bd5219a')
review=load(op.with_name('source_stage_review_READY.json'),'74a400cb0a2f44989c17268f24af560ecb5c9db2fd20fa9e366435e9ca7f286e')
old=load(SF/'finite10_yamen_classification/actual_deployment_review/owner_source_maps_ROOT_DEPLOYED_READY.json','690fba034f8b865e0cbbe31e21a8ee8095ede2471b73235f500fbcb4052c8902')
stage=load(SF/'outputs/root_artisan_A2_source_stage01/receipt.json','4688cdbb0fa137425cc5964d37d918da9358889e68dc6496f2b4fb6ee1405d8c')
hand=load(SF/'a2_production04/handoff_PRODUCTION_PROPOSAL.json','258cde4cb62b3f5fa2e1ac01cb08a322ffc6b8eca3d63c11c34b2add161f7085')
targets={r['target']:r for r in stage['targets']};previous={r['id']:r for r in old['scenes']};rows={r['id']:r for r in owner['scenes']}
assert len(rows)==8 and len(owner['rooms'])==5 and owner['actual_stage_receipt']['sha256']=='4688cdbb0fa137425cc5964d37d918da9358889e68dc6496f2b4fb6ee1405d8c'
def replaced(src):
    v=copy.deepcopy(src)
    for p in v:
        if p in targets:assert v[p]==targets[p]['old_sha256'];v[p]=targets[p]['candidate_sha256']
    return v
def merged(a,b):
    v=copy.deepcopy(a)
    for p,s in b.items():assert p not in v or v[p]==s;v[p]=s
    return v
for ident,node in stage['nodes'].items():
    if ident.startswith('expected_ch4_'):
        sid=node['value']['scene_id'];assert same(rows[sid]['source_sha256'],node['value']['source_sha256'])
        assert same(rows[sid]['receipt_source_sha256'],node['value']['source_sha256'])
q=stage['nodes']['quarter_final']['value'];qsrc=q['source_sha256']
for sid in q['scenes']:
    row=rows[sid];base=previous[sid]
    headers={p:s for p,s in base['source_sha256'].items() if p not in base['receipt_source_sha256']}
    assert same(row['receipt_source_sha256'],qsrc)
    assert same(row['source_sha256'],merged(qsrc,replaced(headers)))
    assert row['scene_path']==q['scenes'][sid]['scene_path'] and row['layout_path']==q['scenes'][sid]['layout_path']
    assert row['world_size']==[3072,2048]
sid='luoyang_estate_riverside_20261021ai';base=previous[sid];row=rows[sid]
esrc=stage['nodes']['estate_final']['value']['source_sha256']
headers={p:s for p,s in base['source_sha256'].items() if p not in base['receipt_source_sha256']}
assert same(row['receipt_source_sha256'],esrc) and same(row['source_sha256'],merged(esrc,replaced(headers))) and len(esrc)==331
sid='ch4_s4_ancient_temple';expected=merged(replaced(previous[sid]['source_sha256']),hand['new_proof_pins'])
assert same(rows[sid]['source_sha256'],expected) and same(rows[sid]['receipt_source_sha256'],expected)
oldrooms={r['id']:r for r in old['rooms']}
for row in owner['rooms']:
    base=oldrooms[row['id']]
    assert same(row['source_sha256'],merged(replaced(base['source_sha256']),hand['new_proof_pins']))
    assert same(row['receipt_source_sha256'],base['receipt_source_sha256'])
core=copy.deepcopy(old['core_source_sha256']);core.update({p:r['candidate_sha256'] for p,r in targets.items()})
assert same(core,owner['core_source_sha256'])
assert review['actual_stage_receipt']==owner['actual_stage_receipt'] and review['target_count']==28
result={'status':'INDEPENDENT_A2_EXPECTED_OWNER_RECIPES_FROM_FIXED690F_AND_ACTUAL4688_NOT_DEPLOYMENT','owner_path':'res://'+op.relative_to(ROOT).as_posix(),'owner_sha256':sha(op.read_bytes()),'stage_sha256':'4688cdbb0fa137425cc5964d37d918da9358889e68dc6496f2b4fb6ee1405d8c','source_review_sha256':'74a400cb0a2f44989c17268f24af560ecb5c9db2fd20fa9e366435e9ca7f286e','scene_counts':{k:{'collector':len(v['source_sha256']),'receipt':len(v['receipt_source_sha256'])}for k,v in rows.items()},'room_count':5,'room_receipts_unchanged':True,'core_exact28_existing_substitutions':True,'all_8scene_5room_expected_dictionaries_independently_reconstructed':True,'no_live_collection_or_canonical_hash_fill':True,'no_engine_stage_decode_or_geometry':True,'blocking_findings':[],'still_pending':'Root actual deployment; final finite Field readiness only after that authority.'}
assert not OUT.exists();OUT.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(OUT),'sha256':sha(OUT.read_bytes())}))
