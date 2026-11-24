extends RefCounted
const FINISH25I_ENABLED: bool=true
const FINISH25I_RUNTIME: String="res://build/luoyang_city_finish_20261025i_source01/exit_wall_repair_20261027b01/closure_READY01/finish8_runtime_READY.gd"
const FINISH25I_RUNTIME_SHA: String="0796b23fa70e5d1a3b25e0d2044f6358c1d055ec4bab3e740ff316b41459323a"
const FINISH25I_DOORS: String="res://build/luoyang_city_finish_20261025i_source01/Estate_wall_source_repair01/closure_READY01/wing_door_depth_children_READY.gd"
const FINISH25I_DOORS_SHA: String="9116c468fb46feffd6625e5752d5c9c21cfb9662100787ae810d129d7c185d00"
const FINISH25I_ADAPTER: String="res://build/luoyang_city_finish_20261025i_source01/temple_signed_iid_repair01/closure_READY01/original_owner_receipts_READY.gd"
const FINISH25I_ADAPTER_SHA: String="c9b0ea604faf4e7ae63c2100e8b49e6a5b5f035fe73da8b514013d92dc4e3c86"
const FINISH25I_AMBIENT: String="res://build/luoyang_city_finish_20261025i_source01/runtime_READY01/ambient18_runtime_READY.gd"
const FINISH25I_AMBIENT_SHA: String="e482fc0043a16c6a873941b1c5706819618896209cbc753ef1535e2231b7a787"
static var _finish25i_handle: Variant=null
static var _finish25i_checking: bool=false
static var _finish25i_original_owners: Dictionary={}
static var _finish25i_active_scenes: Dictionary={}
static func _finish25i_runtime() -> Variant:
	if not FINISH25I_ENABLED: return null
	if _finish25i_handle!=null: return _finish25i_handle
	if FileAccess.get_sha256(FINISH25I_RUNTIME)!=FINISH25I_RUNTIME_SHA: return null
	var script: Variant=load(FINISH25I_RUNTIME)
	if not script is GDScript or script.resource_path!=FINISH25I_RUNTIME: return null
	_finish25i_handle=script;return script
static func original_receipt_for(scene: SceneScript) -> Dictionary:
	if not FINISH25I_ENABLED or scene==null or scene.map_layout==null: return {}
	var row: Dictionary=_finish25i_original_owners.get(scene.get_instance_id(),{})
	if row.is_empty() or row.scene.get_ref()!=scene or row.layout.get_ref()!=scene.map_layout: return {}
	return row.receipt.duplicate(true)
static func _finish25i_promote_original_final() -> void:
	if not FINISH25I_ENABLED: return
	var actual: Dictionary=validation_receipt()
	if actual.get("finalized")!=true or actual.get("full_source_hash_passes")!=2 or actual.get("source_first")!=actual.get("source_final"): return
	for key: int in _finish25i_original_owners.keys():
		var row: Dictionary=_finish25i_original_owners[key]
		if row.scene.get_ref()==null or row.layout.get_ref()==null:
			_finish25i_original_owners.erase(key);continue
		if row.receipt.get("serial")==actual.get("serial") and row.receipt.get("key")==actual.get("key") and row.receipt.get("source_first")==actual.get("source_first"):
			row.receipt=actual.duplicate(true)
