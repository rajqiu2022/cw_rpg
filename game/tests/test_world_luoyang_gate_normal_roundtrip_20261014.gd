extends "res://tests/test_luoyang_gate_fortification_field_key_20261013.gd"
## NEW one no-flags ordinary World->Gate->World trip. No all-city/full-six work.
## A legal public world birth 96px below the original entrance is setup only.
const WORLD = preload("res://scripts/world/world_map_v15_contract.gd")
const WORLD_RAW = preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const WORLD_ID := "world_map_jianghu"
const CURRENT_WORLD_GATE_PINS: Dictionary = {
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"4a7f23c2870fe7e0a8c06a283b4f9fd282f59b1b6b4b5abeb5f8fb5632cc9fa3",
	"res://scripts/field/field_walkable_controller.gd":"7c4ec636ef2cf995b428acecb4c4e237901207543fc1b5aeb3b77a4385695c8a",
	"res://scripts/city/luoyang_gate_fortification_contract_20261013.gd":"555231ce56d7726e16efcf0f50df3481b1ed1b8a13009ac80084495ea102c9cd",
	"res://scripts/city/luoyang_gate_moat_runtime_20261013.gd":"c8fff51978af6a60c571d37fd1da98ea92205fdb9b4d874b40a535ec5f61643f",
	"res://scripts/city/luoyang_gate_fortification_fade_20261013.gd":"26fc78af0e48b497da81940b1b64ed336cd12dec489c67c8810ef980aab91ad6",
	"res://scripts/autoload/loading_manager.gd":"38fce81dd6b397fc171a13f142f8032b7de1c76687654e09fb6fe27738f00e77",
	"res://scripts/autoload/scene_router.gd":"a51f2b769cca1d9541a890c5b31ef75fd240fcb7f70bad1b8e401b117ea0cbff",
	"res://scripts/autoload/platform_bridge.gd":"eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a",
	"res://scripts/autoload/save_manager.gd":"67c06cd14d6a7c0bbfd7467bbaae84f906aad57b19cabc0902baf80eb3aff7d9",
	"res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://scripts/world/world_map_v15_contract.gd":"c10efd8bfeca980325ac0d8d4dcd99a03f5d01aba636efabc524a1cb9f43def8",
	"res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd":"7628d404d7587dfd885937ad1e26ac6a06f4e48ca53c273ccd8d5f1aee5db9db",
	"res://tests/helpers/v15_raw_world_oracle.gd":"c58043373af6154d5f7f79cfa2d0e8dcda38f3fbe0c6648a4af4ce626e8a9c51",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd":"6ad7b6be15fd23ea4f8356c111c5a5a6c54c8e1ec7496083597d01e904711c62",
	"res://tests/helpers/v15_field_raw_oracle.gd":"dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb",
	"res://tests/test_luoyang_gate_fortification_field_key_20261013.gd":"64be58e1f0e1fccdece808a91d81b82e9e5dc41a71e746caae95d35ec7cb249b",
	"res://tests/test_luoyang_four_city_key_smoke_20261012.gd":"65508b636a699dad0cdd73543aea02a06b9730979666191d570e5fe13cab0ba5",
	"res://data/scenes/world_map_jianghu.tres":"685876ac86cb3b739f9b51be12da60e4a125480c715da2d08f9b486d76e5a046",
	"res://data/maps/world_map_jianghu_layout_v15.tres":"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
	"res://data/background_sets/world_map_jianghu_v15_streamed.tres":"3536182ec4eba967e8cd6b5da6b8ca6bb44072022f342d190eb807995a772400",
	"res://data/scenes/ch4_s0_luoyang_gate.tres":"00d0867a56efec29aa509b4366546c8dfbcc2f4d9a73d062acfa756a2252a581",
	"res://art/maps/luoyang_gate_fortification_v3_refined/runtime_manifest.json":"6800370f5d343c8212332f497990ee50e4ea0dfb2002319794ed9a69f72009d0",
}
var transitions: Array[Dictionary] = []
var observations: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var source_world_foot := Vector2(INF,INF)

func _save_evidence(name: String, value: Variant) -> bool:
	var file: FileAccess = FileAccess.open(output+name,FileAccess.WRITE)
	if file == null: return _check(false,"write immediate transition evidence")
	file.store_string(JSON.stringify(_values(value),"\t")); file.close()
	return true

