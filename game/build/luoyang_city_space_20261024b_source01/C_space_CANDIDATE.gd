extends RefCounted
const FINITE_ADAPTER_PATH := "res://build/luoyang_city_space_20261024b_source01/finite_adapter_space_CANDIDATE.gd"
const FINITE_ADAPTER_SHA := "36efa4dbc07a3fd703daefdec4c40e5b7e953895fc8bffc059728b1672de0c14"
static var _finite_adapter_handle: Variant=null
static func _finite_native_adapter() -> Variant:
	if _finite_adapter_handle!=null: return _finite_adapter_handle
	if FileAccess.get_sha256(FINITE_ADAPTER_PATH)!=FINITE_ADAPTER_SHA: return null
	var value: Variant=load(FINITE_ADAPTER_PATH)
	if not value is GDScript or value.resource_path!=FINITE_ADAPTER_PATH: return null
	_finite_adapter_handle=value;return value
## Independent modular reconstruction. Frozen V5 is validated, never edited.
## PENDING pins deliberately refuse publication/Field selection until root freezes
## actual GPU exports. This is not a visual approval or a formal activation.
const BASE = preload("res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd")
const GROUND = preload("res://scripts/city/luoyang_enclosure_v14_ground_binding.gd")
const BASE_CPU_WORKSPACE = preload("res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd")
const GATE_FORTIFICATION = preload("res://scripts/city/luoyang_gate_fortification_contract_20261013.gd")
const MARKET_ENRICHMENT = preload("res://scripts/city/luoyang_market_enrichment_contract_20261014.gd")
const MODULE_CPU = preload("res://scripts/city/luoyang_module_live_cpu_20261015.gd")
const PRECOMPUTED_BUNDLE_PATH="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const ROOT := "res://art/maps/luoyang_enclosure_v11/"
const VERSION := BASE.VERSION
const SIZE := BASE.SIZE
const BODY_SIZE := BASE.BODY_SIZE
const LEGACY_SHAS := BASE.LEGACY_SHAS
const CANDIDATE_FLAG := "--luoyang-enclosure-v11-candidate"
const REVISION_RUNTIME_PATH := "res://scripts/city/luoyang_city_revision_runtime_20261015.gd"
const REVISION_META := "city_frontage_revision_manifest_sha"
# Only live original portal coordinates are translated. These are not saved
# coordinates, arbitrary legacy points or a nearest/interpolated arrival rule.
const FRESH_AUTHORED_ROUTES := {
	"ch4_s0_luoyang_gate->ch4_s1_luoyang_yamen": {"portal":"enter_luoyang","uv":Vector2(.5,.73),"slot":"to_city_gate","foot":Vector2(1536,1860),"reverse":true},
	"ch4_s1_luoyang_yamen->ch4_s0_luoyang_gate": {"portal":"to_city_gate","uv":Vector2(.5,.325),"slot":"enter_luoyang","foot":Vector2(1536,500),"reverse":true},
	"ch4_s1_luoyang_yamen->ch4_s3_luoyang_market": {"portal":"to_south_market","uv":Vector2(.955,.355),"slot":"to_yamen_square","foot":Vector2(1536,770),"reverse":true},
	"ch4_s1_luoyang_yamen->ch4_s2_canal_docks": {"portal":"to_canal_quay","uv":Vector2(.28,.52),"slot":"to_yamen_square","foot":Vector2(260,790),"reverse":true},
	"ch4_s2_canal_docks->ch4_s1_luoyang_yamen": {"portal":"to_yamen_square","uv":Vector2(.85,.59),"slot":"to_canal_quay","foot":Vector2(2790,1350),"reverse":true},
	"ch4_s2_canal_docks->ch4_s3_luoyang_market": {"portal":"to_south_market","uv":Vector2(.955,.355),"slot":"to_canal_docks","foot":Vector2(2840,1060),"reverse":true},
	"ch4_s3_luoyang_market->ch4_s1_luoyang_yamen": {"portal":"to_yamen_square","uv":Vector2(.15,.59),"slot":"to_south_market","foot":Vector2(300,1220),"reverse":true},
	"ch4_s3_luoyang_market->ch4_s0_luoyang_gate": {"portal":"to_city_gate","uv":Vector2(.35,.69),"slot":"enter_luoyang","foot":Vector2(1536,500),"reverse":false},
	"ch4_s3_luoyang_market->ch4_s2_canal_docks": {"portal":"to_canal_docks","uv":Vector2(.28,.52),"slot":"to_south_market","foot":Vector2(260,1740),"reverse":true},
	"world_map_jianghu->ch4_s0_luoyang_gate": {"portal":"luoyang","uv":Vector2(.5,.9),"slot":"return_world","foot":Vector2(1536,1860),"reverse":false},
	"ch4_s4_ancient_temple->ch4_s3_luoyang_market": {"portal":"legacy_portal_6","uv":Vector2(.12,.75),"slot":"to_ancient_temple","foot":Vector2(1536,1860),"reverse":true,"hotspot":6},
	"ch4_s4_ancient_temple->ch4_s2_canal_docks": {"portal":"legacy_portal_7","uv":Vector2(.12,.75),"slot":"canal_world_ferry","foot":Vector2(340,1840),"reverse":false,"hotspot":7},
}
const FRESH_EXTERNAL_SOURCES := {
	"world_map_jianghu": {"scene":"res://data/scenes/world_map_jianghu.tres","scene_sha":"838380fdb05d08b4b521d92efb12a13369358090740dc5c7d4cb7c9ec6f4c015","layout":"res://data/maps/world_map_jianghu_layout_v14.tres","layout_sha":"3dfa1f251b5a5319b8cc6d6b902932fde6382470ae597c697e391252e98f2b3b"},
	"ch4_s4_ancient_temple": {"scene":"res://data/scenes/ch4_s4_ancient_temple.tres","scene_sha":"1570a4d9cfcb0508a12bfa639052db8aec11ab25634a3f5c606d19cbe2223730","layout":"res://data/maps/ch4_s4_ancient_temple_layout_v1.tres","layout_sha":"c639287b0afff4c5e2e8ad667438a5b023102a1215549610189540c8e96a26f0"},
}
# Exact identity-only WORLD local-playtest deployment. Retain the V14 binding
# above for reversible rollback; schema/existing candidate alone grants nothing.
const FRESH_WORLD_V15_SOURCE := {"scene":"res://data/scenes/world_map_jianghu.tres","scene_sha":"685876ac86cb3b739f9b51be12da60e4a125480c715da2d08f9b486d76e5a046","layout":"res://data/maps/world_map_jianghu_layout_v15.tres","layout_sha":"aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072"}
const PATCH_MANIFEST_SHAS := {
	"ch4_s0_luoyang_gate": "20cb77de45df28def34fdeee5f7c75300182ade0a1f6af338088059e47f05de1",
	"ch4_s1_luoyang_yamen": "2e1f562c429aabc89ebd38f044192e0f8dd71738147cb51b5fba4f9d6b7b50d4",
	"ch4_s2_canal_docks": "b4b06110c299bf97dad8eb7134d8b0902135b37bc7c7f4952522ce6f30a5cf23",
	"ch4_s3_luoyang_market": "ba46bfa02e4152918d6696033450bf1f0329be01318f69449a7fad7355a85c84",
}
const EXPORT_PLAN_SHAS := {
	"ch4_s0_luoyang_gate": "21b27195b4dad54ca8ff66c64e5186038f2b994ade8bdb0ae35266e87ed5bdd7",
	"ch4_s1_luoyang_yamen": "cab3991fe92315e61876374aa492177f9ac8441703ec27d757d16df97f724e6e",
	"ch4_s2_canal_docks": "2d4c2da0d2f7882efb693a4f185e0f84c1c495478497c0f671b00177e13c469d",
	"ch4_s3_luoyang_market": "c8ea61b7c98bdb18169ccfeb37ec4279998a06b5fdcbd08980bafc9d279ae2f6",
}
const MANIFEST_SHAS := {
	"ch4_s0_luoyang_gate": "20cb77de45df28def34fdeee5f7c75300182ade0a1f6af338088059e47f05de1",
	"ch4_s1_luoyang_yamen": "2e1f562c429aabc89ebd38f044192e0f8dd71738147cb51b5fba4f9d6b7b50d4",
	"ch4_s2_canal_docks": "b4b06110c299bf97dad8eb7134d8b0902135b37bc7c7f4952522ce6f30a5cf23",
	"ch4_s3_luoyang_market": "ba46bfa02e4152918d6696033450bf1f0329be01318f69449a7fad7355a85c84",
}
const GROUND_MANIFESTS := {
	"ch4_s0_luoyang_gate": {"path":ROOT+"ch4_s0_luoyang_gate/ground_v14/root_ground_v14_02/ground_capture.json","sha256":"1976d00447c8c399b92c9c2b1abdd1c8ce09d97f45263e7449b726f16bbaa3d3"},
	"ch4_s1_luoyang_yamen": {"path":ROOT+"ch4_s1_luoyang_yamen/ground_v14/root_ground_v14_02/ground_capture.json","sha256":"1fd971708ac0375e557749f8175b804ac58d71409e717e7be88cab7eb78e181f"},
	"ch4_s2_canal_docks": {"path":ROOT+"ch4_s2_canal_docks/ground_v14/root_ground_v14_02/ground_capture.json","sha256":"aa2aba7052cb289511eb83d68e6135d96e4001c2950763bb9309e2cdbac2e744"},
	"ch4_s3_luoyang_market": {"path":ROOT+"ch4_s3_luoyang_market/ground_v14/root_ground_v14_02/ground_capture.json","sha256":"559c0ffc87f822873e9fbf04aa9b0ce49d98794a806b29a6efd75c16e3847fae"},
}
static var _records: Dictionary = {}
static var _masks: Dictionary = {}
static var _solids: Dictionary = {}
static var _errors: Array[String] = []
static var _using_patch: Dictionary = {}
static var _transition_validation: Dictionary = {}
static var _transition_full_validations := 0
static var _live_source_token := 0
static var _live_source_task := -1
static var _live_source_job: TransitionSourceJob
static var _live_navigation_task := -1
static var _live_navigation_job: TransitionNavigationJob
static var _live_base_cpu_task := -1
static var _live_base_cpu_job: RefCounted
static var _live_phase_msec: Dictionary = {}
static var _live_base_main_active := false
static var _live_base_main_id: StringName = &""
static var _live_main_timings: Dictionary = {}
static var _live_module_task := -1
static var _live_module_job: RefCounted
static var _live_module_timings: Dictionary = {}
static var _live_revision_task := -1
static var _live_revision_job: RefCounted
static var _resident_ready: Dictionary = {}

static func _revision() -> Variant: return load(REVISION_RUNTIME_PATH)
static func revision_requested(id: StringName) -> bool:
	return _revision().requested(id)
static func _assembled() -> Variant: return load("res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd")
static func assembled_requested(id: StringName) -> bool: return _assembled().requested(id)
static func assembled_bound(scene: SceneScript) -> bool: return _assembled().bound(scene)
static func _harbour() -> Variant: return load("res://scripts/city/luoyang_harbour_life_runtime_20261016.gd")
static func harbour_requested(id: StringName) -> bool: return _harbour().requested(id)
static func harbour_bound(scene: SceneScript) -> bool: return _harbour().bound(scene)
static func _annex() -> Variant: return load("res://scripts/city/luoyang_yamen_annex_runtime_20261016.gd")
static func annex_requested(id: StringName) -> bool: return _annex().requested(id)
static func annex_bound(scene: SceneScript) -> bool: return _annex().bound(scene)
static func revision_bound(scene: SceneScript) -> bool: return assembled_bound(scene) or _revision().bound(scene)
static func _interiors() -> Variant: return load("res://scripts/city/luoyang_functional_interiors_20261016.gd")
static func _precomputed() -> Variant: return load(PRECOMPUTED_BUNDLE_PATH)
static func revision_room_known(id: StringName) -> bool: return _interiors().known(id) or _revision().room_known(id)
static func revision_room_path(id: StringName) -> String:
	return _interiors().room_path(id) if _interiors().known(id) else _revision().room_path(id)
static func revision_room_matches(scene: SceneScript,id: StringName) -> bool:
	return _interiors().matches(scene,id) if _interiors().known(id) else _revision().room_matches(scene,id)
static func revision_room_binding(id: StringName) -> Dictionary:
	return _interiors().return_binding(id) if _interiors().known(id) else _revision()._bindings().get("rooms",{}).get(String(id),{}).duplicate(true)
static func revision_room_return(source: StringName,target: StringName,authored: Variant,remembered: Variant) -> Dictionary:
	return _interiors().room_return(source,target,authored,remembered) if _interiors().known(source) else _revision().room_return(source,target,authored,remembered)

class TransitionSourceJob extends RefCounted:
	# Exclusive plain paths/results only. No Resource, Node or rendering access.
	const PARALLEL_SOURCE_HASH = preload("res://scripts/city/luoyang_parallel_source_hash_20261017k.gd")
	const READ_CHUNK_BYTES := 1024 * 1024
	var paths: Array = []
	var hashes: Dictionary = {}
	var _cancel_mutex := Mutex.new()
	var _cancelled := false
	func request_cancel() -> void:
		_cancel_mutex.lock()
		_cancelled = true
		_cancel_mutex.unlock()
	func _is_cancelled() -> bool:
		_cancel_mutex.lock()
		var cancelled := _cancelled
		_cancel_mutex.unlock()
		return cancelled
	func _file_sha(path: String) -> String:
		if _is_cancelled(): return ""
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null: return ""
		var length := file.get_length()
		var digest := HashingContext.new()
		var valid: bool = length >= 0 and file.get_error() == OK and digest.start(HashingContext.HASH_SHA256) == OK
		var consumed := 0
		while valid and consumed < length:
			if _is_cancelled(): valid = false; break
			var requested := mini(READ_CHUNK_BYTES, length - consumed)
			var bytes := file.get_buffer(requested)
			if bytes.size() != requested or file.get_error() != OK or _is_cancelled() or digest.update(bytes) != OK:
				valid = false
				break
			consumed += bytes.size()
		valid = valid and consumed == length and file.get_position() == length and file.get_length() == length and file.get_error() == OK and not _is_cancelled()
		file.close()
		if not valid: return ""
		var result := digest.finish()
		return result.hex_encode() if result.size() == 32 else ""
	func run() -> void:
		var parallel := PARALLEL_SOURCE_HASH.new()
		parallel.paths = paths.duplicate()
		parallel.external_cancel = _is_cancelled
		parallel.run() # Independent Thread children all joined before return.
		hashes = parallel.hashes
		if _is_cancelled(): hashes.clear()

class TransitionNavigationJob extends RefCounted:
	# Exclusive CPU buffers/plain author data. No imported Resource or static nav.
	var raw_bytes := PackedByteArray()
	var mask_bytes := PackedByteArray()
	var objects: Array = []
	var record: Dictionary = {}
	var solids: Array[PackedVector2Array] = []
	var raster_function: Callable
	var gameplay_function: Callable
	var import_error := ""
	# Gate-only prior packet: preserve every V11 raster/import/gameplay gate
	# before proving its independent third-layer geometry in this same CPU job.
	var prior: Dictionary = {}
	var prior_error := ""
	var ready := false
	var module_pending := false
	var raster_ok := false
	var gameplay_ok := false
	var elapsed_msec := 0
	var _cancel_mutex := Mutex.new()
	var _cancelled := false
	func request_cancel() -> void:
		_cancel_mutex.lock()
		_cancelled = true
		_cancel_mutex.unlock()
	func _is_cancelled() -> bool:
		_cancel_mutex.lock()
		var cancelled := _cancelled
		_cancel_mutex.unlock()
		return cancelled
	func run() -> void:
		var started := Time.get_ticks_msec()
		if not ready or _is_cancelled() or raw_bytes.size() != 3072 * 2048 * 4 or mask_bytes.size() != raw_bytes.size() or not raster_function.is_valid() or not gameplay_function.is_valid(): return
		if not prior.is_empty():
			var prior_raw := Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,raw_bytes)
			var prior_mask := Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,prior.mask_bytes)
			var prior_expected: Image = raster_function.call(prior_raw,prior.objects,_is_cancelled)
			if _is_cancelled(): return
			if prior_expected == null or prior_expected.get_data() != prior.mask_bytes: prior_error = "V11 navigation not exact raw support minus retained/new solids"
			elif not String(prior.import_error).is_empty(): prior_error = prior.import_error
			elif not gameplay_function.call(prior.record,prior_mask,prior.solids,_is_cancelled): prior_error = "V11 original routes/gameplay feet are blocked by new enclosure"
			if _is_cancelled() or not prior_error.is_empty(): return
		var raw := Image.create_from_data(3072, 2048, false, Image.FORMAT_RGBA8, raw_bytes)
		var mask := Image.create_from_data(3072, 2048, false, Image.FORMAT_RGBA8, mask_bytes)
		var expected: Image = raster_function.call(raw, objects, _is_cancelled)
		if _is_cancelled(): return
		raster_ok = expected != null and expected.get_data() == mask_bytes
		if raster_ok and import_error.is_empty(): gameplay_ok = gameplay_function.call(record, mask, solids, _is_cancelled)
		if _is_cancelled(): raster_ok = false; gameplay_ok = false
		elapsed_msec = Time.get_ticks_msec() - started

static func owns_id(id: StringName) -> bool: return BASE.owns_id(id)
static func legacy_scene(id: StringName) -> SceneScript: return BASE.legacy_scene(id)
static func gameplay_identity(id: StringName) -> Dictionary: return BASE.gameplay_identity(id)
static func semantic_fidelity(scene: SceneScript) -> bool:
	# Explicit gameplay delta is checked against the fully original-proven,
	# source-bound complete expected scene, never against a count-only waiver.
	if scene!=null and (scene.has_meta(_annex().META) or scene.has_meta(_harbour().META) or scene.has_meta(_assembled().META) or scene.has_meta(REVISION_META)): return runtime_fidelity(scene)
	return BASE.semantic_fidelity(scene)
static func errors() -> Array[String]: return _errors.duplicate()
static func _fail(message: String) -> bool:
	_clear_live_sources()
	_transition_validation.clear()
	_errors.append(message)
	return false
static func base_manifest_path(id: StringName) -> String: return BASE.ROOT + String(id) + "/art_contract.json"
static func base_manifest_sha(id: StringName) -> String: return String(BASE.MANIFEST_SHAS.get(String(id), ""))
static func manifest_path(id: StringName) -> String:
	return ROOT + String(id) + "/art_patch.json" if PATCH_MANIFEST_SHAS.has(String(id)) else base_manifest_path(id)
static func manifest_sha(id: StringName) -> String: return String(MANIFEST_SHAS.get(String(id), ""))
static func ground_manifest_path(id: StringName) -> String: return String(GROUND_MANIFESTS.get(String(id), {}).get("path", ""))
static func ground_manifest_sha(id: StringName) -> String: return String(GROUND_MANIFESTS.get(String(id), {}).get("sha256", ""))
static func layout_path(id: StringName) -> String: return "res://data/maps/luoyang_enclosure_v11_candidates/%s_layout.tres" % id
static func candidate_path(id: StringName) -> String: return "res://data/scenes/luoyang_enclosure_v11_candidates/%s.tres" % id
static func _vec(value: Variant) -> Vector2: return BASE._vec(value)
static func _polygon(value: Variant) -> PackedVector2Array: return BASE._polygon(value)
static func _num(value: Variant, expected: float) -> bool: return BASE._num(value, expected)
static func _hash(value: Variant) -> bool: return BASE._hash(value)
static func _equal_value(a: Variant, b: Variant) -> bool: return BASE._equal_value(a, b)
static func equal_visual_serialized_value(a: Variant, b: Variant, path: Array) -> bool:
	# NEW exporter annotations contain native Vector/Transform components. The
	# saved text may shorten their decimal spelling, but never their native bits.
	# Physical layout fields and all unlisted scalar paths remain strict BASE.
	if typeof(a) != typeof(b): return false
	if path.size() == 3 and typeof(path[0]) == TYPE_STRING and path[0] == "visual_objects" and _authoring_index(path[1]) and typeof(path[2]) in [TYPE_STRING, TYPE_STRING_NAME] and path[2] == "city_v3_solid_polygons_px":
		return _equal_native_city_solid_polygons(a, b)
	if _native_authoring_scalar_path(path):
		if typeof(a) != TYPE_FLOAT or not is_finite(a) or not is_finite(b): return false
		var left := PackedFloat32Array([a])
		var right := PackedFloat32Array([b])
		return is_finite(left[0]) and is_finite(right[0]) and left.to_byte_array() == right.to_byte_array()
	if a is Array:
		if a.size() != b.size(): return false
		for index: int in a.size():
			if not equal_visual_serialized_value(a[index], b[index], path + [index]): return false
		return true
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not equal_visual_serialized_value(a[key], b[key], path + [key]): return false
		return true
	return BASE.equal_visual_serialized_value(a, b, path)

static func _equal_native_city_solid_polygons(a: Variant, b: Variant) -> bool:
	# These sequences become Vector2/PackedVector2Array in both safe_body and
	# Field CollisionPolygon2D. Text decimals may differ; native geometry may not.
	if not a is Array or not b is Array or a.size() != b.size(): return false
	for polygon_index: int in a.size():
		var left: Variant = a[polygon_index]; var right: Variant = b[polygon_index]
		if not left is Array or not right is Array or left.size() < 3 or left.size() != right.size(): return false
		for vertex_index: int in left.size():
			var p: Variant = left[vertex_index]; var q: Variant = right[vertex_index]
			if not p is Array or not q is Array or p.size() != 2 or q.size() != 2: return false
			for axis: int in 2:
				if typeof(p[axis]) != TYPE_FLOAT or typeof(q[axis]) != TYPE_FLOAT or not is_finite(p[axis]) or not is_finite(q[axis]): return false
				var native_p := PackedFloat32Array([p[axis]]); var native_q := PackedFloat32Array([q[axis]])
				if not is_finite(native_p[0]) or not is_finite(native_q[0]) or native_p.to_byte_array() != native_q.to_byte_array(): return false
	return true

