extends RefCounted
## Exact new-room override, never an amendment to the frozen 20261015 proof.
## Two matched market doors; warehouse remains disabled until native acceptance.
const FLAG := "--luoyang-functional-interiors-20261016"
const FORMAL_ENABLED := true
const SELF_PATH := "res://scripts/city/luoyang_functional_interiors_20261016.gd"
const REGISTRY_PATH := "res://data/maps/luoyang_functional_interiors_20261016/registry.json"
const REGISTRY_SHA := "da704adefa51d4c523e92eea9faae6e1d0a257dc3fc0b4789427300503709eba"
const META := "20261016_sourcefeet_legacy42"
const SOURCE_SIZE := Vector2(1536,1024)
const BODY := Vector2(34,24)
const FOOT_OFFSET := Vector2(0,42)
const CITIES := [&"ch4_s3_luoyang_market",&"ch4_s2_canal_docks"]

static func enabled() -> bool: return FORMAL_ENABLED or FLAG in OS.get_cmdline_user_args()
static func _assembly() -> Variant: return load("res://scripts/city/luoyang_assembled_rooms_20261016b.gd")
static func _city_assembly() -> Variant: return load("res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd")

static func _registry() -> Dictionary:
	if FileAccess.get_sha256(REGISTRY_PATH)!=REGISTRY_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(REGISTRY_PATH))
	return value if value is Dictionary and value.get("schema_version")==1 and value.get("coordinate_contract")==META else {}

static func known(id: StringName) -> bool:
	if _assembly().known(id) or _city_assembly().room_known(id): return true
	return enabled() and _registry().get("rooms",{}).get(String(id),{}).get("door_enabled")==true

static func row(id: StringName) -> Dictionary:
	return _registry().get("rooms",{}).get(String(id),{}).duplicate(true)

static func source_paths() -> Dictionary:
	var config:=_registry()
	if config.is_empty(): return {}
	var result: Dictionary={SELF_PATH:true,REGISTRY_PATH:true}
	for path: String in config.get("source_sha256",{}):
		if not path.begins_with("res://") or ".." in path: return {}
		result[path]=true
	var approval: Dictionary=config.get("import_approval",{})
	if not approval.is_empty(): result[String(approval.path)]=true
	if _assembly().enabled():
		var extra: Dictionary=_assembly().source_paths()
		if extra.is_empty(): return {}
		result.merge(extra)
	return result

static func _check_sources(config: Dictionary) -> bool:
	if config.get("source_sha256",{}).is_empty(): return false
	for path: String in config.source_sha256:
		if FileAccess.get_sha256(path)!=config.source_sha256[path]: return false
	# A raw PNG is not authorization to silently load a differently imported image.
	var approval: Dictionary=config.get("import_approval",{})
	return not approval.is_empty() and FileAccess.get_sha256(String(approval.get("path","")))==approval.get("sha256")

static func room_path(id: StringName) -> String:
	if _assembly().known(id): return _assembly().room_path(id)
	if _city_assembly().room_known(id): return _city_assembly().room_path(id)
	if not known(id): return ""
	var config:=_registry()
	return String(config.rooms[String(id)].scene_path) if _check_sources(config) else ""

