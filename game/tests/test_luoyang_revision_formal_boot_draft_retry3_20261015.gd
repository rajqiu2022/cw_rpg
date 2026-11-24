extends "res://tests/test_luoyang_revision_market_rooms_key_retry3_20261015.gd"
## DRAFT ONLY. ROOT must bind successful A/B evidence and its one boolean edit.
## No candidate _run, room trips, Gate/world, or full-city claim.
const FORMAL_FIXTURE_READY := false
const FORMAL_RUNTIME_SHA := "PENDING_ROOT_TRUE_RUNTIME_SHA"
const FALSE_RUNTIME_BACKUP := "PENDING_ROOT_FALSE_RUNTIME_EXACT_BACKUP"
const FALSE_RUNTIME_SHA := "da8faf3d85a4e7bb91ca74f05a1a630873be5f274d3fd7e12b8e2cb11d528a7e"
const FROZEN_PARENT_PATH := "res://tests/test_luoyang_revision_market_rooms_key_retry3_20261015.gd"
const FROZEN_PARENT_SHA := "72afcd410551b6503410a3812a6b1fd4265f50ea4946fd237ef9ce186a587a0d"
const ACCEPTED_ATOMS := [
	{"path":"PENDING_A_SUCCESS_RESULT","sha":"PENDING_A_RESULT_SHA","scope":"LIMITED_CANDIDATE_MARKET_ROOMS"},
	{"path":"PENDING_B_SUCCESS_RESULT","sha":"PENDING_B_RESULT_SHA","scope":"LIMITED_CANDIDATE_DOCKS"}
]

func _precheck_revision() -> bool:
	if not _check(FORMAL_FIXTURE_READY,"DRAFT refuses execution until ROOT binds A/B and exact true-runtime source"): return false
	if not _track_source(FROZEN_PARENT_PATH,FROZEN_PARENT_SHA) or not _track_source(FALSE_RUNTIME_BACKUP,FALSE_RUNTIME_SHA) or not _track_source(REVISION_PATH,FORMAL_RUNTIME_SHA): return false
	var false_text:=FileAccess.get_file_as_string(FALSE_RUNTIME_BACKUP)
	var true_text:=FileAccess.get_file_as_string(REVISION_PATH)
	var old_literal:="const FORMAL_ENABLED := false"
	if not _check(false_text.count(old_literal)==1 and false_text.replace(old_literal,"const FORMAL_ENABLED := true")==true_text,"Only exact ROOT-authorized FORMAL_ENABLED false-to-true byte-text edit"): return false
	for path: String in RUNTIME_PINS:
		if not _track_source(path,FORMAL_RUNTIME_SHA if path==REVISION_PATH else String(RUNTIME_PINS[path])): return false
	for path: String in UTILITY_PINS:
		if not _track_source(path,UTILITY_PINS[path]): return false
	for atom: Dictionary in ACCEPTED_ATOMS:
		if not _track_source(atom.path,atom.sha): return false
		var evidence: Variant=JSON.parse_string(FileAccess.get_file_as_string(atom.path))
		if not _check(evidence is Dictionary and evidence.get("scope")==atom.scope and evidence.get("complete")==true and evidence.get("failures")==0 and evidence.get("source_before") is Dictionary,"Exact completed candidate atom, never old failed evidence "+atom.scope): return false
		for path: String in evidence.source_before:
			var expected: String=FORMAL_RUNTIME_SHA if path==REVISION_PATH else String(evidence.source_before[path].sha256)
			if not _track_source(path,expected): return false
	revision=load(REVISION_PATH) as Script
	if not _check(revision!=null and revision.get_script_constant_map().get("FORMAL_ENABLED")==true,"Actual frozen adapter default formal enabled"): return false
	var publication: Dictionary=PUBLICATIONS[MARKET_ID]
	if not _track_source(publication.result,publication.sha) or not _track_source(publication.manifest,publication.manifest_sha): return false
	proof=JSON.parse_string(FileAccess.get_file_as_string(publication.result))
	published=JSON.parse_string(FileAccess.get_file_as_string(publication.manifest))
	for path: String in revision.call("source_paths"):
		if not source_before.has(path): source_before[path]=_file(path)
		_check(source_before[path].exists,"Actual default runtime closed source exists "+path)
	source_before[get_script().resource_path]=_file(get_script().resource_path)
	return failures==0

