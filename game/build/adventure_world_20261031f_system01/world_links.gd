extends Node
## Additive three-door travel. No Router internals, shared World resources or save APIs.
const ROOT := "res://build/adventure_world_20261031f_system01/"
const WORLD_SIZE := Vector2(12288,8192)
const WORLDS := [&"world_map_jianghu",&"world_map_jianghu_v15",&"world_map_jianghu_v16"]
const WORLD_NATIVE = preload("res://build/world_coast_20261031h_system02/world_contract_dispatch03.gd")
const ORIGIN_KEY := "adventure_world_origin_v1"
const DOOR = preload("res://scripts/field/world_v15_exit_zone.gd")
var world_owner: Node
var overlay_root: Node2D
var world_nodes: Array[ExitZone] = []
var _local_request: Dictionary = {}
var _return_request: Dictionary = {}
var _return_zone: ExitZone
var _return_connections: Array[Dictionary] = []
var _clock := 0.0
var _request_generation := 0
const REQUEST_TIMEOUT_MSEC := 60000

static func portal_rows() -> Array[Dictionary]:
	return [
		{"id":"adventure31f_forest","label":"竹尾猎径","target_scene":"adventure_zhuwei_hunting_ground","world_foot":Vector2(6900,4700),"require_flag":"zhuwei_village_inquiry_done","locked_label":"先在竹尾村中打听消息","original_return":"ch1_s3_zhuwei_forest","art":"res://art/modules/prop/linxi_village_gate_foreground_v1.png","width":180.0},
		{"id":"adventure31f_mine","label":"襄州深矿","target_scene":"adventure_xiangzhou_deep_mine","world_foot":Vector2(5200,6000),"require_flag":"","original_return":"openworld_xiangzhou_mine_valley","art":"res://art/modules/linxi_mountain_road_20261030g/cave_mouth.png","width":210.0},
		{"id":"adventure31f_riverside","label":"岸驿曲径","target_scene":"adventure_luoyang_riverside_route","world_foot":Vector2(5600,3300),"require_flag":"","original_return":"ch4_s4_ancient_temple","art":"res://art/modules/riverside_waypoint_20261114/riverside_waypoint.png","width":420.0},
		{"id":"zhuwei_riverbank","label":"竹尾河滩","target_scene":"ch2_s1_zhuwei_market","world_foot":Vector2(6710,4840),"local_spawn":Vector2(.365,.905),"require_flag":"chapter1_complete","locked_label":"先完成竹尾村的调查","original_return":"world_map_jianghu","art":"res://art/modules/zhuwei_dojo_20261110/riverbank_world_20261116.png","width":224.0}
	]

static func _row(id: String) -> Dictionary:
	for row: Dictionary in portal_rows():
		if row.id==id:return row
	return {}

static func _target_row(target: String) -> Dictionary:
	for row: Dictionary in portal_rows():
		if row.target_scene==target:return row
	return {}

static func gateway_position(target: StringName) -> Variant:
	var row := _target_row(String(target))
	return row.world_foot / WORLD_SIZE if not row.is_empty() else null

static func doorway(row: Dictionary) -> PackedVector2Array:
	var foot: Vector2=row.world_foot
	return PackedVector2Array([foot+Vector2(-40,-26),foot+Vector2(40,-26),foot+Vector2(40,50),foot+Vector2(-40,50)])

static func _unlocked(row: Dictionary) -> bool:
	var flag: String=String(row.get("require_flag",""))
	if flag.is_empty():return true
	var value: Variant=GameState.flags.get(flag,false)
	return value==true or (value is int and value!=0) or (value is String and not value.is_empty())

static func _world_scene(field: Node) -> SceneScript:
	if not is_instance_valid(field):return null
	for prop: Dictionary in field.get_property_list():
		if prop.name=="_current_scene":return field.get("_current_scene") as SceneScript
	return null

static func is_world(field: Node) -> bool:
	var scene: SceneScript=_world_scene(field)
	return scene!=null and WORLDS.has(scene.scene_id) and WORLD_NATIVE.is_native(scene) and SceneRouter.get_current_field_id()==scene.scene_id

