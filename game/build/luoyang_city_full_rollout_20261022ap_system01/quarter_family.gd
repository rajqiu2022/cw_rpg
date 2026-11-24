extends RefCounted
## Two new AP ordinary fields. The original city validation path remains owned
## by C/B; this family never claims a new field is one of those four cities.
const SELF="res://scripts/city/luoyang_quarters_family_20261022ap.gd"
const INDEX="res://scripts/city/luoyang_quarters_index_20261022ap.gd"
const ROOT="res://data/maps/luoyang_full_city_20261022ap/"
const IDS=[&"luoyang_artisan_residential_20261022ap",&"luoyang_riverside_garden_20261022ap"]
const SIZE=Vector2(3072,2048)
const B_PATH="res://scripts/city/luoyang_precomputed_bundle_20261018r.gd"
const COMPILER="res://build/luoyang_city_full_rollout_20261022ap_system01/quarters_compiler.gd"
static var _data: Dictionary={}
static var _key: String=""
static var _packets: Dictionary={}
static var _images: Dictionary={}
static var _sessions: Dictionary={}
static var _receipt: Dictionary={}
static var _serial: int=0
static var _connection_receipt: Dictionary={}
static func b() -> Variant: return load(B_PATH)
static func requested() -> bool:
	if not FileAccess.file_exists(INDEX): return false
	var authority: Variant=load(INDEX)
	return authority is GDScript and authority.resource_path==INDEX and authority.formal_enabled()==true
static func source_header() -> Dictionary:
	if not requested(): return {}
	var entry: Dictionary=load(INDEX).entry()
	if entry.size()!=2 or entry.get("path")!=ROOT+"manifest.json" or not b()._hash(entry.get("sha256")) or FileAccess.get_sha256(entry.path)!=entry.sha256: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(entry.path))
	if not raw is Dictionary or raw.get("status")!="ROOT_ADMITTED_AP_TWO_QUARTERS" or not raw.get("scenes") is Dictionary or raw.scenes.size()!=2 or not raw.get("source_sha256") is Dictionary or raw.source_sha256.is_empty() or raw.source_sha256.has(INDEX): return {}
	for id: StringName in IDS:
		var row: Dictionary=raw.scenes.get(String(id),{})
		if row.get("scene_path")!=ROOT+String(id)+"/scene.res" or row.get("layout_path")!=ROOT+String(id)+"/layout.res" or row.get("packet_path")!=ROOT+String(id)+"/packet.bin": return {}
		for p: String in [row.scene_path,row.layout_path,row.packet_path,ROOT+String(id)+"/walk.png",COMPILER,SELF]:
			if not raw.source_sha256.has(p): return {}
	for p: String in raw.source_sha256:
		if not p.begins_with("res://") or ".." in p or not b()._hash(raw.source_sha256[p]): return {}
	return raw
static func manifest() -> Dictionary:
	var header: Dictionary=source_header()
	if header.is_empty(): return {}
	var key: String=FileAccess.get_sha256(INDEX)+":"+load(INDEX).entry().sha256
	if key==_key and not _data.is_empty(): return _data
	_data={};_packets={};_images={};_sessions={};_key=""
	var began: int=Time.get_ticks_usec()
	for p: String in header.source_sha256:
		if FileAccess.get_sha256(p)!=header.source_sha256[p]: return {}
	_data=header;_key=key
	_receipt={"serial":_serial,"key":key,"source_first":header.source_sha256.duplicate(true),"source_final":{},"full_source_hash_passes":1,"first_hash_elapsed_us":Time.get_ticks_usec()-began,"finalized":false}
	return _data
static func validation_begin() -> bool:
	_serial+=1;_data={};_key="";_packets={};_images={};_sessions={};_receipt={}
	return not manifest().is_empty()
static func validation_finish() -> bool:
	if _data.is_empty() or _receipt.get("serial")!=_serial or _receipt.get("key")!=_key or source_header().is_empty(): return false
	if FileAccess.get_sha256(INDEX)+":"+load(INDEX).entry().sha256!=_key: return false
	if _receipt.get("finalized")==true: return true
	var began: int=Time.get_ticks_usec();var final: Dictionary={}
	for p: String in _receipt.source_first:
		final[p]=FileAccess.get_sha256(p)
		if final[p]!=_receipt.source_first[p]: _data={};_packets={};_images={};_sessions={};return false
	_receipt.source_final=final;_receipt.full_source_hash_passes=2;_receipt.final_hash_elapsed_us=Time.get_ticks_usec()-began;_receipt.finalized=true;return true
static func validation_receipt() -> Dictionary: return _receipt.duplicate(true)
static func source_paths() -> Dictionary:
	var data: Dictionary=source_header()
	if data.is_empty(): return {}
	var out: Dictionary={SELF:true,INDEX:true,ROOT+"manifest.json":true}
	for p: String in data.source_sha256: out[p]=true
	return out
