extends "res://scripts/dev/run_luoyang_layered_interior_v2.gd"
## LIMITED real Field mechanisms; NOT original city storyline or art approval.
const PROBE := preload("res://tests/helpers/luoyang_layered_interior_v2_probe.gd")
var checks := 0
var failures: Array[String] = []
var qa_probe: RefCounted
var output := ""
var result: Dictionary = {"scope": "LIMITED_LUOYANG_V2_FIELD_MECHANISMS", "art_approved": false, "production_adopted": false, "original_storyline_run": false, "screenshots": [], "actions": [], "NOT_RUN": ["original gate/yamen/market storyline", "rewards", "shops", "bounty execution / noncurrent flag states", "production routing", "world64", "visual approval", "complete continuous-domain alpha absence proof", "all animation states"]}
var catalog_before: Dictionary = {}
var protected_before: Dictionary = {}
var slot_before: Variant
var saves_before: Dictionary = {}

func _start() -> void:
	output = "res://build/luoyang_layered_interior_v2_qa/run_%d_%d/" % [int(Time.get_unix_time_from_system()), Time.get_ticks_msec()]
	if DirAccess.dir_exists_absolute(output):
		quit(1)
		return
	_check(DirAccess.make_dir_recursive_absolute(output) == OK, "unique test-owned evidence directory, no overwrite")
	result["executing_script"] = get_script().resource_path
	result["executing_script_sha256"] = FileAccess.get_sha256(get_script().resource_path)
	result["start_utc_unix"] = Time.get_unix_time_from_system()
	result["historical_evidence_not_inherited"] = {"v1_retry2_main_sha256": "73569029AFC73B0D76BFDC43FA0E3891A774BECF12F2B529D14D6E8FC9A3A83C", "v1_retry2_probe_sha256": "7368020796DA1541C9ACEA464613AD40C6591E278DDF6D9F34506C506002304E", "v2_requires_new_actual_execution": true}
	result["engine_pid"] = OS.get_process_id()
	var dependencies: Dictionary = {}
	for path: String in ["res://scripts/dev/run_luoyang_layered_interior_v2.gd", "res://scripts/dev/luoyang_layered_interior_v2_contract.gd", "res://scripts/dev/luoyang_layered_interior_v2_field.gd", "res://tests/helpers/luoyang_layered_interior_v2_probe.gd", "res://tests/helpers/v15_input_driver.gd", "res://tests/helpers/v15_geometry_oracle.gd"]: dependencies[path] = FileAccess.get_sha256(path)
	result["actual_dependencies_sha256"] = dependencies
	result["gpu"] = DisplayServer.get_name() != "headless"
	_check("--luoyang-layered-v2-preview" in OS.get_cmdline_user_args(), "explicit isolated preview opt-in, never production adoption")
	_check(not bool(result.gpu) or "--qa-gpu-approved" in OS.get_cmdline_user_args(), "GPU only explicit root-approved serial window")
	if not failures.is_empty():
		await _finish()
		return
	# Fresh actual filenames/mtime: concurrent user saves are evidence, not reset.
	saves_before = _save_files()
	result["normal_save_timestamp_precision"] = "Godot mtime is seconds; producer must separately compare fresh filesystem UTCticks before/after. Historical saved baseline is not current runtime evidence."
	_check(saves_before.size() == 6, "fresh six actual normal save files are observed, never restored from historical baseline")
	slot_before = root.get_node("SaveManager").get("active_slot")
	result["normal_saves_before"] = saves_before
	_check(CONTRACT.MANIFEST_SHA.length() == 64, "final V2 manifest exact SHA frozen; pending is NOT_READY, no fallback to first failed capture")
	if not failures.is_empty():
		await _finish()
		return
	_check(source_check(), "actual new runner source gate and independent candidate layout duplication")
	if contract == null or not failures.is_empty():
		await _finish()
		return
	protected_before = protected_state()
	_preflight()
	if not failures.is_empty():
		await _finish()
		return
	_check(await start_preview(), "normal autoloads + real Field subclass start; cold navigation exact, not public-migrated")
	if not is_instance_valid(field) or not failures.is_empty():
		await _finish()
		return
	var actual_player: Node2D = field.get("_player") as Node2D
	var actual_shape: CollisionShape2D = actual_player.get_node_or_null("CollisionShape2D") as CollisionShape2D if is_instance_valid(actual_player) else null
	var actual_sprite: Sprite2D = actual_player.get("sprite") as Sprite2D if is_instance_valid(actual_player) else null
	_check(is_instance_valid(actual_player) and actual_shape != null and actual_shape.shape is RectangleShape2D and actual_shape.shape.size == Vector2(34, 24) and actual_shape.position == Vector2.ZERO and actual_sprite != null and actual_sprite.texture != null, "real normal Player/34x24 body/current texture exist; source or runner exit0 alone is never Field readiness")
	if not failures.is_empty():
		await _finish()
		return
	qa_probe = PROBE.new()
	_check(qa_probe.configure(self, field, contract.manifest, _check, _capture), "independent original PNG / solids oracle ready")
	if failures.is_empty():
		await _capture("entry_adult_scale")
		await qa_probe.run_routes()
		await qa_probe.run_objects()
		await _actions()
		result["mechanisms"] = qa_probe.data.duplicate(true)
	result["probe_state"] = get_probe_state()
	_check(protected_state() == protected_before, "entire coldNav/payloads/flags/gold/stats/party/Inventory/Quest/Bounty preserved, no reset hides mutation")
	_check(contract.canonical_unchanged(), "original four city resources STORAGE unchanged")
	await _finish()

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		print("[LuoyangQA FAIL] " + label)
	elif checks % 50 == 0: print("[LuoyangQA progress] %d checks / %d failures" % [checks, failures.size()])

