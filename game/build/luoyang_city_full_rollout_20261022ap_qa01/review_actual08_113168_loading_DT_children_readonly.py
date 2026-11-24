"""Actual08 selective facts only; no new engine, source collector or big scan."""
from pathlib import Path
import hashlib,json,re
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
ROOT=GAME/'build/luoyang_city_full_rollout_20261022ap_root01'
SF=GAME/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
D=QA/'yamen_performance08_ROOT32_FINAL_READY'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
rp=D/'output/113168_2636/result.json';r=read(rp)
assert sha(rp)=='66f22a34a93e987b51cf8474af673d169723d9104227fc64d04d688177b07928'
assert (r['checks'],r['complete'],r['failures'],r['elapsed_ms'])==(2534,True,0,27311)
assert r['source_before']==r['source_after']and len(r['source_before'])==1264
assert r['players_before']==r['players_after']and len(r['players_before'])==15
fixturepath=D/'yamen_performance08_fixture_ROOT32_READY.json';fixture=read(fixturepath)
assert sha(fixturepath)=='1c113244799813688f0c95fa3775e8867486b92baebcf8134d4a2313646667f0'
expected={**fixture['source_sha256'],'res://'+fixturepath.relative_to(GAME).as_posix():sha(fixturepath)}
assert len(expected)==1264 and {k:v['sha256']for k,v in r['source_before'].items()}==expected
ownerp=SF/'performance43_culture_actual_independent_review/owner_source_maps_READY.json'
assert sha(ownerp)=='544819c110e16409baa090ff807fb314e221bb9d853c353ef6171090427326c0'
owner=read(ownerp);y=next(v for v in owner['scenes']if v['id']=='ch4_s1_luoyang_yamen')
natural=[v for v in r['records']if v['kind']=='PERF08_NATURAL_C_RECEIPT_SELECTIVE_READ']
children=[v for v in r['records']if v['kind']=='PERF08_SIX_DT_CHILD_SPANS']
entries=[v for v in r['records']if v['kind']=='PERF08_ONE_DEFAULT_ENTRY_RESULT']
assert len(natural)==len(children)==len(entries)==1 and len(r['records'])==14
n=natural[0];cs=children[0];entry=entries[0];ident=n['identity']
assert n['sources']==fixture['expected_city_source_sha256']==y['source_sha256']==y['receipt_source_sha256']and len(n['sources'])==1239
assert ident['scene_matches']and ident['scene_id']=='ch4_s1_luoyang_yamen'and ident['token']==1 and ident['sources_finalized']is True and ident['sources_count']==1239 and ident['proof_kind']=='PRECOMPUTED_PUBLISHED_FULL_SOURCE_V1'
assert ident['native_scene_path']==fixture['scene_path']and ident['native_layout_path']==fixture['layout_path']
ready,draw=entry['ready'],entry['hidden_canmove_firstdraw']
assert ready['elapsed_usec']==12677350 and draw['elapsed_usec']==12809060 and draw['loading_hidden_inactive']and draw['can_move']
assert ready['usec']-ready['elapsed_usec']==draw['usec']-draw['elapsed_usec']and draw['usec']>=ready['usec']
assert all(ready[k]==draw[k]for k in ('Field','Scene','Player'))
assert entry['first_under10s']is False and entry['target_usec']==10000000 and entry['functional_entry_and_natural_owner_ok']is True
assert entry['DT_timing_getter_reads']==1
dt=entry['DT_timings_after_frozen_draw'];m=dt['metrics'];spans=m['spans'];outer=spans['projection_and_whole_parent_inverse']
assert dt['same_owner']and dt['getter_read_count']==1 and dt['captured_after_frozen_draw']['usec']>=draw['usec']
assert dt['Field']==draw['Field']and dt['Scene']==draw['Scene']==m['scene_instance']and dt['layout']==m['layout_instance']
assert dt['resident_positive_token']==m['transition_token']==ident['token']==1
assert m['setup_identity_current']and m['profile_origin']=='DISTRICT_SETUP_NOT_WARM_RESUME'and m['fresh_source_validation_credit']is False
last=outer['started_usec'];total=0;walls={}
assert outer['wall_usec']==outer['finished_usec']-outer['started_usec']==1731953
for label,actual in zip(fixture['required_DT_projection_children'],cs['children']):
    child=spans[label]
    assert actual=={'label':label,'started_usec':child['started_usec'],'finished_usec':child['finished_usec'],'wall_usec':child['wall_usec']}
    assert child['started_usec']>=last and child['finished_usec']>=child['started_usec']and child['finished_usec']<=outer['finished_usec']
    assert child['wall_usec']==child['finished_usec']-child['started_usec']
    last=child['finished_usec'];total+=child['wall_usec'];walls[label]=child['wall_usec']
