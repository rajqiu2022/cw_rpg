extends "res://tests/test_luoyang_building_fade_preview_20261010.gd"
## NEW limited candidate Field + ordinary INPUT, not the synthetic preview or six approval.
## Parent is reused only for readonly source/import/player utilities and public cursor cleanup.
const ACTUAL_SELF_PATH := "res://tests/test_luoyang_building_fade_actual_field_20261010.gd"
const RUNTIME_PATH := "res://scripts/city/luoyang_enclosure_building_fade_runtime_20261010.gd"
const FIELD_PATH := "res://scripts/field/field_walkable_controller.gd"
const RAW_PATH := "res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd"
const PHYSICAL_PATH := "res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd"
const INPUT_PATH := "res://tests/helpers/v15_input_driver.gd"
const CONTRACT = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const RAW = preload("res://tests/helpers/luoyang_enclosure_v11_city_only_raw.gd")
const PHYSICAL = preload("res://tests/helpers/joint_v15_wall_v5_city_physical_alpha_probe.gd")
const INPUT = preload("res://tests/helpers/v15_input_driver.gd")
const PATH_SEED := "res://build/joint_world_luoyang_20261003_qa/455_be0_strict4624_candidate_save_headless_20261010/before.json"
const PATH_SEED_SHA := "a54a387722499b7a617fe2f05d9d74a681821f202a61a64980ea49b695492619"
const ACTUAL_IDS: Array[String] = ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s3_luoyang_market"]
const ACTUAL_PINNED := {
	RUNTIME_PATH:"b0c4dbedb0e8f48668a7d191049c5fbd9ae7b2866ea389e1ac2797ae3a0f9e7f",
	FIELD_PATH:"6073da1018dcc1c4fc6a9e8b254b2d0b472c7b434a5bf1751cbe5aea5fe3e6e7",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"558a3edfaa368ff52b67ff0eaade7505191011928c2a724897efc727e43887f6",
	RAW_PATH:"6ad7b6be15fd23ea4f8356c111c5a5a6c54c8e1ec7496083597d01e904711c62",
	PHYSICAL_PATH:"40b42c901ef05ac1971ccaae9ba049b60cfe439baea8778f796f978c4bd54450",
	INPUT_PATH:"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7"
}
var actual_field: Control
var actual_raw: RefCounted
var actual_probe: RefCounted
var actual_driver: RefCounted
var actual_authors: Dictionary = {}
var lifecycle: Array[Dictionary] = []
var observations: Array[Dictionary] = []
var moves: Array[Dictionary] = []
var initial_navigation: Dictionary = {}
var checkpoint_default: Variant
var current_actor_color: PackedByteArray
var current_actor_self_color: PackedByteArray
var current_nonbuilding_base: Dictionary = {}

static func fixture_sources() -> Array[String]:
	var result: Array[String] = [ACTUAL_SELF_PATH,RUNTIME_PATH,FIELD_PATH,RAW_PATH,PHYSICAL_PATH,INPUT_PATH,PATH_SEED,
		"res://tests/test_luoyang_building_fade_preview_20261010.gd",
		"res://scripts/city/luoyang_enclosure_building_fade_preview_20261010.gd",
		"res://scripts/city/luoyang_enclosure_native_depth_overlap_20261009.gd",
		"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd",
		"res://scripts/autoload/platform_bridge.gd","res://scripts/field/player.gd","res://scenes/player.tscn",
		"res://project.godot","res://data/scenes/world_map_jianghu.tres",
		"res://data/maps/world_map_jianghu_layout_v14.tres","res://data/config/outskirts_native_adoption.json"]
	for id: String in ACTUAL_IDS:
		result.append("res://data/scenes/"+id+".tres")
		result.append("res://data/scenes/luoyang_enclosure_v11_candidates/"+id+".tres")
		result.append("res://data/maps/luoyang_enclosure_v11_candidates/"+id+"_layout.tres")
	return result

