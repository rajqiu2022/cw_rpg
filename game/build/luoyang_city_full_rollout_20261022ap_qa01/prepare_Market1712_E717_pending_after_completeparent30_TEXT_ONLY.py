"""Only NEW NOTREADY test text; fixed independent owner, no live observations."""
from pathlib import Path
import copy
import difflib
import hashlib
import json

Q=Path(__file__).resolve().parent;G=Q.parents[1]
S=G/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
R=G/'build/luoyang_city_full_rollout_20261022ap_root01'
P=Q/'market_pawn_single_visual_ROOT41_READY'
D=Q/'market_pawn_after_complete_parent30_PENDING_NOTREADY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p):return 'res://'+p.relative_to(G).as_posix()
def enc(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def emit(name,value):
    p=D/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb') as f:f.write(value)
    return {'path':rel(p),'sha256':sha(p),'bytes':len(value)}
ok=P/'test_market_pawn_single_visual_ROOT41_READY.gd'
of=P/'market_pawn_single_visual_fixture_ROOT41_READY.json'
assert sha(ok)=='303d54c3430d978c0d93f235b2d715107261f7df500ae539448dd5bd31435db6'
assert sha(of)=='eac1f55debb3b5e5bb08d69666663323b4db6a67b394b94a4743862a9f948301'
op=S/'performance60_market_parent30_actual_independent_review/owner_source_maps_READY.json'
vp=op.with_name('source_stage_review_READY.json')
rp=S/'outputs/root_market_complete_parent30_stage01/receipt.json'
qp=Q/'owner60_E717_full8scene5room_core47_independent_recipe_admission_READY.json'
assert sha(op)=='e7177cb8e97e957bab6f0f88bbcbb5bb5d82de4087f2bb45085d4cf06f2a1f03'
assert sha(vp)=='8b03177179bc07f83a26e1af168895bc8fbfb0ac4f0f79a815246a05ddf6beec'
assert sha(rp)=='464ba58b42b26830dc52b0b69511cde141df4fcc18e2aa7094f7794022a2190f'
assert sha(qp)=='56fd391562902fbe95b958a13b1a999501eb1069a4f640716586ae1f47ff8f25'
owner,stage=rd(op),rd(rp);targets={x['target']:x for x in stage['targets']}
old=rd(of);f=copy.deepcopy(old)
for path,row in targets.items():
    if path in f['source_sha256']:
        assert f['source_sha256'][path]==row['old_sha256'];f['source_sha256'][path]=row['candidate_sha256']
f['expected_sources']=copy.deepcopy(next(x for x in owner['scenes'] if x['id']=='ch4_s3_luoyang_market')['source_sha256'])
assert len(f['expected_sources'])==1712 and len(set(f['expected_sources'])-set(old['expected_sources']))==10
for table in [owner['core_source_sha256'],f['expected_sources']]:
    for path,digest in table.items():
        if path in f['source_sha256']:assert f['source_sha256'][path]==digest
        f['source_sha256'][path]=digest
oldowner=S/'performance54_market_tuple3_actual_independent_review/owner_source_maps_READY.json'
oldreview=oldowner.with_name('source_stage_review_READY.json')
oldstage=S/'outputs/root_market_source_only_tuple3_stage01/receipt.json'
oldqa=Q/'market54_FC11_owner_independent_full8scene5room_recipe_review_READY.json'
swaps=[(oldowner,op),(oldreview,vp),(oldstage,rp),(oldqa,qp)]
for before,after in swaps:
    assert f['source_sha256'].pop(rel(before))==sha(before)
    assert f['authority'].pop(rel(before))==sha(before)
    f['source_sha256'][rel(after)]=sha(after);f['authority'][rel(after)]=sha(after)
removed=[]
for path in [R/'integration40/final_guard.json',R/'integration40/generated_JSON_deployment_actual.json',R/'integration41/guard_before.json']:
    assert f['source_sha256'].pop(rel(path))==sha(path) and f['authority'].pop(rel(path))==sha(path)
    removed.append({'path':rel(path),'sha256':sha(path)})
f['status']='MARKET_AFTER_COMPLETE_PARENT30_FIXED_E7171712_PENDING_DEPLOYMENT_NOT_RUN'
f['ready']=False
f['blockers']=['Await Root exact30 formal deployment final guard, exact adapter EOF result, JSONcopy receipt and next fresh guard; do not run.']
f['pending_deployment_authority']={'Root43_final_guard_sha256':None,'Root43_JSONcopy_sha256':None,'next_fresh_guard_sha256':None}
f['scope']['expected_source_recipe']='Fixed independent ownerE717 Market1712 derived from FC11+actualStage464BA exact30existingvalues+10fixedproofs. Preserve Root39 SOURCE_ONLY2; no runtime collector/current expected fill. ROOT41 T inverse FAIL remains.'
fixture=emit('market_pawn_complete_parent30_fixture_PENDING_NOTREADY.json',enc(f))
oldtext=ok.read_bytes();key=oldtext
changes=[('const FIXTURE_READY=true','const FIXTURE_READY=false',1),(rel(of),fixture['path'],1),(sha(of),fixture['sha256'],1),('market_pawn_single_visual_ROOT41_READY/output/','market_pawn_after_complete_parent30_PENDING_NOTREADY/output/',1),('1702','1712',5)]
for a,b,count in changes:
    assert key.count(a.encode())==count;key=key.replace(a.encode(),b.encode())
back=key
for a,b,count in reversed(changes):
    assert back.count(b.encode())==count;back=back.replace(b.encode(),a.encode())
assert back==oldtext
k=emit('test_market_pawn_complete_parent30_PENDING_NOTREADY.gd',key)
kd=emit('complete_key_vs_FAILED_ROOT41.diff',''.join(difflib.unified_diff(oldtext.decode().splitlines(True),key.decode().splitlines(True),fromfile='ROOT41_FAIL_PRESERVED',tofile='PENDING_E7171712')).encode())
fd=emit('complete_fixture_vs_ROOT41.diff',''.join(difflib.unified_diff(enc(old).decode().splitlines(True),enc(f).decode().splitlines(True),fromfile='ROOT41_FIXED_FC11_1702',tofile='PENDING_FIXED_E717_1712')).encode())
proof=emit('whole_key_inverse_and_fixture_recipe_NOTREADY.json',enc({
    'status':'PENDING_ONLY_WHOLE_KEYBYTE_INVERSE_AND_FIXED_OWNER_FIXTURE_RECIPE',
    'old_key_sha256':sha(ok),'old_fixture_sha256':sha(of),'key':k,'fixture':fixture,
    'literal_replacements_only':[{'old':a,'new':b,'count':n} for a,b,n in changes],
    'whole_key_inverse_ROOT41':True,'all_function_bytes_except_five_count_literals_exact':True,
    'fixture_recipe':{'fixed_owner':sha(op),'actual_stage':sha(rp),'targets_existing_value_migration':30,
        'expected_count':1712,'proof_key_additions':10,'source_count_pending':len(f['source_sha256']),
        'four_provenance_path_swaps':[(rel(a),rel(b)) for a,b in swaps],
        'three_old_deployment_provenance_removed_pending_new_actual':removed,
        'Root39_two_SOURCE_ONLY_leaves_preserved':True,'no_current_expected_fill':True},
    'keydiff':kd,'fixturediff':fd,'no_run_or_READY_credit':True}))
handoff=emit('handoff_PENDING_ROOT_DEPLOYMENT_NOT_RUN.json',enc({
    'status':'NEW_E7171712_SINGLE_MARKET_IMAGE_PENDING_NOTREADY_NOT_EXECUTED',
    'key':k,'fixture':fixture,'inverse':proof,'whole_keydiff':kd,'whole_fixturediff':fd,
    'fixed_expected_Market':1712,'guard_count_pending':len(f['source_sha256']),
    'scope_unchanged':'60swhole/20sentry; only one publicnear5701928 plus24px trueINPUT5701904; original1920x1080activeCamera zoom1 onePNG, noSpace/room/crossdistrict/cameraplayerpositionwrites/collector/geometry replay.',
    'no_READY_until_actual_Root_deployment_and_freshguard':True,
    'prior_ROOT38_ROOT41_wholeFAIL_and_crash_preserved':True,
    'operations':{'engine':0,'parse':0,'collector':0,'Stage':0,'canonical':0}}))
print(json.dumps({'key':k,'fixture':fixture,'handoff':handoff,'guard_pending':len(f['source_sha256'])}))
