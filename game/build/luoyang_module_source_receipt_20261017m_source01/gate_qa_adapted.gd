extends RefCounted
## Third layer ONLY after the complete original V11 enclosure proof.
## Pending capture/publication cannot select a Field or replace formal Gate.
const BASE = preload("res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd")
const STABLE_IMPORTS = preload("res://build/luoyang_module_source_receipt_20261017m_source01/stable_candidate.gd")
const CPU_WORKSPACE = preload("res://scripts/city/luoyang_base_cold_cpu_workspace_20261013.gd")
const ID := &"ch4_s0_luoyang_gate"
const FLAG := "--luoyang-gate-fortification-candidate"
const META := "city_gate_fortification_manifest_sha"
const ROOT := "res://art/maps/luoyang_gate_fortification_v3_refined/"
const AUTHOR_PATH := ROOT + "gate_author_config.json"
const AUTHOR_SHA := "0c51ebc73a11d1a7f4679f537c9f71511d58e976689abe5c1db46e8e5bbe45c2"
const MANIFEST_PATH := ROOT + "runtime_manifest.json"
const MANIFEST_SHA := "6800370f5d343c8212332f497990ee50e4ea0dfb2002319794ed9a69f72009d0"
const LAYOUT_PATH := "res://data/maps/luoyang_gate_fortification_v3_candidates/ch4_s0_luoyang_gate_layout.tres"
const SCENE_PATH := "res://data/scenes/luoyang_gate_fortification_v3_candidates/ch4_s0_luoyang_gate.tres"
const BRIDGE := "res://art/modules/world_map_v13/bridge_stone_northsouth_v1.png"
const NEW_BUILDINGS := ["gate_wall_333", "gate_wall_950", "gate_wall_2122", "gate_wall_2739", "gate_tower_140", "gate_tower_2932"]

static func requested(id: StringName, scene: SceneScript = null) -> bool:
	# Zero added file/hash work for the three other cities or original Gate.
	if id != ID: return false
	if FLAG in OS.get_cmdline_user_args(): return true
	return scene != null and scene.scene_id == ID and scene.has_meta(META)

static func bound(scene: SceneScript) -> bool:
	return scene != null and scene.scene_id == ID and scene.map_layout != null and BASE._hash(MANIFEST_SHA) and scene.get_meta(META, "") == MANIFEST_SHA and scene.map_layout.walkable_mask_path == ROOT + "walk.png" and scene.background_path == ROOT + "floor.png"

static func _read(path: String, sha: String) -> Dictionary:
	if not BASE._hash(sha) or FileAccess.get_sha256(path) != sha: return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}

static func author() -> Dictionary:
	var config := _read(AUTHOR_PATH, AUTHOR_SHA)
	if config.get("scene_id") != String(ID) or BASE._vec(config.get("design_size_px")) != BASE.SIZE or BASE._vec(config.get("portal_foot_px")) != Vector2(1536,500) or BASE._vec(config.get("return_foot_px")) != Vector2(1536,1860) or BASE._vec(config.get("retained_sergeant_foot_px")) != Vector2(1740,1540) or config.get("activated") != false: return {}
	return config

