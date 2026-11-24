extends Node

## 统一的启动、场景、战斗与微信资源包 Loading 中枢。

const LOADING_SCREEN_SCENE := preload("res://scenes/ui/loading_screen.tscn")
const WORLD_VISUAL_PATCH := preload("res://scripts/world/world_farmland_visual_patch_resolver_20261015.gd")
const MIN_VISIBLE_SECONDS := 0.62
const EXTERNAL_PROGRESS_CEILING := 0.88
const FIELD_PRELOAD_CONCURRENCY := 8
const WORLD_V15_STREAM = preload("res://scripts/world/world_v15_visible_stream_20261018r.gd")

const CARDS: Array[Dictionary] = [
	{
		"id": &"misty_pass",
		"image": "res://art/loading/v1/loading_misty_pass.jpg",
		"category": "场景手记",
		"title": "雾岭旧道",
		"body": "石阶上只有上山的脚印。可守路人说，昨夜分明有人从山中归来。",
		"contexts": [&"startup", &"field", &"battle_exit"],
	},
	{
		"id": &"five_sects",
		"image": "res://art/loading/v1/loading_five_sects.jpg",
		"category": "门派轶闻",
		"title": "五派同盟",
		"body": "五派共执一纸盟书，却各自收藏着不同的抄本。被删掉的那一行，人人都说不曾见过。",
		"contexts": [&"startup", &"field", &"chapter"],
	},
	{
		"id": &"lengguyun_shadow",
		"image": "res://art/loading/v1/loading_lengguyun_shadow.jpg",
		"category": "人物侧影",
		"title": "冷孤云",
		"body": "他记得师父教过的每一招，却想不起童年那场雪。旧信上的朱印，偏偏来自师门。",
		"contexts": [&"startup", &"field", &"battle_exit", &"chapter"],
	},
	{
		"id": &"sword_practice",
		"image": "res://art/loading/v1/loading_sword_practice.jpg",
		"category": "武学札记",
		"title": "孤云九式",
		"body": "剑招先问落点，再问来处。第九式没有剑谱，只有一句被墨迹遮住的批注。",
		"contexts": [&"battle_enter", &"battle_exit"],
	},
	{
		"id": &"inner_cultivation",
		"image": "res://art/loading/v1/loading_inner_cultivation.jpg",
		"category": "心法要诀",
		"title": "玄霜归藏诀",
		"body": "调息不可求快。寒意沉入丹田时，先分清它来自功法，还是石门后的风。",
		"contexts": [&"battle_enter", &"field"],
	},
	{
		"id": &"secret_archive",
		"image": "res://art/loading/v1/loading_secret_archive.jpg",
		"category": "悬案卷宗",
		"title": "旧居档案",
		"body": "抽屉积灰多年，铜环却没有锈。泥脚印停在墙前——墙后传来纸页翻动的声音。",
		"contexts": [&"field", &"battle_exit", &"chapter"],
	},
	{
		"id": &"jianghu_collection",
		"image": "res://art/loading/v1/loading_sword_practice.jpg",
		"category": "江湖行记",
		"title": "百艺随身",
		"body": "门派给你一条稳路，江湖却不止一条路。村镇教头、无名高人与旧墙残谱，都可能藏着下一门招式。",
		"contexts": [&"startup", &"field", &"chapter"],
	},
]

var _screen: LoadingScreen = null
var _rng := RandomNumberGenerator.new()
var _last_card_id: StringName = &""
var _transition_active := false
var _finishing := false
var _loading_path := ""
var _transition_kind: StringName = &"field"
var _transition_context: Dictionary = {}
var _started_msec := 0
var _progress_base := 0.0
var _progress_span := 1.0
var _external_active := false
var _handoff_progress := 0.0
var _external_token := 0
var _field_preloaded: Array[Resource] = []
var _field_preparation_token := 0
var _source_field: WeakRef = null
var _source_process_mode := Node.PROCESS_MODE_INHERIT
var _field_drain_paths: Array[String] = []
var _field_active_requests: Array[String] = []
var _field_preload_metrics: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	set_process(false)


