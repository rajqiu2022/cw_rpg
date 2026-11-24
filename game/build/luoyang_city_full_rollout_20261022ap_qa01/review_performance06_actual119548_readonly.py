"""One readonly actual timing/identity audit, deliberately no 3GB payload rehash."""
import hashlib
import json
import re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).parent;SF=ROOT/'build/luoyang_city_full_rollout_20261022ap_source_finalize01'
def sha(b):return hashlib.sha256(b).hexdigest()
def load(p,h):
    b=p.read_bytes();assert sha(b)==h;return json.loads(b)
rp=SF/'performance27_yamen_light06/output/119548_2663/result.json'
rh='7d769cfb5a36ee5b2fc4abbde404d84984c494c4db2ecc0df21dd77ba6b9ed7a';r=load(rp,rh)
assert r['complete']and r['checks']==2490 and r['failures']==0 and r['elapsed_ms']==28581
assert r['source_before']==r['source_after']and len(r['source_before'])==1250
fp=SF/'performance28_yamen_light06_ROOT26/yamen_performance06_fixture_ROOT26_READY.json';fh='8174d7c32f48b666099ce753ee0306e0b372bb2b4841c73ced70e7c369df8953';f=load(fp,fh)
expected=dict(f['source_sha256']);expected['res://'+fp.relative_to(ROOT).as_posix()]=fh
assert expected=={p:v['sha256']for p,v in r['source_before'].items()}
small_paths=['res://scripts/city/luoyang_precomputed_bundle_20261018r.gd','res://scripts/city/luoyang_district_life_20261016f.gd','res://scripts/city/luoyang_parallel_source_hash_20261017k.gd','res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd','res://scripts/field/field_walkable_controller.gd','res://scripts/city/luoyang_assembled_interiors_20261016g.gd','res://'+fp.relative_to(ROOT).as_posix()]
for p in small_paths:
    q=ROOT/p[6:];b=q.read_bytes();fact=r['source_before'][p]
    assert sha(b)==fact['sha256']and len(b)==fact['bytes']and int(q.stat().st_mtime)==fact['mtime']
assert r['players_before']==r['players_after']and len(r['players_before'])==15
savedir=Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for p,v in r['players_before'].items():
    q=savedir/p[7:];assert q.exists()==v['exists']
    if q.exists():assert sha(q.read_bytes())==v['sha256']and q.stat().st_size==v['bytes']and int(q.stat().st_mtime)==v['mtime']
