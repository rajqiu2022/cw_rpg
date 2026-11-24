extends RefCounted
## Visual-only child of the original same-capture water Sprite. No Scene writes.
const SELF="res://scripts/city/luoyang_docks_shore_20261020ae.gd"
const INDEX="res://scripts/city/luoyang_docks_shore_index_20261020ae.gd"
const MANIFEST="res://data/maps/luoyang_docks_shore_20261020ae/manifest.json"
const ID=&"ch4_s2_canal_docks"
const SIZE=Vector2(3072,2048)
const AC_META="luoyang_docks_workyard_20261019ac"
const AC_AUTHOR="85dff749b846c5f49992f4a1ae137771af4fa78faf0cca98af69c97a870e8194"
const C_PATH="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"

static func _index() -> Variant:
	var value: Variant=load(INDEX)
	return value if value is GDScript and value.resource_path==INDEX else null

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

static func readiness() -> Dictionary:
	var authority: Variant=_index()
	if authority==null: return {"ok":false,"error":"AE_INDEX_MISSING"}
	var entry: Dictionary=authority.entry()
	if entry.get("manifest_path")!=MANIFEST or not entry.get("manifest_sha256") is String or entry.manifest_sha256.length()!=64: return {"ok":false,"error":"AE_ART_IMPORT_PENDING"}
	if FileAccess.get_sha256(MANIFEST)!=entry.manifest_sha256: return {"ok":false,"error":"AE_MANIFEST_SHA"}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	if not value is Dictionary or value.get("schema_version")!=1 or value.get("status")!="READY_VISUAL_ONLY_SOURCE_BOUND" or value.get("scene_id")!=String(ID) or value.get("geometry_unchanged")!=true: return {"ok":false,"error":"AE_MANIFEST_DOMAIN"}
	if not _pair(value.get("design_size_px")) or _v(value.design_size_px)!=SIZE or not value.get("source_sha256") is Dictionary or not value.get("textures") is Dictionary or not value.get("overlays") is Array: return {"ok":false,"error":"AE_MANIFEST_FIELDS"}
	if value.textures.is_empty() or value.textures.size()>4 or value.overlays.is_empty() or value.overlays.size()>16: return {"ok":false,"error":"AE_BOUNDED_VISUAL_SCOPE"}
	for path: Variant in value.source_sha256:
		if not path is String or not path.begins_with("res://") or ".." in path or path in [SELF,INDEX,MANIFEST] or not value.source_sha256[path] is String or value.source_sha256[path].length()!=64: return {"ok":false,"error":"AE_SOURCE_DOMAIN_OR_CYCLE"}
	var ids: Dictionary={}
	for row: Variant in value.overlays:
		if not row is Dictionary or row.size()!=7 or not row.get("id") is String or not row.id.begins_with("shore_ae_") or ids.has(row.id) or not row.get("texture") is String or not value.textures.has(row.texture): return {"ok":false,"error":"AE_OVERLAY_ID_OR_TEXTURE"}
		if not _pair(row.get("center_px")) or not _pair(row.get("render_size_px"),true) or not _pair(row.get("region_origin_px")) or not _pair(row.get("region_size_px"),true) or not _number(row.get("opacity")) or float(row.opacity)<=0.0 or float(row.opacity)>1.0: return {"ok":false,"error":"AE_OVERLAY_FIELDS"}
		if not Rect2(Vector2.ZERO,SIZE).has_point(_v(row.center_px)): return {"ok":false,"error":"AE_OVERLAY_OUTSIDE_MAP"}
		ids[row.id]=true
	return {"ok":true,"spec":value,"manifest_sha256":entry.manifest_sha256}

static func source_paths() -> Dictionary:
	var ready: Dictionary=readiness()
	if ready.get("ok")!=true: return {}
	var paths: Dictionary={SELF:true,MANIFEST:true}
	for path: String in ready.spec.source_sha256: paths[path]=true
	# INDEX is an external authority leaf collected/pinned by B, never by manifest.
	return paths

static func _proof(scene: SceneScript) -> Dictionary:
	var c: Variant=load(C_PATH)
	for proof: Dictionary in [c._transition_validation,c._resident_ready]:
		if proof.get("scene")==scene and proof.get("record")==c._records.get(String(ID)) and proof.get("id")==ID and int(proof.get("token",0))>0: return proof
	return {}

