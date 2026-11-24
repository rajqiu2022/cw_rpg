extends "res://tests/test_world_map_v14_production_20261002.gd"

## Isolated event diagnosis only. No import/render, save write, asset mutation,
## direct ExitZone.try_interact or pointer -> router success substitution.
var events: Array = []

class EventWitness extends Node:
	var records: Array
	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			records.append({"stage":"input", "device":event.device, "pressed":event.pressed, "position":event.position})
	func _unhandled_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			records.append({"stage":"unhandled", "device":event.device, "pressed":event.pressed, "position":event.position})

func _inspect(label: String, zone: Node2D) -> void:
	var player: Node2D = field.get("_player")
	var marker: Sprite2D = zone.get("marker_visual")
	var point := marker.get_global_transform_with_canvas().origin
	var controls: Array = []
	for node: Node in root.find_children("*", "Control", true, false):
		var control := node as Control
		if control.is_visible_in_tree() and control.mouse_filter != Control.MOUSE_FILTER_IGNORE and control.get_global_rect().has_point(point):
			controls.append({"path":String(control.get_path()), "filter":control.mouse_filter, "rect":control.get_global_rect()})
	print("[V14PointerDiagnostic] ", {"label":label, "field":field.get("_current_scene").scene_id, "root_size":root.size,
		"viewport_rect":root.get_visible_rect(), "stretch":root.get_stretch_transform(), "final_transform":root.get_final_transform(), "screen":point,
		"canvas":marker.get_global_transform_with_canvas(), "marker_rect":marker.get_rect(), "marker_hit":field.call("_pointer_hits_sprite", marker, point, 9.0),
		"player":player.position, "range":zone.get("_in_range"), "can_move":player.get("can_move"),
		"dialog":root.get_node("DialogPlayer").call("is_playing"), "panel":field.get("_system_panel_open"), "rebuild":field.get("_scene_rebuilding"),
		"encounter":field.get("_encounter_locked"), "focus":root.gui_get_focus_owner(), "controls_at_point":controls})
	events.clear()
	await _pointer(point)
	for frame in range(10): await process_frame
	print("[V14PointerDiagnostic] events=",events," actual_router=",root.get_node("SceneRouter").call("get_current_field_id"),
		" loading=",root.get_node("LoadingManager").get("_transition_active"))
	events.clear()
	var physical := root.get_final_transform() * point
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = physical
		event.global_position = physical
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await process_frame
	for frame in range(10): await process_frame
	print("[V14PointerDiagnostic CORRECTED CONTROL] logical=",point," physical=",physical," events=",events,
		" actual_router=",root.get_node("SceneRouter").call("get_current_field_id")," loading=",root.get_node("LoadingManager").get("_transition_active"))

func _run() -> void:
	candidate_stage = true
	active_id = CANDIDATE_ID
	active_path = CANDIDATE_PATH
	world = load(active_path)
	source_contract = _json(SOURCE_PATH)
	player_saves_before = _actual_player_saves()
	print("[V14PointerDiagnostic] Field SHA=",FileAccess.get_sha256("res://scripts/field/field_walkable_controller.gd"))
	_fixture_new_game()
	var witness := EventWitness.new()
	witness.records = events
	root.add_child(witness)
	for portal_id in ["huashan", "luoyang"]:
		var p: Dictionary = {}
		for candidate: Dictionary in world.map_layout.portals:
			if String(candidate.id) == portal_id: p = candidate
		if not await _open_world(_point(p.pos)): continue
		await _normal_dialog_finish()
		_collect_runtime()
		var zone: Node2D = runtime_portals[String(p.target_scene)]
		await _inspect(portal_id + " normal parsed marker click", zone)
		# Independently exercise Space only AFTER logging the failed pointer.
		# It remains an explicit separate control, never pointer success.
		if root.get_node("SceneRouter").call("get_current_field_id") == active_id:
			await _key(KEY_SPACE)
		if await _wait_field(StringName(p.target_scene)):
			print("[V14PointerDiagnostic ACTUAL FIELD] target=",field.get("_current_scene").scene_id," path=",field.get("_current_scene").resource_path)
			await _normal_dialog_finish()
			var exits: Array = field.get("_exit_nodes")
			for reverse: Node2D in exits:
				if String(reverse.get("target_scene_id")) in [String(WORLD_ID),String(CANDIDATE_ID)] or String(reverse.get("action")) == "world_map":
					var stand := _safe_stand_near(reverse.position,70)
					if stand.is_finite() and await _place_fixture(stand): await _inspect(portal_id + " target return marker click", reverse)
					break
		while bool(root.get_node("LoadingManager").get("_transition_active")): await process_frame
		var returned := await _wait_field(active_id)
		print("[V14PointerDiagnostic ACTUAL RETURN] loaded=",returned," scene=",field.get("_current_scene").scene_id,
			" path=",field.get("_current_scene").resource_path," foot=",field.get("_player").position," expected=",_point(p.pos)*WORLD_SIZE)
	print("[V14PointerDiagnostic] normal_save_SHA_unchanged=",player_saves_before == _actual_player_saves()," NO GPU/full-suite approval; diagnosis only")
	quit(0)