func _baseline_path(path: String) -> String:
	# Repository-relative baseline is outside res://; resolve read-only explicitly.
	return ProjectSettings.globalize_path("res://").path_join("..").path_join(path).simplify_path()

func _production_baseline() -> void:
	var path: String = _baseline_path("docs/luoyang-modular-city-trial-production-baseline-20261003.json")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(parsed is Dictionary and parsed.get("files", []).size() == 21, "actual fixed production baseline has exactly 21 reviewed paths")
	if not parsed is Dictionary: return
	var seen: Dictionary = {}
	for entry: Dictionary in parsed.get("files", []):
		var p: String = String(entry.get("path", ""))
		_check(not p.is_empty() and not seen.has(p) and String(entry.get("sha256", "")).length() == 64 and FileAccess.get_sha256(_baseline_path(p)).to_lower() == String(entry.sha256).to_lower(), "formal baseline bytes remain untouched: " + p)
		seen[p] = true

func _preflight() -> void:
	_production_baseline()
	_v1_preservation()
	_original_v2_sources()
	var m: Dictionary = contract.manifest
	_check(FileAccess.get_sha256(CONTRACT.MANIFEST_PATH).to_lower() == CONTRACT.MANIFEST_SHA, "exact frozen art manifest, no mutable status waiver")
	_check(not bool(m.get("production_approved", true)) and m.get("status") == "ART_CANDIDATE_REQUIRES_FIELD_VISUAL_QA", "visual FAIL candidate remains unapproved")
	catalog_before = (m.get("asset_sha256", {}) as Dictionary).duplicate(true)
	for path: String in catalog_before:
		_check(String(catalog_before[path]).length() == 64 and FileAccess.get_sha256(path).to_lower() == String(catalog_before[path]).to_lower(), "real catalog bytes independently bound: " + path)
	for key: String in ["ground_path", "land_path", "raw_walk_path", "walk_path"]:
		var raw: Image = Image.load_from_file(String(m[key]))
		_check(raw != null and raw.get_size() == Vector2i(3072, 2048), "original authoritative canvas dimensions: " + key)
		if raw == null: continue
		var texture: Texture2D = load(String(m[key])) as Texture2D
		var original: Image = texture.get_image() if texture != null else null
		var decoded: Image = original.duplicate() as Image if original != null else null
		if decoded != null and decoded.is_compressed(): _check(decoded.decompress() == OK, "decode independent owned texture clone")
		if decoded != null:
			raw.convert(Image.FORMAT_RGBA8)
			decoded.convert(Image.FORMAT_RGBA8)
		_check(decoded != null and raw.get_size() == decoded.get_size() and raw.get_data() == decoded.get_data(), "imported actual canvas equals raw authoritative PNG byteexact: " + key)
	var generated_sources: Dictionary = {}
	for object: Dictionary in m.objects:
		var raw: Image = Image.load_from_file(String(object.source))
		_check(raw != null and raw.get_size() == Vector2i(contract.vec(object.source_size_px)), "own original source alpha/dimensions: " + String(object.id))
		if object.has("metadata_path"):
			var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(String(object.metadata_path)))
			_check(meta is Dictionary and float(meta.get("source_min_vertex_ground_delta_m", INF)) == 0 and bool(meta.get("sourcebody_and_ground_caster_same_mesh_material_basis_support", false)), "native actual source support and same body/caster registration: " + String(object.id))
			if meta is Dictionary:
				var a: Image = Image.load_from_file(String(meta.get("sourcebody_raw", "")))
				var b: Image = Image.load_from_file(String(meta.get("sourcebody_raw_repeat", "")))
				_check(a != null and b != null and a.get_size() == b.get_size() and a.get_data() == b.get_data(), "actual native raw sourcebody/repeat bytes, not metadata success alone: " + String(object.id))
		elif String(object.get("nature", "")) == "generated_independent_architecture": generated_sources[String(object.id)] = raw
	_check(generated_sources.size() == 3, "three independent architectural source images; no baked full-city substitution")
	if generated_sources.has("south_gate"):
		var gate: Image = generated_sources.south_gate
		for p: Vector2i in [Vector2i(768, 620), Vector2i(768, 700), Vector2i(768, 860)]: _check(gate.get_pixelv(p).a == 0, "original gate hole is genuine transparent source alpha, not solid roof mask")
		_check(gate.get_pixel(768, 910).a > .12, "original stairs retain entity alpha; floor and actual structure semantics remain distinct")
	var shadow: Dictionary = m.shadow_evidence
	for prefix: String in ["on", "off"]:
		var a: Image = Image.load_from_file(String(shadow[prefix + "_path"]))
		var b: Image = Image.load_from_file(String(shadow[prefix + "_repeat_path"]))
		_check(a != null and b != null and a.get_size() == b.get_size() and a.get_data() == b.get_data(), "actual ground native " + prefix + " exact raw repeat")
	_check(m.routes.size() == 5 and not m.objects.is_empty() and m.objects.size() == contract.object_ids.size(), "five declared paths and every distinct V2 contract entity; no V1 cardinality inheritance")
	result["declared_object_ids"] = contract.object_ids.keys()
	result["declared_blocking_ids"] = contract.blocking_ids.keys()
	result["declared_route_ids"] = []
	for route: Dictionary in m.routes: result.declared_route_ids.append(String(route.id))


