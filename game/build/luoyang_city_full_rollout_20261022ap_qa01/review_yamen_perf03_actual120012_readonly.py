"""One actual-report audit. No engine, repeated route, geometry or collector."""
import hashlib
import json
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent
OUT=QA/'yamen_perf03_actual120012_independent_timing_exit_source_review_READY.json'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,s=None):
    b=p.read_bytes()
    if s:assert sha(b)==s
    return json.loads(b)
rp=QA/'yamen_performance03_LIGHT_ROOT16_READY/120012_2710/result.json'
rh='577410432eb9dc9de9fec4d69d24ec5a6c754ae81136d1e147ca8200429ee248'
r=load(rp,rh);assert r['complete'] is True and r['checks']==2465 and r['failures']==0 and r['elapsed_ms']==30596
assert r['source_before']==r['source_after'] and len(r['source_before'])==1238
for p,f in r['source_before'].items():
    assert p.startswith('res://');q=ROOT/p[6:];b=q.read_bytes()
    assert f['exists'] is True and sha(b)==f['sha256'] and len(b)==f['bytes'] and int(q.stat().st_mtime)==f['mtime'],p
assert r['players_before']==r['players_after'] and len(r['players_before'])==15
savedir=Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for p,f in r['players_before'].items():
    q=savedir/p[7:];assert q.exists()==f['exists']
    if q.exists():assert sha(q.read_bytes())==f['sha256'] and q.stat().st_size==f['bytes'] and int(q.stat().st_mtime)==f['mtime']
record=next(x for x in r['records'] if x['kind']=='PERF03_ONE_DEFAULT_ENTRY_RESULT')
proof=next(x for x in r['records'] if x['kind']=='PERF03_NATURAL_C_RECEIPT_SELECTIVE_READ')
fixture=load(QA/'yamen_performance03_fixture_ROOT16_READY.json','a488ba0536d9df8da4b1130a0ea0f4a11626d8bcc0ff7c88a6f744ef6a02c036')
assert proof['sources']==fixture['expected_city_source_sha256'] and len(proof['sources'])==1217
identity=proof['identity'];assert identity['scene_matches'] is True and identity['sources_finalized'] is True and identity['token']==1
assert record['functional_entry_and_natural_owner_ok'] is True and record['first_under10s'] is False
ready=record['ready'];draw=record['hidden_canmove_firstdraw'];profile=record['Field_profile']
assert ready['elapsed_usec']==15781110 and draw['elapsed_usec']==15898031 and draw['loading_hidden_inactive'] is True and draw['can_move'] is True
assert ready['Field']==draw['Field']==profile['Field_instance'] and ready['Scene']==draw['Scene']==profile['scene_instance']
assert profile['setup_identity_current'] is True and profile['status']=='READY' and profile['transition_token']==1
assert profile['observed_live_transition_token']==0 and profile['same_live_transition'] is False and profile['fresh_source_validation_credit'] is False
active=record['last_matching_active_C'];final=record['last_same_token_finalized_C'];assert active==final
c=final['C'];assert final['same_live_owner']==c['token']==1 and c['active'] and c['live_scope'] and c['sources_finalized'] and c['scene_id']=='ch4_s1_luoyang_yamen' and c['source_count']==1217
assert final['captured']['usec']<draw['usec']
assert c['live_phase_msec']=={'precomputed_packet_and_materialize':1982,'resolve_total':4856,'source_start_worker':2836}
phases=profile['phases']
for p,v in phases.items():
    assert v['finished_usec']-v['started_usec']==v['wall_usec'],p
    assert v['wall_time_includes_existing_awaits'] is True
