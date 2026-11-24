extends RefCounted
## Same public API; explicit t successor contract, never overwrite old 11 proof.
const SELF="res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
const MARKET_SPACE_PATH="res://build/luoyang_city_space_20261024b_source01/market_space_runtime_closed02_CANDIDATE.gd"
const MARKET_SPACE_SHA="b50c48f21c8cba132a0d1d015969de8917948cc8abe1f9455e2510abd41c573c"
static var _market_space_handle: Variant=null
static func _market_space_runtime() -> Variant:
	if _market_space_handle!=null: return _market_space_handle
	if FileAccess.get_sha256(MARKET_SPACE_PATH)!=MARKET_SPACE_SHA: return null
	var value: Variant=load(MARKET_SPACE_PATH)
	if not value is GDScript or value.resource_path!=MARKET_SPACE_PATH: return null
	_market_space_handle=value;return value
const HALL_FIXED=preload("res://build/luoyang_hall_portal_fix_20261024a_system01/parent_successor02/mainhall_fixed_columns_ActorLayer_CANDIDATE.gd")
const INDEX="res://scripts/city/luoyang_layout_room_index_20261018t.gd"
const ROOT="res://data/maps/luoyang_layout_rooms_20261018t/"
const ESTATE=preload("res://scripts/city/luoyang_estate_family_20261021am.gd")
const AM_ROOT="res://data/maps/luoyang_estate_rooms_20261021am/"
const AO_ROOM_ROOT="res://data/maps/luoyang_market_two_shops_20261021ao/rooms/"
const AO_PARENT_REGISTRY="res://build/luoyang_market_two_shops_20261021ao_system01/before/registry_AN_167F.json"
const AO_PARENT_SHA="167f4a16816224974f4c41b1b753cf7257bfdd8a9f096dbc0c79351c93b88d4c"
const AO_ROOMS=["luoyang_market_market_northeast_rear_frontage_interior_20261015","luoyang_market_market_east_ward_frontage_interior_20261015"]
const AO_EXECUTION="res://scripts/city/luoyang_ao_district_predecessor_20261021ao.gd"
const AO_EXECUTION_SHA="c7523f853cde1d179a3e708bf6ee53765d6a61c2f4a57c03fb15f3655a614ced"
const AO_PUBLISHED_REGISTRY_SHA="bee00e7db68266d3acf664b6febe3d473fb074f2a8cc3d385ba7006ebc758182"
const AP_ROOT="res://data/maps/luoyang_full_city_20261022ap/rooms/"
const AP_PARENT="res://build/luoyang_city_full_rollout_20261022ap_system01/before/registry_AO_4D056.json"
const AP_PARENT_SHA="4d05631fa7f032f90d1eefdd600408235930b47c54aa5653a7f34a21d2db1297"
const AP_ROOMS=["luoyang_functional_pawnshop_candidate_20261016","luoyang_market_north_market_front_interior_20261015","luoyang_market_market_west_ward_frontage_interior_20261015","luoyang_market_market_northwest_rear_frontage_interior_20261015","luoyang_market_southeast_market_front_interior_20261015"]
const AP_AUTHORITY="res://scripts/city/luoyang_execution_authority_20261022ap.gd"
const AP_QUARTERS="res://scripts/city/luoyang_quarters_family_20261022ap.gd"
static func _ap_approved(path: String,historical: String) -> bool:
	if not path.begins_with("res://scripts/") or not path.ends_with(".gd") or not FileAccess.file_exists(AP_AUTHORITY): return false
	var authority: Variant=load(AP_AUTHORITY)
	return authority is GDScript and authority.resource_path==AP_AUTHORITY and path in authority.OWNED and authority.approved(path,historical)