func _exit_tree() -> void:
	_abandon_field_requests(_field_active_requests)
	_drain_field_requests()
	_field_drain_paths.clear() # Never wait for unfinished loader jobs during shutdown.
	_end_field_validation()
	_field_preloaded.clear()
	_release_source_field(true)


func transition_to(scene_path: String, kind: StringName = &"field", context: Dictionary = {}) -> void:
	if _transition_active:
		push_warning("[LoadingManager] transition already active: %s" % _loading_path)
		return
	_ensure_screen()
	_transition_active = true
	_finishing = false
	_loading_path = scene_path
	_transition_kind = kind
	_transition_context = context.duplicate(true)
	if context.has("field_scene_id"): _hold_source_field()
	_started_msec = Time.get_ticks_msec()
	_external_token += 1
	_external_active = false
	if _handoff_progress > 0.0 and _screen.is_showing():
		_progress_base = _handoff_progress
		_progress_span = 1.0 - _progress_base
		_screen.set_progress(_progress_base, "资源已就绪，正在布置场景……")
	else:
		_progress_base = 0.0
		_progress_span = 1.0
		_screen.configure(_choose_card(kind), String(context.get("title", "")))
		_screen.set_progress(0.0, _stage_text(kind, 0.0))
		_screen.show_screen()
	_handoff_progress = 0.0
	var threaded := not OS.has_feature("web")
	var error := ResourceLoader.load_threaded_request(scene_path, "PackedScene", threaded)
	if error != OK:
		_fail_transition("无法加载下一场景（错误码 %s）。" % error)
		return
	set_process(true)


func begin_external(kind: StringName, title: String, stage_text: String) -> void:
	_ensure_screen()
	_external_token += 1
	_external_active = true
	_handoff_progress = 0.0
	_screen.configure(_choose_card(kind), title)
	_screen.set_progress(0.0, stage_text)
	_screen.show_screen()


func begin_field_preparation(title: String) -> int:
	if _transition_active or _external_active: return 0
	_ensure_screen()
	_external_token += 1
	_field_preparation_token = _external_token
	_external_active = true
	_handoff_progress = .05
	_screen.configure(_choose_card(&"field"), title)
	_screen.set_progress(0.0, "正在校验地图来源、道路与入口……")
	_screen.show_screen(true)
	_hold_source_field()
	return _field_preparation_token


func finish_field_preparation(token: int) -> void:
	if token == 0 or token != _field_preparation_token: return
	_field_preparation_token = 0
	if _transition_active: return
	_external_active = false
	_handoff_progress = 0.0
	_release_source_field(true)
	await _screen.hide_screen()


func _hold_source_field() -> void:
	if _source_field != null: return
	var field: Node = get_tree().current_scene
	if field == null or not field.has_method("get_field_loading_state"): return
	_source_field = weakref(field)
	if field.has_method("_suspend_world_v15_stream"): field.call("_suspend_world_v15_stream")
	_source_process_mode = field.process_mode
	field.process_mode = Node.PROCESS_MODE_DISABLED


func _release_source_field(restore: bool) -> void:
	var field: Node = _source_field.get_ref() if _source_field != null else null
	if restore and is_instance_valid(field) and field.is_inside_tree() and not field.is_queued_for_deletion():
		field.process_mode = _source_process_mode
		if field.has_method("_resume_world_v15_stream"): field.call("_resume_world_v15_stream")
	_source_field = null


func update_external_progress(ratio: float, stage_text: String) -> void:
	if not _external_active:
		return
	_screen.set_progress(clampf(ratio, 0.0, 1.0) * EXTERNAL_PROGRESS_CEILING, stage_text)