static func _native_authoring_scalar_path(path: Array) -> bool:
	if path.size() < 6 or not typeof(path[0]) in [TYPE_STRING, TYPE_STRING_NAME] or not typeof(path[2]) in [TYPE_STRING, TYPE_STRING_NAME] or path[0] != "visual_objects" or not _authoring_index(path[1]) or path[2] != "authoring": return false
	if path.size() == 7:
		if path[3] == "solid_polygons_px": return _authoring_index(path[4]) and _authoring_index(path[5]) and BASE._uv_component(path[6])
		if path[3] == "pieces": return _authoring_index(path[4]) and path[5] == "origin_px" and BASE._uv_component(path[6])
		return path[3] == "original_native_record" and path[4] == "used_bounds_m" and path[5] == "maximum" and _authoring_component3(path[6])
	if path.size() == 8:
		if path[3] == "pieces": return _authoring_index(path[4]) and path[5] == "uv_polygon_px" and _authoring_index(path[6]) and BASE._uv_component(path[7])
		if path[3] == "original_cargo_record": return path[4] == "solid_polygons_px" and _authoring_index(path[5]) and _authoring_index(path[6]) and BASE._uv_component(path[7])
		return path[3] == "original_native_record" and path[4] == "raw_camera" and path[5] == "basis_columns" and _authoring_component3(path[6]) and _authoring_component3(path[7])
	return path.size() == 6 and path[3] == "original_native_record" and path[4] in ["projected_semantic_anchor_px", "world_origin_px"] and BASE._uv_component(path[5])

static func _authoring_index(value: Variant) -> bool: return typeof(value) == TYPE_INT and value >= 0
static func _authoring_component3(value: Variant) -> bool: return typeof(value) == TYPE_INT and value >= 0 and value < 3

static func is_v3(scene: SceneScript) -> bool:
	if scene!=null and scene.has_meta("luoyang_layout_quest_20261018t"): return _precomputed().bound(scene)
	if scene == null or not owns_id(scene.scene_id) or scene.map_layout == null: return false
	if scene.has_meta(_annex().META): return annex_bound(scene)
	if scene.has_meta(_harbour().META): return harbour_bound(scene)
	if scene.has_meta(_assembled().META): return assembled_bound(scene)
	var revised: bool=scene.has_meta(REVISION_META)
	if revised and not _revision().bound(scene): return false
	if scene.has_meta(GATE_FORTIFICATION.META) and not GATE_FORTIFICATION.bound(scene): return false
	if scene.has_meta(MARKET_ENRICHMENT.META) and not revised and not MARKET_ENRICHMENT.bound(scene): return false
	if revised and scene.scene_id==MARKET_ENRICHMENT.ID and scene.get_meta(MARKET_ENRICHMENT.META,"")!=MARKET_ENRICHMENT.MANIFEST_SHA: return false
	if scene.has_meta("city_enclosure_manifest_sha"):
		return scene.map_layout.schema_version == VERSION and _hash(manifest_sha(scene.scene_id)) and scene.get_meta("city_enclosure_manifest_sha") == manifest_sha(scene.scene_id) and scene.get_meta("city_manifest_sha", "") == base_manifest_sha(scene.scene_id) and _hash(ground_manifest_sha(scene.scene_id)) and scene.get_meta("city_ground_manifest_sha", "") == ground_manifest_sha(scene.scene_id) and scene.get_meta("city_ground_manifest_path", "") == ground_manifest_path(scene.scene_id)
	return BASE.is_v3(scene)

