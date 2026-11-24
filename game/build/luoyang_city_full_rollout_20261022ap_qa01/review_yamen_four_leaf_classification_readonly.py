"""Pure candidate review: four existing leaves change class, not sources."""
import copy,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
S=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
P=S/'finite10_yamen_classification'
OUT=Path(__file__).with_name('yamen_four_leaf_classification_independent_static_review_READY.json')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def load(p):return json.loads(p.read_bytes())
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def fact(p):return {'path':'res://'+p.relative_to(ROOT).as_posix(),'sha256':sha(p)}
hand=P/'handoff02_CANDIDATES_READY_NOT_DEPLOYED.json'
assert sha(hand)=='b812325c48c7dceac50bbb170b233a019bfc59c8d0c1d0dd3374142578110c1e'
h=load(hand)
for row in h['targets']:
    for k in ['old_snapshot','candidate']:
        p=ROOT/row[k]['path'][6:];assert sha(p)==row[k]['sha256'] and p.stat().st_size==row[k]['bytes']
oldm=P/'before_yamen_f00D.json';newm=P/'runtime_yamen_manifest_classification_READY.json'
a,b=load(oldm),load(newm);back=copy.deepcopy(b)
troot='res://data/maps/luoyang_layout_bundle_20261018t_retry2/'
paths=[troot+'ch4_s1_luoyang_yamen/'+x for x in ['layout.res','packet.bin','scene.res','manifest.json']]
assert set(p for p in a['legacy_source_sha256'] if p.startswith(troot))==set(paths)
for p in paths:
    assert p not in a['runtime_authority_sha256'] and p not in b['legacy_source_sha256']
    assert b['runtime_authority_sha256'][p]==a['legacy_source_sha256'][p]
    back['legacy_source_sha256'][p]=back['runtime_authority_sha256'].pop(p)
assert same(back,a)
def union(m):
    out={}
    for k in ['legacy_source_sha256','runtime_authority_sha256','artifacts']:
        assert not set(out)&set(m[k]);out.update(m[k])
    return out
assert same(union(a),union(b)) and len(union(a))==1203
assert not any(p.startswith(troot) for p in b['legacy_source_sha256'])
oldi=P/'before_AP_INDEX_b780.gd';newi=P/'FullCityIndex_yamen_classification_READY.gd'
assert newi.read_bytes().count(sha(newm).encode())==1
assert newi.read_bytes().replace(sha(newm).encode(),sha(oldm).encode())==oldi.read_bytes()
op=S/'finite09_stage02_independent_review/owner_source_maps_READY.json'
np=P/'owner_source_maps_EXPECTED_NOT_DEPLOYED.json'
assert sha(op)=='1002af3bf3cd46ef0e1f4864d8313bfca0d82eea04349437b916e5df6f932188'
assert sha(np)=='1302cdb19aa57f7d8d65cb7e9e307b8212e3777093e915fdb23441f75f58fca9'
oa,nb=load(op),load(np);ob=copy.deepcopy(nb)
indexpath=h['targets'][1]['target'];manifestpath=h['targets'][0]['target']
assert ob['core_source_sha256'][indexpath]==sha(newi)
ob['core_source_sha256'][indexpath]=sha(oldi)
changed=0
for oldscene,newscene in zip(oa['scenes'],ob['scenes']):
    assert oldscene['id']==newscene['id']
    for field in ['source_sha256','receipt_source_sha256']:
        for p,oldsha,newsha in [(indexpath,sha(oldi),sha(newi)),(manifestpath,sha(oldm),sha(newm))]:
            if p in oldscene[field]:
                assert oldscene[field][p]==oldsha and newscene[field][p]==newsha
                newscene[field][p]=oldsha;changed+=1
    assert same(newscene,oldscene)
assert changed==10 and same(ob['rooms'],oa['rooms'])
ob['status']=oa['status']
for k in ['parent_source_owner','bounded_runtime_metadata_successor']:del ob[k]
assert same(ob,oa)
assert not OUT.exists()
report={'status':'INDEPENDENT_EXACT_TWO_METADATA_CANDIDATE_REVIEW_NOT_DEPLOYED','handoff':fact(hand),'manifest_candidate':fact(newm),'index_candidate':fact(newi),'owner_candidate':fact(np),'only_four_existing_T_root_leaves_same_SHA_move_legacy_to_runtime_authority':paths,'whole_manifest_typed_inverse':True,'whole_index_single_hash_literal_byte_inverse':True,'complete_source_union_unchanged':1203,'source_classes_disjoint':True,'four_city_collector_receipt_only10_existing_header_value_changes':True,'other_four_scenes_and_five_rooms_full_unchanged':True,'core_only_one_existing_index_value_change':True,'production_B_C_adapter_OWNED_native_or_geometry_unchanged':True,'no_loading_or_Field_admission_claim':True,'engine_runs':0,'stage_runs':0,'collector_calls':0,'native_or_PNG_decode':0,'canonical_writes':0}
OUT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review':fact(OUT),'source_union_same':1203,'metadata_targets':2,'actual_deployment':False}))