func update_field_preparation_progress(token: int,ratio: float,stage_text: String) -> void:
	# Completed real validation phases only. Keep handoff monotonic, and never
	# let an old worker write a successor transition or claim final ready.
	if token<=0 or token!=_field_preparation_token or token!=_external_token or not _external_active or _transition_active or _screen==null: return
	_handoff_progress=maxf(_handoff_progress,clampf(ratio,0.0,.65))
	_screen.set_progress(_handoff_progress,stage_text)


func complete_external(stage_text: String = "资源校验完成，正在进入……") -> void:
	if _screen == null:
		return
	_external_active = false
	_handoff_progress = 0.9
	_screen.set_progress(_handoff_progress, stage_text)
	_external_token += 1
	_delayed_external_hide(_external_token)


func show_external_failure(message: String, retry_action: Callable) -> void:
	_ensure_screen()
	_external_active = false
	_handoff_progress = 0.0
	_screen.show_failure(message, retry_action)
	if not _screen.is_showing():
		_screen.show_screen()


func _process(_delta: float) -> void:
	_drain_field_requests()
	if not _transition_active and _field_drain_paths.is_empty(): set_process(false)
	if not _transition_active or _finishing:
		return
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(_loading_path, progress)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var ratio := float(progress[0]) if not progress.is_empty() else 0.0
			var span: float = _progress_span * .25 if _transition_context.has("field_scene_id") else _progress_span
			var shown := _progress_base + clampf(ratio, 0.0, 1.0) * span
			_screen.set_progress(shown, _stage_text(_transition_kind, ratio))
		ResourceLoader.THREAD_LOAD_LOADED:
			_finishing = true
			_screen.set_progress(_field_progress(.25) if _transition_context.has("field_scene_id") else 1.0, "场景读取完成，正在准备地图资源……")
			_finish_transition.call_deferred(_capture_transition_owner())
		ResourceLoader.THREAD_LOAD_FAILED, ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fail_transition("场景资源读取失败，请重试。")


func _finish_transition(owner: Dictionary = {}) -> void:
	if owner.is_empty(): owner = _capture_transition_owner()
	if not _owns_transition(owner): return
	var elapsed := float(Time.get_ticks_msec() - _started_msec) / 1000.0
	if elapsed < MIN_VISIBLE_SECONDS:
		await get_tree().create_timer(MIN_VISIBLE_SECONDS - elapsed, true, false, true).timeout
	if not _owns_transition(owner): return
	var packed := ResourceLoader.load_threaded_get(_loading_path) as PackedScene
	if packed == null:
		_fail_transition("场景资源格式无效，请重试。")
		return
	if _transition_context.has("field_scene_id"):
		var preloaded: bool = await _preload_field_resources()
		if not _owns_transition(owner): return
		if not preloaded:
			_fail_transition("地图资源读取失败，请重试。")
			return
	set_process(not _field_drain_paths.is_empty())
	# Only a proven, ready city and one exact enabled room may retain the live
	# exterior. The old controller remains alive outside SceneTree/Physics.
	var parked_city: bool=false
	if _transition_context.has("field_scene_id"):
		parked_city=SceneRouter.park_resident_exterior_for_excursion(StringName(_transition_context.field_scene_id))
	var error := get_tree().change_scene_to_packed(packed)
	if error != OK:
		if parked_city: SceneRouter.rollback_resident_room_install()
		_fail_transition("无法进入下一场景（错误码 %s）。" % error)
		return
	_release_source_field(false)
	await get_tree().process_frame
	if not _owns_transition(owner): return
	var field: Node = get_tree().current_scene
	if _transition_context.has("field_scene_id"):
		# SceneTree installation may finish on the next idle boundary. A field
		# transition must never turn a missing ready protocol into success.
		if field == null:
			await get_tree().process_frame
			if not _owns_transition(owner): return
			field = get_tree().current_scene
		if not is_instance_valid(field) or not field.has_method("get_field_loading_state"):
			_fail_transition("地图控制器缺少就绪协议 get_field_loading_state，请重试。")
			return
		var field_ready := false
		while is_instance_valid(field) and field.is_inside_tree() and not field.is_queued_for_deletion() and get_tree().current_scene == field:
			var response: Variant = field.call("get_field_loading_state")
			if not response is Dictionary or typeof(response.get("complete")) != TYPE_BOOL or typeof(response.get("failed")) != TYPE_BOOL:
				_fail_transition("地图就绪协议返回格式错误，请重试。")
				return
			var state: Dictionary = response
			if state.failed:
				_fail_transition("地图初始化未完成：" + String(state.get("stage", "未知错误")))
				return
			_screen.set_progress(_field_progress(.7 + float(state.get("progress", 0.0)) * .29), String(state.get("stage", "正在布置地图……")))
			if state.complete:
				if typeof(state.get("scene_id")) != TYPE_STRING or state.scene_id != String(_transition_context.field_scene_id):
					_fail_transition("地图身份不匹配，请重试。")
					return
				field_ready = true
				break
			await get_tree().process_frame
			if not _owns_transition(owner): return
		if not field_ready:
			_fail_transition("地图初始化已中断，请重试。")
			return
	_screen.set_progress(1.0, "即将抵达……")
	await _screen.hide_screen()
	if not _owns_transition(owner): return
	_reset_transition()