static func _finish25i_ensure(scene: SceneScript) -> bool:
	if not FINISH25I_ENABLED: return true
	# Adapter recursively calls matches; its inner call still executes every old
	# whole-storage guard, but cannot recursively create or finalize a lease.
	if _finish25i_checking: return true
	var runtime: Variant=_finish25i_runtime()
	if runtime==null or scene==null or scene.map_layout==null: return false
	for key: int in _finish25i_original_owners.keys():
		var owner: Dictionary=_finish25i_original_owners[key]
		if owner.scene.get_ref()==null or owner.layout.get_ref()==null: _finish25i_original_owners.erase(key)
	if not _finish25i_original_owners.has(scene.get_instance_id()):
		var first: Dictionary=validation_receipt()
		if int(first.get("serial",0))<=0 or String(first.get("key",""))=="" or not first.get("source_first") is Dictionary or first.source_first.is_empty(): return false
		_finish25i_original_owners[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout),"receipt":first.duplicate(true)}
	if original_receipt_for(scene).is_empty() or FileAccess.get_sha256(FINISH25I_ADAPTER)!=FINISH25I_ADAPTER_SHA: return false
	var adapter: Variant=load(FINISH25I_ADAPTER)
	if not adapter is GDScript or adapter.resource_path!=FINISH25I_ADAPTER: return false
	_finish25i_checking=true
	var receipt: Dictionary=adapter.receipt(scene,null,false)
	_finish25i_checking=false
	if receipt.is_empty(): return false
	if not runtime.ensure(scene,receipt.original_native_navigation,receipt.original_parent_blockers,receipt): return false
	_finish25i_active_scenes[scene.scene_id]=weakref(scene)
	return true
static func _finish25i_safe(id: StringName,foot: Vector2) -> bool:
	var runtime: Variant=_finish25i_handle
	if runtime==null or not foot.is_finite(): return false
	var active: WeakRef=_finish25i_active_scenes.get(id) as WeakRef
	var scene: SceneScript=active.get_ref() as SceneScript if active!=null else null
	if scene==null or scene.scene_id!=id or scene.map_layout==null: return false
	var row: Dictionary=_finish25i_original_owners.get(scene.get_instance_id(),{})
	return not row.is_empty() and row.scene.get_ref()==scene and row.layout.get_ref()==scene.map_layout and runtime.safe_body(scene,foot)
## Exact new ordinary-scene family, not a new C city or a source bypass.
const SELF="res://scripts/city/luoyang_estate_family_20261021am.gd"
const INDEX="res://scripts/city/luoyang_estate_index_20261021am.gd"
const ROOT="res://data/maps/luoyang_estate_courtyard_20261021am/"
const ID=&"luoyang_estate_riverside_20261021ai"
const MARKET=&"ch4_s3_luoyang_market"
const ROOM=&"luoyang_functional_mansion_candidate_20261016"
const SIZE=Vector2(3072,2048)
const ROOM_SIZE=Vector2(1536,1024)
const ROOM_ROOT="res://data/maps/luoyang_estate_rooms_20261021am/"
const E=preload("res://build/luoyang_city_completion_20261021ai_system01/revision2_two_shops_estate/estate_candidate.gd")
const B=preload("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
static var _sessions: Dictionary={}
static var _data: Dictionary={}
static var _packet: Dictionary={}
static var _mask: Image
static var _key: String=""
static var _validation: Dictionary={}
static var _serial: int=0
static func pair(value: Variant) -> bool:
	return value is Array and value.size()==2 and (value[0] is int or value[0] is float) and (value[1] is int or value[1] is float) and is_finite(float(value[0])) and is_finite(float(value[1]))
static func requested() -> bool:
	if not FileAccess.file_exists(INDEX): return false
	var script: Variant=load(INDEX)
	return script is GDScript and script.resource_path==INDEX and script.formal_enabled()==true
static func authority() -> Dictionary:
	if not FileAccess.file_exists(INDEX): return {}
	var script: Variant=load(INDEX)
	if not script is GDScript or script.resource_path!=INDEX: return {}
	var row: Dictionary=script.entry()
	if row.size()!=2 or row.get("path")!=ROOT+"manifest.json" or not B._hash(row.get("sha256")) or FileAccess.get_sha256(row.path)!=row.sha256: return {}
	return row
static func source_header() -> Dictionary:
	# Index binds this small manifest. Collectors may enumerate it without
	# serially hashing Estate media before their ordinary parallel source job.
	var entry: Dictionary=authority()
	if entry.is_empty(): return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(entry.path))
	if not value is Dictionary or value.get("status")!="ROOT_ADMITTED_AM_ESTATE_FAMILY" or value.get("scene_id")!=String(ID) or value.get("mansion_id")!=String(ROOM) or not value.get("source_sha256") is Dictionary or not pair(value.get("market_foot_px")): return {}
	# The only source authority outside this manifest is its one code index.
	# Never pin that index back into its own manifest/hash cycle.
	if value.source_sha256.has(INDEX): return {}
	for path: String in value.source_sha256:
		if not path.begins_with("res://") or ".." in path or not B._hash(value.source_sha256[path]): return {}
	for name: String in ["scene.res","layout.res","packet.bin"]:
		if not value.source_sha256.has(ROOT+name): return {}
	return value
