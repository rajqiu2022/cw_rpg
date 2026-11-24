extends "res://scripts/field/field_walkable_controller.gd"
## Original MainField owns real Player.moved/encounters/flags/dialogs on this road.
const A=preload("res://build/linxi_mountain_road_20261030g_system01/road_author.gd")
const MINI="res://build/linxi_road_portrait_20261030g_source01/road_minimap.gd"
const SOURCE_GUARD="res://build/three_towns_world_20261029j_system01/town_registry.gd"
const TABLET_ID := "road_stone_tablet_visual"
const CAVE_ID := "original_bandit_cave_native_mouth"
const GRAVE_FOOT := Vector2(2495, 2205)
const GRAVE_ART := "res://art/modules/linxi_road_burial_20261113/roadside_grave.png"
const STORY := preload("res://scripts/field/story_cutscene.gd")
const AMBUSH_FRAMES: Array[Texture2D] = [
	preload("res://art/characters/road_story_and_older_npcs_20261112/road_thug/frame_0.tres"),
	preload("res://art/characters/road_story_and_older_npcs_20261112/road_thug/frame_1.tres"),
	preload("res://art/characters/road_story_and_older_npcs_20261112/road_thug/frame_2.tres"),
	preload("res://art/characters/road_story_and_older_npcs_20261112/road_thug/frame_3.tres"),
]
var _road_story_busy := false
var _road_grave: Sprite2D
var _road_static: Array[Sprite2D]=[]
var _road_depth: RefCounted
var _road_cave: Sprite2D
var _road_cave_foot_y: float
var _road_solids: Array[PackedVector2Array]=[]
var _road_edge_shader: Shader
var _road_refreshing_dynamic:=false
var _road_refresh_receipt: Dictionary={}
const EDGE_CODE:="""
shader_type canvas_item;
render_mode unshaded;
uniform vec2 points[16];
uniform int count=0;
uniform float feather=40.0;
varying vec2 p;
varying vec4 tint;
void vertex(){p=VERTEX;tint=COLOR;}
void fragment(){float d=100000.;for(int i=0;i<16;i++){if(i>=count){break;}int j=(i+1)%count;vec2 v=points[j]-points[i];float t=clamp(dot(p-points[i],v)/max(dot(v,v),.0001),0.,1.);d=min(d,length(p-points[i]-v*t));}COLOR=texture(TEXTURE,UV)*tint;COLOR.a*=smoothstep(0.,feather,d);}
"""
func _load_scene(id: StringName) -> SceneScript:return A.scene() if id==A.ID else null
func _resolve_world_size(_scene: SceneScript,_texture: Texture2D) -> Vector2:return A.SIZE
func _scene_depth_band_max() -> int:return 1024
func _road_owned() -> bool:
	return is_inside_tree() and SceneRouter._current_field_id==A.ID and not LoadingManager._transition_active and not LoadingManager._external_active
func _on_player_moved(pos: Vector2) -> void:
	# The departing host must not overwrite the destination payload. Normal
	# movement still runs MainField's original encounter distance/chance/gates.
	if _road_owned():super._on_player_moved(pos)
func _remember_interaction_spawn() -> void:
	if _road_owned():super._remember_interaction_spawn()
func _on_flag_set(flag: StringName, value: Variant) -> void:
	if flag == &"road_stranger_buried":
		_sync_road_burial()
	super._on_flag_set(flag, value)

func _sync_road_burial() -> void:
	# Older saves already past the victory conversation keep the grave as well.
	var reported := QuestManager.is_active(&"q_ch1_main_return_master") or QuestManager.is_completed(&"q_ch1_main_return_master")
	var buried := _flag_truthy("road_stranger_buried") or (reported and _flag_truthy("looted_thug_corpse"))
	var corpse := _visual_layer.get_node_or_null("SceneObject_road_corpse_visual") as Sprite2D
	if is_instance_valid(corpse):
		corpse.visible = not buried
	if is_instance_valid(_road_grave):
		_road_grave.visible = buried
