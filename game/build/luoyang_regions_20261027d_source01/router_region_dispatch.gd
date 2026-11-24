extends RefCounted
## Explicit physical-region / logical-save split. No legacy owner impersonation.
const Entry = preload("res://build/luoyang_regions_20261027d_source01/region_entry.gd")
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const FIELD_SCRIPT = "res://build/luoyang_regions_20261027d_source01/region_field.gd"
static var _navigation: Dictionary = {}
static var _returns: Dictionary = {}

static func author_sha(router: Node) -> String:
	return String(router.get_script().get_script_constant_map().get("REGION27D_AUTHOR_SHA", ""))

static func enabled(router: Node, id: StringName) -> bool:
	return router.get_script().get_script_constant_map().get("REGION27D_ENABLED") == true and Entry.requested(id)

static func current_field(router: Node) -> Node:
	var field: Node = router.get_tree().current_scene
	return field if is_instance_valid(field) and field.get_script() != null and field.get_script().resource_path == FIELD_SCRIPT else null

static func start(router: Node, id: StringName, uv: Variant, action: String, local_version: int, extension: Dictionary = {}) -> bool:
	if not enabled(router, id): return false
	if LoadingManager._transition_active or LoadingManager._external_active: return false
	var selected: Variant = uv
	var saved: Dictionary = extension.duplicate(true)
	if selected == null and id == router.get("_current_field_id"):
		selected = router.get("_current_field_spawn")
		if saved.is_empty(): saved = _navigation.duplicate(true)
	var version: int = local_version if local_version >= 0 else int(router.get("_local_layout_versions").get(String(id), -1))
	var prepared: Dictionary = Entry.prepare(id, selected, version, saved, author_sha(router))
	if prepared.get("ok") != true: push_error("[Region27d Router] " + String(prepared.get("error", "ENTRY_REFUSED"))); return false
	return _launch(router, prepared, action)

static func _launch(router: Node, prepared: Dictionary, action: String) -> bool:
	var id: StringName = StringName(prepared.logical_id)
	var payload: Dictionary = {"scene_id": prepared.region_id, "logical_scene_id": String(id), "region27d_request_serial": prepared.request_serial, "player_spawn": prepared.world_uv}
	if not action.is_empty(): payload.pending_action = action
	router.set("_field_payload", payload)
	router.set("_current_field_id", id)
	router.set("_current_field_spawn", prepared.legacy_uv)
	var versions: Dictionary = router.get("_local_layout_versions").duplicate(true)
	versions[String(id)] = prepared.local_layout_version; router.set("_local_layout_versions", versions)
	AudioManager.stop_dialog_audio()
	router.call("_transition_to", prepared.field_scene, &"field", {"title": "洛阳街区", "field_scene_id": prepared.region_id, "field_spawn": prepared.world_uv})
	return true

static func commit(router: Node, navigation: Dictionary) -> bool:
	var field: Node = current_field(router)
	if field == null or navigation.get("ok") != true or not navigation.get("region27d") is Dictionary: return false
	var owner: RefCounted = field.call("region_session_handle")
	var scene: SceneScript = field.call("region_physical_scene") as SceneScript
	if owner == null or not owner.matches(field, scene) or owner.receipt().get("finalized") != true: return false
	var compiled: Dictionary = field.get("_region")
	var foot: Vector2 = Core.vec(navigation.region27d.get("global_foot_px"))
	var id: String = Core.district_at(compiled, foot)
	if id.is_empty() or navigation.current_field != id or navigation.region27d.region_id != compiled.id or navigation.region27d.revision != compiled.revision or not owner.safe_foot(field, scene, foot): return false
	router.set("_current_field_id", StringName(id)); router.set("_current_field_spawn", navigation.current_field_spawn)
	var versions: Dictionary = router.get("_local_layout_versions").duplicate(true)
	versions[id] = navigation.local_layout_version; router.set("_local_layout_versions", versions)
	_navigation = navigation.region27d.duplicate(true)
	return true

