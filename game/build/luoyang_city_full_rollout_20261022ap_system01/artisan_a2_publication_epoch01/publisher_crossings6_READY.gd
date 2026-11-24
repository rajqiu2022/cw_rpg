extends SceneTree
## Root-only one-domain finite publisher. No C.compile/audit, full raster,
## collector, Physics, Field, import, actor spawning or runtime admission.
const READY=true
const INPUT="res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/input_crossings6_READY.json"
const INPUT_SHA="68a754894f570ea74e0dd617b8a03454fa5e76fb0c53f1182616d14d8c9589e1"
const OUT="res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_a2_publication_epoch01/output_crossings6/"
const SIZE=Vector2(3072,2048)
const ID="luoyang_artisan_residential_20261022ap"
const META="luoyang_full_city_AP"
const LIMIT_MS=60000
var api: Variant
var config: Dictionary={}
var pins: Dictionary={}
var checks: int=0
var failure: String=""
var began: int=0

func _initialize() -> void: call_deferred("run")
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok and failure.is_empty(): failure=label;push_error("ARTISAN_A2_FINITE:"+label)
	return ok
func track(p: String,pin: String) -> bool:
	var actual: String=FileAccess.get_sha256(p)
	if not need(p.begins_with("res://") and not ".." in p and pin.length()==64 and actual==pin and (not pins.has(p) or pins[p]==pin),"SOURCE:"+p): return false
	pins[p]=pin;return true
func json(p: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(p))
	return value if value is Dictionary else {}
func save_json(p: String,value: Dictionary) -> bool:
	if FileAccess.file_exists(p) or DirAccess.make_dir_recursive_absolute(p.get_base_dir())!=OK: return false
	var file:=FileAccess.open(p,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true));file.close();return true
func v(raw: Variant) -> Vector2:
	if raw is Vector2: return raw
	if not raw is Array or raw.size()!=2: return Vector2(INF,INF)
	for x: Variant in raw:
		if typeof(x) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(x)): return Vector2(INF,INF)
	return Vector2(raw[0],raw[1])
func rect(raw: Array) -> Rect2: return Rect2(raw[0],raw[1],raw[2],raw[3])
func bounds(poly: PackedVector2Array) -> Rect2:
	var lo:=Vector2(INF,INF);var hi:=Vector2(-INF,-INF)
	for p: Vector2 in poly: lo=lo.min(p);hi=hi.max(p)
	return Rect2(lo,hi-lo)
func solid_bounds(row: Dictionary) -> Rect2:
	return bounds(row.polygon_px) if row.has("polygon_px") else rect(row.rect_px)
func solid_poly(row: Dictionary) -> PackedVector2Array:
	if row.has("polygon_px"): return row.polygon_px
	var r: Rect2=rect(row.rect_px)
	return PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
func closed_hit(a: Rect2,b: Rect2) -> bool:
	return a.position.x<=b.end.x and b.position.x<=a.end.x and a.position.y<=b.end.y and b.position.y<=a.end.y
func guarded_domain(row: Dictionary) -> Rect2i:
	var r: Rect2=solid_bounds(row)
	var lo:=Vector2i(floori(r.position.x)-1,floori(r.position.y)-1)
	var hi:=Vector2i(ceili(r.end.x)+1,ceili(r.end.y)+1)
	return Rect2i(lo,hi-lo+Vector2i.ONE)

