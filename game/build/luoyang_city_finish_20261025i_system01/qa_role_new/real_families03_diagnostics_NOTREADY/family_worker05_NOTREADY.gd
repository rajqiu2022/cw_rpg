extends "res://build/luoyang_city_finish_20261025i_system01/qa_role_new/real_fields04_ROOT_READY/worker_ROOT_READY.gd"
## System-authored finite Field selftest, not independent geometry QA.
## No original matches/collector/finalize call; reads natural original receipts only.

func arrive(id: StringName,start_us: int,label: String,limit: int) -> bool:
	var until: int = mini(deadline,Time.get_ticks_msec()+limit)
	while Time.get_ticks_msec() < until:
		var public: Dictionary = router().call("get_public_city_preparation_state")
		if public.get("scene_id") == String(id) and public.get("phase") == "FAILED": return check(false,"PUBLIC_REJECT_NO_RETRY",{"public":public,"original_C":passive_original_C_diagnostic()})
		var current: Node = tree.current_scene
		if is_instance_valid(current) and current.has_method("get_field_loading_state"):
			var loading: Dictionary = current.call("get_field_loading_state")
			var s: SceneScript = current.get("_current_scene") as SceneScript
			if s != null and s.scene_id == id:
				if loading.get("failed") == true: return check(false,"FIELD_REJECT_NO_RETRY",{"loading":loading,"public":public,"original_C":passive_original_C_diagnostic()})
				var p: CharacterBody2D = current.get("_player") as CharacterBody2D
				if loading.get("complete") == true and p != null and p.can_process() and p.can_move and hidden():
					await RenderingServer.frame_post_draw
					# Freeze timing BEFORE any verification, hashing, actor sample or screenshot.
					var draw_us: int = Time.get_ticks_usec()
					if not check(tree.current_scene == current and current.get("_current_scene") == s and current.get("_player") == p and p.can_move and hidden() and Time.get_ticks_msec() < until,"REAL_SAME_HIDDEN_OPERABLE_POST_DRAW"): return false
					field = current;scene = s
					records.append({"kind":"NATURAL_HIDDEN_OPERABLE_TIMING_FROZEN_BEFORE_ASSERTIONS","label":label,"scene_id":String(id),"request_us":str(start_us),"draw_us":str(draw_us),"elapsed_us":draw_us-start_us,"Field":str(field.get_instance_id()),"Player":str(p.get_instance_id()),"foot":p.position,"entry_kind":label,"world96_or_default_perf_credit":false})
					# Passive existing getter AFTER draw_us is frozen; no new profile workload.
					records.append({"kind":"PASSIVE_EXISTING_FIELD_LOADING_PROFILE_AFTER_DRAW_TIMESTAMP","scene_id":String(id),"draw_us":str(draw_us),"profile":field.call("get_field_loading_profile")})
					records.append({"kind":"PASSIVE_PUBLIC_AND_C_PREPARATION_STATE_AFTER_FROZEN_DRAW","scene_id":String(id),"draw_us":str(draw_us),"request_us":str(start_us),"public_state":router().call("get_public_city_preparation_state"),"original_C":passive_original_C_diagnostic(),"timing_credit":"draw_us frozen before all getters; getter elapsed is not loading","token_origin":"C latest cached preparation state; natural() separately proves actual Field original owner token, not assumed identical"})
					return natural(scene_row(String(id)))
		await tree.process_frame
	return check(false,"FIXED_LEG_TIMEOUT_NO_EXTENSION:"+label,{"public":router().call("get_public_city_preparation_state"),"original_C":passive_original_C_diagnostic()})

func passive_original_C_diagnostic() -> Dictionary:
	# Same cached class already loaded by SceneRouter; only existing scalar/read-only getters.
	var c: Variant = load(spec.original_C.path)
	return {"errors":c.errors(),"transition_state":c.transition_validation_state(),"source_path":String(spec.original_C.path),"token_origin":"latest canonical C cached preparation, not a substituted Field receipt","business_or_source_hash_calls":0}

