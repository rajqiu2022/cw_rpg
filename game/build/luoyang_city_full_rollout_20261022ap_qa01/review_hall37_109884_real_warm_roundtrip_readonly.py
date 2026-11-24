"""One actual finite hall excursion audit. No engine, collector or replay."""
from pathlib import Path
import hashlib,json,re
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
D=QA/'hall_roundtrip_ROOT37_READY';R=GAME/'build/luoyang_city_full_rollout_20261022ap_root01/integration37'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
rp=D/'output/109884_2827/result.json'
assert sha(rp)=='dd95b4a9eb1f773c771ad6a0f53c982dff2f4363c829cc47d8fca2c79f435a85'
r=rd(rp);fp=D/'hall_roundtrip_fixture_ROOT37_READY.json';f=rd(fp)
assert sha(fp)=='12eafbc445b9480c5230ced6aa644d211964ab098496892e6489acb17306eaec'
assert (r['checks'],r['complete'],r['failures'],r['elapsed_ms'])==(3696,True,0,34339)
assert r['source_before']==r['source_after'] and len(r['source_before'])==1309
expect={**f['source_sha256'],'res://'+fp.relative_to(GAME).as_posix():sha(fp)}
assert {k:v['sha256']for k,v in r['source_before'].items()}==expect
assert r['players_before']==r['players_after'] and len(r['players_before'])==15
records=r['records'];assert len(records)==19
def rows(kind):return[x for x in records if x['kind']==kind]
draws=rows('HALL_FIRST_HIDDEN_OPERABLE_DRAW_BEFORE_POSTVERIFY')
assert len(draws)==3
assert [x['leg']for x in draws]==['EXPLICIT_NEAR_DOOR_NOT_DEFAULT_TRAVEL','REAL_SPACE_HALL_ENTRY','REAL_SPACE_SAME_EXTERIOR_WARM_RETURN']
assert [x['ready']['elapsed_usec']for x in draws]==[13124340,3222344,1710092]
assert [x['draw']['elapsed_usec']for x in draws]==[13250610,3316602,1733385]
for d in draws:
    assert d['draw']['loading_hidden_inactive'] and d['draw']['can_move']
assert draws[0]['draw']['elapsed_usec']<20000000 and draws[1]['draw']['elapsed_usec']<20000000 and draws[2]['draw']['elapsed_usec']<10000000
assert draws[0]['draw']['elapsed_usec']>10000000
walks=rows('HALL_REAL_INPUT');assert len(walks)==2
for w,label,end,n in zip(walks,['street716to660','room1050to1142.5'],[[1536.,660.],[960.,1142.5]],[8,13]):
    v=w['result'];assert w['label']==label and v['ok'] and v['reached'] and v['all_recorded_feet_clear'] and v['physics_samples']==n and v['actual_end']==v['target']==end
