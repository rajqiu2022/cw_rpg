"""NEW frozen hall37 text only; exact hall34 function body, no test execution."""
from pathlib import Path
import copy,difflib,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
P=QA/'hall_roundtrip_ROOT34_READY';D=QA/'hall_roundtrip_ROOT37_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def rel(p):return'res://'+p.relative_to(GAME).as_posix()
def emit(name,data):
    p=D/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as out:out.write(data)
    return{'path':rel(p),'sha256':sha(p),'bytes':p.stat().st_size}
pk=P/'test_hall_roundtrip_ROOT34_READY.gd';pf=P/'hall_roundtrip_fixture_ROOT34_READY.json'
assert sha(pk)=='b91a2b332c08fdc9e38360cd158a9277e569836f7c6fe5df5129217f0100ef68'
assert sha(pf)=='6e0bb85fd73f71cdc22271174831c413023a09e482f756d3cbd52f6b2aa91a93'
ownerp=S/'performance49_estate17_actual_independent_review/owner_source_maps_READY.json'
assert sha(ownerp)=='585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f'
owner=rd(ownerp);old=rd(pf);new=copy.deepcopy(old)
ap=S/'outputs/root_estate_registry_scalar17_stage01/receipt.json'
assert sha(ap)=='96ca5fe818c0952c9f99c362ccad4deef6066acf1e0f9239219aa1db25a102e7'
actual=rd(ap);targets={r['target']:r for r in actual['targets']};assert len(targets)==17
cp=ROOT/'integration36/generated_JSON_deployment_actual.json'
gp=ROOT/'integration36/final_guard.json';bp=ROOT/'integration37/guard_before.json'
assert sha(cp)=='797db65a081f8228d7a87489576679ec4569448972fd7da3ec4a742e6546bdca'
assert sha(gp)=='f3fd504e22d186b6196130dd641aa336ef50f8df69d32a43ef599e2d520ce6e8'
assert sha(bp)=='9ee556050a801c987ffee6f5781cf2dc5af47f9b114f61ed184847f388d99479'
g=rd(gp);b=rd(bp)
assert g['passed']and g['checked']==2118and g['authorized_change_count']==17and g['save_change_count']==0
assert b['passed']and b['checked']==2118
for path,row in targets.items():
    p=GAME/path[6:];assert sha(p)==row['candidate_sha256']
    if path in new['source_sha256']:assert new['source_sha256'][path]==row['old_sha256']
    new['source_sha256'][path]=row['candidate_sha256']
city=next(r for r in owner['scenes']if r['id']=='ch4_s1_luoyang_yamen')
new['expected_city_sources']=copy.deepcopy(city['source_sha256'])
new['expected_G_global_sources']=copy.deepcopy(owner['rooms'][0]['source_sha256'])
assert len(new['expected_city_sources'])==1239and len(new['expected_G_global_sources'])==557
assert all(r['source_sha256']==new['expected_G_global_sources']for r in owner['rooms'])
for table in [new['expected_city_sources'],new['expected_G_global_sources']]:
    for path,digest in table.items():assert new['source_sha256'][path]==digest
assert old['hall_row']==new['hall_row']and len(new['hall_row']['source_sha256'])==247
reviewp=ownerp.with_name('source_stage_review_READY.json')
assert sha(reviewp)=='9d366c621019cd4e0230849dd2a21e1baba6ab0618762fea96572c033e6334c0'
failed35=ROOT/'integration35/final_guard.json';fresh36=ROOT/'integration36/guard_before.json'
assert rd(failed35)['passed']is False
assert sha(fresh36)=='1604107552c7198d9f0592e5d8cdb27d0f4f003ed7be5fccf489cdb181dbcb3f'
cause=GAME/'build/luoyang_city_full_rollout_20261022ap_system01/hall_registry_admission_fix_candidate_epoch01/cause_inverse_and_consumer_scope_READONLY.json'
assert sha(cause)=='85701180c08c1faf4defcbad39236b2810e78cf7276dbce67143fa6170b0dc15'
added=[ownerp,reviewp,ap,gp,cp,bp,failed35,fresh36,cause,pk,pf]
for p in added:
    key,digest=rel(p),sha(p)
    if key in new['source_sha256']:assert new['source_sha256'][key]==digest
    new['source_sha256'][key]=digest
