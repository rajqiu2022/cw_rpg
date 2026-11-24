extends RefCounted
## Market-only third layer, after the unchanged full original enclosure proof.
const BASE = preload("res://scripts/city/luoyang_layered_v3_wall_v5_note_candidate_contract.gd")
const ID := &"ch4_s3_luoyang_market"
const FLAG := "--luoyang-market-enrichment-candidate"
const META := "city_market_enrichment_manifest_sha"
const ROOT := "res://art/maps/luoyang_market_enrichment_v2/"
const AUTHOR_PATH := ROOT + "market_author_config.json"
const AUTHOR_SHA := "f6d7f42539d80a14bad63540713f78a827cd1c3b8c26b98ae01ef5f24311a18d"
const MANIFEST_PATH := ROOT + "runtime_manifest.json"
const MANIFEST_SHA := "d617289ee22a40223f86e9f2003bdc149e8b2714aef1f83d93d4faf605ee67cd"
const LAYOUT_PATH := "res://data/maps/luoyang_market_enrichment_v2_candidates/ch4_s3_luoyang_market_layout.tres"
const SCENE_PATH := "res://data/scenes/luoyang_market_enrichment_v2_candidates/ch4_s3_luoyang_market.tres"
const STREET := "res://art/maps/luoyang_modular_v3/source/street_row_v3.png"
const SEMANTICS := "res://art/maps/luoyang_modular_v3/source/module_semantics.json"
const STALL := "res://art/maps/luoyang_modular_v3/source/goods_stall_v2.png"
const TREE := "res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s3_luoyang_market/entities/native_tree.png"
const TEXTURE_ALIASES := {STREET:ROOT+"textures/street_row.png",STALL:ROOT+"textures/goods_stall.png",TREE:ROOT+"textures/native_tree.png"}
const NEW_BUILDINGS := ["market_west_ward_frontage","market_east_ward_frontage","market_northwest_rear_frontage","market_northeast_rear_frontage"]
const ADD_IDS := ["market_west_ward_frontage","market_east_ward_frontage","market_northwest_rear_frontage","market_northeast_rear_frontage","market_west_alley_stall","market_east_alley_stall","market_west_court_tree_a","market_west_court_tree_b","market_east_court_tree_a","market_east_court_tree_b"]

static func requested(id: StringName, scene: SceneScript = null) -> bool:
	return id == ID and (FLAG in OS.get_cmdline_user_args() or (scene != null and scene.scene_id == ID and scene.has_meta(META)))

static func bound(scene: SceneScript) -> bool:
	return scene != null and scene.scene_id == ID and scene.map_layout != null and BASE._hash(MANIFEST_SHA) and scene.get_meta(META, "") == MANIFEST_SHA and scene.map_layout.walkable_mask_path == ROOT+"walk.png"

static func _source(path: Variant, sha: Variant) -> bool:
	return typeof(path) == TYPE_STRING and path.begins_with("res://") and not ".." in path and BASE._hash(sha) and FileAccess.get_sha256(path) == sha

static func _read(path: String, sha: String) -> Dictionary:
	if not _source(path, sha): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}

static func author() -> Dictionary:
	var config := _read(AUTHOR_PATH,AUTHOR_SHA)
	if config.get("version") != 1.0 or config.get("scene_id") != String(ID) or BASE._vec(config.get("design_size_px")) != BASE.SIZE or not config.get("placements") is Array or config.placements.size() != ADD_IDS.size() or not config.get("source_sha256") is Dictionary: return {}
	if not BASE._equal_value(config.get("texture_aliases"),TEXTURE_ALIASES): return {}
	for source: String in TEXTURE_ALIASES:
		if config.source_sha256.get(source) != config.source_sha256.get(TEXTURE_ALIASES[source]) or not BASE._hash(config.source_sha256.get(source)): return {}
	for path: Variant in config.source_sha256:
		if not _source(path,config.source_sha256[path]): return {}
	for index: int in ADD_IDS.size():
		var item: Variant = config.placements[index]
		if not item is Dictionary or item.get("id") != ADD_IDS[index] or not item.get("kind") in ["street_row","stall","tree"] or not BASE._in_domain(BASE._vec(item.get("foot_px"))) or not item.get("scale") is float or not is_finite(item.scale) or item.scale <= 0.0 or item.scale > 1.0: return {}
	return config