func _process(delta: float) -> void:
	_clock+=delta
	if _clock<.15:return
	_clock=0.0
	var field: Node=get_tree().current_scene
	var scene: SceneScript=_world_scene(field)
	_advance_pending(field,scene)
	if scene==null:return
	_update_map(field,String(SceneRouter.get_current_field_id()))
	if not field.has_method("get_field_loading_state"):return
	var state: Dictionary=field.call("get_field_loading_state")
	if state.get("complete")!=true or state.get("failed")==true:return
	var logical: String=String(SceneRouter.get_current_field_id())
	if is_world(field):
		if field!=world_owner or not is_instance_valid(overlay_root):_attach_world(field)
		for zone: ExitZone in world_nodes:
			if is_instance_valid(zone):zone.is_locked=not _unlocked(_row(String(zone.name)))
		_update_minimap(field)
	else:_bind_return(field,logical)

func local_connector_requested(source: Node,target: String) -> void:
	if _target_row(target).is_empty() or not is_instance_valid(source):return
	_request_generation+=1;_return_request.clear()
	_local_request=_pending_request(source,String(SceneRouter.get_current_field_id()),target)

func prepare_world_view(field: Node) -> void:
	if not is_world(field) or not field.get_field_loading_state().get("complete", false):
		return
	if field != world_owner or not is_instance_valid(overlay_root):
		_attach_world(field)

func _pending_request(source: Node,source_id: String,target: String) -> Dictionary:
	var raw: Variant=GameState.flags.get(ORIGIN_KEY,{})
	var snapshot: Dictionary=raw.duplicate(true) if raw is Dictionary else {}
	return {"source":weakref(source),"source_id":source_id,"target":target,"generation":_request_generation,"expires_msec":Time.get_ticks_msec()+REQUEST_TIMEOUT_MSEC,"origin_snapshot":snapshot}

func _advance_pending(field: Node,scene: SceneScript) -> void:
	if not _local_request.is_empty() and _pending_finished(_local_request,field,scene):_local_request.clear()
	if not _return_request.is_empty() and _pending_finished(_return_request,field,scene):_return_request.clear()

func _pending_finished(request: Dictionary,field: Node,scene: SceneScript) -> bool:
	if int(request.generation)!=_request_generation or Time.get_ticks_msec()>int(request.expires_msec):return true
	var logical: String=String(SceneRouter.get_current_field_id())
	if logical!=request.source_id and logical!=request.target:return true
	var loading: bool=bool(LoadingManager.get("_transition_active")) or bool(LoadingManager.get("_external_active"))
	var source: Node=request.source.get_ref() as Node
	# A failed void call still sitting in its source cannot authorize a later
	# unrelated visit. Null/menu/battle scenes only bridge an active transition.
	if scene==null:return not loading
	if field==source:return not loading
	if logical!=request.target or String(scene.scene_id)!=request.target:return true
	if not field.has_method("get_field_loading_state"):return true
	var state: Dictionary=field.call("get_field_loading_state")
	if state.get("failed")==true:return true
	if state.get("complete")!=true:return false
	# Only consume exactly the provenance observed when this request began.
	# A new accepted World trip or a reload with another row/foot is not ours.
	var snapshot: Dictionary=request.origin_snapshot
	var current: Variant=GameState.flags.get(ORIGIN_KEY,{})
	if not snapshot.is_empty() and current is Dictionary and current==snapshot:GameState.flags.erase(ORIGIN_KEY)
	return true

