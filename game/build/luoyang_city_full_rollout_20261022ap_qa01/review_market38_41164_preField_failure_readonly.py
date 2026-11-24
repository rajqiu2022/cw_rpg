"""Read one rejected actual only; no retry, collector or diagnostic execution."""
from pathlib import Path
import hashlib,json,re
QA=Path(__file__).resolve().parent;GAME=QA.parents[1]
D=QA/'market_pawn_single_visual_ROOT38_READY';R=GAME/'build/luoyang_city_full_rollout_20261022ap_root01/integration38'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
rp=D/'output/41164_2755/result.json';assert sha(rp)=='ef0392075051fab45b6f9da070a0a93c24133459f9fba77b20c8b934c09a9c2b'
r=rd(rp);fp=D/'market_pawn_single_visual_fixture_ROOT38_READY.json';f=rd(fp)
assert sha(fp)=='b57f43d13a1251f933928467883d6c74d100ceedc248669f49586d939c79881b'
assert (r['checks'],r['complete'],r['failures'],r['elapsed_ms'])==(3432,False,2,19511)
assert r['source_before']==r['source_after']and len(r['source_before'])==1723
expected={**f['source_sha256'],'res://'+fp.relative_to(GAME).as_posix():sha(fp)}
assert {k:v['sha256']for k,v in r['source_before'].items()}==expected
assert r['players_before']==r['players_after']and len(r['players_before'])==15
assert len(r['records'])==2
failure,counters=r['records']
assert failure['kind']=='MARKET_PUBLIC_FAILURE'and failure['C_errors']==['Bundle manifest/artifact/current complete legacy source set differs']
public=failure['public']
assert public['scene_id']=='ch4_s3_luoyang_market'and public['accepted']and not public['active']and public['phase']=='FAILED'and public['error']=='CITY_COMPLETE_LIVE_VALIDATION_FAILED'and public['prepared_msec']==0
assert public['bool_means']=='ACCEPTED_ENQUEUED_NOT_READY'
assert counters['kind']=='MARKET_FINITE_OBSERVATION_COUNTS'
for k in ['Space_calls','actual_body_queries','already_loaded_mask_samples','collector_calls','new_geometry','room_or_crossdistrict_trips']:assert counters[k]==0
assert not list(rp.parent.glob('*.png'))
pp=R/'market_pawn_once_process_receipt.json';pr=rd(pp)
assert sha(pp)=='05f94a2bc37a1d3736a66120c4d94e2a9f9e369a8ef47d9b73d110bd79ac8faa'
assert pr['actual_natural_console_exit_code']==1and pr['exit_code_from_retained_process_WaitForExit']and not pr['process_stopped_by_tool']
kp=D/'test_market_pawn_single_visual_ROOT38_READY.gd'
assert sha(kp)==pr['script_sha256']==pr['script_after_sha256']=='08e9da3acd99281f2196ffd6060a1c5eb0383953a2b274f106d837b174554274'
ep,op=R/'market_pawn_once_stderr.log',R/'market_pawn_once_stdout.log'
assert sha(ep)==pr['stderr_sha256']and sha(op)==pr['stdout_sha256']
err=ep.read_text(encoding='utf-8-sig')
counts={k:len(re.findall(v,err,re.M))for k,v in {'ERROR':r'^ERROR:','WARNING':r'^WARNING:','SCRIPT_ERROR':r'^SCRIPT ERROR:'}.items()}
assert counts=={'ERROR':7,'WARNING':1,'SCRIPT_ERROR':0}
assert 'CITY_LIFE_QA_FAIL Matching public failure, no arrival credit'in err
gp,bp=R/'final_guard.json',R/'guard_before.json';g,b=rd(gp),rd(bp)
assert sha(gp)=='6d393713083f7b863f26819d104a2567eff86ddf6121b5d8622e2afaffdbda3a'
assert g['passed']and g['checked']==g['exact_unchanged']==2118and g['authorized_change_count']==g['unexpected_change_count']==g['save_change_count']==0and g['save_count']==15
assert g['facts']==b['facts']
small_count=0
for path,digest in f['source_sha256'].items():
    if path.startswith('res://scripts/'):
        p=GAME/path[6:];assert p.stat().st_size<1048576and sha(p)==digest;small_count+=1
savebase=Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for path,row in r['players_after'].items():
    p=savebase/path.removeprefix('user://');assert p.exists()==row['exists']
    if row['exists']:assert p.stat().st_size==row['bytes']and sha(p)==row['sha256']
out=QA/'market38_41164_preField_source_refusal_independent_readonly_review_READY.json';assert not out.exists()
out.write_text(json.dumps({'status':'MARKET38_WHOLEFAIL_SOURCE_REFUSAL_BEFORE_FIELD_NO_IMAGE_NO_RETRY','report':{'path':str(rp),'sha256':sha(rp)},'actual':{'checks':3432,'failures':2,'complete':False,'elapsed_ms':19511,'public':public,'C_errors':failure['C_errors'],'one_public_request_accepted_not_ready':True,'no_successful_ready_draw_naturalFINAL_or_Field_credit':True,'zero_bodymask_INPUT_Space_room_capture':True,'noPNG_exists':True,'old1700_table_only_fixed_expectation_not_this_actual_naturalreceipt':True,'specific_missing_or_different_sourcekeys_not_observed_here':True},'source_save_guard':{'1723_report_FIRSTFINAL_same':True,'fixed1722guard_plusfixture_exact':True,'current_small_script_SHA_exact_count':small_count,'15save_report_and_currentSHAbytes_same':True,'Root38_2118facts_exactticks_beforeafter_same':True,'guard_sha256':sha(gp),'no_full_media_or_collector_rehash':True},'exit':{'process_receipt_sha256':sha(pp),'true_console':1,'not_C0000005_this_run':True,'elapsed_wall_ms':pr['elapsed_wall_ms'],'log_counts':counts,'nonclean':True,'not_process_clean_or_runtime_success':True},'preserved':['this wholeFAIL/no image','all priorhall/performancefailures and priorC0000005crashes'],'operations':{'engine':0,'collector':0,'newkey_or_retry':0,'Stage':0,'native_or_image_decode':0,'canonical_or_oldreport_writes':0}},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'current_small_script_count':small_count,'true_exit':1,'log_counts':counts}))
