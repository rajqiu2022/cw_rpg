extends SceneTree
## ROOT-only data/import audit. No Field, native Physics or visual-depth credit.
const A = preload("res://scripts/city/luoyang_assembled_rooms_20261016b.gd")
const RAW = preload("res://tests/helpers/v15_field_raw_oracle.gd")
const AUTHOR_SHA := "20986084094a7f233e1d096e8ae466f865d938d48909f7b9e59dc7f4030500c1"
const HELPER_SHA := "862a7b843201223d1d1b96c4b144076588a6a843e3945fd0c8442aec53e4bd5c"
const RAW_SHA := "dc36f4144496477508f9ad8b346f846043db109415760ab87205fa814aad26fb"
const SIZE := Vector2(1536,1024)
const WORLD := Vector2(1920,1280)
const BODY := Vector2(34,24)
const LIMIT_MS := 15000
const PERIMETER := [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]
var began := 0
var checks := 0
var failures := 0
var source_before: Dictionary={}
var players_before: Dictionary={}
var rows: Array[Dictionary]=[]
var floors: Array[PackedVector2Array]=[]
var solids: Array[PackedVector2Array]=[]
var npc_rects: Array[Rect2]=[]
var output := ""
func _initialize() -> void: call_deferred("_run")
func _check(ok: bool,label: String,detail: Variant=null) -> bool:
	checks+=1
	if not ok: failures+=1; printerr("ROOM_CPU_FAIL ",label," ",detail)
	return ok
func _fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false,"sha256":"ABSENT","bytes":0,"mtime_seconds":0}
	var file:=FileAccess.open(path,FileAccess.READ)
	var length:=file.get_length(); file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":length,"mtime_seconds":FileAccess.get_modified_time(path)}
func _pin(path: String,sha: String) -> bool:
	var actual:=_fact(path)
	if not _check(actual.exists and sha.length()==64 and actual.sha256==sha.to_lower(),"Exact source "+path): return false
	if source_before.has(path): return _check(source_before[path]==actual,"Previously pinned source still exact "+path)
	source_before[path]=actual
	return true
func _players() -> Dictionary:
	var result: Dictionary={}
	for index: int in range(5):
		for suffix: String in [".json",".json.bak",".json.tmp"]:
			var path:="user://save_"+str(index)+suffix
			result[path]=_fact(path)
	return result
func _v(pair: Array) -> Vector2: return Vector2(pair[0],pair[1])
func _poly(points: Array,scale: Vector2=Vector2.ONE) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for pair: Array in points: result.append(_v(pair)*scale)
	return result