func _bind_revision() -> bool:
	# Independent city-only binder: never mutate observed metadata to satisfy
	# the inherited candidate status predicate, and never re-prepare C records.
	if oracle!=null: oracle.call("release"); oracle=null
	mask=null; polygons.clear()
	inside_room=false
	if not _check(candidate_scene.scene_id==StringName(MARKET_ID),"Formal fixture binds only actual Market, never room replay"): return false
	oracle=SIMPLE_RAW.new()
	if not _check(bool(revision.call("bound",candidate_scene)) and C._records.has(String(candidate_scene.scene_id)),"Actual revised city bound, prepared record exists before read"): return false
	# Read only the already completed production record; the getter would prepare again.
	var record: Dictionary=(C._records[String(candidate_scene.scene_id)] as Dictionary).duplicate(true)
	var bindings: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/maps/luoyang_city_revision_runtime_20261015/bindings.json"))
	var city_binding: Dictionary=bindings.get("cities",{}).get(String(candidate_scene.scene_id),{})
	var binding_sha: String=RUNTIME_PINS["res://art/maps/luoyang_city_revision_runtime_20261015/bindings.json"]
	if not _check(not city_binding.is_empty() and record.get("canonical_scene_id")==String(candidate_scene.scene_id) and record.get("city_revision_binding_sha")==binding_sha and candidate_scene.get_meta("city_revision_runtime_binding_sha","")==binding_sha and candidate_scene.get_meta("city_frontage_revision_manifest_sha","")==PUBLICATIONS[_city_id()].manifest_sha and candidate_scene.get_meta("city_frontage_revision_author_sha","")==published.author_sha256 and candidate_scene.get_meta("city_revision_published_scene_path","")==city_binding.scene_path and candidate_scene.get_meta("city_revision_source_scene_path","")=="res://data/scenes/%s.tres"%String(candidate_scene.scene_id) and candidate_scene.get_meta("city_frontage_revision_runtime_status","")=="ROOT_APPROVED_DEFAULT_REVISION" and record.get("ground_path")==published.ground_path and record.get("walk_path")==published.walk_path,"Existing production record deep copy exact binding/source/published scene metadata/manifest/ground/walk identity"): return false
	var expected_slots: Dictionary=published.gameplay_slots.duplicate(true)
	if String(candidate_scene.scene_id)==MARKET_ID:
		var disabled: Array=(expected_slots.portals as Array).filter(func(row: Dictionary)->bool:return row.get("source_id")=="enter_southwest_market_front_room")
		if not _check(disabled.size()==1,"Exact published SW pillar door explicit removal domain"): return false
		expected_slots.portals.erase(disabled[0])
		var disabled_receipt: Array=record.get("city_revision_disabled_portals",[])
		_check(candidate_scene.map_layout.portals.size()==12 and disabled_receipt.size()==1 and disabled_receipt[0].id=="enter_southwest_market_front_room" and disabled_receipt[0].building_id=="southwest_market_front" and disabled_receipt[0].reason=="SOURCE_ANCHOR_IS_SOLID_CENTRAL_POST_NOT_DOOR","Only12 runtime Market portals and exact sole SW disabled receipt; old13/9door publication not runtime credit")
	if not _check(record.get("city_revision_manifest_sha")==PUBLICATIONS[_city_id()].manifest_sha and C._equal_value(record.objects,published.objects) and C._equal_value(record.gameplay_slots,expected_slots) and C._equal_value(record.routes,published.routes),"Actual revision record exact published geometry/gameplay/routes plus sole disabled SW door"): return false
	var declarations: Array[Dictionary]=[]
	for object: Dictionary in published.objects:
		var shapes: Array[PackedVector2Array]=[]
		var extent:=C._vec(object.collision_size_px)
		if extent.x>0 and extent.y>0:
			var rect:=Rect2(C._vec(object.physical_center_px)-extent*.5,extent)
			shapes.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
		for raw: Array in object.solid_polygons_px:
			var polygon:=PackedVector2Array()
			for pair: Array in raw: polygon.append(C._vec(pair))
			shapes.append(polygon)
		for shape: PackedVector2Array in shapes: polygons.append(shape)
		if not shapes.is_empty(): declarations.append({"id":object.id,"solid_polygons_px":shapes})
	var owned: Resource=candidate_scene.map_layout.duplicate(true)
	owned.set("visual_objects",declarations)
	var configured: bool=bool(oracle.call("configure",owned,"round_world_pixel",0.0))
	mask=Image.load_from_file(published.walk_path)
	return _check(configured and mask!=null and mask.get_size()==Vector2i(3072,2048) and candidate_scene.map_layout.walkable_mask_path==published.walk_path,"Actual candidate raw navigation+source solids, no old mask substitution")

