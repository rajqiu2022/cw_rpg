extends SceneTree

var failures := 0


func _initialize() -> void:
	var pack_root := ProjectSettings.globalize_path("res://../../wechat_packs")
	var probes := [
		{
			"pack": "chapter1_start.pck",
			"resource": "res://art/backgrounds/bg_ch1_s1_road_cave_entry_v2.png",
			"label": "chapter-one startup mountain-road background",
		},
		{
			"pack": "chapter1_late.pck",
			"resource": "res://art/backgrounds/bg_zhuwei_main_street_release_v3.png",
			"label": "chapter-one late Zhuwei background",
		},
		{
			"pack": "chapter2.pck",
			"resource": "res://art/backgrounds/bg_ch2_forest_edge_v1.png",
			"label": "chapter two forest background",
		},
		{
			"pack": "chapter3.pck",
			"resource": "res://art/backgrounds/bg_ch3_wulin_assembly.png",
			"label": "chapter three assembly background",
		},
	]
	for probe: Dictionary in probes:
		var resource_path := String(probe["resource"])
		_expect(not ResourceLoader.exists(resource_path), "%s is absent from the common pack" % probe["label"])
		var pack_path := pack_root.path_join(String(probe["pack"]))
		_expect(FileAccess.file_exists(pack_path), "%s exists" % probe["pack"])
		_expect(ProjectSettings.load_resource_pack(pack_path, false), "%s mounts without replacing common files" % probe["pack"])
		_expect(ResourceLoader.exists(resource_path), "%s becomes available after mounting" % probe["label"])
	_expect(ResourceLoader.exists("res://scenes/main_menu.tscn"), "common pack retains the startup scene")
	_expect(ResourceLoader.exists("res://data/scenes/ch1_s1_road.tres"), "common pack retains lightweight scene definitions")
	_expect(ResourceLoader.exists("res://art/audio/bgm/bgm_jianghu_journey_v4.wav"), "mounted chapter-one startup pack retains the current v4 field BGM")
	print("[WeChatContentPackMount20260825] checks=19 failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