func _safe(value: Variant) -> Variant:
	if value is Color: return _color(value)
	if value is Vector2: return [value.x,value.y]
	if value is Dictionary:
		var result: Dictionary = {}
		for key: Variant in value: result[key] = _safe(value[key])
		return result
	if value is Array:
		var result: Array = []
		for element: Variant in value: result.append(_safe(element))
		return result
	return value

func _write_actual(name: String,value: Variant) -> bool:
	var path := output+name
	if FileAccess.file_exists(path): return _check(false,"refuse existing actual evidence "+path)
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return _check(false,"write actual evidence "+path)
	file.store_string(JSON.stringify(_safe(value),"\t",true)); file.close()
	var parser := JSON.new()
	return _check(parser.parse(FileAccess.get_file_as_string(path))==OK,"actual evidence readback "+name)

func _path_sources() -> void:
	_check(FileAccess.get_sha256(PATH_SEED)==PATH_SEED_SHA,"fixed455 path seed identity only, not old source digest credit")
	var parser := JSON.new()
	if not _check(parser.parse(FileAccess.get_file_as_string(PATH_SEED))==OK and parser.data is Dictionary,"typed path seed"): return
	var rows: Variant = parser.data.get("sources")
	if not _check(rows is Array and rows.size()==4624,"exact finite455 path seed rows"): return
	var project_prefix := ProjectSettings.globalize_path("res://").replace("\\","/").trim_suffix("/").get_base_dir()+"/"
	for row: Variant in rows:
		if not _check(row is Dictionary and typeof(row.get("path"))==TYPE_STRING,"typed source seed row"): continue
		var path: String = row.path.replace("\\","/")
		if not _check(path.begins_with(project_prefix) and "/../" not in path,"project-only source leaf"): continue
		_track(path)
	for path: String in fixture_sources(): _track(path)
	for path: String in PINNED: _track(path); _check(FileAccess.get_sha256(path)==PINNED[path],"frozen existing dependency "+path)
	_check(FileAccess.get_sha256(FADE_PATH)==FADE_SHA,"frozen preview algorithm unchanged")
	for path: String in ACTUAL_PINNED: _track(path); _check(FileAccess.get_sha256(path)==ACTUAL_PINNED[path],"actual candidate runtime source "+path)
	for id: String in ACTUAL_IDS:
		var reader: RefCounted = RAW.new()
		var record: Dictionary = reader.call("independent_record",StringName(id))
		reader.call("release")
		if not _check(not record.is_empty(),"independent four BASE/patch/ground "+id): continue
		actual_authors[id] = record
		for path: String in record.asset_sha256: _track(path)
		_track(String(record.ground_capture_path))
	for path: String in sources: first[path] = _file(path)

func _unused_capture(_label: String) -> void:
	pass

func _wait_actual(id: String) -> bool:
	var deadline := Time.get_ticks_msec()+60000
	while Time.get_ticks_msec()<deadline:
		await process_frame
		var loader: Node = root.get_node_or_null("LoadingManager")
		if loader!=null and loader.get("_transition_active")==true: continue
		var node: Node = current_scene
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion(): continue
		if node.get_script()==null or node.get_script().resource_path!=FIELD_PATH or node.get("_scene_rebuilding")==true: continue
		var definition: SceneScript = node.get("_current_scene") as SceneScript
		var player: Player = node.get("_player") as Player
		if definition==null or String(definition.scene_id)!=id or not CONTRACT.is_v3(definition) or not is_instance_valid(player): continue
		await actual_driver.call("completed_actor_stage")
		if current_scene!=node or not is_instance_valid(node) or node.is_queued_for_deletion(): continue
		actual_field = node as Control
		return true
	return false

func _held_helper() -> RefCounted:
	return actual_field.get("_v14_modular_overlap") as RefCounted if is_instance_valid(actual_field) else null

