extends RefCounted
## Executable QA worker, loaded AFTER normal autoloads by bootstrap.
## Only real SceneRouter, Input driver, NPC/DP UI and local mask/Physics queries.
const DRIVER_PATH := "res://tests/helpers/v15_input_driver.gd"
const DRIVER_SHA := "a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7"
var tree: SceneTree
var spec: Dictionary = {}
var checks: int = 0
var errors: Array[String] = []
var records: Array = []
var first: Dictionary = {}
var saves_first: Dictionary = {}
var began: int = 0
var deadline: int = 0
var output: String = ""
var field: Node
var scene: SceneScript
var driver: RefCounted
var pictures: int = 0
var writes: int = 0
var input_ticks: int = 0
var physics_queries: int = 0
var mask_queries: int = 0
var space_calls: int = 0
var text_events: Array = []
var gameplay_first: PackedByteArray
var actor_coverage: Dictionary = {}
var phase_coverage: Dictionary = {}
var initial_refs: Array = []

func check(ok: bool,label: String,details: Variant = null) -> bool:
	checks += 1
	if not ok:
		errors.append(label);printerr("FINISH25I_REAL_FIELD_FAIL ",label," ",details)
	return ok

func v(raw: Variant) -> Vector2:
	return raw if raw is Vector2 else Vector2(float(raw[0]),float(raw[1]))

func dp() -> Node: return tree.root.get_node("DialogPlayer")
func player() -> CharacterBody2D: return field.get("_player") as CharacterBody2D if is_instance_valid(field) else null
func router() -> Node: return tree.root.get_node("SceneRouter")
func budget() -> bool: return Time.get_ticks_msec() < deadline
func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false}
	var file := FileAccess.open(path,FileAccess.READ)
	var count: int = file.get_length() if file != null else -1
	if file != null: file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":count,"mtime_seconds":FileAccess.get_modified_time(path)}
func facts(paths: Array) -> Dictionary:
	var out: Dictionary = {}
	for path: String in paths: out[path] = fact(path)
	return out
func saves() -> Dictionary:
	var paths: Array = []
	for slot: int in range(5):
		for suffix: String in [".json",".json.bak",".json.tmp"]: paths.append("user://save_"+str(slot)+suffix)
	return facts(paths)

func gameplay() -> PackedByteArray:
	var members: Array = []
	for stats: CharacterStats in GameState.party:
		members.append({"instance":stats.get_instance_id(),"hp":stats.hp,"max_hp":stats.max_hp,"mp":stats.mp,"max_mp":stats.max_mp})
	return var_to_bytes({"flags":GameState.flags,"gold":GameState.gold,"quests":QuestManager.to_dict(),"inventory":Inventory.to_dict(),"party":members})

func hidden() -> bool:
	var screen: Node = LoadingManager._screen
	var panel: Control = screen.get("root") as Control if is_instance_valid(screen) else null
	return not LoadingManager._external_active and not LoadingManager._transition_active and (panel == null or not panel.is_visible_in_tree())

func actor(id: String) -> NPCNode:
	var found: Array = []
	if not is_instance_valid(field): return null
	for node: NPCNode in field.get("_npc_nodes"):
		if is_instance_valid(node) and node.npc_id == id and node.get_parent() == field.get("_actor_layer"): found.append(node)
	return found[0] if found.size() == 1 else null

func body(actor_node: NPCNode) -> Dictionary:
	if actor_node == null or actor_node._body_collider == null or actor_node._body_collider.get_child_count() != 1: return {}
	var shape: CollisionShape2D = actor_node._body_collider.get_child(0) as CollisionShape2D
	if shape == null or shape.disabled or not shape.shape is RectangleShape2D: return {}
	return {"size":shape.shape.size,"center":actor_node._body_collider.position+shape.position,"layer":actor_node._body_collider.collision_layer,"mask":actor_node._body_collider.collision_mask,"scale":actor_node.sprite_scale,"axis":actor_node.patrol_axis,"distance":actor_node.patrol_distance,"speed":actor_node.patrol_speed,"invert":actor_node.invert_patrol_facing,"origin":actor_node._patrol_origin,"seconds":actor_node.walk_frame_seconds}

