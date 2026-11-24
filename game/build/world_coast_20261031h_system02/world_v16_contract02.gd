extends RefCounted
## NEW candidate coordinate space. Layout format15 is not coordinate version15.
const VERSION := 16
const SIZE := Vector2(12288,8192)
const TILE_SIZE := Vector2i(1536,1024)
const CANDIDATE_ID := &"world_map_jianghu_v16"
const CANDIDATE_PATH := "res://build/world_coast_20261031h_system01/world_v16_scene02.tres"
const LAYOUT_PATH := "res://build/world_coast_20261031h_system01/world_v16_layout02.tres"
const STREAM_PATH := "res://build/world_coast_20261031h_system01/world_v16_stream02.tres"
const ROOT := "res://art/maps/world_coast_20261031h/candidate02/"
const MANIFEST_PATH := ROOT+"runtime_contract.json"
## Root fills only after reviewing the completed actual candidate manifest.
## Empty is intentionally NOT_READY, never current-disk implicit approval.
const MANIFEST_SHA := "f4c592117bfc2a1350674f2b26f79b633e82c6bbc5ee00d42b4d79d06635db89"
const REVISION := "world_coast_20261031h"
const OLD_ROOT := "res://art/maps/world_map_v15_complete_v9c/"
const V15 = preload("res://scripts/world/world_map_v15_contract.gd")
const PORTAL_IDS = V15.PORTAL_IDS
const NAV_TILE_CACHE_LIMIT := 12
static var _manifest: Dictionary = {}
static var _bound_layout: WalkableMapLayout
static var _tiles: Dictionary = {}
static var _lru: Array[Vector2i] = []
static var _solids: Array[PackedVector2Array] = []
static var _solid_bounds: Array[Rect2] = []
static var _rects: Array[Rect2] = []
static var _migration_debug: Dictionary = {}
static var _error := "NOT_BOUND"

static func _pair(value: Variant) -> Vector2:
	if not value is Array or value.size()!=2:return Vector2(INF,INF)
	for scalar: Variant in value:
		if typeof(scalar) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(scalar)):return Vector2(INF,INF)
	return Vector2(float(value[0]),float(value[1]))

static func _polygon(value: Variant) -> PackedVector2Array:
	var result:=PackedVector2Array()
	if not value is Array:return result
	for raw: Variant in value:
		var p:=_pair(raw)
		if not p.is_finite():return PackedVector2Array()
		result.append(p)
	return result

static func _sha(path: String, expected: Variant) -> bool:
	return expected is String and expected.length()==64 and FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==expected.to_lower()

static func _identity(scene: SceneScript) -> bool:
	return scene!=null and scene.scene_id in [&"world_map_jianghu",CANDIDATE_ID] and scene.map_layout!=null and scene.map_layout.resource_path==LAYOUT_PATH and scene.map_layout.schema_version==15 and scene.map_layout.design_size==Vector2i(SIZE) and typeof(scene.map_layout.get_meta("coordinate_space_version",null))==TYPE_INT and scene.map_layout.get_meta("coordinate_space_version") == VERSION and scene.map_layout.get_meta("geography_revision","")==REVISION and scene.streamed_background!=null and scene.streamed_background.resource_path==STREAM_PATH and scene.streamed_background.logical_size==Vector2i(SIZE) and scene.background_path==ROOT+"overview.png" and scene.streamed_background.mobile_preview_path==ROOT+"overview.png" and scene.streamed_background.desktop_preview_path==ROOT+"overview.png"

static func declared_identity(scene: SceneScript) -> bool:
	# Coordinate identity does not turn into an older space when its approval
	# is unavailable. Runtime admission still requires the full is_v16 gate.
	return _identity(scene)

static func is_v16(scene: SceneScript) -> bool:
	if not _identity(scene):return false
	if _bound_layout==scene.map_layout:return _error.is_empty()
	return _bind(scene)

