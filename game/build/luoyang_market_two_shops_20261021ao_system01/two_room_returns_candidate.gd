extends RefCounted
## Two return-only children; active AM registry is only a later explicit deployment target.
const AO=preload("res://build/luoyang_market_two_shops_20261021ao_system01/two_shops_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
const CURRENT="res://data/maps/luoyang_estate_rooms_20261021am/registry.json"
const CURRENT_SHA="167f4a16816224974f4c41b1b753cf7257bfdd8a9f096dbc0c79351c93b88d4c"
const SNAPSHOT="res://build/luoyang_market_two_shops_20261021ao_system01/before/registry_AN_167F.json"
const REGISTRY_CANDIDATE="res://build/luoyang_market_two_shops_20261021ao_system01/publication_assets/registry_candidate.json"
const META="luoyang_room_successor_20261018t"
const AN_PROOF="res://build/luoyang_estate_courtyard_20261021an_system01/publish_mansion_return_dependency_successor.gd"
const AN_PROOF_SHA="1e10441669105e303dc87ef2867adc9d78d10cdee5467feff8cc28b1a607ee03"
static func json(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
static func write_new(path: String,value: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var f:=FileAccess.open(path,FileAccess.WRITE)
	if f==null: return false
	f.store_string(JSON.stringify(value,"\t",true,true));f.close();return true
static func inverse_native(scene: SceneScript,parent: SceneScript,old_sha: String) -> bool:
	var inverse:=scene.duplicate(true) as SceneScript;inverse.map_layout=scene.map_layout.duplicate(true) as WalkableMapLayout;inverse.set_meta(META,old_sha)
	if inverse.map_layout.portals.size()!=parent.map_layout.portals.size(): return false
	var count: int=0
	for i: int in inverse.map_layout.portals.size():
		if inverse.map_layout.portals[i].get("target_scene")==String(AO.ID):
			inverse.map_layout.portals[i]=parent.map_layout.portals[i].duplicate(true);count+=1
	return count==1 and B.equal(B.storage(inverse),B.storage(parent)) and B.equal(B.storage(inverse.map_layout),B.storage(parent.map_layout))
static func publish(spec: Dictionary,track: Callable) -> Dictionary:
	if not AO.spec_valid(spec) or not track.is_valid() or not track.call(CURRENT,CURRENT_SHA) or not track.call(AN_PROOF,AN_PROOF_SHA): return {"ok":false,"error":"AO_TWO_ROOM_EXACT_PUBLISHED_PARENT"}
	if FileAccess.file_exists(SNAPSHOT) or FileAccess.file_exists(REGISTRY_CANDIDATE): return {"ok":false,"error":"AO_NEW_ROOM_OUTPUT_ONLY"}
	var parent: Dictionary=json(CURRENT)
	if parent.get("rooms",{}).size()!=12: return {"ok":false,"error":"AO_PARENT_TWELVE"}
	var chain: Variant=load(AN_PROOF)
	var succession: Dictionary=chain.district_successor(track)
	if succession.is_empty(): return {"ok":false,"error":"AO_EXACT_INHERITED_AB_AE_DISTRICT_EXECUTION_CHAIN"}
	var registry: Dictionary=parent.duplicate(true);var artifacts: Dictionary={};var proofs: Array=[]
	for i: int in 2:
		var move: Dictionary=spec.room_moves[i];var id: String=AO.ROOM_IDS[i];var row: Dictionary=parent.rooms[id]
		if move.scene_id!=id or row.source_sha256.get(chain.DISTRICT)!=chain.DISTRICT_OLD: return {"ok":false,"error":"AO_FIXED_TWO_OLD_ROOM_SOURCES"}
		for p: String in row.source_sha256:
			if not track.call(p,chain.DISTRICT_NOW if p==chain.DISTRICT else String(row.source_sha256[p])): return {"ok":false,"error":"AO_PARENT_DECLARED_SOURCE:"+p}
		var old: Dictionary=json(row.author_path)
		var original:=ResourceLoader.load(row.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var stored: Variant=bytes_to_var(FileAccess.get_file_as_bytes(row.storage_path))
		if original==null or not stored is Dictionary or old.get("room",{}).get("city_id")!=String(AO.ID) or AO.v(old.room.return_foot_px)!=AO.v(move.old_return_foot_px) or not B.equal(B.storage(original),stored.scene) or not B.equal(B.storage(original.map_layout),stored.layout): return {"ok":false,"error":"AO_EXACT_OLD_ROOM_NATIVE_AND_RETURN"}
		var author: Dictionary=old.duplicate(true);author.room.return_foot_px=move.return_foot_px.duplicate();author.room.building_id=move.building_id
		author["ao_return_successor"]={"parent_author_path":row.author_path,"parent_author_sha256":row.author_sha256,"old_room":old.room.duplicate(true),"room_geometry_furniture_dialog_spawn_unchanged":true}
		var inverse: Dictionary=author.duplicate(true);inverse.room=old.room.duplicate(true);inverse.erase("ao_return_successor")
		if not B.equal(inverse,old): return {"ok":false,"error":"AO_ROOM_AUTHOR_COMPLETE_INVERSE"}
		var dir: String=AO.ROOM_ROOT+id+"/"
		if DirAccess.dir_exists_absolute(dir) or not write_new(dir+"author.json",author): return {"ok":false,"error":"AO_NEW_AUTHOR_ONLY"}
		var author_sha: String=FileAccess.get_sha256(dir+"author.json")
		var scene:=original.duplicate(true) as SceneScript;scene.map_layout=original.map_layout.duplicate(true) as WalkableMapLayout;var exits: int=0
		for portal: Dictionary in scene.map_layout.portals:
			if portal.get("target_scene")!=String(AO.ID): continue
			if portal.get("target_pos")!=AO.uv(move.old_return_foot_px): return {"ok":false,"error":"AO_EXACT_OLD_ROOM_EXIT_UV"}
			portal.target_pos=AO.uv(move.return_foot_px);exits+=1
		scene.set_meta(META,author_sha)
		if exits!=1 or not inverse_native(scene,original,row.author_sha256): return {"ok":false,"error":"AO_ROOM_NATIVE_COMPLETE_INVERSE"}
		var storage: Dictionary={"scene":B.storage(scene),"layout":B.storage(scene.map_layout)}
		if ResourceSaver.save(scene.map_layout,dir+"layout.res")!=OK: return {"ok":false,"error":"AO_ROOM_LAYOUT_SAVE"}
		scene.map_layout=ResourceLoader.load(dir+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if scene.map_layout==null or ResourceSaver.save(scene,dir+"scene.res")!=OK: return {"ok":false,"error":"AO_ROOM_SCENE_SAVE"}
		var f:=FileAccess.open(dir+"storage.bin",FileAccess.WRITE)
		if f==null or not B._plain(storage): return {"ok":false,"error":"AO_ROOM_STORAGE_PLAIN"}
		f.store_buffer(var_to_bytes(storage));f.close()
		var readback:=ResourceLoader.load(dir+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if readback==null or not B.equal(B.storage(readback),storage.scene) or not B.equal(B.storage(readback.map_layout),storage.layout) or not B.equal(bytes_to_var(FileAccess.get_file_as_bytes(dir+"storage.bin")),storage) or not inverse_native(readback,original,row.author_sha256): return {"ok":false,"error":"AO_ROOM_READBACK_WHOLE_INVERSE"}
		var next: Dictionary=row.duplicate(true);var pins: Dictionary=row.source_sha256.duplicate(true)
		pins[chain.DISTRICT]=chain.DISTRICT_NOW;pins[AN_PROOF]=AN_PROOF_SHA
		for p: String in succession.proof_sources: pins[p]=succession.proof_sources[p]
		for name: String in ["author.json","layout.res","scene.res","storage.bin"]: pins[dir+name]=FileAccess.get_sha256(dir+name);artifacts[dir+name]=pins[dir+name]
		next.author_path=dir+"author.json";next.author_sha256=author_sha;next.layout_path=dir+"layout.res";next.scene_path=dir+"scene.res";next.storage_path=dir+"storage.bin";next.storage_sha256=pins[dir+"storage.bin"];next.source_sha256=pins
		next["ao_return_only_successor"]=true;next["ao_parent_row"]=row.duplicate(true);next["ao_execution_dependency_chain"]=succession.duplicate(true);registry.rooms[id]=next
		proofs.append({"room_id":id,"old_return":move.old_return_foot_px,"new_return":move.return_foot_px,"furniture_geometry_spawn_dialog_unchanged":true,"native_storage_paths_rebound_not_same_resource_path_claim":true})
	registry["ao_return_successor"]={"parent_snapshot_path":SNAPSHOT,"parent_sha256":CURRENT_SHA,"room_ids":AO.ROOM_IDS.duplicate(),"geometry_reused":true,"AN_mansion_and_other_ten_rows_unchanged":true}
	var inverse: Dictionary=registry.duplicate(true);inverse.erase("ao_return_successor")
	for id: String in AO.ROOM_IDS: inverse.rooms[id]=inverse.rooms[id].ao_parent_row.duplicate(true)
	if not B.equal(inverse,parent): return {"ok":false,"error":"AO_ALL_TWELVE_REGISTRY_WHOLE_INVERSE"}
	if DirAccess.make_dir_recursive_absolute(SNAPSHOT.get_base_dir())!=OK: return {"ok":false,"error":"AO_IMMUTABLE_PARENT_FOLDER"}
	var copy:=FileAccess.open(SNAPSHOT,FileAccess.WRITE)
	if copy==null: return {"ok":false,"error":"AO_PARENT_SNAPSHOT_WRITE"}
	copy.store_buffer(FileAccess.get_file_as_bytes(CURRENT));copy.close()
	if FileAccess.get_sha256(SNAPSHOT)!=CURRENT_SHA or not write_new(REGISTRY_CANDIDATE,registry): return {"ok":false,"error":"AO_EXACT_SNAPSHOT_AND_NEW_REGISTRY"}
	artifacts[SNAPSHOT]=CURRENT_SHA;artifacts[REGISTRY_CANDIDATE]=FileAccess.get_sha256(REGISTRY_CANDIDATE)
	return {"ok":true,"registry_candidate_path":REGISTRY_CANDIDATE,"registry_target_path":CURRENT,"registry_sha256":artifacts[REGISTRY_CANDIDATE],"artifacts":artifacts,"changed_rooms":2,"unchanged_rooms":10,"all_twelve_whole_inverse":true,"proofs":proofs,"interior_geometry_rerun":false,"active_registry_not_written":true}
