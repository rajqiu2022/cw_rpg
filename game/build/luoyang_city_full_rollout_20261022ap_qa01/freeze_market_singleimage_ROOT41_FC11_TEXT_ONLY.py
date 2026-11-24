"""Only NEW fixture/key text. Expectation from actual independent owner, never live."""
from pathlib import Path
import copy,difflib,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01';ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
P=QA/'market_pawn_single_visual_ROOT38_READY';PENDING=QA/'market_pawn_post_SOURCE_ONLY_PENDING_NOTREADY'
D=QA/'market_pawn_single_visual_ROOT41_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p):return'res://'+p.relative_to(GAME).as_posix()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def emit(name,data):
    p=D/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(data)
    return{'path':rel(p),'sha256':sha(p),'bytes':p.stat().st_size}
oldfp=P/'market_pawn_single_visual_fixture_ROOT38_READY.json';oldkp=P/'test_market_pawn_single_visual_ROOT38_READY.gd'
pendingkp=PENDING/'test_market_pawn_after_SOURCE_ONLY_PENDING_NOTREADY.gd';pendingfp=PENDING/'market_pawn_after_SOURCE_ONLY_fixture_PENDING_NOTREADY.json'
assert sha(oldfp)=='b57f43d13a1251f933928467883d6c74d100ceedc248669f49586d939c79881b'
assert sha(oldkp)=='08e9da3acd99281f2196ffd6060a1c5eb0383953a2b274f106d837b174554274'
assert sha(pendingkp)=='62b1dee442402646bec8981207f58fa1d57783e673db334e71f2fb19ced52789'
assert sha(pendingfp)=='a04794b259b28d50a2ae9014a51e092d790b82ac9e9b6597c573422a9b513efc'
op=S/'performance54_market_tuple3_actual_independent_review/owner_source_maps_READY.json';vp=op.with_name('source_stage_review_READY.json')
assert sha(op)=='fc11a02989c4e9d57628dccaa82c08cd11df6767c954f4ed4829b5dcdffc0f02'
assert sha(vp)=='b09ada8b5d0f2c8949ff6c069a3d0bc4b13bdbdecdb107bdf9a74d80eda07d48'
owner=rd(op);stagep=S/'outputs/root_market_source_only_tuple3_stage01/receipt.json';stage=rd(stagep)
assert sha(stagep)=='4c6121af07069bd98b115763ab5e02d7cd8cc2206810b8f9340430708f43a999'
targets={r['target']:r for r in stage['targets']};assert len(targets)==3
gp,cp,bp=ROOT/'integration40/final_guard.json',ROOT/'integration40/generated_JSON_deployment_actual.json',ROOT/'integration41/guard_before.json'
assert sha(bp)=='a56c7db8f6825c5341beeb402fa239406100cae7acc8b1f105cdcbcdf36b5697'
g=rd(gp);assert sha(gp).startswith('ede18')and g['passed']and g['checked']==2118 and g['authorized_change_count']==3 and g['save_change_count']==0
assert sha(cp).startswith('6840')and rd(bp)['passed']and rd(bp)['checked']==2118
old=rd(oldfp);f=copy.deepcopy(old)
for path,tr in targets.items():
    assert old['source_sha256'][path]==tr['old_sha256'];f['source_sha256'][path]=tr['candidate_sha256']
    assert sha(GAME/path[6:])==tr['candidate_sha256']
f['expected_sources']=copy.deepcopy(next(r for r in owner['scenes']if r['id']=='ch4_s3_luoyang_market')['source_sha256'])
assert len(f['expected_sources'])==1702 and len(set(f['expected_sources'])-set(old['expected_sources']))==2
for p,h in owner['core_source_sha256'].items():
    if p in f['source_sha256']:assert f['source_sha256'][p]==h
    f['source_sha256'][p]=h
for p,h in f['expected_sources'].items():
    if p in f['source_sha256']:assert f['source_sha256'][p]==h
    f['source_sha256'][p]=h
