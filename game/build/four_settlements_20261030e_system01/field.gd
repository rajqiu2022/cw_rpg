extends "res://build/sect_completion_20261030a_system01/sect_field.gd"
const LOC=preload("res://build/four_settlements_20261030e_system01/locations.gd")
const ADULT_VISUAL=preload("res://build/linxi_adult_scale_20261030h_system01/adult_visual.gd")
var _adult_visual_receipts: Array[Dictionary]=[]
var _practice_npc: NPCNode
var _practice_post: Sprite2D
var _sealed_forest_gate: ExitZone
const PRACTICE_POST_REGION := Rect2(153,76,95,172)
func _load_scene(id:StringName)->SceneScript:
	if not LOC.IDS.has(id):return null
	var scene:SceneScript=load("res://data/scenes/"+String(id)+".tres").duplicate(false)
	scene.actor_positions_are_feet=true
	return scene
func _setup_scene(scene:SceneScript,spawn:Variant=null,progressive:bool=false)->void:
	super._setup_scene(scene,spawn,progressive)
	if _field_loading_failed:return
	if scene.scene_id in [&"ch1_s2_qingfeng", &"openworld_bailu_ferry", &"openworld_east_sea_port"]:
		_restore_clear_settlement_foot.call_deferred(_player.global_position)
	_setup_world_travel_minimap(scene)

func _restore_clear_settlement_foot(foot: Vector2) -> void:
	await get_tree().physics_frame
	if not is_instance_valid(_player) or _player.global_position.distance_to(foot)>0.5 or REG.actor_shape_clear(_player):
		return
	var level: int=native_town.terrain.actor_level
	for radius in [30.0,60.0,100.0,150.0,220.0,300.0]:
		for i in 12:
			var candidate:=foot+Vector2.from_angle(TAU*float(i)/12.0)*float(radius)
			if native_town.terrain.level_at(candidate)!=level:
				continue
			_player.global_position=candidate
			if REG.actor_shape_clear(_player):
				SceneRouter.set_field_return_spawn(candidate/_world_size)
				return
	_player.global_position=row.arrival
	native_town.terrain.reset_actor(native_town.terrain.level_at(row.arrival))
	SceneRouter.set_field_return_spawn(row.arrival/_world_size)

func get_world_town_debug()->Dictionary:
	return {"id":_current_scene.scene_id,"source_scene":row.scene}
func _setup_world_travel_minimap(scene:SceneScript)->void:
	if not is_instance_valid(_primary_hud):return
	var map:Control=load("res://build/four_settlements_20261030e_system01/minimap.gd").new()
	map.name="CityLocalMinimap";_primary_hud.add_child(map)
	if map.configure(self,scene,_player,_world_camera,world_container):_world_travel_minimap=map
	else:map.queue_free()
func prepare_rows(scene:SceneScript)->void:
	var layout:Dictionary=native_town.layout.business
	npc_rows=scene.npcs.duplicate(true);portal_rows=scene.map_layout.portals.duplicate(true);interaction_rows=scene.map_layout.interactions.duplicate(true)
	if scene.scene_id == &"linxi_tutorial" and GameState.get_flag(&"chapter5_complete"):
		# All four early incarnations share one position. After the return home,
		# select the master by the current story instead of the old tutorial flags.
		var epilogue: bool = GameState.get_flag(&"ch8_linxi_final_return_open")
		for i in range(npc_rows.size() - 1, -1, -1):
			var master: Dictionary = npc_rows[i]
			match String(master.npc_id):
				"xingfantian", "xingfantian_return", "xingfantian_after_training":
					npc_rows.remove_at(i)
				"xingfantian_after_farewell":
					if epilogue:
						npc_rows.remove_at(i)
					else:
						master.erase("require_flag")
						master.erase("hide_flag")
	for d:Dictionary in npc_rows:
		var a:Array=layout.npcs.get(d.npc_id,[])
		if a.is_empty():
			for prefix in layout.get("npc_prefixes",{}):
				if String(d.npc_id).begins_with(prefix):a=layout.npc_prefixes[prefix];break
		assert(not a.is_empty());d.pos=Vector2(a[0],a[1])/_world_size
	for d:Dictionary in portal_rows:
		var target:String=String(d.get("target_scene","world_map_jianghu" if d.get("action","")=="world_map" else ""))
		var a:Array=layout.portal_targets.get(target,layout.portals.get(d.id,[]));assert(not a.is_empty())
		d.pos=Vector2(a[0],a[1])/_world_size;d.size=Vector2(110,86)/_world_size;d.marker_offset=Vector2.ZERO;d.show_destination_label=true
		if scene.scene_id == &"ch2_s1_zhuwei_market":
			# Keep the native town's portal shape and record its real return foot.
			d.erase("source_spawn_pos")
	for d:Dictionary in interaction_rows:
		var a:Array=layout.interactions.get(d.id,[]);assert(not a.is_empty())
		d.pos=Vector2(a[0],a[1])/_world_size;d.size=Vector2(125,100)/_world_size;d.sect_floor=native_town.terrain.level_at(Vector2(a[0],a[1]));d.visual_baked=bool(d.get("visual_baked",true))