func _v1_preservation() -> void:
	var path := "res://build/luoyang_modular_v2_qa/preparation_baseline_20261003.json"
	_check(FileAccess.get_sha256(path).to_lower() == "12e4d90d5435a9500c9f070c52f099e5c3985a8d683a8f587b1531716ce89346", "independent pre-V2 protection baseline remains frozen")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		_check(false, "protection baseline readable")
		return
	for group: String in ["v1_asset_catalog", "v1_frozen_references"]:
		var entries: Array = parsed.get(group, [])
		_check(not entries.is_empty(), "old V1 evidence protection paths present: " + group)
		for entry: Dictionary in entries:
			var original_path: String = String(entry.get("path", ""))
			var actual_path: String = original_path if original_path.begins_with("res://") else _baseline_path(original_path)
			_check(String(entry.get("sha256", "")).length() == 64 and FileAccess.get_sha256(actual_path).to_lower() == String(entry.get("sha256", "")).to_lower(), "old V1 bytes protected, never overwritten: " + original_path)

func _original_v2_sources() -> void:
	# Literal independent raw audit identities, not values obtained from candidate.
	var references: Dictionary = {
		"notice_pavilion_v2.png": {"size": Vector2i(1536, 1024), "sha256": "523ca1084365d836ab6b687804b6a25020b464f897a764d7c7d9c6632a883ccb"},
		"street_lamp_v2.png": {"size": Vector2i(1024, 1536), "sha256": "8efad8443a667ca9d382ca96b0ef4ceea543a095b838259aaab8c01ebeb63043"},
		"goods_stall_v2.png": {"size": Vector2i(1536, 1024), "sha256": "85cfbe6b14d6aef518d33acb3c3034e07a7b26e0d3e57dc3e9c1047452d416d0"},
		"worn_bluestone_v2.png": {"size": Vector2i(1254, 1254), "sha256": "7e9c7d892f86ced04ad3b8ad293208e05d87a01afffc2729804e4469f87deb7d"},
	}
	for name: String in references:
		var ref: Dictionary = references[name]
		var raw_path: String = _baseline_path("assets/raw/scene_module/luoyang_modular_v2/" + name)
		var actual_path: String = CONTRACT.ROOT + "source/" + name
		var raw: Image = Image.load_from_file(raw_path)
		_check(raw != null and raw.get_size() == ref.size and FileAccess.get_sha256(raw_path).to_lower() == ref.sha256 and FileAccess.get_sha256(actual_path).to_lower() == ref.sha256, "actual original / runtime source PNG exact bytes and dimensions: " + name)
		if raw == null or name == "worn_bluestone_v2.png": continue
		_check(raw.get_format() == Image.FORMAT_RGBA8, "actual prop alpha channel is RGBA8, not opaque viewer RGB: " + name)
		for corner: Vector2i in [Vector2i.ZERO, Vector2i(raw.get_width() - 1, 0), raw.get_size() - Vector2i.ONE, Vector2i(0, raw.get_height() - 1)]:
			_check(raw.get_pixelv(corner).a == 0, "raw prop genuine transparent outer corner; hidden RGB is not solid alpha: " + name)
		var gaps: Array[Vector2i] = []
		if name == "notice_pavilion_v2.png": gaps = [Vector2i(500, 330), Vector2i(1000, 330), Vector2i(768, 820), Vector2i(768, 945)]
		if name == "street_lamp_v2.png": gaps = [Vector2i(550, 310), Vector2i(520, 370), Vector2i(550, 500), Vector2i(700, 900), Vector2i(425, 1510)]
		if name == "goods_stall_v2.png": gaps = [Vector2i(270, 910), Vector2i(1260, 910), Vector2i(768, 945)]
		for gap: Vector2i in gaps: _check(raw.get_pixelv(gap).a == 0, "independent source gap remains exact alpha0 without threshold rewriting: " + name + str(gap))
	# These images are original ImageGen assets, not falsely labeled CC0 models.