func _on_field_cutscene_requested(cutscene_id: StringName) -> void:
	if cutscene_id not in [&"road_corpse_approach", &"road_corpse_ambush"]:
		super._on_field_cutscene_requested(cutscene_id)
		return
	if _road_story_busy or not _road_owned() or not is_instance_valid(_player):
		return
	_road_story_busy = true
	_player.set_can_move(false)
	var corpse := A.point(A.data().business.visual_feet.road_corpse_visual)
	var hero_foot := world_container.to_local(_player.global_position)
	var side := -1.0 if hero_foot.x < corpse.x else 1.0
	var resume_node := &"start"
	if cutscene_id == &"road_corpse_approach":
		var inspect := corpse + Vector2(side * 116.0, 26.0)
		await STORY.walk_to(_player, world_container.to_global(inspect), func(foot: Vector2) -> bool:
			return A.safe_foot(world_container.to_local(foot) / A.SIZE))
		_player.set_walk_direction(Vector2(-side, 0.0), false)
	else:
		var start := Vector2(2456, 2084) # Behind the bamboo at the northeast bend.
		var end := hero_foot + Vector2(-side * 176.0, -55.0)
		if not A.safe_foot(end / A.SIZE, false):
			end = hero_foot + Vector2(side * 176.0, -55.0)
		var start_local := _actor_layer.to_local(world_container.to_global(start))
		var end_local := _actor_layer.to_local(world_container.to_global(end))
		var facing := 1.0 if end.x > hero_foot.x else -1.0
		_player.set_walk_direction(Vector2(facing, 0.0), false)
		await STORY.enter_actor(_actor_layer, AMBUSH_FRAMES, start_local, end_local,
			132.0, facing < 0.0, _scene_depth_band_max(), 43.0)
		resume_node = &"n4"
	_road_story_busy = false
	if _road_owned():
		_remember_interaction_spawn()
		DialogPlayer.play_at(load("res://data/dialogs/ch1_road_corpse.tres") as DialogScript, resume_node)
func road_static_identity() -> Array:
	var ids: Array=[get_instance_id(),_player,_world_camera,_world_travel_minimap]
	for node: Node in world_container.get_children():
		if String(node.name).begins_with("RoadGround_"):ids.append(node.get_instance_id())
	for sprite: Sprite2D in _road_static:
		if is_instance_valid(sprite):ids.append(sprite.get_instance_id())
	for body: StaticBody2D in _collision_bodies:
		if is_instance_valid(body) and not String(body.name).begins_with("ObjectCollision_"):ids.append(body.get_instance_id())
	return ids
func get_road_dynamic_refresh_state() -> Dictionary:return _road_refresh_receipt.duplicate(true)
func _refresh_scene_preserving_player() -> void:
	# Unlike MainField's nonresident fallback, never call _setup_scene here.
	# Only the original four conditional objects and original gameplay Areas /
	# NPCs are reprojected; crags, bamboo, ground, camera, mini and Player survive.
	if _current_scene==null or not _road_owned():return
	if _scene_rebuilding or _road_story_busy or DialogPlayer.is_playing():_scene_refresh_pending=true;return
	_scene_rebuilding=true
	var scene: SceneScript=_current_scene
	var before: Array=road_static_identity()
	var could_move: bool=is_instance_valid(_player) and _player.can_move
	if is_instance_valid(_player):_player.set_can_move(false)
	await get_tree().process_frame
	if not _road_owned() or _current_scene!=scene:_scene_rebuilding=false;return
	var functional: Dictionary=ELEVEN_ROOMS.project_portals(scene,scene.map_layout.portals) if ELEVEN_ROOMS.enabled() else FUNCTIONAL_INTERIORS.project_portals(scene,scene.map_layout.portals)
	if functional.get("ok")!=true:
		_scene_rebuilding=false;_field_loading_failed=true;push_error("ROAD_DYNAMIC_PORTAL_REJECTED");return
	if is_instance_valid(_active_dialog_npc):_active_dialog_npc.end_conversation()
	_active_dialog_npc=null
	for npc: NPCNode in _npc_nodes:
		if is_instance_valid(npc):npc.get_parent().remove_child(npc);npc.free()
	_npc_nodes.clear()
	for zone: ExitZone in _exit_nodes:
		if is_instance_valid(zone):zone.get_parent().remove_child(zone);zone.free()
	_exit_nodes.clear()
	for area: Area2D in _trigger_areas:
		if is_instance_valid(area):
			_set_interaction_highlight(area,false);area.get_parent().remove_child(area);area.free()
	_trigger_areas.clear();_trigger_events_in_flight.clear()
	var retained_sprites: Array[Sprite2D]=[]
	for sprite: Sprite2D in _scene_object_nodes:
		if not is_instance_valid(sprite):continue
		if _road_static.has(sprite):retained_sprites.append(sprite)
		else:sprite.get_parent().remove_child(sprite);sprite.free()
	_scene_object_nodes=retained_sprites
	var retained_bodies: Array[StaticBody2D]=[]
	for body: StaticBody2D in _collision_bodies:
		if not is_instance_valid(body):continue
		if String(body.name).begins_with("ObjectCollision_"):body.get_parent().remove_child(body);body.free()
		else:retained_bodies.append(body)
	_collision_bodies=retained_bodies
	_road_refreshing_dynamic=true
	await _spawn_scene_objects(scene.map_layout.visual_objects,false)
	_road_refreshing_dynamic=false
	if not _road_owned() or _current_scene!=scene:_scene_rebuilding=false;return
	_rebuild_walkability_collision_entries(scene.map_layout.blockers,scene.map_layout.visual_objects)
	var npcs: Array=scene.npcs.duplicate(true)
	npcs.append_array(BountyManager.get_scene_npcs(scene.scene_id));_spawn_npcs(npcs)
	_spawn_exits(functional.portals);_spawn_trigger_zones(scene.map_layout.interactions)
	_scene_refresh_pending=false;_scene_rebuilding=false
	_road_refresh_receipt={"dynamic_only":true,"static_preserved":before==road_static_identity(),"objects":_scene_object_nodes.size()-_road_static.size(),"npcs":_npc_nodes.size()}
	if could_move and is_instance_valid(_player) and not DialogPlayer.is_playing() and not _encounter_locked:_player.set_can_move(true)
