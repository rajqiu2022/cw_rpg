extends SceneTree
## Only two public portal rows and two Market wall domains. Root sole CPU.
const READY: bool=false
const INPUT: String="res://build/luoyang_exit_wall_fix_20261027b_system01/input_NOTREADY.json"
const INPUT_SHA: String="PENDING_ROOT_REVIEW_INPUT"
const PREFIX: String="res://build/luoyang_exit_wall_fix_20261027b_system01/"
const GAME_ROOT: String="F:/Code/RPG_GAME/game/"
const SIZE: Vector2=Vector2(3072,2048)
var errors: Array[String]=[]
var checks: int=0
func _initialize() -> void: call_deferred("run")
func physical(path: String) -> String: return GAME_ROOT+path.trim_prefix("res://") if path.begins_with("res://") else path
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label);printerr("EXIT_WALL_LOCAL ",label)
	return ok
func same(a: Variant,b: Variant) -> bool: return var_to_bytes(a)==var_to_bytes(b)
func vec(raw: Array) -> Vector2: return Vector2(float(raw[0]),float(raw[1]))
func sha(raw: PackedByteArray) -> String:
	var h:=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(raw);return h.finish().hex_encode()
func json_file(path: String) -> Dictionary:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(physical(path)))
	return raw if raw is Dictionary else {}
func find(rows: Array,id: String) -> Dictionary:
	var found: Dictionary={}
	for row: Dictionary in rows:
		if String(row.get("id",""))==id:
			if not found.is_empty(): return {}
			found=row
	return found