func _field_progress(ratio: float) -> float:
	return _progress_base + _progress_span * clampf(ratio, 0.0, 1.0)


func _preload_field_resources() -> bool:
	var owner := _capture_transition_owner()
	if not _owns_transition(owner): return false
	var started := Time.get_ticks_usec()
	# Abandoned visible requests belong to the old epoch, never the new batch.
	if not await WORLD_V15_STREAM.wait_for_drains(get_tree(),_owns_transition.bind(owner)): return false
	var world_drain_usec:=Time.get_ticks_usec()-started
	var metrics := {"scene_id": String(_transition_context.field_scene_id), "limit": 1 if OS.has_feature("web") else FIELD_PRELOAD_CONCURRENCY, "count": 0, "completed": 0, "request_peak": 0, "poll_frames": 0, "collect_ms": 0.0, "scene_read_ms": 0.0, "elapsed_ms": 0.0, "complete": false}
	metrics["world_prior_drain_ms"]=world_drain_usec/1000.0
	_field_preload_metrics = metrics.duplicate(true)
	_field_preloaded.clear()
	var path: String=SceneRouter.field_scene_resource_path(StringName(_transition_context.field_scene_id))
	if path.is_empty(): return false
	var scene: Resource
	if int(_transition_context.get("city_validation_token",0)) > 0:
		var validated: Dictionary = SceneRouter.get_validated_field_transition(StringName(_transition_context.field_scene_id))
		if validated.get("token",0) != _transition_context.city_validation_token or not validated.get("scene") is SceneScript: return false
		scene = validated.scene
	else:
		scene = await _read_field_resource(path, owner)
	if not _owns_transition(owner): return false
	metrics.scene_read_ms = (Time.get_ticks_usec() - started) / 1000.0
	if not scene is SceneScript: return false
	var definition: SceneScript = scene as SceneScript
	var paths: Dictionary = {}
	var spawn: Vector2 = _transition_context.get("field_spawn", definition.player_spawn) if _transition_context.get("field_spawn") is Vector2 else definition.player_spawn
	if definition.streamed_background == null:
		_add_field_resource_path(paths, definition.background_path)
	else:
		var stream: StreamedBackgroundSet = definition.streamed_background
		var size := Vector2(stream.logical_size)
		var visible_size: Vector2 = get_viewport().get_visible_rect().size / maxf(1.0, definition.camera_zoom)
		var half := visible_size * .5
		var center := (spawn * size).clamp(half.min(size * .5), (size - half).max(size * .5))
		var visible_rect := Rect2(center - half, visible_size).grow(stream.load_padding)
		for entry: Dictionary in WORLD_VISUAL_PATCH.effective_chunks(stream, stream.uses_desktop_variant()):
			var logical_rect: Rect2 = entry.get("logical_rect", Rect2())
			if logical_rect.intersects(visible_rect, true): _add_field_resource_path(paths, String(entry.get("path", "")))
	var objects: Array = definition.scene_objects
	if definition.map_layout != null:
		objects = definition.map_layout.visual_objects
		_add_field_resource_path(paths, definition.map_layout.walkable_mask_path)
		var shoe := Rect2(spawn * Vector2(definition.map_layout.design_size) - Vector2(17, 12), Vector2(34, 24)).grow(1.0)
		for tile: Dictionary in definition.map_layout.walkable_mask_tiles:
			var tile_rect: Rect2 = tile.get("logical_rect", Rect2())
			if tile_rect.intersects(shoe, true): _add_field_resource_path(paths, String(tile.get("path", "")))
	if WORLD_V15_STREAM.applies(definition):
		var selection_started:=Time.get_ticks_usec()
		var selection: Dictionary=WORLD_V15_STREAM.initial_selection(definition,spawn,get_viewport().get_visible_rect().size)
		metrics["world_selection_ms"]=(Time.get_ticks_usec()-selection_started)/1000.0
		if not selection.get("ok",false): return false
		for texture_path: String in selection.paths:
			if not ResourceLoader.exists(texture_path): return false
			paths[texture_path]=true
		metrics["world_object_total"]=int(selection.total)
		metrics["world_object_selected"]=int(selection.selected)
	else:
		for object: Dictionary in objects: _add_field_resource_path(paths, String(object.get("texture", "")))
	for npc: Dictionary in definition.npcs:
		for key: String in ["sprite_path", "walk_sprite_path", "portrait_path"]: _add_field_resource_path(paths, String(npc.get(key, "")))
	metrics.count = paths.size()
	if not OS.has_feature("web"):
		var success: bool = await _preload_field_parallel(paths.keys(), owner, metrics, started)
		if not _owns_transition(owner): return false
		if not success: return false
		_screen.set_progress(_field_progress(.7), "地图资源已读取，正在校验道路与入口……")
		return true
	var done := 0
	for resource_path: String in paths:
		_screen.set_progress(_field_progress(.25 + .44 * float(done) / maxi(1, paths.size())), "正在读取地图资源……")
		var resource: Resource = await _read_field_resource(resource_path, owner)
		if not _owns_transition(owner): return false
		if resource == null: return false
		done += 1
	metrics.completed = done
	metrics.request_peak = 1 if done > 0 else 0
	_store_preload_metrics(owner, metrics, started, true)
	_screen.set_progress(_field_progress(.7), "地图资源已读取，正在校验道路与入口……")
	return true


