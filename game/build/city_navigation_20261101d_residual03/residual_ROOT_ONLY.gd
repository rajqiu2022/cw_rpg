extends "res://build/city_navigation_20261101d_residual02/residual_ROOT_ONLY.gd"
## Inherit successful131104 market_artisan a+b. Execute only three unfinished
## pairs first; all images/adult measurement occur after those six real legs.
const R3 := "res://build/city_navigation_20261101d_residual03/"
const R3_INPUTS := R3 + "residual_inputs_ROOT_READY.json"
var r3: Dictionary = {}
var inherited_market := false

func run() -> void:
	directory = R3 + "actual/" + str(OS.get_process_id()); DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"RESIDUAL03_EARLIEST_CHECKPOINT_SUSPEND"): finish(); return
	r3 = JSON.parse_string(FileAccess.get_file_as_string(R3_INPUTS)) as Dictionary
	if not need(r3.get("schema") == "CITY_NAVIGATION_20261101D_RESIDUAL03_QA_V1" and r3.get("ready") == true,"ROOT_EXPLICIT_RESIDUAL03_FREEZE"): finish(); return
	if not need(FileAccess.get_sha256(INPUTS) == r3.base_inputs_sha256 and FileAccess.get_sha256(RESIDUAL_INPUTS) == r3.parent_inputs_sha256 and FileAccess.get_sha256(MANIFEST) == r3.approved_candidate_manifest_sha256,"UNCHANGED_BASE_AND_PARENT_QA_INPUTS_AND_FROZEN96"): finish(); return
	cfg = JSON.parse_string(FileAccess.get_file_as_string(INPUTS)) as Dictionary
	residual = JSON.parse_string(FileAccess.get_file_as_string(RESIDUAL_INPUTS)) as Dictionary
	pins = cfg.get("source_pins",{}).duplicate(true)
	for path: String in residual.get("source_pins",{}):
		if not need(not pins.has(path) or pins[path] == residual.source_pins[path],"PARENT_QA_DOES_NOT_OVERRIDE_SOURCE_PIN:"+path): finish(); return
		pins[path] = residual.source_pins[path]
	for path: String in r3.required_source_paths:
		if not need(r3.get("source_pins",{}).has(path),"ROOT_EXPLICIT_RESIDUAL03_PIN:"+path): finish(); return
	for path: String in r3.source_pins:
		var expected: String = String(r3.source_pins[path])
		if not need(path.begins_with("res://") and not ".." in path and expected.length() == 64 and (not pins.has(path) or pins[path] == expected),"RESIDUAL03_DOES_NOT_OVERRIDE_FROZEN_PIN:"+path): finish(); return
		pins[path] = expected
	pins[INPUTS] = r3.base_inputs_sha256; pins[RESIDUAL_INPUTS] = r3.parent_inputs_sha256
	pins[R3_INPUTS] = FileAccess.get_sha256(R3_INPUTS) # Also exact-pinned by Root outer launch.
	first = facts()
	for path: String in pins:
		if not need(path.begins_with("res://") and not ".." in path and first[path].sha256 == pins[path],"RESIDUAL03_SOURCE_FIRST:"+path): finish(); return
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST)) as Dictionary
	if not need(manifest.get("ready") == true and manifest.get("source_pins",{}).size() == 96,"ORIGINAL96_LEAVES_UNCHANGED"): finish(); return
	router = root.get_node("SceneRouter"); host = root.get_node_or_null("CityNavigationRuntime")
	if not need(host != null and host.get_script().resource_path == HOST and ProjectSettings.get_setting("autoload/CityNavigationRuntime","") == "*"+HOST,"ACTUAL_UNCHANGED_HOST"): finish(); return
	pair_data = load(PAIRS) as GDScript
	var until := Time.get_ticks_msec()+3000
	while Time.get_ticks_msec() < until and host.call("get_debug_state").get("ready") != true: await process_frame
	if not _inherit_prefix() or not _inherit_market_artisan(): finish(); return
	# No static audit/Gate/bootstrap/market_artisan travel repeated. Do all real
	# unfinished legs before a visual/height oracle can stop this residual.
	for id: String in ["market_temple","docks_temple","temple_riverside"]:
		var pair: Dictionary = _pair(id)
		if not need(not pair.is_empty(),"EXACT_UNFINISHED_PAIR:"+id): finish(); return
		var a: Dictionary = _endpoint(pair,"a"); var b: Dictionary = _endpoint(pair,"b")
		if not await _near(a,a.arrival) or not await _cross(a) or not await _cross(b): finish(); return
	var south: Dictionary = _endpoint(_pair("docks_temple"),"b")
	if not await _near(south,south.arrival) or not await _capture("temple_south_roadmouth_minimap_normal"): finish(); return
	var civic: Dictionary = _endpoint(_pair("market_artisan"),"a")
	if not await _civic_adults_near(civic) or not _mini_check() or not await _capture("civic_blademaster_adult_and_services_minimap_normal"): finish(); return
	var temple: Dictionary = _endpoint(_pair("temple_riverside"),"a")
	var hall_foot := Vector2(cfg.temple_hall_foot[0],cfg.temple_hall_foot[1])
	if not await _near(temple,hall_foot) or not _hall_check() or not await _capture("temple_scripture_hall_adult_scale_normal"): finish(); return
	finish()