static func _ap_parent_registry(value: Dictionary) -> Dictionary:
	var proof: Dictionary=value.get("ap_return_successor",{})
	if proof.get("parent_snapshot")!=AP_PARENT or proof.get("parent_sha256")!=AP_PARENT_SHA or proof.get("room_ids")!=AP_ROOMS or proof.get("other_seven_rows_unchanged")!=true or proof.get("no_interior_geometry_replay")!=true or FileAccess.get_sha256(AP_PARENT)!=AP_PARENT_SHA: return {}
	var parent: Variant=JSON.parse_string(FileAccess.get_file_as_string(AP_PARENT))
	if not parent is Dictionary or parent.get("rooms",{}).size()!=12: return {}
	var inverse: Dictionary=value.duplicate(true);inverse.erase("ap_return_successor")
	for id: String in AP_ROOMS:
		var row: Dictionary=inverse.get("rooms",{}).get(id,{})
		if row.get("ap_return_only_successor")!=true or not B.equal(row.get("ap_parent_row"),parent.rooms.get(id)): return {}
		inverse.rooms[id]=row.ap_parent_row.duplicate(true)
	return inverse if B.equal(inverse,parent) else {}
static func _ao_execution_parent(value: Dictionary) -> Dictionary:
	if FileAccess.get_sha256(AO_EXECUTION)!=AO_EXECUTION_SHA: return {}
	var helper: Variant=load(AO_EXECUTION)
	if not helper is GDScript or (not helper.admitted(helper.TARGET,helper.OLD_SHA) and not _ap_approved(helper.TARGET,helper.OLD_SHA)): return {}
	var pins: Dictionary={AO_EXECUTION:AO_EXECUTION_SHA,helper.APPROVAL:helper.APPROVAL_SHA,helper.OLD_SNAPSHOT:helper.OLD_SHA}
	var ids: Array=AO_ROOMS.duplicate();ids.append(String(ESTATE.ROOM))
	var expected: Dictionary={"prior_registry_sha256":AO_PUBLISHED_REGISTRY_SHA,"path":helper.TARGET,"old_sha256":helper.OLD_SHA,"new_sha256":helper.NEW_SHA,"room_ids":ids,"proof_sources":pins,"room_author_native_geometry_return_unchanged":true}
	if not B.equal(value.get("ao_execution_dependency_successor"),expected): return {}
	var inverse: Dictionary=value.duplicate(true);inverse.erase("ao_execution_dependency_successor")
	for id: String in ids:
		var row: Dictionary=inverse.get("rooms",{}).get(id,{})
		if row.get("source_sha256",{}).get(helper.TARGET)!=helper.NEW_SHA: return {}
		row.source_sha256[helper.TARGET]=helper.OLD_SHA
		for p: String in pins:
			if row.source_sha256.get(p)!=pins[p]: return {}
			row.source_sha256.erase(p)
	# The original publisher uses this exact sorted/full-precision JSON call,
	# with no trailing newline. This binds ALL values to actual BEE00E7D,
	# without hashing another duplicated 1MB registry during Estate arrival.
	return inverse if B.bytes_sha(JSON.stringify(inverse,"\t",true,true).to_utf8_buffer())==AO_PUBLISHED_REGISTRY_SHA else {}
static func _ao_parent_registry(value: Dictionary) -> Dictionary:
	if value.has("ao_execution_dependency_successor"):
		var published: Dictionary=_ao_execution_parent(value)
		return _ao_parent_registry(published) if not published.is_empty() else {}
	var proof: Dictionary=value.get("ao_return_successor",{})
	if proof.get("parent_snapshot_path")!=AO_PARENT_REGISTRY or proof.get("parent_sha256")!=AO_PARENT_SHA or proof.get("room_ids")!=AO_ROOMS or proof.get("geometry_reused")!=true or proof.get("AN_mansion_and_other_ten_rows_unchanged")!=true or FileAccess.get_sha256(AO_PARENT_REGISTRY)!=AO_PARENT_SHA: return {}
	var parent: Variant=JSON.parse_string(FileAccess.get_file_as_string(AO_PARENT_REGISTRY))
	if not parent is Dictionary or parent.get("rooms",{}).size()!=12: return {}
	var inverse: Dictionary=value.duplicate(true);inverse.erase("ao_return_successor")
	for id: String in AO_ROOMS:
		var row: Dictionary=inverse.get("rooms",{}).get(id,{})
		if row.get("ao_return_only_successor")!=true or not B.equal(row.get("ao_parent_row"),parent.rooms.get(id)): return {}
		inverse.rooms[id]=row.ao_parent_row.duplicate(true)
	return inverse if B.equal(inverse,parent) else {}