func _add_field_resource_path(paths: Dictionary, path: String) -> void:
	if not path.is_empty() and ResourceLoader.exists(path): paths[path] = true


func _read_field_resource(path: String, owner: Dictionary = {}) -> Resource:
	# Only Godot's resource-loader workers decode files. No scene-tree, physics,
	# texture readback or contract validation is performed on a background thread.
	if owner.is_empty(): owner = _capture_transition_owner()
	if not _owns_transition(owner): return null
	while _field_drain_paths.size() >= FIELD_PRELOAD_CONCURRENCY or path in _field_drain_paths:
		_drain_field_requests()
		if _field_drain_paths.size() < FIELD_PRELOAD_CONCURRENCY and not path in _field_drain_paths: break
		await get_tree().process_frame
		if not _owns_transition(owner): return null
	var error := ResourceLoader.load_threaded_request(path, "", not OS.has_feature("web"))
	if error != OK: return null
	var requested: Array[String] = [path]
	_field_active_requests = requested
	while true:
		if not _owns_transition(owner):
			_abandon_field_requests(requested)
			return null
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var resource: Resource = ResourceLoader.load_threaded_get(path)
			requested.clear()
			if resource != null: _field_preloaded.append(resource)
			return resource
		if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			requested.clear()
			return null
		await get_tree().process_frame
	return null


