extends "res://scripts/field/field_walkable_controller.gd"
## Formal UI/state host around the unchanged native scene, actor and cached interiors.
const TOWNS=preload("res://build/three_towns_world_20261029j_system01/town_registry.gd")
const DOOR=preload("res://scripts/field/world_v15_exit_zone.gd")
var native_town: Node2D
var town_row: Dictionary
var town_exit: ExitZone
const LANXI := &"openworld_lanxi_zhai"
const LANXI_TALK := {
	"WestWeaver": ["织布阿嫂","溪风最适合晾布。布头还滴着水，过作坊时当心脚下。"],
	"DyeWorker": ["染坊匠人","这缸蓝靛刚搅过，须等颜色沉一沉，才能下第二匹布。"],
	"CreekVendor": ["溪边摊主","过桥可到上头的铺街。脚下看准木板，沿栏杆走就稳当。"],
	"ClothVendor": ["布摊阿姐","这匹布先点蜡再下靛。你瞧，白纹是蜡护住的地方。"],
	"PlazaCraftsman": ["芦笙匠","竹管要长短配齐，气才接得上。等晒透了，我就试吹一回。"],
	"UpperResident": ["山巷住户","上头是住家的巷子。去街市得走石阶，别从屋底的坡边抄近。"],
	"Farmer": ["粮院农人","上坡那几块田留着蓄水，晒谷才用院里这片干地。"],
	"LaneWorker": ["木楼工匠","坡上的吊脚楼靠下面几根长柱撑着。搬木料得走楼间的巷道。"],
	"Keeper": ["绣坊主人","点蜡、染布、晾晒都分开做。走累了，就在前厅坐一会儿。"],
}

func _load_scene(id: StringName) -> SceneScript:
	if not TOWNS.IDS.has(id):return null
	return load("res://data/scenes/%s.tres"%id) as SceneScript

func _setup_scene(scene: SceneScript,player_spawn_override: Variant=null,_progressive: bool=false) -> void:
	_scene_rebuilding=true
	if scene==null or not TOWNS.source_valid():
		_field_loading_failed=true
		_scene_rebuilding=false
		return
	town_row=TOWNS.town(scene.scene_id)
	_world_size=town_row.size
	_screen_size=_world_size
	_viewport_size=get_viewport_rect().size
	world_container.scale=Vector2.ONE
	world_container.position=Vector2.ZERO
	background.visible=false
	hotspots_container.visible=false
	native_town=(load(town_row.scene) as PackedScene).instantiate()
	native_town.name="NativeTown"
	world_container.add_child(native_town)
	native_town.set_process_unhandled_key_input(false)
	native_town.view_mode=1
	_player=native_town.actor as Player
	_world_camera=native_town.get_node("Camera") as Camera2D
	_world_camera.make_current()
	_camera_scroll_enabled=true
	var foot: Vector2=player_spawn_override*town_row.size if player_spawn_override is Vector2 else town_row.arrival
	_player.global_position=foot
	if scene.scene_id==&"openworld_lanxi_zhai":_restore_terrain(foot)
	_player.set_can_move(true)
	_player.set_weapon_style(_current_player_weapon_type())
	for label: String in ["Title","Status","Hint","TopPanel"]:
		native_town.get_node("UI/"+label).visible=false
	_add_town_exit()
	native_town.update_view()
	_world_camera.force_update_scroll()
	_scene_rebuilding=false
	SceneRouter.set_field_return_spawn(foot/town_row.size)
	TOWNS.ensure_watcher(SceneRouter)
	_setup_world_travel_minimap(scene)

func _restore_terrain(foot: Vector2) -> void:
	var terrain: Node=native_town.terrain
	terrain.reset_actor(terrain.level_at(foot))
	for i: int in range(terrain.ramps.size()):
		var ramp: Dictionary=terrain.ramps[i]
		var top: Vector2=Vector2(ramp.top[0],ramp.top[1])
		var bottom: Vector2=Vector2(ramp.bottom[0],ramp.bottom[1])
		if absf(foot.x-bottom.x)<=float(terrain.data.portal_half_width)-20.0 and foot.y>=top.y and foot.y<=bottom.y:
			terrain.actor_level=int(ramp.low)
			terrain.active_ramp=i
			terrain.apply_actor_mask()
			terrain.after_move()
			break
	terrain.project_actor()

