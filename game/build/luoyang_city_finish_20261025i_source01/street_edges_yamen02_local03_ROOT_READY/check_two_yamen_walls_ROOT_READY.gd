extends SceneTree
## Root-only two fixed Yamen wall domains. No Scene/Field/ResourceLoader/old raster.
const READY: bool=true
const INPUT: String="res://build/luoyang_city_finish_20261025i_source01/street_edges_yamen02_local03_ROOT_READY/input_ROOT_READY.json"
const INPUT_SHA: String="da531695ae5a6f8123702ddd3f28b60cbae5cfaebf914acffe2ad85524ce435a"
const SELF: String="res://build/luoyang_city_finish_20261025i_source01/street_edges_yamen02_local03_ROOT_READY/check_two_yamen_walls_ROOT_READY.gd"
const GAME_ROOT: String="F:/Code/RPG_GAME/game/"
const SIZE: Vector2=Vector2(3072,2048)
const LOTS: Array[String]=["EDGE04_YAMEN_WEST_ARCHIVE_COMPOUND","EDGE04_YAMEN_EAST_RUNNER_COMPOUND"]
var config: Dictionary={}
var checks: int=0
var errors: Array[String]=[]
var first: Dictionary={}
var saves: Dictionary={}
var began: int=0
var pixel_queries: int=0
var affected_route_legs: int=0
func _initialize() -> void: call_deferred("run")
func physical(path: String) -> String: return GAME_ROOT+path.trim_prefix("res://") if path.begins_with("res://") else path
func sha(raw: PackedByteArray) -> String:
	var context: HashingContext=HashingContext.new();context.start(HashingContext.HASH_SHA256);context.update(raw);return context.finish().hex_encode()
func same(a: Variant,b: Variant) -> bool: return var_to_bytes(a)==var_to_bytes(b)
func vec(value: Array) -> Vector2: return Vector2(float(value[0]),float(value[1]))
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label);printerr("STREET4_FAIL ",label)
	return ok
func facts(paths: Array) -> Dictionary:
	var result: Dictionary={}
	for path: String in paths:
		if not FileAccess.file_exists(physical(path)): result[path]={"exists":false};continue
		var file: FileAccess=FileAccess.open(physical(path),FileAccess.READ)
		result[path]={"exists":true,"sha256":FileAccess.get_sha256(physical(path)),"bytes":file.get_length(),"mtime_seconds":FileAccess.get_modified_time(physical(path))};file.close()
	return result
func json_file(path: String) -> Dictionary:
	var result: Variant=JSON.parse_string(FileAccess.get_file_as_string(physical(path)))
	return result if result is Dictionary else {}
func write_new(path: String,bytes: PackedByteArray) -> Dictionary:
	if not check(not FileAccess.file_exists(physical(path)),"ABSENT_NEW_OUTPUT:"+path): return {}
	var file: FileAccess=FileAccess.open(physical(path),FileAccess.WRITE)
	if not check(file!=null,"WRITE_NEW_OUTPUT:"+path): return {}
	file.store_buffer(bytes);file.close();return {"path":path,"sha256":sha(bytes),"bytes":bytes.size()}
func xyxy(poly: PackedVector2Array) -> Array:
	var low: Vector2=poly[0];var high: Vector2=poly[0]
	for point: Vector2 in poly: low=low.min(point);high=high.max(point)
	return [low.x,low.y,high.x,high.y]
func rectangle(raw: Array) -> PackedVector2Array:
	return PackedVector2Array([Vector2(raw[0],raw[1]),Vector2(raw[2],raw[1]),Vector2(raw[2],raw[3]),Vector2(raw[0],raw[3])])
func boxes_intersect(a: Array,b: Array,closed: bool=false) -> bool:
	return maxf(a[0],b[0])<=minf(a[2],b[2]) and maxf(a[1],b[1])<=minf(a[3],b[3]) if closed else maxf(a[0],b[0])<minf(a[2],b[2]) and maxf(a[1],b[1])<minf(a[3],b[3])
