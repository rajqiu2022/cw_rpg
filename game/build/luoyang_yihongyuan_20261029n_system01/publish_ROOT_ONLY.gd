extends SceneTree
## Root-only single publication. No current sources/bins/PNG/save are written.
const Core = preload("res://build/luoyang_regions_20261027d_source01/region_compiler.gd")
const Factory = preload("res://build/luoyang_yihongyuan_20261029n_system01/room_factory.gd")
const HOME := "res://build/luoyang_yihongyuan_20261029n_system01/"
const OLD_MANIFEST := "res://build/luoyang_regions_20261027d_source01/region_runtime_manifest_BUILD.json"
const CIVIC := "luoyang_civic_market_region_27d"
const MARKET := "ch4_s3_luoyang_market"
const ROOM := "yihongyuan27n_interior"
const TEXTURE := "res://art/maps/luoyang_yihongyuan_20261029n/yihongyuan_exterior_v1.png"
const CONTACT := Vector2(5206.18,4174.42)
const SCALE := 1.1521231617647059
const ANCHOR := Vector2(664,1010)
const DOOR := Vector2(5206.18,4185)
const RETURN := Vector2(5206.18,4280)
var checks: int=0
var problems: Array[String]=[]
var output: String

func _initialize() -> void:
	call_deferred("run")
func check(test: bool, message: String) -> bool:
	checks+=1
	if not test:problems.append(message);push_error(message)
	return test
func write_json(path: String,value: Dictionary) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(value,"  ")+"\n");file.close()
func bind(path: String) -> Dictionary:
	return {"path":path,"sha256":FileAccess.get_sha256(path),"bytes":FileAccess.get_file_as_bytes(path).size()}
func write_bin(name: String,value: Dictionary) -> Dictionary:
	var path: String=output+name+".bin"
	var file:=FileAccess.open(path,FileAccess.WRITE);file.store_buffer(var_to_bytes(value));file.close()
	check(var_to_bytes(bytes_to_var(FileAccess.get_file_as_bytes(path)))==var_to_bytes(value),"NEW_BIN_TYPED_ROUNDTRIP:"+name)
	return bind(path)
func world_points(raw: Array) -> PackedVector2Array:
	var result:=PackedVector2Array()
	for p: Variant in raw:result.append(CONTACT+(Core.vec(p)-ANCHOR)*SCALE)
	return result
func native_layers() -> Array:
	# The central stair apron is ground: its visible pixels cannot cover legs.
	# Clip the high volume on either side without changing one PNG pixel.
	var canvas:=PackedVector2Array([Vector2.ZERO,Vector2(1441,0),Vector2(1441,1206),Vector2(0,1206)])
	var steps:=Factory.points([[580,917],[748,923],[775,1206],[540,1206]])
	var result: Array=[]
	for polygon: PackedVector2Array in Geometry2D.intersect_polygons(canvas,steps):
		result.append({"id":"YihongyuanFrontStairGround","polygon":polygon,"uv":polygon.duplicate(),"z_index":-2})
	var ordinal: int=0
	for polygon: PackedVector2Array in Geometry2D.clip_polygons(canvas,steps):
		result.append({"id":"YihongyuanHighBody"+str(ordinal),"polygon":polygon,"uv":polygon.duplicate(),"z_index":floori(CONTACT.y/8.0)});ordinal+=1
	return result

