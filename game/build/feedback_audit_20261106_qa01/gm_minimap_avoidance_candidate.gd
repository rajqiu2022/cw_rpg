extends RefCounted
## Candidate only. Attach to the accepted World icon overlay; no autoload.
## Relocate only an intersecting GM launcher, never the map or its coordinates.
var _launcher_ref: WeakRef
var _original := Vector2.ZERO
var _owned := Vector2.ZERO
var _leased := false
var _moves := 0
var _unresolved := false
var _mini_id := 0
var _viewport_size := Vector2.ZERO
var _user_override := false
var _press_seen := false
var _press_position := Vector2.ZERO
var _observed_launcher_id := 0
var _observed_position := Vector2.ZERO

func sync(owner: Control, mini: Control, map_rect: Rect2, active: bool) -> void:
	if not active or not is_instance_valid(mini):
		release()
		return
	var resized := _viewport_size != owner.get_viewport_rect().size
	if _mini_id != mini.get_instance_id():
		release()
		_mini_id = mini.get_instance_id()
		_user_override = false
		_press_seen = false
		_observed_launcher_id = 0
	if resized:
		_viewport_size = owner.get_viewport_rect().size
		_user_override = false
		_press_seen = false
	var gm := owner.get_node_or_null("/root/GMConsole")
	if gm == null:
		release()
		return
	var launcher := gm.get_node_or_null("GMFloatingButton") as Control
	if not is_instance_valid(launcher) or not launcher.is_visible_in_tree():
		release()
		return
	if not resized and _observed_launcher_id == launcher.get_instance_id() and launcher.position != _observed_position:
		_user_override = true
		_forget()
	_observed_launcher_id = launcher.get_instance_id()
	_observed_position = launcher.position
	# The user owns a deliberate drag. Do not fight it while the pointer is down.
	if gm.get("_drag_candidate") == true:
		if not _press_seen:
			_press_seen = true
			_press_position = launcher.position
		if gm.get("_dragged") == true or launcher.position != _press_position:
			_user_override = true
			_forget()
		return
	if _press_seen:
		if gm.get("_dragged") == true or launcher.position != _press_position:
			_user_override = true
			_forget()
		_press_seen = false
	if _leased and (_launcher_ref.get_ref() != launcher or launcher.position != _owned):
		_forget() # External/user movement supersedes our restoration lease.
		if not resized:
			_user_override = true
	if _user_override:
		return # Do not reassert after release; only resize/new mini clears this.
	var exclusion := _viewport_rect(mini, map_rect.grow(8.0)).grow(10.0)
	var button_rect := _viewport_rect(launcher, Rect2(Vector2.ZERO, launcher.size))
	_unresolved = false
	if not exclusion.intersects(button_rect):
		return
	var viewport_rect := owner.get_viewport_rect()
	var proposals: Array[Vector2] = [
		Vector2(exclusion.position.x - button_rect.size.x, button_rect.position.y),
		Vector2(button_rect.position.x, exclusion.end.y),
		Vector2(button_rect.position.x, exclusion.position.y - button_rect.size.y),
		Vector2(exclusion.end.x, button_rect.position.y),
	]
	for point: Vector2 in proposals:
		var candidate := Rect2(point, button_rect.size)
		if not viewport_rect.encloses(candidate) or exclusion.intersects(candidate):
			continue
		if not _leased:
			_launcher_ref = weakref(launcher)
			_original = launcher.position
			_leased = true
		var delta := point - button_rect.position
		# Convert a viewport delta through the real CanvasLayer and parent basis.
		var local_delta := launcher.get_global_transform_with_canvas().basis_xform_inv(delta)
		launcher.position += launcher.get_transform().basis_xform(local_delta)
		_owned = launcher.position
		_observed_position = launcher.position
		_moves += 1
		return
	_unresolved = true # No safe slot: preserve control visibility and position.

func _viewport_rect(control: Control, rect: Rect2) -> Rect2:
	var transform := control.get_global_transform_with_canvas()
	var result := Rect2(transform * rect.position, Vector2.ZERO)
	for point: Vector2 in [Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		result = result.expand(transform * point)
	return result

func release() -> void:
	var launcher := _launcher_ref.get_ref() as Control if _launcher_ref != null else null
	if _leased and is_instance_valid(launcher) and launcher.position == _owned:
		launcher.position = _original
		_observed_position = launcher.position
	_forget()

func _forget() -> void:
	_launcher_ref = null
	_leased = false

func get_debug_state() -> Dictionary:
	return {"leased":_leased, "moves":_moves, "unresolved":_unresolved, "original":_original, "owned":_owned, "user_override":_user_override, "mini_id":_mini_id, "viewport_size":_viewport_size}
