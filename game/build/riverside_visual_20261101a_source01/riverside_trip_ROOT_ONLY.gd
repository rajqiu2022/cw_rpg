extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"
## Root only: one existing World16 door, natural ground+mini, original return.
const WORLD_SIZE := Vector2(12288,8192)
const SOURCE_FOOT := Vector2(5600,3300)
const LOCAL_ID := &"adventure_luoyang_riverside_route"
const LINK_PATH := "res://build/adventure_world_20261031f_system01/world_links.gd"
const GROUND_PATH := "res://build/riverside_visual_20261101a_system01/natural_ground.gd"
const ASSET_PATH := "res://art/modules/riverside_visual_20261101a/shelter_v1.png"
const ORIGIN := "adventure_world_origin_v1"
var links: Node
var before_core: Dictionary
func _watch() -> void:
	await create_timer(90.0,true,false,true).timeout
	if not done:need(false,"RIVERSIDE_HARD90S");finish()
func boot(_domain: String) -> bool:
	directory="res://build/riverside_visual_20261101a_source01/trip_actual/"+str(OS.get_process_id());DirAccess.make_dir_recursive_absolute(directory)
	await process_frame
	if not need(suspended,"EARLIEST_CHECKPOINT_SUSPENDED_NO_SAVE_API"):return false
	router=root.get_node("SceneRouter")
	links=root.get_node_or_null("AdventureRuntime/AdventureWorldLinks31f")
	if not need(is_instance_valid(links),"ADVENTURE_LINKS_PRESENT"):return false
	return need(FileAccess.get_sha256(ASSET_PATH)=="3da5c59f18a0fdbde2c4dacf188be3ec46d609d185a3b237f14721268e438415","CLEAN_WHOLE_ASSET_EXACT_SHA")
func setup(id: StringName,uv: Variant,version: int=-1) -> bool:
	key(KEY_NONE);var old: int=current_scene.get_instance_id() if current_scene!=null else 0
	records.append({"public_setup_not_continuous_travel":id,"uv":uv,"coordinate_version":16})
	if not need(router.call("go_field_smart",id,uv,"",16,version)==true,"PUBLIC_WORLD16_SETUP"):return false
	return await ready_field(id,old)
func core() -> Dictionary:
	var game: Node=root.get_node("GameState")
	var flags: Dictionary=(game.get("flags") as Dictionary).duplicate(true);flags.erase(ORIGIN)
	var player: Resource=game.get("player") as Resource
	return {"player_instance":player.get_instance_id(),"hp":player.get("hp"),"mp":player.get("mp"),"gold":game.get("gold"),"other_flags":flags}
func wait_links() -> bool:
	for index: int in range(75):
		var state: Dictionary=links.call("get_debug_state")
		if state.get("owner")==field and int(state.get("added_door_count",0))==3:return true
		await tick()
	return need(false,"WORLD_LINKS_ATTACH_TIMEOUT")
func wait_return() -> ExitZone:
	for index: int in range(75):
		var state: Dictionary=links.call("get_debug_state")
		var zone: ExitZone=state.get("return_zone") as ExitZone
		if is_instance_valid(zone) and field.is_ancestor_of(zone):return zone
		await tick()
	need(false,"ORIGINAL_LOCAL_RETURN_BIND_TIMEOUT");return null
