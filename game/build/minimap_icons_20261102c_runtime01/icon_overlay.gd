extends Control
const GM_AVOIDANCE := preload("res://build/minimap_gm_20261106_runtime01/gm_minimap_avoidance.gd")
var _gm_avoidance := GM_AVOIDANCE.new()
## Transparent bitmap glyphs only: no labels, circles, backing tiles or fake doors.
const ATLAS_PATH := "res://art/ui/minimap_icons_20261102c/location_atlas.png"
const ATLAS_CELLS := {"city":Vector2i(0,0), "village":Vector2i(1,0), "outskirts":Vector2i(2,0), "sect":Vector2i(0,1), "ferry":Vector2i(1,1), "pawn":Vector2i(2,1)}
# Offline read-only alpha>=24 audit of the exact selected1536x1024 PNG.
# Rectangles are cell-local; no source pixels or other cell corners are changed.
const ATLAS_NATIVE_SIZE := Vector2i(1536,1024)
const ATLAS_VISIBLE_BOUNDS := {"city":Rect2i(76,125,425,319), "village":Rect2i(31,115,439,326), "outskirts":Rect2i(14,90,418,359), "sect":Rect2i(72,36,420,395), "ferry":Rect2i(20,167,460,238), "pawn":Rect2i(43,57,372,381)}
const PORTRAIT := preload("res://scripts/ui/minimap_portrait.gd")
const EXISTING_ICONS := {"medicine":"res://art/ui/inventory/icons/icon_potion_sm.png", "smith":"res://art/props/blacksmith_hammer.png", "inn":"res://art/ui/inventory/icons/icon_suwusheng_teapot_sm.png", "exit":"res://art/ui/field_hud/portal_arrow_jade_v1.png"}
var _runtime: WeakRef
var _field: WeakRef
var _mini: WeakRef
var _is_world := false
var _icons: Dictionary = {}
var _textures: Dictionary = {}
var _rows: Array[Dictionary] = []
var _placed: Array[Dictionary] = []
var _leases: Array[Dictionary] = []
var _plan_lease: Dictionary = {}
var _portrait: Control
var _gray: ShaderMaterial
var _atlas_ready := false
var _atlas_regions: Dictionary = {}
var _map_rect := Rect2()
var _chart := preload("res://scripts/ui/minimap_exploration.gd").new()
var _overview: Texture2D
var _missing_assets: Array[String] = []
var _last_context := ""

func configure(runtime: Node, field: Node, mini: Control, is_world: bool) -> void:
	_runtime = weakref(runtime); _field = weakref(field); _mini = weakref(mini); _is_world = is_world

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE; focus_mode = Control.FOCUS_NONE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR; process_priority = 1400
	var shader := Shader.new()
	# Sample exactly once. Multiplying the sampled texture by fragment COLOR
	# would square its already-textured RGB/alpha and make small glyphs black.
	shader.code = "shader_type canvas_item; varying vec4 vertex_tint; void vertex(){vertex_tint=COLOR;} void fragment(){vec4 c=texture(TEXTURE,UV); float v=dot(c.rgb,vec3(0.299,0.587,0.114)); COLOR=vec4(vec3(0.35+0.65*v)*vertex_tint.rgb,c.a*vertex_tint.a);}"
	_gray = ShaderMaterial.new(); _gray.shader = shader
	for kind: String in EXISTING_ICONS:
		var path: String = EXISTING_ICONS[kind]
		if ResourceLoader.exists(path): _textures[kind] = load(path) as Texture2D
	if _textures.get("smith") != null:
		var hammer := AtlasTexture.new(); hammer.atlas = _textures.smith; hammer.region = Rect2(28,13,100,100); hammer.filter_clip = true; _textures.smith = hammer
	if _textures.get("exit") != null:
		var arrow := AtlasTexture.new(); arrow.atlas = _textures.exit; arrow.region = Rect2(24,0,256,352); arrow.filter_clip = true; _textures.exit = arrow
	_load_atlas()
	_portrait = PORTRAIT.new(); _portrait.name = "LocalPlayerPortrait"; add_child(_portrait)
	refresh_rows()