func _setup_scene(scene: SceneScript,spawn: Variant=null,progressive: bool=false) -> void:
	if not A.ready():_field_loading_failed=true;push_error("ROAD_CAVE_NATIVE_PENDING");return
	var registry: Variant=load(SOURCE_GUARD)
	if registry==null or not registry.source_valid():_field_loading_failed=true;push_error("ROAD_NATIVE_SOURCE_CHANGED");return
	_road_solids=A.solid_polygons()
	await super._setup_scene(scene,spawn,progressive)
	if is_instance_valid(_player):_player.modulate.a=1.0
func _setup_world_travel_minimap(scene: SceneScript) -> void:
	if not is_instance_valid(_primary_hud):return
	var map: Control=load(MINI).new();map.name="CityLocalMinimap";_primary_hud.add_child(map)
	if map.call("configure",self,scene,_player,_world_camera,world_container):_world_travel_minimap=map
	else:map.queue_free()
func _patch(id: String,points: PackedVector2Array,texture: String,period: Vector2,z: int,feather: float=0.0) -> void:
	var tex: Texture2D=load(texture) as Texture2D
	if tex==null:_field_loading_failed=true;return
	var node:=Polygon2D.new();node.name="RoadGround_"+id;node.polygon=points;node.texture=tex
	node.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;node.z_index=z
	var uv:=PackedVector2Array()
	for p: Vector2 in points:uv.append(p/period*tex.get_size())
	node.uv=uv
	if feather>0 and points.size()<=16:
		if _road_edge_shader==null:_road_edge_shader=Shader.new();_road_edge_shader.code=EDGE_CODE
		var mat:=ShaderMaterial.new();mat.shader=_road_edge_shader;var pad:=PackedVector2Array();pad.resize(16)
		for i: int in range(points.size()):pad[i]=points[i]
		mat.set_shader_parameter("points",pad);mat.set_shader_parameter("count",points.size());mat.set_shader_parameter("feather",feather);node.material=mat
	world_container.add_child(node)
func _spawn_world_background(_scene: SceneScript) -> void:
	_world_background=null;_background_streamer=null;background.texture=null;background.hide();_road_static.clear()
	_road_depth=null;_road_cave=null;_road_grave=null
	for row: Dictionary in A.ground_rows():_patch(row.id,row.polygon,row.texture,row.period,int(row.z),float(row.get("feather_px",0)))
	for row: Dictionary in A.roads():
		var pts: PackedVector2Array=row.points;var width: float=row.width
		for i: int in range(pts.size()-1):
			var a: Vector2=pts[i];var b: Vector2=pts[i+1];var n: Vector2=(b-a).normalized().orthogonal()*width*.5
			_patch(String(row.id)+str(i),PackedVector2Array([a+n,b+n,b-n,a-n]),row.texture,Vector2(512,512),-1000,28)
		for i: int in range(pts.size()):
			var disk:=PackedVector2Array()
			for j: int in range(12):disk.append(pts[i]+Vector2.from_angle(TAU*j/12.0)*width*.5)
			_patch(String(row.id)+"join"+str(i),disk,row.texture,Vector2(512,512),-1000,24)
