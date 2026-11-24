extends SceneTree
## One content batch, reusing the passed Market80492 append/raster/inverse path.
## Original Scene/Layout/NPC/portal/task fields are never rewritten.
const READY: bool=false
const INPUT: String="res://build/luoyang_seven_fields_layout_20261026c_system01/input_NOTREADY.json"
const INPUT_SHA: String="PENDING_FINAL_ART_AUTHOR"
const PREFIX: String="res://build/luoyang_seven_fields_layout_20261026c_system01/"
const GAME_ROOT: String="F:/Code/RPG_GAME/game/"
const IDS: Array[String]=["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen","ch4_s2_canal_docks","ch4_s4_ancient_temple","luoyang_estate_riverside_20261021ai","luoyang_artisan_residential_20261022ap","luoyang_riverside_garden_20261022ap"]
const MARKET: String="ch4_s3_luoyang_market"
var errors: Array[String]=[]
var checks: int=0
func _initialize() -> void: call_deferred("run")
func physical(path: String) -> String: return GAME_ROOT+path.trim_prefix("res://") if path.begins_with("res://") else path
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label);printerr("SEVEN_LAYOUT ",label)
	return ok
func vec(a: Array) -> Vector2: return Vector2(float(a[0]),float(a[1]))
func sha(bytes: PackedByteArray) -> String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(bytes);return h.finish().hex_encode()
func read_json(path: String) -> Dictionary:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(physical(path)));return raw if raw is Dictionary else {}
func write_new(path: String,bytes: PackedByteArray) -> Dictionary:
	if not check(path.begins_with(PREFIX) and not FileAccess.file_exists(physical(path)),"NEW_BUILD_OUTPUT:"+path): return {}
	var file:=FileAccess.open(physical(path),FileAccess.WRITE)
	if not check(file!=null,"OUTPUT_OPEN"): return {}
	file.store_buffer(bytes);file.close();return {"path":path,"sha256":sha(bytes),"bytes":bytes.size()}
func body(foot: Vector2,half: Vector2) -> PackedVector2Array:
	return PackedVector2Array([foot-half,foot+Vector2(half.x,-half.y),foot+half,foot+Vector2(-half.x,half.y)])
func clear(foot: Vector2,half: Vector2,world: Vector2,mask: Image,solids: Array,floors: Array) -> bool:
	if foot.x<half.x or foot.y<half.y or foot.x+half.x>=world.x or foot.y+half.y>=world.y: return false
	var box: PackedVector2Array=body(foot,half)
	for polygon: PackedVector2Array in solids:
		if not Geometry2D.intersect_polygons(box,polygon).is_empty(): return false
	if mask==null:
		for floor_polygon: PackedVector2Array in floors:
			var inside: bool=true
			for point: Vector2 in box:
				if not Geometry2D.is_point_in_polygon(point,floor_polygon): inside=false;break
			if inside: return true
		return false
	for y: int in range(floori(foot.y-half.y),ceili(foot.y+half.y)+1):
		for x: int in range(floori(foot.x-half.x),ceili(foot.x+half.x)+1):
			if mask.get_pixel(x,y).r<0.5: return false
	return true
func fingerprints(payload: Dictionary) -> Dictionary:
	var out: Dictionary={}
	for key: String in payload:
		if payload[key] is Array or key=="parent_blockers_ref": out[key]=sha(var_to_bytes(payload[key]))
	return out
