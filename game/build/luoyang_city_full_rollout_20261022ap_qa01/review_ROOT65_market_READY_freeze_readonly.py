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
oldroot=Q+'market_scholar_identity_Field_ROOT65_NOTREADY/';root=R+'integration65/market_scholar_READY/'
ofp=oldroot+'fixture_NOTREADY.json';fp=root+'fixture_READY.json';oh='0e3cb83f7705632200d23266d602fd2936127238450e4783fcbdba425940ef76';h='4c49bdddd98827e7a2bf59b6501dd8099a5359416ba3e067231e6b82c3816d96'
old=read(ofp,oh);new=read(fp,h);ob=raw(oldroot+'test_market_scholar_NOTREADY.gd');b=raw(root+'test_READY.gd')
assert sha(ob)=='6df543b13c9eac6c3522ebf882c6cc68c074ca84b3d91a1800c0eae9428bf01f'
assert sha(b)=='98b64e7985f47baad676dbd1afa0d2c91e3858fe1e8dd55e4f1b879469538ec7'
rev=b
for a,c in reversed([('const FIXTURE_READY=false','const FIXTURE_READY=true'),(ofp,fp),(oh,h),(oldroot+'output/',root+'output/')]):
    assert rev.count(c.encode())==1;rev=rev.replace(c.encode(),a.encode(),1)
assert rev==ob,'KEY_EXACT_FOUR_LITERAL_BYTE_INVERSE_WITH_EOF'
assert set(new)==set(old)and new['ready']is True and new['blockers']==[]and isinstance(new['status'],str)
v=copy.deepcopy(new)
for k in('ready','status','blockers'):v[k]=copy.deepcopy(old[k])
assert same(v,old),'FIXTURE_EXACT_ONLY_THREE_READINESS_FIELDS_TYPED_INVERSE'
assert json.dumps(v,sort_keys=True,separators=(',',':'))==json.dumps(old,sort_keys=True,separators=(',',':'))
assert new['owner']['sha256']=='c9d9d25bdbcd8c096e0fd16165fdc23943000e34755f11fafa07e5e782822a61'
assert new['expected_city_source_count']==len(new['expected_city_sources'])==1741 and len(new['source_sha256'])==1760
assert new['formal_deployment']['sha256']=='5ba21807aea61698bba817e7c2329823768afe6a14431d4a973313d914cb957d'and new['formal_final_guard']['sha256']=='d081f80929aaf85026c7fce6456ecdda9f9b1883106ed5e66316f27a6745c368'and new['fresh_run_guard']['sha256']=='5a2289cad798d489b8fbb1ba339feef04329d17fdbb4e25ea3a5c6ffd70999e8'
assert new['whole_ms']==60000 and new['entry_ms']==20000 and new['max_pictures']==1
print(json.dumps({'status':'ROOT65_MARKET_SCHOLAR_READY_STATIC_FREEZE_NO_BLOCKER_NOT_RUNTIME_PASS','key_SHA':sha(b),'fixture_SHA':h,'exact_four_key_literal_wholebyte_inverse_including_EOF':True,'fixture_only_ready_status_blockers_complete_typed_and_sortedserialized_inverse':True,'owner_C9D9_expected1741_guard1760_three_actual_credentials_unchanged':True,'60s20s_one_inspection_cameraPNG_no_INPUT_Space_room_quest_sourcecollector_unchanged':True,'QA_engine_parse_Stage_collector_decode_mediahash_or_production_write':False},indent=2))
