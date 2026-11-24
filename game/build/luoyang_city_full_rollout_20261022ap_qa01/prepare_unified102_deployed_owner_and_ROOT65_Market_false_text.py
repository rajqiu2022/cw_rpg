"""Explicit Root request: NEW pure-text FD58+15 deployed values and unchanged-body false test."""
import copy,difflib,hashlib,json,pathlib
G=pathlib.Path(__file__).resolve().parents[2];Q='res://build/luoyang_city_full_rollout_20261022ap_qa01/';R='res://build/luoyang_city_full_rollout_20261022ap_root01/';S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
def path(p):return G/p[6:]
def raw(p):return path(p).read_bytes()
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,h):
    b=raw(p);assert sha(b)==h,p;return json.loads(b)
def js(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def same(a,b):
    if type(a)is not type(b):return False
    if isinstance(a,dict):return a.keys()==b.keys()and all(same(a[k],b[k])for k in a)
    if isinstance(a,list):return len(a)==len(b)and all(same(x,y)for x,y in zip(a,b))
    return a==b
def emit(p,b):
    target=path(p);assert not target.exists(),('NEW_ONLY',p)
    target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(b)
oldop=S+'unified101_actual_owner_READY/owner_source_maps_READY.json';oldoh='fd58f7c2dbd3372d6adbb6f9a39ba7c70568125e4f843c11dc546e750fdfd61c'
old=read(oldop,oldoh)
sp=S+'unified102_ordinary_source_classification_BUILD/exact15_scope_NOTREADY.json';sh='668ab97fd42f7682e808b8314b00798ba26833751cad8649b64f11df5a4ec05b';scope=read(sp,sh)
dp=R+'integration64/formal15_deployment_actual.json';dh='5ba21807aea61698bba817e7c2329823768afe6a14431d4a973313d914cb957d';deployment=read(dp,dh)
gp=R+'integration64/final_guard.json';gh='d081f80929aaf85026c7fce6456ecdda9f9b1883106ed5e66316f27a6745c368';guard=read(gp,gh)
bp=R+'integration65/guard_before.json';bh='5a2289cad798d489b8fbb1ba339feef04329d17fdbb4e25ea3a5c6ffd70999e8';fresh=read(bp,bh)
assert deployment['target_count']==15 and guard['passed']and guard['checked']==2119 and guard['authorized_change_count']==15 and guard['exact_unchanged']==2104 and guard['unexpected_change_count']==0 and guard['save_count']==15 and guard['save_change_count']==0
assert fresh['passed']and fresh['checked']==2119 and fresh['save_count']==15 and fresh['save_change_count']==0 and fresh['unexpected_change_count']==0
def res(p):return'res://'+pathlib.Path(p).relative_to(G).as_posix()
deployed={res(r['path']):r for r in deployment['targets']};delta={}
assert set(deployed)=={r['target']for r in scope['targets']}
for t in scope['targets']:
    p=t['target'];d=deployed[p];c=t['candidate']
    assert d['old_sha256']==d['backup_sha256']==t['old_sha256']==old['core_source_sha256'][p]
    assert d['new_sha256']==c['candidate_sha256']and d['new_bytes']==c['candidate_bytes']
    delta[p]={'old':t['old_sha256'],'new':c['candidate_sha256']}
owner=copy.deepcopy(old);changes=[]
def migrate(table,label):
    before=set(table);n=0
    for p,v in delta.items():
        if p in table:
            assert table[p]==v['old'],(label,p,'EXACT_OLD_VALUE')
            table[p]=v['new'];n+=1
    assert set(table)==before
    changes.append({'domain':label,'existing_value_updates':n,'keyset_unchanged':True})
migrate(owner['core_source_sha256'],'core47')
for k in('scenes','rooms'):
    assert len(owner[k])==(8 if k=='scenes'else 5)
    for row in owner[k]:
        for field in('source_sha256','receipt_source_sha256'):migrate(row[field],k+':'+row['id']+':'+field)
assert all(same(a['receipt_source_sha256'],b['receipt_source_sha256'])for a,b in zip(owner['rooms'],old['rooms']))
assert len(owner['core_source_sha256'])==47
counts={r['id']:[len(r['source_sha256']),len(r['receipt_source_sha256'])]for r in owner['scenes']}
assert[counts[x][0]for x in('ch4_s0_luoyang_gate','ch4_s1_luoyang_yamen','ch4_s2_canal_docks','ch4_s3_luoyang_market')]==[904,1255,1734,1741]
assert counts['luoyang_artisan_residential_20261022ap']==counts['luoyang_riverside_garden_20261022ap']==[341,339]
assert all(len(r['source_sha256'])==573 for r in owner['rooms'])
reverse=copy.deepcopy(owner)
for table in[reverse['core_source_sha256']]+[r[k]for domain in('scenes','rooms')for r in reverse[domain]for k in('source_sha256','receipt_source_sha256')]:
    for p,v in delta.items():
        if p in table:assert table[p]==v['new'];table[p]=v['old']
assert same(reverse,old)and js(reverse)==js(old)
owner['status']='ROOT_DEPLOYED_EXISTING_VALUE_CLASSIFICATION15_OWNER_NOT_RUNTIME_PASS'
owner['classification_predecessor']={'path':oldop,'sha256':oldoh}
owner['actual_metadata_deployment_receipt']={'path':dp,'sha256':dh,'final_guard':{'path':gp,'sha256':gh},'prepared_scope':{'path':sp,'sha256':sh},'all_target_hashes_from_fixed_prepared_candidates_not_current_crawl':True}
owner['classification_only_values_delta']=delta
out=Q+'unified102_deployed_classification15_owner_ROOT64_READY/'
op=out+'owner_source_maps_READY.json';ob=js(owner);emit(op,ob);oh=sha(ob)
proof={'status':'INDEPENDENT_FD58_PLUS_EXACT15_DEPLOYED_VALUE_ONLY_OWNER_NO_COLLECTOR_RUNTIME_CREDIT','owner':{'path':op,'sha256':oh},'fixed_predecessor':{'path':oldop,'sha256':oldoh},'fixed_scope':{'path':sp,'sha256':sh},'deployment':{'path':dp,'sha256':dh},'final_guard':{'path':gp,'sha256':gh},'exact15_delta':delta,'domain_update_counts':changes,'complete_expected_owner_reverse_to_FD58_typed_and_serialized':True,'counts':counts,'core_count':47,'G_full573_keys_unchanged':True,'five_room_receipt_dictionaries_whole_same':True,'old_actual_Stage4CE2_kept_historical_not_relabelled':True,'no_newproof_keys_or_execution101_changes':True,'QA_actions':{'engine':False,'Stage':False,'collector':False,'source_crawl':False,'media_hash':False,'decode':False,'production_write':False}}
pp=out+'owner_text_derivation_review_READY.json';pb=js(proof);emit(pp,pb)
# NEW false successor of exact ROOT63 Market function body; only four key literals.
ofp=R+'integration63/market_scholar_READY/fixture_READY.json';ofh='6492bf7ccd9004231e32a079b26eda498ffb837161a69cda3d005b31427a520d';f0=read(ofp,ofh);f=copy.deepcopy(f0)
market=next(r for r in owner['scenes']if r['id']=='ch4_s3_luoyang_market')
f['status']='ROOT65_MARKET_EXACT_SCHOLAR_FIXED_CLASSIFICATION15_NOTREADY_ROOT_FREEZE_PENDING';f['ready']=False;f['blockers']=['Root must full-read and freeze this NEW same-body one-Market scholar check; no run authorized.']
for table,label in[(f['expected_city_sources'],'Market_expected1741'),(f['source_sha256'],'QA_guard1760')]:migrate(table,label)
assert same(f['expected_city_sources'],market['source_sha256'])and f['expected_city_source_count']==1741
assert f['owner']=={'path':oldop,'sha256':oldoh}and f['source_sha256'].pop(oldop)==oldoh
f['owner']={'path':op,'sha256':oh};assert op not in f['source_sha256'];f['source_sha256'][op]=oh
newpins={'formal_deployment':{'path':dp,'sha256':dh},'formal_final_guard':{'path':gp,'sha256':gh},'fresh_run_guard':{'path':bp,'sha256':bh}}
for k,v in newpins.items():
    oldv=f[k];assert f['source_sha256'].pop(oldv['path'])==oldv['sha256'];assert v['path']not in f['source_sha256']
    f[k]=v;f['source_sha256'][v['path']]=v['sha256']
assert len(f['source_sha256'])==1760 and f['owner_tables_ready']is True
rest=copy.deepcopy(f)
for k in('status','ready','blockers'):rest[k]=f0[k]
for k in newpins:
    v=newpins[k];assert rest['source_sha256'].pop(v['path'])==v['sha256'];rest[k]=copy.deepcopy(f0[k]);rest['source_sha256'][f0[k]['path']]=f0[k]['sha256']
assert rest['source_sha256'].pop(op)==oh;rest['owner']=copy.deepcopy(f0['owner']);rest['source_sha256'][oldop]=oldoh
for table in(rest['expected_city_sources'],rest['source_sha256']):
    for p,v in delta.items():
        if p in table:assert table[p]==v['new'];table[p]=v['old']
assert same(rest,f0)and json.dumps(rest,sort_keys=True)==json.dumps(f0,sort_keys=True)
newroot=Q+'market_scholar_identity_Field_ROOT65_NOTREADY/';fp=newroot+'fixture_NOTREADY.json';fb=js(f);emit(fp,fb);fh=sha(fb)
okp=R+'integration63/market_scholar_READY/test_READY.gd';kb=raw(okp);assert sha(kb)=='1102acfdd58eacaa21425f90042255e8e3ac9f486275781dd8658b87752c78c4'
repl=[('const FIXTURE_READY=true','const FIXTURE_READY=false'),(ofp,fp),(ofh,fh),(R+'integration63/market_scholar_READY/output/',newroot+'output/')]
nb=kb
for a,b in repl:assert nb.count(a.encode())==1;nb=nb.replace(a.encode(),b.encode(),1)
rev=nb
for a,b in reversed(repl):assert rev.count(b.encode())==1;rev=rev.replace(b.encode(),a.encode(),1)
assert rev==kb and b'const FIXTURE_READY=false'in nb
kp=newroot+'test_market_scholar_NOTREADY.gd';emit(kp,nb)
diff=''.join(difflib.unified_diff(kb.decode().splitlines(True),nb.decode().splitlines(True),fromfile=okp,tofile=kp)).encode();emit(newroot+'complete_vs_ROOT63_key_four_literal.diff',diff)
handoff={'status':'NEW_ROOT65_MARKET_SAME_FUNCTIONS_HARDFALSE_CLASSIFICATION15_OWNER_READY_NO_ENGINE','key':{'path':kp,'sha256':sha(nb)},'fixture':{'path':fp,'sha256':fh},'owner':{'path':op,'sha256':oh},'owner_proof':{'path':pp,'sha256':sha(pb)},'source_guard_count':1760,'expected_count':1741,'only_four_key_literal_wholebyte_inverse':True,'same_EOF':True,'fixture_wholetyped_sortedserialized_reverse_to_ROOT63':True,'fixture_delta_only':'ready/status/blockers,existing15source values in both tables,oneowner reference+guardleaf,three actual deployment/final/fresh credentials+guardleaf substitutions. No source key/count expansion.','credentials':newpins,'scope_unchanged':'One default Market,exact scholar/source-body/primaryconfig,camera-only inspection1PNG/saveRestore,noINPUTSpaceRoomQuest/60s20s. OriginalFAILED_ROOT63notrewritten.','QA_engine_parse_Stage_collector_decode_mediahash_or_production_write':False}
hp=newroot+'handoff_NOTREADY.json';hb=js(handoff);emit(hp,hb)
print(json.dumps({'owner':proof['owner'],'owner_proof':{'path':pp,'sha256':sha(pb)},'key':handoff['key'],'fixture':handoff['fixture'],'handoff':{'path':hp,'sha256':sha(hb)},'guard1760_expected1741_unchanged':True,'same_four_key_literals_and_fixture_reverse':True},indent=2))