func portal_leg(leg: Dictionary,label: String) -> bool:
	if not check(scene.scene_id == StringName(leg.source_scene) and leg.get("source_foot_px") is Array and leg.get("expected_target_uv") is Array,"FROZEN_TRUE_SOURCE_FAMILY_PORTAL_LEG"): return false
	var foot: Vector2 = v(leg.source_foot_px)
	if not await inspection(foot,label+":SOURCE_FOOT"): return false
	# Two fixed complete physics->process stages, never wait-until-pass/retry.
	var stage_start: int = Engine.get_physics_frames()
	for _stage: int in range(2):
		await tree.physics_frame
		await tree.process_frame
	if not check(budget() and tree.current_scene == field and player() != null and player().position == foot and clear(foot),"SOURCE_FOOT_WHOLE34X24_PHYSICS_STABLE_WITHOUT_RETRY"): return false
	var matches: Array = []
	for node: Node in field.get("_exit_nodes"):
		if node is Area2D and node.get("target_scene_id") == leg.target_scene and node.position == foot: matches.append(node)
	if not check(matches.size() == 1,"UNIQUE_FROZEN_SOURCE_TARGET_EXIT"): return false
	var zone: Area2D = matches[0]
	var has_public: bool = zone.has_method("can_enter")
	var public_ready: Variant = zone.call("can_enter") if has_public else null
	var original_ready: Variant = zone.get("_in_range")
	records.append({"kind":"ACTUAL_SOURCE_PORTAL_PUBLIC_OR_ORIGINAL_ACTIVATION_GATE","label":label,"source_portal_id":leg.source_portal_id,
		"zone_script":zone.get_script().resource_path,"is_locked":zone.get("is_locked"),"auto_trigger":zone.get("auto_trigger"),
		"target_scene_id":zone.get("target_scene_id"),"target_uv":zone.get("target_spawn_pos"),"expected_target_uv":v(leg.expected_target_uv),
		"has_public_can_enter":has_public,"public_can_enter":public_ready,"original_ExitZone_in_range":original_ready,
		"cache_overlap_DIAGNOSTIC_ONLY":zone.overlaps_body(player()),"monitoring":zone.monitoring,
		"fixed_complete_physics_stages":2,"actual_physics_frame_delta":Engine.get_physics_frames()-stage_start,
		"player_foot":player().position,"zone_foot":zone.position,"wholebody_fullmask_or_sourcepoly_and_Physics_precondition":true,
		"no_private_activate_or_try_interact_call":true,"no_wait_until_pass_retry_or_alternate_pose":true,
		"A07_old_compound_whole_FAIL_retained_not_relabelled":true})
	if not check(zone.get("is_locked") == false and zone.get("auto_trigger") == false and zone.get("target_spawn_pos") == v(leg.expected_target_uv) and zone.monitoring and (public_ready == true if has_public else original_ready == true),"SOURCE_EXACT_TARGET_AND_REAL_PRODUCTION_ACTIVATION_PRECONDITION"): return false
	var request_us: int = Time.get_ticks_usec()
	await driver.key(KEY_SPACE);space_calls += 1
	if not await arrive(StringName(leg.target_scene),request_us,label,int(spec.entry_ms)): return false
	return check(player().position == v(leg.expected_arrival_foot_px),"SOURCE_EXPECTED_FAMILY_ARRIVAL_NOT_OBSERVED_BACKFILL")

func fixed_sources(row: Dictionary) -> bool:
	var artifact: Variant = row.get("expected_sources_artifact")
	if not check(artifact is Dictionary and artifact.get("path") is String and artifact.get("sha256") is String and spec.dependencies.get(artifact.path) == artifact.sha256 and FileAccess.get_sha256(artifact.path) == artifact.sha256,"FIXED_FAMILY_EXPECTATION_ARTIFACT:"+row.scene_id): return false
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(artifact.path))
	var selected: Variant = raw
	for key: String in artifact.get("selector",[]): selected = selected.get(key) if selected is Dictionary else null
	if not check(selected is Dictionary and not selected.is_empty() and selected.size() == int(row.expected_source_count),"FIXED_FAMILY_FULL_SOURCE_MAP:"+row.scene_id): return false
	row.expected_sources = selected
	return true