func _add_town_exit() -> void:
	town_exit=(load("res://scenes/exit_zone.tscn") as PackedScene).instantiate() as ExitZone
	town_exit.set_script(DOOR)
	town_exit.name="WorldReturn"
	town_exit.position=town_row.exit
	town_exit.exit_label="返回江湖大地图"
	town_exit.destination_name="江湖大地图"
	town_exit.target_scene_id=String(TOWNS.WORLD)
	town_exit.always_show_destination=true
	native_town.get_node("Town").add_child(town_exit)
	var p: Vector2=town_row.exit
	var polygon:=PackedVector2Array([p+Vector2(-64,-80),p+Vector2(64,-80),p+Vector2(64,64),p+Vector2(-64,64)])
	town_exit.call("configure_doorway",polygon,_player,Callable(self,"_town_exit_safe"))
	town_exit.configure_marker(p,town_row.size)
	town_exit.exit_triggered.connect(func(_target: String,_spawn: Vector2) -> void:TOWNS.leave_town(_current_scene.scene_id))

func _town_exit_safe(_foot: Vector2) -> bool:
	if not is_instance_valid(native_town) or native_town.in_hall or _system_panel_open or DialogPlayer.is_playing():return false
	if _current_scene.scene_id==&"openworld_lanxi_zhai" and (native_town.terrain.actor_level!=0 or native_town.terrain.active_ramp>=0):return false
	return TOWNS.actor_shape_clear(_player)

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(native_town) or not is_instance_valid(_player):return
	native_town.controls_enabled=not _system_panel_open and not DialogPlayer.is_playing() and not native_town.show_details and not _scene_rebuilding and not bool(LoadingManager.get("_transition_active"))
	# An outgoing field must not overwrite the incoming transition's spawn payload.
	if _scene_rebuilding or bool(LoadingManager.get("_transition_active")) or SceneRouter.get("_current_field_id")!=_current_scene.scene_id:return
	var outdoor: Vector2=native_town.return_foot if native_town.in_hall else _player.global_position
	SceneRouter.set_field_return_spawn(outdoor/town_row.size)

func _process(_delta: float) -> void:
	if not is_instance_valid(native_town):return
	var title: String=native_town.get_node("UI/Title").text
	var parts:=title.split(" · ",true,1)
	scene_title.text=String(town_row.label)+(" · "+parts[1] if parts.size()>1 else "")
	if _primary_hud!=null:
		_primary_hud.set_player_stats(GameState.player,GameState.gold)
		_primary_hud.set_scene_info(scene_title.text,"江湖游历")
		var native_hint: String=native_town.get_node("UI/Hint").text
		_primary_hud.set_hint_text(native_hint if native_hint.begins_with("空格") else "WASD移动 · Shift快走 · 空格交谈/查看 · Esc关闭说明 · M大地图")

func _unhandled_input(event: InputEvent) -> void:
	if _current_scene!=null and _current_scene.scene_id==LANXI and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed and not _system_panel_open and not DialogPlayer.is_playing():
		if _talk_lanxi(event.position):
			get_viewport().set_input_as_handled()
			return
	if is_instance_valid(native_town) and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE and native_town.show_details:
			native_town.show_details=false
			native_town.update_view()
			get_viewport().set_input_as_handled()
			return
		if event.keycode in [KEY_R,KEY_TAB,KEY_1,KEY_2,KEY_3,KEY_4,KEY_5,KEY_6,KEY_7]:
			get_viewport().set_input_as_handled()
			return
		if event.keycode==KEY_SPACE and not _system_panel_open and not DialogPlayer.is_playing():
			if native_town.show_details:native_town.show_details=false
			elif not native_town.in_hall and town_exit.can_enter():town_exit.call("try_interact")
			elif not native_town.in_hall and BountyManager.try_county_board(world_container,_player,_current_scene.scene_id,_screen_size):
				get_viewport().set_input_as_handled()
				return
			elif _current_scene.scene_id==LANXI:
				if not _lanxi_room_door():_talk_lanxi()
			elif AdventureRuntime.interact_nearby(self):
				get_viewport().set_input_as_handled()
				return
			else:native_town.examine()
			if is_instance_valid(native_town):native_town.update_view()
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)

