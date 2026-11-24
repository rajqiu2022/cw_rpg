extends SceneTree
## BUILD preparation only. Four additive low props; never call old compiler/collector/Field.
const READY=true
const INPUT="res://build/luoyang_city_full_rollout_20261022ap_root01/integration59/artisan_life_READY/input_READY.json"
const INPUT_SHA="322ae6f9ed3b0a1bd1b6d72fcaa63ab4d4fabdcfa429614316375d27e1b51be1"
const OUT="res://build/luoyang_city_full_rollout_20261022ap_root01/integration59/artisan_life_READY/output/"
const ID="luoyang_artisan_residential_20261022ap"
const SIZE=Vector2(3072,2048)
const META="luoyang_artisan_life_delta"
const LIMIT_MS=60000
var api: Variant
var config: Dictionary={}
var pins: Dictionary={}
var failure: String=""
var checks: int=0
var began: int=0

func _initialize() -> void: call_deferred("run")
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok and failure.is_empty(): failure=label;push_error("ARTISAN_LIFE_DELTA:"+label)
	return ok
func json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func copy(value: Variant) -> Variant:
	return value.duplicate(true) if value is Array or value is Dictionary else value
func track(path: String,sha: String) -> bool:
	if not need(path.begins_with("res://") and not ".." in path and sha.length()==64 and FileAccess.get_sha256(path)==sha and (not pins.has(path) or pins[path]==sha),"FIXED_SOURCE:"+path): return false
	pins[path]=sha;return true
func save_json(path: String,data: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data,"\t",true,true));file.close();return true
func v(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if not raw is Array or raw.size()!=2: return Vector2(INF,INF)
	for value: Variant in raw:
		if typeof(value) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value)): return Vector2(INF,INF)
	return Vector2(raw[0],raw[1])
func bounds(poly: PackedVector2Array) -> Rect2:
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for point: Vector2 in poly: low=low.min(point);high=high.max(point)
	return Rect2(low,high-low)
func r(raw: Array) -> Rect2: return Rect2(raw[0],raw[1],raw[2],raw[3])
func solid_bounds(row: Dictionary) -> Rect2:
	return bounds(row.polygon_px) if row.has("polygon_px") else r(row.rect_px)
func solid_poly(row: Dictionary) -> PackedVector2Array:
	if row.has("polygon_px"): return row.polygon_px
	var area: Rect2=r(row.rect_px)
	return PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)])
func closed_hit(a: Rect2,b: Rect2) -> bool:
	return a.position.x<=b.end.x and b.position.x<=a.end.x and a.position.y<=b.end.y and b.position.y<=a.end.y
func domain(poly: PackedVector2Array) -> Rect2i:
	var area: Rect2=bounds(poly)
	var low:=Vector2i(floori(area.position.x),floori(area.position.y))
	var high:=Vector2i(ceili(area.end.x),ceili(area.end.y))
	return Rect2i(low,high-low+Vector2i.ONE)
func declared_domains(rows: Array) -> Array[Rect2i]:
	var output: Array[Rect2i]=[]
	for row: Array in rows:
		if row.size()!=4: return []
		output.append(Rect2i(int(row[0]),int(row[1]),int(row[2])-int(row[0])+1,int(row[3])-int(row[1])+1))
	return output
func polygon_arrays(poly: PackedVector2Array) -> Array:
	var output: Array=[]
	for point: Vector2 in poly: output.append([point.x,point.y])
	return output

