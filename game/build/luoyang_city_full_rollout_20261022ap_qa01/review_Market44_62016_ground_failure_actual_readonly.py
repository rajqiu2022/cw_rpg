"""Read completed unique44 report/logs; no retry or media/source recollection."""
from pathlib import Path
import hashlib
import json
import re

Q=Path(__file__).resolve().parent;G=Q.parents[1]
D=Q/'market_pawn_single_visual_ROOT44_READY'
R=G/'build/luoyang_city_full_rollout_20261022ap_root01/integration44'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def rd(p):return json.loads(p.read_text(encoding='utf-8-sig'))
rp=D/'output/62016_2825/result.json'
assert sha(rp)=='d64bb1b9a18eed7dde0594c0a1fa76eec1101fd27f1d47039e36587130d801f7'
r=rd(rp)
assert (r['checks'],r['failures'],r['complete'],r['elapsed_ms'])==(3467,2,False,23675)
fp=D/'market_pawn_single_visual_fixture_ROOT44_READY.json'
assert sha(fp)=='5a4038ba83eb2a502af3029b0ae81456610a7e0608df025d02a18318ae1ad952'
f=rd(fp)
assert len(f['expected_sources'])==1712 and len(f['source_sha256'])==1745
assert len(r['source_before'])==1746 and r['source_before']==r['source_after']
expected={**f['source_sha256'],'res://'+fp.relative_to(G).as_posix():sha(fp)}
assert {p:v['sha256'] for p,v in r['source_before'].items()}==expected
assert len(r['players_before'])==15 and r['players_before']==r['players_after']
assert len(r['records'])==2
failure,counters=r['records']
assert failure['kind']=='MARKET_FIELD_FAILURE'
state=failure['loading']
assert state['scene_id']=='ch4_s3_luoyang_market' and state['failed'] and not state['complete'] and state['progress']==0.1
assert counters['kind']=='MARKET_FINITE_OBSERVATION_COUNTS'
for k in ['Space_calls','actual_body_queries','already_loaded_mask_samples','collector_calls','new_geometry','room_or_crossdistrict_trips']:assert counters[k]==0
assert not list(rp.parent.glob('*.png'))
pp=R/'market_pawn_once_process_receipt.json'
assert sha(pp)=='28d7280ed6d68ef00954722aaf1c1f983e72b68b2bb324d5872b751be509b50e'
pr=rd(pp)
assert pr['actual_natural_console_exit_code']==-1073741819 and pr['exit_code_from_retained_process_WaitForExit'] and not pr['process_stopped_by_tool']
kp=D/'test_market_pawn_single_visual_ROOT44_READY.gd'
assert sha(kp)==pr['script_sha256']==pr['script_after_sha256']=='583020fe2ddd3a9475f0da8a2f7550ef6856f610052906d34b0735b539d0ca66'
ep,op=R/'market_pawn_once_stderr.log',R/'market_pawn_once_stdout.log'
assert sha(ep)==pr['stderr_sha256'] and sha(op)==pr['stdout_sha256']
err=ep.read_text(encoding='utf-8-sig')
counts={k:len(re.findall(pattern,err,re.M)) for k,pattern in {'ERROR':r'^ERROR:','WARNING':r'^WARNING:','SCRIPT_ERROR':r'^SCRIPT ERROR:'}.items()}
assert counts=={'ERROR':9,'WARNING':1,'SCRIPT_ERROR':0}
assert '[Field] District life refused: MARKET_GROUND_OWNER_OR_PARENT' in err
assert 'T_COMPLETE_REVERSIBLE_PARENT_RECORD' not in err
assert 'prepare (res://scripts/city/luoyang_district_life_20261016f.gd:226)' in err
assert 'Matching Field failure before draw' in err and 'Predeclared whole finite scope' in err
gp,bp=R/'final_guard.json',R/'guard_before.json'
assert sha(gp)=='e856e25ef8ed76e829e6ec752e0d50ab3945eeec11390331d4c26665586d9cfc'
g,b=rd(gp),rd(bp)
assert g['passed'] and g['checked']==g['exact_unchanged']==2118 and g['save_count']==15
assert g['authorized_change_count']==g['unexpected_change_count']==g['save_change_count']==0
assert g['facts']==b['facts']
tp=R/'source_only_three_facts_after.json'
assert sha(tp)=='766b9680972cfed65750ab37377cc0fe1daee6b83d03445fa3cbcbc11f5393c4'
t=rd(tp);tb=rd(R/'source_only_three_facts_before.json')
prior=rd(G/'build/luoyang_city_full_rollout_20261022ap_root01/integration39/proof_autoimport_tuple_before_retry1.json')
assert t['facts']==tb['facts']==prior['facts'] and t['runtime_texture_credit'] is False
small=0
for path,digest in f['source_sha256'].items():
    if path.startswith('res://scripts/'):
        p=G/path[6:];assert p.stat().st_size<1048576 and sha(p)==digest;small+=1