func _release_receipt(helper: RefCounted,id: String,reason: String) -> void:
	if helper==null: return
	var state: Dictionary = helper.call("get_fade_runtime_state")
	_check(state.get("runtime_hooked")==false and state.get("building_count")==0,"actual old Field helper released "+id)
	_check(helper.get("_images").is_empty() and helper.get("_actor_pixels").is_empty(),"actual release image/current-frame caches empty "+id)
	# Exact Color receipt is read from the real runtime release, never caused by QA.
	var receipt: Dictionary = helper.call("get_last_release_state") if helper.has_method("get_last_release_state") else {}
	var restored: Variant = receipt.get("restored_buildings")
	var expected_ids: Array = FADE.PREVIEW_BUILDINGS[id]
	var valid: bool = receipt.get("operation")=="release" and typeof(receipt.get("building_count"))==TYPE_INT and receipt.get("building_count")==expected_ids.size() and restored is Array and restored.size()==expected_ids.size()
	var seen: Dictionary = {}
	if restored is Array:
		for row: Variant in restored:
			if not row is Dictionary or typeof(row.get("id"))!=TYPE_STRING or not row.get("base_color") is Color or not row.get("after_color") is Color:
				valid = false
				continue
			valid = valid and row.id in expected_ids and not seen.has(row.id) and var_to_bytes(row.base_color)==var_to_bytes(row.after_color)
			seen[row.id] = true
	_check(valid,"actual real teardown restored every registered authored Color "+id)
	lifecycle.append({"scene_id":id,"reason":reason,"after_release":_safe(state),"release_receipt":_safe(receipt),"test_called_release":false})

func _open_actual(id: String) -> bool:
	var old_helper := _held_helper()
	var old_id := String((actual_field.get("_current_scene") as SceneScript).scene_id) if is_instance_valid(actual_field) else ""
	var old_reference: WeakRef = weakref(actual_field) if is_instance_valid(actual_field) else null
	if actual_probe!=null: actual_probe.call("release"); actual_probe = null
	if actual_raw!=null:
		_check(actual_raw.call("verify_sources")==true,"previous region actual independent sources unchanged")
		actual_raw.call("release"); actual_raw = null
	var accepted: Variant = root.get_node("SceneRouter").call("go_field_smart",StringName(id),null,"",-1,3)
	if not _check(accepted==true,"PUBLIC_API_NOT_INPUT candidate rebuild "+id) or not _check(await _wait_actual(id),"actual candidate Field ready "+id): return false
	if old_helper!=null:
		_check(old_reference.get_ref()==null,"prior Field naturally freed on public rebuild "+old_id)
		_release_receipt(old_helper,old_id,"PUBLIC_API_NOT_INPUT_SCENE_REBUILD")
	var definition: SceneScript = actual_field.get("_current_scene") as SceneScript
	_check(definition.has_meta("city_enclosure_manifest_sha") and definition.background_path==actual_authors[id].ground_path,"real candidate ground + enclosure, not preview backdrop "+id)
	actual_raw = RAW.new()
	if not _check(actual_raw.call("configure_city",definition,true)==true,"actual independent city full17/source binding "+id): return false
	actual_probe = PHYSICAL.new()
	if not _check(actual_probe.call("configure",self,actual_field,actual_authors[id],_check,_unused_capture)==true,"original full875/17/source/Physics probe "+id): return false
	var actor: Player = actual_field.get("_player") as Player
	current_actor_color = var_to_bytes(actor.sprite.modulate)
	current_actor_self_color = var_to_bytes(actor.sprite.self_modulate)
	var helper := _held_helper()
	_check(helper!=null and helper.get_script().resource_path==RUNTIME_PATH,"Field selected exact NEW runtime "+id)
	var state: Dictionary = actual_field.call("get_city_building_fade_debug")
	_check(state.get("runtime_hooked")==true and state.get("opacity")==.55 and state.get("seconds")==.18,"actual runtime .55/.18 contract "+id)
	var expected_ids: Array = FADE.PREVIEW_BUILDINGS[id]
	var ids: Array = []
	for row: Dictionary in state.get("buildings",[]): ids.append(row.id)
	_check(ids.size()==expected_ids.size(),"exact whitelist building count "+id)
	for expected: String in expected_ids: _check(ids.count(expected)==1,"exact building whitelist "+id+"/"+expected)
	current_nonbuilding_base.clear()
	for object: Dictionary in actual_authors[id].objects:
		if object.id in expected_ids: continue
		var sprite: Sprite2D = actual_probe.call("prop",String(object.id))
		if sprite!=null: current_nonbuilding_base[object.id] = var_to_bytes(sprite.self_modulate)
	return failures==0