const AM_PARENT_SHA="6ee6ad3a24c2b2907636ad5220b039c77847adad0d0d54f921f097ea26a4731c"
static func _row_root(row: Dictionary) -> String:
	if row.get("ap_return_only_successor")==true and row.get("scene_id") in AP_ROOMS: return AP_ROOT
	if row.get("ao_return_only_successor")==true and row.get("scene_id") in AO_ROOMS: return AO_ROOM_ROOT
	return AM_ROOT if row.get("am_return_only_successor")==true and row.get("scene_id")==String(ESTATE.ROOM) else ROOT
static func _am_registry_valid(value: Dictionary) -> bool:
	if value.has("ap_return_successor"):
		var parent: Dictionary=_ap_parent_registry(value)
		return not parent.is_empty() and _am_registry_valid(parent)
	if value.has("ao_return_successor"):
		var original_ao_parent: Dictionary=_ao_parent_registry(value)
		return not original_ao_parent.is_empty() and _am_registry_valid(original_ao_parent)
	if FileAccess.get_sha256(ROOT+"registry.json")!=AM_PARENT_SHA: return false
	var original: Variant=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"registry.json"))
	var proof: Dictionary=value.get("am_return_successor",{})
	if not original is Dictionary or proof.get("parent_path")!=ROOT+"registry.json" or proof.get("parent_sha256")!=AM_PARENT_SHA or proof.get("room_ids")!=[String(ESTATE.ROOM)] or proof.get("geometry_reused")!=true: return false
	var inverse: Dictionary=value.duplicate(true);inverse.erase("am_return_successor")
	var row: Dictionary=inverse.get("rooms",{}).get(String(ESTATE.ROOM),{})
	if row.get("am_return_only_successor")!=true or not B.equal(row.get("am_parent_row"),original.rooms.get(String(ESTATE.ROOM))): return false
	inverse.rooms[String(ESTATE.ROOM)]=row.am_parent_row.duplicate(true)
	return B.equal(inverse,original)
const FLAG="--luoyang-layout-quest-20261018t"
const FORMAL_ENABLED=false
const META="source_feet_assembled_interiors_20261016g"
const ROOM_META="luoyang_room_successor_20261018t"
const SIZE=Vector2(1536,1024)
const OLD=preload("res://build/luoyang_layout_quest_20261018t_layout_source01/g_geometry_original.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
static var _config: Dictionary={}
static var _authors: Dictionary={}
static var _sessions: Dictionary={}
static var _storage: Dictionary={}
static func requested() -> bool:
	if FLAG in OS.get_cmdline_user_args(): return true
	return FileAccess.file_exists(INDEX) and load(INDEX).formal_enabled()
static func enabled() -> bool: return requested() or OLD.enabled()
static func catalogue() -> Dictionary:
	if not FileAccess.file_exists(INDEX): return OLD.catalogue() if not requested() else {}
	if not _config.is_empty(): return _config.duplicate(true)
	if not FileAccess.file_exists(INDEX): return {}
	var authority: Dictionary=load(INDEX).registry()
	if authority.get("path") not in [ROOT+"registry.json",AM_ROOT+"registry.json"] or not B._hash(authority.get("sha256")) or FileAccess.get_sha256(authority.path)!=authority.sha256: return {}
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(authority.path))
	if not data is Dictionary or data.get("status")!="CPU_PUBLISHED_ROOM_SUCCESSORS_CANDIDATE" or data.get("rooms",{}).size()!=12 or data.get("coordinate_contract")!=META: return {}
	if authority.path==AM_ROOT+"registry.json" and not _am_registry_valid(data): return {}
	var history: Dictionary=data.get("history",{})
	if history.get("prior_path")!=OLD.REGISTRY_PATH or history.get("prior_sha256")!=OLD.REGISTRY_SHA or FileAccess.get_sha256(history.prior_path)!=history.prior_sha256: return {}
	for id: String in data.rooms:
		var row: Dictionary=data.rooms[id]
		if row.get("scene_id")!=id or row.get("geometry",{}).get("passed")!=true or row.get("runtime_ready")!=true or row.get("door_enabled")!=true: return {}
		for key: String in ["author_path","scene_path","layout_path"]:
			if row.get(key)!=_row_root(row)+id+"/"+{"author_path":"author.json","scene_path":"scene.res","layout_path":"layout.res"}[key] or not row.get("source_sha256",{}).has(row[key]): return {}
	_config=data.duplicate(true); return data
