extends "res://tests/test_luoyang_estate_formal_travel_remaining_READY_20261021an.gd"
## Root-only small typed readback. No geometry, pixel, collector or Field rerun.
const PUBLICATION: String = "res://build/luoyang_market_two_shops_20261021ao_system01/publication/53104/result.json"
const PUBLICATION_SHA: String = "6ea8b224c1ff2403441d927325e928f5f42e69012bb65c6c92b5f7da94f15ad7"
const AUTHOR: String = "res://build/luoyang_market_two_shops_20261021ao_system01/author_READY.json"
const AUTHOR_SHA: String = "227735f42114e843e62109b127a3c57d4a7b9ffdb4e545799ba9d50dc77cc849"
const AO: String = "res://build/luoyang_market_two_shops_20261021ao_system01/two_shops_READY.gd"
const BUNDLE: String = "res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const NATIVE: String = "res://data/maps/luoyang_market_two_shops_20261021ao/runtime/ch4_s3_luoyang_market/"

func _verify() -> bool:
	if not track(PUBLICATION,PUBLICATION_SHA): return false
	if not track(AUTHOR,AUTHOR_SHA): return false
	var proof: Dictionary = _json(PUBLICATION)
	if not check(proof.get("passed") == true and proof.get("published") == true and proof.get("source_first") == proof.get("source_final") and proof.get("native_count") == 24 and proof.get("district_count") == 36 and proof.get("geometry",{}).get("all_old_routes_retested") == false and proof.get("two_room_returns",{}).get("interior_geometry_rerun") == false,"Fixed completed CPU component, no route/interior rerun"): return false
	for path: String in proof.source_first:
		if not track(path,proof.source_first[path]): return false
	for artifacts: Dictionary in [proof.artifacts,proof.two_room_returns.artifacts]:
		for path: String in artifacts:
			if not track(path,artifacts[path]): return false
	var code: Script = load(AO) as Script
	var bundle: Script = load(BUNDLE) as Script
	if not check(code != null and code.can_instantiate() and bundle != null and bundle.can_instantiate(),"Frozen pure APIs compile only in established autoload context"): return false
	var spec: Dictionary = code.author()
	if not check(not spec.is_empty(),"Fixed actual source-pixel author is valid"): return false
	var original: Variant = bytes_to_var(FileAccess.get_file_as_bytes(spec.parent_packet_path))
	var packet: Variant = bytes_to_var(FileAccess.get_file_as_bytes(NATIVE+"packet.bin"))
	var parent: SceneScript = ResourceLoader.load(spec.parent_scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var child: SceneScript = ResourceLoader.load(NATIVE+"scene.res","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(original is Dictionary and packet is Dictionary and parent != null and child != null and bundle.equal(bundle.storage(child),packet.scene_storage) and bundle.equal(bundle.storage(child.map_layout),packet.layout_storage),"Actual native Scene/Layout readback equals typed published packet"): return false
	if not check(child.map_layout.visual_objects.size() == 24 and packet.record.objects.size() == 24 and bundle.equal(code.inverse_record(packet.record,original.record,spec),original.record) and code.native_inverse(child,parent,spec),"Exact two replacements; complete typed record/native parent inverse"): return false
	var inverse: Dictionary = packet.duplicate(true)
	for key: String in ["geometry_basis","record","solids","walk_bytes","mask_sha","scene_storage","layout_storage"]: inverse[key] = original[key]
	for key: String in ["ao_parent_record","ao_parent_packet_sha256","ao_author_sha256"]: inverse.erase(key)
	if not check(bundle.equal(packet.ao_parent_record,original.record) and packet.ao_parent_packet_sha256 == spec.parent_packet_sha256 and packet.ao_author_sha256 == code.AUTHOR_SHA and bundle.bytes_sha(packet.walk_bytes) == proof.walk_candidate.rgba_sha256 and bundle.equal(inverse,original),"Whole typed packet inverse and actual bound walk bytes; no raster rebuild"): return false
	var registry: Dictionary = _json(proof.two_room_returns.registry_candidate_path)
	var snapshot_path: String = registry.ao_return_successor.parent_snapshot_path
	if not track(snapshot_path,registry.ao_return_successor.parent_sha256): return false
	var previous: Dictionary = _json(snapshot_path)
	if not check(previous.rooms.size() == 12 and registry.rooms.size() == 12,"Same twelve-room registry, not all-room runtime tests"): return false
	for id: String in previous.rooms:
		if id not in code.ROOM_IDS and not check(bundle.equal(previous.rooms[id],registry.rooms[id]),"One of unchanged ten complete rows including AN mansion "+id): return false
	for id: String in code.ROOM_IDS:
		var row: Dictionary = registry.rooms[id]
		var old_row: Dictionary = previous.rooms[id]
		var old_author: Dictionary = _json(old_row.author_path)
		var new_author: Dictionary = _json(row.author_path)
		var author_inverse: Dictionary = new_author.duplicate(true)
		author_inverse.room = old_author.room.duplicate(true); author_inverse.erase("ao_return_successor")
		if not check(bundle.equal(author_inverse,old_author) and bundle.equal(new_author.geometry,old_author.geometry),"Two-room author whole inverse; zero furniture/geometry rerun "+id): return false
		var old_scene: SceneScript = ResourceLoader.load(old_row.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var new_scene: SceneScript = ResourceLoader.load(row.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var storage: Variant = bytes_to_var(FileAccess.get_file_as_bytes(row.storage_path))
		if not check(old_scene != null and new_scene != null and storage is Dictionary and bundle.equal(bundle.storage(new_scene),storage.scene) and bundle.equal(bundle.storage(new_scene.map_layout),storage.layout),"Two-room actual typed storage readback "+id): return false
		var room_inverse: SceneScript = new_scene.duplicate(true) as SceneScript
		room_inverse.map_layout = new_scene.map_layout.duplicate(true) as WalkableMapLayout
		room_inverse.set_meta("luoyang_room_successor_20261018t",old_row.author_sha256)
		var exits: int = 0
		for index: int in room_inverse.map_layout.portals.size():
			if room_inverse.map_layout.portals[index].get("target_scene") == MARKET:
				room_inverse.map_layout.portals[index] = old_scene.map_layout.portals[index].duplicate(true); exits += 1
		if not check(exits == 1 and bundle.equal(bundle.storage(room_inverse),bundle.storage(old_scene)) and bundle.equal(bundle.storage(room_inverse.map_layout),bundle.storage(old_scene.map_layout)),"Independent exactly-one return UV plus author-meta typed inverse "+id): return false
	var registry_inverse: Dictionary = registry.duplicate(true)
	registry_inverse.erase("ao_return_successor")
	for id: String in code.ROOM_IDS: registry_inverse.rooms[id] = registry_inverse.rooms[id].ao_parent_row.duplicate(true)
	return check(bundle.equal(registry_inverse,previous),"All twelve registry values whole inverse after only two declared rows")

func _run() -> void:
	began = Time.get_ticks_msec(); deadline = began+30000
	var out_dir: String = "res://build/luoyang_market_two_shops_20261021ao_qa01/native_inverse_%d"%OS.get_process_id()
	if DirAccess.dir_exists_absolute(out_dir): printerr("AO_INVERSE_REPORT_EXISTS"); quit(2); return
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	players_before = saves(); state_before = _state()
	var own: String = get_script().resource_path
	var ok: bool = track(own,FileAccess.get_sha256(own)) and track("res://tests/test_luoyang_estate_formal_travel_remaining_READY_20261021an.gd","7422998b8ee5b13f9280c73f4f2029eda709e3cfbad86e4b6501f5b5e2b6f1a1") and track("res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd","a8d112574bf860fb595c78e34524abba1693cbeb6d65f43c23be50e667ef8895")
	if ok: ok = _verify()
	var final: Dictionary = {}
	for path: String in source_before: final[path] = fact(path)
	var save_final: Dictionary = saves(); var state_final: Dictionary = _state()
	check(final == source_before,"Consumed sources/artifacts first-final SHAbytes/seconds String unchanged")
	check(players_before.size() == 15 and players_before == save_final,"15save first-final unchanged")
	check(state_before == state_final,"Flags/QM/inventory/rewards unchanged; no restoration")
	check(Time.get_ticks_msec() < deadline,"Fixed30s tiny readback, not four source collectors")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var path: String = out_dir.path_join("result.json")
	if FileAccess.file_exists(path): printerr("AO_INVERSE_RESULT_EXISTS"); quit(2); return
	var result: Dictionary = {"scope":"AO_NEW_NATIVE_TWO_ROOM_TYPED_INVERSE_COMPONENT_ONLY_NO_GEOMETRY_FIELD_OR_COLLECTOR","passed":ok and failures==0,"checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"source_first":source_before,"source_final":final,"saves_first":players_before,"saves_final":save_final,"state_first":state_before,"state_final":state_final,"old_route_or_alpha_or_room_geometry_rerun":false}
	var output: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if output == null: printerr("AO_INVERSE_OUTPUT_FAIL"); quit(2); return
	output.store_string(JSON.stringify(result,"\t")); output.close()
	print(JSON.stringify({"path":path,"passed":result.passed,"checks":checks,"failures":failures})); quit(0 if result.passed else 1)
