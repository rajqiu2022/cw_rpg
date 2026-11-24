extends RefCounted
## Independent modular reconstruction. Frozen V5 is validated, never edited.
## PENDING pins deliberately refuse publication/Field selection until root freezes
## actual GPU exports. This is not a visual approval or a formal activation.
const BASE = preload("res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd")
const GROUND = preload("res://scripts/city/luoyang_enclosure_v14_ground_binding.gd")
const BASE_CPU_WORKSPACE = preload("res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd")
const GATE_FORTIFICATION = preload("res://scripts/city/luoyang_gate_fortification_contract_20261013.gd")
const MARKET_ENRICHMENT = preload("res://scripts/city/luoyang_market_enrichment_contract_20261014.gd")
const MODULE_CPU = preload("res://scripts/city/luoyang_module_live_cpu_20261015.gd")
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
	var scene: SceneScript = _transition_validation.scene
	if not is_v3(scene) or not _equal_value(_transition_storage(scene), _transition_validation.output) or not _equal_value(_transition_storage(scene.map_layout), _transition_validation.output_layout): _fail("Validated transition scene/layout changed"); return null
	if not _using_patch.get(String(id), false) or not _equal_value(_records.get(String(id)), _transition_validation.record) or not _equal_value(_solids.get(String(id)), _transition_validation.solids) or not _masks.has(String(id)) or _transition_bytes_sha(_masks[String(id)].get_data()) != _transition_validation.mask_sha: _fail("Validated transition navigation state changed"); return null
	_transition_validation.reuses += 1
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
	_transition_validation = {"token":token, "id":id, "scene":result, "source_scene":scene, "sources":sources, "input":_transition_storage(scene), "input_layout":_transition_storage(scene.map_layout), "output":_transition_storage(result), "output_layout":_transition_storage(result.map_layout), "record":_records[String(id)].duplicate(true), "solids":_solids[String(id)].duplicate(true), "mask_sha":_transition_bytes_sha(_masks[String(id)].get_data()), "reuses":0, "live_scope":true, "sources_finalized":false}
	return result

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
	if not job.raster_ok: return _fail("V11 navigation not exact raw support minus retained/new solids")
	if not job.import_error.is_empty(): return _fail(job.import_error)
	if not job.gameplay_ok: return _fail("V11 original routes/gameplay feet are blocked by new enclosure")
	_report_live_progress(token,.65,"道路与入口已核验，正在准备入场……")
	var mask := Image.create_from_data(int(SIZE.x), int(SIZE.y), false, Image.FORMAT_RGBA8, job.mask_bytes)
	_records[String(id)] = job.record; _masks[String(id)] = mask; _solids[String(id)] = job.solids; _using_patch[String(id)] = true
	return true