static func resolve_scene(scene: SceneScript) -> SceneScript:
	if scene==null: return null
	if scene.has_meta(_annex().META) and not annex_requested(scene.scene_id): _fail("Annex Scene disabled/unbound"); return null
	if not annex_requested(scene.scene_id): return _resolve_scene_before_annex(scene)
	var raw:=ResourceLoader.load("res://data/scenes/%s.tres"%String(scene.scene_id),"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if raw==null: return null
	var parent:=_resolve_scene_before_annex(raw)
	if parent==null: return null
	var result: SceneScript=_annex().apply_sync_after_parent(parent,raw)
	if scene.has_meta(_annex().META) and (result==null or not _annex().serialized_equal(scene,result)): _fail("Annex Scene differs from complete expected"); return null
	return result

static func _resolve_scene_before_annex(scene: SceneScript) -> SceneScript:
	if scene==null: return null
	if scene.has_meta(_harbour().META) and not harbour_requested(scene.scene_id): _fail("Harbour Scene disabled/unbound"); return null
	if not harbour_requested(scene.scene_id): return _resolve_scene_before_harbour(scene)
	var raw:=ResourceLoader.load("res://data/scenes/%s.tres"%String(scene.scene_id),"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if raw==null: return null
	var parent:=_resolve_scene_before_harbour(raw)
	if parent==null: return null
	var result: SceneScript=_harbour().apply_sync_after_parent(parent,raw)
	if scene.has_meta(_harbour().META) and (result==null or not _harbour().serialized_equal(scene,result)): _fail("Harbour current Scene differs from complete expected"); return null
	return result

static func _resolve_scene_before_harbour(scene: SceneScript) -> SceneScript:
	if scene==null or not assembled_requested(scene.scene_id): return _resolve_scene_before_assembly(scene)
	var raw:=ResourceLoader.load("res://data/scenes/%s.tres"%String(scene.scene_id),"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if raw==null: return null
	var parent:=_resolve_scene_before_assembly(raw)
	if parent==null: return null
	var result:=_assembled_after_original_sync(parent,raw)
	if scene.has_meta(_assembled().META) and (result==null or not _assembled().serialized_equal(scene,result)): _fail("Assembled current scene differs from complete expected"); return null
	return result

static func _resolve_scene_before_assembly(scene: SceneScript) -> SceneScript:
	if scene!=null and scene.has_meta(REVISION_META) and not revision_requested(scene.scene_id): return null
	if scene==null or not revision_requested(scene.scene_id): return _resolve_scene_original(scene)
	var canonical_path:="res://data/scenes/%s.tres"%String(scene.scene_id)
	var raw: SceneScript=scene if scene.resource_path==canonical_path and not scene.has_meta(REVISION_META) else ResourceLoader.load(canonical_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if raw==null or raw.resource_path!=canonical_path: _fail("Fourth-layer canonical original input unavailable"); return null
	var original:=_resolve_scene_original(raw)
	if original==null: return null
	var result:=_revision_after_original_sync(original,raw)
	if scene.has_meta(REVISION_META) and (result==null or not _revision().serialized_equal(scene,result)): _fail("Fourth-layer current scene differs from fully proven expected"); return null
	return result

static func _resolve_scene_original(scene: SceneScript) -> SceneScript:
	if scene == null or not owns_id(scene.scene_id): return scene
	if MARKET_ENRICHMENT.requested(scene.scene_id,scene) and MARKET_ENRICHMENT.FLAG in OS.get_cmdline_user_args():
		if not CANDIDATE_FLAG in OS.get_cmdline_user_args() or not "--luoyang-v3-candidate" in OS.get_cmdline_user_args(): _fail("Market candidate requires both existing city candidate flags"); return null
		return materialize(scene.scene_id,scene)
	if GATE_FORTIFICATION.requested(scene.scene_id,scene) and GATE_FORTIFICATION.FLAG in OS.get_cmdline_user_args():
		if not CANDIDATE_FLAG in OS.get_cmdline_user_args() or not "--luoyang-v3-candidate" in OS.get_cmdline_user_args(): _fail("Gate candidate requires both existing city candidate flags"); return null
		return materialize(scene.scene_id,scene)
	if scene.has_meta("city_enclosure_manifest_sha"): return scene if runtime_fidelity(scene) else null
	if CANDIDATE_FLAG in OS.get_cmdline_user_args():
		if not "--luoyang-v3-candidate" in OS.get_cmdline_user_args(): _fail("V11 explicit candidate requires existing city routing flag"); return null
		return materialize(scene.scene_id)
	_using_patch.erase(String(scene.scene_id))
	return BASE.resolve_scene(scene)

# Only the live Router transition supplies a nonzero token. Normal public
# resolve/prepare/materialize calls retain their original complete validation.
static func resolve_scene_for_transition(scene: SceneScript, token: int) -> SceneScript:
	if token <= 0 or scene == null or not owns_id(scene.scene_id): _fail("Invalid city transition validation identity"); return null
	var id: StringName = scene.scene_id
	var path := "res://data/scenes/%s.tres" % String(id)
	if scene.resource_path != path: _fail("Transition city source is not exact canonical path"); return null
	if not _transition_validation.is_empty():
		var reused: SceneScript = transition_scene(token, id)
		if reused == null: return null
		if not _equal_value(_transition_storage(scene), _transition_validation.input) or not _equal_value(_transition_storage(scene.map_layout), _transition_validation.input_layout): _fail("Transition input resource changed"); return null
		return reused
	var candidate: bool = CANDIDATE_FLAG in OS.get_cmdline_user_args() and "--luoyang-v3-candidate" in OS.get_cmdline_user_args()
	if not scene.has_meta("city_enclosure_manifest_sha") and not candidate: _fail("Transition reuse is enclosure-only"); return null
	if scene.has_meta("city_enclosure_manifest_sha") and not is_v3(scene): _fail("Transition enclosure metadata differs"); return null
	var sources: Dictionary = _transition_sources(scene)
	if sources.is_empty(): _fail("Transition complete source identity unavailable"); return null
	_errors.clear()
	_records.erase(String(id)); _masks.erase(String(id)); _solids.erase(String(id)); _using_patch.erase(String(id))
	_transition_full_validations += 1
	# BASE.materialize includes the full BASE.prepare once. The original C
	# enclosure tail then consumes that same validated BASE record, not a bypass.
	var base_scene: SceneScript = BASE.materialize(id)
	if base_scene == null: _errors.assign(BASE.errors()); return null
	if not _prepare_enclosure_after_base(id,null,null,GATE_FORTIFICATION.requested(id,scene),MARKET_ENRICHMENT.requested(id,scene)): return null
	var expected: SceneScript = _materialize_enclosure_after_base(id, base_scene)
	if expected == null: return null
	var result: SceneScript = scene if scene.has_meta("city_enclosure_manifest_sha") and not ((GATE_FORTIFICATION.FLAG in OS.get_cmdline_user_args() and id == GATE_FORTIFICATION.ID) or (MARKET_ENRICHMENT.FLAG in OS.get_cmdline_user_args() and id == MARKET_ENRICHMENT.ID)) else expected
	if not _runtime_matches_expected(result, expected) or not _transition_sources_match(sources): return null
	if revision_requested(id):
		result=_revision_after_original_sync(result,scene)
		if result==null or not _transition_sources_match(sources): return null
	if assembled_requested(id):
		result=_assembled_after_original_sync(result,scene)
		if result==null or not _transition_sources_match(sources): return null
	if harbour_requested(id):
		result=_harbour().apply_sync_after_parent(result,scene)
		if result==null or not _transition_sources_match(sources): return null
	if annex_requested(id):
		result=_annex().apply_sync_after_parent(result,scene)
		if result==null or not _transition_sources_match(sources): return null
	_transition_validation = {"token":token, "id":id, "scene":result, "sources":sources, "input":_transition_storage(scene), "input_layout":_transition_storage(scene.map_layout), "output":_transition_storage(result), "output_layout":_transition_storage(result.map_layout), "record":_records[String(id)].duplicate(true), "solids":_solids[String(id)].duplicate(true), "mask_sha":_transition_bytes_sha(_masks[String(id)].get_data()), "reuses":0}
	return result

static func transition_scene(token: int, id: StringName) -> SceneScript:
	if token <= 0 or _transition_validation.is_empty() or _transition_validation.token != token or _transition_validation.id != id: _fail("Missing/mismatched transition-local city proof"); return null
	if not _transition_sources_match(_transition_validation.sources): return null
	return _transition_packet_scene(token, id)

static func _transition_packet_scene(token: int, id: StringName) -> SceneScript:
	if token <= 0 or _transition_validation.is_empty() or _transition_validation.token != token or _transition_validation.id != id: _fail("Missing/mismatched transition-local city proof"); return null
	var tail_started_usec: int=Time.get_ticks_usec()
	var tail_started_frame: int=Engine.get_process_frames()
	var scene: SceneScript = _transition_validation.scene
	if not is_v3(scene) or not _equal_value(_transition_storage(scene), _transition_validation.output) or not _equal_value(_transition_storage(scene.map_layout), _transition_validation.output_layout): _fail("Validated transition scene/layout changed"); return null
	if not _using_patch.get(String(id), false) or not _equal_value(_records.get(String(id)), _transition_validation.record) or not _equal_value(_solids.get(String(id)), _transition_validation.solids) or not _masks.has(String(id)) or _transition_bytes_sha(_masks[String(id)].get_data()) != _transition_validation.mask_sha: _fail("Validated transition navigation state changed"); return null
	_transition_validation.reuses += 1
	_record_live_tail_stage(token,id,"tail.packet.validate",tail_started_usec,tail_started_frame)
	return scene

static func resolve_scene_for_live_transition(scene: SceneScript, token: int) -> SceneScript:
	# Web/public synchronous callers retain the old complete-check protocol.
	if OS.has_feature("web"): return resolve_scene_for_transition(scene, token)
	if token <= 0 or scene == null or not owns_id(scene.scene_id) or scene.resource_path != "res://data/scenes/%s.tres" % String(scene.scene_id): _fail("Invalid live city source identity"); return null
	var candidate: bool = CANDIDATE_FLAG in OS.get_cmdline_user_args() and "--luoyang-v3-candidate" in OS.get_cmdline_user_args()
	if not scene.has_meta("city_enclosure_manifest_sha") and not candidate: _fail("Live transition is enclosure-only"); return null
	if scene.has_meta("city_enclosure_manifest_sha") and not is_v3(scene): _fail("Live enclosure metadata differs"); return null
	_clear_live_sources()
	_transition_validation.clear()
	_live_source_token = token
	_live_phase_msec.clear()
	_live_main_timings.clear()
	_live_module_timings.clear()
	_report_live_progress(token,.02,"正在核验地图来源……")
	var resolve_started := Time.get_ticks_msec()
	var sources: Dictionary = await _live_source_hashes(scene, token)
	if _live_source_token != token: return null
	_live_phase_msec["source_start_worker"] = Time.get_ticks_msec() - resolve_started
	_report_live_progress(token,.12,"地图来源已核验，正在读取场景图像……")
	if sources.is_empty(): _fail("Live complete source identity unavailable"); return null
	var id: StringName = scene.scene_id
	if _precomputed().requested(id): return await _resolve_precomputed_live(scene,token,sources,resolve_started)
	_errors.clear()
	_records.erase(String(id)); _masks.erase(String(id)); _solids.erase(String(id)); _using_patch.erase(String(id))
	_transition_full_validations += 1
	var base_started := Time.get_ticks_msec()
	var cpu_context: RefCounted = await _prepare_base_cpu_live(id, token, sources)
	if _live_source_token != token: return null
	if cpu_context == null: _clear_live_sources(); return null
	_live_phase_msec["base_cpu_worker"] = Time.get_ticks_msec() - base_started
	_report_live_progress(token,.24,"图像已读取，正在核验场景材质……")
	base_started = Time.get_ticks_msec()
	_live_base_main_active = true
	_live_base_main_id = id
	var owner_check := Callable(load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"), "_owns_base_live_attempt").bind(token,id,cpu_context)
	var base_scene: SceneScript = await BASE.materialize_live(id, token, cpu_context, owner_check)
	# An old coroutine may never clear/error/commit the successor's state.
	if not _owns_base_live_attempt(token,id,cpu_context): return null
	_live_base_main_active = false
	_live_main_timings = cpu_context.main_timings(id)
	_live_phase_msec["base_main"] = Time.get_ticks_msec() - base_started
	_report_live_progress(token,.34,"正在核验城区布局与建筑……")
	if base_scene == null: _errors.assign(BASE.errors()); _clear_live_sources(); return null
	cpu_context.release_pixels()
	await (Engine.get_main_loop() as SceneTree).process_frame
	if not _owns_base_live_attempt(token,id,cpu_context): return null
	if not await _prepare_enclosure_after_base_live(id, token, cpu_context, GATE_FORTIFICATION.requested(id,scene),MARKET_ENRICHMENT.requested(id,scene)):
		if _live_source_token == token: _clear_live_sources()
		return null
	await (Engine.get_main_loop() as SceneTree).process_frame
	if not _owns_base_live_attempt(token,id,cpu_context): return null
	var expected: SceneScript = _materialize_enclosure_after_base(id, base_scene)
	if expected == null: _clear_live_sources(); return null
	var result: SceneScript = scene if scene.has_meta("city_enclosure_manifest_sha") and not ((GATE_FORTIFICATION.FLAG in OS.get_cmdline_user_args() and id == GATE_FORTIFICATION.ID) or (MARKET_ENRICHMENT.FLAG in OS.get_cmdline_user_args() and id == MARKET_ENRICHMENT.ID)) else expected
	if not _runtime_matches_expected(result, expected): _clear_live_sources(); return null
	if revision_requested(id):
		result=await _revision_after_original_live(result,token)
		if _live_source_token!=token: return null
		if result==null: _clear_live_sources(); return null
	if assembled_requested(id):
		result=await _assembled_after_original_live(result,token)
		if _live_source_token!=token: return null
		if result==null: _clear_live_sources(); return null
	if harbour_requested(id):
		result=await _harbour().apply_live_after_parent(result,token)
		if _live_source_token!=token: return null
		if result==null: _clear_live_sources(); return null
	if annex_requested(id):
		result=await _annex().apply_live_after_parent(result,token)
		if _live_source_token!=token: return null
		if result==null: _clear_live_sources(); return null
	_live_phase_msec["resolve_total"] = Time.get_ticks_msec() - resolve_started
	var tail_started_usec: int=Time.get_ticks_usec()
	var tail_started_frame: int=Engine.get_process_frames()
	_transition_validation = {"token":token, "id":id, "scene":result, "source_scene":scene, "sources":sources, "input":_transition_storage(scene), "input_layout":_transition_storage(scene.map_layout), "output":_transition_storage(result), "output_layout":_transition_storage(result.map_layout), "record":_records[String(id)].duplicate(true), "solids":_solids[String(id)].duplicate(true), "mask_sha":_transition_bytes_sha(_masks[String(id)].get_data()), "reuses":0, "live_scope":true, "sources_finalized":false}
	_record_live_tail_stage(token,id,"tail.proof.publish",tail_started_usec,tail_started_frame)
	return result

static func _resolve_precomputed_live(raw: SceneScript,token: int,sources: Dictionary,resolve_started: int) -> SceneScript:
	# Same complete source-first/final protocol and Field/District consumers.
	# Only the publication-proven geometry/material reconstruction is not rerun.
	var id: StringName=raw.scene_id
	if token<=0 or _live_source_token!=token or _live_revision_task>=0 or _live_revision_job!=null: _fail("Bundle live owner unavailable"); return null
	var helper: Variant=_precomputed()
	var job: RefCounted=helper.new()
	if not job.configure(token,id,sources):
		var configure_error: String=job.error(); job.release(); _fail(configure_error); return null
	var started: int=Time.get_ticks_msec()
	var task: int=WorkerThreadPool.add_task(job.run,false,"Luoyang published native bundle packet")
	if task<0: job.release(); _fail("Bundle packet worker unavailable"); return null
	_live_revision_job=job; _live_revision_task=task
	while _live_source_token==token and _live_revision_job==job and not WorkerThreadPool.is_task_completed(task):
		await (Engine.get_main_loop() as SceneTree).process_frame
	# Superseding owner already cancels/joins/releases through _clear_live_sources.
	if _live_source_token!=token or _live_revision_job!=job: return null
	WorkerThreadPool.wait_for_task_completion(task); _live_revision_task=-1
	if not job.mark_joined(token,id):
		var worker_error: String=job.error(); job.release(); _live_revision_job=null; _fail(worker_error); return null
	var data: Dictionary=job.packet(token,id)
	if data.is_empty() or not _equal_value(object_solids(data.get("record",{}).get("objects",[])),data.get("solids")):
		job.release(); _live_revision_job=null; _fail("Bundle complete record/physical solids identity differs"); return null
	var result: SceneScript=helper.materialize(raw,id,data,sources)
	if _live_source_token!=token or _live_revision_job!=job: return null
	if result==null or not is_v3(result):
		job.release(); _live_revision_job=null; _fail("Bundle published full native Scene/layout/source differs"); return null
	# Build every local before any global navigation mutation; no awaits below.
	var mask:=Image.create_from_data(int(SIZE.x),int(SIZE.y),false,Image.FORMAT_RGBA8,data.walk_bytes)
	if mask==null or _transition_bytes_sha(mask.get_data())!=data.mask_sha:
		job.release(); _live_revision_job=null; _fail("Bundle actual full RGBA mask differs"); return null
	var proof: Dictionary={"token":token,"id":id,"scene":result,"source_scene":raw,"sources":sources,"input":_transition_storage(raw),"input_layout":_transition_storage(raw.map_layout),"output":_transition_storage(result),"output_layout":_transition_storage(result.map_layout),"record":data.record.duplicate(true),"solids":data.solids.duplicate(true),"mask_sha":data.mask_sha,"reuses":0,"live_scope":true,"sources_finalized":false,"proof_kind":helper.KIND,"geometry_proof_basis":helper.proof_basis(data)}
	if _live_source_token!=token or _live_revision_job!=job: return null
	_records[String(id)]=data.record; _masks[String(id)]=mask; _solids[String(id)]=data.solids; _using_patch[String(id)]=true
	_transition_validation=proof
	_live_phase_msec["precomputed_packet_and_materialize"]=Time.get_ticks_msec()-started
	_live_phase_msec["resolve_total"]=Time.get_ticks_msec()-resolve_started
	# Do not increment _transition_full_validations: authoring was not rerun.
	job.release(); _live_revision_job=null
	_errors.clear()
	return result

static func _record_live_tail_stage(token: int,id: StringName,label: String,started_usec: int,started_frame: int) -> void:
	# Bounded scalar diagnostics only. Never changes validation or request ownership.
	var finished_usec: int=Time.get_ticks_usec()
	var finished_frame: int=Engine.get_process_frames()
	if token<=0 or _live_source_token!=token or _live_base_main_id!=id or started_usec<0 or finished_usec<started_usec or started_frame<0 or finished_frame<started_frame: return
	if label not in ["tail.harbour.import_readback","tail.harbour.materialize_serialized","tail.nav.commit","tail.proof.publish","tail.packet.validate"]: return
	var row: Dictionary=_live_main_timings.get(label,{"token":token,"scene_id":String(id),"count":0,"total_usec":0,"max_usec":0,"first_started_usec":started_usec,"first_started_frame":started_frame})
	if row.get("token")!=token or row.get("scene_id")!=String(id): return
	var elapsed_usec: int=finished_usec-started_usec
	row.count+=1; row.total_usec+=elapsed_usec
	row.last_started_usec=started_usec; row.last_finished_usec=finished_usec
	row.last_started_frame=started_frame; row.last_finished_frame=finished_frame
	if elapsed_usec>=int(row.max_usec):
		row.max_usec=elapsed_usec; row.max_started_usec=started_usec; row.max_finished_usec=finished_usec
		row.max_started_frame=started_frame; row.max_finished_frame=finished_frame
	_live_main_timings[label]=row

static func _owns_base_live_attempt(token: int, id: StringName, cpu_context: RefCounted) -> bool:
	return token > 0 and _live_source_token == token and _live_base_cpu_job == cpu_context and cpu_context != null and cpu_context.get_script() == BASE_CPU_WORKSPACE and cpu_context.matches_owner(token,id)

static func _prepare_base_cpu_live(id: StringName, token: int, sources: Dictionary) -> RefCounted:
	# Main prepares immutable plain inputs. The job never calls BASE/C prepare.
	var path := base_manifest_path(id)
	var bytes := FileAccess.get_file_as_bytes(path)
	if _transition_bytes_sha(bytes) != BASE.MANIFEST_SHAS[String(id)] or sources.get(path) != BASE.MANIFEST_SHAS[String(id)]: _fail("Live BASE CPU manifest source differs"); return null
	var record: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	if not record is Dictionary: _fail("Live BASE CPU manifest malformed"); return null
	var job := BASE_CPU_WORKSPACE.new()
	var alpha := Callable(BASE.DETAIL_CHECKER, "_alpha_reconstruct") if String(id) == BASE.DETAIL_CHECKER.NOTE_REGION else Callable(BASE.DETAIL_CHECKER.ORIGINAL_CHECKER, "_alpha_reconstruct")
	if not job.configure(token, id, record, sources, alpha): job.release(); _fail("Live BASE CPU inputs unbound"); return null
	_live_base_cpu_job = job
	var task := WorkerThreadPool.add_task(Callable(job, "run"), false, "Luoyang complete BASE PNG computation")
	if task < 0: _live_base_cpu_job = null; job.release(); _fail("Live BASE CPU task unavailable"); return null
	_live_base_cpu_task = task
	while _live_source_token == token and _live_base_cpu_job == job and not WorkerThreadPool.is_task_completed(task):
		await (Engine.get_main_loop() as SceneTree).process_frame
	# Cancellation already joins/releases this job in _clear_live_sources().
	# Do not wait a second time on a task ID removed by that completed join.
	if _live_source_token != token or _live_base_cpu_job != job: return null
	WorkerThreadPool.wait_for_task_completion(task)
	_live_base_cpu_task = -1
	if not job.mark_joined(token, id) or not job.matches(token, id, BASE.ROOT+String(id)+"/", record, record.asset_sha256):
		var error: String = job.error()
		_fail("Live BASE CPU computation failed/cancelled: " + error)
		job.release(); _live_base_cpu_job = null; return null
	return job

static func transition_scene_live(token: int, id: StringName) -> SceneScript:
	if _live_source_token != token or _transition_validation.get("live_scope",false) != true: _fail("Missing live transition source owner"); return null
	return _transition_packet_scene(token, id)

static func resolve_scene_from_live_transition(scene: SceneScript, token: int) -> SceneScript:
	if scene == null or scene.resource_path != "res://data/scenes/%s.tres" % String(scene.scene_id): _fail("Live consumer source path differs"); return null
	var result := transition_scene_live(token, scene.scene_id)
	if result == null: return null
	if not _equal_value(_transition_storage(scene), _transition_validation.input) or not _equal_value(_transition_storage(scene.map_layout), _transition_validation.input_layout): _fail("Live consumer source resource changed"); return null
	return result

static func finalize_live_transition_sources(token: int, id: StringName) -> bool:
	var scene := transition_scene_live(token, id)
	if scene == null: return false
	var source: SceneScript = _transition_validation.source_scene
	if resolve_scene_from_live_transition(source, token) == null: return false
	var expected: Dictionary = _transition_validation.sources.duplicate()
	var resident_before:=resident_source_stamps(expected)
	var actual: Dictionary = await _live_source_hashes(source, token)
	if _live_source_token != token: return false
	if actual.is_empty() or not _equal_value(actual, expected): return _fail("Live transition final complete source identity changed")
	if resolve_scene_from_live_transition(source, token) == null: return false
	_transition_validation.sources_finalized = true
	# Retain only identities belonging to the still-live, successfully installed
	# exterior. Router may lease it for one exact authored room excursion.
	_resident_ready=_transition_validation.duplicate(true)
	_resident_ready["mask"]=_masks[String(id)]
	_resident_ready["stamps"]=resident_source_stamps(expected)
	if resident_before.is_empty() or not _equal_value(resident_before,_resident_ready.stamps): _resident_ready={}
	return true

static func resident_source_stamps(paths: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths:
		var file:=FileAccess.open(path,FileAccess.READ)
		if file==null: return {}
		result[path]={"length":file.get_length(),"mtime_seconds":FileAccess.get_modified_time(path)}
		file.close()
	return result

static func resident_receipt(scene: SceneScript) -> Dictionary:
	if scene==null or _resident_ready.is_empty() or _resident_ready.get("scene")!=scene: return {}
	return _resident_ready.duplicate(true) if resident_matches(_resident_ready,scene) else {}

static func resident_matches(proof: Dictionary,scene: SceneScript) -> bool:
	if scene==null or proof.get("scene")!=scene or proof.get("sources_finalized")!=true or proof.get("stamps",{}).is_empty() or not is_v3(scene): return false
	if _resident_ready.is_empty() or _resident_ready.get("scene")!=scene or _resident_ready.get("sources_finalized")!=true or proof.get("source_scene")!=_resident_ready.get("source_scene") or proof.get("mask")!=_resident_ready.get("mask"): return false
	# Value clones are legitimate; invented SHA values, stamps or geometry are
	# not. Bind the supplied receipt to the actual successfully finalized one.
	for key: String in ["sources","stamps","input","input_layout","output","output_layout","record","solids","mask_sha","token","id"]:
		if not _equal_value(proof.get(key),_resident_ready.get(key)): return false
	var id:=String(scene.scene_id)
	if not _using_patch.get(id,false) or not _equal_value(_transition_storage(scene),proof.output) or not _equal_value(_transition_storage(scene.map_layout),proof.output_layout): return false
	if not _equal_value(_records.get(id),proof.record) or not _equal_value(_solids.get(id),proof.solids) or _masks.get(id)!=proof.mask or _transition_bytes_sha(proof.mask.get_data())!=proof.mask_sha: return false
	var paths:=_transition_sources(proof.source_scene,false)
	if paths.size()!=proof.sources.size(): return false
	for path: String in paths:
		if not proof.sources.has(path): return false
	return _equal_value(resident_source_stamps(paths),proof.stamps)

static func clear_resident_receipt() -> void:
	_resident_ready={}

static func _live_source_hashes(scene: SceneScript, token: int) -> Dictionary:
	if _live_source_task >= 0: return {}
	var paths: Dictionary = _transition_sources(scene, false)
	if paths.is_empty() or _live_source_token != token: return {}
	var job := TransitionSourceJob.new()
	job.paths = paths.keys()
	var task: int = WorkerThreadPool.add_task(job.run, false, "Luoyang complete source SHA")
	if task < 0: return {}
	_live_source_job = job; _live_source_task = task
	while _live_source_token == token and _live_source_job == job and not WorkerThreadPool.is_task_completed(task):
		await (Engine.get_main_loop() as SceneTree).process_frame
	if _live_source_token != token or _live_source_job != job: return {}
	WorkerThreadPool.wait_for_task_completion(task)
	_live_source_task = -1; _live_source_job = null
	if job.hashes.size() != paths.size(): return {}
	for path: String in paths:
		if not _hash(job.hashes.get(path)): return {}
	return job.hashes

static func _clear_live_sources() -> void:
	# Cancel ownership first; join before releasing exclusive worker buffers.
	_live_source_token = 0
	_live_base_main_active = false
	_live_base_main_id = &""
	if _live_source_job != null: _live_source_job.request_cancel()
	if _live_navigation_job != null: _live_navigation_job.request_cancel()
	if _live_base_cpu_job != null: _live_base_cpu_job.request_cancel()
	if _live_module_job != null: _live_module_job.request_cancel()
	if _live_revision_job != null: _live_revision_job.request_cancel()
	if _live_source_task >= 0: WorkerThreadPool.wait_for_task_completion(_live_source_task)
	if _live_navigation_task >= 0: WorkerThreadPool.wait_for_task_completion(_live_navigation_task)
	if _live_base_cpu_task >= 0: WorkerThreadPool.wait_for_task_completion(_live_base_cpu_task)
	if _live_module_task >= 0: WorkerThreadPool.wait_for_task_completion(_live_module_task)
	if _live_revision_task >= 0: WorkerThreadPool.wait_for_task_completion(_live_revision_task)
	if _live_base_cpu_job != null: _live_base_cpu_job.release()
	if _live_module_job != null: _live_module_job.release()
	if _live_revision_job != null: _live_revision_job.release()
	_live_source_task = -1; _live_source_job = null
	_live_navigation_task = -1; _live_navigation_job = null
	_live_base_cpu_task = -1; _live_base_cpu_job = null
	_live_module_task = -1; _live_module_job = null
	_live_revision_task = -1; _live_revision_job = null

static func _report_live_progress(token: int,ratio: float,stage: String) -> void:
	if token<=0 or _live_source_token!=token: return
	var tree:=Engine.get_main_loop() as SceneTree
	var loading:=tree.root.get_node_or_null("LoadingManager") if tree!=null else null
	if loading!=null and loading.has_method("update_field_preparation_progress"): loading.call("update_field_preparation_progress",token,ratio,stage)

static func end_transition_validation(token: int) -> void:
	if _live_source_token == token: _clear_live_sources()
	if not _transition_validation.is_empty() and _transition_validation.token == token: _transition_validation.clear()

static func transition_validation_state() -> Dictionary:
	# Only joined main-thread phase scalars; never read a running CPU job output.
	var main_timings: Dictionary = _live_base_cpu_job.main_timings(_live_base_main_id) if _live_base_main_active and _live_base_cpu_job != null else _live_main_timings.duplicate(true)
	main_timings["module_live"]=_live_module_timings.duplicate(true)
	return {"active":not _transition_validation.is_empty(), "token":_transition_validation.get("token",0), "scene_id":String(_transition_validation.get("id",&"")), "reuse_count":_transition_validation.get("reuses",0), "source_count":_transition_validation.get("sources",{}).size(), "full_validations_total":_transition_full_validations, "live_scope":_transition_validation.get("live_scope",false), "sources_finalized":_transition_validation.get("sources_finalized",false), "source_worker_active":_live_source_task >= 0, "navigation_worker_active":_live_navigation_task >= 0, "revision_worker_active":_live_revision_task >= 0, "revision_worker_owner":_live_source_token if _live_revision_task >= 0 else 0, "base_cpu_worker_active":_live_base_cpu_task >= 0, "base_cpu_owner_token":_live_source_token if _live_base_cpu_task >= 0 else 0, "BASE_live_active":_live_base_main_active, "BASE_live_owner":_live_source_token if _live_base_main_active else 0, "BASE_live_scene_id":String(_live_base_main_id), "BASE_live_phase":"base.validation" if _live_base_main_active else "", "BASE_last_completed_stage":_live_base_cpu_job.main_last_completed_stage(_live_base_main_id) if _live_base_main_active and _live_base_cpu_job != null else "", "main_stage_timings":main_timings, "live_phase_msec":_live_phase_msec.duplicate()}

static func _prepare_or_transition(id: StringName, token: int) -> bool:
	if token == 0:
		if revision_requested(id) or assembled_requested(id) or harbour_requested(id): return resolve_scene(ResourceLoader.load("res://data/scenes/%s.tres"%String(id),"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript)!=null
		return prepare(id)
	if _transition_validation.get("live_scope",false) == true: return transition_scene_live(token,id) != null
	return transition_scene(token,id) != null

static func _transition_storage(resource: Resource) -> Dictionary:
	var fields: Dictionary = {}
	if resource == null: return fields
	for property: Dictionary in resource.get_property_list():
		var name: String = String(property.name)
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or name == "map_layout": continue
		var value: Variant = resource.get(name)
		fields[name] = value.duplicate(true) if value is Array or value is Dictionary else value
	return fields

static func _transition_sources(scene: SceneScript, hash_files: bool = true) -> Dictionary:
	var id: StringName = scene.scene_id
	var paths: Dictionary = {}
	if _precomputed().supported(id):
		var bundle_paths: Dictionary=_precomputed().source_paths(id)
		if bundle_paths.is_empty(): return {}
		paths.merge(bundle_paths)
	paths["res://scripts/city/luoyang_parallel_source_hash_20261017k.gd"] = true
	# Field-owned additive scenery has the same complete first/final source lease;
	# it does not replace the original Scene, record, NAV or task oracle.
	var district: Variant=load("res://scripts/city/luoyang_district_life_20261016f.gd")
	if district.requested(id):
		var district_paths: Dictionary=district.source_paths()
		if district_paths.is_empty(): return {}
		paths.merge(district_paths)
	if annex_requested(id):
		var annex_paths: Dictionary=_annex().source_paths()
		if annex_paths.is_empty(): return {}
		paths.merge(annex_paths)
	if harbour_requested(id):
		var harbour_paths: Dictionary=_harbour().source_paths()
		if harbour_paths.is_empty(): return {}
		paths.merge(harbour_paths)
	if assembled_requested(id):
		var assembled_paths: Dictionary=_assembled().source_paths()
		if assembled_paths.is_empty(): return {}
		paths.merge(assembled_paths)
	paths["res://scripts/city/luoyang_resident_field_20261016.gd"]=true
	if String(id) in ["ch4_s3_luoyang_market","ch4_s2_canal_docks"] and _interiors().enabled():
		var interior_paths: Dictionary=_interiors().source_paths()
		if interior_paths.is_empty(): return {}
		paths.merge(interior_paths)
	if String(id) in ["ch4_s3_luoyang_market","ch4_s2_canal_docks"]:
		# Two unchanged canonical return portals remain the oracle. A live new
		# temple adds its complete independent closure to both return targets.
		var temple: Variant=load("res://scripts/city/luoyang_temple_assembly_20261016.gd")
		if temple.enabled():
			var temple_paths: Dictionary=temple.source_paths()
			if temple_paths.is_empty(): return {}
			paths.merge(temple_paths)
		# Lazy load avoids C -> tasks -> C preload recursion. These exact leaves
		# also participate in the living exterior's metadata invalidation lease.
		var task_paths: Dictionary=load("res://scripts/city/luoyang_city_tasks_20261016.gd").source_paths()
		if task_paths.is_empty(): return {}
		paths.merge(task_paths)
	if revision_requested(id):
		var revision_paths: Dictionary=_revision().source_paths()
		if revision_paths.is_empty(): return {}
		paths.merge(revision_paths)
	if MARKET_ENRICHMENT.requested(id,scene):
		var market_paths := MARKET_ENRICHMENT.source_paths()
		if market_paths.is_empty(): return {}
		paths.merge(market_paths)
		for source: String in ["res://scripts/city/luoyang_market_enrichment_contract_20261014.gd","res://scripts/city/luoyang_market_enrichment_fade_20261014.gd","res://scripts/dev/publish_luoyang_market_enrichment_candidate_20261014.gd","res://scripts/field/field_walkable_controller.gd"]: paths[source] = true
	if GATE_FORTIFICATION.requested(id,scene):
		var gate_paths := GATE_FORTIFICATION.source_paths()
		if gate_paths.is_empty(): return {}
		paths.merge(gate_paths)
		for source: String in ["res://scripts/city/luoyang_gate_fortification_contract_20261013.gd","res://scripts/city/luoyang_gate_moat_runtime_20261013.gd","res://scripts/city/luoyang_gate_fortification_fade_20261013.gd","res://scripts/field/field_walkable_controller.gd"]: paths[source] = true
	var manifests: Array[String] = [base_manifest_path(id), BASE.DETAIL_CHECKER.OLD_ROOT+String(id)+"/art_contract.json", BASE.DETAIL_CHECKER.V4_ROOT+String(id)+"/art_contract.json", manifest_path(id), ground_manifest_path(id)]
	for path: String in manifests:
		paths[path] = true
		var record: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not record is Dictionary or not record.get("asset_sha256") is Dictionary: return {}
		for asset: Variant in record.asset_sha256:
			if not asset is String or not asset.begins_with("res://") or ".." in asset: return {}
			paths[asset] = true
	for path: String in [scene.resource_path, layout_path(id), ROOT+String(id)+"/export_plan.json", BASE.LEGACY_ROOT+String(id)+"_scene.tres", BASE.LEGACY_ROOT+String(id)+"_layout.tres", BASE.SELF_PATH, BASE.DETAIL_CHECKER_PATH, BASE.DETAIL_CHECKER.ORIGINAL_CHECKER_PATH, "res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd", "res://scripts/city/luoyang_layered_v3_contract.gd", "res://scripts/city/luoyang_enclosure_v14_ground_binding.gd", "res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd", "res://scripts/city/luoyang_module_live_cpu_20261015.gd"]: paths[path] = true
	for resource: Resource in [scene.get_script(), scene.map_layout, scene.map_layout.get_script() if scene.map_layout != null else null]:
		if resource != null and not resource.resource_path.is_empty(): paths[resource.resource_path] = true
	# Import settings and concrete compiled resources are part of the identity,
	# too; an unchanged PNG alone cannot authorize reuse of changed import bytes.
	for path: String in paths.keys():
		var import_path := path+".import"
		if not FileAccess.file_exists(import_path): continue
		paths[import_path] = true
		var config := ConfigFile.new()
		if config.load(import_path) != OK: return {}
		if not config.has_section("remap"): return {}
		for key: String in config.get_section_keys("remap"):
			if not key.begins_with("path"): continue
			var compiled: Variant = config.get_value("remap",key)
			if not compiled is String or not compiled.begins_with("res://") or ".." in compiled: return {}
			paths[compiled] = true
	if not hash_files: return paths
	var hashes: Dictionary = {}
	for path: String in paths:
		if not FileAccess.file_exists(path): return {}
		var sha: String = FileAccess.get_sha256(path)
		if not _hash(sha): return {}
		hashes[path] = sha
	return hashes

static func _transition_sources_match(hashes: Dictionary) -> bool:
	for path: String in hashes:
		if FileAccess.get_sha256(path) != hashes[path]: return _fail("Transition validated source changed: "+path)
	return true

static func _transition_bytes_sha(bytes: PackedByteArray) -> String:
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256); digest.update(bytes)
	return digest.finish().hex_encode()

static func prepare(id: StringName, gate_scene: SceneScript = null) -> bool:
	# An unrelated full prepare may not leave an earlier live transition proof.
	_clear_live_sources()
	_transition_validation.clear()
	_errors.clear()
	_records.erase(String(id)); _masks.erase(String(id)); _solids.erase(String(id)); _using_patch.erase(String(id))
	if not BASE.prepare(id): _errors.assign(BASE.errors()); return false
	return _prepare_enclosure_after_base(id,null,null,GATE_FORTIFICATION.requested(id,gate_scene),MARKET_ENRICHMENT.requested(id,gate_scene))

static func _prepare_enclosure_after_base_live(id: StringName, token: int, cpu_context: RefCounted = null, gate_layer: bool = false, market_layer: bool = false) -> bool:
	if token <= 0 or _live_source_token != token or _live_navigation_task >= 0: return false
	var job := TransitionNavigationJob.new()
	var started := Time.get_ticks_msec()
	if not _prepare_enclosure_after_base(id, job, cpu_context, gate_layer,market_layer): return false
	if _live_source_token != token: return false
	_live_phase_msec["enclosure_main"] = Time.get_ticks_msec() - started
	if job.module_pending:
		if not await _finish_live_module(job,id,token): return false
		if _live_source_token!=token: return false
	if not job.ready: return _fail("Live enclosure CPU navigation inputs unavailable")
	_report_live_progress(token,.56,"正在核验道路、碰撞与入口……")
	var task := WorkerThreadPool.add_task(job.run, false, "Luoyang exact raster and full routes")
	if task < 0: return _fail("Live enclosure CPU navigation worker unavailable")
	_live_navigation_job = job; _live_navigation_task = task
	while _live_source_token == token and _live_navigation_job == job and not WorkerThreadPool.is_task_completed(task):
		await (Engine.get_main_loop() as SceneTree).process_frame
	if _live_source_token != token or _live_navigation_job != job: return false
	WorkerThreadPool.wait_for_task_completion(task)
	_live_navigation_task = -1; _live_navigation_job = null
	_live_phase_msec["navigation_worker"] = job.elapsed_msec
	if job._is_cancelled(): return false
	# Preserve original failure priority, then commit only the fully proven data.
	if not job.prior_error.is_empty(): return _fail(job.prior_error)
	if …55404 tokens truncated…0261016g.gd").configure_fixed_columns(world_container,_current_scene,assembled,_world_size):
			assembled.release(); _field_loading_failed=true; push_error("[Field] Main-hall fixed-column scope rejected"); return
		_v14_modular_overlap=assembled; _create_v14_late_depth_refresh()
	if _district_session!=null and _v14_modular_overlap==null:
		var district_fade:=DISTRICT_FADE.new()
		if not district_fade.configure_district(world_container,_current_scene,_district_session.parent_render,_district_session.projected):
			district_fade.release(); _field_loading_failed=true; push_error("[Field] District parent fade whitelist rejected"); return
		_v14_modular_overlap=district_fade; _create_v14_late_depth_refresh()
	if _is_gate_fortification_scene():
		_gate_moat_runtime = GATE_MOAT_RUNTIME.new()
		if not _gate_moat_runtime.prepare(_harbour_gate_visual_scene if HARBOUR_LIFE.bound(_current_scene) else _current_scene):
			_release_gate_moat_runtime()
			push_error("[Field] Gate bound runtime preparation rejected")
			return
	if _current_scene.scene_id in [&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"] and _v14_modular_overlap==null:
		var family: Variant=load("res://scripts/city/luoyang_quarters_family_20261022ap.gd")
		if not family.matches(_current_scene): _field_loading_failed=true;push_error("[Field] AP native depth owner rejected");return
		_v14_modular_overlap=V14_MODULAR_OVERLAP.new();_v14_modular_overlap.configure(world_container);_create_v14_late_depth_refresh()
	if (SceneRouter.layered_world_contract(_current_scene) != null or OUTSKIRTS.is_native(_current_scene) or LUOYANG_V3.is_v3(_current_scene)) and _v14_modular_overlap == null:
		var enclosure: bool = LUOYANG_V3.is_v3(_current_scene) and _current_scene.has_meta("city_enclosure_manifest_sha")
		if enclosure:
			var harbour: bool=HARBOUR_LIFE.bound(_current_scene)
			var annex: bool=LUOYANG_V3.annex_bound(_current_scene)
			var revised_market: bool=_current_scene.scene_id==MARKET_ENRICHMENT.ID and LUOYANG_V3.revision_bound(_current_scene)
			var assembled_city: bool=annex or LUOYANG_V3.assembled_bound(_current_scene)
			var helper: RefCounted = YAMEN_ANNEX_FADE.new() if annex else (HARBOUR_FADE.new() if harbour else (ASSEMBLED_CITY_FADE.new() if assembled_city else (GATE_FORTIFICATION_FADE.new() if _is_gate_fortification_scene() else (MARKET_ENRICHMENT_FADE.new() if MARKET_ENRICHMENT.bound(_current_scene) or revised_market else CITY_ENCLOSURE_FADE.new()))))
			var configured: bool=helper.configure_harbour_scene(world_container,_current_scene,scene_objects) if harbour else (helper.configure_assembled_scene(world_container,_current_scene,scene_objects) if assembled_city else helper.configure_scene(world_container, String(_current_scene.scene_id)))
			if not configured:
				helper.release()
				push_error("[FieldWalkable] enclosure building fade configuration rejected")
				return
			_v14_modular_overlap = helper
		elif LUOYANG_V3.is_v3(_current_scene):
			_v14_modular_overlap = CITY_OVERLAP.new()
		elif OUTSKIRTS.is_native(_current_scene):
			_v14_modular_overlap = OUTSKIRTS_OVERLAP.new()
		else:
			_v14_modular_overlap = V15_MODULAR_OVERLAP.new() if SceneRouter.WORLD_V15.is_v15(_current_scene) else V14_MODULAR_OVERLAP.new()
		if not enclosure: _v14_modular_overlap.configure(world_container)
		_create_v14_late_depth_refresh()
	_field_loading_profile_record("depth_fade_bootstrap", loading_fade_started, loading_spawn_revision, loading_spawn_scene)
	var loading_first_batch_started: Dictionary = _field_loading_profile_clock()
	var loading_first_batch_recorded: bool = false
	var batch_started := Time.get_ticks_usec()
	var processed := 0
	for entry in scene_objects:
		if progressive and Time.get_ticks_usec() - batch_started >= 8000:
			if not loading_first_batch_recorded:
				_field_loading_profile_record("object_first_batch", loading_first_batch_started, loading_spawn_revision, loading_spawn_scene, processed)
				loading_first_batch_recorded = true
			_field_loading_progress = .1 + .7 * float(processed) / maxi(1, scene_objects.size())
			_field_loading_stage = "正在布置建筑与碰撞……"
			await get_tree().process_frame
			if not is_inside_tree(): return
			batch_started = Time.get_ticks_usec()
		processed += 1
		var d: Dictionary = entry
		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		if not _quest_gate_passes(d):
			continue
		var texture_path: Variant = String(d.get("texture", ""))
		var gate_object: bool = _is_gate_fortification_scene() and d.get("gate_module_object",false) == true
		if texture_path == "" or (not gate_object and not ResourceLoader.exists(texture_path)):
			push_warning("[FieldWalkable] scene object texture missing: %s" % texture_path)
			continue
		var tex: Resource = _gate_moat_runtime.texture_for(d) if gate_object and _gate_moat_runtime != null else load(texture_path)
		if not tex is Texture2D:
			push_warning("[FieldWalkable] scene object is not Texture2D: %s" % texture_path)
			continue
		var texture: Texture2D = tex as Texture2D
		if _district_session!=null and not _district_session.texture_matches(String(texture_path),texture):
			_field_loading_failed=true; push_error("[Field] District actual prop texture identity changed"); return
		if TEMPLE_ASSEMBLY.is_scene(_current_scene) and (_temple_session==null or not _temple_session.texture_matches(String(texture_path),texture)):
			_field_loading_failed=true
			if _temple_session!=null: _temple_session.error="TEMPLE_ACTUAL_PROP_TEXTURE_CHANGED:"+String(texture_path)
			return
		var sprite: Sprite2D = Sprite2D.new()
		sprite.name = "SceneObject_%s" % String(d.get("id", "object"))
		sprite.texture = texture
		if gate_object and d.get("gate_hidden",false) == true: sprite.visible = false
		# Native rendered world props are not pixel art. Camera magnification and
		# non-integral authored sizes must not inherit the project nearest filter.
		# Keep all ordinary scene sprites (and the player) unchanged.
		if SceneRouter.layered_world_contract(_current_scene) != null or OUTSKIRTS.is_native(_current_scene) or LUOYANG_V3.is_v3(_current_scene) or ASSEMBLED_ROOMS.is_room(_current_scene) or TEMPLE_ASSEMBLY.is_scene(_current_scene) or _current_scene.scene_id in [&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]:
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.centered = bool(d.get("centered", true))
		sprite.position = _norm_to_screen(d.get("pos", Vector2.ZERO))
		var render_size_value: Variant = d.get("render_size_px", null)
		if render_size_value is Vector2:
			var render_size: Vector2 = render_size_value as Vector2
			sprite.scale = Vector2(
				render_size.x / maxf(1.0, float(texture.get_width())),
				render_size.y / maxf(1.0, float(texture.get_height()))
			)
		else:
			sprite.scale = _scale_value(d.get("scale", Vector2.ONE))
		sprite.rotation_degrees = float(d.get("rotation", 0.0))
		sprite.z_index = int(d.get("z_index", 0))
		if d.has("modulate") and d["modulate"] is Color:
			sprite.modulate = d["modulate"]
		# A separate transparent prop can share the actor depth ladder. This is
		# fundamentally different from a prop baked into the background, which
		# still needs an authored foreground polygon. The visual, foot collision,
		# and depth line all live in one object entry.
		var depth_sorted := bool(d.get("sort_by_feet", false))
		var render_layer: Node2D = _actor_layer if depth_sorted else (_foreground_layer if String(d.get("render_layer", "")) == "foreground" else _visual_layer)
		var shadow_size_value: Variant = d.get("ground_shadow_size_px", null)
		if shadow_size_value is Vector2:
			var shadow_size: Vector2 = shadow_size_value as Vector2
			if shadow_size.x > 0.0 and shadow_size.y > 0.0:
				var foot_normalized: Vector2 = d.get("pos", Vector2.ZERO) + d.get("collision_offset", Vector2.ZERO)
				var shadow := Sprite2D.new()
				shadow.name = "GroundShadow_%s" % String(d.get("id", "object"))
				shadow.texture = _make_prop_contact_shadow_texture()
				shadow.position = _norm_to_screen(foot_normalized) + Vector2(0.0, -3.0)
				shadow.scale = shadow_size / Vector2(shadow.texture.get_size())
				_visual_layer.add_child(shadow)
				_scene_object_nodes.append(shadow)
		if depth_sorted:
			if not d.has("depth_sort_foot_y"):
				push_warning("[FieldWalkable] depth-sorted object needs depth_sort_foot_y: %s" % sprite.name)
			var foot_y: float = clampf(float(d.get("depth_sort_foot_y", (sprite.position.y / _world_size.y))), 0.0, 1.0)
			var foot_global_y: float = world_container.to_global(Vector2(0.0, foot_y * _world_size.y)).y
			sprite.z_index = clampi(int(floor(foot_global_y / 8.0)), 0, _scene_depth_band_max())
		render_layer.add_child(sprite)
		if depth_sorted and _v14_modular_overlap != null:
			if LUOYANG_V3.is_v3(_current_scene) and d.get("role", "") == "water_decoration":
				# CITY.prepare validates the exact dock/boat identity and no support,
				# geometry or interaction. Keep precise ordinary Y ordering, not ghost.
				_v14_modular_overlap.call("add_non_occluding_prop", sprite, String(d.id), float(d.depth_sort_foot_y) * _world_size.y)
			else:
				_v14_modular_overlap.add_prop(sprite, String(d.get("id", "object")), float(d["depth_sort_foot_y"]) * _world_size.y)
		_scene_object_nodes.append(sprite)

		var object_pos: Vector2 = sprite.position
		if LUOYANG_V3.is_v3(_current_scene):
			if bool(d.get("blocking", false)):
				var city_body := StaticBody2D.new()
				city_body.name = "CityV3Physical_%s" % String(d.get("id", "object"))
				city_body.collision_layer = 1
				city_body.collision_mask = 0
				# Parent identity keeps declared WORLD geometry unchanged.
				_collision_layer.add_child(city_body)
				for raw: Variant in d.get("city_v3_solid_polygons_px", []):
					var polygon := CollisionPolygon2D.new()
					polygon.polygon = LUOYANG_V3._polygon(raw)
					city_body.add_child(polygon)
				var box_size: Vector2 = LUOYANG_V3._vec(d.get("collision_size_px"))
				if box_size.x > 0 and box_size.y > 0: _collider(city_body, LUOYANG_V3._vec(d.physical_center_px), box_size)
				city_body.set_meta("authoring_id", String(d.id))
				_collision_bodies.append(city_body)
		elif SceneRouter.WORLD_V15.is_v15(_current_scene) and d.has("solid_polygons_px"):
			# The authored world-pixel solids surround a real open doorway.
			# Never add the legacy whole-compound rectangle over that passage.
			var body := StaticBody2D.new()
			body.name = "ObjectCollision_%s" % String(d.get("id", "object"))
			body.collision_layer = 1
			body.collision_mask = 0
			body.position = object_pos
			_collision_layer.add_child(body)
			for authored: PackedVector2Array in d.solid_polygons_px:
				var polygon := CollisionPolygon2D.new()
				var local := PackedVector2Array()
				for point: Vector2 in authored: local.append(point - object_pos)
				polygon.polygon = local
				body.add_child(polygon)
			_collision_bodies.append(body)
		elif d.has("collision_size"):
			var body: StaticBody2D = StaticBody2D.new()
			body.name = "ObjectCollision_%s" % String(d.get("id", "object"))
			body.collision_layer = 1
			body.collision_mask = 0
			body.position = object_pos
			_collision_layer.add_child(body)
			_collider(
				body,
				_norm_to_screen(d.get("collision_offset", Vector2.ZERO)),
				_norm_size_to_screen(d.get("collision_size", Vector2(0.05, 0.05)))
			)
			_collision_bodies.append(body)

		var interaction_action: String = String(d.get("interaction_action", ""))
		if interaction_action != "":
			_make_sprite_highlight(sprite)
			_spawn_scene_object_interaction(d, object_pos, interaction_action, sprite)
	if not loading_first_batch_recorded:
		_field_loading_profile_record("object_first_batch", loading_first_batch_started, loading_spawn_revision, loading_spawn_scene, processed)


func _create_v14_late_depth_refresh() -> void:
	if is_instance_valid(_v14_late_depth_refresh): return
	var refresher := V14LateDepthRefresh.new()
	refresher.name = "V14LateDepthRefresh"
	# Player animation is advanced in physics; normal NPC/Field idle priority
	# is 0. Run after their idle movement, but before native frame rendering.
	refresher.process_priority = 100
	refresher.field_ref = weakref(self)
	_v14_late_depth_refresh = refresher
	world_container.add_child(refresher)


func _refresh_v14_late_depth(refresher: Node) -> void:
	if refresher != _v14_late_depth_refresh or _scene_rebuilding or _v14_modular_overlap == null: return
	if not is_instance_valid(_player):
		if _is_enclosure_fade_runtime():
			_v14_modular_overlap.refresh(null)
		return
	_v14_modular_overlap.refresh(_player)


func _make_prop_contact_shadow_texture() -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_offsets(PackedFloat32Array([0.0, 0.48, 1.0]))
	gradient.set_colors(PackedColorArray([
		Color(0.04, 0.035, 0.025, 0.38),
		Color(0.04, 0.035, 0.025, 0.18),
		Color(0.04, 0.035, 0.025, 0.0),
	]))
	var texture := GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	return texture


func _spawn_dynamic_occluders(occluder_data: Array) -> void:
	if _foreground_layer == null or not is_instance_valid(_foreground_layer):
		return
	if _world_background == null or _world_background.texture == null:
		return
	for entry in occluder_data:
		if not entry is Dictionary:
			continue
		var data: Dictionary = entry as Dictionary
		var require_flag := String(data.get("require_flag", ""))
		var hide_flag := String(data.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		var occluder := DynamicOccluder2D.new()
		occluder.name = "DynamicOccluder_%s" % String(data.get("id", "foreground"))
		if not occluder.configure(data, _world_background.texture, _world_size):
			push_warning("[FieldWalkable] invalid dynamic occluder: %s" % String(data.get("id", "")))
			occluder.queue_free()
			continue
		_foreground_layer.add_child(occluder)
		_occluder_nodes.append(occluder)


func _update_dynamic_occluders(normalized_foot_position: Vector2, immediate: bool = false) -> void:
	if _v14_modular_overlap != null and _is_enclosure_fade_runtime() and not is_instance_valid(_player):
		_v14_modular_overlap.refresh(null, immediate)
		return
	if _v14_modular_overlap != null and is_instance_valid(_player):
		_v14_modular_overlap.refresh(_player, immediate)
		return
	var player_is_under_building := false
	var player_faded_alpha := 1.0
	var overlap_mask_payload: Dictionary = {}
	# Legacy scene coordinates may address the actor node/torso rather than its
	# rendered feet. Free-standing props must use the same visual foot coordinate
	# as Player.refresh_depth_sort(), otherwise the foreground remains above an
	# actor who is visibly standing in front of the prop.
	var normalized_visual_foot := normalized_foot_position
	if is_instance_valid(_player) and _world_size.y > 0.0 and _player.has_method("get_depth_sort_y"):
		var global_visual_foot := Vector2(_player.global_position.x, float(_player.call("get_depth_sort_y")))
		var local_visual_foot := world_container.to_local(global_visual_foot)
		normalized_visual_foot.y = clampf(local_visual_foot.y / _world_size.y, 0.0, 1.0)
	for occluder in _occluder_nodes:
		if is_instance_valid(occluder):
			occluder.update_player_position(normalized_visual_foot if occluder.uses_foot_depth_sort() else normalized_foot_position, immediate)
			if occluder.contains_fade_point(normalized_foot_position):
				player_is_under_building = true
				var candidate_alpha := occluder.get_player_faded_alpha()
				if candidate_alpha <= player_faded_alpha:
					player_faded_alpha = candidate_alpha
					overlap_mask_payload = occluder.get_actor_overlap_mask_payload()
	if is_instance_valid(_player):
		_player.set_building_overlap(player_is_under_building, player_faded_alpha, immediate, overlap_mask_payload)
	var player_is_over_baked_building := false
	var baked_faded_alpha := 1.0
	for raw_zone: Variant in _actor_fade_zones:
		if not raw_zone is Dictionary:
			continue
		var zone: Dictionary = raw_zone as Dictionary
		var require_flag := String(zone.get("require_flag", ""))
		var hide_flag := String(zone.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		var region: PackedVector2Array = zone.get("region", PackedVector2Array())
		if region.size() < 3 or not Geometry2D.is_point_in_polygon(normalized_foot_position, region):
			continue
		player_is_over_baked_building = true
		baked_faded_alpha = minf(
			baked_faded_alpha,
			clampf(float(zone.get("actor_faded_alpha", 0.46)), 0.15, 0.90)
		)
	if is_instance_valid(_player):
		_player.set_baked_map_overlap(player_is_over_baked_building, baked_faded_alpha, immediate)


func get_v14_modular_overlap_debug() -> Dictionary:
	return _v14_modular_overlap.get_debug_state() if _v14_modular_overlap != null else {"active": false, "pixels": 0, "prop_hits": {}}

func get_v14_depth_order_debug() -> Array[Dictionary]:
	return _v14_modular_overlap.get_depth_order_state() if _v14_modular_overlap != null else []


func get_city_building_fade_debug() -> Dictionary:
	if _v14_modular_overlap != null and _is_enclosure_fade_runtime():
		var state: Dictionary = _v14_modular_overlap.call("get_fade_runtime_state")
		var arguments: PackedStringArray = OS.get_cmdline_user_args()
		state.candidate_flags_present = LUOYANG_V3.CANDIDATE_FLAG in arguments and "--luoyang-v3-candidate" in arguments
		return state
	return {"runtime_hooked":false,"production_hooked":false,"scope":"NOT_LUOYANG_ENCLOSURE"}


func _spawn_scene_object_interaction(d: Dictionary, object_pos: Vector2, action: String, sprite: Sprite2D) -> void:
	var area: Area2D = Area2D.new()
	area.name = "ObjectInteraction_%s" % String(d.get("id", "object"))
	area.collision_layer = 4
	area.collision_mask = 2
	area.position = object_pos + _norm_to_screen(d.get("interaction_offset", Vector2.ZERO))
	_interaction_layer.add_child(area)
	_collider(area, Vector2.ZERO, _norm_size_to_screen(d.get("interaction_size", Vector2(0.10, 0.10))))

	var trigger_data: Dictionary = {
		"id": String(d.get("id", "object")),
		"action": action,
		"interaction_only": true,
		"require_flag": String(d.get("require_flag", "")),
		"hide_flag": String(d.get("hide_flag", "")),
		"require_quest_active": String(d.get("require_quest_active", "")),
		"require_quest_completed": String(d.get("require_quest_completed", "")),
	}
	area.set_meta("trigger_data", trigger_data)
	area.set_meta("highlight_node", sprite)
	area.input_pickable = false
	area.input_event.connect(_on_interaction_area_input.bind(area, trigger_data))

	area.body_entered.connect(func(body: Node2D):
		if body.is_in_group("player"):
			_set_interaction_highlight(area, true)
	)
	area.body_exited.connect(func(body: Node2D):
		if body.is_in_group("player"):
			_set_interaction_highlight(area, false)
			_on_trigger_zone_exited(body, trigger_data)
	)
	_trigger_areas.append(area)


func _spawn_animated_props(animated_props: Array) -> void:
	for entry in animated_props:
		var d: Dictionary = entry
		var require_flag: String = String(d.get("require_flag", ""))
		var hide_flag: String = String(d.get("hide_flag", ""))
		if require_flag != "" and not _flag_truthy(require_flag):
			continue
		if hide_flag != "" and _flag_truthy(hide_flag):
			continue
		var prop_type: Variant = String(d.get("type", "")).to_lower()
		var node: Node2D = null
		match prop_type:
			"banner":
				node = _make_banner_prop(d)
			"texture_sway":
				node = _make_texture_sway_prop(d)
			"hammer":
				node = _make_hammer_prop(d)
			"flame":
				node = _make_flame_prop(d)
			"smoke":
				node = _make_smoke_prop(d)
			"mist_drift":
				node = _make_mist_drift_prop(d)
			"water_shimmer":
				node = _make_water_shimmer_prop(d)
			"snow_drift":
				node = _make_snow_drift_prop(d)
			"rain_field":
				node = _make_rain_field_prop(d)
			"rain_splash":
				node = _make_rain_splash_prop(d)
			"glow":
				node = _make_glow_prop(d)
			_:
				push_warning("[FieldWalkable] unknown animated prop type: %s" % prop_type)
		if node == null:
			continue
		node.name = "AnimatedProp_%s" % String(d.get("id", prop_type))
		node.position = _norm_to_screen(d.get("pos", Vector2.ZERO))
		node.z_index = int(d.get("z_index", 22))
		_visual_layer.add_child(node)
		_animated_prop_nodes.append(node)


func _spawn_active_weather(scene: SceneScript) -> void:
	_clear_active_weather()
	var weather_manager := get_node_or_null("/root/WeatherManager")
	if weather_manager == null or not bool(weather_manager.call("is_weather_visible", scene)):
		return
	for entry: Dictionary in weather_manager.call("get_visual_props"):
		var prop_type := String(entry.get("type", ""))
		var node: Node2D = null
		match prop_type:
			"rain_field":
				node = _make_rain_field_prop(entry)
			"rain_splash":
				node = _make_rain_splash_prop(entry)
		if node == null:
			continue
		node.name = "Weather_%s" % String(entry.get("id", prop_type))
		node.position = _norm_to_screen(entry.get("pos", Vector2.ZERO))
		node.z_index = int(entry.get("z_index", 72))
		_visual_layer.add_child(node)
		_weather_nodes.append(node)


func _clear_active_weather() -> void:
	for node in _weather_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_weather_nodes.clear()


func _on_weather_changed(_weather_id: StringName, _strength: float) -> void:
	if _current_scene == null or _visual_layer == null or _scene_rebuilding:
		return
	_spawn_active_weather(_current_scene)


func _make_banner_prop(d: Dictionary) -> Node2D:
	var root: Node2D = Node2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.04, 0.08)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	var color: Variant = _parse_html_color(String(d.get("color", "#b72f24")), Color(0.72, 0.18, 0.13, 0.92))
	var pole: Line2D = Line2D.new()
	pole.width = maxf(2.0, size_px.x * 0.08)
	pole.default_color = Color(0.18, 0.12, 0.08, 0.85)
	pole.points = PackedVector2Array([Vector2.ZERO, Vector2(0.0, size_px.y)])
	root.add_child(pole)
	var cloth: Polygon2D = Polygon2D.new()
	cloth.color = color
	cloth.polygon = PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(size_px.x, size_px.y * 0.16),
		Vector2(size_px.x * 0.82, size_px.y * 0.55),
		Vector2(0.0, size_px.y * 0.44),
	])
	cloth.position = Vector2(0.0, size_px.y * 0.10)
	root.add_child(cloth)
	var tween := root.create_tween().set_loops()
	tween.tween_property(cloth, "scale:x", 0.82, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(cloth, "scale:x", 1.08, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_texture_sway_prop(d: Dictionary) -> Node2D:
	var texture_path: Variant = String(d.get("texture", ""))
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		push_warning("[FieldWalkable] animated prop texture missing: %s" % texture_path)
		return null
	var tex: Resource = load(texture_path)
	if not tex is Texture2D:
		push_warning("[FieldWalkable] animated prop is not Texture2D: %s" % texture_path)
		return null
	var texture: Texture2D = tex as Texture2D
	var root: Node2D = Node2D.new()
	var sprite: Sprite2D = Sprite2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.04, 0.08)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2.ZERO
	sprite.scale = Vector2(size_px.x / texture.get_width(), size_px.y / texture.get_height())
	root.add_child(sprite)
	var tween := root.create_tween().set_loops()
	tween.tween_property(sprite, "skew", deg_to_rad(-4.0), 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale:x", sprite.scale.x * 0.92, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "skew", deg_to_rad(4.0), 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale:x", sprite.scale.x * 1.06, 0.55 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_hammer_prop(d: Dictionary) -> Node2D:
	var texture_path: Variant = String(d.get("texture", ""))
	if texture_path == "" or not ResourceLoader.exists(texture_path):
		push_warning("[FieldWalkable] hammer prop texture missing: %s" % texture_path)
		return null
	var tex: Resource = load(texture_path)
	if not tex is Texture2D:
		push_warning("[FieldWalkable] hammer prop is not Texture2D: %s" % texture_path)
		return null
	var texture: Texture2D = tex as Texture2D
	var root: Node2D = Node2D.new()
	var sprite: Sprite2D = Sprite2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.035, 0.06)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = Vector2.ZERO
	sprite.position = Vector2(0.0, -size_px.y * 0.65)
	sprite.scale = Vector2(size_px.x / texture.get_width(), size_px.y / texture.get_height())
	root.add_child(sprite)
	var tween := root.create_tween().set_loops()
	tween.tween_property(sprite, "rotation_degrees", -42.0, 0.22 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "rotation_degrees", 24.0, 0.10 / speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.18 / speed)
	return root


func _make_flame_prop(d: Dictionary) -> Node2D:
	## Stylized environmental fire rendered as a small procedural shader plus a
	## few rising embers. It remains visual-only: no collision, light occluder or
	## per-frame script work. Position is the base of the painted brazier/torch.
	var root := Node2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.026, 0.060)))
	var speed := maxf(0.1, float(d.get("speed", 1.0)))
	var outer_color: Color = _parse_html_color(String(d.get("color", "#ff7a1a")), Color(1.0, 0.42, 0.08, 0.88))
	var core_color: Color = _parse_html_color(String(d.get("core_color", "#ffe08a")), Color(1.0, 0.86, 0.48, 0.96))
	var middle_color := outer_color.lerp(core_color, 0.42)
	var glow := Sprite2D.new()
	glow.texture = _make_radial_texture(128, Color(outer_color.r, outer_color.g, outer_color.b, 0.44), Color(outer_color.r, outer_color.g, outer_color.b, 0.0))
	glow.position = Vector2(0.0, -size_px.y * 0.38)
	glow.scale = Vector2(size_px.x / 42.0, size_px.y / 58.0)
	glow.modulate.a = 0.34
	root.add_child(glow)
	var glow_tween := glow.create_tween().set_loops()
	glow_tween.tween_property(glow, "modulate:a", 0.22, 0.36 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween.parallel().tween_property(glow, "scale", glow.scale * Vector2(0.94, 1.08), 0.36 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween.tween_property(glow, "modulate:a", 0.40, 0.42 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow_tween.parallel().tween_property(glow, "scale", glow.scale, 0.42 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	var flame_quad := ColorRect.new()
	flame_quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flame_quad.position = Vector2(-size_px.x * 0.82, -size_px.y * 1.08)
	flame_quad.size = Vector2(size_px.x * 1.64, size_px.y * 1.12)
	var flame_material := ShaderMaterial.new()
	flame_material.shader = ENVIRONMENT_FLAME_SHADER
	flame_material.set_shader_parameter("outer_color", outer_color)
	flame_material.set_shader_parameter("middle_color", middle_color)
	flame_material.set_shader_parameter("core_color", core_color)
	flame_material.set_shader_parameter("speed", speed)
	flame_material.set_shader_parameter("phase", float(abs(hash(d.get("id", "flame"))) % 1000) / 97.0)
	flame_material.set_shader_parameter("opacity", 0.94)
	flame_quad.material = flame_material
	root.add_child(flame_quad)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "flame_embers"))
	var ember_texture := _make_radial_texture(24, Color(core_color.r, core_color.g, core_color.b, 0.95), Color(outer_color.r, outer_color.g, outer_color.b, 0.0))
	var ember_count := maxi(2, roundi(4.0 * _ambient_animation_density()))
	for index in range(ember_count):
		var ember := Sprite2D.new()
		ember.texture = ember_texture
		ember.centered = true
		root.add_child(ember)
		_loop_flame_ember(ember, size_px, speed, rng.randf_range(0.0, 0.75 / speed), rng)
	return root


func _loop_flame_ember(ember: Sprite2D, size_px: Vector2, speed: float, delay: float, rng: RandomNumberGenerator) -> void:
	var start_x := rng.randf_range(-size_px.x * 0.30, size_px.x * 0.30)
	var end_x := start_x + rng.randf_range(-size_px.x * 0.42, size_px.x * 0.42)
	var end_y := -size_px.y * rng.randf_range(0.72, 1.32)
	var life := rng.randf_range(0.52, 0.88) / speed
	var start_scale := rng.randf_range(0.065, 0.12) * maxf(0.65, size_px.x / 32.0)
	ember.position = Vector2(start_x, -size_px.y * rng.randf_range(0.08, 0.24))
	ember.scale = Vector2.ONE * start_scale
	ember.modulate.a = rng.randf_range(0.54, 0.90)
	var tween := ember.create_tween().set_loops()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		if is_instance_valid(ember):
			ember.position = Vector2(start_x, -size_px.y * 0.12)
			ember.scale = Vector2.ONE * start_scale
			ember.modulate.a = 0.82
	)
	tween.tween_property(ember, "position", Vector2(end_x, end_y), life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(ember, "scale", Vector2.ONE * start_scale * 0.34, life)
	tween.parallel().tween_property(ember, "modulate:a", 0.0, life)
	tween.tween_interval(rng.randf_range(0.10, 0.36) / speed)


func _make_smoke_prop(d: Dictionary) -> Node2D:
	var root: Node2D = Node2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.06, 0.12)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	var color: Variant = _parse_html_color(String(d.get("color", "#d8d8cf")), Color(0.78, 0.78, 0.72, 0.22))
	var tex := _make_radial_texture(64, color, Color(color.r, color.g, color.b, 0.0))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "smoke"))
	var smoke_puff_count := maxi(2, roundi(6.0 * _ambient_animation_density()))
	for i in range(smoke_puff_count):
		var puff: Sprite2D = Sprite2D.new()
		puff.texture = tex
		puff.centered = true
		var ox: float = size_px.x * (rng.randf_range(-0.06, 0.06))
		var oy := -size_px.y * rng.randf_range(0.0, 0.10)
		puff.position = Vector2(ox, oy)
		var s := rng.randf_range(0.04, 0.10)
		puff.scale = Vector2.ONE * s
		puff.modulate.a = 0.0
		root.add_child(puff)
		_loop_smoke_puff(puff, size_px, speed, rng.randf_range(0.0, 1.0), rng)
	return root


func _loop_smoke_puff(puff: Sprite2D, size_px: Vector2, speed: float, delay: float, rng: RandomNumberGenerator) -> void:
	var base_pos := puff.position
	var base_scale := puff.scale
	var drift_x := size_px.x * rng.randf_range(-0.03, 0.05)
	var rise_y := -size_px.y * rng.randf_range(0.20, 0.40)
	var grow := rng.randf_range(1.3, 2.0)
	var life := rng.randf_range(1.5, 2.8) / speed
	var tween := puff.create_tween().set_loops()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		if is_instance_valid(puff):
			puff.position = base_pos
			puff.scale = base_scale
			puff.modulate.a = 0.0
	)
	tween.tween_property(puff, "modulate:a", 0.22, life * 0.25)
	tween.parallel().tween_property(puff, "position", base_pos + Vector2(drift_x, rise_y), life)
	tween.parallel().tween_property(puff, "scale", base_scale * grow, life)
	tween.tween_property(puff, "modulate:a", 0.0, life * 0.35)


func _make_mist_drift_prop(d: Dictionary) -> Node2D:
	## Broad low-opacity mist for forests, mountain gates, water edges and cold
	## interiors. A handful of tweened sprites share one radial texture; there is
	## no collision, shader readback or per-frame script update.
	var root := Node2D.new()
	var region_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.45, 0.16)))
	var speed := maxf(0.1, float(d.get("speed", 0.55)))
	var opacity := clampf(float(d.get("opacity", 0.14)), 0.02, 0.30)
	var direction := -1.0 if float(d.get("direction", 1.0)) < 0.0 else 1.0
	var puff_count := clampi(roundi(int(d.get("count", 4)) * _ambient_animation_density()), 1, 6)
	var color: Color = _parse_html_color(String(d.get("color", "#d6e2df")), Color(0.82, 0.88, 0.86, opacity))
	var texture := _make_radial_texture(128, Color(color.r, color.g, color.b, opacity), Color(color.r, color.g, color.b, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "mist_drift"))
	for index in range(puff_count):
		var puff := Sprite2D.new()
		puff.texture = texture
		puff.centered = true
		puff.modulate.a = 0.0
		root.add_child(puff)
		var width_scale := region_px.x / 128.0 * rng.randf_range(0.34, 0.58)
		var height_scale := region_px.y / 128.0 * rng.randf_range(0.42, 0.78)
		puff.scale = Vector2(width_scale, height_scale)
		var start_x := -region_px.x * 0.58 * direction
		var end_x := region_px.x * 0.58 * direction
		var base_y := rng.randf_range(-region_px.y * 0.32, region_px.y * 0.32)
		var life := rng.randf_range(6.0, 9.0) / speed
		var delay := (float(index) / float(puff_count)) * life * 0.65
		var tween := puff.create_tween().set_loops()
		if delay > 0.0:
			tween.tween_interval(delay)
		tween.tween_callback(func() -> void:
			if is_instance_valid(puff):
				puff.position = Vector2(start_x, base_y)
				puff.modulate.a = 0.0
		)
		tween.tween_property(puff, "modulate:a", opacity, life * 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(puff, "position", Vector2(end_x, base_y - region_px.y * 0.08), life).set_trans(Tween.TRANS_SINE)
		tween.tween_property(puff, "modulate:a", 0.0, life * 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_water_shimmer_prop(d: Dictionary) -> Node2D:
	## Sparse reflected streaks for clearly visible rivers, canals and pools.
	## This is not a water simulation: it adds no physics and never distorts the
	## complete baked background.
	var root := Node2D.new()
	var region_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.36, 0.12)))
	var speed := maxf(0.1, float(d.get("speed", 0.65)))
	var opacity := clampf(float(d.get("opacity", 0.18)), 0.04, 0.32)
	var streak_count := clampi(roundi(int(d.get("count", 5)) * _ambient_animation_density()), 1, 8)
	var color: Color = _parse_html_color(String(d.get("color", "#b9e3ef")), Color(0.72, 0.88, 0.94, opacity))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "water_shimmer"))
	for index in range(streak_count):
		var streak := Line2D.new()
		var half_width := region_px.x * rng.randf_range(0.035, 0.080)
		var wave := rng.randf_range(1.0, 3.0)
		streak.points = PackedVector2Array([Vector2(-half_width, 0.0), Vector2(0.0, -wave), Vector2(half_width, 0.0)])
		streak.width = rng.randf_range(1.2, 2.4)
		streak.default_color = Color(color.r, color.g, color.b, 1.0)
		streak.modulate.a = 0.0
		var base_position := Vector2(rng.randf_range(-region_px.x * 0.44, region_px.x * 0.44), rng.randf_range(-region_px.y * 0.40, region_px.y * 0.40))
		streak.position = base_position
		root.add_child(streak)
		var life := rng.randf_range(2.4, 4.2) / speed
		var delay := (float(index) / float(streak_count)) * life * 0.55
		var drift := Vector2(region_px.x * rng.randf_range(0.018, 0.045), region_px.y * rng.randf_range(-0.03, 0.03))
		var tween := streak.create_tween().set_loops()
		if delay > 0.0:
			tween.tween_interval(delay)
		tween.tween_callback(func() -> void:
			if is_instance_valid(streak):
				streak.position = base_position
				streak.modulate.a = 0.0
		)
		tween.tween_property(streak, "modulate:a", opacity, life * 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.parallel().tween_property(streak, "position", base_position + drift, life).set_trans(Tween.TRANS_SINE)
		tween.tween_property(streak, "modulate:a", 0.0, life * 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_snow_drift_prop(d: Dictionary) -> Node2D:
	## One shared flake texture with a bounded number of tweened sprites. Snow is
	## reserved for authored snow scenes; it does not alter navigation or camera.
	var root := Node2D.new()
	var region_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.90, 0.70)))
	var speed := maxf(0.1, float(d.get("speed", 0.75)))
	var opacity := clampf(float(d.get("opacity", 0.42)), 0.08, 0.70)
	var flake_count := clampi(roundi(int(d.get("count", 14)) * _ambient_animation_density()), 4, 18)
	var wind_x := clampf(float(d.get("wind_x", 0.24)), -0.75, 0.75)
	var color: Color = _parse_html_color(String(d.get("color", "#eef5f4")), Color(0.93, 0.97, 0.96, opacity))
	var texture := _make_radial_texture(32, Color(color.r, color.g, color.b, opacity), Color(color.r, color.g, color.b, 0.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "snow_drift"))
	for index in range(flake_count):
		var flake := Sprite2D.new()
		flake.texture = texture
		flake.centered = true
		var flake_scale := rng.randf_range(0.08, 0.18)
		flake.scale = Vector2.ONE * flake_scale
		flake.modulate.a = 0.0
		root.add_child(flake)
		var start := Vector2(rng.randf_range(-region_px.x * 0.50, region_px.x * 0.50), -region_px.y * rng.randf_range(0.45, 0.62))
		var end := Vector2(start.x + region_px.x * wind_x * rng.randf_range(0.72, 1.20), region_px.y * rng.randf_range(0.48, 0.66))
		var life := rng.randf_range(4.6, 7.4) / speed
		var delay := (float(index) / float(flake_count)) * life * 0.72
		var tween := flake.create_tween().set_loops()
		if delay > 0.0:
			tween.tween_interval(delay)
		tween.tween_callback(func() -> void:
			if is_instance_valid(flake):
				flake.position = start
				flake.modulate.a = 0.0
		)
		tween.tween_property(flake, "modulate:a", opacity, life * 0.12)
		tween.parallel().tween_property(flake, "position", end, life).set_trans(Tween.TRANS_SINE)
		tween.parallel().tween_property(flake, "rotation", rng.randf_range(-1.2, 1.2), life)
		tween.tween_property(flake, "modulate:a", 0.0, life * 0.16)
	return root