func _load_atlas() -> void:
	if _atlas_ready or not ResourceLoader.exists(ATLAS_PATH):
		return
	var atlas: Texture2D = load(ATLAS_PATH) as Texture2D
	if atlas == null or Vector2i(atlas.get_width(),atlas.get_height()) != ATLAS_NATIVE_SIZE:
		return
	# Alpha1 specks span most cells and are not useful size evidence. The exact
	# alpha>=24 rectangles below were measured offline; runtime does no image
	# readback or million-pixel scan. Only AtlasTexture's source region changes.
	var cell := Vector2i(atlas.get_width() / 3, atlas.get_height() / 2)
	for kind: String in ATLAS_CELLS:
		var source_cell := Rect2i(ATLAS_CELLS[kind] * cell, cell)
		var content: Rect2i = ATLAS_VISIBLE_BOUNDS[kind]
		if not content.has_area():
			return
		var padded: Rect2i = content.grow(2).intersection(Rect2i(Vector2i.ZERO, cell))
		var region := Rect2i(source_cell.position + padded.position, padded.size)
		var texture := AtlasTexture.new(); texture.atlas = atlas; texture.region = Rect2(region); texture.filter_clip = true
		_textures[kind] = texture
		_atlas_regions[kind] = {"cell":source_cell, "alpha_bounds_in_cell":content, "region":region, "native_padding":2, "alpha_threshold":24, "source_pixels_unchanged":true}
	_atlas_ready = true

func _live() -> Array:
	var runtime: Node = _runtime.get_ref() as Node if _runtime != null else null
	var field: Node = _field.get_ref() as Node if _field != null else null
	var mini: Control = _mini.get_ref() as Control if _mini != null else null
	return [runtime,field,mini]

func refresh_rows() -> void:
	var live: Array = _live()
	var runtime: Node = live[0]; var field: Node = live[1]; var mini: Control = live[2]
	if not is_instance_valid(runtime) or not is_instance_valid(field) or not is_instance_valid(mini):
		return
	var world: Node2D = field.get("world_container") as Node2D
	if not is_instance_valid(world):
		return
	_load_atlas()
	_rows.assign(runtime.call("world_rows" if _is_world else "city_rows", field, world))
	_suppress_old_draws(mini)
	_sync(mini)

func _lease_self_draw(node: CanvasItem) -> void:
	for lease: Dictionary in _leases:
		if lease.node.get_ref() == node:
			node.self_modulate = Color(1,1,1,0)
			return
	_leases.append({"node":weakref(node), "self_modulate":node.self_modulate})
	node.self_modulate = Color(1,1,1,0)

func _suppress_old_draws(mini: Control) -> void:
	_lease_self_draw(mini) # The enlarged chart draws its own frame.
	if _is_world:
		for child_name: String in ["ThreeTownPips", "AdventureWorldPips31f"]:
			var pips: CanvasItem = mini.get_node_or_null(NodePath(child_name)) as CanvasItem
			if is_instance_valid(pips): _lease_self_draw(pips)
	else:
		var old: CanvasItem = mini.get_node_or_null("ClassifiedNavigationMarkers") as CanvasItem
		if is_instance_valid(old):
			_lease_self_draw(old)
		var plan: Control = mini.get("_plan") as Control
		if is_instance_valid(plan):
			var context: String = String(mini.get("_context_id")) + ":" + str(mini.get("_static_build_count"))
			if _plan_lease.get("id",0) != plan.get_instance_id() or _last_context != context:
				_restore_plan()
				_plan_lease = {"node":weakref(plan), "id":plan.get_instance_id(), "portals":(plan.get("portals") as Array).duplicate(true)}
				_last_context = context
			var portals: Array = plan.get("portals")
			if not portals.is_empty():
				var empty: Array[Dictionary] = []; plan.set("portals", empty); plan.queue_redraw()

