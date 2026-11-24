extends "res://scripts/field/field_walkable_controller.gd"
## New city only. Original Luoyang/World/controller sources are never rewritten.
const JL = preload("res://build/jinling_city_20261029_system01/city_author.gd")
var _jl_specs: Array[Dictionary] = []
var _jl_ground: Array[Node2D] = []
var _jl_actor_fade: bool = false
var _jl_district: String = ""
var _jl_dialog_visit: Dictionary = {}
var _jl_layout_revision: int = 0
var _jl_images: Dictionary = {}
var _jl_solid_polygons: Array[PackedVector2Array] = []
var _jl_ground_edge_shader: Shader
const _JL_GROUND_EDGE_CODE := """
shader_type canvas_item;
render_mode unshaded;
uniform vec2 edge_points[16];
uniform int edge_count = 0;
uniform float feather_px = 32.0;
varying vec2 ground_point;
varying vec4 ground_tint;
void vertex() { ground_point = VERTEX; ground_tint = COLOR; }
void fragment() {
	float distance_to_edge = 1000000.0;
	for (int i = 0; i < 16; i++) {
		if (i >= edge_count) { break; }
		int next_point = (i + 1) % edge_count;
		vec2 a = edge_points[i];
		vec2 span = edge_points[next_point] - a;
		float t = clamp(dot(ground_point - a, span) / max(dot(span, span), 0.0001), 0.0, 1.0);
		distance_to_edge = min(distance_to_edge, length(ground_point - a - span * t));
	}
	COLOR = texture(TEXTURE, UV) * ground_tint;
	COLOR.a *= smoothstep(0.0, feather_px, distance_to_edge);
}
"""

func _load_scene(scene_id: StringName) -> SceneScript:
	return JL.scene() if scene_id==JL.ID else null

func _resolve_world_size(_scene: SceneScript, _texture: Texture2D) -> Vector2:
	return JL.SIZE

func _scene_depth_band_max() -> int:
	return 1024

func _setup_scene(scene: SceneScript, player_spawn_override: Variant = null, progressive: bool = false) -> void:
	var art: Dictionary=JL.river_binding()
	if art.get("status")!="READY_NATIVE_RIVER_BINDING":
		_field_loading_failed=true;push_error("[Jinling] 河桥原生绑定未齐，拒绝替代旧图");return
	_jl_specs=JL.building_specs();_jl_specs.append_array(JL.prop_specs())
	for raw: Dictionary in art.get("objects",[]):
		var row: Dictionary=raw.duplicate(true)
		row.foot=Vector2(float(raw.foot[0]),float(raw.foot[1]))
		if raw.has("body"):row.body=Rect2(float(raw.body[0]),float(raw.body[1]),float(raw.body[2]),float(raw.body[3]))
		_jl_specs.append(row)
	for spec: Dictionary in _jl_specs:
		if not ResourceLoader.exists(String(spec.texture)):
			_field_loading_failed=true;push_error("[Jinling] 完整模块缺失 "+String(spec.texture));return
	var blockers: Array[Dictionary]=[]
	for spec: Dictionary in _jl_specs:
		if spec.has("body"):
			var rect: Rect2=spec.body
			blockers.append({"id":spec.id,"pos":rect.get_center()/JL.SIZE,"size":rect.size/JL.SIZE,"walkability_margin":0.0})
	_jl_solid_polygons=JL.solid_polygons()
	scene.map_layout.blockers=blockers
	await super._setup_scene(scene,player_spawn_override,progressive)
	if not is_instance_valid(_player):return
	_portal_layer.z_index=2048;_jl_layout_revision+=1
	for actor: NPCNode in _npc_nodes:
		actor.sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		actor._calibrate_adult_body=true;actor.sprite_scale=.8
		actor._apply_sprite_scale();actor._sync_ground_anchor()
		actor.portrait_path=_jl_matched_portrait(actor.sprite_path)
	_refresh_jl_depth()