static func manifest() -> Dictionary:
	var entry: Dictionary=authority()
	if entry.is_empty(): return {}
	var key: String=FileAccess.get_sha256(INDEX)+":"+entry.sha256
	if key==_key and not _data.is_empty(): return _data
	_data={};_packet={};_mask=null;_sessions.clear();_key=""
	var began: int=Time.get_ticks_usec();var value: Dictionary=source_header()
	if value.is_empty(): return {}
	for path: String in value.source_sha256:
		if FileAccess.get_sha256(path)!=value.source_sha256[path]: return {}
	_key=key;_data=value
	_validation={"serial":_serial,"key":key,"source_first":value.source_sha256.duplicate(true),"source_final":{},"full_source_hash_passes":1,"first_hash_elapsed_us":Time.get_ticks_usec()-began,"final_hash_elapsed_us":0,"finalized":false}
	return _data
static func validation_begin() -> bool:
	# Remove only dead owners or unfinished FIRST from a previous failed attempt.
	# Every live FINAL/parked original receipt remains byte-identical.
	for pending_key: int in _finish25i_original_owners.keys():
		var pending: Dictionary=_finish25i_original_owners[pending_key]
		var pending_scene: SceneScript=pending.scene.get_ref() as SceneScript
		var pending_layout: Resource=pending.layout.get_ref() as Resource
		if pending_scene==null or pending_layout==null:
			_finish25i_original_owners.erase(pending_key);continue
		if pending.receipt.get("finalized")!=true:
			var pending_runtime: Variant=_finish25i_runtime()
			if pending_runtime==null or not pending_runtime.discard_unfinalized_original(pending_scene,pending_layout,"ESTATE_ORIGINAL",pending.receipt): return false
			_finish25i_original_owners.erase(pending_key)
	# One source-first receipt per real joint transition, not one pass for each
	# registry/packet/matches/safe_body call in the same transition.
	_serial+=1;_data={};_packet={};_mask=null;_key="";_validation={};_sessions.clear()
	return requested() and not manifest().is_empty()
static func validation_finish() -> bool:
	if _data.is_empty() or _validation.get("serial")!=_serial or _validation.get("key")!=_key: return false
	if _validation.get("finalized")==true:
		_finish25i_promote_original_final();return true
	var entry: Dictionary=authority()
	if entry.is_empty() or FileAccess.get_sha256(INDEX)+":"+entry.sha256!=_key: return false
	var began: int=Time.get_ticks_usec();var final: Dictionary={}
	for path: String in _validation.source_first:
		final[path]=FileAccess.get_sha256(path)
		if final[path]!=_validation.source_first[path]: _data={};_packet={};_mask=null;_sessions.clear();return false
	_validation.source_final=final;_validation.full_source_hash_passes=2;_validation.final_hash_elapsed_us=Time.get_ticks_usec()-began;_validation.finalized=true
	_finish25i_promote_original_final()
	return true