filters=rows('HALL_UNCHANGED_EXACT_FILTER_COUNT');assert len(filters)==2 and all(x['found_count']==1 for x in filters)
observed=rows('HALL_EXIT_SCALARS_BEFORE_UNCHANGED_FILTER');assert len(observed)==2
assert observed[0]['portal_layer_child_count']==len(observed[0]['nodes'])==4
hall=[x for x in observed[0]['nodes']if x['target_text']=='luoyang_yamen_official_hall_20261018t']
assert len(hall)==1;h=hall[0]
assert h['position']==[1536.,660.] and h['target_type']==4 and h['monitoring'] and not h['locked'] and not h['auto_trigger'] and h['in_range']
assert h['shape_disabled'] and h['shape_type']=='RectangleShape2D' and h['polygon_present'] and not h['polygon_disabled']
assert h['polygon_four_local_points']==f['city_doorway_local_points'] and h['target_spawn']==f['room_spawn_uv']
assert observed[1]['portal_layer_child_count']==len(observed[1]['nodes'])==1
exitroom=observed[1]['nodes'][0]
assert exitroom['scriptpath']=='res://scripts/field/exit_zone.gd' and not exitroom['shape_disabled'] and exitroom['shape_type']=='RectangleShape2D' and not exitroom['polygon_present']
assert exitroom['position']==[960.,1142.5] and exitroom['target_spawn']==f['author_return_uv']
zones=rows('HALL_ACTUAL_NATIVE_ZONE');assert len(zones)==2 and all(x['shape_contract'] and x['enabled_overlap_inrange']for x in zones)
natural=rows('HALL_NATURAL_CITY_SOURCE_OWNER_AFTER_DRAW');assert len(natural)==2
for x in natural:assert x['source_count']==1239 and x['sources']==f['expected_city_sources'] and x['token']==1
assert natural[0]['initial'] and natural[0]['new_fresh_validation_claim'] and not natural[1]['initial'] and not natural[1]['new_fresh_validation_claim'] and natural[1]['warm_return_reuses_original_finalized_proof']
room=rows('HALL_NATURAL_G_SESSION_AND_SEPARATE_GUARD')[0]
assert room['session_finalized'] and room['session_author_exact'] and room['native_paths_exact'] and room['historical_row_count']==247
assert room['global_independent_guard_count']==557 and room['session_has_no_full_source_receipt'] and room['global_guard_not_G_FIRSTFINAL_or_collector_result']
assert room['historical_DT_successor']==f['historical_DT_successor']
park=rows('HALL_REAL_PARKED_LEASE')[0];lease=park['lease']
assert park['retained_alive_detached_identity'] and lease['occupied'] and lease['parked'] and lease['phase']=='PARKED' and lease['excursion_kind']=='room'
assert lease['estimated_bytes']==271367610<lease['limit_bytes']==536870912 and lease['estimate_not_vram_measurement']
assert lease['field_id']==park['saved_ids']['Field'] and lease['generation']==1 and lease['source_count']==1239
back=rows('HALL_REAL_RESUMED_LEASE')[0];ret=back['lease']['return']
assert back['same_original_Field_Player_Scene_layout'] and back['saved_ids']==park['saved_ids']
assert back['lease']['phase']=='RESUMED' and not back['lease']['occupied'] and not back['lease']['parked']
assert ret['hit'] and ret['phase']=='READY' and not ret['active'] and ret['final_live_identity'] and ret['lease_generation']==lease['generation'] and ret['field_id']==lease['field_id']
assert ret['source_fresh_sha']is False and ret['source_basis']=='SAME_LIVE_OBJECTS_AND_EDITOR_METADATA' and ret['total_ms_excludes_loading_hide']
assert ret['metadata_ms']==804.224 and ret['resume_ms']==13.452 and ret['total_ms']==1685.57
assert back['actual_return_foot']==back['expected_author_foot']=='(1536.0, 660.0)'
assert draws[2]['draw']['Field']==draws[0]['draw']['Field']==park['saved_ids']['Field']
for key in ['Player','Scene','layout']:assert draws[2]['draw'][key]==draws[0]['draw'][key]==park['saved_ids'][key]
done=rows('HALL_FINITE_ROUNDTRIP_COMPLETE')[0]
assert done['native_full_body_queries']==31 and done['actual_mask17_samples']==238 and done['pictures']==done['collector_calls']==done['geometry_republication_or_full_routes']==0
pp=R/'hall_roundtrip_once_process_receipt.json';pr=rd(pp)
assert sha(pp)=='dabc751fa70f4da22a1bce96ff9704b85e0e292fcb52fd8e411146fcd8fa82e7'
assert pr['actual_natural_console_exit_code']==-1073741819 and pr['exit_code_from_retained_process_WaitForExit'] and not pr['process_stopped_by_tool']
kp=D/'test_hall_roundtrip_ROOT37_READY.gd';assert sha(kp)==pr['script_sha256']==pr['script_after_sha256']=='7bff48b256b092179ac3a1046f3698f9c24f5813e18f268e9ae3dd0e6bf65976'
ep,op=R/'hall_roundtrip_once_stderr.log',R/'hall_roundtrip_once_stdout.log'
assert sha(ep)==pr['stderr_sha256']and sha(op)==pr['stdout_sha256']
err=ep.read_text(encoding='utf-8-sig')
counts={k:len(re.findall(v,err,re.M))for k,v in {'ERROR':r'^ERROR:','WARNING':r'^WARNING:','SCRIPT_ERROR':r'^SCRIPT ERROR:'}.items()}
assert counts=={'ERROR':10,'WARNING':1,'SCRIPT_ERROR':0}and 'CITY_LIFE_QA_FAIL'not in err
gp,bp=R/'final_guard.json',R/'guard_before.json';g,b=rd(gp),rd(bp)
assert sha(gp)=='c0751c78d4d5bdbb2adeccea9d3ab2d1d1d3e17d29da5d28f2fc1fb4a982a824'
assert g['passed']and g['checked']==g['exact_unchanged']==2118 and g['authorized_change_count']==g['unexpected_change_count']==g['save_change_count']==0 and g['save_count']==15
assert g['facts']==b['facts']
n=0
for path,digest in f['source_sha256'].items():
    if path.startswith('res://scripts/'):
        p=GAME/path[6:];assert p.stat().st_size<1048576 and sha(p)==digest;n+=1