func scene_row(id: String) -> Dictionary:
	for row: Dictionary in spec.scenes:
		if String(row.scene_id) == id: return row
	return {}

func natural(row: Dictionary) -> bool:
	var c: Variant = load(spec.original_C.path)
	var original: Dictionary = c._resident_ready
	var lease: RefCounted = field.get("_finish25i")
	var current: Dictionary = field.call("get_finish25i_state")
	var mask: Image = field.get("_walkable_mask_image") as Image
	if not check(original.get("scene") == scene and original.get("id") == scene.scene_id and original.get("sources_finalized") == true and int(original.get("token",0)) > 0 and original.get("sources") == row.expected_sources,"NATURAL_ORIGINAL_COMPLETE_FINAL_NO_COLLECTOR:"+row.scene_id): return false
	if not check(lease != null and lease.get_script().resource_path == spec.finish_runtime.path and current.get("finalized") == true and current.get("scene_instance") == scene.get_instance_id() and current.get("binding_sha") == spec.finish_binding.sha256 and current.get("token") == original.token and mask != null and lease.call("effective_mask") == mask and current.get("mask") == mask,"NATURAL_EFFECTIVE_LEASE_OWNER_SAME_MASK:"+row.scene_id): return false
	var actual_solids: Array = []
	for node: Node in field.get("_collision_bodies"):
		if node is StaticBody2D and node.has_meta("finish25i_source_ordinal"):
			if not check(node.collision_layer == 1 and node.collision_mask == 0 and node.get_child_count() == 1 and node.get_child(0) is CollisionPolygon2D and not node.get_child(0).disabled,"ENABLED_PUBLISHED_STATIC_BODY"): return false
			actual_solids.append(node)
	if not check(actual_solids.size() == int(row.effective_solid_count),"ACTUAL_FULL_EFFECTIVE_PHYSICS_COUNT_NOT_VISIBLE_COUNT:"+row.scene_id): return false
	records.append({"kind":"PASSIVE_NATURAL_FIRST_FINAL_AND_EFFECTIVE_LEASE","scene":row.scene_id,"source_count":original.sources.size(),"original_token":str(original.token),"lease_owner_key":current.owner_key,"lease_binding":current.binding_sha,"solid_count":actual_solids.size(),"Field":str(field.get_instance_id()),"Scene":str(scene.get_instance_id()),"layout":str(scene.map_layout.get_instance_id()),"QA_validate_finalize_or_geometry_calls":0})
	return true

func arrive(id: StringName,start_us: int,label: String,limit: int) -> bool:
	var until: int = mini(deadline,Time.get_ticks_msec()+limit)
	while Time.get_ticks_msec() < until:
		var public: Dictionary = router().call("get_public_city_preparation_state")
		if public.get("scene_id") == String(id) and public.get("phase") == "FAILED": return check(false,"PUBLIC_REJECT_NO_RETRY",public)
		var current: Node = tree.current_scene
		if is_instance_valid(current) and current.has_method("get_field_loading_state"):
			var loading: Dictionary = current.call("get_field_loading_state")
			var s: SceneScript = current.get("_current_scene") as SceneScript
			if s != null and s.scene_id == id:
				if loading.get("failed") == true: return check(false,"FIELD_REJECT_NO_RETRY",loading)
				var p: CharacterBody2D = current.get("_player") as CharacterBody2D
				if loading.get("complete") == true and p != null and p.can_process() and p.can_move and hidden():
					await RenderingServer.frame_post_draw
					# Freeze timing BEFORE any verification, hashing, actor sample or screenshot.
					var draw_us: int = Time.get_ticks_usec()
					if not check(tree.current_scene == current and current.get("_current_scene") == s and current.get("_player") == p and p.can_move and hidden() and Time.get_ticks_msec() < until,"REAL_SAME_HIDDEN_OPERABLE_POST_DRAW"): return false
					field = current;scene = s
					records.append({"kind":"NATURAL_HIDDEN_OPERABLE_TIMING_FROZEN_BEFORE_ASSERTIONS","label":label,"scene_id":String(id),"request_us":str(start_us),"draw_us":str(draw_us),"elapsed_us":draw_us-start_us,"Field":str(field.get_instance_id()),"Player":str(p.get_instance_id()),"foot":p.position,"entry_kind":label,"world96_or_default_perf_credit":false})
					return natural(scene_row(String(id)))
		await tree.process_frame
	return check(false,"FIXED_LEG_TIMEOUT_NO_EXTENSION:"+label,router().call("get_public_city_preparation_state"))