static func _xy(value: Vector2) -> Array: return [float(value.x),float(value.y)]

static func compose(original: Dictionary, config: Dictionary) -> Dictionary:
	if original.get("canonical_scene_id") != String(ID) or original.get("enclosure_patch_sha256") != config.get("original_enclosure_manifest_sha") or original.get("objects",[]).size() != 16: return {}
	var semantics := _read(SEMANTICS,String(config.source_sha256.get(SEMANTICS,"")))
	var row: Variant = semantics.get("modules",{}).get("street_row_v3.png")
	if not row is Dictionary or row.get("source_sha256") != config.source_sha256.get(STREET) or BASE._vec(row.get("source_size_px")) != Vector2(1536,1024): return {}
	var originals: Dictionary = {}
	for object: Dictionary in original.objects: originals[String(object.id)] = object
	if not originals.has("goods_stall") or not originals.has("street_tree_0"): return {}
	var result := original.duplicate(true)
	for item: Dictionary in config.placements:
		if originals.has(item.id): return {}
		var foot := BASE._vec(item.foot_px)
		var texture: String; var source_size: Vector2; var render: Vector2; var uv: Vector2; var solids: Array = []
		var physical := foot; var collision := Vector2.ZERO
		if item.kind == "street_row":
			texture = STREET; source_size = BASE._vec(row.source_size_px); render = source_size * float(item.scale); uv = BASE._vec(row.foot_uv)
			for polygon: Array in row.solid_polygons_uv:
				var projected: Array = []
				for point: Variant in polygon: projected.append(_xy(foot+(BASE._vec(point)-uv)*render))
				solids.append(projected)
		else:
			var template: Dictionary = originals.goods_stall if item.kind == "stall" else originals.street_tree_0
			texture = STALL if item.kind == "stall" else String(template.texture)
			source_size = BASE._vec(template.source_size_px); uv = BASE._vec(template.foot_uv)
			render = source_size * float(item.scale)
			var ratio := render / BASE._vec(template.render_size_px)
			physical = foot+(BASE._vec(template.physical_center_px)-BASE._vec(template.world_foot_px))*ratio
			collision = BASE._vec(template.collision_size_px)*ratio
			for polygon: Array in template.solid_polygons_px:
				var projected: Array = []
				for point: Variant in polygon: projected.append(_xy(foot+(BASE._vec(point)-BASE._vec(template.world_foot_px))*ratio))
				solids.append(projected)
		var origin := foot-uv*render
		if not render.is_finite() or not origin.is_finite() or origin.x < 0 or origin.y < 0 or origin.x+render.x > BASE.SIZE.x or origin.y+render.y > BASE.SIZE.y or not config.source_sha256.has(texture) or not BASE._png_size(texture,Vector2i(source_size)): return {}
		var source := texture
		texture = String(config.texture_aliases.get(source,""))
		if texture != TEXTURE_ALIASES.get(source) or config.source_sha256.get(texture) != config.source_sha256[source]: return {}
		var object := {"id":item.id,"texture":texture,"source":source,"source_sha256":config.source_sha256[source],"source_size_px":_xy(source_size),"render_size_px":_xy(render),"world_foot_px":_xy(foot),"physical_center_px":_xy(physical),"collision_size_px":_xy(collision),"foot_uv":_xy(uv),"depth_foot_y":float(foot.y),"solid_polygons_px":solids,"blocking":true,"ghost_occlusion":true,"market_enrichment_object":true}
		result.objects.append(object)
	result.walk_path = ROOT+"walk.png"; result.market_enrichment_manifest_sha = MANIFEST_SHA
	return result

static func _imported_same(path: String, expected_size: Vector2i) -> bool:
	var raw := Image.load_from_file(path)
	var texture := ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var decoded := texture.get_image() if texture != null else null
	if raw == null or decoded == null or raw.get_size() != expected_size or (decoded.is_compressed() and decoded.decompress() != OK): return false
	raw.convert(Image.FORMAT_RGBA8); decoded.convert(Image.FORMAT_RGBA8)
	return decoded.get_size() == raw.get_size() and decoded.get_data().slice(0,expected_size.x*expected_size.y*4) == raw.get_data()