static func overrides(id: StringName) -> bool:
	if not requested(): return false
	if not _config.is_empty() and FileAccess.file_exists(INDEX):
		return _config.get("rooms",{}).has(String(id))
	return catalogue().get("rooms",{}).has(String(id))
static func known(id: StringName) -> bool: return overrides(id) if requested() else OLD.known(id)
static func author_for_id(id: StringName) -> Dictionary:
	if not requested(): return OLD.author_for_id(id)
	if _authors.has(id): return _authors[id].duplicate(true)
	var row: Dictionary=catalogue().get("rooms",{}).get(String(id),{})
	if row.is_empty() or FileAccess.get_sha256(row.author_path)!=row.author_sha256: return {}
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(row.author_path))
	if not data is Dictionary or data.get("room",{}).get("scene_id")!=String(id): return {}
	_authors[id]=data.duplicate(true); return data
static func source_paths() -> Dictionary:
	if not FileAccess.file_exists(INDEX):
		var original: Dictionary=OLD.source_paths(); original["res://build/luoyang_layout_quest_20261018t_layout_source01/g_geometry_original.gd"]=true; return original
	var config: Dictionary=catalogue()
	if config.is_empty(): return {}
	var paths: Dictionary={SELF:true,INDEX:true,ROOT+"registry.json":true,"res://build/luoyang_layout_quest_20261018t_layout_source01/g_geometry_original.gd":true,OLD.REGISTRY_PATH:true}
	# Preserve every historical source leaf; new artifacts are additions, not
	# justification to drop old proof/code/import provenance from cold closure.
	var prior: Variant=JSON.parse_string(FileAccess.get_file_as_string(OLD.REGISTRY_PATH))
	if not prior is Dictionary: return {}
	for path: String in prior.get("source_sha256",{}): paths[path]=true
	for old_row: Dictionary in prior.rooms.values():
		for key: String in ["author_path","scene_path","layout_path"]: paths[String(old_row[key])]=true
	for row: Dictionary in config.rooms.values():
		for path: String in row.source_sha256: paths[path]=true
	var future: Dictionary=ESTATE.registry_source()
	if future.is_empty(): return {}
	var successor: Variant=JSON.parse_string(FileAccess.get_file_as_string(future.path))
	if not successor is Dictionary or not _am_registry_valid(successor): return {}
	paths[future.path]=true
	if successor.has("ao_return_successor"):
		paths[AO_PARENT_REGISTRY]=true
		for id: String in AO_ROOMS:
			for path: String in successor.rooms[id].source_sha256: paths[path]=true
	for path: String in successor.rooms[String(ESTATE.ROOM)].source_sha256: paths[path]=true
	# Non-Market cities consume the family/header and one room, not Estate
	# scenery/old publication packet history. B adds full media only to Market.
	paths[ESTATE.SELF]=true;paths[ESTATE.INDEX]=true;paths[ESTATE.ROOT+"manifest.json"]=true
	paths["res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd"]=true
	if config.has("ap_return_successor"):
		paths[AP_PARENT]=true;paths[AP_QUARTERS]=true
		var authority_paths: Dictionary=load(AP_AUTHORITY).source_paths()
		if authority_paths.is_empty(): return {}
		paths.merge(authority_paths)
	paths["res://build/luoyang_hall_portal_fix_20261024a_system01/parent_successor02/mainhall_fixed_columns_ActorLayer_CANDIDATE.gd"]=true
	var space_runtime: Variant=_market_space_runtime()
	if space_runtime==null: return {}
	var room_paths: Dictionary=space_runtime.room_source_paths()
	if room_paths.is_empty(): return {}
	paths.merge(room_paths)
	return paths
