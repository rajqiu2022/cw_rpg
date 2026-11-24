"""Prepare only NEW blocked performance04 key/fixture; no engine/parse/run."""
import copy,difflib,hashlib,json
from pathlib import Path
H=Path(__file__).resolve().parent;G=H.parents[1]
S='res://build/luoyang_city_full_rollout_20261022ap_source_finalize01/'
O=S+'performance09_yamen_light04/'
QA='res://build/luoyang_city_full_rollout_20261022ap_qa01/'
sha=lambda b:hashlib.sha256(b).hexdigest();path=lambda p:G/p.removeprefix('res://')
def fixed(p,s):
    b=path(p).read_bytes();assert sha(b)==s,('PIN_CHANGED',p);return b
def js(v):return (json.dumps(v,ensure_ascii=False,indent=2)+'\n').encode()
parent_path='res://tests/test_luoyang_ap_yamen_performance03_LIGHT_ROOT16_READY_20261023.gd'
parent_sha='2eddf30e62fbf38659e2769bbc7a3433cb4484e4fe7bb87a4043133f76262ee1'
parent=fixed(parent_path,parent_sha);code=parent.decode();hs=[]
ownerpath=S+'performance08_actual_independent_review/owner_source_maps_READY.json'
ownerhash='9d004ac904f42807af3bc5dda757430200f7bebbdaa1ef29487911417e282551'
owner=json.loads(fixed(ownerpath,ownerhash));row=next(r for r in owner['scenes'] if r['id']=='ch4_s1_luoyang_yamen')
assert len(row['source_sha256'])==1221 and row['source_sha256']==row['receipt_source_sha256']
fp0=QA+'yamen_performance03_fixture_ROOT16_READY.json';fh0='a488ba0536d9df8da4b1130a0ea0f4a11626d8bcc0ff7c88a6f744ef6a02c036'
fixture=json.loads(fixed(fp0,fh0))
sources=copy.deepcopy(row['source_sha256'])
qa={'res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd':'a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895',parent_path:parent_sha,ownerpath:ownerhash,S+'outputs/root_performance05_source_stage01/receipt.json':'d0583b4ca4b6ef8703d73efb1e5487ea7a62866cb738d756eb262d6e0419a282'}
for mapping in [owner['core_source_sha256'],qa]:
    for p,s in mapping.items():assert p not in sources or sources[p]==s;sources[p]=s
assert fixture['scene_path'] in row['source_sha256'] and fixture['layout_path'] in row['source_sha256']
fixture.update(status='PENDING_ROOT18_DEPLOYMENT_PERFORMANCE04_ONE_DEFAULT_ENTRY_ONLY',ready=False,blockers=['Root18 actual final deployment guard must exist and pass; no invented guard SHA','Root review and NEW mechanical fixture/key freeze before any one-shot execution'],source_sha256=sources,expected_city_source_sha256=copy.deepcopy(row['source_sha256']),authority={'independent_owner':{'path':ownerpath,'sha256':ownerhash},'actual_source_stage':{'path':S+'outputs/root_performance05_source_stage01/receipt.json','sha256':'d0583b4ca4b6ef8703d73efb1e5487ea7a62866cb738d756eb262d6e0419a282'},'actual_Root_deployment_guard':{'path':'res://build/luoyang_city_full_rollout_20261022ap_root01/integration18/final_guard.json','sha256':None,'pending':True}},pending_authority_not_in_source_guard_until_real_freeze=True,district_timing_rule='Call loading_timing_state exactly once after draw timestamp and natural receipt check. Bind same Field/session/_scene/Scene/layout and saved positive token to existing C._resident_ready. Getter has no source freshness credit. No per-frame DT dictionary copy.',no_current_collector_expected_fill=True)
fixturepath=O+'yamen_performance04_fixture_PENDING_ROOT.json';fixturebytes=js(fixture);fixturesha=sha(fixturebytes)
def replace(old,new):
    global code
    assert code.count(old)==1,('UNIQUE_PARENT_HUNK',old[:90]);hs.append({'old':old,'new':new});code=code.replace(old,new,1)