static func capture(config: Dictionary,cpu_context: RefCounted=null,token: int=0) -> Dictionary:
	# Each immutable report owns exactly one current module. Do not borrow the
	# presentation-group slots or assert bit-exact old 3D support for B3.
	if cpu_context!=null and not _receipt_owner(cpu_context,token): return {}
	var requested: Variant = config.get("native_captures")
	if not requested is Dictionary or requested.size() != 2 or not requested.has("wall") or not requested.has("tower"): return {}
	var merged: Dictionary = {}
	var result: Dictionary = {"schema_version":1,"ground_y_reference_world_px":500}
	for kind: String in ["wall", "tower"]:
		var pin: Variant = requested[kind]
		if not pin is Dictionary or typeof(pin.get("path")) != TYPE_STRING or not BASE._hash(pin.get("sha256")): return {}
		var report := _read(pin.path,pin.sha256)
		var consumer: Variant = report.get("consumer_catalog")
		if report.get("passed_capture_checks") != true or not consumer is Dictionary or not BASE._num(consumer.get("schema_version"), 1) or not BASE._num(consumer.get("ground_y_reference_world_px"), 500): return {}
		var catalog: Variant = consumer.get("source_catalog")
		if not catalog is Dictionary or catalog.get("unchanged") != true or not catalog.get("sha256_by_res_path") is Dictionary or not BASE._equal_value(catalog.sha256_by_res_path, catalog.get("last_readback_sha256_by_res_path")): return {}
		for path: Variant in catalog.sha256_by_res_path:
			var sha: Variant = catalog.sha256_by_res_path[path]
			if not _source(path,sha,cpu_context,token): return {}
			# Reports remain immutable historical oracles. This derived catalogue
			# records the actual approved variant, never labels old hashes current.
			var current_sha: String = FileAccess.get_sha256(path) if cpu_context==null else _receipt_sha(cpu_context,token,path)
			if merged.has(path) and merged[path] != current_sha: return {}
			merged[path] = current_sha
		var item: Variant = consumer.get(kind)
		if not item is Dictionary or not _source(item.get("texture_path"), item.get("texture_sha256"),cpu_context,token) or not _source(item.get("mesh_path"), item.get("mesh_sha256"),cpu_context,token): return {}
		var size := BASE._vec(item.get("render_size_px")); var uv := BASE._vec(item.get("foot_uv")); var anchor := BASE._vec(item.get("foot_anchor_px"))
		if not size.is_finite() or size.x <= 0 or size.y <= 0 or not BASE._png_size(item.texture_path, Vector2i(size)) or not uv.is_finite() or uv.x < 0 or uv.y < 0 or uv.x > 1 or uv.y > 1 or anchor != uv * size: return {}
		var support := BASE._polygon(item.get("support_polygon_px"))
		if support.size() < 3 or Geometry2D.triangulate_polygon(support).is_empty(): return {}
		result[kind] = item.duplicate(true)
	result.source_catalog = {"sha256_by_res_path":merged,"last_readback_sha256_by_res_path":merged.duplicate(),"unchanged":true}
	return result

static func _source(path: Variant, sha: Variant,cpu_context: RefCounted=null,token: int=0) -> bool:
	if typeof(path) != TYPE_STRING or not path.begins_with("res://") or ".." in path or not BASE._hash(sha): return false
	if cpu_context!=null:
		var current: String=_receipt_sha(cpu_context,token,path)
		if current.is_empty(): return false
		if STABLE_IMPORTS.handles(path): return STABLE_IMPORTS.matches_from_receipt(path,sha,cpu_context,token,ID)
		return current==sha
	return FileAccess.get_sha256(path) == sha or STABLE_IMPORTS.matches(path,sha)

static func _receipt_owner(cpu_context: RefCounted,token: int) -> bool:
	return cpu_context!=null and cpu_context.get_script()==CPU_WORKSPACE and token>0 and cpu_context.matches_owner(token,ID)

static func _receipt_sha(cpu_context: RefCounted,token: int,path: String) -> String:
	return cpu_context.source_sha(ID,path) if _receipt_owner(cpu_context,token) else ""

static func _xy(point: Vector2) -> Array: return [float(point.x), float(point.y)]
static func _rect(rect: Rect2) -> Array:
	var points: Array = []
	for point: Vector2 in BASE._rect_polygon(rect): points.append(_xy(point))
	return points

static func _object(oid: String, texture: String, source_size: Vector2, render: Vector2, foot: Vector2, uv: Vector2, solids: Array, ghost: bool = true, sorted: bool = true, z: int = 0) -> Dictionary:
	return {"id":oid,"texture":texture,"source":texture,"source_size_px":_xy(source_size),"render_size_px":_xy(render),"world_foot_px":_xy(foot),"world_origin_px":_xy(foot-uv*render),"physical_center_px":_xy(foot),"collision_size_px":[0.0,0.0],"foot_uv":_xy(uv),"depth_foot_y":float(foot.y),"solid_polygons_px":solids,"blocking":not solids.is_empty(),"ghost_occlusion":ghost,"gate_sort_by_feet":sorted,"gate_z_index":float(z),"gate_module_object":true}

