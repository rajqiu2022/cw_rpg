extends Node
## Renders the authored east region without taking over the validated v16 map.
const ATLAS := preload("res://scripts/world/east_mainland_atlas.gd")
const THEME := preload("res://scripts/ui/wuxia_theme.gd")
const EAST_REGIONAL := &"east_mainland_overworld"
const EAST_IDS := [EAST_REGIONAL, &"east_tidegate_port", &"east_cangpu_city", &"east_salt_bay_village", &"east_tea_ridge_village"]
const WET_IDS := [EAST_REGIONAL, &"east_tidegate_port", &"east_salt_bay_village", &"east_cangpu_city"]
const WATER := preload("res://art/maps/jinling_city_20261029/river_water_v1.png")
const GRASS := preload("res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/grass_ground_diff_2k.jpg")
const EARTH := preload("res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png")
const STONE := preload("res://art/modules/luoyang_moat_v1/cobblestone_floor_08_diff_1k.jpg")
const SALT_SHADER := preload("res://shaders/east_salt_crust.gdshader")
const PAVING_SHADER := preload("res://shaders/east_continuous_paving.gdshader")


func _ready() -> void:
	get_tree().scene_changed.connect(_setup_terrain)
	get_tree().node_added.connect(_on_node_added)


func _setup_terrain() -> void:
	var id := SceneRouter.get_current_field_id()
	if not id in EAST_IDS:
		return
	var field := get_tree().current_scene
	if field == null or not field.has_method("get_field_loading_state"):
		return
	for i in 180:
		if not is_instance_valid(field) or field != get_tree().current_scene or id != SceneRouter.get_current_field_id():
			return
		var layer := field.get("_visual_layer") as Node2D
		var scene := field.get("_current_scene") as SceneScript
		if layer != null and scene != null and scene.scene_id == id and field.call("get_field_loading_state").get("complete", false):
			var size_px: Vector2 = field.get("_world_size")
			if size_px.x > 0 and size_px.y > 0:
				if not layer.has_node("EastTerrain"):
					_add_surfaces(layer, scene, size_px)
					_add_roads(field, layer, scene.map_layout, size_px)
				_install_local_map(field, scene)
				return
		await get_tree().process_frame


func _install_local_map(field: Node, scene: SceneScript) -> void:
	var hud := field.get("_primary_hud") as Control
	var actor := field.get("_player") as Node2D
	if hud == null or actor == null:
		return
	var existing := hud.get_node_or_null("EastMainlandMinimap")
	if existing != null:
		existing.call("configure_local", scene, actor)
		return
	if scene.scene_id != EAST_REGIONAL and GameState.get_flag(ATLAS.visit_flag(scene.scene_id)) != true:
		# This is a cartography-only flag. The general flag event rebuilds Field
		# layers for quest gates; no gate depends on a chart visit.
		GameState.flags[String(ATLAS.visit_flag(scene.scene_id))] = true
	var minimap := ATLAS.new()
	minimap.name = "EastMainlandMinimap"
	hud.add_child(minimap)
	minimap.configure_local(scene, actor)


func _add_surfaces(layer: Node2D, scene: SceneScript, size_px: Vector2) -> void:
	if layer.has_node("EastTerrain") or scene.map_layout.walkable_regions.is_empty():
		return
	var terrain := Node2D.new()
	terrain.name = "EastTerrain"
	terrain.z_index = -100
	layer.add_child(terrain)
	var bounds := PackedVector2Array([Vector2.ZERO, Vector2(size_px.x, 0), size_px, Vector2(0, size_px.y)])
	var id := scene.scene_id
	var wet := id in WET_IDS
	if wet:
		_surface(terrain, bounds, WATER, Vector2(860, 700), Color(0.65, 0.82, 0.83))
	else:
		_surface(terrain, bounds, GRASS, Vector2(1240, 1240), Color(0.75, 0.77, 0.67))
	var land_texture: Texture2D = GRASS if id in [EAST_REGIONAL, &"east_tea_ridge_village"] else EARTH
	for region in scene.map_layout.walkable_regions:
		var points := PackedVector2Array()
		for point in region:
			points.append(point * size_px)
		if wet:
			# A narrow stone shoreline is decorative only; the same inner
			# polygon is the actual land in WalkableMapLayout.
			var shore := Geometry2D.offset_polygon(points, 23.0)
			for band in shore:
				_surface(terrain, band, STONE, Vector2(580, 580), Color(0.71, 0.75, 0.63))
		_surface(terrain, points, land_texture, Vector2(1080, 1080), Color(0.88, 0.89, 0.83))
	for yard: Dictionary in scene.map_layout.get_meta("east_yards", []):
		var outline := PackedVector2Array()
		for point: Vector2 in yard.points:
			outline.append(point * size_px)
		var surface := STONE if yard.surface == "stone" else EARTH
		var period := Vector2.ONE * float(yard.repeat_px)
		var fringe_color: Color = yard.tint
		fringe_color.a = 0.45
		for fringe in Geometry2D.offset_polygon(outline, 8.0, Geometry2D.JOIN_ROUND):
			_surface(terrain, fringe, surface, period, fringe_color)
		_surface(terrain, outline, surface, period, yard.tint)
	for row: Dictionary in scene.map_layout.blockers:
		if not row.has("salt_pan"):
			continue
		# Exactly the same outer rectangle drives the Field's solid footprint.
		var extent: Vector2 = row.size * size_px
		var bed := Rect2(Vector2(row.pos) * size_px - extent * 0.5, extent)
		var crust := String(row.salt_pan) == "crystal"
		_surface(terrain, _corners(bed), EARTH, Vector2(380, 380), Color("806849"))
		_surface(terrain, _corners(bed.grow(-7.0)), STONE, Vector2(520, 520), Color("9c8872"))
		var fill := _surface(terrain, _corners(bed.grow(-15.0)), EARTH if crust else WATER, Vector2(310, 260), Color.WHITE if crust else Color("94aaa1"))
		if crust:
			var material := ShaderMaterial.new()
			material.shader = SALT_SHADER
			fill.material = material
		# Thin shaded inner edge and salt bloom stay within the real rim.
		_surface(terrain, _corners(Rect2(bed.position + Vector2(15, 15), Vector2(bed.size.x - 30, 8))), EARTH, Vector2(310, 240), Color("beb195") if crust else Color("585a43"))