func sample_actor(row: Dictionary) -> Dictionary:
	var node: NPCNode = actor(String(row.npc_id))
	if node == null: check(false,"UNIQUE_REAL_ADOPTED_ACTOR:"+String(row.npc_id));return {}
	var visual: Sprite2D = node.sprite
	var b: Dictionary = body(node)
	if not check(visual != null and visual.texture != null and node.is_visible_in_tree() and node.sprite_path == row.after.sprite_path and node.walk_sprite_path == row.after.walk_sprite_path and node.portrait_path == row.after.portrait_path and node.movement_mode == row.after.movement_mode and node.interaction_action == "ambient25i_daily" and not b.is_empty(),"REAL_ACTOR_PATH_PORTRAIT_ACTION:"+String(row.npc_id)): return {}
	if row.walker:
		var motion: Dictionary = row.original_motion
		var expected_origin: Vector2 = v(motion.source_foot_px)/Vector2(3072,2048)*field.get("_world_size")
		if not check(b.size == Vector2(160.0*.14,160.0*.18) and b.center == Vector2.ZERO and b.scale == 1.0 and b.layer == 1 and b.mask == 0 and b.axis == v(motion.axis) and b.distance == float(motion.distance) and b.speed == float(motion.speed) and b.invert == motion.invert and b.origin == expected_origin and b.seconds == .12 and node._calibrate_adult_body,"SOURCE_ORIGINAL_MOTION_AND_FIXED_NATIVE_BODY:"+String(row.npc_id)): return {}
		var core: Variant = NPCNode._visible_bounds_cache.get(visual.texture.get_instance_id())
		var expected: Dictionary = {}
		for declared: Dictionary in spec.core_textures:
			if declared.path == visual.texture.resource_path: expected = declared
		if not check(not expected.is_empty() and core is Rect2i and core == Rect2i(int(expected.core_rect_xywh[0]),int(expected.core_rect_xywh[1]),int(expected.core_rect_xywh[2]),int(expected.core_rect_xywh[3])) and visual.scale == Vector2.ONE*(140.0/float(core.size.y)),"EXACT_NEW_TEXTURE_CORE_AND_VISUAL140:"+String(row.npc_id)): return {}
		# Visual foot numeric tolerance only; not geometry/owner equality relaxation.
		if not check(absf(visual.position.y+(float(core.end.y)-80.0)*visual.scale.y) < .001,"VISUAL_BOOT_ANCHOR_WITH_ORIGINAL_GROUND_FOOT"): return {}
	actor_coverage[String(row.npc_id)] = true
	return {"npc_id":row.npc_id,"instance":str(node.get_instance_id()),"position":node.position,"texture":visual.texture.resource_path,"frame":visual.frame,"hframes":visual.hframes,"body":b,"conversation":node._conversation_active}

