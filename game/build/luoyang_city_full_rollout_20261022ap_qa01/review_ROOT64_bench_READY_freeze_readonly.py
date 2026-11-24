import copy,hashlib,json,pathlib
G=pathlib.Path(__file__).resolve().parents[2];Q='res://build/luoyang_city_full_rollout_20261022ap_qa01/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
def raw(p):return(G/p[6:]).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=raw(p);assert sha(b)==h,p;return json.loads(b)
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
oldroot=Q+'bench_only_suffix1200_Field_NOTREADY/';root=R+'integration64/bench_READY/'
oldkey=raw(oldroot+'test_bench_suffix_NOTREADY.gd');key=raw(root+'test_READY.gd')
assert sha(oldkey)=='b6f58fb069374eff391a85973563a9fdfca710464b1252067aab24651adaee53'
assert sha(key)=='89126603529c329ec6bbf9419a1fa0c85c9387e09346b6a78ebca248d46bb0b7'
ofp=oldroot+'fixture_NOTREADY.json';fp=root+'fixture_READY.json'
oh='2c3f7ff2a0a5951c7392f75c5313c606d6d478b5440bfdca4397ea9b4a4dc7db';h='4c770774a979919d55d34fe65b777f9c704afdd54f83bb94f8a6b8930819f0fb'
old=read(ofp,oh);f=read(fp,h)
reverse=key
for before,after in reversed([('const BENCH_READY=false','const BENCH_READY=true'),(ofp,fp),(oh,h),(oldroot+'output/',root+'output/')]):
    assert reverse.count(after.encode())==1;reverse=reverse.replace(after.encode(),before.encode(),1)
assert reverse==oldkey,'EXACT4_LITERAL_KEY_BYTE_INVERSE_INCLUDING_FINAL_LF'
assert set(f)==set(old)and f['ready']is True and f['blockers']==[]and f['status']=='ROOT64_FROZEN_BENCH_SUFFIX_ONLY_NOT_RUNTIME_PASS'
credentials={'formal_deployment':{'path':R+'integration62/formal28_deployment_actual.json','sha256':'63ec58f056ca5ddba3682330f286884178946037549bb068c14dbb88c4ba2ffc'},'formal_final_guard':{'path':R+'integration63/final_guard.json','sha256':'4a380ff6428e2276b7dd9a607dbac28bc5e04d7f79514337ce261288e1983618'},'fresh_run_guard':{'path':R+'integration64/guard_before.json','sha256':'3e370f0e0985fa2386184ed08413fe71f1e4d1ddaa4503390f7c8493c768105c'}}
rev=copy.deepcopy(f)
for k in ('ready','status','blockers'):rev[k]=old[k]
assert len(f['source_sha256'])==len(old['source_sha256'])+3
for k,v in credentials.items():
    assert same(f[k],v)and old[k]is None
    d=read(v['path'],v['sha256'])
    if k!='formal_deployment':assert d['passed']and d['checked']==2119 and d['save_count']==15 and d['save_change_count']==0
    assert v['path']not in old['source_sha256']and rev['source_sha256'].pop(v['path'])==v['sha256']
    rev[k]=None
assert same(rev,old),'FULL_TYPED_FIXTURE_INVERSE'
assert json.dumps(rev,sort_keys=True,separators=(',',':'))==json.dumps(old,sort_keys=True,separators=(',',':'))
assert f['whole_ms']==60000 and f['entry_ms']==20000 and f['max_pictures']==0 and f['expected_family_receipt_count']==339
assert f['inspection_near_px']==[1260,1176]and f['endpoint_px']==[1260,1200]
assert f['local_prior']['sha256']=='1b45b8af2d6be3d911a80782b796cda43deb57e103f381de5b8c5db46b3ba130'
print(json.dumps({'status':'ROOT64_BENCH_READY_STATIC_FREEZE_NO_BLOCKER_NOT_RUNTIME_PASS','key_SHA':sha(key),'fixture_SHA':h,'exact_four_literal_wholebyte_inverse_including_final_LF':True,'fixture_fulltyped_and_sortedserialized_inverse':True,'credentials_exact':credentials,'guard_count':len(f['source_sha256']),'source_prior_bench_originalbody_339_60s20s_0PNG_2INPUT_unchanged':True,'positive_target_hit_failable_not_guessed_pixel_count':True,'QA_engine_parse_collector_decode_or_production_write':False},indent=2))
