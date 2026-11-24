"""Only emit NEW QA text/fixture. No Godot, source collector or native decoding."""
from pathlib import Path
import copy,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
D=QA/'market_pawn_single_visual_ROOT38_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p):return'res://'+p.relative_to(GAME).as_posix()
def enc(v):return(json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
def emit(name,data):
    p=D/name;assert not p.exists();p.parent.mkdir(parents=True,exist_ok=True)
    with p.open('xb')as f:f.write(data)
    return{'path':rel(p),'sha256':sha(p),'bytes':p.stat().st_size}
op=S/'performance49_estate17_actual_independent_review/owner_source_maps_READY.json'
assert sha(op)=='585717db94be4c11be5eb80629e3d8a0457ba292e188ce4dc5f40c42f1cb870f'
o=rd(op);market=next(r for r in o['scenes']if r['id']=='ch4_s3_luoyang_market')
expected=copy.deepcopy(market['source_sha256']);assert len(expected)==1700
guard=dict(expected)
for p,h in o['core_source_sha256'].items():
    if p in guard:assert guard[p]==h
    guard[p]=h
coords=GAME/'build/luoyang_city_full_rollout_20261022ap_system01/final_system_coordinates_handoff_READY.json'
assert sha(coords)=='761092c89967b8fd80aa5f7915a52b9c6317a7e36e2fd9d60a1294ab966623a0'
door=next(x for x in rd(coords)['doors']if x['id']=='pawn')
assert door['source_approach']==[[570,1928],[570,1904]]and door['source_portal_foot']==[570,1904]
historical=QA/'bounded_remaining_fade_history_BDE_joint_estate_READY.json'
assert sha(historical)=='0d8b2464e9909ea856cd5c213330429a8941591fc85c9973f2c44e551fd7d956'
hdoor=next(x for x in rd(historical)['doors']if x['id']=='pawn')
assert hdoor['source_approach']==door['source_approach']and hdoor['setup_uv']==[570/3072,1928/2048]
art=GAME/'build/luoyang_city_full_rollout_20261022ap_art01/acceptance_gap_readonly_20261023_epoch01.json'
assert sha(art)=='f66214a999503613370bcab56c8b9d6cb6271988fcdb6f394b1428257e59b109'
bp=ROOT/'integration38/guard_before.json';gp=ROOT/'integration37/final_guard.json'
assert sha(bp)=='7c2cc2b44109bd59b45c11c0c01edb251fb6c1d090e6f409003fda44da7c680f'
assert sha(gp)=='c0751c78d4d5bdbb2adeccea9d3ab2d1d1d3e17d29da5d28f2fc1fb4a982a824'
assert rd(bp)['passed']and rd(bp)['checked']==2118and rd(bp)['save_count']==15
template=QA/'market_pawn_single_visual_TEMPLATE_NOTREADY.gd'
base=GAME/'tests/test_luoyang_city_life_cpu_draft_20261016f.gd';driver=GAME/'tests/helpers/v15_input_driver.gd'
assert sha(base)=='a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895'
assert sha(driver)=='a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7'
formal=ROOT/'integration36/final_guard.json';formalcopy=ROOT/'integration36/generated_JSON_deployment_actual.json'
assert sha(formal)=='f3fd504e22d186b6196130dd641aa336ef50f8df69d32a43ef599e2d520ce6e8'
assert sha(formalcopy)=='797db65a081f8228d7a87489576679ec4569448972fd7da3ec4a742e6546bdca'
authorities=[op,coords,historical,art,bp,gp,template,base,driver,formal,formalcopy]
for p in authorities:
    k,h=rel(p),sha(p)
    if k in guard:assert guard[k]==h
    guard[k]=h
scene_path='res://build/luoyang_city_full_rollout_20261022ap_system01/finite_two_domain_publication_epoch05_bound01/output/market/scene.res'
layout_path=scene_path.replace('/scene.res','/layout.res')
assert expected[scene_path]=='f93728babb75be86b876b0d43d0dc43a1c46b4cbf7b5dd6da64be4481e9e8a56'
assert expected[layout_path]=='cfb1729706402388fba9c43c6882c3e1f38058a0d9cee763bfb38d8cbe13ab20'
f={'status':'ROOT38_CURRENT_MARKET_SINGLEIMAGE_FINITE_OBSERVATION_READY_NOT_RUN','ready':True,'whole_ms':60000,'entry_ms':20000,'max_pictures':1,'expected_sources':expected,'source_sha256':guard,'scene_path':scene_path,'layout_path':layout_path,'setup_uv':[570/3072,1928/2048],'input_world':door['source_approach'],'normal_viewport':[1920,1080],'camera_zoom':1,'authority':{rel(p):sha(p)for p in authorities},'scope':{'one_public_near_not_default_or_worldtravel':True,'24px_realINPUT_only':True,'Space':0,'room':0,'crossdistrict':0,'pictures':1,'camera_or_player_position_writes':0,'no_newgeometry_or_manualcollector':True,'original34x24_actualPhysics_and17_loadedmask':True,'coordinates':'Fixed761092 pawn authorportal5701904; near1928=+24south, independently same oldBDE door approach. F662 is readonlyART gap provenance only; oldactual/sourceoracles not reused.','picture':'Full original normal1920x1080 activeCamera zoom1; record state only, never pan/zoom/frameall. PNG is observation not automaticARTpass.','performance':'20s finiteentrycap; recordunder10 honestly, not grantfirst<10. All pre/postsourcechecks and oneimage remain inside60s whole.','expected_source_recipe':'Fixed5857 Market1700 + fixedcore/provenance; no observedcollector or node expected backfill.','save15_suspended_and_preserved':True}}
fixture=emit('market_pawn_single_visual_fixture_ROOT38_READY.json',enc(f))
body=template.read_bytes();key=body
changes=[('const FIXTURE_READY=false','const FIXTURE_READY=true'),('PENDING_FROZEN_FIXTURE_SHA',fixture['sha256']),('PENDING_FROZEN_FIXTURE',fixture['path']),('PENDING_OUTPUT_ROOT',rel(D/'output'))]
for a,b in changes:
    assert key.count(a.encode())==1;key=key.replace(a.encode(),b.encode(),1)
inverse=key
for a,b in reversed(changes):assert inverse.count(b.encode())==1;inverse=inverse.replace(b.encode(),a.encode(),1)
assert inverse==body
k=emit('test_market_pawn_single_visual_ROOT38_READY.gd',key)
import difflib
diff=emit('complete_key_vs_TEMPLATE.diff',''.join(difflib.unified_diff(body.decode().splitlines(True),key.decode().splitlines(True),fromfile='TEMPLATE_NOTREADY',tofile='ROOT38_READY')).encode())
h=emit('handoff_ROOT38_READY_NOT_RUN.json',enc({'status':'ROOT38_CURRENT_MARKET_SINGLE_ART_OBSERVATION_READY_ROOT_MUST_REVIEW_BEFORE_ONE_GUI','key':k,'fixture':fixture,'template':{'path':rel(template),'sha256':sha(template)},'key_template_diff':diff,'source_guard_count':len(guard),'expected1700_fixed5857':True,'one_entry20s_whole60s':True,'one24px_INPUT_onePNG_noSpace_room_crossdistrict':True,'camera1920x1080_zoom1_readonly_no_positionwrites':True,'beforeRoot38':sha(bp),'body_origin':'Selected hall37 readiness/hidden-draw and original34x24 actualclear/driver primitives, not oldhall exercise; NEW narrowerART observation scope, no hall/room/lease/Space functions.','old_hall_and_performance_tests_not_replayed':True,'operations':{'engine':0,'parse':0,'collector':0,'geometry':0,'Stage':0,'canonical_write':0}}))
print(json.dumps({'key':k,'fixture':fixture,'handoff':h,'source_guard_count':len(guard)}))
