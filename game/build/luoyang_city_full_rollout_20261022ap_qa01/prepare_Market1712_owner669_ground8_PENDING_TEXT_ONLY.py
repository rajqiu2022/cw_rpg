"""New pending source-only successor; does not execute or edit old GUI tests."""
from pathlib import Path
import copy
import difflib
import hashlib
import json

Q=Path(__file__).resolve().parent;G=Q.parents[1];S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01';R=G/'build/luoyang_city_full_rollout_20261022ap_root01'
P=Q/'market_pawn_single_visual_ROOT44_READY';D=Q/'market_pawn_after_ground8_PENDING_NOTREADY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p):return 'res://'+p.relative_to(G).as_posix()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def emit(n,b):
    p=D/n;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as f:f.write(b)
    return {'path':rel(p),'sha256':sha(p),'bytes':len(b)}
ok=P/'test_market_pawn_single_visual_ROOT44_READY.gd';of=P/'market_pawn_single_visual_fixture_ROOT44_READY.json'
assert sha(ok)=='583020fe2ddd3a9475f0da8a2f7550ef6856f610052906d34b0735b539d0ca66'
assert sha(of)=='5a4038ba83eb2a502af3029b0ae81456610a7e0608df025d02a18318ae1ad952'
op=S/'performance64_ground8_actual_independent_review/owner_source_maps_READY.json';vp=op.with_name('source_stage_review_READY.json')
rp=S/'outputs/root_market_ground_exact8_stage01/receipt.json'
qp=Q/'owner64_669_full8scene5room_core47_fixedE717_existing8value_review_READY.json'
assert sha(op)=='669e5d3e4ece06cf33707d6afdced6d65dc5ca7785b8f44ff19698dde741f7c0'
assert sha(vp)=='cfe5264353ede060100454e510ab1088b91a581fb4648d8554382378a0425a2d'
assert sha(rp)=='1dff38bf897130d74bb6c0d51b4436fa25d97de9bb8e4502ea8490364262ccfe'
assert sha(qp)=='2638be4d8b42e3b2c1751b031cf78d28175422f84e19323a402e1e66481f35f4'
owner,stage=rd(op),rd(rp);targets={r['target']:r for r in stage['targets']}
old=rd(of);f=copy.deepcopy(old)
for path,row in targets.items():
    assert f['source_sha256'][path]==row['old_sha256'];f['source_sha256'][path]=row['candidate_sha256']
f['expected_sources']=copy.deepcopy(next(r for r in owner['scenes'] if r['id']=='ch4_s3_luoyang_market')['source_sha256'])
assert len(f['expected_sources'])==1712 and set(f['expected_sources'])==set(old['expected_sources'])
for table in [owner['core_source_sha256'],f['expected_sources']]:
    for path,digest in table.items():assert f['source_sha256'][path]==digest
oldowner=S/'performance60_market_parent30_actual_independent_review/owner_source_maps_READY.json'
oldreview=oldowner.with_name('source_stage_review_READY.json')
oldstage=S/'outputs/root_market_complete_parent30_stage01/receipt.json'
oldqa=Q/'owner60_E717_full8scene5room_core47_independent_recipe_admission_READY.json'
swaps=[(oldowner,op),(oldreview,vp),(oldstage,rp),(oldqa,qp)]
for before,after in swaps:
    assert f['source_sha256'].pop(rel(before))==sha(before) and f['authority'].pop(rel(before))==sha(before)
    f['source_sha256'][rel(after)]=sha(after);f['authority'][rel(after)]=sha(after)
removed=[]
for p in [R/'integration43/final_guard.json',R/'integration43/generated_JSON_deployment_actual.json',R/'integration44/guard_before.json']:
    assert f['source_sha256'].pop(rel(p))==sha(p) and f['authority'].pop(rel(p))==sha(p)
    removed.append({'path':rel(p),'sha256':sha(p)})
f['status']='MARKET_GROUND8_FIXED_OWNER6691712_PENDING_ROOT45_FORMAL_NOT_RUN';f['ready']=False
f['blockers']=['Await Root45 exact8 formal final guard/copy receipt and Root46 fresh guard. Do not run.']
f['pending_deployment_authority']={'Root45_final_guard_sha256':None,'Root45_JSONcopy_sha256':None,'Root46_fresh_guard_sha256':None}
f['scope']['expected_source_recipe']='Fixed independent owner669 Market1712 inheritedE717 with actual1DFF exact8 existing values only, no new source key/proof95. Preserve Root39SOURCE_ONLY2. ROOT44groundFAIL and previous failures retained; no observedcollector/current expected fill.'
assert len(f['source_sha256'])==1742
fixture=emit('market_pawn_ground8_fixture_PENDING_NOTREADY.json',enc(f))
body=ok.read_bytes();key=body
changes=[('const FIXTURE_READY=true','const FIXTURE_READY=false'),(rel(of),fixture['path']),(sha(of),fixture['sha256']),('market_pawn_single_visual_ROOT44_READY/output/','market_pawn_after_ground8_PENDING_NOTREADY/output/')]
for a,b in changes:assert key.count(a.encode())==1;key=key.replace(a.encode(),b.encode(),1)
back=key
for a,b in reversed(changes):assert back.count(b.encode())==1;back=back.replace(b.encode(),a.encode(),1)
assert back==body
k=emit('test_market_pawn_ground8_PENDING_NOTREADY.gd',key)
kd=emit('complete_key_vs_FAILED_ROOT44.diff',''.join(difflib.unified_diff(body.decode().splitlines(True),key.decode().splitlines(True),fromfile='ROOT44_FAIL_PRESERVED',tofile='GROUND8_PENDING')).encode())
fd=emit('complete_fixture_vs_ROOT44.diff',''.join(difflib.unified_diff(enc(old).decode().splitlines(True),enc(f).decode().splitlines(True),fromfile='ROOT44_FIXED_E717',tofile='PENDING_FIXED669')).encode())
h=emit('handoff_PENDING_ROOT45_DEPLOYMENT_NOT_RUN.json',enc({'status':'NEW_ROOT46_GROUND8_SOURCE_SUCCESSOR_PENDING_NOTREADY',
    'key':k,'fixture':fixture,'keydiff':kd,'fixturediff':fd,'source_guard_pending':1742,'expected_market_count':1712,
    'fixed_owner669':sha(op),'actualStage1DFF':sha(rp),'whole_keybyte_inverse_ROOT44_only_four_readiness_path_literals':True,
    'function_body_allbytes_exact_ROOT44':True,'no_source_count_literal_change':True,
    'fixture_existing8value_migration_no_newkey':True,'provenance4swaps':[(rel(a),rel(b)) for a,b in swaps],
    'old_deployment3_removed_wait_actual45_and46':removed,
    'scope':'Same60s/20s publicnear5701928→trueINPUT5701904 ordinary1920x1080zoom1 onePNG/noSpaceRoomCollectorGeometryCameraWrites.',
    'no_READY_or_runtime_claim':True,'operations':{'engine':0,'parse':0,'Stage':0,'collector':0,'canonical':0}}))
print(json.dumps({'key':k,'fixture':fixture,'handoff':h,'ready':False}))