func _process(_delta: float) -> void:
	var live: Array = _live()
	var mini: Control = live[2]
	if not is_instance_valid(mini):
		_gm_avoidance.release()
		hide(); return
	_sync(mini)

func _sync(mini: Control) -> void:
	visible = mini.visible and mini.get("_configured") == true
	if not visible:
		_gm_avoidance.release()
		return
	size = mini.size
	_map_rect = mini.get("_map_rect")
	var extra := (_map_rect.size * 0.35).round()
	_map_rect.position.x -= extra.x
	_map_rect.size += extra
	if _is_world:
		_gm_avoidance.sync(self, mini, _map_rect, visible)
	var origin: Vector2 = Vector2.ZERO if _is_world else mini.get("_world_origin")
	var extent: Vector2 = mini.get("_world_size")
	if extent.x <= 0 or extent.y <= 0 or _map_rect.size == Vector2.ZERO:
		return
	var scene_key := String(mini.get("_scene_id"))
	if _is_world:
		_overview = mini.get("_effective_overview") as Texture2D
	else:
		var plan := mini.get("_plan") as Control
		visible = is_instance_valid(plan) and plan.visible
		if not visible:
			return
		_overview = plan.get("base_texture") as Texture2D
		_refine_city_capture(mini, extent)
		_lease_self_draw(plan)
		var original := mini.get_node_or_null("PlayerPortraitMarker") as Control
		if original:
			_lease_self_draw(original)
		scene_key += "/" + String(mini.get("_context_id"))
	var uv: Vector2 = mini.get("_player_uv")
	_chart.follow(scene_key, uv, extent, _map_rect.size)
	_portrait.call("sync_marker", _chart.project(uv, _map_rect))
	var ui_scale: float = clampf(get_viewport_rect().size.y / 1080.0, .72, 1.0)
	_placed.clear(); _missing_assets.clear()
	var active: Dictionary = {}
	var ordered: Array = _rows.duplicate(true)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return _priority(a) > _priority(b) if _priority(a) != _priority(b) else String(a.id) < String(b.id))
	for row: Dictionary in ordered:
		var texture: Texture2D = _textures.get(String(row.kind)) as Texture2D
		if texture == null:
			if not _missing_assets.has(String(row.kind)): _missing_assets.append(String(row.kind))
			continue # No fake label, rectangle or substitute when art is missing.
		var point: Vector2 = _chart.project((row.foot - origin) / extent, _map_rect)
		if not _map_rect.grow(.1).has_point(point):
			continue
		var side: float = (22.0 if _is_world else (19.0 if row.kind == "exit" else 24.0)) * ui_scale
		var box := Rect2()
		for shift: Vector2 in [Vector2.ZERO, Vector2(0,-5), Vector2(5,0), Vector2(-5,0), Vector2(0,5), Vector2(5,-5), Vector2(-5,-5)]:
			var center: Vector2 = (point + shift * ui_scale).clamp(_map_rect.position + Vector2.ONE * side * .5, _map_rect.end - Vector2.ONE * side * .5)
			var candidate := Rect2(center - Vector2.ONE * side * .5, Vector2.ONE * side)
			var free := true
			for other: Dictionary in _placed:
				if candidate.grow(.5).intersects(other.rect): free = false; break
			if free: box = candidate; break
		if box.size == Vector2.ZERO:
			continue
		var id: String = String(row.id)
		active[id] = true
		var icon: TextureRect = _icons.get(id) as TextureRect
		if not is_instance_valid(icon):
			icon = TextureRect.new(); icon.name = "MapGlyph"; icon.mouse_filter = Control.MOUSE_FILTER_IGNORE; icon.focus_mode = Control.FOCUS_NONE
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			add_child(icon); _icons[id] = icon
		icon.texture = texture; icon.position = box.position; icon.size = box.size
		icon.material = _gray if _is_world and row.get("visited") != true else null
		icon.modulate.a = 1.0 if _chart.is_explored((row.foot - origin) / extent) else 0.30
		icon.visible = true
		var record: Dictionary = row.duplicate(true); record["rect"] = box; record["point"] = point; _placed.append(record)
	for id: String in _icons.keys():
		if not active.has(id):
			var old: TextureRect = _icons[id] as TextureRect
			if is_instance_valid(old): old.queue_free()
			_icons.erase(id)
	move_child(_portrait, get_child_count()-1)
	queue_redraw()