replace('const FIXTURE="'+fp0+'"','const FIXTURE="'+fixturepath+'"')
replace('const FIXTURE_SHA="'+fh0+'"','const FIXTURE_SHA="'+fixturesha+'"')
replace('var max_observe_gap_usec: int=0\n','var max_observe_gap_usec: int=0\nvar district_timing_reads: int=0\nvar district_timing_fact: Dictionary={}\n')
replace('fixture.expected_city_source_sha256.size()==1217,"Fixed60s/0pictures/one default public entry/source1217"','fixture.expected_city_source_sha256.size()==1221,"Fixed60s/0pictures/one default public entry/source1221"')
replace('"Natural full1217 source map equals independent owner1292"','"Natural full1221 source map equals independent owner9D004"')
insert='''func district_timing_once_after_frozen_draw() -> bool:
	if not check(not draw_fact.is_empty() and district_timing_reads==0,"District timing only once after frozen firstdraw"): return false
	var field: Node=current_scene
	var current: SceneScript=field.get("_current_scene") as SceneScript
	var district: RefCounted=field.get("_district_session") as RefCounted
	if not check(is_instance_valid(field) and current!=null and current.scene_id==ID and current.map_layout!=null and district!=null and district.has_method("loading_timing_state"),"Existing same Field district scalar getter"): return false
	var layout: Resource=current.map_layout
	var proof: Dictionary=C._resident_ready
	if not check(field.get_instance_id()==draw_fact.Field and current.get_instance_id()==draw_fact.Scene and district.get("_scene")==current and proof.get("scene")==current and proof.get("id")==ID and proof.get("sources_finalized")==true and int(proof.get("token",0))>0,"Existing natural district owner Scene/layout/token before read"): return false
	district_timing_reads+=1
	var metrics: Variant=district.call("loading_timing_state")
	if not check(metrics is Dictionary,"District timing dictionary available; missing not zero"): return false
	var same_owner: bool=field==current_scene and field.get("_district_session")==district and field.get("_current_scene")==current and district.get("_scene")==current and current.map_layout==layout and metrics.get("setup_identity_current")==true and metrics.get("scene_id")==String(ID) and metrics.get("scene_instance")==current.get_instance_id() and metrics.get("layout_instance")==layout.get_instance_id() and int(metrics.get("transition_token",0))==int(proof.token) and int(metrics.get("transition_token",0))>0
	district_timing_fact={"captured_after_frozen_draw":clock_fact(),"Field":field.get_instance_id(),"Scene":current.get_instance_id(),"layout":layout.get_instance_id(),"district":district.get_instance_id(),"resident_positive_token":proof.token,"getter_read_count":district_timing_reads,"same_owner":same_owner,"metrics":metrics,"not_fresh_source_evidence":true,"missing_not_zero":true}
	return check(same_owner and metrics.get("profile_origin")=="DISTRICT_SETUP_NOT_WARM_RESUME" and metrics.get("fresh_source_validation_credit")==false,"Saved DT setup token matches natural resident proof; never new freshness credit")

'''
replace('func exercise_cpu() -> bool:\n',insert+'func exercise_cpu() -> bool:\n')
replace('\t\t\tvar owner_ok: bool=natural_receipt_only()\n','\t\t\tvar owner_ok: bool=natural_receipt_only()\n\t\t\tvar timing_ok: bool=district_timing_once_after_frozen_draw() if owner_ok else false\n')
replace('"Field_profile":last_Field_profile,"LM":last_LM,"max_observe_gap_usec":max_observe_gap_usec,"missing_reset_metrics_not_zero_or_fresh":true','"Field_profile":last_Field_profile,"LM":last_LM,"DT_timings_after_frozen_draw":district_timing_fact,"DT_timing_getter_reads":district_timing_reads,"max_observe_gap_usec":max_observe_gap_usec,"missing_reset_metrics_not_zero_or_fresh":true')
replace('\t\t\treturn owner_ok\n','\t\t\treturn owner_ok and timing_ok\n')
replace('finish("res://build/luoyang_city_full_rollout_20261022ap_qa01/yamen_performance03_LIGHT_ROOT16_READY/%d_%d"','finish("'+O+'output/%d_%d"')
# Record names distinguish new observations from the retained original report.
for label in ['PHASE_CLOCK','NATURAL_C_RECEIPT_SELECTIVE_READ','TERMINAL_FAILURE','ONE_DEFAULT_ENTRY_RESULT','TIMEOUT']:
    replace('"PERF03_'+label+'"','"PERF04_'+label+'"')
replace('"YAMEN_PERF03_ONE_DEFAULT_PUBLIC_ENTRY_0INPUT_0PICTURE_NO_GEOMETRY_OR_COLLECTOR"','"YAMEN_PERF04_ONE_DEFAULT_PUBLIC_ENTRY_0INPUT_0PICTURE_NO_GEOMETRY_OR_COLLECTOR"')
inverse=code
for h in reversed(hs):assert inverse.count(h['new'])==1;inverse=inverse.replace(h['new'],h['old'],1)
assert inverse.encode()==parent
assert code.count('district.call("loading_timing_state")')==1
observe=code[code.index('func observe_readonly()'):code.index('func post_draw_readonly()')]
assert 'loading_timing_state' not in observe and code.count('await process_frame')==parent.decode().count('await process_frame')
scriptpath=O+'test_yamen_performance04_PENDING_ROOT.gd';scriptbytes=code.encode()
diff=''.join(difflib.unified_diff(parent.decode().splitlines(True),code.splitlines(True),fromfile=parent_path,tofile=scriptpath)).encode()
proof={'status':'BLOCKED_PERFORMANCE04_SOURCE_TEXT_PREPARATION_ONLY_NOT_PARSED_OR_RUN','ready':False,'parent_script':{'path':parent_path,'sha256':parent_sha},'script':{'path':scriptpath,'sha256':sha(scriptbytes)},'fixture':{'path':fixturepath,'sha256':fixturesha,'expected_city_sources':1221,'source_guard_before_real_deployment_pin':len(sources)},'whole_parent_script_byte_inverse':True,'hunks':hs,'no_new_yield_worker_poll_or_source_validation':True,'district_timing_getter_only_after_frozen_draw_once':True,'blocked_on_real_Root18_deployment_guard':True,'actual_deployment_guard_sha256':None,'stage_engine_parse_collector_or_public_requests_executed':0,'freeze_only_changes':['Fixture ready/status/blockers','Exact real Root18 guard identity/source_guard leaf and pending marker','NEW ready fixture path/SHA literal in NEW final script'], 'no_automatic_replay_or_all_city_loading_credit':True}
out={fixturepath:fixturebytes,scriptpath:scriptbytes,O+'complete_vs_2EDD.diff':diff,O+'handoff_PENDING_ROOT_NOT_RUN.json':js(proof)}
assert not path(O).exists()
for p,b in out.items():
    path(p).parent.mkdir(parents=True,exist_ok=True)
    with path(p).open('xb') as f:f.write(b)
print(json.dumps({'script':proof['script'],'fixture':proof['fixture'],'handoff':{'path':O+'handoff_PENDING_ROOT_NOT_RUN.json','sha256':sha(out[O+'handoff_PENDING_ROOT_NOT_RUN.json'])},'ready':False,'engine':False}))
