extends Control
## Additive marker-only layer. No texture capture, camera, physics or business writes.
const SELF := "res://build/city_navigation_minimap_20261101d_candidate01/mini_marker_overlay.gd"
const Semantics = preload("res://build/city_navigation_minimap_20261101d_candidate01/service_semantics.gd")
const META := "city_navigation_20261101d_minimap"
const SCHEMA := "CITY_NAVIGATION_PAIRED_MARKERS_20261101D_V1"
const MINI_SCRIPTS := ["res://build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd", "res://build/three_settlements_20261030e_system01/city_minimap.gd"]
const ICONS := {"medicine":"res://art/ui/inventory/icons/icon_potion_sm.png", "smith":"res://art/props/blacksmith_hammer.png", "inn":"res://art/ui/inventory/icons/icon_suwusheng_teapot_sm.png"}
const EXIT_ICON := "res://art/ui/field_hud/portal_arrow_jade_v1.png"
var _field: WeakRef
var _mini: WeakRef
var _world: WeakRef
var _metadata: Dictionary = {}
var _rows: Array[Dictionary] = []
var _placed: Array[Dictionary] = []
var _saved_portals: Array[Dictionary] = []
var _plan_instance := 0
var _build_count := -1
var _textures: Dictionary = {}
var _snapshot := ""
var _room_services: Dictionary = {}
var _refresh_clock := 1.0
var _suppressed: Array[Dictionary] = []
var _attached_context := ""
var _context_stale := false

static func source_paths() -> Array[String]:
	var result: Array[String] = [SELF]
	result.append_array(Semantics.source_paths())
	var media: Array[String] = [EXIT_ICON]
	for path: String in ICONS.values(): media.append(path)
	for path: String in media:
		result.append(path); result.append(path + ".import")
		var expression := RegEx.new()
		expression.compile('path="(res://[^"\\r\\n]+\\.ctex)"')
		var found: RegExMatch = expression.search(FileAccess.get_file_as_string(path + ".import"))
		if found != null: result.append(found.get_string(1))
	return result

static func attach(field: Node, pairedmetadata: Dictionary) -> Dictionary:
	if not is_instance_valid(field) or not field.is_inside_tree() or field.get_tree().current_scene != field: return {"ok":false, "error":"MINI_ACTUAL_FIELD"}
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	if scene == null or pairedmetadata.get("ok") != true or pairedmetadata.get("schema") != SCHEMA or pairedmetadata.get("scene_id") != String(scene.scene_id) or not pairedmetadata.get("portals") is Array: return {"ok":false, "error":"MINI_PAIRED_METADATA"}
	var mini := field.get("_world_travel_minimap") as Control
	var world := field.get("world_container") as Node2D
	if not is_instance_valid(mini) or mini.get_script() == null or mini.get_script().resource_path not in MINI_SCRIPTS or not is_instance_valid(world): return {"ok":false, "error":"MINI_SUPPORTED_LIVE_HELPER"}
	if mini.get("_configured") != true or field.get("_field_loading_failed") == true or field.get("_scene_rebuilding") == true: return {"ok":false, "error":"MINI_NOT_READY"}
	for value: Variant in pairedmetadata.portals:
		if not value is Dictionary or not value.get("foot") is Vector2 or not value.foot.is_finite() or value.get("kind") not in ["building_door", "area_exit"] or String(value.get("id", "")).is_empty(): return {"ok":false, "error":"MINI_TYPED_PORTAL"}
	detach(field)
	var layer: Variant = load(SELF).new()
	layer.name = "ClassifiedNavigationMarkers"
	layer._field = weakref(field); layer._mini = weakref(mini); layer._world = weakref(world)
	layer._metadata = pairedmetadata.duplicate(true)
	layer._attached_context = String(mini.get("_context_id"))
	mini.add_child(layer)
	# Normal child ordering, never raise an absolute z over the hero portrait.
	var portrait: Control = mini.get("_portrait_marker") as Control
	if is_instance_valid(portrait): mini.move_child(layer, portrait.get_index())
	field.set_meta(META, weakref(layer))
	layer.call("_sync", true)
	return {"ok":true, "node":layer, "state":layer.call("get_debug_state")}

