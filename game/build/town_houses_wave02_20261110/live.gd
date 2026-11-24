extends "res://build/victory_quest_20261108/story_live.gd"

const JINLING := &"openworld_jinling_city"
const LANXI := &"openworld_lanxi_zhai"
const HOUSES := {
	"PocketHome1": "house_back",
	"PocketHome2": "house_front",
	"PocketHome4": "house_side",
	"PocketHome11": "small_cottage",
	"PocketHome17": "small_cottage",
	"PocketHome18": "house_front",
	"PocketHome20": "house_side",
}
const VARIANTS := [
	"silk_back_w","silk_storage","silk_workshop","north_home_mid",
	"east_riverside_house","west_home_front","south_market_w","south_market_e","east_home_side",
	"south_market_rear_w","south_market_rear_e"
]

func _run() -> void:
	await process_frame
	root.get_node("PlatformBridge").set_checkpoint_saves_suspended(true)
	router=root.get_node("SceneRouter")
	state=root.get_node("GameState")
	quests=root.get_node("QuestManager")
	dialogue=root.get_node("DialogPlayer")
	state.reset_for_new_game()
	quests.reset_for_new_game()
	router.reset_for_new_game()
	var registry: Script = load("res://build/three_towns_world_20261029j_system01/town_registry.gd")
	expect(registry.source_valid(),"unchanged strict native source validation")
	var city := await enter(JINLING)
	if city!=null:
		await settle(city)
		await verify_jinling(city)
	var village := await enter(LANXI)
	if village!=null:
		await settle(village)
		await verify_lanxi(village)
	print("TOWN_HOUSES_WAVE02 checks=",checks," failures=",failures)
	quit(1 if failures else 0)

func verify_jinling(field: Node) -> void:
	var author: Script = load("res://build/jinling_city_20261029_system01/city_author.gd")
	var district: Script = load("res://build/city_neighborhoods_20261031d/neighborhoods.gd")
	var prior := {}
	for row in district.buildings("jinling",author.building_specs_before31d()):prior[row.id]=row
	var count := 0
	var previous_repeat := 0
	var next_repeat := 0
	for row in author.building_specs():
		var old: Dictionary = prior[row.id]
		if String(old.texture).contains("_shop_residence_"):previous_repeat+=1
		if String(row.texture).contains("_shop_residence_"):next_repeat+=1
		if row.id not in VARIANTS:
			expect(row==old,"untouched "+String(row.id))
			continue
		count+=1
		var body: Rect2 = row.body
		expect(row.foot==old.foot and old.body.encloses(body) and body.has_area(),"old footprint not expanded "+String(row.id))
		expect(row.texture!=old.texture and ResourceLoader.exists(row.texture) and row.native_scale>0,"native artwork switched "+String(row.id))
	expect(count==11 and previous_repeat==20 and next_repeat==9,"eleven duplicate fronts replaced")
	await sample(field,Vector2(2380,1195),"jinling-silk.png")
	await sample(field,Vector2(2805,3155),"jinling-south.png")
	await walk_right(field,Vector2(2750,3160),false)
	var reeds := zone_to(field,&"openworld_jinling_reed_marsh")
	expect(reeds!=null and reeds.global_position.distance_to(author.REED_FOOT)<12,"original reed marsh gate preserved")

func verify_lanxi(field: Node) -> void:
	var native: Node2D = field.get("native_town")
	if not expect(is_instance_valid(native),"native Lanxi scene active"):return
	var terrain: Node = native.get("terrain")
	for id in HOUSES:
		var home := native.get_node("Town/"+id) as Node2D
		var art := home.get_node("Art") as Sprite2D
		var shape := home.get_node("Body/Outline") as CollisionPolygon2D
		var rect: Rect2 = home.get_meta("visual_rect")
		var elevation: float = home.get_meta("elevation")
		expect(rect.size.x>=490 and is_equal_approx(art.scale.x,art.scale.y) and art.texture.resource_path.get_file()==HOUSES[id]+".png","correct full building "+id)
		expect(int(home.get_meta("terrain_level"))==terrain.level_at(home.global_position) and shape.polygon.size()==4 and elevation>=0,"old terrain and body "+id)
	# Samples either side of the widened roof silhouettes, not a teleport across a cliff.
	await sample(field,Vector2(2320,2080),"lanxi-dye-lane.png")
	await sample(field,Vector2(1300,1600),"lanxi-west-homes.png")
	await walk_right(field,Vector2(1290,1610),true)
	expect(native.get_node("Town/PocketInfill7/Art").scale==Vector2(.5,.5),"tight riverside plot left unchanged")

func sample(field: Node, point: Vector2, file_name: String) -> void:
	var actor: Player = await position_at(field,point)
	check_clear(actor,"walkable sightline "+file_name)
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	get_root().get_texture().get_image().save_png("user://"+file_name)

func walk_right(field: Node, point: Vector2, physical: bool) -> void:
	var actor: Player = await position_at(field,point)
	var before := actor.global_position
	if physical:
		var key := InputEventKey.new()
		key.keycode=KEY_D
		key.physical_keycode=KEY_D
		key.pressed=true
		Input.parse_input_event(key)
		await create_timer(0.2).timeout
		key=InputEventKey.new()
		key.keycode=KEY_D
		key.physical_keycode=KEY_D
		Input.parse_input_event(key)
	else:
		Input.action_press("move_right")
		await create_timer(0.25).timeout
		Input.action_release("move_right")
	await physics_frame
	expect(actor.global_position.x-before.x>=28,"actual rightward input traverses "+String(router.get_current_field_id())+" "+str(before)+" -> "+str(actor.global_position))
