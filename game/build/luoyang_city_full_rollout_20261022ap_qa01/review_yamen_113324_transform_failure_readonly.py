"""Read only actual result, preserving transform FAIL and separate timing credit."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).resolve().parent
P=QA/'yamen_three_low_props_classified/113324_2708/result.json'
OUT=QA/'yamen_113324_transform_failure_independent_review_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(P)=='4360c20d9c55fc7717afbf728c11cbabb6344c04012f8bda9280b6a05a9dcc86'
r=json.loads(P.read_bytes());assert r['complete'] is False and (r['checks'],r['failures'],r['elapsed_ms'])==(2456,2,33415)
assert r['source_before']==r['source_after'] and len(r['source_before'])==1225
assert r['players_before']==r['players_after'] and len(r['players_before'])==15
fixture=json.loads((QA/'yamen_three_low_props_classification_fixture_READY.json').read_bytes())
assert len(fixture['expected_city_source_sha256'])==1211
for path,h in fixture['expected_city_source_sha256'].items():assert r['source_before'][path]['sha256']==h
t=next(x for x in r['records'] if x['kind']=='ONE_LEG_TIMING')
s=next(x for x in r['records'] if x['kind']=='SINGLE_YAMEN_FINITE_SCOPE')
assert s['ready']['elapsed_usec']==16397959 and s['firstdraw']['elapsed_usec']==16517877
assert s['firstdraw']['loading_hidden_inactive'] is True and s['firstdraw']['can_move'] is True
assert s['ready']['Field']==s['firstdraw']['Field'] and s['ready']['Scene']==s['firstdraw']['Scene']
c=t['last_matching_active_profile']['C'];assert c['active'] is True and c['live_scope'] is True and c['sources_finalized'] is True and c['source_count']==1211
assert c['scene_id']=='ch4_s1_luoyang_yamen' and c['token']==t['last_matching_active_profile']['same_live_owner']==1
assert t['profile_after_draw']['active'] is False and t['profile_after_draw']['token']==0
assert s['Physics_queries_actual']==1 and s['native_mask_observations_actual']==17
assert s['first_actual_input']=={} and s['pictures']==[]
assert not OUT.exists()
report={'status':'INDEPENDENT_REAL_YAMEN_ENTRY_COMPONENTS_PASSED_TRANSFORM_WHOLE_FAIL','actual_result':{'path':'res://'+P.relative_to(ROOT).as_posix(),'sha256':sha(P)},'complete':False,'checks':2456,'failures':2,'whole_attempt_elapsed_ms':33415,'source_before_after_exact_facts':1225,'production_expected_count':1211,'save_before_after_exact_seconds_facts':15,'save_precision_boundary':'Report mtime seconds, not Root exactticks; no new save snapshot or restore.','entry_component':{'ready_seconds':16.397959,'first_postdraw_loading_hidden_can_move_seconds':16.517877,'same_scene_field_player':True,'initial_below10_seconds':False},'last_matching_same_token_source_profile':c,'LM_same_scene_profile':t['last_matching_active_profile']['LM'],'timing_boundaries':['resolve_total includes source_start_worker and packet/materialize; do not sum them.','LM elapsed/scene_read are inclusive cumulative counters, not independent addends.','main_stage_timings.module_live empty means unavailable, not measured zero.','profile_after_draw is reset/token0, not a fresh source profile.'],'passed_before_failure':['Natural exact precomputed owner and complete1211 source equality','Exact Scene/layout/world and existing Field mask full frozen RGBA','Default foot actual17 and one original34x24 Physics query','Exactly one first north prop sprite/body identified'],'not_granted':['First prop full transform','Any three polygon comparison','NPC six config','Any INPUT/front block/ghost/restoration','Pictures','Whole test PASS','Loading under10s'],'mask_observations':17,'Physics_queries':1,'INPUT_or_picture_count':0,'transform_actual_values_recorded':False,'engine_runs':0,'collector_calls':0,'native_or_PNG_decode':0,'canonical_writes':0}
OUT.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review_sha256':sha(OUT),'whole_complete':False,'entry_firstdraw_seconds':16.517877,'INPUT':0,'pictures':0}))
