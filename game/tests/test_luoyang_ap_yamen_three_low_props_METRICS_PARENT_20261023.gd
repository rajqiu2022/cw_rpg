extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Preparation only. Root alone may run a separately frozen successor.
## No inherited itinerary, geometry compilation, collector, portal trip or teleport.
const ACTUAL_READY: bool = false
const CONTRACT_PATH: String = "PENDING_ROOT_APPROVED_FINITE_YAMEN_CONTRACT"
const CONTRACT_SHA: String = "PENDING_INDEPENDENT_SOURCE_OWNER_AND_STATION_PROOF"
const YAMEN: StringName = &"ch4_s1_luoyang_yamen"
const WHOLE_MS: int = 60000
const ARRIVAL_MS: int = 60000 # Also capped by WHOLE; never an added minute.
const MAX_PICTURES: int = 2
const INPUT := preload("res://tests/helpers/v15_input_driver.gd")
const C := preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
var contract: Dictionary = {}
var own_field: Node
var own_scene: SceneScript
var own_player: CharacterBody2D
var input_driver: RefCounted
var requested_usec: int = 0
var ready_fact: Dictionary = {}
var draw_fact: Dictionary = {}
var first_input_fact: Dictionary = {}
var last_matching_profile: Dictionary = {}
var pictures: Array[Dictionary] = []

func precheck() -> bool:
	if not check(ACTUAL_READY, "NOTREADY: finite consumers, independent owners and local stations not frozen"): return false
	# No resource discovery/current-SHA expectation. A successor must replace
	# BOTH constants and freeze the exact native/session/source-owner contract.
	if not track(CONTRACT_PATH, CONTRACT_SHA): return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CONTRACT_PATH))
	if not check(parsed is Dictionary and parsed.get("ready") == true, "Exact approved finite Yamen contract"): return false
	contract = parsed
	if not check(contract.get("whole_ms") == WHOLE_MS and contract.get("arrival_ms") == ARRIVAL_MS and contract.get("max_pictures") == MAX_PICTURES, "Original sixty-second cap and two images maximum"): return false
	if not check(OS.get_cmdline_user_args().is_empty() and DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0, "Ordinary public setup, no candidate flags"): return false
	for path: String in contract.source_sha256:
		if not track(path, contract.source_sha256[path]): return false
	return check(false, "Draft intentionally has no approved local executor/API; do not enable this file")

func _clock_fact() -> Dictionary:
	return {"usec": Time.get_ticks_usec(), "process_frame": Engine.get_process_frames(), "physics_frame": Engine.get_physics_frames()}

func _observe_readonly() -> void:
	if requested_usec <= 0: return
	var router: Node = root.get_node("SceneRouter")
	var lm: Node = root.get_node("LoadingManager")
	var active_owner: int = int(router.call("live_field_transition_token", YAMEN))
	var profile: Dictionary = C.transition_validation_state()
	# Sample only immutable copied scalar/maps, never running worker output.
	# Do not borrow stale timings after reset/token0, or claim missing as zero.
	if active_owner > 0 and profile.get("active") == true and profile.get("live_scope") == true and profile.get("scene_id") == String(YAMEN) and profile.get("token") == active_owner:
		last_matching_profile = {"captured": _clock_fact(), "same_live_owner": active_owner, "C": profile.duplicate(true)}
		var preload_metrics: Dictionary = lm.call("get_field_preload_metrics")
		if preload_metrics.get("scene_id") == String(YAMEN): last_matching_profile["LM"] = preload_metrics.duplicate(true)
	if not is_instance_valid(current_scene) or not current_scene.has_method("get_field_loading_state"): return
	var state: Dictionary = current_scene.call("get_field_loading_state")
	var scene: SceneScript = current_scene.get("_current_scene") as SceneScript
	var player: CharacterBody2D = current_scene.get("_player") as CharacterBody2D
	if scene == null or scene.scene_id != YAMEN or player == null: return
	if ready_fact.is_empty() and state.get("complete") == true and not state.get("failed", false) and player.can_process() and player.get("can_move") == true:
		ready_fact = _clock_fact()
		ready_fact.merge({"Field": current_scene.get_instance_id(), "Scene": scene.get_instance_id(), "Player": player.get_instance_id(), "loading_state": state.duplicate(true), "elapsed_usec": int(ready_fact.usec) - requested_usec})

