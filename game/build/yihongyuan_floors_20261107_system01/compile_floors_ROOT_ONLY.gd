extends SceneTree
## Generates two isolated Variant candidates from current accepted 1F and media.
const Home := "res://build/yihongyuan_floors_20261107_system01/"
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Old := "res://build/interior_identity_20261107_runtime01/yihongyuan27n_interior.bin"
const OldSHA := "649075ce491953d63013f9f4ca0fe7d6eb3e6451e28980ff5865e451d9c004d9"
const Lower := "yihongyuan27n_interior"
const Upper := "yihongyuan27n_upper"
const Market := "ch4_s3_luoyang_market"
const Hall := Vector2(1536,1024)
const Half := Vector2(17,12)
const Up := Vector2(416,456)
const Down := Vector2(768,928)
const UpperArrival := Vector2(768,832)
const LowerReturn := Vector2(416,576)
const Media := "res://art/modules/yihongyuan_floors_20261107/"
const UpperScene := "res://build/yihongyuan_floors_20261107_runtime01/yihongyuan27n_upper.tres"
const Textures := {
	"tea_table":["f05dd2c74a6dae660859a5979eefc1c25b7bc1eb4eba17b11a91b780615b9d11",Vector2(1610,977)],
	"up_stair":["69b0caf4dee4c0f74dc574a7af0fe16dcbe727c957788c4d46740acec283de7a",Vector2(1024,1536)],
	"upper_shell":["bd38f76c264b173cdcae2e260bcfb31d127c6dc02482db413b3648c4bf21bb0e",Vector2(1536,1024)],
}
const NewTableIDs := ["yihongyuan_public_table","yihongyuan_quiet_table","yihongyuan_backstage_desk"]
var problems: Array[String] = []
var checks := 0
var output := ""
var media_pins: Dictionary = {}
var blocked_route_samples: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func need(ok: bool,name: String) -> bool:
	checks+=1
	if not ok:problems.append(name);printerr(name)
	return ok

func _rect(p: Vector2,s: Vector2) -> PackedVector2Array:
	return PackedVector2Array([p,p+Vector2(s.x,0),p+s,p+Vector2(0,s.y)])

func _row(id: String,logical: String,path: String,pos: Vector2,size: Vector2,scale: float,foot: Vector2,depth: int) -> Dictionary:
	return {"id":id,"owner_id":id,"key":logical+"/"+id,"logical_id":logical,"texture":path,"texture_size_px":size,"position_px":pos,"scale":Vector2.ONE*scale,"foot_px":foot,"centered":false,"source_row":{"sort_by_feet":false,"z_index":depth}}

func _pin(role: String) -> bool:
	var path := Media+role+".png"
	var size: Vector2 = Textures[role][1]
	if not need(FileAccess.get_sha256(path)==Textures[role][0],"EXACT_RAW_RGB_RGBA:"+role):return false
	var sidecar := ConfigFile.new()
	if not need(sidecar.load(path+".import")==OK,"REAL_IMPORT_SIDECAR:"+role):return false
	var imported: String = sidecar.get_value("remap","path","")
	if not need(imported.begins_with("res://.godot/imported/"+role+".png-") and imported.ends_with(".ctex") and FileAccess.file_exists(imported),"REAL_PROJECT_CTEXTURE:"+role):return false
	var texture := load(path) as Texture2D
	if not need(texture!=null and texture.resource_path==path and texture.get_size()==size,"REAL_IMPORT_SIZE:"+role):return false
	for leaf: String in [path,path+".import",imported]:
		media_pins[leaf]=FileAccess.get_sha256(leaf)
	return true

func _layers(polygons: Array, prefix: String) -> Array:
	var rows: Array = []
	for n: int in range(polygons.size()):
		var uv: PackedVector2Array = polygons[n][0]
		var geom: PackedVector2Array = uv.duplicate()
		if polygons[n].size()>2:
			for i: int in range(geom.size()):geom[i]-=polygons[n][2]
		rows.append({"id":prefix+str(n),"polygon":geom,"uv":uv,"z_index":polygons[n][1]})
	return rows

func _table(id: String,logical: String,foot: Vector2,ratio: float) -> Dictionary:
	return _row(id,logical,Media+"tea_table.png",foot-Vector2(805,901)*ratio,Textures.tea_table[1],ratio,foot,floori(foot.y/8.0))