static func exit_region(router: Node, logical: String, door_id: String, target: String, uv: Vector2, legacy_uv: Vector2) -> bool:
	if LoadingManager._transition_active or LoadingManager._external_active: return false
	var field: Node = current_field(router)
	if field == null or DialogPlayer.is_playing(): return false
	var owner: RefCounted = field.call("region_session_handle")
	var scene: SceneScript = field.call("region_physical_scene") as SceneScript
	var compiled: Dictionary = field.get("_region")
	if owner == null or not owner.revalidate_boundary(field, scene, compiled): return false
	var doors: Array = compiled.portals.filter(func(row: Dictionary) -> bool: return row.logical_id == logical and row.id == door_id)
	if doors.size() != 1: return false
	var row: Dictionary = doors[0]; var data: Dictionary = row.get("data", row)
	if data.get("target_scene") != target or data.get("target_pos") != uv or row.legacy_source_uv != legacy_uv: return false
	var player: Node2D = field.get("_player") as Node2D
	if player == null or player.position.distance_to(row.foot) > 118.0 or not owner.safe_foot(field, scene, player.position): return false
	if data.get("region27d_target") is Dictionary:
		# This exact immutable portal contract carries a new-region world foot.
		# It never writes that foot into a legacy portal_return_spawns UV slot.
		var authored: Dictionary = Entry.prepare_authored(data.region27d_target, author_sha(router))
		if authored.get("ok") != true: return false
		return _launch(router, authored, "")
	var route: String = target + "->" + logical
	var return_foot: Vector2 = row.get("return_foot", Vector2(INF, INF))
	if not return_foot.is_finite() or not owner.safe_foot(field, scene, return_foot): return false
	var remembered: Dictionary = {"region_id": compiled.id, "revision": compiled.revision, "logical_id": logical, "global_foot_px": [return_foot.x, return_foot.y]}
	if router.LUOYANG_V3.owns_id(StringName(target)) and not enabled(router, StringName(target)):
		# This authenticated door carries its original authored UV. The paired
		# portal route validates/migrates it and commits the reverse UV on success.
		_leave_for_city(router, StringName(target), uv, legacy_uv, route, remembered)
		return router.get("_portal_preparing") == true or router.get_current_field_id() == StringName(target)
	var before: Dictionary = _returns.duplicate(true)
	_returns[route] = remembered
	var returns: Dictionary = router.get("_portal_return_spawns").duplicate(true)
	var previous_returns: Dictionary = returns.duplicate(true)
	returns[route] = legacy_uv; router.set("_portal_return_spawns", returns)
	if not router.call("go_field_smart", StringName(target), uv):
		_returns = before; router.set("_portal_return_spawns", previous_returns); return false
	_navigation.clear()
	return true

static func _leave_for_city(router: Node, target: StringName, authored: Vector2, legacy_uv: Vector2, route: String, remembered: Dictionary) -> void:
	await router.go_field_from_portal(target, authored, legacy_uv)
	if router.get_current_field_id() == target and router.get("_portal_return_spawns").get(route) == legacy_uv:
		_returns[route] = remembered
		_navigation.clear()

static func enter_from_legacy(router: Node, target: StringName, authored: Variant, source_uv: Variant, action: String) -> bool:
	# This path is only called after an explicit enabled alias match. Failures do
	# not fall back to old city identity or private exit activation.
	var field: Node = router.get_tree().current_scene
	if not is_instance_valid(field) or field.get_script().resource_path != "res://scripts/field/field_walkable_controller.gd" or field.get("_field_loading_complete") != true or field.get("_field_loading_failed") == true: return false
	var source: SceneScript = field.get("_current_scene") as SceneScript
	if source == null or not source_uv is Vector2 or not authored is Vector2: return false
	var matches: Array = []
	for exit: ExitZone in field.get("_exit_nodes"):
		if is_instance_valid(exit) and exit.target_scene_id == String(target) and exit.target_spawn_pos == authored and not exit.is_locked and exit.action.is_empty():
			# Original Field binds d.source_spawn_pos (an authored approach), not
			# necessarily the activation area's d.pos. Authenticate that real binding.
			if _bound_source_spawn(exit, field, source_uv): matches.append(exit)
	if matches.size() != 1: return false
	if field.call("_spawn_has_foot_clearance", source, source_uv) != true: return false
	var route: String = String(source.scene_id) + "->" + String(target)
	return start(router, target, authored, action, 3, _returns.get(route, {}))

static func _bound_source_spawn(zone: ExitZone, field: Node, spawn: Vector2) -> bool:
	if not spawn.is_finite() or spawn.x < 0 or spawn.y < 0 or spawn.x > 1 or spawn.y > 1 or zone.get_parent() != field.get("_portal_layer"): return false
	var count: int = 0
	for connection: Dictionary in zone.exit_triggered.get_connections():
		var callable: Callable = connection.get("callable", Callable())
		if callable.get_object() != field or callable.get_method() != &"_on_exit_triggered": continue
		var arguments: Array = callable.get_bound_arguments()
		if arguments.size() != 1 or not arguments[0] is Vector2 or arguments[0] != spawn: return false
		count += 1
	return count == 1