func _corners(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])


func _surface(parent: Node2D, points: PackedVector2Array, material: Texture2D, period: Vector2, tint: Color) -> Polygon2D:
	var floor := Polygon2D.new()
	floor.polygon = points
	floor.texture = material
	floor.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	floor.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor.antialiased = true
	var uvs := PackedVector2Array()
	for p in points:
		uvs.append(p * Vector2(material.get_size()) / period)
	floor.uv = uvs
	floor.color = tint
	parent.add_child(floor)
	return floor


func _add_roads(field: Node, layer: Node2D, layout: WalkableMapLayout, size_px: Vector2) -> void:
	var paving := ShaderMaterial.new()
	paving.shader = PAVING_SHADER
	for road: Dictionary in layout.get_meta("east_routes", []):
		var points: PackedVector2Array = road.points
		var valid := true
		for i in range(points.size() - 1):
			var steps := maxi(1, int(ceil(((points[i + 1] - points[i]) * size_px).length() / 16.0)))
			for step in range(steps + 1):
				var point := points[i].lerp(points[i + 1], float(step) / steps)
				var on_land := false
				for poly in layout.walkable_regions:
					if Geometry2D.is_point_in_polygon(point, poly):
						on_land = true
						break
				if not on_land or field.call("_is_blocked_by_layout", point):
					push_warning("East road %s blocked at %s" % [road.id, point * size_px])
					valid = false
					break
			if not valid:
				break
		if not valid:
			continue
		var texture := load(road.texture) as Texture2D
		if texture == null:
			continue
		var road_line := Line2D.new()
		road_line.name = "TravelRoute_%s" % road.id
		road_line.width = float(road.width_px)
		road_line.texture = texture
		road_line.texture_mode = Line2D.LINE_TEXTURE_TILE
		road_line.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		if road.has("repeat_px"):
			road_line.default_color = layout.get_meta("east_lane_tint", Color.WHITE)
			var lane := ShaderMaterial.new()
			lane.shader = preload("res://shaders/east_settlement_lane.gdshader")
			lane.set_shader_parameter("repeat_px", float(road.repeat_px))
			lane.set_shader_parameter("width_px", road_line.width)
			road_line.material = lane
		elif texture == STONE:
			road_line.material = paving
		road_line.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		road_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		road_line.end_cap_mode = Line2D.LINE_CAP_ROUND
		road_line.joint_mode = Line2D.LINE_JOINT_ROUND
		road_line.antialiased = true
		road_line.z_index = -1
		for point in points:
			road_line.add_point(point * size_px)
		layer.add_child(road_line)


func _on_node_added(node: Node) -> void:
	if node is WorldMapPanel:
		_install_atlas.call_deferred(node)
	elif node.name == &"VisualLayer" and SceneRouter.get_current_field_id() in EAST_IDS:
		_setup_terrain.call_deferred()


func _install_atlas(panel: WorldMapPanel) -> void:
	if not is_instance_valid(panel) or panel.has_node("Frame/EastAtlasTab"):
		return
	var atlas := ATLAS.new() as Control
	atlas.name = "UnifiedTravelChart"
	# The original adventure overlay appends labels at z=10 and its
	# marker at z=20 while the panel is open; keep those on the west page.
	atlas.z_index = 24
	panel.close_btn.z_index = 25
	panel.map_rect.add_child(atlas)
	atlas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	atlas.hide()
	var tab := Button.new()
	tab.name = "EastAtlasTab"
	tab.z_index = 25
	panel.map_rect.get_parent().add_child(tab)
	tab.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	tab.position = Vector2(60, 10)
	THEME.style_button(tab, 19, THEME.JADE)
	tab.pressed.connect(func(): _switch_atlas(panel, atlas, tab, not atlas.visible))
	panel.visibility_changed.connect(func():
		if panel.visible:
			_switch_atlas.call_deferred(panel, atlas, tab, true)
	)
	if panel.visible:
		_switch_atlas(panel, atlas, tab, true)


func _switch_atlas(panel: WorldMapPanel, atlas: Control, tab: Button, unified: bool) -> void:
	if not is_instance_valid(panel) or not is_instance_valid(atlas) or not is_instance_valid(tab):
		return
	if unified:
		var path := SceneRouter.field_scene_resource_path(SceneRouter.get_active_world_map_scene())
		var west := load(path) as SceneScript if ResourceLoader.exists(path) else null
		var preview := panel.map_texture.texture
		# The known v16 preview is full-extent; do not position non-v16 maps in its space.
		unified = atlas.call("configure_overview", west, preview)
	atlas.visible = unified
	panel.map_texture.visible = not unified
	for child in panel.map_rect.get_children():
		if child is CanvasItem and child.has_meta("world_map_runtime"):
			child.visible = not unified
	tab.text = "中原详图" if unified else "东西总览"
	if unified:
		atlas.move_to_front()
		atlas.queue_redraw()
