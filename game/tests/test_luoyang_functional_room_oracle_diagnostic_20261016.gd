extends SceneTree
## ROOT-only bounded CPU diagnosis, exact retry2 binder clone; no Field or PNG IO.
const RAW = preload("res://tests/helpers/v15_field_raw_oracle.gd")
const REGISTRY := "res://data/maps/luoyang_functional_interiors_20261016/registry.json"
const REGISTRY_SHA := "da704adefa51d4c523e92eea9faae6e1d0a257dc3fc0b4789427300503709eba"
const WORLD := Vector2(1920,1280)
var rows: Array[Dictionary]=[]
var errors: Array[String]=[]
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var began:=Time.get_ticks_msec()
	var platform:=root.get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	if FileAccess.get_sha256(REGISTRY)!=REGISTRY_SHA: errors.append("registry source drift")
	var config: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(REGISTRY))
	for id: String in config.rooms:
		var item: Dictionary=config.rooms[id]
		var scene:=ResourceLoader.load(item.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var original_layout:=ResourceLoader.load(item.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if scene==null or original_layout==null: errors.append("resource missing "+id); continue
		var author: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(item.author_path))
		var source: Resource=scene.map_layout
		var clone: Resource=source.duplicate(true)
		clone.set("design_size",Vector2i(WORLD)); clone.set("blockers",[])
		var declarations: Array[Dictionary]=[]
		var polygons: Array=[]
		for base: Dictionary in author.furniture_bases:
			var poly:=PackedVector2Array()
			for pair: Array in base.ground_polygon_px: poly.append(Vector2(pair[0],pair[1])*WORLD/Vector2(1536,1024))
			declarations.append({"id":base.id,"solid_polygons_px":[poly]})
			var bounded:=true
			for point: Vector2 in poly: bounded=bounded and point.is_finite() and point.x>=0 and point.y>=0 and point.x<=WORLD.x and point.y<=WORLD.y
			polygons.append({"id":base.id,"count":poly.size(),"triangulation":Geometry2D.triangulate_polygon(poly),"in_world_domain":bounded})
		clone.set("visual_objects",declarations)
		var floors: Array=[]
		for polygon: PackedVector2Array in clone.get("walkable_regions"):
			var normalized:=true
			for point: Vector2 in polygon: normalized=normalized and point.is_finite() and point.x>=0 and point.y>=0 and point.x<=1 and point.y<=1
			floors.append({"count":polygon.size(),"triangulation":Geometry2D.triangulate_polygon(polygon),"normalized":normalized,"polygon":polygon})
		var oracle:=RAW.new()
		var accepted: bool=oracle.configure(clone,"normalized_image_round",0.0)
		var row: Dictionary={"id":id,"scene_path":scene.resource_path,"scene_layout_path":source.resource_path,"explicit_reload_layout_path":original_layout.resource_path,"source_design_size":source.get("design_size"),"clone_design_size":clone.get("design_size"),"clone_blockers":clone.get("blockers"),"clone_visual_objects":clone.get("visual_objects"),"mask_path":clone.get("walkable_mask_path"),"mask_tiles":clone.get("walkable_mask_tiles"),"floor_triangles":floors,"solid_triangles":polygons,"accepted":accepted,"oracle_errors":oracle.errors.duplicate(),"oracle_size":oracle.size,"region_count":oracle.regions.size(),"solid_count":oracle.solids.size(),"source_sha256":FileAccess.get_sha256(item.layout_path),"expected_layout_sha256":config.source_sha256[item.layout_path]}
		rows.append(row)
		print(JSON.stringify(row))
		if not accepted: errors.append(id+": "+str(oracle.errors))
		oracle.release()
	if Time.get_ticks_msec()-began>30000: errors.append("diagnosis shared30s exceeded")
	var output:="res://build/luoyang_functional_room_oracle_diagnostic_20261016/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	var file:=FileAccess.open(output.path_join("result.json"),FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"scope":"CPU_EXACT_RETRY2_BIND_CLONE_DIAGNOSIS_NO_FIELD","rows":rows,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"registry_sha256":FileAccess.get_sha256(REGISTRY)},"\t")); file.close()
	else: errors.append("own output unavailable")
	print("ROOM_ORACLE_DIAG=",output,"/result.json")
	quit(0 if errors.is_empty() else 1)