func _actions() -> void:
	var actor: Node2D = field.get("_player") as Node2D
	for mode: String in ["space", "mouse"]:
		var driven: Dictionary = await qa_probe.move_to(contract.gate_foot)
		_check(bool(driven.get("ok", false)), "normal input reaches real gate checkpoint for " + mode)
		if not bool(driven.get("ok", false)): continue
		var original: Vector2 = actor.position
		var count: int = (field.get("observed_actions") as Array).size()
		var click: Dictionary = {}
		if mode == "space": await qa_probe.driver.key(KEY_SPACE)
		else: click = await qa_probe.click_entity(qa_probe.prop("south_gate"))
		await qa_probe.driver.completed_actor_stage()
		var state: Dictionary = field.call("get_preview_return_state")
		var events: Array = (field.get("observed_actions") as Array).slice(count)
		_check(bool(state.get("active", false)) and actor.position.distance_to(contract.inner_foot) < .03 and qa_probe.clear(actor.position), "actual gate " + mode + " performs only local memory checkpoint movement")
		_check(_has_action(events, "enter_luoyang", "scene:ch4_s1_luoyang_yamen", mode), "normal " + mode + " gate records exact original identity/action without executing old route")
		await _capture("gate_enter_" + mode)
		count = (field.get("observed_actions") as Array).size()
		if mode == "space": await qa_probe.driver.key(KEY_SPACE)
		else:
			var exit: Node2D = _exit("lab_return")
			var marker: Sprite2D = exit.get("marker_visual") as Sprite2D if exit != null else null
			_check(marker != null, "actual local return marker exists")
			if marker != null: await qa_probe.driver.pointer(marker.get_global_transform_with_canvas().origin)
		await qa_probe.driver.completed_actor_stage()
		state = field.call("get_preview_return_state")
		_check(not bool(state.get("active", true)) and actor.position.distance_to(original) < .03 and qa_probe.clear(actor.position), "normal local reverse input returns exact original grounded foot, not authored approximate anchor")
		_check(_has_action((field.get("observed_actions") as Array).slice(count), "lab_return", "lab:return_checkpoint", mode), "reverse input is observed actual exit, not direct test teleport")
		result.actions.append({"kind": "gate_checkpoint", "mode": mode, "original": [original.x, original.y], "returned": [actor.position.x, actor.position.y], "return_state": state, "enter_events": events, "entity_click": click})
	for case: Dictionary in [{"id": "inn", "point": contract.anchors.inn, "source_id": "inn", "action": "lab:inspect_inn"}, {"id": "shop", "point": contract.anchors.shop, "source_id": "luoyang_armorer", "action": "shop:luoyang_armory"}, {"id": "notice_pavilion", "point": contract.anchors.bounty_board, "source_id": "", "action": ""}]:
		for mode: String in ["space", "mouse"]:
			var driven: Dictionary = await qa_probe.move_to(case.point)
			_check(bool(driven.get("ok", false)), "normal input reaches dry-run entity station: " + String(case.id))
			if not bool(driven.get("ok", false)): continue
			var count: int = (field.get("observed_actions") as Array).size()
			var click: Dictionary = {}
			if mode == "space": await qa_probe.driver.key(KEY_SPACE)
			else: click = await qa_probe.click_entity(qa_probe.prop(String(case.id)))
			await qa_probe.driver.completed_actor_stage()
			var events: Array = (field.get("observed_actions") as Array).slice(count)
			_check(not events.is_empty(), "normal dry-run " + mode + " entity input actually dispatches: " + String(case.id))
			if case.id == "notice_pavilion":
				for event: Dictionary in events:
					var flags: Dictionary = protected_before.flags
					var require_flag: String = String(event.get("require_flag", ""))
					var hide_flag: String = String(event.get("hide_flag", ""))
					var allowed: bool = (require_flag.is_empty() or _truthy(flags.get(require_flag))) and (hide_flag.is_empty() or not _truthy(flags.get(hide_flag)))
					_check(event.get("source_id") in ["luoyang_wanted_board", "luoyang_repeatable_bounty_board"] and bool(event.get("gate_passes", false)) == allowed, "board preserves original independent flag boundary, never clears flag to force success")
			else: _check(_has_action(events, String(case.source_id), String(case.action), mode), "exact shop / explicitly noncanonical inn identity remains dry-run")
			result.actions.append({"kind": case.id, "mode": mode, "events": events, "entity_click": click})
			await _capture(String(case.id) + "_" + mode)
	for event: Dictionary in field.get("observed_actions"):
		_check(bool(event.get("dry_run", false)) and not bool(event.get("executed", true)) and String(event.get("input_kind", "")) in ["space", "mouse"], "every observed action originates normal input and never executes production gameplay")
	_check(current_scene == field and protected_state() == protected_before, "dry-run actions never replace real Field / mutate original gameplay or cold navigation")
	await _npc_actions()