func _lanxi_room_door() -> bool:
	if native_town.in_hall:
		if _player.global_position.distance_to(native_town.hall.get_node("Exit").global_position)>=100:return false
		native_town.leave_hall()
		return true
	if _player.global_position.distance_to(native_town.DOOR)>=100:return false
	native_town.enter_hall()
	return native_town.in_hall

func _talk_lanxi(click_position: Variant=null) -> bool:
	if not is_instance_valid(native_town) or not is_instance_valid(_player):return false
	var residents: Array= native_town.get_node("Town").get_children()
	if native_town.in_hall:residents=[native_town.hall.get_node("Sort/Keeper")]
	var nearby: Node2D
	var nearest:=155.0
	for resident: Node in residents:
		if not resident is Node2D or not LANXI_TALK.has(String(resident.name)):continue
		if not native_town.in_hall and int(resident.get_meta("terrain_level",-1))!=int(native_town.terrain.actor_level):continue
		var distance: float=_player.global_position.distance_to(resident.global_position)
		if distance>=nearest:continue
		if click_position is Vector2:
			var art:=resident.get_node_or_null("Art") as Sprite2D
			if art==null or not art.get_rect().has_point(art.get_global_transform_with_canvas().affine_inverse()*click_position):continue
		nearby=resident
		nearest=distance
	if nearby==null:return false
	var line: Array=LANXI_TALK[String(nearby.name)]
	var node:=DialogNode.new()
	node.node_id=&"start"
	node.speaker=line[0]
	node.text=line[1]
	node.portrait_path="res://art/modules/miao_town_20261029f/%s.png"%String(nearby.get_meta("portrait","woman_portrait"))
	node.on_end="end"
	var script:=DialogScript.new()
	script.dialog_id=StringName("lanxi_"+String(nearby.name).to_snake_case())
	script.entry_node_id=node.node_id
	script.nodes.assign([node])
	if not native_town.in_hall:
		var resident_ref: WeakRef=weakref(nearby)
		nearby.set_physics_process(false)
		DialogPlayer.dialog_ended.connect(func(_id: StringName)->void:
			var resident: Node=resident_ref.get_ref()
			if is_instance_valid(resident):resident.set_physics_process(true)
		,CONNECT_ONE_SHOT)
	DialogPlayer.play(script)
	return true

func _refresh_scene_preserving_player() -> void:
	# Quest/dialog callbacks may refresh UI, never rebuild native geometry or reset its terrain.
	_refresh_gold()
	_refresh_quest_panel()

func get_world_town_debug() -> Dictionary:
	var returns: Dictionary=SceneRouter.get("_portal_return_spawns")
	var world_id: StringName=SceneRouter.get_active_world_map_scene()
	var terrain: Variant=native_town.get("terrain") if _current_scene.scene_id==&"openworld_lanxi_zhai" else null
	return {"id":_current_scene.scene_id,"source_scene":town_row.scene,"actor":_player,"arrival_foot":town_row.arrival,"exit_foot":town_row.exit,"return_world_id":world_id,"return_world_foot":returns.get(String(_current_scene.scene_id)+"->"+String(world_id),town_row.world_foot/TOWNS.WORLD_SIZE)*TOWNS.WORLD_SIZE,"game_player_instance":GameState.player,"hud_instance":_primary_hud,"terrain_level":terrain.actor_level if terrain!=null else 0,"active_ramp":terrain.active_ramp if terrain!=null else -1,"terrain_height":terrain.actor_height if terrain!=null else 0.0,"cached_room":native_town.in_hall}
