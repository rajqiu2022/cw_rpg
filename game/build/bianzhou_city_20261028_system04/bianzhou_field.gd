extends "res://scripts/field/field_walkable_controller.gd"
## New city only. Original Luoyang/World/controller sources are never rewritten.
const BZ = preload("res://build/bianzhou_city_20261028_system01/city_author.gd")
var _bz_specs: Array[Dictionary] = []
var _bz_ground: Array[Node2D] = []
var _bz_actor_fade: bool = false
var _bz_district: String = ""
var _bz_dialog_visit: Dictionary = {}
var _bz_layout_revision: int = 0
var _bz_images: Dictionary = {}
var _bz_solid_polygons: Array[PackedVector2Array] = []

func _load_scene(scene_id: StringName) -> SceneScript:
	return BZ.scene() if scene_id==BZ.ID else null

func _resolve_world_size(_scene: SceneScript, _texture: Texture2D) -> Vector2:
	return BZ.SIZE

func _scene_depth_band_max() -> int:
	return 1024

func _setup_scene(scene: SceneScript, player_spawn_override: Variant = null, progressive: bool = false) -> void:
	var completion: Dictionary=BZ.completion_data()
	if completion.get("status")!="READY_FINAL_BINDING":
		_field_loading_failed=true;push_error("[Bianzhou] 整城实体绑定尚未齐备");return
	_bz_specs=BZ.building_specs();_bz_specs.append_array(BZ.prop_specs())
	var gate: Variant=JSON.parse_string(FileAccess.get_file_as_string(BZ.GATE_BINDING))
	if not gate is Dictionary or gate.get("status")!="READY_FOR_BOUND_FIELD":
		_field_loading_failed=true;push_error("[Bianzhou] 南门模块尚未完成接合，拒绝替代旧图");return
	if not gate.get("objects") is Array or not gate.get("blockers") is Array:return
	for raw: Dictionary in gate.objects:
		var row: Dictionary=raw.duplicate(true)
		row.foot=Vector2(float(raw.foot[0]),float(raw.foot[1]))
		if raw.has("body"):row.body=Rect2(float(raw.body[0]),float(raw.body[1]),float(raw.body[2]),float(raw.body[3]))
		_bz_specs.append(row)
	for spec: Dictionary in _bz_specs:
		if not ResourceLoader.exists(String(spec.get("texture",""))):
			_field_loading_failed=true;push_error("[Bianzhou] 完整模块未入库，拒绝创建玩家");return
	var blockers: Array[Dictionary]=[]
	for spec: Dictionary in _bz_specs:
		if spec.has("body"):
			var rect: Rect2=spec.body
			blockers.append({"id":spec.id,"pos":rect.get_center()/BZ.SIZE,"size":rect.size/BZ.SIZE,"walkability_margin":0.0})
	_bz_solid_polygons.clear()
	for row: Dictionary in gate.blockers:
		if row.has("polygon"):
			var polygon:=PackedVector2Array()
			for point: Array in row.polygon:polygon.append(Vector2(float(point[0]),float(point[1])))
			_bz_solid_polygons.append(polygon);continue
		var rect:=Rect2(float(row.rect[0]),float(row.rect[1]),float(row.rect[2]),float(row.rect[3]))
		blockers.append({"id":row.id,"pos":rect.get_center()/BZ.SIZE,"size":rect.size/BZ.SIZE,"walkability_margin":0.0})
	scene.map_layout.blockers=blockers
	await super._setup_scene(scene,player_spawn_override,progressive)
	if not is_instance_valid(_player):return
	_portal_layer.z_index=2048
	_bz_layout_revision+=1
	for actor: NPCNode in _npc_nodes:
		actor.sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		if actor.npc_id.begins_with("bianzhou_life_"):
			actor._calibrate_adult_body=true;actor.sprite_scale=.8
			actor._apply_sprite_scale();actor._sync_ground_anchor()
		# Clear ID-guessed generic faces for both original services and life rows.
		# Only explicit matching body/portrait pairs are used; no Hero fallback.
		actor.portrait_path=_bz_matched_portrait(actor.sprite_path)
	_refresh_bz_depth()