func _inherit_market_artisan() -> bool:
	if not need(FileAccess.get_sha256(r3.inherited_report) == r3.inherited_report_sha256,"IMMUTABLE131104_WHOLE_FAIL_PRESERVED"): return false
	var prior: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(r3.inherited_report)) as Dictionary
	if not need(prior.get("passed") == false and prior.get("checks") == 132 and prior.get("errors") == ["ORIGINAL_FULL_FOOT_SAFE_120PX_SOUTH_OF_BLADEMASTER"] and prior.get("input_events") == 8 and prior.get("normal_images") == 0,"EXACT131104_SCOPE_ONLY_INVALID_NEAR_ORACLE"): return false
	var trips: Array = prior.get("records",[]).filter(func(row: Dictionary) -> bool: return row.get("true_space_crossing") == true)
	if not need(trips.size() == 2 and trips[0].get("pair") == "market_artisan" and trips[0].get("side") == "a" and trips[1].get("pair") == "market_artisan" and trips[1].get("side") == "b" and trips[0].get("actual_foot") == trips[0].get("expected_arrival") and trips[1].get("actual_foot") == trips[1].get("expected_arrival") and trips[0].get("actual_logical") == "luoyang_artisan_residential_20261022ap" and trips[1].get("actual_logical") == "ch4_s3_luoyang_market" and var_to_bytes(prior.get("source_first",{})) == var_to_bytes(prior.get("source_final",{})),"INHERIT_TWO_TRUE_SPACE_EXACT_ARRIVALS_AND_SOURCE_PREFIX_NO_RERUN"): return false
	inherited_market = true
	records.append({"inherited_true_space_crossings_only":trips,"report":r3.inherited_report,"report_sha256":r3.inherited_report_sha256,"prior_whole_passed":false,"market_artisan_not_reexecuted":true,"remaining_true_directions_required":6,"visuals_delayed_until_all_six_legs_done":true})
	return true

