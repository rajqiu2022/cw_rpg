extends RefCounted
## Native return-only descendants of five existing IDs. No room geometry job.
const ROOT="res://data/maps/luoyang_full_city_20261022ap/rooms/"
const BUILD="res://build/luoyang_city_full_rollout_20261022ap_system01/"
const SNAPSHOT=BUILD+"before/registry_AO_4D056.json"
const REGISTRY_CANDIDATE=BUILD+"publication_assets/registry_candidate.json"
const META="luoyang_room_successor_20261018t"
const SIZE=Vector2(3072,2048)
const HISTORICAL_D="res://scripts/city/luoyang_district_life_20261016f.gd"
const HISTORICAL_D_SHA="bcd4e401303e97cd65075c86c9bba6d08c4b3d542a36a1ec546f73c949670118"
const HISTORICAL_D_SNAPSHOT="res://build/luoyang_docks_district08_20261019aa_source01/before/District_original.gd"
const EXECUTING_D_SHA="1b44e7452f7fac5056c6da65af1560d0dafdb2ad61d0020291ad2a17a7842fa9"
const IDS=["luoyang_functional_pawnshop_candidate_20261016","luoyang_market_north_market_front_interior_20261015","luoyang_market_market_west_ward_frontage_interior_20261015","luoyang_market_market_northwest_rear_frontage_interior_20261015","luoyang_market_southeast_market_front_interior_20261015"]
static func b() -> Variant: return load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
static func v(raw: Array) -> Vector2: return Vector2(raw[0],raw[1])
static func json(path: String) -> Dictionary:
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(path));return raw if raw is Dictionary else {}
static func fail(error: String,detail: String="") -> Dictionary: return {"ok":false,"error":error,"detail":detail}
static func write_json(path: String,raw: Dictionary) -> bool:
	if FileAccess.file_exists(path) or DirAccess.make_dir_recursive_absolute(path.get_base_dir())!=OK: return false
	var f:=FileAccess.open(path,FileAccess.WRITE)
	if f==null: return false
	f.store_string(JSON.stringify(raw,"\t",true,true));f.close();return true
static func inverse_native(child: SceneScript,parent: SceneScript,move: Dictionary,parent_author_sha: String) -> bool:
	if child==null or child.map_layout==null or parent==null or parent.map_layout==null or child.map_layout.portals.size()!=parent.map_layout.portals.size(): return false
	var inverse:=child.duplicate(true) as SceneScript;inverse.map_layout=child.map_layout.duplicate(true) as WalkableMapLayout;inverse.set_meta(META,parent_author_sha)
	var count: int=0
	for i: int in inverse.map_layout.portals.size():
		var old: Dictionary=parent.map_layout.portals[i]
		if old.get("target_scene")!=move.old_city: continue
		if old.get("target_pos")!=v(move.old_return)/SIZE: return false
		var actual: Dictionary=inverse.map_layout.portals[i]
		if actual.get("target_scene")!=move.city or actual.get("target_pos")!=v(move["return"])/SIZE: return false
		inverse.map_layout.portals[i]=old.duplicate(true);count+=1
	return count==1 and b().equal(b().storage(inverse),b().storage(parent)) and b().equal(b().storage(inverse.map_layout),b().storage(parent.map_layout))