func new_placement(raw: Dictionary) -> Dictionary:
	var source: Dictionary=json(raw.source_author.path);var selected: Array=[]
	for item: Dictionary in source.get("furniture",[]):
		if item.get(raw.source_author.selector_field)==raw.source_author.selector_value: selected.append(item)
	if not need(selected.size()==1,"ONE_ORIGINAL_ASSET_ROW:"+raw.id): return {}
	var original: Dictionary=selected[0]
	if not need(original.texture==raw.texture and String(original.source_sha256).to_lower()==raw.source_png_sha256 and api.equal(original.source_size_px,raw.source_size_px) and api.equal(original.source_ground_anchor_px,raw.source_ground_anchor_px) and api.equal(original.get(raw.source_author.polygon_field),raw.source_ground_solid_polygons_px),"ALL_ORIGINAL_SOURCE_POLYGON_ANCHOR_SIZE_PNG_UNCHANGED:"+raw.id): return {}
	if not need(raw.source_ground_solid_polygons_px.size()==1 and raw.height_behavior=="LOW_OPAQUE_ACTOR_LOCAL_GHOST","EXACT_ONE_LOW_SOLID:"+raw.id): return {}
	var foot: Vector2=v(raw.foot_px);var anchor: Vector2=v(raw.source_ground_anchor_px);var size: Vector2=v(raw.source_size_px);var scale_value: float=float(raw.uniform_scale)
	if not need(foot.is_finite() and anchor.is_finite() and size==Vector2(1536,1024) and scale_value>0,"EXACT_SOURCE_TRANSFORM:"+raw.id): return {}
	var poly:=PackedVector2Array()
	for point: Array in raw.source_ground_solid_polygons_px[0]: poly.append(foot+(v(point)-anchor)*scale_value)
	if not need(poly.size()>=3 and not Geometry2D.triangulate_polygon(poly).is_empty(),"NATIVE_F32_SOURCE_POLYGON:"+raw.id): return {}
	var full:=Rect2(foot-anchor*scale_value,size*scale_value)
	if not need(Rect2(Vector2.ZERO,SIZE).encloses(full),"COMPLETE_UNCROPPED_CANVAS_IN_WORLD:"+raw.id): return {}
	var visual: Dictionary={"id":raw.id,"texture":raw.texture,"pos":(foot+(size*.5-anchor)*scale_value)/SIZE,"render_size_px":size*scale_value,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y}
	return {"visual":visual,"solid":{"id":String(raw.id)+"_hull_0","polygon_px":poly,"asset":raw.id,"source_polygon":raw.source_ground_solid_polygons_px[0].duplicate(true)},"full_canvas":full,"polygon_json":polygon_arrays(poly),"domain":domain(poly)}