static func scene_path(id: StringName) -> String:
	return ROOT+String(id)+"/scene.res" if id in IDS and not manifest().is_empty() else ""
static func packet(id: StringName) -> Dictionary:
	var data: Dictionary=manifest()
	if id not in IDS or data.is_empty(): return {}
	if _packets.has(id): return _packets[id]
	var row: Dictionary=data.scenes[String(id)]
	var raw: Variant=bytes_to_var(FileAccess.get_file_as_bytes(row.packet_path))
	if not raw is Dictionary or not b()._plain(raw) or raw.get("kind")!="AP_SOURCE_BOUND_NEW_ORDINARY_QUARTER" or raw.get("scene_id")!=String(id) or not raw.get("walk_bytes") is PackedByteArray or b().bytes_sha(raw.walk_bytes)!=raw.get("mask_sha256"): return {}
	_packets[id]=raw;return raw
static func matches(scene: SceneScript) -> bool:
	if scene==null or scene.scene_id not in IDS or scene.map_layout==null or not scene.actor_positions_are_feet: return false
	var data: Dictionary=manifest();var value: Dictionary=packet(scene.scene_id)
	if data.is_empty() or value.is_empty(): return false
	var row: Dictionary=data.scenes[String(scene.scene_id)]
	if scene.resource_path!=row.scene_path or scene.map_layout.resource_path!=row.layout_path or scene.get_meta("luoyang_full_city_AP","")!=value.author_sha256: return false
	if not b().equal(b().storage(scene),value.scene_storage) or not b().equal(b().storage(scene.map_layout),value.layout_storage): return false
	for old: int in _sessions.keys():
		if _sessions[old].scene.get_ref()==null or _sessions[old].layout.get_ref()==null: _sessions.erase(old)
	if _sessions.size()>=8 and not _sessions.has(scene.get_instance_id()): return false
	_sessions[scene.get_instance_id()]={"scene":weakref(scene),"layout":weakref(scene.map_layout)};return true
static func safe_body(id: StringName,foot: Vector2) -> bool:
	var value: Dictionary=packet(id)
	if value.is_empty(): return false
	if not _images.has(id):
		var image: Image=Image.load_from_file(ROOT+String(id)+"/walk.png")
		if image==null: return false
		image.convert(Image.FORMAT_RGBA8)
		if image.get_size()!=Vector2i(3072,2048) or image.get_data()!=value.walk_bytes: return false
		_images[id]=image
	return load(COMPILER).safe_body(foot,_images[id],value.solids)
static func owns_route(source: StringName,target: StringName) -> bool:
	if source not in IDS and target not in IDS: return false
	var data: Dictionary=source_header()
	if data.is_empty(): return false
	var found: int=0
	for row: Dictionary in data.get("connections",[]):
		if row.get("source")==String(source) and row.get("target")==String(target): found+=1
	return found==1