static func _prepare_enclosure_after_base(id: StringName, navigation_job: TransitionNavigationJob = null, cpu_context: RefCounted = null, gate_layer: bool = false, market_layer: bool = false) -> bool:
	if cpu_context != null and (cpu_context.get_script() != BASE_CPU_WORKSPACE or _live_source_token <= 0 or _live_base_cpu_job != cpu_context or not cpu_context.matches_owner(_live_source_token, id)): return _fail("Unbound/cancelled live enclosure source receipt")
	if not PATCH_MANIFEST_SHAS.has(String(id)): return true
	if not _hash(manifest_sha(id)) or not _hash(EXPORT_PLAN_SHAS.get(String(id))): return _fail("V11 authoring/export is PENDING; no candidate or formal adoption")
	var patch_path: String = manifest_path(id)
	if FileAccess.get_sha256(patch_path) != manifest_sha(id): return _fail("Frozen V11 patch bytes missing/changed")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(patch_path))
	if not parsed is Dictionary: return _fail("Malformed V11 patch")
	var patch: Dictionary = parsed
	var prefix: String = ROOT + String(id) + "/"
	var plan_path: String = prefix + "export_plan.json"
	if patch.get("canonical_scene_id") != String(id) or patch.get("status") != "GPU_EXPORTED_REQUIRES_FIELD_VISUAL_QA" or patch.get("base_manifest_path") != base_manifest_path(id) or patch.get("base_manifest_sha256") != base_manifest_sha(id) or patch.get("export_plan_path") != plan_path or patch.get("export_plan_sha256") != EXPORT_PLAN_SHAS[String(id)] or FileAccess.get_sha256(plan_path) != EXPORT_PLAN_SHAS[String(id)]: return _fail("V11 exact source/authoring identity mismatch")
	var plan_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	if not plan_raw is Dictionary: return _fail("Malformed frozen V11 plan")
	var plan: Dictionary = plan_raw
	if not _equal_value(patch.get("remove_object_ids"), plan.get("remove_object_ids")) or not patch.get("objects") is Array or not plan.get("objects") is Array or patch.objects.size() != plan.objects.size(): return _fail("V11 removal/exported group set differs from authoring")
	var catalog: Variant = patch.get("asset_sha256")
	if not catalog is Dictionary or catalog.is_empty(): return _fail("V11 independent asset catalog missing")
	for path: Variant in catalog:
		if not path is String or not path.begins_with("res://") or ".." in path or not _hash(catalog[path]) or (FileAccess.get_sha256(path) if cpu_context == null else cpu_context.source_sha(id, path)) != catalog[path]: return _fail("Changed V11 source/export asset: " + str(path))
	if not plan.get("source_catalog") is Dictionary or plan.source_catalog.is_empty() or not patch.get("remove_object_ids") is Array or not _equal_value(patch.get("source_catalog"), plan.get("source_catalog")): return _fail("V11 original atlas/removal source set changed")
	for path: Variant in plan.get("source_catalog", {}):
		if not catalog.has(path) or catalog[path] != plan.source_catalog[path]: return _fail("Original atlas missing from V11 catalog")
	var baseline_raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(base_manifest_path(id)))
	if not baseline_raw is Dictionary: return _fail("Validated V5 author record unreadable")
	var record: Dictionary = baseline_raw.duplicate(true)
	var ground: Dictionary = GROUND.read(GROUND_MANIFESTS.get(String(id), {}), id, prefix, baseline_raw, plan, String(EXPORT_PLAN_SHAS[String(id)]), cpu_context)
	if ground.has("error"): return _fail("V11 native ground: " + String(ground.error))
	var removed: Dictionary = {}
	for oid: Variant in patch.remove_object_ids:
		if not oid is String or oid.is_empty() or removed.has(oid): return _fail("Invalid explicit removed object identity")
		removed[oid] = false
	var objects: Array = []
	var seen: Dictionary = {}
	for object: Dictionary in record.objects:
		if removed.has(String(object.id)): removed[String(object.id)] = true
		else: objects.append(object); seen[String(object.id)] = true
	for oid: String in removed:
		if not removed[oid]: return _fail("Removal not an actual frozen object: " + oid)
	for index: int in patch.objects.size():
		var object: Variant = patch.objects[index]
		var author: Variant = plan.objects[index]
		if not object is Dictionary or not author is Dictionary or not _equal_value(object.get("authoring"), author): return _fail("Export lost exact independently authored geometry")
		var oid: String = String(object.get("id", ""))
		if oid.is_empty() or seen.has(oid) or oid != author.get("id"): return _fail("Duplicate/new object identity mismatch")
		var texture: String = String(object.get("texture", ""))
		var render: Vector2 = _vec(object.get("render_size_px"))
		var foot: Vector2 = _vec(object.get("world_foot_px"))
		var uv: Vector2 = _vec(object.get("foot_uv"))
		var origin: Vector2 = _vec(object.get("world_origin_px"))
		if texture != prefix + "entities/" + oid + ".png" or not catalog.has(texture) or object.get("source") != texture or object.get("source_sha256") != catalog[texture] or not BASE._png_size(texture, Vector2i(render)) or not ResourceLoader.exists(texture): return _fail("V11 independent Sprite PNG missing/unimported")
		if not _imported_sprite_matches(texture): return _fail("V11 imported Sprite pixels/alpha differ from frozen actual PNG")
		if not BASE._in_domain(foot) or not render.is_finite() or render.x <= 0 or render.y <= 0 or render != _vec(object.get("source_size_px")) or not uv.is_finite() or uv.x < 0 or uv.y < 0 or uv.x > 1 or uv.y > 1 or foot != _vec(author.get("world_foot_px")) or not _num(object.get("depth_foot_y"), foot.y): return _fail("V11 measured render/ground-foot binding invalid")
		# Exact native bits tolerate only arithmetic evaluation roundoff, not an
		# arbitrary pixel epsilon or an alpha-bbox-derived replacement ground foot.
		if PackedFloat32Array([origin.x + uv.x * render.x, origin.y + uv.y * render.y]).to_byte_array() != PackedFloat32Array([foot.x, foot.y]).to_byte_array(): return _fail("V11 crop origin/footUV does not reconstruct authored ground foot")
		if not _equal_value(object.get("solid_polygons_px"), author.get("solid_polygons_px")) or not _equal_value(object.get("physical_center_px"), author.get("physical_center_px")) or not _equal_value(object.get("collision_size_px"), author.get("collision_size_px")) or not _equal_value(object.get("blocking"), author.get("blocking")) or not _object_render_role_valid(id, object) or not _render_role_matches_author(object, author): return _fail("V11 exported solid/render-role differs from authoring")
		if not _object_solids_valid(object): return _fail("Invalid new measured physical footprint")
		seen[oid] = true; objects.append(object)
	record.objects = objects
	record.walk_path = String(patch.get("walk_path", ""))
	if record.walk_path != prefix + "walk.png" or not catalog.has(record.walk_path): return _fail("V11 walk not bound to independent root")
	var image: Image = Image.load_from_file(record.walk_path)
	var raw: Image = Image.load_from_file(String(record.raw_walk_path))
	if image == null or raw == null or image.get_size() != Vector2i(SIZE) or raw.get_size() != Vector2i(SIZE) or not ResourceLoader.exists(record.walk_path): return _fail("V11 complete raw support/walk missing")
	image.convert(Image.FORMAT_RGBA8)
	if navigation_job == null:
		var expected: Image = raster_walk(raw, objects)
		if expected == null or expected.get_data() != image.get_data(): return _fail("V11 navigation not exact raw support minus retained/new solids")
	var imported: Texture2D = ResourceLoader.load(record.walk_path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var decoded: Image = imported.get_image() if imported != null else null
	var import_error := ""
	if decoded == null or (decoded.is_compressed() and decoded.decompress() != OK): import_error = "V11 imported walk undecodable"
	else:
		decoded.convert(Image.FORMAT_RGBA8)
		if decoded.get_size() != image.get_size() or decoded.get_data().slice(0, int(SIZE.x * SIZE.y * 4)) != image.get_data(): import_error = "V11 imported navigation differs"
	if navigation_job == null and not import_error.is_empty(): return _fail(import_error)
	for path: String in catalog: record.asset_sha256[path] = catalog[path]
	for path: String in ground.asset_sha256: record.asset_sha256[path] = ground.asset_sha256[path]
	record.ground_path = ground.ground_path
	record.ground_capture_path = ground.ground_capture_path; record.ground_capture_sha256 = ground.ground_capture_sha256
	record.enclosure_patch_path = patch_path; record.enclosure_patch_sha256 = manifest_sha(id)
	record.enclosure_base_manifest_path = base_manifest_path(id); record.enclosure_base_manifest_sha256 = base_manifest_sha(id)
	if navigation_job!=null and (gate_layer or market_layer):
		# Export an exclusive prior packet; retain all original enclosure raster,
		# import and gameplay checks in the same final navigation worker.
		navigation_job.prior={"record":record.duplicate(true),"objects":objects.duplicate(true),"mask_bytes":image.get_data().duplicate(),"solids":object_solids(objects),"import_error":import_error}
		var live_raw:=raw.duplicate() as Image
		live_raw.convert(Image.FORMAT_RGBA8)
		navigation_job.raw_bytes=live_raw.get_data().duplicate()
		navigation_job.record=record.duplicate(true)
		navigation_job.module_pending=true
		return true
	if gate_layer:
		if id != GATE_FORTIFICATION.ID: return _fail("Gate module cannot select another city")
		if navigation_job == null and not _all_gameplay_safe_cpu(record,image,object_solids(objects),Callable()): return _fail("V11 original routes/gameplay feet are blocked by new enclosure")
		var packet := GATE_FORTIFICATION.read_after_original(record)
		if packet.has("error"): return _fail(String(packet.error))
		if navigation_job != null:
			navigation_job.prior = {"record":record.duplicate(true),"objects":objects.duplicate(true),"mask_bytes":image.get_data().duplicate(),"solids":object_solids(objects),"import_error":import_error}
		record = packet.record; objects = record.objects
		for object: Dictionary in objects:
			if not _object_solids_valid(object): return _fail("Gate independent physical geometry invalid: "+String(object.get("id","")))
		image = Image.load_from_file(String(record.walk_path))
		if image == null or image.get_size() != Vector2i(SIZE): return _fail("Gate complete navigation missing")
		image.convert(Image.FORMAT_RGBA8)
		import_error = ""
		if navigation_job == null:
			var expected_gate := raster_walk(raw,objects)
			if expected_gate == null or expected_gate.get_data() != image.get_data(): return _fail("Gate navigation is not exact raw support minus authored solids")
			if not _all_gameplay_safe_cpu(record,image,object_solids(objects),Callable()): return _fail("Gate original routes/gameplay feet blocked")
	if market_layer:
		if id != MARKET_ENRICHMENT.ID or gate_layer: return _fail("Market module cannot select another city or Gate")
		if navigation_job == null and not _all_gameplay_safe_cpu(record,image,object_solids(objects),Callable()): return _fail("Original market enclosure gameplay blocked")
		var market_packet := MARKET_ENRICHMENT.read_after_original(record)
		if market_packet.has("error"): return _fail(String(market_packet.error))
		if navigation_job != null:
			navigation_job.prior = {"record":record.duplicate(true),"objects":objects.duplicate(true),"mask_bytes":image.get_data().duplicate(),"solids":object_solids(objects),"import_error":import_error}
		record = market_packet.record; objects = record.objects
		for object: Dictionary in objects:
			if not _object_solids_valid(object): return _fail("Market independent physical geometry invalid: "+String(object.get("id","")))
		image = Image.load_from_file(String(record.walk_path))
		if image == null or image.get_size() != Vector2i(SIZE): return _fail("Market complete navigation missing")
		image.convert(Image.FORMAT_RGBA8)
		import_error = ""
		if navigation_job == null:
			var expected_market := raster_walk(raw,objects)
			if expected_market == null or expected_market.get_data() != image.get_data(): return _fail("Market navigation is not exact raw support minus authored solids")
			if not _all_gameplay_safe_cpu(record,image,object_solids(objects),Callable()): return _fail("Market original routes/gameplay feet blocked")
	if navigation_job != null:
		var raw_copy := raw.duplicate() as Image
		raw_copy.convert(Image.FORMAT_RGBA8)
		navigation_job.raw_bytes = raw_copy.get_data().duplicate()
		navigation_job.mask_bytes = image.get_data().duplicate()
		navigation_job.objects = objects.duplicate(true)
		navigation_job.record = record.duplicate(true)
		navigation_job.solids = object_solids(navigation_job.objects)
		navigation_job.import_error = import_error
		navigation_job.raster_function = _raster_walk_cpu
		navigation_job.gameplay_function = _all_gameplay_safe_cpu
		navigation_job.ready = true
		return true
	_records[String(id)] = record; _masks[String(id)] = image; _solids[String(id)] = object_solids(objects); _using_patch[String(id)] = true
	if not _all_gameplay_safe(id, record): _records.erase(String(id)); _masks.erase(String(id)); _solids.erase(String(id)); _using_patch.erase(String(id)); return _fail("V11 original routes/gameplay feet are blocked by new enclosure")
	return true

static func _finish_live_module(navigation_job: TransitionNavigationJob,id: StringName,token: int) -> bool:
	if _live_source_token!=token or _live_module_task>=0 or _live_module_job!=null: return false
	if id==GATE_FORTIFICATION.ID and not _owns_base_live_attempt(token,id,_live_base_cpu_job): return _fail("Live Gate module joined source receipt owner unavailable")
	var module:=MODULE_CPU.new()
	if not module.configure(token,id,navigation_job.record,_live_base_cpu_job if id==GATE_FORTIFICATION.ID else null): return _fail("Live module CPU owner/source identity unavailable")
	_live_module_job=module
	var task:=WorkerThreadPool.add_task(module.run,false,"Luoyang exact module source/PNG/Lanczos")
	if task<0: _live_module_job=null; return _fail("Live module CPU worker unavailable")
	_live_module_task=task
	var frames:=0
	while _live_source_token==token and _live_module_job==module and not WorkerThreadPool.is_task_completed(task):
		var status: Dictionary=module.status()
		var fraction:=clampf(float(status.completed)/float(status.total),0.0,1.0)
		var image_phase:=String(status.phase)!="module.source"
		_report_live_progress(token,(.43 if image_phase else .35)+fraction*(.08 if image_phase else .07),"正在核验建筑图像……" if image_phase else "正在核验建筑素材来源……")
		frames+=1
		await (Engine.get_main_loop() as SceneTree).process_frame
	if _live_source_token!=token or _live_module_job!=module: return false
	WorkerThreadPool.wait_for_task_completion(task); _live_module_task=-1
	if not module.mark_joined(token,id): return _fail("Live module CPU completion owner changed")
	var packet: Dictionary=module.packet(token,id)
	if packet.is_empty() or packet.has("error"): return _fail(String(packet.get("error","Live module CPU cancelled/incomplete")))
	var import_timings: Array[Dictionary]=[]
	for row: Dictionary in packet.imports:
		await (Engine.get_main_loop() as SceneTree).process_frame
		if _live_source_token!=token or _live_module_job!=module: return false
		var started:=Time.get_ticks_usec()
		var same:=MODULE_CPU.imported_same(row)
		import_timings.append({"path":row.path,"elapsed_usec":Time.get_ticks_usec()-started,"full_RGBA_exact":same})
		if not same: return _fail("Live module imported full pixels differ: "+String(row.path))
		_report_live_progress(token,.51+.04*float(import_timings.size())/float(packet.imports.size()),"正在核验建筑导入像素……")
	var record: Dictionary=packet.record
	var objects: Array=record.objects
	for object: Dictionary in objects:
		if not _object_solids_valid(object): return _fail("Live module independent physical geometry invalid: "+String(object.get("id","")))
	if packet.walk_bytes.size()!=3072*2048*4: return _fail("Live module complete navigation pixels missing")
	navigation_job.mask_bytes=packet.walk_bytes.duplicate()
	navigation_job.objects=objects.duplicate(true); navigation_job.record=record.duplicate(true)
	navigation_job.solids=object_solids(navigation_job.objects)
	navigation_job.import_error=""
	navigation_job.raster_function=_raster_walk_cpu; navigation_job.gameplay_function=_all_gameplay_safe_cpu
	navigation_job.module_pending=false; navigation_job.ready=true
	_live_module_timings={"scene_id":String(id),"cpu_ms":module.elapsed_ms,"cpu_wait_frames":frames,"imports":import_timings,"full_source_pixel_geometry_checks_retained":true}
	module.release(); _live_module_job=null
	return true

static func _revision_commit(id: StringName,packet: Dictionary) -> void:
	# No writes before original proof, new raster/routes and imported RGBA agree.
	_records[String(id)]=packet.record
	_masks[String(id)]=Image.create_from_data(int(SIZE.x),int(SIZE.y),false,Image.FORMAT_RGBA8,packet.walk_bytes)
	_solids[String(id)]=packet.solids
	_using_patch[String(id)]=true

static func _revision_after_original_sync(original: SceneScript,raw: SceneScript) -> SceneScript:
	var id:=original.scene_id
	var sources:=_transition_sources(raw)
	if sources.is_empty(): _fail("Fourth-layer complete source identity unavailable"); return null
	var revision: Variant=_revision()
	var job: RefCounted=revision.new()
	if not job.configure(0,id,_records[String(id)]): job.release(); _fail("Fourth-layer original packet unbound"); return null
	job.run()
	if not job.mark_joined(0,id): job.release(); _fail("Fourth-layer synchronous CPU cancelled"); return null
	var packet: Dictionary=job.packet(0,id)
	if packet.is_empty():
		var error: String=job.error(); job.release(); _fail(error); return null
	if not MODULE_CPU.imported_same(packet): job.release(); _fail("Fourth-layer imported full navigation RGBA differs"); return null
	var result: SceneScript=revision.materialize_after_original(original,packet)
	if result==null or not _transition_sources_match(sources): job.release(); _fail("Fourth-layer expected scene/source differs"); return null
	_revision_commit(id,packet)
	job.release()
	return result

static func _revision_after_original_live(original: SceneScript,token: int) -> SceneScript:
	if original==null or _live_source_token!=token or _live_revision_task>=0 or _live_revision_job!=null: return null
	var id:=original.scene_id
	var revision: Variant=_revision()
	var job: RefCounted=revision.new()
	if not job.configure(token,id,_records[String(id)]): job.release(); _fail("Fourth-layer live original packet unbound"); return null
	_live_revision_job=job
	var task:=WorkerThreadPool.add_task(job.run,false,"Luoyang fourth-layer exact source/raster/875+17")
	if task<0: _live_revision_job=null; job.release(); _fail("Fourth-layer worker unavailable"); return null
	_live_revision_task=task
	var frames:=0
	while _live_source_token==token and _live_revision_job==job and not WorkerThreadPool.is_task_completed(task):
		_report_live_progress(token,.66,"正在核验街巷、房门与室内来源……")
		frames+=1
		await (Engine.get_main_loop() as SceneTree).process_frame
	if _live_source_token!=token or _live_revision_job!=job: return null
	WorkerThreadPool.wait_for_task_completion(task); _live_revision_task=-1
	if not job.mark_joined(token,id): _fail("Fourth-layer completion owner changed"); return null
	var packet: Dictionary=job.packet(token,id)
	if packet.is_empty(): _fail("Fourth-layer CPU rejected: "+job.error()); return null
	await (Engine.get_main_loop() as SceneTree).process_frame
	if _live_source_token!=token or _live_revision_job!=job: return null
	if not MODULE_CPU.imported_same(packet): _fail("Fourth-layer imported full navigation RGBA differs"); return null
	await (Engine.get_main_loop() as SceneTree).process_frame
	if _live_source_token!=token or _live_revision_job!=job: return null
	var result: SceneScript=revision.materialize_after_original(original,packet)
	if result==null: _fail("Fourth-layer full expected serialized scene differs"); return null
	_revision_commit(id,packet)
	_live_phase_msec["revision_cpu_worker"]=job.elapsed_ms
	_live_phase_msec["revision_wait_frames"]=frames
	_live_phase_msec["revision_full875_and17"]=true
	job.release(); _live_revision_job=null
	_report_live_progress(token,.68,"街巷与房门已核验，正在准备入场……")
	return result

static func _assembled_after_original_sync(original: SceneScript,raw: SceneScript) -> SceneScript:
	var id:=original.scene_id
	var sources:=_transition_sources(raw)
	if sources.is_empty(): _fail("Assembled child complete source identity unavailable"); return null
	var revision: Variant=_assembled()
	var job: RefCounted=revision.new()
	if not job.configure(0,id,_records[String(id)]): job.release(); _fail("Assembled child original packet unbound"); return null
	job.run()
	if not job.mark_joined(0,id): job.release(); _fail("Assembled child synchronous CPU cancelled"); return null
	var packet: Dictionary=job.packet(0,id)
	if packet.is_empty():
		var error: String=job.error(); job.release(); _fail(error); return null
	if not MODULE_CPU.imported_same(packet): job.release(); _fail("Assembled child imported full navigation RGBA differs"); return null
	var result: SceneScript=revision.materialize_after_original(original,packet)
	if result==null or not _transition_sources_match(sources): job.release(); _fail("Assembled child expected scene/source differs"); return null
	_revision_commit(id,packet)
	job.release()
	return result

static func _assembled_after_original_live(original: SceneScript,token: int) -> SceneScript:
	if original==null or _live_source_token!=token or _live_revision_task>=0 or _live_revision_job!=null: return null
	var id:=original.scene_id
	var revision: Variant=_assembled()
	var job: RefCounted=revision.new()
	if not job.configure(token,id,_records[String(id)]): job.release(); _fail("Assembled child live original packet unbound"); return null
	_live_revision_job=job
	var task:=WorkerThreadPool.add_task(job.run,false,"Luoyang assembled child exact source/raster/875+17")
	if task<0: _live_revision_job=null; job.release(); _fail("Assembled child worker unavailable"); return null
	_live_revision_task=task
	var frames:=0
	while _live_source_token==token and _live_revision_job==job and not WorkerThreadPool.is_task_completed(task):
		_report_live_progress(token,.66,"正在核验街巷、房门与室内来源……")
		frames+=1
		await (Engine.get_main_loop() as SceneTree).process_frame
	if _live_source_token!=token or _live_revision_job!=job: return null
	WorkerThreadPool.wait_for_task_completion(task); _live_revision_task=-1
	if not job.mark_joined(token,id): _fail("Assembled child completion owner changed"); return null
	var packet: Dictionary=job.packet(token,id)
	if packet.is_empty(): _fail("Assembled child CPU rejected: "+job.error()); return null
	await (Engine.get_main_loop() as SceneTree).process_frame
	if _live_source_token!=token or _live_revision_job!=job: return null
	if not MODULE_CPU.imported_same(packet): _fail("Assembled child imported full navigation RGBA differs"); return null
	await (Engine.get_main_loop() as SceneTree).process_frame
	if _live_source_token!=token or _live_revision_job!=job: return null
	var result: SceneScript=revision.materialize_after_original(original,packet)
	if result==null: _fail("Assembled child full expected serialized scene differs"); return null
	_revision_commit(id,packet)
	_live_phase_msec["assembled_cpu_worker"]=job.elapsed_ms
	_live_phase_msec["assembled_wait_frames"]=frames
	_live_phase_msec["assembled_full875_and17"]=true
	job.release(); _live_revision_job=null
	_report_live_progress(token,.68,"街巷与房门已核验，正在准备入场……")
	return result

static func effective_author_record(id: StringName, transition_token: int = 0) -> Dictionary:
	if not _prepare_or_transition(id, transition_token): return {}
	if _records.has(String(id)): return _records[String(id)].duplicate(true)
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(base_manifest_path(id)))
	return raw.duplicate(true) if raw is Dictionary else {}