static func validation_receipt() -> Dictionary: return _validation.duplicate(true)
static func source_paths() -> Dictionary:
	var data: Dictionary=source_header()
	if data.is_empty(): return {}
	var paths: Dictionary={SELF:true,INDEX:true,ROOT+"manifest.json":true}
	for path: String in data.source_sha256: paths[path]=true
	if FINISH25I_ENABLED:
		var runtime: Variant=_finish25i_runtime()
		if runtime==null: return {}
		var extra: Dictionary=runtime.source_paths_for(ID)
		if extra.is_empty(): return {}
		paths.merge(extra,true);paths[FINISH25I_ADAPTER]=true
		if FileAccess.get_sha256(FINISH25I_AMBIENT)!=FINISH25I_AMBIENT_SHA: return {}
		var ambient: Variant=load(FINISH25I_AMBIENT)
		if not ambient is GDScript or ambient.resource_path!=FINISH25I_AMBIENT: return {}
		var ambient_paths: Dictionary=ambient.source_paths_for(ID)
		if ambient_paths.is_empty(): return {}
		paths.merge(ambient_paths,true)
	if FINISH25I_ENABLED:
		if FileAccess.get_sha256(FINISH25I_DOORS)!=FINISH25I_DOORS_SHA: return {}
		var doors: Variant=load(FINISH25I_DOORS)
		if not doors is GDScript or doors.resource_path!=FINISH25I_DOORS: return {}
		var door_paths: Dictionary=doors.source_paths_for(ID)
		if door_paths.is_empty(): return {}
		paths.merge(door_paths,true)
	return paths
static func scene_path(id: StringName) -> String:
	return ROOT+"scene.res" if id==ID and requested() and not manifest().is_empty() else ""
static func registry_source() -> Dictionary:
	var data: Dictionary=source_header()
	if data.is_empty() or data.get("registry_path")!=ROOM_ROOT+"registry.json" or data.source_sha256.get(data.registry_path)!=data.get("registry_sha256") or FileAccess.get_sha256(data.registry_path)!=data.registry_sha256: return {}
	return {"path":data.registry_path,"sha256":data.registry_sha256}
static func packet() -> Dictionary:
	var data: Dictionary=manifest()
	if data.is_empty(): return {}
	if not _packet.is_empty(): return _packet
	var value: Variant=bytes_to_var(FileAccess.get_file_as_bytes(ROOT+"packet.bin"))
	if not value is Dictionary or not B._plain(value) or not value.get("enclosure_successor_AM") is Dictionary or not value.get("walk_bytes") is PackedByteArray or B.bytes_sha(value.walk_bytes)!=value.get("mask_sha256"): return {}
	_packet=value;return _packet
static func matches(scene: SceneScript) -> bool:
	if not requested() or scene==null or scene.scene_id!=ID or scene.map_layout==null or not scene.actor_positions_are_feet or scene.resource_path!=ROOT+"scene.res" or scene.map_layout.resource_path!=ROOT+"layout.res": return false
	for key: int in _sessions.keys():
		if _sessions[key].scene.get_ref()==null or _sessions[key].layout.get_ref()==null: _sessions.erase(key)
	var prior: Dictionary=_sessions.get(scene.get_instance_id(),{})
	if not prior.is_empty(): return prior.scene.get_ref()==scene and prior.layout.get_ref()==scene.map_layout and B.equal(B.storage(scene),prior.packet.scene_storage) and B.equal(B.storage(scene.map_layout),prior.packet.layout_storage) and _finish25i_ensure(scene)
	var value: Dictionary=packet()
	if _sessions.size()>=4 or value.is_empty() or not B.equal(B.storage(scene),value.scene_storage) or not B.equal(B.storage(scene.map_layout),value.layout_storage): return false
	_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout),"packet":value}
	return _finish25i_ensure(scene)
static func safe_body(foot: Vector2) -> bool:
	if FINISH25I_ENABLED: return _finish25i_safe(ID,foot)
	var value: Dictionary=packet()
	if value.is_empty() or not foot.is_finite(): return false
	var solids: Array[Dictionary]=[]
	for row: Dictionary in value.rectangular_solids: solids.append(row)
	if _mask==null: _mask=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,value.walk_bytes)
	return E.safe_body(foot,_mask,solids)
static func owns_route(source: StringName,target: StringName) -> bool:
	return requested() and ((source==MARKET and target==ID) or (source==ID and target in [MARKET,ROOM]) or (source==ROOM and target==ID))