func placement(row: Dictionary,asset: Dictionary) -> Dictionary:
	var scale_value: float=float(row.width)/float(asset.used_rect[2])
	var foot: Vector2=v(row.foot);var anchor: Vector2=v(asset.ground_anchor)
	var used: Rect2=rect(asset.used_rect)
	var alpha:=Rect2(foot+(used.position-anchor)*scale_value,used.size*scale_value)
	if not need(Rect2(Vector2.ZERO,SIZE).encloses(alpha) and asset.get("support_rects",[]).is_empty(),"FULL_UNCHANGED_SOURCE_DOMAIN:"+row.id): return {}
	var solids: Array[Dictionary]=[]
	for i: int in asset.get("solid_rects",[]).size():
		var raw: Array=asset.solid_rects[i]
		var area:=Rect2(foot+(rect(raw).position-anchor)*scale_value,rect(raw).size*scale_value)
		solids.append({"id":String(row.id)+"_base_"+str(i),"rect_px":[area.position.x,area.position.y,area.size.x,area.size.y],"asset":row.asset,"source_rect":raw.duplicate()})
	for i: int in asset.get("solid_polygons",[]).size():
		var original: Array=asset.solid_polygons[i];var poly:=PackedVector2Array()
		for raw: Array in original: poly.append(foot+(v(raw)-anchor)*scale_value)
		if not need(poly.size()>=3 and not Geometry2D.triangulate_polygon(poly).is_empty(),"REAL_SOURCE_POLYGON:"+row.id): return {}
		solids.append({"id":String(row.id)+"_hull_"+str(i),"polygon_px":poly,"asset":row.asset,"source_polygon":original.duplicate(true)})
	var visual: Dictionary={"id":row.id,"texture":asset.texture,"pos":(foot+(v(asset.source_size)*.5-anchor)*scale_value)/SIZE,"render_size_px":v(asset.source_size)*scale_value,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/SIZE.y}
	return {"visual":visual,"solids":solids,"alpha":alpha}
func tiles(section: Dictionary,asset: Dictionary) -> Array[Dictionary]:
	var output: Array[Dictionary]=[]
	var area: Rect2=rect(section.rect);var tile: Vector2=v(section.tile_size);var source_size: Vector2=v(asset.source_size)
	if not need(Rect2(Vector2.ZERO,SIZE).encloses(area) and tile.x>0 and tile.y>0 and tile.x/source_size.x==tile.y/source_size.y,"UNIFORM_SECTION:"+section.id): return output
	var scale_value: float=tile.x/source_size.x
	for yi: int in ceili(area.size.y/tile.y):
		for xi: int in ceili(area.size.x/tile.x):
			var offset:=Vector2(xi,yi)*tile;var shown: Vector2=(area.size-offset).min(tile)
			var texture: String=asset.texture
			if shown!=tile:
				var crop: Vector2=shown/scale_value
				if not need(crop.x==floorf(crop.x) and crop.y==floorf(crop.y),"INTEGER_ATLAS_SOURCE_REGION"): return []
				texture=String(section.clip_textures.get(str(int(crop.x))+"x"+str(int(crop.y)),""))
				if not need(config.source_pins.has(texture),"EXACT_ATLAS_DECLARED:"+texture): return []
				var edge:=ResourceLoader.load(texture,"",ResourceLoader.CACHE_MODE_REUSE) as AtlasTexture
				if not need(edge!=null and edge.atlas!=null and edge.atlas.resource_path==asset.texture and edge.region==Rect2(Vector2.ZERO,crop) and edge.margin==Rect2(),"WHOLE_EXISTING_TEXTURE_ATLAS_NO_PIXEL_EDIT:"+texture): return []
			output.append({"id":String(section.id)+"_"+str(xi)+"_"+str(yi),"texture":texture,"pos":(area.position+offset+shown*.5)/SIZE,"render_size_px":shown,"centered":true,"sort_by_feet":false,"z_index":int(section.z)})
	return output
func expand(author: Dictionary) -> Dictionary:
	if not need(author.scenes.size()==1 and author.scenes[0].scene_id==ID,"ONE_ARTISAN_AUTHOR"): return {}
	var scene: Dictionary=author.scenes[0];var visuals: Array[Dictionary]=[];var solids: Array[Dictionary]=[];var boxes: Dictionary={};var ground_count: int=0
	for section: Dictionary in scene.ground_sections:
		var rows: Array[Dictionary]=tiles(section,author.assets[section.asset])
		if rows.is_empty(): return {}
		visuals.append_array(rows);ground_count+=rows.size()
	for row: Dictionary in scene.placements:
		var built: Dictionary=placement(row,author.assets[row.asset])
		if built.is_empty(): return {}
		visuals.append(built.visual);solids.append_array(built.solids);boxes[row.id]=built.alpha
	return {"visuals":visuals,"solids":solids,"boxes":boxes,"ground_count":ground_count}

