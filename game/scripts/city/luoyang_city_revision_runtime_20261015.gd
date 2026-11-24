extends RefCounted
## Fourth layer consumes a fully proven original scene/record. Never calls prepare.
## Loaded lazily by C: the frozen author helpers preload C, not the reverse.
const C = preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const FLAG := "--luoyang-city-revision-runtime-candidate-20261015"
const FORMAL_ENABLED := true # ROOT only, after candidate key acceptance.
const META := "city_frontage_revision_manifest_sha"
const BIND_PATH := "res://art/maps/luoyang_city_revision_runtime_20261015/bindings.json"
const BIND_SHA := "aa2cc1e741598a9dfc38e2c065e90c892a2795c1eb54456c745426e3a7782dac"
const CITY_PINS := {
	"ch4_s3_luoyang_market":{"manifest":"e103039fcf1d332fbb9cebe289cee88bcdb82c4c5fc28274e3737be489dc62f3","author":"cf904eae70c2f789e123c9249b4b47aea6fdb0c63cec7d99a61a4cffe66d935d","walk":"res://art/maps/luoyang_city_revision_retry2_20261015/ch4_s3_luoyang_market/walk.png"},
	"ch4_s2_canal_docks":{"manifest":"fae2b99d98499fc255c9c5607b9811fd29d6b539a2969cec0937884f29f02451","author":"bb92cf64f25a46f438c6e0d0641bbd8b7b99a0d1d4a9a9f4361bb5a55c5fe200","walk":"res://art/maps/luoyang_city_revision_v1_20261015/ch4_s2_canal_docks/walk.png"}
}
const ROOM_PREFIX := "luoyang_market_"
var _token := 0
var _id: StringName = &""
var _original: Dictionary = {}
var _helper: Variant
var _packet: Dictionary = {}
var _error := ""
var _mutex := Mutex.new()
var _cancelled := false
var _joined := false
var elapsed_ms := 0

static func requested(id: StringName) -> bool:
	return enabled() and CITY_PINS.has(String(id))

static func enabled() -> bool: return FORMAL_ENABLED or FLAG in OS.get_cmdline_user_args()

static func bound(scene: SceneScript) -> bool:
	if scene==null or not requested(scene.scene_id) or scene.map_layout==null: return false
	var pin: Dictionary=CITY_PINS[String(scene.scene_id)]
	return scene.get_meta(META,"")==pin.manifest and scene.get_meta("city_frontage_revision_author_sha","")==pin.author and scene.get_meta("city_revision_runtime_binding_sha","")==BIND_SHA and scene.map_layout.walkable_mask_path==pin.walk

static func _bindings() -> Dictionary:
	if FileAccess.get_sha256(BIND_PATH)!=BIND_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(BIND_PATH))
	return value if value is Dictionary and value.get("flag")==FLAG and value.get("status")=="RUNTIME_CANDIDATE_ONLY_NOT_FORMAL" else {}

static func source_paths() -> Dictionary:
	var config:=_bindings()
	if config.is_empty(): return {}
	var paths: Dictionary={BIND_PATH:true,"res://scripts/city/luoyang_city_revision_runtime_20261015.gd":true,"res://scripts/autoload/scene_router.gd":true,"res://scripts/autoload/loading_manager.gd":true,"res://scripts/field/field_walkable_controller.gd":true}
	for path: String in config.source_sha256:
		if not path.begins_with("res://") or ".." in path: return {}
		paths[path]=true
	return paths

static func _check_sources(config: Dictionary,cancel: Callable=Callable()) -> bool:
	for path: String in config.get("source_sha256",{}):
		if cancel.is_valid() and cancel.call(): return false
		if FileAccess.get_sha256(path)!=config.source_sha256[path]: return false
	return not config.get("source_sha256",{}).is_empty()

