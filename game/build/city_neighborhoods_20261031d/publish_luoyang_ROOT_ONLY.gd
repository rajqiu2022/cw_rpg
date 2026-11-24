extends SceneTree
## Root-only bounded immutable Civic delta. No Field, save API, or old-file write.
const Core=preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Common=preload("res://build/three_settlements_20261030e_system01/common_author.gd")
const SPEC="res://build/city_neighborhoods_20261031d/luoyang_courts.json"
const SPEC_SHA="276bdf00d494f48ce2f1d1bcc2efb19533bce804cca1f85718a179ad56e23fea"
const OUT="res://build/city_neighborhoods_20261031d/luoyang_output"
var errors: Array[String]=[]
var checks := 0
var suspended := false
func _initialize() -> void:
	root.child_entered_tree.connect(_early)
	for node: Node in root.get_children():_early(node)
	_run.call_deferred()
func _early(node: Node) -> void:
	if node.name==&"PlatformBridge" and node.has_method("set_checkpoint_saves_suspended"):
		node.call("set_checkpoint_saves_suspended",true);suspended=bool(node.call("is_checkpoint_saves_suspended"))
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok:errors.append(label)
	return ok
func bound(poly: PackedVector2Array) -> Rect2:
	var result:=Rect2(poly[0],Vector2.ZERO)
	for p: Vector2 in poly:result=result.expand(p)
	return result