func observe_city(row: Dictionary) -> bool:
	var samples: Dictionary = {}
	var start: int = Time.get_ticks_msec()
	while Time.get_ticks_msec()-start < 900 and budget():
		await RenderingServer.frame_post_draw
		for person: Dictionary in row.actors:
			var value: Dictionary = sample_actor(person)
			if value.is_empty(): return false
			var id: String = String(person.npc_id)
			if not samples.has(id): samples[id] = []
			samples[id].append(value)
	for person: Dictionary in row.actors:
		var id: String = String(person.npc_id)
		if person.walker:
			var frames: Dictionary = {};var positions: Dictionary = {};var previous: PackedByteArray
			for value: Dictionary in samples[id]:
				if not check(value.texture == person.after.walk_sprite_path and value.hframes == 4 and not value.conversation,"REAL_PATROL_WALK4_NOT_FORCED_FRAME"): return false
				frames[int(value.frame)] = true;positions[var_to_str(value.position)] = true
				var current: PackedByteArray = var_to_bytes(value.body)
				if previous.is_empty(): previous = current
				elif not check(previous == current,"ORIGINAL_BODY_LANE_SPEED_CONSTANT_ACROSS_FOUR_PHASES"): return false
			if not check(frames.size() == 4 and positions.size() > 1,"ALL_FOUR_REAL_PHASES_AND_ACTUAL_PATROL:"+id): return false
			phase_coverage[id] = true
	records.append({"kind":"ACTUAL_SCENE_NPC_ADOPTION_900MS","scene":row.scene_id,"samples":samples,"camera_or_NPC_or_frame_writes":0})
	return true

func clear(foot: Vector2) -> bool:
	if not budget() or tree.current_scene != field or player() == null: return false
	var p: CharacterBody2D = player()
	var shape: CollisionShape2D = p.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var world: Node2D = field.get("world_container") as Node2D
	var mask: Image = field.get("_walkable_mask_image") as Image
	if shape == null or shape.disabled or not shape.shape is RectangleShape2D or shape.shape.size != Vector2(34,24) or world == null or mask == null or foot.x < 17 or foot.y < 12 or roundi(foot.x+17) >= mask.get_width() or roundi(foot.y+12) >= mask.get_height(): return false
	for y: int in range(roundi(foot.y-12),roundi(foot.y+12)+1):
		for x: int in range(roundi(foot.x-17),roundi(foot.x+17)+1):
			mask_queries += 1
			var c: Color = mask.get_pixel(x,y)
			if c.r < .5 or c.a < .5: return false
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape;query.transform = shape.global_transform
	query.transform.origin += world.to_global(foot)-p.global_position
	query.exclude = [p.get_rid()];query.collision_mask = p.collision_mask;query.collide_with_areas = false;physics_queries += 1
	return p.get_world_2d().direct_space_state.intersect_shape(query,16).is_empty()

func inspection(foot: Vector2,label: String) -> bool:
	if not check(writes < int(spec.max_inspection_writes) and clear(foot),"ROOT_DECLARED_ONE_POSE_NO_RETRY_FULLBODY_PHYSICS:"+label): return false
	var before: Vector2 = player().position
	driver.release_movement();player().position = foot;player().reset_physics_interpolation();writes += 1
	await tree.physics_frame;await driver.completed_actor_stage()
	records.append({"kind":"EXPLICIT_QA_INSPECTION_NOT_DEFAULT_OR_CONTINUOUS_TRAVEL","label":label,"from":before,"requested":foot,"actual":player().position,"writes":writes,"NPC_camera_body_or_speed_writes":0})
	return check(player().position == foot and clear(foot),"EXACT_INSPECTION_AFTER_REAL_PHYSICS")

func on_text(speaker: String,text: String,choices: bool,portrait: String) -> void:
	text_events.append({"speaker":speaker,"text":text,"has_choices":choices,"portrait":portrait})

