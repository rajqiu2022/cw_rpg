extends "res://tests/test_luoyang_gate_fortification_entry_diagnostic_20261013.gd"
## Six finite cases; reuse original normal INPUT/875/full17/Physics/4px helpers.
## Arrival90/shared270 is bounded diagnosis, never a loading-speed claim.
const REFINED_SOURCE_READY := true
const REFINED_PINS: Dictionary = {
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"48ed42a3f53b689b9ab27f825a9605732392f2015a26e8f21e3828af1bce34ca",
	"res://scripts/field/field_walkable_controller.gd":"94d87559b57e79264499f5a6bf387823d707f4f29e78aa9f6e4f180fd054cf8f",
	"res://scripts/city/luoyang_gate_fortification_contract_20261013.gd":"555231ce56d7726e16efcf0f50df3481b1ed1b8a13009ac80084495ea102c9cd",
	"res://scripts/city/luoyang_gate_moat_runtime_20261013.gd":"c8fff51978af6a60c571d37fd1da98ea92205fdb9b4d874b40a535ec5f61643f",
	"res://scripts/city/luoyang_gate_fortification_fade_20261013.gd":"26fc78af0e48b497da81940b1b64ed336cd12dec489c67c8810ef980aab91ad6",
	"res://scripts/dev/publish_luoyang_gate_fortification_v3_candidate_20261014.gd":"73086031162914885fd5490a5aaf4c05e58d5e8b48ff93d636544f88e27f5abe",
	"res://art/maps/luoyang_gate_fortification_v3_refined/gate_author_config.json":"0c51ebc73a11d1a7f4679f537c9f71511d58e976689abe5c1db46e8e5bbe45c2",
	"res://art/maps/luoyang_gate_fortification_v3_refined/runtime_manifest.json":"6800370f5d343c8212332f497990ee50e4ea0dfb2002319794ed9a69f72009d0",
	"res://data/scenes/luoyang_gate_fortification_v3_candidates/ch4_s0_luoyang_gate.tres":"00d0867a56efec29aa509b4366546c8dfbcc2f4d9a73d062acfa756a2252a581",
	"res://data/maps/luoyang_gate_fortification_v3_candidates/ch4_s0_luoyang_gate_layout.tres":"34b8689b51b3f7637a416e08bca7e069afa43bdf30bdd74654fd2c2dcd945e88",
	"res://art/maps/luoyang_gate_fortification_v3_refined/floor.png":"adb3a8dd26e7d3ba5ad6301f27a54d9d9d4fcb2ca940163571e2a39e8921b00e",
	"res://art/maps/luoyang_gate_fortification_v3_refined/walk.png":"d9a14f7a604d0dd31e0f250c9b4539920aaf4bdbf5c7eda809457cc266991df0",
	"res://tests/test_luoyang_four_city_key_smoke_20261012.gd":"65508b636a699dad0cdd73543aea02a06b9730979666191d570e5fe13cab0ba5",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd":"6ad7b6be15fd23ea4f8356c111c5a5a6c54c8e1ec7496083597d01e904711c62",
	"res://tests/helpers/v15_field_raw_oracle.gd":"dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb",
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://scripts/field/player.gd":"9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://scripts/autoload/scene_router.gd":"a51f2b769cca1d9541a890c5b31ef75fd240fcb7f70bad1b8e401b117ea0cbff",
	"res://scripts/autoload/platform_bridge.gd":"eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a",
	"res://scripts/autoload/save_manager.gd":"67c06cd14d6a7c0bbfd7467bbaae84f906aad57b19cabc0902baf80eb3aff7d9",
}
const ENTRY_PARENT := "res://tests/test_luoyang_gate_fortification_entry_diagnostic_20261013.gd"
const ENTRY_PARENT_SHA := "5098c466482e38ce69eb5e16b0c13cee3d2bb47aecd6c911bee386d78fb40f4d"
var fade_observations: Array[Dictionary] = []

func _move(point: Vector2) -> Dictionary:
	var actual: Dictionary = await super._move(point)
	if actual.get("ok") != true:
		var evidence: Dictionary = {"target":point,"msec":Time.get_ticks_msec(),"physics_frame":Engine.get_physics_frames(),"driver_receipt":actual}
		var file: FileAccess = FileAccess.open(output+"move_failure_%d.json" % Time.get_ticks_usec(),FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(_values(evidence),"\t")); file.close()
		_check(file != null,"immediate real move failure receipt")
		print("REFINED_GATE_MOVE_FAILURE="+JSON.stringify(_values(evidence)))
	return actual

