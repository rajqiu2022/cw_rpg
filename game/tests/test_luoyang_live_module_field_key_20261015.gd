extends "res://tests/test_world_luoyang_gate_normal_roundtrip_retry2_20261014.gd"
## NEW actual Field key: Gate+Market live-module loading, Yamen setup only.
## No fake route, old-case budget changes, full-city/six/world rebuild or audio QA.
const MARKET = preload("res://scripts/city/luoyang_market_enrichment_contract_20261014.gd")
const NEW_PINS := {
	"res://scripts/city/luoyang_market_enrichment_contract_20261014.gd": "a77ada38fc93debbe0d1c904d4976760fd2bcabda22be21fa116c17896ea208a",
	"res://data/scenes/ch4_s1_luoyang_yamen.tres": "5a0c1124a4166087573a1d4d6bc217e496251856cb88a60b6f78ba04019c12f5",
	"res://tests/helpers/v15_raw_world_oracle.gd": "c58043373af6154d5f7f79cfa2d0e8dcda38f3fbe0c6648a4af4ce626e8a9c51",
	"res://tests/test_world_luoyang_gate_normal_roundtrip_retry2_20261014.gd": "a7fce73af15d31c171e9bba8f8e34772204830637fbea87c29395f6b40b497b8",
	"res://scripts/autoload/save_manager.gd": "67c06cd14d6a7c0bbfd7467bbaae84f906aad57b19cabc0902baf80eb3aff7d9",
	"res://scripts/world/world_map_v15_contract.gd": "c10efd8bfeca980325ac0d8d4dcd99a03f5d01aba636efabc524a1cb9f43def8",
	"res://scripts/field/player.gd": "9f283beaa3f8c3c3b5eb36547627e5414d91722078dfc00d08bf2f07f2910419",
	"res://data/scenes/ch4_s3_luoyang_market.tres": "2df5059ab647d956e7b37c8bb5f7d0d568d575deac7931b3ccadb5451c6fe8f6",
	"res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd": "7628d404d7587dfd885937ad1e26ac6a06f4e48ca53c273ccd8d5f1aee5db9db",
	"res://scripts/city/luoyang_gate_fortification_contract_20261013.gd": "e510d3faf993ceeca6c321a1c0d94c5a1fab86a4393f41a588ba766f821c3171",
	"res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd": "6ad7b6be15fd23ea4f8356c111c5a5a6c54c8e1ec7496083597d01e904711c62",
	"res://tests/test_luoyang_four_city_key_smoke_20261012.gd": "65508b636a699dad0cdd73543aea02a06b9730979666191d570e5fe13cab0ba5",
	"res://tests/helpers/v15_input_driver.gd": "a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://data/scenes/world_map_jianghu.tres": "685876ac86cb3b739f9b51be12da60e4a125480c715da2d08f9b486d76e5a046",
	"res://scripts/autoload/platform_bridge.gd": "eec9dd3cc56e310c436ff542e3ed4228c9f7216be8608b6959c69717718c500a",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd": "ec0ea7b63674f5660924a19c26890015cbd855f176c2a66ef301e29694eace04",
	"res://scripts/autoload/scene_router.gd": "a51f2b769cca1d9541a890c5b31ef75fd240fcb7f70bad1b8e401b117ea0cbff",
	"res://data/scenes/ch4_s0_luoyang_gate.tres": "00d0867a56efec29aa509b4366546c8dfbcc2f4d9a73d062acfa756a2252a581",
	"res://tests/helpers/v15_field_raw_oracle.gd": "dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb",
	"res://scripts/ui/loading_screen.gd": "60a8bade4696dc3b8d0736561bd0a6c19ccc4637540a0fcca366171d0c9850da",
	"res://scripts/autoload/loading_manager.gd": "b427b1098e00627c4a82e62f2f23dde102ed7f8836748760b945df507183322d",
	"res://tests/test_luoyang_gate_fortification_field_key_20261013.gd": "64be58e1f0e1fccdece808a91d81b82e9e5dc41a71e746caae95d35ec7cb249b",
	"res://scripts/city/luoyang_module_live_cpu_20261015.gd": "780af073facaba7a5dc469df5de6bca1b6c698c2b95a85c1389511d900b2a63e",
	"res://scripts/field/field_walkable_controller.gd": "7c4ec636ef2cf995b428acecb4c4e237901207543fc1b5aeb3b77a4385695c8a"
}
const SCOPE := "KEY_GATE_AND_MARKET_LIVE_MODULE_PLUS_YAMEN_SETUP_ONLY_20261015"
const NEW_BUDGET_MS := 240000
var live_started: int
var observation_tag := "source_precheck"
var observation_target := ""
var tag_started_usec := 0
var previous_frame_usec := 0
var tag_stats: Dictionary = {}
var module_stats: Dictionary = {}
var module_receipts: Dictionary = {}
var progress_samples: Array[Dictionary] = []
var prior_progress_key := ""
var loading_captures: Array[Dictionary] = []
var loading_capture_requested: Dictionary = {}
var loading_capture_pending := 0
var observe_live := false

