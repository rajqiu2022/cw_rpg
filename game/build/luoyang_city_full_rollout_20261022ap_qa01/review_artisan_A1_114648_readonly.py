"""Read actual A1 source/save/camera/image hashes; never opens/decode images."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).resolve().parent
P=ROOT/'build/luoyang_city_full_rollout_20261022ap_system01/artisan_a1_material_epoch01/output/114648_2563/result.json'
OUT=QA/'artisan_A1_114648_independent_readonly_review_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(P)=='dfcb0f9e3204af800ee4eb058c93dac0c44809b838a3794492df1f856f8d7eef'
r=json.loads(P.read_bytes())
assert r['complete'] is True and (r['checks'],r['failures'],r['elapsed_ms'])==(503,0,2056)
assert r['source_before']==r['source_after'] and len(r['source_before'])==69
for p,f in r['source_before'].items():
    assert p.startswith('res://');path=ROOT/p[6:]
    assert sha(path)==f['sha256'] and path.stat().st_size==f['bytes']
assert r['players_before']==r['players_after'] and len(r['players_before'])==15
material=next(x for x in r['records'] if x['kind']=='A1_ONLY_EXISTING_GROUND_MATERIALS')
assert (material['stone_sections'],material['stone_tiles'],material['grass_tiles'],material['union_segments'])==(9,62,24,32)
assert material['native_data_or_geometry_changed'] is False and material['original_alpha_formula_and_source_pixels_unchanged'] is True
assert len(material['bound'])==86
for row in material['bound']:
    assert row['scale']=='(0.25, 0.25)'
    if row['kind']=='stone':assert row['contrast']==.45 and row['core_alpha']==1.0 and row['union_feather_world']==32.0
    else:assert row['kind']=='grass' and row['saturation']==.58 and row['alpha_unchanged'] is True
pic=next(x for x in r['records'] if x['kind']=='A1_ONE_SAME_CAMERA_GROUND_PLATE')
assert pic['camera_effective_center']=='(2112.0, 1508.0)' and pic['world_scale']==1.0
assert pic['same_world_rect']==[1152,968,1920,1080]
assert pic['Field_Player_NPC_HUD_omitted'] is True and pic['geometry_Physics_collector_import_calls']==0
assert pic['not_pixel_identical_full_Field_frame'] is True and pic['whole_district_ART_still_pending'] is True
assert pic['image']['sha256']=='e9d4f5455998337d231159c1138c2fd078c24b7305f606ed002a08a9f0e5565d'
assert sha(ROOT/pic['image']['path'][6:])==pic['image']['sha256']
assert not OUT.exists()
v={'status':'INDEPENDENT_A1_PURE_GROUND_VISUAL_TECHNICAL_REPORT_REVIEW_NOT_DEPLOYED','actual_result':{'path':'res://'+P.relative_to(ROOT).as_posix(),'sha256':sha(P)},'report_complete':True,'checks':503,'failures':0,'elapsed_ms':2056,'OS_exit_code':None,'OS_boundary':'Root did not retain exit code; report complete true and ended own process are not OS0 proof. No rerun to recover it.','source_before_after_and_current_SHA_bytes':69,'save_before_after_seconds_facts_same':15,'save_precision_boundary':'Report seconds mtime, not Root exactticks; no save restore or new save snapshot.','material_counts':{'stone_sections':9,'stone_tiles':62,'grass_tiles':24,'union_segments':32},'camera':{'effective_center':[2112,1508],'world_scale':1,'world_rect':[1152,968,1920,1080]},'image':pic['image'],'image_open_or_decode_performed':False,'Field_Player_NPC_HUD_omitted':True,'not_pixel_identical_full_Field_frame':True,'Root_ART_boundary':'Stone contrast limited improvement; dry-grey grass, giant L paving and isolated wall still reject whole-district ART. A1 not deployed.','engine_runs':0,'collector_or_Physics_or_geometry_runs':0,'native_or_PNG_decode':0,'canonical_writes':0}
OUT.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review_sha256':sha(OUT),'sources':69,'save_facts':15,'OS_exit_code':None,'image_opened':False}))
