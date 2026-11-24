extends "res://tests/helpers/luoyang_enclosure_v11_native_npc_band_probe_20261009.gd"
## Read-only appendix around the ORIGINAL complete collision trial.
## No input/position/refresh/planner/assertion override; original failures survive.
var diagnostic_directory: String=""
var collision_receipts: Array[Dictionary]=[]

func set_diagnostic_directory(directory: String) -> bool:
	if not directory.begins_with("res://build/joint_world_luoyang_20261003_qa/yamen_original_stop_diagnostic_") or not directory.ends_with("/") or not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(directory)): return false
	diagnostic_directory=directory
	return true

func _foot_snapshot(id: String,label: String) -> Dictionary:
	var player: CharacterBody2D=field.get("_player") as CharacterBody2D
	var definition: SceneScript=field.get("_current_scene") as SceneScript
	var foot: float=float(player.call("get_depth_sort_y"))
	var native: PackedByteArray=PackedFloat32Array([foot]).to_byte_array()
	var shape: CollisionShape2D=player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var helper: RefCounted=field.get("_v14_modular_overlap") as RefCounted
	return {"label":label,"ticks_usec":Time.get_ticks_usec(),"physics_frame":Engine.get_physics_frames(),"process_frame":Engine.get_process_frames(),"scene_id":String(definition.scene_id),"field_instance_id":field.get_instance_id(),"player_instance_id":player.get_instance_id(),"player_position":_scalar_evidence(player.position),"player_position_native_hex":PackedVector2Array([player.position]).to_byte_array().hex_encode(),"raw_foot":foot,"raw_foot_float64_hex":PackedFloat64Array([foot]).to_byte_array().hex_encode(),"packed_float32_foot":native.decode_float(0),"packed_float32_hex":native.hex_encode(),"velocity":_scalar_evidence(player.velocity),"safe_margin":player.safe_margin,"shape_size":_scalar_evidence((shape.shape as RectangleShape2D).size),"shape_transform":_scalar_evidence(shape.global_transform),"own_source_overlap_at_actual_position":_own_body_overlap(id,player.position),"actual_Physics_hits_at_actual_position":_physical_hits(player.position),"native_depth_states":helper.call("get_depth_order_state"),"observation_never_refreshes_or_changes_input":true}

