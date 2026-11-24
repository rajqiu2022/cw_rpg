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
oldroot=Q+'market_scholar_primary_camera_residual_NOTREADY/';root=R+'integration66/scholar_residual_READY/'
ofp=oldroot+'fixture_NOTREADY.json';fp=root+'fixture_READY.json';oh='01b7d4274c04392d37a3f8c9fa509edf32ed6969f6442c04dc475ef0c1d91bc9';h='596c8c59b7833dc2905ad89210d5d787deb411d79363a717f6a6e782b86f37d5'
old=read(ofp,oh);new=read(fp,h);ob=raw(oldroot+'test_residual_NOTREADY.gd');b=raw(root+'test_READY.gd')
assert sha(ob)=='814c3c48afa77cd14656644fa043cc9d70233140bf71a6762cad8edf0d00c12c'
assert sha(b)=='8731b0100cec98eeec5b3a8415d3309c92fdd3bbffc640e53c9ea06e50e7236a'
rev=b
for a,c in reversed([('const RESIDUAL_READY=false','const RESIDUAL_READY=true'),(ofp,fp),(oh,h),(oldroot+'output/',root+'output/')]):
    assert rev.count(c.encode())==1;rev=rev.replace(c.encode(),a.encode(),1)
assert rev==ob,'EXACT_FOUR_LITERAL_WHOLE_BYTE_INVERSE_INCLUDING_EOF'
assert set(new)==set(old)and new['ready']is True and new['blockers']==[]and isinstance(new['status'],str)
v=copy.deepcopy(new)
for k in('ready','status','blockers'):v[k]=copy.deepcopy(old[k])
assert same(v,old),'ONLY_THREE_FIXTURE_READINESS_FIELDS_TYPED_INVERSE'
assert json.dumps(v,sort_keys=True,separators=(',',':'))==json.dumps(old,sort_keys=True,separators=(',',':'))
assert len(new['source_sha256'])==15 and new['whole_ms']==60000 and new['entry_ms']==20000 and new['max_pictures']==1
assert new['expected_natural_source_count']==1741 and new['scholar']['task_projected_dialog_id']==new['scholar']['primary_dialog_id']=='luoyang_city_tasks_20261016/paper_offer'
assert new['scholar']['expected_default_quest_state']==0 and new['inspection_camera']['focus_source_px']==[520,1340]and new['camera_zoom']==1.05
assert new['owner']['sha256']=='c9d9d25bdbcd8c096e0fd16165fdc23943000e34755f11fafa07e5e782822a61'
assert b'first_draw={"camera_instance":camera.get_instance_id(),"meaning":"setup_camera_identity_only_NOT_firstdraw_measurement"}'in b
assert b'_one_exact_scholar('not in b and b'_city_owner('not in b and b'get_image('not in b
print(json.dumps({'status':'ROOT66_RESIDUAL_READY_STATIC_FREEZE_NO_BLOCKER_NOT_RUNTIME_PASS','key_SHA':sha(b),'fixture_SHA':h,'exact_four_literal_wholebyte_inverse_including_EOF':True,'fixture_only_ready_status_blockers_complete_typed_and_sortedserialized_inverse':True,'15pins_60s20s_1741passivecount_Taskprimary_camera_fields_unchanged':True,'inherited_camera_function_and_gameplay_unchanged_by_fixed_parent_reference':True,'camera_instance_identity_only_no_fabricated_firstdraw':True,'no_fullsource_body_defaultbenchmark_retest':True,'QA_engine_parse_collector_Stage_decode_or_production_write':False},indent=2))