func _npc_actions() -> void:
	for node: Node in (field.get("_actor_layer") as Node).get_children():
		if not node is NPCNode: continue
		var npc: NPCNode = node as NPCNode
		var station := Vector2(INF, INF)
		for offset: Vector2 in [Vector2(60, 0), Vector2(-60, 0), Vector2(0, 60), Vector2(0, -60)]:
			if qa_probe.clear(npc.position + offset):
				station = npc.position + offset
				break
		_check(station.is_finite(), "normal NPC has independent legal interaction station: " + npc.npc_id)
		if not station.is_finite(): continue
		for mode: String in ["space", "mouse"]:
			var driven: Dictionary = await qa_probe.move_to(station)
			_check(bool(driven.get("ok", false)), "normal input reaches original NPC interaction range: " + npc.npc_id)
			if not bool(driven.get("ok", false)): continue
			var count: int = (field.get("observed_actions") as Array).size()
			var click: Dictionary = {}
			if mode == "space": await qa_probe.driver.key(KEY_SPACE)
			else: click = await qa_probe.click_entity(npc.sprite)
			await qa_probe.driver.completed_actor_stage()
			var events: Array = (field.get("observed_actions") as Array).slice(count)
			var matches := false
			for event: Dictionary in events:
				if event.get("source_id") == npc.npc_id and event.get("activation") == "npc" and event.get("input_kind") == mode and bool(event.get("dry_run", false)) and not bool(event.get("executed", true)): matches = true
			_check(matches and protected_state() == protected_before, "real NPC " + mode + " records original identity but opens no dialog/shop/spar and mutates no gameplay")
			result.actions.append({"kind": "original_npc", "npc_id": npc.npc_id, "mode": mode, "events": events, "entity_click": click, "drive": driven})
			await _capture(npc.npc_id + "_" + mode)

