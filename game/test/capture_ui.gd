extends SceneTree

## Headless UI 截图测试脚本。
##
## 用法（从 game/ 目录）：
##   godot --headless --script test/capture_ui.gd -- scene=<scene_id>
##
## 支持场景:
##   main_menu  — 主菜单
##   inventory  — 背包面板
##   equipment  — 装备面板
##   quest       — 任务面板
##   skill       — 技能面板
##   battle:<id> — 战斗场景 (如 battle:thug_lone)
##   field:<id>  — 探索场景 (如 field:ch1_s1_road)
##
## 输出: screenshots/{scene}_{timestamp}.png
##
## 依赖: Godot 4 的 rendering 管线支持 headless 模式。
##       若不支持 --headless 渲染，截图可能为空/灰。

var _capture_target: String = "main_menu"
var _main: Node = null

func _initialize() -> void:
	# 解析命令行参数
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("scene="):
			_capture_target = arg.replace("scene=", "")
		elif arg.begins_with("battle="):
			_capture_target = "battle:" + arg.replace("battle=", "")
		elif arg.begins_with("field="):
			_capture_target = "field:" + arg.replace("field=", "")

	_ensure_dirs()
	_bootstrap_autoloads()

	match true:
		_capture_target == "main_menu":
			_capture_main_menu()
		_capture_target == "inventory":
			_capture_inventory()
		_capture_target == "equipment":
			_capture_equipment()
		_capture_target == "quest":
			_capture_quest()
		_capture_target == "skill":
			_capture_skill()
		_capture_target.begins_with("battle:"):
			_capture_battle()
		_capture_target.begins_with("field:"):
			_capture_field()
		_:
			print("[CaptureUI] Unknown target: %s" % _capture_target)
			quit(1)


func _ensure_dirs() -> void:
	DirAccess.make_dir_recursive_absolute("screenshots")


func _bootstrap_autoloads() -> void:
	# Godot autoloads 在 SceneTree 脚本中可用，但部分需要手动初始化
	# GameState / Inventory / QuestManager 已经通过 autoload 注册
	print("[CaptureUI] Autoloads ready.")


func _capture_main_menu() -> void:
	print("[CaptureUI] Capturing: main_menu")
	change_scene_to_file("res://scenes/main_menu.tscn")
	await _wait_frames(3)
	_screenshot("main_menu")
	quit(0)


func _capture_inventory() -> void:
	print("[CaptureUI] Capturing: inventory panel")
	_spawn_scene_with_panel("res://scenes/field.tscn", "ch1_s1_road", func(root: Node):
		var inv := _instantiate_panel("res://scenes/ui/inventory_panel.tscn")
		root.add_child(inv)
		inv.call("open")
		await _wait_frames(2)
	)

	_screenshot("inventory")
	quit(0)


func _capture_equipment() -> void:
	print("[CaptureUI] Capturing: equipment panel")
	_spawn_scene_with_panel("res://scenes/field.tscn", "ch1_s1_road", func(root: Node):
		var eq_panel := _instantiate_panel("res://scenes/ui/equipment_panel.tscn")
		eq_panel.offset_right = 640
		eq_panel.offset_bottom = 720
		root.add_child(eq_panel)
		eq_panel.call("open")
		await _wait_frames(2)
	)

	_screenshot("equipment")
	quit(0)


func _capture_quest() -> void:
	print("[CaptureUI] Capturing: quest panel")
	_spawn_scene_with_panel("res://scenes/field.tscn", "ch1_s1_road", func(root: Node):
		var qp := _instantiate_panel("res://scenes/ui/quest_panel.tscn")
		root.add_child(qp)
		qp.call("open")
		await _wait_frames(2)
	)

	_screenshot("quest")
	quit(0)


func _capture_skill() -> void:
	print("[CaptureUI] Capturing: skill panel")
	_spawn_scene_with_panel("res://scenes/field.tscn", "ch1_s1_road", func(root: Node):
		var sp := _instantiate_panel("res://scenes/ui/skill_panel.tscn")
		root.add_child(sp)
		sp.call("open")
		await _wait_frames(2)
	)

	_screenshot("skill")
	quit(0)


func _capture_battle() -> void:
	var enemy_id := _capture_target.replace("battle:", "")
	if enemy_id == "" or enemy_id == "battle:":
		enemy_id = "thug_lone"
	print("[CaptureUI] Capturing: battle vs %s" % enemy_id)

	# 手动模拟 SceneRouter 的 battle payload
	var payload := {
		"enemy_id": enemy_id,
		"return_scene": &"ch1_s1_road",
	}

	change_scene_to_file("res://scenes/battle.tscn")
	await _wait_frames(5)
	_screenshot("battle_%s" % enemy_id)
	quit(0)


func _capture_field() -> void:
	var scene_id := _capture_target.replace("field:", "")
	if scene_id == "":
		scene_id = "ch1_s1_road"
	print("[CaptureUI] Capturing: field %s" % scene_id)

	change_scene_to_file("res://scenes/field.tscn")
	await _wait_frames(4)
	_screenshot("field_%s" % scene_id)
	quit(0)


func _spawn_scene_with_panel(scene_path: String, scene_id: String, callback: Callable) -> void:
	change_scene_to_file(scene_path)
	await _wait_frames(3)
	var root := get_first_node_in_group(&"field_root")
	if root == null:
		root = root
	await _wait_frames(1)
	callback.call(root)


func _instantiate_panel(path: String) -> Node:
	var scene := load(path) as PackedScene
	if scene == null:
		push_error("[CaptureUI] Cannot load: %s" % path)
		return Node.new()
	return scene.instantiate()


func _screenshot(name: String) -> void:
	var ts := Time.get_unix_time_from_system()
	var fname := "screenshots/%s_%d.png" % [name, ts]
	var img := get_root().get_viewport().get_texture().get_image()
	if img == null:
		print("[CaptureUI] WARNING: screenshot image is null (headless GPU required)")
		return
	var err := img.save_png(fname)
	if err == OK:
		print("[CaptureUI] Saved: %s" % fname)
	else:
		print("[CaptureUI] ERROR saving screenshot: %d" % err)


func _wait_frames(count: int):
	for _i in count:
		await process_frame


func quit(code: int = 0) -> void:
	# 确保 process_mode 允许 quit
	get_root().set_meta("finished", true)
	await _wait_frames(1)
	get_root().propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	if code != 0:
		push_error("[CaptureUI] exit code %d" % code)