func run() -> void:
	output=HOME+"output/"+str(OS.get_process_id())+"/"
	DirAccess.make_dir_recursive_absolute(output)
	var old_raw: PackedByteArray=FileAccess.get_file_as_bytes(OLD_MANIFEST)
	var manifest: Dictionary=JSON.parse_string(old_raw.get_string_from_utf8())
	var author: Dictionary=Core.read_json(manifest.author.path,manifest.author.sha256)
	if not check(not author.is_empty() and manifest.compiled_bindings.size()==9,"CURRENT_NINE_IMMUTABLE_REGIONS"):finish();return
	var baseline: Dictionary={}
	for id: String in manifest.compiled_bindings:
		var binding: Dictionary=manifest.compiled_bindings[id]
		if not check(FileAccess.get_sha256(binding.path)==binding.sha256,"ORIGINAL_BIN_SOURCE:"+id):finish();return
		baseline[id]=FileAccess.get_file_as_bytes(binding.path)
	var civic: Dictionary=bytes_to_var(baseline[CIVIC])
	var before: Dictionary=civic.duplicate(true)
	var rows: Array=civic.render.filter(func(row: Dictionary) -> bool:return row.get("owner_id")=="spring_house_complete_v1")
	if not check(rows.size()==1 and civic.solids.size()==130,"FIXED_SPRING_ROW_AND_OLD_SOLIDS"):finish();return
	var row: Dictionary=rows[0]
	if not check(row.key==MARKET+"/spring_house_complete_v1" and row.foot_px==Vector2(5200,4160),"EXACT_OLD_FACADE_OWNER"):finish();return
	var footprint:=world_points([[230,951],[400,834],[1259,912],[1090,1028]])
	var channel:=world_points([[580,917],[748,923],[760,1070],[567,1064]])
	var new_solids: Array=Geometry2D.clip_polygons(footprint,channel)
	if not check(not new_solids.is_empty(),"SOURCE_FOUNDATION_MINUS_CENTRAL_APRON"):finish();return
	var old_last: PackedVector2Array=civic.solids[129]
	if not check(old_last.size()==8 and old_last[0].distance_to(Vector2(5885.97998046875,4055.969970703125))<.01,"EXACT_ONLY_SPRING_OLD_SOLID"):finish();return
	civic.solids.remove_at(129)
	for polygon: PackedVector2Array in new_solids:civic.solids.append(polygon)
	civic.solid_cells={}
	var all_solids: Array=civic.solids;civic.solids=[]
	for polygon: PackedVector2Array in all_solids:Core._append_solid(civic,polygon)
	row.texture=TEXTURE;row.texture_size_px=Vector2(1441,1206)
	row.foot_px=CONTACT;row.position_px=CONTACT-ANCHOR*SCALE;row.scale=Vector2.ONE*SCALE
	row["display_name"]="怡红院";row["yihongyuan_native_layers"]=native_layers()
	if not check(Factory.media(TEXTURE,civic.sources),"NEW_FACADE_IMPORTED_MEDIA"):finish();return
	var portal: Dictionary={"id":"enter_yihongyuan27n","key":MARKET+"/enter_yihongyuan27n","logical_id":MARKET,"foot":DOOR,"foot_px":DOOR,"size_px":Vector2(100,64),"legacy_source_uv":RETURN/Vector2(6144,4608),"return_foot":RETURN,"data":{"id":"enter_yihongyuan27n","pos":DOOR/Vector2(6144,4608),"source_spawn_pos":RETURN/Vector2(6144,4608),"size":Vector2(100,64)/Vector2(6144,4608),"target_scene":ROOM,"target_pos":Vector2(768,850)/Vector2(1536,1024),"label":"进入怡红院","auto_trigger":false,"region27d_target":{"region_id":ROOM,"logical_id":ROOM,"foot_px":[768,850]}}}
	civic.portals.append(portal)
	var market: Dictionary=Core.load_terminal(author.terminal_bindings[MARKET])
	if not check(not market.is_empty(),"REUSE_CURRENT_MARKET_TERMINAL_NO_RECAPTURE"):finish();return
	var room: Dictionary=Factory.compile(author,market)
	if not check(room.get("ok")==true,"ONE_ROOM_FACTORY:"+str(room.get("error",""))):finish();return
	check(room.npcs.size()==6 and room.yihongyuan_daily.size()==4,"SIX_ORDINARY_ADULTS_FOUR_MATCHED_DIALOGUES")
	check(Core.safe_body(civic,DOOR,Vector2(17,12)) and Core.npc_route_clear(civic,DOOR,DOOR,Vector2(17,12)),"REAL_FRONT_DOOR_FULL_BODY")
	check(Core.safe_segment(civic,RETURN,DOOR,Vector2(17,12)) and Core.npc_route_clear(civic,RETURN,DOOR,Vector2(17,12)),"STREET_RETURN_TO_DOOR_CLEAR")
	check(not Core.safe_body(civic,CONTACT+(Vector2(400,910)-ANCHOR)*SCALE,Vector2(17,12)),"WEST_FOUNDATION_REJECT")
	check(not Core.safe_body(civic,CONTACT+(Vector2(1050,930)-ANCHOR)*SCALE,Vector2(17,12)),"EAST_FOUNDATION_REJECT")
	var rollback: Dictionary=civic.duplicate(true)
	rollback.render=before.render;rollback.solids=before.solids;rollback.solid_cells=before.solid_cells;rollback.sources=before.sources;rollback.portals=before.portals
	check(var_to_bytes(rollback)==var_to_bytes(before),"CIVIC_ALL_OTHER_TYPED_FIELDS_UNCHANGED")
	if not problems.is_empty():finish();return
	manifest.compiled_bindings[CIVIC]=write_bin(CIVIC,civic)
	manifest.compiled_bindings[ROOM]=write_bin(ROOM,room)
	# The old author stays immutable. This explicit publication successor adds
	# metadata for the exact one-room factory; all eight other bindings are kept.
	var added_author: Dictionary=author.duplicate(true)
	added_author["yihongyuan27n_publication"]={"room_id":ROOM,"definition":HOME+"interior_definition_CANDIDATE.json","exterior_native_anchor":[664,1010],"contact_world":[CONTACT.x,CONTACT.y],"scale":SCALE}
	write_json(output+"regions_author_READY.json",added_author)
	manifest.author=bind(output+"regions_author_READY.json")
	for id: String in manifest.compiled_bindings:
		if id==CIVIC or id==ROOM:continue
		check(FileAccess.get_file_as_bytes(manifest.compiled_bindings[id].path)==baseline[id],"OTHER_EIGHT_BIN_BYTES_IDENTICAL:"+id)
	var ready: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(HOME+"runtime_modules_CANDIDATE.json"))
	for path: String in ready:
		var input: String=String(ready[path])
		manifest.runtime_modules[path]=FileAccess.get_sha256(input)
	manifest["status"]="YIHONGYUAN29N_ONE_ROOM_PUBLICATION_NOT_FIELD_ACCEPTANCE"
	write_json(output+"region_runtime_manifest_READY.json",manifest)
	var result: Dictionary={"passed":problems.is_empty(),"checks":checks,"failures":problems,"output":output,"manifest":bind(output+"region_runtime_manifest_READY.json"),"civic":manifest.compiled_bindings[CIVIC],"room":manifest.compiled_bindings[ROOM],"door_foot":[DOOR.x,DOOR.y],"street_return":[RETURN.x,RETURN.y],"room_spawn":[768,850],"room_exit":[768,920],"production_writes":0,"other_eight_bin_bytes_identical":true}
	write_json(output+"result.json",result)
	print(JSON.stringify(result));quit(0 if problems.is_empty() else 1)
func finish() -> void:
	write_json(output+"result.json",{"passed":false,"checks":checks,"failures":problems,"production_writes":0})
	quit(1)
