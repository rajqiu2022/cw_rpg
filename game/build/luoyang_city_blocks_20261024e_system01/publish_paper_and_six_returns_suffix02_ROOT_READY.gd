extends SceneTree
## Remaining-only: inherited18routes/native/crowd prefix, paper888 and six returns.
const READY=true
const INPUT="res://build/luoyang_city_blocks_20261024e_system01/paper_and_six_returns_input01_ROOT_READY.json"
const INPUT_SHA="3ab89dce3f2ae150505d5cdc6f858af2552c921fb34051436dbd891d096a49b4"
const LIMIT_MS=60000
var begun: int=0
var checks: int=0
var errors: Array[String]=[]
var report: Dictionary={"passed":false,"raster":0,"native_packet_decode":0,"Field":0,"Physics":0,"old_routes_replayed":0,"images_written":0,"formal_writes":0}
func _initialize() -> void: begun=Time.get_ticks_msec();call_deferred("run")
func check(value: bool,label: String) -> bool:
	checks+=1
	if Time.get_ticks_msec()-begun>=LIMIT_MS: value=false;label="WHOLE60S:"+label
	if not value: errors.append(label)
	return value
func sha(bytes: PackedByteArray) -> String:
	var hashing:=HashingContext.new();hashing.start(HashingContext.HASH_SHA256);hashing.update(bytes);return hashing.finish().hex_encode()