assert phases['setup_total']['wall_usec']==7380835 and phases['district_prepare_and_projection']['wall_usec']==3097956 and phases['complete_source_final_await']['wall_usec']==3142170 and phases['environment_install']['wall_usec']==191565
assert phases['ready_ui']['finished_usec']<phases['setup_total']['started_usec']
contained=[p for p in phases if p not in ['ready_ui','setup_total']]
assert all(phases['setup_total']['started_usec']<=phases[p]['started_usec']<=phases[p]['finished_usec']<=phases['setup_total']['finished_usec'] for p in contained)
ordered=sorted((phases[p]['started_usec'],phases[p]['finished_usec'],p) for p in contained)
assert all(a[1]<=b[0] for a,b in zip(ordered,ordered[1:]))
contained_usec=sum(phases[p]['wall_usec'] for p in contained);remaining_usec=phases['setup_total']['wall_usec']-contained_usec
lm=record['LM']['metrics'];assert lm['scene_id']=='ch4_s1_luoyang_yamen' and lm['complete'] is True and lm['count']==lm['completed']==26 and lm['request_peak']==8 and lm['active_requests']==lm['draining_requests']==0
traces=[x for x in r['records'] if x['kind']=='PERF03_PHASE_CLOCK'];assert len(traces)==11
assert record['max_observe_gap_usec']==3047839 and any(x['C_scalars'].get('same_current_owner') and x['C_scalars'].get('sources_finalized') for x in traces)
ip=ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration17'
processpath=ip/'yamen_performance03_once_process_receipt.json';process=load(processpath,'c7b77e20a1f41a86994accc865a63b5389e56ed10d3190488837aa58ca42ea24')
assert process['actual_natural_console_exit_code']==-1073741819 and process['exit_code_from_retained_process_WaitForExit'] is True and process['process_stopped_by_tool'] is False
stderr=Path(process['stderr_path']).read_bytes();stdout=Path(process['stdout_path']).read_bytes()
assert sha(stderr)==process['stderr_sha256'] and sha(stdout)==process['stdout_sha256']
log=stderr.decode();errors=len(re.findall(r'^ERROR:',log,re.M));warnings=len(re.findall(r'^WARNING:',log,re.M))
assert errors==12 and warnings==2 and 'SCRIPT ERROR:' not in log
assert not list(rp.parent.glob('*.png'))
fieldtext=(ROOT/'scripts/field/field_walkable_controller.gd').read_text(encoding='utf-8')
assert 'await district.prepare(scene,navigation_objects,district_owner)' in fieldtext and 'await SceneRouter.finalize_field_transition_sources(source_validation_scene_id, source_validation_token)' in fieldtext
result={'status':'INDEPENDENT_YAMEN_PERF03_FUNCTIONAL_COMPONENTS_COMPLETE_PERFORMANCE_AND_PROCESS_FAILED','actual_result':{'path':'res://'+rp.relative_to(ROOT).as_posix(),'sha256':rh,'functional_complete':True,'checks':2465,'failures':0,'elapsed_ms':30596},'true_process_outcome':{'exit':-1073741819,'hex':'0xC0000005','receipt_sha256':'c7b77e20a1f41a86994accc865a63b5389e56ed10d3190488837aa58ca42ea24','retained_WaitForExit':True,'whole_clean_or_performance_PASS':False,'crash_root_cause':'NOT_PROVEN by leak logs or this receipt'},'source_first_last_current_SHA_bytes_seconds_exact':1238,'save_first_last_current_SHA_bytes_seconds_exact':15,'timing_usec':{'default_request_to_ready':15781110,'default_request_to_hidden_canmove_postdraw':15898031,'ready_to_hidden_draw':draw['elapsed_usec']-ready['elapsed_usec'],'first_under10s':False,'Field_setup_total':7380835,'Field_DT_prepare_and_projection':3097956,'Field_C_complete_source_final_await':3142170,'Field_ENV_install':191565,'Field_ready_UI_outside_setup_total':phases['ready_ui']['wall_usec'],'recorded_disjoint_child_spans_inside_setup':contained_usec,'setup_uninstrumented_wall_remainder_not_mainCPU_claim':remaining_usec},'C_msec_nested_not_additive':c['live_phase_msec'],'LM_metrics':lm,'identity_scope':{'C_last_active_and_finalized_same_token':1,'C_sources_expected_exact':1217,'C_snapshot_precedes_firstdraw':True,'resident_identity':identity,'Field_setup_identity_current':True,'Field_saved_transition_token':1,'Field_observed_live_transition_token_after_reset':0,'Field_getter_fresh_source_credit':False,'geometry_or_collector_called_for_owner':False},'phase_clock':{'events':len(traces),'max_original_poll_wall_gap_usec':3047839,'not_an_isolated_mainthread_measurement':True},'interpretation_limits':['C resolve includes source worker and materialize; never sum resolve plus children.','Field setup total includes the shown disjoint child wall spans and awaits; do not add total to children. ready_ui precedes setup_total.','DT phase includes prepare and object/navigation/NPC projection; it is not measured NPC rendering time alone.','C final-await includes full-source validation await and original owner checks; do not bypass hashing to satisfy timing.','LM scene_read_ms is cumulative from preload including drain, not an additional independent stage.','No source6017 crawl, geometry/route/furniture/room/INPUT/Physics or screenshot tests; this is one default entry, not SSDcold/allcity/repeat-time evidence.'],'nonclean_logs':{'errors':errors,'warnings':warnings,'script_errors':0,'WASAPI_dummy_fallback':True,'CanvasShader_RID_Texture_and_resource_exit_errors':True,'stderr_sha256':sha(stderr)},'QA_actions':{'engine_or_replay':False,'PNG_ctex_native_decode_or_geometry':False,'collector_or_source_validator_call':False,'production_or_old_report_write':False},'Root_next':'Use measured DT/source-final bottlenecks for a new scoped implementation decision. Do not rerun this baseline to wash performance or crash.'}
assert not OUT.exists();OUT.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(OUT),'sha256':sha(OUT.read_bytes()),'setup_child_total_usec':contained_usec,'setup_remainder_usec':remaining_usec}))
