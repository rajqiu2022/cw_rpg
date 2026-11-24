extends SceneTree
## Actual published-layout/source + independent RAW_ORACLE static predicates.
## Runtime Sprite lookup fixtures below are SYNTHETIC, NOT ordinary Field/input,
## roof/wall/Physics/visual/RELEASE acceptance. Nothing in production is written.
const ADAPTER_PATH: String = "res://tests/helpers/joint_v15_release_world_prepared_phase.gd"
const ADAPTER_SHA: String = "00120ad24c7ff1617ee7518d0a8e28223430d286c53c05af96212bffdccfdfd7"
const RAW = preload("res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd")
const SOURCE_PATH: String = "res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST_PATH: String = "res://art/maps/world_map_v15_complete_v9c/art_contract.json"
const LAYOUT_PATH: String = "res://data/maps/world_map_jianghu_layout_v15.tres"
const SCENE_PATH: String = "res://data/scenes/world_map_jianghu_v15.tres"
const PINS: Dictionary = {
	ADAPTER_PATH:ADAPTER_SHA,
	"res://tests/helpers/joint_v15_v9c_world_prepared_phase.gd":"16a66f74eba277c9dcf7c1a6801bb5183d0fedf363a3e6fc3805bc41e7474970",
	SOURCE_PATH:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
	MANIFEST_PATH:"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
	LAYOUT_PATH:"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072",
	SCENE_PATH:"31c5034e44092f146879e45715b97425c6e899e8ef1c375c94f03b2a35fc9065",
	"res://tests/helpers/joint_v15_v9c_world_raw_oracle.gd":"7628d404d7587dfd885937ad1e26ac6a06f4e48ca53c273ccd8d5f1aee5db9db",
	"res://scripts/field/field_walkable_controller.gd":"b3301d6064e332e519b0fc3b4daed880ec3d77d98f2c744933b5d7077b9eb8ef"}
class Subject:
	extends "res://tests/helpers/joint_v15_release_world_prepared_phase.gd"
	var assertions: Array[Dictionary] = []
	func _check(ok: bool,label: String) -> void:
		checks += 1
		if not ok: failures += 1
		assertions.append({"ok":ok,"label":label})

class SyntheticField:
	extends Node
	var _scene_object_nodes: Array[Sprite2D] = []
	var _screen_size: Vector2 = Vector2(12288,8192)

var checks: int = 0
var failures: int = 0
var records: Array[Dictionary] = []
var base_scene: SceneScript
var original_source: Dictionary
var original_manifest: Dictionary
var raw: RefCounted

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> void:
	checks += 1
	records.append({"ok":ok,"label":label})
	if not ok:
		failures += 1
		push_error("[LANDMARK ASSOCIATION UNIT] "+label)

func _hashes() -> Dictionary:
	var hashes: Dictionary = {}
	for path: String in PINS:
		hashes[path] = FileAccess.get_sha256(path).to_lower() if FileAccess.file_exists(path) else "MISSING"
	return hashes

func _subject() -> RefCounted:
	var subject: RefCounted = Subject.new()
	var scene: SceneScript = base_scene.duplicate(false) as SceneScript
	scene.map_layout = base_scene.map_layout.duplicate(true) as WalkableMapLayout
	subject.set("world",scene)
	subject.set("source",original_source.duplicate(true))
	subject.set("manifest",original_manifest.duplicate(true))
	subject.set("oracle",raw)
	return subject

func _portal(subject: RefCounted,id: String) -> Dictionary:
	for row: Dictionary in (subject.get("world") as SceneScript).map_layout.portals:
		if row.get("id") == id: return row
	return {}

func _object(subject: RefCounted,id: String) -> Dictionary:
	var compound: Variant = _portal(subject,id).get("compound_id")
	for row: Dictionary in (subject.get("world") as SceneScript).map_layout.visual_objects:
		if row.get("id") == compound: return row
	return {}