static func _relocate(original: Dictionary, oid: String, render: Vector2, foot: Vector2) -> Dictionary:
	var ratio := render / BASE._vec(original.render_size_px)
	var old_foot := BASE._vec(original.world_foot_px)
	var solids: Array = []
	for polygon: Array in original.solid_polygons_px:
		var transformed: Array = []
		for point: Variant in polygon: transformed.append(_xy(foot + (BASE._vec(point)-old_foot)*ratio))
		solids.append(transformed)
	return _object(oid, original.source, BASE._vec(original.source_size_px), render, foot, BASE._vec(original.foot_uv), solids)

static func compose(old_record: Dictionary, config: Dictionary, native: Dictionary) -> Dictionary:
	if config.is_empty() or native.is_empty() or old_record.get("canonical_scene_id") != String(ID): return {}
	var base := _read(BASE.ROOT+String(ID)+"/art_contract.json", String(BASE.MANIFEST_SHAS[String(ID)]))
	if base.is_empty(): return {}
	var originals: Dictionary = {}
	for object: Dictionary in base.objects: originals[String(object.id)] = object
	var removed: Dictionary = {}
	for oid: String in config.remove_object_ids: removed[oid] = false
	var objects: Array = []
	for object: Dictionary in old_record.objects:
		if removed.has(String(object.id)): removed[String(object.id)] = true
		else: objects.append(object.duplicate(true))
	for oid: String in removed:
		if not removed[oid]: return {}
	objects.append(_relocate(originals.south_gate, "north_court_boundary", BASE._vec(config.gate_render_size_px), Vector2(1536,500)))
	for index: int in 2:
		objects.append(_relocate(originals["west_street_front" if index == 0 else "east_street_front"], "west_street_front" if index == 0 else "east_street_front", BASE._vec(config.frontage_render_size_px), BASE._vec(config.frontage_feet_px[index])))
	for kind: String in ["wall", "tower"]:
		var item: Dictionary = native[kind]
		for x: Variant in config["wall_centers_x" if kind == "wall" else "tower_centers_x"]:
			var foot := Vector2(float(x),500); var origin := foot-BASE._vec(item.foot_anchor_px)
			var polygon: Array = []
			for point: Variant in item.support_polygon_px: polygon.append(_xy(origin+BASE._vec(point)))
			objects.append(_object("gate_%s_%d" % [kind,int(x)], item.texture_path, BASE._vec(item.render_size_px), BASE._vec(item.render_size_px), foot, BASE._vec(item.foot_uv), [polygon]))
	var deck := _object("gate_bridge_deck", BRIDGE, Vector2(1024,1536), Vector2(320,480), Vector2(1536,960), Vector2(.5,1), [], false, false, 0)
	objects.append(deck)
	for index: int in config.bridge_rail_source_rects_px.size():
		var value: Array = config.bridge_rail_source_rects_px[index]
		var region := Rect2i(int(value[0]),int(value[1]),int(value[2]),int(value[3]))
		var origin := Vector2(1376,480)+Vector2(region.position)*.3125
		var render := Vector2(region.size)*.3125
		var side: int = index % 2
		var foot := Vector2(1470 if side == 0 else 1602, origin.y+render.y)
		var rail := _object("gate_bridge_rail_%d" % index, BRIDGE, Vector2(region.size), render, foot, (foot-origin)/render, [_rect(Rect2(1436 if side == 0 else 1576,origin.y,60,120))])
		rail.gate_atlas_region = [float(region.position.x),float(region.position.y),float(region.size.x),float(region.size.y)]
		objects.append(rail)
	for index: int in config.bank_solid_rects_px.size():
		var value: Array = config.bank_solid_rects_px[index]
		var water := _object("gate_moat_blocker_%d" % index, BRIDGE, Vector2.ONE, Vector2.ONE, Vector2(1,1), Vector2.ZERO, [_rect(Rect2(float(value[0]),float(value[1]),float(value[2]),float(value[3])))], false, false)
		water.gate_atlas_region = [0.0,0.0,1.0,1.0]; water.gate_hidden = true
		objects.append(water)
	var record := old_record.duplicate(true)
	record.objects = objects; record.walk_path = ROOT+"walk.png"; record.ground_path = ROOT+"floor.png"
	record.gate_fortification_manifest_sha = MANIFEST_SHA
	return record

