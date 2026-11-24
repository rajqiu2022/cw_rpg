extends SceneTree
## Root-only candidate publisher. READY/input/source/ART/pixel priors are closed
## before any publication. No Field, source collector, C.prepare or full raster.
const READY=false
const INPUT="res://build/luoyang_city_space_20261024b_source01/publication_input_threshold_return_successor02_NOTREADY.json"
const INPUT_SHA="PENDING_ROOT_FROZEN_INPUT"
const OUT="res://build/luoyang_city_space_20261024b_source01/native_publication_threshold_return_NOTRUN/"
const BASIS="EXACT_CURRENT_FINITE_MARKET_TO_FULL_MERCHANT_BLOCK_20261024B"
const SIZE=Vector2i(3072,2048)
const LIMIT_MS=60000
var config: Dictionary={}
var api: Variant
var geometry: Variant
var wall: Variant
var dg: Variant
var first: Dictionary={}
var failure: String=""
var started: int=0
var checks: int=0

func _initialize() -> void: call_deferred("_run")
func need(condition: bool,label: String) -> bool:
	checks+=1
	if not condition and failure.is_empty(): failure=label;push_error("MARKET_BLOCK_PUBLISHER:"+label)
	return condition
func read_json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func track(path: String,sha: String) -> bool:
	if not need(path.begins_with("res://") and ".." not in path and sha.length()==64,"DECLARED_RES_SOURCE:"+path): return false
	var actual: String=FileAccess.get_sha256(path)
	if not need(actual==sha and (not first.has(path) or first[path]==sha),"FIXED_SOURCE_SHA:"+path): return false
	first[path]=sha;return true
func v(raw: Variant) -> Vector2: return geometry.v(raw)
func box(raw: Array) -> Rect2: return Rect2(raw[0],raw[1],raw[2],raw[3])
func load_mask(path: String) -> Image:
	var image: Image=Image.load_from_file(path)
	if image!=null: image.convert(Image.FORMAT_RGBA8)
	return image
func pointer(root: Variant,path: Array) -> Variant:
	var value: Variant=root
	for key: Variant in path:
		if not value is Dictionary or not value.has(key): return null
		value=value[key]
	return value
func assign_pointer(root: Dictionary,path: Array,value: Variant) -> bool:
	if path.is_empty(): return false
	var cursor: Dictionary=root
	for i: int in path.size()-1:
		if not cursor.get(path[i]) is Dictionary: return false
		cursor=cursor[path[i]]
	if not cursor.has(path[-1]): return false
	cursor[path[-1]]=value
	return true

