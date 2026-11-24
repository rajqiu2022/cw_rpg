extends "res://tests/test_luoyang_assembled_scenes_key_retry4_20261016b.gd"
## NEW narrow draft. ROOT alone compiles/runs after final publication and pins.
## No parent _run/_precheck/_exercise, old anvil fade or whole-city replay.
const KEY_READY=false
const BASE_PATH="res://tests/test_luoyang_assembled_scenes_key_retry4_20261016b.gd"
const BASE_SHA="91f27cf8b07d1b65d459c75661052d87895c715a6ca6f24377342ea1d6d5af35"
const ANNEX_PATH="res://scripts/city/luoyang_yamen_annex_runtime_20261016.gd"
const FINAL_PINS={
	"res://tests/helpers/v15_input_driver.gd":"a3c59fde8d9f55d71919276286dc720e177ef3dc046d224204868a24881de5d7",
	"res://tests/helpers/v15_field_raw_oracle.gd":"dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb",
	"res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd":"73e09f2fbccf696c334b8d60120df0cbe37535d4da8bd22f856d913db4889c0a",
	"res://data/maps/luoyang_assembled_rooms_20261016b/smithy_author.json":"760e0169750c73579cd59679dddeaf89c7e2de349e83dd90c812cfaea37ae9b9",
	"res://scripts/city/luoyang_assembled_low_furniture_fade_20261016.gd":"829e8e708813ffcbc759fef1a3fda01945b3b169f56626efbf9b285e69906524",
	"res://scripts/city/luoyang_assembled_rooms_20261016b.gd":"4552f6ecd6f5dff5d34646b5a482b116eea98c4fbfd2b98d669fe0ef129df1b8",
	"res://scripts/field/field_walkable_controller.gd":"PENDING_FINAL_HOOK",
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"PENDING_FINAL_HOOK",
	ANNEX_PATH:"PENDING_PUBLICATION_AND_IMPORT"
}
var annex: Variant
var room_refs: Array[WeakRef]=[]
var room_identity: Dictionary={}
var npc_alpha: Dictionary={}