static func prepare_arrival(source: StringName,target: StringName,authored: Variant,remembered: Variant,destination: SceneScript) -> Dictionary:
	if not owns_route(source,target) or not authored is Vector2 or destination==null or destination.scene_id!=target: return {}
	var data: Dictionary=manifest()
	if data.is_empty(): return {}
	var expected: Vector2
	if target==ID:
		if not matches(destination): return {}
		expected=Vector2(1536,1840)/SIZE if source==MARKET else Vector2(1536,544)/SIZE
	elif target==MARKET: expected=E.v(data.market_foot_px)/SIZE
	else: expected=Vector2(768,840)/ROOM_SIZE
	if authored!=expected or (remembered!=null and not remembered is Vector2): return {}
	var arrival: Vector2=remembered if remembered is Vector2 else authored
	var size: Vector2=ROOM_SIZE if target==ROOM else SIZE
	# Remembered feet must belong to this exact route's doorway vicinity, not an
	# unrelated old Market/mansion position transplanted into a different map.
	if not arrival.is_finite() or ((arrival-expected)*size).length()>180.0: return {}
	if target==ID:
		if not safe_body(arrival*SIZE): return {}
	elif target==MARKET:
		var city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
		if not city.is_v3(destination) or not city.safe_body(MARKET,arrival*SIZE): return {}
	else:
		var rooms: Variant=load("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
		if not rooms.matches(destination,ROOM): return {}
		var geometry: Dictionary=rooms.compile_geometry(rooms.author_for_id(ROOM).get("geometry",{}),ROOM_SIZE)
		if not rooms.safe_foot(geometry,arrival*ROOM_SIZE,ROOM_SIZE,true): return {}
	return {"spawn":arrival,"source_version":3,"target_version":3,"reason":"am_exact_source_bound_family_arrival"}
static func project_market(scene: SceneScript,original: Array) -> Dictionary:
	if not requested() or scene==null or scene.scene_id!=MARKET: return {"ok":true,"portals":original.duplicate(true)}
	var data: Dictionary=manifest();var city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
	if data.is_empty() or not city.is_v3(scene): return {"ok":false,"portals":[],"error":"AM_MARKET_BOUND_SOURCE"}
	var foot: Vector2=E.v(data.market_foot_px)
	if not city.safe_body(MARKET,foot) or not city.safe_body(MARKET,foot+Vector2(0,24)): return {"ok":false,"portals":[],"error":"AM_ALLEY_NATIVE34X24_AND24"}
	var result: Array=[];var removed: int=0
	for row: Dictionary in original:
		if String(row.get("target_scene",""))==String(ID) or row.get("id")=="am_market_estate_alley": return {"ok":false,"portals":[],"error":"AM_DUPLICATE_ALLEY"}
		if String(row.get("target_scene",""))==String(ROOM):
			if row.get("pos")!=Vector2(2820.8/3072.0,1704.0/2048.0) or row.get("size")!=Vector2(40.0/3072.0,32.0/2048.0) or row.get("auto_trigger")!=false: return {"ok":false,"portals":[],"error":"AM_ONLY_EXACT_OLD_MANSION_DOOR_REMOVABLE"}
			removed+=1
		else: result.append(row.duplicate(true))
	if removed!=1: return {"ok":false,"portals":[],"error":"AM_EXACTLY_ONE_OLD_MANSION_DOOR_REQUIRED"}
	result.append({"id":"am_market_estate_alley","pos":foot/SIZE,"size":Vector2(40,32)/SIZE,"auto_trigger":false,"target_scene":String(ID),"target_scene_path":ROOT+"scene.res","target_pos":Vector2(1536,1840)/SIZE,"label":"前往宅园","interaction_polygon_px":PackedVector2Array([foot+Vector2(-20,-16),foot+Vector2(20,-16),foot+Vector2(20,16),foot+Vector2(-20,16)])})
	return {"ok":true,"portals":result,"removed_only_previous_mansion_door":removed}