static func read_after_original(old_record: Dictionary) -> Dictionary:
	var config := author(); var native := capture(config)
	var manifest := _read(MANIFEST_PATH, MANIFEST_SHA)
	if config.is_empty() or native.is_empty() or manifest.get("status") != "PUBLISHED_CANDIDATE_REQUIRES_REAL_FIELD_QA" or manifest.get("author_sha256") != AUTHOR_SHA or not manifest.get("asset_sha256") is Dictionary: return {"error":"Gate author/native capture/publication PENDING or changed"}
	for path: Variant in manifest.asset_sha256:
		if not _source(path, manifest.asset_sha256[path]): return {"error":"Gate source changed: "+str(path)}
	var record := compose(old_record,config,native)
	if record.is_empty() or not BASE._equal_value(record.objects, manifest.get("objects")) or not BASE._equal_value(old_record.gameplay_slots,manifest.get("gameplay_slots")) or not BASE._equal_value(old_record.routes,manifest.get("routes")): return {"error":"Gate exact geometry/gameplay authoring differs"}
	if not BASE._hash(config.get("expected_walk_sha256")) or manifest.asset_sha256.get(record.walk_path) != config.expected_walk_sha256 or FileAccess.get_sha256(record.walk_path) != config.expected_walk_sha256: return {"error":"A3/B3 walk differs from original exact Gate navigation"}
	var floor: Image = Image.load_from_file(record.ground_path)
	var off: Image = Image.load_from_file(config.shadow_off_raw_path)
	if floor == null or off == null or off.get_size() != Vector2i(6144,4096) or floor.get_size() != Vector2i(BASE.SIZE) or FileAccess.get_sha256(config.shadow_off_raw_path) != config.shadow_off_raw_sha256: return {"error":"Gate exact OFF raw/logical derivation missing"}
	off.resize(3072,2048,Image.INTERPOLATE_LANCZOS); off.convert(Image.FORMAT_RGBA8); floor.convert(Image.FORMAT_RGBA8)
	if off.get_data() != floor.get_data(): return {"error":"Gate logical background is not original OFF Lanczos bytes"}
	for path: String in [record.ground_path,record.walk_path]:
		var image: Image = Image.load_from_file(path)
		var texture: Texture2D = ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var imported: Image = texture.get_image() if texture != null else null
		if image == null or imported == null or (imported.is_compressed() and imported.decompress() != OK): return {"error":"Gate import missing"}
		image.convert(Image.FORMAT_RGBA8); imported.convert(Image.FORMAT_RGBA8)
		if image.get_size() != Vector2i(BASE.SIZE) or imported.get_size() != image.get_size() or imported.get_data().slice(0,3072*2048*4) != image.get_data(): return {"error":"Gate imported full pixels differ"}
	for path: String in manifest.asset_sha256: record.asset_sha256[path] = manifest.asset_sha256[path]
	return {"record":record,"config":config,"native":native}

static func source_paths() -> Dictionary:
	var manifest := _read(MANIFEST_PATH, MANIFEST_SHA)
	if manifest.is_empty() or not manifest.get("asset_sha256") is Dictionary: return {}
	var result: Dictionary = {AUTHOR_PATH:true,MANIFEST_PATH:true,LAYOUT_PATH:true,SCENE_PATH:true}
	for path: String in manifest.asset_sha256: result[path] = true
	result.merge(STABLE_IMPORTS.source_paths(),true)
	return result