static func matches(scene: SceneScript,id: StringName) -> bool:
	if _assembly().known(id): return _assembly().matches(scene,id)
	if _city_assembly().room_known(id): return _city_assembly().room_matches(scene,id)
	if scene==null or not known(id) or scene.scene_id!=id or scene.get_meta("functional_interior_revision","")!=META: return false
	var config:=_registry()
	var item: Dictionary=config.rooms[String(id)]
	if not _check_sources(config) or scene.resource_path!=item.scene_path or scene.map_layout==null or scene.map_layout.resource_path!=item.layout_path: return false
	var expected:=ResourceLoader.load(item.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(item.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if expected==null or layout==null or expected.actor_positions_are_feet or not expected.is_walkable or expected.on_enter_dialog!=null or not expected.hotspots.is_empty() or not expected.trigger_zones.is_empty(): return false
	expected.map_layout=layout
	# Pinned new NPC definitions are included in the entire serialized scene.
	# The old R.emptyNPC condition remains untouched for all old room resources.
	return load("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd").serialized_equal(scene,expected)

static func is_room(scene: SceneScript) -> bool:
	return scene!=null and scene.get_meta("functional_interior_revision","")==META and known(scene.scene_id)

static func author_for(scene: SceneScript) -> Dictionary:
	if not matches(scene,scene.scene_id): return {}
	var item:=row(scene.scene_id)
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(item.author_path))
	return value if value is Dictionary and value.get("schema_version")==2 else {}

static func _v(value: Variant) -> Vector2:
	return Vector2(value[0],value[1]) if value is Array and value.size()==2 else Vector2(INF,INF)

static func _poly(value: Array,scale: Vector2=Vector2.ONE) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point: Variant in value: result.append(_v(point)*scale)
	return result

static func origin_uv(source_foot: Vector2,world_size: Vector2) -> Vector2:
	return source_foot/SOURCE_SIZE-FOOT_OFFSET/world_size

static func compile_geometry(author: Dictionary,world_size: Vector2) -> Dictionary:
	var result:=author.duplicate(true)
	var source_floors: Array=[]; var source_solids: Array=[]
	var world_floors: Array=[]; var world_solids: Array=[]
	var scale: Vector2=world_size/SOURCE_SIZE
	for region: Array in author.get("floor_regions_px",[]):
		source_floors.append(_poly(region)); world_floors.append(_poly(region,scale))
	for obstacle: Dictionary in author.get("furniture_bases",[]):
		if obstacle.get("blocking")==true:
			source_solids.append(_poly(obstacle.ground_polygon_px)); world_solids.append(_poly(obstacle.ground_polygon_px,scale))
	result["_compiled"]={"world_size":world_size,"source_floors":source_floors,"source_solids":source_solids,"world_floors":world_floors,"world_solids":world_solids}
	return result

static func safe_origin(author: Dictionary,origin: Vector2,world_size: Vector2,full_samples: bool=false) -> bool:
	if author.is_empty() or not origin.is_finite() or not world_size.is_finite() or world_size.x<=0 or world_size.y<=0: return false
	if not author.has("_compiled") or author._compiled.world_size!=world_size: return false
	var foot: Vector2=origin+FOOT_OFFSET
	var body:=PackedVector2Array([foot+Vector2(-17,-12),foot+Vector2(17,-12),foot+Vector2(17,12),foot+Vector2(-17,12)])
	var scale: Vector2=world_size/SOURCE_SIZE
	var inside:=false
	for region: PackedVector2Array in author._compiled.world_floors:
		if Geometry2D.clip_polygons(body,region).is_empty(): inside=true; break
	if not inside: return false
	for obstacle: PackedVector2Array in author._compiled.world_solids:
		if not Geometry2D.intersect_polygons(body,obstacle).is_empty(): return false
	if full_samples:
		# Independent native 35*25=875 foot samples, plus the 17 perimeter/cross
		# samples below. This is an audit option, never the frame-loop algorithm.
		for y: int in range(-12,13):
			for x: int in range(-17,18):
				if not _point_clear(author,(foot+Vector2(x,y))/scale): return false
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		if not _point_clear(author,(foot+offset)/scale): return false
	return true

static func _point_clear(author: Dictionary,point: Vector2) -> bool:
	var inside:=false
	for region: PackedVector2Array in author._compiled.source_floors:
		if Geometry2D.is_point_in_polygon(point,region): inside=true; break
	if not inside: return false
	for obstacle: PackedVector2Array in author._compiled.source_solids:
		if Geometry2D.is_point_in_polygon(point,obstacle): return false
	return true

static func safe_motion(author: Dictionary,from: Vector2,to: Vector2,world_size: Vector2) -> bool:
	if not from.is_finite() or not to.is_finite(): return false
	var steps:=maxi(1,ceili(from.distance_to(to)/4.0))
	for index: int in range(steps+1):
		if not safe_origin(author,from.lerp(to,float(index)/steps),world_size): return false
	return true

static func return_binding(id: StringName) -> Dictionary:
	if _assembly().known(id): return _assembly().return_binding(id)
	if _city_assembly().room_known(id): return _city_assembly().room_binding(id)
	return row(id) if known(id) else {}

static func project_portals(scene: SceneScript,original: Array) -> Dictionary:
	var result: Array=original.duplicate(true)
	if not enabled() or scene==null or scene.scene_id!=&"ch4_s3_luoyang_market": return {"ok":true,"portals":result}
	var contract: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	if not contract.revision_bound(scene) or not _check_sources(_registry()): return {"ok":false,"portals":[]}
	for id: String in _registry().rooms:
		var item:=row(StringName(id))
		if item.get("door_enabled")!=true or item.get("city_id")!=String(scene.scene_id): continue
		var count:=0
		for portal: Dictionary in result:
			if String(portal.get("target_scene",""))!=id: continue
			count+=1
			if portal.get("id")!="enter_"+String(item.building_id)+"_room" or portal.get("pos")!=_v(item.return_foot_px)/Vector2(3072,2048) or portal.get("target_pos")!=Vector2(.5,.625) or portal.get("size")!=Vector2(40.0/3072,32.0/2048) or portal.get("auto_trigger")!=false: return {"ok":false,"portals":[]}
			var author: Variant=JSON.parse_string(FileAccess.get_file_as_string(item.author_path))
			if not author is Dictionary: return {"ok":false,"portals":[]}
			if _assembly().known(StringName(id)):
				var assembled: Dictionary=_assembly().author()
				if not _assembly().sources_match(assembled): return {"ok":false,"portals":[]}
				portal.target_pos=_v(assembled.geometry.spawn_foot_px)/SOURCE_SIZE
				portal.target_scene_path=assembled.room.scene_path
			else:
				portal.target_pos=_v(author.spawn_foot_px)/SOURCE_SIZE
				portal.target_scene_path=item.scene_path
			portal.label="进入"+String(item.door_label)
		if count!=1: return {"ok":false,"portals":[]}
	return {"ok":true,"portals":result}

static func room_return(source: StringName,target: StringName,authored: Variant,remembered: Variant) -> Dictionary:
	if _assembly().known(source): return _assembly().room_return(source,target,authored,remembered)
	if _city_assembly().room_known(source): return _city_assembly().room_return(source,target,authored,remembered)
	var item:=return_binding(source)
	if item.is_empty() or String(target)!=item.city_id or not authored is Vector2 or authored!=_v(item.return_foot_px)/Vector2(3072,2048) or not _check_sources(_registry()): return {}
	var arrival: Vector2=remembered if remembered is Vector2 else authored
	var contract: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	if not arrival.is_finite() or not contract.safe_body(target,arrival*Vector2(3072,2048)): return {}
	return {"spawn":arrival,"source_version":3,"target_version":3,"reason":"functional_room_exact_door_and_actual_remembered_feet"}

static func owns_dialog(id: String) -> bool:
	return id in ["luoyang_distinct_rooms_20261016/smith_daily","luoyang_distinct_rooms_20261016/cloth_daily","luoyang_distinct_rooms_20261016/warehouse_daily"]

static func dialog_allowed(scene: SceneScript,id: String) -> bool:
	if not owns_dialog(id): return true
	if _assembly().is_room(scene):
		return _assembly().matches(scene,scene.scene_id) and id=="luoyang_distinct_rooms_20261016/smith_daily" and FileAccess.get_sha256("res://data/dialogs/"+id+".tres")==_assembly().author().source_sha256.get("res://data/dialogs/"+id+".tres","")
	if not is_room(scene): return false
	var path: String="res://data/dialogs/"+id+".tres"
	var expected: String=_registry().get("source_sha256",{}).get(path,"")
	if expected.is_empty() or FileAccess.get_sha256(path)!=expected: return false
	for npc: Dictionary in scene.npcs:
		if npc.get("dialog_id")==id: return true
	return false