func _source_hits(actor: Player,prop: Sprite2D,base: Color) -> int:
	# Original disk PNG alpha; import alpha is checked separately before first input.
	var texture := Image.load_from_file(actor.sprite.texture.resource_path)
	if texture==null: return -1
	var image := Image.load_from_file(prop.texture.resource_path)
	if image==null: return -1
	var cell := Vector2i(texture.get_width()/actor.sprite.hframes,texture.get_height()/actor.sprite.vframes)
	var origin := actor.sprite.frame_coords*cell
	var ar := actor.sprite.get_rect()
	var pr := prop.get_rect()
	var count := 0
	for y: int in cell.y:
		for x: int in cell.x:
			if texture.get_pixelv(origin+Vector2i(x,y)).a<=0: continue
			var uv := (Vector2(x,y)+Vector2(.5,.5))/Vector2(cell)
			if actor.sprite.flip_h: uv.x=1-uv.x
			if actor.sprite.flip_v: uv.y=1-uv.y
			var point := actor.sprite.to_global(ar.position+uv*ar.size)
			var puv := (prop.to_local(point)-pr.position)/pr.size
			if puv.x<0 or puv.y<0 or puv.x>=1 or puv.y>=1: continue
			if prop.flip_h: puv.x=1-puv.x
			if prop.flip_v: puv.y=1-puv.y
			if _alpha(image,puv*Vector2(image.get_size())-Vector2(.5,.5))*prop.modulate.a*base.a>0: count+=1
	return count

func _move(label: String,target: Vector2,direct: bool=false) -> bool:
	var result: Dictionary = await actual_driver.call("drive",actual_field,target,Callable(actual_probe,"clear")) if direct else await actual_probe.call("move_to",target)
	moves.append({"label":label,"target":target,"actual_input":result})
	return _check(result.get("ok")==true,"ordinary INPUT full875/17/source/Physics reaches "+label)