static func object_solids(objects: Array) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	for object: Dictionary in objects:
		for raw: Variant in object.get("solid_polygons_px", []): result.append(_polygon(raw))
		var size: Vector2 = _vec(object.get("collision_size_px"))
		if size.x > 0: result.append(BASE._rect_polygon(Rect2(_vec(object.physical_center_px) - size * .5, size)))
	return result

static func _imported_sprite_matches(path: String) -> bool:
	var source: Image = Image.load_from_file(path)
	var texture: Texture2D = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var imported: Image = texture.get_image() if texture != null else null
	if source == null or imported == null or source.get_used_rect().size == Vector2i.ZERO or (imported.is_compressed() and imported.decompress() != OK): return false
	source.convert(Image.FORMAT_RGBA8); imported.convert(Image.FORMAT_RGBA8)
	return source.get_size() == imported.get_size() and imported.get_data().slice(0, source.get_width() * source.get_height() * 4) == source.get_data()

static func _object_solids_valid(object: Dictionary) -> bool:
	var size: Vector2 = _vec(object.get("collision_size_px"))
	var polygons: Variant = object.get("solid_polygons_px")
	if not polygons is Array or not size.is_finite() or not _vec(object.get("physical_center_px")).is_finite() or size.x < 0 or size.y < 0 or (size.x == 0) != (size.y == 0) or typeof(object.get("blocking")) != TYPE_BOOL or (size.x > 0 and not polygons.is_empty()) or object.blocking != (size.x > 0 or not polygons.is_empty()): return false
	for polygon: PackedVector2Array in object_solids([object]):
		if polygon.size() < 3 or Geometry2D.triangulate_polygon(polygon).is_empty(): return false
		for point: Vector2 in polygon:
			if not BASE._in_domain(point): return false
	return true