func _tag(tag: String, target: String) -> void:
	observation_tag = tag; observation_target = target
	tag_started_usec = Time.get_ticks_usec(); previous_frame_usec = tag_started_usec
	if not tag_stats.has(tag): tag_stats[tag] = {"target":target,"frames":0,"max_gap_usec":0,"opaque_frames":0,"first_progress":-1.0,"last_progress":-1.0,"distinct_progress":{},"public_call_ms":-1,"elapsed_ms":0}
	prior_progress_key = ""

func _finish_tag() -> void:
	if tag_stats.has(observation_tag): tag_stats[observation_tag].elapsed_ms = (Time.get_ticks_usec() - tag_started_usec) / 1000.0

func _loading_snapshot() -> Dictionary:
	var manager: Node = root.get_node("LoadingManager")
	var screen: Node = manager.get("_screen") as Node
	var panel: Control = screen.get("root") as Control if is_instance_valid(screen) else null
	var progress: ProgressBar = screen.get("progress_bar") as ProgressBar if is_instance_valid(screen) else null
	var stage: Label = screen.get("stage_label") as Label if is_instance_valid(screen) else null
	var percent: Label = screen.get("percent_label") as Label if is_instance_valid(screen) else null
	return {"visible":panel != null and panel.visible,"alpha":panel.modulate.a if panel != null else 0.0,"progress":progress.value if progress != null else -1.0,"stage":stage.text if stage != null else "NO_SCREEN","percent":percent.text if percent != null else "","LM_transition":manager.get("_transition_active"),"LM_external":manager.get("_external_active")}

func _capture_live_loading(id: String) -> void:
	loading_capture_pending += 1
	await RenderingServer.frame_post_draw
	var snapshot := _loading_snapshot()
	var image: Image = root.get_texture().get_image()
	var path := output + "loading_" + id + ".png"
	var ok: bool = image != null and not image.is_empty() and image.save_png(path) == OK
	_check(ok and snapshot.visible and snapshot.alpha == 1.0, "Actual opaque Loading GPU capture " + id)
	loading_captures.append({"target":id,"path":path,"sha256":FileAccess.get_sha256(path) if ok else "","snapshot":snapshot,"frame":Engine.get_process_frames()})
	loading_capture_pending -= 1

func _live_frame() -> void:
	if not observe_live or not tag_stats.has(observation_tag): return
	var now := Time.get_ticks_usec()
	var gap := now - previous_frame_usec if previous_frame_usec > 0 else 0
	previous_frame_usec = now
	var stats: Dictionary = tag_stats[observation_tag]
	stats.frames += 1; stats.max_gap_usec = maxi(stats.max_gap_usec,gap)
	var loading := _loading_snapshot()
	if loading.visible and loading.alpha == 1.0: stats.opaque_frames += 1
	if float(loading.progress) >= 0.0:
		if float(stats.first_progress) < 0.0: stats.first_progress = loading.progress
		stats.last_progress = loading.progress
		stats.distinct_progress[str(roundi(loading.progress))] = true
	var state: Dictionary = C.transition_validation_state()
	var task: int = int(C.get("_live_module_task"))
	var job: RefCounted = C.get("_live_module_job") as RefCounted
	var phase := "non_module"
	var status: Dictionary = {}
	if job != null:
		status = job.call("status") # Mutex-protected scalars only; never _packet.
		phase = "module.worker." + String(status.get("phase","unknown")) if task >= 0 else "module.import.main"
	if observation_target in [GATE_ID,String(MARKET.ID)]:
		if not module_stats.has(observation_target): module_stats[observation_target] = {"worker_frames":0,"import_main_frames":0,"phases":{},"max_gap_by_phase_usec":{},"opaque_worker_frames":0,"progress_in_worker":{}}
		var module: Dictionary = module_stats[observation_target]
		if task >= 0 and job != null:
			module.worker_frames += 1; module.phases[String(status.get("phase","unknown"))] = true
			if loading.visible and loading.alpha == 1.0: module.opaque_worker_frames += 1
			module.progress_in_worker[str(roundi(loading.progress))] = true
			if not loading_capture_requested.has(observation_target) and loading.visible and loading.alpha == 1.0:
				loading_capture_requested[observation_target] = true
				_capture_live_loading(observation_target)
		elif job != null: module.import_main_frames += 1
		module.max_gap_by_phase_usec[phase] = maxi(int(module.max_gap_by_phase_usec.get(phase,0)),gap)
	var receipt: Dictionary = state.get("main_stage_timings",{}).get("module_live",{})
	var receipt_id: String = receipt.get("scene_id","")
	if receipt_id in [GATE_ID,String(MARKET.ID)] and not receipt.get("imports",[]).is_empty(): module_receipts[receipt_id] = receipt.duplicate(true)
	var key := observation_tag + "/" + String(loading.stage) + "/" + str(roundi(loading.progress)) + "/" + phase
	if key != prior_progress_key:
		progress_samples.append({"tag":observation_tag,"target":observation_target,"elapsed_ms":Time.get_ticks_msec()-live_started,"frame":Engine.get_process_frames(),"gap_usec":gap,"phase":phase,"worker_status":status,"loading":loading})
		prior_progress_key = key