func _portal(id: String,logical: String,foot: Vector2,target: String,arrival: Vector2,label: String) -> Dictionary:
	return {"id":id,"logical_id":logical,"key":logical+"/"+id,"foot":foot,"foot_px":foot,"legacy_source_uv":foot/Hall,"size_px":Vector2(56,30),"return_foot":foot,"data":{"id":id,"target_scene":target,"target_pos":arrival/Hall,"label":label,"destination_name":label,"show_destination_label":true,"region27d_target":{"region_id":target,"logical_id":target,"foot_px":[arrival.x,arrival.y]}}}

func _lower(prior: Dictionary) -> Dictionary:
	var room: Dictionary = prior.duplicate(true)
	room["yihong_floor_profile"]="YIHONG_LOWER_20261107_V1"
	room.sources[Old]=OldSHA
	for path: String in media_pins:
		if not path.contains("upper_shell.png"):room.sources[path]=media_pins[path]
	var replaced: Array[String] = []
	for i: int in range(room.render.size()):
		var original: Dictionary = room.render[i]
		if original.owner_id not in NewTableIDs:continue
		var table := _table(original.owner_id,original.logical_id,original.foot_px,0.107 if original.owner_id=="yihongyuan_backstage_desk" else 0.102)
		# Preserve owner ID, transforms that affect business, and all old physical
		# table bases. Only visual placement/texture/size/scale changes.
		for key: String in ["texture","texture_size_px","position_px","scale"]:original[key]=table[key]
		replaced.append(original.owner_id)
	if not need(replaced.size()==3 and NewTableIDs.all(func(id: String) -> bool:return id in replaced),"EXACT_THREE_PREDECESSOR_TABLE_ROLES"):return {}
	var origin := Vector2(416-512*0.114,389)
	var stair := _row("yihong_lower_ascending_stair",Market,Media+"up_stair.png",origin,Textures.up_stair[1],0.114,Vector2(416,558),20)
	var tread := PackedVector2Array([Vector2(303,244),Vector2(719,244),Vector2(900,1468),Vector2(124,1468)])
	var left := PackedVector2Array([Vector2(239,68),Vector2(303,68),Vector2(303,244),Vector2(124,1468),Vector2(124,1480),Vector2(43,1480),Vector2(45,929),Vector2(85,929),Vector2(239,193)])
	var right := PackedVector2Array()
	for i: int in range(left.size()-1,-1,-1):right.append(Vector2(1024-left[i].x,left[i].y))
	stair["yihongyuan_native_layers"]=_layers([[tread,12],[left,74],[right,74]],"YihongStairRail")
	room.render.append(stair)
	# Widen into the open lower tread. These are boundaries of the traversable
	# stair only; the table blockers and every old polygon remain byte-identical.
	Core._append_solid(room,PackedVector2Array([Vector2(384,428),Vector2(395,428),Vector2(386,550),Vector2(359,550)]))
	Core._append_solid(room,PackedVector2Array([Vector2(437,428),Vector2(448,428),Vector2(473,550),Vector2(446,550)]))
	Core._append_solid(room,_rect(Vector2(384,427),Vector2(64,11)))
	room.portals.append(_portal("yihong_stairs_up_20261107",Lower,Up,Upper,UpperArrival,"上二楼·雅阁"))
	return room