static func _object_render_role_valid(id: StringName, object: Dictionary) -> bool:
	# Reuse frozen explicit role restrictions, without giving water/board art
	# any new navigation support or permission to hide ordinary wall solids.
	if not BASE._object_role_error(id, object).is_empty(): return false
	if object.has("walk_support") and (typeof(object.walk_support) != TYPE_BOOL or object.walk_support != false): return false
	var role: String = object.get("role", "")
	if role == "": return object.get("ghost_occlusion") == true and object.get("sort_by_feet", true) == true
	if not _object_solids_valid(object) or object.blocking != false or not object.solid_polygons_px.is_empty() or _vec(object.collision_size_px) != Vector2.ZERO or object.get("walk_support") != false: return false
	if role == "ground_overlay": return object.get("sort_by_feet") == false and _num(object.get("z_index"), -2)
	# Water retains explicit authored mooring depth sorting, never alpha bottom.
	return role == "water_decoration" and object.get("sort_by_feet") == true and not object.has("z_index") and _num(object.get("depth_foot_y"), _vec(object.get("world_foot_px")).y)

static func _render_role_matches_author(object: Dictionary, author: Dictionary) -> bool:
	if object.get("role", "") != author.get("role", "") or object.get("ghost_occlusion") != author.get("ghost_occlusion", true): return false
	for key: String in ["walk_support", "interaction_required", "z_index", "sort_by_feet"]:
		if object.has(key) != author.has(key) or (author.has(key) and not _equal_value(object[key], author[key])): return false
	return true