func segment_hits_box(a: Vector2,b: Vector2,raw: Array,half: Vector2) -> bool:
	# Continuous whole-body segment vs exact closed axis-aligned new wall base.
	var low: Vector2=Vector2(raw[0],raw[1])-half;var high: Vector2=Vector2(raw[2],raw[3])+half
	var delta: Vector2=b-a;var t0: float=0.0;var t1: float=1.0
	for axis: int in range(2):
		if delta[axis]==0.0:
			if a[axis]<low[axis] or a[axis]>high[axis]: return false
		else:
			var enter: float=(float(low[axis])-a[axis])/delta[axis];var leave: float=(float(high[axis])-a[axis])/delta[axis]
			if enter>leave:
				var swap: float=enter
				enter=leave;leave=swap
			t0=maxf(t0,enter);t1=minf(t1,leave)
			if t0>t1: return false
	return true
func project(lot: Dictionary) -> Dictionary:
	var asset: Dictionary=lot.source_asset;var ratio: float=float(lot.uniform_scale);var foot: Vector2=vec(lot.foot_px);var anchor: Vector2=vec(asset.source_ground_anchor_px)
	var points: PackedVector2Array=[]
	for raw_point: Array in asset.true_ground_polygon_px: points.append(foot+(vec(raw_point)-anchor)*ratio)
	var expected_points: PackedVector2Array=[]
	for expected_point: Array in lot.new_ground_polygon_world_f32: expected_points.append(vec(expected_point))
	check(same(points,expected_points),"EXACT_SOURCE_F32_BASE:"+String(lot.lot_id))
	var render_size: Vector2=vec(asset.source_size_px)*ratio;var top: Vector2=foot-anchor*ratio
	var row: Dictionary={"id":String(lot.candidate_render_row.id),"texture":String(asset.texture),"source_sha256":String(asset.source_sha256),"pos":(top+render_size*.5)/SIZE,"render_size_px":render_size,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/2048.0,"world_foot_px":foot,"physical_center_px":foot,"collision_size_px":Vector2.ZERO,"blocking":true,"city_v3_solid_polygons_px":[points]}
	var expected_row: Dictionary=lot.candidate_render_row.duplicate(true)
	for key: String in ["pos","render_size_px","world_foot_px","physical_center_px","collision_size_px"]: expected_row[key]=vec(expected_row[key])
	expected_row.city_v3_solid_polygons_px=[expected_points]
	check(same(row,expected_row),"EXACT_STORED_RENDER_ROW:"+String(lot.lot_id))
	var dimensions: Vector2=vec(asset.source_size_px);var sprite_scale: Vector2=Vector2(render_size.x/dimensions.x,render_size.y/dimensions.y)
	var source_a1: Array=asset.complete_A1_xyxy;var render_a1: PackedVector2Array=[]
	for corner: Vector2 in rectangle(source_a1): render_a1.append(row.pos*SIZE+(corner-dimensions*.5)*sprite_scale)
	return {"row":row,"points":points,"bounds":xyxy(points),"render_complete_A1":xyxy(render_a1)}
func finish(components: Dictionary) -> void:
	var last: Dictionary=facts(first.keys());var save_last: Dictionary=facts(config.get("save_absolute_paths",[]))
	check(first==last,"FIXED_SOURCE_FIRST_FINAL_SAME");check(saves==save_last,"FIFTEEN_SAVE_BYTES_SHA_MTIME_SECONDS_SAME")
	check(Time.get_ticks_msec()-began<20000,"FINITE_CPU20S_NO_EXTENSION")
	var report: Dictionary={"status":"ROOT_FINITE_TWO_YAMEN_NEW_WALL_DOMAINS_NOT_FIELD_OR_INDEPENDENT_PRIOR","passed":errors.is_empty() and not components.is_empty(),"checks":checks,"errors":errors.duplicate(),"components":components,"elapsed_ms":Time.get_ticks_msec()-began,"source_first":first,"source_final":last,"save_first":saves,"save_final":save_last,"new_domain_pixel_queries":pixel_queries,"only_affected_old_route_legs":affected_route_legs,"old_global_geometry_replay":false,"old87517_replay":false,"Scene_Field_packet_ResourceLoader_calls":0,"canonical_writes":0,"actual_Field_pass":false,"whole_city_ART_pass":false,"independent_QA_credit":false,"exactticks_protection":"Root external guard; internal Godot facts deliberately seconds only"}
	var output: String=String(config.get("output_root",""))+str(OS.get_process_id())+"/"
	if output.begins_with("res://build/luoyang_city_finish_20261025i_source01/street_edges_yamen02_local03_ROOT_READY/"):
		DirAccess.make_dir_recursive_absolute(physical(output));write_new(output+"result.json",(JSON.stringify(report,"\t")+"\n").to_utf8_buffer());print("STREET4_RESULT ",output+"result.json")
	quit(0 if report.passed else 1)