func _spawn_world_background(_scene: SceneScript) -> void:
	_world_background=null;_background_streamer=null;_jl_ground.clear()
	_draw_jl_patch("outer_grass_base",PackedVector2Array([Vector2.ZERO,Vector2(JL.SIZE.x,0),JL.SIZE,Vector2(0,JL.SIZE.y)]),JL.GRASS,Vector2(768,768),-1200)
	for rect: Rect2 in [Rect2(80,80,5472,2000),Rect2(80,2520,5472,1496)]:
		_draw_jl_patch("bank_courts%d"%_jl_ground.size(),PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]),JL.SOIL,Vector2(512,512),-1100)
	_draw_jl_patch("canal_water",PackedVector2Array([Vector2(0,2040),Vector2(5632,2040),Vector2(5632,2560),Vector2(0,2560)]),JL.WATER,Vector2(420,420),-1090)
	for patch: Dictionary in preload("res://build/city_visual_diversity_20261031c/district_visuals.gd").rows("jinling"):
		_draw_jl_patch(patch.id,patch.polygon,patch.texture,patch.period,patch.z,PackedVector2Array(),patch.feather_px)
	for road: Dictionary in JL.roads():
		var pts: PackedVector2Array=road.points
		for i: int in range(pts.size()-1):
			var a: Vector2=pts[i];var b: Vector2=pts[i+1];var normal: Vector2=(b-a).normalized().orthogonal()*float(road.width)*.5
			var period:=Vector2(512,512) if String(road.texture)==JL.SOIL else (Vector2(256,170.6666667) if String(road.texture)==JL.STONE else Vector2(128,128))
			_draw_jl_patch(String(road.id)+str(i),PackedVector2Array([a+normal,b+normal,b-normal,a-normal]),String(road.texture),period,-998 if String(road.texture)==JL.PAVING else (-999 if String(road.texture)==JL.STONE else -1000))
	for bridge: Dictionary in JL.bridge_rows():
		var texture:=load(String(bridge.texture)) as Texture2D
		var sprite:=Sprite2D.new();sprite.name="JinlingDeck_"+String(bridge.id);sprite.centered=false;sprite.texture=texture
		sprite.scale=Vector2.ONE*float(bridge.scale);sprite.position=bridge.foot-bridge.source_foot*float(bridge.scale);sprite.z_index=-970
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;world_container.add_child(sprite);_jl_ground.append(sprite)
	var art: Dictionary=JL.river_binding()
	for raw: Dictionary in art.get("ground",[]):
		var polygon:=PackedVector2Array()
		for point: Array in raw.polygon:polygon.append(Vector2(float(point[0]),float(point[1])))
		_draw_jl_patch(raw.id,polygon,raw.texture,Vector2(float(raw.period[0]),float(raw.period[1])),int(raw.z),PackedVector2Array(),float(raw.get("feather_px",0)))
		if raw.has("opacity"):_jl_ground.back().modulate=Color(1,1,1,float(raw.opacity))
	for raw: Dictionary in art.get("foreground",[]):
		_draw_jl_foreground(raw)

func _draw_jl_foreground(raw: Dictionary) -> void:
	var node:=Polygon2D.new();node.name="JinlingRail_"+String(raw.id)
	var polygon:=PackedVector2Array();var uv:=PackedVector2Array()
	for point: Array in raw.polygon:polygon.append(Vector2(float(point[0]),float(point[1])))
	for point: Array in raw.source_uv:uv.append(Vector2(float(point[0]),float(point[1])))
	node.polygon=polygon;node.uv=uv;node.texture=load(String(raw.texture)) as Texture2D
	node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;node.z_index=clampi(int(floor(float(raw.depth_y)/8)),0,1024)
	_actor_layer.add_child(node);_jl_ground.append(node)