func _transition_busy(manager: Node) -> bool:
	return int(C.get("_live_module_task")) >= 0 or C.get("_live_module_job") != null or super._transition_busy(manager)

func _wait_field(id: String) -> bool:
	var ok: bool = await super._wait_field(id) # Original full idle/60s/identity guards.
	if ok:
		var actual: SceneScript = field.get("_current_scene") as SceneScript
		_check(actual != null and actual.scene_id == StringName(id) and actual.resource_path == "res://data/scenes/" + id + ".tres", "Actual canonical Field identity " + id)
	return ok

func _module_assert(id: String, expected: Array[String]) -> void:
	var receipt: Dictionary = module_receipts.get(id,{})
	var observed: Dictionary = module_stats.get(id,{})
	var imports: Array = receipt.get("imports",[])
	var seen: Dictionary = {}
	var good: bool = receipt.get("scene_id") == id and receipt.get("full_source_pixel_geometry_checks_retained") == true and int(receipt.get("cpu_wait_frames",0)) > 0 and int(receipt.get("cpu_ms",-1)) >= 0 and imports.size() == expected.size()
	for row: Dictionary in imports:
		var path: String = row.get("path","")
		good = good and expected.has(path) and not seen.has(path) and row.get("full_RGBA_exact") == true and typeof(row.get("elapsed_usec")) == TYPE_INT and int(row.elapsed_usec) >= 0
		seen[path] = true
	_check(good, "Actual " + id + " live CPU and every main-thread fullRGBA import receipt")
	_check(int(observed.get("worker_frames",0)) > 0 and int(observed.get("opaque_worker_frames",0)) > 0 and observed.get("progress_in_worker",{}).size() > 1 and observed.get("phases",{}).has("module.source"), "Actual frames and changing opaque progress during " + id + " module CPU work")
	rows.append({"kind":"ACTUAL_LIVE_MODULE","id":id,"production_receipt":receipt,"frame_observation":observed,"source_and_geometry_not_skipped":true,"speed_or_smoothness_approved":false})

func _sources_market() -> bool:
	var original_reader: RefCounted = RAW.new()
	var original: Dictionary = original_reader.call("independent_record",MARKET.ID)
	original_reader.call("release")
	if not _check(not original.is_empty(),"Independent complete Market original source record"): return false
	var result: Dictionary = MARKET.read_after_original(original)
	if not _check(result.get("record") is Dictionary and not result.has("error"),"Independent full Market source/import/composition retained: " + String(result.get("error",""))): return false
	packet = result
	manifest = MARKET.runtime_manifest()
	return _check(packet.record.objects == manifest.objects and packet.record.gameplay_slots == manifest.gameplay_slots and packet.record.routes == manifest.routes,"Market full original gameplay and26 composed objects, not reused Gate proof")