static func actor_shape_clear(actor: Player) -> bool:
	if not is_instance_valid(actor) or not actor.is_inside_tree():return false
	var contact: CollisionShape2D=actor.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if contact==null or contact.shape==null or contact.disabled:return false
	var query:=PhysicsShapeQueryParameters2D.new()
	query.shape=contact.shape;query.transform=contact.global_transform
	query.collision_mask=actor.collision_mask;query.exclude=[actor.get_rid()]
	query.collide_with_areas=false;query.collide_with_bodies=true;query.margin=0.0
	return actor.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _world_door_safe(global_foot: Vector2,field: Node,row_id: String) -> bool:
	var row: Dictionary=_row(row_id)
	if row.is_empty() or field!=world_owner or field!=get_tree().current_scene or not is_world(field):return false
	if not bool(field.get("_field_loading_complete")) or bool(field.get("_system_panel_open")) or bool(field.get("_scene_rebuilding")) or DialogPlayer.is_playing():return false
	if bool(LoadingManager.get("_transition_active")) or bool(LoadingManager.get("_external_active")):return false
	var actor: Player=field.get("_player") as Player
	var world: Node2D=field.get("world_container") as Node2D
	if not is_instance_valid(actor) or not actor.can_move or world==null:return false
	if actor.global_position.distance_to(global_foot)>.01:return false
	var foot: Vector2=world.to_local(global_foot)
	if not Geometry2D.is_point_in_polygon(foot,doorway(row)):return false
	var scene: SceneScript=_world_scene(field)
	var contract: Variant=SceneRouter.layered_world_contract(scene)
	if contract==null or not contract.safe_foot(scene,foot/WORLD_SIZE):return false
	var stream: Variant=field.get("_world_v15_stream")
	if not is_instance_valid(stream) or not stream.visual_ready_for_motion(foot):return false
	if actor.movement_constraint.is_valid() and not bool(actor.movement_constraint.call(global_foot)):return false
	return actor_shape_clear(actor)

func enter_from_world(field: Node,row: Dictionary) -> bool:
	var fixed: Dictionary=_row(String(row.get("id","")))
	if fixed.is_empty() or not _unlocked(fixed) or not is_instance_valid(field):return false
	var actor: Player=field.get("_player") as Player
	if not is_instance_valid(actor) or not _world_door_safe(actor.global_position,field,String(fixed.id)):return false
	var world_id: StringName=_world_scene(field).scene_id
	var foot: Vector2=(field.get("world_container") as Node2D).to_local(actor.global_position)
	var accepted: bool=SceneRouter.go_field_smart(StringName(fixed.target_scene),fixed.get("local_spawn",Vector2(.5,.9)),"",SceneRouter.world_version_for_scene(world_id),-1)
	if not accepted:return false
	_request_generation+=1;_local_request.clear();_return_request.clear()
	GameState.flags[ORIGIN_KEY]={"row_id":String(fixed.id),"world_id":String(world_id),"source_foot":[foot.x,foot.y],"world_version":SceneRouter.world_version_for_scene(world_id)}
	return true

func validated_origin(target: String="") -> Dictionary:
	var value: Variant=GameState.flags.get(ORIGIN_KEY,{})
	if not value is Dictionary or value.size() not in [3,4]:return {}
	if not value.get("row_id") is String or not value.get("world_id") is String:return {}
	var row: Dictionary=_row(value.row_id)
	var world_id:=StringName(value.world_id)
	if row.is_empty() or not WORLDS.has(world_id):return {}
	var source_version: Variant=value.get("world_version",15)
	if typeof(source_version) not in [TYPE_INT,TYPE_FLOAT] or source_version not in [15,16]:return {}
	if value.size()==4 and not value.has("world_version"):return {}
	if world_id==&"world_map_jianghu_v16" and source_version!=16:return {}
	if world_id==&"world_map_jianghu_v15" and source_version!=15:return {}
	if int(source_version)>SceneRouter.world_version_for_scene(world_id):return {}
	if not target.is_empty() and row.target_scene!=target:return {}
	var pair: Variant=value.get("source_foot")
	if not pair is Array or pair.size()!=2:return {}
	for scalar: Variant in pair:
		if typeof(scalar) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(scalar)):return {}
	var foot:=Vector2(float(pair[0]),float(pair[1]))
	if not Geometry2D.is_point_in_polygon(foot,doorway(row)):return {}
	var source_scene: SceneScript=WORLD_NATIVE.V16.source_scene(int(source_version))
	var source_contract: Variant=WORLD_NATIVE.contract_for(source_scene)
	if source_contract==null or not source_contract.safe_foot(source_scene,foot/WORLD_SIZE):return {}
	var active: StringName=SceneRouter.get_active_world_map_scene()
	if WORLDS.has(active) and SceneRouter.world_version_for_scene(active)==16:world_id=active
	var scene: SceneScript=WORLD_NATIVE.scene_for(world_id)
	if scene==null:return {}
	var contract: Variant=SceneRouter.layered_world_contract(scene)
	if contract==null or not contract.safe_foot(scene,foot/WORLD_SIZE):return {}
	return {"row":row,"world_id":world_id,"foot":foot}