static func detach(field: Node) -> void:
	if not is_instance_valid(field) or not field.has_meta(META): return
	var reference: WeakRef = field.get_meta(META) as WeakRef
	var old: Node = reference.get_ref() as Node if reference != null else null
	field.remove_meta(META)
	if is_instance_valid(old): old.call("release"); old.get_parent().remove_child(old); old.queue_free()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE; focus_mode = Control.FOCUS_NONE
	process_priority = 200; texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_room_services = Semantics.service_rooms()
	for role: String in ICONS: _textures[role] = load(ICONS[role]) as Texture2D
	# Existing 128-square hammer, alpha bounds (32,17)..(119,109). A padded
	# square Atlas keeps the complete tool legible without any pixel rewrite.
	var hammer := AtlasTexture.new()
	hammer.atlas = _textures.smith as Texture2D
	hammer.region = Rect2(28,13,100,100); hammer.filter_clip = true
	_textures["smith"] = hammer
	_textures["exit"] = load(EXIT_ICON) as Texture2D

func _process(delta: float) -> void:
	_refresh_clock += delta
	_sync(_refresh_clock >= .25)

func _sync(refresh_actors: bool) -> void:
	var field: Node = _field.get_ref() as Node if _field != null else null
	var mini: Control = _mini.get_ref() as Control if _mini != null else null
	var world: Node2D = _world.get_ref() as Node2D if _world != null else null
	if not is_instance_valid(field) or not is_instance_valid(mini) or not is_instance_valid(world): hide(); return
	if field.get_tree().current_scene != field or mini.get("_configured") != true: hide(); return
	var plan: Control = mini.get("_plan") as Control
	if not is_instance_valid(plan): hide(); return
	if String(mini.get("_context_id")) != _attached_context:
		_context_stale = true; release(); return
	visible = plan.visible
	var count: int = int(mini.get("_static_build_count"))
	if _plan_instance != plan.get_instance_id() or count != _build_count:
		# Only the old display list is leased. Authoritative compiled portals,
		# live ExitZones and source dictionaries are never altered.
		_saved_portals.assign(plan.get("portals").duplicate(true))
		_plan_instance = plan.get_instance_id(); _build_count = count
		var empty: Array[Dictionary] = []
		plan.set("portals", empty); plan.queue_redraw()
	if refresh_actors:
		_refresh_clock = 0.0; _rows.clear()
		for portal: Dictionary in _metadata.portals:
			var row: Dictionary = {"id":portal.id,"foot":portal.foot,"kind":portal.kind,"target_scene":String(portal.get("target_scene","")),"locked":portal.get("locked",false),"pair_id":String(portal.get("pair_id","")),"source_portal":String(portal.get("source_portal",""))}
			row["service"] = String(_room_services.get(String(row.get("target_scene", "")), {}).get("service", "")) if row.kind == "building_door" else ""
			_rows.append(row)
		_rows.append_array(Semantics.active_actor_markers(field, world, _room_services))
	var area: Rect2 = mini.get("_map_rect")
	var origin: Vector2 = mini.get("_world_origin")
	var extent: Vector2 = mini.get("_world_size")
	var fingerprint: String = var_to_str([area, origin, extent, _rows, get_viewport_rect().size])
	if fingerprint != _snapshot:
		_snapshot = fingerprint; _layout(area, origin, extent); queue_redraw()