func natural(row: Dictionary) -> bool:
	if row.owner_kind == "C": return super.natural(row)
	var original: Dictionary = {}
	var token: int = 0
	var key: String = ""
	if row.owner_kind == "TEMPLE":
		var temple: RefCounted = field.get("_temple_session")
		if not check(temple != null and temple.get_script().resource_path == row.original_owner.path,"REAL_TEMPLE_FIELD_PREPARED_SESSION"): return false
		original = temple.call("state")
		token = temple.get_instance_id()
		key = "TEMPLE_ORIGINAL_INSTANCE:"+str(token)+":"+str(scene.get_instance_id())+":"+str(scene.map_layout.get_instance_id())
		if not check(original.get("released") == false and original.get("scene_instance") == scene.get_instance_id() and String(original.get("error","")) == "","TEMPLE_ORIGINAL_SAME_SCENE_NOT_FAKE_ROUTER_FIRST"): return false
	else:
		var family: Variant = load(row.original_owner.path)
		if not check(family is GDScript and family.resource_path == row.original_owner.path,"ORIGINAL_PER_SCENE_RECEIPT_GETTER_ONLY"): return false
		original = family.original_receipt_for(scene)
		token = int(original.get("serial",0));key = String(original.get("key",""))
		if not check(int(original.get("full_source_hash_passes",0)) == 2,"ORIGINAL_FAMILY_TWO_NATURAL_SOURCE_PASSES"): return false
	if not check(original.get("finalized") == true and token > 0 and key != "" and original.get("source_first") == row.expected_sources and original.get("source_final") == row.expected_sources,"NATURAL_ORIGINAL_FAMILY_FIRST_FINAL:"+row.scene_id): return false
	var lease: RefCounted = field.get("_finish25i")
	var state: Dictionary = field.call("get_finish25i_state")
	var mask: Image = field.get("_walkable_mask_image") as Image
	if not check(lease != null and lease.get_script().resource_path == spec.finish_runtime.path and state.get("finalized") == true and state.get("binding_sha") == spec.finish_binding.sha256 and state.get("scene_instance") == scene.get_instance_id() and state.get("token") == token and state.get("owner_key") == key,"NEW_FAMILY_LEASE_SAME_ORIGINAL_OBJECT_KEY_TOKEN"): return false
	if row.owner_kind == "TEMPLE":
		if not check(mask == null and lease.call("effective_mask") == null and row.mask_kind == "SOURCE_POLYGON_ONLY","TEMPLE_POLYGON_ONLY_NO_INVENTED_MASK"): return false
	else:
		if not check(mask != null and lease.call("effective_mask") == mask and state.get("mask") == mask,"FAMILY_EFFECTIVE_IMAGE_OBJECT_IDENTICAL"): return false
	var count: int = 0
	for node: Node in field.get("_collision_bodies"):
		if node is StaticBody2D and node.has_meta("finish25i_source_ordinal"):
			if not check(node.collision_layer == 1 and node.collision_mask == 0 and node.get_child_count() == 1 and node.get_child(0) is CollisionPolygon2D and not node.get_child(0).disabled,"TRUE_ENABLED_PUBLISHED_FAMILY_POLYGON"): return false
			count += 1
	if not check(count == int(row.effective_solid_count),"TRUE_FULL_FAMILY_PHYSICS_COUNT"): return false
	records.append({"kind":"NATURAL_FAMILY_ORIGINAL_FINAL_AND_EFFECTIVE_LEASE","scene":row.scene_id,"token":str(token),"key":key,"source_count":row.expected_sources.size(),"solids":count,"mask_kind":row.mask_kind,"original_matches_or_finalize_calls_by_QA":0})
	return true

func clear(foot: Vector2) -> bool:
	if scene == null or scene.scene_id != &"ch4_s4_ancient_temple": return super.clear(foot)
	if not budget() or tree.current_scene != field or player() == null: return false
	var p: CharacterBody2D = player()
	var shape: CollisionShape2D = p.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var world: Node2D = field.get("world_container") as Node2D
	var lease: RefCounted = field.get("_finish25i")
	if shape == null or shape.disabled or not shape.shape is RectangleShape2D or shape.shape.size != Vector2(34,24) or world == null or lease == null: return false
	# A production predicate plus real Physics is only a no-search precondition here,
	# not independent Temple geometric proof (that prior was already accepted).
	if not lease.call("safe_foot",foot,true): return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape;query.transform = shape.global_transform
	query.transform.origin += world.to_global(foot)-p.global_position
	query.exclude = [p.get_rid()];query.collision_mask = p.collision_mask;query.collide_with_areas = false;physics_queries += 1
	return p.get_world_2d().direct_space_state.intersect_shape(query,16).is_empty()