func _draw_jl_patch(id: String, polygon: PackedVector2Array, texture_path: String, period: Vector2, z: int, source_uv: PackedVector2Array = PackedVector2Array(), feather_px: float = 0.0) -> void:
	var texture:=load(texture_path) as Texture2D
	if texture==null:_field_loading_failed=true;return
	var node:=Polygon2D.new();node.name="JinlingPaving_"+id;node.polygon=polygon;node.texture=texture
	node.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED if source_uv.is_empty() else CanvasItem.TEXTURE_REPEAT_DISABLED
	node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;node.antialiased=true
	var uv:=PackedVector2Array()
	if source_uv.is_empty():
		for point: Vector2 in polygon:uv.append(point/period*texture.get_size())
	else:
		if source_uv.size()!=polygon.size():_field_loading_failed=true;return
		uv=source_uv
	if feather_px>0.0:
		if polygon.size()>16:_field_loading_failed=true;return
		if _jl_ground_edge_shader==null:
			_jl_ground_edge_shader=Shader.new();_jl_ground_edge_shader.code=_JL_GROUND_EDGE_CODE
		var material:=ShaderMaterial.new();material.shader=_jl_ground_edge_shader
		var boundary: PackedVector2Array=polygon.duplicate();boundary.resize(16)
		material.set_shader_parameter("edge_points",boundary);material.set_shader_parameter("edge_count",polygon.size());material.set_shader_parameter("feather_px",feather_px)
		node.material=material
	# Exact standalone water tile only; no bridge/bank/feather material changes.
	if id=="canal_water" and texture_path=="res://art/maps/jinling_city_20261029/river_water_v1.png" and source_uv.is_empty() and feather_px<=0.0:
		var water_flow_material:=ShaderMaterial.new()
		water_flow_material.shader=preload("res://build/city_visual_diversity_20261031c/river_flow.gdshader")
		node.material=water_flow_material
	node.set_meta("jl_texture_path",texture_path);node.set_meta("jl_period",period)
	node.set_meta("jl_source_uv",source_uv);node.set_meta("jl_feather_px",feather_px)
	node.uv=uv;node.z_index=z;world_container.add_child(node);_jl_ground.append(node)

func _spawn_scene_objects(_objects: Array, _progressive: bool = false) -> void:
	for spec: Dictionary in _jl_specs:
		var path: String=String(spec.texture);var texture:=load(path) as Texture2D
		if texture==null or not spec.has("source_foot_px") or not spec.has("native_scale"):
			_field_loading_failed=true;push_error("[Jinling] 原生模块脚锚缺失 "+path);return
		if not _jl_images.has(path):_jl_images[path]=texture.get_image()
		var sprite:=Sprite2D.new();sprite.name="JinlingObject_"+String(spec.id);sprite.texture=texture
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.centered=false
		var foot: Vector2=spec.foot;var scale_factor: float=float(spec.native_scale)
		var source_foot:=Vector2(float(spec.source_foot_px[0]),float(spec.source_foot_px[1]))
		if spec.has("source_region_px"):
			var region: Array=spec.source_region_px
			sprite.region_enabled=true;sprite.region_rect=Rect2(float(region[0]),float(region[1]),float(region[2]),float(region[3]))
		sprite.scale=Vector2.ONE*scale_factor;sprite.position=foot-source_foot*scale_factor
		sprite.z_index=clampi(int(floor(foot.y/8)),0,1024)
		sprite.set_meta("jl_foot",foot);sprite.set_meta("jl_source_foot",source_foot)
		_actor_layer.add_child(sprite);_scene_object_nodes.append(sprite)

func _rebuild_walkability_collision_entries(blockers: Array, _objects: Array) -> void:
	_walkability_blocker_footprints.clear()
	for row: Dictionary in blockers:
		var size: Vector2=row.size;var pos: Vector2=row.pos
		_walkability_blocker_footprints.append(Rect2(pos-size*.5,size))

func _is_blocked_by_layout(normalized_pos: Vector2) -> bool:
	if super._is_blocked_by_layout(normalized_pos):return true
	for polygon: PackedVector2Array in _jl_solid_polygons:
		if Geometry2D.is_point_in_polygon(normalized_pos*JL.SIZE,polygon):return true
	return false

func _spawn_collision_rects(rows: Array) -> void:
	super._spawn_collision_rects(rows)
	for polygon: PackedVector2Array in _jl_solid_polygons:
		var body:=StaticBody2D.new();body.name="JinlingRiverPolygon_%d"%_collision_bodies.size()
		body.collision_layer=1;body.collision_mask=0
		var shape:=CollisionPolygon2D.new();shape.polygon=polygon;body.add_child(shape)
		_collision_layer.add_child(body);_collision_bodies.append(body)

func _refresh_scene_preserving_player() -> void:
	# This city's decoration and occupancy have no quest/flag-dependent rows.
	# Opening a conversation or accepting a bounty must not rebuild terrain.
	_refresh_quest_panel();_scene_refresh_pending=false

func _process(delta: float) -> void:
	super._process(delta)
	if _scene_rebuilding or not is_instance_valid(_player):return
	_refresh_jl_depth()
	var foot: Vector2=world_container.to_local(_player.global_position)
	for row: Dictionary in JL.district_rows():
		if (row.rect as Rect2).has_point(foot):
			var name: String="金陵城 · "+String(row.name)
			if _jl_district!=name:
				_jl_district=name;scene_title.text=name
				if _primary_hud!=null:_primary_hud.set_scene_info(name)
			break

