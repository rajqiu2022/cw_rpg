extends RefCounted
## Only three existing room returns; furniture/geometry/other nine rows are reused.
const AF=preload("res://build/luoyang_city_completion_20261021ai_system01/frontage_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const ORIGINAL="res://data/maps/luoyang_layout_rooms_20261018t/registry.json"
const ORIGINAL_SHA="6ee6ad3a24c2b2907636ad5220b039c77847adad0d0d54f921f097ea26a4731c"
const ROOM_META="luoyang_room_successor_20261018t"
static func json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func write_json(path: String,value: Dictionary) -> bool:
	if FileAccess.file_exists(path): return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(value,"\t",true,true));file.close();return true
static func inverse_native(scene: SceneScript,old_scene: SceneScript,old_author: Dictionary,old_sha: String) -> bool:
	var inverse:=scene.duplicate(true) as SceneScript
	inverse.map_layout=scene.map_layout.duplicate(true) as WalkableMapLayout
	inverse.set_meta(ROOM_META,old_sha)
	var changed: int=0
	for portal: Dictionary in inverse.map_layout.portals:
		if String(portal.get("target_scene",""))!=String(AF.ID): continue
		portal.target_pos=AF.uv(old_author.room.return_foot_px);changed+=1
	return changed==1 and B.equal(B.storage(inverse),B.storage(old_scene)) and B.equal(B.storage(inverse.map_layout),B.storage(old_scene.map_layout))