func parent_native() -> Dictionary:
	var spec: Dictionary=config.parent
	var packet: Variant=bytes_to_var(FileAccess.get_file_as_bytes(spec.packet_path))
	var scene:=ResourceLoader.load(spec.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var layout:=ResourceLoader.load(spec.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	var image: Image=load_mask(spec.walk_path)
	if not need(packet is Dictionary and api._plain(packet) and scene!=null and layout!=null and image!=null,"FIXED_CURRENT_PARENT_PACKET_SCENE_LAYOUT"): return {}
	if not need(packet.record.canonical_scene_id=="ch4_s3_luoyang_market" and packet.record.objects.size()==23 and scene.map_layout.visual_objects.size()==23,"EXACT_CURRENT_NATIVE23"): return {}
	var actual_ids: Array=[]
	for row: Dictionary in packet.record.objects: actual_ids.append(String(row.id))
	if not need(actual_ids==config.parent_native_object_ids,"ROOT_READBACK23_IDS_AND_ORDER"): return {}
	if not need(api.equal(api.storage(scene),packet.scene_storage) and api.equal(api.storage(scene.map_layout),packet.layout_storage) and api.equal(api.storage(layout),packet.layout_storage),"WHOLE_PARENT_STORAGE"): return {}
	if not need(image.get_size()==SIZE and image.get_data()==packet.walk_bytes and packet.mask_sha==spec.mask_rgba_sha256 and api.bytes_sha(image.get_data())==spec.mask_rgba_sha256,"PARENT_WHOLE_RGBA_PACKET_EQUAL"): return {}
	if not need(api.equal(wall.native_solids(packet.record.objects),packet.solids),"WHOLE_PARENT_NATIVE_SOLIDS"): return {}
	return {"packet":packet,"scene":scene,"mask":image}

func authored_plinth_alpha(author: Dictionary) -> Dictionary:
	# Bounded source-image evidence, not roof/A1 rectangle collision. Only the
	# exact manually authored plinth polygons are sampled; no source edits.
	var report: Dictionary={}
	for placement: Dictionary in author.complete_buildings:
		var asset: Dictionary=author.assets[placement.asset_id]
		var image: Image=load_mask(asset.texture)
		if not need(image!=null and image.get_size()==Vector2i(v(asset.source_size_px)),"EXACT_COMPLETE_SHOP_SOURCE_IMAGE"): return {}
		var polygon_rows: Array=[]
		for raw: Variant in asset.ground_solid_polygons_px:
			var polygon: PackedVector2Array=geometry.poly(raw);var rect: Rect2=geometry.bounds(polygon)
			var samples: int=0;var minimum_alpha: float=1.0
			for y: int in range(floori(rect.position.y),ceili(rect.end.y)+1):
				for x: int in range(floori(rect.position.x),ceili(rect.end.x)+1):
					if not Geometry2D.is_point_in_polygon(Vector2(x,y),polygon): continue
					samples+=1;minimum_alpha=minf(minimum_alpha,image.get_pixel(x,y).a)
			if not need(samples>0 and minimum_alpha>=.5,"WHOLE_AUTHORED_VISIBLE_PLINTH_ALPHA_COVERAGE"): return {}
			polygon_rows.append({"interior_integer_samples":samples,"minimum_alpha":minimum_alpha})
		report[placement.id]={"source_alpha_only_not_whole_building_volume":true,"polygons":polygon_rows}
	return report

func record_child(parent: Dictionary,author: Dictionary) -> Dictionary:
	var replacements: Array=[]
	for placement: Dictionary in author.complete_buildings:
		var asset: Dictionary=author.assets.get(placement.asset_id,{})
		var row: Dictionary=geometry.building(asset,placement)
		if not need(not row.is_empty(),"MEASURED_COMPLETE_BUILDING:"+String(placement.id)): return {}
		replacements.append(row)
	if not need(replacements.size()==2,"EXACT_TWO_COMPLETE_SHOPS"): return {}
	var result: Dictionary=geometry.replace_objects(parent.objects,replacements,author.native_object_moves)
	if not need(not result.is_empty(),"EXACT_NATIVE_REPLACEMENTS_AND_MOVES"): return {}
	var pruned: Dictionary=geometry.retire_closed_stalls(result.rows,author.retire_closed_stall_ids)
	if not need(not pruned.is_empty() and pruned.rows.size()==21,"EXACT_TWO_CLOSED_DUPLICATES_ONLY"): return {}
	var child: Dictionary=parent.duplicate(true);child.objects=pruned.rows
	var walls: Array=[]
	for placement: Dictionary in author.low_wall_components:
		var row: Dictionary=geometry.low_wall(author.low_wall_asset,placement)
		if not need(not row.is_empty() and geometry.exact_row(parent.objects,String(placement.id)).is_empty(),"NEW_SOURCE_BOUND_LOW_WALL"): return {}
		walls.append(row)
	if not need(walls.size()==4,"EXACT_FOUR_REAR_COURT_PANELS"): return {}
	child.objects.append_array(walls.duplicate(true))
	var fields: Array=[{"pointer":["objects"],"old":parent.objects.duplicate(true)}]
	for change: Dictionary in author.record_point_migrations:
		var path: Array=change.pointer
		if not need(path in [["npc_stations"],["interaction_anchors"],["gameplay_slots","npcs"],["gameplay_slots","interactions"],["gameplay_slots","portals"]],"EXACT_POINT_FIELD_ALLOWLIST"): return {}
		var old: Variant=pointer(child,path)
		if not need(old is Array,"POINT_FIELD_ARRAY"): return {}
		var migrated: Dictionary=geometry.exact_point_row_migration(old,change.deltas,change.id_key,change.point_key)
		if not need(not migrated.is_empty(),"SAME_ID_POINT_AND_SHAPE_MIGRATION"): return {}
		fields.append({"pointer":path.duplicate(),"old":old.duplicate(true)})
		if not assign_pointer(child,path,migrated.rows): return {}
	var routes: Array=child.routes.duplicate(true);var seen: Dictionary={}
	for change: Dictionary in author.route_replacements:
		var id: String=String(change.id);var ordinal: int=-1
		if not need(not seen.has(id),"UNIQUE_ROUTE_DELTA"): return {}
		seen[id]=true
		for i: int in routes.size():
			if String(routes[i].id)==id:
				if ordinal!=-1: return {}
				ordinal=i
		if not need(ordinal>=0 and geometry.poly(routes[ordinal].points_px)==geometry.poly(change.old_points_px),"EXACT_CURRENT_ROUTE:"+id): return {}
		routes[ordinal].points_px=change.new_points_px.duplicate(true)
	fields.append({"pointer":["routes"],"old":parent.routes.duplicate(true)});child.routes=routes
	fields.append({"pointer":["walk_path"],"old":parent.walk_path});child.walk_path=OUT+"walk.png"
	var inverse: Dictionary=child.duplicate(true)
	for change: Dictionary in fields:
		if not assign_pointer(inverse,change.pointer,change.old): return {}
	if not need(api.equal(inverse,parent),"WHOLE_NATIVE_RECORD_EXACT_TYPED_INVERSE"): return {}
	return {"record":child,"old_fields":fields,"replacements":replacements,"new_walls":walls}

func child_scene(parent: SceneScript,author: Dictionary,result: Dictionary) -> Dictionary:
	var visuals: Dictionary=geometry.replace_objects(parent.map_layout.visual_objects,result.replacements,author.native_object_moves,true)
	if not need(not visuals.is_empty(),"EXACT_VISUAL_REPLACEMENT_AND_MOVES"): return {}
	var pruned: Dictionary=geometry.retire_closed_stalls(visuals.rows,author.retire_closed_stall_ids)
	if not need(not pruned.is_empty(),"EXACT_VISUAL_CLOSED_RETIREMENTS"): return {}
	var child:=parent.duplicate(true) as SceneScript;child.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	if not need(child!=parent and child.map_layout!=parent.map_layout,"INDEPENDENT_NATIVE_SCENE_LAYOUT"): return {}
	child.map_layout.visual_objects.clear();child.map_layout.visual_objects.append_array(pruned.rows.duplicate(true));child.map_layout.walkable_mask_path=OUT+"walk.png"
	for row: Dictionary in result.new_walls: child.map_layout.visual_objects.append(geometry.render_entry(row))
	var people: Dictionary=geometry.exact_point_row_migration(child.npcs,author.scene_npc_migrations,"npc_id","pos",true)
	var portals: Dictionary=geometry.exact_point_row_migration(child.map_layout.portals,author.native_portal_migrations,"id","pos",true)
	if not need(not people.is_empty() and not portals.is_empty(),"NATIVE_SAME_ID_PEOPLE_PORTALS"): return {}
	child.npcs.clear();child.npcs.append_array(people.rows);child.map_layout.portals.clear();child.map_layout.portals.append_array(portals.rows)
	var inverse:=child.duplicate(true) as SceneScript;inverse.map_layout=child.map_layout.duplicate(true) as WalkableMapLayout
	inverse.npcs.clear();inverse.npcs.append_array(parent.npcs.duplicate(true));inverse.map_layout.portals.clear();inverse.map_layout.portals.append_array(parent.map_layout.portals.duplicate(true))
	inverse.map_layout.visual_objects.clear();inverse.map_layout.visual_objects.append_array(parent.map_layout.visual_objects.duplicate(true));inverse.map_layout.walkable_mask_path=parent.map_layout.walkable_mask_path
	if not need(api.equal(api.storage(inverse),api.storage(parent)) and api.equal(api.storage(inverse.map_layout),api.storage(parent.map_layout)),"WHOLE_SCENE_LAYOUT_TYPED_INVERSE"): return {}
	return {"scene":child,"inverse_fields":["Scene.npcs","Layout.visual_objects","Layout.portals","Layout.walkable_mask_path"]}

func local_mask(parent: Dictionary,record: Dictionary,author: Dictionary,prior: Dictionary) -> Dictionary:
	var raw: Image=load_mask(parent.packet.record.raw_walk_path)
	if not need(raw!=null and raw.get_size()==SIZE,"PINNED_ORIGINAL_RAW_GROUND_MASK"): return {}
	var output: Image=parent.mask.duplicate() as Image;var before: PackedByteArray=parent.mask.get_data();var changed: Array=[];var seen: Dictionary={}
	for values: Array in author.changed_mask_domains_closed:
		if not need(values.size()==4,"EXACT_CLOSED_MASK_DOMAIN"): return {}
		var rect:=Rect2i(values[0],values[1],values[2]-values[0]+1,values[3]-values[1]+1)
		if not need(Rect2i(Vector2i.ZERO,SIZE).encloses(rect),"MASK_DOMAIN_INSIDE"): return {}
		for y: int in range(rect.position.y,rect.end.y):
			if not need(Time.get_ticks_msec()-started<LIMIT_MS,"FINITE_PUBLICATION_WALLTIME"): return {}
			for x: int in range(rect.position.x,rect.end.x):
				var offset: int=y*SIZE.x+x
				if seen.has(offset): continue
				seen[offset]=true
				if not need(seen.size()<=int(config.pixel_visit_budget),"FINITE_UNION_PIXEL_BUDGET"): return {}
				var point:=Vector2(x,y);var base: Color=raw.get_pixel(x,y)
				var old_expected: Color=Color.BLACK if wall.native_raster_blocked(point,parent.packet.record.objects) else base
				if not need(parent.mask.get_pixel(x,y)==old_expected,"LOCAL_PARENT_RAW_PLUS_NATIVE_EQUAL"): return {}
				var desired: Color=Color.BLACK if wall.native_raster_blocked(point,record.objects) else base
				if output.get_pixel(x,y)==desired: continue
				changed.append(offset);output.set_pixel(x,y,desired)
	var after: PackedByteArray=output.get_data();var inverse: PackedByteArray=after.duplicate()
	for pixel: int in changed:
		for channel: int in 4: inverse[pixel*4+channel]=before[pixel*4+channel]
	if not need(inverse==before and api.bytes_sha(before)==prior.parent_rgba_sha256 and api.bytes_sha(after)==prior.expected_child_rgba_sha256 and changed.size()==int(prior.changed_pixels) and seen.size()==int(prior.union_visited_pixels),"INDEPENDENT_PRIOR_AND_WHOLE_RGBA_INVERSE"): return {}
	return {"mask":output,"changed_pixels":changed.size(),"union_visited_pixels":seen.size(),"parent_rgba_sha256":api.bytes_sha(before),"child_rgba_sha256":api.bytes_sha(after),"whole_RGBA_inverse":true,"outside_union_unchanged":true}

func closed_box_hit(a: Rect2,b: Rect2) -> bool:
	return a.position.x<=b.end.x and a.end.x>=b.position.x and a.position.y<=b.end.y and a.end.y>=b.position.y

func safe_body(foot: Vector2,mask: Image,solids: Array[PackedVector2Array],npc: bool=false) -> bool:
	var half:=Vector2(17,15 if npc else 12)
	if not foot.is_finite() or foot.x-half.x<0 or foot.y-half.y<0 or roundi(foot.x+half.x)>=SIZE.x or roundi(foot.y+half.y)>=SIZE.y: return false
	var r:=Rect2(foot-half,half*2)
	var body:=PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
	# Original DG closed-boundary + rounded-hull1085 rules, never an epsilon.
	if not dg.safe_foot(solids,foot,half) or (npc and not dg._npc_clear(foot,mask,solids)): return false
	for solid: PackedVector2Array in solids:
		if not Geometry2D.intersect_polygons(body,solid).is_empty(): return false
		for point: Vector2 in body:
			if Geometry2D.is_point_in_polygon(point,solid): return false
	for y: int in range(roundi(r.position.y),roundi(r.end.y)+1):
		for x: int in range(roundi(r.position.x),roundi(r.end.x)+1):
			var color: Color=mask.get_pixel(x,y)
			if color.r<.5 or color.a<.5: return false
	# Exact original seventeen mask probes, additional to every875/1085pixel.
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		var point:=Vector2i((foot+offset).round())
		var color: Color=mask.get_pixelv(point)
		if color.r<.5 or color.a<.5: return false
	return true

func collect_paths(record: Dictionary,district: Dictionary) -> Array:
	var paths: Array=record.routes.duplicate(true)
	for key: String in ["entry_foot_px","return_foot_px"]:
		if record.has(key): paths.append({"id":key,"points_px":[record[key],record[key]]})
	for kind: String in ["npcs","interactions","portals"]:
		for row: Dictionary in record.get("gameplay_slots",{}).get(kind,[]):
			for key: String in ["stand_px","foot_px","arrival_foot_px"]:
				if row.has(key): paths.append({"id":kind+":"+String(row.get("source_id",""))+":"+key,"points_px":[row[key],row[key]],"npc":kind=="npcs"})
			if row.has("passage_path_px"): paths.append({"id":"passage:"+String(row.get("source_id","")),"points_px":row.passage_path_px.duplicate(true)})
	for person: Dictionary in district.crowd:
		var foot: Vector2=v(person.foot_px);var distance: float=float(person.distance_px)
		paths.append({"id":"district:"+String(person.id),"points_px":[foot-Vector2(distance,0),foot+Vector2(distance,0)],"npc":true,"real_original_npc_lane":true})
	for index: int in district.protected_feet.size():
		var foot: Variant=district.protected_feet[index]
		paths.append({"id":"protected_district:"+str(index),"points_px":[foot,foot]})
	return paths

func route_delta_audit(parent_record: Dictionary,record: Dictionary,district: Dictionary,spec: Dictionary,mask: Image,solids: Array[PackedVector2Array],domains: Array[Rect2],changed_segments: Dictionary,new_paths: Array,all_six_lanes: bool=false) -> Dictionary:
	var paths: Array=collect_paths(record,district);paths.append_array(new_paths.duplicate(true))
	var new_ids: Dictionary={}
	for row: Dictionary in new_paths: new_ids[row.id]=true
	var failures: Array=[];var rows: Array=[];var checked: int=0;var inherited: int=0;var complete_lanes: int=0
	for path: Dictionary in paths:
		var npc: bool=path.get("npc",false)
		var forced: bool=new_ids.has(path.id) or (all_six_lanes and path.get("real_original_npc_lane",false))
		if all_six_lanes and path.get("real_original_npc_lane",false): complete_lanes+=1
		for segment: int in range(path.points_px.size()-1):
			var a: Vector2=v(path.points_px[segment]);var z: Vector2=v(path.points_px[segment+1])
			if not a.is_finite() or not z.is_finite(): return {"passed":false,"error":"NONFINITE_ROUTE"}
			var full: bool=forced or segment in changed_segments.get(path.id,[])
			var selected: bool=full
			var sweep:=Rect2(a.min(z),a.max(z)-a.min(z)).grow_individual(17,15,17,15)
			for domain: Rect2 in domains:
				if closed_box_hit(sweep,domain): selected=true
			if not selected: inherited+=1;continue
			var count: int=0;var steps: int=maxi(1,ceili(a.distance_to(z)/4.0))
			for index: int in range(steps+1):
				var foot: Vector2=a.lerp(z,float(index)/steps)
				var local: bool=full
				if not full:
					var body:=Rect2(foot-Vector2(17,15 if npc else 12),Vector2(34,30 if npc else 24))
					for domain: Rect2 in domains:
						if closed_box_hit(body,domain): local=true
				if not local: continue
				checked+=1;count+=1
				if not safe_body(foot,mask,solids,npc): failures.append({"id":path.id,"segment":segment,"sample":index,"foot":foot,"npc":npc})
			rows.append({"id":path.id,"segment":segment,"samples":count,"entire_changed_or_new_segment":full,"npc_full1085":npc})
	return {"passed":failures.is_empty() and (not all_six_lanes or complete_lanes==6),"checked_samples":checked,"failures":failures,"segments":rows,"unaffected_segments_inherited_not_replayed":inherited,"complete_real_NPC_lanes":complete_lanes,"max_step_px":4,"body_px":[34,24],"full875_plus17":true,"all_old_routes_replayed":false}

func route_audit(parent_record: Dictionary,record: Dictionary,mask: Image,author: Dictionary) -> Dictionary:
	var domains: Array[Rect2]=[]
	for values: Array in author.changed_mask_domains_closed:
		domains.append(Rect2(values[0],values[1],values[2]-values[0]+1,values[3]-values[1]+1))
	var changed: Dictionary={}
	for change: Dictionary in author.route_replacements:
		var all_segments: Array=[]
		for index: int in change.new_points_px.size()-1: all_segments.append(index)
		changed[String(change.id)]=all_segments
	var new_paths: Array=[]
	for change: Dictionary in author.record_point_migrations:
		for delta: Dictionary in change.deltas:
			new_paths.append({"id":"moved:"+str(change.pointer)+":"+String(delta.id),"points_px":[delta.new_foot_px,delta.new_foot_px],"npc":change.pointer==["npc_stations"] or change.pointer==["gameplay_slots","npcs"]})
	for delta: Dictionary in author.scene_npc_migrations:
		new_paths.append({"id":"scene_npc:"+String(delta.id),"points_px":[delta.new_foot_px,delta.new_foot_px],"npc":true})
	new_paths.append_array(author.extra_new_paths.duplicate(true))
	var solids: Array[PackedVector2Array]=wall.native_solids(record.objects)
	var district_solids: Array[PackedVector2Array]=geometry.district_solids(author)
	if not need(district_solids.size()==13,"EXACT_13_EXISTING_DISTRICT_PROP_SOLIDS_WITH_MEDICINE_REPLACEMENT"): return {}
	solids.append_array(district_solids)
	var result: Dictionary=route_delta_audit(parent_record,record,author.runtime_district,author,mask,solids,domains,changed,new_paths)
	if not need(result.get("passed")==true and int(result.get("checked_samples",0))>0,"EXACT_EXISTING_FULL87517_AND_NPC1085_LOCAL_ROUTE_AUDIT"): return {}
	return result

func publication() -> Dictionary:
	config=read_json(INPUT)
	if not need(config.get("ready")==true and config.get("root_run_authorized")==true and config.get("asset_geometry_ready")==true and config.get("independent_mask_prior_ready")==true,"ROOT_ASSET_AND_PRIOR_READY"): return {}
	for path: String in config.source_pins:
		if not track(path,config.source_pins[path]): return {}
	api=load(config.bundle_api_path);geometry=load(config.geometry_helper_path);wall=load(config.native_raster_helper_path);dg=load(config.district_geometry_path)
	if not need(api!=null and geometry!=null and wall!=null and dg!=null,"PINNED_PURE_BUILD_APIS"): return {}
	var author: Dictionary=read_json(config.author_path);var prior: Dictionary=read_json(config.pixel_prior_path)
	var alpha_result: Dictionary=authored_plinth_alpha(author)
	if alpha_result.size()!=2: return {}
	var parent: Dictionary=parent_native()
	if parent.is_empty(): return {}
	var record_result: Dictionary=record_child(parent.packet.record,author)
	if record_result.is_empty(): return {}
	var scene_result: Dictionary=child_scene(parent.scene,author,record_result)
	if scene_result.is_empty(): return {}
	var mask_result: Dictionary=local_mask(parent,record_result.record,author,prior)
	if mask_result.is_empty(): return {}
	var route_result: Dictionary=route_audit(parent.packet.record,record_result.record,mask_result.mask,author)
	if route_result.is_empty(): return {}
	var child: SceneScript=scene_result.scene;var packet: Dictionary=parent.packet.duplicate(true)
	var new_fields: Dictionary={"record":record_result.record,"solids":wall.native_solids(record_result.record.objects),"walk_bytes":mask_result.mask.get_data(),"mask_sha":mask_result.child_rgba_sha256,"scene_storage":api.storage(child),"layout_storage":api.storage(child.map_layout),"geometry_basis":BASIS,"space_replan_parent_packet_sha256":config.parent.packet_sha256,"space_replan_input_sha256":INPUT_SHA}
	for key: String in new_fields: packet[key]=new_fields[key]
	var inverse: Dictionary=packet.duplicate(true)
	for key: String in new_fields:
		if parent.packet.has(key): inverse[key]=parent.packet[key]
		else: inverse.erase(key)
	if not need(api.equal(inverse,parent.packet) and api._plain(packet),"WHOLE_PACKET_ALL_HISTORY_TYPED_INVERSE"): return {}
	# All proofs run before the first write. Never overwrite a native epoch.
	if not need(not DirAccess.dir_exists_absolute(OUT) and DirAccess.make_dir_recursive_absolute(OUT)==OK,"ABSENT_NEW_BUILD_OUTPUT"): return {}
	if not need(mask_result.mask.save_png(OUT+"walk.png")==OK and ResourceSaver.save(child.map_layout,OUT+"layout.res")==OK,"NEW_WALK_LAYOUT_WRITE"): return {}
	child.map_layout=ResourceLoader.load(OUT+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(child.map_layout!=null and ResourceSaver.save(child,OUT+"scene.res")==OK,"NEW_SCENE_WRITE"): return {}
	var back:=ResourceLoader.load(OUT+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(back!=null and api.equal(api.storage(back),packet.scene_storage) and api.equal(api.storage(back.map_layout),packet.layout_storage),"WHOLE_NATIVE_STORAGE_READBACK"): return {}
	var file:=FileAccess.open(OUT+"packet.bin",FileAccess.WRITE)
	if file==null: return {}
	file.store_buffer(var_to_bytes(packet));file.close()
	if not need(api.equal(bytes_to_var(FileAccess.get_file_as_bytes(OUT+"packet.bin")),packet),"PACKET_WHOLE_READBACK"): return {}
	var artifacts: Dictionary={}
	for name: String in ["scene.res","layout.res","packet.bin","walk.png"]: artifacts[OUT+name]=FileAccess.get_sha256(OUT+name)
	mask_result.erase("mask")
	return {"published":true,"artifacts":artifacts,"native_visuals":back.map_layout.visual_objects.size(),"native_solids":packet.solids.size(),"record_old_fields":record_result.old_fields,"source_plinth_alpha_proof":alpha_result,"mask_proof":mask_result,"route_proof":route_result,"whole_record_packet_scene_layout_inverse":true,"runtime_admission":false,"source_DAG_pending":true}

func _run() -> void:
	if not READY: push_error("MARKET_PUBLICATION_BUILD_NOT_ROOT_READY");quit(2);return
	started=Time.get_ticks_msec()
	if not track(INPUT,INPUT_SHA): quit(1);return
	var result: Dictionary=publication();var final: Dictionary={}
	for path: String in first: final[path]=FileAccess.get_sha256(path)
	var same: bool=first==final
	var passed: bool=result.get("published",false) and failure.is_empty() and same
	var report: Dictionary={"passed":passed,"checks":checks,"error":failure,"elapsed_ms":Time.get_ticks_msec()-started,"result":result,"source_first":first,"source_final":final,"source_first_final_same":same,"Field_Physics_collector_C_prepare_full_city_geometry_calls":0,"formal_writes":0}
	# The Root execution wrapper retains stdout/stderr even if publication exits
	# before output creation. No false success receipt is generated in advance.
	if DirAccess.dir_exists_absolute(OUT):
		var output:=FileAccess.open(OUT+"publication_result.json",FileAccess.WRITE)
		if output!=null: output.store_string(JSON.stringify(report,"\t",true,true));output.close()
	print(JSON.stringify({"passed":passed,"checks":checks,"error":failure,"elapsed_ms":Time.get_ticks_msec()-started}))
	quit(0 if passed else 1)
