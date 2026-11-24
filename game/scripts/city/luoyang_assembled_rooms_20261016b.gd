extends RefCounted
## Independently authored floor shell + transparent furniture. No old raster
## overlay and no inherited 20261016 baked-room geometry or identity proof.
const FLAG := "--luoyang-assembled-scenes-20261016b"
const FORMAL_ENABLED := true
const ROOM := &"luoyang_market_shop_interior_20261015"
const CITY := &"ch4_s3_luoyang_market"
const META := "assembled_ground_feet_20261016b"
const SELF_PATH := "res://scripts/city/luoyang_assembled_rooms_20261016b.gd"
const AUTHOR_PATH := "res://data/maps/luoyang_assembled_rooms_20261016b/smithy_author.json"
const AUTHOR_SHA := "760e0169750c73579cd59679dddeaf89c7e2de349e83dd90c812cfaea37ae9b9"
const SIZE := Vector2(1536,1024)
const NATIVE_BODY := Vector2(34,24)
const GEOMETRY=preload("res://scripts/city/luoyang_functional_interiors_20261016.gd")

static func enabled() -> bool: return FORMAL_ENABLED or FLAG in OS.get_cmdline_user_args()
static func _rooms() -> Variant: return load("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
static func known(id: StringName) -> bool: return _rooms().known(id) if _rooms().overrides(id) else ((enabled() and id==ROOM) or (id!=ROOM and _rooms().known(id)))

static func author() -> Dictionary:
	if FileAccess.get_sha256(AUTHOR_PATH)!=AUTHOR_SHA: return {}
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR_PATH))
	if not parsed is Dictionary or parsed.get("schema_version")!=1 or parsed.get("status")!="READY_ASSEMBLED_CANDIDATE" or parsed.get("coordinate_contract")!=META or parsed.get("assets_ready")!=true: return {}
	if parsed.get("room",{}).get("scene_id")!=String(ROOM) or parsed.get("furniture",[]).size()!=6 or parsed.get("source_sha256",{}).is_empty(): return {}
	return parsed

static func _sources_match(data: Dictionary) -> bool:
	if data.is_empty(): return false
	for path: String in data.source_sha256:
		if not path.begins_with("res://") or ".." in path or FileAccess.get_sha256(path)!=data.source_sha256[path]: return false
	return true

static func sources_match(data: Dictionary) -> bool: return _sources_match(data)

static func source_paths() -> Dictionary:
	var data:=author()
	if data.is_empty(): return {}
	var result: Dictionary={SELF_PATH:true,AUTHOR_PATH:true,"res://scripts/city/luoyang_assembled_furniture_fade_20261016b.gd":true,"res://scripts/city/luoyang_assembled_low_furniture_fade_20261016.gd":true}
	for path: String in data.source_sha256: result[path]=true
	var extra: Dictionary=_rooms().source_paths()
	if extra.is_empty(): return {}
	result.merge(extra)
	return result

static func room_path(id: StringName) -> String:
	if id!=ROOM or _rooms().overrides(id): return _rooms().room_path(id)
	var data:=author()
	return String(data.room.scene_path) if known(id) and _sources_match(data) else ""

static func return_binding(id: StringName) -> Dictionary:
	if id!=ROOM or _rooms().overrides(id): return _rooms().return_binding(id)
	var data:=author()
	return data.get("room",{}).duplicate(true) if known(id) else {}

