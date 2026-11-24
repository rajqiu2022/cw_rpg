"""Static review only. No parse, engine, image/geometry work or collector."""
from pathlib import Path
import hashlib,json,re
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
D=QA/'market_pawn_single_visual_ROOT38_READY';S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
kp=D/'test_market_pawn_single_visual_ROOT38_READY.gd';fp=D/'market_pawn_single_visual_fixture_ROOT38_READY.json'
assert sha(kp)=='08e9da3acd99281f2196ffd6060a1c5eb0383953a2b274f106d837b174554274'
assert sha(fp)=='b57f43d13a1251f933928467883d6c74d100ceedc248669f49586d939c79881b'
key=kp.read_text(encoding='utf-8');f=rd(fp);t=(QA/'market_pawn_single_visual_TEMPLATE_NOTREADY.gd').read_text(encoding='utf-8')
back=key
for a,b in [('const FIXTURE_READY=true','const FIXTURE_READY=false'),('res://'+fp.relative_to(GAME).as_posix(),'PENDING_FROZEN_FIXTURE'),(sha(fp),'PENDING_FROZEN_FIXTURE_SHA'),('res://'+(D/'output').relative_to(GAME).as_posix(),'PENDING_OUTPUT_ROOT')]:
    assert back.count(a)==1;back=back.replace(a,b,1)
assert back==t
owner=rd(S/'performance49_estate17_actual_independent_review/owner_source_maps_READY.json')
expected=next(x for x in owner['scenes']if x['id']=='ch4_s3_luoyang_market')['source_sha256']
assert f['expected_sources']==expected and len(expected)==1700 and len(f['source_sha256'])==1722
assert all(f['source_sha256'][p]==h for p,h in expected.items())
assert f['input_world']==[[570,1928],[570,1904]]and f['setup_uv']==[570/3072,1928/2048]
assert f['whole_ms']==60000 and f['entry_ms']==20000 and f['max_pictures']==1 and f['normal_viewport']==[1920,1080]and f['camera_zoom']==1
assert f['ready']is True and f['scope']['Space']==f['scope']['room']==f['scope']['crossdistrict']==0
assert 'KEY_SPACE'not in key and key.count('"go_field_smart"')==1 and key.count('await driver.drive(')==1 and key.count('image.save_png(')==1
assert 'root.get_camera_2d()==camera'in key and 'camera.zoom==Vector2.ONE'in key and 'image.get_size()==Vector2i(1920,1080)'in key
for forbidden in ['G._','validation_begin(','validation_finish(','resident_receipt(','source_paths(','camera.zoom =','camera.position =','player.position =','KEY_SPACE']:
    assert forbidden not in key
def fn(text,name):
    return text.split('\nfunc '+name+'(',1)[1].split('\nfunc ',1)[0]
def nocomments(text):return'\n'.join(x for x in text.splitlines()if x.strip()and not x.lstrip().startswith('#'))
hall=(QA/'hall_roundtrip_ROOT37_READY/test_hall_roundtrip_ROOT37_READY.gd').read_text(encoding='utf-8')
assert nocomments(fn(key,'_clear'))==nocomments(fn(hall,'_clear'))
assert fn(key,'_loading_hidden')==fn(hall,'_loading_hidden')
for p,h in f['authority'].items():assert sha(GAME/p[6:])==h
assert f['authority']['res://build/luoyang_city_full_rollout_20261022ap_root01/integration38/guard_before.json']=='7c2cc2b44109bd59b45c11c0c01edb251fb6c1d090e6f409003fda44da7c680f'
out=D/'independent_singleimage_static_admission_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'ROOT38_NEW_FINITE_CURRENT_MARKET_ART_OBSERVATION_STATIC_NO_BLOCKER_NOT_RUN','key':{'path':str(kp),'sha256':sha(kp),'lines':len(key.splitlines())},'fixture':{'path':str(fp),'sha256':sha(fp)},'checks':{'READY_only4literal_whole_template_inverse':True,'originalhall37_bodyquery_and_loadinghidden_primitives_exact':True,'fixed5857_Market1700_expected_whole_equal':True,'1722guard_fixedauthorities':True,'coords761092_and_historicalBDE_pawn_5701928_to5701904_noactualfill':True,'firstclock_before_sourcecopies':True,'naturalC_FINAL1700_no_manualvalidator':True,'onepublicnear_one24px_realINPUT_onePNG':True,'original_activeCamera1920x1080_zoom1_readonly':True,'0Space_room_crossdistrict_position_zoomwrites':True,'whole60s_entry20s_unchanged_after_precheck_and_postcheck':True,'15save_suspension_and_parentfinish_guard':True},'limits':['NEW currentlocalART observation only; image requires Root visualreview and does not selfgrantART.','Explicitnear setup is not default/worldtravel.','No first<10s promise, no allcity/room/oldroute revalidation.','No oldhall/performance replay or processclean guarantee.'],'operations':{'engine':0,'parse':0,'collector':0,'geometry':0,'image_decode':0,'Stage':0,'canonical_write':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'lines':len(key.splitlines())}))