func _run() -> void:
	if not await boot(""):finish();return
	before_core=core()
	if not await setup(&"world_map_jianghu",SOURCE_FOOT/WORLD_SIZE):finish();return
	if not await wait_links():finish();return
	if not need(foot().distance_to(SOURCE_FOOT)<.01 and router.call("world_version_for_scene",&"world_map_jianghu")==16,"FORMAL16_SOURCE_FOOT_EXACT"):finish();return
	var door: ExitZone
	for zone: ExitZone in field.get("_exit_nodes"):
		if zone.get_meta("portal_id","")=="adventure31f_riverside":door=zone;break
	var contract: Variant=router.call("layered_world_contract",field.get("_current_scene"))
	if not need(door!=null and bool(door.call("can_enter")) and contract!=null and contract.safe_foot(field.get("_current_scene"),foot()/WORLD_SIZE) and load(LINK_PATH).actor_shape_clear(actor),"FORMAL16_CONTRACT_TRUE_DOOR_SHAPE_CLEAR"):finish();return
	var landmark: Sprite2D=world.get_node_or_null("AdventureWorldLinks31f/adventure31f_riverside_WholeLandmark") as Sprite2D
	if not need(landmark!=null and landmark.texture!=null and not landmark.texture is AtlasTexture and landmark.texture.resource_path==ASSET_PATH,"NEW_FRONT_WHOLE_LANDMARK_NO_CROP"):finish();return
	records.append({"landmark_scale":landmark.scale,"whole_texture":landmark.texture.resource_path,"world_source_foot":foot()})
	await shot("world_riverside_front_landmark")
	if not await enter(LOCAL_ID):finish();return
	var returning: ExitZone=await wait_return()
	if returning==null:finish();return
	var origin: Dictionary=links.call("validated_origin",String(LOCAL_ID))
	if not need(not origin.is_empty() and origin.foot.distance_to(SOURCE_FOOT)<.01 and returning.target_scene_id=="world_map_jianghu","TRUSTED_WORLD_ORIGIN_BOUND_TO_ORIGINAL_LOCAL_RETURN"):finish();return
	var runtime: Node=root.get_node("AdventureRuntime")
	var visuals: Node=field.get("_visual_layer") as Node
	var ground: Polygon2D=visuals.get_node_or_null("RiversideNaturalGround01") as Polygon2D
	var mini: Control=(runtime.get("_ui") as CanvasLayer).get_node_or_null("AdventureTerrainMinimap") as Control
	if not need(ground!=null and mini!=null,"LOCAL_NATURAL_GROUND_AND_MINI_PRESENT"):finish();return
	var viewport: SubViewport=mini.get("_viewport") as SubViewport
	var mini_world: Node=viewport.get_child(0)
	var mini_ground: Polygon2D=mini_world.get_node_or_null("RiversideNaturalGround01") as Polygon2D
	if not need(mini_ground!=null and ground.get_meta("source_route_segment_count")==mini_ground.get_meta("source_route_segment_count") and (ground.material as ShaderMaterial).shader.resource_path==load(GROUND_PATH).SHADER_PATH and (mini_ground.material as ShaderMaterial).shader.resource_path==load(GROUND_PATH).SHADER_PATH,"LOCAL_AND_MINI_SAME_GROUND_SHADER_AND_CENTERLINES"):finish();return
	for child: Node in visuals.get_children():
		if child is Line2D and String(child.name).begins_with("TravelRoute_"):
			if not need(not child.visible,"REJECTED_TUBULAR_ROUTE_RETAINED_BUT_HIDDEN"):finish();return
	for index: int in range(8):await tick()
	await shot("local_riverside_natural_paths_and_minimap")
	if not await walk(Vector2(2048,2856.96),40):finish();return
	if not need(returning.overlaps_body(actor) and bool(returning.call("_can_enter")) and load(LINK_PATH).actor_shape_clear(actor),"ORIGINAL_RETURN_REAL_OVERLAP_AND_CLEARANCE"):finish();return
	if not await enter(&"world_map_jianghu"):finish();return
	for index: int in range(75):
		if (links.call("validated_origin") as Dictionary).is_empty():break
		await tick()
	need(foot().distance_to(SOURCE_FOOT)<.01 and core()==before_core and (links.call("validated_origin") as Dictionary).is_empty(),"TRUE_SPACE_RETURN_EXACT_WORLD_FOOT_AND_CORE_PRESERVED")
	finish()
func finish() -> void:
	if done:return
	key(KEY_NONE);done=true
	var file:=FileAccess.open(directory+"/result.json",FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"records":records,"input_events":inputs,"scope":"one original formalWorld16 riverside door trueSpace enter; NEW whole landmark and naturalpaths+mini images; original local arrow trueSpace exactWorld return; no oldboat/city/battle/gather matrices","real_save_API_calls":0,"actor_camera_writes":0,"production_writes":0},"\t"));file.close()
	quit(0 if errors.is_empty() else 1)