func _run() -> void:
	var started:=Time.get_ticks_msec(); deadline=started+180000
	output="res://build/luoyang_revision_formal_boot_20261015/%d_%d/"%[OS.get_process_id(),Time.get_ticks_usec()]
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players(); prior_slot=int(root.get_node("SaveManager").get("active_slot"))
	_check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"Unique independent formal boot output")
	_check(bridge.call("is_checkpoint_saves_suspended")==true,"Checkpoint writes held before first await")
	var args:=OS.get_cmdline_user_args()
	_check("--luoyang-formal-revision-boot-key" in args and not REVISION_FLAG in args and not "--luoyang-city-revision-candidate-retry2-20261015" in args and not "--luoyang-v3-candidate" in args and not "--luoyang-enclosure-v11-candidate" in args and not "--luoyang-market-enrichment-candidate-20261014" in args,"Ordinary formal boot without candidate selection flags")
	_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"Installed actual GPU engine ordinary clock")
	driver=INPUT_DRIVER.new(); driver.call("configure",self)
	if _precheck_revision() and failures==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4)
		process_frame.connect(_frame_gap)
		if await _public_setup(Vector2(735,920)):
			var enabled: Array=(candidate_scene.map_layout.portals as Array).filter(func(portal: Dictionary)->bool:return portal.get("candidate_only",false)==true and portal.get("enabled",false)==true)
			var nodes: Array=field.get("_exit_nodes")
			_check(candidate_scene.get_meta("city_frontage_revision_runtime_status","")=="ROOT_APPROVED_DEFAULT_REVISION" and candidate_scene.map_layout.portals.size()==12 and enabled.size()==8 and nodes.size()==12,"Actual default formal Market12 portal nodes and eight enabled reviewed doors")
			if await _way(PackedVector2Array([Vector2(735,920),Vector2(735,890)]),"formal_native_normal_INPUT30px_only") and await _fade("inn",false,"formal_inn_front_alpha1"):
				rows.append(_state("ACTUAL_FORMAL_MARKET_AFTER_NORMAL30PX"))
				captures.append(await _capture_gate("ordinary_formal_market_front"))
	if process_frame.is_connected(_frame_gap): process_frame.disconnect(_frame_gap)
	if oracle!=null: _check(bool(oracle.call("verify_sources")),"Independent formal navigation source unchanged"); oracle.call("release"); oracle=null
	mask=null; polygons.clear(); candidate_scene=null
	if driver!=null: driver.call("release"); driver=null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	field=null
	for cursor: int in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,cursor)
	await process_frame; await process_frame
	_check(_sources()==source_before and _players()==players_before and root.get_node("SaveManager").get("active_slot")==prior_slot and bridge.call("is_checkpoint_saves_suspended")==true,"Exact formal source/15save/slot/checkpoint guards unchanged")
	_check(Time.get_ticks_msec()<deadline and captures.size()==1 and transitions.is_empty() and room_receipts.is_empty(),"Shared180/arrival60 one formal birth+normal30px+onePNG only")
	var result: Dictionary={"scope":"ORDINARY_FORMAL_MARKET_BOOT_ONLY_NOT_ROOM_OR_ALL_CITY_REPLAY","complete":failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-started,"budget_ms":180000,"arrival_ms":60000,"records":rows,"arrival_observations":observations,"captures":captures,"source_before":source_before,"source_after":_sources(),"players_before":players_before,"players_after":_players(),"candidate_actual_evidence":ACCEPTED_ATOMS,"only_authorized_production_delta":"Exact FORMAL_ENABLED false-to-true","room_or_Gate_or_world_travel_retested":false,"full_city_or_loading_speed_credit":false,"ROOT_outer_exactticks_and_complete_stderr_required":true}
	_save_evidence("result.json",result)
	print("LUOYANG_REVISION_FORMAL_BOOT="+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)
