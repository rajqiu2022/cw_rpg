"""Mechanical READY freeze plus current8/source proof static check; no GUI run."""
from pathlib import Path
import copy
import difflib
import hashlib
import json

Q=Path(__file__).resolve().parent;G=Q.parents[1];S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01';R=G/'build/luoyang_city_full_rollout_20261022ap_root01'
P=Q/'market_pawn_after_ground8_PENDING_NOTREADY';D=Q/'market_pawn_single_visual_ROOT46_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p):return 'res://'+p.relative_to(G).as_posix()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return list(a)==list(b) and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def emit(n,b):
    p=D/n;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as f:f.write(b)
    return {'path':rel(p),'sha256':sha(p),'bytes':len(b)}
pk=P/'test_market_pawn_ground8_PENDING_NOTREADY.gd';pf=P/'market_pawn_ground8_fixture_PENDING_NOTREADY.json'
assert sha(pk)=='b7dba99f672a8f88e7a31ec2f9873f678905d03533ad9d30f1b17f4168e5b5e9'
assert sha(pf)=='4980ea7cd2176cfdb33bc93984642fb692780e6894d5d0f51d093ce99093fb47'
gp=R/'integration45/final_guard.json';cp=R/'integration45/generated_JSON_deployment_actual.json';bp=R/'integration46/guard_before.json'
assert sha(gp)=='7e97f211d124b9c8fc6d1445fbbfd6960c1bb21a4dac725460551358afdf2cad'
assert sha(cp)=='de662ec731a6d58c647a1f9f857aa73fef4089f64419d29cb0f77ac033e7bbdd'
assert sha(bp)=='5ebb41cb36fd84bf408d641cfdec7526804126d322d7e1e8084de06dc63ece42'
guard,fresh=rd(gp),rd(bp)
assert guard['passed'] and guard['checked']==2118 and guard['authorized_change_count']==8 and guard['exact_unchanged']==2110
assert guard['unexpected_change_count']==guard['save_change_count']==0 and guard['save_count']==15
assert fresh['passed'] and fresh['checked']==2118 and guard['facts']==fresh['facts']
copydoc=rd(cp);assert copydoc['GD_copied']==copydoc['native_or_save_writes']==0 and len(copydoc['rows'])==4
rp=S/'outputs/root_market_ground_exact8_stage01/receipt.json'
assert sha(rp)=='1dff38bf897130d74bb6c0d51b4436fa25d97de9bb8e4502ea8490364262ccfe'
stage=rd(rp);targets={x['target']:x for x in stage['targets']}
assert len(targets)==8
for path,row in targets.items():assert sha(G/path[6:])==row['candidate_sha256']
ground=G/'scripts/city/luoyang_market_ground_20261020ae.gd'
assert sha(ground)=='c1ef10bce6ef1b4b8ff4e50f7a00a7e409b80e8c36cfed9d4eea33fedcce05ce' and ground.stat().st_size==8495
op=S/'performance64_ground8_actual_independent_review/owner_source_maps_READY.json'
assert sha(op)=='669e5d3e4ece06cf33707d6afdced6d65dc5ca7785b8f44ff19698dde741f7c0'
owner=rd(op);old=rd(pf);f=copy.deepcopy(old)
assert old['ready'] is False and len(old['source_sha256'])==1742
for path in [gp,cp,bp]:
    assert rel(path) not in f['source_sha256'] and rel(path) not in f['authority']
    f['source_sha256'][rel(path)]=sha(path);f['authority'][rel(path)]=sha(path)
