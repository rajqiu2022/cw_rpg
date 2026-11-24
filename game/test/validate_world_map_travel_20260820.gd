extends SceneTree

const SAFE_SETTLEMENTS := [
	"linxi_tutorial", "linxi_village_center", "linxi_village_scrollmap",
	"ch1_s0_linxi_main_walkable", "ch1_s2_qingfeng", "ch2_s1_zhuwei_market",
	"ch2_s4_lingyue_gate", "ch3_s1_wulin_assembly", "ch4_s1_luoyang_yamen",
	"ch4_s3_luoyang_market",
]
const INTERNAL_SCENE_PORTALS := [&"north_forest", &"zhuwei_cave", &"zhuwei_forest", &"west_ruin", &"river_camp", &"canal", &"temple_tunnel"]

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var world := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	_check(world != null, "world map scene loads")
	if world != null:
		_check(world.background_path == "res://art/backgrounds/region_masters_v2/bg_world_map_jianghu_v11_2304.png", "world map uses the route-synchronized v11 realistic background")
		_check(world.map_layout != null and world.map_layout.walkable_mask_path == "res://art/navigation_masks/world_map_jianghu_walk_v11.png", "world map walking uses the v11 shared-source route mask")
		_check(ResourceLoader.exists(world.background_path), "new world map background exists")
		var actual_design_size := Vector2i.ZERO if world.map_layout == null else world.map_layout.design_size
		_check(actual_design_size == Vector2i(2304, 1536), "world map is an optimized large scrolling 2304x1536 stage (actual=%s)" % actual_design_size)
		_check(world.player_visual_scale < 1.0, "world map uses travel-scale actor")
		var portal_ids: Dictionary = {}
		if world.map_layout != null:
			for raw: Dictionary in world.map_layout.portals:
				portal_ids[StringName(raw.get("id", ""))] = raw
			for portal_id: StringName in INTERNAL_SCENE_PORTALS:
				_check(not portal_ids.has(portal_id), "%s stays inside its owning settlement route" % portal_id)

	for scene_id: String in SAFE_SETTLEMENTS:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		_check(scene != null, "%s settlement loads" % scene_id)
		if scene == null:
			continue
		_check(scene.is_settlement, "%s is explicitly marked as a safe settlement" % scene_id)
		_check(scene.encounter_enemy_ids.is_empty() and scene.encounter_groups.is_empty(), "%s has no random encounter roster" % scene_id)
		_check(scene.encounter_step_distance <= 0.0 and scene.encounter_chance <= 0.0, "%s has no random encounter trigger" % scene_id)

	_check(_layout_has_world_exit("res://data/maps/linxi_village_scrollmap_layout_v1.tres", &"linxi_to_world_map"), "Linxi city edge reaches the world map")
	_check(_layout_has_world_exit("res://data/maps/ch1_s2_qingfeng_layout_v2.tres", &"zhuwei_to_world_map"), "Zhuwei city edge reaches the world map")
	for scene_id: String in ["ch2_s4_lingyue_gate", "ch3_s1_wulin_assembly", "ch4_s0_luoyang_gate"]:
		var scene := load("res://data/scenes/%s.tres" % scene_id) as SceneScript
		var has_exit := false
		if scene != null:
			for hotspot: Dictionary in scene.hotspots:
				if String(hotspot.get("action", "")) == "world_map":
					has_exit = true
					break
			if not has_exit and scene.map_layout != null:
				for portal: Dictionary in scene.map_layout.portals:
					if String(portal.get("action", "")) == "world_map" or String(portal.get("target_scene", "")) == "world_map_jianghu":
						has_exit = true
						break
		_check(has_exit, "%s has a city-edge world map exit" % scene_id)

	var controller_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	_check(controller_source.contains("_current_scene.is_settlement"), "runtime blocks random encounters in settlements")
	_finish()


func _layout_has_world_exit(path: String, portal_id: StringName) -> bool:
	var layout := load(path) as WalkableMapLayout
	if layout == null:
		return false
	for portal: Dictionary in layout.portals:
		if StringName(portal.get("id", "")) == portal_id:
			return String(portal.get("target_scene", "")) == "world_map_jianghu"
	return false


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)


func _finish() -> void:
	print("[WorldMapTravel20260820] checks=%d failed=%d" % [checks, failures.size()])
	for failure: String in failures:
		push_error("[WorldMapTravel20260820] %s" % failure)
	quit(1 if not failures.is_empty() else 0)
