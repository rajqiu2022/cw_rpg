extends RefCounted
## Source-bound visual-only overlay AFTER the unchanged harbour publication.
## No C/nav/old record mutation and no cross-token texture or proof cache.
const SELF := "res://scripts/city/luoyang_docks_office_roles_20261016h.gd"
const FLAG := "--luoyang-docks-office-roles-20261016h"
const FORMAL_ENABLED := true
const AUTHOR_PATH := "res://data/maps/luoyang_docks_office_20261016h/author.json"
const AUTHOR_SHA := "dc8d7ae836735f349360ca0bd69cc0290ebc6461470e7bd3af359ded568ec9e7"
const META := "docks_office_roles_visual_author_20261016h"
const CITY := &"ch4_s2_canal_docks"
const BUILDING := "harbour_cargo_trade_front"
const ROLE_IDS := ["harbour_life_docks_loading_attendant","harbour_life_docks_booking_attendant"]
const SIZE := Vector2(3072,2048)
const VISUAL_KEYS := ["texture","source","source_sha256","source_size_px","pos","render_size_px","centered","foot_uv","actual_gpu","historical_parent_visual_provenance","docks_office_visual_author"]

static func enabled() -> bool: return FORMAL_ENABLED or FLAG in OS.get_cmdline_user_args()
static func requested(id: StringName) -> bool: return enabled() and id==CITY
static func _v(raw: Array) -> Vector2: return Vector2(float(raw[0]),float(raw[1]))
static func _sha(bytes: PackedByteArray) -> String:
	var hash: HashingContext=HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256)!=OK or hash.update(bytes)!=OK: return ""
	return hash.finish().hex_encode()
static func _wire(value: Variant) -> String: return JSON.stringify(JSON.parse_string(JSON.stringify(value,"\t",true,true)),"\t",true,true)
static func author() -> Dictionary:
	if AUTHOR_SHA.length()!=64 or FileAccess.get_sha256(AUTHOR_PATH)!=AUTHOR_SHA: return {}
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR_PATH))
	if not raw is Dictionary or raw.get("status")!="READY_SOURCE_BOUND_VISUAL_CANDIDATE" or raw.get("scene_id")!=String(CITY): return {}
	return raw
static func source_paths() -> Dictionary:
	if not enabled(): return {SELF:true}
	var result: Dictionary={SELF:true,AUTHOR_PATH:true}
	var data: Dictionary=author()
	for path: String in data.get("source_sha256",{}):
		if not path.begins_with("res://") or ".." in path: return {}
		result[path]=true
	return result
static func _polygon(raw: Array) -> PackedVector2Array:
	var result: PackedVector2Array=PackedVector2Array()
	for point: Array in raw: result.append(_v(point))
	return result
static func prepare_packet(record: Dictionary,cancel: Callable=Callable()) -> Dictionary:
	var data: Dictionary=author()
	if data.is_empty() or data.get("source_sha256",{}).is_empty() or data.get("roles",{}).size()!=2: return {}
	for path: String in data.source_sha256:
		if cancel.is_valid() and cancel.call(): return {}
		if FileAccess.get_sha256(path)!=data.source_sha256[path]: return {}
	var import_proof: Dictionary=data.get("import_proof",{})
	var report_path: String=String(import_proof.get("path",""))
	if data.source_sha256.get(report_path)!=import_proof.get("sha256"): return {}
	var import_report: Variant=JSON.parse_string(FileAccess.get_file_as_string(report_path))
	if not import_report is Dictionary or import_report.get("passed")!=true or not import_report.get("failures",["missing"]).is_empty() or _wire(import_report.get("rows"))!=_wire(data.get("texture_proofs")): return {}
	if data.source_sha256.get(data.parent_manifest)!=data.parent_manifest_sha256: return {}
	var parent: Variant=JSON.parse_string(FileAccess.get_file_as_string(data.parent_manifest))
	if not parent is Dictionary: return {}
	var original: Dictionary={}; var actual: Dictionary={}; var count: int=0
	for item: Dictionary in parent.get("record",{}).get("objects",[]):
		if item.get("id")==BUILDING: original=item
	for item: Dictionary in record.get("objects",[]):
		if item.get("id")==BUILDING: actual=item; count+=1
	if count!=1 or original.is_empty() or _wire(actual)!=_wire(original): return {}
	var office: Dictionary=data.office
	if office.get("id")!=BUILDING or office.get("no_new_portal_or_room")!=true or _v(office.expected_foot_px)!=_v(actual.world_foot_px): return {}
	var anchor: Vector2=_v(office.source_ground_anchor_px)
	var scale: Vector2=_v(office.render_scale_xy)
	if not anchor.is_finite() or not scale.is_finite() or scale.x<=0 or scale.y<=0 or office.ground_solid_polygons_px.is_empty(): return {}
	# New complete base MUST lie inside the existing physical support. Never
	# overwrite NAV, remove old solid or hide a geometry mismatch with alpha.
	for raw: Array in office.ground_solid_polygons_px:
		var pending: Array[PackedVector2Array]=[]
		var polygon: PackedVector2Array=PackedVector2Array()
		for point: Array in raw: polygon.append(_v(actual.world_foot_px)+(_v(point)-anchor)*scale)
		if polygon.size()<3: return {}
		pending.append(polygon)
		for old_raw: Array in actual.solid_polygons_px:
			var remaining: Array[PackedVector2Array]=[]
			for piece: PackedVector2Array in pending: remaining.append_array(Geometry2D.clip_polygons(piece,_polygon(old_raw)))
			pending=remaining
		if not pending.is_empty(): return {}
	var used: Dictionary={String(office.texture):_v(office.source_size_px)}
	for id: String in ROLE_IDS:
		var role: Dictionary=data.roles.get(id,{})
		var dimensions: Array=role.get("runtime_size_px",[])
		if role.is_empty() or dimensions.size()!=2 or dimensions[0]!=160 or dimensions[1]!=160 or role.get("hframes")!=1: return {}
		used[String(role.texture)]=Vector2(160,160)
	var proofs: Dictionary={}
	for row: Dictionary in data.get("texture_proofs",[]):
		var path: String=String(row.get("texture",""))
		if proofs.has(path) or not used.has(path) or row.get("full_rgba_exact")!=true or row.get("params23")!=true: return {}
		for key: String in ["texture","import_path","compiled_path"]:
			if not data.source_sha256.has(String(row.get(key,""))): return {}
		var image: Image=Image.load_from_file(path)
		if image==null or image.get_size()!=Vector2i(int(row.size_px[0]),int(row.size_px[1])): return {}
		if Vector2(image.get_size())!=used[path]: return {}
		image.convert(Image.FORMAT_RGBA8)
		if _sha(image.get_data())!=row.get("rgba_sha256"): return {}
		proofs[path]=row.duplicate(true)
	if used.size()!=3 or proofs.size()!=used.size(): return {}
	return {"author_sha256":AUTHOR_SHA,"author":data,"texture_proofs":proofs,"same_existing_base":true,"no_navigation_or_task_delta":true}