static func raster_walk(raw: Image, objects: Array) -> Image:
	return _raster_walk_cpu(raw, objects)

static func _raster_walk_cpu(raw: Image, objects: Array, cancelled: Callable = Callable()) -> Image:
	if raw == null or raw.get_size() != Vector2i(SIZE): return null
	var result: Image = raw.duplicate() as Image
	result.convert(Image.FORMAT_RGBA8)
	for rect: Rect2i in [Rect2i(0, 0, int(SIZE.x), 24), Rect2i(0, int(SIZE.y) - 24, int(SIZE.x), 24), Rect2i(0, 0, 24, int(SIZE.y)), Rect2i(int(SIZE.x) - 24, 0, 24, int(SIZE.y))]: result.fill_rect(rect, Color.BLACK)
	# Preserve frozen V5 integer-point polygon raster and half-open rectangles.
	# Never start from old walk.png, which retains invisible removed-wall solids.
	for object: Dictionary in objects:
		if cancelled.is_valid() and cancelled.call(): return null
		for value: Variant in object.get("solid_polygons_px", []):
			var polygon: PackedVector2Array = _polygon(value)
			var minimum := Vector2(INF, INF); var maximum := Vector2(-INF, -INF)
			for point: Vector2 in polygon: minimum = minimum.min(point); maximum = maximum.max(point)
			for y: int in range(maxi(0, floori(minimum.y)), mini(int(SIZE.y), ceili(maximum.y) + 1)):
				if cancelled.is_valid() and cancelled.call(): return null
				for x: int in range(maxi(0, floori(minimum.x)), mini(int(SIZE.x), ceili(maximum.x) + 1)):
					if Geometry2D.is_point_in_polygon(Vector2(x, y), polygon): result.set_pixel(x, y, Color.BLACK)
		var size: Vector2 = _vec(object.get("collision_size_px"))
		if size.x <= 0: continue
		var rect := Rect2(_vec(object.physical_center_px) - size * .5, size)
		for y: int in range(maxi(0, ceili(rect.position.y)), mini(int(SIZE.y), ceili(rect.end.y))):
			if cancelled.is_valid() and cancelled.call(): return null
			for x: int in range(maxi(0, ceili(rect.position.x)), mini(int(SIZE.x), ceili(rect.end.x))): result.set_pixel(x, y, Color.BLACK)
	return result