func dialog_node(id: String,portrait: String,npc: NPCNode) -> bool:
	await tree.process_frame
	var node: DialogNode = dp().get("_current_node") as DialogNode
	var graph: DialogScript = dp().get("_current_script") as DialogScript
	var layer: CanvasLayer = dp().get("_box") as CanvasLayer
	var box: Control = layer.get_node_or_null("DialogBox") as Control if layer != null else null
	var image: TextureRect = box.get("portrait") as TextureRect if box != null else null
	var choices: Control = box.get("choices_container") as Control if box != null else null
	var helper: RefCounted = field.get("_ambient25i")
	var lease: Dictionary = helper.get("_session") if helper != null else {}
	var correct: bool = node != null and graph != null and node.node_id == StringName(id) and node.choices.is_empty() and lease.get("script") == graph and lease.get("actor") is WeakRef and lease.actor.get_ref() == npc and field.get("_active_dialog_npc") == npc and box != null and box.is_visible_in_tree() and image != null and image.is_visible_in_tree() and image.texture != null and image.texture.resource_path == portrait and choices != null and not choices.is_visible_in_tree()
	records.append({"kind":"REAL_SPACE_DP_UI_NODE","node":String(node.node_id) if node != null else "NULL","portrait":image.texture.resource_path if image != null and image.texture != null else "","actor":npc.npc_id,"no_choices":node != null and node.choices.is_empty()})
	return check(correct,"REAL_OWNED_HERO_NPC_UI:"+id)

func advance_from(id: String) -> bool:
	for press: int in range(3):
		var node: DialogNode = dp().get("_current_node") as DialogNode
		if node == null or String(node.node_id) != id: return true
		if not budget(): return false
		await driver.key(KEY_SPACE);space_calls += 1
	return check(dp().get("_current_node") == null or String((dp().get("_current_node") as DialogNode).node_id) != id,"REAL_SPACE_ADVANCE_BOUNDED_NO_PRIVATE_DP_CALL")

func picture(label: String) -> bool:
	var camera: Camera2D = field.get("_world_camera") as Camera2D
	if not check(pictures < 1 and camera != null and camera == tree.root.get_camera_2d() and camera.enabled and camera.zoom == Vector2.ONE*scene.camera_zoom and scene.camera_zoom == 1.05 and field.get("_camera_zoom") == scene.camera_zoom,"UNCHANGED_ORIGINAL_CAMERA_105_ONE_PNG"): return false
	await RenderingServer.frame_post_draw
	var image: Image = tree.root.get_texture().get_image()
	var path: String = output.path_join(label+".png")
	if not check(image != null and image.get_size() == Vector2i(1920,1080) and not FileAccess.file_exists(path) and image.save_png(path) == OK,"ONE_ORIGINAL_VIEWPORT_NO_EDIT"): return false
	pictures += 1;records.append({"kind":"ONE_ACTUAL_LOCAL_REPRESENTATIVE_NOT_WHOLECITY_ART","path":path,"sha256":FileAccess.get_sha256(path)})
	return true