func _post_draw_readonly() -> void:
	if requested_usec <= 0 or not draw_fact.is_empty() or not is_instance_valid(current_scene): return
	var scene: SceneScript = current_scene.get("_current_scene") as SceneScript
	var player: CharacterBody2D = current_scene.get("_player") as CharacterBody2D
	if scene == null or scene.scene_id != YAMEN or player == null or not player.can_process() or player.get("can_move") != true: return
	var state: Dictionary = current_scene.call("get_field_loading_state")
	var lm: Node = root.get_node("LoadingManager")
	var screen: Node = lm.get("_screen")
	var panel: Control = screen.get("root") as Control if is_instance_valid(screen) else null
	if state.get("complete") != true or state.get("failed", false) or (panel != null and panel.is_visible_in_tree()) or lm.get("_external_active") == true or lm.get("_transition_active") == true: return
	if C._resident_ready.get("scene") != scene or C._resident_ready.get("sources_finalized") != true: return
	# Freeze first-postdraw cheap scalar before hashes, copied receipt or images.
	draw_fact = _clock_fact()
	draw_fact.merge({"elapsed_usec": int(draw_fact.usec) - requested_usec, "Field": current_scene.get_instance_id(), "Scene": scene.get_instance_id(), "Player": player.get_instance_id(), "foot": player.position, "loading_hidden_inactive": true, "can_move": true})

func _request_default_yamen() -> bool:
	requested_usec = Time.get_ticks_usec()
	# null means production default; no near setup/source UV or authored shortcut.
	if not check(root.get_node("SceneRouter").call("go_field_smart", YAMEN, null), "One real public default Yamen request"): return false
	while Time.get_ticks_msec() < mini(deadline, int(requested_usec / 1000) + ARRIVAL_MS):
		_observe_readonly()
		var public_state: Dictionary = root.get_node("SceneRouter").call("get_public_city_preparation_state")
		if public_state.get("scene_id") == String(YAMEN) and public_state.get("phase") == "FAILED":
			records.append({"kind": "TERMINAL_REQUEST_FAILURE", "public": public_state, "C_errors": C.errors(), "timing": last_matching_profile})
			return check(false, "Default Yamen request failed; no success duration")
		if not draw_fact.is_empty():
			own_field = current_scene; own_scene = own_field.get("_current_scene") as SceneScript; own_player = own_field.get("_player") as CharacterBody2D
			records.append({"kind": "ONE_LEG_TIMING", "request_usec": requested_usec, "ready": ready_fact, "firstdraw": draw_fact, "last_matching_active_profile": last_matching_profile, "profile_after_draw": C.transition_validation_state(), "missing_or_reset_is_not_zero_or_fresh": true})
			return true
		await process_frame
	return check(false, "Original sixty-second scope/arrival exhausted")

func _actual_body_query(at: Vector2) -> Array[Dictionary]:
	var shape: CollisionShape2D = own_player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape == null or not shape.shape is RectangleShape2D or (shape.shape as RectangleShape2D).size != Vector2(34, 24) or shape.disabled: return [{"invalid_original_player_body": true}]
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape.shape; query.transform = shape.global_transform
	query.transform.origin += at - own_player.position
	query.collision_mask = own_player.collision_mask; query.exclude = [own_player.get_rid()]
	query.collide_with_areas = false
	return own_player.get_world_2d().direct_space_state.intersect_shape(query, 16)

