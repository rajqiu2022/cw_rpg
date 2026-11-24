"""NEW exact READY text plus static inverse after Root deployment. Never run GUI."""
from pathlib import Path
import copy
import difflib
import hashlib
import json

Q=Path(__file__).resolve().parent;G=Q.parents[1]
S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
R=G/'build/luoyang_city_full_rollout_20261022ap_root01'
P=Q/'market_pawn_after_complete_parent30_PENDING_NOTREADY'
D=Q/'market_pawn_single_visual_ROOT44_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p):return 'res://'+p.relative_to(G).as_posix()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def same(a,b):
    if type(a) is not type(b):return False
    if isinstance(a,dict):return list(a)==list(b) and all(same(a[k],b[k]) for k in a)
    if isinstance(a,list):return len(a)==len(b) and all(same(x,y) for x,y in zip(a,b))
    return a==b
def emit(name,b):
    p=D/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as f:f.write(b)
    return {'path':rel(p),'sha256':sha(p),'bytes':len(b)}
pk=P/'test_market_pawn_complete_parent30_PENDING_NOTREADY.gd'
pf=P/'market_pawn_complete_parent30_fixture_PENDING_NOTREADY.json'
assert sha(pk)=='72edff18c0089597b35d147361a4fa717878d77fe708a093e5aa063c46021f31'
assert sha(pf)=='aef463c026b630b5e59cd7b5162121eb1c5b1b19cf83948486c04fc2e05d259d'
gp=R/'integration43/final_guard.json';cp=R/'integration43/generated_JSON_deployment_actual.json';bp=R/'integration44/guard_before.json'
assert sha(gp)=='13b8a316c70e128b5f5edeabd3228573a0f1c10f3a2733d91aa8228ff207d268'
assert sha(cp)=='2b32391b13f0418b1f5e2841fa7310217ad54d64e4cafb37dc84d43399cbdeca'
assert sha(bp)=='6414e69b22da56ae3d2173bc0468adb4e55cc488780af2b7c0772d45b9d63ef9'
guard,fresh=rd(gp),rd(bp)
assert guard['passed'] and guard['checked']==2118 and guard['authorized_change_count']==30 and guard['exact_unchanged']==2088
assert guard['unexpected_change_count']==guard['save_change_count']==0 and guard['save_count']==15
assert fresh['passed'] and fresh['checked']==2118 and guard['facts']==fresh['facts']
copyreceipt=rd(cp)
assert copyreceipt['GD_copied']==copyreceipt['native_or_save_writes']==0 and len(copyreceipt['rows'])==15
rp=S/'outputs/root_market_complete_parent30_stage01/receipt.json'
assert sha(rp)=='464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f'
stage=rd(rp);targets={x['target']:x for x in stage['targets']}
assert len(targets)==30
for path,row in targets.items():
    p=G/path[6:];assert sha(p)==row['candidate_sha256']
adapter=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01/finite_adapter_production08/finite_adapter_READY.gd'
assert adapter.stat().st_size==31206 and not adapter.read_bytes().endswith(b'\n') and b'\r' not in adapter.read_bytes()
assert sha(adapter)=='cf2aa3da4f8dbafd30d48d9310d69d7eacb9f17d25e47ce02ca221835eff3736'
op=S/'performance60_market_parent30_actual_independent_review/owner_source_maps_READY.json'
assert sha(op)=='e7177cb8e97e957bab6f0f88bbcbb5bb5d82de4087f2bb45085d4cf06f2a1f03'
owner=rd(op)
old=rd(pf);f=copy.deepcopy(old)
assert old['ready'] is False and len(old['source_sha256'])==1742
for p in [gp,cp,bp]:
    assert rel(p) not in f['source_sha256'] and rel(p) not in f['authority']
    f['source_sha256'][rel(p)]=sha(p);f['authority'][rel(p)]=sha(p)
