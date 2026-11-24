extends RefCounted
## One living exterior, never a disk-resource validation cache. No cold path is
## authorized by this object. A source metadata change discards it and the Router
## uses the original complete SHA/pixel/geometry path. Seconds-resolution mtime
## is an editor invalidation signal, NOT protection against forged timestamps.
const CITY := &"ch4_s3_luoyang_market"
const SUPPORTED_CITIES := [CITY,&"ch4_s2_canal_docks",&"ch4_s0_luoyang_gate",&"ch4_s1_luoyang_yamen"]
const LIMIT_BYTES := 512 * 1024 * 1024
const LIVE_WORLD_FORMAL_ENABLED := true
const LIVE_WORLD_FLAG := "--luoyang-live-city-lease-20261016g"
var city_id: StringName = &""
var field: Node = null
var room: StringName = &""
var receipt: Dictionary = {}
var return_spawn := Vector2.ZERO
var authored_exit := Vector2.ZERO
var original_mode := Node.PROCESS_MODE_INHERIT
var parked := false
var generation := 0
var last: Dictionary = {"phase":"EMPTY"}
var excursion_kind: String = ""
var static_identity: Dictionary = {}
var implementation_stamps: Dictionary = {}

static func extended_enabled() -> bool:
	return LIVE_WORLD_FORMAL_ENABLED or LIVE_WORLD_FLAG in OS.get_cmdline_user_args()

static func _implementation_stamps() -> Dictionary:
	var paths: Dictionary={}
	for path: String in ["res://scripts/autoload/scene_router.gd","res://scripts/autoload/loading_manager.gd","res://scripts/field/field_walkable_controller.gd","res://scripts/city/luoyang_resident_field_20261016.gd"]:
		var file: FileAccess=FileAccess.open(path,FileAccess.READ)
		if file==null: return {}
		paths[path]={"length":file.get_length(),"mtime_seconds":FileAccess.get_modified_time(path)}
		file.close()
	return paths

func stage(node: Node,id: StringName,proof: Dictionary,spawn: Vector2,authored: Vector2,mode: int,kind: String="room") -> bool:
	if is_instance_valid(field) or not is_instance_valid(node) or proof.is_empty() or not node.is_inside_tree() or not spawn.is_finite(): return false
	var scene: SceneScript=node.get("_current_scene") as SceneScript
	if scene==null or not supports_city(scene.scene_id) or kind not in ["room","world","ap_artisan"] or (kind=="world" and not extended_enabled()): return false
	if kind=="ap_artisan" and (not extended_enabled() or scene.scene_id!=CITY or id!=&"luoyang_artisan_residential_20261022ap" or spawn!=Vector2(1100,1860)/Vector2(3072,2048) or authored!=spawn): return false
	var estimate: int=node.call("resident_estimated_bytes")
	if estimate<=0 or estimate>LIMIT_BYTES: last={"phase":"MEMORY_REFUSED","estimated_bytes":estimate,"limit_bytes":LIMIT_BYTES}; return false
	field=node; city_id=scene.scene_id; room=id; receipt=proof; return_spawn=spawn; authored_exit=authored; original_mode=mode
	excursion_kind=kind; static_identity=node.call("resident_static_identity")
	implementation_stamps=_implementation_stamps()
	if static_identity.is_empty() or implementation_stamps.is_empty(): field=null; receipt={}; room=&""; city_id=&""; return false
	generation+=1
	last={"phase":"STAGED","generation":generation,"field_id":node.get_instance_id(),"room":String(id),"estimated_bytes":estimate,"limit_bytes":LIMIT_BYTES,"estimate_not_vram_measurement":true}
	last["source_count"]=proof.sources.size()
	last["mtime_precision"]="SECONDS_NOT_FORGED_TIMESTAMP_PROOF"
	last["excursion_kind"]=kind
	return true

func detach(tree: SceneTree) -> bool:
	if not is_instance_valid(field) or parked or tree.current_scene!=field or not field.call("resident_begin_park"): return false
	tree.current_scene=null
	field.get_parent().remove_child(field)
	parked=true; last.phase="PARKED"
	return not field.is_inside_tree()

func matches(source: StringName,target: StringName) -> bool:
	return parked and is_instance_valid(field) and source==room and supports_city(city_id) and target==city_id

func identities_match() -> bool:
	if not extended_enabled(): return is_instance_valid(field) # Existing room-only contract.
	return is_instance_valid(field) and not static_identity.is_empty() and field.call("resident_static_identity")==static_identity and _implementation_stamps()==implementation_stamps

static func supports_city(id: StringName) -> bool: return id in SUPPORTED_CITIES

func attach(tree: SceneTree) -> bool:
	if not parked or not is_instance_valid(field) or field.is_inside_tree(): return false
	tree.root.add_child(field)
	tree.current_scene=field
	parked=false; last.phase="ATTACHED"
	return true

func finish() -> void:
	last.phase="RESUMED"
	field=null; receipt={}; room=&""; city_id=&""; parked=false; static_identity={}; implementation_stamps={}; excursion_kind=""

func release(reason: String) -> void:
	generation+=1
	if is_instance_valid(field):
		if parked:
			field.call("resident_discard")
			field.free()
		else: field.call("resident_abort_park",original_mode)
	field=null; receipt={}; room=&""; city_id=&""; parked=false; static_identity={}; implementation_stamps={}; excursion_kind=""
	last={"phase":"RELEASED","reason":reason,"generation":generation}

func state() -> Dictionary:
	var result:=last.duplicate(true)
	result.occupied=is_instance_valid(field); result.parked=parked
	result.city_id=String(city_id)
	return result