func _bind() -> bool:
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	# The old World/Gate override intentionally only admitted those two IDs.
	# Keep the original city-only Yamen oracle here, without that Gate-only tail.
	if scene != null and String(scene.scene_id) == YAMEN_ID:
		if oracle != null: oracle.call("release"); oracle = null
		polygons.clear(); mask = null
		oracle = RAW.new()
		if not _check(scene.resource_path == "res://data/scenes/ch4_s1_luoyang_yamen.tres" and bool(oracle.call("configure_city",scene,true)),"Unchanged actual Yamen independent original reader"): return false
		mask = Image.load_from_file(scene.map_layout.walkable_mask_path)
		for solid: Dictionary in oracle.get("solids"):
			if solid.kind == "exact_world_polygon": polygons.append(solid.polygon)
			else:
				var rect: Rect2 = solid.rect
				polygons.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
		return _check(mask != null,"Yamen actual original full875 mask")
	if scene == null or scene.scene_id != MARKET.ID: return super._bind()
	if oracle != null: oracle.call("release"); oracle = null
	mask = null; polygons.clear()
	if not _check(MARKET.bound(scene) and scene.resource_path == "res://data/scenes/ch4_s3_luoyang_market.tres" and packet.get("record") is Dictionary,"Canonical actual enriched Market bound"): return false
	var declarations: Array[Dictionary] = []
	for object: Dictionary in packet.record.objects:
		var shapes: Array[PackedVector2Array] = []
		var extent := Vector2(object.collision_size_px[0],object.collision_size_px[1])
		if extent.x > 0 and extent.y > 0:
			var center := Vector2(object.physical_center_px[0],object.physical_center_px[1])
			var rect := Rect2(center-extent*.5,extent)
			shapes.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
		for source: Array in object.solid_polygons_px:
			var polygon := PackedVector2Array()
			for point: Array in source: polygon.append(Vector2(point[0],point[1]))
			if not _check(polygon.size() >= 3 and not Geometry2D.triangulate_polygon(polygon).is_empty(),"Market finite independent source solid"): return false
			shapes.append(polygon)
		for shape: PackedVector2Array in shapes: polygons.append(shape)
		if not shapes.is_empty(): declarations.append({"id":object.id,"solid_polygons_px":shapes})
	var owned: Resource = scene.map_layout.duplicate(true)
	owned.set("visual_objects",declarations)
	oracle = SIMPLE_RAW.new()
	var configured: bool = bool(oracle.call("configure",owned,"round_world_pixel",0.0))
	owned = null
	mask = Image.load_from_file(packet.record.walk_path)
	return _check(configured and mask != null and mask.get_size() == Vector2i(3072,2048) and scene.map_layout.walkable_mask_path == packet.record.walk_path,"Market independent875/full17/raw PNG and physical declarations")