func picture(label: String) -> bool:
	var camera: Camera2D = field.get("_world_camera") as Camera2D
	if not check(pictures < int(spec.max_pictures) and camera != null and camera == tree.root.get_camera_2d() and camera.enabled and camera.zoom == Vector2.ONE*scene.camera_zoom and field.get("_camera_zoom") == scene.camera_zoom,"UNCHANGED_SOURCE_FAMILY_CAMERA_NO_QA_OVERRIDE"): return false
	await RenderingServer.frame_post_draw
	var image: Image = tree.root.get_texture().get_image()
	var path: String = output.path_join(str(pictures+1)+"_"+label+".png")
	if not check(image != null and image.get_size() == Vector2i(1920,1080) and not FileAccess.file_exists(path) and image.save_png(path) == OK,"ONE_SOURCE_CAMERA_PNG_PER_DECLARED_FAMILY"): return false
	pictures += 1;records.append({"kind":"FINITE_ACTUAL_FAMILY_VIEW_NOT_WHOLE_CITY_ART","scene":String(scene.scene_id),"path":path,"sha256":FileAccess.get_sha256(path),"camera_zoom":camera.zoom})
	return true

func source_input(row: Dictionary) -> bool:
	var from: Vector2 = v(row.source_input.from)
	var to: Vector2 = v(row.source_input.to)
	if not check(from.distance_to(to) == 8.0,"FROZEN_NEW_DOMAIN_EIGHT_PIXEL_SOURCE_LEG"): return false
	if not await inspection(from,"SOURCE_FIXED_NEW_DOMAIN_NOT_DEFAULT_TRAVEL"): return false
	var moved: Dictionary = await driver.drive(field,to,Callable(self,"clear"))
	input_ticks += int(moved.get("physics_samples",0))
	if not check(moved.get("ok") == true,"TRUE_INPUT_NEW_DOMAIN_NO_ROUTE_RETRY"): return false
	return true

func exercise() -> bool:
	var first_row: Dictionary = spec.scenes[0]
	var start: int = Time.get_ticks_usec()
	if not check(router().call("go_field_smart",StringName(first_row.scene_id)),"PUBLIC_FIRST_FAMILY_REQUEST") or not await arrive(StringName(first_row.scene_id),start,"PUBLIC_DEFAULT_SETUP_NOT_LOADING_BENCHMARK",int(spec.entry_ms)): return false
	initial_refs = [weakref(field),weakref(player()),weakref(scene),weakref(scene.map_layout)]
	for index: int in range(spec.scenes.size()):
		var row: Dictionary = spec.scenes[index]
		if index > 0 and not await portal_leg(spec.portal_legs[index-1],"REAL_SOURCE_SPACE_LINK_"+str(index)): return false
		if row.get("source_input") is Dictionary and not await source_input(row): return false
		if row.get("picture_before_talk",false) and not await picture("actual_"+String(row.scene_id)): return false
		for talk_row: Dictionary in row.get("talks",[]):
			var actor_row: Dictionary = talk_row.actor
			if sample_actor(actor_row).is_empty(): return false
			var npc: NPCNode = actor(String(talk_row.talk_npc_id))
			var physical: Dictionary = body(npc)
			if not check(npc.position == v(talk_row.source_foot_px) and physical.size == Vector2(160.0*.14,160.0*.18) and physical.center == Vector2.ZERO and physical.scale == 1.0 and npc._calibrate_adult_body,"NEW_ESTATE_SOURCE_FOOT_NATIVE_BODY_NOT_SHRUNK"): return false
			if not await talk(talk_row): return false
	if spec.get("return_leg") is Dictionary:
		if not await portal_leg(spec.return_leg,"REAL_NEW_LINK_RETURN"): return false
		var same: bool = field == initial_refs[0].get_ref() and player() == initial_refs[1].get_ref() and scene == initial_refs[2].get_ref() and scene.map_layout == initial_refs[3].get_ref()
		records.append({"kind":"FAMILY_NEW_LOOP_RETURN_CLASSIFICATION","same_Field_Player_Scene_layout":same,"warm_resident_credit":same,"newowner_reentry_if_not_same":not same})
	return check(writes <= int(spec.max_inspection_writes) and pictures == int(spec.max_pictures) and gameplay() == gameplay_first,"FINITE_FAMILY_OR_NEW_RESIDENT_SCOPE_COMPLETE")

