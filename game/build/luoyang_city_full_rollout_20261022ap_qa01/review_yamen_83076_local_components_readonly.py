"""One read-only local-component review; original whole FAIL stays unchanged."""
import hashlib,json,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).resolve().parent
P=QA/'yamen_three_low_props_expression_stage_trace_final/83076_2677/result.json'
ERR=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration13/yamen_expression_stage_stderr.log'
OUT=QA/'yamen_83076_local_components_and_terminal_lamp_independent_review_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(P)=='37d2771abd630fdcda790a3df7beebae9fe531b848475b1e035236cdc5b66b50'
assert sha(ERR)=='db24e1dbd5cc872055f6343c3ede231b67ad5a1b5e8202b8f8fab406cc4168db'
r=json.loads(P.read_bytes());assert r['complete'] is False and (r['checks'],r['failures'],r['elapsed_ms'])==(2610,2,42023)
assert r['source_before']==r['source_after'] and len(r['source_before'])==1228
assert r['players_before']==r['players_after'] and len(r['players_before'])==15
fixture=json.loads((QA/'yamen_expression_stage_trace_final_fixture_READY.json').read_bytes())
for path,h in fixture['expected_city_source_sha256'].items():assert r['source_before'][path]['sha256']==h
assert len(fixture['expected_city_source_sha256'])==1211
rows=r['records'];ofkind=lambda k:[x for x in rows if x['kind']==k]
trans=ofkind('EXACT_NATIVE_TRANSFORM_ACTUAL_AND_INDEPENDENT_SOURCE_EXPRESSION')
inputs=ofkind('FINITE_NORMAL_INPUT');blocks=ofkind('ACTUAL_FRONT_BLOCK_AND_EXACT_NEGATIVE')
local=ofkind('ACTUAL_PROP_ACTOR_LOCAL_STATE');npcs=ofkind('SIX_DG_CONFIG_ONLY_NOT_ENTIRE_PATROL_PERIOD')
assert len(trans)==len(blocks)==3 and len(inputs)==31 and len(local)==9 and len(npcs)==1 and npcs[0]['initial'] is True
assert all(x['result']['ok'] and x['result']['all_recorded_feet_clear'] for x in inputs)
assert inputs[-1]['result']['actual_end']==[1300.0,1394.0]
assert len(ofkind('NATURAL_SOURCE_FINAL_OWNER'))==1
for row in trans:
    for k in ['texture_path','texture_size','native_scale','field_position']:assert row['actual'][k]==row['expected'][k]
target_ids={x['id'] for x in trans};assert len(target_ids)==3
ghost_summary=[]
for row in local:
    d=row['fact'];target=d['id'];assert target in target_ids and d['actor_base_alpha']==1.0 and target not in d['fade_ids']
    for ancestor in d['prop_alpha_chain']:assert ancestor['modulate_alpha']==ancestor['self_modulate_alpha']==1.0
    hits=d['prop_hits']
    if row['expected_target_hit']:
        assert d['active'] is True and d['space']=='actor_frame' and d['ghost_visible'] is True and d['ghost_material_present'] is True and hits.get(target,0)>0
        ghost_summary.append({'id':target,'observed_target_pixels':hits[target],'foot':d['foot']})
    else:assert hits.get(target,0)==0
assert len(ghost_summary)==3
scope=ofkind('SINGLE_YAMEN_FINITE_SCOPE')[0]
assert scope['stage_trace_events']==12 and scope['Physics_queries_actual']==471 and scope['native_mask_observations_actual']==7956
assert scope['ready']['elapsed_usec']==15962908 and scope['firstdraw']['elapsed_usec']==16082152
assert scope['max_original_observe_wall_gap_usec']==3076103
for pic in scope['pictures']:assert sha(ROOT/pic['path'][6:])==pic['sha256']
assert {x['sha256'] for x in scope['pictures']}=={'c1224e1ec15274c643ba15bdbb32a4b4f258467f208755e60484d2bf99c0f427','c3865969f9386d7e228c600df5827ade4baef677ee51037c4fc739b77f2133ca'}
err=ERR.read_text(encoding='utf-8')
fail_lines=[x for x in err.splitlines() if x.startswith('CITY_LIFE_QA_FAIL')]
assert len(fail_lines)==2 and fail_lines[0].startswith('CITY_LIFE_QA_FAIL Outside all three restores ordinary actor; no forced refresh')
assert '"prop_hits": { "lamp_0": 35 }' in fail_lines[0]
assert all('"'+p+'":' not in fail_lines[0].split('"prop_hits":',1)[1].split('}',1)[0] for p in target_ids)
prior=QA/'wall_yamen_independent_recipe07_BOUND05_SOURCE_FROZEN_RETRY1_NOT_ACTUAL.json'
assert sha(prior)=='448c148ed5a15aaf4b1acbf6472afd6f94fe1ea2bdb654717dd59a5a56b4f947'
old_lamp=[x for x in json.loads(prior.read_bytes())['Yamen']['parent_geometry']['solids'] if x['id']=='lamp_0_poly_0']
assert len(old_lamp)==1
trace=[]
for row in ofkind('READONLY_STAGE_CHANGE_CLOCK'):
    trace.append({'elapsed_usec':row['clock']['elapsed_usec'],'phase':row['public']['phase'],'Field_stage':row['Field_loading_state'].get('stage'),'C':row['C_current_scalars'],'previous_observe_wall_gap_usec':row['previous_observe_wall_gap_usec'],'max_wall_gap_usec':row['max_observe_wall_gap_usec']})
