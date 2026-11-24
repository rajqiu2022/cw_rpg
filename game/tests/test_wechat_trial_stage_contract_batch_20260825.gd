extends SceneTree

var failures := 0


func _initialize() -> void:
	var script_path := "res://../scripts/prepare_wechat_trial_stage.py"
	_check(FileAccess.file_exists(script_path), "trial staging builder exists")
	var source := FileAccess.get_file_as_string(script_path)
	_check("wechat-trial-chapters-1-3" in source, "stage builder declares the first-three-chapter scope")
	_check("screenshots" in source and "shutil.rmtree(stage_root)" in source, "stage builder excludes screenshots and only rebuilds its verified staging directory")
	_check('VOICE_GROUPS = ("ch1", "ch2", "ch3", "lin", "int")' in source, "stage builder keeps only trial dialogue voice groups")
	_check("is_trial_scene" in source and 'stem.startswith(("ch1_", "ch2_", "ch3_", "linxi_"))' in source, "stage builder limits field scenes to the trial route")
	_check("is_future_chapter_name" in source and "TRIAL_BLOCKED_DATA_IDS" in source, "script catalog ids cannot pull later chapters or late legendary arts into the trial")
	_check("path.stat().st_size > 0" in source and 'path.name.endswith(".import")' in source, "zero-byte voice placeholders and stale import sidecars are excluded")
	_check("EXT_RESOURCE_UID_RE" in source and "strippedUidHints" in source, "clean staging strips stale UID hints while keeping authoritative text paths")
	_check("skill_unique_v1" in source and 'f"vfx_{current.stem}_4frame_v1.png"' in source, "only selected skills pull their generated unique VFX")
	var build_script := FileAccess.get_file_as_string("res://../scripts/build_wechat_trial.ps1")
	_check("prepare_wechat_trial_stage.py" in build_script and "FullProject" in build_script, "WeChat build uses staging by default and keeps an explicit full-project escape hatch")
	_check("OutputDirectoryName" in build_script and "ValidatePattern" in build_script and "Remove-Item -LiteralPath $verifiedOutputRoot" in build_script, "converter output is name-constrained, path-verified and cleaned before every build")
	_check("project.config.json" in build_script and "$projectConfig.appid = $AppId" in build_script and "$projectConfig.isGameTourist" in build_script, "build overwrites the converter template AppID and tourist flag")
	var preflight := FileAccess.get_file_as_string("res://../scripts/validate_wechat_trial_release.py")
	_check("EXPECTED_PACKS" in preflight and "require-real-credentials" in preflight and "require-devtools-plugin" in preflight and "file_sha256" in preflight, "release preflight validates credentials, WXGameKit identity and all staged pack hashes")
	var opener := FileAccess.get_file_as_string("res://../scripts/open_wechat_trial.ps1")
	_check("validate_wechat_trial_release.py" in opener and "cli.bat" in opener and "open --project" in opener, "DevTools launcher gates IDE import on the release preflight")
	var framework_prep := FileAccess.get_file_as_string("res://../scripts/prepare_wechat_framework.py")
	_check("_emscripten_glViewport" in framework_prep and "COMPAT_SOURCE_VIEWPORT" in framework_prep and "SAFE_VIEWPORT" in framework_prep and "len(matched_viewports) != 1" in framework_prep, "both standard and no-EH Godot viewport arrows are normalized before WeChat conversion")
	_check("--input-type=module --check" in build_script and "frameworkSyntax" in build_script, "converted framework receives a mandatory whole-file JavaScript syntax check")
	_check("prepare_wechat_compat_runtime.mjs" in build_script and "wasmExceptions = $false" in build_script and 'runtimeVersion = $wechatEngineVersion' in build_script, "WeChat build uses the bundled no-EH compatibility runtime")
	_check("compressData = $false" in build_script and 'dataCompression = "none"' in build_script and "prepare_wechat_data_container.py" in build_script and "dataFile = $dataContainerPath" in build_script, "trial wraps the Godot PCK in an uncompressed WXGameKit data container")
	_check("UTF8Encoding($false)" in build_script and build_script.count("WriteAllText") >= 2, "transformer and DevTools project JSON are written as UTF-8 without a BOM")
	_check("0x4E91" in build_script and "0x5F71" in build_script and "0x4FA0" in build_script and "0x4F20" in build_script, "Chinese project name is code-page independent under Windows PowerShell 5.1")
	_check("0x6587" in build_script and "0x8F7D" in build_script and "0x7F16" in build_script and "0x5177" in build_script, "default Godot path is code-page independent under Windows PowerShell 5.1")
	_check("pck_has_magic" in preflight and "PCK_MAGIC = b\"GDPC\"" in preflight and "UNITY_WEB_DATA_MAGIC" in preflight and "data_has_pack" in preflight, "release preflight validates both the WXGameKit container and embedded Godot PCK")
	var smoke_server := FileAccess.get_file_as_string("res://../scripts/serve_wechat_smoke.py")
	_check("PCK_MAGIC = b\"GDPC\"" in smoke_server and "Godot main pack is missing or malformed" in smoke_server, "local CDN fails fast instead of serving a malformed direct Godot pack")
	var godot_adapter := FileAccess.get_file_as_string("res://../scripts/wechat_godot_custom_instance.js")
	_check("pthreadMainPrefixURL" in godot_adapter and "WebAssembly.RuntimeError" in godot_adapter and '"readAsync"' not in godot_adapter and '"readBinary"' not in godot_adapter and "--main-pack" in godot_adapter and "noExitRuntime" in godot_adapter, "Godot adapter removes obsolete Unity keys while preserving plugin I/O and packaged index.pck")
	_check("configureGodotWXGameKit(" in build_script and "dataFile = $dataContainerPath" in build_script and "wechat_godot_custom_instance.js" in build_script, "build configures the Godot adapter before WXGameKit starts")
	print("[WeChatTrialStageContract20260825] checks=25 failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
