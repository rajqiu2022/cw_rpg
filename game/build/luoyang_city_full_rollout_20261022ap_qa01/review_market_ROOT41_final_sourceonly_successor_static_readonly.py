"""Final text/source recipe check only, no parse/engine/runtime source collection."""
from pathlib import Path
import copy,hashlib,json
QA=Path(__file__).resolve().parent;GAME=QA.parents[1];S=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
D=QA/'market_pawn_single_visual_ROOT41_READY';P=QA/'market_pawn_single_visual_ROOT38_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p):return'res://'+p.relative_to(GAME).as_posix()
kp=D/'test_market_pawn_single_visual_ROOT41_READY.gd';fp=D/'market_pawn_single_visual_fixture_ROOT41_READY.json'
pk=P/'test_market_pawn_single_visual_ROOT38_READY.gd';pf=P/'market_pawn_single_visual_fixture_ROOT38_READY.json'
assert sha(kp)=='303d54c3430d978c0d93f235b2d715107261f7df500ae539448dd5bd31435db6'
assert sha(fp)=='eac1f55debb3b5e5bb08d69666663323b4db6a67b394b94a4743862a9f948301'
key=kp.read_text(encoding='utf-8');back=key
for a,b,count in [(rel(fp),rel(pf),1),(sha(fp),sha(pf),1),('market_pawn_single_visual_ROOT41_READY/output/','market_pawn_single_visual_ROOT38_READY/output/',1),('1702','1700',5)]:
    assert back.count(a)==count;back=back.replace(a,b)
assert back.encode()==pk.read_bytes()
old,new=rd(pf),rd(fp);op=S/'performance54_market_tuple3_actual_independent_review/owner_source_maps_READY.json'
assert sha(op)=='fc11a02989c4e9d57628dccaa82c08cd11df6767c954f4ed4829b5dcdffc0f02'
o=rd(op);expected=next(r for r in o['scenes']if r['id']=='ch4_s3_luoyang_market')['source_sha256']
assert new['expected_sources']==expected and len(expected)==1702 and len(new['source_sha256'])==1735
stage=rd(S/'outputs/root_market_source_only_tuple3_stage01/receipt.json');tr={x['target']:x for x in stage['targets']}
for path,h in old['source_sha256'].items():assert new['source_sha256'][path]==(tr[path]['candidate_sha256']if path in tr else h)
assert all(new['source_sha256'][p]==h for p,h in expected.items())
assert new['ready']and new['whole_ms']==60000 and new['entry_ms']==20000 and new['max_pictures']==1
assert new['setup_uv']==old['setup_uv']and new['input_world']==old['input_world']==[[570,1928],[570,1904]]
for k in old:
    if k not in ['status','source_sha256','expected_sources','authority','scope']:assert new[k]==old[k]
scope=copy.deepcopy(new['scope']);scope['expected_source_recipe']=old['scope']['expected_source_recipe'];assert scope==old['scope']
for path,h in new['authority'].items():
    if 'root_market_source_only_tuple3_stage01/receipt.json'not in path:assert sha(GAME/path[6:])==h
assert 'KEY_SPACE'not in key and key.count('"go_field_smart"')==key.count('await driver.drive(')==key.count('image.save_png(')==1
assert 'root.get_camera_2d()==camera'in key and 'camera.zoom==Vector2.ONE'in key
out=D/'independent_final1702_static_admission_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'ROOT41_NEW_SINGLE_MARKET_CURRENT_ART_STATIC_NO_BLOCKER_NOT_RUN','key_sha256':sha(kp),'fixture_sha256':sha(fp),'checks':{'wholebyte_inverse_ROOT38_only_fixturepath_SHA_output_5sourcecount_literals':True,'all_other_functionbytes_exact':True,'full1702_expected_fixed_FC11_owner_exact':True,'1735guard_original1722_kept_3headers_changed_plus2SOURCE_ONLY_and11fixed_provenance':True,'scope_clock_INPUT_camera_body_60s20s_onePNG_0Space_room_crossdistrict_unchanged':True,'Root40formal_EDE18_6840_and_Root41freshA56C_bound':True,'no_observedcollector_or_node_expected_fill':True,'SOURCE_ONLY2_not_runtimeTexture_admission':True},'limits':['Root38FAIL and source failure snapshotdraft remain unreplayed.','Currentimage observation only; Root must visually judge ART, no automaticpass.','No firstentry<10s claim or allcity completion.'],'operations':{'engine':0,'parse':0,'collector':0,'Stage':0,'image_or_geometry_decode':0,'canonical_write':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'lines':len(key.splitlines())}))