static func install(water: Sprite2D,scene: SceneScript,world_size: Vector2) -> Dictionary:
	if scene==null or scene.scene_id!=ID or world_size!=SIZE or not is_instance_valid(water): return {"ok":false,"error":"AE_PARENT_DOMAIN"}
	var authority: Variant=_index()
	if authority==null: return {"ok":false,"error":"AE_INDEX_MISSING"}
	if authority.formal_enabled()!=true: return {"ok":true,"enabled":false}
	if scene.get_meta(AC_META,"")!=AC_AUTHOR or water.position!=Vector2(2500,1292) or water.scale!=Vector2.ONE or water.centered or water.z_index!=-999 or water.texture==null or water.get_node_or_null("DocksShoreVisualOnlyAE")!=null: return {"ok":false,"error":"AE_CURRENT_AC_OR_WATER_PARENT"}
	var ready: Dictionary=readiness()
	if ready.get("ok")!=true: return ready
	var proof: Dictionary=_proof(scene)
	if proof.is_empty() or proof.get("sources",{}).get(SELF)!=FileAccess.get_sha256(SELF) or proof.sources.get(INDEX)!=FileAccess.get_sha256(INDEX) or proof.sources.get(MANIFEST)!=ready.manifest_sha256: return {"ok":false,"error":"AE_FIRST_SOURCE_OWNER"}
	for path: String in ready.spec.source_sha256:
		if proof.sources.get(path)!=ready.spec.source_sha256[path]: return {"ok":false,"error":"AE_SOURCE_NOT_IN_FIRST:"+path}
	var textures: Dictionary={}
	for path: String in ready.spec.textures:
		var row: Dictionary=ready.spec.textures[path]
		if not _pair(row.get("size_px"),true) or row.get("full_rgba_exact")!=true or row.get("params23")!=true or row.get("zero_mipmaps")!=true or row.get("detect3d_compress_to")!=0 or ready.spec.source_sha256.get(path)!=row.get("source_sha256") or ready.spec.source_sha256.get(row.get("import_path",""))!=row.get("import_sha256") or ready.spec.source_sha256.get(row.get("compiled_path",""))!=row.get("compiled_sha256"): return {"ok":false,"error":"AE_TEXTURE_PROOF"}
		var texture:=ResourceLoader.load(path) as Texture2D
		var image: Image=texture.get_image() if texture!=null else null
		if image==null or Vector2(image.get_size())!=_v(row.size_px) or image.has_mipmaps(): return {"ok":false,"error":"AE_TEXTURE_SIZE_OR_MIPS"}
		image.convert(Image.FORMAT_RGBA8)
		if _sha(image.get_data())!=row.get("rgba_sha256"): return {"ok":false,"error":"AE_ACTUAL_RGBA"}
		textures[path]=texture
	# Validate everything before adding a child. No partial layer on any failure.
	for row: Dictionary in ready.spec.overlays:
		var size: Vector2=textures[row.texture].get_size()
		var region:=Rect2(_v(row.region_origin_px),_v(row.region_size_px))
		if not Rect2(Vector2.ZERO,size).encloses(region): return {"ok":false,"error":"AE_ATLAS_REGION"}
	var root:=Node2D.new()
	root.name="DocksShoreVisualOnlyAE"; root.position=-water.position; root.z_index=1
	root.set_meta("ae_visual_only",true); root.set_meta("ae_manifest_sha256",ready.manifest_sha256)
	for row: Dictionary in ready.spec.overlays:
		var sprite:=Sprite2D.new()
		sprite.name=String(row.id); sprite.texture=textures[row.texture]
		# The existing dry wharf is z=-2. Only this exact presentation class may
		# cover its already-existing post; no authored/free z value is accepted.
		sprite.z_index=997 if String(row.id).begins_with("shore_ae_mooring_") else 0
		sprite.region_enabled=true; sprite.region_rect=Rect2(_v(row.region_origin_px),_v(row.region_size_px))
		sprite.position=_v(row.center_px); sprite.scale=_v(row.render_size_px)/_v(row.region_size_px)
		# A fixed source-bound wet class, never arbitrary per-row RGB data.
		sprite.self_modulate=Color(0.38,0.48,0.52,float(row.opacity)) if String(row.id).begins_with("shore_ae_wet_") else Color(1,1,1,float(row.opacity))
		sprite.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
		root.add_child(sprite)
	water.add_child(root)
	return {"ok":true,"enabled":true,"root":root,"count":ready.spec.overlays.size(),"effective_z_index":-998,"mooring_effective_z_index":-1,"physics_added":0,"walk_support":false,"ghost_registration":false}