static func publish(spec: Dictionary,track: Callable) -> Dictionary:
	if not track.is_valid() or not track.call(ORIGINAL,ORIGINAL_SHA): return {"ok":false,"error":"AF_ROOM_PRIOR_REGISTRY"}
	var registry: Dictionary=json(ORIGINAL)
	if registry.get("rooms",{}).size()!=12 or spec.get("room_moves",[]).size()!=3: return {"ok":false,"error":"AF_ROOM_EXACT_COUNTS"}
	var result: Dictionary=registry.duplicate(true);var outputs: Dictionary={};var proofs: Array=[]
	for i: int in 3:
		var move: Dictionary=spec.room_moves[i];var id: String=AF.ROOM_IDS[i]
		if move.get("scene_id")!=id: return {"ok":false,"error":"AF_ROOM_FIXED_THREE_IDS"}
		var row: Dictionary=registry.rooms[id]
		for path: String in row.source_sha256:
			if not track.call(path,String(row.source_sha256[path])): return {"ok":false,"error":"AF_ROOM_OLD_SOURCE"}
		var old_author: Dictionary=json(row.author_path)
		var old_scene:=ResourceLoader.load(row.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var old_layout:=ResourceLoader.load(row.layout_path,"",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		var old_storage: Variant=bytes_to_var(FileAccess.get_file_as_bytes(row.storage_path))
		if old_author.is_empty() or old_scene==null or old_layout==null or not old_storage is Dictionary or AF.v(old_author.room.return_foot_px)!=AF.v(move.old_return_foot_px): return {"ok":false,"error":"AF_ROOM_OLD_NATIVE"}
		old_scene.map_layout=old_layout
		if old_scene.get_meta(ROOM_META,"")!=row.author_sha256 or not B.equal(B.storage(old_scene),old_storage.scene) or not B.equal(B.storage(old_layout),old_storage.layout): return {"ok":false,"error":"AF_ROOM_WHOLE_OLD_STORAGE"}
		var author: Dictionary=old_author.duplicate(true)
		author.room.return_foot_px=move.return_foot_px.duplicate();author.room.building_id=move.building_id
		for key: String in ["door_candidate_source_px","door_candidate_status","external_claim","external_label"]:
			author.room.erase(key) # obsolete old shared-building annotation, not plot text
		author["af_return_successor"]={"parent_author_path":row.author_path,"parent_author_sha256":row.author_sha256,"old_room":old_author.room.duplicate(true),"geometry_and_furniture_unchanged":true}
		var inverse_author: Dictionary=author.duplicate(true);inverse_author.room=old_author.room.duplicate(true);inverse_author.erase("af_return_successor")
		if not B.equal(inverse_author,old_author): return {"ok":false,"error":"AF_ROOM_AUTHOR_WHOLE_INVERSE"}
		var dir: String=AF.ROOM_ROOT+id+"/"
		if DirAccess.dir_exists_absolute(dir) or DirAccess.make_dir_recursive_absolute(dir)!=OK: return {"ok":false,"error":"AF_ROOM_NEW_OUTPUT_ONLY"}
		if not write_json(dir+"author.json",author): return {"ok":false,"error":"AF_ROOM_NEW_AUTHOR"}
		var author_sha: String=FileAccess.get_sha256(dir+"author.json")
		var scene:=old_scene.duplicate(true) as SceneScript
		scene.map_layout=old_layout.duplicate(true) as WalkableMapLayout
		var exits: int=0
		for portal: Dictionary in scene.map_layout.portals:
			if String(portal.get("target_scene",""))!=String(AF.ID): continue
			if portal.get("target_pos")!=AF.uv(old_author.room.return_foot_px): return {"ok":false,"error":"AF_ROOM_EXACT_OLD_RETURN_UV"}
			portal.target_pos=AF.uv(move.return_foot_px);exits+=1
		scene.set_meta(ROOM_META,author_sha)
		if exits!=1 or not inverse_native(scene,old_scene,old_author,row.author_sha256): return {"ok":false,"error":"AF_ROOM_COMPLETE_NATIVE_INVERSE"}
		var storage: Dictionary={"scene":B.storage(scene),"layout":B.storage(scene.map_layout)}
		if ResourceSaver.save(scene.map_layout,dir+"layout.res")!=OK: return {"ok":false,"error":"AF_ROOM_LAYOUT_WRITE"}
		scene.map_layout=ResourceLoader.load(dir+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if scene.map_layout==null or ResourceSaver.save(scene,dir+"scene.res")!=OK: return {"ok":false,"error":"AF_ROOM_SCENE_WRITE"}
		var saved:=ResourceLoader.load(dir+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if saved==null or not B.equal(B.storage(saved),storage.scene) or not B.equal(B.storage(saved.map_layout),storage.layout) or not inverse_native(saved,old_scene,old_author,row.author_sha256): return {"ok":false,"error":"AF_ROOM_WHOLE_READBACK"}
		var file:=FileAccess.open(dir+"storage.bin",FileAccess.WRITE)
		if file==null or not B._plain(storage): return {"ok":false,"error":"AF_ROOM_STORAGE_WRITE"}
		file.store_buffer(var_to_bytes(storage));file.close()
		if not B.equal(bytes_to_var(FileAccess.get_file_as_bytes(dir+"storage.bin")),storage): return {"ok":false,"error":"AF_ROOM_STORAGE_READBACK"}
		var next: Dictionary=row.duplicate(true);var pins: Dictionary=row.source_sha256.duplicate(true)
		for name: String in ["author.json","scene.res","layout.res","storage.bin"]:
			pins[dir+name]=FileAccess.get_sha256(dir+name);outputs[dir+name]=pins[dir+name]
		next.author_path=dir+"author.json";next.author_sha256=author_sha;next.scene_path=dir+"scene.res";next.layout_path=dir+"layout.res";next.storage_path=dir+"storage.bin";next.storage_sha256=pins[dir+"storage.bin"];next.source_sha256=pins
		next["af_return_only_successor"]=true;next["af_parent_row"]=row.duplicate(true)
		next["af_return_proof"]={"whole_author_inverse":true,"whole_native_inverse":true,"geometry_reused_not_rerun":true,"interior_spawn_unchanged":true,"return_uv":var_to_str(AF.uv(move.return_foot_px))}
		result.rooms[id]=next
		proofs.append({"id":id,"building_id":move.building_id,"old_return_foot_px":move.old_return_foot_px,"return_foot_px":move.return_foot_px,"geometry_unchanged":B.equal(author.geometry,old_author.geometry),"furniture_unchanged":B.equal(author.furniture,old_author.furniture)})
	result["af_return_successor"]={"parent_path":ORIGINAL,"parent_sha256":ORIGINAL_SHA,"room_ids":AF.ROOM_IDS.duplicate(),"geometry_reused":true}
	var inverse: Dictionary=result.duplicate(true);inverse.erase("af_return_successor")
	for id: String in AF.ROOM_IDS: inverse.rooms[id]=inverse.rooms[id].af_parent_row.duplicate(true)
	if not B.equal(inverse,registry): return {"ok":false,"error":"AF_ROOM_ALL_TWELVE_ROWS_WHOLE_INVERSE"}
	if not write_json(AF.ROOM_ROOT+"registry.json",result): return {"ok":false,"error":"AF_ROOM_NEW_REGISTRY"}
	outputs[AF.ROOM_ROOT+"registry.json"]=FileAccess.get_sha256(AF.ROOM_ROOT+"registry.json")
	return {"ok":true,"registry_path":AF.ROOM_ROOT+"registry.json","registry_sha256":outputs[AF.ROOM_ROOT+"registry.json"],"artifact_sha256":outputs,"changed_rooms":3,"unchanged_rooms":9,"proofs":proofs,"all_twelve_whole_inverse":true,"not_room_geometry_or_Field_credit":true}