static func read_after_original_cpu(old_record: Dictionary,cancel: Callable,progress: Callable,cpu_context: RefCounted=null,token: int=0) -> Dictionary:
	# Same author/capture/source/compose/OFF-Lanczos predicates as synchronous
	# read_after_original; only imported Texture operations remain on main.
	if cancel.call(): return {}
	if cpu_context!=null and not _receipt_owner(cpu_context,token): return {"error":"Gate live module source receipt owner unavailable"}
	progress.call("module.source",0,1)
	var config:=author(); var native:=capture(config,cpu_context,token)
	var manifest:=_read(MANIFEST_PATH,MANIFEST_SHA)
	if config.is_empty() or native.is_empty() or manifest.get("status")!="PUBLISHED_CANDIDATE_REQUIRES_REAL_FIELD_QA" or manifest.get("author_sha256")!=AUTHOR_SHA or not manifest.get("asset_sha256") is Dictionary: return {"error":"Gate author/native capture/publication PENDING or changed"}
	var done:=0
	for path: Variant in manifest.asset_sha256:
		if cancel.call(): return {}
		if not _source(path,manifest.asset_sha256[path],cpu_context,token): return {"error":"Gate source changed: "+str(path)}
		done+=1; progress.call("module.source",done,manifest.asset_sha256.size())
	var record:=compose(old_record,config,native)
	if record.is_empty() or not BASE._equal_value(record.objects,manifest.get("objects")) or not BASE._equal_value(old_record.gameplay_slots,manifest.get("gameplay_slots")) or not BASE._equal_value(old_record.routes,manifest.get("routes")): return {"error":"Gate exact geometry/gameplay authoring differs"}
	if not BASE._hash(config.get("expected_walk_sha256")) or manifest.asset_sha256.get(record.walk_path)!=config.expected_walk_sha256 or FileAccess.get_sha256(record.walk_path)!=config.expected_walk_sha256: return {"error":"A3/B3 walk differs from original exact Gate navigation"}
	if cancel.call(): return {}
	progress.call("module.images",0,3)
	var floor:=Image.load_from_file(record.ground_path)
	var off:=Image.load_from_file(config.shadow_off_raw_path)
	if floor==null or off==null or off.get_size()!=Vector2i(6144,4096) or floor.get_size()!=Vector2i(BASE.SIZE) or FileAccess.get_sha256(config.shadow_off_raw_path)!=config.shadow_off_raw_sha256: return {"error":"Gate exact OFF raw/logical derivation missing"}
	if cancel.call(): return {}
	progress.call("module.Lanczos",1,3)
	off.resize(3072,2048,Image.INTERPOLATE_LANCZOS); off.convert(Image.FORMAT_RGBA8); floor.convert(Image.FORMAT_RGBA8)
	if cancel.call(): return {}
	if off.get_data()!=floor.get_data(): return {"error":"Gate logical background is not original OFF Lanczos bytes"}
	var imports: Array[Dictionary]=[]
	for path: String in [record.ground_path,record.walk_path]:
		if cancel.call(): return {}
		var image:=Image.load_from_file(path)
		if image==null or image.get_size()!=Vector2i(BASE.SIZE): return {"error":"Gate import missing"}
		image.convert(Image.FORMAT_RGBA8)
		imports.append({"path":path,"size":image.get_size(),"bytes":image.get_data()})
	for path: String in manifest.asset_sha256: record.asset_sha256[path]=manifest.asset_sha256[path]
	progress.call("module.images",3,3)
	return {"record":record,"config":config,"native":native,"imports":imports,"walk_bytes":imports[1].bytes}

static func runtime_manifest() -> Dictionary:
	return _read(MANIFEST_PATH, MANIFEST_SHA)

static func apply_scene(scene: SceneScript, record: Dictionary) -> void:
	scene.background_path = record.ground_path
	scene.map_layout.walkable_mask_path = record.walk_path
	scene.set_meta(META, MANIFEST_SHA)

static func apply_entry(entry: Dictionary, authored: Dictionary) -> void:
	if not authored.get("gate_module_object",false): return
	# Source origin remains exact in the separately pinned author manifest.
	# Runtime uses native pos/render/footUV; do not serialize an unused duplicate
	# Float64 spelling of that derived Vector2 as a new annotation protocol.
	entry.erase("world_origin_px")
	entry.sort_by_feet = authored.gate_sort_by_feet; entry.z_index = int(authored.gate_z_index)
	entry.ghost_occlusion = authored.ghost_occlusion
	if authored.has("gate_atlas_region"):
		var region: Array = authored.gate_atlas_region
		entry.gate_atlas_region = Rect2i(int(region[0]),int(region[1]),int(region[2]),int(region[3]))
