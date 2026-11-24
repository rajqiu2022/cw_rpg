extends "res://build/east_mainland_20261112/live.gd"

const REGISTRY_PATH := "res://build/three_towns_world_20261029j_system01/town_registry.gd"

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
	var field:=await enter(BAILU)
	if field!=null:
		await inspect(field,["FisherA","FisherB","FisherC","FisherD","BackHouse0","BackHouse1","BackHouse2"],Vector2(1160,1750),"bailu")
		if await boat(field,"openworld_bailu_ferry_boatman","openworld_bailu_ferry_boat",WEST,0):
			await inspect(current_scene,["HouseA","HouseB","HouseC","BackHouse0","BackHouse1"],Vector2(1060,2535),"donghai")
			await boat(current_scene,"openworld_east_sea_port_boatman","openworld_east_sea_port_boat",BAILU,0)
	print("FERRY_SCALE checks=",checks," failures=",failures)
	quit(1 if failures else 0)

func set_foot(field:Node, point:Vector2) -> Player:
	var actor:Player=field.get("_player")
	var town:Node2D=field.get("native_town")
	actor.global_position=point
	town.terrain.reset_actor(town.terrain.level_at(point))
	await physics_frame
	await physics_frame
	return actor

func inspect(field:Node,names:Array[String],camera_foot:Vector2,id:String) -> void:
	var town:Node2D=field.get("native_town")
	for name in names:
		var house:=town.get_node("Town/"+name) as Node2D
		var art:=house.get_node("Art") as Sprite2D
		var shape:=house.get_node("Body/Shape") as CollisionPolygon2D
		expect(art.scale.x==art.scale.y and art.scale.x>=.68,"proportional "+id+" "+name)
		var center := (shape.polygon[0] + shape.polygon[2]) * 0.5
		var actor:=await set_foot(field,shape.to_global(center))
		var body := shape.get_parent() as StaticBody2D
		var point := PhysicsPointQueryParameters2D.new()
		point.position = shape.to_global(center)
		point.collision_mask = body.collision_layer
		var hits := town.get_world_2d().direct_space_state.intersect_point(point,16)
		expect(hits.any(func(hit:Dictionary):return hit.collider==body),"solid foundation "+id+" "+name)
		actor=await set_foot(field,house.position+Vector2(0,85))
		expect((load(REGISTRY_PATH) as Script).actor_shape_clear(actor),"clear approach "+id+" "+name)
	await set_foot(field,camera_foot)
	await create_timer(.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://"+id+".png")