static func _bind(scene: SceneScript) -> bool:
	_error="V16_CONTRACT_UNAVAILABLE";_manifest.clear();_tiles.clear();_lru.clear();_solids.clear();_solid_bounds.clear();_rects.clear();_bound_layout=null
	if not _sha(MANIFEST_PATH,MANIFEST_SHA):_error="V16_MANIFEST_NOT_ROOT_PINNED";return false
	var file:=FileAccess.open(MANIFEST_PATH,FileAccess.READ)
	if file==null or file.get_length()>2097152:return false
	var raw: Variant=JSON.parse_string(file.get_as_text())
	if not raw is Dictionary:return false
	var data: Dictionary=raw
	if data.get("coordinate_version")!=VERSION or _pair(data.get("world_size"))!=SIZE or data.get("scene_id")!=String(CANDIDATE_ID) or data.get("scene_path")!=CANDIDATE_PATH or data.get("layout_path")!=LAYOUT_PATH or data.get("stream_path")!=STREAM_PATH or data.get("overview_path")!=ROOT+"overview.png":return false
	if not _sha(LAYOUT_PATH,data.get("layout_sha256")) or not _sha(STREAM_PATH,data.get("stream_sha256")) or not _sha(CANDIDATE_PATH,data.get("scene_sha256")):return false
	var geometry: Variant=data.get("geometry")
	if not geometry is Dictionary or geometry.get("rf_path")!=ROOT+"terrain_height.rf" or geometry.get("mesh_path")!=ROOT+"terrain_patch.res":return false
	if not _sha(geometry.rf_path,geometry.get("rf_sha256")) or not _sha(geometry.mesh_path,geometry.get("mesh_sha256")):return false
	var rf_file:=FileAccess.open(geometry.rf_path,FileAccess.READ)
	if rf_file==null or rf_file.get_length()!=1537*1025*4:return false
	if geometry.get("baseline_mesh_path")!=OLD_ROOT+"terrain_mesh.res" or not _sha(geometry.baseline_mesh_path,geometry.get("baseline_mesh_sha256")):return false
	var nav: Variant=data.get("navigation_tiles")
	if not nav is Array or nav.size()!=64 or scene.map_layout.walkable_mask_tiles.size()!=64:return false
	var seen: Dictionary={}
	for index: int in range(64):
		var entry: Variant=nav[index]
		if not entry is Dictionary:return false
		var rect: Variant=entry.get("logical_rect")
		if not rect is Array or rect.size()!=4:return false
		var expected:=Rect2((index%8)*1536,(index/8)*1024,1536,1024)
		var coordinates: Array=[expected.position.x,expected.position.y,1536,1024]
		for component: int in range(4):
			if typeof(rect[component]) not in [TYPE_INT,TYPE_FLOAT] or float(rect[component])!=float(coordinates[component]):return false
		var path: String=String(entry.get("path",""))
		var suffix: String="chunks/r%d_c%d_walk.png"%[index/8,index%8]
		if path not in [ROOT+suffix,OLD_ROOT+suffix] or not _sha(path,entry.get("sha256")):return false
		var typed: Dictionary=scene.map_layout.walkable_mask_tiles[index]
		if typed.get("path")!=path or typed.get("logical_rect")!=expected or seen.has(path):return false
		seen[path]=true
	var regions: Variant=data.get("migration_regions")
	if not regions is Array:return false
	var region_ids: Dictionary={}
	for region: Variant in regions:
		if not region is Dictionary or not region.get("id") is String or region_ids.has(region.id) or region.get("historic_portal_id") not in ["east_sea_port","bailu_ferry","bianzhou"]:return false
		var polygon:=_polygon(region.get("source_polygon_px"))
		if polygon.size()<3 or Geometry2D.triangulate_polygon(polygon).is_empty():return false
		for p: Vector2 in polygon:
			if p.x<0 or p.y<0 or p.x>SIZE.x or p.y>SIZE.y:return false
		if region.has("source_x_range"):
			var interval:=_pair(region.source_x_range)
			if not interval.is_finite() or interval.x<0 or interval.y>SIZE.x or interval.x>=interval.y:return false
		region_ids[region.id]=true
	var moved: Variant=data.get("moved_portals")
	if not moved is Array:return false
	var moved_seen: Dictionary={}
	for id: Variant in moved:
		if id not in ["bianzhou","east_sea_port"] or moved_seen.has(id):return false
		moved_seen[id]=true
	var ids: Dictionary={}
	for portal: Dictionary in scene.map_layout.portals:
		var id: String=String(portal.get("id",""))
		if id not in PORTAL_IDS or ids.has(id):return false
		ids[id]=true
	if ids.size()!=16:return false
	for object: Dictionary in scene.map_layout.visual_objects:
		if object.has("solid_polygons_px"):
			var polygons: Variant=object.solid_polygons_px
			if not polygons is Array or polygons.is_empty():return false
			for p: Variant in polygons:
				if not p is PackedVector2Array or p.size()<3 or Geometry2D.triangulate_polygon(p).is_empty():return false
				var minimum: Vector2=p[0]
				var maximum: Vector2=p[0]
				for vertex: Vector2 in p:
					if not vertex.is_finite() or vertex.x<0 or vertex.y<0 or vertex.x>=SIZE.x or vertex.y>=SIZE.y:return false
					minimum=minimum.min(vertex);maximum=maximum.max(vertex)
				_solids.append(p)
				_solid_bounds.append(Rect2(minimum,maximum-minimum))
		elif object.has("collision_size"):
			var margin: Vector2=object.get("walkability_margin_px",Vector2(18.432,12.288))
			var extent: Vector2=object.collision_size*SIZE
			var center: Vector2=(object.get("pos",Vector2.ZERO)+object.get("collision_offset",Vector2.ZERO))*SIZE
			if not margin.is_finite() or not extent.is_finite() or not center.is_finite() or extent.x<=0 or extent.y<=0 or margin.x<0 or margin.y<0:return false
			_rects.append(Rect2(center-extent*.5-margin,extent+margin*2))
	for object: Dictionary in scene.map_layout.blockers:
		var extent: Vector2=object.get("size",Vector2.ZERO)*SIZE
		var center: Vector2=object.get("pos",Vector2.ZERO)*SIZE
		var margin: Vector2=object.get("walkability_margin_px",Vector2(64.512,43.008))
		if not margin.is_finite() or not extent.is_finite() or not center.is_finite() or extent.x<=0 or extent.y<=0 or margin.x<0 or margin.y<0:return false
		_rects.append(Rect2(center-extent*.5-margin,extent+margin*2))
	_manifest=data;_bound_layout=scene.map_layout;_error=""
	return true