func rect(low: Vector2,size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([low,low+Vector2(size.x,0),low+size,low+Vector2(0,size.y)])
func contains(point: Vector2,polys: Array) -> bool:
	for poly: PackedVector2Array in polys:
		if Geometry2D.is_point_in_polygon(point,poly): return true
	return false
func mask_file(row: Dictionary) -> Image:
	if not check(FileAccess.get_sha256(physical(row.path))==row.sha256,"PINNED_MASK:"+String(row.path)): return null
	var image:=Image.load_from_file(physical(row.path))
	if not check(image!=null and image.get_size()==Vector2i(3072,2048) and not image.has_mipmaps(),"RGBA_MASK_SIZE"): return null
	image.convert(Image.FORMAT_RGBA8)
	if not check(sha(image.get_data())==row.RGBA_sha256,"RGBA_MASK_EXACT"): return null
	return image
func typed_payload(row: Dictionary) -> Dictionary:
	var raw: PackedByteArray=FileAccess.get_file_as_bytes(physical(row.path))
	if not check(sha(raw)==row.sha256,"PINNED_PAYLOAD:"+String(row.path)): return {}
	var decoded: Variant=bytes_to_var(raw)
	return decoded if check(decoded is Dictionary and var_to_bytes(decoded)==raw,"WHOLE_TYPED_PAYLOAD") else {}
func portal_delta(parent: Dictionary) -> Dictionary:
	var child: Dictionary=parent.duplicate(true)
	var is_yamen: bool=String(parent.scene_id)=="ch4_s1_luoyang_yamen"
	var id: String="finish_i_yamen_to_artisan" if is_yamen else "finish_i_artisan_to_yamen"
	var portal: Dictionary=find(child.portal_after,id)
	var previous: Dictionary=find(parent.portal_after,id)
	if not check(not portal.is_empty() and previous.get("label")=="City public branch","EXACT_TWO_ENGLISH_PORTALS_ONLY"): return {}
	if is_yamen:
		if not check(portal.pos==Vector2(120,1240)/SIZE and portal.target_pos==Vector2(128,1300)/SIZE and portal.target_scene=="luoyang_artisan_residential_20261022ap","YAMEN_EXACT_PRIOR_ROUTE"): return {}
		portal.pos=Vector2(120,700)/SIZE
		portal.interaction_polygon_px=rect(Vector2(100,684),Vector2(40,32))
		portal.label="前往百工坊"
	else:
		if not check(portal.pos==Vector2(128,1300)/SIZE and portal.target_pos==Vector2(120,1240)/SIZE and portal.target_scene=="ch4_s1_luoyang_yamen","ARTISAN_EXACT_PRIOR_RECIPROCAL"): return {}
		portal.target_pos=Vector2(120,700)/SIZE
		portal.label="前往府衙"
	var found: int=0
	for route: Dictionary in child.new_route_contracts:
		if route.get("source_portal_id")!=id: continue
		if not check(same(route.source_portal_row,previous),"ORIGINAL_DUPLICATED_PORTAL_ROW_EXACT"): return {}
		found+=1;route.source_portal_row=portal.duplicate(true)
		if is_yamen: route.source_foot_px=Vector2(120,700)
		else:
			route.target_foot_px=Vector2(120,700)
			route.expected_normalized=Vector2(120,700)/SIZE
			route.source_target_pos=Vector2(120,700)/SIZE
	if not check(found==1,"UNIQUE_RECIPROCAL_CONTRACT"): return {}
	var inverse: Dictionary=child.duplicate(true)
	inverse.portal_after=parent.portal_after.duplicate(true);inverse.new_route_contracts=parent.new_route_contracts.duplicate(true)
	if not check(same(inverse,parent),"PORTAL_ONLY_TWO_FIELDS_WHOLE_INVERSE"): return {}
	return {"child":child,"whole_payload_inverse":true,"changed_fields":["portal_after","new_route_contracts"],"new_world_foot":Vector2(120,700),"original_south_market_3001220_untouched":true}
func wall_delta(parent: Dictionary,art: Dictionary,mask: Image,baseline: Image) -> Dictionary:
	var child: Dictionary=parent.duplicate(true)
	var old_polys: Array=[]
	for spec: Dictionary in art.retire_only:
		var old: Dictionary=find(parent.effective_navigation,String(spec.id))
		var addition: Dictionary=find(parent.visual_additions,String(spec.id))
		if not check(not old.is_empty() and same(old,addition) and vec(old.world_foot_px)==vec(spec.old_foot) and old.texture=="res://art/maps/luoyang_enclosure_v11/ch4_s3_luoyang_market/entities/v13_market_west_plot_wall.png","EXACT_RETIRED_TWO_ADDITIONS"): return {}
		old_polys.append_array(old.city_v3_solid_polygons_px)
		child.effective_navigation.erase(old);child.visual_additions.erase(addition)
		for poly: PackedVector2Array in old.city_v3_solid_polygons_px:
			var matching: Array=[]
			for retained: PackedVector2Array in child.effective_solids:
				if same(poly,retained): matching.append(retained)
			if not check(matching.size()==1,"EXACT_TWO_OLD_BASES_RETIRED"): return {}
			child.effective_solids.erase(matching[0])
	var retained_solids: Array=child.effective_solids.duplicate(true)
	var asset: Dictionary=art.asset;var new_polys: Array=[];var new_rows: Array=[]
	for placement: Dictionary in art.placements:
		if not check(float(placement.uniform_scale)==1.0 and find(child.effective_navigation,String(placement.id)).is_empty(),"FOUR_NATIVE_SCALE1_UNIQUE_WALLS"): return {}
		var foot: Vector2=vec(placement.foot);var polys: Array=[]
		for raw: Array in asset.true_ground_polygons:
			var poly:=PackedVector2Array()
			for point: Array in raw: poly.append(foot+(vec(point)-vec(asset.source_anchor)))
			for other: PackedVector2Array in retained_solids:
				if not check(Geometry2D.intersect_polygons(poly,other).is_empty(),"NEW_BASE_NO_RETAINED_BODY_OVERLAP"): return {}
			polys.append(poly);new_polys.append(poly)
		var dimensions: Vector2=vec(asset.source_size)
		var row: Dictionary={"id":String(placement.id),"texture":String(asset.texture),"pos":(foot+dimensions*.5-vec(asset.source_anchor))/SIZE,"render_size_px":dimensions,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y,"world_foot_px":[float(foot.x),float(foot.y)],"physical_center_px":[float(foot.x),float(foot.y)],"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":polys,"blocking":true,"district_life_fade":false}
		child.effective_navigation.append(row);child.visual_additions.append(row);child.effective_solids.append_array(polys);new_rows.append(row)
	if not check(child.effective_navigation.size()==parent.effective_navigation.size()+2 and child.effective_solids.size()==parent.effective_solids.size()+2,"ONLY_TWO_TO_FOUR_WALL_COUNT_DELTA"): return {}
	var inverse: Dictionary=child.duplicate(true)
	for key: String in ["effective_navigation","visual_additions","effective_solids"]: inverse[key]=parent[key].duplicate(true)
	if not check(same(inverse,parent),"WALL_THREE_FIELDS_WHOLE_TYPED_INVERSE"): return {}
	var result: Image=mask.duplicate();var changed: Dictionary={};var domains: Array=[Rect2i(2290,1598,241,13),Rect2i(2694,1598,253,13)]
	for domain: Rect2i in domains:
		for y: int in range(domain.position.y,domain.end.y):
			for x: int in range(domain.position.x,domain.end.x):
				var point:=Vector2(x,y);var base: Color=baseline.get_pixel(x,y)
				if not check(base==Color.WHITE,"FIXED_PRE_WALL_DOMAIN_WAS_OPEN"): return {}
				var expected: Color=Color.BLACK if contains(point,old_polys) else base
				if not check(mask.get_pixel(x,y)==expected,"OLD_LOCAL_MASK_EXACT_TWO_BASES_NO_OTHER_BLACK"): return {}
				var next: Color=Color.BLACK if contains(point,new_polys) else base
				if next!=mask.get_pixel(x,y): changed[y*3072+x]=mask.get_pixel(x,y)
				result.set_pixel(x,y,next)
	var restored: Image=result.duplicate()
	for index: int in changed: restored.set_pixel(index%3072,floori(float(index)/3072.0),changed[index])
	if not check(same(restored.get_data(),mask.get_data()),"WHOLE_RGBA_INVERSE_ONLY_TWO_LOCAL_DOMAINS"): return {}
	# The old 144px passage is geometrically outside both new bases. Check only
	# its adjacent local strip, not any old street/room/city route matrix.
	if not check(2538.0-2530.0==8.0 and 2700.0-2682.0==18.0,"SOURCE_144_ACCESS_STREET_2538_TO2682_PRESERVED"): return {}
	for y: int in range(1586,1623):
		for x: int in range(2538,2683):
			if not check(result.get_pixel(x,y).r>=.5,"LOCAL_ACCESS144_REMAINS_OPEN"): return {}
	return {"child":child,"mask_image":result,"new_ids":new_rows.map(func(row: Dictionary) -> String: return row.id),"local_domains":domains,"changed_pixels":changed.size(),"whole_payload_inverse":true,"whole_RGBA_inverse":true,"effective_navigation_count":child.effective_navigation.size(),"effective_solids_count":child.effective_solids.size()}
func write_new(path: String,data: PackedByteArray) -> Dictionary:
	if not check(path.begins_with(PREFIX) and not FileAccess.file_exists(physical(path)),"NEW_BUILD_OUTPUT_ONLY"): return {}
	var f:=FileAccess.open(physical(path),FileAccess.WRITE)
	if not check(f!=null,"OUTPUT_OPEN"): return {}
	f.store_buffer(data);f.close();return {"path":path,"sha256":sha(data),"bytes":data.size()}
func run() -> void:
	if not check(READY and FileAccess.get_sha256(physical(INPUT))==INPUT_SHA,"ROOT_READY_INPUT"): quit(2);return
	var spec: Dictionary=json_file(INPUT)
	if not check(spec.get("ready")==true and spec.get("scope")=="TWO_PORTALS_TWO_WALL_DOMAINS_ONLY","FINITE_SCOPE"): quit(2);return
	for path: String in spec.sources:
		if not check(FileAccess.get_sha256(physical(path))==spec.sources[path],"SOURCE:"+path): quit(2);return
	var binding: Dictionary=json_file(spec.binding.path);var art: Dictionary=json_file(spec.art.path)
	var components: Dictionary={};var work: Dictionary={}
	for id: String in ["ch4_s1_luoyang_yamen","luoyang_artisan_residential_20261022ap","ch4_s3_luoyang_market"]:
		var parent: Dictionary=typed_payload(binding.scenes[id].payload)
		if parent.is_empty(): quit(1);return
		var derived: Dictionary={}
		if id=="ch4_s3_luoyang_market":
			var mask: Image=mask_file(binding.scenes[id].mask);var baseline: Image=mask_file(spec.pre_wall_mask)
			if mask==null or baseline==null: quit(1);return
			derived=wall_delta(parent,art,mask,baseline)
		else: derived=portal_delta(parent)
		if derived.is_empty(): quit(1);return
		work[id]=derived
	for path: String in spec.sources:
		if not check(FileAccess.get_sha256(physical(path))==spec.sources[path],"SOURCE_FINAL:"+path): quit(1);return
	var root: String=spec.output_root+str(OS.get_process_id())+"/"
	for id: String in work:
		var folder: String=root+id+"/";DirAccess.make_dir_recursive_absolute(physical(folder))
		var child: Dictionary=work[id].child;var fingerprints: Dictionary={}
		for key: String in child:
			if child[key] is Array or key=="parent_blockers_ref": fingerprints[key]=sha(var_to_bytes(child[key]))
		var row: Dictionary=work[id].duplicate();row.erase("child");row.erase("mask_image")
		row.payload=write_new(folder+"payload.bin",var_to_bytes(child));row.fingerprints=fingerprints
		if work[id].has("mask_image"):
			var mask_path: String=folder+"walk_overlay.png";var image: Image=work[id].mask_image
			if not check(not FileAccess.file_exists(physical(mask_path)) and image.save_png(physical(mask_path))==OK,"ONE_NEW_MARKET_MASK"): quit(1);return
			row.mask={"path":mask_path,"sha256":FileAccess.get_sha256(physical(mask_path)),"RGBA_sha256":sha(image.get_data()),"size":[3072,2048]}
		components[id]=row
	var report: Dictionary={"passed":errors.is_empty(),"status":"LOCAL_TWO_PORTALS_ADULT_WALLS_NOT_FIELD_OR_ART_PASS","checks":checks,"errors":errors,"components":components,"source_first":spec.sources,"source_final":spec.sources,"old_city_geometry_rebuilt":false,"Scene_Field_Router_calls":0,"old_routes_replayed":0}
	write_new(root+"result.json",(JSON.stringify(report,"\t")+"\n").to_utf8_buffer());print("EXIT_WALL_RESULT ",root+"result.json");quit(0 if errors.is_empty() else 1)