func _make_rain_field_prop(d: Dictionary) -> Node2D:
	## A camera-safe rain sheet with two procedural depth layers. The cold tint
	## sits behind actors while streaks pass in front, so characters remain clear.
	var root := Node2D.new()
	var region_px := _norm_size_to_screen(d.get("size", Vector2(1.04, 1.04)))
	var speed := maxf(0.1, float(d.get("speed", 1.0)))
	var intensity := clampf(float(d.get("intensity", 0.62)), 0.08, 1.0)
	var opacity := clampf(float(d.get("opacity", 0.52)), 0.08, 0.78)
	var wind_x := clampf(float(d.get("wind_x", 0.18)), -0.80, 0.80)
	var rain_color := _parse_html_color(String(d.get("color", "#aed1dc")), Color(0.68, 0.82, 0.87, 0.92))
	var tint_color := _parse_html_color(String(d.get("tint_color", "#18303d")), Color(0.08, 0.16, 0.21, 0.90))

	var tint := Polygon2D.new()
	tint.name = "RainColdTint"
	tint.z_index = -51
	tint.polygon = PackedVector2Array([
		region_px * Vector2(-0.5, -0.5),
		region_px * Vector2(0.5, -0.5),
		region_px * Vector2(0.5, 0.5),
		region_px * Vector2(-0.5, 0.5),
	])
	tint.color = Color(tint_color.r, tint_color.g, tint_color.b, clampf(float(d.get("tint_opacity", 0.16)), 0.0, 0.30))
	root.add_child(tint)

	var rain_quad := ColorRect.new()
	rain_quad.name = "RainStreaks"
	rain_quad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rain_quad.position = region_px * -0.5
	rain_quad.size = region_px
	var rain_material := ShaderMaterial.new()
	rain_material.shader = ENVIRONMENT_RAIN_SHADER
	rain_material.set_shader_parameter("rain_color", rain_color)
	rain_material.set_shader_parameter("rain_pattern", _get_rain_pattern_texture())
	rain_material.set_shader_parameter("intensity", intensity * _ambient_animation_density())
	rain_material.set_shader_parameter("speed", speed)
	rain_material.set_shader_parameter("slant", wind_x)
	rain_material.set_shader_parameter("aspect_ratio", region_px.x / maxf(region_px.y, 1.0))
	rain_material.set_shader_parameter("phase", float(abs(hash(d.get("id", "rain_field"))) % 7919) / 79.19)
	rain_quad.material = rain_material
	rain_quad.modulate.a = opacity
	root.add_child(rain_quad)
	return root


