"""Read-only independent review of Root stage02 and Source owner output."""
import copy,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];S=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
OUT=Path(__file__).with_name('finite09_stage02_actual_independent_review_READY.json')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def res(p):
    assert p.startswith('res://');v=(ROOT/p[6:]).resolve();assert v.is_relative_to(ROOT);return v
def load(p):return json.loads(p.read_bytes())
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys() and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def ptr(d,ks):
    for k in ks:d=d[k]
    return d
def fact(p):return {'path':'res://'+p.relative_to(ROOT).as_posix(),'sha256':sha(p)}
rp=S/'outputs/root_finite09_two_domain_stage02/receipt.json'
assert sha(rp)=='885a813db26487582bc7cb31d02ec89827dc929a9e2653e71137defd8ff8c3a0'
r=load(rp);plan=load(S/'finite09_input02_ROOT_LOCKED.json')
assert r['status']=='AP_SOURCE_METADATA_STAGED_NOT_DEPLOYED'
assert r['source_first']==r['source_final']
for path,h in r['source_first'].items():assert sha(res(path))==h,('stage source current',path)
pins={x['id']:x for x in plan['pinned_inputs']};nodes=r['nodes']
scope=load(res(pins['root_finite08_actual_backups']['path']))
old={x['target']:x['old_sha256'] for x in scope['targets']}
assert len(r['targets'])==29 and {x['target'] for x in r['targets']}==set(old)==set(plan['root_target_allowlist'])
for x in r['targets']:
    assert x['old_sha256']==old[x['target']] and sha(res(x['target']))==x['old_sha256']
    assert sha(res(x['candidate_path']))==x['candidate_sha256']!=x['old_sha256']
assert r['target_partition']=={'patch_count':28,'copy_count':1,'total':29,'intersection_empty':True,'union_exact_targets':True}
assert sha(res(r['patch_path']))==r['patch_sha256']
cp=load(res(r['byte_copy_plan']['path']));assert sha(res(r['byte_copy_plan']['path']))==r['byte_copy_plan']['sha256']
assert len(cp['rows'])==1 and cp['rows'][0]['target']=='res://data/maps/luoyang_full_city_20261022ap/execution_successor.json'
typed=[];indices=[]
def value(x):
    if isinstance(x,dict) and '$sha' in x:
        n=nodes[x['$sha']];return n['disabled_sha256'] if x.get('variant')=='disabled' else n['sha256']
    return x
for row in plan['nodes']:
    n=nodes[row['id']];assert sha(res(n['path']))==n['sha256']
    if row['kind'] in ['metadata','finite_contract']:
        actual=load(res(n['path']));assert same(actual,n['value'])
        inverse=copy.deepcopy(actual)
        for d in reversed(r['proofs'][row['id']]['source_delta']):
            holder=ptr(inverse,d['pointer'][:-1]);k=d['pointer'][-1]
            if d['existed']:holder[k]=d['old']
            else:del holder[k]
        base=pins[row['base_input']];assert sha(res(base['path']))==base['sha256']
        assert same(inverse,load(res(base['path'])));typed.append(row['id'])
    if row['kind'] in ['index','finite_index']:
        raw=res(n['path']).read_bytes()
        if row['kind']=='finite_index':
            extra=r['proofs'][row['id']]['append_exact_bytes'].encode();assert raw.endswith(extra);raw=raw[:-len(extra)]
        text=raw.decode();assert text.count(row['enabled_literal'])==1
        text=text.replace(row['enabled_literal'],row['disabled_literal'])
        for op in reversed(row['replacements']):
            after=value(op['new']);assert text.count(after)==1;text=text.replace(after,op['old'])
        assert text.encode()==res(pins[row['base_input']]['path']).read_bytes();indices.append(row['id'])
