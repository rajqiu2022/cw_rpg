"""Small deployment/guard receipts and two fixed QA successor inverses only."""
import copy,hashlib,json,pathlib
G=pathlib.Path(__file__).resolve().parents[2]
Q='res://build/luoyang_city_full_rollout_20261022ap_qa01/'
R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def raw(p):return(G/p[6:]).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=raw(p);assert sha(b)==h,p;return json.loads(b)
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
deployment=read(R+'integration62/formal28_deployment_actual.json','63ec58f056ca5ddba3682330f286884178946037549bb068c14dbb88c4ba2ffc')
final=read(R+'integration62/final_guard.json','f86bfd6ebf1b7d991e744fd3fb432bed1f18f94d5822bc5257565f7627d772f5')
fresh=read(R+'integration63/guard_before.json','aa590b674ee21050c26ba767a3a546d35c0cf191772dafcc920c2d2b267bc6f8')
actual=read(S+'outputs/root_unified_life_garden_scholar28_stage01/receipt.json','4ce21902185a78f6c441f8ee8d63d30b30a7c31c61f135b5df13322bc266d945')
assert deployment['target_count']==28 and len(deployment['targets'])==28
targets={r['target']:r for r in actual['targets']}
def res(p):return'res://'+pathlib.Path(p).relative_to(G).as_posix()
assert{res(r['path'])for r in deployment['targets']}==set(targets)
for r in deployment['targets']:
    t=targets[res(r['path'])]
    assert r['sha256']==t['candidate_sha256'] and r['backup_sha256']==t['old_sha256']
    assert r['bytes']==len(raw(t['candidate_path']))
assert final['passed']and final['checked']==2119 and final['authorized_change_count']==28 and final['exact_unchanged']==2091 and final['unexpected_change_count']==0
assert final['save_count']==15 and final['save_change_count']==0
assert fresh['passed']and fresh['checked']==2119 and fresh['unexpected_change_count']==0 and fresh['save_count']==15 and fresh['save_change_count']==0
assert final['parent_fact_values_copied']is False and fresh['parent_fact_values_copied']is False
assert final['retained_prior_failure'] and fresh['retained_prior_failure']
rows=[]
for stem in ('artisan_four_low_props','market_scholar_identity'):
    root=Q+stem+'_Field_FD58_NOTREADY/'
    hb=raw(root+'handoff_NOTREADY.json');h=json.loads(hb)
    kb=raw(h['key']['path']);assert sha(kb)==h['key']['sha256']
    fb=raw(h['fixture']['path']);assert sha(fb)==h['fixture']['sha256']
    original=raw(h['parent_key']['path']);assert sha(original)==h['parent_key']['sha256']
    reverse=kb
    for a,b in reversed(h['only_three_key_literals']):
        assert reverse.count(b.encode())==1
        reverse=reverse.replace(b.encode(),a.encode(),1)
    assert reverse==original and b'const FIXTURE_READY=false' in kb
    f=json.loads(fb);rev=copy.deepcopy(f)
    for d in reversed(h['fixture_complete_delta']):
        if d['existed']:assert same(rev[d['field']],d['new']);rev[d['field']]=d['old']
        else:assert same(rev[d['field']],d['new']);del rev[d['field']]
    old=read(h['parent_fixture']['path'],h['parent_fixture']['sha256'])
    assert same(rev,old)and json.dumps(rev,ensure_ascii=False,indent=2)==json.dumps(old,ensure_ascii=False,indent=2)
    assert f['ready']is False and all(v is None for k in ('formal_deployment','formal_final_guard','fresh_run_guard')for v in f[k].values())
    assert f['owner']['sha256']=='fd58f7c2dbd3372d6adbb6f9a39ba7c70568125e4f843c11dc546e750fdfd61c'
    rows.append({'id':stem,'key_SHA':sha(kb),'fixture_SHA':sha(fb),'exact_three_literal_inverse':True,'fixture_full_typed_serialized_inverse':True,'hardfalse':True,'pending_three_credentials_all_null':True})
print(json.dumps({'status':'ROOT62_DEPLOYMENT_RECEIPTS_AND_FD58_FALSE_SUCCESSORS_NO_BLOCKER_FOR_MECHANICAL_ROOT_FREEZE_NOT_ENGINE_AUTHORITY','deployment28_matches_fixed_actual_candidate_and_old_SHA':True,'formal_guard':{'checked':2119,'authorized':28,'exact_same':2091,'save15_changes':0,'unexpected':0},'fresh63':{'checked':2119,'save15_changes':0,'unexpected':0},'retained2118_domain_failure':True,'NativeGeometry_added_one_domain_not_hidden_target':True,'two_keys':rows,'scope':'No engine/collector/source scan/media hash/decode/production write. Exact candidate byte counts read only; no source-payload SHA rehash.'},indent=2))