func json_file(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

func v(raw: Variant) -> Vector2:
	return raw if raw is Vector2 else Vector2(raw[0],raw[1])

func polygon(raw: Variant) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for point: Variant in raw: result.append(v(point))
	return result

func bounds(points: PackedVector2Array) -> Rect2:
	var low:=Vector2(INF,INF);var high:=Vector2(-INF,-INF)
	for point: Vector2 in points: low=low.min(point);high=high.max(point)
	return Rect2(low,high-low)

func cross(a: Vector2,b: Vector2,p: Vector2) -> float: return (float(b.x)-a.x)*(float(p.y)-a.y)-(float(b.y)-a.y)*(float(p.x)-a.x)

func on(a: Vector2,b: Vector2,p: Vector2) -> bool: return cross(a,b,p)==0.0 and p.x>=minf(a.x,b.x) and p.x<=maxf(a.x,b.x) and p.y>=minf(a.y,b.y) and p.y<=maxf(a.y,b.y)

func touch(a: Vector2,b: Vector2,c: Vector2,d: Vector2) -> bool:
	return cross(a,b,c)*cross(a,b,d)<0.0 and cross(c,d,a)*cross(c,d,b)<0.0 or on(a,b,c) or on(a,b,d) or on(c,d,a) or on(c,d,b)

func safe(foot: Vector2,mask: Image,solids: Array,half: Vector2=Vector2(17,12)) -> bool:
	if not foot.is_finite() or foot.x<half.x or foot.y<half.y or roundi(foot.x+half.x)>=3072 or roundi(foot.y+half.y)>=2048: return false
	var area:=Rect2(foot-half,half*2)
	var body:=PackedVector2Array([area.position,Vector2(area.end.x,area.position.y),area.end,Vector2(area.position.x,area.end.y)])
	for row: Dictionary in solids:
		var shape:=polygon(row.points_px)
		if not bounds(shape).intersects(area,true): continue
		if not Geometry2D.intersect_polygons(body,shape).is_empty(): return false
		for point: Vector2 in body:
			if Geometry2D.is_point_in_polygon(point,shape): return false
		for point: Vector2 in shape:
			if point.x>=area.position.x and point.x<=area.end.x and point.y>=area.position.y and point.y<=area.end.y: return false
		for i: int in range(body.size()):
			for j: int in range(shape.size()):
				if touch(body[i],body[(i+1)%body.size()],shape[j],shape[(j+1)%shape.size()]): return false
	for y: int in range(roundi(area.position.y),roundi(area.end.y)+1):
		for x: int in range(roundi(area.position.x),roundi(area.end.x)+1):
			var color:=mask.get_pixel(x,y)
			if color.r<.5 or color.a<.5: return false
	for offset: Vector2 in [Vector2(-17,-12),Vector2(0,-12),Vector2(17,-12),Vector2(-17,0),Vector2.ZERO,Vector2(17,0),Vector2(-17,12),Vector2(0,12),Vector2(17,12),Vector2(-8.5,-12),Vector2(8.5,-12),Vector2(-8.5,12),Vector2(8.5,12),Vector2(-17,-6),Vector2(-17,6),Vector2(17,-6),Vector2(17,6)]:
		var color:=mask.get_pixelv(Vector2i((foot+offset).round()))
		if color.r<.5 or color.a<.5: return false
	return true


func image(path: String) -> Image:
	var value:=Image.load_from_file(path)
	if value==null or value.is_empty(): return null
	if value.get_format() not in [Image.FORMAT_RGB8,Image.FORMAT_RGBA8]: return null
	if value.get_format()==Image.FORMAT_RGB8: value.convert(Image.FORMAT_RGBA8)
	return value

func write_bytes(path: String,value: PackedByteArray) -> bool:
	if FileAccess.file_exists(path): return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_buffer(value);file.close();return true

func run() -> void:
	var cfg:=json_file(INPUT)
	if not check(READY and FileAccess.get_sha256(INPUT)==INPUT_SHA and cfg.get("ready")==true,"ROOT_FROZEN_SUFFIX"): finish();return
	var prefix:=json_file(cfg.prefix.path);var component:=json_file(cfg.components.path)
	var first: Dictionary=component.get("source_first",{}).duplicate()
	first[INPUT]=INPUT_SHA
	for row: Dictionary in [cfg.prefix,cfg.components,cfg.author,cfg.independent_paper_check]: first[row.path]=row.sha256
	for path: String in cfg.fixed_artifacts: first[path]=cfg.fixed_artifacts[path]
	first[String(prefix.get("stdout_path",""))]=prefix.get("stdout_sha256","")
	first[String(prefix.get("receipt_path",""))]=prefix.get("receipt_sha256","")
	for path: String in first:
		if not check(path.begins_with("res://") and FileAccess.get_sha256(path)==first[path],"SOURCE_FIRST:"+path): finish();return
	if not check(prefix.get("status")=="LIMITED_PASSED_PREFIX_OF_FAILED_PUBLICATION05_NOT_WHOLE_PASS" and prefix.get("components_path")==cfg.components.path and prefix.get("components_sha256")==cfg.components.sha256 and prefix.get("failure",{}).get("id")=="paper_task_artisan_kept" and v(prefix.failure.foot)==Vector2(880,1340) and prefix.get("prefix_sample_count")==null,"FIXED_FAILED_ACTUAL_PREFIX_NOT_WHOLE_PASS"): finish();return
	var author:=json_file(cfg.author.path);var old_author:=json_file(prefix.author_path)
	var inverse:=author.duplicate(true)
	if not check(inverse.npc_migrations.size()==old_author.npc_migrations.size()+1,"ONLY_ONE_REAL_TASK_MIGRATION"): finish();return
	var moved: Dictionary=inverse.npc_migrations.pop_back()
	if not check(moved.id=="luoyang_paper_artisan_20261016" and v(moved.old_foot_px)==Vector2(880,1340) and v(moved.foot_px)==Vector2(888,1340) and inverse==old_author,"WHOLE_AUTHOR07_INVERSE06_NO_GEOMETRY_CHANGE"): finish();return
	var projection: Variant=bytes_to_var(FileAccess.get_file_as_bytes(component.render_projection.path))
	var solids: Variant=bytes_to_var(FileAccess.get_file_as_bytes(component.geometry.path))
	if not check(projection is Dictionary and projection.get("ok")==true and projection.render.size()==43 and solids is Array and not solids.is_empty(),"FROZEN43_RENDER_AND_SOLIDS_ONLY"): finish();return
	var mask:=image(component.walk_path)
	if not check(mask!=null and mask.get_size()==Vector2i(3072,2048) and sha(mask.get_data())==component.walk_RGBA_sha256 and component.walk_RGBA_sha256=="b6d6d0af0e2e03a7588a2f3561fd6c9aa4f821fe31265338ee79f0463305cb06","FIXED_COMPONENT_MASK_RGBA_NOT_RASTER"): finish();return
	if not check(not safe(Vector2(880,1340),mask,solids,Vector2(17,15)),"OLD880_REAL_CLOSED_BODY_NEGATIVE"): finish();return
	if not check(safe(Vector2(888,1340),mask,solids,Vector2(17,15)),"NEW888_REAL_CLOSED_BODY1085_PLUS17"): finish();return
	var returns: Array=[]
	for row: Dictionary in author.room_migrations:
		var foot:=v(row.return_foot_px)
		if not check(safe(foot,mask,solids),"REMAINING_ROOM_RETURN875_PLUS17:"+String(row.room_id)): finish();return
		returns.append({"room_id":row.room_id,"foot_px":row.return_foot_px,"safe":true})
	if not check(returns.size()==6,"EXACT_REMAINING_SIX_ROOMS"): finish();return
	var final: Dictionary={}
	for path: String in first:
		final[path]=FileAccess.get_sha256(path)
		if not check(final[path]==first[path],"SOURCE_FINAL:"+path): finish();return
	var out: String=String(cfg.output_prefix)+str(OS.get_process_id())+"/"
	if not check(not DirAccess.dir_exists_absolute(out) and DirAccess.make_dir_recursive_absolute(out)==OK,"NEW_SMALL_HEADER_ONLY"): finish();return
	var inverse_path: String=component.geometry.path.get_base_dir()+"/pixel_inverse.bin"
	var header: Dictionary={"status":"MARKET24E_BLOCK_OVERLAY_BUILD_ONLY","ready":false,"runtime_ready":false,"author_path":cfg.author.path,"author_sha256":cfg.author.sha256,"parent_native4_unchanged":author.parent.artifacts,"combined_visuals_before":37,"combined_visuals_after":43,"walk_path":component.walk_path,"walk_sha256":component.walk_sha256,"walk_RGBA_sha256":component.walk_RGBA_sha256,"changed_pixels":component.changed_pixels,"visited_pixels":component.visited_pixels,"render_projection":component.render_projection,"geometry":component.geometry,"pixel_inverse":{"path":inverse_path,"sha256":cfg.fixed_artifacts[inverse_path]},"full_render_inverse":true,"full_RGBA_inverse":true,"components_parent":cfg.components,"route_proof":{"ok":true,"kind":"FIXED_FAILED_ACTUAL_PREFIX_PLUS_ONLY_REMAINING_SUFFIX","prefix":cfg.prefix,"inherited_prefix_sample_count":null,"no_sample_count_invented":true,"old880_negative":true,"new888_positive":true,"six_returns":returns,"eighteen_old_routes_not_replayed":true},"source_first":first,"source_final":final,"Field_Physics_ART_pending":true}
	if not check(write_bytes(out+"overlay_header_NOTREADY.json",JSON.stringify(header,"\t",true,true).to_utf8_buffer()),"WRITE_ONLY_NEW_HEADER"): finish();return
	report.passed=true;report.output=out;report.header_sha256=FileAccess.get_sha256(out+"overlay_header_NOTREADY.json");report.route_proof=header.route_proof
	finish()
func finish() -> void:
	report.errors=errors;report.checks=checks;report.elapsed_ms=Time.get_ticks_msec()-begun
	print(JSON.stringify(report));quit(0 if report.passed else 1)
