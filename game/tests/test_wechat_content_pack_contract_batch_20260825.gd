extends SceneTree

var failures := 0


func _initialize() -> void:
	var manifest_path := "res://config/wechat_content_packs.json"
	_check(FileAccess.file_exists(manifest_path), "runtime content-pack manifest exists")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	_check(parsed is Dictionary, "runtime content-pack manifest is valid JSON")
	var packs: Dictionary = parsed.get("packs", {}) if parsed is Dictionary else {}
	_check(packs.size() == 4 and packs.has("chapter1_start") and packs.has("chapter1_late") and packs.has("chapter2") and packs.has("chapter3"), "manifest declares four staged content packs")
	var manager := FileAccess.get_file_as_string("res://scripts/autoload/content_pack_manager.gd")
	_check("HTTPRequest.new()" in manager and "download_file" in manager, "content packs download to a file without buffering the whole PCK in memory")
	_check("expected_bytes" in manager and "_file_size" in manager and "FileAccess.get_sha256" not in manager, "large downloaded packs use non-blocking size validation instead of synchronous WASM SHA-256")
	_check("ProjectSettings.load_resource_pack" in manager and "false" in manager, "verified packs mount without replacing common files")
	_check('WEB_CACHE_ROOT := "/tmp/wechat_content_packs"' in manager and ".part" in manager, "chapter PCKs use temporary cache and are excluded from persistent userfs sync")
	_check('total = int(_pack_entry(_active_pack).get("bytes", 0))' in manager and "600.0" in manager, "large first download shows manifest-backed progress and allows slow mobile networks")
	_check("pack_progress" in manager and "ProgressBar" in manager, "chapter downloads expose progress and a blocking loading overlay")
	var manager_script := load("res://scripts/autoload/content_pack_manager.gd") as Script
	var manager_instance: Node = manager_script.new()
	_check(manager_instance.call("pack_for_scene", &"linxi_tutorial") == &"chapter1_start", "Linxi maps resolve to the startup segment")
	_check(manager_instance.call("pack_for_scene", &"ch1_s3_zhuwei_forest") == &"chapter1_late", "Zhuwei and cave maps resolve to the late chapter-one segment")
	_check(manager_instance.call("pack_for_scene", &"ch2_s2_forest_edge") == &"chapter2", "chapter-two maps resolve to chapter two")
	_check(manager_instance.call("pack_for_scene", &"ch3_s1_wulin_assembly") == &"chapter3", "chapter-three maps resolve to chapter three")
	_check(manager_instance.call("pack_for_scene", &"world_map_jianghu") == &"common", "world map remains in the common pack")
	manager_instance.free()
	var router := FileAccess.get_file_as_string("res://scripts/autoload/scene_router.gd")
	_check(router.count("ContentPackManager.ensure_scene_pack") >= 3, "all field transition entry points enforce chapter-pack readiness")
	var partitioner := FileAccess.get_file_as_string("res://../scripts/prepare_wechat_content_packs.py")
	_check("safe_rebuild_root" in partitioner and "PACK_IDS" in partitioner, "pack partitioner owns only verified generated directories")
	_check('("chapter1_start", [1], "林西启动段")' in partitioner and 'f"{pack_id}.pck"' in partitioner, "partitioner finalizes hashes for both chapter-one segments and later chapters")
	var build_script := FileAccess.get_file_as_string("res://../scripts/build_wechat_trial.ps1")
	_check("--export-pack" in build_script and "prepare_wechat_content_packs.py" in build_script, "WeChat build exports chapter PCKs before the common Web package")
	_check("Get-FileHash" in build_script and "contentPacks" in build_script, "package report records each published PCK hash and size")
	var smoke_server := FileAccess.get_file_as_string("res://../scripts/serve_wechat_smoke.py")
	_check("Access-Control-Allow-Origin" in smoke_server and 'clean_path.startswith("/packs/")' in smoke_server, "local smoke server exposes Web files and chapter packs with CORS")
	_check('clean_path == "/.data.bin"' in smoke_server and 'clean_path == f"/{data_file.name}"' in smoke_server and 'clean_path.startswith("/webgl/")' in smoke_server and "UnityWebData1.0" in smoke_server, "local smoke server exposes all WXGameKit data-container URL forms")
	_check('pck_file = web_root / "index.pck"' in smoke_server and "Godot main pack" in smoke_server, "local smoke server validates the direct Godot main pack")
	print("[WeChatContentPackContract20260825] checks=20 failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