func _layout(area: Rect2, origin: Vector2, extent: Vector2) -> void:
	_placed.clear(); _suppressed.clear()
	if extent.x <= 0 or extent.y <= 0 or area.size.x <= 0 or area.size.y <= 0: return
	var ordered: Array[Dictionary] = _rows.duplicate(true)
	for row: Dictionary in ordered:
		row["priority"] = 100 if not String(row.get("service", "")).is_empty() else (80 if row.kind == "area_exit" else 60)
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.priority) > int(b.priority) if a.priority != b.priority else String(a.id) < String(b.id))
	var scale_ui: float = clampf(get_viewport_rect().size.y / 1080.0, .72, 1.0)
	for row: Dictionary in ordered:
		var point: Vector2 = area.position + (row.foot - origin) / extent * area.size
		if not area.grow(.1).has_point(point): _suppressed.append({"id":row.id,"reason":"OUTSIDE_CURRENT_CONTEXT"}); continue
		var side: float = (19.0 if row.priority == 100 else 12.0) * scale_ui
		var chosen := Rect2()
		# Only small cartographic displacement with a leader line. Stable IDs
		# decide ties; high-value services/exits precede ordinary interior doors.
		for shift: Vector2 in [Vector2.ZERO, Vector2(0,-8), Vector2(8,0), Vector2(-8,0), Vector2(0,8), Vector2(8,-8), Vector2(-8,-8)]:
			var center: Vector2 = (point + shift * scale_ui).clamp(area.position + Vector2.ONE * side * .5, area.end - Vector2.ONE * side * .5)
			var box := Rect2(center - Vector2.ONE * side * .5, Vector2.ONE * side)
			var free := true
			for prior: Dictionary in _placed:
				if box.grow(1.0).intersects(prior.rect): free = false; break
			if free: chosen = box; break
		if chosen.size == Vector2.ZERO: _suppressed.append({"id":row.id,"reason":"DENSITY_COLLISION","priority":row.priority}); continue
		var placed: Dictionary = row.duplicate(true)
		placed["point"] = point; placed["rect"] = chosen
		_placed.append(placed)

func _draw() -> void:
	for row: Dictionary in _placed:
		var box: Rect2 = row.rect
		var center := box.get_center()
		var ink := Color(.045,.09,.105,1.0)
		var edge := Color(.59,.85,.83,1.0) if row.get("locked") != true else Color(.6,.44,.43,1.0)
		if center.distance_to(row.point) > 2.0: draw_line(row.point, center, edge, .8, true)
		var role: String = String(row.get("service", ""))
		if not role.is_empty():
			draw_rect(box, ink); draw_rect(box, edge, false, 1.0)
			var texture: Texture2D = _textures.get(role) as Texture2D
			if texture != null: draw_texture_rect(texture, box.grow(-1.0), false)
			# Chinese short category supplies a reliable meaning at tiny scale;
			# icons remain the existing unmodified bitmap, not a newly drawn asset.
			_draw_short(String(Semantics.LABELS.get(role, "服")), box, edge)
		elif row.kind == "area_exit":
			draw_circle(center, box.size.x * .52, ink)
			var source := Rect2(24,0,256,352)
			var target := Rect2(center - Vector2(box.size.y * .7272727,box.size.y) * .5, Vector2(box.size.y * .7272727,box.size.y))
			draw_texture_rect_region(_textures.exit as Texture2D, target, source, edge)
		else:
			# Semantic map glyph, not a textured UI button: an open doorway has
			# a lintel and two uprights, while inter-area exits use the jade arrow.
			draw_rect(box, ink)
			var p := PackedVector2Array([Vector2(box.position.x+2,box.end.y-1),Vector2(box.position.x+2,box.position.y+1),Vector2(box.end.x-2,box.position.y+1),Vector2(box.end.x-2,box.end.y-1)])
			draw_polyline(p,edge,1.5,true)
			if row.get("locked") == true: draw_line(box.position + Vector2(2,2), box.end - Vector2(2,2), edge, 1.2, true)

func _draw_short(text: String, box: Rect2, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var font_size := 9
	var width: float = font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	var at := Vector2(box.end.x-width,box.end.y)
	draw_string_outline(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,3,Color(.025,.045,.055,1))
	draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func get_debug_state() -> Dictionary:
	return {"schema":"CITY_NAVIGATION_MINI_OVERLAY_20261101D_V1", "scene_id":_metadata.get("scene_id",""), "context_id":_attached_context, "context_stale":_context_stale, "portal_rows":_metadata.get("portals",[]).size(), "markers":_placed.duplicate(true), "suppressed":_suppressed.duplicate(true), "old_yellow_points_leased":_saved_portals.size(), "mouse_filter":mouse_filter, "source_image_writes":0, "captures_requested":0, "business_writes":0, "layout_writes":0, "hero_portrait_unchanged":true}

func release() -> void:
	set_process(false); hide()
	var mini: Control = _mini.get_ref() as Control if _mini != null else null
	if is_instance_valid(mini):
		var plan: Control = mini.get("_plan") as Control
		if is_instance_valid(plan) and plan.get_instance_id() == _plan_instance and int(mini.get("_static_build_count")) == _build_count and plan.get("portals").is_empty():
			plan.set("portals", _saved_portals.duplicate(true)); plan.queue_redraw()