func _spawn_scene_objects(objects: Array,progressive: bool=false) -> void:
	# The real inherited consumer keeps original hide/quest/action semantics for
	# corpse/chest/herb, not a static duplicate pretending the flags are preserved.
	await super._spawn_scene_objects(objects,progressive)
	if not _road_refreshing_dynamic:
		for row: Dictionary in A.specs():
			var tex: Texture2D=load(String(row.texture)) as Texture2D
			if tex==null:_field_loading_failed=true;push_error("ROAD_NATIVE_MODULE_MISSING:"+String(row.texture));return
			var sprite:=Sprite2D.new();sprite.name="RoadNative_"+String(row.id);sprite.texture=tex;sprite.centered=false
			var source:=Vector2(row.source_foot_px[0],row.source_foot_px[1]);sprite.scale=Vector2.ONE*float(row.native_scale)
			sprite.position=row.foot-source*float(row.native_scale);sprite.z_index=clampi(int(floor(float(row.foot.y)/8)),0,1024)
			sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.set_meta("road_foot",row.foot)
			_actor_layer.add_child(sprite);_scene_object_nodes.append(sprite);_road_static.append(sprite)
			if String(row.id)==CAVE_ID:
				_road_cave=sprite
				_road_cave_foot_y=float(row.foot.y)
		var grave_texture := load(GRAVE_ART) as Texture2D
		if grave_texture != null:
			_road_grave = Sprite2D.new()
			_road_grave.name = "RoadsideGrave"
			_road_grave.texture = grave_texture
			_road_grave.centered = false
			_road_grave.offset = -Vector2(768, 972)
			_road_grave.position = GRAVE_FOOT
			_road_grave.scale = Vector2.ONE * 142.0 / 1263.0
			_road_grave.z_index = floori(GRAVE_FOOT.y / 8.0)
			_road_grave.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			_actor_layer.add_child(_road_grave)
			_scene_object_nodes.append(_road_grave)
			_road_static.append(_road_grave)
	_sync_road_burial()
	# A road refresh respawns the inherited tablet but retains native sprites.
	_road_depth=preload("res://build/linxi_mountain_road_20261030g_system01/road_depth.gd").new()
	_road_depth.configure(world_container)
	if is_instance_valid(_player):_road_depth.add_actor(_player)
	if is_instance_valid(_road_cave):_road_depth.add_prop(_road_cave,CAVE_ID,_road_cave_foot_y)
	for ridge: Sprite2D in _road_static:
		if String(ridge.name).begins_with("RoadNative_granite_ridge_"):
			var foot: Vector2=ridge.get_meta("road_foot")
			_road_depth.add_prop(ridge,String(ridge.name).trim_prefix("RoadNative_"),foot.y)
	var tablet := _visual_layer.get_node_or_null("SceneObject_"+TABLET_ID) as Sprite2D
	if is_instance_valid(tablet):
		tablet.reparent(_actor_layer)
		var tablet_foot := A.point(A.data().business.visual_feet[TABLET_ID])
		_road_depth.add_prop(tablet,TABLET_ID,tablet_foot.y)
func _rebuild_walkability_collision_entries(blockers: Array,objects: Array) -> void:
	_walkability_blocker_footprints.clear()
	for row: Dictionary in blockers:
		var size: Vector2=row.size;var center: Vector2=row.pos
		_walkability_blocker_footprints.append(Rect2(center-size*.5,size))
	for row: Dictionary in objects:
		if not row.has("collision_size"):continue
		if String(row.get("require_flag",""))!="" and not _flag_truthy(String(row.require_flag)):continue
		if String(row.get("hide_flag",""))!="" and _flag_truthy(String(row.hide_flag)):continue
		if not _quest_gate_passes(row):continue
		var center: Vector2=row.pos+row.get("collision_offset",Vector2.ZERO);var size: Vector2=row.collision_size
		_walkability_blocker_footprints.append(Rect2(center-size*.5,size))
func _spawn_collision_rects(rows: Array) -> void:
	super._spawn_collision_rects(rows)
	for polygon: PackedVector2Array in _road_solids:
		var body:=StaticBody2D.new();body.name="RoadCaveSolid_%d"%_collision_bodies.size();body.collision_layer=1;body.collision_mask=0
		var shape:=CollisionPolygon2D.new();shape.polygon=polygon;body.add_child(shape);_collision_layer.add_child(body);_collision_bodies.append(body)
func _is_blocked_by_layout(uv: Vector2) -> bool:
	if super._is_blocked_by_layout(uv):return true
	for solid: PackedVector2Array in _road_solids:
		if Geometry2D.is_point_in_polygon(uv*A.SIZE,solid):return true
	return false
func _update_dynamic_occluders(normalized_foot_position: Vector2, immediate: bool=false) -> void:
	if _road_depth==null or not is_instance_valid(_player):
		super._update_dynamic_occluders(normalized_foot_position,immediate)
		return
	_road_depth.add_actor(_player)
	_road_depth.refresh(_player,immediate)

func _process(delta: float) -> void:
	super._process(delta)
	if not _scene_rebuilding and _road_depth!=null and is_instance_valid(_player):
		# Also track animation changes when the character is standing still.
		_road_depth.refresh(_player)