func publish_one(id: String,source: Dictionary,author: Dictionary,assets: Dictionary,root: String) -> Dictionary:
	var parent_bytes: PackedByteArray=FileAccess.get_file_as_bytes(physical(source.payload.path))
	var raw: Variant=bytes_to_var(parent_bytes)
	if not check(raw is Dictionary and var_to_bytes(raw)==parent_bytes and raw.scene_id==id,"TYPED_PARENT:"+id): return {}
	var parent: Dictionary=raw;var child: Dictionary=parent.duplicate(true)
	var world: Vector2=vec(source.world_size_px);var coordinates: Vector2=vec(author.coordinate_size_px)
	if not check(world==parent.world_size_px and coordinates.is_finite() and coordinates.x>0 and coordinates.y>0 and world.x/coordinates.x==world.y/coordinates.y,"UNIFORM_SOURCE_COORDINATES:"+id): return {}
	var polygon_only: bool=source.mask.kind=="SOURCE_POLYGON_ONLY"
	if not check(polygon_only==(id=="ch4_s4_ancient_temple"),"ORIGINAL_MASK_KIND:"+id): return {}
	var old_mask: Image=null;var mask: Image=null
	if not polygon_only:
		old_mask=Image.load_from_file(physical(source.mask.path))
		if not check(old_mask!=null and old_mask.get_size()==Vector2i(world) and not old_mask.has_mipmaps(),"OLD_MASK_SIZE:"+id): return {}
		old_mask.convert(Image.FORMAT_RGBA8)
		if not check(sha(old_mask.get_data())==source.mask.RGBA_sha256,"OLD_RGBA:"+id): return {}
		mask=old_mask.duplicate()
	var appended: Array=[];var changed: Dictionary={}
	for placement: Dictionary in author.placements:
		var asset: Dictionary=assets[placement.asset_id]
		var foot: Vector2=vec(placement.foot);var anchor: Vector2=vec(asset.source_anchor)
		var size: Vector2=vec(asset.source_size);var ratio: float=float(placement.uniform_scale)
		if not check(foot.is_finite() and anchor.is_finite() and size.is_finite() and size.x>0 and size.y>0 and is_finite(ratio) and ratio>0,"FINITE_ASSET_PLACEMENT:"+String(placement.id)): return {}
		var same_coordinates: bool=coordinates==world
		var foot_world: Vector2=foot if same_coordinates else foot/coordinates*world
		for old: Dictionary in child.effective_navigation:
			if not check(old.id!=placement.id,"UNIQUE_NEW_ID:"+String(placement.id)): return {}
		var polygons: Array=[]
		for source_polygon: Array in asset.true_ground_polygons:
			var polygon:=PackedVector2Array()
			for point: Array in source_polygon:
				var source_point: Vector2=foot+(vec(point)-anchor)*ratio
				polygon.append(source_point if same_coordinates else source_point/coordinates*world)
			for old: PackedVector2Array in child.effective_solids:
				if not check(Geometry2D.intersect_polygons(polygon,old).is_empty(),"NEW_TRUE_BASE_OVERLAP:"+String(placement.id)): return {}
			polygons.append(polygon)
			var bounds:=Rect2(polygon[0],Vector2.ZERO)
			for point: Vector2 in polygon: bounds=bounds.expand(point)
			if not check(Rect2(Vector2.ZERO,world).encloses(bounds),"BODY_INSIDE_WORLD:"+String(placement.id)): return {}
			if mask==null: continue
			for y: int in range(floori(bounds.position.y),ceili(bounds.end.y)+1):
				for x: int in range(floori(bounds.position.x),ceili(bounds.end.x)+1):
					if not Geometry2D.is_point_in_polygon(Vector2(x,y),polygon): continue
					var index: int=y*int(world.x)+x
					if not changed.has(index): changed[index]=old_mask.get_pixel(x,y)
					mask.set_pixel(x,y,Color(0,0,0,1))
		if not check(not polygons.is_empty(),"NEW_VISIBLE_OBJECT_REQUIRES_REAL_BASE:"+String(placement.id)): return {}
		var render_size: Vector2=size*ratio if same_coordinates else size*ratio/coordinates*world
		var row: Dictionary={"id":String(placement.id),"texture":String(asset.texture),"pos":(foot+(size*0.5-anchor)*ratio)/coordinates,"render_size_px":render_size,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/coordinates.y,"world_foot_px":[float(foot_world.x),float(foot_world.y)],"physical_center_px":[float(foot_world.x),float(foot_world.y)],"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":polygons,"blocking":true,"district_life_fade":false}
		child.effective_navigation.append(row);child.visual_additions.append(row);child.effective_solids.append_array(polygons);appended.append(row)
	var inverse: Dictionary=child.duplicate(true)
	inverse.effective_navigation.resize(parent.effective_navigation.size());inverse.visual_additions.resize(parent.visual_additions.size());inverse.effective_solids.resize(parent.effective_solids.size())
	if not check(var_to_bytes(inverse)==parent_bytes,"WHOLE_PARENT_TYPED_INVERSE:"+id): return {}
	if mask!=null:
		var restored: Image=mask.duplicate()
		for index: int in changed: restored.set_pixel(index%int(world.x),floori(float(index)/world.x),changed[index])
		if not check(sha(restored.get_data())==source.mask.RGBA_sha256,"RGBA_INVERSE_ONLY_NEW_DOMAINS:"+id): return {}
	for route: Dictionary in author.get("routes",[]):
		var ok: bool=true
		for i: int in range(1,route.points.size()):
			var a: Vector2=vec(route.points[i-1]) if coordinates==world else vec(route.points[i-1])/coordinates*world
			var b: Vector2=vec(route.points[i]) if coordinates==world else vec(route.points[i])/coordinates*world
			var steps: int=maxi(1,ceili(a.distance_to(b)/8.0))
			for j: int in range(steps+1):
				if not clear(a.lerp(b,float(j)/steps),Vector2(17,12),world,mask,child.effective_solids,parent.effective_walkable_polygons): ok=false;break
			if not ok: break
		if not check(ok,"LOCAL_ENTRY_OR_SHORT_ROUTE:"+id+":"+String(route.id)): return {}
	var output: String=root+id+"/";DirAccess.make_dir_recursive_absolute(physical(output))
	var result: Dictionary={"payload":write_new(output+"payload.bin",var_to_bytes(child)),"fingerprints":fingerprints(child),"added_ids":appended.map(func(row: Dictionary) -> String: return row.id),"effective_navigation_count":child.effective_navigation.size(),"effective_solids_count":child.effective_solids.size(),"parent_payload":source.payload,"whole_payload_inverse":true,"new_domain_pixel_count":changed.size(),"old_routes_replayed":0}
	if polygon_only: result.mask={"kind":"SOURCE_POLYGON_ONLY"}
	else:
		var path: String=output+"walk_overlay.png"
		if not check(not FileAccess.file_exists(physical(path)) and mask.save_png(physical(path))==OK,"NEW_MASK_OUTPUT:"+id): return {}
		result.mask={"kind":"RAW_RGBA8_PENDING_ISOLATED_IMPORT","path":path,"sha256":FileAccess.get_sha256(physical(path)),"RGBA_sha256":sha(mask.get_data()),"size":[int(world.x),int(world.y)],"bytes":FileAccess.get_file_as_bytes(physical(path)).size()}
		result.whole_RGBA_inverse=true
	return result
