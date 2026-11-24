extends "res://scripts/city/luoyang_enclosure_building_fade_preview_20261010.gd"
## Field-selected enclosure runtime. Frozen preview/source-alpha/native-order
## algorithms are inherited; only binding, Player handoff and teardown differ.
var _runtime_bound := false
var _last_release: Dictionary = {}

func configure_scene(world: Node2D, scene_id: String) -> bool:
	_runtime_bound = configure_preview(world, scene_id, .55, .18)
	return _runtime_bound

func refresh_preview(player: Player, delta: float, force: bool = false) -> bool:
	if not _runtime_bound:
		_clear_fade(player, "RUNTIME_NOT_CONFIGURED")
		return false
	var previous: Player = _fade_player.get_ref() as Player if _fade_player != null else null
	var elapsed: float = delta
	if _fade_player != null and previous != player:
		# Clear BOTH previous/current ghosts and restore base Colors/signature,
		# without discarding the already registered props or native depth entries.
		_clear_fade(player, "RUNTIME_PLAYER_REPLACED")
		_fade_last_ticks = Time.get_ticks_usec()
		elapsed = 0.0
	return super.refresh_preview(player, elapsed, force)

func get_fade_runtime_state() -> Dictionary:
	var state: Dictionary = super.get_fade_preview_state()
	state.preview_only = false
	state.production_hooked = _runtime_bound and not _fade_scene.is_empty()
	state.runtime_hooked = state.production_hooked
	state.scope = "VALIDATED_LUOYANG_ENCLOSURE_ONLY"
	if state.status == "READY_PREVIEW_ONLY": state.status = "READY_ENCLOSURE_RUNTIME"
	return state

func release() -> void:
	# Value-only receipt for a real Field teardown. Local weak refs are discarded
	# on return; the public receipt retains no node, texture, Image or callable.
	var pending: Array[Dictionary] = _fade_records.duplicate()
	var before: Dictionary = {}
	for record: Dictionary in pending:
		var node: Sprite2D = record.sprite.get_ref() as Sprite2D
		if is_instance_valid(node): before[node.get_instance_id()] = node.self_modulate
	release_preview()
	_runtime_bound = false
	var restored: Array[Dictionary] = []
	for record: Dictionary in pending:
		var node: Sprite2D = record.sprite.get_ref() as Sprite2D
		if is_instance_valid(node) and before.has(node.get_instance_id()):
			restored.append({"id":record.id,"instance_id":node.get_instance_id(),"base_color":record.base_color,"before_color":before[node.get_instance_id()],"after_color":node.self_modulate})
	_last_release = {"operation":"release","building_count":restored.size(),"restored_buildings":restored}

func get_last_release_state() -> Dictionary:
	return _last_release.duplicate(true)