static func storage_for(row: Dictionary) -> Dictionary:
	if _storage.has(row.scene_id): return _storage[row.scene_id]
	if row.get("storage_path")!=_row_root(row)+String(row.scene_id)+"/storage.bin" or FileAccess.get_sha256(row.storage_path)!=row.get("storage_sha256"): return {}
	var value: Variant=bytes_to_var(FileAccess.get_file_as_bytes(row.storage_path))
	if not value is Dictionary or not B._plain(value): return {}
	_storage[row.scene_id]=value; return value
static func room_path(id: StringName) -> String:
	if not requested(): return OLD.room_path(id)
	var row: Dictionary=catalogue().get("rooms",{}).get(String(id),{})
	if row.is_empty(): return ""
	for path: String in row.source_sha256:
		if FileAccess.get_sha256(path)!=row.source_sha256[path] and not _ap_approved(path,String(row.source_sha256[path])): return ""
	return row.scene_path
static func return_binding(id: StringName) -> Dictionary:
	if not known(id): return {}
	var original: Dictionary=author_for_id(id).get("room",{}).duplicate(true)
	var space_runtime: Variant=_market_space_runtime()
	if space_runtime==null: return {}
	return space_runtime.room_return_binding(id,original) if space_runtime.owns_room(id) else original
static func authored_return_uv(id: StringName) -> Vector2:
	var row: Dictionary=return_binding(id); var raw: Variant=row.get("return_foot_px",[])
	return Vector2(float(raw[0])/3072.0,float(raw[1])/2048.0) if raw is Array and raw.size()==2 else Vector2(INF,INF)
static func matches(scene: SceneScript,id: StringName) -> bool:
	if not requested(): return OLD.matches(scene,id)
	if scene==null or scene.scene_id!=id or scene.map_layout==null or not scene.actor_positions_are_feet or not known(id): return false
	var row: Dictionary=catalogue().rooms[String(id)]
	var expected: Dictionary=storage_for(row)
	if expected.is_empty(): return false
	if scene.resource_path!=row.scene_path or scene.map_layout.resource_path!=row.layout_path or scene.get_meta(ROOM_META,"")!=row.author_sha256: return false
	var session: Dictionary=_sessions.get(scene.get_instance_id(),{})
	if not session.is_empty(): return session.scene.get_ref()==scene and session.layout.get_ref()==scene.map_layout and B.equal(B.storage(scene),expected.scene) and B.equal(B.storage(scene.map_layout),expected.layout)
	for key: int in _sessions.keys():
		if _sessions[key].scene.get_ref()==null or _sessions[key].layout.get_ref()==null: _sessions.erase(key)
	if _sessions.size()>=16 or room_path(id).is_empty() or not B.equal(B.storage(scene),expected.scene) or not B.equal(B.storage(scene.map_layout),expected.layout): return false
	_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout),"author":author_for_id(id),"finalized":false}
	return true
static func is_room(scene: SceneScript) -> bool:
	if not requested(): return OLD.is_room(scene)
	if scene==null: return false
	var session: Dictionary=_sessions.get(scene.get_instance_id(),{})
	return not session.is_empty() and session.scene.get_ref()==scene and session.layout.get_ref()==scene.map_layout
static func geometry_for(scene: SceneScript) -> Dictionary:
	if not requested(): return OLD.geometry_for(scene)
	if not is_room(scene): return {}
	var data: Dictionary=_sessions[scene.get_instance_id()].author.geometry.duplicate(true)
	if scene.scene_id==HALL_FIXED.ROOM: data[HALL_FIXED.POLICY_KEY]=HALL_FIXED.AUTHOR_SHA
	return data