admission=ROOT/'integration39/source_only_two_leaf_admission.json'
assert sha(admission)=='b1bb3a2ce1067f0d5029f052fe59631e785ca114a591dff5de07150e52d368e4'
proofp=QA/'proof_tuple39_117100_SOURCE_ONLY_two_leaf_evidence_independent_review_READY.json'
assert sha(proofp)=='e935cede7865d93a98b67919872609d1db1ef19682fd154d008c9c5a9f08c202'
ownerreview=QA/'market54_FC11_owner_independent_full8scene5room_recipe_review_READY.json'
assert sha(ownerreview)=='56e565b1bf76395efacf8a9f86c2fd910569e7d3e07223216e8744bde49f303f'
added=[op,vp,stagep,gp,cp,bp,admission,proofp,ownerreview,oldkp,oldfp]
for p in added:f['source_sha256'][rel(p)]=sha(p);f['authority'][rel(p)]=sha(p)
f['status']='ROOT41_CURRENT_MARKET_SINGLEIMAGE_SOURCE_ONLY_CLOSURE_READY_NOT_RUN'
f['ready']=True
f['scope']['expected_source_recipe']='FixedFC11 Market1702 wholemap inherited5857+actual4C612 exact3headers+RootB1BB_SOURCE_ONLY2leaves. No observedcollector/currentfile expected backfill. Root38FAIL retained.'
fixture=emit('market_pawn_single_visual_fixture_ROOT41_READY.json',enc(f))
body=pendingkp.read_bytes();key=body
changes=[('const FIXTURE_READY=false','const FIXTURE_READY=true'),(rel(pendingfp),fixture['path']),(sha(pendingfp),fixture['sha256']),('market_pawn_post_SOURCE_ONLY_PENDING_NOTREADY/output/','market_pawn_single_visual_ROOT41_READY/output/')]
for a,b in changes:assert key.count(a.encode())==1;key=key.replace(a.encode(),b.encode(),1)
inverse=key
for a,b in reversed(changes):assert inverse.count(b.encode())==1;inverse=inverse.replace(b.encode(),a.encode(),1)
assert inverse==body
k=emit('test_market_pawn_single_visual_ROOT41_READY.gd',key)
diff=emit('complete_key_vs_ROOT38.diff',''.join(difflib.unified_diff(oldkp.read_text(encoding='utf-8').splitlines(True),key.decode().splitlines(True),fromfile='ROOT38_FAILED_PRESERVED',tofile='ROOT41_READY')).encode())
fd=emit('complete_fixture_vs_ROOT38.diff',''.join(difflib.unified_diff(oldfp.read_text(encoding='utf-8').splitlines(True),enc(f).decode().splitlines(True),fromfile='ROOT38_FIXED1700_FAILED',tofile='ROOT41_FIXED_FC11_1702')).encode())
handoff=emit('handoff_ROOT41_READY_NOT_RUN.json',enc({'status':'ROOT41_NEW_SINGLE_MARKET_IMAGE_ROOT_REVIEW_BEFORE_ONE_GUI_NOT_RUN','key':k,'fixture':fixture,'full_keydiff_ROOT38':diff,'full_fixturediff_ROOT38':fd,'whole_key_inverse_pending62B1':True,'functions_ROOT38_only5sourcecount_literals_1700_to1702':True,'fixed_owner_FC11':sha(op),'actualStage4C612':sha(stagep),'formalRoot40_final':sha(gp),'formalRoot40_copy':sha(cp),'Root41_fresh':sha(bp),'expected_market_sources':1702,'guard_count':len(f['source_sha256']),'scope_unchanged':'60swhole/20sentry; onepublicnear5701928, one24px realINPUT5701904; originalactive1920x1080zoom1camera onePNG;0Space/room/crossdistrict/geometry/collector/cameraorplayerpositionwrite.','two_newleaves_SOURCE_ONLY_not_runtimeTexture_credit':True,'old38_FAIL_and_false62B1_preserved':True,'operations':{'engine':0,'parse':0,'collector':0,'Stage':0,'canonical_write':0}}))
print(json.dumps({'key':k,'fixture':fixture,'handoff':handoff,'guard_count':len(f['source_sha256']),'Root40final':sha(gp),'copy':sha(cp)}))
