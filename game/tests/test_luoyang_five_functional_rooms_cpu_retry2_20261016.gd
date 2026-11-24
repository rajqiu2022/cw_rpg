extends SceneTree
## NEW retry2: exact real save names and world-pixel875 center; 912 draft preserved.
## ROOT-only bounded CPU/import/source audit. No Field, Physics or exterior-door credit.
## Full source-raster geometry is independently projected to the native cover world.
const SOURCE_READY := true
const REGISTRY := "res://data/maps/luoyang_functional_interiors_20261016/registry.json"
const REGISTRY_SHA := "da704adefa51d4c523e92eea9faae6e1d0a257dc3fc0b4789427300503709eba"
const ADAPTER := "res://scripts/city/luoyang_functional_interiors_20261016.gd"
const ADAPTER_SHA := "8c240e2e9dea961e2573813a1b127d1a8e88b7dad0e812033ea675481eafe611"
const FIELD := "res://scripts/field/field_walkable_controller.gd"
const FIELD_SHA := "b472320b3af47a904f3f43254219bbd5330e98f94f9ba886b1a9474018a9c356"
const OTHER_HOOK_PINS := {
	"res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd":"887a9d060cc7a1d57af9c2ab7f62af4d7b6cacd8937c69e5baa609fefeeedd29",
	"res://scripts/autoload/scene_router.gd":"1877df7c4544275e66241552cee63e00f69d84a4c38bf5166976a4e401b2c1e1",
	"res://scripts/city/luoyang_resident_field_20261016.gd":"cd5d3485d7f639b447010df9e88cc6347242a2a2fe491a873fa2e46d6ff55b86"
}
const RAW_MANIFEST := "assets/raw/luoyang_city_expansion_20261016/production_author_v2/manifest.json"
const RAW_MANIFEST_SHA := "c06ae77834546daf25a0d9946eb08386942f383bb3d1852022e0928840f33f14"
const SOURCE_SIZE := Vector2(1536,1024)
const VIEWPORT := Vector2(1920,1080)
const WORLD := Vector2(1920,1280)
const OFFSET := Vector2(0,42)
const BODY := Vector2(34,24)
const TYPES := ["smithy","cloth_shop","warehouse","pawnshop","mansion_reception"]
const LIMIT_MS := 60000
const PERIMETER := [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]
var failures := 0
var checks := 0
var began := 0
var rows: Array[Dictionary] = []
var sources: Dictionary = {}
var saves: Dictionary = {}
var output := ""
var helper: Script

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String,detail: Variant=null) -> bool:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL ",label," ",detail)
	return ok

func _fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false,"sha256":"","bytes":0,"mtime_seconds":0}
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size(),"mtime_seconds":FileAccess.get_modified_time(path)}

func _track(path: String,sha: String) -> bool:
	var fact:=_fact(path)
	if not _check(fact.exists and sha.length()==64 and fact.sha256==sha.to_lower(),"Exact source "+path,fact): return false
	if sources.has(path): return _check(sources[path]==fact,"Same source throughout "+path)
	sources[path]=fact
	return true

func _repo(path: String) -> String:
	return ProjectSettings.globalize_path("res://").trim_suffix("/").trim_suffix("\\").get_base_dir().path_join(path)

func _json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(value is Dictionary,"Dictionary JSON "+path)
	return value if value is Dictionary else {}

func _v(value: Variant) -> Vector2:
	return Vector2(value[0],value[1])

func _poly(value: Array,scale: Vector2=Vector2.ONE) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point: Variant in value: result.append(_v(point)*scale)
	return result

