extends "res://build/city_neighborhoods_20261031d/publish_luoyang_ROOT_ONLY.gd"
## Only the first publisher's one misplaced house; all other success inherited.
const NEXT_SPEC="res://build/city_neighborhoods_20261031d/luoyang_courts02.json"
const NEXT_SPEC_SHA="ae62f835402769b0da96685e20d8f7bea017204c4684d7df26d96ad0263bdb97"
const BASE_BIN="res://build/city_neighborhoods_20261031d/luoyang_output/134988/luoyang_civic_market_region_27d.bin"
const BASE_SHA="97f924fed6abed74e55bb2c750cab77db3d0caa439498368fc6f2ec68168d1d8"
func _run() -> void:
	await process_frame
	var directory:=OUT+"/"+str(OS.get_process_id())
	if not need(suspended and not DirAccess.dir_exists_absolute(directory),"NEW_RESIDUAL_OUTPUT_AND_EARLIEST_SUSPEND"):quit(1);return
	DirAccess.make_dir_recursive_absolute(directory)
	if not need(FileAccess.get_sha256("res://build/city_neighborhoods_20261031d/publish_luoyang_ROOT_ONLY.gd")=="406bde4b2774059f1623d87beda346341e99713ac533b2906921ebbb47c5b129" and FileAccess.get_sha256(BASE_BIN)==BASE_SHA,"FROZEN_FIRST_PUBLISHER_AND_BIN"):finish(directory);return
	var spec: Dictionary=Core.read_json(NEXT_SPEC,NEXT_SPEC_SHA)
	var before: Dictionary=bytes_to_var(FileAccess.get_file_as_bytes(BASE_BIN))
	if not need(not spec.is_empty() and before.get("id")==spec.region and Core.source_pass(before.sources),"FIRST_TYPED_PARENT_SOURCES"):finish(directory);return
	var out: Dictionary=before.duplicate(true)
	var raw: Dictionary=spec.buildings[1]
	if not need(raw.id=="cloth31d_east_house" and raw.foot==[2490,3500] and out.courts31d_restore.new_solid_indices==[130,131,132,133],"ONE_FIXED_RESIDUAL_SCOPE"):finish(directory);return
	var row: Dictionary=Common.building(raw.id,Common.EAST,Vector2(raw.foot[0],raw.foot[1]),raw.width,raw.depth,"31d布院完整侧楼")
	var source:=Vector2(row.source_foot_px[0],row.source_foot_px[1])
	var selected: Array=out.render.filter(func(item: Dictionary)->bool:return item.id==raw.id and item.logical_id==spec.logical)
	if not need(selected.size()==1 and selected[0].foot_px==Vector2(2580,3960),"ORIGINAL_ONE_HOUSE_VISUAL"):finish(directory);return
	selected[0].foot_px=row.foot;selected[0].position_px=row.foot-source*row.native_scale
	var polygon: PackedVector2Array=Common.rect_polygon(row.body)
	out.solids[131]=polygon
	for cell: Variant in out.solid_cells.keys():
		out.solid_cells[cell].erase(131)
		if out.solid_cells[cell].is_empty():out.solid_cells.erase(cell)
	var bounds: Rect2=bound(polygon)
	for x: int in range(floori(bounds.position.x/Core.CELL),floori(bounds.end.x/Core.CELL)+1):
		for y: int in range(floori(bounds.position.y/Core.CELL),floori(bounds.end.y/Core.CELL)+1):
			var cell:=Vector2i(x,y)
			if not out.solid_cells.has(cell):out.solid_cells[cell]=[]
			out.solid_cells[cell].append(131)
	out.courts31d_restore.rows[1].polygon=polygon
	out.courts31d_restore.spec=NEXT_SPEC;out.courts31d_restore.source_sha256=NEXT_SPEC_SHA
	out.sources[NEXT_SPEC]=NEXT_SPEC_SHA
	# All other published geometry remains byte-identical. No repeated165 matrix.
	for i: int in range(out.solids.size()):
		if i!=131 and not need(var_to_bytes(out.solids[i])==var_to_bytes(before.solids[i]),"UNCHANGED_OTHER_SOLID:"+str(i)):finish(directory);return
	for i: int in range(out.solids.size()):
		if i!=131 and not need(Geometry2D.intersect_polygons(polygon,out.solids[i]).is_empty(),"NEW_HOUSE_CLEAR_OTHER_BASE:"+str(i)):finish(directory);return
	for npc: Dictionary in out.npcs:
		var center: Vector2=npc.foot+npc.get("body_offset_px",Vector2.ZERO)
		var half_body: Vector2=npc.get("half_body",Vector2(17,15))
		if not need(Geometry2D.intersect_polygons(Common.rect_polygon(Rect2(center-half_body,half_body*2)),polygon).is_empty(),"NEW_HOUSE_CLEAR_OLD_NPC"):finish(directory);return
	if not need(Core.safe_body(out,Vector2(2730,3930),Vector2(17,12)) and Core.safe_segment(out,Vector2(3072,3930),Vector2(2730,3930),Vector2(17,12)),"ORIGINAL_XUANTONG_NOTE_FRONT_REOPENED"):finish(directory);return
	if not need(Core.safe_body(out,Vector2(2640,4280),Vector2(17,12)) and Core.npc_route_clear(out,Vector2(2640,4280),Vector2(2640,4280),Vector2(17,12)),"ORIGINAL_CLOTH_RESTORE_TARGET_CLEAR"):finish(directory);return
	for key: String in ["floor_rects","surfaces","npcs","portals","interactions","districts"]:
		if not need(var_to_bytes(out[key])==var_to_bytes(before[key]),"SEMANTIC_FIELD_STILL_EXACT:"+key):finish(directory);return
	var path:=directory+"/luoyang_civic_market_region_27d.bin"
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_buffer(var_to_bytes(out));file.close()
	var result:=FileAccess.open(directory+"/binding.json",FileAccess.WRITE)
	result.store_string(JSON.stringify({"path":path,"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size(),"new_body_indices":[130,131,132,133],"restore_rows":out.courts31d_restore.rows,"inherited_publisher":134988,"one_house_index":131,"first_missing_task_route_not_claimed_pass":true},"\t"));result.close()
	finish(directory)