static func publish(spec: Dictionary,track: Callable) -> Dictionary:
	if spec.get("schema_version")!=1 or spec.get("status")!="ROOT_BOUND_FIVE_RETURN_ONLY_MOVES" or not spec.get("moves") is Array or spec.moves.size()!=5 or not track.is_valid() or not track.call(spec.parent_registry,spec.parent_registry_sha256): return fail("FIVE_RETURN_AUTHOR_NOT_BOUND")
	var parent: Dictionary=json(spec.parent_registry)
	if parent.get("rooms",{}).size()!=12 or FileAccess.file_exists(SNAPSHOT) or FileAccess.file_exists(REGISTRY_CANDIDATE): return fail("EXACT_TWELVE_AND_NEW_OUTPUTS")
	var pending: Array[Dictionary]=[]
	# Preflight every historical source/native before writing any descendant.
	for i: int in 5:
		var move: Dictionary=spec.moves[i]
		if move.get("scene_id")!=IDS[i] or not parent.rooms.has(IDS[i]): return fail("FIXED_FIVE_ROOM_IDENTITIES")
		var row: Dictionary=parent.rooms[IDS[i]]
		for path: String in row.source_sha256:
			if path==HISTORICAL_D and row.source_sha256[path]==HISTORICAL_D_SHA:
				# This is the immutable room's publication input, not permission to
				# execute arbitrary changed code. Preserve its historical field;
				# the final AP authority must independently admit its exact chain.
				if not track.call(HISTORICAL_D_SNAPSHOT,HISTORICAL_D_SHA) or not track.call(HISTORICAL_D,EXECUTING_D_SHA): return fail("ROOM_HISTORICAL_EXECUTABLE_INPUT",path)
				continue
			if not track.call(path,row.source_sha256[path]): return fail("ROOM_PARENT_SOURCE",path)
		var author: Dictionary=json(row.author_path)
		var scene:=ResourceLoader.load(row.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var stored: Variant=bytes_to_var(FileAccess.get_file_as_bytes(row.storage_path))
		if scene==null or scene.map_layout==null or not stored is Dictionary or not b().equal(b().storage(scene),stored.scene) or not b().equal(b().storage(scene.map_layout),stored.layout) or author.get("room",{}).get("city_id")!=move.old_city or v(author.room.return_foot_px)!=v(move.old_return) or DirAccess.dir_exists_absolute(ROOT+IDS[i]): return fail("WHOLE_OLD_ROOM_AND_RETURN",IDS[i])
		pending.append({"move":move,"row":row,"author":author,"scene":scene})
	var result: Dictionary=parent.duplicate(true);var artifacts: Dictionary={};var proof: Array=[]
	for task: Dictionary in pending:
		var move: Dictionary=task.move;var old: Dictionary=task.author;var row: Dictionary=task.row;var parent_scene: SceneScript=task.scene
		var author: Dictionary=old.duplicate(true)
		author.room.city_id=move.city;author.room.building_id=move.building_id;author.room.return_foot_px=move["return"].duplicate()
		author["ap_return_only_successor"]={"parent_author_path":row.author_path,"parent_author_sha256":row.author_sha256,"old_room":old.room.duplicate(true),"geometry_furniture_NPC_dialog_spawn_unchanged":true}
		var inverse: Dictionary=author.duplicate(true);inverse.room=old.room.duplicate(true);inverse.erase("ap_return_only_successor")
		if not b().equal(inverse,old): return fail("ROOM_AUTHOR_COMPLETE_INVERSE",move.scene_id)
		var directory: String=ROOT+move.scene_id+"/"
		if not write_json(directory+"author.json",author): return fail("NEW_ROOM_AUTHOR",move.scene_id)
		var author_sha: String=FileAccess.get_sha256(directory+"author.json")
		var scene:=parent_scene.duplicate(true) as SceneScript;scene.map_layout=parent_scene.map_layout.duplicate(true) as WalkableMapLayout
		var changed: int=0
		for portal: Dictionary in scene.map_layout.portals:
			if portal.get("target_scene")!=move.old_city: continue
			if portal.get("target_pos")!=v(move.old_return)/SIZE: return fail("OLD_PORTAL_RETURN_UV",move.scene_id)
			portal.target_scene=move.city;portal.target_pos=v(move["return"])/SIZE;changed+=1
		scene.set_meta(META,author_sha)
		if changed!=1 or not inverse_native(scene,parent_scene,move,row.author_sha256): return fail("WHOLE_RETURN_NATIVE_INVERSE",move.scene_id)
		var stored: Dictionary={"scene":b().storage(scene),"layout":b().storage(scene.map_layout)}
		if ResourceSaver.save(scene.map_layout,directory+"layout.res")!=OK: return fail("NEW_LAYOUT_SAVE")
		scene.map_layout=ResourceLoader.load(directory+"layout.res","",ResourceLoader.CACHE_MODE_IGNORE) as WalkableMapLayout
		if scene.map_layout==null or ResourceSaver.save(scene,directory+"scene.res")!=OK: return fail("NEW_SCENE_SAVE")
		var f:=FileAccess.open(directory+"storage.bin",FileAccess.WRITE)
		if f==null or not b()._plain(stored): return fail("PLAIN_STORAGE_WRITE")
		f.store_buffer(var_to_bytes(stored));f.close()
		var read:=ResourceLoader.load(directory+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		if read==null or not b().equal(b().storage(read),stored.scene) or not b().equal(b().storage(read.map_layout),stored.layout) or not b().equal(bytes_to_var(FileAccess.get_file_as_bytes(directory+"storage.bin")),stored) or not inverse_native(read,parent_scene,move,row.author_sha256): return fail("WHOLE_NATIVE_STORAGE_READBACK",move.scene_id)
		var child: Dictionary=row.duplicate(true);var pins: Dictionary=row.source_sha256.duplicate(true)
		for name: String in ["author.json","layout.res","scene.res","storage.bin"]: pins[directory+name]=FileAccess.get_sha256(directory+name);artifacts[directory+name]=pins[directory+name]
		child.author_path=directory+"author.json";child.author_sha256=author_sha;child.scene_path=directory+"scene.res";child.layout_path=directory+"layout.res";child.storage_path=directory+"storage.bin";child.storage_sha256=pins[directory+"storage.bin"];child.source_sha256=pins
		child["ap_return_only_successor"]=true;child["ap_parent_row"]=row.duplicate(true);result.rooms[move.scene_id]=child
		proof.append({"id":move.scene_id,"old_city":move.old_city,"new_city":move.city,"old_return":move.old_return,"new_return":move["return"],"geometry_replayed":false,"whole_author_and_native_inverse":true})
	result["ap_return_successor"]={"parent_snapshot":SNAPSHOT,"parent_sha256":spec.parent_registry_sha256,"room_ids":IDS.duplicate(),"other_seven_rows_unchanged":true,"no_interior_geometry_replay":true}
	var inverse: Dictionary=result.duplicate(true);inverse.erase("ap_return_successor")
	for id: String in IDS: inverse.rooms[id]=inverse.rooms[id].ap_parent_row.duplicate(true)
	if not b().equal(inverse,parent): return fail("ALL_TWELVE_REGISTRY_INVERSE")
	if DirAccess.make_dir_recursive_absolute(SNAPSHOT.get_base_dir())!=OK: return fail("PARENT_SNAPSHOT_DIRECTORY")
	var f:=FileAccess.open(SNAPSHOT,FileAccess.WRITE)
	if f==null: return fail("SNAPSHOT_WRITE")
	f.store_buffer(FileAccess.get_file_as_bytes(spec.parent_registry));f.close()
	if FileAccess.get_sha256(SNAPSHOT)!=spec.parent_registry_sha256 or not write_json(REGISTRY_CANDIDATE,result): return fail("REGISTRY_AND_SNAPSHOT_READBACK")
	artifacts[SNAPSHOT]=spec.parent_registry_sha256;artifacts[REGISTRY_CANDIDATE]=FileAccess.get_sha256(REGISTRY_CANDIDATE)
	return {"ok":true,"artifacts":artifacts,"proofs":proof,"registry_path":REGISTRY_CANDIDATE,"registry_sha256":artifacts[REGISTRY_CANDIDATE],"five_returns_changed_seven_rows_exact":true,"old_registry_not_written":true,"room_geometry_replayed":false,"historical_D_input":{"path":HISTORICAL_D,"sha256":HISTORICAL_D_SHA,"snapshot":HISTORICAL_D_SNAPSHOT,"execution_checked_separately":true,"formal_AP_execution_chain_admission_not_granted_by_publication":true}}