new['authority']['owner']={'path':rel(ownerp),'sha256':sha(ownerp)}
for name,p in [('actual_scalar17_stage',ap),('scalar17_independent_owner_review',reviewp),('formal_Root36_after',gp),('formal_Root36_copy',cp),('Root37_before',bp),('Root35_failed_before_any_deployment_preserved',failed35),('Root36_fresh_current_after_editor_mtime_drift',fresh36),('registry_header_cause_correction',cause)]:
    new['authority'][name]={'path':rel(p),'sha256':sha(p)}
new['status']='ROOT37_HALL_METADATA_REGISTRY_SCALAR_SUCCESSOR_READY_NOT_RUN'
new['guard_derivation']='FixedROOT34 guard plus independent585717 owner/explicit96CA17 target values only, all17 deploymentheaders protected. Same1239 city and557 globalG keysets. Append immutable realRoot36 deployment/Root37fresh and priorfailed35 provenance; no livecollector expected fill.557 is intended independentguard, never an observed old G catalogue/session FIRSTFINAL.'
new['predicate_successor']['guard_scope']='ROOT34 function body and strict doorway/filter unchanged. Existing productiontarget values follow approved96CA17, fixed independentowner5857 supplies1239/557 maps; historical247row/sourceDT successor unchanged. Root33/34FAIL and35guardFAIL retained.'
new['predicate_successor']['external_tasks']='Root34preserved9C27tasks remains protected. Root35authorization failed beforewrites on two editorimport mtimes only; Root36fresh preserves those currentmetadata values, not retroactive35authority.'
assert all(new[k]==old[k]for k in old if k not in ['status','source_sha256','expected_city_sources','expected_G_global_sources','authority','guard_derivation','predicate_successor'])
fixture=emit('hall_roundtrip_fixture_ROOT37_READY.json',enc(new))
text=pk.read_bytes();key=text
changes=[(rel(pf),fixture['path']),(sha(pf),fixture['sha256']),('hall_roundtrip_ROOT34_READY/output/','hall_roundtrip_ROOT37_READY/output/')]
for a,z in changes:
    a,z=a.encode(),z.encode();assert key.count(a)==1;key=key.replace(a,z,1)
reverse=key
for a,z in reversed(changes):assert reverse.count(z.encode())==1;reverse=reverse.replace(z.encode(),a.encode(),1)
assert reverse==text
keydesc=emit('test_hall_roundtrip_ROOT37_READY.gd',key)
kd=emit('complete_key_vs_ROOT34.diff',''.join(difflib.unified_diff(text.decode().splitlines(True),key.decode().splitlines(True),fromfile='ROOT34',tofile='ROOT37')).encode())
fd=emit('complete_fixture_vs_ROOT34.diff',''.join(difflib.unified_diff(pf.read_text(encoding='utf-8').splitlines(True),enc(new).decode().splitlines(True),fromfile='ROOT34',tofile='ROOT37')).encode())
handoff=emit('handoff_ROOT37_READY_NOT_RUN.json',enc({'status':'ROOT37_READY_FIXED_OWNER5857_DEPLOYMENT36_NO_TEST_RUN','key':keydesc,'fixture':fixture,'key_diff':kd,'fixture_diff':fd,'whole_key_inverse_ROOT34_exact':True,'only_key_changes':'fixture path/SHA and output directory; all function bodies/60s/20s/20s/10s/zero pictures/INPUT/Space/routes/shape filters identical','fixed_owner':{'path':rel(ownerp),'sha256':sha(ownerp)},'actual_stage96CA':sha(ap),'Root36final':sha(gp),'Root37fresh':sha(bp),'source_guard_count':len(new['source_sha256']),'city_expected_count':1239,'G_independent_guard_count':557,'hall_historical_row_count':247,'G557_not_an_old_runtime_accepted_source_receipt':True,'all17_current_deployed_headerSHA_verified':True,'prior35failure_retained_no_late_authorization':True,'operations':{'engine':0,'parse':0,'collector':0,'geometry':0,'Stage':0,'canonical_write':0}}))
print(json.dumps({'key':keydesc,'fixture':fixture,'handoff':handoff,'guardcount':len(new['source_sha256'])}))
