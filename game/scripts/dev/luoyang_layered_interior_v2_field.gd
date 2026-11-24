extends "res://scripts/field/field_walkable_controller.gd"
## Loaded after autoloads. No production controller or action dispatcher edits.
var lab_contract: RefCounted
var definition: SceneScript
var observed_actions: Array[Dictionary] = []
var return_state: Dictionary = {"active": false, "local_only": true}
var _input_kind := "none"
var _pointer_images: Dictionary = {}

func _ready() -> void:
	if lab_contract == null or not lab_contract.materialization_valid(definition):
		push_error("Luoyang dev Field refuses inherited layout/scene arrays")
		return
	_init_ui_canvas_layers()
	_init_field_ui_styles()
	_init_formal_hud()
	_apply_formal_hud_mode()
	_disable_gameplay_button_focus(self)
	# No inherited _ready(), EventBus UI listeners or system panel instantiation.
	# Disable every authored/HUD button too: keyboard protection alone is unsafe.
	_disable_lab_buttons(self)
	_current_scene = definition
	var original_spawn: Variant = SceneRouter.get("_current_field_spawn")
	var original_payload: Dictionary = SceneRouter.get("_field_payload").duplicate(true)
	_setup_scene(definition, definition.player_spawn)
	# The inherited setup writes a transient return anchor; restore the exact
	# TWO touched fields before the first frame. The public navigation loader
	# intentionally upgrades old versions to formal14, so it is not a rollback.
	# Do not touch version/current ID/returns or hide any other state mutation.
	SceneRouter.set("_current_field_spawn", original_spawn)
	SceneRouter.set("_field_payload", original_payload)
	_refresh_gold()
	var banner := Label.new()
	banner.name = "LabSafetyBanner"
	banner.text = "洛阳分层试样 · 交互只记录，不推进剧情 · 不保存"
	banner.position = Vector2(420, 18)
	banner.add_theme_font_size_override("font_size", 26)
	banner.add_theme_color_override("font_color", Color(1, .88, .54))
	banner.add_theme_color_override("font_outline_color", Color.BLACK)
	banner.add_theme_constant_override("outline_size", 4)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_canvas_layer.add_child(banner)
	if _formal_hint_label != null:
		_formal_hint_label.text = "分层机制试样 · 移动 / 空格 / 近距点击；全部动作只记录，不保存"

func _disable_lab_buttons(node: Node) -> void:
	if node is BaseButton:
		node.disabled = true
		node.visible = false
	for child: Node in node.get_children(): _disable_lab_buttons(child)

func _resolve_player_spawn(_scene: SceneScript, override: Variant) -> Vector2:
	var point: Vector2 = override if override is Vector2 else definition.player_spawn
	return point if lab_contract.safe_body(point * lab_contract.SIZE) else definition.player_spawn

func _spawn_has_foot_clearance(_scene: SceneScript, point: Vector2) -> bool:
	return lab_contract.safe_body(point * lab_contract.SIZE)

func _is_inside_walkable_screen(screen_pos: Vector2) -> bool:
	return lab_contract.safe_body(world_container.to_local(screen_pos))

func _rebuild_walkability_collision_entries(_blockers: Array, _objects: Array) -> void:
	# Exact declared zero-margin geometry shared with actual CollisionPolygon2D;
	# never inherit the legacy normalized .004 grow or v15 travel capsule.
	_walkability_blocker_footprints.clear()

func _spawn_scene_objects(objects: Array) -> void:
	_v14_modular_overlap = load("res://scripts/world/outskirts_modular_overlap.gd").new()
	_v14_modular_overlap.configure(world_container)
	_create_v14_late_depth_refresh()
	super._spawn_scene_objects(objects)
	for sprite: Sprite2D in _scene_object_nodes:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	for object: Dictionary in lab_contract.manifest.objects:
		if not bool(object.blocking): continue
		var body := StaticBody2D.new()
		body.name = "LabPhysical_%s" % String(object.id)
		body.collision_layer = 1
		body.collision_mask = 0
		# Geometry is explicitly WORLD pixels. Parent transform stays identity.
		body.position = Vector2.ZERO
		_collision_layer.add_child(body)
		for raw: Array in object.get("solid_polygons_px", []):
			var polygon := CollisionPolygon2D.new()
			polygon.polygon = lab_contract.polygon_from(raw)
			body.add_child(polygon)
		var box_size: Vector2 = lab_contract.vec(object.get("collision_size_px", []))
		if box_size.x > 0 and box_size.y > 0:
			var shape := CollisionShape2D.new()
			var rectangle := RectangleShape2D.new()
			rectangle.size = box_size
			shape.shape = rectangle
			shape.position = lab_contract.vec(object.physical_center_px)
			body.add_child(shape)
		body.set_meta("authoring_id", String(object.id))
		_collision_bodies.append(body)

