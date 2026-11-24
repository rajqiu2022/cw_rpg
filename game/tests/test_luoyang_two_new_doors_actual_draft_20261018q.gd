extends "res://tests/test_luoyang_mansion_return_diagnostic_draft_20261018q.gd"
## NOTREADY: only mansion+warehouse, three-door original predicates/cheap FF81 observer unchanged.
const TWO_DOORS_READY=false
const TWO_DOORS_WHOLE_MS=180000
const FINAL_ROUTER_SHA="PENDING_SYSTEM_FREEZE"
const FINAL_TEMPLE_SHA="PENDING_SYSTEM_FREEZE"
const FINAL_TEMPLE_BIND="PENDING_SYSTEM_BIND_PATH"
const FINAL_TEMPLE_BIND_SHA="PENDING_SYSTEM_FREEZE"
const TWO_ROOM_IDS=[MANSION_ID,"luoyang_canal_warehouse_interior_20261016"]
func _precheck_actual() -> bool:
	if not check(TWO_DOORS_READY,"NOTREADY until ROOT freezes new authored-return Router and Temple dependencies"): return false
	if not check(DisplayServer.get_name()!="headless" and Engine.time_scale==1.0 and OS.get_cmdline_user_args().is_empty(),"Ordinary GUI/no spacing or other candidate flag"): return false
	var pins: Dictionary={M.SELF:"d82232b96035f365652831238bad490e79dc973b75d3550c79d6ab6b2070b979",M.REGISTRY_PATH:"959bc6f5408261586a6165bf731347959e6287bea9afa8bfb40f6e4035302ad5",CONTRACT:CONTRACT_SHA,RAW_PATH:RAW_SHA,"res://tests/test_luoyang_three_doors_actual_retry3_20261018q.gd":"52aaaa3db603ba52504cd7dff1667e18d5f1013020d362fa7897181fb086b8e2","res://tests/test_luoyang_three_exterior_doors_cpu_20261016g.gd":"91c09043fc1ad85fb392909ed3b6235ddf064dee3bea943365c91cd88fdb5b89","res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd":"a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895","res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7","res://scripts/field/field_walkable_controller.gd":"638cd8f0a37aacff56d074383d868f2d00bab3b81fcf56bf4d148fb84f556839","res://scripts/autoload/scene_router.gd":FINAL_ROUTER_SHA,"res://scripts/autoload/loading_manager.gd":"5550a037e8001069713b0af317a6db2cd2ac427189f8f75d2e87e755ece210db","res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"06244b1dc286149ce8299cd83f766d2d9f5fd9b61bcb59180261dff40d8e9d3d","res://scripts/city/luoyang_harbour_life_runtime_20261016.gd":"1a269bc65df4aa70edd59a67ee5415768bee039ea52188939905746a99ef61ad","res://scripts/city/luoyang_district_life_20261016f.gd":"6921fa796c419202fc9707559addabdb013ea0b37ec51e6303e9f4923a79fc17","res://scripts/city/luoyang_resident_field_20261016.gd":"f1730e461fe6328763cfd70c79b2bbc36c80a2afb7609c364fa7ea7af8acdd7f","res://scripts/city/luoyang_temple_assembly_20261016.gd":FINAL_TEMPLE_SHA,FINAL_TEMPLE_BIND:FINAL_TEMPLE_BIND_SHA}
	for path: String in pins:
		if not track(path,pins[path]): return false
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return false
	if not track("res://tests/test_luoyang_mansion_return_diagnostic_draft_20261018q.gd","ff81ea5865811f2c84ec51a7640647c1223924b3c91cb1358dc91635032afd21") or not track("res://scripts/city/luoyang_building_spacing_20261017p.gd","1c94f23ad8e69022712aeffdf7ebd125d201cede2838e4e45d38fadbacb35b16"): return false
	package=M.catalogue()
	if not check(M.FORMAL_ENABLED and package.get("rooms",{}).has(MANSION_ID) and package.rooms.has("luoyang_canal_warehouse_interior_20261016"),"Same default two new-room identities, no synthetic room"): return false
	for path: String in package.source_sha256:
		if not track(path,package.source_sha256[path]): return false
	var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT))
	var navigation: Dictionary=contract.combined_navigation_sources
	if not check(navigation.size()==9 and navigation.get("world_size_px") is Array and _v(navigation.world_size_px)==WORLD,"Exact immutable mixed contract/world domain"): return false
	for key: String in ["district_author","district_binding","district_geometry","district_runtime"]:
		var declared: Variant=navigation.get(key)
		if not check(declared is Dictionary and declared.has("path") and declared.has("sha256"),"Original explicit source dictionary "+key): return false
		# Only the approved current District dependency differs. The immutable
		# old contract and old CPU source facts remain separately pinned above.
		var expected: String=pins.get(String(declared.path),String(declared.sha256))
		if not track(declared.path,expected): return false
	author=JSON.parse_string(FileAccess.get_file_as_string(navigation.district_author.path))
	return true
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+TWO_DOORS_WHOLE_MS
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	folder="res://build/luoyang_two_new_doors_actual_20261018q/%d_%d"%[OS.get_process_id(),began];DirAccess.make_dir_recursive_absolute(folder)
	var complete: bool=_precheck_actual()
	if complete:
		driver=INPUT.new();driver.configure(self)
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		process_frame.connect(_sample_wait_state)
		var contract: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CONTRACT));var selected: Array[Dictionary]=[]
		for door: Dictionary in contract.doors:
			if door.room_id in TWO_ROOM_IDS: selected.append(door)
		complete=check(selected.size()==2,"Exactly original mansion+warehouse; successful pawn NOT repeated")
		if complete:
			for door: Dictionary in selected:
				if not await _trip_door(door): complete=false;break
		_sample_wait_state();process_frame.disconnect(_sample_wait_state)
	if driver!=null: driver.release();driver=null
	if is_instance_valid(current_scene):
		var own: Node=current_scene;var weak: WeakRef=weakref(own);current_scene=null;own.queue_free();field=null;scene=null;own=null
		await process_frame;await process_frame
		if not check(weak.get_ref()==null,"Own two-door final Field actually exited"): complete=false
	contexts.clear();independent=null;active_mask=null
	records.append({"kind":"TWO_NEW_DOORS_SCOPE","doors":door_rows,"captures":pictures,"whole_ms":TWO_DOORS_WHOLE_MS,"arrival_ms":ARRIVAL_MS,"return_ms":RETURN_MS,"last_snapshot":last_wait_sample,"bounded_phases":phase_samples,"source_oracle_or_return_predicates_weakened":false,"candidate_flags":OS.get_cmdline_user_args(),"pawn_or_tenrooms_or_spacing_retested":false})
	complete=check(door_rows.size()==2 and pictures.size()==2,"Two actual Space entries and precise live returns, each original2s predicate") and complete
	finish(folder,began,complete,"MANSION_AND_WAREHOUSE_ONLY_REAL_SPACE_EXACT_LIVE_RETURNS_NOT_PAWN_OR_SPACING_RETEST")