static func room_path(id: StringName) -> String:
	if not enabled(): return ""
	var config:=_bindings()
	var room: Dictionary=config.get("rooms",{}).get(String(id),{})
	if room.is_empty() or not _check_sources(config): return ""
	return String(room.scene_path)

static func room_known(id: StringName) -> bool:
	# Exact explicit authored IDs; no directory glob, prefix lookup or alias.
	if not enabled(): return false
	return _bindings().get("rooms",{}).has(String(id))

static func room_matches(scene: SceneScript,id: StringName) -> bool:
	if scene==null or not room_known(id): return false
	var config:=_bindings()
	var room: Dictionary=config.rooms.get(String(id),{})
	if room.is_empty() or not _check_sources(config) or scene.resource_path!=room.scene_path or scene.scene_id!=id or scene.map_layout==null or scene.map_layout.resource_path!=room.layout_path: return false
	var expected:=ResourceLoader.load(room.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(room.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if expected==null or layout==null or expected.scene_id!=id or not expected.is_walkable or not expected.npcs.is_empty() or not expected.hotspots.is_empty() or expected.on_enter_dialog!=null or expected.actor_positions_are_feet: return false
	expected.map_layout=layout
	var helper: Variant=load("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd")
	return helper.serialized_equal(scene,expected)

static func room_return(source: StringName,target: StringName,authored: Variant,remembered: Variant) -> Dictionary:
	if not requested(target): return {}
	var config:=_bindings()
	var room: Dictionary=config.get("rooms",{}).get(String(source),{})
	if room.is_empty() or target!=&"ch4_s3_luoyang_market" or not authored is Vector2 or authored!=C._vec(room.return_foot_px)/C.SIZE or not _check_sources(config): return {}
	var arrival: Vector2=remembered if remembered is Vector2 else authored
	if not arrival.is_finite() or not C.safe_body(target,arrival*C.SIZE): return {}
	return {"spawn":arrival,"source_version":C.VERSION,"target_version":C.VERSION,"reason":"exact_per_room_current_format_return"}

static func fresh_foot(id: StringName,key: String,old_route: Dictionary,record: Dictionary) -> Variant:
	if not requested(id) or record.get("city_revision_binding_sha")!=BIND_SHA: return null
	for mapping: Dictionary in record.get("city_revision_fresh_arrivals",[]):
		if mapping.route_key!=key: continue
		if mapping.slot!=old_route.slot or C._vec(mapping.old_foot_px)!=old_route.foot or C._vec(mapping.authored_uv)!=old_route.uv: return null
		var original:=_find(record.get("city_revision_original_portals",[]),"source_id",String(old_route.slot))
		if original.is_empty() or C._vec(original.arrival_foot_px)!=old_route.foot: return null
		return C._vec(mapping.foot_px)
	return old_route.foot

static func _find(items: Array,key: String,value: String) -> Dictionary:
	var result: Dictionary={}
	for item: Dictionary in items:
		if item.get(key)==value:
			if not result.is_empty(): return {}
			result=item
	return result

func configure(token: int,id: StringName,original: Dictionary) -> bool:
	if token<0 or not requested(id) or original.get("canonical_scene_id")!=String(id) or _token!=0 or not _original.is_empty(): return false
	var config:=_bindings()
	var city: Dictionary=config.get("cities",{}).get(String(id),{})
	if city.is_empty(): return false
	_helper=load(city.helper_path)
	if _helper==null: return false
	_token=token; _id=id; _original=original.duplicate(true); return true
func request_cancel() -> void:
	_mutex.lock(); _cancelled=true; _mutex.unlock()
func _is_cancelled() -> bool:
	_mutex.lock(); var value:=_cancelled; _mutex.unlock(); return value
func mark_joined(token: int,id: StringName) -> bool:
	_joined=token==_token and id==_id and not _is_cancelled(); return _joined
func packet(token: int,id: StringName) -> Dictionary:
	return _packet if _joined and token==_token and id==_id and not _is_cancelled() else {}
func error() -> String: return _error
func release() -> void:
	_original.clear(); _packet.clear(); _helper=null; _token=0; _id=&""; _joined=false
func _reject(message: String) -> void: _error=message; _packet.clear()

func run() -> void:
	var started:=Time.get_ticks_msec()
	var config:=_bindings()
	if config.is_empty() or not _check_sources(config,_is_cancelled): _reject("Fourth-layer frozen source closure changed/cancelled"); return
	var city: Dictionary=config.cities.get(String(_id),{})
	if city.is_empty(): _reject("Fourth-layer city identity missing"); return
	# Script is compiled/loaded on main before this exclusive CPU task starts.
	var helper: Variant=_helper
	var authoring: Dictionary=helper.author(); var home: Dictionary=helper.homes()
	var spec: Dictionary=helper.spec_for(authoring,_id)
	var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(city.manifest_path))
	var publication: Variant=JSON.parse_string(FileAccess.get_file_as_string(city.result_path))
	if spec.is_empty() or not manifest is Dictionary or not publication is Dictionary or publication.get("passed")!=true or manifest.get("full_original_C_first")!=true or manifest.get("author_sha256")!=helper.AUTHOR_SHA or manifest.get("status")!="PUBLISHED_FOURTH_LAYER_CANDIDATE_NOT_FORMAL_NOT_ROUTER_INSTALLED": _reject("Fourth-layer exact publication missing"); return
	var record: Dictionary=helper.compose(_original,spec,home)
	if record.is_empty(): _reject("Fourth-layer explicit source-bound composition refused"); return
	for field: String in ["objects","gameplay_slots","routes","ground_path","walk_path"]:
		if not C._equal_value(record.get(field),manifest.get(field)): _reject("Fourth-layer published geometry differs: "+field); return
	if manifest.get("raw_walk_path")!=_original.raw_walk_path or FileAccess.get_sha256(_original.raw_walk_path)!=manifest.get("raw_walk_sha256"): _reject("Fourth-layer original raw support differs"); return
	for object: Dictionary in record.objects:
		if not C._object_solids_valid(object): _reject("Fourth-layer physical geometry invalid"); return
	var raw:=Image.load_from_file(_original.raw_walk_path)
	var mask:=Image.load_from_file(record.walk_path)
	if raw==null or mask==null or raw.get_size()!=Vector2i(C.SIZE) or mask.get_size()!=Vector2i(C.SIZE): _reject("Fourth-layer full raw/mask unavailable"); return
	raw.convert(Image.FORMAT_RGBA8); mask.convert(Image.FORMAT_RGBA8)
	var expected: Image=C._raster_walk_cpu(raw,record.objects,_is_cancelled)
	if _is_cancelled(): return
	if expected==null or expected.get_data()!=mask.get_data(): _reject("Fourth-layer mask is not original raw minus explicit solids"); return
	var solids: Array[PackedVector2Array]=C.object_solids(record.objects)
	if not C._all_gameplay_safe_cpu(record,mask,solids,_is_cancelled) or not _routes17(record,mask,solids,_is_cancelled): _reject("Fourth-layer exact875+17/4px routes blocked"); return
	if _is_cancelled(): return
	record.city_revision_binding_sha=BIND_SHA
	record.city_revision_manifest_sha=CITY_PINS[String(_id)].manifest
	record.city_revision_original_portals=_original.gameplay_slots.portals.duplicate(true)
	record.city_revision_fresh_arrivals=spec.fresh_arrival_overrides.duplicate(true)
	_packet={"record":record,"solids":solids,"walk_bytes":mask.get_data(),"size":mask.get_size(),"path":record.walk_path,"bytes":mask.get_data(),"spec":spec,"home":home,"city":city,"enabled_doors":config.runtime_enabled_doors.duplicate(),"bindings":config}
	elapsed_ms=Time.get_ticks_msec()-started

static func _routes17(record: Dictionary,image: Image,solids: Array[PackedVector2Array],cancel: Callable) -> bool:
	for route: Dictionary in record.routes:
		for index in range(route.points_px.size()-1):
			var a:=C._vec(route.points_px[index]); var b:=C._vec(route.points_px[index+1]); var steps:=maxi(1,ceili(a.distance_to(b)/4.0))
			for step in range(steps+1):
				if cancel.call(): return false
				var foot:=a.lerp(b,float(step)/float(steps))
				if not C._safe_body_cpu(foot,image,solids): return false
				for i in 17:
					var sample:=foot if i==0 else foot+Vector2(cos(TAU*(i-1)/16.0)*10,sin(TAU*(i-1)/16.0)*6)
					var color:=image.get_pixelv(Vector2i(roundi(sample.x),roundi(sample.y)))
					if color.r<.5 or color.a<.5: return false
					for polygon: PackedVector2Array in solids:
						if Geometry2D.is_point_in_polygon(sample,polygon): return false
	return true

static func materialize_after_original(original: SceneScript,packet_data: Dictionary) -> SceneScript:
	if original==null or packet_data.is_empty(): return null
	var city: Dictionary=packet_data.city
	var helper: Variant=load(city.helper_path)
	var expected: SceneScript=helper.apply_candidate(original,packet_data.record,packet_data.spec,packet_data.home)
	if expected==null: return null
	expected.set_meta(META,CITY_PINS[String(original.scene_id)].manifest)
	# First match the exact published nine-portal candidate, then apply only
	# explicit door enabling. No published file/metadata is silently rewritten.
	var published:=ResourceLoader.load(city.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if published==null or published.resource_path!=city.scene_path or published.map_layout.resource_path!=city.layout_path or not helper.serialized_equal(published,expected): return null
	var disabled: Array[Dictionary]=[]
	for portal: Dictionary in expected.map_layout.portals.duplicate():
		if not portal.get("candidate_only",false): continue
		var building_id:=String(portal.get("building_id",""))
		if not building_id in packet_data.enabled_doors:
			if building_id!="southwest_market_front": return null
			var slot:=_find(packet_data.record.gameplay_slots.portals,"source_id",String(portal.id))
			if slot.is_empty(): return null
			disabled.append({"id":String(portal.id),"building_id":building_id,"reason":"SOURCE_ANCHOR_IS_SOLID_CENTRAL_POST_NOT_DOOR","published_manifest_sha":CITY_PINS[String(original.scene_id)].manifest})
			expected.map_layout.portals.erase(portal)
			packet_data.record.gameplay_slots.portals.erase(slot)
			continue
		portal.enabled=true
		portal.router_install_status="EXPLICIT_NESTED_ID_RESOLVER_CANDIDATE"
	if original.scene_id==&"ch4_s3_luoyang_market" and disabled.size()!=1: return null
	if original.scene_id==&"ch4_s3_luoyang_market" and (expected.map_layout.portals.size()!=12 or packet_data.record.gameplay_slots.portals.size()!=12): return null
	packet_data.record.city_revision_disabled_portals=disabled
	expected.set_meta("city_revision_runtime_binding_sha",BIND_SHA)
	expected.set_meta("city_revision_published_scene_path",city.scene_path)
	expected.set_meta("city_revision_source_scene_path","res://data/scenes/%s.tres"%String(original.scene_id))
	expected.set_meta("city_frontage_revision_runtime_status","ROOT_APPROVED_DEFAULT_REVISION" if FORMAL_ENABLED else "BOUND_RUNTIME_CANDIDATE_NOT_FORMAL")
	return expected

static func serialized_equal(a: SceneScript,b: SceneScript) -> bool:
	if a==null or b==null or a.scene_id!=b.scene_id or not bound(a) or not bound(b): return false
	var helper: Variant=load("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd" if a.scene_id==&"ch4_s3_luoyang_market" else "res://scripts/city/luoyang_city_revision_candidate_20261015.gd")
	return helper.serialized_equal(a,b)
