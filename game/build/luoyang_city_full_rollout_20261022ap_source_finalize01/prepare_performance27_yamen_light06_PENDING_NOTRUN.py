"""NEW pending performance06 text only, no future source SHA/expected map fill."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'performance17_yamen_light05_ROOT21/';O=S+'performance27_yamen_light06/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s;return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
pp=P+'test_yamen_performance05_ROOT21_READY.gd';ps='b88b9322905405ed0b018f747a39fc502f005893f8ea8b424832786eee56fd4a'
parent=fixed(pp,ps)
oldfp=P+'yamen_performance05_fixture_ROOT21_READY.json';oldfs='e8b1bea1a4b84f3227c1dacfffc353f2a101f5f481867765d5210e45463c27e7'
fixture=json.loads(fixed(oldfp,oldfs))
fixture.update(status='PENDING_CANONICAL_B_ACTUAL_STAGE_OWNER_AND_ROOT25_DEPLOYMENT_PERFORMANCE06_NOT_RUN',ready=False,source_sha256={},expected_city_source_sha256={},
 blockers=['Root unique canonical-B exact22 actual source receipt and independent owner are required; no invented header hashes','Root25 actual deployment guard and exactcopy must pass, followed by NEW mechanical ready freeze and QA admission'],
 authority={'fixed_prior_owner':{'path':S+'performance15_B_only_actual_independent_review/owner_source_maps_READY.json','sha256':'5050ba8038aa1fbdf5c07f086427f5230171a93819ca5a6dd8ebb8da30d54e4e'},
 'independent_owner':{'path':S+'performance26_canonical_B_actual_independent_review/owner_source_maps_READY.json','sha256':None,'pending':True},
 'actual_source_stage':{'path':S+'outputs/root_B_canonical_keys_stage01/receipt.json','sha256':None,'pending':True},
 'actual_Root_deployment_guard':{'path':'res://build/luoyang_city_full_rollout_20261022ap_root01/integration25/final_guard.json','sha256':None,'pending':True},
 'actual_Root_deployment_copy':{'path':None,'sha256':None,'pending':True}},
 pending_authority_not_in_source_guard_until_real_freeze=True,
 expected_source_count_recipe={'fixed5050':1223,'two_new_canonical_B_proof_leaves':2,'derived_pending_count':1225,'not_actual_collector_observation':True},
 no_pre_stage_expected_map_or_current_source_fill=True)
fp=O+'yamen_performance06_fixture_PENDING_ROOT.json';fb=js(fixture);key=parent;hunks=[]
def replace(a,b):
    global key
    aa,bb=a.encode(),b.encode();assert key.count(aa)==1;hunks.append({'old':a,'new':b});key=key.replace(aa,bb,1)
replace('const FIXTURE="'+oldfp+'"','const FIXTURE="'+fp+'"')
replace('const FIXTURE_SHA="'+oldfs+'"','const FIXTURE_SHA="'+sha(fb)+'"')
replace('fixture.expected_city_source_sha256.size()==1223,"Fixed60s/0pictures/one default public entry/source1223"','fixture.expected_city_source_sha256.size()==1225,"Fixed60s/0pictures/one default public entry/source1225"')
replace('"Natural full1223 source map equals independent B-only successor owner"','"Natural full1225 source map equals independent canonical-B successor owner"')
replace('finish("res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance16_yamen_light05/output/%d_%d"','finish("res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance27_yamen_light06/output/%d_%d"')
for a,b in [('PERF05_PHASE_CLOCK','PERF06_PHASE_CLOCK'),('PERF05_NATURAL_C_RECEIPT_SELECTIVE_READ','PERF06_NATURAL_C_RECEIPT_SELECTIVE_READ'),('PERF05_TERMINAL_FAILURE','PERF06_TERMINAL_FAILURE'),('PERF05_ONE_DEFAULT_ENTRY_RESULT','PERF06_ONE_DEFAULT_ENTRY_RESULT'),('PERF05_TIMEOUT','PERF06_TIMEOUT'),('YAMEN_PERF05_ONE_DEFAULT_PUBLIC_ENTRY_0INPUT_0PICTURE_NO_GEOMETRY_OR_COLLECTOR','YAMEN_PERF06_ONE_DEFAULT_PUBLIC_ENTRY_0INPUT_0PICTURE_NO_GEOMETRY_OR_COLLECTOR')]:replace('"'+a+'"','"'+b+'"')
back=key
for h in reversed(hunks):
    assert back.count(h['new'].encode())==1;back=back.replace(h['new'].encode(),h['old'].encode(),1)
assert back==parent and key.count(b'district.call("loading_timing_state")')==1
kp=O+'test_yamen_performance06_PENDING_ROOT.gd'
diff=''.join(difflib.unified_diff(parent.decode().splitlines(True),key.decode().splitlines(True),fromfile=pp,tofile=kp)).encode()
hand={'status':'PERFORMANCE06_PENDING_TEXT_ONLY_FIXED_PARENT05_NO_FUTURE_SHA_INVENTED','ready':False,'parent_key':{'path':pp,'sha256':ps},
 'key':{'path':kp,'sha256':sha(key)},'fixture':{'path':fp,'sha256':sha(fb)},'whole_parent_key_byte_inverse':True,'hunks':hunks,
 'diff':{'path':O+'complete_vs_b88B.diff','sha256':sha(diff)},'expected_and_guard_maps_empty_until_actual_owner':True,
 'fixed_1223_plus_two_proof_recipe_not_actual_count_credit':True,'unknown_stage_owner_and_deployment_pins_explicit_pending':True,
 'public_null_one_Yamen_ready_draw_before_natural_source_and_once_DT_getter_cadence_unchanged':True,
 'zero_INPUT_picture_geometry_collector_60s_scope_unchanged':True,'no_G_change_or_warm_travel':True,'engine_parse_Stage_collector_public_requests':0}
files={'test_yamen_performance06_PENDING_ROOT.gd':key,'yamen_performance06_fixture_PENDING_ROOT.json':fb,'complete_vs_b88B.diff':diff,'handoff_PENDING_ROOT_NOT_RUN.json':js(hand)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