func _observe_actual(label: String,target_id: String,require_positive: bool=false,require_restored: bool=false) -> void:
	# Do not call refresh or inject delta: actual priority100 Field callback owns it.
	var start := Time.get_ticks_usec()
	var frames := 0
	while frames<8 or Time.get_ticks_usec()-start<300000:
		await process_frame
		frames += 1
		if Time.get_ticks_usec()-start>3000000: break
	await actual_driver.call("completed_actor_stage")
	await RenderingServer.frame_post_draw
	var player: Player = actual_field.get("_player") as Player
	var helper := _held_helper()
	var state: Dictionary = actual_field.call("get_city_building_fade_debug")
	var target: Sprite2D = actual_probe.call("prop",target_id)
	var target_records: Array = []
	for row: Dictionary in state.buildings:
		if row.id==target_id: target_records.append(row)
	if not _check(target_records.size()==1 and is_instance_valid(target),"one actual target record "+label): return
	var target_row: Dictionary = target_records[0]
	var style: String = String(player.get("_weapon_style"))
	var direction: String = String(player.get("_direction"))
	var moving: bool = player.get("_is_moving")==true
	var frames_expected: int = 8 if moving else 4
	var strip_expected := "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/%s/lengguyun_%s_%s_%s_25d_%df.png"%[style,style,"walk" if moving else "idle",direction,frames_expected]
	_check(player.sprite.texture.resource_path==strip_expected and player.sprite.hframes==frames_expected and player.sprite.vframes==1 and not player.sprite.region_enabled and not player.sprite.flip_h and not player.sprite.flip_v and first.has(strip_expected),"actual current actor source/strip/frame protected before await "+label)
	_asset_pair(strip_expected)
	_asset_pair(target.texture.resource_path)
	var registered: Array = []
	for row: Dictionary in helper.get("_props"):
		if row.sprite==target and row.id==target_id: registered.append(row)
	if not _check(registered.size()==1,"one actual registered prop "+label): return
	var actor_raw: float = player.get_depth_sort_y()
	var prop_raw: float = target.to_global(registered[0].foot_local).y
	var actor_bytes := PackedFloat32Array([actor_raw]).to_byte_array()
	var prop_bytes := PackedFloat32Array([prop_raw]).to_byte_array()
	var hits := _source_hits(player,target,target_row.base_color)
	var geometry: RefCounted = actual_probe.get("alpha") as RefCounted
	var actual_prop_in_front: bool = geometry.call("actual_in_front",target,player)
	var expected := actor_bytes.decode_float(0)<prop_bytes.decode_float(0) and actual_prop_in_front and hits>0
	_check(hits>=0 and target_row.hit==expected,"independent original PNG + native foot trigger "+label)
	_check(is_equal_approx(float(target_row.factor),.55 if expected else 1.),"natural .18 settled target "+label)
	if require_positive: _check(expected and target_row.hit==true and is_equal_approx(float(target_row.factor),.55),"actual visible building fade positive "+label)
	if require_restored: _check(not expected and target_row.hit==false and target_row.factor==1.,"actual front/leave authored opacity recovery "+label)
	_check(var_to_bytes(player.sprite.modulate)==current_actor_color and var_to_bytes(player.sprite.self_modulate)==current_actor_self_color,"actual Player base colors unchanged "+label)
	_check(actual_probe.call("raw_evidence",player.position).get("clear")==true and actual_probe.call("physical_clear",player.position)==true,"actual observed full875+17/source and Physics "+label)
	var debug: Dictionary = actual_field.call("get_v14_modular_overlap_debug")
	var union_exact: bool = actual_probe.call("exact_union",debug)
	_check(union_exact,"original independent current-frame LINEAR union unchanged "+label)
	var exclusions: Array = []
	var expected_ids: Array = FADE.PREVIEW_BUILDINGS[String((actual_field.get("_current_scene") as SceneScript).scene_id)]
	for object: Dictionary in actual_authors[String((actual_field.get("_current_scene") as SceneScript).scene_id)].objects:
		if object.id in expected_ids: continue
		var sprite: Sprite2D = actual_probe.call("prop",String(object.id))
		if sprite!=null:
			_check(not (state.buildings as Array).any(func(row: Dictionary): return row.id==object.id),"nonbuilding never registered "+String(object.id))
			_check(current_nonbuilding_base.has(object.id) and var_to_bytes(sprite.self_modulate)==current_nonbuilding_base[object.id],"actual nonbuilding color not faded "+String(object.id))
			exclusions.append({"id":object.id,"display_color":_color(sprite.self_modulate)})
	var image := root.get_texture().get_image()
	var path := output+label+".png"
	_check(image!=null and image.save_png(path)==OK,"real candidate ground GPU capture "+label)
	observations.append({"label":label,"scene_id":String((actual_field.get("_current_scene") as SceneScript).scene_id),"actual_root":player.position,"frames":frames,"elapsed_usec":Time.get_ticks_usec()-start,
		"actor_raw_float64_hex":PackedFloat64Array([actor_raw]).to_byte_array().hex_encode(),"actor_native_float32_hex":actor_bytes.hex_encode(),"prop_raw_float64_hex":PackedFloat64Array([prop_raw]).to_byte_array().hex_encode(),"prop_native_float32_hex":prop_bytes.hex_encode(),
		"independent_original_alpha_hits":hits,"independent_expected_hit":expected,"actual_prop_in_front_by_Z_sibling":actual_prop_in_front,"current_frame_union_byte_exact":union_exact,"runtime":_safe(state),"actor_body_colors":[_color(player.sprite.modulate),_color(player.sprite.self_modulate)],
		"nonbuilding_exclusions":exclusions,"actual_ghost":_ghost_record(),
		"path":path,"sha256":FileAccess.get_sha256(path),"full_geometry_or_visual_approval":false})
	_write_actual(label+".json",observations[-1])