func _attempt_north_front(prop_id: String, forbidden_foot: Vector2) -> bool:
	# Call only after a frozen source-backed front route was reached by INPUT.
	var before: Vector2 = own_player.position
	var negative: Array[Dictionary] = _actual_body_query(forbidden_foot)
	var actual_samples: Array[Vector2] = []
	Input.action_press("move_up")
	for tick: int in 24: # Bounded attempt, NOT a preclaimed observed sample count.
		await physics_frame
		if Time.get_ticks_msec() >= deadline or not is_instance_valid(own_player): break
		actual_samples.append(own_player.position)
		if not _actual_body_query(own_player.position).is_empty():
			input_driver.release_movement(); return check(false, "Stopped original body must remain nonintersecting")
	input_driver.release_movement(); await input_driver.completed_actor_stage()
	if first_input_fact.is_empty(): first_input_fact = _clock_fact()
	# The frozen successor must bind negative collider RID/ID to this prop and
	# compare stopped foot against its independent source polygon. Not 'any hit'.
	records.append({"kind": "LOCAL_FRONT_ATTEMPT_PENDING_EXACT_PROP_NEGATIVE_BIND", "id": prop_id, "before": before, "after": own_player.position, "observed_samples": actual_samples, "negative_hit_count": negative.size()})
	return check(false, "Pending exact prop collider/source polygon assertion; no blocked-body credit yet")

func _ghost_and_opacity_readonly(prop: Sprite2D, prop_id: String) -> Dictionary:
	var overlap: RefCounted = own_field.get("_v14_modular_overlap")
	var debug: Dictionary = overlap.call("get_debug_state") if overlap != null and overlap.has_method("get_debug_state") else {}
	var actor: Sprite2D = own_player.get("sprite") as Sprite2D
	var ghost: Sprite2D = own_player.get_node_or_null("BuildingOverlapGhost") as Sprite2D
	var alpha_chain: Array[Dictionary] = []
	var item: Node = prop
	while item != null and item != root:
		if item is CanvasItem: alpha_chain.append({"node": item.name, "modulate_alpha": (item as CanvasItem).modulate.a, "self_modulate_alpha": (item as CanvasItem).self_modulate.a})
		item = item.get_parent()
	return {"id": prop_id, "foot": own_player.position, "active": debug.get("active"), "space": debug.get("space"), "pixels": debug.get("pixels"), "prop_hits": debug.get("prop_hits"), "actor_texture_id": debug.get("actor_texture_id"), "ghost_visible": ghost != null and ghost.visible, "ghost_material_present": ghost != null and ghost.material != null, "actor_base_alpha": actor.modulate.a if actor != null else -1, "prop_alpha_chain": alpha_chain, "fade_ids": overlap.get("_fade_ids").duplicate() if overlap != null else []}

func _capture_representative(label: String) -> bool:
	if not check(label in ["desk_behind_actor_local", "bench_front_opaque"] and pictures.size() < MAX_PICTURES, "Only two predeclared representative images"): return false
	await RenderingServer.frame_post_draw
	var path: String = contract.output_path.path_join(label + ".png")
	var image: Image = root.get_texture().get_image()
	if not check(image != null and not FileAccess.file_exists(path) and image.save_png(path) == OK, "One ordinary existing-camera capture"): return false
	pictures.append({"label": label, "path": path, "sha256": FileAccess.get_sha256(path)})
	return true

func exercise_cpu() -> bool:
	# Deliberately not inherited CPU work. No C/RAW geometry or source collector.
	return check(false, "Pending Root-approved exact consumer/owner/local-route fixture and executor")

func _run() -> void:
	var began: int = Time.get_ticks_msec(); deadline = began + WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended", true); players_before = saves()
	var complete: bool = false
	# Even accidental execution cannot issue a request while ACTUAL_READY=false.
	if precheck(): complete = await exercise_cpu()
	if input_driver != null: input_driver.release()
	if RenderingServer.frame_post_draw.is_connected(_post_draw_readonly): RenderingServer.frame_post_draw.disconnect(_post_draw_readonly)
	finish("res://build/luoyang_city_full_rollout_20261022ap_qa01/yamen_low_props_DRAFT_NOTREADY/%d_%d" % [OS.get_process_id(), began], began, complete, "NOTREADY_PREPARATION_ONLY_NO_ACTUAL_CREDIT")