func _attach_world(field: Node) -> void:
	world_owner=field;world_nodes.clear()
	var world: Node2D=field.get("world_container") as Node2D
	var actor: Player=field.get("_player") as Player
	if world==null or actor==null:return
	if _world_scene(field).scene_id in [&"world_map_jianghu", &"world_map_jianghu_v16"]:
		_install_world_surface(world)
	overlay_root=Node2D.new();overlay_root.name="AdventureWorldLinks31f";world.add_child(overlay_root)
	if _world_scene(field).scene_id in [&"world_map_jianghu", &"world_map_jianghu_v16"]:
		_add_meadow_clusters(field)
	for row: Dictionary in portal_rows():
		_add_landmark(field,row)
		var zone: ExitZone=(load("res://scenes/exit_zone.tscn") as PackedScene).instantiate() as ExitZone
		zone.set_script(DOOR);zone.name=row.id;zone.position=row.world_foot
		zone.exit_label="进入"+String(row.label);zone.destination_name=row.label
		zone.target_scene_id=row.target_scene;zone.target_spawn_pos=row.get("local_spawn",Vector2(.5,.9))
		zone.is_locked=not _unlocked(row);zone.always_show_destination=true
		zone.set_meta("portal_id",row.id);overlay_root.add_child(zone)
		zone.call("configure_doorway",doorway(row),actor,Callable(self,"_world_door_safe").bind(field,String(row.id)))
		zone.configure_marker(row.world_foot,WORLD_SIZE)
		if zone.prompt!=null:
			zone.prompt.z_as_relative=false;zone.prompt.z_index=4095
		if zone.marker_visual!=null:
			zone.marker_visual.z_as_relative=false;zone.marker_visual.z_index=4094
		zone.exit_triggered.connect(func(_id: String,_pos: Vector2) -> void:enter_from_world(field,row))
		zone.exit_locked.connect(func(_label: String) -> void:EventBus.toast_requested.emit(String(row.get("locked_label","此处尚未开放"))))
		var live: Array=field.get("_exit_nodes");live.append(zone);world_nodes.append(zone)

func _install_world_surface(world: Node2D) -> void:
	var streamer := world.get_node_or_null("WorldBackgroundChunks")
	if streamer == null or streamer.has_meta("river_meadow_surface"):
		return
	var surface := ShaderMaterial.new()
	surface.shader = load("res://shaders/world_river_meadow_surface.gdshader")
	surface.set_shader_parameter("river_detail", load("res://art/maps/jinling_city_20261029/river_water_v1.png"))
	surface.set_shader_parameter("meadow_detail", load("res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/grass_ground_diff_2k.jpg"))
	streamer.set_meta("river_meadow_surface", true)
	for child: Node in streamer.get_children():
		if child is Sprite2D:
			child.material = surface
	streamer.child_entered_tree.connect(func(child: Node) -> void:
		if child is Sprite2D:
			child.material = surface
	)