func _spawn_exits(exit_data: Array) -> void:
	_sealed_forest_gate = null
	super._spawn_exits(exit_data)
	if _current_scene.scene_id != &"ch1_s2_qingfeng":
		return
	for zone: ExitZone in _exit_nodes:
		if zone.is_locked and zone.destination_name == "前往后山密林":
			zone.destination_name = "后山密林 · 暂时封锁"
			zone.prompt.text = zone.destination_name
			_sealed_forest_gate = zone
			return


func interact() -> void:
	if is_instance_valid(_sealed_forest_gate) and not DialogPlayer.is_playing() and not _system_panel_open:
		var gate := _sealed_forest_gate
		var shape := gate.get_node("CollisionShape2D") as CollisionShape2D
		var size: Vector2 = shape.shape.size
		var bounds := Rect2(-size * 0.5, size)
		if native_town.terrain.actor_level == gate.get_meta("sect_floor") and bounds.has_point(shape.to_local(_player.global_position)):
			_show_toast(gate.exit_label)
			return
	super.interact()


func _spawn_npcs(npc_data: Array) -> void:
	var first: int=_npc_nodes.size()
	super._spawn_npcs(npc_data)
	if _field_loading_failed or _current_scene==null or not ADULT_VISUAL.SCENES.has(_current_scene.scene_id):return
	if first==0:_adult_visual_receipts.clear()
	for i: int in range(first,_npc_nodes.size()):
		var receipt: Dictionary=ADULT_VISUAL.apply(_npc_nodes[i])
		_adult_visual_receipts.append(receipt)
		if receipt.get("ok")!=true:
			_field_loading_failed=true
			push_error("LINXI_ADULT_VISUAL_PROTECTION_FAILED:"+String(receipt.get("npc_id",""))+":"+String(receipt.get("reason","body/business/foot changed")))
			return
		if _npc_nodes[i].npc_id=="tang_xingzhou_recruit":
			_practice_npc=_npc_nodes[i]
			var art: Sprite2D=_practice_npc.sprite
			# Frame one contains a clean post, separated from Tang's body and staff.
			_practice_post=Sprite2D.new()
			_practice_post.name="ConversationPracticePost"
			_practice_post.texture=art.texture
			_practice_post.transform=art.transform
			_practice_post.centered=false
			_practice_post.offset=art.get_rect().position+PRACTICE_POST_REGION.position
			_practice_post.region_enabled=true
			_practice_post.region_rect=PRACTICE_POST_REGION
			_practice_post.region_filter_clip_enabled=true
			_practice_post.hide()
			_practice_npc.add_child(_practice_post)

func _process(delta:float)->void:
	super._process(delta)
	if is_instance_valid(_practice_post) and is_instance_valid(_practice_npc):
		_practice_post.visible=_practice_npc.sprite.texture!=_practice_post.texture

func get_linxi_adult_visual_debug() -> Dictionary:
	return {"scene_id":String(_current_scene.scene_id) if _current_scene!=null else "","scope":ADULT_VISUAL.SCENES,"records":_adult_visual_receipts.duplicate(true),"original_scene_and_NPCNode_sources_changed":false}