func _spawn_world_background(_scene: SceneScript) -> void:
	_world_background=null;_background_streamer=null;_bz_ground.clear()
	_draw_bz_patch("outer_grass_base",PackedVector2Array([Vector2.ZERO,Vector2(BZ.SIZE.x,0),BZ.SIZE,Vector2(0,BZ.SIZE.y)]),BZ.GRASS,Vector2(768,768),-1200)
	_draw_bz_patch("inner_city_base",PackedVector2Array([Vector2(160,880),Vector2(5984,880),Vector2(5984,5236),Vector2(160,5236)]),BZ.STONE,Vector2(768,512),-1100)
	for road: Dictionary in BZ.roads():
		var pts: PackedVector2Array=road.points
		for i: int in range(pts.size()-1):
			var a: Vector2=pts[i];var b: Vector2=pts[i+1];var normal: Vector2=(b-a).normalized().orthogonal()*float(road.width)*.5
			var period:=Vector2(512,512) if String(road.texture)==BZ.SOIL else (Vector2(512,341.3333333) if String(road.texture)==BZ.STONE else Vector2(384,384))
			_draw_bz_patch(String(road.id)+str(i),PackedVector2Array([a+normal,b+normal,b-normal,a-normal]),String(road.texture),period,-1000)
	# Forecourts intentionally meet street edges. These are paving, not open NAV.
	for rect: Rect2 in [Rect2(4640,2650,1180,340),Rect2(300,2600,1080,500),Rect2(3300,1820,740,360),Rect2(1730,1280,1000,260)]:
		_draw_bz_patch("forecourt%d"%_bz_ground.size(),PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]),BZ.STONE,Vector2(512,341.3333333),-1000)

	for patch: Dictionary in BZ.ground_patches():
		_draw_bz_patch(patch.id,patch.polygon,patch.texture,patch.period,patch.z)

func _draw_bz_patch(id: String, polygon: PackedVector2Array, texture_path: String, period: Vector2, z: int) -> void:
	var texture:=load(texture_path) as Texture2D
	if texture==null:_field_loading_failed=true;return
	var node:=Polygon2D.new();node.name="BianzhouPaving_"+id;node.polygon=polygon;node.texture=texture
	node.texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED;node.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	var uv:=PackedVector2Array()
	for point: Vector2 in polygon:uv.append(point/period*texture.get_size())
	node.uv=uv;node.z_index=z;world_container.add_child(node);_bz_ground.append(node)

