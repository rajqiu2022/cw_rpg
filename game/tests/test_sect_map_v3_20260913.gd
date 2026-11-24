extends SceneTree

const SCENE_PATHS := [
	"res://data/scenes/openworld_huashan_forecourt.tres",
	"res://data/scenes/openworld_huashan_sword_terrace.tres",
	"res://data/scenes/openworld_huashan_waterfall_terrace.tres",
	"res://data/scenes/openworld_wudang_gate.tres",
	"res://data/scenes/openworld_wudang_taiji_court.tres",
	"res://data/scenes/openworld_wudang_purple_cloud_court.tres",
]

var checks := 0
var failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_scene_contract()
	_check_gate_fade_contract()
	_check_player_facing_gate_language()
	_check_route_contract()
	_check_world_hd_contract()
	await process_frame
	await process_frame
	print("[SectMapV3] checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error("[SectMapV3] " + label)


func _inside_layout(layout: WalkableMapLayout, point: Vector2) -> bool:
	var inside := false
	for region: PackedVector2Array in layout.walkable_regions:
		if region.size() >= 3 and Geometry2D.is_point_in_polygon(point, region):
			inside = true
			break
	if not inside:
		return false
	for blocker: Dictionary in layout.blockers:
		var polygon: PackedVector2Array = blocker.get("region", PackedVector2Array())
		if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(point, polygon):
			return false
		var center: Vector2 = blocker.get("pos", Vector2(-10, -10))
		var size: Vector2 = blocker.get("size", Vector2.ZERO)
		if size.x > 0.0 and size.y > 0.0 and Rect2(center - size * 0.5, size).has_point(point):
			return false
	return true


func _find_portal(layout: WalkableMapLayout, portal_id: String) -> Dictionary:
	for portal: Dictionary in layout.portals:
		if String(portal.get("id", "")) == portal_id:
			return portal
	return {}


func _check_scene_contract() -> void:
	var backgrounds := {}
	for path: String in SCENE_PATHS:
		var scene := load(path) as SceneScript
		_check(scene != null, "scene loads: " + path)
		if scene == null:
			continue
		backgrounds[scene.background_path] = true
		_check(scene.map_layout != null, "scene owns a walkable layout: " + scene.display_name)
		_check(is_equal_approx(scene.player_visual_scale, 0.70), "actor scale is normalized to 0.70: " + scene.display_name)
		_check(ResourceLoader.exists(scene.background_path), "scene background exists: " + scene.display_name)
		var texture := load(scene.background_path) as Texture2D
		_check(texture != null and texture.get_width() == 3072 and texture.get_height() == 2048, "scene uses native 3072x2048 art: " + scene.display_name)
		if scene.map_layout == null:
			continue
		_check(scene.map_layout.design_size == Vector2i(3072, 2048), "layout matches native 3072x2048 art: " + scene.display_name)
		_check(scene.map_layout.display_at_native_size, "layout is not downscaled: " + scene.display_name)
		for probe: Dictionary in scene.map_layout.walkable_probes:
			_check(_inside_layout(scene.map_layout, probe.get("pos", Vector2.ZERO)), "walkable probe is clear: %s/%s" % [scene.scene_id, probe.get("id", "")])
		for probe: Dictionary in scene.map_layout.blocked_probes:
			_check(not _inside_layout(scene.map_layout, probe.get("pos", Vector2.ZERO)), "blocked probe stays blocked: %s/%s" % [scene.scene_id, probe.get("id", "")])
		for portal: Dictionary in scene.map_layout.portals:
			_check(_inside_layout(scene.map_layout, portal.get("pos", Vector2.ZERO)), "portal is reachable: %s/%s" % [scene.scene_id, portal.get("id", "")])
	_check(backgrounds.size() == SCENE_PATHS.size(), "six sect districts use six distinct backgrounds")


func _check_gate_fade_contract() -> void:
	for scene_path: String in [
		"res://data/scenes/openworld_huashan_forecourt.tres",
		"res://data/scenes/openworld_wudang_gate.tres",
		"res://data/scenes/ch2_s4_lingyue_gate.tres",
		"res://data/scenes/ch4_s0_luoyang_gate.tres",
	]:
		var scene := load(scene_path) as SceneScript
		var fade_entries: Array[Dictionary] = []
		if scene != null:
			fade_entries.assign(scene.map_layout.actor_fade_zones)
			for occluder: Dictionary in scene.map_layout.occluders:
				if String(occluder.get("depth_mode", "overlap")) == "overlap":
					fade_entries.append({
						"region": occluder.get("fade_region", PackedVector2Array()),
						"cover_polygon": occluder.get("cover_polygon", PackedVector2Array()),
						"actor_faded_alpha": occluder.get("actor_faded_alpha", 1.0),
					})
		_check(scene != null and not fade_entries.is_empty(), "traversable gate owns an actor-fade region: " + scene_path)
		if scene == null or fade_entries.is_empty():
			continue
		var under_gate := Vector2(-1, -1)
		for probe: Dictionary in scene.map_layout.walkable_probes:
			if String(probe.get("id", "")) in ["under_gate", "arch_threshold"]:
				under_gate = probe.get("pos", Vector2(-1, -1))
		var covered := false
		for zone: Dictionary in fade_entries:
			var region: PackedVector2Array = zone.get("region", PackedVector2Array())
			covered = covered or (region.size() >= 3 and Geometry2D.is_point_in_polygon(under_gate, region))
			_check(float(zone.get("actor_faded_alpha", 1.0)) <= 0.45, "gate fade is visibly semi-transparent: " + scene.display_name)
		_check(covered, "gate crossing witness lies inside fade region: " + scene.display_name)
		for probe: Dictionary in scene.map_layout.walkable_probes:
			if String(probe.get("id", "")) == "lower_stairs_no_fade":
				var lower_stairs: Vector2 = probe.get("pos", Vector2(-1, -1))
				var lower_stairs_faded := false
				for zone: Dictionary in fade_entries:
					var zone_region: PackedVector2Array = zone.get("region", PackedVector2Array())
					lower_stairs_faded = lower_stairs_faded or (zone_region.size() >= 3 and Geometry2D.is_point_in_polygon(lower_stairs, zone_region))
				_check(not lower_stairs_faded, "open stairs remain fully opaque: " + scene.display_name)
		if scene.scene_id == &"openworld_wudang_gate":
			var owns_real_foreground := false
			for zone: Dictionary in fade_entries:
				var cover: PackedVector2Array = zone.get("cover_polygon", PackedVector2Array())
				owns_real_foreground = owns_real_foreground or cover.size() >= 3
			_check(owns_real_foreground, "Wudang gate uses a sampled foreground, not actor alpha alone")

	for scene_path: String in [
		"res://data/scenes/openworld_wudang_taiji_court.tres",
		"res://data/scenes/openworld_wudang_purple_cloud_court.tres",
	]:
		var scene := load(scene_path) as SceneScript
		var depth_sorted := 0
		for occluder: Dictionary in scene.map_layout.occluders:
			if String(occluder.get("depth_mode", "")) == "y_sort" and float(occluder.get("depth_y", 0.0)) > 0.0:
				depth_sorted += 1
		_check(depth_sorted >= 4, "Wudang court owns foot-Y foreground props: " + scene.display_name)


func _check_player_facing_gate_language() -> void:
	var dialog := load("res://data/dialogs/openworld_wudang_gate_disciple.tres") as DialogScript
	_check(dialog != null and not dialog.nodes.is_empty(), "Wudang gate dialogue loads")
	if dialog == null or dialog.nodes.is_empty():
		return
	var text := String(dialog.nodes[0].text)
	for leaked_term: String in ["开放", "触发", "剧情", "选择武当"]:
		_check(not text.contains(leaked_term), "Wudang gate dialogue hides design term: " + leaked_term)
	_check(text.contains("考校") and text.contains("叩山门"), "Wudang gate dialogue states in-world admission conditions")


func _check_route_contract() -> void:
	var huashan_gate := load("res://data/scenes/openworld_huashan_forecourt.tres") as SceneScript
	var huashan_mid := load("res://data/scenes/openworld_huashan_sword_terrace.tres") as SceneScript
	var huashan_top := load("res://data/scenes/openworld_huashan_waterfall_terrace.tres") as SceneScript
	var wudang_gate := load("res://data/scenes/openworld_wudang_gate.tres") as SceneScript
	var wudang_mid := load("res://data/scenes/openworld_wudang_taiji_court.tres") as SceneScript
	var wudang_top := load("res://data/scenes/openworld_wudang_purple_cloud_court.tres") as SceneScript
	_check(String(_find_portal(huashan_gate.map_layout, "huashan_to_sword_terrace").get("target_scene", "")) == "openworld_huashan_sword_terrace", "Huashan gate leads to sword terrace")
	_check(String(_find_portal(huashan_mid.map_layout, "to_huashan_waterfall").get("target_scene", "")) == "openworld_huashan_waterfall_terrace", "Huashan sword terrace leads to waterfall terrace")
	_check(String(_find_portal(huashan_top.map_layout, "return_huashan_sword_terrace").get("target_scene", "")) == "openworld_huashan_sword_terrace", "Huashan top route returns to sword terrace")
	_check(String(_find_portal(wudang_gate.map_layout, "to_wudang_taiji_court").get("target_scene", "")) == "openworld_wudang_taiji_court", "Wudang gate leads to Taiji court")
	_check(String(_find_portal(wudang_mid.map_layout, "to_wudang_purple_cloud_court").get("target_scene", "")) == "openworld_wudang_purple_cloud_court", "Wudang Taiji court leads to Purple Cloud court")
	_check(String(_find_portal(wudang_top.map_layout, "return_wudang_taiji_court").get("target_scene", "")) == "openworld_wudang_taiji_court", "Wudang top route returns to Taiji court")


func _check_world_hd_contract() -> void:
	var image := Image.new()
	var source_path := ProjectSettings.globalize_path("res://../assets/raw/scene_background/scene_realism_v5/bg_world_map_jianghu_v12_pc_4608.png")
	_check(image.load(source_path) == OK, "v12 high-resolution world-map source loads")
	_check(image.get_width() == 4608 and image.get_height() == 3072, "world-map desktop source keeps a 2x high-resolution working image")
	var world := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	var huashan := _find_portal(world.map_layout, "huashan")
	_check(huashan.get("target_pos", Vector2.ZERO).distance_to(Vector2(0.500, 0.885)) < 0.001, "world map enters Huashan at the new gate road")