func _add_meadow_clusters(field: Node) -> void:
	var scene := _world_scene(field)
	var contract: Variant = SceneRouter.layered_world_contract(scene)
	if contract == null or SceneRouter.world_version_for_scene(scene.scene_id) != 16:
		return
	var props: Array[Texture2D] = []
	for name: String in ["veg_grass_tuft_a","veg_grass_tuft_b","veg_bush_green_a","veg_bush_green_b"]:
		props.append(load("res://art/modules/veg/" + name + ".png") as Texture2D)
	# Colonies at quiet alluvial flats, leaving the trade-road and door feet clear.
	var colonies := PackedVector2Array([Vector2(4420,1710),Vector2(5050,1835),Vector2(5910,1975),Vector2(6610,2290),Vector2(7875,3010),Vector2(8480,3240),Vector2(9000,3550),Vector2(7700,4500),Vector2(8130,4710),Vector2(6550,5330),Vector2(5870,5700),Vector2(6260,5990),Vector2(8080,6970),Vector2(9990,6770)])
	var rng := RandomNumberGenerator.new()
	rng.seed = 140311
	for center in colonies:
		for i in 9:
			var foot := center + Vector2(rng.randf_range(-135,135),rng.randf_range(-92,92))
			if not contract.safe_foot(scene, foot / WORLD_SIZE):
				continue
			var mark := Sprite2D.new()
			mark.texture = props[(i + rng.randi_range(0,2)) % props.size()]
			mark.scale = Vector2.ONE * (rng.randf_range(16.0,37.0) / maxf(1,mark.texture.get_width()))
			mark.position = foot - Vector2(0,mark.texture.get_height()*mark.scale.y*.35)
			mark.flip_h = rng.randi_range(0,1) == 0
			mark.modulate = Color(0.83,0.88,0.78,0.88)
			mark.z_index = -75
			overlay_root.add_child(mark)

func _add_landmark(field: Node,row: Dictionary) -> void:
	var sprite:=Sprite2D.new();sprite.name=String(row.id)+"_WholeLandmark"
	sprite.texture=load(String(row.art)) as Texture2D
	if sprite.texture==null:return
	sprite.scale=Vector2.ONE*(float(row.width)/sprite.texture.get_width())
	# Complete image, no atlas/crop. The visual and its bounded native-UV
	# footprints stay north of the authored interaction/approach passage.
	sprite.position=row.world_foot+Vector2(0,-55)-Vector2(0,sprite.texture.get_height()*sprite.scale.y*.5)
	var actors: Node2D=field.get("_actor_layer") as Node2D
	sprite.z_as_relative=true;sprite.z_index=clampi(int((row.world_foot.y-55)/8.0),0,4000)+(actors.z_index if actors!=null else 20)
	if row.id=="adventure31f_riverside":
		# This is a terrain vignette, not a life-sized foreground building.
		# Put the south end of the path next to the real door, above the map
		# terrain and below the entire actor layer.
		sprite.position=row.world_foot+Vector2(3,-29)-Vector2(0,sprite.texture.get_height()*sprite.scale.y*.5)
		sprite.z_index=(actors.z_index if actors!=null else 20)-1
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	elif row.id == "zhuwei_riverbank":
		sprite.position = row.world_foot + Vector2(15, -5.0 - sprite.texture.get_height() * sprite.scale.y * 0.5)
		sprite.z_index = (actors.z_index if actors != null else 20) - 1
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.set_meta("whole_existing_asset",String(row.art));overlay_root.add_child(sprite)
	var body_index:=0
	for polygon: PackedVector2Array in _landmark_footprints(row,sprite):
		var body:=StaticBody2D.new();body.name=String(row.id)+"_NativeFootprint_"+str(body_index)
		body.collision_layer=1;body.collision_mask=0
		var shape:=CollisionPolygon2D.new();shape.polygon=polygon;body.add_child(shape)
		body.set_meta("native_source_asset",String(row.art));body.set_meta("native_source_uv_footprint",true)
		overlay_root.add_child(body);body_index+=1
	if row.id=="adventure31f_forest":
		for side: float in [-1.0,1.0]:
			var bamboo:=Sprite2D.new();bamboo.texture=load("res://art/modules/linxi_scale_polish_20261030h/green_bamboo.png") as Texture2D
			bamboo.scale=Vector2.ONE*(110.0/bamboo.texture.get_width());bamboo.position=row.world_foot+Vector2(side*100,-120)
			bamboo.z_index=sprite.z_index;overlay_root.add_child(bamboo)

