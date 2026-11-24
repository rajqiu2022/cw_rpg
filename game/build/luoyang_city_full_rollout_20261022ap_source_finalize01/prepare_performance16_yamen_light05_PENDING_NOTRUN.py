"""Prepare blocked performance05 text only; no expected map before actual stage."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
P=S+'performance10_yamen_light04_ROOT18/';O=S+'performance16_yamen_light05/'
def p(v):return G/v.removeprefix('res://')
def sha(b):return hashlib.sha256(b).hexdigest()
def fixed(path,s):
    b=p(path).read_bytes();assert sha(b)==s,('PIN_CHANGED',path);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
parentpath=P+'test_yamen_performance04_ROOT18_READY.gd';parentsha='51fdd9470cd4d20fde9325fa819516d9412210cde99bc7798033dd02faccc63c'
parent=fixed(parentpath,parentsha)
oldfixture=P+'yamen_performance04_fixture_ROOT18_READY.json';oldfixturesha='1e8926959c79c2819253da70befac4d64ad619770eab838a1f2b1b88e01d97c5'
fixture=json.loads(fixed(oldfixture,oldfixturesha))
fixture.update(status='PENDING_REAL_B_ONLY_STAGE_OWNER_AND_ROOT21_DEPLOYMENT_PERFORMANCE05_NOT_RUN',ready=False,
 source_sha256={},expected_city_source_sha256={},
 blockers=['Root unique exact22 actual source receipt and independently derived owner must exist; no invented candidate/header SHA','Root21 exact22 deployment copy and final_guard must pass and be pinned; then NEW mechanical fixture/key freeze'],
 authority={'fixed_prior_owner':{'path':S+'performance08_actual_independent_review/owner_source_maps_READY.json','sha256':'9d004ac904f42807af3bc5dda757430200f7bebbdaa1ef29487911417e282551'},
 'independent_owner':{'path':S+'performance15_B_only_actual_independent_review/owner_source_maps_READY.json','sha256':None,'pending':True},
 'actual_source_stage':{'path':S+'outputs/root_B_only_symmetric_wire_stage01/receipt.json','sha256':None,'pending':True},
 'actual_Root_deployment_guard':{'path':'res://build/luoyang_city_full_rollout_20261022ap_root01/integration21/final_guard.json','sha256':None,'pending':True},
 'actual_Root_deployment_copy':{'path':None,'sha256':None,'pending':True}},
 pending_authority_not_in_source_guard_until_real_freeze=True,
 expected_source_count_recipe={'fixed9D004':1221,'two_new_B_proof_leaves':2,'derived_pending_count':1223,'not_actual_collector_observation':True},
 no_pre_stage_expected_map_or_current_source_fill=True)
fp=O+'yamen_performance05_fixture_PENDING_ROOT.json';fb=js(fixture);code=parent;hunks=[]
def replace(a,b):
    global code
    aa,bb=a.encode(),b.encode();assert code.count(aa)==1,(a,code.count(aa));hunks.append({'old':a,'new':b});code=code.replace(aa,bb,1)
replace('const FIXTURE="'+oldfixture+'"','const FIXTURE="'+fp+'"')
replace('const FIXTURE_SHA="'+oldfixturesha+'"','const FIXTURE_SHA="'+sha(fb)+'"')
replace('fixture.expected_city_source_sha256.size()==1221,"Fixed60s/0pictures/one default public entry/source1221"','fixture.expected_city_source_sha256.size()==1223,"Fixed60s/0pictures/one default public entry/source1223"')
replace('"Natural full1221 source map equals independent owner9D004"','"Natural full1223 source map equals independent B-only successor owner"')
replace('finish("res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance09_yamen_light04/output/%d_%d"','finish("res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/performance16_yamen_light05/output/%d_%d"')
for a,b in [('PERF04_PHASE_CLOCK','PERF05_PHASE_CLOCK'),('PERF04_NATURAL_C_RECEIPT_SELECTIVE_READ','PERF05_NATURAL_C_RECEIPT_SELECTIVE_READ'),('PERF04_TERMINAL_FAILURE','PERF05_TERMINAL_FAILURE'),('PERF04_ONE_DEFAULT_ENTRY_RESULT','PERF05_ONE_DEFAULT_ENTRY_RESULT'),('PERF04_TIMEOUT','PERF05_TIMEOUT'),('YAMEN_PERF04_ONE_DEFAULT_PUBLIC_ENTRY_0INPUT_0PICTURE_NO_GEOMETRY_OR_COLLECTOR','YAMEN_PERF05_ONE_DEFAULT_PUBLIC_ENTRY_0INPUT_0PICTURE_NO_GEOMETRY_OR_COLLECTOR')]:replace('"'+a+'"','"'+b+'"')
inverse=code
for h in reversed(hunks):
    a,b=h['old'].encode(),h['new'].encode();assert inverse.count(b)==1;inverse=inverse.replace(b,a,1)
assert inverse==parent and code.count(b'district.call("loading_timing_state")')==1
keypath=O+'test_yamen_performance05_PENDING_ROOT.gd'
diff=''.join(difflib.unified_diff(parent.decode().splitlines(True),code.decode().splitlines(True),fromfile=parentpath,tofile=keypath)).encode()
hand={'status':'BLOCKED_PERFORMANCE05_TEXT_ONLY_NO_STAGE_OWNER_OR_DEPLOYMENT_SHA_INVENTED','ready':False,
 'parent_key':{'path':parentpath,'sha256':parentsha},'key':{'path':keypath,'sha256':sha(code)},'fixture':{'path':fp,'sha256':sha(fb)},
 'whole_parent_key_byte_inverse':True,'hunks':hunks,'diff':{'path':O+'complete_vs_51FDD947.diff','sha256':sha(diff)},
 'source_expectations_empty_and_explicitly_blocked_until_real_owner':True,'natural_public_null_Yamen_ready_and_draw_clocks_and_once_DT_query_unchanged':True,
 '60s_zeroINPUT_picture_geometry_collector_unchanged':True,'future_freeze_changes_only':'Ready/status/blockers/real owner-derived expected+guard maps/real Stage andRoot21 deployment authorities, then NEW key fixturepath/SHA literals.',
 'owner_script_prepared_not_executed':S+'prepare_performance15_B_only_actual_owner_NOTRUN.py','stage_engine_parse_collector_public_requests':0}
files={'test_yamen_performance05_PENDING_ROOT.gd':code,'yamen_performance05_fixture_PENDING_ROOT.json':fb,'complete_vs_51FDD947.diff':diff,'handoff_PENDING_ROOT_NOT_RUN.json':js(hand)}
assert not p(O).exists();p(O).mkdir()
for name,b in files.items():(p(O)/name).write_bytes(b)
print(json.dumps({name:sha(b)for name,b in files.items()},indent=2))
