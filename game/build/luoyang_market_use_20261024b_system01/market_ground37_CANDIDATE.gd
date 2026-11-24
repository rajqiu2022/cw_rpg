extends RefCounted
## Market-only render suffix. Never writes Scene, C record, NPCs or navigation.
const SELF="res://scripts/city/luoyang_market_ground_20261020ae.gd"
const INDEX="res://scripts/city/luoyang_market_ground_index_20261020ae.gd"
const MANIFEST="res://data/maps/luoyang_market_ground_20261020ae/manifest.json"
const ID=&"ch4_s3_luoyang_market"
const SIZE=Vector2(3072,2048)
const FIRST_CLUSTER=Rect2(1050,1012,960,368)
const BASE_COUNT=36
const C_PATH="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const MARKET_SPACE_READY=false
const MARKET_SPACE_RUNTIME="res://build/luoyang_city_space_20261024b_source01/market_space_runtime_CANDIDATE.gd"
const MARKET_SPACE_RUNTIME_SHA=""

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
static func _pair(value: Variant,positive: bool=false) -> bool:
	if not value is Array or value.size()!=2: return false
	for part: Variant in value:
		if not _number(part) or (positive and float(part)<=0.0): return false
	return true
static func _v(value: Array) -> Vector2: return Vector2(float(value[0]),float(value[1]))
static func _sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256); context.update(bytes)
	return context.finish().hex_encode()
static func _index() -> Variant:
	var value: Variant=load(INDEX)
	return value if value is GDScript and value.resource_path==INDEX else null
static func readiness() -> Dictionary:
	var authority: Variant=_index()
	if authority==null: return {"ok":false,"error":"MARKET_GROUND_INDEX_MISSING"}
	var entry: Dictionary=authority.entry()
	if entry.get("manifest_path")!=MANIFEST or not entry.get("manifest_sha256") is String or entry.manifest_sha256.length()!=64: return {"ok":false,"error":"MARKET_GROUND_ART_IMPORT_PENDING"}
	if FileAccess.get_sha256(MANIFEST)!=entry.manifest_sha256: return {"ok":false,"error":"MARKET_GROUND_MANIFEST_SHA"}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not value is Dictionary or value.get("schema_version")!=1 or value.get("status")!="READY_VISUAL_ONLY_SOURCE_BOUND" or value.get("scene_id")!=String(ID) or value.get("geometry_unchanged")!=true: return {"ok":false,"error":"MARKET_GROUND_MANIFEST_DOMAIN"}
	if not _pair(value.get("design_size_px")) or _v(value.design_size_px)!=SIZE or not value.get("source_sha256") is Dictionary or not value.get("textures") is Dictionary or not value.get("overlays") is Array: return {"ok":false,"error":"MARKET_GROUND_MANIFEST_FIELDS"}
	if value.textures.size()!=1 or value.overlays.is_empty() or value.overlays.size()>8: return {"ok":false,"error":"MARKET_GROUND_FIRST_CLUSTER_SCOPE"}
	for path: Variant in value.source_sha256:
		if not path is String or not path.begins_with("res://") or ".." in path or path in [SELF,INDEX,MANIFEST] or not value.source_sha256[path] is String or value.source_sha256[path].length()!=64: return {"ok":false,"error":"MARKET_GROUND_SOURCE_DOMAIN_OR_CYCLE"}
	var ids: Dictionary={}
	for row: Variant in value.overlays:
		if not row is Dictionary or row.size()!=7 or not row.get("id") is String or not row.id.begins_with("market_ground_ae_") or ids.has(row.id) or not row.get("texture") is String or not value.textures.has(row.texture): return {"ok":false,"error":"MARKET_GROUND_OVERLAY_ID"}
		if not _pair(row.get("center_px")) or not _pair(row.get("render_size_px"),true) or not _pair(row.get("region_origin_px")) or not _pair(row.get("region_size_px"),true) or not _number(row.get("opacity")) or float(row.opacity)<=0.0 or float(row.opacity)>1.0: return {"ok":false,"error":"MARKET_GROUND_OVERLAY_FIELDS"}
		if not FIRST_CLUSTER.encloses(Rect2(_v(row.center_px)-_v(row.render_size_px)*.5,_v(row.render_size_px))): return {"ok":false,"error":"MARKET_GROUND_OUTSIDE_FIRST_CLUSTER"}
		ids[row.id]=true
	return {"ok":true,"spec":value,"manifest_sha256":entry.manifest_sha256}
static func source_paths() -> Dictionary:
	var ready: Dictionary=readiness()
	if ready.get("ok")!=true: return {}
	var paths: Dictionary={SELF:true,MANIFEST:true}
	for path: String in ready.spec.source_sha256: paths[path]=true
	paths[MARKET_SPACE_RUNTIME]=true
	return paths # INDEX is externally pinned by B, not in this manifest.