savebase=Path('C:/Users/rajqiu/AppData/Roaming/Godot/app_userdata/云影侠传')
for path,row in r['players_after'].items():
    p=savebase/path.removeprefix('user://');assert p.exists()==row['exists']
    if row['exists']:assert p.stat().st_size==row['bytes'] and sha(p)==row['sha256']
dt=(G/'scripts/city/luoyang_district_life_20261016f.gd').read_text(encoding='utf-8-sig')
ground=(G/'scripts/city/luoyang_market_ground_20261020ae.gd').read_text(encoding='utf-8-sig')
assert dt.index('if current.is_empty(): return _reject("T_COMPLETE_REVERSIBLE_PARENT_RECORD")')<dt.index('_market_ground=ground.prepare(')<dt.index('_receipt={"matched":true')
assert 'if scene==null or scene.scene_id!=ID or not owner.is_valid() or not owner.call() or base_render.size()!=BASE_COUNT: return {"ok":false,"error":"MARKET_GROUND_OWNER_OR_PARENT"}' in ground
out=Q/'Market44_62016_later_ground_refusal_wholeFAIL_independent_review_READY.json'
assert not out.exists()
out.write_text(json.dumps({
    'status':'MARKET44_WHOLEFAIL_LATER_GROUND_PREPARE_NO_DRAW_IMAGE_INPUT_OR_FINAL_OWNER_CREDIT',
    'actual':{'report_SHA':sha(rp),'checks':3467,'failures':2,'complete':False,'elapsed_ms':23675,
        'only_loading_failure_snapshot':failure,'all_finite_action_counters_zero':True,'noPNG':True,
        'reached_DT226_ground_prepare_after_previous_T_inverse_and_samewire_gates':True,
        'not_observed_which_aggregate_ground_predicate_failed':True,
        'no_natural1712_FINAL_or_C_record_pair_dictionary_saved':True,
        'loading_progress10percent_is_not_elapsed_or_render_percentage':True,
        'no_successful_entry_ready_hidden_draw_time_available':True},
    'protection':{'1746_report_FIRSTFINAL_fixed1745_plus_fixture_exact':True,'current_small_scripts_exact':small,
        '15save_report_and_currentSHAbytes_same':True,'Root2118facts_exactticks_beforeafter_same':True,
        'Root_final_guard_SHA':sha(gp),'three_SOURCE_ONLY_facts_same_prior39_beforeafter_not_rehashed':True,'threefacts_after_SHA':sha(tp)},
    'exit':{'true_console':-1073741819,'hex':'0xC0000005','nonclean':True,'process_receipt_SHA':sha(pp),
        'wall_ms':pr['elapsed_wall_ms'],'log_counts':counts,'crash_rootcause_not_claimed':True},
    'source_boundary':['MARKET_GROUND_OWNER_OR_PARENT aggregates scene null/id, owner validity, owner.call and BASE_COUNT; report contains no separating values',
        'Current ground helper fixed BASE_COUNT36 is a readonly source lead, not a measured actual render count',
        'Do not bypass ground owner/parent checks or redraw/retry to manufacture ART evidence',
        'ROOT38/41/44 wholeFAIL and all C0000005 exits preserved; repair of earlier T order is not whole runtime success'],
    'operations':{'engine':0,'collector':0,'new_test':0,'packet_or_image_decode':0,'mediahash':0,'Stage':0,'canonical':0}
},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'receipt':str(out),'sha256':sha(out),'true_exit':-1073741819,'log_counts':counts,'current_scripts':small}))
