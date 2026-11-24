"""Preserve the first true Yamen default-entry failure without runtime replay."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).resolve().parent
P=QA/'yamen_three_low_props_metrics/14912_2691/result.json'
OUT=QA/'yamen_14912_failed_admission_independent_review_READY.json'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
assert sha(P)=='916ce7342a7258a6bbe76e3f039b937146082bbc8afa5ebeef04388b06831095'
r=json.loads(P.read_bytes())
assert r['complete'] is False and r['checks']==2446 and r['failures']==2 and r['elapsed_ms']==17399
assert r['source_before']==r['source_after'] and len(r['source_before'])==1222
assert r['players_before']==r['players_after'] and len(r['players_before'])==15
fixture=json.loads((QA/'yamen_three_low_props_metrics_fixture_READY.json').read_bytes())
for p,h in fixture['expected_city_source_sha256'].items():
    assert r['source_before'][p]['exists'] is True and r['source_before'][p]['sha256']==h
assert len(fixture['expected_city_source_sha256'])==1211
terminal=next(x for x in r['records'] if x['kind']=='TERMINAL_REQUEST_FAILURE')
assert terminal['public']['accepted'] is True and terminal['public']['phase']=='FAILED'
assert terminal['public']['error']=='CITY_COMPLETE_LIVE_VALIDATION_FAILED'
assert terminal['C_errors']==['Live complete source identity unavailable']
assert terminal['timing']=={}
scope=next(x for x in r['records'] if x['kind']=='SINGLE_YAMEN_FINITE_SCOPE')
assert all(scope[k]=={} for k in ['ready','firstdraw','first_actual_input','last_matching_profile'])
assert scope['pictures']==[] and scope['Physics_queries_actual']==scope['native_mask_observations_actual']==0
assert not OUT.exists()
v={'status':'INDEPENDENT_FAILED_REAL_DEFAULT_YAMEN_ADMISSION_NOT_LOADING_PASS','actual_result':{'path':'res://'+P.relative_to(ROOT).as_posix(),'sha256':sha(P)},'complete':False,'checks':2446,'failures':2,'whole_attempt_elapsed_ms':17399,'source_facts_before_after_exact':1222,'independent_production_source_count_protected':1211,'save_before_after_exact_seconds_facts':15,'save_precision_boundary':'Report stores seconds mtime, not Root exactticks. No save restoration or new current-save snapshot performed.','terminal_public':terminal['public'],'C_errors':terminal['C_errors'],'successful_loading_duration':None,'empty_ready_draw_profile_is_not_zero_or_fresh':True,'Field_or_input_or_Physics_or_picture_credit':False,'finite_prop_assertions_executed':0,'old_parse_failure110148_preserved_separate':True,'engine_runs':0,'collector_calls':0,'native_or_PNG_decode':0,'canonical_writes':0}
OUT.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'review_sha256':sha(OUT),'result_complete':False,'production_protected':1211,'successful_loading_duration':None}))
