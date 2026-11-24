extends SceneTree

var checks := 0
var failed := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_linxi_threshold()
	_check_luoyang_districts()
	_check_open_regions()
	_check_navigation_and_streaming_contract()
	_check_audio_contract()
	await process_frame
	await process_frame
	print("[RegionScenePolish] checks=%d failed=%d" % [checks, failed])
	quit(1 if failed else 0)


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		push_error("[RegionScenePolish] " + label)


func _inside_layout(layout: WalkableMapLayout, point: Vector2) -> bool:
	if layout.walkable_mask_path != "":
		var image := Image.new()
		if image.load(ProjectSettings.globalize_path(layout.walkable_mask_path)) != OK:
			return false
		var sample := Vector2i(
			clampi(roundi(point.x * float(image.get_width() - 1)), 0, image.get_width() - 1),
			clampi(roundi(point.y * float(image.get_height() - 1)), 0, image.get_height() - 1)
		)
		return image.get_pixelv(sample).r > 0.5
	var inside := false
	for region: PackedVector2Array in layout.walkable_regions:
		if region.size() >= 3 and Geometry2D.is_point_in_polygon(point, region):
			inside = true
			break
	if not inside:
		return false
	for blocker: Dictionary in layout.blockers:
		var region: PackedVector2Array = blocker.get("region", PackedVector2Array())
		if region.size() >= 3 and Geometry2D.is_point_in_polygon(point, region):
			return false
		var center: Vector2 = blocker.get("pos", Vector2(-10, -10))
		var size: Vector2 = blocker.get("size", Vector2.ZERO)
		if size.x > 0.0 and size.y > 0.0:
			var rect := Rect2(center - size * 0.5, size)
			if rect.has_point(point):
				return false
	return true


func _check_layout_probes(path: String) -> void:
	var layout := load(path) as WalkableMapLayout
	_check(layout != null, "layout loads: " + path)
	if layout == null:
		return
	for probe: Dictionary in layout.walkable_probes:
		_check(_inside_layout(layout, probe.get("pos", Vector2.ZERO)), "walkable probe is clear: %s/%s" % [path, probe.get("id", "")])
	for probe: Dictionary in layout.blocked_probes:
		_check(not _inside_layout(layout, probe.get("pos", Vector2.ZERO)), "blocked probe stays blocked: %s/%s" % [path, probe.get("id", "")])
	for portal: Dictionary in layout.portals:
		_check(_inside_layout(layout, portal.get("pos", Vector2.ZERO)), "portal foot point is reachable: %s/%s" % [path, portal.get("id", "")])


func _check_linxi_threshold() -> void:
	var layout := load("res://data/maps/linxi_village_scrollmap_layout_v1.tres") as WalkableMapLayout
	var portal: Dictionary = {}
	for candidate: Dictionary in layout.portals:
		if candidate.get("id", "") == "enter_south_scholar_house":
			portal = candidate
	_check(not portal.is_empty(), "Linxi south private-school portal exists")
	_check(_inside_layout(layout, portal.get("pos", Vector2.ZERO)), "Linxi south private-school threshold is walkable")
	_check(float(portal.get("pos", Vector2.ZERO).y) >= 0.38, "Linxi portal trigger reaches the exterior road")


func _check_luoyang_districts() -> void:
	var scene_paths := [
		"res://data/scenes/ch4_s0_luoyang_gate.tres",
		"res://data/scenes/ch4_s1_luoyang_yamen.tres",
		"res://data/scenes/ch4_s2_canal_docks.tres",
		"res://data/scenes/ch4_s3_luoyang_market.tres",
	]
	var backgrounds := {}
	var music := {}
	for path in scene_paths:
		var scene := load(path) as SceneScript
		_check(scene != null, "Luoyang district scene loads: " + path)
		if scene == null:
			continue
		backgrounds[scene.background_path] = true
		music[scene.bgm_path] = true
		_check(ResourceLoader.exists(scene.background_path), "Luoyang district owns a real background: " + scene.display_name)
		_check(ResourceLoader.exists(scene.bgm_path), "Luoyang district owns a real BGM: " + scene.display_name)
		_check(scene.map_layout != null and scene.map_layout.design_size.x >= 2304, "Luoyang district is a multi-screen layout: " + scene.display_name)
		_check_layout_probes(scene.map_layout.resource_path)
	_check(backgrounds.size() == 4, "four Luoyang districts use four distinct backgrounds")
	_check(music.size() == 1 and music.has("res://art/audio/bgm/bgm_linxi_village_v6.wav"), "four Luoyang districts temporarily share the player-approved no-brass baseline")
	var gate := load("res://data/scenes/ch4_s0_luoyang_gate.tres") as SceneScript
	var luoyang_has_gate_depth := not gate.map_layout.actor_fade_zones.is_empty()
	for raw_occluder: Variant in gate.map_layout.occluders:
		var occluder: Dictionary = raw_occluder as Dictionary
		var fade_region: PackedVector2Array = occluder.get("fade_region", PackedVector2Array())
		luoyang_has_gate_depth = luoyang_has_gate_depth or fade_region.size() >= 3
	_check(luoyang_has_gate_depth, "Luoyang gate arch has an authored foreground-occlusion region")
	var board_found := false
	for item: Dictionary in gate.map_layout.interactions:
		if item.get("id", "") == "luoyang_wanted_board":
			board_found = bool(item.get("visual_baked", false)) and String(item.get("baked_feature", "")) != ""
	_check(board_found, "Luoyang case clue is attached to a visible wanted board")