static func _packet_valid(packet: Dictionary) -> bool:
	return not packet.is_empty() and packet.get("author_sha256")==AUTHOR_SHA and packet.get("same_existing_base")==true and packet.get("no_navigation_or_task_delta")==true
static func materialize(scene: SceneScript,packet: Dictionary) -> SceneScript:
	if scene==null or scene.scene_id!=CITY or not _packet_valid(packet) or scene.map_layout==null: return null
	# Observe actual imported Texture2D on MAIN, not ResourceLoader in worker.
	for path: String in packet.texture_proofs:
		var proof: Dictionary=packet.texture_proofs[path]
		var texture: Texture2D=ResourceLoader.load(path) as Texture2D
		var image: Image=texture.get_image() if texture!=null else null
		if image==null or image.get_size()!=Vector2i(int(proof.size_px[0]),int(proof.size_px[1])): return null
		image.convert(Image.FORMAT_RGBA8)
		if _sha(image.get_data())!=proof.rgba_sha256: return null
	var office: Dictionary=packet.author.office
	var objects: Array=scene.map_layout.visual_objects.duplicate(true)
	var count: int=0
	for item: Dictionary in objects:
		if item.get("id")!=BUILDING: continue
		count+=1
		var before: Dictionary=item.duplicate(true)
		var foot: Vector2=_v(office.expected_foot_px)
		var anchor: Vector2=_v(office.source_ground_anchor_px)
		var scale: Vector2=_v(office.render_scale_xy)
		item.texture=String(office.texture)
		var origin: Vector2=foot-anchor*scale
		item.pos=origin/SIZE
		item.render_size_px=_v(office.source_size_px)*scale
		item.centered=false
		item.foot_uv=[anchor.x/float(office.source_size_px[0]),anchor.y/float(office.source_size_px[1])]
		item.historical_parent_visual_provenance={"source":before.get("source"),"source_sha256":before.get("source_sha256"),"source_size_px":before.get("source_size_px"),"actual_gpu":before.get("actual_gpu"),"scope":"Original published native render evidence ONLY; not new office artwork/GPU evidence"}
		item.source=String(office.texture)
		item.source_sha256=packet.author.source_sha256[String(office.texture)]
		item.source_size_px=office.source_size_px.duplicate()
		item.erase("actual_gpu")
		item.docks_office_visual_author=AUTHOR_SHA
		var preserved: Dictionary=item.duplicate(true)
		for key: String in VISUAL_KEYS: before.erase(key); preserved.erase(key)
		if _wire(before)!=_wire(preserved): return null
	if count!=1: return null
	# Do not touch inherited external layout resources or the CPU record.
	scene.map_layout=scene.map_layout.duplicate(true)
	scene.map_layout.visual_objects.assign(objects)
	scene.set_meta(META,AUTHOR_SHA)
	return scene
static func project_npcs(scene: SceneScript,original: Array) -> Dictionary:
	if scene==null or scene.scene_id!=CITY or scene.get_meta(META,"")!=AUTHOR_SHA: return {"ok":false,"error":"Office roles lack actual Scene visual binding"}
	var data: Dictionary=author()
	if data.is_empty(): return {"ok":false,"error":"Office role author source changed"}
	var result: Array=original.duplicate(true)
	var seen: Dictionary={}
	for row: Dictionary in result:
		var id: String=String(row.get("npc_id",""))
		if id not in ROLE_IDS: continue
		if seen.has(id): return {"ok":false,"error":"Duplicate exact office role ID"}
		var role: Dictionary=data.roles[id]
		if row.get("npc_name")!=role.expected_name or row.get("pos")!=_v(role.expected_foot_px)/SIZE or row.get("sprite_path")!=role.expected_original_texture or row.get("movement_mode")!="idle" or row.get("scale")!=1.0 or not String(row.get("dialog_id","")).is_empty() or not String(row.get("interaction_action","")).is_empty(): return {"ok":false,"error":"Original office role semantics or foot changed"}
		row.sprite_path=String(role.texture)
		seen[id]=true
	return {"ok":seen.size()==2,"npcs":result,"author_sha256":AUTHOR_SHA,"changed_fields":["sprite_path"],"single_frame_not_animation":true}