func _precheck() -> bool:
	if not _check(KEY_READY,"Explicit final source readiness, draft must refuse"): return false
	if not _track(BASE_PATH,BASE_SHA): return false
	for path: String in FINAL_PINS:
		if not _track(path,FINAL_PINS[path]): return false
	annex=load(ANNEX_PATH)
	if not _check(annex!=null and annex.enabled() and not annex.FORMAL_ENABLED and annex.FLAG in OS.get_cmdline_user_args() and ASSEMBLY.FORMAL_ENABLED,"Only new annex candidate; smithy remains ordinary formal"): return false
	room_author=ASSEMBLY.author()
	if not _check(not room_author.is_empty(),"Existing six-component author present"): return false
	for path: String in room_author.source_sha256:
		if not _track(path,room_author.source_sha256[path]): return false
	for path: String in ASSEMBLY.source_paths():
		if not source_before.has(path) and not _track(path): return false
	var original_config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(R.BIND_PATH))
	var child_config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(annex.BIND_PATH))
	if not _track(R.BIND_PATH,R.BIND_SHA) or not _track(annex.BIND_PATH,annex.BIND_SHA): return false
	for config: Dictionary in [original_config,child_config]:
		for path: String in config.source_sha256:
			if not source_before.has(path) and not _track(path,config.source_sha256[path]): return false
	for id: String in ["ch4_s3_luoyang_market","ch4_s1_luoyang_yamen"]:
		var item: Dictionary=original_config.cities[id] if id=="ch4_s3_luoyang_market" else child_config
		var pin: String=R.PINS[id] if id=="ch4_s3_luoyang_market" else String(item.manifest_sha256)
		if not _track(item.manifest_path,pin): return false
		var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(item.manifest_path))
		manifest_records[id]=manifest.record; candidate_manifest_paths[id]=item
		var canonical:=ResourceLoader.load("res://data/scenes/"+id+".tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var closure: Dictionary=C._transition_sources(canonical,false)
		if not _check(not closure.is_empty(),"Full production-declared current source closure "+id): return false
		for path: String in closure:
			if not source_before.has(path) and not _track(path): return false
	for path: String in annex.source_paths():
		if not source_before.has(path) and not _track(path): return false
	return _track(get_script().resource_path)

func _bind_geometry() -> bool:
	if String(scene.scene_id)!="ch4_s1_luoyang_yamen":
		var accepted: bool=super._bind_geometry()
		return accepted and (String(scene.scene_id)==String(ASSEMBLY.ROOM) or _ready_city_proof())
	if oracle!=null: oracle.call("release")
	oracle=RAW.new(); floors.clear(); exact_solids.clear()
	current_size=field.get("_world_size")
	var id:=String(scene.scene_id)
	if not _check(annex.bound(scene) and current_size==Vector2(3072,2048) and C._records.has(id),"Actual new annex child and existing prepared record"): return false
	var record: Dictionary=C._records[id].duplicate(true)
	var binding: Variant=record.get("annex_runtime_binding_sha")
	var unchanged: Variant=record.get("annex_parent_semantics_unchanged")
	record.erase("annex_runtime_binding_sha"); record.erase("annex_parent_semantics_unchanged")
	if not _check(binding==annex.BIND_SHA and unchanged==true and _complete_publication_record(record,manifest_records[id],id),"Whole child record, only two declared annex receipts removed"): return false
	var item: Dictionary=candidate_manifest_paths[id]
	if not _check(scene.map_layout.walkable_mask_path==item.walk_path and scene.get_meta("yamen_annex_published_scene_path","")==item.scene_path and scene.map_layout.visual_objects.size()==24,"Actual child24 and new source-bound navigation"): return false
	var clone: Resource=scene.map_layout.duplicate(true)
	clone.set("design_size",Vector2i(current_size))
	var declarations: Array[Dictionary]=[]
	for object: Dictionary in record.objects:
		var shapes: Array[PackedVector2Array]=[]
		var extent:=Vector2(object.collision_size_px[0],object.collision_size_px[1])
		if extent.x>0 and extent.y>0:
			var center:=Vector2(object.physical_center_px[0],object.physical_center_px[1])
			var rect:=Rect2(center-extent*.5,extent)
			shapes.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
		for raw: Array in object.solid_polygons_px:
			var poly:=PackedVector2Array()
			for pair: Array in raw: poly.append(Vector2(pair[0],pair[1]))
			shapes.append(poly)
		if not shapes.is_empty(): declarations.append({"id":object.id,"solid_polygons_px":shapes})
		if String(object.id) in ["assembled_east_service_annex","assembled_west_service_annex"]:
			var entry: Dictionary={}
			for visual: Dictionary in scene.map_layout.visual_objects:
				if visual.id==object.id: entry=visual; break
			if not _check(not entry.is_empty() and C._equal_value(entry.city_v3_solid_polygons_px,object.solid_polygons_px),"Native render solid is exact moved record "+String(object.id)): return false
	clone.set("visual_objects",declarations)
	if not _check(bool(oracle.call("configure",clone,"round_world_pixel",0.0)),"Independent child mask/continuous source solids",oracle.get("errors")): return false
	for region: PackedVector2Array in oracle.get("regions"):
		var projected:=PackedVector2Array()
		for point: Vector2 in region: projected.append(point*current_size)
		floors.append(projected)
	for solid: Dictionary in oracle.get("solids"):
		if solid.kind=="exact_world_polygon": exact_solids.append(solid.polygon)
		else:
			var rect: Rect2=solid.rect
			exact_solids.append(PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]))
	return _check(_clear((field.get("_player") as Node2D).position) and not _foot_frame("Yamen_birth").is_empty(),"Actual Yamen birth full875/17/continuous native34x24 body/Physics") and _ready_city_proof()