func resolve_portal_formula(leg: Dictionary) -> bool:
	if not leg.get("expected_target_uv_formula") is Dictionary: return leg.get("expected_target_uv") is Array
	var formula: Dictionary = leg.expected_target_uv_formula
	if not formula.get("numerator") is Array or formula.numerator.size()!=2 or not formula.get("denominator") is Array or formula.denominator.size()!=2: return false
	var denominator: Vector2 = v(formula.denominator)
	if denominator.x<=0 or denominator.y<=0: return false
	var uv: Vector2 = v(formula.numerator)/denominator
	leg.expected_target_uv=[uv.x,uv.y]
	return uv.is_finite()

func precheck() -> bool:
	if not check(spec.get("ready") == true and spec.get("formal_deployed") == true and spec.get("formal_stage_actual") is Dictionary and spec.get("Root_deployment_actual") is Dictionary and int(spec.whole_ms) == 60000 and int(spec.entry_ms) == 20000 and int(spec.max_inspection_writes) <= 4 and int(spec.max_pictures) <= 2 and spec.scenes is Array and spec.scenes.size() >= 1 and spec.scenes.size() <= 3 and spec.portal_legs is Array and spec.portal_legs.size() == spec.scenes.size()-1,"DEPLOYED_FIXED_AUTHORITY_AND_FAMILY_SPLIT_BUDGET"): return false
	if not check(DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and tree.root.get_visible_rect().size == Vector2(1920,1080) and OS.get_cmdline_user_args().is_empty(),"NORMAL_GUI_NO_BODY_OR_SPEED_OR_CAMERA_OVERRIDE"): return false
	if not check(spec.get("dependencies") is Dictionary and not spec.dependencies.is_empty(),"FIXED_FINITE_FAMILY_DEPENDENCIES"): return false
	first = facts(spec.dependencies.keys())
	for path: String in spec.dependencies:
		if not check(String(spec.dependencies[path]).length() == 64 and first[path].get("sha256") == spec.dependencies[path],"FAMILY_FIXED_SOURCE:"+path): return false
	for row: Dictionary in spec.scenes:
		if not check(row.get("owner_kind") in ["C","QUARTER","ESTATE","TEMPLE"] and typeof(row.get("effective_solid_count")) in [TYPE_INT,TYPE_FLOAT] and float(row.effective_solid_count) == float(int(row.effective_solid_count)) and int(row.effective_solid_count) > 0,"EXACT_FAMILY_ROW_SCHEMA"): return false
		if not fixed_sources(row): return false
	for leg: Dictionary in spec.portal_legs:
		if not check(resolve_portal_formula(leg),"SOURCE_VECTOR2_DIVISION_NOT_HAND_FILLED_UV"): return false
		if not check(leg.get("source_foot_px") is Array and leg.get("expected_target_uv") is Array and leg.get("expected_arrival_foot_px") is Array and leg.get("required_fixed_source_authority") is Dictionary,"FROZEN_SOURCE_PORTAL_SCALARS_REQUIRED"): return false
	if spec.get("return_leg") is Dictionary:
		var back: Dictionary = spec.return_leg
		if not check(resolve_portal_formula(back),"SOURCE_RETURN_VECTOR2_DIVISION"): return false
		if not check(back.get("source_foot_px") is Array and back.get("expected_target_uv") is Array and back.get("expected_arrival_foot_px") is Array and back.get("required_fixed_source_authority") is Dictionary,"FROZEN_NEW_RETURN_SCALARS_REQUIRED"): return false
	return true