func talk(row: Dictionary) -> bool:
	var npc: NPCNode = actor(String(row.talk_npc_id))
	if not check(npc != null and not dp().is_playing(),"ACTUAL_ADOPTED_TALK_ACTOR"): return false
	# Predetermined relative inspection formula, NOT default/performance or authored NAV proof.
	var source_pose: Vector2 = npc.position
	if not await inspection(source_pose+Vector2(0,72),"TALK_RELATIVE_SOURCE_ACTOR_PLUS_0_72"): return false
	var moved: Dictionary = await driver.drive(field,source_pose+Vector2(0,64),Callable(self,"clear"))
	input_ticks += int(moved.get("physics_samples",0))
	if not check(moved.get("ok") == true and npc.global_position.distance_to(player().global_position) <= 118.0,"REAL_SHORT_INPUT_TO_ACTUAL_NPC"): return false
	var before_body: PackedByteArray = var_to_bytes(body(npc))
	var count_before: int = text_events.size()
	await driver.key(KEY_SPACE);space_calls += 1
	if not await dialog_node("hero","res://art/characters/protagonist_portrait.png",npc): return false
	var frozen_position: Vector2 = npc.position
	var frozen_phase: float = npc._patrol_phase
	await tree.process_frame;await tree.physics_frame
	if not check(npc._conversation_active and npc.position == frozen_position and npc._patrol_phase == frozen_phase,"ACTUAL_CONVERSATION_FREEZES_ONLY_EXISTING_PATROL_API"): return false
	if not await advance_from("hero") or not await dialog_node("start",npc.portrait_path,npc): return false
	var node: DialogNode = dp().get("_current_node") as DialogNode
	if not check(node.speaker == npc.npc_name and node.text == row.talk_text.lines[0] and node.on_end == "next:reply","APPROVED_NPC_FIRST_LINE"): return false
	if row.picture_here and not await picture("01_actual_NPC_hero_first_portrait"): return false
	if not await advance_from("start") or not await dialog_node("reply",npc.portrait_path,npc): return false
	node = dp().get("_current_node") as DialogNode
	if not check(node.text == row.talk_text.lines[1] and node.on_end == "end","APPROVED_NPC_SECOND_LINE_DIRECT_END"): return false
	if not await advance_from("reply"): return false
	await driver.completed_actor_stage()
	if not check(not dp().is_playing() and not npc._conversation_active and field.get("_active_dialog_npc") == null and player().can_move and var_to_bytes(body(npc)) == before_body and text_events.size() >= count_before+3,"NATURAL_END_CONTROL_AND_ORIGINAL_MOTION_BODY_RESTORED"): return false
	if npc.movement_mode == "patrol":
		var start: Vector2 = npc.position
		var until: int = mini(deadline,Time.get_ticks_msec()+350)
		while Time.get_ticks_msec() < until: await tree.process_frame
		if not check(npc.position != start and npc.sprite.texture == npc._walk_texture,"TRUE_PATROL_RESUMED_NO_QA_PHASE_OR_POSITION_WRITE"): return false
	return check(gameplay() == gameplay_first,"ZERO_EFFECTS_APPROVED_DAILY_DIALOG")

func portal_leg(leg: Dictionary,label: String) -> bool:
	if not check(scene.scene_id == StringName(leg.source_scene) and leg.get("source_foot_px") is Array and leg.get("expected_target_uv") is Array,"FIXED_INDEPENDENT_SOURCE_PORTAL_LEG"): return false
	var source_foot: Vector2 = v(leg.source_foot_px)
	if not await inspection(source_foot,label+":PORTAL_SOURCE_FOOT"): return false
	var matches: Array = []
	for node: Node in field.get("_exit_nodes"):
		if node is Area2D and node.get("target_scene_id") == leg.target_scene and node.position == source_foot: matches.append(node)
	if not check(matches.size() == 1,"UNIQUE_ACTUAL_SOURCE_EXIT_NOT_SIGNAL_SHORTCUT"): return false
	var zone: Area2D = matches[0]
	if not check(zone.get("is_locked") == false and zone.get("auto_trigger") == false and zone.get("target_spawn_pos") == v(leg.expected_target_uv) and zone.monitoring and zone.overlaps_body(player()),"ORIGINAL_GATE_UNLOCK_AND_AUTHORED_TARGET_BEFORE_TRUE_SPACE"): return false
	var request_us: int = Time.get_ticks_usec()
	await driver.key(KEY_SPACE);space_calls += 1
	if not await arrive(StringName(leg.target_scene),request_us,label,int(spec.entry_ms)): return false
	if not check(player().position == v(leg.expected_arrival_foot_px),"SOURCE_EXPECTED_ARRIVAL_NOT_OBSERVED_BACKFILL"): return false
	return true