e=next(v for v in r['records']if v['kind']=='PERF06_ONE_DEFAULT_ENTRY_RESULT');n=next(v for v in r['records']if v['kind']=='PERF06_NATURAL_C_RECEIPT_SELECTIVE_READ')
assert n['sources']==f['expected_city_source_sha256']and len(n['sources'])==1225
assert n['identity']['token']==1 and n['identity']['sources_finalized']and n['identity']['scene_matches']
assert e['functional_entry_and_natural_owner_ok']and not e['first_under10s']
ready=e['ready'];draw=e['hidden_canmove_firstdraw'];profile=e['Field_profile'];dt=e['DT_timings_after_frozen_draw'];m=dt['metrics']
assert ready['elapsed_usec']==13668482 and draw['elapsed_usec']==13787677 and draw['loading_hidden_inactive']and draw['can_move']
assert ready['usec']-ready['elapsed_usec']==draw['usec']-draw['elapsed_usec']
assert ready['Field']==draw['Field']==profile['Field_instance']==dt['Field']and ready['Scene']==draw['Scene']==profile['scene_instance']==dt['Scene']==m['scene_instance']
assert profile['layout_instance']==dt['layout']==m['layout_instance']
assert profile['transition_token']==m['transition_token']==dt['resident_positive_token']==n['identity']['token']==1
assert profile['setup_identity_current']and not profile['same_live_transition']and profile['observed_live_transition_token']==0 and not profile['fresh_source_validation_credit']
assert dt['same_owner']and dt['not_fresh_source_evidence']and m['setup_identity_current']and not m['fresh_source_validation_credit']and m['profile_origin']=='DISTRICT_SETUP_NOT_WARM_RESUME'
assert dt['captured_after_frozen_draw']['usec']>draw['usec']and dt['getter_read_count']==e['DT_timing_getter_reads']==1
active=e['last_matching_active_C'];final=e['last_same_token_finalized_C'];assert active==final
c=final['C'];assert final['same_live_owner']==c['token']==1 and c['source_count']==1225 and c['sources_finalized']and c['active']and c['live_scope']and final['captured']['usec']<draw['usec']
assert c['live_phase_msec']=={'resolve_total':4094,'source_start_worker':2081,'precomputed_packet_and_materialize':1972}
ph=profile['phases'];sp=m['spans']
for v in ph.values():assert v['wall_usec']==v['finished_usec']-v['started_usec']
for v in sp.values():assert v['wall_usec']==v['finished_usec']-v['started_usec']
assert ph['setup_total']['wall_usec']==5975553 and ph['district_prepare_and_projection']['wall_usec']==2180206 and ph['complete_source_final_await']['wall_usec']==2608925
assert sp['projection_and_whole_parent_inverse']['wall_usec']==1942521 and sp['projection_and_whole_parent_inverse']['process_frames']==0
assert ph['ready_ui']['finished_usec']<ph['setup_total']['started_usec']
contained=sorted((v['started_usec'],v['finished_usec'],v['wall_usec'])for k,v in ph.items()if k not in ('ready_ui','setup_total'))
assert all(ph['setup_total']['started_usec']<=a<=b<=ph['setup_total']['finished_usec']for a,b,_ in contained)
assert all(a[1]<=b[0]for a,b in zip(contained,contained[1:]))
child=sum(v[2]for v in contained);remainder=ph['setup_total']['wall_usec']-child
lm=e['LM']['metrics'];assert lm['count']==lm['completed']==26 and lm['complete']and lm['active_requests']==lm['draining_requests']==0 and lm['request_peak']==8
traces=[v for v in r['records']if v['kind']=='PERF06_PHASE_CLOCK'];assert len(traces)==11 and e['max_observe_gap_usec']==2130226
process=load(ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration26/yamen_performance06_once_process_receipt.json','6029f32da64c277a3bb349bed45efa88424a546c207556510a0caa0f16e29da9')
assert process['actual_natural_console_exit_code']==-1073741819 and process['exit_code_from_retained_process_WaitForExit']and not process['process_stopped_by_tool']
logs={}
for kind in ('stdout','stderr'):
    raw=Path(process[kind+'_path']).read_bytes();assert sha(raw)==process[kind+'_sha256'];logs[kind]=raw.decode()
errors=len(re.findall(r'^ERROR:',logs['stderr'],re.M));warnings=len(re.findall(r'^WARNING:',logs['stderr'],re.M));assert errors==12 and warnings==2 and 'SCRIPT ERROR:'not in logs['stderr']
assert not list(rp.parent.glob('*.png'))
out=QA/'performance06_actual119548_independent_timing_identity_exit_review_READY.json'
result={'status':'FUNCTIONAL_ENTRY_COMPONENT_COMPLETE_PERFORMANCE_AND_PROCESS_FAILED_NOT_WHOLE_PASS','actual_result_sha256':rh,'functional_checks':2490,'functional_failures':0,'actual_scope_elapsed_ms':28581,'true_console_exit':-1073741819,'true_console_exit_hex':'0xC0000005','crash_cause':'NOT_PROVEN_BY_THIS_LOG','source_before_after_declared_expected_SHA_same':1250,'current_small_implementation_fixture_SHA_bytes_seconds_checked':len(small_paths),'all1250_payloads_or_3GB_rehashed':False,'save_before_after_current_SHA_bytes_seconds_same':15,'natural_C_expected_sources':1225,'same_DT_Field_Scene_layout_positive_token_and_postdraw_single_read':True,'DT_and_Field_metrics_freshsource_credit':False,'timing_usec':{'ready':13668482,'hidden_canmove_firstdraw':13787677,'ready_to_draw':draw['elapsed_usec']-ready['elapsed_usec'],'Field_setup_total':5975553,'Field_DT_prepare_projection':2180206,'DT_projection_whole_parent_inverse':1942521,'Field_source_final_await':2608925,'ENV_install':ph['environment_install']['wall_usec'],'readyUI_outside_setup':ph['ready_ui']['wall_usec'],'disjoint_child_sum_inside_setup':child,'uninstrumented_setup_wall_remainder':remainder},'under10':False,'C_nested_msec_not_additive':c['live_phase_msec'],'LM_metrics':lm,'phase_events':len(traces),'max_poll_gap_usec':e['max_observe_gap_usec'],'logs':{'errors':errors,'warnings':warnings,'Script_errors':0,'WASAPI_dummy_and_exit_resource_leaks_preserved':True},'optimization_evidence_boundary':'DT 1.942521s encloses several projection/copy/whole_bound/record inverse/wire-comparison operations and has no intermediate subspan. It supports targeting this synchronous region, not assigning all cost to one function, skipping validation, or a claimed saving. Cross-check fixed-source call graph before proposing reuse.','engine_collector_geometry_decode_or_replay':False,'old_report_or_production_writes':False,'whole_runtime_clean_or_performance_PASS':False}
guard=load(ROOT/'build/luoyang_city_full_rollout_20261022ap_root01/integration26/final_guard.json','5aeead442497a2778ce010ca396b7b50f2e4e9ee5c8da538a51eeaa4bff1ac5d')
assert guard['passed']and guard['exact_unchanged']==2117 and guard['save_count']==15 and guard['save_change_count']==0 and guard['unexpected_change_count']==0 and guard['all_changes']==[]
prior=load(SF/'performance16_yamen_light05/output/69256_2621/result.json','0864e2ee5d12e6e86fec1b13b817f216f881ca0f1c5a68df85e1737c6002b3f1')
pe=next(v for v in prior['records']if v['kind']=='PERF05_ONE_DEFAULT_ENTRY_RESULT')
draw_delta=pe['hidden_canmove_firstdraw']['elapsed_usec']-draw['elapsed_usec']
projection_delta=pe['DT_timings_after_frozen_draw']['metrics']['spans']['projection_and_whole_parent_inverse']['wall_usec']-sp['projection_and_whole_parent_inverse']['wall_usec']
assert draw_delta==661072 and projection_delta==790434
result['Root26_final_exact2117_including15save_ticks']=True
result['formal_revision']='AP14, deployedB9D5B'
result['one_observation_difference_from_prior05_usec']={'hidden_draw_lower':draw_delta,'DT_projection_lower':projection_delta}
result['comparison_limit']='One05 and one06 observation only, not causal statistics or SSDcold/repeat/all-city gain; never multiply pure-record timing gains by call counts. Firstdraw remains over10s and processC0000005 remains a failure.'
assert not out.exists();out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8');print(json.dumps({'path':str(out),'sha256':sha(out.read_bytes()),'setup_remainder_usec':remainder}))