static func state() -> Dictionary:
	return {"region27d": _navigation.duplicate(true), "region27d_returns": _returns.duplicate(true)}

static func resume_modal(router: Node, action: String) -> bool:
	var id: StringName = router.get("_current_field_id")
	if not enabled(router, id) or _navigation.get("logical_id") != String(id): return false
	return start(router, id, router.get("_current_field_spawn"), action, int(router.get("_local_layout_versions").get(String(id), -1)), _navigation)

static func capture_modal(router: Node, kind: StringName) -> bool:
	var field: Node = current_field(router)
	if field == null or kind != &"battle_enter": return true
	field.call("_publish_region_navigation")
	if field.get("_field_loading_failed") == true or _navigation.is_empty(): return false
	var battle: Dictionary = router.get("_battle_payload").duplicate(true)
	var physical: String = String(field.get("_region").id)
	var logical: String = String(router.get("_current_field_id"))
	if String(battle.get("return_scene", "")) not in [physical, logical]: return false
	battle.return_scene = StringName(logical)
	battle.return_spawn = router.get("_current_field_spawn")
	battle["return_region27d"] = _navigation.duplicate(true)
	router.set("_battle_payload", battle)
	return true

static func resume_battle(router: Node, payload: Dictionary, action: String) -> bool:
	var battle: Dictionary = router.get("_battle_payload")
	var id: StringName = StringName(payload.get("return_scene", ""))
	if not enabled(router, id) or String(battle.get("return_scene", "")) != String(id): return false
	var extension: Dictionary = payload.get("return_region27d", battle.get("return_region27d", {}))
	if extension.is_empty() or extension.get("logical_id") != String(id): return false
	return start(router, id, payload.get("return_spawn"), action, int(payload.get("return_local_layout_version", 3)), extension)

static func restore(data: Dictionary) -> void:
	_navigation = data.get("region27d", {}).duplicate(true)
	_returns = data.get("region27d_returns", {}).duplicate(true)

static func reset() -> void:
	_navigation.clear(); _returns.clear(); Entry.abort_pending()

static func preflight(router: Node, data: Dictionary, fallback: StringName, versions: Dictionary, city_contract: Variant) -> Dictionary:
	var legacy: Dictionary = data.duplicate(true)
	var logical: String = String(data.get("current_field", fallback))
	var scoped_versions: Dictionary = versions.duplicate(true)
	var local_versions: Dictionary = data.get("local_layout_versions", {}).duplicate(true)
	var saved_versions: Dictionary = local_versions.duplicate(true)
	for alias: String in Entry.ALIASES:
		scoped_versions.erase(alias); local_versions.erase(alias)
	legacy.local_layout_versions = local_versions
	if Entry.requested(StringName(logical)): legacy.current_field = ""
	var returns: Dictionary = data.get("portal_return_spawns", {}).duplicate(true)
	var regional_returns: Dictionary = {}
	for key: String in returns.keys():
		var parts: PackedStringArray = key.split("->")
		if parts.size() == 2 and Entry.requested(StringName(parts[1])):
			regional_returns[key] = returns[key]; returns.erase(key)
	legacy.portal_return_spawns = returns
	var result: Dictionary = city_contract.prepare_navigation(legacy, &"", scoped_versions)
	if result.is_empty(): return {}
	var checks: Array = []
	if Entry.requested(StringName(logical)): checks.append({"id": logical, "uv": data.get("current_field_spawn"), "ext": data.get("region27d", {})})
	for key: String in regional_returns:
		checks.append({"id": key.split("->")[1], "uv": regional_returns[key], "ext": data.get("region27d_returns", {}).get(key, {})})
	for check: Dictionary in checks:
		var uv: Vector2 = Core.vec(check.uv)
		var prepared: Dictionary = Entry.prepare(StringName(check.id), uv, int(saved_versions.get(check.id, 1)), check.ext, author_sha(router))
		Entry.abort_pending()
		if prepared.get("ok") != true: return {}
	result.current_field = logical
	if Entry.requested(StringName(logical)): result.current_field_spawn = data.get("current_field_spawn")
	result.portal_return_spawns.merge(regional_returns, true)
	for alias: String in Entry.ALIASES:
		if saved_versions.has(alias): result.local_layout_versions[alias] = saved_versions[alias]
	result.merge({"region27d": data.get("region27d", {}).duplicate(true), "region27d_returns": data.get("region27d_returns", {}).duplicate(true)}, true)
	return result