func _observe_wall_fade(phase: String) -> void:
	var held: Node = field
	var player: Node2D = field.get("_player") as Node2D
	var end: int = mini(deadline,Time.get_ticks_msec()+250)
	while Time.get_ticks_msec() < end: await process_frame
	if not _check(is_instance_valid(held) and current_scene == held and held.get("_player") == player and is_instance_valid(player) and _clear(player.position),"live same Field/Player and clear foot after natural fade interval"): return
	var sprite: Sprite2D = field.find_child("SceneObject_gate_wall_950",true,false) as Sprite2D
	var debug: Dictionary = field.call("get_city_building_fade_debug")
	var matching: Array = (debug.get("buildings",[]) as Array).filter(func(r: Dictionary)->bool: return r.get("id") == "gate_wall_950")
	if not _check(sprite != null and matching.size() == 1,"same live wall950 native sprite and fade record"): return
	var record: Dictionary = matching[0]
	var base: Color = record.base_color
	var native: Color = sprite.self_modulate
	var hit: bool = record.hit == true
	var expected: float = .55 if hit else 1.0
	_check(base.a == 1.0 and sprite.modulate.a == 1.0 and var_to_bytes(native) == var_to_bytes(record.display_color) and absf(float(record.factor)-expected) < .000001 and absf(native.a-expected) < .000001,"actual wall950 hit implies native .55, no hit implies native1")
	if phase == "leave": _check(not hit and absf(float(record.factor)-1.0) < .000001 and absf(native.a-base.a) < .000001,"normal leave restores wall950 to base1")
	fade_observations.append({"phase":phase,"field_instance_id":field.get_instance_id(),"player_instance_id":(field.get("_player") as Node2D).get_instance_id(),"player_foot":(field.get("_player") as Node2D).position,"wall_instance_id":sprite.get_instance_id(),"wall_position":sprite.position,"wall_color_native_bytes":var_to_bytes(native).hex_encode(),"base_color_native_bytes":var_to_bytes(base).hex_encode(),"self_modulate_alpha":native.a,"hit":hit,"eligible":record.eligible,"factor":record.factor,"target":record.target,"process_frame":Engine.get_process_frames(),"physics_frame":Engine.get_physics_frames(),"msec":Time.get_ticks_msec(),"credit":"ONE_WALL_SAME_FRAME_NOT_FULL_RGBA"})
	var file: FileAccess = FileAccess.open(output+"wall_fade_observations.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(_values(fade_observations),"\t")); file.close()
	_check(file != null,"same-frame native wall fade evidence saved")

func _exercise_gate() -> void:
	if not _sources_gate(): return
	if not _check(bool(root.get_node("SceneRouter").call("go_field_smart",StringName(GATE_ID),null,"",-1,3)),"public actual refined candidate startup"): return
	if not await _wait_field(GATE_ID) or not _bind(): return
	var player: Node2D = field.get("_player") as Node2D
	_check(player.position.distance_to(Vector2(1536,1860)) < .03 and _clear(player.position),"original spawn1860 full875/full17/Physics")
	rows.append({"kind":"REAL_GATE_SPAWN","position":player.position,"raw17":oracle.call("foot_evidence",player.position),"raw875":_body_raw(player.position),"Physics":_physical(player.position),"runtime":field.call("get_gate_fortification_state")})
	var bridge: Dictionary = await _move(Vector2(1536,560))
	if not _check(bridge.get("ok") == true,"normal bridge crossing original INPUT/clearance"): return
	rows.append({"kind":"BRIDGE_DECK","input":bridge})
	gallery.append({"kind":"GATE_GPU","image":await _capture_gate("refined_gate_before_portal")})
	_save_gallery()
	var on_bridge: Dictionary = await _move(Vector2(1536,760))
	if not _check(on_bridge.get("ok") == true,"normal bridge viewpoint approach"): return
	gallery.append({"kind":"BRIDGE_GPU","movement":on_bridge,"image":await _capture_gate("refined_bridge_before_portal")})
	_save_gallery()
	await _stop_case("WATER_RAIL_STOP",Vector2(1536,760),Vector2(1450,760),"move_left")
	if failures != 0: return
	for point: Vector2 in [Vector2(1536,380),Vector2(1100,380)]:
		var approach: Dictionary = await _move(point)
		if not _check(approach.get("ok") == true,"original reachable wall-inner approach"): return
	await _stop_case("WALL_STOP",Vector2(1100,420),Vector2(1100,470),"move_down")
	if failures != 0: return
	await _observe_wall_fade("wall_stop")
	for point: Vector2 in [Vector2(1100,380),Vector2(1536,380)]:
		var leave: Dictionary = await _move(point)
		if not _check(leave.get("ok") == true,"normal leave from wall-inner side"): return
	await _observe_wall_fade("leave")
	if failures != 0: return
	await _trip("space")
	if failures != 0: return
	var module: RefCounted = field.get("_gate_moat_runtime") as RefCounted
	var state: Dictionary = field.call("get_gate_fortification_state")
	weak_runtime = weakref(module)
	viewport_ids = [int(state.reflection_viewport_id),int(state.water_viewport_id)]
	module = null

func _run() -> void:
	var platform: Node = root.get_node("PlatformBridge")
	platform.call("set_checkpoint_saves_suspended",true)
	_check(platform.call("is_checkpoint_saves_suspended") == true,"checkpoint held before first await")
	players_before = _players(); prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	prior_navigation = (root.get_node("SceneRouter").call("get_navigation_state") as Dictionary).duplicate(true)
	output = "res://build/joint_world_luoyang_20261003_qa/gate_refined_field_key_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK,"new refined output")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_check(REFINED_SOURCE_READY and not REFINED_PINS.is_empty() and "--luoyang-gate-refined-field-key" in args and GATE.FLAG in args and "--luoyang-v3-candidate" in args and "--luoyang-enclosure-v11-candidate" in args,"frozen explicit refined candidate flags")
	for path: String in REFINED_PINS:
		source_before[path] = _file(path)
		_check(source_before[path].sha256 == REFINED_PINS[path],"exact current executed source " + path)
	for path: String in [OLD_KEY,OLD_WALL,ENTRY_PARENT]: source_before[path] = _file(path)
	_check(source_before[OLD_KEY].sha256 == OLD_KEY_SHA and source_before[OLD_WALL].sha256 == OLD_WALL_SHA and source_before[ENTRY_PARENT].sha256 == ENTRY_PARENT_SHA,"three immutable original QA helpers")
	source_before[get_script().resource_path] = _file(get_script().resource_path)
	for path: String in GATE.source_paths(): source_before[path] = _file(path)
	driver = INPUT_DRIVER.new(); driver.call("configure",self)
	deadline = Time.get_ticks_msec()+270000
	if failures == 0:
		for id: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(id).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		await _exercise_gate()
	if oracle != null: _check(bool(oracle.call("verify_sources")),"raw source unchanged"); oracle.call("release"); oracle = null
	mask = null; polygons.clear(); packet.clear(); manifest.clear()
	if driver != null: driver.call("release"); driver = null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	if weak_runtime != null: _check(weak_runtime.get_ref() == null and not is_instance_id_valid(viewport_ids[0]) and not is_instance_id_valid(viewport_ids[1]),"final actual module/viewport release")
	root.get_node("SceneRouter").call("restore_navigation_state",prior_navigation,&"world_map_jianghu",&"world_map_jianghu")
	_check(_sources() == source_before and _players() == players_before and root.get_node("SaveManager").get("active_slot") == prior_slot,"source15/slot unchanged; exactticks outer root")
	_check(rows.size() == 6,"six finite receipts, no Mouse/NPC/full-six")
	var result: Dictionary = {"scope":"REFINED_GATE_SOURCE_SPAWN_BRIDGE_WATER_WALL_SPACE_NOT_SIX","complete":failures == 0,"checks":checks,"failures":failures,"records":rows,"gallery":gallery,"arrival_observations":arrival_observations,"wall_fade":fade_observations,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"audio_driver":AudioServer.get_driver_name(),"audio_credit":false,"NPC_dialogue_tested":false,"full_rgba_occlusion_tested":false,"formal_approved":false}
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	_check(file != null,"write final finite evidence")
	if file != null: file.store_string(JSON.stringify(_values(result),"\t")); file.close()
	print("REFINED_GATE_FIELD_KEY_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures == 0 else 1)