func _upper(prior: Dictionary) -> Dictionary:
	var sources: Dictionary = media_pins.duplicate()
	sources[UpperScene]=FileAccess.get_sha256(Home+"yihongyuan27n_upper.tres.txt")
	var shell := _row("yihong_upper_native_shell",Upper,Media+"upper_shell.png",Vector2.ZERO,Hall,1.0,Vector2.ZERO,-1000)
	var shapes: Array = [
		[_rect(Vector2.ZERO,Vector2(1536,768)),-1000],
		[_rect(Vector2(0,967),Vector2(1536,57)),-1000],
		[_rect(Vector2(0,768),Vector2(78,199)),-1000],
		[_rect(Vector2(650,768),Vector2(208,199)),-1000],
		[_rect(Vector2(1432,768),Vector2(104,199)),-1000],
		[_rect(Vector2(78,768),Vector2(572,199)),300],
		[_rect(Vector2(858,768),Vector2(574,199)),300],
	]
	shell["yihongyuan_native_layers"]=_layers(shapes,"YihongUpperPartition")
	# Show just the head of the same stair, at the same scale, where the
	# upstairs deck opens. Preserve source UVs instead of stretching the steps.
	var stair := _row("yihong_upper_descending_threshold",Upper,Media+"up_stair.png",Vector2(768-312*0.114,878),Textures.up_stair[1],0.114,Down,-975)
	var descent := PackedVector2Array([Vector2(220,220),Vector2(804,220),Vector2(890,940),Vector2(134,940)])
	stair["yihongyuan_native_layers"]=_layers([[descent,-950,Vector2(200,220)]],"YihongUpperDescent")
	var walls: Array[PackedVector2Array] = [
		_rect(Vector2.ZERO,Vector2(1536,433)),
		PackedVector2Array([Vector2(0,433),Vector2(267,433),Vector2(148,808),Vector2(0,808)]),
		PackedVector2Array([Vector2(1238,433),Vector2(1536,433),Vector2(1536,808),Vector2(1360,808)]),
		_rect(Vector2(0,808),Vector2(650,216)),
		_rect(Vector2(858,808),Vector2(678,216)),
		_rect(Vector2(650,960),Vector2(208,64)),
	]
	var room: Dictionary = {
		"ok":true,"schema":Core.SCHEMA,"id":Upper,"size":Hall,"revision":prior.revision,"sources":sources,
		"districts":{Upper:{"domain":Rect2(Vector2.ZERO,Hall),"legacy_size":Hall,"legacy_version":1,"legacy_frame_origin":Vector2.ZERO,"save_fallback_uv":UpperArrival/Hall,"migrations":[],"legacy_version_migrations":{}}},
		"floor_rects":[Rect2(Vector2.ZERO,Hall)],"surfaces":[],"render":[shell,stair],"solids":[],"npcs":[],"portals":[_portal("yihong_stairs_down_20261107",Upper,Down,Lower,LowerReturn,"下楼·接待厅")],"interactions":[],"solid_cells":{},
		"source_context_ids":[Market],"room_source_logical_id":Market,"physical_phase_scope":prior.physical_phase_scope.duplicate(true),"navigation_kind":"AUTHORED_INTERIOR",
		"room_enclosure":{"wall_ground_polygons_px":walls,"native_complete_shell":Media+"upper_shell.png"},"room_display_name":"怡红院·二楼雅阁","yihong_floor_profile":"YIHONG_UPPER_20261107_V1",
	}
	for wall: PackedVector2Array in walls:Core._append_solid(room,wall)
	var chair: Dictionary = {}
	for old: Dictionary in prior.render:
		if old.owner_id=="yihongyuan_guest_chair":chair=old;break
	if not need(not chair.is_empty(),"EXACT_EXISTING_SINGLE_CHAIR_DONOR"):return {}
	for path: String in prior.sources:
		if path.contains(chair.texture.get_file()):room.sources[path]=prior.sources[path]
	for i: int in range(2):
		var foot: Vector2 = [Vector2(525,637),Vector2(1005,664)][i]
		room.render.append(_table("yihong_upper_tea_table_"+str(i),Upper,foot,0.104))
		Core._append_solid(room,_rect(foot-Vector2(66,21),Vector2(132,28)))
		for j: int in range(2):
			var seat := foot+Vector2(-56+112*j,65)
			var row: Dictionary = chair.duplicate(true)
			var id := "yihong_upper_seat_"+str(i)+"_"+str(j)
			row.id=id;row.owner_id=id;row.key=Upper+"/"+id;row.logical_id=Upper
			row.position_px+=seat-chair.foot_px;row.foot_px=seat
			room.render.append(row)
			Core._append_solid(room,_rect(seat-Vector2(16,12),Vector2(32,20)))
	return room

func _route(room: Dictionary,points: Array,label: String) -> void:
	for i: int in range(1,points.size()):
		var start: Vector2 = points[i-1]
		var end: Vector2 = points[i]
		var test := label+":"+str(i)
		if not need(Core.safe_segment(room,start,end,Half) and Core.npc_route_clear(room,start,end,Half),test):
			var steps := maxi(1,ceili(start.distance_to(end)))
			for j: int in range(steps+1):
				var p := start.lerp(end,float(j)/steps)
				var static_safe := Core.safe_body(room,p,Half)
				var actor_safe := Core.npc_route_clear(room,p,p,Half)
				if static_safe and actor_safe:continue
				var body := _rect(p-Half,Half*2.0)
				var hits: Array = []
				for k: int in range(room.solids.size()):
					if not Geometry2D.intersect_polygons(body,room.solids[k]).is_empty():hits.append({"index":k,"polygon":str(room.solids[k])})
				blocked_route_samples[test]={"foot":str(p),"ground_covered":Core.ground_covers(room,Rect2(p-Half,Half*2.0)),"static_safe":static_safe,"actor_safe":actor_safe,"solid_intersections":hits}
				break