func inherited_clear(author: Dictionary,new_rows: Array,domains: Array[Rect2i],old_solids: Array,people: Array) -> Dictionary:
	var data: Dictionary=author.scenes[0];var inherited: Array=[];var NPCs: Array=[];var aprons: Array=[]
	var old_visual_bounds: Array[Rect2]=[]
	for row: Dictionary in data.placements:
		var asset: Dictionary=author.assets[row.asset];var scale_value: float=float(row.width)/float(asset.used_rect[2]);var used: Rect2=r(asset.used_rect)
		old_visual_bounds.append(Rect2(v(row.foot)+(used.position-v(asset.ground_anchor))*scale_value,used.size*scale_value))
	for i: int in new_rows.size():
		var item: Dictionary=new_rows[i];var box: Rect2=bounds(item.solid.polygon_px)
		for old: Dictionary in old_solids:
			if not need(not closed_hit(box,solid_bounds(old)),"NEW_BODY_AABB_DISJOINT_FROM_ALL27:"+String(item.solid.id)+":"+String(old.id)): return {}
		for old: Rect2 in old_visual_bounds:
			if not need(not item.full_canvas.intersects(old,true),"FULL_NEW_CANVAS_DISJOINT_FROM_OLD_USED_RECT:"+String(item.solid.id)): return {}
		for j: int in range(i):
			if not need(not item.full_canvas.intersects(new_rows[j].full_canvas,true),"FOUR_COMPLETE_NEW_CANVASES_DISJOINT"): return {}
	for route: Dictionary in data.routes:
		for ordinal: int in route.points.size()-1:
			var a: Vector2=v(route.points[ordinal]);var b: Vector2=v(route.points[ordinal+1])
			var sweep:=Rect2(a.min(b)-Vector2(17,12),a.max(b)-a.min(b)+Vector2(34,24))
			for area: Rect2i in domains:
				if not need(not closed_hit(sweep,Rect2(Vector2(area.position),Vector2(area.size))),"OLD_ROUTE_OUTSIDE_ALL4_DELTA_DOMAINS:"+String(route.id)+":"+str(ordinal)): return {}
			inherited.append({"id":route.id,"segment":ordinal})
	for person: Dictionary in people:
		if person.scene_id!=ID: continue
		var foot: Vector2=v(person.foot_px);var approach: Vector2=v(person.approach_px)
		var idle:=Rect2(foot-Vector2(17,15),Vector2(34,30));var sweep:=Rect2(foot.min(approach)-Vector2(17,12),foot.max(approach)-foot.min(approach)+Vector2(34,24))
		for area: Rect2i in domains:
			var area_float:=Rect2(Vector2(area.position),Vector2(area.size))
			if not need(not closed_hit(idle,area_float) and not closed_hit(sweep,area_float),"ALL4_IDLE_NPC34x30_AND48APPROACH_INHERITED"): return {}
		NPCs.append({"id":person.npc_id,"foot":person.foot_px,"approach":person.approach_px})
	for doorway: Dictionary in author.adult_doors:
		var selected: Array=[]
		for row: Dictionary in data.placements:
			if row.id==doorway.placement_id: selected.append(row)
		if not need(selected.size()==1,"FIVE_EXISTING_BUILDING_FEET"): return {}
		var foot: Vector2=v(selected[0].foot)
		var apron:=Rect2(foot-Vector2(64+17,12),Vector2(128+34,96+24))
		for area: Rect2i in domains:
			if not need(not closed_hit(apron,Rect2(Vector2(area.position),Vector2(area.size))),"ORIGINAL_5_DOOR128x96_APRON_WITH_FULLBODY_UNCHANGED"): return {}
		aprons.append({"id":doorway.placement_id,"foot":foot})
	for portal: Dictionary in data.portals:
		for dy: float in [0.0,10.0,24.0]:
			var body:=Rect2(v(portal.foot)+Vector2(0,dy)-Vector2(17,12),Vector2(34,24))
			for area: Rect2i in domains:
				if not need(not closed_hit(body,Rect2(Vector2(area.position),Vector2(area.size))),"ALL4_PORTAL_PLUS10_PLUS24_OUTSIDE_DELTA"): return {}
	if not need(data.routes.size()==7 and NPCs.size()==4 and aprons.size()==5 and data.portals.size()==4,"EXACT_INHERITED_AUTHOR_DOMAINS"): return {}
	return {"original7_route_segments_inherited":inherited,"original4NPC34x30_and48approaches_inherited":NPCs,"original5_door_aprons_inherited":aprons,"original4portals_plus10_plus24_inherited":true,"old_geometry_not_resampled":true}