func _spawn_scene_objects(_objects: Array, _progressive: bool = false) -> void:
	# The specs are true complete images and native oblique views, never rotated
	# front elevations. Each physical footprint belongs to one actual object.
	var audit: Variant=JSON.parse_string(FileAccess.get_file_as_string("res://build/major_cities_20261028_art01/reuse_resources.json"))
	if not audit is Dictionary:_field_loading_failed=true;return
	var measured: Dictionary={}
	for row: Dictionary in audit.assets:measured["res://"+String(row.path).trim_prefix("game/")]=row
	for spec: Dictionary in _bz_specs:
		var path: String=String(spec.get("texture",""))
		if not ResourceLoader.exists(path):_field_loading_failed=true;push_error("[Bianzhou] 缺少完整模块 "+path);return
		var texture:=load(path) as Texture2D
		if texture==null:_field_loading_failed=true;return
		if not _bz_images.has(path):_bz_images[path]=texture.get_image()
		var sprite:=Sprite2D.new();sprite.name="BianzhouObject_"+String(spec.id);sprite.texture=texture
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;sprite.centered=false
		var foot: Vector2=spec.foot
		var source_foot:=Vector2(texture.get_width()*.5,texture.get_height()*.90)
		var native_scale: float=float(spec.get("native_scale",0))
		if measured.has(path):
			var bounds: Array=measured[path].alpha8_subject_diagnostic_NOT_MARGIN
			source_foot=Vector2((float(bounds[0])+float(bounds[2]))*.5,float(bounds[3]))
			if native_scale<=0:native_scale=float(spec.visible_width)/(float(bounds[2])-float(bounds[0]))
		elif spec.has("source_foot_px"):
			source_foot=Vector2(float(spec.source_foot_px[0]),float(spec.source_foot_px[1]))
		elif path.ends_with("chest_common_wood_v1.png"):
			source_foot=Vector2(256,468);native_scale=float(spec.visible_width)/432.0
		if native_scale<=0:native_scale=float(spec.visible_width)/float(texture.get_width())
		if spec.has("source_region_px"):
			# Reuse the complete native cross-section authored for a longitudinal
			# repeat. No PNG rewrite, rotation, horizontal squeeze or proxy strip.
			var region: Array=spec.source_region_px
			sprite.region_enabled=true
			sprite.region_rect=Rect2(float(region[0]),float(region[1]),float(region[2]),float(region[3]))
		sprite.scale=Vector2.ONE*native_scale;sprite.position=foot-source_foot*native_scale
		sprite.z_index=clampi(int(floor(foot.y/8.0)),0,1024)
		sprite.set_meta("bz_foot",foot);sprite.set_meta("bz_source_foot",source_foot)
		_actor_layer.add_child(sprite);_scene_object_nodes.append(sprite)
		if spec.get("label","")!="":
			var label:=Label.new();label.text=String(spec.label);label.position=foot-Vector2(140,30)
			label.add_theme_font_size_override("font_size",18);label.add_theme_color_override("font_shadow_color",Color.BLACK)
			label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2)
			_interaction_layer.add_child(label)

func _rebuild_walkability_collision_entries(blockers: Array, _objects: Array) -> void:
	_walkability_blocker_footprints.clear()
	for row: Dictionary in blockers:
		var size: Vector2=row.size;var pos: Vector2=row.pos
		_walkability_blocker_footprints.append(Rect2(pos-size*.5,size))

func _is_blocked_by_layout(normalized_pos: Vector2) -> bool:
	if super._is_blocked_by_layout(normalized_pos):return true
	for polygon: PackedVector2Array in _bz_solid_polygons:
		if Geometry2D.is_point_in_polygon(normalized_pos*BZ.SIZE,polygon):return true
	return false

func _spawn_collision_rects(rows: Array) -> void:
	super._spawn_collision_rects(rows)
	for polygon: PackedVector2Array in _bz_solid_polygons:
		var body:=StaticBody2D.new();body.name="BianzhouWallPolygon_%d"%_collision_bodies.size()
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
	_refresh_bz_depth()
	var foot: Vector2=world_container.to_local(_player.global_position)
	for row: Dictionary in BZ.district_rows():
		if (row.rect as Rect2).has_point(foot):
			var name: String="汴州城 · "+String(row.name)
			if _bz_district!=name:
				_bz_district=name;scene_title.text=name
				if _primary_hud!=null:_primary_hud.set_scene_info(name)
			break

func _refresh_bz_depth() -> void:
	if not is_instance_valid(_player):return
	var foot: Vector2=world_container.to_local(_player.global_position)
	var occluded:=false
	for node: Node2D in _scene_object_nodes:
		if not is_instance_valid(node) or not node is Sprite2D:continue
		var sprite: Sprite2D=node as Sprite2D
		var world_foot: Vector2=sprite.get_meta("bz_foot",Vector2.ZERO)
		if world_foot.y<=foot.y:continue
		var image: Image=_bz_images.get(sprite.texture.resource_path)
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
	if occluded!=_bz_actor_fade:
		_bz_actor_fade=occluded
		_player.modulate.a=.42 if occluded else 1.0