assert n==97
savebase=Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for path,row in r['players_after'].items():
    p=savebase/path.removeprefix('user://');assert p.exists()==row['exists']
    if row['exists']:assert p.stat().st_size==row['bytes']and sha(p)==row['sha256']
out=QA/'hall37_109884_real_resident_componentPASS_nonclean_independent_review_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'HALL37_FINITE_REAL_ROUNDTRIP_FUNCTIONAL_COMPONENT_PASS_TRUE_C0000005_EXIT_NOT_WHOLE_OR_CITY_PASS','report':{'path':str(rp),'sha256':sha(rp)},'process':{'path':str(pp),'sha256':sha(pp),'true_exit':-1073741819,'hex':'C0000005','wall_ms':pr['elapsed_wall_ms'],'log_counts':counts,'nonclean':True,'crash_cause_not_established':True},'functional':{'checks':3696,'failures':0,'complete':True,'elapsed_ms':34339,'whole60s_cap_pass':True,'near_not_default_or_worldtravel':True,'near_ready_usec':13124340,'near_draw_usec':13250610,'near20s_cap_pass_but_under10false':True,'room_ready_usec':3222344,'room_draw_usec':3316602,'real2INPUT_8plus13physics_and2Space_path':True,'exact_hall_found1_author1536_660_correct_polygon':True,'room_enabled_rectangle_exactexit':True,'natural_G_finalized_sameScene_layout_author_historical247':True,'G557_independent_guard_not_natural_source_receipt':True,'original_exterior_PARKED_alive_detached':True,'estimated_retained_bytes_notVRAM':271367610,'limit_bytes':536870912,'warm_ready_usec':1710092,'warm_hidden_operable_draw_usec':1733385,'warm_under10s_pass_once':True,'same_Field_Player_Scene_layout':park['saved_ids'],'return_authorfoot_exact':[1536,660],'return_hit_READY_RESUMED_final_identity':True,'return_source_basis':ret['source_basis'],'return_fresh_SHA':False,'return_metadata_ms':804.224,'return_resume_ms':13.452,'return_total_ms_excludes_loading_hide':1685.57,'timing_note':'External hidden-draw clock and internal returntotal have different boundaries; do not sum them or infer an exclusive hidden duration. Single observation, not stable performance statistics.','native_fullbody_queries':31,'already_loaded_mask_local_samples':238},'source_save':{'1309report_FIRSTFINAL_same':True,'1308fixedguard_plusfixture_exact':True,'initial_naturalC_FINAL1239_fixed5857':True,'warm_same_original_token1_proof_reused_no_newfreshclaim':True,'97current_small_scripts_SHA_exact':True,'15save_firstfinal_and_currentSHAbytes_same':True,'Root37_2118facts_exactticks_beforeafter_same':True,'guard_sha256':sha(gp),'no_full_media_current_rehash':True},'limits':['No screenshots/ART/fullcity completion.','First near entry13.250610s still fails10s target; room20s component and warm<10 credited only here.','No otherroom/all12room/wholegeometry/collector/worldtravel coverage.','Oldhall33/34FAIL and35guardFAIL/crash history retained.','Functional component PASS never changes trueC0000005 process failure to cleanPASS.'],'operations':{'engine':0,'collector':0,'Stage':0,'native_or_image_decode':0,'big_media_hash':0,'canonical_or_old_report_writes':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'checks':3696,'functional':True,'true_exit':-1073741819,'log_counts':counts}))