func additive_mask(parent: PackedByteArray,new_rows: Array,domains: Array[Rect2i],prior: Dictionary) -> Dictionary:
	var fresh: PackedByteArray=parent.duplicate();var visited: Dictionary={}
	for area: Rect2i in domains:
		if not need(Rect2i(0,0,3072,2048).encloses(area),"FOUR_CLOSED_DOMAINS_IN_WORLD"): return {}
		for y: int in range(area.position.y,area.end.y):
			for x: int in range(area.position.x,area.end.x):
				var index: int=y*3072+x
				if visited.has(index): continue
				visited[index]=true
				for item: Dictionary in new_rows:
					var poly: PackedVector2Array=item.solid.polygon_px;var own: Rect2i=item.domain
					# Exact original floor(low)..ceil(high) inclusive bbox before PIP.
					if own.has_point(Vector2i(x,y)) and Geometry2D.is_point_in_polygon(Vector2(x,y),poly):
						var offset: int=index*4
						fresh[offset]=0;fresh[offset+1]=0;fresh[offset+2]=0;fresh[offset+3]=255
						break
	var inverse: PackedByteArray=fresh.duplicate();var changed: int=0
	for index: int in visited:
		var offset: int=index*4;var different: bool=false
		for channel: int in 4:
			if parent[offset+channel]!=fresh[offset+channel]: different=true
			inverse[offset+channel]=parent[offset+channel]
		if different:
			if not need(parent[offset]==255 and parent[offset+1]==255 and parent[offset+2]==255 and parent[offset+3]==255 and fresh[offset]==0 and fresh[offset+1]==0 and fresh[offset+2]==0 and fresh[offset+3]==255,"ONLY_WHITE_TO_BLACK_NO_ALPHA_OR_WHITE_FILL"): return {}
			changed+=1
	var digest: String=api.bytes_sha(fresh)
	if not need(inverse==parent and digest==prior.expected_child_RGBA_sha256 and changed==int(prior.changed_pixels) and visited.size()==int(prior.union_visited_pixels),"INDEPENDENT_PRIOR_FULL_RGBA_CHANGEDCOUNT_AND_WHOLE_INVERSE"): return {}
	return {"bytes":fresh,"image":Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,fresh),"proof":{"parent_rgba_sha256":api.bytes_sha(parent),"child_rgba_sha256":digest,"visited_pixels":visited.size(),"changed_pixels":changed,"only_white_to_black":true,"domain_count":4,"outside_all4_domains_exact":true,"whole_RGBA_inverse":true,"old27_or_old_routes_not_rasterized":true}}

func safe(foot: Vector2,mask: Image,solids: Array) -> bool:
	var body:=Rect2(foot-Vector2(17,12),Vector2(34,24))
	if not foot.is_finite() or not Rect2(Vector2.ZERO,SIZE).encloses(body): return false
	var polygon:=PackedVector2Array([body.position,Vector2(body.end.x,body.position.y),body.end,Vector2(body.position.x,body.end.y)])
	for solid: Dictionary in solids:
		if not closed_hit(body,solid_bounds(solid)): continue
		var other: PackedVector2Array=solid_poly(solid)
		if not Geometry2D.intersect_polygons(polygon,other).is_empty(): return false
		for i: int in 4:
			if Geometry2D.is_point_in_polygon(polygon[i],other): return false
			for j: int in other.size():
				if Geometry2D.segment_intersects_segment(polygon[i],polygon[(i+1)%4],other[j],other[(j+1)%other.size()])!=null: return false
	for y: int in range(-12,13):
		for x: int in range(-17,18):
			var pixel:=Vector2i((foot+Vector2(x,y)).round())
			if mask.get_pixelv(pixel)!=Color.WHITE: return false
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		if mask.get_pixelv(Vector2i((foot+offset).round()))!=Color.WHITE: return false
	return true
func new_paths(mask: Image,solids: Array,people: Array) -> Dictionary:
	var count: int=0;var rows: Array=[]
	for path: Dictionary in config.new_finite_paths:
		var samples: int=0
		for ordinal: int in path.points.size()-1:
			var a: Vector2=v(path.points[ordinal]);var b: Vector2=v(path.points[ordinal+1]);var steps: int=maxi(1,ceili(a.distance_to(b)/4.0))
			for i: int in range(steps+1):
				var foot: Vector2=a.lerp(b,float(i)/steps)
				if not need(safe(foot,mask,solids),"NEW_SHORT_PROP_FRONT_SIDE_BEHIND_875PLUS17:"+String(path.id)): return {}
				for npc: Dictionary in people:
					if npc.scene_id==ID and not need(not closed_hit(Rect2(foot-Vector2(17,12),Vector2(34,24)),Rect2(v(npc.foot_px)-Vector2(17,15),Vector2(34,30))),"NEW_PATH_AVOIDS_REAL4_IDLE_NPCS"): return {}
				samples+=1;count+=1
		rows.append({"id":path.id,"samples":samples,"full875_plus17":true})
	for point: Array in config.new_negative_feet:
		if not need(not safe(v(point),mask,solids),"FOUR_NEW_BODY_REJECTION_PROBES"): return {}
	return {"finite_new_paths":rows,"finite_body_samples":count,"four_negative_bodies_rejected":true,"Physics_or_Field_credit":false}