func _ready_city_proof() -> bool:
	var proof: Dictionary=C.resident_receipt(scene)
	var sources: Dictionary=proof.get("sources",{})
	var valid: bool=proof.get("scene")==scene and proof.get("sources_finalized")==true and not sources.is_empty()
	for path: String in sources:
		if not source_before.has(path) or (source_before.has(path) and sources[path]!=source_before[path].sha256): valid=false
	rows.append({"kind":"ACTUAL_SOURCE_FINALIZED_CITY","id":String(scene.scene_id),"source_count":sources.size(),"source_finalized":proof.get("sources_finalized",false),"all_in_own_before_scope":valid})
	return _check(valid,"Actual production full first/final source proof, no prepare getter")

func _workbench() -> Sprite2D:
	for node: Sprite2D in field.get("_scene_object_nodes"):
		if String(node.name)=="SceneObject_workbench": return node
	return null

func _identity() -> Dictionary:
	var player:=field.get("_player") as CharacterBody2D
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	return {"field":field.get_instance_id(),"player":player.get_instance_id(),"shape":shape.get_instance_id(),"resource":shape.shape.get_instance_id(),"body":(shape.shape as RectangleShape2D).size,"offset":shape.position,"players":get_nodes_in_group("player").size(),"npcs":get_nodes_in_group("npc").size()}

func _ghost_frame(label: String,behind: bool) -> bool:
	var player:=field.get("_player") as CharacterBody2D
	var actor:=player.get("sprite") as Sprite2D
	var ghost:=player.get("_overlap_ghost") as Sprite2D
	var prop:=_workbench()
	var debug: Dictionary=field.call("get_v14_modular_overlap_debug")
	var fade: Dictionary=field.call("get_city_building_fade_debug")
	if not _check(prop!=null and ghost!=null and _identity()==room_identity and _clear(player.position),"Same native actor/body/groups and full87517/Physics "+label): return false
	var prop_first: bool=prop.z_index<player.z_index or (prop.z_index==player.z_index and prop.get_index()<player.get_index())
	var valid: bool=prop_first==not behind and prop.self_modulate.a==1.0 and prop.modulate.a==1.0 and actor.modulate.a==1.0 and actor.self_modulate.a==1.0
	valid=valid and fade.get("low_furniture_policy")=="OPAQUE_WITH_SOURCE_ALPHA_ACTOR_GHOST" and "workbench" in fade.get("opaque_low_ids",[])
	for building: Dictionary in fade.get("buildings",[]):
		if String(building.id) in ["anvil_stump","bellows","quench_tub","workbench"]: valid=false
	var mask_pixels:=0
	if behind:
		var texture:=debug.get("mask_texture") as Texture2D
		var material:=ghost.material as ShaderMaterial
		if texture==null or material==null: return _check(false,"Live actual-frame ghost texture/material "+label)
		var image:=texture.get_image()
		if image.is_compressed(): image.decompress()
		for y: int in image.get_height():
			for x: int in image.get_width():
				if image.get_pixel(x,y).a>0: mask_pixels+=1
		valid=valid and ghost.is_visible_in_tree() and debug.get("active")==true and int(debug.get("pixels",0))==mask_pixels and mask_pixels>0 and int(debug.get("prop_hits",{}).get("workbench",0))>0
		valid=valid and absf(ghost.modulate.a-.46)<.000001 and absf(float(material.get_shader_parameter("ghost_alpha"))-.46)<.000001 and material.get_shader_parameter("frame_mask")==texture
		valid=valid and ghost.texture==actor.texture and ghost.frame==actor.frame and ghost.hframes==actor.hframes and ghost.vframes==actor.vframes and ghost.position==actor.position and ghost.scale==actor.scale and ghost.flip_h==actor.flip_h and ghost.flip_v==actor.flip_v and ghost.region_rect==actor.region_rect and ghost.region_enabled==actor.region_enabled and ghost.get_parent()==player and ghost.get_class()=="Sprite2D" and ghost.get_groups().is_empty()
	else: valid=valid and not ghost.visible and debug.get("active")==false and int(debug.get("pixels",0))==0
	for npc: Node in field.get("_npc_nodes"):
		var sprite:=npc.get("sprite") as Sprite2D
		if sprite!=null and npc_alpha.has(npc.get_instance_id()): valid=valid and [sprite.modulate,sprite.self_modulate]==npc_alpha[npc.get_instance_id()]
	rows.append({"kind":"OPAQUE_WORKBENCH_CURRENT_FRAME_GHOST","label":label,"engine_frame":Engine.get_process_frames(),"actor_frame":actor.frame,"texture":actor.texture.resource_path,"flip":actor.flip_h,"foot":player.position,"prop_alpha":prop.self_modulate.a,"main_alpha":actor.modulate.a,"ghost_visible":ghost.visible,"ghost_alpha":ghost.modulate.a,"mask_nonzero":mask_pixels,"prop_hits":debug.get("prop_hits",{}),"prop_first":prop_first,"identity":_identity(),"native_depth":field.call("get_v14_depth_order_debug")})
	if _foot_frame(label).is_empty(): valid=false
	return _check(valid,"Opaque low furniture, exact same-frame visual-only masked actor, unchanged NPCs "+label)