func _refresh_jl_depth() -> void:
	if not is_instance_valid(_player):return
	var foot: Vector2=world_container.to_local(_player.global_position)
	var occluded:=false
	for node: Node2D in _scene_object_nodes:
		if not is_instance_valid(node) or not node is Sprite2D:continue
		var sprite: Sprite2D=node as Sprite2D
		var world_foot: Vector2=sprite.get_meta("jl_foot",Vector2.ZERO)
		if world_foot.y<=foot.y:continue
		var image: Image=_jl_images.get(sprite.texture.resource_path)
		if image==null:continue
		# Sample the real object alpha at the hero's visible body, never the full
		# transparent canvas. Buildings remain opaque; only the actor is ghosted.
		for offset: Vector2 in [Vector2(0,-18),Vector2(0,-55),Vector2(0,-95),Vector2(-12,-55),Vector2(12,-55)]:
			var local: Vector2=sprite.to_local(_player.global_position+offset)
			if sprite.region_enabled and not Rect2(Vector2.ZERO,sprite.region_rect.size).has_point(local):continue
			var pixel:=Vector2i(local.floor())
			if sprite.region_enabled:pixel+=Vector2i(sprite.region_rect.position)
			if pixel.x>=0 and pixel.y>=0 and pixel.x<image.get_width() and pixel.y<image.get_height() and image.get_pixelv(pixel).a>.08:
				occluded=true;break
		if occluded:break
	if occluded!=_jl_actor_fade:
		_jl_actor_fade=occluded
		_player.modulate.a=.42 if occluded else 1.0

func _on_npc_action_requested(npc_id: String, action: String) -> void:
	if not action.begins_with("jinling_ambient:"):
		super._on_npc_action_requested(npc_id,action);return
	if DialogPlayer.is_playing():return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(JL.LORE))
	if not data is Dictionary:return
	var role: String=action.trim_prefix("jinling_ambient:")
	var selected: Dictionary={}
	for entry: Dictionary in data.entries:
		if entry.role==role:selected=entry;break
	if selected.is_empty():return
	var actor: NPCNode
	for item: NPCNode in _npc_nodes:
		if item.npc_id==npc_id:actor=item;break
	if actor==null:return
	var script:=DialogScript.new();script.dialog_id=StringName("jinling_life_"+npc_id)
	var hero:=DialogNode.new();hero.node_id=&"start";hero.speaker=GameState.player.display_name if GameState.player!=null else String(data.opening_speaker);hero.portrait_path=_npc_hero_portrait_24b(GameState.player.portrait_path if GameState.player!=null else "");hero.text=String(selected.opening);hero.on_end="next:reply"
	var reply:=DialogNode.new();reply.node_id=&"reply";reply.speaker=actor.npc_name
	var visit: int=int(_jl_dialog_visit.get(npc_id,0));reply.text=String(selected.lines[visit%selected.lines.size()]);reply.on_end="end"
	script.nodes=[hero,reply];_jl_dialog_visit[npc_id]=visit+1
	_active_dialog_npc=actor;actor.begin_conversation(_player.global_position);_player.set_can_move(false)
	DialogPlayer.set_default_portrait(actor.portrait_path);DialogPlayer.set_default_speaker(actor.npc_name);DialogPlayer.play(script)