func _truthy(value: Variant) -> bool:
	if value == null: return false
	if value is bool: return value
	if value is int: return value != 0
	if value is String: return not value.is_empty()
	return true

func _has_action(events: Array, id: String, action: String, mode: String) -> bool:
	for event: Dictionary in events:
		if event.get("source_id") == id and event.get("action") == action and event.get("input_kind") == mode and bool(event.get("dry_run", false)) and not bool(event.get("executed", true)): return true
	return false

func _exit(id: String) -> Node2D:
	for node: Node2D in field.get("_exit_nodes"):
		var data: Dictionary = node.get_meta("lab_portal", {})
		if data.get("id") == id: return node
	return null

func _save_files() -> Dictionary:
	var dir: DirAccess = DirAccess.open("user://")
	var files: Dictionary = {}
	if dir == null: return files
	for name: String in dir.get_files():
		if name.begins_with("save_") and (name.ends_with(".json") or name.ends_with(".json.bak") or name.ends_with(".json.tmp")):
			var path: String = "user://" + name
			var handle: FileAccess = FileAccess.open(path, FileAccess.READ)
			files[path] = {"sha256": FileAccess.get_sha256(path), "mtime_seconds": FileAccess.get_modified_time(path), "bytes": handle.get_length() if handle != null else -1}
			if handle != null: handle.close()
	return files

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	_check(current_scene == field and is_instance_valid(field), "screenshot is actual live Field, not software composition")
	if not is_instance_valid(field): return
	field.call("_snap_camera_to_player")
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var path: String = output + label + ".png"
	_check(image != null and image.get_size() == Vector2i(1920, 1080), "actual GPU viewport is full 1920x1080")
	if image == null: return
	_check(image.save_png(path) == OK and FileAccess.get_sha256(path).length() == 64, "actual raw screenshot persisted: " + label)
	result.screenshots.append({"path": path, "sha256": FileAccess.get_sha256(path), "label": label, "visual_verdict": "NOT_REVIEWED"})