func _work_station(label: String,behind: bool) -> bool:
	var until:=mini(deadline,Time.get_ticks_msec()+3500)
	var seen: Dictionary={}
	while Time.get_ticks_msec()<until and seen.size()<4:
		await RenderingServer.frame_post_draw
		var sprite: Sprite2D=(field.get("_player") as Node).get("sprite")
		var key:=str(sprite.texture.get_instance_id())+":"+str(sprite.frame)
		if seen.has(key): continue
		seen[key]=true
		if not _ghost_frame(label+"_natural"+str(seen.size()),behind): return false
	if not _check(seen.size()==4,"Four naturally displayed frames "+label): return false
	await _capture("workbench_"+label)
	return true

func _workbench_trip() -> bool:
	var city: Node=field
	var remembered: Vector2=(field.get("_player") as Node2D).position
	await driver.call("key",KEY_SPACE)
	if not await _wait(String(ASSEMBLY.ROOM)): return false
	room_identity=_identity()
	for npc: Node in field.get("_npc_nodes"):
		var sprite:=npc.get("sprite") as Sprite2D
		if sprite!=null: npc_alpha[npc.get_instance_id()]=[sprite.modulate,sprite.self_modulate]
	for node: Node in [field,field.get("_player"),_workbench()]: room_refs.append(weakref(node))
	if not await _way(_room_points([[768,717],[500,770],[300,760]]),"spawn_to_workbench_front") or not await _work_station("front",false): return false
	if not await _way(_room_points([[300,760],[200,760],[200,690],[300,690]]),"actual_left_bypass_to_behind") or not await _work_station("behind",true): return false
	# Real short horizontal movement changes facing while still behind the same desk.
	if not await _way(_room_points([[300,690],[308,690],[300,690]]),"normal_input_behind_turn") or not _ghost_frame("behind_turned",true): return false
	if not await _way(_room_points([[300,690],[200,690],[200,780],[400,780],[400,730]]),"safe_fullbody_bypass_to_equalfoot_side") or not await _work_station("equalfoot_side",false): return false
	if not await _way(_room_points([[400,730],[400,780],[300,780],[300,760]]),"front_restored") or not await _work_station("front_restored",false): return false
	if not await _way(_room_points([[300,760],[500,770],[768,717],[768,885]]),"normal_room_exit"): return false
	var started:=Time.get_ticks_usec()
	await driver.call("key",KEY_SPACE)
	if not await _wait("ch4_s3_luoyang_market"): return false
	var elapsed: float=(Time.get_ticks_usec()-started)/1000.0
	if not _check(field==city and (field.get("_player") as Node2D).position.distance_to(remembered)<.3 and elapsed<RETURN_MS,"One same-door resident return hidden+operable below2000ms",elapsed): return false
	await process_frame; await process_frame
	for ref: WeakRef in room_refs:
		if not _check(ref.get_ref()==null,"Released room actor/workbench/Field, no ghost retained"): return false
	return true