func _check_open_regions() -> void:
	var world := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	var targets := {}
	for portal: Dictionary in world.map_layout.portals:
		targets[String(portal.get("id", ""))] = String(portal.get("target_scene", ""))
	_check(targets.get("luoyang", "") == "ch4_s0_luoyang_gate", "world map enters Luoyang through its city gate")
	_check(targets.get("wudang", "") == "openworld_wudang_gate", "world map enters the actual Wudang forecourt")

	var yanmen := load("res://data/scenes/openworld_yanmen_pass.tres") as SceneScript
	for portal: Dictionary in yanmen.map_layout.portals:
		if portal.get("id", "") == "snow_hidden_cave":
			_check(String(portal.get("require_flag", "")) == "" and String(portal.get("locked_label", "")) == "", "Yanmen cave entrance has no narrative hard lock")
			_check("高危" in String(portal.get("label", "")), "Yanmen cave communicates danger instead of denying entry")
	var guard := load("res://data/enemies/openworld_yanmen_cave_guard.tres") as EnemyDef
	var raider := load("res://data/enemies/openworld_snow_raider.tres") as EnemyDef
	_check(guard.level >= 10 and guard.attack >= 88 and raider.level >= 9 and raider.attack >= 78, "Yanmen cave uses combat difficulty as its soft gate")

	var ferry := load("res://data/scenes/openworld_bailu_ferry.tres") as SceneScript
	_check(ferry.map_layout.design_size.x >= 3072 and ferry.background_path.ends_with("bg_bailu_ferry_gameplay_v2_3072.png"), "Bailu is a unique equal-scale multi-screen ferry")
	var stable_duan := false
	for npc: Dictionary in ferry.npcs:
		if npc.get("npc_id", "") == "duan_changfeng":
			stable_duan = String(npc.get("sprite_path", "")).ends_with("_v2_stable.png")
	_check(stable_duan, "Duan Changfeng uses normalized four-frame standing art")
	_check_layout_probes("res://data/maps/openworld_bailu_ferry_layout.tres")

	var wudang := load("res://data/scenes/openworld_wudang_gate.tres") as SceneScript
	var wudang_has_gate_depth := not wudang.map_layout.actor_fade_zones.is_empty()
	for occluder: Dictionary in wudang.map_layout.occluders:
		var fade_region: PackedVector2Array = occluder.get("fade_region", PackedVector2Array())
		wudang_has_gate_depth = wudang_has_gate_depth or fade_region.size() >= 3
	_check(wudang.map_layout.design_size.x >= 2304 and wudang_has_gate_depth, "Wudang is a constrained multi-screen 2.5D scene with arch depth")
	_check_layout_probes("res://data/maps/openworld_wudang_gate_layout_v1.tres")


func _check_navigation_and_streaming_contract() -> void:
	var world_layout := load("res://data/maps/world_map_jianghu_layout_v11.tres") as WalkableMapLayout
	var open_plain_found := false
	for probe: Dictionary in world_layout.walkable_probes:
		if probe.get("id", "") == "central_plain_center":
			open_plain_found = true
			_check(_inside_layout(world_layout, probe.get("pos", Vector2.ZERO)), "central open-plain witness is walkable")
	_check(open_plain_found, "world-map layout preserves a named open-plain regression witness")
	var field_source := FileAccess.get_file_as_string("res://scripts/field/field_walkable_controller.gd")
	var stream_source := FileAccess.get_file_as_string("res://scripts/field/background_chunk_streamer.gd")
	_check("var use_smoothing := false" in field_source, "long-scene camera no longer compounds movement smoothing")
	_check("_load_all_chunks_now" in stream_source and "OS.has_feature(\"web\")" in stream_source, "web/mobile movement cannot synchronously stream background chunks while walking")
	_check("not bool(captured.get(\"visual_baked\", false))" in field_source, "baked quest objects do not receive generic exclamation substitutes")


func _check_audio_contract() -> void:
	var bgm_paths := [
		"res://art/audio/bgm/bgm_victory_v4_approved.wav",
		"res://art/audio/bgm/bgm_linxi_village_v6.wav",
	]
	for path in bgm_paths:
		_check(ResourceLoader.exists(path), "new clean tonal BGM exists: " + path)
	var victory_source := FileAccess.get_file_as_string("res://scripts/ui/result_victory.gd")
	_check("bgm_victory_v4_approved.wav" in victory_source, "victory page uses the short cue derived from the approved theme")