# The native plan owns the one-shot scene capture. Increase its sampling once
# per viewport, preserving the original bounds, origin and retained scene.
func _refine_city_capture(mini: Control, extent: Vector2) -> void:
	var vp := mini.get_node_or_null("CityVisualThumbnail/StaticCityVisualCache") as SubViewport
	if vp == null or vp.has_meta("local_detail_ready"):
		return
	var dimensions := Vector2i((extent * minf(1.0, 2560.0 / maxf(extent.x, extent.y))).round()).maxi(1)
	if dimensions.x > vp.size.x:
		var factor := Vector2(dimensions) / Vector2(vp.size)
		vp.canvas_transform = vp.canvas_transform.scaled(factor)
		vp.size = dimensions
		vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.set_meta("local_detail_ready", true)

func _priority(row: Dictionary) -> int:
	return 80 if String(row.kind) == "exit" else (90 if _is_world else 100)

func _draw() -> void:
	if _overview == null or _map_rect.size == Vector2.ZERO:
		return
	# Match the accepted unobtrusive city mini frame, without the old thick art.
	draw_rect(_map_rect.grow(8), Color(.035,.07,.085,.5))
	draw_rect(_map_rect.grow(8), Color(.43,.57,.60,.26), false, 1)
	_chart.draw_layer(self, _overview, _map_rect)
	_chart.draw_layer(self, _chart.texture, _map_rect)

func _restore_plan() -> void:
	var reference: WeakRef = _plan_lease.get("node") as WeakRef
	var plan: Control = reference.get_ref() as Control if reference != null else null
	if is_instance_valid(plan) and (plan.get("portals") as Array).is_empty():
		plan.set("portals", _plan_lease.get("portals",[])); plan.queue_redraw()
	_plan_lease.clear()

func _exit_tree() -> void:
	_gm_avoidance.release()
	_restore_plan()
	for lease: Dictionary in _leases:
		var node: CanvasItem = lease.node.get_ref() as CanvasItem
		if is_instance_valid(node): node.self_modulate = lease.self_modulate

func get_debug_state() -> Dictionary:
	return {"kind":"WORLD" if _is_world else "CITY", "atlas_path":ATLAS_PATH, "atlas_ready":_atlas_ready, "atlas_regions":_atlas_regions.duplicate(true), "rows":_rows.duplicate(true), "markers":_placed.duplicate(true), "missing_assets":_missing_assets.duplicate(), "ordinary_building_markers":0, "icon_backplates":0, "icon_text":0, "world_player_arrow":false, "world_player_portrait":_portrait.call("get_debug_state") if is_instance_valid(_portrait) else {}, "mouse_filter":mouse_filter, "coordinate_owner_unchanged":true}

func ready_for_loading_release() -> bool:
	var live: Array = _live()
	var mini: Control = live[2]
	if not is_instance_valid(mini) or mini.get("_configured") != true or not _atlas_ready or not _missing_assets.is_empty() or _map_rect.size.x <= 0 or _map_rect.size.y <= 0:
		return false
	if _is_world:
		return _overview != null and is_instance_valid(_portrait)
	var plan: Control = mini.get("_plan") as Control
	# The loading owner separately waits for the original thumbnail capture.
	# Preparing these icons must not reject that first still-pending draw frame.
	return is_instance_valid(plan)