func exercise() -> bool:
	var first_row: Dictionary = spec.scenes[0]
	var request_us: int = Time.get_ticks_usec()
	if not check(router().call("go_field_smart",StringName(first_row.scene_id)),"ONE_PUBLIC_DEFAULT_REQUEST_NO_PRIVATE_PLAYER_SETUP") or not await arrive(StringName(first_row.scene_id),request_us,"PUBLIC_DEFAULT_QA_SETUP_NOT_WORLD96_BENCHMARK",int(spec.entry_ms)): return false
	initial_refs = [weakref(field),weakref(player()),weakref(scene),weakref(scene.map_layout)]
	if not await observe_city(first_row) or not await talk(first_row): return false
	if not await portal_leg(spec.portal_legs[0],"REAL_SPACE_FORWARD"): return false
	var second_row: Dictionary = spec.scenes[1]
	if not await observe_city(second_row) or not await talk(second_row): return false
	if not await portal_leg(spec.portal_legs[1],"REAL_SPACE_RETURN"): return false
	var same: bool = field == initial_refs[0].get_ref() and player() == initial_refs[1].get_ref() and scene == initial_refs[2].get_ref() and scene.map_layout == initial_refs[3].get_ref()
	records.append({"kind":"ACTUAL_ROUNDTRIP_IDENTITY_CLASSIFICATION","same_Field_Player_Scene_layout":same,"warm_resident_credit":same,"newowner_reentry_if_not_same":not same,"no_fake_same_owner":true})
	return check(actor_coverage.size() == int(spec.expected_actor_count) and phase_coverage.size() == int(spec.expected_walker_count) and pictures == 1 and writes == 4 and gameplay() == gameplay_first,"FINITE_TWO_TRUE_FIELDS_ACTUAL_5WALKER_SUBSET_7PORTRAIT_SUBSET_ROUNDTRIP")

func resolve_fixed_source_maps() -> bool:
	# Expectations come only from the immutable Source descriptor, never actual C sources.
	for row: Dictionary in spec.scenes:
		var declared: Variant = row.get("expected_sources_artifact")
		if not check(declared is Dictionary and declared.get("path") is String and declared.get("sha256") is String and String(declared.sha256).length() == 64 and spec.dependencies.get(declared.path) == declared.sha256 and FileAccess.get_sha256(declared.path) == declared.sha256,"FIXED_SOURCE_MAP_ARTIFACT:"+row.scene_id): return false
		var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(declared.path))
		if not check(raw is Dictionary and raw.get("scene_id") == row.scene_id and raw.get("source_sha256") is Dictionary and raw.source_sha256.size() == int(row.expected_source_count),"FULL_SOURCE_MAP_SCHEMA_COUNT:"+row.scene_id): return false
		row.expected_sources = raw.source_sha256
	return true

func precheck() -> bool:
	if not check(spec.get("ready") == true and spec.get("formal_deployed") == true and int(spec.whole_ms) == 60000 and int(spec.entry_ms) == 20000 and int(spec.max_inspection_writes) == 4 and spec.scenes.size() == 2 and spec.portal_legs is Array and spec.portal_legs.size() == 2 and spec.dependencies is Dictionary and not spec.dependencies.is_empty(),"FINAL_IMMUTABLE_SOURCE_AUTHORITY_AND_EXACT_BUDGET_REQUIRED"): return false
	if not resolve_fixed_source_maps(): return false
	if not check(DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and tree.root.get_visible_rect().size == Vector2(1920,1080) and OS.get_cmdline_user_args().is_empty(),"ORIGINAL_NATIVE_GUI_NO_SPEED_CAMERA_FLAGS"): return false
	for key: String in ["original_C","finish_runtime","finish_binding","source_authority"]:
		var artifact: Variant = spec.get(key)
		if not check(artifact is Dictionary and artifact.get("path") is String and artifact.get("sha256") is String and artifact.sha256.length() == 64 and spec.dependencies.get(artifact.path) == artifact.sha256,"FINAL_SOURCE_ARTIFACT_NOT_PENDING:"+key): return false
	first = facts(spec.dependencies.keys())
	for path: String in spec.dependencies:
		if not check(String(spec.dependencies[path]).length() == 64 and first[path].get("sha256") == spec.dependencies[path],"EXACT_FIXED_QA_AND_NEW_RUNTIME_SOURCE:"+path): return false
	for row: Dictionary in spec.scenes:
		if not check(row.get("expected_sources") is Dictionary and not row.expected_sources.is_empty() and typeof(row.get("effective_solid_count")) in [TYPE_INT,TYPE_FLOAT] and float(row.effective_solid_count) == float(int(row.effective_solid_count)) and int(row.effective_solid_count) > 0 and row.get("actors") is Array and row.get("talk_text") is Dictionary,"INDEPENDENT_FULLMAP_AND_EXPECTED_ACTORS_REQUIRED:"+row.scene_id): return false
	for leg: Dictionary in spec.portal_legs:
		if not check(leg.get("source_foot_px") is Array and leg.get("expected_target_uv") is Array and leg.get("expected_arrival_foot_px") is Array,"SOURCE_PORTAL_EXACT_COORDS_NOT_PREDICTED_FROM_ACTUAL"): return false
	return true