func _gate_hole() -> void:
	if not await _move("gate_center_passage",Vector2(1536,1600)): return
	var sprite: Sprite2D = actual_probe.call("prop","south_gate")
	var image := Image.load_from_file(sprite.texture.resource_path)
	var pixels: Array = []
	for pixel: Vector2i in [Vector2i(768,620),Vector2i(768,700),Vector2i(768,800),Vector2i(768,850)]:
		var a := image.get_pixelv(pixel).a
		_check(a==0.,"original gate transparent source witness retained")
		pixels.append({"pixel":[pixel.x,pixel.y],"alpha":a})
	_write_actual("original_gate_hole_source.json",{"path":sprite.texture.resource_path,"sha256":FileAccess.get_sha256(sprite.texture.resource_path),"source_hole_witnesses":pixels,"full_actor_alpha_overlap_not_assumed_zero":true})
	await _observe_actual("01_gate_actual_passage","south_gate")

func _ghost_record() -> Dictionary:
	var debug: Dictionary = actual_field.call("get_v14_modular_overlap_debug")
	return {"active":debug.get("active"),"pixels":debug.get("pixels"),"prop_hits":debug.get("prop_hits"),"native_depth_key":debug.get("native_depth_key"),"raw_actor_foot_y":debug.get("raw_actor_foot_y"),"retained_original_ghost_not_full_solid_actor":true}

func _run() -> void:
	var bridge: Node = root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended"): quit(1); return
	checkpoint_default = bridge.call("is_checkpoint_saves_suspended")
	bridge.call("set_checkpoint_saves_suspended",true)
	players = _players(); slot = root.get_node("SaveManager").get("active_slot")
	_check(checkpoint_default==false and bridge.call("is_checkpoint_saves_suspended")==true,"checkpoint first, before await/fixture")
	var args := OS.get_cmdline_user_args()
	var legal: Array[String] = ["--building-fade-actual-field","--fresh-start-only","--luoyang-v3-candidate","--luoyang-enclosure-v11-candidate","--audio-preview-dummy","--qa-gpu-approved"]
	_check(args.size()==legal.size(),"only explicit limited actual candidate/Dummy GPU arguments")
	for arg: String in legal: _check(args.count(arg)==1,"unique actual Field flag "+arg)
	_check(DisplayServer.get_name()!="headless" and AudioServer.get_driver_name()=="Dummy" and Engine.time_scale==1. and FileAccess.get_sha256(OS.get_executable_path())==ENGINE_SHA,"actual GPU/installed engine and explicit untested Dummy")
	output = "res://build/joint_world_luoyang_20261003_qa/building_fade_actual_field_%d_%d_%d/"%[int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) and DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))==OK,"unique BUILD actual evidence"): quit(1); return
	_path_sources()
	_write_actual("source_before.json",first)
	actual_driver = INPUT.new(); actual_driver.call("configure",self)
	if failures==0:
		for name: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(name).call("reset_for_new_game")
		var router: Node = root.get_node("SceneRouter")
		router.call("restore_navigation_state",router.call("get_navigation_state"),&"",&"world_map_jianghu")
		initial_navigation = router.call("get_navigation_state").duplicate(true)
		_check(initial_navigation.get("world_map_version")==14 and String(router.call("get_active_world_map_scene"))=="world_map_jianghu","current formal world14 unaffected")
		var state: Node = root.get_node("GameState")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: state.call("set_flag",StringName(flag),true)
		state.set("current_chapter",4)
		for id: String in ACTUAL_IDS:
			if not await _open_actual(id): break
			if id=="ch4_s0_luoyang_gate": await _gate_hole()
			elif id=="ch4_s3_luoyang_market":
				_asset_pair(INN)
				if await _move("inn_original_route_start",Vector2(1000,1060)):
					var points := PackedVector2Array([Vector2(1000,1060),Vector2(735,920),Vector2(735,830)])
					var result: Dictionary = await actual_driver.call("follow",actual_field,points,Callable(actual_probe,"clear"),Callable(actual_probe,"segment"))
					moves.append({"label":"original_inn_and_paper","original_points_native_hex":points.to_byte_array().hex_encode(),"actual_input":result})
					_check(result.get("ok")==true,"original inn route normal input unchanged")
					if result.get("ok")==true and await _move("inn_behind828",Vector2(735,828),true):
						await _observe_actual("02_inn_behind","inn",true)
						if await _move("inn_front832",Vector2(735,832),true): await _observe_actual("03_inn_front","inn",false,true)
						if await _move("inn_leave",Vector2(1000,1060)): await _observe_actual("04_inn_leave","inn",false,true)
			else:
				var target := "magistrate_hall" if id=="ch4_s1_luoyang_yamen" else "north_canal_warehouse"
				await _observe_actual("rebuild_"+id,target)
	await _finish_actual()

