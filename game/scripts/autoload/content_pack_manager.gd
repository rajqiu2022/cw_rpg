extends Node

## 微信试玩版的按章资源下载与挂载。
##
## 桌面版和普通Web版继续使用完整工程资源，本管理器直接判定为就绪；
## 只有同时具备`web`和`wechat_trial`特性时才下载章节PCK。

signal pack_progress(pack_id: StringName, downloaded_bytes: int, total_bytes: int)
signal pack_ready(pack_id: StringName)
signal pack_failed(pack_id: StringName, message: String)

const MANIFEST_PATH := "res://config/wechat_content_packs.json"
const CACHE_FOLDER := "wechat_content_packs"
const WEB_CACHE_ROOT := "/tmp/wechat_content_packs"
const OVERLAY_LAYER := 240
const UI_FONT_PATH := "res://art/fonts/LXGWWenKaiLite-Regular.ttf"

var _manifest: Dictionary = {}
var _mounted: Dictionary = {&"common": true}
var _callbacks: Dictionary = {}
var _request: HTTPRequest = null
var _active_pack: StringName = &""
var _active_temp_path := ""
var _active_final_path := ""
var _failed_pack: StringName = &""
var _overlay: CanvasLayer = null
var _status_label: Label = null
var _progress_bar: ProgressBar = null
var _retry_button: Button = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_manifest()
	if not _uses_remote_packs():
		for pack_id in [&"chapter1_start", &"chapter1_late", &"chapter2", &"chapter3"]:
			_mounted[pack_id] = true


func _process(_delta: float) -> void:
	if _request == null or String(_active_pack).is_empty():
		return
	var downloaded := _request.get_downloaded_bytes()
	var total := _request.get_body_size()
	# Godot Web / WXGameKit does not always expose Content-Length through
	# HTTPRequest while streaming to a file. The signed manifest already owns
	# the exact byte count, so use it as the progress denominator instead of
	# leaving the user on an indeterminate bar for a ~100 MiB first download.
	if total <= 0:
		total = int(_pack_entry(_active_pack).get("bytes", 0))
	_update_progress(downloaded, total)


func is_scene_ready(scene_id: StringName) -> bool:
	return is_pack_ready(pack_for_scene(scene_id))


func is_pack_ready(pack_id: StringName) -> bool:
	return not _uses_remote_packs() or bool(_mounted.get(pack_id, false))


func pack_for_scene(scene_id: StringName) -> StringName:
	var text := String(scene_id)
	if text.begins_with("ch2_"):
		return &"chapter2"
	if text.begins_with("ch3_"):
		return &"chapter3"
	if text.begins_with("linxi_") or text == "ch1_s1_road":
		return &"chapter1_start"
	if text.begins_with("ch1_") or text in ["interior_bandit_cave", "interior_inn_hall", "interior_martial_hall"]:
		return &"chapter1_late"
	return &"common"


func ensure_scene_pack(scene_id: StringName, completed: Callable = Callable()) -> bool:
	return ensure_pack(pack_for_scene(scene_id), completed)


func ensure_pack(pack_id: StringName, completed: Callable = Callable()) -> bool:
	if is_pack_ready(pack_id):
		return true
	if not completed.is_null():
		var pending: Array = _callbacks.get(pack_id, [])
		pending.append(completed)
		_callbacks[pack_id] = pending
	if pack_id == _active_pack:
		return false
	if not String(_active_pack).is_empty():
		_fail_pack(pack_id, "已有章节资源正在下载，请稍候。")
		return false
	if _try_mount_cached(pack_id):
		_finish_pack(pack_id)
		return false
	_start_download(pack_id)
	return false


func _uses_remote_packs() -> bool:
	return OS.has_feature("web") and OS.has_feature("wechat_trial")