func _run() -> void:
	await process_frame
	var directory:=OUT+"/"+str(OS.get_process_id())
	if not need(suspended and not DirAccess.dir_exists_absolute(directory),"ROOT_NEW_OUTPUT_AND_EARLIEST_SUSPEND"):quit(1);return
	DirAccess.make_dir_recursive_absolute(directory)
	var spec: Dictionary=Core.read_json(SPEC,SPEC_SHA)
	if not need(spec.get("schema")==1 and FileAccess.get_sha256(spec.parent)==spec.parent_sha256,"EXACT_PARENT_C0A8"):finish(directory);return
	var old: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(spec.parent))
	if not need(old.get("id")==spec.region and Core.plain(old) and Core.source_pass(old.sources),"PARENT_TYPED_SOURCES"):finish(directory);return
	var out: Dictionary=old.duplicate(true)
	var prior_count: int=out.solids.size()
	var indices: Array[int]=[];var descriptors: Array=[]
	for raw: Dictionary in spec.buildings:
		var texture: String=Common.BASE+"canal_warehouse_v3.png" if raw.kind=="warehouse" else (Common.EAST if raw.kind=="east" else Common.WEST)
		var row: Dictionary=Common.building(raw.id,texture,Vector2(raw.foot[0],raw.foot[1]),raw.width,raw.depth,"31d完整行业院附属楼")
		var source: Vector2=Vector2(row.source_foot_px[0],row.source_foot_px[1])
		var image:=load(texture) as Texture2D
		if not need(image!=null and row.native_scale<=1.0,"WHOLE_NATIVE_UNIFORM_BUILDING:"+raw.id):finish(directory);return
		var polygon: PackedVector2Array=Common.rect_polygon(row.body)
		for existing: Dictionary in descriptors:
			if not need(Geometry2D.intersect_polygons(polygon,existing.polygon).is_empty(),"NEW_BASES_DISJOINT:"+raw.id):finish(directory);return
		if raw.has("replaces"):
			var found: Array=out.render.filter(func(r: Dictionary)->bool:return String(r.get("id",""))==String(raw.replaces) and r.logical_id==spec.logical)
			if not need(found.size()==1,"EXACT_REPLACED_ANNEX:"+raw.id):finish(directory);return
			var box: Array=raw.old_solid_bounds
			var original_bounds:=Rect2(box[0],box[1],box[2],box[3])
			var matching := 0
			for prior: PackedVector2Array in old.solids:
				if bound(prior)==original_bounds:matching+=1
			if not need(matching==1 and row.body.encloses(original_bounds),"RETAINED_ANNEX_BASE_INSIDE_NEW_COMPLETE_BODY:"+raw.id):finish(directory);return
			out.render=out.render.filter(func(r: Dictionary)->bool:return not(String(r.get("id",""))==String(raw.replaces) and r.logical_id==spec.logical))
		# Existing source grounding is an already adopted contract, not alpha bbox.
		out.render.append({"id":raw.id,"owner_id":raw.id,"key":String(spec.logical)+"/"+String(raw.id),"logical_id":spec.logical,"texture":texture,"texture_size_px":image.get_size(),"position_px":row.foot-source*row.native_scale,"foot_px":row.foot,"scale":Vector2.ONE*row.native_scale,"centered":false,"plot_id":"31d_"+String(raw.id),"source_row":{"sort_by_feet":true}})
		indices.append(out.solids.size());out.solids.append(polygon)
		descriptors.append({"id":raw.id,"polygon":polygon,"restore":Vector2(raw.restore[0],raw.restore[1]),"replaces":raw.get("replaces","")})
		for path: String in [texture,texture+".import"]:
			if not need(FileAccess.file_exists(path),"EXISTING_ASSET_SOURCE:"+path):finish(directory);return
			out.sources[path]=FileAccess.get_sha256(path)
		var import_config:=ConfigFile.new()
		if not need(import_config.load(texture+".import")==OK,"EXISTING_IMPORT_CONFIG"):finish(directory);return
		var remap: String=import_config.get_value("remap","path","")
		if not need(FileAccess.file_exists(remap),"EXISTING_IMPORT_LEAF"):finish(directory);return
		out.sources[remap]=FileAccess.get_sha256(remap)
	# Rebuild only the new body's index references; prior cells and indices exact.
	for i: int in indices:
		var bounds: Rect2=bound(out.solids[i])
		for x: int in range(floori(bounds.position.x/Core.CELL),floori(bounds.end.x/Core.CELL)+1):
			for y: int in range(floori(bounds.position.y/Core.CELL),floori(bounds.end.y/Core.CELL)+1):
				var cell:=Vector2i(x,y)
				if not out.solid_cells.has(cell):out.solid_cells[cell]=[]
				out.solid_cells[cell].append(i)
	for raw_route: Array in spec.protected_routes:
		for i: int in range(raw_route.size()-1):
			var start:=Vector2(raw_route[i][0],raw_route[i][1]);var end:=Vector2(raw_route[i+1][0],raw_route[i+1][1])
			if not need(Core.safe_segment(out,start,end,Vector2(17,12)),"PRESERVED_MAIN_OR_TASK_APPROACH"):finish(directory);return
	for descriptor: Dictionary in descriptors:
		if not need(Core.safe_body(out,descriptor.restore,Vector2(17,12)) and Core.npc_route_clear(out,descriptor.restore,descriptor.restore,Vector2(17,12)),"DECLARED_RESTORE_CLEAR:"+descriptor.id):finish(directory);return
	# Original NPC stations and patrol segments must not be enclosed by new bases.
	for npc: Dictionary in out.npcs:
		var center: Vector2=npc.foot+npc.get("body_offset_px",Vector2.ZERO)
		var half_body: Vector2=npc.get("half_body",Vector2(17,15))
		for descriptor: Dictionary in descriptors:
			if not need(Geometry2D.intersect_polygons(Common.rect_polygon(Rect2(center-half_body,half_body*2)),descriptor.polygon).is_empty(),"NPC_STATION_CLEAR:"+String(npc.get("npc_id",""))):finish(directory);return
	out.sources[SPEC]=FileAccess.get_sha256(SPEC);out.sources[spec.parent]=spec.parent_sha256
	out.courts31d_restore={"spec":SPEC,"source_sha256":out.sources[SPEC],"parent":spec.parent,"parent_sha256":spec.parent_sha256,"new_solid_indices":indices,"rows":descriptors}
	for key: String in ["floor_rects","surfaces","npcs","portals","interactions","districts"]:
		if not need(var_to_bytes(out[key])==var_to_bytes(old[key]),"OLD_SEMANTIC_FIELD_EXACT:"+key):finish(directory);return
	if not need(out.solids.size()==prior_count+4 and Core.plain(out),"EXACT_FOUR_NEW_BASES_PLAIN"):finish(directory);return
	var file:=FileAccess.open(directory+"/luoyang_civic_market_region_27d.bin",FileAccess.WRITE)
	file.store_buffer(var_to_bytes(out));file.close()
	var result:=FileAccess.open(directory+"/binding.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"path":directory+"/luoyang_civic_market_region_27d.bin","sha256":FileAccess.get_sha256(directory+"/luoyang_civic_market_region_27d.bin"),"bytes":FileAccess.get_file_as_bytes(directory+"/luoyang_civic_market_region_27d.bin").size(),"new_body_indices":indices,"restore_rows":descriptors},"\t"));result.close()
	finish(directory)
func finish(directory: String) -> void:
	var report:=FileAccess.open(directory+"/report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"Field_instances":0,"canonical_writes":0,"save_APIs":0},"\t"));report.close()
	quit(0 if errors.is_empty() else 1)