func _capture_transition_owner() -> Dictionary:
	return {"token": _external_token, "path": _loading_path, "kind": _transition_kind, "context": var_to_bytes(_transition_context)}


func _owns_transition(owner: Dictionary) -> bool:
	return is_inside_tree() and _transition_active and owner.get("token") == _external_token and owner.get("path") == _loading_path and owner.get("kind") == _transition_kind and owner.get("context") == var_to_bytes(_transition_context)


func _preload_field_parallel(paths: Array, owner: Dictionary, metrics: Dictionary, started: int) -> bool:
	var next := 0
	var pending: Array[String] = []
	_field_active_requests = pending
	var batch_started := Time.get_ticks_usec()
	while next < paths.size() or not pending.is_empty():
		if not _owns_transition(owner):
			_abandon_field_requests(pending)
			return false
		_drain_field_requests()
		while next < paths.size() and pending.size() + _field_drain_paths.size() < FIELD_PRELOAD_CONCURRENCY:
			var path: String = paths[next]
			if path in _field_drain_paths: break
			if ResourceLoader.load_threaded_request(path, "", true) != OK:
				_abandon_field_requests(pending)
				_store_preload_metrics(owner, metrics, started, false)
				return false
			pending.append(path)
			next += 1
			metrics.request_peak = maxi(int(metrics.request_peak), pending.size() + _field_drain_paths.size())
		var completed_before := int(metrics.completed)
		for index in range(pending.size() - 1, -1, -1):
			var path := pending[index]
			var status := ResourceLoader.load_threaded_get_status(path)
			if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: continue
			pending.remove_at(index)
			if status != ResourceLoader.THREAD_LOAD_LOADED:
				_abandon_field_requests(pending)
				_store_preload_metrics(owner, metrics, started, false)
				return false
			var collect_started := Time.get_ticks_usec()
			var resource: Resource = ResourceLoader.load_threaded_get(path)
			metrics.collect_ms += (Time.get_ticks_usec() - collect_started) / 1000.0
			if resource == null:
				_abandon_field_requests(pending)
				_store_preload_metrics(owner, metrics, started, false)
				return false
			_field_preloaded.append(resource)
			metrics.completed += 1
		_screen.set_progress(_field_progress(.25 + .44 * float(metrics.completed) / maxi(1, paths.size())), "正在读取地图资源……")
		_store_preload_metrics(owner, metrics, started, false)
		# Refill completed slots immediately; do not force one frame per cached batch.
		if int(metrics.completed) > completed_before and next < paths.size() and Time.get_ticks_usec() - batch_started < 8000: continue
		if next < paths.size() or not pending.is_empty():
			metrics.poll_frames += 1
			await get_tree().process_frame
			if not _owns_transition(owner):
				_abandon_field_requests(pending)
				return false
			batch_started = Time.get_ticks_usec()
	_store_preload_metrics(owner, metrics, started, true)
	return true


func _store_preload_metrics(owner: Dictionary, metrics: Dictionary, started: int, complete: bool) -> void:
	if not _owns_transition(owner): return
	metrics.elapsed_ms = (Time.get_ticks_usec() - started) / 1000.0
	metrics.complete = complete
	_field_preload_metrics = metrics.duplicate(true)


func get_field_preload_metrics() -> Dictionary:
	var result := _field_preload_metrics.duplicate(true)
	result["active_requests"] = _field_active_requests.size()
	result["draining_requests"] = _field_drain_paths.size()
	return result


func _abandon_field_requests(paths: Array) -> void:
	for path: String in paths: _field_drain_paths.append(path)
	paths.clear() # The owning local array is emptied too, preventing duplicate drain.
	if is_inside_tree(): set_process(true)