func contains_pixel(row: Dictionary,p: Vector2i) -> bool:
	if row.has("polygon_px"):
		# Preserve original paint_polygon floor(low)..ceil(high) inclusive domain.
		var b: Rect2=bounds(row.polygon_px)
		if p.x<floori(b.position.x) or p.y<floori(b.position.y) or p.x>ceili(b.end.x) or p.y>ceili(b.end.y): return false
		return Geometry2D.is_point_in_polygon(Vector2(p),row.polygon_px)
	var r: Rect2=rect(row.rect_px)
	return p.x>=ceili(r.position.x) and p.x<=floori(r.end.x) and p.y>=ceili(r.position.y) and p.y<=floori(r.end.y)
func finite_mask(old: PackedByteArray,solids: Array,walk: Rect2i,domains: Array[Rect2i],expected: Dictionary) -> Dictionary:
	var fresh: PackedByteArray=old.duplicate();var visited: Dictionary={}
	for area: Rect2i in domains:
		if not need(Rect2i(0,0,3072,2048).encloses(area),"LOCAL_DOMAIN_IN_WORLD"): return {}
		for y: int in range(area.position.y,area.end.y):
			for x: int in range(area.position.x,area.end.x):
				var index: int=y*3072+x
				if visited.has(index): continue
				visited[index]=true
				var point:=Vector2i(x,y);var white: bool=walk.has_point(point)
				if white:
					for solid: Dictionary in solids:
						if contains_pixel(solid,point): white=false;break
				var offset: int=index*4;var value: int=255 if white else 0
				fresh[offset]=value;fresh[offset+1]=value;fresh[offset+2]=value;fresh[offset+3]=255
	var inverse: PackedByteArray=fresh.duplicate();var changed: int=0
	for index: int in visited:
		var offset: int=index*4;var different: bool=false
		for channel: int in 4:
			if fresh[offset+channel]!=old[offset+channel]: different=true
			inverse[offset+channel]=old[offset+channel]
		if different: changed+=1
	var digest: String=api.bytes_sha(fresh)
	if not need(inverse==old and digest==expected.expected_child_RGBA_sha256 and changed==int(expected.changed_pixels) and visited.size()==int(expected.union_visited_pixels),"INDEPENDENT_PREDECLARED_FULL_RGBA_CHANGEDCOUNT_AND_8DOMAIN_INVERSE"): return {}
	var image:=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,fresh)
	return {"image":image,"bytes":fresh,"proof":{"parent_rgba_sha256":api.bytes_sha(old),"child_rgba_sha256":digest,"visited_pixels":visited.size(),"changed_pixels":changed,"domain_count":domains.size(),"whole_RGBA_inverse":true,"outside_eight_guarded_domains_exact":true,"pixel_rebuilt_from_original_walkrect_and_ALL27_source_solids":true,"blind_white_fill":false}}

func safe(foot: Vector2,mask: Image,solids: Array,npc: bool=false) -> bool:
	var half:=Vector2(17,15 if npc else 12);var r:=Rect2(foot-half,half*2)
	if not foot.is_finite() or r.position.x<0 or r.position.y<0 or roundi(r.end.x)>=3072 or roundi(r.end.y)>=2048: return false
	var body:=PackedVector2Array([r.position,Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])
	for solid: Dictionary in solids:
		if closed_hit(r,solid_bounds(solid)):
			var poly: PackedVector2Array=solid_poly(solid)
			if not Geometry2D.intersect_polygons(body,poly).is_empty(): return false
			for a: int in 4:
				if Geometry2D.is_point_in_polygon(body[a],poly): return false
				for b: int in poly.size():
					if Geometry2D.segment_intersects_segment(body[a],body[(a+1)%4],poly[b],poly[(b+1)%poly.size()])!=null: return false
	for y: int in range(-15 if npc else -12,16 if npc else 13):
		for x: int in range(-17,18):
			var point:=Vector2i((foot+Vector2(x,y)).round());var color: Color=mask.get_pixelv(point)
			if color.r<.5 or color.a<.5: return false
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		var color: Color=mask.get_pixelv(Vector2i((foot+offset).round()))
		if color.r<.5 or color.a<.5: return false
	return true
