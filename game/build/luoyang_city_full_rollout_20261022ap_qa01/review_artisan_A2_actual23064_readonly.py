"""One report/current-source review; source-only contact arithmetic, no raster."""
import hashlib
import json
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent
OUT=QA/'artisan_A2_actual23064_components_and_mask_contact_readonly_review_READY.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def read(p,s=None):
    b=p.read_bytes()
    if s:assert sha(b)==s
    return json.loads(b)
rp=QA/'artisan_A2_finite_Field_ROOT16_READY/23064_2678/result.json'
rh='5b498c4ed7ded7a5cbb44da766c02390efb15b6c8cd9f13722f3e3fb43f69204'
r=read(rp,rh);assert r['complete'] is False and r['checks']==687 and r['failures']==2 and r['elapsed_ms']==9291
assert r['source_before']==r['source_after'] and len(r['players_before'])==15 and r['players_before']==r['players_after']
for p,f in r['source_before'].items():
    q=ROOT/p[6:];assert p.startswith('res://') and f['exists'] is True
    b=q.read_bytes();assert sha(b)==f['sha256'] and len(b)==f['bytes'] and int(q.stat().st_mtime)==f['mtime'],p
base=Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for p,f in r['players_before'].items():
    q=base/p[7:];assert q.exists()==f['exists']
    if q.exists():assert sha(q.read_bytes())==f['sha256'] and q.stat().st_size==f['bytes'] and int(q.stat().st_mtime)==f['mtime']
records=r['records'];kinds=[x['kind'] for x in records]
entry=next(x for x in records if x['kind']=='A2_DEFAULT_ENTRY_TIMING')
assert entry['ready']['elapsed_usec']==4907075 and entry['firstdraw']['elapsed_usec']==5041070 and entry['first_under10s'] is True
assert entry['firstdraw']['loading_hidden_inactive'] is True and entry['firstdraw']['can_move'] is True
profile=entry['Field_profile'];assert profile['status']=='READY' and profile['setup_identity_current'] is True and profile['transition_token']==0 and profile['fresh_source_validation_credit'] is False
assert entry['LM']=={},'Do not fabricate missing preload metrics as zero'
owners=[x for x in records if x['kind']=='A2_NATURAL_FAMILY_OWNER'];assert len(owners)==1 and owners[0]['source_count']==270 and owners[0]['finalized'] and owners[0]['same_weak_scene_layout']
visuals=[x for x in records if x['kind']=='A2_REAL132_ENV_AND4PEOPLE'];assert len(visuals)==1
v=visuals[0];assert v['initial'] is True and v['ground']==118 and v['opaque_props']==14 and len(v['NPCs'])==4
env=v['ENV_receipt'];assert env['ok'] is True and env['source_hash_passes']==2 and env['source_first']==env['source_final']
assert env['a2_exact_runtime_material']['ground_material_count']==118 and env['a2_exact_runtime_material']['opaque_props_unchanged']==14
assert env['original_complete_alpha_ground_stamps_retained']==1 and 'artisan_union_visual_only' not in env
starts=[x for x in records if x['kind']=='EXPLICIT_TEST_ONLY_INSPECTION_BEFORE']
ends=[x for x in records if x['kind']=='EXPLICIT_TEST_ONLY_INSPECTION_AFTER']
segments=[x for x in records if x['kind']=='A2_REAL_INPUT_SHORT_SEGMENT']
assert len(starts)==len(ends)==7 and all(x['actual_mask17_and_Physics_clear'] for x in starts)
assert len(segments)==9 and all(x['result']['ok'] and x['result']['all_recorded_feet_clear'] and x['result']['reached'] for x in segments)
assert [x['result']['actual_end'] for x in segments[:6]]==[[float(x),1446.0] for x in [343,560,880,1840,2160,2320]]
assert [x['result']['actual_end'] for x in segments[6:]]==[[2040.0,1490.0],[2470.0,1490.0],[2470.0,1486.0]]
neg=next(x for x in records if x['kind']=='A2_RACK_EXACT_NEGATIVE_ACTUAL')
assert len(neg['hits'])==1 and neg['hits'][0]['authoring_id']=='ap_cloth_rack_v2_hull_0' and neg['hits'][0]['ap_exact_native_geometry'] is True
failure=records[-1];assert failure['kind']=='A2_RACK_BLOCK_PARTIAL_FAILURE'
assert failure['actual_foot']=='(2470.0, 1458.375)' and failure['physics_positions']==['(2470.0, 1478.0)','(2470.0, 1470.0)','(2470.0, 1462.0)','(2470.0, 1458.375)']
assert 'A2_RACK_REAL_BLOCK' not in kinds and 'A2_FINITE_SCOPE' not in kinds
prior=read(QA/'artisan_a2_independent_native_ABI_prior_and_whole_source_inverse_READY.json','d0d544ed24996bf3bc4569ae9b4fd4fc3c6edba85f264075e8e67c336675ce3e')
poly=next(x['polygon_px'] for x in prior['expected27_source_solids'] if x['id']=='ap_cloth_rack_v2_hull_0')
bottom=poly[2][1];assert bottom==poly[3][1]==1446.3599853515625
real_top=1458.375-12;gap=real_top-bottom;assert gap==0.0150146484375 and gap>0
points=[]
for x in [2453,2470,2487]:
    p=[x,1446];cross=[]
    for a,b in zip(poly,poly[1:]+poly[:1]):cross.append((b[0]-a[0])*(p[1]-a[1])-(b[1]-a[1])*(p[0]-a[0]))
    assert all(z>0 for z in cross),('strict convex interior',p,cross)
    points.append({'rounded_north_probe':p,'strict_positive_cross_products':cross,'source_raster_implication':'Original fixed polygon painting makes this integer interior point black. No PNG read or new pixel sample performed.'})