static func configure_fixed_columns(world: Node2D,scene: SceneScript,fade: RefCounted,world_size: Vector2) -> bool:
	if scene==null or scene.scene_id!=HALL_FIXED.ROOM or not is_room(scene) or not matches(scene,scene.scene_id): return false
	return HALL_FIXED.install(world,scene,author_for_id(scene.scene_id),fade,world_size)
static func compile_geometry(data: Dictionary,world_size: Vector2) -> Dictionary:
	if data.has(HALL_FIXED.POLICY_KEY): return HALL_FIXED.compile_bases(data,OLD.compile_geometry(data,world_size),world_size)
	return OLD.compile_geometry(data,world_size) if data.get("actor_clearance_model") is Dictionary else OLD.GEOMETRY.compile_geometry(data,world_size)
static func safe_foot(data: Dictionary,foot: Vector2,world_size: Vector2,full: bool=false) -> bool:
	return OLD.safe_foot(data,foot,world_size,full) if data.get("actor_clearance_model") is Dictionary else OLD.GEOMETRY.safe_origin(data,foot-Vector2(0,42),world_size,full)
static func safe_motion(data: Dictionary,first: Vector2,last: Vector2,world_size: Vector2) -> bool:
	var n: int=maxi(1,ceili(first.distance_to(last)/4.0))
	for i: int in range(n+1):
		if not safe_foot(data,first.lerp(last,float(i)/n),world_size): return false
	return true
static func project_objects(scene: SceneScript,world_size: Vector2) -> Array:
	if not requested(): return OLD.project_objects(scene,world_size)
	if not is_room(scene): return []
	var rows: Array=[]
	for item: Dictionary in _sessions[scene.get_instance_id()].author.furniture:
		var ratio: float=float(item.render_scale)
		rows.append({"id":item.id,"texture":item.texture,"centered":false,"pos":(OLD.GEOMETRY._v(item.placement_foot_px)-OLD.GEOMETRY._v(item.source_ground_anchor_px)*ratio)/SIZE,"render_size_px":OLD.GEOMETRY._v(item.source_size_px)*ratio*(world_size/SIZE),"sort_by_feet":true,"depth_sort_foot_y":float(item.depth_foot_y)/1024.0,"assembled_furniture":true})
	return rows
static func prop_ids(scene: SceneScript=null) -> Array:
	if not requested(): return OLD.prop_ids(scene)
	var ids: Array=[]
	if is_room(scene):
		for item: Dictionary in _sessions[scene.get_instance_id()].author.furniture: ids.append(String(item.id))
	return ids
static func fade_ids(scene: SceneScript=null) -> Array:
	if not requested(): return OLD.fade_ids(scene)
	var ids: Array=[]
	if is_room(scene):
		for item: Dictionary in _sessions[scene.get_instance_id()].author.furniture:
			if item.get("height_behavior")=="HIGH_FURNITURE_FADE" or item.get("fade_allowed")==true: ids.append(String(item.id))
	return ids
static func finalize_setup(scene: SceneScript) -> bool:
	if not requested(): return OLD.finalize_setup(scene)
	if not matches(scene,scene.scene_id) or room_path(scene.scene_id)!=scene.resource_path or not matches(scene,scene.scene_id): return false
	_sessions[scene.get_instance_id()].finalized=true; return true
static func dialog_allowed(scene: SceneScript,id: String) -> bool:
	if not requested(): return OLD.dialog_allowed(scene,id)
	if not is_room(scene) or not matches(scene,scene.scene_id): return false
	var count: int=0
	for npc: Dictionary in scene.npcs:
		if String(npc.get("dialog_id",""))==id: count+=1
	var path: String="res://data/dialogs/"+id+".tres"
	var pin: String=String(catalogue().rooms[String(scene.scene_id)].source_sha256.get(path,""))
	return count==1 and B._hash(pin) and FileAccess.get_sha256(path)==pin