func finite_audit(before: Dictionary,after: Dictionary,mask: Image,solids: Array,domains: Array[Rect2i],people: Array) -> Dictionary:
	if not need(api.equal(before.routes,after.routes) and api.equal(before.portals,after.portals) and v(before.spawn)==v(after.spawn),"SEVEN_ROUTES_AND_FOUR_PORTALS_AND_SPAWN_EXACT"): return {}
	var inherited: Array=[];var affected: Array=[];var finite: Array=[];var samples: int=0
	for route: Dictionary in after.routes:
		for ordinal: int in route.points.size()-1:
			var a: Vector2=v(route.points[ordinal]);var b: Vector2=v(route.points[ordinal+1]);var selected: bool=false
			var sweep:=Rect2(a.min(b)-Vector2(17,12),a.max(b)-a.min(b)+Vector2(34,24))
			for domain: Rect2i in domains:
				if closed_hit(sweep,Rect2(Vector2(domain.position),Vector2(domain.size))): selected=true
			if not selected: inherited.append({"id":route.id,"segment":ordinal});continue
			affected.append({"id":route.id,"segment":ordinal})
			var steps: int=maxi(1,ceili(a.distance_to(b)/4.0))
			for i: int in range(steps+1):
				var foot: Vector2=a.lerp(b,float(i)/steps);var local: bool=false
				for domain: Rect2i in domains:
					if closed_hit(Rect2(foot-Vector2(17,12),Vector2(34,24)),Rect2(Vector2(domain.position),Vector2(domain.size))): local=true
				if local:
					samples+=1
					if not need(safe(foot,mask,solids),"AFFECTED_ORIGINAL_87517:"+route.id): return {}
	for row: Dictionary in config.new_finite_paths:
		var count: int=0
		for segment: int in row.points.size()-1:
			var a: Vector2=v(row.points[segment]);var b: Vector2=v(row.points[segment+1]);var steps: int=maxi(1,ceili(a.distance_to(b)/4.0))
			for i: int in range(steps+1):
				var foot: Vector2=a.lerp(b,float(i)/steps)
				if not need(safe(foot,mask,solids),"NEW_FINITE_87517:"+row.id): return {}
				for person: Dictionary in people:
					if person.scene_id!=ID: continue
					if not need(not closed_hit(Rect2(foot-Vector2(17,12),Vector2(34,24)),Rect2(v(person.foot_px)-Vector2(17,15),Vector2(34,30))),"NEW_PATH_AVOIDS_FOUR_REAL_IDLE_PEOPLE"): return {}
				count+=1;samples+=1
		finite.append({"id":row.id,"samples":count,"full875_plus17":true})
	for p: Array in config.new_negative_feet:
		if not need(not safe(v(p),mask,solids),"NEW_RACK_NEGATIVE_FULL_BODY_REJECTS"): return {}
	var idle_inherited: Array=[]
	for person: Dictionary in people:
		if person.scene_id!=ID: continue
		for field: String in ["foot_px","approach_px"]:
			var half:=Vector2(17,15 if field=="foot_px" else 12);var body:=Rect2(v(person[field])-half,half*2)
			for domain: Rect2i in domains:
				if not need(not closed_hit(body,Rect2(Vector2(domain.position),Vector2(domain.size))),"UNCHANGED_PEOPLE_OR_APPROACH_OUTSIDE_DELTA"): return {}
		idle_inherited.append({"id":person.npc_id,"foot":person.foot_px,"approach":person.approach_px,"idle_only":true})
	for portal: Dictionary in after.portals:
		for dy: float in [0.0,10.0,24.0]:
			var body:=Rect2(v(portal.foot)+Vector2(0,dy)-Vector2(17,12),Vector2(34,24))
			for domain: Rect2i in domains:
				if not need(not closed_hit(body,Rect2(Vector2(domain.position),Vector2(domain.size))),"UNCHANGED_PORTAL_FOOT_PLUS10_PLUS24_OUTSIDE_DELTA"): return {}
	return {"passed":true,"inherited_original_segments":inherited,"affected_original_segments":affected,"finite_new_paths":finite,"finite_body_samples":samples,"four_idle_people_and_approaches_inherited":idle_inherited,"five_adult_door_measurements_inherited":true,"not_whole_scene_route_replay":true,"Physics_or_Field_credit":false}

