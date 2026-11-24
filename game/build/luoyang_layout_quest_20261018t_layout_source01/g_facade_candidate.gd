extends RefCounted
## Same public API; explicit t successor contract, never overwrite old 11 proof.
const SELF="res://scripts/city/luoyang_assembled_interiors_20261016g.gd"
const INDEX="res://scripts/city/luoyang_layout_room_index_20261018t.gd"
const ROOT="res://data/maps/luoyang_layout_rooms_20261018t/"
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
	if authority.get("path")!=ROOT+"registry.json" or not B._hash(authority.get("sha256")) or FileAccess.get_sha256(authority.path)!=authority.sha256: return {}
	var data: Variant=JSON.parse_string(FileAccess.get_file_as_string(authority.path))
	if not data is Dictionary or data.get("status")!="CPU_PUBLISHED_ROOM_SUCCESSORS_CANDIDATE" or data.get("rooms",{}).size()!=12 or data.get("coordinate_contract")!=META: return {}
	var history: Dictionary=data.get("history",{})
	if history.get("prior_path")!=OLD.REGISTRY_PATH or history.get("prior_sha256")!=OLD.REGISTRY_SHA or FileAccess.get_sha256(history.prior_path)!=history.prior_sha256: return {}
	for id: String in data.rooms:
		var row: Dictionary=data.rooms[id]
		if row.get("scene_id")!=id or row.get("geometry",{}).get("passed")!=true or row.get("runtime_ready")!=true or row.get("door_enabled")!=true: return {}
		for key: String in ["author_path","scene_path","layout_path"]:
			if row.get(key)!=ROOT+id+"/"+{"author_path":"author.json","scene_path":"scene.res","layout_path":"layout.res"}[key] or not row.get("source_sha256",{}).has(row[key]): return {}
	_config=data.duplicate(true); return data
static func overrides(id: StringName) -> bool: return requested() and catalogue().get("rooms",{}).has(String(id))
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
	return paths
static func storage_for(row: Dictionary) -> Dictionary:
	if _storage.has(row.scene_id): return _storage[row.scene_id]
	if row.get("storage_path")!=ROOT+String(row.scene_id)+"/storage.bin" or FileAccess.get_sha256(row.storage_path)!=row.get("storage_sha256"): return {}
	var value: Variant=bytes_to_var(FileAccess.get_file_as_bytes(row.storage_path))
	if not value is Dictionary or not B._plain(value): return {}
	_storage[row.scene_id]=value; return value
static func room_path(id: StringName) -> String:
	if not requested(): return OLD.room_path(id)
	var row: Dictionary=catalogue().get("rooms",{}).get(String(id),{})
	if row.is_empty(): return ""
	for path: String in row.source_sha256:
		if FileAccess.get_sha256(path)!=row.source_sha256[path]: return ""
	return row.scene_path
static func return_binding(id: StringName) -> Dictionary:
	return author_for_id(id).get("room",{}).duplicate(true) if known(id) else {}
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
	return _sessions[scene.get_instance_id()].author.geometry.duplicate(true) if is_room(scene) else {}
static func compile_geometry(data: Dictionary,world_size: Vector2) -> Dictionary:
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
	if not requested(): return OLD.room_return(source,target,authored,remembered)
	var binding: Dictionary=return_binding(source)
	if binding.is_empty() or String(target)!=binding.city_id or not authored is Vector2 or authored!=authored_return_uv(source): return {}
	var arrival: Vector2=remembered if remembered is Vector2 else authored
	return {"spawn":arrival,"source_version":3,"target_version":3,"reason":"t_exact_source_bound_room_return"} if load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd").safe_body(target,arrival*Vector2(3072,2048)) else {}
static func project_portals(scene: SceneScript,original: Array) -> Dictionary:
	if not requested(): return OLD.project_portals(scene,original)
	var result: Array=original.duplicate(true)
	if scene==null or scene.scene_id not in [&"ch4_s3_luoyang_market",&"ch4_s1_luoyang_yamen",&"ch4_s2_canal_docks"]: return {"ok":true,"portals":result}
	var city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	if not city.is_v3(scene): return {"ok":false,"portals":[],"error":"t actual prepared city identity"}
	for id: String in catalogue().get("rooms",{}):
		var data: Dictionary=author_for_id(StringName(id)); var row: Dictionary=data.get("room",{})
		if row.get("city_id")!=String(scene.scene_id): continue
		var position: Vector2=authored_return_uv(StringName(id)); var foot: Vector2=position*Vector2(3072,2048)
		if not city.safe_body(scene.scene_id,foot): return {"ok":false,"portals":[],"error":"t exact native door foot refused "+id}
		var count: int=0
		for portal: Dictionary in result:
			if String(portal.get("target_scene",""))!=id: continue
			count+=1
			if portal.get("pos")!=position or portal.get("size")!=Vector2(40.0/3072.0,32.0/2048.0) or portal.get("auto_trigger")!=false: return {"ok":false,"portals":[],"error":"t existing exact doorway identity "+id}
			portal.target_scene_path=catalogue().rooms[id].scene_path; portal.target_pos=OLD.GEOMETRY._v(data.geometry.spawn_foot_px)/SIZE; portal.label="进入"+String(data.display_name)
			portal.interaction_polygon_px=_door_polygon(foot)
		if count>1: return {"ok":false,"portals":[],"error":"t duplicate doorway"}
		if count==0:
			var matching: int=0
			for item: Dictionary in city._records.get(String(scene.scene_id),{}).get("objects",[]):
				if String(item.get("id",""))==String(row.building_id): matching+=1
			if matching!=1: return {"ok":false,"portals":[],"error":"t exact building authority absent"}
			result.append({"id":"t_enter_"+String(row.building_id)+"_"+String(data.type_id),"pos":position,"size":Vector2(40.0/3072.0,32.0/2048.0),"target_scene":id,"target_scene_path":catalogue().rooms[id].scene_path,"target_pos":OLD.GEOMETRY._v(data.geometry.spawn_foot_px)/SIZE,"auto_trigger":false,"label":"进入"+String(data.display_name),"interaction_polygon_px":_door_polygon(foot)})
	return {"ok":true,"portals":result}
static func _door_polygon(foot: Vector2) -> PackedVector2Array:
	return PackedVector2Array([foot+Vector2(-20,-16),foot+Vector2(20,-16),foot+Vector2(20,16),foot+Vector2(-20,16)])