func _finish_actual() -> void:
	var old_helper := _held_helper()
	var old_id := String((actual_field.get("_current_scene") as SceneScript).scene_id) if is_instance_valid(actual_field) else ""
	if actual_probe!=null: actual_probe.call("release"); actual_probe = null
	if actual_raw!=null:
		_check(actual_raw.call("verify_sources")==true,"final independent region source verification")
		actual_raw.call("release"); actual_raw = null
	var reference: WeakRef = weakref(actual_field) if is_instance_valid(actual_field) else null
	if is_instance_valid(current_scene): current_scene.queue_free(); current_scene = null
	actual_field = null
	for tick: int in 8: await process_frame
	if old_helper!=null:
		_check(reference.get_ref()==null,"final owned Field naturally freed")
		_release_receipt(old_helper,old_id,"OWNED_FIELD_EXIT")
	actual_driver.call("release"); actual_driver = null
	if not initial_navigation.is_empty():
		var router: Node = root.get_node("SceneRouter")
		router.call("reset_for_new_game"); router.call("restore_navigation_state",router.call("get_navigation_state"),&"",&"world_map_jianghu")
		_check(router.call("get_navigation_state")==initial_navigation,"public current navigation restored")
	_release_process_cursors()
	for tick: int in 8: await process_frame
	var same := true
	var last: Dictionary = {}
	for path: String in first:
		last[path] = _file(path)
		if last[path]!=first[path]: same = false
	_check(same,"fresh complete source/import/compiled remains unchanged after final await")
	_check(players==_players() and slot==root.get_node("SaveManager").get("active_slot"),"15 normal saves/active slot unchanged, outer precise ticks required")
	_check(root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended")==true and AudioServer.get_driver_name()=="Dummy","checkpoint held through quit; audio remains untested")
	_check(lifecycle.size()==4,"four actual candidate Field release lifecycles")
	_check(observations.size()==6,"gate/two intermediate district/inn behind-front-leave actual captures")
	var result := {"scope":"LUOYANG_BUILDING_FADE_LIMITED_ACTUAL_CANDIDATE_FIELD_NOT_APPROVAL","complete":failures==0,"checks":checks,"failures":failures,
		"audio_tested":false,"dummy_audio_explicit":true,"production_field_integrated":true,"approval":false,"full_geometry_tested":false,"full_gameplay_tested":false,"historical_compatibility_tested":false,
		"checkpoint_default":checkpoint_default,"checkpoint_held_to_quit":true,"source_before":first,"source_after":last,"source_unchanged":same,"players_before":players,"players_after":_players(),
		"active_slot_before":slot,"active_slot_after":root.get_node("SaveManager").get("active_slot"),"normal_input_moves":moves,"actual_observations":observations,"four_region_release":lifecycle,
		"cursor_cleanup":cursor_cleanup,"public_scene_rebuild_is_not_input_credit":true,"ghost_retained":true,"outer_fresh_prelaunch_exact_UTC_ticks_and_full_stderr_required":true}
	_write_actual("result.json",result)
	print("BUILDING_FADE_ACTUAL_FIELD_RESULT "+output+"result.json checks="+str(checks)+" failures="+str(failures))
	quit(0 if failures==0 else 1)