key=ROOT/'tests/test_luoyang_ap_artisan_A2_finite_Field_ROOT16_READY_20261023.gd'
assert sha(key.read_bytes())=='c384f042997e39468445e1023f841f6486e3ed66392997ab64d11a68b0d8bf75'
text=key.read_text(encoding='utf-8');assert 'Vector2i(at.round()+offset)' in text
assert text.index('if px.x<0 or px.y<0')<text.index('return body_query(at).is_empty()')
ip=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration16'
process=read(ip/'artisan_A2_public_Field_process_receipt.json')
assert process['actual_natural_console_exit_code']==1 and process['exit_code_from_retained_process_WaitForExit'] is True and process['process_stopped_by_tool'] is False
stderr=(ip/'artisan_A2_public_Field_stderr.log').read_bytes();assert sha(stderr)==process['stderr_sha256']
log=stderr.decode();errors=len(re.findall(r'^ERROR:',log,re.M));warnings=len(re.findall(r'^WARNING:',log,re.M))
assert errors==10 and warnings==3 and 'SCRIPT ERROR:' not in log
png=rp.with_name('default_A2_Field_context.png');assert png.exists() and not rp.with_name('rack_front_opaque.png').exists()
result={'status':'INDEPENDENT_ACTUAL23064_LOCAL_COMPONENTS_ONLY_WHOLE_FAIL_RETAINED','actual_report':{'path':'res://'+rp.relative_to(ROOT).as_posix(),'sha256':rh,'complete':False,'checks':687,'failures':2,'elapsed_ms':9291},'true_natural_console_exit':1,'source_first_last_current_SHA_bytes_seconds_same':len(r['source_before']),'player_saves_first_last_current_SHA_bytes_seconds_same':15,'default_entry':{'ready_usec':4907075,'hidden_canmove_firstdraw_usec':5041070,'first_under10s_this_one_entry':True,'SSD_cold_or_repeat_allcity_credit':False,'Family270_naturally_complete_first_only_observation':owners[0],'profile':profile,'LM_metrics':'MISSING_NOT_ZERO'},'completed_components':{'actual118material_14opaque_4visible_NPC_initial_ENV_rut':True,'ENV_source_count':len(env['source_first']),'authorized_test_inspection_starts':7,'six_fixed_true_INPUT_crossings':6,'rack_true_INPUT_front_segments':3,'total_successful_INPUT_physics_samples':sum(x['result']['physics_samples'] for x in segments),'exact_single_rack_negative_hit':neg,'north_input_observed_physics_ticks_before_failure':4},'source_only_terminal_contact_arithmetic':{'actual_recorded_foot':[2470,1458.375],'original_body_height':24,'real_body_top':real_top,'frozen_rack_bottom':bottom,'positive_source_geometry_gap':gap,'QA_rounded_foot_y':1458,'north_rounded_mask_y':1446,'north_probes_strict_interior':points,'clear_actual_order':'mask17 first; returns false before body_query on any black pixel','credit_boundary':'Runtime aggregate had no per-probe or same-moment Physics detail. Exact source/hash implication explains the discrete mask rejection; it is not a newly observed Physics query, cannot prove engine penetration or full24tick safe stop.'},'not_executed':['remaining20 north ticks','rack final stopped assertion','rack_front_opaque second image','final4NPC/same-instance pass','final Family owner check','final finite scope counters'],'single_image_hash_only_no_open':{'path':'res://'+png.relative_to(ROOT).as_posix(),'sha256':sha(png.read_bytes())},'nonclean':{'errors':errors,'warnings':warnings,'WASAPI_dummy_fallback':True,'Image_rawload_warning':True,'Texture_RID_resource_exit_errors':True,'script_errors':0,'stderr_sha256':sha(stderr)},'QA_actions':{'engine_or_newkey':False,'PNG_ctex_native_decode_or_ABI':False,'raster_geometry_route_replay':False,'production_or_report_modification':False},'next_decision':'Root decides whether any bounded residual evidence is necessary. No automatic rerun, mask edit or epsilon.'}
assert not OUT.exists();OUT.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(OUT),'sha256':sha(OUT.read_bytes()),'sources':len(r['source_before']),'success_INPUT_samples':sum(x['result']['physics_samples'] for x in segments)}))
