"""NEW Source-reviewed scalar clock trace; no production/actual execution."""
import copy,hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2];QA=Path(__file__).resolve().parent
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def key(p):return 'res://'+p.relative_to(ROOT).as_posix()
os=ROOT/'tests/test_luoyang_ap_yamen_EXPRESSION_TRACE_CANDIDATE_NOTREADY_20261023.gd'
op=QA/'yamen_expression_trace_fixture_CANDIDATE_NOTREADY.json'
assert sha(os)=='eba1e72c9220e5b1208caaacd799d8c1dd6543024258fae17f86219832c57c48'
assert sha(op)=='3ce75ffcb64010967fc94011036843610b50c3f69455a0d6d6f6f3b3b4ab0f27'
sp=ROOT/'tests/test_luoyang_ap_yamen_EXPRESSION_STAGE_TRACE_CANDIDATE_NOTREADY_20261023.gd'
fp=QA/'yamen_expression_stage_trace_fixture_CANDIDATE_NOTREADY.json'
hp=QA/'yamen_expression_stage_trace_handoff_CANDIDATE_NOTREADY.json'
assert not any(p.exists() for p in [sp,fp,hp])
fixture=json.loads(op.read_bytes())
fixture['read_only_trace_scope']={'cadence':'Only original _observe calls, after super; no added yield or sampler worker','events':'publicphase/Fieldstage/Csourceworker/Csources_finalized/sameowner-token-scene changes','profile_read':'One additional cheap C.transition_validation_state scalar-map copy at the same cadence; no validator/collector/worker output access','max_wall_gap':'Monotonic interval between original observations, not attributed CPU work','max_events':96,'source_note':'Cresolve total nests source and packet; empty module timings unavailable; unassigned11.574877s is not proven all-main-thread.'}
abi=QA/'yamen_pure_transform_abi01/result_113876_85940.json'
assert sha(abi)=='30ead6851fdbf09c24bbcc8111e5a6d84cf5a6b3fa2d618a65ce48889b1b033c'
abij=json.loads(abi.read_bytes())
assert abij['complete'] is True and abij['no_autoload'] is True and abij['elapsed_usec']==71
assert abij['Resource_loads']==abij['Field_Scene_native_geometry_image_or_collector']==0
for row in abij['rows']:assert row['field_scale_f32_bytes']=='8fc2f53d8fc2f53d'
fixture['constant_ABI_evidence_not_live_expected_fill']={'path':key(abi),'sha256':sha(abi),'producer_actual_Sprite_values_used':False,'Root_captured_OS_exit_code':0}
fixture['source_sha256'][key(abi)]=sha(abi)
fp.write_text(json.dumps(fixture,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
raw=os.read_text(encoding='utf-8');body=raw;changes=[]
def replace(a,b):
    global body
    assert body.count(a)==1;body=body.replace(a,b);changes.append({'old':a,'new':b})
replace(key(op),key(fp));replace(sha(op),sha(fp))
replace('yamen_three_low_props_expression_trace_candidate/%d_%d','yamen_three_low_props_expression_stage_trace_candidate/%d_%d')
replace('var stage_trace_events: int = 0\n','var stage_trace_events: int = 0\nvar prior_observe_usec: int = 0\nvar max_observe_wall_gap_usec: int = 0\n')
start=body.index('func _observe_readonly() -> void:\n');end=body.index('\nfunc _point(',start)
old=body[start:end]
new='''func _observe_readonly() -> void:
	super._observe_readonly()
	if requested_usec <= 0: return
	var now_usec: int = Time.get_ticks_usec()
	var gap_usec: int = now_usec - prior_observe_usec if prior_observe_usec > 0 else 0
	prior_observe_usec = now_usec
	max_observe_wall_gap_usec = maxi(max_observe_wall_gap_usec,gap_usec)
	if stage_trace_events >= 96: return
	var router: Node = root.get_node("SceneRouter")
	var public_state: Dictionary = router.call("get_public_city_preparation_state")
	if public_state.get("scene_id") != String(YAMEN): return
	var profile: Dictionary = C.transition_validation_state()
	var live_owner: int = int(router.call("live_field_transition_token",YAMEN))
	var same_owner: bool = live_owner > 0 and profile.get("active") == true and profile.get("live_scope") == true and profile.get("scene_id") == String(YAMEN) and profile.get("token") == live_owner
	var field_state: Dictionary = {}
	var field_instance: int = 0
	if is_instance_valid(current_scene) and current_scene.has_method("get_field_loading_state"):
		field_state = current_scene.call("get_field_loading_state")
		field_instance = current_scene.get_instance_id()
	var scalar_profile: Dictionary = {"same_current_owner":same_owner,"live_owner":live_owner,"active":profile.get("active"),"live_scope":profile.get("live_scope"),"scene_id":profile.get("scene_id"),"token":profile.get("token"),"source_worker_active":profile.get("source_worker_active"),"sources_finalized":profile.get("sources_finalized")}
	var signature: String = JSON.stringify([public_state.get("request_generation"),public_state.get("token"),public_state.get("phase"),field_instance,field_state.get("scene_id"),field_state.get("stage"),field_state.get("complete"),field_state.get("failed"),scalar_profile])
	if signature == trace_signature: return
	trace_signature = signature; stage_trace_events += 1
	var clock: Dictionary = _clock_fact()
	clock["elapsed_usec"] = int(clock.usec) - requested_usec
	records.append({"kind":"READONLY_STAGE_CHANGE_CLOCK","clock":clock,"public":public_state.duplicate(true),"Field_instance":field_instance,"Field_loading_state":field_state.duplicate(true),"C_current_scalars":scalar_profile,"previous_observe_wall_gap_usec":gap_usec,"max_observe_wall_gap_usec":max_observe_wall_gap_usec,"no_extra_yield_or_worker":true})
'''
replace(old,new)
replace('"native_mask_observations_actual":actual_mask_samples,','"native_mask_observations_actual":actual_mask_samples,"stage_trace_events":stage_trace_events,"max_original_observe_wall_gap_usec":max_observe_wall_gap_usec,')
back=body
for row in reversed(changes):assert back.count(row['new'])==1;back=back.replace(row['new'],row['old'])
assert back==raw
sp.write_text(body,encoding='utf-8',newline='\n')
h={'status':'QA_SOURCE_EXPRESSION_SOURCE_REVIEWED_CLOCK_CANDIDATE_NOTREADY','script':{'path':key(sp),'sha256':sha(sp),'lines':len(body.splitlines())},'fixture':{'path':key(fp),'sha256':sha(fp)},'constant_ABI_result':{'path':key(abi),'sha256':sha(abi)},'whole_byte_inverse_toEBA1':True,'exact_replacements':changes,'same_three_transform_native_expression_oracle36FD':True,'same1211_production_source_map':fixture['expected_city_source_sha256']==json.loads(op.read_bytes())['expected_city_source_sha256'],'same_old_geometry_polygons_NPC_paths_60s_2pictures':True,'additional_profile_call_only_public_readonly_copy_same_observe_cadence':True,'awaiting_Root_final_freeze':True,'engine_or_parse_runs':0,'canonical_writes':0}
hp.write_text(json.dumps(h,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'script':h['script'],'fixture':h['fixture'],'handoff_sha256':sha(hp)}))
