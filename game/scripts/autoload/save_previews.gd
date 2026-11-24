extends "res://scripts/autoload/save_manager.gd"

# Keep the small JPEG inside the same atomic JSON transaction as the character.
# A recovered backup therefore also recovers its matching image.
const WIDTH := 480
var _menu_frame := PackedByteArray()
var _menu_owner: WeakRef
var _scene_id := 0

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)

func _on_node_added(node: Node) -> void:
	if node.scene_file_path == "res://scenes/ui/system_menu.tscn" or (node.scene_file_path == "res://scenes/ui/save_slot_panel.tscn" and not node.get("embedded")):
		node.visibility_changed.connect(_remember_frame.bind(node))
		_remember_frame(node)

func _remember_frame(menu: Control) -> void:
	if not menu.is_visible_in_tree():
		return
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("_open_system_menu"):
		return
	# Visibility changes before the menu's first rendered frame.
	_menu_frame = _capture()
	_menu_owner = weakref(menu)
	_scene_id = scene.get_instance_id()

func _capture() -> PackedByteArray:
	if DisplayServer.get_name() == "headless":
		return PackedByteArray()
	var image := get_viewport().get_texture().get_image()
	if image == null or image.is_empty():
		return PackedByteArray()
	var width := mini(image.get_width(), WIDTH)
	image.resize(width, maxi(1, roundi(float(width) * image.get_height() / image.get_width())), Image.INTERPOLATE_BILINEAR)
	return image.save_jpg_to_buffer(0.80)

func _write_slot_atomic(slot: int, payload: String) -> bool:
	var menu := _menu_owner.get_ref() as Control if _menu_owner != null else null
	var scene := get_tree().current_scene
	var jpeg := PackedByteArray()
	if scene != null:
		if menu != null and menu.is_visible_in_tree() and scene.get_instance_id() == _scene_id:
			jpeg = _menu_frame
		else:
			jpeg = _capture()
	if not jpeg.is_empty():
		var data: Dictionary = JSON.parse_string(payload)
		data["preview_jpeg"] = Marshalls.raw_to_base64(jpeg)
		payload = JSON.stringify(data, "  ")
	return super._write_slot_atomic(slot, payload)

func get_slot_preview(slot: int) -> Texture2D:
	var encoded: Variant = _read_slot_data(slot).get("preview_jpeg", "")
	if not encoded is String or encoded.is_empty() or encoded.length() > 1000000:
		return null
	var image := Image.new()
	if image.load_jpg_from_buffer(Marshalls.base64_to_raw(encoded)) != OK:
		return null
	return ImageTexture.create_from_image(image)
