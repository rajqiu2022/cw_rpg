extends RefCounted
## One return-only child. No interior geometry or furniture republishing.
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const PARENT="res://data/maps/luoyang_layout_rooms_20261018t/registry.json"
const PARENT_SHA="6ee6ad3a24c2b2907636ad5220b039c77847adad0d0d54f921f097ea26a4731c"
const OUTPUT="res://data/maps/luoyang_estate_rooms_20261021am/"
const ROOM="luoyang_functional_mansion_candidate_20261016"
const ESTATE="luoyang_estate_riverside_20261021ai"
const META="luoyang_room_successor_20261018t"
static func write_new(path: String,data: Dictionary) -> bool:
	if FileAccess.file_exists(path): return false
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(data,"\t",true,true));file.close();return true
static func native_inverse(scene: SceneScript,original: SceneScript,old_author: Dictionary,old_sha: String) -> bool:
	var inverse:=scene.duplicate(true) as SceneScript
	inverse.map_layout=scene.map_layout.duplicate(true) as WalkableMapLayout
	inverse.set_meta(META,old_sha);var count: int=0
	for row: Dictionary in inverse.map_layout.portals:
		if row.get("target_scene")!=ESTATE: continue
		if row.get("target_pos")!=Vector2(1536.0/3072.0,544.0/2048.0): return false
		row.target_scene=old_author.room.city_id;row.target_pos=E.uv(old_author.room.return_foot_px);count+=1
	return count==1 and B.equal(B.storage(inverse),B.storage(original)) and B.equal(B.storage(inverse.map_layout),B.storage(original.map_layout))