func _ordinary_key() -> void:
	var world: SceneScript = ResourceLoader.load("res://data/scenes/world_map_jianghu.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not _check(world != null and WORLD.is_v15(world),"Original formal world setup definition"): return
	var portal: Dictionary = {}
	for item: Dictionary in world.map_layout.portals:
		if String(item.get("target_scene","")) == GATE_ID: portal = item
	if not _check(not portal.is_empty() and portal.get("pos") is Vector2,"One original world Luoyang portal"): return
	var entrance: Vector2 = portal.pos * WORLD.SIZE
	var setup := entrance + Vector2(0,96)
	_tag("WORLD_SETUP_ONLY",WORLD_ID)
	var call_started := Time.get_ticks_msec()
	var ok: bool = bool(root.get_node("SceneRouter").call("go_field_smart",StringName(WORLD_ID),setup/WORLD.SIZE,"",15))
	tag_stats[observation_tag].public_call_ms = Time.get_ticks_msec()-call_started
	if not _check(ok,"Legal nearGate public world birth setup, not long travel") or not await _wait_field(WORLD_ID) or not _bind(): return
	_finish_tag()
	var born: Vector2 = (field.get("_player") as Node2D).position
	if not _check(born.distance_to(setup)<.03 and _clear(born),"Original world setup birth full17/Physics"): return
	var approach: Dictionary = await _move(entrance)
	if not _check(approach.get("ok")==true,"Original normal INPUT96px world portal approach"): return
	rows.append({"kind":"WORLD_NORMAL96","input":approach,"foot":(field.get("_player") as Node2D).position,"raw17":oracle.call("foot_evidence",(field.get("_player") as Node2D).position),"Physics":_physical((field.get("_player") as Node2D).position),"setup_not_long_walk_credit":true})
	var gate_zone: Node
	for item: Node in field.get("_exit_nodes"):
		if String(item.get("target_scene_id")) == GATE_ID: gate_zone=item
	if not _check(gate_zone!=null and bool(gate_zone.get("_in_range")) and not bool(gate_zone.get("is_locked")),"Actual original world Gate portal overlap"): return
	_tag("GATE_LIVE_SPACE",GATE_ID)
	if not await _space_to(GATE_ID): return
	_finish_tag()
	_module_assert(GATE_ID,[GATE.ROOT+"floor.png",GATE.ROOT+"walk.png"])
	_tag("QA_GATE_FULL_SOURCE_ORACLE_NOT_LOADING_PERFORMANCE",GATE_ID)
	if not _sources_gate() or not _bind(): return
	var foot: Vector2 = (field.get("_player") as Node2D).position
	if not _check(foot.distance_to(Vector2(1536,1860))<.03 and _clear(foot),"Actual cold live Gate full875/17/Physics and exact original1860 birth"): return
	rows.append({"kind":"ACTUAL_GATE_FIELD","foot":foot,"raw875":_body_raw(foot),"raw17":oracle.call("foot_evidence",foot),"Physics":_physical(foot),"runtime":field.call("get_gate_fortification_state")})
	captures.append(await _capture_gate("actual_gate_after_live_space"))
	_finish_tag()
	var yamen: SceneScript = ResourceLoader.load("res://data/scenes/ch4_s1_luoyang_yamen.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var departure: Dictionary = {}
	if yamen != null:
		for item: Dictionary in yamen.map_layout.portals:
			if item.get("id") == "to_south_market": departure=item
	if not _check(not departure.is_empty() and departure.get("arrival_foot_px") == Vector2(300,1220),"Original Yamen toMarket legal source portal foot"): return
	_tag("YAMEN_PUBLIC_PORTAL_SETUP_ONLY_NOT_GATE_OR_MARKET_PERFORMANCE",YAMEN_ID)
	call_started = Time.get_ticks_msec()
	ok = bool(root.get_node("SceneRouter").call("go_field_smart",StringName(YAMEN_ID),Vector2(300,1220)/Vector2(3072,2048)))
	tag_stats[observation_tag].public_call_ms = Time.get_ticks_msec()-call_started
	if not _check(ok,"Explicit public Yamen legal portal setup, not Gate-toYamen travel") or not await _wait_field(YAMEN_ID) or not _bind(): return
	_finish_tag()
	foot = (field.get("_player") as Node2D).position
	if not _check(foot.distance_to(Vector2(300,1220))<.03 and _clear(foot),"Actual legal Yamen portal setup full875/17/Physics"): return
	var market_zone: Node
	for item: Node in field.get("_exit_nodes"):
		if String(item.get("target_scene_id")) == String(MARKET.ID): market_zone=item
	if not _check(market_zone!=null and bool(market_zone.get("_in_range")) and not bool(market_zone.get("is_locked")),"Actual original Yamen toMarket portal overlap"): return
	rows.append({"kind":"YAMEN_SETUP_ONLY","foot":foot,"raw875":_body_raw(foot),"raw17":oracle.call("foot_evidence",foot),"Physics":_physical(foot),"Gate_to_Yamen_travel_tested":false,"performance_credit":false})
	_tag("MARKET_LIVE_SPACE",String(MARKET.ID))
	if not await _space_to(String(MARKET.ID)): return
	_finish_tag()
	var expected: Array[String]=[MARKET.TEXTURE_ALIASES[MARKET.STREET],MARKET.TEXTURE_ALIASES[MARKET.STALL],MARKET.TEXTURE_ALIASES[MARKET.TREE],MARKET.ROOT+"walk.png"]
	_module_assert(String(MARKET.ID),expected)
	_tag("QA_MARKET_FULL_SOURCE_ORACLE_NOT_LOADING_PERFORMANCE",String(MARKET.ID))
	if not _sources_market() or not _bind(): return
	foot=(field.get("_player") as Node2D).position
	if not _check(foot.distance_to(Vector2(1536,770))<.03 and _clear(foot),"Actual live Market full875/17/Physics original770 portal birth"): return
	rows.append({"kind":"ACTUAL_MARKET_FIELD","foot":foot,"raw875":_body_raw(foot),"raw17":oracle.call("foot_evidence",foot),"Physics":_physical(foot),"fade":field.call("get_city_building_fade_debug")})
	captures.append(await _capture_gate("actual_market_after_live_space"))
	_finish_tag()

func _run() -> void:
	live_started=Time.get_ticks_msec(); deadline=live_started+NEW_BUDGET_MS
	output="res://build/luoyang_live_module_field_key_20261015/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"Checkpoints held before first await")
	players_before=_players(); prior_slot=int(root.get_node("SaveManager").get("active_slot"))
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"Unique live module actual Field key output")
	var args:=OS.get_cmdline_user_args()
	_check("--luoyang-live-module-field-key" in args and not "--world-v15-candidate" in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args and not GATE.FLAG in args and not MARKET.FLAG in args,"Ordinary formal key with no candidate flags")
	_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path()).to_lower()==ENGINE_SHA,"Actual installed GPU engine ordinary clock")
	for path: String in NEW_PINS:
		source_before[path]=_file(path)
		_check(source_before[path].exists and source_before[path].sha256==NEW_PINS[path],"Frozen current new/helper/legacy consumer "+path)
	source_before[get_script().resource_path]=_file(get_script().resource_path)
	for module: Script in [GATE,MARKET]:
		var published: Dictionary=module.call("runtime_manifest")
		_check(not published.is_empty() and published.get("asset_sha256") is Dictionary,"Exact existing module runtime manifest")
		for path: String in module.call("source_paths"):
			if not source_before.has(path): source_before[path]=_file(path)
		for path: String in published.get("asset_sha256",{}):
			if not source_before.has(path): source_before[path]=_file(path)
			_check(source_before[path].sha256==published.asset_sha256[path],"Existing complete published source/import catalog "+path)
	var cache: Dictionary=C.get("_records")
	_check(not cache.has(GATE_ID) and not cache.has(String(MARKET.ID)),"Fresh process module caches empty; not OS disk-cold claim")
	driver=INPUT_DRIVER.new(); driver.call("configure",self)
	if failures==0:
		for id: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(id).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		observe_live=true; process_frame.connect(_live_frame)
		await _ordinary_key()
	observe_live=false
	if process_frame.is_connected(_live_frame): process_frame.disconnect(_live_frame)
	while loading_capture_pending>0 and Time.get_ticks_msec()<deadline: await process_frame
	if oracle!=null:
		_check(bool(oracle.call("verify_sources")),"Final independent raw navigation sources unchanged")
		oracle.call("release"); oracle=null
	mask=null; polygons.clear(); packet.clear(); manifest.clear()
	if driver!=null: driver.call("release"); driver=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	_check(_sources()==source_before and _players()==players_before and root.get_node("SaveManager").get("active_slot")==prior_slot and bridge.call("is_checkpoint_saves_suspended")==true,"All source/player15/slot guards unchanged, checkpoints held to quit; ROOT exactticks")
	_check(Time.get_ticks_msec()<deadline and transitions.size()==2 and captures.size()==2 and loading_captures.size()==2 and module_receipts.has(GATE_ID) and module_receipts.has(String(MARKET.ID)),"NEW single shared240/arrival60 two real Space/live module Field receipts complete")
	var result: Dictionary={"scope":SCOPE,"complete":failures==0,"checks":checks,"failures":failures,"records":rows,"transitions":transitions,"arrival_observations":observations,"loading_progress_samples":progress_samples,"per_tag_timings":tag_stats,"module_frame_observations":module_stats,"actual_module_receipts":module_receipts,"Field_captures":captures,"Loading_captures":loading_captures,"elapsed_ms":Time.get_ticks_msec()-live_started,"budget_ms":NEW_BUDGET_MS,"each_arrival_ms":60000,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"world_long_walk_tested":false,"Gate_to_Yamen_travel_tested":false,"Yamen_setup_excluded_from_Gate_Market_performance":true,"QA_full_source_oracle_tags_excluded_from_loading_performance":true,"cold_scope":"Fresh process C module caches; OS file cache not controlled","full_six_or_full_city_completion_credit":false,"loading_speed_or_smoothness_approved":false,"audio_credit":false,"ROOT_outer_exactticks_and_complete_stderr_review_required":true}
	_save_evidence("result.json",result)
	print("LUOYANG_LIVE_MODULE_FIELD_KEY_RESULT="+output+"result.json checks="+str(checks)+" failures="+str(failures)+" elapsed_ms="+str(result.elapsed_ms))
	quit(0 if failures==0 else 1)