func publication() -> Dictionary:
	if not need(READY and OS.get_cmdline_user_args().is_empty() and not DirAccess.dir_exists_absolute(OUT+"native"),"ROOT_ONLY_READY_NEW_OUTPUT_NO_FLAGS"): return {}
	if not track(INPUT,INPUT_SHA): return {}
	config=json(INPUT)
	if not need(config.get("status")=="FROZEN_ARTISAN_A2_FINITE_LOCAL_PUBLICATION_ROOT_ONLY","EXACT_A2_INPUT_KIND"): return {}
	for p: String in config.source_pins:
		if not track(p,config.source_pins[p]): return {}
	if not track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)): return {}
	api=load(config.bundle_api_path)
	if not need(api is GDScript,"PINNED_STORAGE_CODEC_ONLY"): return {}
	var before: Dictionary=json(config.parent_author);var after: Dictionary=json(config.author)
	var old: Dictionary=expand(before);var fresh: Dictionary=expand(after)
	if not need(not old.is_empty() and not fresh.is_empty() and old.visuals.size()==106 and old.solids.size()==33 and fresh.visuals.size()==132 and fresh.ground_count==118 and fresh.solids.size()==27,"EXACT_SOURCE_106_33_TO132_27"): return {}
	if not need(before.adult_doors==after.adult_doors and after.scenes[0].water_regions.is_empty(),"FIVE_ADULT_DOORS_AND_NO_WATER_SUPPORT_CHANGE"): return {}
	var parent: Variant=bytes_to_var(FileAccess.get_file_as_bytes(config.parent_packet))
	var source_scene:=ResourceLoader.load(config.parent_scene,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var source_layout:=ResourceLoader.load(config.parent_layout,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	var png:=Image.load_from_file(config.parent_walk)
	if png!=null: png.convert(Image.FORMAT_RGBA8)
	if not need(parent is Dictionary and api._plain(parent) and source_scene!=null and source_layout!=null and png!=null,"FROZEN_53624_NATIVE_AND_ONE_PARENT_RGBA"): return {}
	if not need(api.equal(api.storage(source_scene),parent.scene_storage) and api.equal(api.storage(source_layout),parent.layout_storage) and api.equal(api.storage(source_scene.map_layout),parent.layout_storage) and api.equal(source_layout.visual_objects,old.visuals) and api.equal(parent.solids,old.solids),"WHOLE_PARENT_STORAGE_AND_ALL106_ROWS_ALL33_SOURCE_SOLIDS"): return {}
	if not need(png.get_size()==Vector2i(3072,2048) and png.get_data()==parent.walk_bytes and api.bytes_sha(parent.walk_bytes)==config.parent_rgba_sha256 and parent.mask_sha256==config.parent_rgba_sha256,"WHOLE_PARENT_PNG_PACKET_RGBA_EXACT"): return {}
	var oldmap: Dictionary={};var newmap: Dictionary={};var domains: Array[Rect2i]=[];var changes: Array=[]
	for row: Dictionary in old.solids: oldmap[row.id]=row
	for row: Dictionary in fresh.solids: newmap[row.id]=row
	var union: Dictionary=oldmap.duplicate()
	for key: String in newmap: union[key]=true
	var ordered: Array=union.keys();ordered.sort()
	for key: String in ordered:
		if oldmap.has(key) and newmap.has(key) and api.equal(oldmap[key],newmap[key]): continue
		if not need(key in config.allowed_changed_solid_ids,"ONLY_SEVEN_DECLARED_SOLID_IDS:"+key): return {}
		changes.append(key)
		if oldmap.has(key): domains.append(guarded_domain(oldmap[key]))
		if newmap.has(key): domains.append(guarded_domain(newmap[key]))
	var expected_domains: Array[Rect2i]=[]
	for row: Array in config.local_domains_xywh: expected_domains.append(Rect2i(int(row[0]),int(row[1]),int(row[2]),int(row[3])))
	if not need(changes.size()==7 and domains.size()==8 and api.equal(domains,expected_domains),"EXACT_8_SOURCE_DERIVED_LOCAL_DOMAINS_NO_EPSILON"): return {}
	var rack: Dictionary=newmap["ap_cloth_rack_v2_hull_0"]
	for row: Dictionary in fresh.solids:
		if row.id!=rack.id and not need(not closed_hit(solid_bounds(row),solid_bounds(rack)),"NEW_RACK_AABB_CLEAR_OF_ALL_RETAINED_BODIES"): return {}
	var ids: Array=fresh.boxes.keys()
	for i: int in ids.size():
		for j: int in range(i+1,ids.size()):
			if not need(not fresh.boxes[ids[i]].intersects(fresh.boxes[ids[j]],true),"ALL14_FULL_ALPHA_BOUNDS_DISJOINT"): return {}
	var oracle: Dictionary=json(config.independent_expectation_path)
	if not need(oracle.get("status")=="FROZEN_INDEPENDENT_SOURCE_ABI_PRIOR_ONLY_NOT_PUBLISHER_NATIVE_FIELD_OR_ART_ADMISSION" and oracle.prior_mask.original_RGBA_sha256==config.parent_rgba_sha256 and oracle.prior_mask.whole_inverse_RGBA_sha256==config.parent_rgba_sha256 and oracle.prior_mask.old_eight_domains_RGBA_diff==0,"INDEPENDENT_PRIOR_IDENTITY"): return {}
	var delta: Dictionary=finite_mask(parent.walk_bytes,fresh.solids,Rect2i(rect(after.scenes[0].walk_rect)),domains,oracle.prior_mask)
	if delta.is_empty(): return {}
	var people: Dictionary=json(config.people_path)
	var audit: Dictionary=finite_audit(before.scenes[0],after.scenes[0],delta.image,fresh.solids,domains,people.people)
	if audit.is_empty(): return {}
	var child:=source_scene.duplicate(false) as SceneScript;var layout:=source_layout.duplicate(false) as WalkableMapLayout
	for prop: Dictionary in source_scene.get_property_list():
		if (int(prop.usage)&PROPERTY_USAGE_STORAGE)==0 or prop.name in ["script","map_layout"]: continue
		var value: Variant=source_scene.get(prop.name)
		if value is Array or value is Dictionary: child.set(prop.name,value.duplicate(true))
	for prop: Dictionary in source_layout.get_property_list():
		if (int(prop.usage)&PROPERTY_USAGE_STORAGE)==0 or prop.name=="script": continue
		var value: Variant=source_layout.get(prop.name)
		if value is Array or value is Dictionary: layout.set(prop.name,value.duplicate(true))
	child.map_layout=layout;child.set_meta(META,config.source_pins[config.author])
	layout.visual_objects=fresh.visuals.duplicate(true)
	var retained_blockers: Array[Dictionary]=[]
	for row: Dictionary in source_layout.blockers:
		if not newmap.has(row.id): continue
		var copy: Dictionary=row.duplicate(true)
		if row.id=="ap_cloth_rack_v2_hull_0": copy.ground_polygon_world=rack.polygon_px.duplicate()
		retained_blockers.append(copy)
	layout.blockers=retained_blockers;layout.walkable_mask_path=OUT+"native/walk.png"
	if not need(layout.blockers.size()==27 and child!=source_scene and layout!=source_layout and api.equal(child.npcs,source_scene.npcs),"ISOLATED_CHILD_27_WITH_ALL4_NPCS_EXACT"): return {}
	var scene_snapshot: Dictionary=api.storage(child);var layout_snapshot: Dictionary=api.storage(layout)
	var inverse_scene: Dictionary=scene_snapshot.duplicate(true);inverse_scene.fields["metadata/"+META]=parent.scene_storage.fields["metadata/"+META]
	var inverse_layout: Dictionary=layout_snapshot.duplicate(true)
	for key: String in ["visual_objects","blockers","walkable_mask_path"]: inverse_layout.fields[key]=parent.layout_storage.fields[key].duplicate(true) if parent.layout_storage.fields[key] is Array else parent.layout_storage.fields[key]
	if not need(api.equal(inverse_scene,parent.scene_storage) and api.equal(inverse_layout,parent.layout_storage),"COMPLETE_NATIVE_STORAGE_INVERSE_ONLY_DECLARED_FIELDS"): return {}
	var proof: Dictionary={"body":[34,24],"full875_plus17_finite":audit,"local_mask":delta.proof,"changed_solid_ids":changes,"old_visual_count":106,"new_visual_count":132,"new_ground_count":118,"retained_opaque_props":14,"old_solid_count":33,"new_solid_count":27,"all_7_routes_all4NPC_all4portals_exact":true,"native_storage_inverse":true,"no_C_compile_or_full_raster_or_collectors":true,"independent_expectation":{"path":config.independent_expectation_path,"sha256":config.source_pins[config.independent_expectation_path]}}
	var packet: Dictionary=parent.duplicate(true)
	packet.author_path=config.author;packet.author_sha256=config.source_pins[config.author];packet.scene_storage=scene_snapshot;packet.layout_storage=layout_snapshot;packet.solids=fresh.solids.duplicate(true);packet.mask_sha256=delta.proof.child_rgba_sha256;packet.walk_bytes=delta.bytes;packet.geometry=audit;packet.parent_packet_sha256=config.source_pins[config.parent_packet];packet.parent_whole_inverse={"scene":true,"layout":true,"finite_delta":true};packet.local_mask_inverse=delta.proof
	packet["a2_finite_proof"]=proof
	var packet_inverse: Dictionary=packet.duplicate(true);packet_inverse.erase("a2_finite_proof")
	for key: String in ["author_path","author_sha256","scene_storage","layout_storage","solids","mask_sha256","walk_bytes","geometry","parent_packet_sha256","parent_whole_inverse","local_mask_inverse"]: packet_inverse[key]=parent[key].duplicate(true) if parent[key] is Array or parent[key] is Dictionary else parent[key]
	if not need(api._plain(packet) and api.equal(packet_inverse,parent),"WHOLE_PACKET_INVERSE_ALL_UNLISTED_FIELDS_EXACT"): return {}
	var directory: String=OUT+"native/"
	if not need(DirAccess.make_dir_recursive_absolute(directory)==OK and delta.image.save_png(directory+"walk.png")==OK,"NEW_NATIVE_BUILD_AND_WALK_WRITE"): return {}
	var mask_back:=Image.load_from_file(directory+"walk.png")
	if mask_back!=null: mask_back.convert(Image.FORMAT_RGBA8)
	if not need(mask_back!=null and mask_back.get_data()==delta.bytes,"NEW_MASK_FULL_RGBA_READBACK"): return {}
	if not need(ResourceSaver.save(layout,directory+"layout.res")==OK,"NEW_LAYOUT_WRITE"): return {}
	child.map_layout=ResourceLoader.load(directory+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if not need(child.map_layout!=null and ResourceSaver.save(child,directory+"scene.res")==OK,"NEW_SCENE_WRITE"): return {}
	var readback:=ResourceLoader.load(directory+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not need(readback!=null and api.equal(api.storage(readback),scene_snapshot) and api.equal(api.storage(readback.map_layout),layout_snapshot),"COMPLETE_NEW_NATIVE_STORAGE_READBACK"): return {}
	var file:=FileAccess.open(directory+"packet.bin",FileAccess.WRITE)
	if not need(file!=null,"NEW_PACKET_OPEN"): return {}
	file.store_buffer(var_to_bytes(packet));file.close()
	if not need(api.equal(bytes_to_var(FileAccess.get_file_as_bytes(directory+"packet.bin")),packet),"COMPLETE_PACKET_READBACK"): return {}
	if not need(api.equal(api.storage(source_scene),parent.scene_storage) and api.equal(api.storage(source_layout),parent.layout_storage) and api.equal(api.storage(source_scene.map_layout),parent.layout_storage),"PARENT_RESOURCES_IMMUTABLE_AFTER_CHILD_WRITE"): return {}
	var artifacts: Dictionary={}
	for name: String in ["layout.res","scene.res","packet.bin","walk.png"]: artifacts[directory+name]=FileAccess.get_sha256(directory+name)
	var manifest: Dictionary={"status":"BUILD_ONLY_A2_NATIVE_MASK_MATERIAL_ART_AND_RUNTIME_PENDING","formal_enabled":false,"scene_id":ID,"author_path":config.author,"author_sha256":config.source_pins[config.author],"artifacts":artifacts,"mask_sha256":packet.mask_sha256,"parent_publication":{"path":config.parent_report,"sha256":config.source_pins[config.parent_report]},"finite_proof":proof,"fixed_input":{"path":INPUT,"sha256":INPUT_SHA},"material_profiles":after.a2_ground_profiles,"runtime_source_closure_pending":true,"outdoor_ART_pending":true,"Physics_or_Field_pending":true,"source_first":pins.duplicate(true)}
	if not need(save_json(OUT+"manifest_PENDING.json",manifest),"BUILD_ONLY_NON_ADMITTING_MANIFEST"): return {}
	return {"published":true,"artifacts":artifacts,"finite_proof":proof,"whole_packet_inverse":true,"whole_scene_layout_inverse":true,"scene_NPC_portals_inherited":true,"outdoor_ART_pending":true,"manifest_path":OUT+"manifest_PENDING.json"}

func run() -> void:
	began=Time.get_ticks_msec()
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform!=null and platform.has_method("set_checkpoint_saves_suspended"): platform.call("set_checkpoint_saves_suspended",true)
	var result: Dictionary=publication();var final: Dictionary={}
	for p: String in pins:
		final[p]=FileAccess.get_sha256(p);need(final[p]==pins[p],"SOURCE_FINAL:"+p)
	need(Time.get_ticks_msec()-began<LIMIT_MS,"FIXED_60S_LIMIT")
	result.merge({"passed":failure.is_empty() and result.get("published",false),"error":failure,"checks":checks,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"source_first":pins,"source_final":final,"scope":"ARTISAN_A2_FINITE_EIGHT_DOMAIN_BUILD_ONLY_NOT_ART_RUNTIME_OR_FIELD","C_compile_fullraster_collectors_Physics_calls":0},true)
	var report: String=OUT+"runs/"+str(OS.get_process_id())+"_"+str(began)+"/result.json"
	if not save_json(report,result): print("A2_REPORT_WRITE_FAILED:"+report);quit(1);return
	print(JSON.stringify({"passed":result.passed,"error":failure,"path":report}));quit(0 if result.passed else 1)