assert walls=={'projection_detail.g_project':404541,'projection_detail.layout_author':15314,'projection_detail.t_transform':49999,'projection_detail.parent_clones_and_receipts':50390,'projection_detail.b_restore_t':862697,'projection_detail.same_wire':348896}
assert total==cs['child_sum_usec']==1731837 and cs['outer_residual_usec']==outer['wall_usec']-total==116 and cs['getter_read_count']==1 and cs['same_owner']
assert cs['children_not_added_to_outer']and cs['g_project_not_isolated_JSON_parse']and cs['freshsource_credit']is False
profile=entry['Field_profile'];p=profile['phases']
assert profile['status']=='READY'and profile['setup_identity_current']and profile['Field_instance']==draw['Field']and profile['scene_instance']==draw['Scene']and profile['layout_instance']==dt['layout']
assert profile['transition_token']==1 and profile['observed_live_transition_token']==0 and profile['same_live_transition']is False and profile['fresh_source_validation_credit']is False
assert p['setup_total']['wall_usec']==5416420 and p['complete_source_final_await']['wall_usec']==2352787 and p['district_prepare_and_projection']['wall_usec']==1969255 and p['environment_install']['wall_usec']==190565
assert p['district_prepare_and_projection']['started_usec']<=outer['started_usec']<=outer['finished_usec']<=p['district_prepare_and_projection']['finished_usec']
assert p['setup_total']['finished_usec']<=ready['usec']and entry['last_same_token_finalized_C']['C']['sources_finalized']is True
c=entry['last_same_token_finalized_C']['C']
assert c['token']==1 and c['source_count']==1239 and c['live_phase_msec']=={'precomputed_packet_and_materialize':2026,'resolve_total':4027,'source_start_worker':1960}
lm=entry['LM']['metrics'];assert lm['count']==lm['completed']==26 and lm['elapsed_ms']==237.68 and lm['complete']and lm['active_requests']==lm['draining_requests']==0
processp=ROOT/'integration32/yamen_performance08_once_process_receipt.json';process=read(processp)
assert sha(processp)=='f7feaa02bf0a91710335d2ed5925c82fd635979daaa754316308f3938b4a7f90'
assert process['actual_natural_console_exit_code']==-1073741819 and process['exit_code_from_retained_process_WaitForExit']and not process['process_stopped_by_tool']
assert process['script_sha256']==process['script_after_sha256']==sha(D/'test_yamen_performance08_ROOT32_FINAL_READY.gd')=='01e9e50b94aa4cf9b97d4f224938c5e1a98ad8c4328ea7128d9ccd4174d445b3'
stderrp=ROOT/'integration32/yamen_performance08_once_stderr.log';stdoutp=ROOT/'integration32/yamen_performance08_once_stdout.log'
assert sha(stderrp)==process['stderr_sha256']and sha(stdoutp)==process['stdout_sha256']
err=stderrp.read_text(encoding='utf-8-sig');logcounts={'ERROR':len(re.findall(r'^ERROR:',err,re.M)),'WARNING':len(re.findall(r'^WARNING:',err,re.M)),'SCRIPT_ERROR':len(re.findall(r'^SCRIPT ERROR:',err,re.M))}
assert logcounts=={'ERROR':10,'WARNING':1,'SCRIPT_ERROR':0}
assert 'CULTURE_X_SOURCE_CHANGED'not in err
guardp=ROOT/'integration32/final_guard.json';guard=read(guardp)
assert sha(guardp)=='2ecd58b5ca647489eb94725ac88bf1ae060677090ffd77d43a05e37aa94b5bf2'
assert guard['passed']and guard['checked']==guard['exact_unchanged']==2118 and guard['authorized_change_count']==guard['unexpected_change_count']==guard['save_change_count']==0 and guard['save_count']==15
savebase=Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for key,row in r['players_after'].items():
    f=savebase/key.removeprefix('user://');assert f.exists()==row['exists']
    if row['exists']:assert f.stat().st_size==row['bytes']and sha(f)==row['sha256']
prior_draw_usec=13787677;prior_projection_usec=1942521
out=QA/'actual08_113168_DTchildren_independent_readonly_review_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'ACTUAL08_FUNCTIONAL_ENTRY_AND_SIX_DT_CHILDREN_CONFIRMED_PERFORMANCE_AND_EXIT_FAIL_PRESERVED','report':{'path':str(rp),'sha256':sha(rp)},'process_receipt':{'path':str(processp),'sha256':sha(processp)},'root_final_guard':{'path':str(guardp),'sha256':sha(guardp)},'functional':{'complete':True,'checks':2534,'failures':0,'report_elapsed_ms':27311,'natural_same_owner_FINAL_sources':1239,'independent_owner5448_exact':True,'source_guard_first_final_count':1264,'source_guard_values_fixed_fixture_plus_fixture_itself':True,'save15_report_firstfinal_and_current_SHA_bytes_same':True,'Root2118exactticks_guard_inherited_not_rerun':True,'INPUT_images_geometry_collectors':0},'performance':{'target_usec':10000000,'ready_usec':12677350,'hidden_canmove_draw_usec':12809060,'under10s':False,'draw_minus_ready_usec':131710,'C_nested_msec':c['live_phase_msec'],'Field_setup_total_usec':5416420,'Field_FINALawait_usec':2352787,'Field_district_outer_usec':1969255,'ENV_usec':190565,'LM_component_ms':237.68,'LM_textures':26,'process_wall_ms':process['elapsed_wall_ms'],'span_envelopes_nested_not_added':True},'DT':{'getter_once_after_draw':True,'same_Field_Scene_layout_session_token1':True,'metrics_not_fresh_source_proof':True,'six_wall_usec':walls,'sum_usec':1731837,'outer_usec':1731953,'residual_usec':116,'all_six_exact_sequential_inside_outer':True,'largest_observed_child':'projection_detail.b_restore_t','g_project_includes_SHA_JSON_projection_not_pureparse':True},'single_observations_vs06':{'draw_lower_usec':prior_draw_usec-draw['elapsed_usec'],'projection_outer_lower_usec':prior_projection_usec-outer['wall_usec'],'noncausal_not_statistically_stable_gain':True,'07_failure_not_an_entry_baseline':True},'exit':{'true_console_code':-1073741819,'hex':'C0000005','whole_clean_PASS':False,'logs':logcounts,'exit_root_cause_not_inferred':True},'limits':['No new engine/collector/whole-source or media hash scan','Functional success does not meet10s target or erase true exit crash','No wholecity ART/NPC/room/hall/resident warm credit','Old07 FAIL and all prior reports unchanged']},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'logcounts':logcounts,'draw_usec':draw['elapsed_usec'],'DT_outer_usec':outer['wall_usec']}))