func _get_rain_pattern_texture() -> ImageTexture:
	## Build one tiny sparse tile when the first rainy scene is entered. The old
	## shader generated several hashes per 1080P pixel every frame; sampling this
	## cached tile twice gives the same near/far depth read at a fraction of that
	## cost. The texture is retained across weather rebuilds in this field.
	if _rain_pattern_texture != null:
		return _rain_pattern_texture
	const PATTERN_SIZE := 128
	var image := Image.create(PATTERN_SIZE, PATTERN_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 0x5241494E
	for _index in range(18):
		var start_x := rng.randi_range(2, PATTERN_SIZE - 4)
		var start_y := rng.randi_range(0, PATTERN_SIZE - 1)
		var length := rng.randi_range(8, 22)
		var alpha := rng.randf_range(0.46, 0.90)
		for step in range(length):
			var x := posmod(start_x + roundi(float(step) * 0.18), PATTERN_SIZE)
			var y := posmod(start_y + step, PATTERN_SIZE)
			var edge_fade := minf(1.0, minf(float(step + 1), float(length - step)) / 3.0)
			var value := alpha * edge_fade
			var previous := image.get_pixel(x, y)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, maxf(previous.a, value)))
			if step % 3 != 0:
				var soft_x := posmod(x + 1, PATTERN_SIZE)
				var soft_previous := image.get_pixel(soft_x, y)
				image.set_pixel(soft_x, y, Color(1.0, 1.0, 1.0, maxf(soft_previous.a, value * 0.24)))
	_rain_pattern_texture = ImageTexture.create_from_image(image)
	return _rain_pattern_texture


func _make_rain_splash_prop(d: Dictionary) -> Node2D:
	## Sparse ground response. Each reusable crown redraws at a new random point
	## every loop; count is capped so large scrolling maps do not pay per-pixel cost.
	var root := Node2D.new()
	var region_px := _norm_size_to_screen(d.get("size", Vector2(0.72, 0.18)))
	var speed := maxf(0.1, float(d.get("speed", 1.0)))
	var opacity := clampf(float(d.get("opacity", 0.46)), 0.08, 0.70)
	var splash_count := clampi(roundi(int(d.get("count", 8)) * _ambient_animation_density()), 3, 12)
	var color := _parse_html_color(String(d.get("color", "#c6e4e9")), Color(0.78, 0.90, 0.92, opacity))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(d.get("id", "rain_splash"))
	for index in range(splash_count):
		var splash := Node2D.new()
		splash.name = "Splash_%02d" % index
		splash.modulate.a = 0.0
		root.add_child(splash)
		var crown := Line2D.new()
		crown.width = rng.randf_range(1.0, 1.7)
		crown.default_color = Color(color.r, color.g, color.b, 1.0)
		crown.antialiased = true
		crown.points = PackedVector2Array([Vector2(-7.0, 1.0), Vector2(-2.2, -3.8), Vector2(0.0, 0.0), Vector2(2.4, -3.5), Vector2(7.0, 1.0)])
		splash.add_child(crown)
		var ring := Line2D.new()
		ring.width = 1.0
		ring.default_color = Color(color.r, color.g, color.b, 0.72)
		ring.antialiased = true
		var ring_points := PackedVector2Array()
		for point_index in range(13):
			var angle := TAU * float(point_index) / 12.0
			ring_points.append(Vector2(cos(angle) * 7.5, sin(angle) * 2.2 + 1.6))
		ring.points = ring_points
		splash.add_child(ring)
		_loop_rain_splash(splash, region_px, speed, opacity, rng.randf_range(0.0, 1.1 / speed), rng)
	return root


