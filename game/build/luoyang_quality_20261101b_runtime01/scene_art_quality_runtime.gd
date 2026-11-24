extends Node
## Independent additive presentation host. Never edits an old source receipt,
## compiled table, Scene/Resource, physics, portal, actor position or save.
const HOME := "res://build/luoyang_quality_20261101b_runtime01/"
const SELF := HOME + "scene_art_quality_runtime.gd"
const MANIFEST := HOME + "source_pins_READY.json"
const FIELD := "res://build/luoyang_regions_20261027d_source01/region_field.gd"
const FIELD_SHA := "b6a8ce785d74d22a46fa680afcf0c365e15a0e83a887ccd8a40fffab875118cd"
const REGION_MANIFEST := "res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json"
const REGION_MANIFEST_SHA := "a3a8de318f0bc5a3fd130cb5248e5110785ea15fca127e883165ccad69a02c79"
const GROUND := "res://build/luoyang_quality_20261101b_ground01/ground_visual.gd"
const SEATED := "res://build/luoyang_quality_20261101b_seated01/live_seated_view.gd"
const DECOR := "res://build/luoyang_quality_20261101b_decor01/live_decor_view.gd"
const IDS := ["luoyang_estate_region_27d", "luoyang_civic_market_region_27d", "luoyang_temple_region_27d", "yihongyuan27n_interior"]
const BIN_SHAS := {
	"luoyang_estate_region_27d": "42f767179381ee82256c05ad1e248e3447b1cfd77a89c71d5df33aa2bc659cca",
	"luoyang_civic_market_region_27d": "87490133576f5e664ac3e3f51e07c5c149131f3326710491d2597caf2db1d5c0",
	"luoyang_temple_region_27d": "0e5dce86183a20ead453aa3e5c08907b556540123cb4c25ca2f6d88152c1fb90",
	"yihongyuan27n_interior": "396aec45e0286687122e9dade5a94f15dd2fd026a5959a6cdbb898ec1fdf02fc",
}
var _pins: Dictionary = {}
var _bindings: Dictionary = {}
var _manifest_sha := ""
var _decor_enabled := false
var _ready_sources := false
var _clock := 0.0
var _seen: Dictionary = {}
var _last_error := ""
var _attached_count := 0

func _ready() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not raw is Dictionary or raw.get("schema") != "SCENE_ART_QUALITY_20261101B_INDEPENDENT_V1" or raw.get("ready") != true:
		_reject("QUALITY31B_ROOT_FREEZE_REQUIRED"); set_process(false); return
	_pins = raw.get("source_pins", {}).duplicate(true)
	_bindings = raw.get("region_bindings", {}).duplicate(true)
	_decor_enabled = raw.get("decor_enabled", false) == true
	if raw.get("ground_helper") != GROUND or raw.get("seated_helper") != SEATED or raw.get("decor_helper") != DECOR or _pins.get(FIELD) != FIELD_SHA or _pins.get(REGION_MANIFEST) != REGION_MANIFEST_SHA or _bindings.size() != 4 or not _pins.has(SELF) or not _pins.has("res://project.godot"):
		_reject("QUALITY31B_FREEZE_DOMAIN"); set_process(false); return
	for path: String in [GROUND, SEATED]:
		if not _pins.has(path): _reject("QUALITY31B_HELPER_MISSING:" + path); set_process(false); return
	if _decor_enabled and not _pins.has(DECOR): _reject("QUALITY31B_DECOR_MISSING"); set_process(false); return
	for id: String in IDS:
		var binding: Dictionary = _bindings.get(id, {})
		if binding.get("sha256") != BIN_SHAS[id] or _pins.get(String(binding.get("path", ""))) != BIN_SHAS[id]:
			_reject("QUALITY31B_BIN_DOMAIN:" + id); set_process(false); return
	_manifest_sha = FileAccess.get_sha256(MANIFEST)
	_ready_sources = _sources_match()
	if not _ready_sources: _reject("QUALITY31B_INITIAL_SOURCE_SHA"); set_process(false)

func _sources_match() -> bool:
	if _pins.is_empty() or FileAccess.get_sha256(MANIFEST) != _manifest_sha: return false
	# This feature owns one autoload registration, not the whole project file.
	# Root's freeze/QA/final guard still check the exact one-line project SHA for
	# this change; later unrelated project settings must not disable the views.
	if ProjectSettings.get_setting("autoload/SceneArtQualityRuntime", "") != "*" + SELF: return false
	for path: String in _pins:
		if path == "res://project.godot": continue
		if not path.begins_with("res://") or ".." in path or not _pins[path] is String or String(_pins[path]).length() != 64 or FileAccess.get_sha256(path) != _pins[path]: return false
	return true

func _reject(reason: String) -> void:
	_last_error = reason
	push_error("[SceneArtQuality31b] " + reason)