func publication() -> Dictionary:
	if not need(READY and OS.get_cmdline_user_args().is_empty() and not DirAccess.dir_exists_absolute(OUT+"native"),"HARD_FALSE_UNTIL_ROOT_AND_INDEPENDENT_PRIOR_NEW_OUTPUT"): return {}
	if not track(INPUT,INPUT_SHA): return {}
	config=json(INPUT)
	if not need(config.get("status")=="ARTISAN_LIFE_FOUR_POLYGON_ADDITIVE_BUILD_INPUT_NOTREADY" and config.get("ready")==true and config.get("independent_prior_ready")==true and config.independent_prior.sha256.length()==64,"FROZEN_INPUT_AND_PRIOR_REQUIRED_NO_OBSERVED_FILL"): return {}
	for path: String in config.source_pins:
		if not track(path,config.source_pins[path]): return {}
	if not track(config.independent_prior.path,config.independent_prior.sha256): return {}
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return {}
	api=load(config.bundle_api_path)
	if not need(api is GDScript,"EXACT_STORAGE_CODEC_ONLY_NO_VALIDATOR"): return {}
	var spec: Dictionary=json(config.author_delta.path);var author: Dictionary=json(spec.parent_author.path)
	var report: Dictionary=json(config.parent_report.path);var approval: Dictionary=json(spec.root_authorization.path)
	if not need(spec.get("status")=="ARTISAN_FOUR_LOW_PROPS_FROZEN_DESIGN_BUILD_ONLY" and spec.get("scene_id")==ID and spec.placements.size()==4 and author.scenes.size()==1 and author.scenes[0].scene_id==ID,"EXACT_ONE_DOMAIN_FOUR_SOURCE_PROPS"): return {}
	if not need(approval.get("status")=="ROOT_LIMITED_DESIGN_REVIEW_APPROVED_BUILD_ONLY_NOT_SOURCE_STAGE_OR_FORMAL" and approval.get("proposal_sha256")==spec.proposal.sha256 and approval.get("production_writes_authorized")==false,"ROOT9499_BUILD_ONLY_SCOPE"): return {}
	if not need(report.get("passed")==true and report.get("published")==true and report.get("whole_packet_inverse")==true and report.get("whole_scene_layout_inverse")==true and api.equal(report.source_first,report.source_final),"FIXED_A2_PUBLISHED_WHOLE_INVERSE_INHERITED"): return {}
	for key: String in config.parent:
		var leaf: Dictionary=config.parent[key]
		if not need(report.artifacts.get(leaf.path)==leaf.sha256,"ALL4_NATIVE_FROM_FIXED_A2_REPORT"): return {}
	var old_proof: Dictionary=report.finite_proof
	if not need(old_proof.new_visual_count==132 and old_proof.new_solid_count==27 and old_proof.new_ground_count==118 and old_proof.retained_opaque_props==14 and old_proof.all_7_routes_all4NPC_all4portals_exact==true and old_proof.native_storage_inverse==true,"A2_132_27_118_14_AND_PROTECTED_AUTHOR_DOMAINS"): return {}
	var parent: Variant=bytes_to_var(FileAccess.get_file_as_bytes(config.parent.packet.path))
	var source_scene:=ResourceLoader.load(config.parent.scene.path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var source_layout:=ResourceLoader.load(config.parent.layout.path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	var image: Image=Image.load_from_file(config.parent.walk.path)
	if image!=null: image.convert(Image.FORMAT_RGBA8)
	if not need(parent is Dictionary and api._plain(parent) and source_scene!=null and source_layout!=null and image!=null,"ONE_FIXED_PARENT_PACKET_AND_PNG_NATIVE"): return {}
	if not need(parent.get("kind")=="AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER" and parent.get("scene_id")==ID and parent.author_path==spec.parent_author.path and parent.author_sha256==spec.parent_author.sha256 and parent.solids.size()==27 and source_layout.visual_objects.size()==132 and source_layout.blockers.size()==27,"EXACT_A2_NATIVE_PARENT"): return {}
	# Native proof has integer leaves; frozen JSON report has JSON numeric leaves.
	# Keep storage and final packet inverse strictly typed; only this native/report
	# cross-format bridge uses the original symmetric JSON serialization contract.
	if not need(api.equal(api.storage(source_scene),parent.scene_storage) and api.equal(api.storage(source_layout),parent.layout_storage) and api.equal(api.storage(source_scene.map_layout),parent.layout_storage) and api.equal(api._wire(parent.a2_finite_proof),api._wire(old_proof)),"PARENT_FULL_STORAGE_AND_OLD_A2_PROOF_SYMMETRIC_JSON_BRIDGE"): return {}
	if not need(image.get_size()==Vector2i(3072,2048) and image.get_data()==parent.walk_bytes and parent.mask_sha256==config.parent_rgba_sha256 and api.bytes_sha(parent.walk_bytes)==config.parent_rgba_sha256,"PARENT_PNG_PACKET_ALL_RGBA_BA3713_EXACT"): return {}
	var rows: Array=[];var domains: Array[Rect2i]=[];var polygon_list: Array=[];var IDs: Dictionary={}
	for raw: Dictionary in spec.placements:
		if not need(not IDs.has(raw.id),"UNIQUE_NEW_IDS"): return {}
		IDs[raw.id]=true
		for old: Dictionary in source_layout.visual_objects:
			if not need(old.id!=raw.id,"NO_OLD_VISUAL_REPLACED"): return {}
		var built: Dictionary=new_placement(raw)
		if built.is_empty(): return {}
		rows.append(built);domains.append(built.domain);polygon_list.append({"id":raw.id,"points":built.polygon_json})
	if not need(api.equal(domains,declared_domains(config.local_domains_closed)),"EXACT4_SOURCE_F32_CLOSED_DOMAINS_NO_EPSILON"): return {}
	var prior: Dictionary=json(config.independent_prior.path)
	if not need(prior.get("status")=="INDEPENDENT_ARTISAN_LIFE_FOUR_POLYGON_PRIOR_NOT_RUNTIME" and prior.get("parent_rgba_sha256")==config.parent_rgba_sha256 and prior.get("whole_inverse_parent_RGBA_sha256")==config.parent_rgba_sha256 and api.equal(domains,declared_domains(prior.domains_closed)) and api.equal(polygon_list,prior.polygons),"INDEPENDENT_NATIVE_F32_PRIOR_BEFORE_PUBLISHER"): return {}
	var people: Dictionary=json(config.people_path)
	var inherited: Dictionary=inherited_clear(author,rows,domains,parent.solids,people.people)
	if inherited.is_empty(): return {}
	var delta: Dictionary=additive_mask(parent.walk_bytes,rows,domains,prior)
	if delta.is_empty(): return {}
	var solids: Array=parent.solids.duplicate(true)
	for built: Dictionary in rows: solids.append(built.solid)
	var local_audit: Dictionary=new_paths(delta.image,solids,people.people)
	if local_audit.is_empty(): return {}
	var child:=source_scene.duplicate(false) as SceneScript
	var layout:=source_layout.duplicate(false) as WalkableMapLayout
	for property: Dictionary in source_scene.get_property_list():
		if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or property.name in ["script","map_layout"]: continue
		var value: Variant=source_scene.get(property.name)
		if value is Array or value is Dictionary: child.set(property.name,value.duplicate(true))
	for property: Dictionary in source_layout.get_property_list():
		if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or property.name=="script": continue
		var value: Variant=source_layout.get(property.name)
		if value is Array or value is Dictionary: layout.set(property.name,value.duplicate(true))
	child.map_layout=layout;child.set_meta(META,config.author_delta.sha256)
	for built: Dictionary in rows:
		layout.visual_objects.append(built.visual)
		layout.blockers.append({"id":built.solid.id,"ground_polygon_world":built.solid.polygon_px.duplicate(),"walkability_margin":0.0})
	layout.walkable_mask_path=OUT+"native/walk.png"
	if not need(child!=source_scene and layout!=source_layout and layout.visual_objects.size()==136 and layout.blockers.size()==31 and api.equal(child.npcs,source_scene.npcs) and api.equal(layout.portals,source_layout.portals),"ONLY4_ADDITIVE_VISUALS_AND_REAL_BLOCKERS"): return {}
	for i: int in 132:
		if not need(api.equal(layout.visual_objects[i],source_layout.visual_objects[i]),"ORIGINAL132_ROWS_ORDER_AND_VALUES_EXACT"): return {}
	for i: int in 27:
		if not need(api.equal(layout.blockers[i],source_layout.blockers[i]) and api.equal(solids[i],parent.solids[i]),"ORIGINAL27_NATIVE_AND_PACKET_SOLIDS_EXACT"): return {}
	var scene_snapshot: Dictionary=api.storage(child);var layout_snapshot: Dictionary=api.storage(layout)
	var scene_inverse: Dictionary=scene_snapshot.duplicate(true);scene_inverse.fields.erase("metadata/"+META)
	var layout_inverse: Dictionary=layout_snapshot.duplicate(true)
	for key: String in ["visual_objects","blockers","walkable_mask_path"]: layout_inverse.fields[key]=copy(parent.layout_storage.fields[key])
	if not need(api.equal(scene_inverse,parent.scene_storage) and api.equal(layout_inverse,parent.layout_storage),"WHOLE_STORAGE_INVERSE_ONLY4_ROWS_MASKPATH_AND_NEW_META"): return {}
	var proof: Dictionary={"parent_packet_sha256":config.parent.packet.sha256,"author_delta":config.author_delta,"old_visual_count":132,"new_visual_count":136,"old_solid_count":27,"new_solid_count":31,"ground_count_unchanged":118,"low_opaque_props":18,"native_f32_polygons":polygon_list,"domains_closed":config.local_domains_closed,"local_mask":delta.proof,"inherited":inherited,"local_finite_body":local_audit,"whole_scene_layout_inverse":true,"original_a2_finite_proof_wholetyped_retained":true,"independent_prior":config.independent_prior,"Physics_Field_ART_or_runtime_credit":false}
	var packet: Dictionary=parent.duplicate(true)
	packet.scene_storage=scene_snapshot;packet.layout_storage=layout_snapshot;packet.solids=solids
	packet.mask_sha256=delta.proof.child_rgba_sha256;packet.walk_bytes=delta.bytes
	packet.life_cluster_finite_proof=proof;packet.life_parent_packet_sha256=config.parent.packet.sha256;packet.life_author_delta=config.author_delta
	var packet_inverse: Dictionary=packet.duplicate(true)
	for key: String in ["life_cluster_finite_proof","life_parent_packet_sha256","life_author_delta"]: packet_inverse.erase(key)
	for key: String in ["scene_storage","layout_storage","solids","mask_sha256","walk_bytes"]: packet_inverse[key]=copy(parent[key])
	if not need(api._plain(packet) and api.equal(packet_inverse,parent),"WHOLE_PACKET_INVERSE_KEEP_OLD_A2_AUTHOR_GEOMETRY_AND_PROOF"): return {}
	var native: String=OUT+"native/"
	if not need(DirAccess.make_dir_recursive_absolute(native)==OK and delta.image.save_png(native+"walk.png")==OK,"NEW_WALK_ONLY_OUTPUT"): return {}
	var back_image: Image=Image.load_from_file(native+"walk.png")
	if back_image!=null: back_image.convert(Image.FORMAT_RGBA8)
	if not need(back_image!=null and back_image.get_data()==delta.bytes,"WHOLE_NEW_PNG_RGBA_READBACK"): return {}
	if not need(ResourceSaver.save(layout,native+"layout.res")==OK,"NEW_LAYOUT_WRITE"): return {}
	child.map_layout=ResourceLoader.load(native+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(child.map_layout!=null and ResourceSaver.save(child,native+"scene.res")==OK,"NEW_SCENE_WRITE"): return {}
	var back:=ResourceLoader.load(native+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(back!=null and api.equal(api.storage(back),scene_snapshot) and api.equal(api.storage(back.map_layout),layout_snapshot),"WHOLE_NEW_NATIVE_STORAGE_READBACK"): return {}
	var file:=FileAccess.open(native+"packet.bin",FileAccess.WRITE)
	if not need(file!=null,"NEW_PACKET_OPEN"): return {}
	file.store_buffer(var_to_bytes(packet));file.close()
	if not need(api.equal(bytes_to_var(FileAccess.get_file_as_bytes(native+"packet.bin")),packet),"NEW_PACKET_WHOLE_READBACK"): return {}
	if not need(api.equal(api.storage(source_scene),parent.scene_storage) and api.equal(api.storage(source_layout),parent.layout_storage) and api.equal(api.storage(source_scene.map_layout),parent.layout_storage),"PARENT_RESOURCES_IMMUTABLE_AFTER_PUBLICATION"): return {}
	var artifacts: Dictionary={}
	for name: String in ["scene.res","layout.res","packet.bin","walk.png"]: artifacts[native+name]=FileAccess.get_sha256(native+name)
	var manifest: Dictionary={"status":"BUILD_ONLY_ARTISAN_LIFE_DELTA_ART_NATIVE_FIELD_SOURCE_PENDING","formal_enabled":false,"scene_id":ID,"artifacts":artifacts,"mask_sha256":packet.mask_sha256,"parent_A2":config.parent,"finite_proof":proof,"source_first":pins.duplicate(true),"old_a2_finite_proof_unchanged":true,"runtime_Family132_27_gate_not_changed":true,"outdoor_alpha_ART_and_actor_local_ghost_pending":true}
	if not need(save_json(OUT+"manifest_PENDING.json",manifest),"NONADMITTING_BUILD_MANIFEST"): return {}
	return {"published":true,"artifacts":artifacts,"finite_proof":proof,"whole_packet_inverse":true,"whole_scene_layout_inverse":true,"formal_enabled":false,"ART_Field_runtime_source_pending":true}
func run() -> void:
	began=Time.get_ticks_msec()
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform!=null and platform.has_method("set_checkpoint_saves_suspended"): platform.call("set_checkpoint_saves_suspended",true)
	var result: Dictionary=publication();var final: Dictionary={}
	for path: String in pins:
		final[path]=FileAccess.get_sha256(path);need(final[path]==pins[path],"SOURCE_FINAL:"+path)
	need(Time.get_ticks_msec()-began<LIMIT_MS,"FIXED60S_BUILD_CAP")
	result.merge({"passed":failure.is_empty() and result.get("published",false),"error":failure,"checks":checks,"elapsed_ms":Time.get_ticks_msec()-began,"source_first":pins,"source_final":final,"scope":"FOUR_ADDITIVE_LOW_PROP_POLYGONS_ONLY_NOT_FORMAL_ART_OR_FIELD","old_geometry_recompile_fullraster_collector_Physics_Field_import_calls":0},true)
	var report: String=OUT+"runs/"+str(OS.get_process_id())+"_"+str(began)+"/result.json"
	if not save_json(report,result): print("LIFE_REPORT_WRITE_FAILED:"+report);quit(1);return
	print(JSON.stringify({"passed":result.passed,"error":failure,"path":report}));quit(0 if result.passed else 1)

