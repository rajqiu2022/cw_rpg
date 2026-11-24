extends "res://scripts/field/field_walkable_controller.gd"
## Native outdoor geometry with the original story rows, gates and dialogs retained.
const REG=preload("res://build/three_towns_world_20261029j_system01/town_registry.gd")
var native_town:Node2D
var row:Dictionary
var npc_rows:Array=[]
var portal_rows:Array=[]
var interaction_rows:Array=[]
func _load_scene(id:StringName)->SceneScript:
	if not REG.SECT_IDS.has(id):return null
	var source:SceneScript=load("res://data/scenes/"+String(id)+".tres")
	var scene:SceneScript=source.duplicate(false);scene.actor_positions_are_feet=true;return scene
func _setup_scene(scene:SceneScript,spawn:Variant=null,_progressive:bool=false)->void:
	_scene_rebuilding=true
	if scene==null or not REG.source_valid():_field_loading_failed=true;_scene_rebuilding=false;return
	row=REG.town(scene.scene_id);_world_size=row.size;_screen_size=row.size;_viewport_size=get_viewport_rect().size
	world_container.scale=Vector2.ONE;world_container.position=Vector2.ZERO;background.hide();hotspots_container.hide()
	_create_runtime_layers()
	native_town=load(row.scene).instantiate();world_container.add_child(native_town);native_town.set_process_unhandled_key_input(false)
	_player=native_town.actor;_world_camera=native_town.get_node("Camera");_world_camera.make_current();_camera_scroll_enabled=true
	_player.global_position=spawn*row.size if spawn is Vector2 else row.arrival
	native_town.terrain.reset_actor(native_town.terrain.level_at(_player.position));native_town.view_mode=1
	_player.set_can_move(true);_player.set_weapon_style(_current_player_weapon_type())
	for name in ["Top","Title","Status","Hint"]:native_town.get_node("UI/"+name).hide()
	native_town.update_view();_world_camera.force_update_scroll();process_priority=100
	prepare_rows(scene);rebuild_business();_scene_rebuilding=false
	SceneRouter.set_field_return_spawn(_player.position/_world_size)
func prepare_rows(scene:SceneScript)->void:
	npc_rows=scene.npcs.duplicate(true);portal_rows=scene.map_layout.portals.duplicate(true)
	interaction_rows=scene.map_layout.interactions.duplicate(true);interaction_rows.append_array(_legacy_hotspots_to_interactions(scene.hotspots))
	var npc_feet:Array=[];var portal_feet:Array=[];var interaction_feet:Array=[]
	match String(scene.scene_id):
		"ch2_s4_lingyue_gate":
			portal_feet=[Vector2(3250,1120),Vector2(1900,3434)]
			interaction_feet=[Vector2(1500,1770),Vector2(3340,1180),Vector2(2300,2870)]
		"ch7_s1_lieyun_valley_ferry":
			npc_feet=[Vector2(2810,3050)];portal_feet=[Vector2(2600,3794),Vector2(3100,1160)];interaction_feet=[Vector2(1510,3110)]
		"ch7_s2_mingwu_tea_town":
			npc_feet=[Vector2(1990,2890)];portal_feet=[Vector2(1700,3534),Vector2(4080,1350)];interaction_feet=[Vector2(1730,2660)]
	for i in range(npc_rows.size()):
		assert(i<npc_feet.size());npc_rows[i].pos=npc_feet[i]/_world_size
	for i in range(portal_rows.size()):
		assert(i<portal_feet.size());portal_rows[i].pos=portal_feet[i]/_world_size;portal_rows[i].size=Vector2(120,90)/_world_size
		portal_rows[i].show_destination_label=true
	for i in range(interaction_rows.size()):
		assert(i<interaction_feet.size());interaction_rows[i].pos=interaction_feet[i]/_world_size;interaction_rows[i].size=Vector2(140,140)/_world_size
		interaction_rows[i].sect_floor=native_town.terrain.level_at(interaction_feet[i]);interaction_rows[i].visual_baked=true