func _spawn_exits(data: Array) -> void:
	super._spawn_exits(data)
	for index in range(_exit_nodes.size()):
		var zone: ExitZone = _exit_nodes[index]
		var binding: Dictionary = data[index]
		zone.set_meta("lab_portal", binding.duplicate(true))
		for connection: Dictionary in zone.exit_triggered.get_connections(): zone.exit_triggered.disconnect(connection.callable)
		for connection: Dictionary in zone.exit_action_triggered.get_connections(): zone.exit_action_triggered.disconnect(connection.callable)
		zone.exit_triggered.connect(func(_target: String, _pos: Vector2): _activate_identity(String(binding.id), "portal"))
		zone.exit_action_triggered.connect(func(_action: String): _activate_identity(String(binding.id), "portal"))

func _on_player_moved(_position: Vector2) -> void:
	if _scene_rebuilding or not is_instance_valid(_player): return
	_update_actor_depth(_player)
	# Current-frame local alpha ghost and 8px-band tie order use the existing
	# ordinary-field helper's late refresh. No encounters or Router writes.

func _on_player_interacted() -> void:
	_input_kind = "space"
	super._on_player_interacted()
	_input_kind = "none"

func _pointer_hits_sprite(sprite: Sprite2D, viewport_point: Vector2, padding: float = 0) -> bool:
	if sprite == null or sprite.texture == null or not sprite.is_visible_in_tree(): return false
	# Physical entity mouse probes must hit actual current alpha, not the large
	# transparent RGBA rectangle. Arrow padding remains normal Field behavior.
	if sprite.name == "MarkerVisual": return super._pointer_hits_sprite(sprite, viewport_point, padding)
	var path: String = sprite.texture.resource_path
	if not _pointer_images.has(path):
		var original_image: Image = sprite.texture.get_image()
		if original_image == null: return false
		if original_image.is_compressed() and original_image.decompress() != OK: return false
		_pointer_images[path] = original_image
	var local: Vector2 = sprite.get_global_transform_with_canvas().affine_inverse() * viewport_point
	var rect: Rect2 = sprite.get_rect()
	if not rect.has_point(local): return false
	var image: Image = _pointer_images[path]
	var uv: Vector2 = (local - rect.position) / rect.size
	if sprite.flip_h: uv.x = 1.0 - uv.x
	if sprite.flip_v: uv.y = 1.0 - uv.y
	var source_rect: Rect2 = sprite.region_rect if sprite.region_enabled else Rect2(Vector2.ZERO, Vector2(image.get_size()))
	var frame_size: Vector2 = source_rect.size / Vector2(sprite.hframes, sprite.vframes)
	var frame_origin: Vector2 = source_rect.position + Vector2(sprite.frame % sprite.hframes, floori(float(sprite.frame) / float(sprite.hframes))) * frame_size
	var pixel: Vector2i = Vector2i(frame_origin + Vector2(minf(floorf(uv.x * frame_size.x), frame_size.x - 1), minf(floorf(uv.y * frame_size.y), frame_size.y - 1)))
	return pixel.x >= 0 and pixel.y >= 0 and pixel.x < image.get_width() and pixel.y < image.get_height() and image.get_pixelv(pixel).a > .1

func _dispatch_pointer_interaction(point: Vector2) -> bool:
	_input_kind = "mouse"
	var handled: bool = super._dispatch_pointer_interaction(point)
	_input_kind = "none"
	return handled

