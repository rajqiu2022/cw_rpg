extends SceneTree

var failures := 0
var checks := 0
var changes := 0
const NPC_SCENE := preload("res://scenes/npc_node.tscn")
const CATALOG := preload("res://data/npcs/npc_catalog.tres")

func _initialize() -> void:
	call_deferred("_run")

func _check(passed: bool, label: String) -> void:
	checks += 1
	if not passed:
		failures += 1
		push_error("[FAIL] " + label)

func _run() -> void:
	await process_frame
	var saves_before := _save_snapshot()
	await _audio_checks()
	await _npc_checks()
	await _router_audio_checks()
	await _field_capture(&"linxi_village_scrollmap", Vector2(0.825, 0.56))
	await _field_capture(&"openworld_jinling_city", Vector2(0.63, 0.62))
	_check(_save_snapshot() == saves_before, "all five user save slots and backups remain unchanged")
	print("[NpcScaleBgmContinuity] checks=%d failures=%d" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _save_snapshot() -> Dictionary:
	var snapshot := {}
	var saves := root.get_node("SaveManager")
	for slot in range(5):
		for path: String in [saves.slot_path(slot), saves.slot_backup_path(slot)]:
			snapshot[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	return snapshot

func _audio_checks() -> void:
	var manager := root.get_node("AudioManager")
	root.get_node("EventBus").bgm_changed.connect(func(_path: String): changes += 1)
	manager.play_bgm("res://art/audio/bgm/bgm_village_day_v4.wav", 0.06, "linxi_village_center")
	await create_timer(0.20).timeout
	var original: AudioStreamPlayer = manager.bgm_player
	original.seek(17.0)
	await create_timer(0.10).timeout
	var before := original.get_playback_position()
	var change_count := changes
	manager.ensure_bgm_for_scene(&"linxi_village_scrollmap")
	await create_timer(0.14).timeout
	_check(manager.bgm_player == original, "same song across actual scene definitions retains player")
	_check(changes == change_count, "same song scene switch does not emit a track change")
	_check(original.get_playback_position() >= before, "same song scene switch preserves playback position")
	print("[BgmContinuity] actual-scenes before=%.3f after=%.3f player=%d" % [before, original.get_playback_position(), original.get_instance_id()])
	manager.play_bgm("res://art/audio/bgm/../bgm/bgm_village_day_v4.wav", 0.06, "room")
	_check(manager.bgm_player == original and changes == change_count, "equivalent normalized path retains song")
	var uid := ResourceLoader.get_resource_uid("res://art/audio/bgm/bgm_village_day_v4.wav")
	if uid != ResourceUID.INVALID_ID:
		manager.play_bgm(ResourceUID.id_to_text(uid), 0.06, "uid-alias")
		_check(manager.bgm_player == original and changes == change_count, "UID alias retains song")
	manager.stop_bgm(0.20)
	await create_timer(0.04).timeout
	manager.play_bgm("res://art/audio/bgm/bgm_village_day_v4.wav", 0.06, "same-song-return")
	await create_timer(0.25).timeout
	_check(manager.bgm_player == original and original.playing, "same song request cancels an in-flight stop without restart")
	_check(original.get_playback_position() > before, "cancelled fade retains advancing playhead")
	manager.pause_for_platform()
	var paused := original.get_playback_position()
	manager.play_bgm("res://art/audio/bgm/bgm_village_day_v4.wav", 0.06, "paused-room")
	_check(manager.bgm_player == original and original.stream_paused, "same song request preserves platform pause")
	manager.resume_after_platform()
	await create_timer(0.10).timeout
	_check(original.get_playback_position() >= paused, "platform resume preserves playhead")
	manager.play_bgm("res://art/audio/bgm/bgm_battle_mountain_v4.wav", 0.06)
	_check(manager.bgm_player != original, "different song uses crossfade incoming player")
	await create_timer(0.18).timeout
	_check(not original.playing and manager.bgm_player.playing, "different track retires outgoing player normally")
	manager.stop_bgm(0.06)
	await create_timer(0.10).timeout
	_check(manager.get_current_bgm() == "" and not manager.bgm_player.playing, "explicit stop still works")

func _npc_checks() -> void:
	var audited := 0
	for file: String in DirAccess.get_files_at("res://data/scenes"):
		if not file.ends_with(".tres"):
			continue
		var scene := load("res://data/scenes/" + file) as SceneScript
		if scene == null:
			continue
		for data: Dictionary in scene.npcs:
			var path := String(data.get("sprite_path", ""))
			var scale := float(data.get("scale", 0.08))
			var profile: NPCProfile = CATALOG.find(StringName(data.get("npc_id", "")), scene.scene_id)
			if profile != null:
				if not profile.sprite_path.is_empty(): path = profile.sprite_path
				if profile.sprite_scale > 0.0: scale = profile.sprite_scale
			var relevant := false
			for family: String in NPCNode.SMALL_ADULT_FAMILIES:
				if path.get_file().begins_with(family): relevant = true
			if not relevant:
				continue
			var npc: NPCNode = NPC_SCENE.instantiate()
			npc.sprite_path = path
			npc.sprite_scale = scale * scene.npc_visual_scale
			npc.npc_id = String(data.get("npc_id", ""))
			npc.walk_sprite_path = String(data.get("walk_sprite_path", ""))
			npc.conversation_sprite_paths = Dictionary(data.get("conversation_sprite_paths", {}))
			root.add_child(npc)
			await process_frame
			npc.apply_runtime_idle_texture(npc.sprite.texture)
			var visible: Rect2i = npc._visible_bounds(npc.sprite.texture)
			var expected := NPCNode.CALIBRATED_ADULT_HEIGHT * npc.sprite_scale
			_check(is_equal_approx(visible.size.y * npc.sprite.scale.y, expected), "%s/%s visible adult height" % [file, npc.npc_id])
			var expected_legacy_foot := npc.sprite.texture.get_height() * npc.sprite_scale * 0.45
			_check(is_equal_approx(npc.get_depth_sort_y(), expected_legacy_foot), "legacy foot plane preserved: " + npc.npc_id)
			npc.set_ground_anchored(true)
			_check(is_zero_approx(npc.get_depth_sort_y()), "explicit foot anchor remains fixed: " + npc.npc_id)
			var collider := npc.get("_body_collider") as StaticBody2D
			var shape := collider.get_child(0) as CollisionShape2D
			var rectangle := shape.shape as RectangleShape2D
			_check(is_equal_approx(rectangle.size.y, npc.sprite.texture.get_height() * npc.sprite_scale * 0.18), "physical footprint not enlarged: " + npc.npc_id)
			for facing: Vector2 in [Vector2.DOWN, Vector2.UP, Vector2.LEFT, Vector2.RIGHT]:
				if npc.has_conversation_facing(npc._facing_from_vector(facing)):
					npc.begin_conversation(npc.global_position + facing * 80.0)
					visible = npc._visible_bounds(npc.sprite.texture)
					_check(is_equal_approx(visible.size.y * npc.sprite.scale.y, expected), "conversation visible height remains fixed: " + npc.npc_id)
					_check(is_zero_approx(npc.get_depth_sort_y()), "conversation foot remains fixed: " + npc.npc_id)
				npc.end_conversation()
			audited += 1
			npc.free()
	print("[NpcScale] audited shared guard/waiter entries=%d" % audited)
	_check(audited >= 12, "shared family audit covers more than the two reported actors")

func _router_audio_checks() -> void:
	var manager := root.get_node("AudioManager")
	var router := root.get_node("SceneRouter")
	router.go_field_smart(&"linxi_village_center", Vector2(0.50, 0.65))
	await _wait_for_field(&"linxi_village_center")
	await create_timer(0.20).timeout
	var original: AudioStreamPlayer = manager.bgm_player
	original.seek(17.0)
	await create_timer(0.12).timeout
	var before := original.get_playback_position()
	var track_changes := changes
	router.go_field_smart(&"linxi_village_scrollmap", Vector2(0.825, 0.56))
	await _wait_for_field(&"linxi_village_scrollmap")
	await create_timer(0.12).timeout
	_check(manager.bgm_player == original and original.playing, "actual SceneRouter/loading transition keeps same BGM player alive")
	_check(changes == track_changes, "actual Field exit/entry never issues same-song track change")
	_check(original.get_playback_position() >= before, "actual Field transition preserves song playback position")
	print("[BgmRouterContinuity] center->south before=%.3f after=%.3f changes=%d player=%d" % [before, original.get_playback_position(), changes-track_changes, original.get_instance_id()])

func _wait_for_field(scene_id: StringName) -> void:
	for tick in range(180):
		await process_frame
		if current_scene != null and current_scene.get("_current_scene") != null and current_scene.get("_current_scene").scene_id == scene_id and not root.get_node("LoadingManager").get("_transition_active"):
			return
	_check(false, "Field transition completed: " + String(scene_id))

func _field_capture(scene_id: StringName, foot: Vector2) -> void:
	root.get_node("SceneRouter").go_field_smart(scene_id, foot)
	await _wait_for_field(scene_id)
	var field := current_scene
	_check(field != null and field.get("_current_scene") != null and field.get("_current_scene").scene_id == scene_id, "actual Field loads: " + String(scene_id))
	if field == null: return
	for tick in range(15): await process_frame
	for npc: NPCNode in field.get("_npc_nodes"):
		if npc.npc_id in ["linxi_south_farmer", "linxi_south_apprentice", "linxi_south_veteran", "jinling_water_patrol"]:
			var measured := npc._visible_bounds(npc.sprite.texture)
			print("[NpcScaleRuntime] %s effective_height=%.3f scale=%.4f depth_foot=%.3f" % [npc.npc_id, measured.size.y * npc.sprite.scale.y, npc.sprite.scale.y, npc.get_depth_sort_y()])
		if npc.get("_calibrate_adult_body"):
			var bounds := npc._visible_bounds(npc.sprite.texture)
			_check(is_equal_approx(bounds.size.y * npc.sprite.scale.y, NPCNode.CALIBRATED_ADULT_HEIGHT * npc.sprite_scale), "Field final sprite override preserves adult scale: " + npc.npc_id)
	var gm := root.get_node_or_null("GMConsole")
	if gm != null:
		for child in gm.get_children():
			if child is CanvasLayer: child.visible = false
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var output := "res://build/npc_scale_%s_20261001.png" % String(scene_id)
		root.get_texture().get_image().save_png(output)
		print("[NpcScaleCapture] " + output)
