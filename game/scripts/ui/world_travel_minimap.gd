extends Control
## Read-only travel HUD. All map coordinates share one aspect-fit image rect.
const OVERVIEW_PATH := "res://art/maps/world_map_v15_complete_v9c/overview.png"
const FRAME_PATH := "res://art/ui/field_hud/v1/hud_quest_panel.png"
const OVERVIEW: Texture2D = preload(OVERVIEW_PATH)
const WORLD_VISUAL_PATCH := preload("res://scripts/world/world_farmland_visual_patch_resolver_20261015.gd")
const FRAME: Texture2D = preload(FRAME_PATH)
const WORLD_IDS := [&"world_map_jianghu", &"world_map_jianghu_v15", &"world_map_jianghu_v16"]
const WORLD_NATIVE = preload("res://build/world_coast_20261031h_system02/world_contract_dispatch03.gd")

var _configured := false
var _effective_overview: Texture2D = OVERVIEW
var _effective_overview_path := OVERVIEW_PATH
var _scene_id: StringName
var _world_size := Vector2.ZERO
var _player_ref: WeakRef
var _camera_ref: WeakRef
var _world_ref: WeakRef
var _portals: Array[Dictionary] = []
var _map_rect := Rect2()
var _view_rect := Rect2()
var _player_world := Vector2.ZERO
var _player_uv := Vector2.ZERO
var _player_marker := Vector2.ZERO
var _direction := "down"
var _viewport_size := Vector2.ZERO
var _plaque_ref: WeakRef
var _plaque_original_position := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_process(_configured)
	visible = false


func configure(scene: SceneScript, player: Node2D, camera: Camera2D, world_root: Node2D = null) -> bool:
	release()
	if scene == null or not WORLD_IDS.has(scene.scene_id) or scene.map_layout == null:
		return false
	if not WORLD_NATIVE.is_native(scene):
		return false
	if not is_instance_valid(player) or not is_instance_valid(camera):
		return false
	_world_size = Vector2(scene.map_layout.design_size)
	if not _world_size.is_finite() or _world_size.x <= 0.0 or _world_size.y <= 0.0:
		return false
	if world_root == null:
		world_root = player.get_parent() as Node2D
	if not is_instance_valid(world_root):
		return false
	for portal: Dictionary in scene.map_layout.portals:
		var uv: Variant = portal.get("pos")
		if not uv is Vector2 or not uv.is_finite() or uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
			release()
			return false
		_portals.append({"id": String(portal.get("id", "")), "uv": uv, "target_scene": String(portal.get("target_scene", ""))})
	_scene_id = scene.scene_id
	_effective_overview_path = scene.background_path if WORLD_NATIVE.V16.is_v16(scene) else WORLD_VISUAL_PATCH.overview_path(scene)
	_effective_overview = load(_effective_overview_path) as Texture2D if _effective_overview_path != OVERVIEW_PATH else OVERVIEW
	if _effective_overview == null and WORLD_NATIVE.V16.is_v16(scene):
		release();return false
	if _effective_overview == null:
		_effective_overview = OVERVIEW
		_effective_overview_path = OVERVIEW_PATH
	_player_ref = weakref(player)
	_camera_ref = weakref(camera)
	_world_ref = weakref(world_root)
	_configured = true
	set_process(true)
	update_view()
	return true


func _process(_delta: float) -> void:
	update_view()