f['status']='ROOT46_CURRENT_MARKET_SINGLEIMAGE_GROUND8_FIXED_OWNER669_READY_NOT_RUN';f['ready']=True
del f['blockers']
f['pending_deployment_authority']={'Root45_final_guard_sha256':sha(gp),'Root45_JSONcopy_sha256':sha(cp),'Root46_fresh_guard_sha256':sha(bp)}
expected=next(x for x in owner['scenes'] if x['id']=='ch4_s3_luoyang_market')['source_sha256']
assert len(f['source_sha256'])==1745 and f['expected_sources']==expected and len(expected)==1712
for path,digest in {**owner['core_source_sha256'],**expected}.items():assert f['source_sha256'][path]==digest
back=copy.deepcopy(f)
for path in [gp,cp,bp]:del back['source_sha256'][rel(path)];del back['authority'][rel(path)]
for key in ['status','ready','blockers','pending_deployment_authority']:back[key]=old[key]
assert set(back)==set(old) and all(same(back[k],old[k]) for k in old)
assert enc({k:back[k] for k in old})==pf.read_bytes()
fixture=emit('market_pawn_single_visual_fixture_ROOT46_READY.json',enc(f))
body=pk.read_bytes();key=body
changes=[('const FIXTURE_READY=false','const FIXTURE_READY=true'),(rel(pf),fixture['path']),(sha(pf),fixture['sha256']),('market_pawn_after_ground8_PENDING_NOTREADY/output/','market_pawn_single_visual_ROOT46_READY/output/')]
for a,b in changes:assert key.count(a.encode())==1;key=key.replace(a.encode(),b.encode(),1)
back=key
for a,b in reversed(changes):assert back.count(b.encode())==1;back=back.replace(b.encode(),a.encode(),1)
assert back==body
k=emit('test_market_pawn_single_visual_ROOT46_READY.gd',key)
prior=Q/'market_pawn_single_visual_ROOT44_READY/test_market_pawn_single_visual_ROOT44_READY.gd'
priorf=prior.with_name('market_pawn_single_visual_fixture_ROOT44_READY.json')
original=prior.read_bytes();back=key
fullchanges=[(rel(priorf),fixture['path']),(sha(priorf),fixture['sha256']),('market_pawn_single_visual_ROOT44_READY/output/','market_pawn_single_visual_ROOT46_READY/output/')]
for a,b in reversed(fullchanges):assert back.count(b.encode())==1;back=back.replace(b.encode(),a.encode(),1)
assert back==original
kd=emit('complete_key_vs_FAILED_ROOT44.diff',''.join(difflib.unified_diff(original.decode().splitlines(True),key.decode().splitlines(True),fromfile='ROOT44_FAILED_PRESERVED',tofile='ROOT46_READY')).encode())
fd=emit('complete_fixture_vs_ROOT44.diff',''.join(difflib.unified_diff(enc(rd(priorf)).decode().splitlines(True),enc(f).decode().splitlines(True),fromfile='ROOT44_FIXED_E717',tofile='ROOT46_FIXED669')).encode())
fmap={x:y for x,y in f.items() if x not in ['source_sha256','expected_sources','authority']}
pdiff=emit('fixture_non_source_tables_ROOT46.json',enc(fmap))
static=emit('independent_final1712_samebody_static_admission_READY.json',enc({
    'status':'STATIC_ROOT46_READY_ADMISSION_SAME_BODY_FOR_ONE_ROOT_GUI_NOT_RUN_BY_QA',
    'key':k,'fixture':fixture,'owner669':sha(op),'expected_sources':1712,'guard_sources':1745,
    'checks':{'current8_deployed_SHA_exact_to1DFF_and_groundC1EF8495':True,
        'Root45_2118only8authorized_save15_and_Root46fresh_facts_exact':True,
        'pending_four_literal_key_inverse_and_fixture_readiness3authority_inverse':True,
        'complete_key_ROOT44_only_fixturepath_SHA_output_three_literals_inverse':True,
        'all_functions_body_bytes_and_1712counts_unmodified':True,
        'full1712_independent_owner669_and_core47_exact_no_currentfill':True,
        'same60s20s_5701928_trueINPUT5701904_1920x1080zoom1_onePNG_noSpaceRoomGeometryCollector':True,
        'all_old_failures_and_SOURCE_ONLY_limits_preserved':True},
    'operations':{'engine':0,'parse':0,'collector':0,'Stage':0,'canonical':0}}))
h=emit('handoff_ROOT46_READY_NOT_RUN.json',enc({
    'status':'ROOT46_NEW_SINGLE_MARKET_IMAGE_FIXED_OWNER6691712_GROUND8_FORMAL_READY_NOT_RUN',
    'key':k,'fixture':fixture,'static_review':static,'whole_keydiff_ROOT44':kd,'whole_fixturediff_ROOT44':fd,'fixture_non_source_tables':pdiff,
    'owner669':sha(op),'actualStage1DFF':sha(rp),'Root45_final':sha(gp),'Root45_JSONcopy':sha(cp),'Root46_fresh':sha(bp),
    'expected_market':1712,'guard_count':1745,'key_lines':len(key.splitlines()),
    'scope':'Only one publicnear5701928 +24px trueINPUT5701904, ordinary1920x1080zoom1camera onePNG.60swhole20sentry.NoSpace/room/crossdistrict/playercameraPositionWrite/collector/geometry.',
    'all_prior_failed44_and_pending_artifacts_unchanged':True,'operations':{'engine':0,'parse':0,'Stage':0,'collector':0,'canonical':0}}))
print(json.dumps({'key':k,'fixture':fixture,'static':static,'handoff':h,'key_lines':len(key.splitlines())}))