func _load_manifest() -> void:
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_error("[ContentPack] manifest missing: %s" % MANIFEST_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if parsed is Dictionary:
		_manifest = parsed
	else:
		push_error("[ContentPack] invalid manifest JSON")


func _pack_entry(pack_id: StringName) -> Dictionary:
	var packs: Dictionary = _manifest.get("packs", {})
	var entry: Variant = packs.get(String(pack_id), {})
	return entry as Dictionary if entry is Dictionary else {}


func _start_download(pack_id: StringName) -> void:
	var entry := _pack_entry(pack_id)
	var file_name := String(entry.get("file", ""))
	if file_name.is_empty():
		_fail_pack(pack_id, "章节资源清单缺少文件名。")
		return
	_ensure_cache_folder()
	_active_pack = pack_id
	_failed_pack = &""
	_active_final_path = "%s/%s" % [_cache_root(), file_name]
	_active_temp_path = _active_final_path + ".part"
	_request = HTTPRequest.new()
	_request.name = "ChapterPackDownload"
	_request.process_mode = Node.PROCESS_MODE_ALWAYS
	_request.download_file = _active_temp_path
	# Mobile networks can legitimately need several minutes for the first
	# chapter pack. A visible percentage is preferable to a premature retry.
	_request.timeout = 600.0
	add_child(_request)
	_request.request_completed.connect(_on_request_completed)
	_show_overlay("正在下载%s资源……  0%%" % _pack_display_name(pack_id), false)
	var base_url := String(_manifest.get("baseUrl", "")).trim_suffix("/")
	var error := _request.request("%s/%s" % [base_url, file_name])
	if error != OK:
		_fail_active("无法开始下载（错误码%s）。" % error)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		_fail_active("下载失败（网络%s / HTTP %s）。" % [result, response_code])
		return
	var expected_bytes := int(_pack_entry(_active_pack).get("bytes", 0))
	if expected_bytes <= 0 or _file_size(_active_temp_path) != expected_bytes:
		_fail_active("章节资源大小校验失败，请重试。")
		return
	if FileAccess.file_exists(_active_final_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_active_final_path))
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(_active_temp_path),
		ProjectSettings.globalize_path(_active_final_path)
	)
	if rename_error != OK:
		_fail_active("章节资源写入失败（错误码%s）。" % rename_error)
		return
	if not ProjectSettings.load_resource_pack(_active_final_path, false):
		_fail_active("章节资源挂载失败。")
		return
	var finished_pack := _active_pack
	_cleanup_request()
	_mounted[finished_pack] = true
	_hide_overlay()
	_finish_pack(finished_pack)


func _try_mount_cached(pack_id: StringName) -> bool:
	var entry := _pack_entry(pack_id)
	var file_name := String(entry.get("file", ""))
	var expected_bytes := int(entry.get("bytes", 0))
	if file_name.is_empty() or expected_bytes <= 0:
		return false
	var path := "%s/%s" % [_cache_root(), file_name]
	if not FileAccess.file_exists(path) or _file_size(path) != expected_bytes:
		return false
	if not ProjectSettings.load_resource_pack(path, false):
		return false
	_mounted[pack_id] = true
	return true


func _finish_pack(pack_id: StringName) -> void:
	pack_ready.emit(pack_id)
	var pending: Array = _callbacks.get(pack_id, [])
	_callbacks.erase(pack_id)
	for callback: Callable in pending:
		if not callback.is_null():
			callback.call(true)


func _fail_active(message: String) -> void:
	var failed_pack := _active_pack
	_failed_pack = failed_pack
	_cleanup_request()
	_show_overlay(message, true)
	pack_failed.emit(failed_pack, message)


func _fail_pack(pack_id: StringName, message: String) -> void:
	_failed_pack = pack_id
	pack_failed.emit(pack_id, message)
	_show_overlay(message, true)


func _cleanup_request() -> void:
	if is_instance_valid(_request):
		_request.queue_free()
	_request = null
	_active_pack = &""
	_active_temp_path = ""
	_active_final_path = ""


func _ensure_cache_folder() -> void:
	DirAccess.make_dir_recursive_absolute(_cache_root())


func _cache_root() -> String:
	# The mini-game adapter persistently mirrors /userfs. Chapter PCKs are large
	# runtime caches, not save data; keeping them in /tmp avoids copying tens of
	# megabytes every five seconds and prevents a second in-memory copy.
	if _uses_remote_packs():
		return WEB_CACHE_ROOT
	return ProjectSettings.globalize_path("user://%s" % CACHE_FOLDER)