func _civic_adults_near(endpoint: Dictionary) -> bool:
	var geo: GDScript = load("res://build/city_navigation_20261101d_candidate01/navigation_geometry.gd") as GDScript
	var region: Dictionary = geo.call("region_for",String(endpoint.scene_id))
	var authored: Array = region.get("npcs",[]).filter(func(row: Dictionary) -> bool: return row.get("data",{}).get("npc_id") == "spar_luoyang_blademaster")
	if not need(authored.size() == 1 and authored[0].get("foot") is Vector2,"EXACT_COMPILED_BLADEMASTER_FOOT_NOT_NAME_GUESS"): return false
	var npc_foot: Vector2 = authored[0].foot
	var near_foot := Vector2(2920,4240)
	if not need(npc_foot == Vector2(2800,4240),"EXACT_E197_COMPILED_BLADEMASTER_FOOT_FOR_FIXED_NEAR"): return false
	if not need(geo.call("safe_static",String(endpoint.scene_id),near_foot) == true,"ORIGINAL_FULL_FOOT_SAFE_FIXED_NAV_VERIFIED_2920_4240"): return false
	if not await _near(endpoint,near_foot): return false
	await process_frame; await RenderingServer.frame_post_draw
	var art: Node = field.get_node_or_null("Quality20261101dArtView")
	if not need(art != null and art.get_script().resource_path == ART,"ACTUAL_CIVIC_ADULT_ART_OWNER"): return false
	var originals: Dictionary = art.get("_actor_before")
	var actors: Dictionary = field.get("_region_actors")
	var measured: Array[Dictionary] = []
	records.append({"civic_six_adult_current_residents_measured":measured,"compiled_blademaster_foot":npc_foot,"public_fixed_NAV_verified_near":near_foot,"one_normal_image_replaces_old_civic_service_image":true,"no_dialogue_or_actor_writes":true})
	var blademaster_visible := false
	for id: String in ADULT_IDS:
		var key: String = "ch4_s3_luoyang_market/" + id
		var npc: NPCNode = actors.get(key,{}).get("node") as NPCNode
		if not is_instance_valid(npc): measured.append({"id":id,"resident":false,"not_fabricated":"original flags or absent actor slot"}); continue
		if not need(npc.sprite != null and npc.sprite.texture != null,"RESIDENT_ADULT_REAL_SPRITE:"+id): return false
		var sprite: Sprite2D = npc.sprite
		var image: Image = sprite.texture.get_image()
		if not need(image != null,"RESIDENT_ADULT_REAL_GPU_IMAGE:"+id): return false
		var frame_size := Vector2i(floori(float(image.get_width())/maxi(1,sprite.hframes)),floori(float(image.get_height())/maxi(1,sprite.vframes)))
		var frame := Rect2i(sprite.frame_coords * frame_size,frame_size)
		var current_core: Rect2i = image.get_region(frame).get_used_rect()
		var visible_height: float = float(current_core.size.y) * absf(sprite.scale.y)
		var local_core := Rect2(sprite.get_rect().position+Vector2(current_core.position),Vector2(current_core.size))
		var transform: Transform2D = sprite.get_global_transform_with_canvas()
		var screen := Rect2(transform * local_core.position,Vector2.ZERO)
		for corner: Vector2 in [local_core.position,Vector2(local_core.end.x,local_core.position.y),local_core.end,Vector2(local_core.position.x,local_core.end.y)]: screen = screen.expand(transform * corner)
		var on_screen: bool = sprite.is_visible_in_tree() and Rect2(Vector2.ZERO,root.get_viewport().get_visible_rect().size).encloses(screen)
		var after: Dictionary = _adult_body_business(npc)
		var original: Dictionary = originals.get(npc.get_instance_id(),{})
		var intact: bool = not original.is_empty() and var_to_bytes(original) == var_to_bytes(after)
		measured.append({"id":id,"resident":true,"current_texture":sprite.texture.resource_path,"current_frame":sprite.frame,"hframes":sprite.hframes,"vframes":sprite.vframes,"actual_frame_rect":frame,"current_alpha_core":current_core,"actual_sprite_scale":sprite.scale,"actual_visible_core_height":visible_height,"screen_core_rect":screen,"visible_in_tree":sprite.is_visible_in_tree(),"whole_core_on_screen":on_screen,"original_body_action_unchanged":intact,"original_body_business":original,"actual_body_business":after})
		if not need(current_core.size.y > 0 and intact,"RESIDENT_ADULT_BODY_ACTION_ORIGINAL_IDENTITY:"+id): return false
		if id == "spar_luoyang_blademaster":
			blademaster_visible = on_screen and absf(visible_height-132.0) <= .1
			if not need(blademaster_visible,"ACTUAL_VISIBLE_CURRENT_FRAME_BLADEMASTER_132PX_PLUS_MINUS_POINT1"): return false
	return need(blademaster_visible,"HERO_AND_BLADEMASTER_NORMAL_NEAR_FRAME_NOT_OFFSCREEN_HEIGHT_ONLY")

func finish() -> void:
	if done: return
	done = true
	for code: Key in [KEY_W,KEY_A,KEY_S,KEY_D,KEY_SPACE]:
		if Input.is_physical_key_pressed(code): _key(code,false)
	var final_sources: Dictionary = facts() if not pins.is_empty() else {}
	if not first.is_empty(): need(var_to_bytes(first) == var_to_bytes(final_sources),"SOURCE_FIRST_FINAL_EXACT_NO_OLD_WRITES")
	var executed: int = records.filter(func(row: Dictionary) -> bool: return row.get("true_space_crossing") == true).size()
	records.append({"scope":"RESIDUAL03_SIX_REAL_DIRECTIONS_PLUS_TWO_INHERITED_MAX_THREE_IMAGES","inherited_true_directions":2 if inherited_market else 0,"executed_true_directions":executed,"no_Gate_or_static22_retest":true,"no_battle_crafting_or_gait_retest":true,"save_apis":0,"save_metadata_samples":0,"userstate_reads_writes":0,"player_router_camera_private_writes":0})
	var result: Dictionary = {"passed":errors.is_empty(),"checks":checks,"errors":errors,"input_events":inputs,"normal_images":images,"inherited_true_directions":2 if inherited_market else 0,"executed_true_directions":executed,"records":records,"source_first":first,"source_final":final_sources,"checkpoint_suspended":suspended,"root_only":true}
	var file := FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(result,"\t")+"\n")
	print("CITYNAV31D_RESIDUAL03 ",JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"inputs":inputs,"images":images,"inherited":2 if inherited_market else 0,"executed":executed,"result":directory+"/result.json"}))
	quit(0 if errors.is_empty() else 1)