binding=load(res(pins['finite08_binding']['path']))
groups={x['id']:x for x in plan['source_groups']}
finite=[]
for domain in ['market','yamen']:
    row=next(x for x in plan['nodes'] if x['id']=='finite08_'+domain)
    d=binding['domains'][domain];parent=nodes[row['parent_node']]
    expected=copy.deepcopy(parent['value']);oldparent=copy.deepcopy(expected)
    for p,h in oldparent['artifacts'].items():
        if p not in d['manifest_immutable']['artifacts']:
            assert p not in expected['legacy_source_sha256'] or expected['legacy_source_sha256'][p]==h
            expected['legacy_source_sha256'][p]=h
    for p in d['manifest_immutable']['artifacts']:
        expected['legacy_source_sha256'].pop(p,None);expected['runtime_authority_sha256'].pop(p,None)
    expected.update(copy.deepcopy(d['manifest_immutable']))
    expected.update(formal_enabled=True,publication_full_source_finalized=True,finite_source_closure_pending=False)
    for p,h in groups['finite08_'+domain+'_sources']['leaves'].items():
        assert isinstance(h,str)
        if p in expected['artifacts']:assert expected['artifacts'][p]==h;continue
        where=[k for k in ['legacy_source_sha256','runtime_authority_sha256'] if p in expected[k]]
        assert len(where)<=1
        if where:assert expected[where[0]][p]==h
        else:expected['legacy_source_sha256'][p]=h
    expected['legacy_source_sha256'][row['parent_header_path']]=parent['sha256']
    actual=load(res(nodes[row['id']]['path']));assert same(actual,expected)
    assert same(actual['parent_publication'],oldparent['parent_publication'])
    union={}
    for k in ['legacy_source_sha256','runtime_authority_sha256','artifacts']:
        assert not set(union)&set(actual[k]);union.update(actual[k])
    assert row['file'] not in union
    for p,h in union.items():
        staged=next((t for t in r['targets'] if t['target']==p),None)
        assert (staged['candidate_sha256'] if staged else sha(res(p)))==h
    finite.append({'domain':domain,'complete_count':len(union),'manifest_sha256':nodes[row['id']]['sha256'],'whole_independent_reconstruction':True,'source_classes_disjoint':True,'r3_immediate_parent_typed_unchanged':True})
ownerp=S/'finite09_stage02_independent_review/owner_source_maps_READY.json'
reviewp=S/'finite09_stage02_independent_review/stage_source_review_READY.json'
assert sha(ownerp)=='1002af3bf3cd46ef0e1f4864d8313bfca0d82eea04349437b916e5df6f932188'
assert sha(reviewp)=='c4e2bc80c85fc817af5fbdbcf0b76c11a076c574337c33ee2be68e03d4ee5133'
owner=load(ownerp);assert owner['actual_stage_receipt']['sha256']==sha(rp)
assert len(owner['scenes'])==8 and len(owner['rooms'])==5
for scene in owner['scenes']:
    if scene['id'].startswith('ch4_s'):
        assert same(scene['source_sha256'],nodes['expected_'+scene['id']+'_true']['value']['source_sha256'])
assert not OUT.exists()
result={'status':'ROOT_ACTUAL_FINITE09_STAGE02_INDEPENDENT_QA_REVIEW_NOT_DEPLOYMENT','actual_stage_receipt':fact(rp),'source_owner':fact(ownerp),'source_review':fact(reviewp),'source_first_final_current_count':len(r['source_first']),'canonical_targets_still_exact_old':29,'candidate_SHA_exact':29,'whole_metadata_typed_inverse_nodes':typed,'whole_index_byte_inverse_nodes':indices,'finite_manifests':finite,'target_partition':r['target_partition'],'independent_owner_schema':{'scenes':8,'rooms':5},'four_independent_maps_equal_source_recipe_owner':True,'no_runtime_or_ART_or_performance_credit':True,'engine_runs':0,'collector_calls':0,'native_or_PNG_decode':0,'canonical_writes':0}
OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review':fact(OUT),'source_count':len(r['source_first']),'metadata':len(typed),'indices':len(indices),'finite':finite}))
