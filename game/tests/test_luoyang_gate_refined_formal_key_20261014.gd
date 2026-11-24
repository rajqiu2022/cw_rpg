extends "res://tests/test_luoyang_gate_refined_fortification_field_key_20261014.gd"
## Formal no-flags deployment only: source/spawn/one Space round trip, one GPU PNG.
## The prior six geometry cases are NOT rerun or credited as new cases here.
const FORMAL_SOURCE_READY := true
const FORMAL_PINS: Dictionary = {
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
	"res://data/scenes/ch4_s0_luoyang_gate.tres":"00d0867a56efec29aa509b4366546c8dfbcc2f4d9a73d062acfa756a2252a581",
}
const CANONICAL_GATE := "res://data/scenes/ch4_s0_luoyang_gate.tres"
const CANDIDATE_TEST := "res://tests/test_luoyang_gate_refined_fortification_field_key_20261014.gd"
const CANDIDATE_TEST_SHA := "bfe0ab16046bff03907dc899ebb48e3414ac37b03421a7b92089824d8e60ad99"

func _sources_gate() -> bool:
	if not super._sources_gate(): return false
	var canonical: SceneScript = ResourceLoader.load(CANONICAL_GATE,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var candidate: SceneScript = ResourceLoader.load(GATE.SCENE_PATH,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _check(canonical != null and candidate != null and canonical.resource_path == CANONICAL_GATE and candidate.resource_path == GATE.SCENE_PATH and canonical.scene_id == StringName(GATE_ID) and GATE.bound(canonical) and canonical.map_layout.resource_path == GATE.LAYOUT_PATH,"actual canonical resource path/meta/published layout"): return false
	if not _check(C._runtime_matches_expected(canonical,candidate),"canonical source complete spatial/story fields equal published candidate"): return false
	rows[-1].canonical_path = canonical.resource_path
	rows[-1].canonical_sha = FileAccess.get_sha256(CANONICAL_GATE)
	rows[-1].canonical_layout = canonical.map_layout.resource_path
	rows[-1].canonical_meta = canonical.get_meta(GATE.META)
	rows[-1].candidate_scene_sha = FileAccess.get_sha256(GATE.SCENE_PATH)
	return true

func _bind() -> bool:
	if not super._bind(): return false
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if String(scene.scene_id) != GATE_ID: return true
	return _check(scene.resource_path == CANONICAL_GATE and scene.map_layout.resource_path == GATE.LAYOUT_PATH and GATE.bound(scene),"real current Field consumes canonical Gate, not candidate routing")

func _exercise_gate() -> void:
	if not _sources_gate(): return
	if not _check(bool(root.get_node("SceneRouter").call("go_field_smart",StringName(GATE_ID),null,"",-1,3)),"public no-flags canonical Gate startup"): return
	if not await _wait_field(GATE_ID) or not _bind(): return
	var player: Node2D = field.get("_player") as Node2D
	_check(player.position.distance_to(Vector2(1536,1860)) < .03 and _clear(player.position),"formal original spawn1860 full875/full17/Physics")
	rows.append({"kind":"REAL_FORMAL_GATE_SPAWN","position":player.position,"runtime_path":(field.get("_current_scene") as SceneScript).resource_path,"raw17":oracle.call("foot_evidence",player.position),"raw875":_body_raw(player.position),"Physics":_physical(player.position),"runtime":field.call("get_gate_fortification_state")})
	var approach: Dictionary = await _move(Vector2(1536,560))
	if not _check(approach.get("ok") == true,"normal formal approach for one actual GPU view"): return
	gallery.append({"kind":"FORMAL_GATE_GPU","movement":approach,"image":await _capture_gate("formal_gate_before_portal")})
	_save_gallery()
	await _trip("space")
	if failures != 0: return
	var module: RefCounted = field.get("_gate_moat_runtime") as RefCounted
	var state: Dictionary = field.call("get_gate_fortification_state")
	weak_runtime = weakref(module); viewport_ids = [int(state.reflection_viewport_id),int(state.water_viewport_id)]; module = null

func _run() -> void:
	var platform: Node = root.get_node("PlatformBridge")
	platform.call("set_checkpoint_saves_suspended",true)
	_check(platform.call("is_checkpoint_saves_suspended") == true,"checkpoint held before first await")
	players_before = _players(); prior_slot = int(root.get_node("SaveManager").get("active_slot"))
	prior_navigation = (root.get_node("SceneRouter").call("get_navigation_state") as Dictionary).duplicate(true)
	output = "res://build/joint_world_luoyang_20261003_qa/gate_refined_formal_key_%d_%d/" % [OS.get_process_id(),Time.get_ticks_usec()]
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output)) == OK,"new formal output")
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_check(FORMAL_SOURCE_READY and not FORMAL_PINS.is_empty() and "--luoyang-gate-refined-formal-key" in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args and not GATE.FLAG in args,"hard no-three-candidate-flags formal mode")
	for path: String in FORMAL_PINS:
		source_before[path] = _file(path)
		_check(source_before[path].sha256 == FORMAL_PINS[path],"exact current formal source " + path)
	for path: String in [OLD_KEY,OLD_WALL,ENTRY_PARENT,CANDIDATE_TEST]: source_before[path] = _file(path)
	_check(source_before[OLD_KEY].sha256 == OLD_KEY_SHA and source_before[OLD_WALL].sha256 == OLD_WALL_SHA and source_before[ENTRY_PARENT].sha256 == ENTRY_PARENT_SHA and source_before[CANDIDATE_TEST].sha256 == CANDIDATE_TEST_SHA,"four immutable prior QA helpers")
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
	_check(rows.size() == 3 and gallery.size() == 1,"three formal receipts/one GPU, no repeated geometry or Mouse")
	var result: Dictionary = {"scope":"FORMAL_NOFLAGS_GATE_SOURCE_SPAWN_SPACE_NOT_SIX","complete":failures == 0,"checks":checks,"failures":failures,"records":rows,"gallery":gallery,"arrival_observations":arrival_observations,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"candidate_flags_present":false,"audio_driver":AudioServer.get_driver_name(),"audio_credit":false,"NPC_dialogue_tested":false,"full_rgba_occlusion_tested":false,"whole_geometry_retested":false,"loading_speed_approved":false,"full_formal_release_approved":false}
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	_check(file != null,"write final finite formal evidence")
	if file != null: file.store_string(JSON.stringify(_values(result),"\t")); file.close()
	print("REFINED_GATE_FORMAL_KEY_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures == 0 else 1)
