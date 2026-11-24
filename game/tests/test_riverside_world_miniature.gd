extends "res://build/world_sects_cities_20261031c_qa01/probe_base_ROOT_ONLY.gd"

const SIZE:=Vector2(12288,8192)
const DOOR:=Vector2(5600,3300)
const WORLD:=&"world_map_jianghu"
const LOCAL:=&"adventure_luoyang_riverside_route"
const ART:="res://art/modules/riverside_world_miniature_20261108/riverside_vignette.png"
const DEPTH=preload("res://scripts/world/v14_modular_overlap.gd")
const LINKS="res://build/adventure_world_20261031f_system01/world_links.gd"

func _run() -> void:
	directory="user://"
	await process_frame
	router=root.get_node("SceneRouter")
	var links:=root.get_node("AdventureRuntime/AdventureWorldLinks31f")
	var navigation:=root.get_node("CityNavigationRuntime")
	need(navigation.call("get_debug_state").ready,"strict CityNavigation source gate remains ready")
	if not need(suspended and router.call("go_field_smart",WORLD,DOOR/SIZE,"",16,-1),"official World16 setup"):
		finish(); return
	if not await ready_field(WORLD): finish(); return
	for n in range(75):
		if links.get("world_owner")==field: break
		await tick()
	var layer:=world.get_node_or_null("AdventureWorldLinks31f")
	if not need(layer!=null,"official world overlay"): finish(); return
	var prop:=layer.get_node_or_null("adventure31f_riverside_WholeLandmark") as Sprite2D
	var gate:=layer.get_node_or_null("adventure31f_riverside") as ExitZone
	if not need(prop!=null and prop.texture.resource_path==ART and gate!=null,"new vignette on original door"): finish(); return
	var depth:=DEPTH.new()
	need(depth.effective_z(prop)<depth.effective_z(actor),"miniature cannot occlude player")
	need(gate.marker_visual.z_index==4096 and gate.prompt.z_index==4096 and not gate.prompt.z_as_relative,"top-layer marker and text")
	need(is_equal_approx(prop.texture.get_width()*prop.scale.x,400.0) and not layer.has_node("adventure31f_riverside_NativeFootprint_0"),"compact art without fake building collider")
	need(foot().distance_to(DOOR)<.01 and gate.call("can_enter"),"original route foot and prompt")
	await shot("riverside_original_door")
	var offset:=Vector2(0,-90)
	if not await walk(DOOR+offset,50): finish(); return
	await shot("riverside_actor_over_miniature")
	if not await walk(DOOR,50): finish(); return
	var source:=foot()
	if not await enter(LOCAL): finish(); return
	var returning: ExitZone
	for n in range(75):
		returning=links.get("_return_zone") as ExitZone
		if returning!=null: break
		await tick()
	if not need(returning!=null and returning.target_scene_id==String(WORLD),"local doorway still returns to World"): finish(); return
	var wait_until:=Time.get_ticks_msec()+15000
	while Time.get_ticks_msec()<wait_until:
		var state: Dictionary=navigation.call("get_debug_state")
		if state.attached_scene==String(LOCAL) and not navigation.call("view_preparation_busy") and actor.get("can_move")==true: break
		await tick()
	if not need(navigation.call("get_debug_state").attached_scene==String(LOCAL) and not navigation.call("view_preparation_busy") and actor.get("can_move")==true,"wait for local loading view and input readiness"): finish(); return
	if not await walk(Vector2(2048,2856.96),120): finish(); return
	if not await enter(WORLD): finish(); return
	need(foot().distance_to(source)<.01,"returns to precise World departure foot")
	finish()

func finish() -> void:
	print("RIVERSIDE_MINIATURE_RESULT ",checks,"/",errors.size())
	super.finish()