func run() -> void:
	began=Time.get_ticks_msec()
	if not check(READY and FileAccess.get_sha256(physical(INPUT))==INPUT_SHA,"ROOT_READY_FIXED_INPUT"): quit(2);return
	config=json_file(INPUT)
	if not check(config.get("ready")==true and config.get("root_run_authorized")==true,"EXPLICIT_ROOT_AUTHORIZATION"): quit(2);return
	var paths: Array=config.sources.keys();paths.append(INPUT);paths.append(SELF);first=facts(paths);saves=facts(config.save_absolute_paths)
	for path: String in config.sources:
		if not check(first[path].get("sha256")==config.sources[path],"FIXED_SOURCE:"+path): finish({});return
	if not check(saves.size()==15,"EXACT15_SAVE_FACTS"): finish({});return
	var author: Dictionary=json_file(config.author.path);var ids: Array[String]=[];var derived: Dictionary={};var per_lot: Array=[];var frozen_parents: Dictionary={}
	for parent_scene_id: String in config.scenes:
		var parent_pin: Dictionary=config.scenes[parent_scene_id].payload
		var parent_raw: PackedByteArray=FileAccess.get_file_as_bytes(physical(parent_pin.path));var parent_value: Variant=bytes_to_var(parent_raw)
		if not check(parent_value is Dictionary and var_to_bytes(parent_value)==parent_raw,"PARENT_FULL_TYPED_ROUNDTRIP:"+parent_scene_id): finish({});return
		frozen_parents[parent_scene_id]=parent_value
	for lot: Dictionary in author.lots:
		var local_error_count: int=errors.size();var id: String=String(lot.lot_id);ids.append(id)
		var model: Dictionary=project(lot);var bounds: Array=model.bounds
		# New walls must not be authored inside an unchanged river or old body.
		# Only this new polygon is queried; no old whole-mask raster is repeated.
		for old_solid_index: int in range(frozen_parents[String(lot.scene_id)].effective_solids.size()):
			var old_solid: PackedVector2Array=frozen_parents[String(lot.scene_id)].effective_solids[old_solid_index]
			if not boxes_intersect(bounds,xyxy(old_solid),true): continue
			check(Geometry2D.intersect_polygons(model.points,old_solid).is_empty(),"UNCHANGED_ORIGINAL_SOLID_OR_WATER_NOT_OCCUPIED:"+id+":"+str(old_solid_index))
		for old_a1: Dictionary in config.parent_complete_A1[String(lot.scene_id)]: check(not boxes_intersect(model.render_complete_A1,old_a1.xyxy),"COMPLETE_A1_FIXED_OLD:"+id+":"+String(old_a1.id))
		for strip: Dictionary in config.protected_strips[String(lot.scene_id)]: check(not boxes_intersect(model.render_complete_A1,strip.xyxy),"FULL_PUBLIC_DESIGN_STRIP:"+id+":"+String(strip.id))
		for npc: Dictionary in config.NPC_guards[String(lot.scene_id)]: check(not segment_hits_box(vec(npc.from_px),vec(npc.to_px),bounds,Vector2(17,15)),"UNCHANGED_NPC34x30_FULL_PATROL:"+id+":"+String(npc.id))
		for portal: Dictionary in config.portal_guards[String(lot.scene_id)]: check(not boxes_intersect(bounds,portal.player_body_and_portal_foot_guard_xyxy,true),"UNCHANGED_PORTAL_AND_RETURN:"+id+":"+String(portal.id))
		for route: Dictionary in config.route_guards[String(lot.scene_id)]:
			for leg: int in range(route.points_px.size()-1):
				var from: Vector2=vec(route.points_px[leg]);var to: Vector2=vec(route.points_px[leg+1]);var leg_box: Array=xyxy(PackedVector2Array([from,to]));leg_box=[leg_box[0]-17,leg_box[1]-12,leg_box[2]+17,leg_box[3]+12]
				if not boxes_intersect(bounds,leg_box,true): continue
				affected_route_legs+=1;check(not segment_hits_box(from,to,bounds,Vector2(17,12)),"AFFECTED_CONTINUOUS_PLAYER34x24_ROUTE:"+id+":"+String(route.id)+":"+str(leg))
		derived[id]=model;per_lot.append({"id":id,"passed":errors.size()==local_error_count,"source_ground":model.points,"final_consumer_A1":model.render_complete_A1})
	if not check(ids.size()==2 and ids==LOTS,"EXACT_ROOT_TWO_YAMEN_ITEMS_NO_GATE_NO_INN_NO_AUTO_REPAIR"): finish({"per_lot":per_lot});return
	# No candidate payload/mask is emitted if ANY explicit frozen item fails.
	if not errors.is_empty(): finish({"per_lot":per_lot,"no_child_emitted_on_failure":true});return
	var output: String=String(config.output_root)+str(OS.get_process_id())+"/";DirAccess.make_dir_recursive_absolute(physical(output))
	var artifacts: Dictionary={};var inverse_all: Dictionary={}
	for scene_id: String in config.scenes:
		var scene_cfg: Dictionary=config.scenes[scene_id];var parent_bytes: PackedByteArray=FileAccess.get_file_as_bytes(physical(scene_cfg.payload.path))
		var parent: Dictionary=frozen_parents[scene_id];var child: Dictionary=parent.duplicate(true);var added: Array=[];var mask: Image=Image.load_from_file(physical(scene_cfg.mask.path))
		if not check(mask!=null and mask.get_size()==Vector2i(3072,2048) and not mask.has_mipmaps(),"PARENT_FIXED_MASK:"+scene_id): finish({});return
		mask.convert(Image.FORMAT_RGBA8)
		if not check(sha(mask.get_data())==scene_cfg.mask.RGBA_sha256,"PARENT_FULL_RGBA_FIXED:"+scene_id): finish({});return
		var before_image: Image=mask.duplicate();var patches: Array=[]
		for lot: Dictionary in author.lots:
			if lot.scene_id!=scene_id: continue
			var model: Dictionary=derived[String(lot.lot_id)];var raw_domain: Array=lot.closed_domain_xyxy;var actual_bounds: Array=model.bounds
			var exact_domain: Array[int]=[ceili(actual_bounds[0]),ceili(actual_bounds[1]),floori(actual_bounds[2]),floori(actual_bounds[3])];var domain: Array[int]=[]
			if not check(raw_domain.size()==4,"EXACT_CLOSED_DOMAIN_FOUR_SCALARS:"+String(lot.lot_id)): finish({});return
			for domain_scalar: int in range(4):
				var declared_coordinate: float=float(raw_domain[domain_scalar])
				if not check(is_finite(declared_coordinate) and declared_coordinate==floor(declared_coordinate) and declared_coordinate==float(exact_domain[domain_scalar]),"EXACT_CLOSED_NEW_DOMAIN_INTEGER_SCALAR:"+String(lot.lot_id)+":"+str(domain_scalar)): finish({});return
				domain.append(int(declared_coordinate))
			for old_row: Dictionary in child.effective_navigation: check(old_row.get("id")!=model.row.id,"UNIQUE_NEW_ID:"+String(model.row.id))
			child.effective_navigation.append(model.row);child.visual_additions.append(model.row);child.effective_solids.append(model.points);added.append(model.row.id)
			var before_rgba: PackedByteArray=[];var after_rgba: PackedByteArray=[];var changed: int=0
			for y: int in range(domain[1],domain[3]+1):
				for x: int in range(domain[0],domain[2]+1):
					pixel_queries+=1;var old_color: Color=mask.get_pixel(x,y);before_rgba.append_array(PackedByteArray([old_color.r8,old_color.g8,old_color.b8,old_color.a8]))
					if Geometry2D.is_point_in_polygon(Vector2(x,y),model.points): mask.set_pixel(x,y,Color(0,0,0,old_color.a))
					var after_color: Color=mask.get_pixel(x,y);after_rgba.append_array(PackedByteArray([after_color.r8,after_color.g8,after_color.b8,after_color.a8]))
					if old_color!=after_color: changed+=1
			patches.append({"lot_id":lot.lot_id,"closed_xyxy":domain,"before_RGBA":before_rgba,"after_RGBA":after_rgba,"changed_pixels":changed})
		var restored: Dictionary=child.duplicate(true);restored.effective_navigation=restored.effective_navigation.slice(0,parent.effective_navigation.size());restored.visual_additions=restored.visual_additions.slice(0,parent.visual_additions.size());restored.effective_solids=restored.effective_solids.slice(0,parent.effective_solids.size())
		check(same(restored,parent) and var_to_bytes(restored)==parent_bytes,"COMPLETE_TYPED_BYTE_PAYLOAD_INVERSE:"+scene_id)
		var undone: Image=mask.duplicate()
		for patch: Dictionary in patches:
			var cursor: int=0;var box: Array=patch.closed_xyxy
			for y: int in range(box[1],box[3]+1):
				for x: int in range(box[0],box[2]+1): undone.set_pixel(x,y,Color8(patch.before_RGBA[cursor],patch.before_RGBA[cursor+1],patch.before_RGBA[cursor+2],patch.before_RGBA[cursor+3]));cursor+=4
		check(undone.get_data()==before_image.get_data(),"FULL_RGBA_INVERSE_DOMAIN_ONLY:"+scene_id)
		for original_key: Variant in parent:
			if original_key not in ["effective_navigation","visual_additions","effective_solids"]: check(same(parent[original_key],child[original_key]),"ALL_OTHER_PAYLOAD_KEYS_IDENTICAL:"+scene_id+":"+String(original_key))
		if not errors.is_empty(): finish({"per_lot":per_lot,"earlier_components":artifacts,"inverse_failed_scene":scene_id});return
		var scene_dir: String=output+scene_id+"/";DirAccess.make_dir_recursive_absolute(physical(scene_dir))
		artifacts[scene_id]={"payload":write_new(scene_dir+"payload.bin",var_to_bytes(child)),"mask":write_new(scene_dir+"walk_overlay.png",mask.save_png_to_buffer()),"full_RGBA_sha256":sha(mask.get_data()),"new_ids":added,"NAV_count":child.effective_navigation.size(),"solid_count":child.effective_solids.size()}
		inverse_all[scene_id]={"parent_payload":scene_cfg.payload,"parent_mask":scene_cfg.mask,"new_navigation_suffix_count":added.size(),"patches":patches,"complete_payload_inverse":same(restored,parent),"whole_RGBA_inverse":undone.get_data()==before_image.get_data()}
	var inverse_pin: Dictionary=write_new(output+"two_Yamen_domain_inverse.bin",var_to_bytes(inverse_all))
	finish({"per_lot":per_lot,"scenes":artifacts,"inverse":inverse_pin,"only_two_Yamen_new_domains":true,"all_old_portals_NPCs_routes_parent_arrays_retained":true,"cart_and_shrine_are_separate_visual_only_candidates_not_applied_here":true})