static func _base_count_matches(scene: SceneScript,base_render: Array) -> bool:
	if scene!=null and scene.scene_id==ID:
		var space: Variant=load(MARKET_SPACE_RUNTIME)
		if space is GDScript and space.resource_path==MARKET_SPACE_RUNTIME and space.requested(scene):
			return MARKET_SPACE_READY and base_render.size()==37 and space.bound(scene) and space.ground_parent_matches(scene,base_render)
	if base_render.size()==BASE_COUNT: return true
	if scene==null or scene.scene_id!=ID or scene.map_layout==null or base_render.size()!=BASE_COUNT-1: return false
	var native: Array=scene.map_layout.visual_objects
	if native.size()!=23: return false
	for row: Dictionary in native:
		if row.get("id")=="v13_market_west_plot_wall": return false
	# Existing B boundary proves exact finite source-FIRST owner/session,
	# whole storage and the fixed one-wall removal; no extra packet decode.
	var b: Variant=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
	return b.finite_market_retired_visual_id(scene,"v13_market_west_plot_wall",native)

static func prepare(scene: SceneScript,sources: Dictionary,base_render: Array,owner: Callable) -> Dictionary:
	if scene==null or scene.scene_id!=ID or not owner.is_valid() or not owner.call() or not _base_count_matches(scene,base_render): return {"ok":false,"error":"MARKET_GROUND_OWNER_OR_PARENT"}
	var space: Variant=load(MARKET_SPACE_RUNTIME)
	if space is GDScript and space.resource_path==MARKET_SPACE_RUNTIME and space.requested(scene) and (not MARKET_SPACE_READY or sources.get(MARKET_SPACE_RUNTIME)!=MARKET_SPACE_RUNTIME_SHA): return {"ok":false,"error":"MARKET_GROUND_SPACE_SOURCE_FIRST"}
	var authority: Variant=_index()
	if authority==null: return {"ok":false,"error":"MARKET_GROUND_INDEX_MISSING"}
	if authority.formal_enabled()!=true: return {"ok":true,"enabled":false,"textures":{},"entries":[],"parent_render":base_render.duplicate(true)}
	var b: Variant=load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
	if not scene.has_meta("luoyang_layout_quest_20261018t") or not b.whole_bound(scene): return {"ok":false,"error":"MARKET_GROUND_BUNDLE_OWNER"}
	var ready: Dictionary=readiness()
	if ready.get("ok")!=true: return ready
	if sources.get(SELF)!=FileAccess.get_sha256(SELF) or sources.get(INDEX)!=FileAccess.get_sha256(INDEX) or sources.get(MANIFEST)!=ready.manifest_sha256: return {"ok":false,"error":"MARKET_GROUND_FIRST_SOURCE_OWNER"}
	for path: String in ready.spec.source_sha256:
		if sources.get(path)!=ready.spec.source_sha256[path]: return {"ok":false,"error":"MARKET_GROUND_SOURCE_NOT_IN_FIRST:"+path}
	var textures: Dictionary={}
	for path: String in ready.spec.textures:
		var row: Dictionary=ready.spec.textures[path]
		if not _pair(row.get("size_px"),true) or row.get("full_rgba_exact")!=true or row.get("params23")!=true or row.get("zero_mipmaps")!=true or row.get("detect3d_compress_to")!=0 or ready.spec.source_sha256.get(path)!=row.get("source_sha256") or ready.spec.source_sha256.get(row.get("import_path",""))!=row.get("import_sha256") or ready.spec.source_sha256.get(row.get("compiled_path",""))!=row.get("compiled_sha256"): return {"ok":false,"error":"MARKET_GROUND_TEXTURE_PROOF"}
		var texture:=ResourceLoader.load(path) as Texture2D
		var image: Image=texture.get_image() if texture!=null else null
		if image==null or Vector2(image.get_size())!=_v(row.size_px) or image.has_mipmaps(): return {"ok":false,"error":"MARKET_GROUND_TEXTURE_SIZE_OR_MIPS"}
		image.convert(Image.FORMAT_RGBA8)
		if _sha(image.get_data())!=row.get("rgba_sha256"): return {"ok":false,"error":"MARKET_GROUND_ACTUAL_RGBA"}
		textures[path]=texture
	var entries: Array=[]
	var old_ids: Dictionary={}
	for item: Dictionary in base_render: old_ids[String(item.get("id",""))]=true
	for row: Dictionary in ready.spec.overlays:
		if old_ids.has(row.id): return {"ok":false,"error":"MARKET_GROUND_DUPLICATE_PARENT_ID"}
		# No atlas/rotation/collision keys are passed through from arbitrary input.
		# Field ordinary Sprite does not consume region_rect, so use the whole PNG.
		if _v(row.region_origin_px)!=Vector2.ZERO or _v(row.region_size_px)!=Vector2(textures[row.texture].get_size()): return {"ok":false,"error":"MARKET_GROUND_WHOLE_PNG_REQUIRED"}
		entries.append({"id":String(row.id),"texture":String(row.texture),"pos":_v(row.center_px)/SIZE,"render_size_px":_v(row.render_size_px),"centered":true,"sort_by_feet":false,"z_index":-998,"blocking":false,"modulate":Color(1,1,1,float(row.opacity))})
	if not owner.call(): return {"ok":false,"error":"MARKET_GROUND_OWNER_CHANGED"}
	return {"ok":true,"enabled":true,"textures":textures,"entries":entries,"parent_render":base_render.duplicate(true),"manifest_sha256":ready.manifest_sha256}

static func render(base_render: Array,session: Dictionary) -> Array:
	var c: Variant=load(C_PATH)
	if session.get("ok")!=true or not c._equal_value(base_render,session.get("parent_render")): return []
	var result: Array=base_render.duplicate(true)
	result.append_array(session.get("entries",[]).duplicate(true))
	return result