func _write_room(room: Dictionary) -> Dictionary:
	var path: String = output+String(room.id)+".bin"
	var bytes: PackedByteArray = var_to_bytes(room)
	var fd := FileAccess.open(path,FileAccess.WRITE)
	if not need(fd!=null,"EXACT_OUTPUT_OPEN:"+room.id):return {}
	fd.store_buffer(bytes);fd.close()
	return {"candidate":path,"bytes":bytes.size(),"sha256":FileAccess.get_sha256(path)}

func _run() -> void:
	output=Home+"compile_actual/"+str(OS.get_process_id())+"/"
	DirAccess.make_dir_recursive_absolute(output)
	if not need(FileAccess.get_sha256(Old)==OldSHA,"EXACT_CURRENT_1F_PREDECESSOR"):finish({});return
	var prior: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(Old))
	if not need(prior.id==Lower and prior.size==Hall and prior.npcs.size()==10 and prior.portals.size()==1,"EXACT_PRIOR_ROOM_ROSTER_PORTAL"):finish({});return
	for role: String in Textures:
		if not _pin(role):finish({});return
	var lower := _lower(prior)
	var upper := _upper(prior)
	if lower.is_empty() or upper.is_empty():finish({});return
	var inverse := lower.duplicate(true)
	for key: String in ["render","sources","solids","solid_cells","portals"]:inverse[key]=prior[key]
	inverse.erase("yihong_floor_profile")
	need(var_to_bytes(inverse)==var_to_bytes(prior),"LOWER_UNOWNED_TYPED_INVERSE")
	need(var_to_bytes(lower.portals[0])==var_to_bytes(prior.portals[0]) and var_to_bytes(lower.npcs)==var_to_bytes(prior.npcs),"ORIGINAL_EXIT_AND_TEN_ACTORS_IDENTICAL")
	for i: int in range(prior.solids.size()):need(prior.solids[i]==lower.solids[i],"ORIGINAL_BLOCKER_UNCHANGED:"+str(i))
	_route(lower,[Vector2(768,850),Vector2(768,594),Vector2(416,594),Up],"LOWER_CENTER_ASCENT")
	_route(lower,[LowerReturn,Vector2(416,600),Vector2(768,600),Vector2(768,920)],"LOWER_RETURN_AND_ORIGINAL_EXIT")
	_route(upper,[UpperArrival,Down],"UPPER_CENTER_DESCENT")
	_route(upper,[UpperArrival,Vector2(768,630),Vector2(768,495)],"UPPER_CENTER_WALKABLE")
	need(not Core.safe_segment(lower,Vector2(326,500),Vector2(416,500),Half) and not Core.safe_segment(lower,Vector2(516,500),Vector2(416,500),Half),"LEFT_AND_RIGHT_STAIR_SIDE_ENTRY_BLOCKED")
	need(not Core.safe_body(lower,Vector2(416,430),Half),"CANNOT_PASS_STAIR_TOP")
	var stair_restore_sample := Vector2(390,500)
	need(Core.safe_body(prior,stair_restore_sample,Half) and Core.npc_route_clear(prior,stair_restore_sample,stair_restore_sample,Half) and not Core.safe_body(lower,stair_restore_sample,Half),"SYNTHETIC_PREDECESSOR_STAIR_FOOT_ONLY")
	need(Core.plain(lower) and Core.plain(upper),"PLAIN_TYPED_VARIANT_PAYLOADS")
	if not problems.is_empty():finish({});return
	var rows := {Lower:_write_room(lower),Upper:_write_room(upper)}
	finish(rows)

func finish(rooms: Dictionary) -> void:
	var report := {"checks":checks,"failures":problems,"rooms":rooms,"media_pins":media_pins,"blocked_route_samples":blocked_route_samples,"canonical_writes":false}
	var fd := FileAccess.open(output+"result.json",FileAccess.WRITE)
	if fd!=null:fd.store_string(JSON.stringify(report,"  ")+"\n");fd.close()
	print(JSON.stringify(report))
	quit(0 if problems.is_empty() and rooms.size()==2 else 1)
