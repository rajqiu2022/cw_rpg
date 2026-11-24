import copy,hashlib,json,pathlib
G=pathlib.Path(__file__).resolve().parents[2]
Q='res://build/luoyang_city_full_rollout_20261022ap_qa01/'
R='res://build/luoyang_city_full_rollout_20261022ap_root01/'
def raw(p):return(G/p[6:]).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=raw(p);assert sha(b)==h,p;return json.loads(b)
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
pins={'formal_deployment':{'path':R+'integration62/formal28_deployment_actual.json','sha256':'63ec58f056ca5ddba3682330f286884178946037549bb068c14dbb88c4ba2ffc'},'formal_final_guard':{'path':R+'integration62/final_guard.json','sha256':'f86bfd6ebf1b7d991e744fd3fb432bed1f18f94d5822bc5257565f7627d772f5'},'fresh_run_guard':{'path':R+'integration63/guard_before.json','sha256':'aa590b674ee21050c26ba767a3a546d35c0cf191772dafcc920c2d2b267bc6f8'}}
for row in pins.values():read(row['path'],row['sha256'])
reports=[]
for stem,name,kh,fh,pkh,pfh in [
 ('artisan_four_low_props','artisan','a411b26ac334aa8431ab498c779cfcd6abbcbd75a38dc3a7adc4fb91c34ad4f0','1be43b84c7e2875191154a1e6b8728f1e6d960baf5ccb92c8ee58c7ae6d38d51','5968dbc8739caea5dad045743add5e0d26f1a9117a14c5f751ef23238ed54e31','9ab1516df13c360a55921ae6a6a1063b903fd9e3a75803bbae33ec8f7bb465d4'),
 ('market_scholar_identity','market_scholar','1102acfdd58eacaa21425f90042255e8e3ac9f486275781dd8658b87752c78c4','6492bf7ccd9004231e32a079b26eda498ffb837161a69cda3d005b31427a520d','0e55f86f9e0ce71d88ed5b429d3058623f40f57dc5617438733f826ada3fab43','5deb8172dc75dad282072ae1af0ae0548f1405fb1896c41b95231080aa85a188')]:
    oldroot=Q+stem+'_Field_FD58_NOTREADY/';newroot=R+'integration63/'+name+'_READY/'
    fp=newroot+'fixture_READY.json';kp=newroot+'test_READY.gd';ofp=oldroot+'fixture_NOTREADY.json';okp=oldroot+'test_'+stem+'_NOTREADY.gd'
    f=read(fp,fh);old=read(ofp,pfh);b=raw(kp);ob=raw(okp);assert sha(b)==kh and sha(ob)==pkh
    repl=[('const FIXTURE_READY=false','const FIXTURE_READY=true'),(ofp,fp),(pfh,fh),(oldroot+'output/',newroot+'output/')]
    rev=b
    for a,c in reversed(repl):assert rev.count(c.encode())==1,(name,c);rev=rev.replace(c.encode(),a.encode(),1)
    assert rev==ob or rev+b'\n'==ob,(name,'FOUR_LITERAL_INVERSE_PLUS_ONLY_ONE_FINAL_BLANK_LF')
    eof_difference=(rev!=ob)
    assert f['ready']is True and f['status']=='ROOT63_FROZEN_LOCAL_FIELD_CHECK_ONLY_NOT_RUNTIME_PASS'and f['blockers']==[]
    assert set(f)==set(old),(name,'NO_NEW_FIXTURE_FIELD')
    inverse=copy.deepcopy(f)
    for k in ('ready','status','blockers'):inverse[k]=copy.deepcopy(old[k])
    assert len(f['source_sha256'])==len(old['source_sha256'])+3
    for k,row in pins.items():
        assert same(f[k],row)and old[k]=={'path':None,'sha256':None}
        assert row['path']not in old['source_sha256']and inverse['source_sha256'].pop(row['path'])==row['sha256']
        inverse[k]=copy.deepcopy(old[k])
    if 'guarded_source_count'in old:
        assert f['guarded_source_count']==379;inverse['guarded_source_count']=old['guarded_source_count']
    else:assert len(f['source_sha256'])==1760
    assert same(inverse,old),(name,'FULL_TYPED_FIXTURE_INVERSE')
    assert json.dumps(inverse,ensure_ascii=False,sort_keys=True,separators=(',',':'))==json.dumps(old,ensure_ascii=False,sort_keys=True,separators=(',',':'))
    assert f['whole_ms']==60000 and f['entry_ms']==20000 and f['max_pictures']==1
    if name=='artisan':assert f['expected_source_count']==341 and f['expected_receipt_count']==339
    else:assert f['expected_city_source_count']==1741 and f['owner_tables_ready']is True
    reports.append({'name':name,'key':{'path':kp,'sha256':kh},'fixture':{'path':fp,'sha256':fh},'key_only_four_literal_wholebyte_inverse':not eof_difference,'one_final_blank_LF_removed_in_Root_READY':eof_difference,'four_literal_plus_explicit_EOF_inverse':True,'fixture_fulltyped_and_sortedserialized_inverse':True,'guard_count':len(f['source_sha256']),'body_expected_maps_budget_camera_routes_unchanged':True})
print(json.dumps({'status':'ROOT63_TWO_READY_FREEZES_STATIC_NO_BLOCKER_NOT_RUNTIME_PASS','credentials_exact':pins,'keys':reports,'limitations':'No engine/parse/collector/geometry/media decode or source payload rehash; only fixed small artifacts. Root decides exclusive actual execution.'},indent=2))