static func project_connections(scene: SceneScript,original: Array) -> Dictionary:
	if scene==null: return {"ok":false,"error":"AP_CONNECTION_SCENE_NULL","portals":[]}
	var data: Dictionary=source_header()
	if data.is_empty(): return {"ok":false,"error":"AP_CONNECTION_HEADER_NOT_READY","portals":[]}
	var selected: Array=[]
	for row: Dictionary in data.get("connections",[]):
		if row.get("source")==String(scene.scene_id) and row.get("target") in [String(IDS[0]),String(IDS[1])] and row.get("kind")=="PUBLIC_QUARTER_LINK": selected.append(row)
	if selected.is_empty(): return {"ok":true,"portals":original.duplicate(true),"AP_connection_delta":0}
	# Existing fields load only this control header and projection executable,
	# not future Garden/Artisan media. Their own parent family/C lease owns the
	# actual native resources. Keep this composed source domain cycle-free.
	var header_first: Dictionary={INDEX:FileAccess.get_sha256(INDEX),ROOT+"manifest.json":load(INDEX).entry().sha256}
	for path: String in [SELF,COMPILER]:
		if not data.source_sha256.has(path) or FileAccess.get_sha256(path)!=data.source_sha256[path]: return {"ok":false,"error":"AP_CONNECTION_HEADER_EXECUTABLE_CHANGED","portals":[]}
		header_first[path]=data.source_sha256[path]
	var parent_ok: bool=false
	if scene.scene_id in IDS: parent_ok=matches(scene)
	elif scene.scene_id==&"luoyang_estate_riverside_20261021ai": parent_ok=load("res://scripts/city/luoyang_estate_family_20261021am.gd").matches(scene)
	else:
		var city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
		parent_ok=city.is_v3(scene) and b().whole_bound(scene)
	if not parent_ok: return {"ok":false,"error":"AP_CONNECTION_REAL_PARENT_OWNER","portals":[]}
	var out: Array=original.duplicate(true)
	for row: Dictionary in selected:
		if not load(COMPILER).pair(row.get("source_foot")) or not load(COMPILER).pair(row.get("target_foot")) or not owns_route(scene.scene_id,StringName(row.target)): return {"ok":false,"error":"AP_CONNECTION_EXACT_COORDINATES","portals":[]}
		var foot: Vector2=load(COMPILER).v(row.source_foot)
		for offset: float in [0.0,10.0,24.0]:
			var point: Vector2=foot+Vector2(0,offset)
			var safe: bool=false
			if scene.scene_id in IDS: safe=safe_body(scene.scene_id,point)
			elif scene.scene_id==&"luoyang_estate_riverside_20261021ai": safe=load("res://scripts/city/luoyang_estate_family_20261021am.gd").safe_body(point)
			else: safe=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd").safe_body(scene.scene_id,point)
			if not safe: return {"ok":false,"error":"AP_CONNECTION_NATIVE_BODY_PLUS24:"+String(row.id),"portals":[]}
		for prior: Dictionary in out:
			if prior.get("id")==row.id or String(prior.get("target_scene",""))==row.target: return {"ok":false,"error":"AP_CONNECTION_DUPLICATE_TARGET","portals":[]}
		out.append({"id":row.id,"pos":foot/SIZE,"size":Vector2(40,32)/SIZE,"target_scene":row.target,"target_scene_path":ROOT+row.target+"/scene.res","target_pos":load(COMPILER).v(row.target_foot)/SIZE,"auto_trigger":false,"label":row.label,"interaction_polygon_px":PackedVector2Array([foot+Vector2(-20,-16),foot+Vector2(20,-16),foot+Vector2(20,16),foot+Vector2(-20,16)])})
	var header_final: Dictionary={}
	for path: String in header_first:
		header_final[path]=FileAccess.get_sha256(path)
		if header_final[path]!=header_first[path]: return {"ok":false,"error":"AP_CONNECTION_HEADER_SOURCE_FINAL_CHANGED","portals":[]}
	_connection_receipt={"scene_id":String(scene.scene_id),"source_first":header_first,"source_final":header_final,"scope":"AP_PUBLIC_LINK_HEADER_ONLY_PARENT_NATIVE_LEASE_SEPARATE","future_quarter_media_loaded":false,"source_hash_passes":2}
	return {"ok":true,"portals":out,"AP_connection_delta":selected.size(),"native_parent_portals_unchanged_prefix":true,"source_receipt":_connection_receipt.duplicate(true)}
static func connection_receipt() -> Dictionary: return _connection_receipt.duplicate(true)
static func prepare_arrival(source: StringName,target: StringName,authored: Variant,remembered: Variant,destination: SceneScript) -> Dictionary:
	if not authored is Vector2 or not owns_route(source,target) or manifest().is_empty(): return {}
	var route: Dictionary={}
	for row: Dictionary in _data.connections:
		if row.source==String(source) and row.target==String(target): route=row
	if route.is_empty() or not load(COMPILER).pair(route.get("target_foot")): return {}
	var target_size: Vector2=load(COMPILER).v(route.target_size) if load(COMPILER).pair(route.get("target_size")) else SIZE
	if authored!=load(COMPILER).v(route.target_foot)/target_size or (remembered!=null and not remembered is Vector2): return {}
	var arrival: Vector2=remembered if remembered is Vector2 else authored
	if not arrival.is_finite() or ((arrival-authored)*target_size).length()>180.0: return {}
	if target in IDS:
		if not matches(destination) or not safe_body(target,arrival*SIZE): return {}
	elif target==&"luoyang_estate_riverside_20261021ai":
		var estate: Variant=load("res://scripts/city/luoyang_estate_family_20261021am.gd")
		if not estate.matches(destination) or not estate.safe_body(arrival*SIZE): return {}
	elif route.get("target_kind")=="EXISTING_ROOM_RETURN_ONLY":
		var rooms: Variant=load("res://scripts/city/luoyang_assembled_interiors_20261016g.gd")
		if not rooms.matches(destination,target) or target_size!=Vector2(1536,1024): return {}
		var geometry: Dictionary=rooms.compile_geometry(rooms.author_for_id(target).get("geometry",{}),target_size)
		if geometry.is_empty() or not rooms.safe_foot(geometry,arrival*target_size,target_size,true): return {}
	else:
		# A legacy field must already have passed its OWN arrival/identity path.
		# Revalidate its original full body rather than claiming our new mask.
		var old_city: Variant=load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
		if destination==null or destination.scene_id!=target or not old_city.safe_body(target,arrival*SIZE): return {}
	return {"spawn":arrival,"source_version":3,"target_version":3,"reason":"source_bound_AP_quarter_pair"}
