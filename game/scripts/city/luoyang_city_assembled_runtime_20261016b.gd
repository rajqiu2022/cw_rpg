extends RefCounted
## NEW child consumes the complete original enclosure/frontage proof first.
## Same exclusive CPU job lifecycle; never prepares C or edits frozen parents.
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const A=preload("res://scripts/city/luoyang_city_assembled_retry2_20261016b.gd")
const SERIAL=preload("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd")
const ASSEMBLED_SERIAL=preload("res://scripts/city/luoyang_city_assembled_serialized_20261016b.gd")
const FLAG="--luoyang-assembled-scenes-20261016b"
const FORMAL_ENABLED=true
const META="city_assembled_runtime_binding_sha_20261016b"
const BIND_PATH="res://data/maps/luoyang_city_assembled_20261016b/runtime_bindings.json"
const BIND_SHA="0eefe2fcf873bd9e237bc474c2db6603d916f93dec2e9d513a464345a070f8e9"
const PREFIX="res://build/luoyang_city_assembled_publication_20261016b/78428_1686/"
const PINS={"ch4_s1_luoyang_yamen":"517a0e68c01dd2ff27a648f72736a100c8523780d5f49423b682c3452b94a32f","ch4_s3_luoyang_market":"eac64463aa3bc00835114b0856e6e00a98d57c38d0fd6e8de472f329cd28bd13"}
var _token=0
var _id: StringName=&""
var _original: Dictionary={}
var _packet: Dictionary={}
var _error=""
var _mutex=Mutex.new()
var _cancelled=false
var _joined=false
var elapsed_ms=0
static func enabled() -> bool: return FORMAL_ENABLED or FLAG in OS.get_cmdline_user_args()
static func requested(id: StringName) -> bool: return enabled() and PINS.has(String(id))
static func bound(scene: SceneScript) -> bool:
	return scene!=null and requested(scene.scene_id) and scene.map_layout!=null and scene.get_meta(META,"")==BIND_SHA and scene.get_meta(A.META,"")==A.AUTHOR_SHA and scene.get_meta("city_assembled_manifest_sha","")==PINS[String(scene.scene_id)] and scene.map_layout.walkable_mask_path==PREFIX+String(scene.scene_id)+"/walk.png" and scene.map_layout.schema_version==C.VERSION and scene.get_meta("city_enclosure_manifest_sha","")==C.manifest_sha(scene.scene_id) and scene.get_meta("city_ground_manifest_sha","")==C.ground_manifest_sha(scene.scene_id)
static func _bindings() -> Dictionary:
	if FileAccess.get_sha256(BIND_PATH)!=BIND_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(BIND_PATH))
	return value if value is Dictionary and value.get("status")=="CANDIDATE_AFTER_COMPLETE_PARENT_NOT_FORMAL" and value.get("author_sha256")==A.AUTHOR_SHA else {}
static func _sources(config: Dictionary,cancel: Callable=Callable()) -> bool:
	if config.get("source_sha256",{}).is_empty(): return false
	for path: String in config.source_sha256:
		if cancel.is_valid() and cancel.call(): return false
		if not path.begins_with("res://") or ".." in path or FileAccess.get_sha256(path)!=config.source_sha256[path]: return false
	return true
static func source_paths() -> Dictionary:
	var config:=_bindings()
	if config.is_empty(): return {}
	var paths={BIND_PATH:true,"res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd":true,"res://scripts/city/luoyang_city_assembled_fade_20261016b.gd":true}
	for path: String in config.source_sha256: paths[path]=true
	return paths
static func room_known(id: StringName) -> bool: return enabled() and _bindings().get("rooms",{}).has(String(id))
static func room_binding(id: StringName) -> Dictionary: return _bindings().get("rooms",{}).get(String(id),{}).duplicate(true) if room_known(id) else {}
static func room_path(id: StringName) -> String:
	var config:=_bindings()
	return String(config.rooms[String(id)].scene_path) if room_known(id) and _sources(config) else ""