static func safe_body(id: StringName, point_px: Vector2) -> bool:
	if not PATCH_MANIFEST_SHAS.has(String(id)) or not _using_patch.get(String(id), false): return BASE.safe_body(id, point_px)
	if not _masks.has(String(id)) or not point_px.is_finite(): return false
	var image: Image = _masks[String(id)]
	return _safe_body_cpu(point_px, image, _solids[String(id)])

static func _safe_body_cpu(point_px: Vector2, image: Image, solids: Array[PackedVector2Array]) -> bool:
	if image == null or not point_px.is_finite(): return false
	var rect := Rect2(point_px - BODY_SIZE * .5, BODY_SIZE)
	if not BASE._in_domain(rect.position) or not BASE._in_domain(rect.end) or roundi(rect.position.x) < 0 or roundi(rect.position.y) < 0 or roundi(rect.end.x) >= image.get_width() or roundi(rect.end.y) >= image.get_height(): return false
	for y: int in range(roundi(rect.position.y), roundi(rect.end.y) + 1):
		for x: int in range(roundi(rect.position.x), roundi(rect.end.x) + 1):
			var color: Color = image.get_pixel(x, y)
			if color.a < .5 or color.r < .5: return false
	for polygon: PackedVector2Array in solids:
		if not Geometry2D.intersect_polygons(BASE._rect_polygon(rect), polygon).is_empty(): return false
	return true

static func _all_gameplay_safe(id: StringName, record: Dictionary) -> bool:
	return _all_gameplay_safe_points(record, _record_body_safe.bind(id))

static func _record_body_safe(point_px: Vector2, id: StringName) -> bool:
	return safe_body(id, point_px)

static func _all_gameplay_safe_cpu(record: Dictionary, image: Image, solids: Array[PackedVector2Array], cancelled: Callable) -> bool:
	return _all_gameplay_safe_points(record, _safe_body_cpu.bind(image, solids), cancelled)

static func _all_gameplay_safe_points(record: Dictionary, body_safe: Callable, cancelled: Callable = Callable()) -> bool:
	for key: String in ["entry_foot_px", "return_foot_px"]:
		if cancelled.is_valid() and cancelled.call(): return false
		if not body_safe.call(_vec(record[key])): return false
	var object_ids: Dictionary = {}
	for object: Dictionary in record.objects: object_ids[String(object.id)] = true
	for kind: String in ["npcs", "interactions", "portals"]:
		for slot: Dictionary in record.gameplay_slots[kind]:
			if cancelled.is_valid() and cancelled.call(): return false
			if not body_safe.call(_vec(slot.get("stand_px" if kind == "interactions" else "foot_px"))): return false
			if kind == "interactions" and not object_ids.has(String(slot.object_id)): return false
			if kind == "portals" and not body_safe.call(_vec(slot.arrival_foot_px)): return false
			for point: Variant in slot.get("patrol_path_px", []):
				if cancelled.is_valid() and cancelled.call(): return false
				if not body_safe.call(_vec(point)): return false
			for point: Variant in slot.get("passage_path_px", []):
				if cancelled.is_valid() and cancelled.call(): return false
				if not body_safe.call(_vec(point)): return false
	for route: Dictionary in record.routes:
		var points: Array = route.points_px
		for index: int in range(points.size() - 1):
			var a: Vector2 = _vec(points[index]); var b: Vector2 = _vec(points[index + 1])
			var steps: int = maxi(1, ceili(a.distance_to(b) / 4.))
			for step: int in range(steps + 1):
				if cancelled.is_valid() and cancelled.call(): return false
				if not body_safe.call(a.lerp(b, float(step) / steps)): return false
	return true

static func materialize(id: StringName, gate_scene: SceneScript = null) -> SceneScript:
	if not prepare(id,gate_scene): return null
	var scene: SceneScript = BASE.materialize(id)
	if scene == null: _errors.assign(BASE.errors()); return null
	return _materialize_enclosure_after_base(id, scene)

static func _materialize_enclosure_after_base(id: StringName, scene: SceneScript) -> SceneScript:
	if not PATCH_MANIFEST_SHAS.has(String(id)): return scene
	var record: Dictionary = _records[String(id)]
	scene.background_path = String(record.ground_path)
	scene.map_layout.visual_objects.clear()
	scene.map_layout.walkable_mask_path = String(record.walk_path)
	for authored: Dictionary in record.objects:
		var entry: Dictionary = authored.duplicate(true)
		var foot: Vector2 = _vec(authored.world_foot_px); var render: Vector2 = _vec(authored.render_size_px)
		entry.pos = (foot + (Vector2(.5, .5) - _vec(authored.foot_uv)) * render) / SIZE
		entry.render_size_px = render; entry.centered = true
		entry.sort_by_feet = authored.get("role", "") != "ground_overlay"
		if not entry.sort_by_feet: entry.z_index = -2; entry.ghost_occlusion = false
		if record.has("gate_fortification_manifest_sha"): GATE_FORTIFICATION.apply_entry(entry,authored)
		entry.depth_sort_foot_y = foot.y / SIZE.y
		entry.city_v3_solid_polygons_px = authored.solid_polygons_px.duplicate(true); entry.erase("solid_polygons_px")
		scene.map_layout.visual_objects.append(entry)
	scene.set_meta("city_enclosure_manifest_sha", manifest_sha(id))
	scene.set_meta("city_ground_manifest_sha", ground_manifest_sha(id))
	scene.set_meta("city_ground_manifest_path", ground_manifest_path(id))
	if record.has("gate_fortification_manifest_sha"): GATE_FORTIFICATION.apply_scene(scene,record)
	if record.has("market_enrichment_manifest_sha"): MARKET_ENRICHMENT.apply_scene(scene,record)
	return scene if semantic_fidelity(scene) else null