assert len(trace)==12 and any(x['C']['same_current_owner'] and x['C']['sources_finalized'] for x in trace)
assert not OUT.exists()
v={'status':'INDEPENDENT_LOCAL_COMPONENTS_ONLY_WHOLE_FAIL_AND_CRASH_PRESERVED','actual_result':{'path':'res://'+P.relative_to(ROOT).as_posix(),'sha256':sha(P)},'stderr':{'path':'res://'+ERR.relative_to(ROOT).as_posix(),'sha256':sha(ERR)},'whole_complete':False,'checks':2610,'failures':2,'whole_elapsed_ms':42023,'Root_captured_console_exit':{'signed':-1073741819,'hex':'0xC0000005','source':'Root WaitForExit capture for launcher90732; not inferred from result.complete','clean':False},'source_before_after_exact_facts':1228,'production_expected_source_count':1211,'save_before_after_exact_seconds_facts':15,'save_precision_boundary':'Report seconds mtime, not Root exactticks; no save restore.','passed_prefix_components':{'three_full_source_transform_exact':True,'three_native_polygons_exact_runtime':True,'initial_six_DG_configuration':True,'normal_INPUT_segments':31,'three_real_front_blocks_and_target_only_negative_controls':True,'front_stopped_feet':[{'id':x['id'],'start':x['start'],'end':x['end']} for x in blocks],'three_behind_actor_local_hits':ghost_summary,'objects_all_ancestor_alpha1_and_not_fade_ids':True,'all_three_target_hits_clear_on_return_front':True,'actual_Physics_queries':471,'actual17_mask_observations':7956,'not_source875_replay':True},'terminal_readonly_scope_analysis':{'at_fixed_foot':[1300,1394],'observed_global_prop_hits_from_stderr':{'lamp_0':35},'three_new_prop_hits_absent':True,'old_lamp_fixed_source_primitive':old_lamp[0],'local_exit_credit':'Existing 31st INPUT reaches fixed endpoint with clear body; three new prop masks absent. Global ghost remains legitimately active for old lamp, not a new-prop failure.','original_global_ghost_false_assertion_still_failed':True,'no_lamp_movement_ghost_disable_or_new_engine_needed':True},'not_executed_after_terminal_failure':['Second six-NPC/same-instance check','Gameplay flags/quests/inventory/gold/reputation equality check','Final natural source-owner assertion'],'timing':{'ready_seconds':15.962908,'firstdraw_hidden_can_move_seconds':16.082152,'below10seconds':False,'first_completed_INPUT_drive_seconds':16.816947,'max_original_observe_wall_gap_seconds':3.076103,'trace':trace,'last_matching_profile':ofkind('ONE_LEG_TIMING')[0]['last_matching_active_profile'],'boundary':'Nested C and cumulative LM counters not additive. Frame gaps are observed wall gaps, not attributed CPU work; missing events/timings remain missing.'},'pictures_SHA_only_no_image_open':scope['pictures'],'Root_ART_boundary':'Two pictures Root viewed: low-prop opaque/actor-local ghost finite pass only; whole courtyard sparsity still not full ART admission.','old113324_whole_FAIL_and16_517877_retained':True,'stop_all_Yamen_entry_and_three_props_engine_replay':True,'engine_runs':0,'collector_calls':0,'native_or_PNG_decode':0,'canonical_writes':0}
OUT.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review_sha256':sha(OUT),'whole_complete':False,'three_local_prop_components':True,'terminal_old_lamp_only':True,'exit':'0xC0000005','INPUT_segments':31,'stage_events':12}))