static func room_matches(scene: SceneScript,id: StringName) -> bool:
	var config:=_bindings(); var room: Dictionary=config.get("rooms",{}).get(String(id),{})
	if scene==null or not room_known(id) or not _sources(config) or scene.scene_id!=id or scene.resource_path!=room.scene_path or scene.map_layout==null or scene.map_layout.resource_path!=room.layout_path: return false
	var expected:=ResourceLoader.load(room.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	return expected!=null and expected.get_meta("city_relocated_room_author_sha_20261016b","")==A.AUTHOR_SHA and SERIAL.serialized_equal(scene,expected)
static func room_return(source: StringName,target: StringName,authored: Variant,remembered: Variant) -> Dictionary:
	var room:=room_binding(source)
	if room.is_empty() or target!=&"ch4_s3_luoyang_market" or not authored is Vector2 or authored!=C._vec(room.return_foot_px)/C.SIZE or not _sources(_bindings()): return {}
	var foot: Vector2=remembered if remembered is Vector2 else authored
	return {"spawn":foot,"source_version":3,"target_version":3,"reason":"assembled_relocated_home_exact_authored_and_actual_return"} if foot.is_finite() and C.safe_body(target,foot*C.SIZE) else {}
static func serialized_equal(actual: SceneScript,expected: SceneScript) -> bool:
	return bound(actual) and bound(expected) and ASSEMBLED_SERIAL.equal(actual,expected)
static func publication_record_equal(native: Dictionary,published: Dictionary) -> bool:
	# The frozen publisher's exact _write protocol is JSON.stringify(value,
	# "\t",true,true), then JSON.parse_string on readback. The file retains
	# 245.75999450683594, but its parsed double is245.7599945068359. Thus even
	# full_precision output does not imply native-double identity after parsing.
	# Compare every field/type/value in THAT explicit wire domain, never epsilon
	# or a deleted-field whitelist. Keep native unchanged for actual geometry.
	var encoded: Variant=JSON.parse_string(JSON.stringify(native,"\t",true,true))
	return encoded is Dictionary and C._equal_value(encoded,published)
func configure(token: int,id: StringName,original: Dictionary) -> bool:
	if token<0 or not requested(id) or original.get("canonical_scene_id")!=String(id) or not _original.is_empty() or _bindings().is_empty(): return false
	_token=token; _id=id; _original=original.duplicate(true); return true
func request_cancel() -> void:
	_mutex.lock(); _cancelled=true; _mutex.unlock()
func _is_cancelled() -> bool:
	_mutex.lock(); var value: bool=_cancelled; _mutex.unlock(); return value
func mark_joined(token: int,id: StringName) -> bool:
	_joined=token==_token and id==_id and not _is_cancelled(); return _joined
func packet(token: int,id: StringName) -> Dictionary: return _packet if _joined and token==_token and id==_id and not _is_cancelled() else {}
func error() -> String: return _error
func release() -> void:
	_original.clear(); _packet.clear(); _token=0; _joined=false
func _reject(message: String) -> void: _error=message; _packet.clear()
func run() -> void:
	var started:=Time.get_ticks_msec(); var config:=_bindings()
	if not _sources(config,_is_cancelled): _reject("Assembled source closure changed/cancelled"); return
	var author:=A.author(); var spec:=A.spec_for(author,_id); var donors: Dictionary={}
	for path: String in author.get("source_sha256",{}):
		if path.ends_with(".json"): donors[path]=JSON.parse_string(FileAccess.get_file_as_string(path))
	var city: Dictionary=config.get("cities",{}).get(String(_id),{})
	var manifest: Variant=JSON.parse_string(FileAccess.get_file_as_string(String(city.get("manifest_path",""))))
	if not manifest is Dictionary or manifest.get("status")!="NEW_LAYOUT_CPU_PUBLISHED_NOT_IMPORTED_NOT_RUNTIME_NOT_FORMAL" or manifest.get("author_sha256")!=A.AUTHOR_SHA: _reject("Assembled publication identity missing"); return
	var record:=A.compose(_original,spec,donors)
	if record.is_empty(): _reject("Assembled explicit parent composition refused"); return
	record.walk_path=manifest.walk_path
	if not publication_record_equal(record,manifest.record): _reject("Assembled complete published record differs in exact original writer domain"); return
	var raw:=Image.load_from_file(String(record.raw_walk_path)); var mask:=Image.load_from_file(String(record.walk_path))
	if raw==null or mask==null or raw.get_size()!=Vector2i(C.SIZE) or mask.get_size()!=Vector2i(C.SIZE): _reject("Assembled original raw support/mask unavailable"); return
	raw.convert(Image.FORMAT_RGBA8); mask.convert(Image.FORMAT_RGBA8)
	var raster:=C._raster_walk_cpu(raw,record.objects,_is_cancelled)
	if _is_cancelled(): return
	if raster==null or raster.get_data()!=mask.get_data(): _reject("Assembled mask is not exact original raw-minus-solids"); return
	var solids:=C.object_solids(record.objects)
	if not C._all_gameplay_safe_cpu(record,mask,solids,_is_cancelled) or not _routes17(record,mask): _reject("Assembled875+17/4px routes refused"); return
	if _is_cancelled(): return
	_packet={"record":record,"solids":solids,"walk_bytes":mask.get_data(),"bytes":mask.get_data(),"size":mask.get_size(),"path":record.walk_path,"city":city,"spec":spec,"parent_record":_original.duplicate(true)}
	elapsed_ms=Time.get_ticks_msec()-started
func _routes17(record: Dictionary,mask: Image) -> bool:
	for route: Dictionary in record.routes:
		for i: int in range(route.points_px.size()-1):
			var a:=C._vec(route.points_px[i]); var b:=C._vec(route.points_px[i+1]); var n:=maxi(1,ceili(a.distance_to(b)/4.0))
			for j: int in range(n+1):
				if _is_cancelled(): return false
				var foot:=a.lerp(b,float(j)/n)
				for d: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
					var p:=Vector2i((foot+d).round())
					if p.x<0 or p.y<0 or p.x>=mask.get_width() or p.y>=mask.get_height(): return false
					var color:=mask.get_pixelv(p)
					if color.r<.5 or color.a<.5: return false
	return true
static func materialize_after_original(parent: SceneScript,packet_data: Dictionary) -> SceneScript:
	if parent==null or packet_data.is_empty(): return null
	var city: Dictionary=packet_data.city
	var expected:=A.apply_scene(parent,packet_data.record,String(city.walk_path))
	var published:=ResourceLoader.load(city.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if expected==null or published==null or not ASSEMBLED_SERIAL.equal(expected,published): return null
	# NPCs/interactions/task anchors are strictly unchanged before task projection.
	if not C._equal_value(parent.npcs,expected.npcs) or not C._equal_value(parent.map_layout.interactions,expected.map_layout.interactions): return null
	expected.set_meta(META,BIND_SHA); expected.set_meta("city_assembled_manifest_sha",PINS[String(parent.scene_id)])
	expected.set_meta("city_assembled_published_scene_path",city.scene_path)
	packet_data.record["assembled_runtime_binding_sha"]=BIND_SHA
	packet_data.record["assembled_parent_task_semantics_preserved"]=true
	return expected
