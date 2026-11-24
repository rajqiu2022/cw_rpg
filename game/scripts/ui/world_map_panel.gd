class_name WorldMapPanel
extends Control

signal closed

const WORLD_SCENE_PATH := "res://data/scenes/world_map_jianghu.tres"
const PLAYER_MARKER_PATH := "res://art/characters/weapon_variants/lengguyun/v7_idle_stable/sword/lengguyun_sword_idle_down_25d_4f.png"
const CLOSE_NORMAL := preload("res://art/ui/inventory/buttons/btn_x_normal.png")
const CLOSE_HOVER := preload("res://art/ui/inventory/buttons/btn_x_hover.png")
const CLOSE_PRESSED := preload("res://art/ui/inventory/buttons/btn_x_pressed.png")

@onready var map_rect: Control = %MapRect
@onready var map_texture: TextureRect = %Map
@onready var close_btn: TextureButton = %CloseBtn


func _ready() -> void:
	visible = false
	close_btn.texture_normal = CLOSE_NORMAL
	close_btn.texture_hover = CLOSE_HOVER
	close_btn.texture_pressed = CLOSE_PRESSED
	close_btn.tooltip_text = "关闭 (Esc / M)"
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(close)


func open() -> void:
	visible = true
	move_to_front()
	_rebuild_from_world_scene()
	close_btn.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func _rebuild_from_world_scene() -> void:
	for child: Node in map_rect.get_children():
		if child != map_texture and child.has_meta("world_map_runtime"):
			child.queue_free()
	var world_id := SceneRouter.get_active_world_map_scene()
	var world_scene: SceneScript = load(SceneRouter.field_scene_resource_path(world_id)) as SceneScript
	if world_scene == null or world_scene.map_layout == null:
		return
	var preview_path := world_scene.background_path
	if world_scene.streamed_background != null:
		var mobile_preview := world_scene.streamed_background.get_preview_path(false)
		if not mobile_preview.is_empty():
			preview_path = mobile_preview
	if not preview_path.is_empty() and ResourceLoader.exists(preview_path):
		map_texture.texture = load(preview_path) as Texture2D
	for raw_portal: Variant in world_scene.map_layout.portals:
		if raw_portal is Dictionary:
			_build_location_label(raw_portal)
	_build_player_marker(SceneRouter.get_world_map_position_for_scene(SceneRouter.get_current_field_id(), world_id))


func _build_location_label(entry: Dictionary) -> void:
	var position_value: Variant = entry.get("pos", null)
	if not position_value is Vector2:
		return
	var label := Label.new()
	label.set_meta("world_map_runtime", true)
	var unlocked := _is_unlocked(String(entry.get("require_flag", "")))
	var is_ferry := String(entry.get("travel_mode", "")) == "ferry"
	label.text = String(entry.get("label", entry.get("id", "未知地点"))) + (" · 渡口" if is_ferry else "")
	label.tooltip_text = ("步行抵达后乘船换乘" if unlocked else "航线尚未开放") if is_ferry else ("已可进入" if unlocked else "尚未开放")
	var label_width := 132.0 if is_ferry else 96.0
	label.position = Vector2(position_value) * map_rect.size + Vector2(-label_width * 0.5, 18.0)
	label.size = Vector2(label_width, 30.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.48, 1.0) if unlocked else Color(0.64, 0.70, 0.67, 0.9))
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.03, 1.0))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_rect.add_child(label)


func _build_player_marker(position_value: Variant) -> void:
	if not position_value is Vector2 or not ResourceLoader.exists(PLAYER_MARKER_PATH):
		return
	var strip := load(PLAYER_MARKER_PATH) as Texture2D
	var frame := AtlasTexture.new()
	frame.atlas = strip
	frame.region = Rect2(48.0, 10.0, 64.0, 148.0)
	var marker := Sprite2D.new()
	marker.set_meta("world_map_runtime", true)
	marker.texture = frame
	marker.position = Vector2(position_value) * map_rect.size + Vector2(0.0, -29.0)
	marker.scale = Vector2(0.36, 0.36)
	map_rect.add_child(marker)


func _is_unlocked(flag: String) -> bool:
	if flag.is_empty():
		return true
	var value: Variant = GameState.flags.get(flag, false)
	return value == true or (value is int and value != 0) or (value is String and not value.is_empty())


func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_M)):
		get_viewport().set_input_as_handled()
		close()
