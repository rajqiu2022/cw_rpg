extends SceneTree

## Isolated navigation-state regression. Never opens or writes a user save slot.
## Exercises fresh portal cycles and synthetic v12 navigation snapshots against
## the staging v13 map; production-only free-roam save migration is held pending.

const STAGING := "res://data/scenes/world_map_jianghu_v13_staging.tres"
const PRODUCTION := "res://data/scenes/world_map_jianghu.tres"
const OLD_LAYOUT := "res://data/maps/world_map_jianghu_layout_v12.tres"

var _checks := 0
var _failed := 0
var _pending := 0
var _strict := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var router := root.get_node("SceneRouter")
	var staging := load(STAGING) as SceneScript if ResourceLoader.exists(STAGING) else null
	var old_layout := load(OLD_LAYOUT) as WalkableMapLayout if ResourceLoader.exists(OLD_LAYOUT) else null
	var production := load(PRODUCTION) as SceneScript
	var production_v13 := production != null and production.map_layout != null and production.map_layout.schema_version == 13
	_strict = OS.get_cmdline_user_args().has("--strict-v13") or production_v13
	_require(staging != null and old_layout != null, "staging v13 and old v12 layout both load")
	if staging == null or staging.map_layout == null or old_layout == null:
		_finish()
		return
	var old_portals: Dictionary = {}
	for raw in old_layout.portals:
		var portal: Dictionary = raw
		old_portals[String(portal.get("id", ""))] = portal
	var field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	field.set("_current_scene", staging)
	field.set("_screen_size", Vector2(staging.map_layout.design_size))
	field.set("_world_size", Vector2(staging.map_layout.design_size))
	field.call("_load_walkable_mask", staging.map_layout.walkable_mask_path)
	field.call("_load_walkable_mask_tiles", staging.map_layout.walkable_mask_tiles)
	field.call("_rebuild_walkability_collision_entries", staging.map_layout.blockers, staging.map_layout.visual_objects)
	var original_state: Dictionary = router.get_navigation_state()
	_check(staging.map_layout.portals.size() == 16 and old_portals.size() == 16, "new and old maps each have sixteen named gateways")
	for raw in staging.map_layout.portals:
		var portal: Dictionary = raw
		var id := String(portal.get("id", ""))
		_check(old_portals.has(id), "legacy gateway ID retained: " + id)
		if not old_portals.has(id):
			continue
		var old_portal: Dictionary = old_portals[id]
		var target := StringName(portal.get("target_scene", ""))
		var new_foot: Vector2 = portal.get("pos", Vector2(-1, -1))
		var old_foot: Vector2 = old_portal.get("pos", Vector2(-1, -1))
		var target_foot: Vector2 = portal.get("target_pos", Vector2(0.5, 0.8))
		var reviewed := not bool(portal.get("staging_pending_asset", false))

		# New game: enter the region from v13, then use its in-game world return.
		router.reset_for_new_game()
		var entered: Vector2 = router.resolve_portal_arrival(StringName(staging.scene_id), target, new_foot, target_foot)
		_check(entered.distance_to(target_foot) < 0.0001, "new-game entry keeps authored regional spawn: " + id)
		var returned: Vector2 = router.resolve_portal_arrival(target, StringName(staging.scene_id), target_foot, old_foot)
		_require(reviewed and returned.distance_to(new_foot) < 0.0001, "new-game return uses v13 gateway: " + id)

		# Old game: a persisted v12 paired return must not pull a player to its
		# former normalized coordinate once v13 is active.
		var packed_old := [old_foot.x, old_foot.y]
		var packed_target := [target_foot.x, target_foot.y]
		var legacy_returns := {"%s->world_map_jianghu" % String(target): packed_old}
		router.restore_navigation_state({
			"current_field": String(target),
			"current_field_spawn": packed_target,
			"portal_return_spawns": legacy_returns,
		})
		var legacy_return: Vector2 = router.resolve_portal_arrival(target, StringName(staging.scene_id), target_foot, old_foot)
		_require(reviewed and legacy_return.distance_to(new_foot) < 0.0001, "legacy v12 paired return migrates to v13 gateway: " + id)
		if reviewed:
			_check(field.call("_spawn_has_foot_clearance", staging, returned), "new-game returned foot avoids sea, roof and wall: " + id)
			_check(field.call("_spawn_has_foot_clearance", staging, legacy_return), "old-game returned foot avoids sea, roof and wall: " + id)

		# Explicit in-memory v12 -> v13 save upgrade, including both directions
		# of the persisted paired route. No call uses a real save slot.
		var old_navigation := {
			"current_field": "world_map_jianghu",
			"current_field_spawn": packed_old,
			"portal_return_spawns": {
				"%s->world_map_jianghu" % String(target): packed_old,
				"world_map_jianghu->%s" % String(target): packed_target,
			},
		}
		router.restore_navigation_state(old_navigation)
		var unchanged: Dictionary = router.get_navigation_state()
		_check(router.get_current_field_id() == &"world_map_jianghu", "default restore retains official v12 field: " + id)
		_check((router.get_current_field_spawn() as Vector2).distance_to(old_foot) < 0.0001, "default restore retains old v12 foot: " + id)
		_check((unchanged.get("portal_return_spawns", {}) as Dictionary).has("%s->world_map_jianghu" % String(target)), "default restore retains v12 paired key: " + id)
		router.restore_navigation_state(old_navigation, &"", StringName(staging.scene_id))
		var upgraded: Dictionary = router.get_navigation_state()
		var upgrade_foot: Vector2 = router.get_current_field_spawn()
		_check(router.get_current_field_id() == StringName(staging.scene_id), "explicit upgrade changes old current_field to v13: " + id)
		_check(upgrade_foot.distance_to(new_foot) < 0.0001, "explicit upgrade maps old player position to matching v13 gateway: " + id)
		_require(reviewed and field.call("_spawn_has_foot_clearance", staging, upgrade_foot), "upgraded old player foot avoids sea, roof and wall: " + id)
		var upgraded_returns: Dictionary = upgraded.get("portal_return_spawns", {})
		var inbound_key := "%s->%s" % [String(target), String(staging.scene_id)]
		var outbound_key := "%s->%s" % [String(staging.scene_id), String(target)]
		_check(upgraded_returns.has(inbound_key) and upgraded_returns.has(outbound_key), "explicit upgrade rewrites both paired return keys: " + id)
		if upgraded_returns.has(inbound_key) and upgraded_returns.has(outbound_key):
			var migrated_inbound: Array = upgraded_returns[inbound_key]
			var preserved_outbound: Array = upgraded_returns[outbound_key]
			_check(Vector2(float(migrated_inbound[0]), float(migrated_inbound[1])).distance_to(new_foot) < 0.0001, "old world-side remembered foot migrates to matching v13 gateway: " + id)
			_check(Vector2(float(preserved_outbound[0]), float(preserved_outbound[1])).distance_to(target_foot) < 0.0001, "region-side remembered foot remains unchanged: " + id)

	# Samples away from portals, including former sea/city-risk coordinates:
	# the upgrade must choose one named old region and land at its reviewed
	# corresponding safe gateway rather than keep a normalized v12 pixel.
	for old_free_foot in [Vector2(0.50, 0.50), Vector2(0.78, 0.34), Vector2(0.94, 0.54), Vector2(0.63, 0.92)]:
		var expected_id := _nearest_old_gateway_id(old_portals, old_free_foot)
		var expected_new := _portal_by_id(staging.map_layout.portals, expected_id)
		router.restore_navigation_state({
			"current_field": "world_map_jianghu",
			"current_field_spawn": [old_free_foot.x, old_free_foot.y],
			"portal_return_spawns": {},
		}, &"", StringName(staging.scene_id))
		var migrated_free: Vector2 = router.get_current_field_spawn()
		_check(migrated_free.distance_to(expected_new.get("pos", Vector2(-1, -1))) < 0.0001, "old free-roam coordinate maps by named regional gateway: " + expected_id)
		_require(not bool(expected_new.get("staging_pending_asset", false)) and field.call("_spawn_has_foot_clearance", staging, migrated_free), "old free-roam coordinate lands on safe v13 foot: " + expected_id)

	router.restore_navigation_state(original_state)
	field.free()
	if production_v13:
		_pending_note("production v12 current_field_spawn migration needs live SaveManager/Field round trip before final acceptance")
	else:
		_pending_note("production still runs v12; old current_field=world_map_jianghu free-roam position migration not yet testable")
	_finish()


func _nearest_old_gateway_id(portals: Dictionary, point: Vector2) -> String:
	var found := ""
	var best := INF
	for id in portals.keys():
		var portal: Dictionary = portals[id]
		var position: Vector2 = portal.get("pos", Vector2.ZERO)
		var distance := point.distance_squared_to(position)
		if distance < best:
			found = String(id)
			best = distance
	return found


func _portal_by_id(portals: Array, id: String) -> Dictionary:
	for raw in portals:
		if raw is Dictionary and String((raw as Dictionary).get("id", "")) == id:
			return raw as Dictionary
	return {}


func _pending_note(message: String) -> void:
	_pending += 1
	print("[PENDING] " + message)


func _require(ok: bool, message: String) -> void:
	if ok:
		_check(true, message)
	elif _strict:
		_check(false, message)
	else:
		_pending_note(message)


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("[PASS] " + message)
	else:
		_failed += 1
		push_error("[FAIL] " + message)


func _finish() -> void:
	print("[WorldMapV13SaveReturn] checks=%d failed=%d pending=%d" % [_checks, _failed, _pending])
	quit(1 if _failed > 0 else 0)