func _on_trigger_zone_entered(body: Node2D, data: Dictionary) -> void:
	if body != _player or not bool(data.get("interaction_only", false)): return
	var action: String = String(data.get("action", ""))
	if action.begins_with("lab_identity:"): _activate_identity(action.trim_prefix("lab_identity:"), "entity")
	# No trigger-in-flight lock, Dialog, scene refresh or automatic body-enter.

func _on_npc_interacted(npc_id: String, dialog_id: String) -> void:
	_record_npc(npc_id, "dialog:" + dialog_id)

func _on_npc_action_requested(npc_id: String, action: String) -> void:
	_record_npc(npc_id, action)

func _record_npc(id: String, action: String) -> void:
	if not is_instance_valid(_player) or not lab_contract.safe_body(_player.position): return
	for npc: Dictionary in definition.npcs:
		if String(npc.npc_id) != id: continue
		_record({"source_scene_id": npc.lab_source_scene_id, "source_id": id, "action": action}, "npc", true)
		return

func _resolve_field_action(_action: String) -> void:
	push_error("Lab refuses unbound action dispatch")

func _activate_identity(id: String, activation: String) -> void:
	if not is_instance_valid(_player) or not lab_contract.safe_body(_player.position): return
	var activated := false
	for binding: Dictionary in lab_contract.action_bindings(id):
		var required: String = String(binding.get("require_flag", ""))
		var hidden: String = String(binding.get("hide_flag", ""))
		var allowed: bool = (required.is_empty() or _flag_truthy(required)) and (hidden.is_empty() or not _flag_truthy(hidden))
		_record(binding, activation, allowed)
		activated = activated or allowed
	if not activated: return
	# Only this dev checkpoint moves the player. Original target is audit-only.
	if id in ["south_gate", "enter_luoyang"] and not bool(return_state.active):
		var source: Vector2 = _player.position
		if source.distance_to(lab_contract.gate_foot) > 64 or not lab_contract.safe_body(lab_contract.inner_foot): return
		return_state = {"active": true, "local_only": true, "source_foot_px": source, "target_foot_px": lab_contract.inner_foot, "original_route_executed": false}
		_player.position = lab_contract.inner_foot
		_update_actor_depth(_player)
		_snap_camera_to_player()
	elif id == "lab_return" and bool(return_state.active):
		var source: Vector2 = return_state.source_foot_px
		if _player.position.distance_to(lab_contract.inner_foot) > 64 or not lab_contract.safe_body(source): return
		_player.position = source
		return_state.active = false
		return_state.returned_foot_px = source
		_update_actor_depth(_player)
		_snap_camera_to_player()

func _record(binding: Dictionary, activation: String, allowed: bool) -> void:
	var event: Dictionary = binding.duplicate(true)
	event.activation = activation
	event.input_kind = _input_kind
	event.player_foot_px = _player.position
	event.dry_run = true
	event.gate_passes = allowed
	event.executed = false
	observed_actions.append(event)
	_show_toast("只记录、不执行：" + String(binding.action) + ("" if allowed else "（原门禁未满足）"))

func get_lab_contract() -> Dictionary:
	return lab_contract.manifest.duplicate(true)

func get_lab_scene() -> SceneScript:
	return definition

func get_preview_return_state() -> Dictionary:
	return return_state.duplicate(true)

func _open_system_menu() -> void:
	_show_toast("机制试样不提供存档、任务、商店或战斗；Esc退出。")
func _open_save_slot_panel() -> void: _open_system_menu()
func _toggle_inventory_panel() -> void: _open_system_menu()
func _toggle_equipment_panel() -> void: _open_system_menu()
func _toggle_skill_panel() -> void: _open_system_menu()
func _toggle_quest_log_panel() -> void: _open_system_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().call("restore_preview_state")
			get_tree().quit()
			get_viewport().set_input_as_handled()
		elif event.keycode in [KEY_F5, KEY_M, KEY_C, KEY_K, KEY_J, KEY_I, KEY_F12, KEY_E]:
			_open_system_menu()
			get_viewport().set_input_as_handled()
		return
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.device < 0:
		get_viewport().set_input_as_handled()
		return
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		if _dispatch_pointer_interaction(event.position): get_viewport().set_input_as_handled()