func _loop_rain_splash(splash: Node2D, region_px: Vector2, speed: float, opacity: float, delay: float, rng: RandomNumberGenerator) -> void:
	var life := rng.randf_range(0.24, 0.38) / speed
	var pause := rng.randf_range(0.38, 0.92) / speed
	var tween := splash.create_tween().set_loops()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_callback(func() -> void:
		if is_instance_valid(splash):
			splash.position = Vector2(rng.randf_range(-region_px.x * 0.48, region_px.x * 0.48), rng.randf_range(-region_px.y * 0.46, region_px.y * 0.46))
			splash.scale = Vector2(0.38, 0.26)
			splash.modulate.a = 0.0
	)
	tween.tween_property(splash, "modulate:a", opacity, life * 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(splash, "scale", Vector2(1.10, 0.82), life).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(splash, "modulate:a", 0.0, life * 0.76).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_interval(pause)


func _make_glow_prop(d: Dictionary) -> Node2D:
	var root: Node2D = Node2D.new()
	var size_px: Vector2 = _norm_size_to_screen(d.get("size", Vector2(0.08, 0.08)))
	var speed: float = maxf(0.1, float(d.get("speed", 1.0)))
	var color: Variant = _parse_html_color(String(d.get("color", "#ff8a22")), Color(1.0, 0.45, 0.12, 0.55))
	var glow: Sprite2D = Sprite2D.new()
	glow.texture = _make_radial_texture(256, color, Color(color.r, color.g, color.b, 0.0))
	glow.centered = true
	glow.scale = Vector2(size_px.x / 128.0, size_px.y / 128.0)
	glow.modulate.a = 0.45
	root.add_child(glow)
	var tween := root.create_tween().set_loops()
	tween.tween_property(glow, "modulate:a", 0.18, 0.65 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(glow, "modulate:a", 0.52, 0.65 / speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	return root


func _make_radial_texture(size: int, inner: Color, outer: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx: float = size / 2.0
	var cy: float = size / 2.0
	var r: float = size / 2.0
	for y in range(size):
		for x in range(size):
			var dist: float = sqrt((x - cx) ** 2 + (y - cy) ** 2) / r
			var t: float = clampf(dist, 0.0, 1.0)
			var c: Color = inner.lerp(outer, t)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)


func _scale_value(v: Variant) -> Vector2:
	if v is Vector2:
		return v
	if v is float or v is int:
		return Vector2(float(v), float(v))
	return Vector2.ONE


func _ambient_animation_density() -> float:
	if not is_inside_tree():
		return 1.0
	var platform := get_node_or_null("/root/PlatformBridge")
	if platform != null and platform.has_method("ambient_animation_density"):
		return clampf(float(platform.call("ambient_animation_density")), 0.40, 1.0)
	return 1.0


func _parse_html_color(hex_str: String, fallback: Color) -> Color:
	var s := hex_str.strip_edges()
	if s.begins_with("#"):
		s = s.substr(1)
	if s.length() == 6:
		return Color(
			float(("0x" + s.substr(0, 2)).hex_to_int()) / 255.0,
			float(("0x" + s.substr(2, 2)).hex_to_int()) / 255.0,
			float(("0x" + s.substr(4, 2)).hex_to_int()) / 255.0,
			0.9
		)
	return fallback



func _norm_to_screen(value: Variant) -> Vector2:
	var v: Vector2 = value if value is Vector2 else Vector2.ZERO
	return Vector2(v.x * _screen_size.x, v.y * _screen_size.y)


func _norm_size_to_screen(value: Variant) -> Vector2:
	var v: Vector2 = value if value is Vector2 else Vector2(0.1, 0.1)
	return Vector2(v.x * _screen_size.x, v.y * _screen_size.y)


func _on_trigger_zone_entered(body: Node2D, data: Dictionary) -> void:
	if _resident_parked: return
	if not body.is_in_group("player"):
		return
	if LUOYANG_V3.is_v3(_current_scene):
		var foot: Vector2 = world_container.to_local(body.global_position)
		var polygon: PackedVector2Array = data.get("city_v3_interaction_polygon_px", PackedVector2Array())
		if polygon.size() < 3 or not LUOYANG_V3.safe_body(_current_scene.scene_id, foot) or not Geometry2D.is_point_in_polygon(foot, polygon): return
	if DialogPlayer.is_playing():
		return
	var trigger_id: String = String(data.get("id", ""))
	if trigger_id != "" and _trigger_events_in_flight.get(trigger_id, false):
		return
	var require_flag: String = String(data.get("require_flag", ""))
	var hide_flag: String = String(data.get("hide_flag", ""))

	if require_flag != "" and not _flag_truthy(require_flag):
		return
	if hide_flag != "" and _flag_truthy(hide_flag):
		return
	if not _quest_gate_passes(data):
		return
	var action: String = String(data.get("action", ""))

	if action != "":
		if not _city_task_action_allowed(action): return
		if trigger_id != "":
			_trigger_events_in_flight[trigger_id] = true
		# Only an explicitly activated native discovery may retry in place after
		# its real dialogue ends (including the ordinary full-bag fallback).
		var outskirts_biome: String = OUTSKIRTS.biome_for(_current_scene.scene_id) if _current_scene != null else ""
		var native_discovery: bool = not outskirts_biome.is_empty() and trigger_id == "discovery_cache" and bool(data.get("interaction_only", false)) and action == "dialog:outskirts_%s_discovery" % outskirts_biome
		if native_discovery:
			_outskirts_discovery_dialog_pending = true
		_resolve_field_action(action)
		if native_discovery:
			_outskirts_discovery_dialog_pending = false


func _on_trigger_zone_exited(body: Node2D, data: Dictionary) -> void:
	if _resident_parked: return
	if not body.is_in_group("player"):
		return
	var trigger_id: String = String(data.get("id", ""))
	if trigger_id != "":
		_trigger_events_in_flight.erase(trigger_id)


func _on_player_interacted() -> void:
	if DialogPlayer.is_playing():
		return
	if not _uses_enclosure_dispatch_memory():
		_remember_interaction_spawn()
	## 优先检测 NPC 交互
	for npc in _npc_nodes:
		if npc.try_interact():
			return
	## 其次检测出口交互
	for zone in _exit_nodes:
		if zone.try_interact():
			return
	## Finally inspect nearby scene objects. Interaction-only areas are never
	## allowed to interrupt movement on entry; they require the explicit action.
	for area in _trigger_areas:
		if not is_instance_valid(area) or not area.overlaps_body(_player):
			continue
		var trigger_data: Variant = area.get_meta("trigger_data", {})
		if trigger_data is Dictionary and bool(trigger_data.get("interaction_only", false)):
			_on_trigger_zone_entered(_player, trigger_data)
			return


func _on_player_moved(_global_pos: Vector2) -> void:
	if _scene_rebuilding or not is_instance_valid(_player) or _current_scene == null:
		return
	_update_actor_depth(_player)
	var player_spawn := _current_player_spawn()
	# Occlusion polygons and return-payload writes do not need physics-tick
	# precision. Sampling them by travelled pixels removes repeated polygon tests
	# and Dictionary mutations while keeping doorway returns visually exact.
	if (not _occluder_nodes.is_empty() or not _actor_fade_zones.is_empty()) and _sample_moved_enough(_last_occlusion_sample, player_spawn, OCCLUSION_SAMPLE_DISTANCE_PX):
		_update_dynamic_occluders(player_spawn)
		_last_occlusion_sample = player_spawn
	if _sample_moved_enough(_last_return_spawn_sample, player_spawn, RETURN_SPAWN_SAMPLE_DISTANCE_PX):
		SceneRouter.set_field_return_spawn(player_spawn)
		_last_return_spawn_sample = player_spawn
	if _encounter_locked:
		return
	# 城市、村落与安全据点只允许剧情显式发起战斗，绝不滚随机遭遇。
	if _current_scene.is_settlement:
		return
	if (_current_scene.encounter_enemy_ids.is_empty() and _current_scene.encounter_groups.is_empty()) or _current_scene.encounter_step_distance <= 0.0:
		return
	if DialogPlayer.is_playing() or not _player.can_move:
		_last_encounter_position = _player.position
		return
	var required_flag := String(_current_scene.encounter_require_flag)
	if required_flag != "" and not _flag_truthy(required_flag):
		_last_encounter_position = _player.position
		return
	_encounter_distance += _player.position.distance_to(_last_encounter_position)
	_last_encounter_position = _player.position
	if _encounter_distance < _current_scene.encounter_step_distance:
		return
	_encounter_distance = 0.0
	if randf() > clampf(_current_scene.encounter_chance, 0.0, 1.0):
		return
	_encounter_locked = true
	_player.set_can_move(false)
	var enemy_ids := _pick_random_encounter_group()
	if enemy_ids.is_empty():
		_encounter_locked = false
		_player.set_can_move(true)
		return
	_show_toast("敌影逼近！")
	await get_tree().create_timer(0.45).timeout
	SceneRouter.start_encounter(enemy_ids, _current_scene.scene_id, _current_player_spawn())


func _sample_moved_enough(previous: Vector2, current: Vector2, pixel_distance: float) -> bool:
	var pixel_delta := (current - previous) * _screen_size
	return pixel_delta.length_squared() >= pixel_distance * pixel_distance


func _pick_random_encounter_group() -> Array[StringName]:
	var result: Array[StringName] = []
	if _current_scene == null:
		return result
	if not _current_scene.encounter_groups.is_empty():
		var total_weight: float = 0.0
		for group in _current_scene.encounter_groups:
			total_weight += maxf(0.0, float(group.get("weight", 1.0)))
		var roll: float = randf() * total_weight if total_weight > 0.0 else 0.0
		for group in _current_scene.encounter_groups:
			roll -= maxf(0.0, float(group.get("weight", 1.0)))
			if roll <= 0.0:
				var raw_ids: Variant = group.get("enemy_ids", [])
				if raw_ids is Array or raw_ids is PackedStringArray:
					for raw_id in raw_ids:
						var enemy_id := StringName(raw_id)
						if String(enemy_id) != "":
							result.append(enemy_id)
				return result
	if not _current_scene.encounter_enemy_ids.is_empty():
		result.append(StringName(_current_scene.encounter_enemy_ids.pick_random()))
	return result


func get_city_task_projection_state() -> Dictionary:
	return _city_tasks_receipt.duplicate(true)

func _city_task_dialog_allowed(id: String) -> bool:
	if ELEVEN_ROOMS.is_room(_current_scene): return not _resident_parked and ELEVEN_ROOMS.dialog_allowed(_current_scene,id)
	if FUNCTIONAL_INTERIORS.owns_dialog(id): return not _resident_parked and FUNCTIONAL_INTERIORS.dialog_allowed(_current_scene,id)
	if not CITY_TASKS.owns_dialog(id): return true
	return not _resident_parked and CITY_TASKS.authorize_dialog(id,GameState.flags.duplicate(true),QuestManager.states.duplicate(true))

func _city_task_action_allowed(action: String) -> bool:
	return _city_task_dialog_allowed(action.trim_prefix("dialog:")) if action.begins_with("dialog:") else true

func _resolve_field_action(action: String) -> void:
	if not _city_task_action_allowed(action): return
	# Movement retains its low-frequency return cache. An explicit action must
	# capture the final feet, including the last <3px before a spar/other modal.
	_remember_interaction_spawn()
	if action.begins_with("outskirts_entry:"):
		var biome := action.trim_prefix("outskirts_entry:")
		if not OUTSKIRTS.ENTRIES.has(biome) or _current_scene == null: return
		var entry: Dictionary = OUTSKIRTS.ENTRIES[biome]
		if _current_scene.scene_id != entry.source: return
		var data: Dictionary = OUTSKIRTS.authoring_contract(biome)
		if data.is_empty(): return
		if not is_instance_valid(_player) or not _spawn_has_foot_clearance(_current_scene, _outskirts_source_player_foot()): return
		for zone: ExitZone in _exit_nodes:
			if is_instance_valid(zone) and zone.target_scene_id == String(entry.scene):
				zone.try_interact()
				break
		return
	## Preserve the exact exploration position when a local event starts battle.
	if action.begins_with("battle:"):
		var enemy_id := action.trim_prefix("battle:")
		if not enemy_id.is_empty() and _current_scene != null:
			SceneRouter.start_battle(enemy_id, _current_scene.scene_id, _current_player_spawn())
		return
	if action.begins_with("battle_solo:"):
		var enemy_id := action.trim_prefix("battle_solo:")
		if not enemy_id.is_empty() and _current_scene != null:
			SceneRouter.start_solo_battle(enemy_id, _current_scene.scene_id, _current_player_spawn())
		return
	if action.begins_with("battle_group:"):
		var enemy_csv := action.trim_prefix("battle_group:")
		if not enemy_csv.is_empty() and _current_scene != null:
			SceneRouter.start_encounter_csv(enemy_csv, _current_scene.scene_id, _current_player_spawn())
		return
	if action.begins_with("battle_group_then:"):
		var parts := action.split(":", true, 2)
		var enemy_csv := parts[1] if parts.size() > 1 else ""
		var dialog_id := parts[2] if parts.size() > 2 else ""
		if not enemy_csv.is_empty() and _current_scene != null:
			var victory_action := "dialog:%s" % dialog_id if not dialog_id.is_empty() else ""
			SceneRouter.start_encounter_csv(enemy_csv, _current_scene.scene_id, _current_player_spawn(), victory_action)
		return
	if action.begins_with("battle_solo_then:"):
		var parts := action.split(":", true, 2)
		var enemy_id := parts[1] if parts.size() > 1 else ""
		var dialog_id := parts[2] if parts.size() > 2 else ""
		if not enemy_id.is_empty() and _current_scene != null:
			var victory_action := "dialog:%s" % dialog_id if not dialog_id.is_empty() else ""
			SceneRouter.start_solo_battle(enemy_id, _current_scene.scene_id, _current_player_spawn(), victory_action)
		return
	SceneRouter.resolve_action(action)


func _update_actor_depth(actor: Node2D) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	actor.set_meta("depth_band_max", _scene_depth_band_max())
	if actor.has_method("refresh_depth_sort"):
		actor.call("refresh_depth_sort")
		return
	# Eight-pixel bands keep nearby feet in the correct front/back order while
	# still avoiding a z-index rebuild for every single movement pixel.
	var depth_y := actor.global_position.y
	if actor.has_method("get_depth_sort_y"):
		depth_y = float(actor.call("get_depth_sort_y"))
	var depth_band := clampi(int(floor(depth_y / 8.0)), 0, _scene_depth_band_max())
	if actor.z_index != depth_band:
		actor.z_index = depth_band


func _scene_depth_band_max() -> int:
	if SceneRouter.WORLD_V15.is_v15(_current_scene): return 1024
	return 512 if SceneRouter.WORLD_V14.is_v14(_current_scene) else 255


func _uses_enclosure_dispatch_memory() -> bool:
	return _current_scene != null and _current_scene.scene_id in [
		&"ch4_s0_luoyang_gate", &"ch4_s1_luoyang_yamen",
		&"ch4_s2_canal_docks", &"ch4_s3_luoyang_market",
	] and _current_scene.has_meta("city_enclosure_manifest_sha") and LUOYANG_V3.is_v3(_current_scene)


func _remember_interaction_spawn() -> void:
	if _scene_rebuilding or _current_scene == null or not is_instance_valid(_player):
		return
	var exact_spawn := _current_player_spawn()
	SceneRouter.set_field_return_spawn(exact_spawn)
	_last_return_spawn_sample = exact_spawn


func _current_player_spawn() -> Vector2:
	if not is_instance_valid(_player) or _screen_size.x <= 0.0 or _screen_size.y <= 0.0:
		return _current_scene.player_spawn if _current_scene != null else Vector2(0.5, 0.8)
	return Vector2(
		clampf(_player.position.x / _screen_size.x, 0.0, 1.0),
		clampf(_player.position.y / _screen_size.y, 0.0, 1.0)
	)


func _on_npc_interacted(_npc_id: String, dialog_id: String) -> void:
	if _culture_x != null and _culture_x.handles(_npc_id):
		_open_culture_x_menu(_npc_id)
		return
	_on_npc_primary_dialog(_npc_id, dialog_id)


func _on_npc_primary_dialog(_npc_id: String, dialog_id: String, include_opening_24b: bool = true) -> void:
	if not _city_task_dialog_allowed(dialog_id): return
	if dialog_id == "":
		return
	var path := "res://data/dialogs/%s.tres" % dialog_id
	if not ResourceLoader.exists(path):
		push_warning("[FieldWalkable] dialog not found: %s" % path)
		return
	var script: Resource = load(path)
	if script is DialogScript:
		_remember_interaction_spawn()
		var playable_script := _build_active_side_quest_followup(script as DialogScript)
		_player.set_can_move(false)
		# 传递 NPC 头像给对话系统
		for npc in _npc_nodes:
			if npc.npc_id == _npc_id:
				_active_dialog_npc = npc
				npc.begin_conversation(_player.global_position)
				_player.set_walk_direction(npc.global_position - _player.global_position, false)
				DialogPlayer.set_default_portrait(npc.portrait_path)
				DialogPlayer.set_default_speaker(npc.npc_name)
				break
		DialogPlayer.play(_prepare_npc_conversation_24b(playable_script, false, include_opening_24b))
		EventBus.npc_talked_to.emit(StringName(_npc_id))


func _build_active_side_quest_followup(original: DialogScript) -> DialogScript:
	## 数据已配置专属进行中对话时不会走到这里；这个兜底负责尚未补齐
	## variant 的支线NPC，避免玩家反复看到“是否接受”的初次邀约。
	if original == null:
		return original
	for node: DialogNode in original.nodes:
		if node == null or node.accept_quest == &"":
			continue
		var qid := node.accept_quest
		var quest := QuestManager.load_def(qid)
		if quest == null or quest.kind != QuestDef.Kind.SIDE or not QuestManager.is_active(qid):
			continue
		if _dialog_completes_quest(original, qid):
			continue
		if node.on_end.begins_with("battle:") or node.on_end.begins_with("battle_solo:") or node.on_end.begins_with("battle_group:") or node.on_end.begins_with("battle_group_then:") or node.on_end.begins_with("battle_solo_then:") or node.on_end.begins_with("spar:"):
			continue
		var followup := DialogScript.new()
		followup.dialog_id = StringName("runtime_followup_%s" % String(qid))
		followup.entry_node_id = &"start"
		var npc_line := DialogNode.new()
		npc_line.node_id = &"start"
		npc_line.text = "“%s”有进展了吗？" % quest.title
		npc_line.on_end = "next:reply"
		var player_line := DialogNode.new()
		player_line.node_id = &"reply"
		player_line.speaker = "冷孤云"
		player_line.portrait_path = "res://art/characters/protagonist_portrait.png"
		player_line.text = "还在查找。等有了结果，我会回来告诉你。"
		player_line.on_end = "end"
		followup.nodes.assign([npc_line, player_line])
		return followup
	return original


func _dialog_completes_quest(script: DialogScript, qid: StringName) -> bool:
	for node: DialogNode in script.nodes:
		if node != null and node.complete_quest == qid:
			return true
	return false


func _on_npc_action_requested(npc_id: String, action: String) -> void:
	if action == "culture_x_menu":
		_open_culture_x_menu(npc_id)
		return
	_on_npc_primary_action(npc_id, action)


func _on_npc_primary_action(npc_id: String, action: String, include_opening_24b: bool = true) -> void:
	if action.is_empty() or DialogPlayer.is_playing():
		return
	if not _city_task_action_allowed(action): return
	if action.begins_with("spar:"):
		_play_sparring_preface(npc_id, action, include_opening_24b)
		return
	EventBus.npc_talked_to.emit(StringName(npc_id))
	_resolve_field_action(action)


func _play_sparring_preface(npc_id: String, action: String, include_opening_24b: bool = true) -> void:
	# These are the existing confirmation acceptance gates. Capture once before
	# either the normal invitation locks movement or the no-NPC modal fallback.
	if _uses_enclosure_dispatch_memory() and action.begins_with("spar:") and action.split(":", false).size() >= 6 and _sparring_confirm_dialog != null:
		_remember_interaction_spawn()
	var npc: NPCNode = null
	for candidate in _npc_nodes:
		if candidate != null and candidate.npc_id == npc_id:
			npc = candidate
			break
	if npc == null:
		_show_sparring_confirmation(npc_id, action)
		return
	_active_dialog_npc = npc
	npc.begin_conversation(_player.global_position)
	_player.set_walk_direction(npc.global_position - _player.global_position, false)
	_player.set_can_move(false)
	DialogPlayer.set_default_portrait(npc.portrait_path)
	DialogPlayer.set_default_speaker(npc.npc_name)
	_pending_sparring_npc_id = npc_id
	var opponent_name := _sparring_opponent_name(action, npc.npc_name)
	var preface := DialogScript.new()
	preface.dialog_id = StringName("runtime_spar_preface_%s" % npc_id)
	preface.entry_node_id = &"invite"
	var invite := DialogNode.new()
	invite.node_id = &"invite"
	invite.text = "江湖路远，招式贵在印证。%s抱拳一礼：若不嫌弃，可与我点到为止，彼此看看手上功夫。" % opponent_name
	invite.choices = [
		{"text": "请赐教", "next": "ready"},
		{"text": "今日先不打扰", "next": "end"},
	]
	var ready := DialogNode.new()
	ready.node_id = &"ready"
	ready.text = "好。刀兵无眼，心里有数便好。摆开架势吧。"
	ready.on_end = action
	preface.nodes.assign([invite, ready])
	DialogPlayer.play(_prepare_npc_conversation_24b(preface, false, include_opening_24b))


func _sparring_opponent_name(action: String, fallback: String) -> String:
	var parts := action.split(":", false)
	return String(parts[3]) if parts.size() > 3 and not String(parts[3]).is_empty() else fallback


func _on_dialog_spar_requested(action_payload: String) -> void:
	var npc_id := _pending_sparring_npc_id
	if npc_id.is_empty() and is_instance_valid(_active_dialog_npc):
		npc_id = _active_dialog_npc.npc_id
	_show_sparring_confirmation(npc_id, "spar:" + action_payload)


func _init_sparring_confirmation() -> void:
	_sparring_confirm_dialog = FORMAL_CONFIRM_SCENE.instantiate() as FormalConfirmDialog
	_sparring_confirm_dialog.name = "SparringConfirmation"
	_sparring_confirm_dialog.confirmed.connect(_confirm_sparring)
	_sparring_confirm_dialog.cancelled.connect(_cancel_sparring_confirmation)
	_system_ui_canvas_layer.add_child(_sparring_confirm_dialog)


func _show_sparring_confirmation(npc_id: String, action: String) -> void:
	var parts := action.split(":", false)
	if parts.size() < 6 or _sparring_confirm_dialog == null:
		push_warning("[FieldWalkable] invalid sparring action: %s" % action)
		return
	var spar_id := String(parts[1])
	var opponent_name := String(parts[3])
	var win_reward := maxi(0, int(parts[4]))
	var loss_reward := maxi(0, int(parts[5]))
	var record: Dictionary = GameState.sparring_records.get(spar_id, {})
	var reward_note: String
	if bool(record.get("won", false)):
		reward_note = "[color=#92a8aa]你已取得首胜，本次复战没有阅历、经验、金钱或掉落，仅供试招。[/color]"
	elif bool(record.get("loss_reward_claimed", false)):
		reward_note = "[color=#e5c47b]首胜可得阅历 %d。[/color]\n首次败北奖励已领取，再次落败没有奖励。" % win_reward
	else:
		reward_note = "[color=#e5c47b]首次胜利：阅历 %d[/color]\n首次落败：阅历 %d（仅一次，且不影响之后领取首胜奖励）" % [win_reward, loss_reward]
	_pending_sparring_action = action
	_pending_sparring_npc_id = npc_id
	if _player != null:
		_player.set_can_move(false)
	_sparring_confirm_dialog.show_confirm(
		"与%s切磋" % opponent_name,
		"[center]%s\n\n切磋点到为止，战后恢复到切磋前的气血与内力。[/center]" % reward_note,
		"开始切磋",
		"暂不"
	)


func _confirm_sparring() -> void:
	var action := _pending_sparring_action
	var npc_id := _pending_sparring_npc_id
	_pending_sparring_action = ""
	_pending_sparring_npc_id = ""
	if action.is_empty():
		_restore_player_after_sparring_prompt()
		return
	EventBus.npc_talked_to.emit(StringName(npc_id))
	_resolve_field_action(action)


func _cancel_sparring_confirmation() -> void:
	_pending_sparring_action = ""
	_pending_sparring_npc_id = ""
	_restore_player_after_sparring_prompt()


func _restore_player_after_sparring_prompt() -> void:
	if _player != null and not DialogPlayer.is_playing() and not _system_panel_open:
		_player.set_can_move(true)


func _generic_npc_portrait(npc_id: String) -> String:
	# Non-critical NPCs use a small reusable portrait set. Important characters
	# keep their authored portrait_path in scene data and never enter this branch.
	var id := npc_id.to_lower()
	if id.contains("woman") or id.contains("妇") or id.contains("guest"):
		return "res://art/characters/portraits/generic/portrait_generic_young_woman_v1.png"
	if id.contains("old") or id.contains("elder") or id.contains("keeper") or id.contains("掌柜"):
		return "res://art/characters/portraits/generic/portrait_generic_older_man_v1.png"
	if id.contains("vendor") or id.contains("wife"):
		return "res://art/characters/portraits/generic/portrait_generic_older_woman_v1.png"
	return "res://art/characters/portraits/generic/portrait_generic_young_man_v1.png"


func _on_exit_triggered(target_scene: String, target_pos: Vector2, source_portal_spawn: Vector2) -> void:
	# Interior excursions remember the real safe feet used for Space, not just
	# the fixed doorway marker. The room's authored exit remains separately bound.
	if _current_scene!=null and _current_scene.scene_id in FUNCTIONAL_INTERIORS.CITIES and LUOYANG_V3.revision_room_known(StringName(target_scene)):
		var actual:=resident_actual_spawn()
		if not LUOYANG_V3.safe_body(_current_scene.scene_id,actual*LUOYANG_V3.SIZE): return
		source_portal_spawn=actual
	var outskirts_biome := OUTSKIRTS.biome_for(StringName(target_scene))
	if not outskirts_biome.is_empty():
		var entry: Dictionary = OUTSKIRTS.ENTRIES[outskirts_biome]
		if _current_scene == null or _current_scene.scene_id != entry.source or OUTSKIRTS.authoring_contract(outskirts_biome).is_empty(): return
		if not _spawn_has_foot_clearance(_current_scene, entry.source_pos) or not _spawn_has_foot_clearance(_current_scene, _outskirts_source_player_foot()): return
	if StringName(target_scene) == SceneRouter.WORLD_MAP_SCENE:
		if _uses_enclosure_dispatch_memory():
			_remember_interaction_spawn()
		SceneRouter.go_world_map(target_pos)
	else:
		# Remember the authored door anchor, not the last movement sample. The
		# latter may be outside the doorway (mouse interaction radius) or stale by
		# several pixels, which caused room exits to return at unrelated locations.
		SceneRouter.go_field_from_portal(StringName(target_scene), target_pos, source_portal_spawn)

func _outskirts_source_player_foot() -> Vector2:
	if not is_instance_valid(_player): return Vector2(INF, INF)
	return (_player.position + Vector2(0, float(_player.call("_visual_foot_offset")))) / _world_size

func _outskirts_portal_clearance(point: Vector2) -> bool:
	return _current_scene != null and _spawn_has_foot_clearance(_current_scene, point)


func _flag_truthy(key: String) -> bool:
	var v: Variant = GameState.flags.get(key, null)
	if v == null: return false
	if typeof(v) == TYPE_BOOL: return v
	if typeof(v) == TYPE_INT: return v != 0
	if typeof(v) == TYPE_STRING: return v != ""
	return true


# --- UI 样式（与 field_controller.gd 保持一致）---

func _init_field_ui_styles() -> void:
	_hud_btn_normal = _make_hud_style(Color(0.040, 0.058, 0.074, 0.94))
	_hud_btn_hover = _make_hud_style(Color(0.055, 0.145, 0.145, 0.98))
	for b in [inventory_btn, equipment_btn, skill_btn, quest_log_btn]:
		_style_hud_button(b)
	UI_THEME.style_label(scene_title, 24, UI_THEME.GOLD_LIGHT)
	UI_THEME.style_label(player_info, 18, UI_THEME.TEXT, false)
	UI_THEME.style_label(hud_gold, 18, UI_THEME.GOLD, false)
	UI_THEME.style_rich_text(quest_list, 15)
	quest_list.visible = false
	quest_log_btn.visible = false
	UI_THEME.style_label(hint_label, 13, Color(0.78, 0.88, 0.90, 0.86), false)


func _make_hud_style(c: Color) -> StyleBoxFlat:
	var s := UI_THEME.button_style(c, UI_THEME.BLUE_STEEL, 8)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _hud_asset(name: String) -> String:
	return HUD_ART_DIR + "/hud_" + name + ".png"


func _make_tex_rect(node_name: String, asset_name: String, pos: Vector2, sz: Vector2) -> TextureRect:
	var r: TextureRect = TextureRect.new()
	r.name = node_name
	r.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset(asset_name))
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.position = pos
	r.size = sz
	return r


func _init_formal_hud() -> void:
	_primary_hud = FIELD_PRIMARY_HUD_SCENE.instantiate()
	_primary_hud.name = "FieldPrimaryHud"
	_hud_canvas_layer.add_child(_primary_hud)
	_formal_hud_layer = _primary_hud
	_primary_hud.inventory_pressed.connect(_toggle_inventory_panel)
	_primary_hud.equipment_pressed.connect(_toggle_equipment_panel)
	_primary_hud.skill_pressed.connect(_toggle_skill_panel)
	_primary_hud.quest_pressed.connect(_toggle_quest_log_panel)
	_primary_hud.system_pressed.connect(_open_system_menu)


func _apply_formal_hud_mode() -> void:
	if scene_title != null:
		scene_title.visible = false
	if player_info != null:
		player_info.visible = false
	if hud_gold != null:
		hud_gold.visible = false
	if quest_list != null:
		quest_list.visible = false
	if hint_bar != null:
		hint_bar.visible = false
	if inventory_btn != null:
		inventory_btn.visible = false
	if equipment_btn != null:
		equipment_btn.visible = false
	if skill_btn != null:
		skill_btn.visible = false
	if quest_log_btn != null:
		quest_log_btn.visible = false
	# The formal HUD owns the textured system button. Keep the legacy plain
	# Button wired for compatibility, but never show two menu controls.
	if system_btn != null:
		system_btn.visible = false


func _build_player_info_panel() -> void:
	var panel := _make_tex_rect("PlayerPanel", "player_panel", Vector2(10, 10), Vector2(340, 98))
	_formal_hud_layer.add_child(panel)

	var portrait: TextureRect = TextureRect.new()
	portrait.name = "Portrait"
	portrait.position = Vector2(22, 22)
	portrait.size = Vector2(44, 44)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var pp: String = GameState.player.portrait_path if GameState.player != null else ""
	if pp == "":
		pp = "res://art/characters/protagonist_neutral.png"
	if ResourceLoader.exists(pp):
		portrait.texture = load(pp)
	_formal_hud_layer.add_child(portrait)
	_formal_portrait = portrait

	var name_label: Label = Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(76, 14)
	name_label.size = Vector2(180, 18)
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", UI_THEME.TEXT)
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.62))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	_formal_hud_layer.add_child(name_label)
	_formal_name_label = name_label

	var hp_label: Label = Label.new()
	hp_label.name = "HpLabel"
	hp_label.position = Vector2(76, 40)
	hp_label.size = Vector2(30, 14)
	hp_label.text = "生命"
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.82, 0.85))
	_formal_hud_layer.add_child(hp_label)

	var hp_bg: TextureRect = TextureRect.new()
	hp_bg.name = "HpBg"
	hp_bg.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("hp_bg"))
	hp_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hp_bg.stretch_mode = TextureRect.STRETCH_SCALE
	hp_bg.position = Vector2(108, 40)
	hp_bg.size = Vector2(160, 14)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(hp_bg)

	var hp_fill: TextureRect = TextureRect.new()
	hp_fill.name = "HpFill"
	hp_fill.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("hp_fill"))
	hp_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hp_fill.stretch_mode = TextureRect.STRETCH_SCALE
	hp_fill.position = Vector2(108, 40)
	hp_fill.size = Vector2(160, 14)
	hp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(hp_fill)
	_formal_hp_bar = hp_fill

	var mp_label: Label = Label.new()
	mp_label.name = "MpLabel"
	mp_label.position = Vector2(76, 60)
	mp_label.size = Vector2(30, 14)
	mp_label.text = "内力"
	mp_label.add_theme_font_size_override("font_size", 11)
	mp_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.82, 0.85))
	_formal_hud_layer.add_child(mp_label)

	var mp_bg: TextureRect = TextureRect.new()
	mp_bg.name = "MpBg"
	mp_bg.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("mp_bg"))
	mp_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mp_bg.stretch_mode = TextureRect.STRETCH_SCALE
	mp_bg.position = Vector2(108, 60)
	mp_bg.size = Vector2(160, 14)
	mp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(mp_bg)

	var mp_fill: TextureRect = TextureRect.new()
	mp_fill.name = "MpFill"
	mp_fill.texture = UI_TEXTURE_SKIN.load_texture(_hud_asset("mp_fill"))
	mp_fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mp_fill.stretch_mode = TextureRect.STRETCH_SCALE
	mp_fill.position = Vector2(108, 60)
	mp_fill.size = Vector2(160, 14)
	mp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_formal_hud_layer.add_child(mp_fill)
	_formal_mp_bar = mp_fill

	var gold_label: Label = Label.new()
	gold_label.name = "GoldLabel"
	gold_label.position = Vector2(76, 78)
	gold_label.size = Vector2(180, 16)
	gold_label.add_theme_font_size_override("font_size", 13)
	gold_label.add_theme_color_override("font_color", Color(0.86, 0.82, 0.50, 0.94))
	gold_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.58))
	gold_label.add_theme_constant_override("shadow_offset_x", 1)
	gold_label.add_theme_constant_override("shadow_offset_y", 1)
	_formal_hud_layer.add_child(gold_label)
	_formal_gold_label = gold_label


