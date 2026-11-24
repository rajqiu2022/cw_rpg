extends SceneTree

var failures := 0


func _initialize() -> void:
	var project_text := FileAccess.get_file_as_string("res://project.godot")
	var preset_text := FileAccess.get_file_as_string("res://export_presets.cfg")
	_check('PlatformBridge="*res://scripts/autoload/platform_bridge.gd"' in project_text, "PlatformBridge is an autoload")
	_check('ContentPackManager="*res://scripts/autoload/content_pack_manager.gd"' in project_text, "ContentPackManager is an autoload")
	_check('window/handheld/orientation=0' in project_text, "handheld orientation is landscape")
	_check('pointing/emulate_mouse_from_touch=true' in project_text, "touch input emits mouse events for existing UI")
	_check('pointing/emulate_touch_from_mouse=true' in project_text, "desktop can emulate touch during QA")
	_check('renderer/rendering_method="gl_compatibility"' in project_text, "Web uses the Compatibility renderer")
	_check('variant/thread_support=false' in preset_text, "Web export is single threaded")
	_check('custom_features="wechat_trial"' in preset_text, "WeChat release feature flag is exported")
	_check('export_path="build/wechat_web/index.html"' in preset_text, "Web export stays inside the game build directory")
	_check("screenshots/*" in preset_text and "test/*" in preset_text and "addons/*" in preset_text, "release export excludes screenshots, tests and editor addons")
	_check("art/audio/bgm/*_v2.wav" in preset_text and "art/audio/bgm/*_v3.wav" in preset_text and "art/audio/bgm/*_v4.wav" not in preset_text, "release export excludes superseded BGM generations but retains current v4 music")
	_check(ResourceLoader.exists("res://scripts/autoload/platform_bridge.gd"), "platform bridge script exists")
	_check(ResourceLoader.exists("res://scripts/autoload/audio_manager.gd"), "audio manager exists")
	_check(ResourceLoader.exists("res://scripts/autoload/save_manager.gd"), "save manager exists")
	_check(ResourceLoader.exists("res://scripts/autoload/content_pack_manager.gd"), "content pack manager exists")
	var audio_text := FileAccess.get_file_as_string("res://scripts/autoload/audio_manager.gd")
	_check("unlock_from_user_gesture" in audio_text and "_pending_bgm_path" in audio_text, "Web audio waits for a user gesture")
	_check('if not OS.has_feature("web")' in audio_text and "_warmup_audio_device()" in audio_text, "Web skips the unsupported generator warmup path")
	_check("pause_for_platform" in audio_text and "resume_after_platform" in audio_text, "audio handles platform pause/resume")
	var save_text := FileAccess.get_file_as_string("res://scripts/autoload/save_manager.gd")
	_check("_write_slot_atomic" in save_text and "slot_backup_path" in save_text, "save slots use temp-file commit and backup recovery")
	var platform_text := FileAccess.get_file_as_string("res://scripts/autoload/platform_bridge.gd")
	_check("WECHAT_TRIAL_MAX_CHAPTER := 3" in platform_text and "is_scene_allowed" in platform_text, "WeChat trial runtime cannot enter chapter-four resources")
	_check("ThemeDB.fallback_font" in platform_text and "node_added.connect" in platform_text and "normal_font" in platform_text, "Web runtime injects the bundled Chinese font into static and dynamic UI controls")
	var chapter_end_text := FileAccess.get_file_as_string("res://scripts/ui/chapter_end.gd")
	_check("试玩内容已完成" in chapter_end_text and "is_chapter_allowed" in chapter_end_text, "chapter three ends at the reviewed trial boundary")
	var pack_plan_path := "res://../config/wechat-content-pack-plan-v1.json"
	_check(FileAccess.file_exists(pack_plan_path), "chapters one to three own a machine-readable package plan")
	var pack_plan: Variant = JSON.parse_string(FileAccess.get_file_as_string(pack_plan_path))
	_check(pack_plan is Dictionary and String(pack_plan.get("releaseScope", "")) == "chapters-1-3-trial", "package plan is scoped to the first three chapters")
	_check(pack_plan is Dictionary and (pack_plan.get("remoteData", {}) as Dictionary).get("packs", []).size() == 5, "package plan separates common data and four staged content packs")
	print("[WeChatReleaseFoundation20260824] checks=25 failures=%d" % failures)
	quit(1 if failures > 0 else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("[PASS] %s" % message)
	else:
		failures += 1
		push_error("[FAIL] %s" % message)