func _landmark_footprints(row: Dictionary,sprite: Sprite2D) -> Array[PackedVector2Array]:
	# Only the actual ground-contact source parts, never the texture rectangle:
	# two gate column plinths; cave side rocks/back rim (mouth stays open).
	# The riverside pool, rocks and pavilion are solid, but its center trail
	# and south approach retain the validated door and return rectangle.
	var source: Array[PackedVector2Array]=[]
	match String(row.id):
		"adventure31f_forest":
			source=[PackedVector2Array([Vector2(.161,.684),Vector2(.239,.660),Vector2(.348,.704),Vector2(.271,.755)]),PackedVector2Array([Vector2(.691,.822),Vector2(.777,.800),Vector2(.869,.850),Vector2(.774,.898)])]
		"adventure31f_mine":
			source=[PackedVector2Array([Vector2(.12,.63),Vector2(.32,.61),Vector2(.33,.76),Vector2(.15,.78)]),PackedVector2Array([Vector2(.70,.65),Vector2(.90,.72),Vector2(.84,.84),Vector2(.70,.80)]),PackedVector2Array([Vector2(.30,.40),Vector2(.73,.40),Vector2(.70,.58),Vector2(.35,.59)])]
		"adventure31f_riverside":
			source=[
				PackedVector2Array([Vector2(.59,.43),Vector2(.74,.36),Vector2(.86,.40),Vector2(.96,.51),Vector2(.97,.68),Vector2(.87,.77),Vector2(.72,.80),Vector2(.60,.67),Vector2(.54,.54)]),
				PackedVector2Array([Vector2(.14,.40),Vector2(.35,.35),Vector2(.43,.40),Vector2(.31,.50),Vector2(.19,.50),Vector2(.12,.46)]),
				PackedVector2Array([Vector2(.06,.58),Vector2(.22,.58),Vector2(.35,.67),Vector2(.37,.77),Vector2(.31,.88),Vector2(.19,.87),Vector2(.10,.75)])
			]
		"zhuwei_riverbank":
			source = [
				PackedVector2Array([Vector2(.18,.57),Vector2(.34,.51),Vector2(.37,.62),Vector2(.31,.73),Vector2(.19,.68)]),
				PackedVector2Array([Vector2(.57,.64),Vector2(.74,.46),Vector2(.88,.55),Vector2(.87,.76),Vector2(.68,.82),Vector2(.57,.75)])
			]
	var result: Array[PackedVector2Array]=[]
	var size: Vector2=sprite.texture.get_size()
	for uv: PackedVector2Array in source:
		var polygon:=PackedVector2Array()
		for point: Vector2 in uv:polygon.append(sprite.position+(point-Vector2(.5,.5))*size*sprite.scale)
		result.append(polygon)
	return result

func _bind_return(field: Node,logical: String) -> void:
	var origin: Dictionary=validated_origin(logical)
	if origin.is_empty():
		_restore_return();return
	if is_instance_valid(_return_zone) and _return_zone.is_inside_tree() and field.is_ancestor_of(_return_zone):return
	_restore_return()
	var exits: Variant=field.get("_exit_nodes")
	if not exits is Array:return
	for raw: Variant in exits:
		var zone: ExitZone=raw as ExitZone
		if not is_instance_valid(zone) or zone.target_scene_id!=String(origin.row.original_return):continue
		_return_zone=zone;_return_connections.clear()
		for connection: Dictionary in zone.exit_triggered.get_connections():
			_return_connections.append(connection);zone.exit_triggered.disconnect(connection.callable)
		zone.set_meta("adventure31f_original_label",zone.exit_label)
		zone.set_meta("adventure31f_original_destination",zone.destination_name)
		zone.set_meta("adventure31f_original_target",zone.target_scene_id)
		zone.set_meta("adventure31f_original_spawn",zone.target_spawn_pos)
		zone.exit_label="返回江湖大地图";zone.destination_name="返回江湖大地图"
		zone.target_scene_id=String(origin.world_id);zone.target_spawn_pos=origin.foot/WORLD_SIZE
		if zone.prompt!=null:zone.prompt.text="返回江湖大地图"
		zone.exit_triggered.connect(Callable(self,"_return_to_world").bind(field,logical))
		return