static func publish(track: Callable) -> Dictionary:
	if not track.is_valid() or not track.call(PARENT,PARENT_SHA) or DirAccess.dir_exists_absolute(OUTPUT): return {"ok":false,"error":"AM_RETURN_EXACT_PARENT_NEW_OUTPUT"}
	var prior: Dictionary=E.json(PARENT);var row: Dictionary=prior.get("rooms",{}).get(ROOM,{})
	if prior.get("rooms",{}).size()!=12 or row.is_empty(): return {"ok":false,"error":"AM_RETURN_TWELVE_PARENT"}
	for path: String in row.source_sha256:
		if not track.call(path,String(row.source_sha256[path])): return {"ok":false,"error":"AM_RETURN_PARENT_SOURCE"}
	var old: Dictionary=E.json(row.author_path)
	var original:=ResourceLoader.load(row.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var stored: Variant=bytes_to_var(FileAccess.get_file_as_bytes(row.storage_path))
	if old.get("room",{}).get("city_id")!="ch4_s3_luoyang_market" or old.room.get("building_id")!="market_east_ward_frontage" or E.v(old.room.get("return_foot_px",[]))!=Vector2(2820.8,1704) or original==null or not stored is Dictionary or not B.equal(B.storage(original),stored.scene) or not B.equal(B.storage(original.map_layout),stored.layout): return {"ok":false,"error":"AM_RETURN_EXACT_OLD_ROOM_AND_NATIVE"}
	var author: Dictionary=old.duplicate(true)
	author.room.city_id=ESTATE;author.room.building_id="estate_ak_main_hall";author.room.return_foot_px=[1536,544]
	author.am_return_successor={"parent_author_path":row.author_path,"parent_author_sha256":row.author_sha256,"old_room":old.room.duplicate(true),"geometry_and_furniture_unchanged":true,"reason":"same mansion interior enters actual independent Estate main hall, not old shared street facade"}
	var inverse_author: Dictionary=author.duplicate(true);inverse_author.room=old.room.duplicate(true);inverse_author.erase("am_return_successor")
	if not B.equal(inverse_author,old): return {"ok":false,"error":"AM_RETURN_WHOLE_AUTHOR_INVERSE"}
	var dir: String=OUTPUT+ROOM+"/"
	if DirAccess.make_dir_recursive_absolute(dir)!=OK or not write_new(dir+"author.json",author): return {"ok":false,"error":"AM_RETURN_NEW_AUTHOR"}
	var sha: String=FileAccess.get_sha256(dir+"author.json")
	var scene:=original.duplicate(true) as SceneScript;scene.map_layout=original.map_layout.duplicate(true) as WalkableMapLayout
	var count: int=0
	for portal: Dictionary in scene.map_layout.portals:
		if portal.get("target_scene")!=old.room.city_id: continue
		if portal.get("target_pos")!=E.uv(old.room.return_foot_px): return {"ok":false,"error":"AM_RETURN_EXACT_OLD_EXIT"}
		portal.target_scene=ESTATE;portal.target_pos=Vector2(1536.0/3072.0,544.0/2048.0);count+=1
	scene.set_meta(META,sha)
	if count!=1 or not native_inverse(scene,original,old,row.author_sha256): return {"ok":false,"error":"AM_RETURN_WHOLE_NATIVE_INVERSE"}
	var storage: Dictionary={"scene":B.storage(scene),"layout":B.storage(scene.map_layout)}
	if not B._plain(storage) or ResourceSaver.save(scene.map_layout,dir+"layout.res")!=OK: return {"ok":false,"error":"AM_RETURN_LAYOUT"}
	scene.map_layout=ResourceLoader.load(dir+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
	if scene.map_layout==null or ResourceSaver.save(scene,dir+"scene.res")!=OK: return {"ok":false,"error":"AM_RETURN_SCENE"}
	var file:=FileAccess.open(dir+"storage.bin",FileAccess.WRITE)
	if file==null: return {"ok":false,"error":"AM_RETURN_STORAGE"}
	file.store_buffer(var_to_bytes(storage));file.close()
	var readback:=ResourceLoader.load(dir+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if readback==null or not B.equal(B.storage(readback),storage.scene) or not B.equal(B.storage(readback.map_layout),storage.layout) or not B.equal(bytes_to_var(FileAccess.get_file_as_bytes(dir+"storage.bin")),storage) or not native_inverse(readback,original,old,row.author_sha256): return {"ok":false,"error":"AM_RETURN_READBACK_AND_INVERSE"}
	var next: Dictionary=row.duplicate(true);var pins: Dictionary=row.source_sha256.duplicate(true);var outputs: Dictionary={}
	for name: String in ["author.json","scene.res","layout.res","storage.bin"]:
		pins[dir+name]=FileAccess.get_sha256(dir+name);outputs[dir+name]=pins[dir+name]
	next.author_path=dir+"author.json";next.author_sha256=sha;next.scene_path=dir+"scene.res";next.layout_path=dir+"layout.res";next.storage_path=dir+"storage.bin";next.storage_sha256=pins[dir+"storage.bin"];next.source_sha256=pins
	next.am_return_only_successor=true;next.am_parent_row=row.duplicate(true)
	next.am_return_proof={"whole_author_inverse":true,"whole_native_inverse":true,"interior_geometry_and_furniture_reused":true,"new_city":ESTATE,"new_return_foot":[1536,544]}
	var registry: Dictionary=prior.duplicate(true);registry.rooms[ROOM]=next
	registry.am_return_successor={"parent_path":PARENT,"parent_sha256":PARENT_SHA,"room_ids":[ROOM],"geometry_reused":true}
	var inverse: Dictionary=registry.duplicate(true);inverse.erase("am_return_successor");inverse.rooms[ROOM]=row.duplicate(true)
	if not B.equal(inverse,prior) or not write_new(OUTPUT+"registry.json",registry): return {"ok":false,"error":"AM_RETURN_TWELVE_WHOLE_INVERSE"}
	outputs[OUTPUT+"registry.json"]=FileAccess.get_sha256(OUTPUT+"registry.json")
	return {"ok":true,"registry_path":OUTPUT+"registry.json","registry_sha256":outputs[OUTPUT+"registry.json"],"artifacts":outputs,"changed_rooms":1,"unchanged_rooms":11,"all_twelve_whole_inverse":true,"interior_geometry_rerun":false}