func _on_npc_action_requested(npc_id: String, action: String) -> void:
	if not action.begins_with("bianzhou_ambient:"):
		super._on_npc_action_requested(npc_id,action);return
	if DialogPlayer.is_playing():return
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(BZ.LORE))
	if not data is Dictionary:return
	var role: String=action.trim_prefix("bianzhou_ambient:")
	var selected: Dictionary={}
	for entry: Dictionary in data.entries:
		if entry.role==role:selected=entry;break
	if selected.is_empty():return
	var actor: NPCNode
	for item: NPCNode in _npc_nodes:
		if item.npc_id==npc_id:actor=item;break
	if actor==null:return
	var script:=DialogScript.new();script.dialog_id=StringName("bianzhou_life_"+npc_id)
	var hero:=DialogNode.new();hero.node_id=&"start";hero.speaker=String(data.opening_speaker);hero.text=String(selected.opening);hero.on_end="next:reply"
	var reply:=DialogNode.new();reply.node_id=&"reply";reply.speaker=role
	var visit: int=int(_bz_dialog_visit.get(npc_id,0));reply.text=String(selected.lines[visit%selected.lines.size()]);reply.on_end="end"
	script.nodes=[hero,reply];_bz_dialog_visit[npc_id]=visit+1
	_active_dialog_npc=actor;actor.begin_conversation(_player.global_position);_player.set_can_move(false)
	DialogPlayer.set_default_portrait(actor.portrait_path);DialogPlayer.set_default_speaker(role);DialogPlayer.play(script)

func get_bianzhou_debug() -> Dictionary:
	return {"size":BZ.SIZE,"layout_version":BZ.VERSION,"layout_revision":_bz_layout_revision,"objects":_scene_object_nodes.size(),"blockers":_collision_bodies.size(),"npcs":_npc_nodes.size(),"district":_bz_district,"field_instance":get_instance_id(),"player_instance":_player.get_instance_id() if is_instance_valid(_player) else 0}

func _bz_matched_portrait(sprite_path: String) -> String:
	var name: String=sprite_path.get_file()
	if name.begins_with("guard_young_bluegrey_"):return "res://art/characters/portraits/luoyang_city_finish_20261025i/guard_young_bluegrey_portrait_v1.png"
	if name.begins_with("guard_veteran_ochre_"):return "res://art/characters/portraits/luoyang_city_finish_20261025i/guard_veteran_ochre_portrait_v1.png"
	if name.begins_with("npc_docks_strong_carrier_"):return "res://art/characters/portraits/luoyang_docks_roles_20261019ad/portrait_docks_strong_carrier_v1.png"
	if name.begins_with("npc_street_merchant_"):return "res://art/characters/portraits/street_expansion_v1/portrait_street_merchant_v1.png"
	if name.begins_with("npc_escort_guard_"):return "res://art/characters/portraits/street_expansion_v1/portrait_escort_guard_v1.png"
	if name.begins_with("npc_vegetable_seller_"):return "res://art/characters/portraits/street_expansion_v1/portrait_vegetable_seller_v1.png"
	if sprite_path=="res://art/characters/npc_duqingshan_v3_idle_down_25d_4f.png":return "res://art/characters/portrait_duqingshan_steady.png"
	if sprite_path=="res://art/characters/npc_linxi_farmer_idle_down_25d_4f_v1_runtime.png":return "res://art/characters/portraits/portrait_linxi_farmer_v1.png"
	if sprite_path=="res://art/characters/npc_luoyang_paper_scholar_idle_down_25d_1f_20261024.png":return "res://art/characters/portraits/luoyang_scholar_20261024c/paper_scholar_v1.png"
	if sprite_path=="res://art/characters/street_expansion_v1/npc_inn_waiter_idle_down_4f.png":return "res://art/characters/portraits/street_expansion_v1/portrait_inn_waiter_v1.png"
	return ""