func _file_size(path: String) -> int:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return -1
	var size := file.get_length()
	file.close()
	return size


func _update_progress(downloaded: int, total: int) -> void:
	pack_progress.emit(_active_pack, downloaded, total)
	var loading_manager := get_node_or_null("/root/LoadingManager")
	if loading_manager != null and loading_manager.has_method("update_external_progress"):
		var ratio := clampf(float(downloaded) / float(total), 0.0, 1.0) if total > 0 else 0.0
		var message := "正在下载%s资源……" % _pack_display_name(_active_pack)
		if total > 0:
			message = "正在下载%s资源……  %.1f / %.1f MB" % [
				_pack_display_name(_active_pack),
				float(downloaded) / 1048576.0,
				float(total) / 1048576.0,
			]
		loading_manager.call("update_external_progress", ratio, message)
	if _progress_bar != null:
		_progress_bar.indeterminate = total <= 0
		if total > 0:
			_progress_bar.value = clampf(float(downloaded) / float(total) * 100.0, 0.0, 100.0)
	if _status_label != null and total > 0:
		var percent := int(clampf(float(downloaded) / float(total) * 100.0, 0.0, 100.0))
		_status_label.text = "正在下载%s资源……  %d%%（%.1f / %.1f MB）" % [
			_pack_display_name(_active_pack),
			percent,
			float(downloaded) / 1048576.0,
			float(total) / 1048576.0,
		]


func _show_overlay(message: String, allow_retry: bool) -> void:
	var loading_manager := get_node_or_null("/root/LoadingManager")
	if loading_manager != null:
		if allow_retry and loading_manager.has_method("show_external_failure"):
			loading_manager.call("show_external_failure", message, Callable(self, "_on_retry_pressed"))
		elif loading_manager.has_method("begin_external"):
			loading_manager.call(
				"begin_external",
				&"field",
				"正在准备%s" % _pack_display_name(_active_pack),
				message
			)
		return
	_ensure_overlay()
	_overlay.visible = true
	_status_label.text = message
	_progress_bar.visible = not allow_retry
	_retry_button.visible = allow_retry


func _hide_overlay() -> void:
	var loading_manager := get_node_or_null("/root/LoadingManager")
	if loading_manager != null and loading_manager.has_method("complete_external"):
		loading_manager.call("complete_external", "章节资源校验完成，正在进入……")
		return
	if _overlay != null:
		_overlay.visible = false


func _ensure_overlay() -> void:
	if _overlay != null:
		return
	_overlay = CanvasLayer.new()
	_overlay.name = "ContentPackOverlay"
	_overlay.layer = OVERLAY_LAYER
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.02, 0.025, 0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_overlay.add_child(shade)
	var panel := VBoxContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-260.0, -75.0)
	panel.size = Vector2(520.0, 150.0)
	panel.add_theme_constant_override("separation", 18)
	shade.add_child(panel)
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 24)
	_status_label.add_theme_color_override("font_color", Color("d6edf2"))
	var ui_font := load(UI_FONT_PATH) as Font
	if ui_font != null:
		_status_label.add_theme_font_override("font", ui_font)
	panel.add_child(_status_label)
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(520.0, 24.0)
	_progress_bar.show_percentage = false
	panel.add_child(_progress_bar)
	_retry_button = Button.new()
	_retry_button.text = "重试下载"
	_retry_button.custom_minimum_size = Vector2(220.0, 52.0)
	_retry_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if ui_font != null:
		_retry_button.add_theme_font_override("font", ui_font)
	_retry_button.pressed.connect(_on_retry_pressed)
	panel.add_child(_retry_button)


func _on_retry_pressed() -> void:
	var retry_pack := _failed_pack
	if not String(retry_pack).is_empty():
		_start_download(retry_pack)


func _pack_display_name(pack_id: StringName) -> String:
	match pack_id:
		&"chapter1_start": return "第一章·林西启程"
		&"chapter1_late": return "第一章·竹尾后山"
		&"chapter2": return "第二章"
		&"chapter3": return "第三章"
		_: return "公共"