static func runtime_fidelity(scene: SceneScript) -> bool:
	if scene == null: return _fail("Missing city scene")
	if scene.has_meta(_annex().META):
		if not annex_bound(scene): return _fail("Annex runtime identity differs")
		var annex_token: int=int(_transition_validation.get("token",0))
		if annex_token>0 and _transition_validation.get("id")==scene.scene_id:
			var proven:=_transition_packet_scene(annex_token,scene.scene_id)
			return proven!=null and _annex().serialized_equal(scene,proven)
		return resolve_scene(scene)!=null
	if scene.has_meta(_harbour().META):
		if not harbour_bound(scene): return _fail("Harbour runtime identity differs")
		var harbour_token: int=int(_transition_validation.get("token",0))
		if harbour_token>0 and _transition_validation.get("id")==scene.scene_id:
			var proven:=_transition_packet_scene(harbour_token,scene.scene_id)
			return proven!=null and _harbour().serialized_equal(scene,proven)
		return resolve_scene(scene)!=null
	if scene.has_meta(_assembled().META):
		if not assembled_bound(scene): return _fail("Assembled runtime identity differs")
		var assembled_token: int=int(_transition_validation.get("token",0))
		if assembled_token>0 and _transition_validation.get("id")==scene.scene_id:
			var proven:=_transition_packet_scene(assembled_token,scene.scene_id)
			return proven!=null and _assembled().serialized_equal(scene,proven)
		return resolve_scene(scene)!=null
	if scene.has_meta(REVISION_META):
		if not is_v3(scene): return _fail("Fourth-layer runtime binding differs")
		var token: int=int(_transition_validation.get("token",0))
		if token>0 and _transition_validation.get("id")==scene.scene_id:
			var proven:=_transition_packet_scene(token,scene.scene_id)
			return proven!=null and _revision().serialized_equal(scene,proven)
		return resolve_scene(scene)!=null
	if not scene.has_meta("city_enclosure_manifest_sha"): return BASE.runtime_fidelity(scene)
	if not is_v3(scene): return _fail("Serialized enclosure not bound to current manifest")
	var expected: SceneScript = materialize(scene.scene_id,scene)
	return _runtime_matches_expected(scene, expected)

static func _runtime_matches_expected(scene: SceneScript, expected: SceneScript) -> bool:
	if expected == null or not semantic_fidelity(scene): return false
	if scene.has_meta(MARKET_ENRICHMENT.META) != expected.has_meta(MARKET_ENRICHMENT.META) or (expected.has_meta(MARKET_ENRICHMENT.META) and scene.get_meta(MARKET_ENRICHMENT.META) != expected.get_meta(MARKET_ENRICHMENT.META)): return _fail("Serialized Market module source metadata differs")
	if scene.has_meta(GATE_FORTIFICATION.META) != expected.has_meta(GATE_FORTIFICATION.META) or (expected.has_meta(GATE_FORTIFICATION.META) and scene.get_meta(GATE_FORTIFICATION.META) != expected.get_meta(GATE_FORTIFICATION.META)): return _fail("Serialized Gate module source metadata differs")
	for name: String in ["background_path", "streamed_background", "player_spawn", "player_visual_scale", "actor_positions_are_feet", "npcs", "animated_props", "scene_objects", "collision_rects", "exits", "trigger_zones"]:
		if not _equal_value(expected.get(name), scene.get(name)): return _fail("Serialized V11 city spatial field differs: " + name)
	for property: Dictionary in expected.map_layout.get_property_list():
		var name: String = String(property.name)
		if (int(property.usage) & PROPERTY_USAGE_STORAGE) == 0 or name in ["script", "resource_path", "resource_name", "resource_local_to_scene"]: continue
		var equal: bool = equal_visual_serialized_value(expected.map_layout.get(name), scene.map_layout.get(name), ["visual_objects"]) if name == "visual_objects" else _equal_value(expected.map_layout.get(name), scene.map_layout.get(name))
		if not equal: return _fail("Serialized V11 native layout differs: " + name)
	return true

static func repair_spawn(id: StringName, normalized: Vector2) -> Variant:
	if not normalized.is_finite() or normalized.x < 0 or normalized.y < 0 or normalized.x > 1 or normalized.y > 1: return null
	if safe_body(id, normalized * SIZE): return normalized
	for radius: int in range(4, 197, 4):
		for index: int in 32:
			var point: Vector2 = normalized * SIZE + Vector2.from_angle(TAU * index / 32.) * radius
			if safe_body(id, point): return point / SIZE
	return null

static func migrate_spawn_report(id: StringName, normalized: Vector2, source_version: int, source_scene: StringName = &"", transition_token: int = 0) -> Dictionary:
	if source_version == 1:
		if not _enclosure_arrival_context(id): _fail("V11 requires fresh-start/current coordinate version"); return {}
		return _fresh_authored_portal_arrival(id, normalized, source_scene, transition_token)
	# Current-format saves/remembered exact return feet retain the original path.
	if source_version != VERSION or not _prepare_or_transition(id, transition_token): _fail("V11 requires fresh-start/current coordinate version"); return {}
	var repaired: Variant = repair_spawn(id, normalized)
	return {"scene_id": String(id), "spawn": repaired, "source_version": VERSION, "target_version": VERSION, "reason": "same_version_local_clearance"} if repaired is Vector2 else {}

static func _enclosure_arrival_context(id: StringName) -> bool:
	if not owns_id(id): return false
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var enclosure_candidate: bool = CANDIDATE_FLAG in args
	var city_candidate: bool = "--luoyang-v3-candidate" in args
	if enclosure_candidate or city_candidate: return enclosure_candidate and city_candidate
	# Formal selection reads only the exact canonical city resource. Neither a
	# prepared cache nor merely existing candidate files can authorize this path.
	var path: String = "res://data/scenes/%s.tres" % String(id)
	if not ResourceLoader.exists(path): return false
	var scene: SceneScript = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	return scene != null and scene.resource_path == path and scene.scene_id == id and scene.has_meta("city_enclosure_manifest_sha") and is_v3(scene)