func _build_scene_name_badge() -> void:
	var badge := _make_tex_rect("SceneBadgeBg", "scene_badge", Vector2(1730, 10), Vector2(180, 26))
	_formal_hud_layer.add_child(badge)
	var label: Label = Label.new()
	label.name = "FormalSceneLabel"
	label.position = badge.position
	label.size = badge.size
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.94, 0.92))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formal_hud_layer.add_child(label)
	_formal_scene_label = label


func _build_quest_display() -> void:
	var panel := _make_tex_rect("QuestPanel", "quest_panel", Vector2(1600, 46), Vector2(300, 100))
	_formal_hud_layer.add_child(panel)


func _build_bottom_bar() -> void:
	var bar := _make_tex_rect("BottomBar", "bottom_bar", Vector2(0, 937), Vector2(1920, 143))
	_formal_hud_layer.add_child(bar)
	_formal_bottom_bar = bar
	var label: Label = Label.new()
	label.name = "FormalHintLabel"
	label.position = Vector2(0, 955)
	label.size = Vector2(1920, 30)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.82, 0.90, 0.94, 0.90))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_formal_hud_layer.add_child(label)
	_formal_hint_label = label


func _init_hud_right_buttons() -> void:
	var btn_keys := ["inventory", "equipment", "skill", "quest", "system"]
	var positions := [
		Vector2(1670, 120),
		Vector2(1670, 218),
		Vector2(1670, 316),
		Vector2(1670, 414),
		Vector2(1670, 512),
	]
	for i in range(btn_keys.size()):
		var key: String = btn_keys[i]
		var tex_normal := UI_TEXTURE_SKIN.load_texture(_hud_asset("btn_" + key + "_normal"))
		if tex_normal == null:
			continue
		var btn: TextureButton = TextureButton.new()
		btn.name = "FormalBtn_" + key.capitalize()
		btn.texture_normal = tex_normal
		btn.texture_hover = UI_TEXTURE_SKIN.load_texture(_hud_asset("btn_" + key + "_hover"))
		btn.texture_pressed = UI_TEXTURE_SKIN.load_texture(_hud_asset("btn_" + key + "_pressed"))
		btn.position = positions[i]
		btn.mouse_filter = Control.MOUSE_FILTER_STOP
		_formal_hud_layer.add_child(btn)
		match key:
			"inventory": btn.pressed.connect(_toggle_inventory_panel)
			"equipment": btn.pressed.connect(_toggle_equipment_panel)
			"skill": btn.pressed.connect(_toggle_skill_panel)
			"quest": btn.pressed.connect(_toggle_quest_log_panel)
func _style_hud_button(btn: Button) -> void:
	UI_THEME.style_button(btn, 16, UI_THEME.BLUE_STEEL)
	btn.add_theme_stylebox_override("normal", _hud_btn_normal)
	btn.add_theme_stylebox_override("hover", _hud_btn_hover)
	btn.add_theme_stylebox_override("pressed", _hud_btn_hover)
	btn.add_theme_stylebox_override("focus", _hud_btn_hover)
	btn.add_theme_color_override("font_color", UI_THEME.TEXT)


# --- 信号回调 ---

func _on_flag_set(_flag: StringName, _v: Variant) -> void:
	if _culture_committing:
		_scene_refresh_pending = true
		return
	## flag 变化可能解锁/隐藏 NPC/出口/触发区，重新生成场景元素。
	## 对话中重建会把玩家原地放进新的 Area2D，造成同一对话再次触发。
	if DialogPlayer.is_playing():
		_scene_refresh_pending = true
		return
	_refresh_scene_preserving_player()


func _on_active_quests_changed() -> void:
	_refresh_quest_panel()
	if _culture_committing:
		_scene_refresh_pending = true
		return
	# 采集物、任务宝箱等场景元素以任务状态为显示条件。接受或完成
	# 任务后必须重建当前场景，不能等玩家切图后才看到变化。
	if DialogPlayer.is_playing():
		_scene_refresh_pending = true
		return
	_refresh_scene_preserving_player()


func _quest_gate_passes(data: Dictionary) -> bool:
	var active_qid := StringName(String(data.get("require_quest_active", "")))
	if active_qid != &"" and not QuestManager.is_active(active_qid):
		return false
	var completed_qid := StringName(String(data.get("require_quest_completed", "")))
	if completed_qid != &"" and not QuestManager.is_completed(completed_qid):
		return false
	return true


func _refresh_scene_preserving_player() -> void:
	if _current_scene == null or _scene_rebuilding:
		return
	if SceneRouter.RESIDENT_CITY.extended_enabled() and LUOYANG_V3.owns_id(_current_scene.scene_id) and not LUOYANG_V3.resident_receipt(_current_scene).is_empty():
		_scene_rebuilding=true
		if is_instance_valid(_player): _player.set_can_move(false)
		# Flag changes may originate in a physics callback. Mutate bodies outside
		# that flushing query and coalesce multiple same-frame quest signals.
		await get_tree().process_frame
		if not is_inside_tree() or _resident_parked: _scene_rebuilding=false; return
		var refreshed: bool=await _resident_refresh_dynamic()
		_scene_rebuilding=false
		if not refreshed:
			_field_loading_failed=true; _field_loading_complete=false; _field_loading_stage="城市动态投影失败"
		elif is_instance_valid(_player) and not DialogPlayer.is_playing(): _player.set_can_move(true)
		return
	var spawn := _current_scene.player_spawn
	if is_instance_valid(_player) and _screen_size.x > 0.0 and _screen_size.y > 0.0:
		spawn = Vector2(
			clampf(_player.position.x / _screen_size.x, 0.0, 1.0),
			clampf(_player.position.y / _screen_size.y, 0.0, 1.0)
		)
	_setup_scene(_current_scene, spawn)


func _apply_pending_scene_refresh() -> void:
	if not _scene_refresh_pending:
		return
	_scene_refresh_pending = false
	_refresh_scene_preserving_player()


func _on_gold_changed(_n: int) -> void:
	_refresh_gold()


func _on_reputation_changed(_value: int, _title: String) -> void:
	_refresh_gold()


func _on_dialog_started(_id: StringName) -> void:
	if _outskirts_discovery_dialog_pending and OUTSKIRTS.is_native(_current_scene):
		_outskirts_discovery_dialog_id = _id
		_outskirts_discovery_dialog_pending = false
	if is_instance_valid(_player):
		_player.set_can_move(false)
	if _primary_hud != null:
		_primary_hud.set_hint_visible(false)
	if _formal_bottom_bar != null:
		_formal_bottom_bar.visible = false
	if _formal_hint_label != null:
		_formal_hint_label.visible = false

func _on_dialog_ended(_id: StringName) -> void:
	var culture_primary: Dictionary = {}
	if _culture_x != null:
		_culture_committing = true
		var culture: Dictionary = _culture_x.finish(_id)
		_culture_committing = false
		if culture.get("ignore_stale_dialog_end", false): return
		if culture.get("ok") != true:
			_show_toast("本次核对未能确认，进度未变。")
		elif culture.get("primary") is Dictionary:
			culture_primary = culture
		elif culture.get("feedback") is DialogScript:
			if is_instance_valid(_active_dialog_npc):
				DialogPlayer.set_default_portrait(_active_dialog_npc.portrait_path)
				DialogPlayer.set_default_speaker(_active_dialog_npc.npc_name)
			DialogPlayer.play(culture.feedback)
			return
	if OUTSKIRTS.is_native(_current_scene) and _outskirts_discovery_dialog_id != &"" and _id == _outskirts_discovery_dialog_id:
		_trigger_events_in_flight.erase("discovery_cache")
		_outskirts_discovery_dialog_id = &""
	if is_instance_valid(_active_dialog_npc):
		_active_dialog_npc.end_conversation()
	_active_dialog_npc = null
	if is_instance_valid(_player) and not _scene_rebuilding and not (_sparring_confirm_dialog != null and _sparring_confirm_dialog.visible):
		_player.set_can_move(true)
	if _primary_hud != null:
		_primary_hud.set_hint_visible(true)
	if _formal_bottom_bar != null:
		_formal_bottom_bar.visible = true
	if _formal_hint_label != null:
		_formal_hint_label.visible = true
	if _scene_refresh_pending:
		call_deferred("_apply_pending_scene_refresh")
	if not culture_primary.is_empty(): call_deferred("_play_culture_x_primary", culture_primary)


func _on_culture_x_text_displayed(_speaker: String, _text: String, _choices: bool, _portrait: String) -> void:
	if _culture_x != null: _culture_x.observe_node()


func _open_culture_x_menu(npc_id: String) -> void:
	if _culture_x == null or DialogPlayer.is_playing() or _resident_parked or _scene_rebuilding: return
	var opened: Dictionary = _culture_x.open(npc_id)
	if opened.get("ok") != true:
		_show_toast("先靠近当事人，再核对这件事。")
		return
	_remember_interaction_spawn()
	_active_dialog_npc = opened.npc
	_active_dialog_npc.begin_conversation(_player.global_position)
	_player.set_walk_direction(_active_dialog_npc.global_position - _player.global_position, false)
	_player.set_can_move(false)
	DialogPlayer.set_default_portrait(_active_dialog_npc.portrait_path)
	DialogPlayer.set_default_speaker(_active_dialog_npc.npc_name)
	DialogPlayer.play(_prepare_npc_conversation_24b(opened.script, true))


func _play_culture_x_primary(result: Dictionary) -> void:
	if _culture_x == null or not _culture_x.handles(String(result.get("npc_id", ""))) or DialogPlayer.is_playing(): return
	for npc: NPCNode in _npc_nodes:
		if is_instance_valid(npc) and npc.npc_id == result.npc_id and npc.global_position.distance_to(_player.global_position) <= 118.0:
			var primary: Dictionary = result.primary
			if not String(primary.get("interaction_action", "")).is_empty(): _on_npc_primary_action(npc.npc_id, primary.interaction_action, false)
			elif not String(primary.get("dialog_id", "")).is_empty(): _on_npc_primary_dialog(npc.npc_id, primary.dialog_id, false)
			return


func get_culture_integration_state() -> Dictionary:
	return _culture_x.debug_state() if _culture_x != null else {"enabled": false, "session_active": false}