static func _pixel_clear(point: Vector2) -> bool:
	if not point.is_finite() or point.x<0 or point.y<0 or point.x>=SIZE.x or point.y>=SIZE.y:return false
	var pixel:=Vector2i(roundi(point.x),roundi(point.y))
	if pixel.x<0 or pixel.y<0 or pixel.x>=int(SIZE.x) or pixel.y>=int(SIZE.y):return false
	var cell:=Vector2i(pixel.x/1536,pixel.y/1024)
	if not _tiles.has(cell):
		var index: int=cell.y*8+cell.x
		var path: String=_manifest.navigation_tiles[index].path
		var texture:=load(path) as Texture2D
		var bitmap: Image=texture.get_image() if texture!=null else null
		if bitmap!=null and bitmap.is_compressed():bitmap.decompress()
		if bitmap!=null and bitmap.get_size()!=TILE_SIZE:bitmap=null
		_tiles[cell]=bitmap
	_lru.erase(cell);_lru.append(cell)
	while _lru.size()>NAV_TILE_CACHE_LIMIT:_tiles.erase(_lru.pop_front())
	var bitmap: Image=_tiles[cell]
	if bitmap==null:return false
	var p:=pixel-cell*TILE_SIZE
	var color:=bitmap.get_pixel(p.x,p.y)
	return color.a>=.5 and maxf(color.r,maxf(color.g,color.b))>=.5