static func room_return(source: StringName,target: StringName,authored: Variant,remembered: Variant) -> Dictionary:
	if ESTATE.owns_route(source,target) and source==ESTATE.ROOM and target==ESTATE.ID:
		var destination:=ResourceLoader.load(ESTATE.scene_path(target),"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		return ESTATE.prepare_arrival(source,target,authored,remembered,destination)
	if not requested(): return OLD.room_return(source,target,authored,remembered)
	var binding: Dictionary=return_binding(source)
	if binding.is_empty() or String(target)!=binding.city_id or not authored is Vector2 or authored!=authored_return_uv(source): return {}
	var arrival: Vector2=remembered if remembered is Vector2 else authored
	if target in [&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]:
		var family: Variant=load(AP_QUARTERS)
		return {"spawn":arrival,"source_version":3,"target_version":3,"reason":"AP_exact_existing_room_new_quarter_return"} if arrival.is_finite() and ((arrival-authored)*Vector2(3072,2048)).length()<=180 and family.safe_body(target,arrival*Vector2(3072,2048)) else {}
	return {"spawn":arrival,"source_version":3,"target_version":3,"reason":"t_exact_source_bound_room_return"} if load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd").safe_body(target,arrival*Vector2(3072,2048)) else {}
static func project_portals(scene: SceneScript,original: Array) -> Dictionary:
	if not requested(): return OLD.project_portals(scene,original)
	var result: Array=original.duplicate(true)
	var space_runtime: Variant=_market_space_runtime()
	if space_runtime==null: return {"ok":false,"portals":[],"error":"MARKET_SPACE_RUNTIME_SOURCE_CHANGED"}
	if scene!=null and space_runtime.owns_room(scene.scene_id):
		if not matches(scene,scene.scene_id): return {"ok":false,"portals":[],"error":"MARKET_SPACE_ROOM_WHOLE_NATIVE_IDENTITY"}
		return space_runtime.room_exit_portals(scene,result)
	if scene!=null and scene.scene_id==&"luoyang_estate_riverside_20261021ai": return load(AP_QUARTERS).project_connections(scene,result)
	if scene==null or scene.scene_id not in [&"ch4_s3_luoyang_market",&"ch4_s1_luoyang_yamen",&"ch4_s2_canal_docks",&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]: return {"ok":true,"portals":result}
	var city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	var new_quarter: bool=scene.scene_id in [&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]
	var family: Variant=load(AP_QUARTERS) if new_quarter else null
	if (new_quarter and not family.matches(scene)) or (not new_quarter and not city.is_v3(scene)): return {"ok":false,"portals":[],"error":"t actual prepared city identity"}
	var config: Dictionary=catalogue()
	for id: String in config.get("rooms",{}):
		var data: Dictionary=author_for_id(StringName(id)); var row: Dictionary=data.get("room",{});var door_scene_path: String=String(config.rooms[id].scene_path)
		# Market's frozen native has seven original entries; the mansion is one
		# of G's three appended bays (T.layout_transform.materialize explicitly
		# preserves that split). First reproduce that exact old G door, then the
		# family transform below must remove exactly one, never tolerate zero.
		if ESTATE.requested() and scene.scene_id==ESTATE.MARKET and id==String(ESTATE.ROOM):
			var parent: Dictionary=config.rooms[id].get("am_parent_row",{})
			if parent.is_empty() or FileAccess.get_sha256(parent.author_path)!=parent.get("author_sha256"): return {"ok":false,"portals":[],"error":"AM_PRIOR_MANSION_SOURCE"}
			var old_data: Variant=JSON.parse_string(FileAccess.get_file_as_string(parent.author_path))
			if not old_data is Dictionary or old_data.get("room",{}).get("city_id")!=String(ESTATE.MARKET): return {"ok":false,"portals":[],"error":"AM_PRIOR_MANSION_BINDING"}
			data=old_data;row=data.room;door_scene_path=String(parent.scene_path)
		if row.get("city_id")!=String(scene.scene_id): continue
		var exact_market_space: bool=scene.scene_id==&"ch4_s3_luoyang_market" and space_runtime.owns_room(StringName(id))
		if exact_market_space:
			row=space_runtime.room_return_binding(StringName(id),row)
			if row.is_empty(): return {"ok":false,"portals":[],"error":"MARKET_SPACE_TWO_RETURNS_SOURCE_CHANGED"}
		var position: Vector2=Vector2(float(row.return_foot_px[0])/3072.0,float(row.return_foot_px[1])/2048.0); var foot: Vector2=position*Vector2(3072,2048)
		if (new_quarter and not family.safe_body(scene.scene_id,foot)) or (not new_quarter and not city.safe_body(scene.scene_id,foot)): return {"ok":false,"portals":[],"error":"t exact native door foot refused "+id}
		var native_position: Vector2=position
		if exact_market_space:
			native_position=space_runtime.city_native_threshold(scene,StringName(id),position)
			if not native_position.is_finite(): return {"ok":false,"portals":[],"error":"MARKET_SPACE_TWO_NATIVE_THRESHOLDS_SOURCE_CHANGED"}
		var exact_south_material: bool=new_quarter and scene.scene_id==&"luoyang_artisan_residential_20261022ap" and id=="luoyang_market_southeast_market_front_interior_20261015"
		if exact_south_material:
			# Immutable53624 retains the actual threshold1900. Its separate return
			# foot1924 was already body/+24 checked; never reinterpret either.
			if row.get("building_id")!="ap_carpentry_general_shop_south" or position!=Vector2(1536,1924)/Vector2(3072,2048) or FileAccess.get_sha256("res://build/luoyang_city_full_rollout_20261022ap_system01/artisan_revision4/publication/53624/result.json")!="09301b55d1ea22c94d1dd35096597c87cfe691dba6e04e26b35e3db7c612b575": return {"ok":false,"portals":[],"error":"AP exact material threshold/return proof"}
			native_position=Vector2(1536,1900)/Vector2(3072,2048)
		var count: int=0
		for portal: Dictionary in result:
			if String(portal.get("target_scene",""))!=id: continue
			count+=1
			if portal.get("pos")!=native_position or portal.get("size")!=Vector2(40.0/3072.0,32.0/2048.0) or portal.get("auto_trigger")!=false: return {"ok":false,"portals":[],"error":"t existing exact doorway identity "+id}
			portal.target_scene_path=door_scene_path; portal.target_pos=OLD.GEOMETRY._v(data.geometry.spawn_foot_px)/SIZE; portal.label="进入"+String(data.display_name)
			portal.interaction_polygon_px=_door_polygon(native_position*Vector2(3072,2048))
		if count>1: return {"ok":false,"portals":[],"error":"t duplicate doorway"}
		if exact_south_material and count!=1: return {"ok":false,"portals":[],"error":"AP missing exact material native doorway"}
		if exact_market_space and count!=1: return {"ok":false,"portals":[],"error":"MARKET_SPACE_MISSING_EXACT_NATIVE_TWO_DOORS"}
		if count==0:
			var matching: int=0
			var objects: Array=scene.map_layout.visual_objects if new_quarter else city._records.get(String(scene.scene_id),{}).get("objects",[])
			for item: Dictionary in objects:
				if String(item.get("id",""))==String(row.building_id): matching+=1
			if matching!=1: return {"ok":false,"portals":[],"error":"t exact building authority absent"}
			result.append({"id":"t_enter_"+String(row.building_id)+"_"+String(data.type_id),"pos":position,"size":Vector2(40.0/3072.0,32.0/2048.0),"target_scene":id,"target_scene_path":door_scene_path,"target_pos":OLD.GEOMETRY._v(data.geometry.spawn_foot_px)/SIZE,"auto_trigger":false,"label":"进入"+String(data.display_name),"interaction_polygon_px":_door_polygon(foot)})
	var projected: Dictionary=ESTATE.project_market(scene,result) if ESTATE.requested() and scene.scene_id==ESTATE.MARKET else {"ok":true,"portals":result}
	return load(AP_QUARTERS).project_connections(scene,projected.portals) if projected.get("ok")==true else projected
static func _door_polygon(foot: Vector2) -> PackedVector2Array:
	return PackedVector2Array([foot+Vector2(-20,-16),foot+Vector2(20,-16),foot+Vector2(20,16),foot+Vector2(-20,16)])