func _stop_appendix(id: String,original: Dictionary) -> Dictionary:
	var stop: Dictionary=original.get("stop",{})
	if stop.get("not_run",false)==true or not stop.has("samples"): return {"available":false,"original_stop":stop}
	var samples: Array=stop.samples
	var packed:=PackedVector2Array()
	var raw_calls: Array[Dictionary]=[]
	for value: Variant in samples:
		var p: Vector2=point(value)
		packed.append(p)
		raw_calls.append({"position":_scalar_evidence(p),"raw875_and17":raw_evidence(p),"retroactive_Physics_pass_claimed":false})
	var direction: Vector2=point(stop.direction)
	var reconstructed: Vector2=point(stop.next_requested_body_center)-direction*float(stop.next_step_px)
	var final_after: Vector2=point(stop.end)
	var last_sample: Vector2=packed[packed.size()-1]
	var stationary: bool=packed.size()==31
	for index in range(maxi(0,packed.size()-5),packed.size()): stationary=stationary and packed[index].distance_to(reconstructed)<.01
	var components: Dictionary={"all_clear_original":stop.all_clear,"advance_dot_gt_one":(reconstructed-point(stop.start)).dot(direction)>1,"stationary_last_five_recomputed":stationary,"next_own_source_and_actual_Physics_original":stop.next_source_own_body_overlap and stop.next_hits_own,"additional_real_input_displacement_lt_point01":float(stop.additional_normal_input_displacement_px)<.01,"final_after_not_inside_own_source_polygon":not _own_body_overlap(id,final_after)}
	# The parent did not store its first final separately. Preserve the original
	# stationary verdict and explicitly expose any native subtraction ambiguity;
	# this reconstruction is an appendix, not a replacement stop-time observation.
	var all_six: bool=true
	for value: Variant in components.values(): all_six=all_six and value==true
	var segments: Array[Dictionary]=[]
	for index in range(1,packed.size()):
		var a: Vector2=packed[index-1]; var b: Vector2=packed[index]
		var count: int=maxi(1,ceili(a.distance_to(b)/4))
		var clear_raw: bool=true
		var bad: Dictionary={}
		for sample in range(count+1):
			var p: Vector2=a.lerp(b,float(sample)/count)
			var evidence: Dictionary=raw_evidence(p)
			if evidence.get("clear")!=true:
				clear_raw=false; bad={"index":sample,"position":_scalar_evidence(p),"raw":evidence}; break
		segments.append({"raw_clear":clear_raw,"centers":count+1,"first_bad":bad,"retroactive_Physics_pass_claimed":false})
	var source_geometry: Dictionary={"walk_path":manifest.walk_path,"walk_file_sha256":FileAccess.get_sha256(String(manifest.walk_path)),"walk_size":[walk.get_width(),walk.get_height()],"walk_format":walk.get_format(),"original_stationary_last_five":stop.stationary_last_five,"first_final_reconstruction_is_not_new_live_observation":true,"own_source_id":id,"source_polygon_native_hex":var_to_bytes(solids[id]).hex_encode()}
	return {"available":true,"six_original_condition_appendix":components,"all_six_recomputed":all_six,"independent_source_geometry":source_geometry,"original_stop_preserved":true,"original_record_var_bytes_hex":var_to_bytes(stop).hex_encode(),"samples_native_hex":packed.to_byte_array().hex_encode(),"source_polygons":_scalar_evidence(solids[id]),"source_polygons_native_hex":var_to_bytes(solids[id]).hex_encode(),"first_final_reconstructed_from_original_next_and_step":_scalar_evidence(reconstructed),"reconstructed_final_native_hex":PackedVector2Array([reconstructed]).to_byte_array().hex_encode(),"last_original_sample":_scalar_evidence(last_sample),"last_sample_matches_reconstructed_final_native":PackedVector2Array([last_sample]).to_byte_array()==PackedVector2Array([reconstructed]).to_byte_array(),"final_after_raw875_and17":raw_evidence(final_after),"final_after_actual_Physics_query_after_complete_trial":_physical_hits(final_after),"original_sample_raw_rechecks":raw_calls,"original_segment_raw_rechecks":segments,"original_all_clear_includes_prior_live_Physics_not_retroactively_recreated":true,"appendix_does_not_replace_original_assertion":true}

func _collision_trial(id: String) -> Dictionary:
	var before: Dictionary=_foot_snapshot(id,"BEFORE_ORIGINAL_COMPLETE_TRIAL")
	var original: Dictionary=await super._collision_trial(id)
	# super has already completed original stop, extra input, bypass and capture.
	# This immediate receipt is persisted BEFORE the subsequent alpha trial.
	var row: Dictionary={"scope":"YAMEN_ORIGINAL_COMPLETE_COLLISION_TRIAL_READONLY_APPENDIX_NOT_FULL_APPROVAL","id":id,"original_collision":original.duplicate(true),"original_collision_var_bytes_hex":var_to_bytes(original).hex_encode(),"before":before,"after_complete_trial":_foot_snapshot(id,"AFTER_STOP_AND_ORIGINAL_BYPASS_NOT_STOP_TIME"),"appendix":_stop_appendix(id,original),"original_parent_assertions_retained":true,"original_failure_changed_to_pass":false}
	var path: String=diagnostic_directory+"collision_"+id+".json"
	var wrote: bool=not diagnostic_directory.is_empty() and not FileAccess.file_exists(path)
	if wrote:
		var file:=FileAccess.open(path,FileAccess.WRITE)
		wrote=file!=null
		if file!=null:
			var encoded: String=JSON.stringify(row,"\t",true)
			file.store_string(encoded); file.flush(); wrote=file.get_error()==OK; file.close()
			var parser:=JSON.new()
			wrote=wrote and parser.parse(FileAccess.get_file_as_string(path))==OK and parser.data==JSON.parse_string(encoded)
	_check(wrote,"immediate original collision receipt persisted: "+id)
	collision_receipts.append({"id":id,"path":path,"sha256":FileAccess.get_sha256(path) if wrote else "NOT_WRITTEN","appendix_all_six":row.appendix.get("all_six_recomputed"),"original_parent_assertions_retained":true})
	print("YAMEN_ORIGINAL_COLLISION_RECEIPT "+id+" "+path)
	return original