func run(owner_tree: SceneTree,fixture: Dictionary) -> void:
	tree = owner_tree;spec = fixture;began = Time.get_ticks_msec();deadline = began+60000
	output = String(spec.get("output_root","res://build/luoyang_city_finish_20261025i_system01/qa_role_new/real_fields04_ROOT_READY/output/"))+str(OS.get_process_id())+"_"+str(began)+"/"
	if DirAccess.dir_exists_absolute(output): printerr("PRESERVE_OUTPUT");tree.quit(2);return
	DirAccess.make_dir_recursive_absolute(output)
	saves_first = saves();gameplay_first = gameplay()
	var complete: bool = false
	if precheck() and check(FileAccess.get_sha256(DRIVER_PATH) == DRIVER_SHA,"MATURE_REAL_INPUT_DRIVER_SOURCE"):
		var input_script: GDScript = load(DRIVER_PATH) as GDScript
		if check(input_script != null and input_script.can_instantiate(),"REAL_INPUT_DRIVER_LOAD"):
			driver = input_script.new();driver.configure(tree)
			dp().text_displayed.connect(on_text)
			complete = await exercise()
	if driver != null: driver.release()
	if dp().text_displayed.is_connected(on_text): dp().text_displayed.disconnect(on_text)
	var last: Dictionary = facts(spec.get("dependencies",{}).keys())
	var saves_last: Dictionary = saves()
	check(first == last,"FIXED_OWN_SOURCE_FACTS_FIRST_FINAL")
	check(saves_first == saves_last and tree.root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended") == true,"ALL15_SAVE_FACTS_UNCHANGED_CHECKPOINT_STILL_SUSPENDED")
	check(gameplay_first == gameplay(),"NO_FLAGS_QUESTS_INVENTORY_GOLD_HPMP_EFFECTS")
	check(complete and budget(),"FIXED_WHOLE60S_NO_EXTENSION")
	var report: Dictionary = {"complete":complete and errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"group":spec.get("group_id"),"records":records,"source_first":first,"source_final":last,"saves_first":saves_first,"saves_final":saves_last,"actual_actor_ids":actor_coverage.keys(),"actual_four_phase_walkers":phase_coverage.keys(),"inspection_position_writes":writes,"real_INPUT_ticks":input_ticks,"Space_calls":space_calls,"local_body_Physics_queries":physics_queries,"local_mask_pixel_queries":mask_queries,"pictures":pictures,"old_collectors_or87517_or114selftest_or16graphs_orServices":0,"NPC_camera_body_phase_writes":0,"runtime_author_selftest_not_independent":true}
	var file := FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file == null: tree.quit(2);return
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	print("FINISH25I_ACTUAL_FIELDS ",output+"result.json")
	tree.quit(0 if report.complete else 1)