static func _fresh_authored_portal_arrival(id: StringName, normalized: Vector2, source: StringName, transition_token: int = 0) -> Dictionary:
	var route_key: String = String(source) + "->" + String(id)
	if source == &"" or not owns_id(id) or not normalized.is_finite() or not FRESH_AUTHORED_ROUTES.has(route_key): _fail("Unknown live authored city arrival"); return {}
	var route: Dictionary = FRESH_AUTHORED_ROUTES[route_key]
	# Native Vector2 component identity; not approximate equality or a radius.
	if normalized.x != route.uv.x or normalized.y != route.uv.y: _fail("Live authored city target_pos differs"); return {}
	if not _fresh_source_portal_matches(source, id, normalized, route): _fail("Live authored city source portal is not source-bound"); return {}
	var original: SceneScript = legacy_scene(id)
	if original == null or original.map_layout == null: _fail("Missing frozen city arrival origin"); return {}
	var arrival_portals: int = 0
	for portal: Dictionary in original.map_layout.portals:
		if String(portal.get("id", "")) != String(route.slot): continue
		if bool(route.reverse) and String(portal.get("target_scene", "")) != String(source): _fail("Authored reverse city anchor differs"); return {}
		arrival_portals += 1
	if arrival_portals != 1: _fail("Authored city arrival slot is missing/ambiguous"); return {}
	var record: Dictionary = effective_author_record(id, transition_token)
	if record.is_empty(): return {}
	var arrival_slots: int = 0
	var foot := Vector2(INF, INF)
	for slot: Dictionary in record.gameplay_slots.portals:
		if String(slot.get("source_id", "")) != String(route.slot): continue
		foot = _vec(slot.get("arrival_foot_px")); arrival_slots += 1
	var expected_foot: Variant=route.foot
	if revision_requested(id): expected_foot=_revision().fresh_foot(id,route_key,route,record)
	if arrival_slots != 1 or not expected_foot is Vector2 or not foot.is_finite() or foot!=expected_foot or not safe_body(id, foot): _fail("Authored current city arrival is not exact/full-body clear"); return {}
	# Deliberately no repair_spawn/nearest/semantic interpolation on authored1.
	return {"scene_id":String(id),"spawn":foot / SIZE,"source_version":1,"target_version":VERSION,"reason":"exact_live_authored_portal"}

static func _fresh_source_portal_matches(source: StringName, target: StringName, normalized: Vector2, route: Dictionary) -> bool:
	var original: SceneScript
	var layout: WalkableMapLayout
	if owns_id(source):
		original = legacy_scene(source)
		layout = original.map_layout if original != null else null
	elif FRESH_EXTERNAL_SOURCES.has(String(source)):
		var pin: Dictionary = FRESH_EXTERNAL_SOURCES[String(source)]
		if source == &"world_map_jianghu" and FileAccess.get_sha256(FRESH_WORLD_V15_SOURCE.scene).to_lower() == FRESH_WORLD_V15_SOURCE.scene_sha: pin = FRESH_WORLD_V15_SOURCE
		if FileAccess.get_sha256(pin.scene).to_lower() != pin.scene_sha or FileAccess.get_sha256(pin.layout).to_lower() != pin.layout_sha: return false
		original = ResourceLoader.load(pin.scene, "", ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		layout = ResourceLoader.load(pin.layout, "", ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if original == null or original.map_layout == null or original.map_layout.resource_path != pin.layout: return false
	else: return false
	if original == null or original.scene_id != source or layout == null: return false
	if route.has("hotspot"):
		# Exact original Field legacy-hotspot conversion (two fixed Temple edges).
		# These scene: hotspots have no authored UV; Field assigns (.12,.75).
		var index: int = int(route.hotspot)
		var hotspot_uv := Vector2(.12,.75)
		return layout.portals.is_empty() and layout.interactions.is_empty() and index >= 0 and index < original.hotspots.size() and String(original.hotspots[index].get("action", "")) == "scene:" + String(target) and String(route.portal) == "legacy_portal_%d" % index and normalized.x == hotspot_uv.x and normalized.y == hotspot_uv.y
	var matches: int = 0
	for portal: Dictionary in layout.portals:
		var uv: Variant = portal.get("target_pos")
		if String(portal.get("id", "")) == String(route.portal) and String(portal.get("target_scene", "")) == String(target) and uv is Vector2 and uv.x == normalized.x and uv.y == normalized.y: matches += 1
	return matches == 1

static func versions_supported(data: Dictionary, target_versions: Dictionary) -> bool: return BASE.versions_supported(data, target_versions)
static func prepare_navigation(data: Dictionary, fallback: StringName, target_versions: Dictionary) -> Dictionary:
	_errors.clear()
	if not versions_supported(data, target_versions): return {}
	var result: Dictionary = data.duplicate(true)
	var versions: Dictionary = data.get("local_layout_versions", {}).duplicate(true)
	for id: String in target_versions:
		if not owns_id(StringName(id)) or not (_num(target_versions[id], 1) or _num(target_versions[id], VERSION)): _fail("Invalid target current city coordinate version"); return {}
		if int(target_versions[id]) == VERSION and not prepare(StringName(id)): return {}
	var current := StringName(data.get("current_field", fallback))
	result.current_field = String(current)
	if owns_id(current) and int(target_versions.get(String(current), 1)) == VERSION:
		var report: Dictionary = migrate_spawn_report(current, _vec(data.get("current_field_spawn")), int(versions.get(String(current), 1)))
		if report.is_empty(): return {}
		result.current_field_spawn = [report.spawn.x, report.spawn.y]
	var returns: Variant = data.get("portal_return_spawns", {})
	if not returns is Dictionary: _fail("Malformed current paired return coordinates"); return {}
	var repaired: Dictionary = returns.duplicate(true)
	for key: Variant in returns:
		var parts: PackedStringArray = String(key).split("->")
		if parts.size() != 2: continue
		var id := StringName(parts[1])
		if not owns_id(id) or int(target_versions.get(String(id), 1)) != VERSION: continue
		var report: Dictionary = migrate_spawn_report(id, _vec(returns[key]), int(versions.get(String(id), 1)))
		if report.is_empty(): return {}
		repaired[key] = [report.spawn.x, report.spawn.y]
	result.portal_return_spawns = repaired
	for id: String in target_versions: versions[id] = int(target_versions[id])
	result.local_layout_versions = versions
	return result