func _process(delta: float) -> void:
	_clock += delta
	if _clock < 0.25: return
	_clock = fmod(_clock, 0.25)
	for key: int in _seen.keys():
		var reference: WeakRef = _seen[key].get("field") as WeakRef
		if reference == null or reference.get_ref() == null: _seen.erase(key)
	var field: Node = get_tree().current_scene
	if not is_instance_valid(field) or field.is_queued_for_deletion() or field.get_script() == null or field.get_script().resource_path != FIELD: return
	if _seen.has(field.get_instance_id()): return
	var loading: Node = get_node_or_null("/root/LoadingManager")
	if loading == null or loading.get("_transition_active") == true or loading.get("_external_active") == true: return
	if field.get("_field_loading_complete") != true or field.get("_field_loading_failed") == true or field.get("_scene_rebuilding") == true: return
	var scene: SceneScript = field.get("_current_scene") as SceneScript
	var region: Variant = field.get("_region")
	if scene == null or not region is Dictionary or String(region.get("id", "")) not in IDS or String(scene.scene_id) != String(region.id): return
	var owner: RefCounted = field.get("_region_owner") as RefCounted
	if owner == null or owner.call("receipt").get("phase") != "LIVE": return
	# Only once for each actual Field instance, after both loading owners release.
	var status: Dictionary = {"field": weakref(field), "region_id": String(region.id), "ok": false}
	_seen[field.get_instance_id()] = status
	if not _sources_match(): _reject("QUALITY31B_LIVE_SOURCE_SHA"); return
	var binding: Dictionary = _bindings[String(region.id)]
	if owner.call("receipt").get("source_first", {}).get(String(binding.path)) != binding.sha256 or owner.call("revalidate_boundary", field, scene, region) != true:
		_reject("QUALITY31B_ORIGINAL_LIVE_BOUNDARY"); return
	var receipt_before: PackedByteArray = var_to_bytes(owner.call("receipt"))
	var compiled_before: PackedByteArray = var_to_bytes(region)
	var result: Dictionary
	if String(region.id) == "yihongyuan27n_interior":
		var seated: GDScript = load(SEATED) as GDScript
		if seated == null or not seated.has_method("attach"): _reject("QUALITY31B_SEATED_API"); return
		result = seated.call("attach", field)
		status["seated"] = result.duplicate(true)
		if not result.get("ok", false): _reject("QUALITY31B_SEATED:" + String(result.get("error", "UNKNOWN"))); return
		if _decor_enabled and region.get("interior_identity_20261107","") != "YIHONG_NATIVE_ROOM_20261107_V1":
			var decor: GDScript = load(DECOR) as GDScript
			if decor == null or not decor.has_method("attach"): _reject("QUALITY31B_DECOR_API"); return
			result = decor.call("attach", field)
			status["decor"] = result.duplicate(true)
		if result.get("ok", false):
			var mini: Node = field.get("_world_travel_minimap")
			if is_instance_valid(mini) and mini.get_script() != null and mini.get_script().resource_path == "res://build/luoyang_garden_city_minimap_20261030b_system01/city_minimap.gd": mini.call("_build_plan")
	else:
		var ground: GDScript = load(GROUND) as GDScript
		if ground == null or not ground.has_method("attach_view"): _reject("QUALITY31B_GROUND_API"); return
		result = ground.call("attach_view", field, _pins)
		status["ground"] = result.duplicate(true)
	if not result.get("ok", false): _reject("QUALITY31B_ATTACH:" + String(result.get("error", "UNKNOWN"))); return
	if receipt_before != var_to_bytes(owner.call("receipt")) or compiled_before != var_to_bytes(region) or owner.call("revalidate_boundary", field, scene, region) != true or not _sources_match():
		_reject("QUALITY31B_FINAL_ORIGINAL_RECEIPT_COMPILED_OR_SOURCE_CHANGED"); return
	status["ok"] = true
	status["original_receipt_identical"] = true
	status["compiled_identical"] = true
	status["decor_enabled"] = _decor_enabled
	field.set_meta("scene_art_quality31b", {"ok": true, "region_id": region.id, "original_receipt_identical": true, "compiled_identical": true, "decor_enabled": _decor_enabled})
	_attached_count += 1
	print("[SceneArtQuality31b] attached ", region.id, " old receipt/compiled identical")

func get_debug_state() -> Dictionary:
	var entries: Array[Dictionary] = []
	for status: Dictionary in _seen.values():
		var copy := status.duplicate(true); copy.erase("field"); entries.append(copy)
	return {"ready": _ready_sources, "last_error": _last_error, "attached_count": _attached_count, "decor_enabled": _decor_enabled, "source_manifest_sha256": _manifest_sha, "entries": entries, "poll_seconds": 0.25, "save_access": false}