func _norm_poly(points: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for pair: Array in points: result.append(Vector2(float(pair[0])/1536.0,float(pair[1])/1024.0))
	return result
func _point(point: Vector2,local_solids: Array) -> bool:
	var inside:=false
	for poly: PackedVector2Array in floors:
		if Geometry2D.is_point_in_polygon(point,poly): inside=true; break
	if not inside: return false
	for poly: PackedVector2Array in local_solids:
		if Geometry2D.is_point_in_polygon(point,poly): return false
	return true
func _body(foot: Vector2,skip_npc: int=-1) -> bool:
	var rect:=Rect2(foot-BODY*.5,BODY)
	var pixel:=Vector2(roundi(foot.x),roundi(foot.y))
	var domain:=rect.merge(Rect2(pixel-BODY*.5,BODY))
	var body:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var inside:=false
	for poly: PackedVector2Array in floors:
		if Geometry2D.clip_polygons(body,poly).is_empty(): inside=true; break
	if not inside: return false
	var nearby: Array[PackedVector2Array]=[]
	for poly: PackedVector2Array in solids:
		var bounds:=Rect2(poly[0],Vector2.ZERO)
		for p: Vector2 in poly: bounds=bounds.expand(p)
		if domain.intersects(bounds,true): nearby.append(poly)
		if rect.intersects(bounds,true) and not Geometry2D.intersect_polygons(body,poly).is_empty(): return false
	for index: int in npc_rects.size():
		if index!=skip_npc and rect.intersects(npc_rects[index],true): return false
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			if not _point(pixel+Vector2(x,y),nearby): return false
	for offset: Vector2 in PERIMETER:
		if not _point(foot+offset,nearby): return false
	return true
func _storage(a: Variant,b: Variant) -> bool:
	if typeof(a)!=typeof(b): return false
	if a==null or b==null: return a==b
	if a is Script: return a.resource_path==b.resource_path
	if a is Resource:
		if a.get_script()!=b.get_script(): return false
		for property: Dictionary in a.get_property_list():
			if int(property.usage)&PROPERTY_USAGE_STORAGE and property.name not in ["resource_path","resource_name"]:
				if not _storage(a.get(property.name),b.get(property.name)): return false
		return true
	if a is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _storage(a[key],b[key]): return false
		return true
	if a is Array:
		if a.size()!=b.size(): return false
		for index: int in a.size():
			if not _storage(a[index],b[index]): return false
		return true
	return a==b
func _imports(data: Dictionary) -> void:
	var approval: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(data.import_approval.path))
	_check(approval.status=="ROOT_APPROVED_NEW_IMPORTS_ONLY_NOT_RUNTIME" and approval.expected_rows==7 and approval.all_full_rgba_exact and approval.all_strict_params23,"Exact actual seven-import approval")
	var report: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(approval.report_path))
	_check(report.get("passed")==true and report.get("rows",[]).size()==7 and report.get("failures",[]).is_empty(),"Exact ROOT actual native import result")
	for item: Dictionary in approval.rows:
		var path: String=item.source
		var raw_path:=ProjectSettings.globalize_path("res://").trim_suffix("/").trim_suffix("\\").get_base_dir().path_join("assets/raw/luoyang_assembled_20261016b/"+path.get_file())
		_pin(raw_path,item.source_sha256)
		var original:=Image.load_from_file(raw_path)
		var actual:=ResourceLoader.load(path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var image: Image=actual.get_image() if actual!=null else null
		var direct:=CompressedTexture2D.new()
		var loaded:=direct.load(item.compiled)
		var compiled: Image=direct.get_image() if loaded==OK else null
		if original!=null: original.convert(Image.FORMAT_RGBA8)
		if image!=null: image.convert(Image.FORMAT_RGBA8)
		if compiled!=null: compiled.convert(Image.FORMAT_RGBA8)
		_check(original!=null and image!=null and compiled!=null and original.get_size()==Vector2i(SIZE) and image.get_size()==original.get_size() and compiled.get_size()==original.get_size() and image.get_mipmap_count()==0 and compiled.get_mipmap_count()==0 and original.get_data()==image.get_data() and original.get_data()==compiled.get_data(),"Actual original/native-import/directctex fullRGBA exact "+path)
		var config:=ConfigFile.new()
		_check(config.load(item["import"])==OK and config.get_value("deps","source_file")==path and config.get_value("remap","path")==item.compiled and config.get_section_keys("params").size()==23,"Exact source/import/native compiled binding "+path)
		rows.append({"kind":"ACTUAL_IMPORT_RGBA","path":path,"compiled":item.compiled,"source_sha":item.source_sha256,"actual_mips":image.get_mipmap_count() if image!=null else -1})
func _audit(data: Dictionary) -> void:
	var scene:=ResourceLoader.load(data.room.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(data.room.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not _check(scene!=null and layout!=null,"New independent room resources load"): return
	var geometry: Dictionary=data.geometry
	_check(scene.actor_positions_are_feet and scene.is_walkable and scene.is_settlement and scene.scene_id==A.ROOM and scene.background_path==data.shell.texture and data.shell.contains_furniture==false and scene.scene_objects.is_empty() and layout.visual_objects.size()==6 and layout.blockers.size()==6,"Empty-shell identity plus six separate visuals; ART supplies semantic empty-floor evidence")
	_check(scene.map_layout.resource_path==data.room.layout_path and scene.player_spawn==_v(geometry.spawn_foot_px)/SIZE and layout.design_size==Vector2i(SIZE) and layout.fill_viewport and layout.display_at_native_size and SIZE*maxf(1920.0/SIZE.x,1080.0/SIZE.y)==WORLD,"Ground feet spawn with no minus42; independent cover=1920x1280")
	_check(_v(data.room.native_body_px)==BODY and _v(data.room.native_collision_child_offset_px)==Vector2.ZERO,"New native body34x24/offset0 declaration")
	var player_scene:=load("res://scenes/player.tscn") as PackedScene
	var player: Node=player_scene.instantiate()
	player.call("set_ground_anchored",true)
	var shape:=player.get_node("CollisionShape2D") as CollisionShape2D
	_check(not player.is_inside_tree() and shape.shape is RectangleShape2D and (shape.shape as RectangleShape2D).size==BODY and shape.position==Vector2.ZERO,"Off-tree native Player resource grounding only, NOT Field/Physics credit")
	player.free()
	_check(layout.walkable_regions.size()==geometry.floor_regions_px.size(),"Exact floor count")
	for index: int in geometry.floor_regions_px.size():
		_check(layout.walkable_regions[index]==_norm_poly(geometry.floor_regions_px[index]),"Exact normalized floor "+str(index))
		floors.append(_poly(geometry.floor_regions_px[index],WORLD/SIZE))
	for index: int in data.furniture.size():
		var prop: Dictionary=data.furniture[index]
		var visual: Dictionary=layout.visual_objects[index]
		var blocker: Dictionary=layout.blockers[index]
		var base: Dictionary=geometry.furniture_bases[index]
		var ratio: float=prop.render_scale
		var expected_pos:=Vector2((float(prop.placement_foot_px[0])-float(prop.source_ground_anchor_px[0])*ratio)/1536.0,(float(prop.placement_foot_px[1])-float(prop.source_ground_anchor_px[1])*ratio)/1024.0)
		_check(prop.id==visual.id and prop.id==blocker.id and prop.id==base.id and visual.texture==prop.texture and not visual.centered and visual.assembled_furniture and visual.sort_by_feet and visual.pos==expected_pos and visual.render_size_px==Vector2(float(prop.source_size_px[0])*ratio,float(prop.source_size_px[1])*ratio) and visual.depth_sort_foot_y==float(prop.depth_foot_y)/1024.0,"Exact independent visual source/anchor/render/depth "+String(prop.id))
		_check(base.blocking and blocker.walkability_margin==0.0 and blocker.ground_polygon==_norm_poly(base.ground_polygon_px) and prop.room_ground_solid_polygons_px[0]==base.ground_polygon_px,"Exact ground hull separate from tall visual "+String(prop.id))
		solids.append(_poly(base.ground_polygon_px,WORLD/SIZE))
	var empty_blockers: Array[Dictionary]=[]
	var declarations: Array[Dictionary]=[]
	for index: int in solids.size(): declarations.append({"id":geometry.furniture_bases[index].id,"solid_polygons_px":[solids[index]]})
	var clone: Resource=layout.duplicate(true)
	clone.set("design_size",Vector2i(WORLD)); clone.set("blockers",empty_blockers); clone.set("visual_objects",declarations)
	var oracle:=RAW.new()
	_check(oracle.configure(clone,"normalized_image_round",0.0) and clone.get("blockers").is_empty() and layout.blockers.size()==6 and oracle.regions.size()==floors.size() and oracle.solids.size()==6,"Typed oracle clone clears only duplicate blockers, exact floors/solids remain",oracle.errors)
	var source_npc: Dictionary=scene.npcs[0]
	var npc_texture:=ResourceLoader.load(source_npc.sprite_path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var frames:=maxi(1,npc_texture.get_width()/npc_texture.get_height())
	var npc_size:=Vector2(float(npc_texture.get_width())/frames*.14,npc_texture.get_height()*.18)*float(source_npc.scale)*scene.npc_visual_scale
	for slot: Dictionary in geometry.npc_slots:
		var foot:=_v(slot.foot_px)*WORLD/SIZE
		npc_rects.append(Rect2(foot-npc_size*.5,npc_size))
	_check(scene.npcs.size()==1 and source_npc.source_foot_px==Vector2(663,448) and _body(Vector2(663,448)*WORLD/SIZE,0) and _body(Vector2(663,505)*WORLD/SIZE),"NPC authored sourcefoot/self-only exclusion and no-exclusion approach, data-only")
	var compiled: Dictionary=A.compile_geometry(geometry,WORLD)
	_check(geometry.required_routes.size()==9 and geometry.validation_stations.size()==3,"Exactly nine full routes and three visual stations")
	for route: Dictionary in geometry.required_routes:
		var samples:=0; var clear:=true
		var points: Array=route.feet_points_px
		for index: int in range(points.size()-1):
			var from:=_v(points[index])*WORLD/SIZE; var to:=_v(points[index+1])*WORLD/SIZE
			var steps:=maxi(1,ceili(from.distance_to(to)/4.0))
			for step: int in range(steps+1):
				if Time.get_ticks_msec()-began>LIMIT_MS: clear=false; break
				var foot:=from.lerp(to,float(step)/steps)
				samples+=1
				if not _body(foot) or not oracle.clear(foot) or not A.safe_foot(compiled,foot,WORLD,false): clear=false; break
			if not clear: break
		_check(clear,"Complete continuous+round875+17 <=4worldpx route "+String(route.id))
		rows.append({"kind":"COMPLETE_FEET_ROUTE","id":route.id,"samples":samples,"clear":clear,"body":BODY,"offset":Vector2.ZERO,"max_step_world_px":4})
	for station: Dictionary in geometry.validation_stations: _check(_body(_v(station.foot_px)*WORLD/SIZE),"Full body station "+String(station.id))
	_check(_v(geometry.validation_stations[0].foot_px)==Vector2(425,672) and _v(geometry.validation_stations[1].foot_px)==Vector2(425,606) and _v(geometry.validation_stations[2].foot_px)==Vector2(482,640),"Exact front/behind/tie station coordinates")
	_check(geometry.negative_points.size()==1 and _v(geometry.negative_points[0].foot_px)==Vector2(425,633) and not _body(Vector2(425,633)*WORLD/SIZE) and not A.safe_foot(compiled,Vector2(425,633)*WORLD/SIZE,WORLD,true),"Anvil real ground center refuses complete player body")
	_check(layout.portals.size()==1 and layout.portals[0].pos==Vector2(768,885)/SIZE and layout.portals[0].target_pos==_v(data.room.return_foot_px)/Vector2(3072,2048),"Exact feet-domain exit and original exterior return marker")
	var serialized:=output.path_join("room_roundtrip.tres")
	if _check(ResourceSaver.save(scene.duplicate(true),serialized)==OK,"Own serialized scene copy saved"):
		var reloaded:=ResourceLoader.load(serialized,"",ResourceLoader.CACHE_MODE_IGNORE)
		_check(reloaded!=null and _storage(scene,reloaded),"All Scene/layout/NPC/visual storage fields roundtrip exact")
	oracle.release()
func _run() -> void:
	began=Time.get_ticks_msec()
	var bridge: Node=root.get_node("PlatformBridge")
	bridge.call("set_checkpoint_saves_suspended",true)
	players_before=_players()
	output="res://build/luoyang_assembled_room_cpu_20261016b/%d_%d"%[OS.get_process_id(),began]
	DirAccess.make_dir_recursive_absolute(output)
	if _pin(A.SELF_PATH,HELPER_SHA) and _pin(A.AUTHOR_PATH,AUTHOR_SHA) and _pin("res://tests/helpers/v15_field_raw_oracle.gd",RAW_SHA):
		var data:=A.author()
		if _check(not data.is_empty() and data.source_sha256.size()==37,"Frozen one-room author37 closure"):
			for path: String in data.source_sha256: _pin(path,data.source_sha256[path])
			source_before[get_script().resource_path]=_fact(get_script().resource_path)
			if failures==0: _imports(data); _audit(data)
	var after: Dictionary={}
	for path: String in source_before: after[path]=_fact(path)
	var players_after:=_players()
	_check(after==source_before and players_after==players_before and bridge.call("is_checkpoint_saves_suspended")==true,"Complete exact source closure and15saves held")
	_check(Time.get_ticks_msec()-began<=LIMIT_MS,"Shared15sec, no extended guard or old-room replay")
	var file:=FileAccess.open(output.path_join("result.json"),FileAccess.WRITE)
	if file!=null:
		file.store_string(JSON.stringify({"scope":"NEW_ASSEMBLED_ROOM_DATA_IMPORT_GEOMETRY_ONLY","complete":true,"passed":failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"budget_ms":LIMIT_MS,"records":rows,"source_before":source_before,"source_after":after,"players_before":players_before,"players_after":players_after,"Field_Physics_depth_alpha_visual_or_external_city_credit":false,"empty_shell_semantics_remain_ART_visual_review":true},"\t")); file.close()
	else: failures+=1
	print("ASSEMBLED_ROOM_CPU=",output,"/result.json checks=",checks," failures=",failures)
	quit(0 if failures==0 else 1)