static func safe_foot(scene: SceneScript, point: Vector2) -> bool:
	if not point.is_finite() or not is_v16(scene):return false
	var samples:=PackedVector2Array([point*SIZE])
	for i: int in range(16):samples.append(point*SIZE+Vector2(cos(TAU*i/16.0)*10,sin(TAU*i/16.0)*6))
	for p: Vector2 in samples:
		if not _pixel_clear(p):return false
	var minimum: Vector2=point*SIZE-Vector2(10,6)
	var maximum: Vector2=point*SIZE+Vector2(10,6)
	for rect: Rect2 in _rects:
		if rect.position.x>maximum.x or rect.position.y>maximum.y or rect.end.x<minimum.x or rect.end.y<minimum.y:continue
		for p: Vector2 in samples:
			if rect.has_point(p):return false
	for index: int in range(_solids.size()):
		var bounds: Rect2=_solid_bounds[index]
		if bounds.position.x>maximum.x or bounds.position.y>maximum.y or bounds.end.x<minimum.x or bounds.end.y<minimum.y:continue
		var polygon: PackedVector2Array=_solids[index]
		for p: Vector2 in samples:
			if Geometry2D.is_point_in_polygon(p,polygon):return false
	return true

static func source_scene(version: int) -> SceneScript:
	if version==VERSION:return load(CANDIDATE_PATH) as SceneScript if ResourceLoader.exists(CANDIDATE_PATH) else null
	if version in [12,13,14,15]:return V15.source_scene(version)
	return null

static func _portal(scene: SceneScript,id: String) -> Dictionary:
	for p: Dictionary in scene.map_layout.portals:
		if String(p.get("id",""))==id:return p
	return {}

static func migrate_spawn(point: Vector2, from_version: int, target: SceneScript) -> Variant:
	_migration_debug={"from_version":from_version,"reason":"rejected","source_point":point}
	if not point.is_finite() or not is_v16(target):return null
	if from_version==VERSION:
		# Current-space invalid coordinates do not authorize a historic gate warp.
		if safe_foot(target,point):_migration_debug.reason="current_space_exact";return point
		_migration_debug.reason="current_space_unsafe";return null
	if from_version not in [12,13,14,15]:return null
	if from_version!=15:
		var through: Variant=V15.migrate_spawn(point,from_version,V15.source_scene(15))
		if not through is Vector2:return null
		point=through
	var old:=V15.source_scene(15)
	if old==null or not V15.safe_foot(old,point):
		_migration_debug.reason="source15_not_legitimate";return null
	for id: Variant in _manifest.moved_portals:
		var previous:=_portal(old,String(id))
		var next:=_portal(target,String(id))
		if previous.is_empty() or next.is_empty():return null
		if ((point-Vector2(previous.pos))*SIZE).length()<=64:
			var foot: Vector2=next.get("source_spawn_pos",next.pos)
			if safe_foot(target,foot):_migration_debug.merge({"reason":"same_moved_portal_id","portal_id":id},true);return foot
	if safe_foot(target,point):_migration_debug.reason="source15_exact_preserved";return point
	var matches: Array[Dictionary]=[]
	for region: Dictionary in _manifest.migration_regions:
		if region.has("source_x_range"):
			var interval:=_pair(region.source_x_range)
			if point.x*SIZE.x<interval.x or point.x*SIZE.x>=interval.y:continue
		if Geometry2D.is_point_in_polygon(point*SIZE,_polygon(region.source_polygon_px)):matches.append(region)
	if matches.size()!=1:_migration_debug.reason="historic_domain_missing_or_ambiguous";return null
	var row: Dictionary=matches[0]
	var portal:=_portal(target,String(row.historic_portal_id))
	if portal.is_empty():return null
	var foot: Vector2=portal.get("source_spawn_pos",portal.pos)
	if not safe_foot(target,foot):return null
	_migration_debug.merge({"reason":"declared_historic_domain_gate","region_id":row.id,"portal_id":row.historic_portal_id,"destination_point":foot},true)
	return foot

static func repair_spawn(scene: SceneScript,point: Vector2) -> Variant:
	return point if safe_foot(scene,point) else null

static func get_last_migration_debug() -> Dictionary:return _migration_debug.duplicate(true)
static func get_navigation_cache_debug() -> Dictionary:return {"tiles":_tiles.size(),"limit":NAV_TILE_CACHE_LIMIT,"error":_error,"coordinate_version":VERSION}