func _drain_field_requests() -> void:
	for index in range(_field_drain_paths.size() - 1, -1, -1):
		var path := _field_drain_paths[index]
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS: continue
		_field_drain_paths.remove_at(index)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			ResourceLoader.load_threaded_get(path) # Completed abandoned request: discard only.


func _fail_transition(message: String) -> void:
	SceneRouter.rollback_resident_room_install()
	_abandon_field_requests(_field_active_requests)
	set_process(not _field_drain_paths.is_empty())
	_transition_active = false
	_finishing = false
	_field_preloaded.clear()
	_field_preparation_token = 0
	_release_source_field(true)
	_end_field_validation()
	var retry_path := _loading_path
	var retry_kind := _transition_kind
	var retry_context := _transition_context.duplicate(true)
	_screen.show_failure(message, func() -> void:
		transition_to(retry_path, retry_kind, retry_context)
	)


func _reset_transition() -> void:
	_abandon_field_requests(_field_active_requests)
	_end_field_validation()
	_transition_active = false
	_finishing = false
	_loading_path = ""
	_transition_context.clear()
	_progress_base = 0.0
	_progress_span = 1.0
	_field_preloaded.clear()
	_field_preparation_token = 0
	_release_source_field(false)
	set_process(not _field_drain_paths.is_empty())


func _end_field_validation() -> void:
	var token := int(_transition_context.get("city_validation_token",0))
	var router: Node = get_node_or_null("/root/SceneRouter")
	if token > 0 and router != null: router.call("end_field_transition_validation", token)
	_transition_context.erase("city_validation_token")


func _delayed_external_hide(token: int) -> void:
	await get_tree().create_timer(1.2, true, false, true).timeout
	if token != _external_token or _transition_active or _external_active or _screen == null:
		return
	_handoff_progress = 0.0
	await _screen.hide_screen()


func _ensure_screen() -> void:
	if _screen != null and is_instance_valid(_screen):
		return
	_screen = LOADING_SCREEN_SCENE.instantiate() as LoadingScreen
	add_child(_screen)


func _choose_card(kind: StringName) -> Dictionary:
	var candidates: Array[Dictionary] = []
	for card: Dictionary in CARDS:
		var contexts: Array = card.get("contexts", [])
		if kind in contexts:
			candidates.append(card)
	if candidates.is_empty():
		candidates = CARDS.duplicate(true)
	if candidates.size() > 1:
		var filtered: Array[Dictionary] = []
		for card: Dictionary in candidates:
			if StringName(card.get("id", &"")) != _last_card_id:
				filtered.append(card)
		if not filtered.is_empty():
			candidates = filtered
	var selected := candidates[_rng.randi_range(0, candidates.size() - 1)]
	_last_card_id = StringName(selected.get("id", &""))
	return selected


func _stage_text(kind: StringName, ratio: float) -> String:
	if ratio < 0.2:
		return "正在整理行囊……" if kind != &"battle_enter" else "正在排布战阵……"
	if ratio < 0.75:
		return "正在铺开江湖画卷……" if kind != &"battle_enter" else "正在校验招式与敌阵……"
	return "正在点亮场景细节……"

## Runtime I/O failure uses the existing Loading failure/retry surface. It cannot
## hide or replace an already-active successor transition.
func show_world_stream_failure(field: Node, scene_id: StringName, spawn: Vector2) -> void:
	if _transition_active or _external_active or get_tree().current_scene!=field: return
	if scene_id!=&"world_map_jianghu": return
	_external_token+=1 # Invalidate any earlier delayed external hide.
	var owner: WeakRef=weakref(field)
	show_external_failure("地图建筑资源读取失败，请重试。",func() -> void:
		var current: Node=owner.get_ref()
		if not is_instance_valid(current) or get_tree().current_scene!=current or _transition_active or _external_active: return
		SceneRouter.go_field_smart(scene_id,spawn)
	)