func _restore_return() -> void:
	if is_instance_valid(_return_zone):
		for connection: Dictionary in _return_zone.exit_triggered.get_connections():_return_zone.exit_triggered.disconnect(connection.callable)
		for connection: Dictionary in _return_connections:
			if connection.callable.is_valid():_return_zone.exit_triggered.connect(connection.callable,int(connection.flags))
		_return_zone.exit_label=String(_return_zone.get_meta("adventure31f_original_label",_return_zone.exit_label))
		_return_zone.destination_name=String(_return_zone.get_meta("adventure31f_original_destination",_return_zone.destination_name))
		_return_zone.target_scene_id=String(_return_zone.get_meta("adventure31f_original_target",_return_zone.target_scene_id))
		_return_zone.target_spawn_pos=_return_zone.get_meta("adventure31f_original_spawn",_return_zone.target_spawn_pos)
		if _return_zone.prompt!=null:_return_zone.prompt.text=_return_zone.destination_name
	_return_zone=null;_return_connections.clear()

func _return_to_world(_id: String,_pos: Vector2,field: Node,logical: String) -> void:
	if field!=get_tree().current_scene or not is_instance_valid(_return_zone):return
	var origin: Dictionary=validated_origin(logical)
	if origin.is_empty():return
	var actor: Player=field.get("_player") as Player
	if not is_instance_valid(actor) or not actor.can_move or not actor_shape_clear(actor):return
	if bool(field.get("_system_panel_open")) or bool(field.get("_scene_rebuilding")) or DialogPlayer.is_playing():return
	if bool(LoadingManager.get("_transition_active")) or bool(LoadingManager.get("_external_active")):return
	# Keep original arrow's physical overlap semantics; no remote exit invocation.
	if not _return_zone.overlaps_body(actor):return
	var next_request: Dictionary=_pending_request(field,logical,String(origin.world_id))
	if SceneRouter.go_field_smart(origin.world_id,origin.foot/WORLD_SIZE,"",SceneRouter.world_version_for_scene(origin.world_id),-1):
		_request_generation+=1;_local_request.clear()
		next_request.generation=_request_generation;_return_request=next_request

func _update_map(field: Node,logical: String) -> void:
	var panel: WorldMapPanel
	for prop: Dictionary in field.get_property_list():
		if prop.name=="_world_map_panel":panel=field.get("_world_map_panel") as WorldMapPanel;break
	if not is_instance_valid(panel) or not panel.visible or not WORLDS.has(SceneRouter.get_active_world_map_scene()):return
	for row: Dictionary in portal_rows():
		var found:=false
		for child: Node in panel.map_rect.get_children():
			if not child.is_queued_for_deletion() and child.get_meta("adventure31f_map_id","")==row.id:found=true;break
		if found:continue
		var entry: Dictionary=row.duplicate();entry.pos=row.world_foot/WORLD_SIZE
		panel.call("_build_location_label",entry)
		var label: Label=panel.map_rect.get_child(panel.map_rect.get_child_count()-1) as Label
		label.set_meta("adventure31f_map_id",row.id);label.z_index=10;label.position+=Vector2(40,-46)
	var associated: Dictionary=_target_row(logical)
	if associated.is_empty():return
	var origin: Dictionary=validated_origin(logical)
	var foot: Vector2=origin.foot if not origin.is_empty() else associated.world_foot
	var marker: Sprite2D
	for child: Node in panel.map_rect.get_children():
		if child is Sprite2D and child.has_meta("world_map_runtime") and not child.is_queued_for_deletion():marker=child;break
	if marker==null:
		panel.call("_build_player_marker",foot/WORLD_SIZE)
		marker=panel.map_rect.get_child(panel.map_rect.get_child_count()-1) as Sprite2D
	if marker!=null:
		marker.position=foot/WORLD_SIZE*panel.map_rect.size+Vector2(0,-29);marker.z_index=20
		marker.set_meta("adventure31f_origin_marker",associated.id)

func _update_minimap(field: Node) -> void:
	var mini: Variant=field.get("_world_travel_minimap")
	if not is_instance_valid(mini) or mini.has_node("AdventureWorldPips31f"):return
	var pips: Control=load(ROOT+"minimap_pips.gd").new()
	pips.name="AdventureWorldPips31f";mini.add_child(pips)

func get_debug_state() -> Dictionary:
	return {"owner":world_owner,"added_door_count":world_nodes.size(),"portals":portal_rows(),"origin":validated_origin(),"return_zone":_return_zone,"local_pending":not _local_request.is_empty(),"return_pending":not _return_request.is_empty()}