func _prepare_npc_conversation_24b(script: DialogScript, preserve_instance: bool, include_opening: bool = true) -> DialogScript:
	# Only actual, currently selected NPC conversations. Auto scene narrative,
	# combat, feedback continuations and DP's global entrypoints are untouched.
	if not include_opening or not is_instance_valid(_active_dialog_npc) or _current_scene == null: return script
	if script == null: return script
	# Match DP.play's existing gate resolution before adding the real greeting.
	# Never play an inaccessible source or move its effects into the safe fallback.
	var playable_24b: DialogScript = script
	if not DialogPlayer.can_play_script(playable_24b):
		playable_24b = DialogPlayer._early_visit_dialog(playable_24b)
		if playable_24b == null or not DialogPlayer.can_play_script(playable_24b):
			push_warning("[NPC conversation] existing safe fallback could not be resolved")
			return script
		# Present generated fallback, never retain a lease on the blocked graph.
		# Current generated culture scripts have no story/inventory gate; this is
		# a defensive cancellation, with no new dialog/quest/state event emitted.
		if preserve_instance and _culture_x != null:
			_culture_x.abort("blocked_graph_replaced_with_original_safe_fallback")
	var npc: NPCNode = _active_dialog_npc
	var key: String = String(_current_scene.scene_id) + "|" + npc.npc_id
	var visit: int = int(_npc_conversation_visits_24b.get(key, 0))
	var pure_daily: bool = playable_24b == script and (npc.get_meta("ap_daily_exact_identity", false) == true or npc.get_meta("ap_quarter_daily_exact_identity", false) == true)
	var hero_name: String = GameState.player.display_name if GameState.player != null else "冷孤云"
	var hero_portrait: String = GameState.player.portrait_path if GameState.player != null else ""
	hero_portrait = _npc_hero_portrait_24b(hero_portrait)
	var prepared: Dictionary = NPC_CONVERSATION_24B.prepare(playable_24b, String(_current_scene.scene_id), npc.npc_id, npc.npc_name, hero_name, hero_portrait, visit, pure_daily, preserve_instance)
	if prepared.get("ok") != true:
		push_warning("[NPC conversation] presentation left unchanged: " + String(prepared.get("error", "unknown")))
		return playable_24b
	_npc_conversation_visits_24b[key] = visit + 1
	return prepared.script as DialogScript


func _npc_hero_portrait_24b(raw: String) -> String:
	if not raw.is_empty() and ResourceLoader.exists(raw):
		var texture_24b: Texture2D = load(raw) as Texture2D
		if texture_24b != null: return raw
	return NPC_CONVERSATION_24B.HERO_PORTRAIT


func _refresh_gold() -> void:
	var p: CharacterStats = GameState.player
	if p != null:
		if player_info != null:
			player_info.text = "%s  Lv.%d  生命 %d/%d  内力 %d/%d" % [p.display_name, p.level, p.hp, p.max_hp, p.mp, p.max_mp]
		if _formal_name_label != null:
			_formal_name_label.text = "%s  Lv.%d" % [p.display_name, p.level]
		if _formal_hp_bar != null:
			_formal_hp_bar.size.x = 160.0 * clampf(float(p.hp) / float(p.max_hp), 0.0, 1.0)
		if _formal_mp_bar != null:
			_formal_mp_bar.size.x = 160.0 * clampf(float(p.mp) / float(p.max_mp), 0.0, 1.0)
		if _primary_hud != null:
			_primary_hud.set_player_stats(p, GameState.gold)
	if hud_gold != null:
		hud_gold.text = "金 %d · 声望 %d" % [GameState.gold, GameState.reputation]
	if _formal_gold_label != null:
		_formal_gold_label.text = "金 %d" % GameState.gold
	if _primary_hud != null and p == null:
		_primary_hud.set_hint_text("WASD 移动   空格/Enter 交互   C 角色   K 武学   J 任务   Esc 关闭")


func _refresh_quest_panel() -> void:
	if quest_list == null:
		return
	var actives := QuestManager.get_active_quests()
	if actives.is_empty():
		quest_list.text = "[i]暂无任务[/i]"
		if _primary_hud != null:
			_primary_hud.set_quest_tracker("", "", "", "")
		return
	var lines: Array[String] = []
	for q in actives:
		var prefix: String = "[color=#e3a64a]●[/color] " if (q as QuestDef).kind == QuestDef.Kind.MAIN else "[color=#88aabb]○[/color] "
		lines.append("%s[b]%s[/b]\n  %s" % [prefix, (q as QuestDef).title, (q as QuestDef).desc_in_progress])
	quest_list.text = "\n\n".join(lines)
	if _primary_hud != null:
		var main_quest := QuestManager.get_current_main_quest()
		var tracked_side := QuestManager.get_tracked_side_quest()
		_primary_hud.set_quest_tracker(
			main_quest.title if main_quest != null else "",
			main_quest.get_tracker_hint() if main_quest != null else "",
			tracked_side.title if tracked_side != null else "",
			tracked_side.get_tracker_hint() if tracked_side != null else ""
		)


func _on_tracked_quest_changed(_qid: StringName) -> void:
	_refresh_quest_panel()


func _on_quest_accepted(qid: StringName) -> void:
	var def: QuestDef = QuestManager.load_def(qid)
	if def == null:
		return
	_item_toast_lines.append("[color=#72d2a6]接收任务：[/color][color=#f0d8ad]%s[/color]" % def.title)
	_show_item_toast()


func _on_quest_progressed(qid: StringName) -> void:
	var def := QuestManager.load_def(qid)
	if def == null:
		return
	var records := QuestManager.get_progress_record_texts(qid)
	var latest := records[-1] if not records.is_empty() else "发现了新的调查进展"
	_item_toast_lines.append("[color=#e3a64a]任务推进：[/color][color=#f0d8ad]%s[/color]\n[color=#9fd3d0]%s[/color]" % [def.title, latest])
	_show_item_toast()


func _on_evidence_acquired(evidence_id: StringName) -> void:
	var evidence := InvestigationState.load_evidence_def(evidence_id)
	if evidence == null:
		return
	_item_toast_lines.append("[color=#e3a64a]获得线索：[/color][color=#72d2c9]%s[/color]" % evidence.display_name)
	_show_item_toast()


func _on_companion_joined(_companion_id: StringName, display_name: String) -> void:
	_item_toast_lines.append("[color=#e3a64a]队友加入：[/color][color=#72d2a6]%s[/color]" % display_name)
	_show_item_toast()


func _on_quest_completed(qid: StringName) -> void:
	var def: QuestDef = QuestManager.load_def(qid)
	if def != null:
		print("[FieldWalkable] quest completed → %s（gold +%d, exp +%d）" % [def.title, def.reward_gold, def.reward_exp])
		_item_toast_lines.append("[color=#e3a64a]完成任务：[/color][color=#f0d8ad]%s[/color]" % def.title)
		_show_item_toast()


func _on_item_picked_up(item_id: StringName, count: int) -> void:
	var item := Inventory.load_item_by_id(item_id)
	var display_name := String(item_id)
	var q_color: String = "#c0c8d0"
	if item != null:
		display_name = item.display_name
		if item.category == Item.Category.CONSUMABLE:
			q_color = "#e3a64a"
		else:
			q_color = _quality_color(item.quality)
	_item_toast_lines.append("[color=#8899aa]获得[/color] [color=%s]%s[/color] × %d" % [q_color, display_name, count])
	if item_id == &"linxi_iron_sword" and not bool(GameState.flags.get("seen_linxi_sword_equip_tip", false)):
		_item_toast_lines.append("[color=#e3a64a]提示：[/color][color=#9fd3d0]装备剑后，方可使用林西剑法。[/color]")
		GameState.set_flag(&"seen_linxi_sword_equip_tip", true)
	_show_item_toast()


func _on_skill_learned(skill_id: StringName, display_name: String) -> void:
	var skill_path := "res://data/skills/%s.tres" % String(skill_id)
	var skill := load(skill_path) as Skill if ResourceLoader.exists(skill_path) else null
	var quality_color := _quality_color(skill.quality) if skill != null else "#c0c8d0"
	var learned_type := "心法" if skill != null and skill.is_internal_art else "招式"
	_item_toast_lines.append("[color=#e3a64a]学会%s：[/color][color=%s]%s[/color]" % [learned_type, quality_color, display_name])
	_show_item_toast()


func _quality_color(q: int) -> String:
	match q:
		1: return "#1eff00"
		2: return "#0070dd"
		3: return "#a335ee"
		4: return "#ff8000"
		_: return "#c0c8d0"


func _show_item_toast() -> void:
	if _item_toast == null or not is_instance_valid(_item_toast):
		_item_toast = RichTextLabel.new()
		_item_toast.bbcode_enabled = true
		_item_toast.fit_content = true
		_item_toast.position = Vector2(_viewport_size.x / 2 - 190, _viewport_size.y * 0.22)
		_item_toast.custom_minimum_size = Vector2(380, 44)
		_item_toast.add_theme_font_size_override("normal_font_size", 20)
		_item_toast.add_theme_color_override("default_color", Color(0.88, 0.92, 0.96, 1.0))
		_item_toast.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.98))
		_item_toast.add_theme_constant_override("outline_size", 5)
		_item_toast.add_theme_constant_override("line_spacing", 4)
		_hud_canvas_layer.add_child(_item_toast)
	_item_toast.text = "\n".join(_item_toast_lines)
	_item_toast_serial += 1
	var serial := _item_toast_serial
	await get_tree().create_timer(2.5).timeout
	if serial != _item_toast_serial or not is_instance_valid(_item_toast):
		return
	_item_toast_lines.clear()
	_item_toast.queue_free()
	_item_toast = null


func _show_toast(text: String) -> void:
	var toast: Label = Label.new()
	toast.text = text
	toast.position = Vector2(_viewport_size.x / 2 - 150, _viewport_size.y * 0.25)
	toast.custom_minimum_size = Vector2(300, 40)
	toast.add_theme_color_override("font_color", Color(0.98, 0.92, 0.62, 1))
	toast.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.03, 0.98))
	toast.add_theme_constant_override("outline_size", 5)
	toast.add_theme_font_size_override("font_size", 20)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hud_canvas_layer.add_child(toast)
	var expiry := toast.create_tween()
	expiry.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	expiry.tween_interval(2.5)
	expiry.tween_callback(toast.queue_free)


func _on_quest_log_pressed() -> void:
	_toggle_quest_log_panel()


func _open_quest_log_panel() -> void:
	if _quest_panel_full == null:
		return
	if _inventory_panel != null:
		var d: ColorRect = _inventory_panel.get_node_or_null("Dim")
		if d: d.visible = true
		_inventory_panel.visible = false
	if _equipment_panel != null:
		_equipment_panel.visible = false
	if _skill_panel != null:
		_skill_panel.visible = false
	_quest_panel_full.open()
	_on_system_panel_opened()

func _toggle_quest_log_panel() -> void:
	if _quest_panel_full == null:
		return
	if _quest_panel_full.visible:
		_quest_panel_full.close()
	else:
		_open_quest_log_panel()


func _on_ui_requested(panel_id: StringName) -> void:
	if DialogPlayer.is_playing():
		return
	if not _panels_ready:
		return
	match panel_id:
		&"inventory":
			_open_inventory_panel()
		&"world_map":
			_open_world_map_panel()
		&"close_equipment":
			if _equipment_panel:
				_equipment_panel.visible = false
		&"equipment":
			_open_equipment_panel()
		&"skills":
			_open_skill_panel()
		&"quest_log":
			_open_quest_log_panel()


func _open_world_map_panel() -> void:
	if _world_map_panel == null:
		_world_map_panel = WORLD_MAP_PANEL_SCENE.instantiate() as WorldMapPanel
		_system_ui_canvas_layer.add_child(_world_map_panel)
		_world_map_panel.closed.connect(_on_system_panel_closed)
	_world_map_panel.open()
	_on_system_panel_opened()


func _init_m5_panels() -> void:
	_inventory_panel = INVENTORY_PANEL_SCENE.instantiate()
	_equipment_panel = EQUIPMENT_PANEL_SCENE.instantiate()
	_skill_panel = SKILL_PANEL_SCENE.instantiate()
	_quest_panel_full = QUEST_PANEL_SCENE.instantiate()
	_system_ui_canvas_layer.add_child(_inventory_panel)
	_inventory_panel.visible = false
	_system_ui_canvas_layer.add_child(_equipment_panel)
	_equipment_panel.visible = false
	_system_ui_canvas_layer.add_child(_skill_panel)
	_skill_panel.visible = false
	_system_ui_canvas_layer.add_child(_quest_panel_full)
	# 面板自行关闭时（ESC/关闭按钮），也要恢复主 HUD
	_inventory_panel.closed.connect(_on_system_panel_closed)
	_equipment_panel.closed.connect(_on_system_panel_closed)
	_panels_ready = true
	_skill_panel.closed.connect(_on_system_panel_closed)
	_quest_panel_full.closed.connect(_on_system_panel_closed)


func _open_inventory_panel() -> void:
	if _inventory_panel == null:
		return
	# Restore MainPanel center
	var mp: Control = _inventory_panel.get_node_or_null("MainPanel")
	if mp:
		mp.offset_left = -640
		mp.offset_right = 640
		mp.offset_top = -360
		mp.offset_bottom = 360
	var dim: ColorRect = _inventory_panel.get_node_or_null("Dim")
	if dim:
		dim.visible = true
	# Reset to "all" tab when opening via I (not via equipment)
	_inventory_panel.call("_set_filter_internal", "all", false)
	if _equipment_panel != null:
		_equipment_panel.visible = false
	if _skill_panel != null:
		_skill_panel.visible = false
	if _quest_panel_full != null:
		_quest_panel_full.visible = false
	_inventory_panel.open()
	_on_system_panel_opened()

func _toggle_inventory_panel() -> void:
	if _inventory_panel == null:
		return
	# If equipment is open, close both
	if _equipment_panel != null and _equipment_panel.visible:
		_close_all_system_panels()
		return
	if _inventory_panel.visible:
		_inventory_panel.close()
	else:
		_open_inventory_panel()


func _open_equipment_panel() -> void:
	if _equipment_panel == null:
		_init_m5_panels()
	if _equipment_panel == null:
		return
	if _inventory_panel != null:
		_inventory_panel.visible = false
	if _skill_panel != null:
		_skill_panel.visible = false
	if _quest_panel_full != null:
		_quest_panel_full.visible = false
	_equipment_panel.open()
	_on_system_panel_opened()

func _toggle_equipment_panel() -> void:
	if _equipment_panel == null:
		return
	if _equipment_panel.visible:
		_equipment_panel.close()
	else:
		_open_equipment_panel()


func _open_skill_panel() -> void:
	if _skill_panel == null:
		return
	if _inventory_panel != null:
		var d: ColorRect = _inventory_panel.get_node_or_null("Dim")
		if d: d.visible = true
		_inventory_panel.visible = false
	if _equipment_panel != null:
		_equipment_panel.visible = false
	if _quest_panel_full != null:
		_quest_panel_full.visible = false
	_skill_panel.open()
	_on_system_panel_opened()

func _toggle_skill_panel() -> void:
	if _skill_panel == null:
		return
	if _skill_panel.visible:
		_skill_panel.close()
	else:
		_open_skill_panel()


var _system_panel_open: bool = false


func _pointer_hits_sprite(sprite: Sprite2D, viewport_point: Vector2, padding: float = 0.0) -> bool:
	if LUOYANG_V3.is_v3(_current_scene) and sprite != null and String(sprite.name) != "MarkerVisual": return _city_alpha.hits(sprite, viewport_point)
	if sprite == null or sprite.texture == null or not sprite.is_visible_in_tree():
		return false
	var transform := sprite.get_global_transform_with_canvas()
	var local_point := transform.affine_inverse() * viewport_point
	# Padding is in viewport pixels, independent of camera zoom / sprite scale.
	var scale_min := maxf(0.001, minf(transform.x.length(), transform.y.length()))
	return sprite.get_rect().grow(padding / scale_min).has_point(local_point)


func _pointer_hits_area(area: Area2D, viewport_point: Vector2) -> bool:
	if not is_instance_valid(area) or not area.is_visible_in_tree():
		return false
	for child in area.get_children():
		if (area.has_method("configure_doorway") or LUOYANG_V3.is_v3(_current_scene)) and child is CollisionPolygon2D and not child.disabled:
			var polygon_point: Vector2 = child.get_global_transform_with_canvas().affine_inverse() * viewport_point
			if Geometry2D.is_point_in_polygon(polygon_point, child.polygon): return true
		if not child is CollisionShape2D or child.disabled or child.shape == null:
			continue
		var point: Vector2 = child.get_global_transform_with_canvas().affine_inverse() * viewport_point
		if child.shape is RectangleShape2D and Rect2(-child.shape.size * 0.5, child.shape.size).has_point(point):
			return true
		if child.shape is CircleShape2D and point.length_squared() <= child.shape.radius * child.shape.radius:
			return true
	return false


func _dispatch_pointer_interaction(viewport_point: Vector2) -> bool:
	if _scene_rebuilding or _system_panel_open or _encounter_locked or DialogPlayer.is_playing():
		return false
	if not is_instance_valid(_player) or not _player.can_move:
		return false
	if not _uses_enclosure_dispatch_memory():
		_remember_interaction_spawn()
	# Click the drawn arrow, not its distant ground trigger. Marker > NPC >
	# prop > bare exit ground. Nearest marker wins; authored order breaks ties.
	var picked_exit: ExitZone = null
	var nearest := INF
	for zone in _exit_nodes:
		if not is_instance_valid(zone) or not _pointer_hits_sprite(zone.marker_visual, viewport_point, 9.0):
			continue
		var distance: float = (zone.marker_visual.get_global_transform_with_canvas().origin - viewport_point).length_squared()
		if distance < nearest:
			picked_exit = zone
			nearest = distance
	if picked_exit != null:
		if not picked_exit.try_interact():
			_show_toast("请靠近出口后再点击")
		return true
	var picked_npc: NPCNode = null
	var front_y := -INF
	for npc in _npc_nodes:
		if is_instance_valid(npc) and _pointer_hits_sprite(npc.sprite, viewport_point):
			var depth: float = npc.get_depth_sort_y()
			if depth > front_y:
				picked_npc = npc
				front_y = depth
	if picked_npc != null:
		if not picked_npc.try_interact():
			_show_toast("请靠近后再交谈")
		return true
	for area in _trigger_areas:
		if not is_instance_valid(area):
			continue
		var data: Dictionary = area.get_meta("trigger_data", {})
		if not bool(data.get("interaction_only", false)):
			continue
		var visual: Variant = area.get_meta("highlight_node") if area.has_meta("highlight_node") else null
		var visual_hit := is_instance_valid(visual) and visual is Sprite2D and _pointer_hits_sprite(visual, viewport_point)
		if visual_hit or (not LUOYANG_V3.is_v3(_current_scene) and _pointer_hits_area(area, viewport_point)):
			if area.overlaps_body(_player):
				_on_trigger_zone_entered(_player, data)
			else:
				_show_toast("请靠近后再查看")
			return true
	for zone in _exit_nodes:
		if _pointer_hits_area(zone, viewport_point):
			if not zone.try_interact():
				_show_toast("请靠近出口后再点击")
			return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	# A pointer may synchronously replace/remove this Field (e.g. a bounty
	# board). Preserve the actual live Viewport before dispatching that action.
	var input_viewport := get_viewport()
	if not is_instance_valid(input_viewport):
		return
	# The project deliberately emulates both touch -> mouse and mouse -> touch
	# for GUI buttons. World interactions accept only the original device;
	# consume its synthetic twin before modal guards / physics picking.
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.device < 0:
		input_viewport.set_input_as_handled()
		return
	if DialogPlayer.is_playing():
		return
	if (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed):
		if _dispatch_pointer_interaction(event.position):
			if is_instance_valid(input_viewport):
				input_viewport.set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# ESC — 关闭系统面板 或 切换右侧菜单
		if event.keycode == KEY_ESCAPE:
			if _system_panel_open:
				_close_all_system_panels()
			else:
				if _primary_hud != null:
					_primary_hud.toggle_right_menu()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_J:
			_on_quest_log_pressed()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_I:
			# Inventory/character entry is temporarily disabled. Consume I so the
			# hidden legacy panel cannot still be opened from the keyboard.
			if INVENTORY_SHORTCUT_ENABLED:
				_toggle_inventory_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_C:
			_toggle_equipment_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_K:
			_toggle_skill_panel()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_M:
			get_viewport().set_input_as_handled()
			EventBus.ui_requested.emit(&"world_map")

		elif event.keycode == KEY_F5:
			_open_system_menu()
			get_viewport().set_input_as_handled()

func _on_system_panel_opened() -> void:
	_system_panel_open = true
	if _primary_hud != null:
		_primary_hud.hide_for_system_ui()
	if _player != null:
		_player.set_can_move(false)



func _on_system_panel_closed() -> void:
	if _inventory_panel != null:
		# Restore MainPanel center
		var mp: Control = _inventory_panel.get_node_or_null("MainPanel")
		if mp:
			mp.offset_left = -640
			mp.offset_right = 640
			mp.offset_top = -360
			mp.offset_bottom = 360
		var dim: ColorRect = _inventory_panel.get_node_or_null("Dim")
		if dim:
			dim.visible = true
		_inventory_panel.visible = false
	if _equipment_panel != null and _equipment_panel.visible:
		_equipment_panel.visible = false
		_equipment_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		# Restore Container position
		var ctr: Control = _equipment_panel.get_node_or_null("Container")
		if ctr and ctr.offset_left != 0:
			for child in ctr.get_children():
				if child is Control:
					child.offset_left += 1280
					child.offset_right += 1280
			ctr.offset_left = 0
			ctr.offset_right = 640
	_system_panel_open = false
	if _primary_hud != null:
		_primary_hud.show_after_system_ui()
	if _player != null:
		_player.set_can_move(true)


func _close_all_system_panels() -> void:
	if _inventory_panel != null and _inventory_panel.visible:
		_inventory_panel.close()
	if _equipment_panel != null and _equipment_panel.visible:
		_equipment_panel.close()
	if _skill_panel != null and _skill_panel.visible:
		_skill_panel.close()
	if _quest_panel_full != null and _quest_panel_full.visible:
		_quest_panel_full.close()
	var system_menu := _system_ui_canvas_layer.get_node_or_null("SystemMenu") as SystemMenu
	if system_menu != null and system_menu.visible:
		system_menu.close()
	_on_system_panel_closed()


func _open_save_slot_panel() -> void:
	if DialogPlayer.is_playing():
		return
	const SAVE_SLOT_PANEL_SCENE := preload("res://scenes/ui/save_slot_panel.tscn")
	var panel: Control = SAVE_SLOT_PANEL_SCENE.instantiate()
	_system_ui_canvas_layer.add_child(panel)
	panel.open(SaveSlotPanel.Mode.SAVE)
	_on_system_panel_opened()
	panel.closed.connect(_on_system_panel_closed)
