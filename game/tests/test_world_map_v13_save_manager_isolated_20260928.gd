extends SceneTree

## Exercises SaveManager's real JSON path with a test-only subclass whose
## slot_path is confined to a unique user://qa_world_v13_* directory. Never
## opens the player's normal save_0..save_4.json files.

const STAGING := "res://data/scenes/world_map_jianghu_v13_staging.tres"
const OLD_LAYOUT := "res://data/maps/world_map_jianghu_layout_v12.tres"
const ISOLATED_MANAGER := "res://tests/isolated_permanent_resource_save_20260910.gd"

var _checks := 0
var _failed := 0
var _test_dir := ""
var _manager: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var staging := load(STAGING) as SceneScript
	var old_layout := load(OLD_LAYOUT) as WalkableMapLayout
	_check(staging != null and old_layout != null and staging.map_layout != null, "staging and legacy maps load")
	if staging == null or old_layout == null or staging.map_layout == null:
		_finish()
		return
	var router := root.get_node("SceneRouter")
	var prior_navigation: Dictionary = router.get_navigation_state()
	var old_portals: Dictionary = {}
	for raw in old_layout.portals:
		var portal: Dictionary = raw
		old_portals[String(portal.get("id", ""))] = portal
	_test_dir = "user://qa_world_v13_%d" % Time.get_ticks_usec()
	var absolute_dir := ProjectSettings.globalize_path(_test_dir).simplify_path()
	var user_root := ProjectSettings.globalize_path("user://").simplify_path()
	_check(absolute_dir.begins_with(user_root + "/") and absolute_dir != user_root, "temporary save directory stays beneath user root")
	if _failed > 0:
		_finish()
		return
	_check(DirAccess.make_dir_recursive_absolute(absolute_dir) == OK, "unique QA save directory created")
	_manager = load(ISOLATED_MANAGER).new()
	_manager.set("isolated_dir", _test_dir)
	root.add_child(_manager)
	var qa_slot_path := String(_manager.call("slot_path", 0))
	_check(qa_slot_path.begins_with(_test_dir + "/") and qa_slot_path != "user://save_0.json", "isolated SaveManager overrides player slot path")
	if _failed > 0:
		_cleanup()
		router.restore_navigation_state(prior_navigation)
		_finish()
		return
	var field: Node = load("res://scripts/field/field_walkable_controller.gd").new()
	field.set("_current_scene", staging)
	field.set("_screen_size", Vector2(staging.map_layout.design_size))
	field.set("_world_size", Vector2(staging.map_layout.design_size))
	field.call("_load_walkable_mask", staging.map_layout.walkable_mask_path)
	field.call("_load_walkable_mask_tiles", staging.map_layout.walkable_mask_tiles)
	field.call("_rebuild_walkability_collision_entries", staging.map_layout.blockers, staging.map_layout.visual_objects)
	for raw in staging.map_layout.portals:
		var portal: Dictionary = raw
		var id := String(portal.get("id", ""))
		_check(old_portals.has(id), "legacy portal exists for actual save: " + id)
		if not old_portals.has(id):
			continue
		var old_foot: Vector2 = (old_portals[id] as Dictionary).get("pos", Vector2.ZERO)
		var new_foot: Vector2 = portal.get("pos", Vector2.ZERO)
		var target := String(portal.get("target_scene", ""))
		router.restore_navigation_state({
			"current_field": "world_map_jianghu",
			"current_field_spawn": [old_foot.x, old_foot.y],
			"portal_return_spawns": {"%s->world_map_jianghu" % target: [old_foot.x, old_foot.y]},
		})
		_check(_manager.call("save_to_slot", 0), "v12 navigation writes isolated JSON: " + id)
		_check(_manager.call("get_save_field_id", 0) == &"world_map_jianghu", "default save preview keeps v12: " + id)
		_check(_manager.call("get_save_field_id", 0, router.WORLD_MAP_STAGING_SCENE) == StringName(staging.scene_id), "opt-in save preview resolves v13: " + id)
		_check(_manager.call("load_from_slot", 0), "default actual JSON load succeeds: " + id)
		_check(router.get_current_field_id() == &"world_map_jianghu" and router.get_current_field_spawn().distance_to(old_foot) < 0.0001, "default actual JSON load retains v12 location: " + id)
		_check(_manager.call("load_from_slot", 0, router.WORLD_MAP_STAGING_SCENE), "opt-in actual JSON load succeeds: " + id)
		_check(router.get_current_field_id() == StringName(staging.scene_id) and router.get_current_field_spawn().distance_to(new_foot) < 0.0001, "opt-in actual JSON maps matching v13 portal: " + id)
		_check(field.call("_spawn_has_foot_clearance", staging, router.get_current_field_spawn()), "actual JSON migrated portal avoids wall/water: " + id)
		var remembered: Dictionary = router.get_navigation_state().get("portal_return_spawns", {})
		var return_key := "%s->%s" % [target, String(staging.scene_id)]
		_check(remembered.has(return_key), "actual JSON rewrites paired return key: " + id)
		if remembered.has(return_key):
			var pair: Array = remembered[return_key]
			_check(Vector2(float(pair[0]), float(pair[1])).distance_to(new_foot) < 0.0001, "actual JSON rewrites paired return foot: " + id)
	for old_free in [Vector2(0.50, 0.50), Vector2(0.78, 0.34), Vector2(0.94, 0.54), Vector2(0.63, 0.92)]:
		router.restore_navigation_state({
			"current_field": "world_map_jianghu",
			"current_field_spawn": [old_free.x, old_free.y],
			"portal_return_spawns": {},
		})
		_check(_manager.call("save_to_slot", 0), "free-roam v12 JSON writes to isolated slot: " + str(old_free))
		_check(_manager.call("load_from_slot", 0, router.WORLD_MAP_STAGING_SCENE), "free-roam opt-in JSON load succeeds: " + str(old_free))
		_check(router.get_current_field_id() == StringName(staging.scene_id) and field.call("_spawn_has_foot_clearance", staging, router.get_current_field_spawn()), "free-roam JSON migrates to safe v13 land: " + str(old_free))
	field.free()
	router.restore_navigation_state(prior_navigation)
	_cleanup()
	_finish()


func _cleanup() -> void:
	if _manager != null:
		_manager.queue_free()
	var absolute_dir := ProjectSettings.globalize_path(_test_dir).simplify_path()
	var user_root := ProjectSettings.globalize_path("user://").simplify_path()
	if _test_dir.is_empty() or not absolute_dir.begins_with(user_root + "/"):
		return
	for filename in ["save_0.json", "save_0.json.bak", "save_0.json.tmp"]:
		var path := absolute_dir.path_join(filename)
		if FileAccess.file_exists(path):
			_check(DirAccess.remove_absolute(path) == OK, "remove only QA-created file: " + filename)
	_check(DirAccess.remove_absolute(absolute_dir) == OK, "remove only unique QA-created directory")


func _check(ok: bool, message: String) -> void:
	_checks += 1
	if ok:
		print("[PASS] " + message)
	else:
		_failed += 1
		push_error("[FAIL] " + message)


func _finish() -> void:
	print("[WorldMapV13ActualSave] checks=%d failed=%d" % [_checks, _failed])
	quit(1 if _failed > 0 else 0)