func _write_json(path: String, value: Dictionary) -> bool:
	if FileAccess.file_exists(path): return false
	var encoded: String = JSON.stringify(value, "\t")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(encoded)
	file.flush()
	var ok: bool = file.get_error() == OK
	file.close()
	return ok and FileAccess.get_file_as_string(path) == encoded and JSON.parse_string(FileAccess.get_file_as_string(path)) == JSON.parse_string(encoded)

func _finish() -> void:
	if contract != null:
		if not protected_before.is_empty(): _check(protected_state() == protected_before, "before-cleanup protected snapshot remains exact; no mutation rollback")
		restore_preview_state()
		_production_baseline()
	_v1_preservation()
	for path: String in catalog_before: _check(FileAccess.get_sha256(path).to_lower() == String(catalog_before[path]).to_lower(), "test did not alter any captured asset/source bytes: " + path)
	result["normal_saves_after_behaviors"] = _save_files()
	_check(_save_files() == saves_before and root.get_node("SaveManager").get("active_slot") == slot_before, "fresh real normal saves SHA+mtime and active slot unchanged after behaviors")
	var field_ref: WeakRef = weakref(field) if is_instance_valid(field) else null
	if qa_probe != null: qa_probe.release()
	qa_probe = null
	if is_instance_valid(field):
		current_scene = null
		field.queue_free()
	field = null
	contract = null
	for tick in 8:
		await process_frame
		await physics_frame
	_check(field_ref == null or field_ref.get_ref() == null, "test-owned Field/normal actor naturally released; no live debug Node evidence")
	var audio: Node = root.get_node_or_null("AudioManager")
	if audio != null:
		audio.call("stop_bgm", 0.0)
		audio.call("stop_ambience", 0.0)
		audio.call("stop_music_sting")
		audio.call("stop_all_sfx")
		audio.call("stop_voice")
		audio.call("stop_dialog_audio")
	var cursor: Node = root.get_node_or_null("CursorManager")
	var cursor_refs: Array[WeakRef] = []
	if cursor != null:
		for key: String in ["_arrow", "_hand", "_wait"]:
			if cursor.get(key) is Resource: cursor_refs.append(weakref(cursor.get(key)))
		for shape: int in [Input.CURSOR_ARROW, Input.CURSOR_POINTING_HAND, Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null, shape)
		for key: String in ["_arrow", "_hand", "_wait"]: cursor.set(key, null)
	await create_timer(.20).timeout
	for tick in 8: await process_frame
	for ref: WeakRef in cursor_refs: _check(ref.get_ref() == null, "exit-only cursor texture naturally released, runtime cursor not changed during behaviors")
	result["normal_saves_after_cleanup"] = _save_files()
	_check(_save_files() == saves_before and root.get_node("SaveManager").get("active_slot") == slot_before, "normal saves remain exact after cleanup; user writes would be reported, not erased")
	result["checks"] = checks
	result["failures"] = failures.size()
	result["failure_labels"] = failures
	result["completed"] = true
	result["end_utc_unix"] = Time.get_unix_time_from_system()
	if not _write_json(output + "result.json", result):
		_check(false, "evidence write/flush/byte/readback failed closed")
	print("[LuoyangQA] %d checks / %d failures; scope LIMITED; art NOT_APPROVED; evidence %s" % [checks, failures.size(), output])
	quit(0 if failures.is_empty() else 1)