static func matches(scene: SceneScript,id: StringName) -> bool:
	if id!=ROOM or _rooms().overrides(id): return _rooms().matches(scene,id)
	if scene==null or not known(id) or scene.scene_id!=id or not scene.actor_positions_are_feet or scene.get_meta("assembled_room_contract","")!=META: return false
	var data:=author()
	if not _sources_match(data) or scene.resource_path!=data.room.scene_path or scene.map_layout==null or scene.map_layout.resource_path!=data.room.layout_path or scene.background_path!=data.shell.texture: return false
	var expected:=ResourceLoader.load(data.room.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(data.room.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if expected==null or layout==null or not expected.actor_positions_are_feet or expected.on_enter_dialog!=null or not expected.hotspots.is_empty() or not expected.trigger_zones.is_empty(): return false
	expected.map_layout=layout
	return load("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd").serialized_equal(scene,expected)

static func is_room(scene: SceneScript) -> bool:
	if scene!=null and (scene.scene_id!=ROOM or _rooms().overrides(scene.scene_id)): return _rooms().is_room(scene)
	return scene!=null and known(scene.scene_id) and scene.get_meta("assembled_room_contract","")==META

static func geometry_for(scene: SceneScript) -> Dictionary:
	if scene!=null and (scene.scene_id!=ROOM or _rooms().overrides(scene.scene_id)): return _rooms().geometry_for(scene)
	return author().get("geometry",{}).duplicate(true) if matches(scene,scene.scene_id) else {}

static func compile_geometry(geometry: Dictionary,world_size: Vector2) -> Dictionary:
	if geometry.get("coordinate_contract")==_rooms().META: return _rooms().compile_geometry(geometry,world_size)
	return GEOMETRY.compile_geometry(geometry,world_size)

static func safe_foot(geometry: Dictionary,foot: Vector2,world_size: Vector2,full_samples: bool=false) -> bool:
	if geometry.get("coordinate_contract")==_rooms().META: return _rooms().safe_foot(geometry,foot,world_size,full_samples)
	# This is a pure adapter to the existing rectangle/polygon implementation.
	# Its +42 is cancelled mathematically here; the NEW Player node is already
	# at its ground feet and its native collision child is at ZERO, not +42.
	return GEOMETRY.safe_origin(geometry,foot-Vector2(0,42),world_size,full_samples)

static func safe_motion(geometry: Dictionary,from: Vector2,to: Vector2,world_size: Vector2) -> bool:
	if geometry.get("coordinate_contract")==_rooms().META: return _rooms().safe_motion(geometry,from,to,world_size)
	if not from.is_finite() or not to.is_finite(): return false
	var steps:=maxi(1,ceili(from.distance_to(to)/4.0))
	for index: int in range(steps+1):
		if not safe_foot(geometry,from.lerp(to,float(index)/steps),world_size): return false
	return true

static func project_objects(scene: SceneScript,world_size: Vector2) -> Array:
	if scene!=null and (scene.scene_id!=ROOM or _rooms().overrides(scene.scene_id)): return _rooms().project_objects(scene,world_size)
	var data:=author()
	if not is_room(scene) or data.is_empty() or not world_size.is_finite() or world_size.x<=0 or world_size.y<=0: return []
	var objects: Array=[]
	for item: Dictionary in data.furniture:
		var native_size:=Vector2(item.source_size_px[0],item.source_size_px[1])
		var anchor:=Vector2(item.source_ground_anchor_px[0],item.source_ground_anchor_px[1])
		var foot:=Vector2(item.placement_foot_px[0],item.placement_foot_px[1])
		var ratio: float=float(item.render_scale)
		if native_size.x<=0 or native_size.y<=0 or not anchor.is_finite() or not foot.is_finite() or not is_finite(ratio) or ratio<=0: return []
		objects.append({"id":item.id,"texture":item.texture,"centered":false,"pos":(foot-anchor*ratio)/SIZE,"render_size_px":native_size*ratio*(world_size/SIZE),"sort_by_feet":true,"depth_sort_foot_y":float(item.depth_foot_y)/SIZE.y,"assembled_furniture":true,"source_ground_anchor_px":anchor,"placement_foot_px":foot,"assembly_author_sha":AUTHOR_SHA})
	return objects

static func fade_ids(scene: SceneScript=null) -> Array:
	if scene!=null and (scene.scene_id!=ROOM or _rooms().overrides(scene.scene_id)): return _rooms().fade_ids(scene)
	var result: Array=[]
	for item: Dictionary in author().get("furniture",[]):
		if item.get("fade_allowed")==true: result.append(String(item.id))
	return result

static func prop_ids(scene: SceneScript=null) -> Array:
	if scene!=null and (scene.scene_id!=ROOM or _rooms().overrides(scene.scene_id)): return _rooms().prop_ids(scene)
	var result: Array=[]
	for item: Dictionary in author().get("furniture",[]): result.append(String(item.id))
	return result

static func room_return(source: StringName,target: StringName,authored: Variant,remembered: Variant) -> Dictionary:
	if source!=ROOM or _rooms().overrides(source): return _rooms().room_return(source,target,authored,remembered)
	var binding:=return_binding(source)
	if binding.is_empty() or target!=CITY or not authored is Vector2 or authored!=Vector2(binding.return_foot_px[0],binding.return_foot_px[1])/Vector2(3072,2048) or not _sources_match(author()): return {}
	var arrival: Vector2=remembered if remembered is Vector2 else authored
	var city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	if not arrival.is_finite() or not city.safe_body(target,arrival*Vector2(3072,2048)): return {}
	return {"spawn":arrival,"source_version":3,"target_version":3,"reason":"assembled_room_groundfeet_to_same_outdoor_actual_feet"}
