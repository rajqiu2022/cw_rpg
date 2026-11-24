extends SceneTree

var failures := 0


func _initialize() -> void:
	await process_frame
	_test_loading_contracts()
	await _test_loading_screen_runtime()
	print("[LoadingExperienceBatch20260901] failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _test_loading_contracts() -> void:
	var project := FileAccess.get_file_as_string("res://project.godot")
	_check('run/main_scene="res://scenes/loading_bootstrap.tscn"' in project, "startup enters through the Loading bootstrap")
	_check('LoadingManager="*res://scripts/autoload/loading_manager.gd"' in project, "LoadingManager is an autoload")
	var router := FileAccess.get_file_as_string("res://scripts/autoload/scene_router.gd")
	_check(router.count('_transition_to(SCENE_BATTLE, &"battle_enter"') == 4, "all four battle entry APIs use the Loading layer")
	_check('_transition_to(target_scene, &"field"' in router and '_transition_to(SCENE_FIELD_WALKABLE, &"field"' in router, "classic and walkable fields use the Loading layer")
	_check('_change_scene_immediate(SCENE_VICTORY)' in router and '_change_scene_immediate(SCENE_DEFEAT)' in router, "battle results open immediately without an intermediate Loading screen")
	_check('SceneRouter.go_field_smart(' in FileAccess.get_file_as_string("res://scripts/ui/result_victory.gd"), "closing the reward screen starts the field Loading transition")
	var manager := FileAccess.get_file_as_string("res://scripts/autoload/loading_manager.gd")
	for category in ["场景手记", "门派轶闻", "人物侧影", "武学札记", "心法要诀", "悬案卷宗"]:
		_check(category in manager, "Loading catalog includes %s" % category)
	_check("load_threaded_request" in manager and "load_threaded_get_status" in manager, "scene progress comes from Godot threaded loading")
	var content_manager := FileAccess.get_file_as_string("res://scripts/autoload/content_pack_manager.gd")
	_check("update_external_progress" in content_manager and "complete_external" in content_manager, "WeChat pack download shares the formal Loading screen")
	var pack_builder := FileAccess.get_file_as_string("res://../scripts/prepare_wechat_content_packs.py")
	_check('"art/loading/"' in pack_builder, "startup Loading art remains in the WeChat common pack")
	var total_bytes := 0
	for file_name in [
		"loading_misty_pass.jpg",
		"loading_five_sects.jpg",
		"loading_lengguyun_shadow.jpg",
		"loading_sword_practice.jpg",
		"loading_inner_cultivation.jpg",
		"loading_secret_archive.jpg",
	]:
		var path := "res://art/loading/v1/%s" % file_name
		_check(FileAccess.file_exists(path), "%s is present" % file_name)
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			total_bytes += file.get_length()
			file.close()
	_check(total_bytes <= 1024 * 1024, "six Loading images stay below 1 MiB source budget (%d bytes)" % total_bytes)


func _test_loading_screen_runtime() -> void:
	var packed := load("res://scenes/ui/loading_screen.tscn") as PackedScene
	_check(packed != null, "Loading screen scene parses")
	if packed == null:
		return
	var screen := packed.instantiate() as LoadingScreen
	root.add_child(screen)
	await process_frame
	screen.configure({
		"image": "res://art/loading/v1/loading_secret_archive.jpg",
		"category": "悬案卷宗",
		"title": "旧居档案",
		"body": "抽屉积灰多年，铜环却没有锈。",
	}, "地下档案室")
	screen.show_screen()
	screen.set_progress(0.63, "正在校验卷宗与场景……")
	await create_timer(0.24).timeout
	_check(screen.is_showing(), "Loading screen becomes visible")
	_check(screen.progress_bar.value == 63.0, "progress bar displays runtime progress")
	_check(screen.percent_label.text == "63%", "numeric percent stays synchronized")
	_check(screen.background.texture != null, "selected Loading art is loaded")
	if "--capture" in OS.get_cmdline_user_args():
		await process_frame
		var screenshot := root.get_viewport().get_texture().get_image()
		if screenshot != null:
			var save_error := screenshot.save_png("res://screenshots/loading_screen_archive_v1.png")
			_check(save_error == OK, "Loading acceptance screenshot is saved")
		else:
			print("[SKIP] dummy renderer cannot capture the Loading screen")
	screen.show_failure("资源校验失败。", Callable())
	_check(screen.stage_label.text == "资源校验失败。", "Loading screen exposes a readable failure state")
	screen.queue_free()
	await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