static func read_after_original(original: Dictionary) -> Dictionary:
	var config := author(); var manifest := _read(MANIFEST_PATH,MANIFEST_SHA)
	if config.is_empty() or manifest.get("status") != "PUBLISHED_CANDIDATE_REQUIRES_REAL_FIELD_QA" or manifest.get("author_sha256") != AUTHOR_SHA or not manifest.get("asset_sha256") is Dictionary: return {"error":"Market author/publication pending or changed"}
	for path: Variant in manifest.asset_sha256:
		if not _source(path,manifest.asset_sha256[path]): return {"error":"Market source changed: "+str(path)}
	var record := compose(original,config)
	if record.is_empty() or not BASE._equal_value(record.objects,manifest.get("objects")) or not BASE._equal_value(original.gameplay_slots,manifest.get("gameplay_slots")) or not BASE._equal_value(original.routes,manifest.get("routes")) or original.ground_path != manifest.get("ground_path"): return {"error":"Market independent geometry/gameplay/floor differs"}
	var seen: Dictionary = {}
	for object: Dictionary in record.objects:
		if not object.get("market_enrichment_object",false) or seen.has(object.texture): continue
		seen[object.texture] = true
		if not _imported_same(object.texture,Vector2i(BASE._vec(object.source_size_px))): return {"error":"Market imported source pixels differ"}
	if not _imported_same(record.walk_path,Vector2i(BASE.SIZE)): return {"error":"Market imported navigation pixels differ"}
	for path: String in manifest.asset_sha256: record.asset_sha256[path] = manifest.asset_sha256[path]
	return {"record":record}

static func source_paths() -> Dictionary:
	var manifest := _read(MANIFEST_PATH,MANIFEST_SHA)
	if manifest.is_empty() or not manifest.get("asset_sha256") is Dictionary: return {}
	var result: Dictionary = {AUTHOR_PATH:true,MANIFEST_PATH:true,LAYOUT_PATH:true,SCENE_PATH:true}
	for path: String in manifest.asset_sha256: result[path] = true
	return result

static func runtime_manifest() -> Dictionary: return _read(MANIFEST_PATH,MANIFEST_SHA)

static func read_after_original_cpu(original: Dictionary,cancel: Callable,progress: Callable) -> Dictionary:
	if cancel.call(): return {}
	progress.call("module.source",0,1)
	var config:=author(); var manifest:=_read(MANIFEST_PATH,MANIFEST_SHA)
	if config.is_empty() or manifest.get("status")!="PUBLISHED_CANDIDATE_REQUIRES_REAL_FIELD_QA" or manifest.get("author_sha256")!=AUTHOR_SHA or not manifest.get("asset_sha256") is Dictionary: return {"error":"Market author/publication pending or changed"}
	var done:=0
	for path: Variant in manifest.asset_sha256:
		if cancel.call(): return {}
		if not _source(path,manifest.asset_sha256[path]): return {"error":"Market source changed: "+str(path)}
		done+=1; progress.call("module.source",done,manifest.asset_sha256.size())
	var record:=compose(original,config)
	if record.is_empty() or not BASE._equal_value(record.objects,manifest.get("objects")) or not BASE._equal_value(original.gameplay_slots,manifest.get("gameplay_slots")) or not BASE._equal_value(original.routes,manifest.get("routes")) or original.ground_path!=manifest.get("ground_path"): return {"error":"Market independent geometry/gameplay/floor differs"}
	var seen: Dictionary={}; var imports: Array[Dictionary]=[]
	for object: Dictionary in record.objects:
		if not object.get("market_enrichment_object",false) or seen.has(object.texture): continue
		seen[object.texture]=Vector2i(BASE._vec(object.source_size_px))
	seen[record.walk_path]=Vector2i(BASE.SIZE)
	done=0
	for path: String in seen:
		if cancel.call(): return {}
		var raw:=Image.load_from_file(path)
		if raw==null or raw.get_size()!=seen[path]: return {"error":"Market imported source pixels differ"}
		raw.convert(Image.FORMAT_RGBA8)
		imports.append({"path":path,"size":raw.get_size(),"bytes":raw.get_data()})
		done+=1; progress.call("module.images",done,seen.size())
	for path: String in manifest.asset_sha256: record.asset_sha256[path]=manifest.asset_sha256[path]
	return {"record":record,"imports":imports,"walk_bytes":imports.back().bytes}
static func apply_scene(scene: SceneScript, record: Dictionary) -> void:
	scene.map_layout.walkable_mask_path = record.walk_path
	scene.set_meta(META,MANIFEST_SHA)