func _observe(target: String, reason: String, started: int) -> void:
	var manager: Node = root.get_node("LoadingManager")
	var actual: Node = current_scene
	var scene: SceneScript = actual.get("_current_scene") as SceneScript if is_instance_valid(actual) and actual.scene_file_path == "res://scenes/field_walkable.tscn" else null
	var player: Node = actual.get("_player") as Node if scene != null else null
	var ready: Dictionary = actual.call("get_field_loading_state") if scene != null else {}
	var record: Dictionary = {"target":target,"reason":reason,"elapsed_ms":Time.get_ticks_msec()-started,"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames(),"actual_file":actual.scene_file_path if is_instance_valid(actual) else "NONE","actual_scene_id":String(scene.scene_id) if scene != null else "NONE","actual_Field_id":actual.get_instance_id() if scene != null else 0,"player_exists":is_instance_valid(player),"player_inside":player.is_inside_tree() if is_instance_valid(player) else false,"player_queued":player.is_queued_for_deletion() if is_instance_valid(player) else false,"Field_ready":ready,"LM_active":manager.get("_transition_active"),"LM_external_active":manager.get("_external_active"),"LM_token":manager.get("_external_token"),"LM_metrics":manager.call("get_field_preload_metrics"),"C_errors":C.errors(),"C_state":C.transition_validation_state(),"router_field_id":String(root.get_node("SceneRouter").call("get_current_field_id"))}
	observations.append(record)
	_save_evidence("transition_observations.json",observations)
	print("WORLD_GATE_OBSERVATION="+JSON.stringify(_values(record)))

func _wait_field(id: String) -> bool:
	var started: int = Time.get_ticks_msec()
	var end: int = mini(deadline,started+60000)
	_observe(id,"wait_begin_after_synchronous_input_or_public_call",started)
	var prior_signature := ""
	while Time.get_ticks_msec() < end:
		await process_frame
		var manager: Node = root.get_node("LoadingManager")
		var actual: Node = current_scene
		var scene: SceneScript = actual.get("_current_scene") as SceneScript if is_instance_valid(actual) and actual.scene_file_path == "res://scenes/field_walkable.tscn" else null
		var player: Node2D = actual.get("_player") as Node2D if scene != null else null
		var ready: Dictionary = actual.call("get_field_loading_state") if scene != null else {}
		var signature: String = str(manager.get("_transition_active"))+"|"+(String(scene.scene_id) if scene != null else "NONE")+"|"+str(ready)
		if signature != prior_signature:
			_observe(id,"state_changed",started); prior_signature = signature
		if bool(manager.get("_transition_active")): continue
		if scene != null and String(scene.scene_id) != id and ready.get("complete") == true:
			_observe(id,"wrong_ready_Field_after_loading_silent_rollback_or_rejection",started)
			return _check(false,"target rejected/rolled back to another ready Field "+id)
		if scene == null or String(scene.scene_id) != id or ready.get("complete") != true or ready.get("failed") == true or not is_instance_valid(player) or not player.is_inside_tree() or player.is_queued_for_deletion() or actual.is_queued_for_deletion() or bool(actual.get("_scene_rebuilding")): continue
		await driver.call("completed_actor_stage")
		if current_scene != actual or not is_instance_valid(actual) or bool(manager.get("_transition_active")) or actual.get("_player") != player or bool(actual.get("_scene_rebuilding")): continue
		field = actual
		_observe(id,"arrived",started)
		return true
	_observe(id,"arrival60_or_shared300_timeout_before_cleanup",started)
	return _check(false,"finite60s arrival/shared300s whole trip "+id)

func _bind() -> bool:
	if (field.get("_current_scene") as SceneScript).scene_id != StringName(WORLD_ID):
		if not super._bind(): return false
		var gate_scene: SceneScript = field.get("_current_scene") as SceneScript
		return _check(gate_scene.resource_path == "res://data/scenes/ch4_s0_luoyang_gate.tres" and GATE.bound(gate_scene),"actual canonical Gate not candidate routing")
	if oracle != null:
		_check(bool(oracle.call("verify_sources")),"previous independent source stable")
		oracle.call("release"); oracle = null
	mask = null; polygons.clear()
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	oracle = WORLD_RAW.new()
	return _check(scene.resource_path == "res://data/scenes/world_map_jianghu.tres" and WORLD.is_v15(scene) and bool(oracle.call("configure",scene.map_layout)),"ordinary formal world independent original navigation/physical sources")

func _clear(p: Vector2) -> bool:
	if Time.get_ticks_msec() >= deadline or oracle == null: return false
	var scene: SceneScript = field.get("_current_scene") as SceneScript if is_instance_valid(field) else null
	if scene != null and String(scene.scene_id) == WORLD_ID: return bool(oracle.call("clear",p)) and _physical(p)
	return super._clear(p)

func _space_to(target: String) -> bool:
	var started: int = Time.get_ticks_msec()
	_observe(target,"before_actual_Space",started)
	await driver.call("key",KEY_SPACE)
	var elapsed: int = Time.get_ticks_msec()-started
	transitions.append({"kind":"REAL_SPACE","target":target,"input_call_elapsed_ms":elapsed,"includes_synchronous_portal_preparation":true,"direct_router_shortcut":false})
	_observe(target,"after_actual_Space_return",started)
	_save_evidence("public_input_timings.json",transitions)
	return await _wait_field(target)

func _exercise_gate() -> void:
	var definition: SceneScript = ResourceLoader.load("res://data/scenes/world_map_jianghu.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _check(definition != null and WORLD.is_v15(definition),"actual formal world definition"): return
	var authored: Dictionary = {}
	for portal: Dictionary in definition.map_layout.portals:
		if String(portal.get("target_scene","")) == GATE_ID:
			if not authored.is_empty(): _check(false,"unique authored world Luoyang entrance"); return
			authored = portal
	if not _check(not authored.is_empty() and authored.get("pos") is Vector2,"original authored world Luoyang entry"): return
	var world_entry: Vector2 = authored.pos*WORLD.SIZE
	var setup: Vector2 = world_entry+Vector2(0,96)
	var started: int = Time.get_ticks_msec()
	var ok: bool = bool(root.get_node("SceneRouter").call("go_field_smart",StringName(WORLD_ID),setup/WORLD.SIZE,"",15))
	transitions.append({"kind":"PUBLIC_WORLD_SETUP","setup_foot":setup,"entry_foot":world_entry,"version":15,"public_call_elapsed_ms":Time.get_ticks_msec()-started,"legal_return_context_birth_only":true,"world_long_walk_credit":false})
	_save_evidence("public_input_timings.json",transitions)
	if not _check(ok,"public legal current15 world entrance-near birth") or not await _wait_field(WORLD_ID) or not _bind(): return
	var player: Node2D = field.get("_player") as Node2D
	if not _check(player.position.distance_to(setup) < .03 and _clear(player.position),"actual legal setup matches original world 17/Physics"): return
	var approach: Dictionary = await _move(world_entry)
	if not _check(approach.get("ok") == true,"normal original INPUT final96px world entrance approach"): return
	var zone: Node
	for item: Node in field.get("_exit_nodes"):
		if String(item.get("target_scene_id")) == GATE_ID: zone = item
	if not _check(zone != null and bool(zone.get("_in_range")) and not bool(zone.get("is_locked")),"actual world Luoyang unlocked portal overlap"): return
	source_world_foot = (field.get("_player") as Node2D).position
	rows.append({"kind":"WORLD_NORMAL_APPROACH","setup_is_not_long_walk_credit":true,"input":approach,"departure":source_world_foot,"raw17":oracle.call("foot_evidence",source_world_foot),"Physics":_physical(source_world_foot)})
	if not await _space_to(GATE_ID): return
	# Keep the full original source/import/third-layer geometry guards; no reuse bypass.
	if not _sources_gate() or not _bind(): return
	player = field.get("_player") as Node2D
	if not _check(player.position.distance_to(Vector2(1536,1860)) < .03 and _clear(player.position),"real World-to-Gate canonical birth1860 full875/full17/Physics, no rollback"): return
	rows.append({"kind":"REAL_GATE_ARRIVAL","foot":player.position,"raw875":_body_raw(player.position),"raw17":oracle.call("foot_evidence",player.position),"Physics":_physical(player.position),"gate_state":field.call("get_gate_fortification_state")})
	captures.append(await _capture_gate("actual_gate_after_world_space"))
	_save_evidence("gallery.json",captures)
	var back_approach: Dictionary = await _move(Vector2(1536,1800))
	if not _check(back_approach.get("ok") == true,"normal short departure away from Gate spawn"): return
	back_approach = await _move(Vector2(1536,1860))
	if not _check(back_approach.get("ok") == true,"normal original Gate return-world approach"): return
	var reverse: Node
	for item: Node in field.get("_exit_nodes"):
		if String(item.get("action")) == "world_map": reverse = item
	if not _check(reverse != null and bool(reverse.get("_in_range")),"actual original Gate return_world overlap"): return
	weak_runtime = weakref(field.get("_gate_moat_runtime"))
	var gate_state: Dictionary = field.call("get_gate_fortification_state")
	viewport_ids = [int(gate_state.reflection_viewport_id),int(gate_state.water_viewport_id)]
	if not await _space_to(WORLD_ID) or not _bind(): return
	var returned: Vector2 = (field.get("_player") as Node2D).position
	var release_ok: bool = weak_runtime.get_ref() == null and not is_instance_id_valid(viewport_ids[0]) and not is_instance_id_valid(viewport_ids[1])
	_check(returned.distance_to(source_world_foot) < .03 and _clear(returned) and release_ok,"normal Space returns to same original world entrance foot and releases Gate viewports")
	rows.append({"kind":"REAL_SPACE_ROUND_TRIP","departure":source_world_foot,"return":returned,"return_distance":returned.distance_to(source_world_foot),"raw17":oracle.call("foot_evidence",returned),"Physics":_physical(returned),"Gate_runtime_released":release_ok,"no_router_shortcuts":true})

func _run() -> void:
	var bridge: Node = root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	_check(bridge.call("is_checkpoint_saves_suspended") == true,"hold checkpoints before first await")
	players_before = _players(); prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	deadline = Time.get_ticks_msec()+300000
	output = "res://build/joint_world_luoyang_20261003_qa/world_gate_normal_trip_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK,"unique one-trip evidence")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_check("--world-gate-normal-trip" in args and not "--world-v15-candidate" in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args and not GATE.FLAG in args and not "--luoyang-market-enrichment-candidate" in args,"hard no candidate flags ordinary one trip")
	_check(DisplayServer.get_name() != "headless" and Engine.time_scale == 1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower() == ENGINE_SHA,"actual GPU installed engine ordinary clock")
	for path: String in CURRENT_WORLD_GATE_PINS:
		source_before[path] = _file(path)
		_check(CURRENT_WORLD_GATE_PINS[path].length() == 64 and source_before[path].sha256 == CURRENT_WORLD_GATE_PINS[path],"fresh exact executed source "+path)
	source_before[get_script().resource_path] = _file(get_script().resource_path)
	var gate_manifest: Dictionary = GATE.runtime_manifest()
	_check(not gate_manifest.is_empty() and gate_manifest.get("asset_sha256") is Dictionary,"original full Gate manifest")
	for path: String in GATE.source_paths(): source_before[path] = _file(path)
	for path: String in gate_manifest.get("asset_sha256",{}):
		if not source_before.has(path): source_before[path] = _file(path)
		_check(source_before[path].sha256 == gate_manifest.asset_sha256[path],"restored original full import/source catalog "+path)
	driver = INPUT_DRIVER.new(); driver.call("configure",self)
	if failures == 0:
		for id: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(id).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		await _exercise_gate()
	if oracle != null: _check(bool(oracle.call("verify_sources")),"final independent raw sources stable"); oracle.call("release"); oracle = null
	mask = null; polygons.clear(); packet.clear(); manifest.clear()
	if driver != null: driver.call("release"); driver = null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	# Owned process only: do not re-prepare every city via navigation restoration.
	_check(_sources() == source_before and _players() == players_before and root.get_node("SaveManager").get("active_slot") == prior_slot and bridge.call("is_checkpoint_saves_suspended") == true,"sources/player15/slot unchanged; root exactticks guard")
	_check(rows.size() == 4 and transitions.size() == 3 and captures.size() == 1,"one source/normal approach/birth/roundtrip, one public setup plus two real Space inputs")
	var result: Dictionary = {"scope":"ONE_NOFLAGS_WORLD_GATE_SPACE_ROUNDTRIP_NOT_FULL_WORLD_CITY","complete":failures == 0,"checks":checks,"failures":failures,"records":rows,"transitions":transitions,"observations":observations,"captures":captures,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"world_long_walk_credit":false,"full_six_tested":false,"full_gameplay_tested":false,"loading_speed_approved":false,"audio_driver":AudioServer.get_driver_name(),"audio_credit":false,"exactticks_guard":"ROOT_OUTER_REQUIRED"}
	_save_evidence("result.json",result)
	print("WORLD_GATE_NORMAL_TRIP_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures == 0 else 1)
