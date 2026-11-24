extends "res://tests/test_bianzhou_old_post_v2.gd"

const OLD_WAITER := "res://art/characters/street_expansion_v1/npc_inn_waiter_idle_down_4f.png"
const WALK := "res://art/characters/street_expansion_v1/npc_street_merchant_right_walk_8f_v3_runtime.png"
const PORTRAIT := "res://art/characters/portraits/street_expansion_v1/portrait_inn_waiter_v1.png"
const DEPTH := preload("res://scripts/world/v14_modular_overlap.gd")
var _checked_city := false
var _city_before_return: Node

func _ready_field(id: StringName) -> Node:
	var result: Node=await super._ready_field(id)
	if result==null: return null
	if id==CITY and not _checked_city:
		_checked_city=true
		_city_before_return=result
		await _city_npcs(result)
	elif id==POST:
		await _depth_at_front(result)
	return result

func _city_npcs(field: Node) -> void:
	var waiter: NPCNode
	var merchants: Array[NPCNode]=[]
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.sprite_path==OLD_WAITER:
			_expect(npc.sprite.hframes==4 and npc.sprite.texture.resource_path.ends_with("npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png"),"complete waiter strip "+npc.npc_id)
			_expect(npc.portrait_path==PORTRAIT,"unchanged waiter portrait "+npc.npc_id)
			if npc.npc_id=="bianzhou_life_25": waiter=npc
		if npc.movement_mode=="patrol" and npc.walk_sprite_path==WALK: merchants.append(npc)
	_expect(waiter!=null and not merchants.is_empty(),"both screenshot identities present")
	for phase: float in [0.0,PI]:
		var starts: Array[Vector2]=[]
		for npc: NPCNode in merchants:
			npc._patrol_phase=phase
			npc.position=npc._patrol_origin
			starts.append(npc.position)
		await process_frame
		await process_frame
		for i: int in range(merchants.size()):
			var npc:=merchants[i]
			var dx:=npc.position.x-starts[i].x
			var hd:=npc.sprite.get_node_or_null("PCNativeHDView") as Sprite2D
			_expect(absf(dx)>.001 and npc.sprite.flip_h==(dx>0) and hd!=null and hd.visible and hd.flip_h==npc.sprite.flip_h,"actual step matches merchant-facing art "+npc.npc_id)

func _done() -> void:
	if _failed==0 and is_instance_valid(current_scene) and current_scene!=_city_before_return and _router.call("get_current_field_id")==CITY and DisplayServer.get_name()!="headless":
		for npc: NPCNode in current_scene.get("_npc_nodes"):
			if npc.npc_id!="bianzhou_life_25": continue
			var player:=current_scene.get("_player") as Player
			player.global_position=npc.global_position+Vector2(36,64)
			current_scene.call("_snap_camera_to_player")
			await process_frame
			await RenderingServer.frame_post_draw
			_expect(root.get_texture().get_image().save_png("user://bianzhou_waiter_and_merchants.png")==OK,"NPC scene capture")
			break
	super._done()

func _depth_at_front(field: Node) -> void:
	var player:=field.get("_player") as Player
	var original:=player.global_position
	var world:=field.get("world_container") as Node2D
	var actor_layer:=field.get("_actor_layer") as Node2D
	var scene: SceneScript=field.get("_current_scene")
	var depth := DEPTH.new()
	for spec: Array in [["post_cottage",Vector2(769,1160),Vector2(626,880),146],["post_stables",Vector2(990,940),Vector2(978,650),115]]:
		var item:=actor_layer.get_node("SceneObject_"+String(spec[0])) as Sprite2D
		for i in [1,2]:
			var point: Vector2=spec[i]
			_expect(bool(field.call("_spawn_has_foot_clearance",scene,point/Vector2(3072,2048))),"clear walkable depth sample "+String(spec[0])+" "+str(i))
			player.global_position=world.to_global(point)
			field.call("_update_actor_depth",player)
			_expect((depth.effective_z(player.sprite)>depth.effective_z(item)) if i==1 else (depth.effective_z(player.sprite)<depth.effective_z(item)),"front/back effective depth "+String(spec[0])+" "+str(i))
		_expect(item.z_index<int(spec[3]) and item.self_modulate.a==1.0,"opaque building with corrected foot "+String(spec[0]))
	player.global_position=world.to_global(Vector2(769,1160))
	field.call("_update_actor_depth",player)
	field.call("_snap_camera_to_player")
	await process_frame
	await RenderingServer.frame_post_draw
	_expect(root.get_texture().get_image().save_png("user://old_post_front_order.png")==OK,"front of cottage normal image")
	player.global_position=original
	field.call("_update_actor_depth",player)