f['status']='ROOT44_CURRENT_MARKET_SINGLEIMAGE_COMPLETE_PARENT30_FIXED_E717_READY_NOT_RUN'
f['ready']=True
del f['blockers']
f['pending_deployment_authority']={'Root43_final_guard_sha256':sha(gp),'Root43_JSONcopy_sha256':sha(cp),'next_fresh_guard_sha256':sha(bp)}
assert len(f['source_sha256'])==1745
expected=next(x for x in owner['scenes'] if x['id']=='ch4_s3_luoyang_market')['source_sha256']
assert f['expected_sources']==expected and len(expected)==1712
for path,digest in {**owner['core_source_sha256'],**expected}.items():assert f['source_sha256'][path]==digest
back=copy.deepcopy(f)
for p in [gp,cp,bp]:del back['source_sha256'][rel(p)];del back['authority'][rel(p)]
for key in ['status','ready','blockers','pending_deployment_authority']:back[key]=old[key]
# Dict top-level insertion order differs only from deleted blocker reinsertion;
# compare complete strict values, then fixed JSON ordering is re-emitted via old key order.
assert set(back)==set(old) and all(same(back[k],old[k]) for k in old)
back={k:back[k] for k in old}
assert enc(back)==pf.read_bytes()
fixture=emit('market_pawn_single_visual_fixture_ROOT44_READY.json',enc(f))
body=pk.read_bytes();key=body
changes=[('const FIXTURE_READY=false','const FIXTURE_READY=true'),(rel(pf),fixture['path']),(sha(pf),fixture['sha256']),('market_pawn_after_complete_parent30_PENDING_NOTREADY/output/','market_pawn_single_visual_ROOT44_READY/output/')]
for a,b in changes:assert key.count(a.encode())==1;key=key.replace(a.encode(),b.encode(),1)
back=key
for a,b in reversed(changes):assert back.count(b.encode())==1;back=back.replace(b.encode(),a.encode(),1)
assert back==body
k=emit('test_market_pawn_single_visual_ROOT44_READY.gd',key)
prior=Q/'market_pawn_single_visual_ROOT41_READY/test_market_pawn_single_visual_ROOT41_READY.gd'
oldfixture=prior.with_name('market_pawn_single_visual_fixture_ROOT41_READY.json')
original=prior.read_bytes();inverse=key
fullchanges=[(rel(oldfixture),fixture['path']),(sha(oldfixture),fixture['sha256']),('market_pawn_single_visual_ROOT41_READY/output/','market_pawn_single_visual_ROOT44_READY/output/'),('1702','1712')]
for a,b in reversed(fullchanges):
    assert inverse.count(b.encode())==(5 if a=='1702' else 1)
    inverse=inverse.replace(b.encode(),a.encode())
assert inverse==original
kd=emit('complete_key_vs_FAILED_ROOT41.diff',''.join(difflib.unified_diff(original.decode().splitlines(True),key.decode().splitlines(True),fromfile='ROOT41_FAILED_PRESERVED',tofile='ROOT44_READY')).encode())
fd=emit('complete_fixture_vs_ROOT41.diff',''.join(difflib.unified_diff(enc(rd(oldfixture)).decode().splitlines(True),enc(f).decode().splitlines(True),fromfile='ROOT41_FIXED_FC11_1702',tofile='ROOT44_FIXED_E717_1712')).encode())
freeze=emit('mechanical_freeze_key_vs_PENDING.diff',''.join(difflib.unified_diff(body.decode().splitlines(True),key.decode().splitlines(True),fromfile='PENDING72ED',tofile='ROOT44_READY')).encode())
static=emit('independent_final1712_static_admission_READY.json',enc({
    'status':'STATIC_ROOT44_READY_ADMISSION_FOR_ONE_ROOT_REVIEWED_GUI_NOT_EXECUTED_BY_QA',
    'key':k,'fixture':fixture,'expected_owner_E717':sha(op),'expected_sources':1712,'guard_sources':1745,
    'checks':{'current30_deployed_SHAbytes_all_exact_to464BA':True,'adapterCF2AA31206_noCR_noFinalLF_exact':True,
        'Root43_guard2118_only30authorized_save15_same':True,'Root44fresh_fullfacts_exact_to_Root43final':True,
        'key_pending_four_literal_inverse':True,'key_ROOT41_only_fixturepath_SHA_output_and_five1702to1712_literals':True,
        'complete_fixture_inverse_PENDING_after_only_readiness_and_three_actual_authorities':True,
        'expected_full1712_exact_independent_E717_no_currentfill':True,'all47core_and_full1712_source_values_bound':True,
        'same_60s20s_near5701928_trueINPUT5701904_zoom1_1920x1080_onePNG_noSpaceRoom':True,
        'Root39_two_SOURCE_ONLY_preserved_no_runtimeTexture_credit':True},
    'limits':['Root must independently pin and read frozen complete key/fixture before unique GUI run',
        'All previous failures/crashes remain; no successful Market entry/ART claim yet',
        'No engine/parse/collector/nativegeometry or packet/image decode done by QA'],
    'operations':{'engine':0,'parse':0,'collector':0,'Stage':0,'canonical':0}}))
handoff=emit('handoff_ROOT44_READY_NOT_RUN.json',enc({
    'status':'ROOT44_NEW_SINGLE_MARKET_IMAGE_FIXED_E7171712_AFTER_EXACT30_FORMAL_NOT_RUN',
    'key':k,'fixture':fixture,'static_review':static,'full_keydiff_ROOT41':kd,'full_fixturediff_ROOT41':fd,'mechanical_pending_keydiff':freeze,
    'owner_E717':sha(op),'actualStage464BA':sha(rp),'Root43_deployment_final':sha(gp),'Root43_JSONcopy':sha(cp),'Root44_fresh':sha(bp),
    'expected_market_sources':1712,'guard_count':1745,
    'scope':'60swhole/20sentry; onepublicnear5701928 one24px trueINPUT5701904; ordinaryactive1920x1080zoom1Camera onePNG. NoSpace/room/crossdistrict/cameraplayerpositionwrites/collector/newgeometry.',
    'prior_failed_ROOT38_ROOT41_and_false_pending_preserved':True,'operations':{'engine':0,'parse':0,'collector':0,'Stage':0,'canonical':0}}))
print(json.dumps({'key':k,'fixture':fixture,'static':static,'handoff':handoff,'key_lines':len(key.splitlines()),'guard':1745}))