func publish_market_migration(source: Dictionary,root: String) -> Dictionary:
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(physical(source.payload.path));var raw: Variant=bytes_to_var(bytes)
	if not check(raw is Dictionary and raw.scene_id==MARKET and var_to_bytes(raw)==bytes,"CURRENT_MARKET9F08_TYPED_PARENT"): return {}
	var parent: Dictionary=raw;var child: Dictionary=parent.duplicate(true)
	var migration: Dictionary={"npc_id":"spar_luoyang_patrol","old_source_origin_px":[1260.0,1580.0],"new_source_origin_px":[1380.0,1580.0]}
	for old: Dictionary in parent.npc_migrations:
		if not check(old.get("npc_id")!=migration.npc_id,"NO_EXISTING_PATROL_MIGRATION"): return {}
	child.npc_migrations.append(migration)
	var inverse: Dictionary=child.duplicate(true);var removed: Variant=inverse.npc_migrations.pop_back()
	if not check(var_to_bytes(removed)==var_to_bytes(migration) and var_to_bytes(inverse)==bytes,"MARKET_ONLY_ONE_MIGRATION_FULL_TYPED_INVERSE"): return {}
	var output: String=root+MARKET+"/";DirAccess.make_dir_recursive_absolute(physical(output))
	return {"payload":write_new(output+"payload.bin",var_to_bytes(child)),"mask":source.mask,"fingerprints":fingerprints(child),"only_changed_field":"npc_migrations","whole_payload_inverse":true,"six_street_instances_material_mask_unchanged":true,"prior49check97ms_inherited_not_replayed":true}
func run() -> void:
	if not check(READY and FileAccess.get_sha256(physical(INPUT))==INPUT_SHA,"ROOT_READY_INPUT"): quit(2);return
	var spec: Dictionary=read_json(INPUT)
	if not check(spec.get("ready")==true,"ROOT_READY_BATCH"): quit(2);return
	for path: String in spec.sources:
		if not check(FileAccess.get_sha256(physical(path))==spec.sources[path],"FIXED_SOURCE:"+path): quit(2);return
	var binding: Dictionary=read_json(spec.binding.path);var author: Dictionary=read_json(spec.author.path)
	if not check(author.get("scenes") is Dictionary and author.scenes.size()==7 and not author.scenes.has(MARKET),"EXACT_SEVEN_ART_SCENES_NO_MARKET_LAYOUT"): quit(2);return
	var root: String=spec.output_root+str(OS.get_process_id())+"/"
	if not check(root.begins_with(PREFIX),"NEW_BATCH_OUTPUT_SCOPE"): quit(2);return
	DirAccess.make_dir_recursive_absolute(physical(root))
	var scenes: Dictionary={}
	for id: String in IDS:
		var result: Dictionary=publish_one(id,binding.scenes[id],author.scenes[id],author.assets,root)
		if not result.is_empty(): scenes[id]=result
	var market: Dictionary=publish_market_migration(binding.scenes[MARKET],root)
	if not market.is_empty(): scenes[MARKET]=market
	for path: String in spec.sources: check(FileAccess.get_sha256(physical(path))==spec.sources[path],"SOURCE_FINAL:"+path)
	var report: Dictionary={"passed":errors.is_empty() and scenes.size()==8,"status":"ONE_SEVEN_FIELD_CONTENT_BATCH_PLUS_ONLY_MARKET_PATROL_MIGRATION_NOT_FIELD_OR_ART_PASS","checks":checks,"errors":errors,"scenes":scenes,"parent_binding":spec.binding,"Scene_Field_Router_calls":0,"canonical_writes":0,"old87517_or_city_matrix_replayed":0,"actual_Field_pass":false}
	write_new(root+"result.json",(JSON.stringify(report,"\t")+"\n").to_utf8_buffer());print("SEVEN_LAYOUT_RESULT ",root+"result.json");quit(0 if report.passed else 1)