func update_view() -> void:
	if not _configured or not is_inside_tree():
		visible = false
		return
	var player := _player_ref.get_ref() as Node2D
	var camera := _camera_ref.get_ref() as Camera2D
	var world := _world_ref.get_ref() as Node2D
	if not is_instance_valid(player) or not is_instance_valid(camera) or not is_instance_valid(world):
		visible = false
		return
	var hud := get_parent() as Control
	var plaque := hud.get_node_or_null("MapInfoPanel") as Control if hud != null else null
	visible = hud == null or ((plaque == null or plaque.is_visible_in_tree()) and not (hud.has_method("is_right_menu_visible") and hud.call("is_right_menu_visible")))
	var viewport_size := get_viewport_rect().size
	if viewport_size != _viewport_size:
		_viewport_size = viewport_size
		var ui_scale := clampf(viewport_size.y / 1080.0, 0.72, 1.0)
		size = Vector2(280.0, 210.0) * ui_scale
		var top := 116.0 * ui_scale
		var art := plaque.get_node_or_null("MapPanelArt") as TextureRect if plaque != null else null
		if plaque != null:
			if art != null:
				top = maxf(top, art.get_global_rect().end.y + 10.0 * ui_scale)
		top = clampf(top, 8.0, maxf(8.0, viewport_size.y - size.y - 12.0))
		var right_margin := 16.0 * ui_scale
		var canvas_position := Vector2(maxf(8.0, viewport_size.x - right_margin - size.x), top)
		if art != null:
			if _plaque_ref == null:
				_plaque_ref = weakref(plaque)
				_plaque_original_position = plaque.position
			# The minimap sets the right edge; transparent plaque canvas is not width.
			var center_x := maxf(8.0 + size.x * .5, viewport_size.x - right_margin - size.x * .5)
			plaque.global_position += Vector2(center_x - art.get_global_rect().get_center().x, 0.0)
			canvas_position.x = center_x - size.x * .5
		position = hud.get_global_transform().affine_inverse() * canvas_position if hud != null else canvas_position
		var inset := Rect2(Vector2(18.0, 32.0) * ui_scale, Vector2(244.0, 162.0) * ui_scale)
		var fit := minf(inset.size.x / _world_size.x, inset.size.y / _world_size.y)
		var fit_size := _world_size * fit
		_map_rect = Rect2(inset.position + (inset.size - fit_size) * 0.5, fit_size)
	var foot := player.global_position
	if player.has_method("get_depth_sort_y"):
		foot.y = float(player.call("get_depth_sort_y"))
	_player_world = world.to_local(foot)
	_player_uv = _player_world / _world_size
	_player_marker = _map_rect.position + _player_uv * _map_rect.size
	_direction = String(player.get("_direction"))
	# Inverse the actual rendered camera canvas, including camera limits/zoom.
	var inverse_canvas := get_viewport().get_canvas_transform().affine_inverse()
	var a := world.to_local(inverse_canvas * Vector2.ZERO) / _world_size
	var b := world.to_local(inverse_canvas * viewport_size) / _world_size
	var low := a.min(b).clamp(Vector2.ZERO, Vector2.ONE)
	var high := a.max(b).clamp(Vector2.ZERO, Vector2.ONE)
	_view_rect = Rect2(_map_rect.position + low * _map_rect.size, (high - low) * _map_rect.size)
	queue_redraw()


func _draw() -> void:
	if not _configured:
		return
	draw_texture_rect(FRAME, Rect2(Vector2.ZERO, size), false)
	draw_texture_rect(_effective_overview, _map_rect, false)
	draw_rect(_view_rect, Color(0.68, 0.91, 0.95, 0.9), false, 1.0)
	for portal: Dictionary in _portals:
		var point: Vector2 = _map_rect.position + portal.uv * _map_rect.size
		draw_circle(point, 3.0, Color(0.04, 0.12, 0.16, 1.0))
		draw_circle(point, 2.0, Color(0.8, 0.87, 0.67, 1.0))
	var facing := Vector2.DOWN
	match _direction:
		"up": facing = Vector2.UP
		"left": facing = Vector2.LEFT
		"right": facing = Vector2.RIGHT
	var side := facing.orthogonal()
	draw_circle(_player_marker, 5.5, Color(0.02, 0.08, 0.12, 1.0))
	draw_colored_polygon(PackedVector2Array([_player_marker + facing * 6.0, _player_marker - facing * 3.0 + side * 3.5, _player_marker - facing * 3.0 - side * 3.5]), Color(0.7, 1.0, 1.0, 1.0))


func get_debug_state() -> Dictionary:
	var global_map := Rect2(get_global_transform() * _map_rect.position, _map_rect.size)
	var portals: Array[Dictionary] = []
	for portal: Dictionary in _portals:
		var copy := portal.duplicate()
		copy["marker"] = get_global_transform() * (_map_rect.position + portal.uv * _map_rect.size)
		portals.append(copy)
	return {"configured": _configured, "scene_id": String(_scene_id), "visible": is_visible_in_tree(), "world_size": _world_size, "panel_rect": get_global_rect(), "map_rect": global_map, "player_world": _player_world, "player_uv": _player_uv, "player_marker": get_global_transform() * _player_marker, "direction": _direction, "view_rect": Rect2(get_global_transform() * _view_rect.position, _view_rect.size), "portals": portals, "mouse_filter": mouse_filter, "overview_path": OVERVIEW_PATH, "effective_overview_path":_effective_overview_path,"frame_path": FRAME_PATH}


func release() -> void:
	_restore_plaque()
	_effective_overview = OVERVIEW
	_effective_overview_path = OVERVIEW_PATH
	_configured = false
	visible = false
	set_process(false)
	_player_ref = null
	_camera_ref = null
	_world_ref = null
	_portals.clear()
	_scene_id = &""
	_world_size = Vector2.ZERO
	_viewport_size = Vector2.ZERO
	queue_redraw()


func _restore_plaque() -> void:
	var plaque: Variant = _plaque_ref.get_ref() if _plaque_ref != null else null
	if is_instance_valid(plaque):
		plaque.position = _plaque_original_position
	_plaque_ref = null


func _exit_tree() -> void:
	_restore_plaque()