func is_jinling_foot_safe_native(foot: Vector2, include_npcs: bool = true) -> bool:
	if _current_scene==null or _current_scene.map_layout==null or not is_instance_valid(_player):return false
	var body:=Rect2(foot-Vector2(17,12),Vector2(34,24))
	var corners:=PackedVector2Array([body.position,Vector2(body.end.x,body.position.y),body.end,Vector2(body.position.x,body.end.y)])
	for point: Vector2 in corners:
		var admitted:=false
		for polygon: PackedVector2Array in _current_scene.map_layout.walkable_regions:
			if Geometry2D.is_point_in_polygon(point/JL.SIZE,polygon):admitted=true;break
		if not admitted:return false
	var normalized:=Rect2(body.position/JL.SIZE,body.size/JL.SIZE)
	for rect: Rect2 in _walkability_blocker_footprints:
		if normalized.intersects(rect,true):return false
	for polygon: PackedVector2Array in _jl_solid_polygons:
		if not Geometry2D.intersect_polygons(corners,polygon).is_empty():return false
	var excluded: Array[RID]=[_player.get_rid()]
	if not include_npcs:
		for actor: NPCNode in _npc_nodes:
			var collider: StaticBody2D=actor.get("_body_collider")
			if is_instance_valid(collider):excluded.append(collider.get_rid())
	var shape:=RectangleShape2D.new();shape.size=Vector2(34,24)
	var query:=PhysicsShapeQueryParameters2D.new();query.shape=shape;query.collision_mask=1;query.exclude=excluded
	query.transform=Transform2D(0.0,world_container.to_global(foot));query.collide_with_areas=false;query.collide_with_bodies=true
	return world_container.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _on_npc_primary_dialog(npc_id: String, dialog_id: String, include_opening_24b: bool = true) -> void:
	if npc_id!="jinling_water_patrol" or dialog_id!="openworld_jinling_guide":
		super._on_npc_primary_dialog(npc_id,dialog_id,include_opening_24b);return
	var original:=load("res://data/dialogs/openworld_jinling_guide.tres") as DialogScript
	if original==null or not DialogPlayer.can_play_script(original):return
	var playable:=original.duplicate(true) as DialogScript
	var hero:=DialogNode.new();hero.node_id=&"__jinling_hero_open"
	hero.speaker=GameState.player.display_name if GameState.player!=null else "冷孤云"
	hero.portrait_path=_npc_hero_portrait_24b(GameState.player.portrait_path if GameState.player!=null else "")
	hero.text="叨扰了，这一带平日可还安稳？";hero.on_end="next:start"
	playable.nodes.push_front(hero)
	_remember_interaction_spawn();_player.set_can_move(false)
	for actor: NPCNode in _npc_nodes:
		if actor.npc_id==npc_id:
			_active_dialog_npc=actor;actor.begin_conversation(_player.global_position)
			DialogPlayer.set_default_portrait(actor.portrait_path);DialogPlayer.set_default_speaker(actor.npc_name);break
	DialogPlayer.play_at(playable,hero.node_id)
	EventBus.npc_talked_to.emit(StringName(npc_id))

func get_jinling_debug() -> Dictionary:
	return {"size":JL.SIZE,"layout_version":JL.VERSION,"layout_revision":_jl_layout_revision,"objects":_scene_object_nodes.size(),"blockers":_collision_bodies.size(),"npcs":_npc_nodes.size(),"district":_jl_district,"field_instance":get_instance_id(),"player_instance":_player.get_instance_id() if is_instance_valid(_player) else 0}

func _jl_matched_portrait(sprite_path: String) -> String:
	var name: String=sprite_path.get_file()
	if name.begins_with("guard_young_bluegrey_"):return "res://art/characters/portraits/luoyang_city_finish_20261025i/guard_young_bluegrey_portrait_v1.png"
	if name.begins_with("guard_veteran_ochre_"):return "res://art/characters/portraits/luoyang_city_finish_20261025i/guard_veteran_ochre_portrait_v1.png"
	if name.begins_with("npc_docks_strong_carrier_"):return "res://art/characters/portraits/luoyang_docks_roles_20261019ad/portrait_docks_strong_carrier_v1.png"
	if name.begins_with("npc_street_merchant_"):return "res://art/characters/portraits/street_expansion_v1/portrait_street_merchant_v1.png"
	if name.begins_with("npc_escort_guard_"):return "res://art/characters/portraits/street_expansion_v1/portrait_escort_guard_v1.png"
	if sprite_path=="res://art/characters/npc_zhuwei_vegetable_vendor_idle_down_25d_4f_v2_runtime.png":return "res://art/characters/portraits/generic/portrait_generic_older_woman_v1.png"
	if sprite_path=="res://art/characters/npc_duqingshan_v3_idle_down_25d_4f.png":return "res://art/characters/portrait_duqingshan_steady.png"
	if sprite_path=="res://art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png":return "res://art/characters/portraits/portrait_linxi_farmer_v1.png"
	if sprite_path=="res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png":return "res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png"
	if sprite_path=="res://art/characters/npc_zhuwei_inn_waiter_idle_down_25d_4f_v2_runtime.png":return "res://art/characters/portraits/street_expansion_v1/portrait_inn_waiter_v1.png"
	return ""
