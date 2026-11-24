extends SceneTree

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for layout_path in [
		"res://data/maps/openworld_bianzhou_city_layout_v2.tres",
		"res://data/maps/openworld_xiangzhou_city_layout_v2.tres",
		"res://data/maps/openworld_jinling_city_layout_v2.tres",
		"res://data/maps/openworld_bailu_ferry_layout.tres",
	]:
		_validate_mask_contract(layout_path)

	var xiangzhou := load("res://data/maps/openworld_xiangzhou_city_layout_v2.tres") as WalkableMapLayout
	_check(xiangzhou != null and not xiangzhou.occluders.is_empty(), "襄州树冠拥有独立遮挡层")
	if xiangzhou != null and not xiangzhou.occluders.is_empty():
		var tree: Dictionary = xiangzhou.occluders[0]
		_check(String(tree.get("depth_mode", "")) == "overlap", "树冠只在角色进入覆盖区时参与层级")
		_check(float(tree.get("actor_faded_alpha", 1.0)) <= 0.5, "树下角色使用明确半透明剪影")
		_check(ResourceLoader.exists(String(tree.get("alpha_mask_texture_path", ""))), "树冠透明蒙版存在")

	var world := load("res://data/maps/world_map_jianghu_layout_v12.tres") as WalkableMapLayout
	_check(world != null and world.schema_version == 12, "江湖地图v12布局可加载")
	if world != null:
		_check(world.portals.size() == 16, "江湖地图保留16个入口")
		var portal_positions := {}
		for portal: Dictionary in world.portals:
			portal_positions[String(portal.get("id", ""))] = portal.get("pos", Vector2.ZERO)
			_check(bool(portal.get("show_destination_label", false)), "入口常驻显示地名：%s" % portal.get("id", ""))
		for required in ["bianzhou", "xiangzhou", "jinling", "luoyang", "lingyue", "east_sea_port"]:
			_check(portal_positions.has(required), "世界地图入口存在：" + required)
		if portal_positions.has("luoyang") and portal_positions.has("lingyue") and portal_positions.has("east_sea_port"):
			_check(Vector2(portal_positions["luoyang"]).distance_to(Vector2(portal_positions["lingyue"])) > 0.16, "凌月山与洛阳入口已拉开")
			_check(Vector2(portal_positions["luoyang"]).distance_to(Vector2(portal_positions["east_sea_port"])) > 0.10, "东海埠与洛阳入口已拉开")

	var world_scene := load("res://data/scenes/world_map_jianghu.tres") as SceneScript
	_check(world_scene != null and world_scene.background_path.ends_with("bg_world_map_jianghu_v12_2304.png"), "世界地图使用写实v12底图")
	_check(world_scene != null and world_scene.bgm_path.ends_with("bgm_jianghu_journey_v4.wav"), "世界地图使用江湖行旅音乐路由")

	for scene_path in [
		"res://data/scenes/openworld_bianzhou_city.tres",
		"res://data/scenes/openworld_xiangzhou_city.tres",
		"res://data/scenes/openworld_jinling_city.tres",
		"res://data/scenes/openworld_bailu_ferry.tres",
		"res://data/scenes/openworld_wudang_gate.tres",
	]:
		var scene_def := load(scene_path) as SceneScript
		_check(scene_def != null, "场景可加载：" + scene_path)
		if scene_def == null:
			continue
		_check(not scene_def.bgm_path.ends_with("bgm_linxi_village_v6.wav"), "后续场景不再复用被否决的林西临时音乐：" + scene_path)
		for npc: Dictionary in scene_def.npcs:
			var name := String(npc.get("npc_name", ""))
			if name.contains("守") or name.contains("巡") or name.contains("兵") or name.contains("捕"):
				_check(float(npc.get("scale", 1.0)) >= 0.90, "守卫比例不再过小：%s" % name)

	_check(ResourceLoader.exists("res://art/ui/bounty_board/bounty_board_frame_v2.png"), "新版通缉榜美术已接入")
	_check(ResourceLoader.exists("res://art/audio/bgm/bgm_victory_v4_approved.wav"), "胜利短乐句已接入")
	var bounty_scene := load("res://scenes/bounty_board.tscn") as PackedScene
	_check(bounty_scene != null, "新版通缉榜场景可解析")
	if bounty_scene != null:
		var instance := bounty_scene.instantiate()
		root.add_child(instance)
		await process_frame
		_check(instance.get_node_or_null("BountyBoardArt") != null, "通缉榜运行时显示生成的武侠底图")
		instance.queue_free()
		await process_frame

	print("[CityFerryWorldV11Polish] checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)


func _validate_mask_contract(layout_path: String) -> void:
	var layout := load(layout_path) as WalkableMapLayout
	_check(layout != null, "导航布局可加载：" + layout_path)
	if layout == null:
		return
	_check(layout.schema_version >= 5, "导航布局使用精确蒙版版式：" + layout_path)
	_check(not layout.walkable_mask_path.is_empty(), "导航布局声明像素蒙版：" + layout_path)
	var image := Image.new()
	var error := image.load(ProjectSettings.globalize_path(layout.walkable_mask_path))
	_check(error == OK and not image.is_empty(), "导航蒙版可读取：" + layout.walkable_mask_path)
	if error != OK or image.is_empty():
		return
	for probe: Dictionary in layout.walkable_probes:
		_check(_sample_mask(image, probe.get("pos", Vector2.ZERO)) > 0.5, "应可走：%s/%s" % [layout_path, probe.get("id", "")])
	for probe: Dictionary in layout.blocked_probes:
		_check(_sample_mask(image, probe.get("pos", Vector2.ZERO)) < 0.5, "应阻挡：%s/%s" % [layout_path, probe.get("id", "")])


func _sample_mask(image: Image, normalized: Vector2) -> float:
	var x := clampi(roundi(normalized.x * float(image.get_width() - 1)), 0, image.get_width() - 1)
	var y := clampi(roundi(normalized.y * float(image.get_height() - 1)), 0, image.get_height() - 1)
	return image.get_pixel(x, y).r


func _check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("[CityFerryWorldV11Polish] " + description)