func rebuild_business()->void:
	for n in _npc_nodes:n.queue_free()
	for n in _exit_nodes:n.queue_free()
	for n in _trigger_areas:n.queue_free()
	_npc_nodes.clear();_exit_nodes.clear();_trigger_areas.clear()
	_spawn_npcs(npc_rows);_spawn_exits(portal_rows);_spawn_trigger_zones(interaction_rows)
	for npc in _npc_nodes:
		npc.set_ground_anchored(true);npc.set_meta("sect_floor",native_town.terrain.level_at(npc.position))
		for body in npc.find_children("*","StaticBody2D",true,false):body.collision_layer=native_town.terrain.layer(npc.get_meta("sect_floor"))
	for zone in _exit_nodes:
		var level:int=native_town.terrain.level_at(zone.position);zone.set_meta("sect_floor",level)
		var height:float=native_town.terrain.elevation(level)
		# Keep the collision at ground coordinates; persist the projected arrow anchor through bob animation.
		zone.configure_marker(zone.position,_world_size,Vector2(0,-height))
func _physics_process(_delta:float)->void:
	if not is_instance_valid(native_town):return
	native_town.controls_enabled=not _system_panel_open and not DialogPlayer.is_playing() and not native_town.show_details and not _scene_rebuilding and not bool(LoadingManager.get("_transition_active"))
	if _scene_rebuilding or bool(LoadingManager.get("_transition_active")) or SceneRouter.get("_current_field_id")!=_current_scene.scene_id:return
	SceneRouter.set_field_return_spawn(_player.position/_world_size)
func _process(_delta:float)->void:
	if not is_instance_valid(native_town):return
	scene_title.text=_current_scene.display_name
	if _primary_hud!=null:
		_primary_hud.set_player_stats(GameState.player,GameState.gold);_primary_hud.set_scene_info(scene_title.text,"江湖游历")
		_primary_hud.set_hint_text("WASD移动 · Shift快走 · 空格交谈/查看 · M大地图")
	for npc in _npc_nodes:
		if not is_instance_valid(npc) or npc.is_queued_for_deletion():continue
		npc.set_ground_anchored(true);npc.sprite.position.y-=native_town.terrain.elevation(npc.get_meta("sect_floor"));npc.z_as_relative=false;npc.z_index=native_town.foot_depth(npc.position.y)
func interact()->void:
	if DialogPlayer.is_playing() or _system_panel_open:return
	var level:int=native_town.terrain.actor_level
	for npc in _npc_nodes:
		if npc.get_meta("sect_floor")==level and npc.try_interact():return
	for zone in _exit_nodes:
		if zone.get_meta("sect_floor")==level and zone.try_interact():return
	for area in _trigger_areas:
		if is_instance_valid(area) and area.overlaps_body(_player):
			var d:Dictionary=area.get_meta("trigger_data",{})
			if d.get("sect_floor",0)==level:_on_trigger_zone_entered(_player,d);return
	native_town.examine()
func _on_trigger_zone_entered(body:Node2D,data:Dictionary)->void:
	if data.get("sect_floor",0)!=native_town.terrain.actor_level:return
	super._on_trigger_zone_entered(body,data)
func _unhandled_input(event:InputEvent)->void:
	if is_instance_valid(native_town) and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE and native_town.show_details:
			native_town.show_details=false;native_town.update_view();get_viewport().set_input_as_handled();return
		if event.keycode==KEY_SPACE:
			if native_town.show_details:native_town.show_details=false;native_town.update_view()
			else:interact()
			get_viewport().set_input_as_handled();return
		if event.keycode in [KEY_R,KEY_TAB]:get_viewport().set_input_as_handled();return
	super._unhandled_input(event)
func _refresh_scene_preserving_player()->void:
	_refresh_gold();_refresh_quest_panel()
	if is_instance_valid(native_town):rebuild_business()
func _on_exit_triggered(target:String,pos:Vector2,source:Vector2)->void:
	if SceneRouter.is_world_map_scene(StringName(target)):
		SceneRouter.go_world_map()
	else:super._on_exit_triggered(target,pos,source)