func _exercise() -> bool:
	if not await _setup(PLAN.market): return false
	if not await _way(PLAN.market.approach,"ordinary_existing_smithy_entry") or not _portal(PLAN.market) or not await _workbench_trip(): return false
	var setup: Dictionary={"id":"ch4_s1_luoyang_yamen","size":Vector2(3072,2048),"setup_foot":Vector2(2190,1260)}
	if not await _setup(setup): return false
	if not await _way(PackedVector2Array([Vector2(2190,1260),Vector2(2190,1220)]),"east_new_lane_short_INPUT_nativebody"): return false
	if not _check(_clear(Vector2(2190,1150)) and not _physical(Vector2(2640,1160)) and not _clear(Vector2(2640,1160)) and not _physical(Vector2(2110,1280)),"Old east-base corridor clear/new base and original wall still native-solid"): return false
	if not await _overview("yamen_annex_separation"): return false
	# Existing authored court crossing connects the two lanes; no private teleport.
	if not await _way(PackedVector2Array([Vector2(2190,1220),Vector2(2190,1100),Vector2(2050,1100),Vector2(2050,1080),Vector2(1100,1080),Vector2(860,1080),Vector2(860,1120)]),"east_court_west_lane_normal_INPUT"): return false
	return _check(_clear(Vector2(755,1050)) and not _physical(Vector2(590,1050)) and not _clear(Vector2(590,1050)),"West vacated old-base strip now clear/new annex still blocking; no invisible residual wall")

func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+SHARED_MS
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players()
	output="res://build/luoyang_annex_low_furniture_key_20261016/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var complete:=false
	if _precheck():
		_check(DisplayServer.get_name()!="headless" and Engine.time_scale==1,"Actual normal-clock GPU")
		driver=INPUT.new(); driver.call("configure",self)
		for singleton: String in ["GameState","Inventory","QuestManager","BountyManager","InvestigationState","SceneRouter"]: root.get_node(singleton).call("reset_for_new_game")
		for flag: String in ["chapter3_complete","seen_ch4_yamen","chapter4_started"]: root.get_node("GameState").call("set_flag",StringName(flag),true)
		root.get_node("GameState").set("current_chapter",4); initialized=true
		complete=await _exercise()
	if initialized: root.get_node("SceneRouter").call("reset_for_new_game")
	if driver!=null: driver.call("release"); driver=null
	if oracle!=null: oracle.call("release"); oracle=null
	field=null; scene=null
	if initialized and is_instance_valid(current_scene): current_scene.queue_free(); current_scene=null
	if initialized: await process_frame; await process_frame
	var after: Dictionary={}
	for path: String in source_before: after[path]=_fact(path)
	var players_after:=_players()
	_check(after==source_before and players_after==players_before and bridge.call("is_checkpoint_saves_suspended")==true,"Exact own source/15save before-after; no file restoration")
	_check(complete and Time.get_ticks_msec()<deadline,"Fixed120s/60arrival/two setups/one smithy trip only")
	var file:=FileAccess.open(output.path_join("result.json"),FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"scope":"TWO_ANNEX_LANES_ONE_OPAQUE_WORKBENCH_FOUR_STATIONS","complete":complete and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"shared_ms":SHARED_MS,"arrival_ms":ARRIVAL_MS,"return_limit_ms":RETURN_MS,"records":rows,"captures":captures,"source_before":source_before,"source_after":after,"players_before":players_before,"players_after":players_after},"\t")); file.close()
	print("ANNEX_LOW_FURNITURE_KEY=",output,"/result.json")
	quit(0 if complete and failures==0 else 1)