func _static(subject: RefCounted,expected: bool,label: String) -> Dictionary:
	subject.call("_static_portals_and_spacing")
	var ok: bool = int(subject.get("failures")) == 0
	_check(ok == expected,label)
	var result: Dictionary = {"case":label,"checks":subject.get("checks"),"failures":subject.get("failures"),"assertions":subject.get("assertions"),"ordinary_Field_executed":false}
	return result

func _run() -> void:
	_check(OS.get_cmdline_user_args().is_empty(),"no candidate execution/filter arguments; static and synthetic only")
	var self_sha: String = FileAccess.get_sha256(get_script().resource_path)
	var before: Dictionary = _hashes()
	_check(before == PINS,"exact source/manifest/published layout/immutable parent/Field/adapter pins")
	if failures > 0: quit(1); return
	original_source = JSON.parse_string(FileAccess.get_file_as_string(SOURCE_PATH))
	original_manifest = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	base_scene = load(SCENE_PATH) as SceneScript
	_check(base_scene != null and base_scene.map_layout != null and base_scene.map_layout.resource_path == LAYOUT_PATH,"actual published candidate external layout, not invented map")
	if failures > 0: quit(1); return
	raw = RAW.new()
	_check(raw.call("configure",base_scene.map_layout) == true,"real independent round-world-pixel/complete17 RAW_ORACLE configured")
	if failures > 0: quit(1); return
	var actual: RefCounted = _subject()
	var static_positive: Dictionary = _static(actual,true,"complete original16 destinations+17shoe and all nine core actual36center+36door predicates")
	var center_pairs: int = 0
	var door_pairs: int = 0
	var landing_checks: int = 0
	for assertion: Dictionary in actual.get("assertions"):
		if String(assertion.label).begins_with("core actual landmark logical spacing"): center_pairs += 1
		if String(assertion.label).begins_with("all36 actual core DOOR"): door_pairs += 1
		if String(assertion.label).begins_with("independent complete17 portal landing"): landing_checks += 1
	_check(center_pairs == 36 and door_pairs == 36 and landing_checks == 16,"actual full static positive exercised all36+36 spacings and16 independent landings")
	var case_records: Array[Dictionary] = []
	for id: String in Subject.DESTINATIONS:
		var baseline: RefCounted = _subject()
		var binding: Dictionary = baseline.call("_release_landmark_binding",id)
		_check(not binding.is_empty() and binding.object.id == _portal(baseline,id).compound_id and binding.object.source == binding.authored_portal.source,"exact actual source association:"+id)
		var bad: RefCounted = _subject()
		_portal(bad,id)["compound_id"] = "NOT_AUTHORED_"+id
		_check((bad.call("_release_landmark_binding",id) as Dictionary).is_empty(),"no guessed or stale portal_id fallback:"+id)
		case_records.append(_static(bad,false,"actual full static rejects wrong compound mapping:"+id))
		bad = null
		baseline = null
	for kind: String in ["missing_compound","compound_wrong_type","duplicate_runtime_portal","missing_runtime_object","duplicate_runtime_object","source_mismatch","source_sha_mismatch","texture_mismatch","role_mismatch","position_mismatch","duplicate_authored_portal","duplicate_authored_object","missing_authored_compound","catalog_texture_mismatch"]:
		var bad: RefCounted = _subject()
		var portal: Dictionary = _portal(bad,"huashan")
		var object: Dictionary = _object(bad,"huashan")
		var layout: WalkableMapLayout = (bad.get("world") as SceneScript).map_layout
		var changed_source: Dictionary = bad.get("source")
		match kind:
			"missing_compound": portal.erase("compound_id")
			"compound_wrong_type": portal["compound_id"] = 7
			"duplicate_runtime_portal": layout.portals.append(portal.duplicate(true))
			"missing_runtime_object": layout.visual_objects.erase(object)
			"duplicate_runtime_object": layout.visual_objects.append(object.duplicate(true))
			"source_mismatch": object["source"] = _object(bad,"luoyang").source
			"source_sha_mismatch": object["source_sha256"] = "0".repeat(64)
			"texture_mismatch": object["texture"] = _object(bad,"luoyang").texture
			"role_mismatch": object["role"] = "arbitrary_marker"
			"position_mismatch": object["pos"] += Vector2(.0001,0)
			"duplicate_authored_portal":
				for row: Dictionary in changed_source.portals:
					if row.id == "huashan": changed_source.portals.append(row.duplicate(true)); break
			"duplicate_authored_object":
				for row: Dictionary in changed_source.objects:
					if row.id == portal.compound_id: changed_source.objects.append(row.duplicate(true)); break
			"missing_authored_compound":
				for row: Dictionary in changed_source.portals:
					if row.id == "huashan": row.erase("compound_id")
			"catalog_texture_mismatch": (bad.get("manifest") as Dictionary).asset_sha256[object.texture] = "0".repeat(64)
		_check((bad.call("_release_landmark_binding","huashan") as Dictionary).is_empty(),"actual mapping predicate rejects:"+kind)
		case_records.append(_static(bad,false,"complete static refuses:"+kind))
		bad = null
	# Narrow regression for Variant/String guards. Only runtime portal.id is
	# direct-helper-only: immutable original static assumes String portal IDs.
	var type_cases: Array[Dictionary] = [
		{"target":"runtime_portal","key":"compound_id","value":7.0},
		{"target":"runtime_portal","key":"compound_id","value":true},
		{"target":"runtime_portal","key":"compound_id","value":null},
		{"target":"runtime_portal","key":"compound_id","value":INF},
		{"target":"runtime_portal","key":"source","value":7},
		{"target":"authored_portal","key":"source","value":7},
		{"target":"runtime_portal","key":"id","value":7},
		{"target":"authored_portal","key":"id","value":7},
		{"target":"runtime_object","key":"id","value":7},
		{"target":"authored_object","key":"id","value":7},
		{"target":"runtime_object","key":"texture","value":true},
		{"target":"runtime_object","key":"role","value":7},
		{"target":"runtime_object","key":"source_sha256","value":null}]
	for fixture: Dictionary in type_cases:
		var bad: RefCounted = _subject()
		var binding: Dictionary = bad.call("_release_landmark_binding","huashan")
		_check(not binding.is_empty(),"pristine actual association before type mutation")
		if binding.is_empty(): continue
		var target: Dictionary
		match String(fixture.target):
			"runtime_portal": target = binding.portal
			"authored_portal": target = binding.authored_portal
			"runtime_object": target = binding.object
			"authored_object": target = binding.authored_object
		var label: String = "%s.%s TYPE_%d" % [fixture.target,fixture.key,typeof(fixture.value)]
		target[fixture.key] = fixture.value
		var direct_rejected: bool = (bad.call("_release_landmark_binding","huashan") as Dictionary).is_empty()
		_check(direct_rejected,"actual helper safely rejects wrong type:"+label)
		var static_executed: bool = not (fixture.target == "runtime_portal" and fixture.key == "id")
		if static_executed:
			case_records.append(_static(bad,false,"complete static safely refuses wrong type:"+label))
		case_records.append({"case":label,"direct_helper_executed":true,"direct_helper_rejected":direct_rejected,"full_static_executed":static_executed,"ordinary_Field_executed":false})
		bad = null
	# Synthetic nodes use REAL texture resources and published positions. This
	# exercises actual lookup only, not production Field spawn/input/roof alpha.
	var synthetic: SyntheticField = SyntheticField.new()
	root.add_child(synthetic)
	actual.set("field",synthetic)
	var owned: Array[Sprite2D] = []
	for id: String in Subject.DESTINATIONS:
		var binding: Dictionary = actual.call("_release_landmark_binding",id)
		if binding.is_empty(): continue
		var object: Dictionary = binding.object
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "SceneObject_"+String(object.id)
		sprite.texture = load(String(object.texture)) as Texture2D
		sprite.position = Vector2(object.pos.x*synthetic._screen_size.x,object.pos.y*synthetic._screen_size.y)
		synthetic.add_child(sprite)
		synthetic._scene_object_nodes.append(sprite)
		owned.append(sprite)
		_check(actual.call("_actual_landmark_sprite",id) == sprite,"synthetic lookup returns unique correct actual texture/position:"+id)
	_check(owned.size() == 16,"all16 authored compounds, no proxy city markers")
	for id: String in Subject.DESTINATIONS:
		var portal: Dictionary = _portal(actual,id)
		var original_compound: Variant = portal.compound_id
		portal.compound_id = "NOT_AUTHORED_"+id
		_check(actual.call("_actual_landmark_sprite",id) == null,"synthetic actual lookup refuses wrong authored association:"+id)
		portal.compound_id = original_compound
	var original_sprite: Sprite2D = actual.call("_actual_landmark_sprite","huashan") as Sprite2D
	if original_sprite != null:
		var old_position: Vector2 = original_sprite.position
		original_sprite.position += Vector2(.25,0)
		_check(actual.call("_actual_landmark_sprite","huashan") == null,"synthetic wrong actual Sprite position rejected exactly, no epsilon")
		original_sprite.position = old_position
		var old_texture: Texture2D = original_sprite.texture
		original_sprite.texture = (actual.call("_actual_landmark_sprite","luoyang") as Sprite2D).texture
		_check(actual.call("_actual_landmark_sprite","huashan") == null,"synthetic wrong real texture source rejected")
		original_sprite.texture = old_texture
		var old_name: StringName = original_sprite.name
		original_sprite.name = "UnrelatedMarker"
		_check(actual.call("_actual_landmark_sprite","huashan") == null,"synthetic missing exact runtime name rejected")
		original_sprite.name = old_name
		synthetic._scene_object_nodes.append(original_sprite)
		_check(actual.call("_actual_landmark_sprite","huashan") == null,"duplicate exact runtime Sprite identity rejected, never first/last wins")
		synthetic._scene_object_nodes.pop_back()
		synthetic._screen_size = Vector2(1920,1080)
		_check(actual.call("_actual_landmark_sprite","huashan") == null,"wrong runtime logical-size domain rejected")
		synthetic._screen_size = Subject.SIZE
		_check(actual.call("_actual_landmark_sprite","huashan") == original_sprite,"synthetic positive restored only in owned memory")
	else: _check(false,"actual pinned huashan synthetic lookup exists for negatives")
	actual.set("field",null)
	synthetic.queue_free()
	owned.clear()
	actual = null
	for index in 8: await process_frame
	_check(raw.call("verify_sources") == true,"all consumed actual nav tile source bytes unchanged")
	raw = null
	_check(_hashes() == before and FileAccess.get_sha256(get_script().resource_path) == self_sha,"all immutable/source/layout/adapter/Field bytes unchanged")
	var output: String = "res://build/joint_world_luoyang_20261003_qa/landmark_mapping_units_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	_check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output) == OK,"unique BUILD evidence only")
	var file: FileAccess = FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file == null: failures += 1
	else:
		file.store_string(JSON.stringify({"schema":1,"scope":"ACTUAL_PUBLISHED_STATIC_AND_SYNTHETIC_SPRITE_LOOKUP_NOT_FIELD_INPUT_RELEASE","checks":checks,"failures":failures,"source_sha256":self_sha,"pins":before,"full_static_positive":static_positive,"negative_cases":case_records,"records":records,"actual_static_raw_landings":landing_checks,"actual_center_pairs":center_pairs,"actual_door_pairs":door_pairs,"synthetic_sprite_count":16,"ordinary_Field_executed":false,"input_executed":false,"release_complete":false,"formal_cutover":false,"output":output},"\t"))
		file.close()
	base_scene = null
	print("LANDMARK_MAPPING_UNITS: %d/%d; output=%s; actual static + synthetic lookup only" % [checks,failures,output])
	quit(0 if failures == 0 else 1)