func _normalized_poly(value: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point: Variant in value: result.append(Vector2(float(point[0])/1536.0,float(point[1])/1024.0))
	return result

func _bounds(poly: PackedVector2Array) -> Rect2:
	var rect:=Rect2(poly[0],Vector2.ZERO)
	for point: Vector2 in poly: rect=rect.expand(point)
	return rect

func _inside(point: Vector2,floors: Array,solids: Array) -> bool:
	var inside:=false
	for poly: PackedVector2Array in floors:
		if Geometry2D.is_point_in_polygon(point,poly): inside=true; break
	if not inside: return false
	for poly: PackedVector2Array in solids:
		if Geometry2D.is_point_in_polygon(point,poly): return false
	return true

func _body(foot: Vector2,floors: Array,solids: Array,npcs: Array,exclude_npc: int=-1) -> Dictionary:
	var rect:=Rect2(foot-BODY*.5,BODY)
	var local_solids: Array=[]
	for poly: PackedVector2Array in solids:
		if rect.intersects(_bounds(poly),true): local_solids.append(poly)
	for index: int in npcs.size():
		if index!=exclude_npc and rect.intersects(npcs[index],true): return {"ok":false,"reason":"npc_body","npc_index":index,"foot":foot}
	var body_poly:=PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	var enclosed:=false
	for floor: PackedVector2Array in floors:
		if Geometry2D.clip_polygons(body_poly,floor).is_empty(): enclosed=true; break
	if not enclosed: return {"ok":false,"reason":"continuous_floor","foot":foot}
	for poly: PackedVector2Array in local_solids:
		if not Geometry2D.intersect_polygons(body_poly,poly).is_empty(): return {"ok":false,"reason":"continuous_furniture","foot":foot}
	var pixel_center:=Vector2(roundi(foot.x),roundi(foot.y))
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			if not _inside(pixel_center+Vector2(x,y),floors,local_solids): return {"ok":false,"reason":"875_pixel","foot":foot,"offset":[x,y]}
	for offset: Vector2 in PERIMETER:
		if not _inside(foot+offset,floors,local_solids): return {"ok":false,"reason":"17_perimeter","foot":foot,"offset":offset}
	return {"ok":true}

func _route(points: Array,floors: Array,solids: Array,npcs: Array,compiled: Dictionary) -> Dictionary:
	var count:=0
	for segment: int in range(points.size()-1):
		var from:=_v(points[segment])*WORLD/SOURCE_SIZE
		var to:=_v(points[segment+1])*WORLD/SOURCE_SIZE
		var steps:=maxi(1,ceili(from.distance_to(to)/4.0))
		for step: int in range(steps+1):
			if Time.get_ticks_msec()-began>LIMIT_MS: return {"ok":false,"reason":"shared_cpu_deadline","samples":count}
			var foot:=from.lerp(to,float(step)/steps)
			var result:=_body(foot,floors,solids,npcs)
			count+=1
			if not result.ok: return {"ok":false,"reason":result,"samples":count}
			if not bool(helper.call("safe_origin",compiled,foot-OFFSET,WORLD,false)): return {"ok":false,"reason":"production_predicate_disagrees","foot":foot,"samples":count}
	return {"ok":true,"samples":count,"body_samples_per_position":875,"perimeter_samples_per_position":17,"max_world_step_px":4}

func _rgba(path: String) -> Image:
	var image:=Image.load_from_file(path)
	if image!=null and not image.is_empty(): image.convert(Image.FORMAT_RGBA8)
	return image

func _equal_storage(a: Variant,b: Variant) -> bool:
	if typeof(a)!=typeof(b): return false
	if a==null or b==null: return a==b
	if a is Script: return a.resource_path==b.resource_path
	if a is Resource:
		if a.get_script()!=b.get_script(): return false
		for property: Dictionary in a.get_property_list():
			if int(property.usage)&PROPERTY_USAGE_STORAGE and property.name not in ["resource_path","resource_name"]:
				if not _equal_storage(a.get(property.name),b.get(property.name)): return false
		return true
	if a is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equal_storage(a[key],b[key]): return false
		return true
	if a is Array:
		if a.size()!=b.size(): return false
		for index: int in a.size():
			if not _equal_storage(a[index],b[index]): return false
		return true
	return a==b

func _npc_rects(scene: SceneScript,author: Dictionary) -> Array:
	var result: Array=[]
	_check(scene.npcs.size()==author.npc_slots.size(),"Exact NPC slot count "+String(author.id))
	for index: int in scene.npcs.size():
		var npc: Dictionary=scene.npcs[index]
		var slot: Dictionary=author.npc_slots[index]
		var tex:=ResourceLoader.load(npc.sprite_path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		if not _check(tex!=null,"NPC texture "+String(npc.npc_id)): continue
		var scale: float=float(npc.scale)*scene.npc_visual_scale
		var frames:=maxi(1,tex.get_width()/tex.get_height()) if tex.get_width()>tex.get_height() else 1
		var native_size:=Vector2(float(tex.get_width())/frames*.14,tex.get_height()*.18)*scale
		var foot:=_v(slot.foot_px)*WORLD/SOURCE_SIZE
		_check(npc.source_foot_px==_v(slot.foot_px) and npc.pos==_v(slot.foot_px)/SOURCE_SIZE and npc.movement_mode=="idle","Exact NPC sourcefeet, no Player42 shift "+String(npc.npc_id))
		result.append(Rect2(foot-native_size*.5,native_size))
	return result

func _point_on_route(point: Vector2,routes: Array) -> bool:
	for route: Dictionary in routes:
		var points: Array=route.feet_points_px
		for index: int in range(points.size()-1):
			var a:=_v(points[index]); var delta:=_v(points[index+1])-a
			var relative:=point-a
			if delta.cross(relative)==0 and relative.dot(delta)>=0 and relative.dot(delta)<=delta.length_squared(): return true
	return false

func _room(id: String,item: Dictionary,raw: Dictionary) -> void:
	var name: String=item.type
	var scene:=ResourceLoader.load(item.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(item.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not _check(scene!=null and layout!=null,"Reload scene/layout "+name): return
	var author:=_json(item.author_path)
	for key: String in ["floor_regions_px","furniture_bases","spawn_foot_px","npc_slots","functional_points","required_routes"]:
		_check(author.get(key)==raw.get(key),"Unchanged ART v2 "+name+" "+key)
	_check(author.front_exit.approach_foot_px==raw.front_exit.approach_foot_px and author.front_exit.activation_polygon_px==raw.front_exit.activation_polygon_px,"Unchanged exit geometry "+name)
	_check(scene.scene_id==StringName(id) and scene.is_walkable and scene.is_settlement and not scene.actor_positions_are_feet and scene.player_spawn==_v(raw.spawn_foot_px)/SOURCE_SIZE and scene.map_layout.resource_path==item.layout_path,"Scene source-foot spawn contract "+name)
	_check(scene.hotspots.is_empty() and scene.trigger_zones.is_empty() and scene.on_enter_dialog==null and scene.encounter_enemy_ids.is_empty() and scene.encounter_chance==0,"No new automatic story/reward/encounter "+name)
	_check(layout.design_size==Vector2i(SOURCE_SIZE) and layout.fill_viewport and layout.display_at_native_size,"Exact cover input "+name)
	var cover:=maxf(VIEWPORT.x/SOURCE_SIZE.x,VIEWPORT.y/SOURCE_SIZE.y)
	_check(SOURCE_SIZE*cover==WORLD and BODY==Vector2(34,24) and OFFSET==Vector2(0,42),"Independent native cover/body/legacy offset "+name)
	var floors: Array=[]; var solids: Array=[]
	_check(layout.walkable_regions.size()==raw.floor_regions_px.size() and layout.blockers.size()==raw.furniture_bases.size(),"Full floor/furniture counts "+name)
	for index: int in raw.floor_regions_px.size():
		_check(layout.walkable_regions[index]==_normalized_poly(raw.floor_regions_px[index]),"Exact normalized floor "+name+str(index))
		floors.append(_poly(raw.floor_regions_px[index],WORLD/SOURCE_SIZE))
	for index: int in raw.furniture_bases.size():
		var base: Dictionary=raw.furniture_bases[index]
		var blocker: Dictionary=layout.blockers[index]
		_check(base.blocking==true and blocker.id==base.id and blocker.ground_polygon==_normalized_poly(base.ground_polygon_px) and blocker.walkability_margin==0.0,"Exact furniture polygon, not AABB "+name+"/"+String(base.id))
		var solid:=_poly(base.ground_polygon_px,WORLD/SOURCE_SIZE)
		solids.append(solid)
		var center:=Vector2.ZERO
		for point: Vector2 in solid: center+=point
		center/=solid.size()
		_check(not _body(center,floors,solids,[]).ok and Geometry2D.is_point_in_polygon(center,solid),"Source furniture centroid unwalkable (floor or base) "+name+"/"+String(base.id))
	var npcs:=_npc_rects(scene,raw)
	for index: int in raw.npc_slots.size():
		var slot: Dictionary=raw.npc_slots[index]
		_check(_body(_v(slot.foot_px)*WORLD/SOURCE_SIZE,floors,solids,npcs,index).ok,"NPC own-body exclusion only at own groundfoot "+name)
		_check(_body(_v(slot.approach_foot_px)*WORLD/SOURCE_SIZE,floors,solids,npcs).ok,"NPC approach full body, no exclusion "+name)
	var compiled: Dictionary=helper.call("compile_geometry",author,WORLD)
	for point: Dictionary in raw.functional_points:
		_check(_point_on_route(_v(point.foot_px),raw.required_routes) and _body(_v(point.foot_px)*WORLD/SOURCE_SIZE,floors,solids,npcs).ok,"Every function point is on an authored proven route, full body "+name+"/"+String(point.id))
	var route_rows: Array=[]
	var exit_points: Array=[]
	for route: Dictionary in raw.required_routes:
		if route.id=="to_exit": exit_points=route.feet_points_px
	_check(exit_points.size()>=2 and _v(exit_points.back())==Vector2(768,885),"Exact front exit point "+name)
	for route: Dictionary in raw.required_routes:
		var points: Array=route.feet_points_px.duplicate(true)
		_check(_v(points.front())==_v(raw.spawn_foot_px),"Route begins at authored spawn "+name+"/"+String(route.id))
		var receipt:=_route(points,floors,solids,npcs,compiled)
		_check(receipt.ok,"Independent <=4px full875+17 route "+name+"/"+String(route.id),receipt)
		route_rows.append({"id":route.id,"receipt":receipt})
		# Reverse the exact same proven path, then exact spawn-to-exit path; no shortcut.
		points.reverse(); points.append_array(exit_points.slice(1))
		var back:=_route(points,floors,solids,npcs,compiled)
		_check(back.ok,"Functional point to original exit via same path "+name+"/"+String(route.id),back)
	for slot: Dictionary in raw.npc_slots:
		var npc_route:=_route(slot.route_from_spawn_feet_px,floors,solids,npcs,compiled)
		_check(npc_route.ok,"NPC approach route <=4px full875+17 "+name,npc_route)
		var points: Array=slot.route_from_spawn_feet_px.duplicate(true)
		points.reverse(); points.append_array(exit_points.slice(1))
		_check(_route(points,floors,solids,npcs,compiled).ok,"NPC approach back to exit "+name)
	var exit_foot:=_v(raw.front_exit.approach_foot_px)*WORLD/SOURCE_SIZE
	var exit_origin:=exit_foot-OFFSET
	_check(helper.call("origin_uv",_v(raw.spawn_foot_px),WORLD)==_v(raw.spawn_foot_px)/SOURCE_SIZE-OFFSET/WORLD,"Player +42 conversion once "+name)
	_check(Geometry2D.is_point_in_polygon(exit_foot,_poly(raw.front_exit.activation_polygon_px,WORLD/SOURCE_SIZE)) and exit_origin+OFFSET==exit_foot,"Visible-foot exit activation (not body origin) "+name)
	_check(layout.portals.size()==(1 if item.city_id!="" else 0),"No invented exterior exit "+name)
	if not layout.portals.is_empty():
		var portal: Dictionary=layout.portals[0]
		_check(portal.pos==Vector2(768,885)/SOURCE_SIZE and portal.size==Vector2(110,30)/SOURCE_SIZE and portal.target_scene==item.city_id and portal.target_pos==_v(item.return_foot_px)/Vector2(3072,2048) and not portal.auto_trigger,"Exact original exterior owner and return-foot data "+name)
	var original_png:=_repo(raw.source_image)
	_check(_track(original_png,raw.source_sha256) and _track(scene.background_path,raw.source_sha256),"Original PNG byte identity "+name)
	var source:=_rgba(original_png)
	var texture:=ResourceLoader.load(scene.background_path,"Texture2D",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var imported: Image=texture.get_image() if texture!=null else null
	if imported!=null: imported.convert(Image.FORMAT_RGBA8)
	_check(source!=null and imported!=null and source.get_size()==Vector2i(SOURCE_SIZE) and imported.get_size()==source.get_size() and source.get_mipmap_count()==0 and imported.get_mipmap_count()==0 and source.get_data()==imported.get_data(),"Actual ResourceLoader fullRGBA exact/no-mip "+name)
	var import_cfg:=ConfigFile.new()
	if _check(import_cfg.load(scene.background_path+".import")==OK,"Native .import exists "+name):
		var compiled_path: String=import_cfg.get_value("remap","path","")
		_check(sources.has(scene.background_path+".import") and sources.has(compiled_path),"Import and compiled exact pins included before decode "+name)
		var direct:=CompressedTexture2D.new()
		if _check(direct.load(compiled_path)==OK,"Direct compiled texture loads "+name):
			var direct_image:=direct.get_image(); direct_image.convert(Image.FORMAT_RGBA8)
			_check(direct_image.get_data()==source.get_data() and direct_image.get_size()==source.get_size() and direct_image.get_mipmap_count()==0,"Direct compiled fullRGBA exact "+name)
		_check(import_cfg.get_value("deps","source_file")==scene.background_path and import_cfg.get_value("params","compress/mode")==0 and import_cfg.get_value("params","mipmaps/generate")==false and import_cfg.get_value("params","process/fix_alpha_border")==false and import_cfg.get_value("params","detect_3d/compress_to")==0,"Exact source/deps and non-mutating import policy "+name)
	var serialized:=output.path_join(name+"_roundtrip.tres")
	var copy: Resource=scene.duplicate(true)
	if _check(ResourceSaver.save(copy,serialized)==OK,"Save QA-only serialized roundtrip "+name):
		var reloaded:=ResourceLoader.load(serialized,"",ResourceLoader.CACHE_MODE_IGNORE)
		_check(reloaded!=null and _equal_storage(scene,reloaded),"All storage fields survive serialization "+name)
	rows.append({"type":name,"scene_id":id,"world_size":WORLD,"native_body":BODY,"legacy_offset":OFFSET,"furniture_count":solids.size(),"npc_count":npcs.size(),"routes":route_rows,"door_enabled":item.door_enabled,"native_physics_tested":false,"external_door_tested":false})

func _run() -> void:
	began=Time.get_ticks_msec()
	var platform:=root.get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	for index: int in range(5):
		for suffix: String in [".json",".json.bak",".json.tmp"]:
			var path:="user://save_"+str(index)+suffix
			saves[path]=_fact(path)
	output="res://build/luoyang_five_functional_rooms_cpu_20261016/"+str(OS.get_process_id())+"_"+str(began)
	DirAccess.make_dir_recursive_absolute(output)
	if _check(SOURCE_READY,"Frozen source readiness, no PENDING execution") and _track(REGISTRY,REGISTRY_SHA) and _track(ADAPTER,ADAPTER_SHA) and _track(FIELD,FIELD_SHA) and _track(_repo(RAW_MANIFEST),RAW_MANIFEST_SHA):
		var config:=_json(REGISTRY)
		var manifest:=_json(_repo(RAW_MANIFEST))
		helper=load(ADAPTER) as Script
		for path: String in OTHER_HOOK_PINS: _track(path,OTHER_HOOK_PINS[path])
		_check(config.rooms.size()==5 and config.coordinate_contract=="20261016_sourcefeet_legacy42" and _v(config.native_player_body)==BODY and _v(config.native_player_collision_offset)==OFFSET,"Exact five-room registry contract")
		for path: String in config.source_sha256: _track(path,config.source_sha256[path])
		var approval: Dictionary=config.get("import_approval",{})
		_check(not approval.is_empty(),"ROOT actual five-import approval required")
		if not approval.is_empty(): _track(approval.path,approval.sha256)
		if not approval.is_empty():
			var approval_data:=_json(approval.path)
			_check(approval_data.get("status")=="ROOT_APPROVED_EXACT_FIVE_TEXTURE_IMPORT_COPY_NOT_ROOM_RUNTIME_APPROVAL" and approval_data.get("rows",[]).size()==5,"Actual independent ROOT import approval, not room credit")
			_track(approval_data.report_path,approval_data.report_sha256)
			_track(approval_data.verifier_path,approval_data.verifier_sha256)
			var import_report:=_json(approval_data.report_path)
			_check(import_report.get("passed")==true and import_report.get("failures",[]).is_empty() and import_report.get("rows",[]).size()==5,"Exact existing natural import result")
			for atom: Dictionary in approval_data.rows:
				_check(atom.full_rgba_exact and atom.params23,"ROOT import row admitted only with fullRGBA and23params "+String(atom.source))
				_track(atom.source,atom.source_sha256); _track(atom["import"],atom.import_sha256); _track(atom.compiled,atom.compiled_sha256)
		if failures==0:
			for name: String in TYPES:
				for id: String in config.rooms:
					var item: Dictionary=config.rooms[id]
					if item.type!=name: continue
					var raw_name:="interior_"+name+"_v1.json"
					for atom: Dictionary in manifest.files:
						if String(atom.path).get_file()!=raw_name: continue
						if _track(_repo(atom.path),atom.sha256): _room(id,item,_json(_repo(atom.path)))
					_check(item.door_enabled==(name in ["smithy","cloth_shop"]),"Only two matched exterior doors enabled "+name)
		_check(rows.size()==5,"Five distinct actual backgrounds/rooms audited")
	var after: Dictionary={}
	for path: String in sources:
		after[path]=_fact(path)
		_check(after[path]==sources[path],"Source SHA/bytes/mtime unchanged "+path)
	var players_after: Dictionary={}
	for path: String in saves:
		players_after[path]=_fact(path)
		_check(players_after[path]==saves[path],"Player save untouched "+path)
	_check(Time.get_ticks_msec()-began<=LIMIT_MS,"Finite CPU shared60s")
	var result:={"scope":"FIVE_SOURCE_GEOMETRY_AND_ACTUAL_IMPORT_CPU_ONLY_NOT_PHYSICS_OR_DOOR_GPU","complete":true,"passed":failures==0,"failures":failures,"checks":checks,"elapsed_ms":Time.get_ticks_msec()-began,"rooms":rows,"source_before":sources,"source_after":after,"players_before":saves,"players_after":players_after,"engine_physics_tested":false,"external_doors_tested":false}
	var file:=FileAccess.open(output.path_join("result.json"),FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(result,"\t")); file.close()
	else: failures+=1; printerr("FAIL unable to write own bounded CPU result")
	print("FIVE_ROOM_CPU result=",output," checks=",checks," failures=",failures)
	helper=null
	quit(0 if failures==0 else 1)

