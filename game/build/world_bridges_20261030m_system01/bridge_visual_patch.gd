extends RefCounted
## Desktop World15 presentation only. Original input objects/solids are never edited.
const BINDING_PATH := "res://art/modules/world_bridges_20261030m/bridge_bindings.json"
const ROOT := "res://build/world_bridges_20261030m_system01/"
const NEW_ART := "res://art/modules/world_bridges_20261030m/"
const LAYOUT := "res://data/maps/world_map_jianghu_layout_v15.tres"
const LAYOUT_SHA := "aeae58273fed2bbfd8145347bab75fbbd934ac2c4efd0f622edb7fa7b1c9f072"
const SOURCE_ROWS_SHA := "dd1e58a5955803d6c351eb87833731174483688c135de6a4fc14309fe39bcfed"
const INVENTORY_SHA := "961ca32b6f9b29e328bb58572f5669f5bcabb7889749f5d98c9fc7429ca2f055"
const WORLD_SIZE := Vector2(12288,8192)
const IDS := ["bridge_00","bridge_01","bridge_02","bridge_03","bridge_04"]
const CLIP_META := &"world_bridge_partition_20261030m"
const SHADER = preload("res://build/world_bridges_20261030m_system01/bridge_partition.gdshader")

static func _sha(path: String, expected: String) -> bool:
	return expected.length()==64 and FileAccess.file_exists(path) and FileAccess.get_sha256(path)==expected

static func _json(path: String) -> Dictionary:
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>2097152:return {}
	var raw: Variant=JSON.parse_string(file.get_as_text())
	return raw if raw is Dictionary else {}

static func _vec(raw: Variant) -> Vector2:
	return Vector2(float(raw[0]),float(raw[1])) if raw is Array and raw.size()==2 else Vector2(INF,INF)

static func _poly(raw: Variant) -> PackedVector2Array:
	var result:=PackedVector2Array()
	if not raw is Array:return result
	for point: Variant in raw:
		var p:=_vec(point)
		if not p.is_finite():return PackedVector2Array()
		result.append(p)
	return result

static func _error(reason: String) -> Dictionary:
	return {"ok":false,"error":"WORLD_BRIDGE30M:"+reason}

static func _matches_original(data: Dictionary, expected: Dictionary) -> bool:
	for key: String in ["id","role","texture"]:
		if String(data.get(key,""))!=String(expected.get(key,"")):return false
	for key: String in ["pos","render_size_px"]:
		if data.get(key)!=_vec(expected.get(key)):return false
	for key: String in ["sort_by_feet","centered"]:
		if bool(data.get(key,key=="centered"))!=bool(expected.get(key,key=="centered")):return false
	for key: String in ["rotation","z_index","depth_sort_foot_y"]:
		if float(data.get(key,0))!=float(expected.get(key,0)):return false
	for key: String in ["collision_size","collision_offset","walkability_margin_px"]:
		if data.has(key)!=expected.has(key):return false
		if data.has(key) and data[key]!=_vec(expected[key]):return false
	if data.has("solid_polygons_px")!=expected.has("solid_polygons_px"):return false
	if data.has("solid_polygons_px"):
		var polys: Array=data.solid_polygons_px
		if polys.size()!=expected.solid_polygons_px.size():return false
		for i: int in range(polys.size()):
			if polys[i]!=_poly(expected.solid_polygons_px[i]):return false
	return true

static func _import_valid(row: Dictionary, expected_path: String) -> bool:
	if row.get("path")!=expected_path or row.get("full_RGBA_exact")!=true or int(row.get("mipmap_count",-1))!=0:return false
	if not _sha(expected_path,String(row.get("sha256",""))) or not _sha(expected_path+".import",String(row.get("import_sha256",""))):return false
	var config:=ConfigFile.new()
	if config.load(expected_path+".import")!=OK:return false
	for pair: Array in [["compress/mode",0],["mipmaps/generate",false],["process/fix_alpha_border",false],["process/premult_alpha",false],["process/size_limit",0],["detect_3d/compress_to",0]]:
		if config.get_value("params",pair[0],null)!=pair[1]:return false
	var compiled: String=String(row.get("compiled_path",""))
	if not compiled.begins_with("res://.godot/imported/") or compiled.get_file()!=expected_path.get_file()+"-"+expected_path.md5_text()+".ctex":return false
	return config.get_value("remap","path","")==compiled and config.get_value("deps","source_file","")==expected_path and _sha(compiled,String(row.get("compiled_sha256","")))

static func _deck_valid(mapped: PackedVector2Array, old: Dictionary) -> bool:
	# Root may extend a new native deck onto the EXISTING approach/passages, but
	# cannot hide a poor width/alignment fit by changing NAV or existing rail bodies.
	var old_a:=_vec(old.deck_surface_bank_centers_world_px[0])
	var old_b:=_vec(old.deck_surface_bank_centers_world_px[1])
	var axis: Vector2=(old_b-old_a).normalized()
	var normal:=Vector2(-axis.y,axis.x)
	var a: Vector2=(mapped[0]+mapped[3])*.5
	var b: Vector2=(mapped[1]+mapped[2])*.5
	if (b-a).normalized().dot(axis)<cos(deg_to_rad(3.0)):return false
	if absf(((a+b-old_a-old_b)*.5).dot(normal))>8.0:return false
	var width: float=(mapped[0].distance_to(mapped[3])+mapped[1].distance_to(mapped[2]))*.5
	if absf(width-float(old.deck_surface_width_px))>12.0:return false
	var first: float=(a-old_a).dot(axis);var last: float=(b-old_a).dot(axis)
	if first>8.0 or last<(old_b-old_a).length()-8.0:return false
	var passage_a: float=(_vec(old.outer_passage_endpoints_world_px[0])-old_a).dot(axis)
	var passage_b: float=(_vec(old.outer_passage_endpoints_world_px[1])-old_a).dot(axis)
	return first>=minf(passage_a,passage_b)-16.0 and last<=maxf(passage_a,passage_b)+16.0

static func prepare(objects: Array, sealed_sha: String) -> Dictionary:
	# No unapproved/partial new presentation and no guessed foreground polygons.
	if sealed_sha.length()!=64:return _error("PENDING_ROOT_NATIVE_ANCHORS_AND_APPROVAL")
	if not _sha(BINDING_PATH,sealed_sha) or not _sha(LAYOUT,LAYOUT_SHA):return _error("BINDING_OR_ORIGINAL_LAYOUT_SHA")
	if not _sha(ROOT+"bridge_source_rows_LAYOUT_TYPED_03_READY.json",SOURCE_ROWS_SHA) or not _sha(ROOT+"bridge_inventory_READY.json",INVENTORY_SHA):return _error("ORIGINAL_BRIDGE_EVIDENCE_SHA")
	var binding:=_json(BINDING_PATH)
	if int(binding.get("schema_version",0))!=1 or binding.get("approved")!=true or binding.get("approved_by")!="root":return _error("NOT_APPROVED")
	if not _sha(ROOT+"bridge_visual_patch.gd",String(binding.get("helper_sha256",""))) or not _sha(ROOT+"bridge_partition.gdshader",String(binding.get("shader_sha256",""))):return _error("HELPER_OR_GPU_SHADER_SHA")
	if not _sha("res://scripts/world/world_v15_stream_overlap_20261018r.gd",String(binding.get("overlap_sha256",""))):return _error("MATCHING_WORLD_ONLY_OVERLAP_REQUIRED")
	var source:=_json(ROOT+"bridge_source_rows_LAYOUT_TYPED_03_READY.json")
	var inventory:=_json(ROOT+"bridge_inventory_READY.json")
	var originals: Dictionary={};var ordinals: Dictionary={};var counts: Dictionary={}
	for row: Dictionary in source.get("rows",[]):originals[String(row.id)]=row
	if originals.size()!=93:return _error("ORIGINAL93_ROWS")
	for ordinal: int in range(objects.size()):
		var row: Dictionary=objects[ordinal]
		var id: String=String(row.get("id",""))
		if not id.begins_with("bridge_"):continue
		if not originals.has(id) or counts.has(id) or not _matches_original(row,originals[id]):return _error("INPUT_BRIDGE_ROW:"+id)
		counts[id]=true;ordinals[id]=ordinal
	if counts.size()!=93:return _error("INPUT93_ROWS")
	var entries: Variant=binding.get("bridges",[])
	if not entries is Array or entries.size()!=5:return _error("EXACT5_NATIVE_BRIDGES")
	var presentations: Dictionary={};var textures: Dictionary={}
	for index: int in range(5):
		var entry: Dictionary=entries[index]
		var id: String=String(entry.get("id",""))
		if id!=IDS[index]:return _error("BRIDGE_ORDER")
		var old: Dictionary=inventory.bridges[index]
		var art: String=NEW_ART+id+".png"
		if not _import_valid(entry.get("resource",{}),art) or not ResourceLoader.exists(art):return _error("NATIVE_IMPORT:"+id)
		# Import bytes/size are Root-sealed; do not synchronously load all five
		# textures ahead of the existing owner-scoped asynchronous streamer.
		var native_size:=_vec(entry.resource.get("size"))
		if not native_size.is_finite() or native_size.x<=0 or native_size.y<=0:return _error("NATIVE_SIZE:"+id)
		var scale_factor: float=float(entry.get("scale",0))
		var origin:=_vec(entry.get("origin_world_px"))
		var rotation: float=float(entry.get("rotation_degrees",0))
		if not is_finite(scale_factor) or scale_factor<=0 or scale_factor>1 or not origin.is_finite() or not is_finite(rotation) or absf(rotation)>15:return _error("UNIFORM_NATIVE_TRANSFORM:"+id)
		var anchors:=_poly(entry.get("source_deck_quad_px",[]))
		if anchors.size()!=4:return _error("ACTUAL_NEW_DECK_ANCHORS:"+id)
		var mapped:=PackedVector2Array()
		for corner: int in range(4):
			if anchors[corner].x<0 or anchors[corner].y<0 or anchors[corner].x>native_size.x or anchors[corner].y>native_size.y:return _error("SOURCE_DECK_OUTSIDE_PNG:"+id)
			mapped.append(origin+(anchors[corner]*scale_factor).rotated(deg_to_rad(rotation)))
		if not _deck_valid(mapped,old):return _error("ACTUAL_DECK_WIDTH_PASSAGE_OR_ALIGNMENT:"+id)
		var allowed: Array=old.nearside_post_ids.duplicate();allowed.append(old.nearrail_id)
		var foreground: Variant=entry.get("foreground_parts",[])
		if not foreground is Array or foreground.is_empty() or foreground.size()>allowed.size():return _error("ACTUAL_NEW_FOREGROUND_REQUIRED:"+id)
		var parts: Array[Dictionary]=[];var seen: Dictionary={}
		for raw: Dictionary in foreground:
			var source_id: String=String(raw.get("source_component_id",""))
			if source_id not in allowed or seen.has(source_id):return _error("FOREGROUND_OWNER:"+source_id)
			seen[source_id]=true
			var polys: Array[PackedVector2Array]=[]
			for points: Variant in raw.get("source_polygons_px",[]):
				var polygon:=_poly(points)
				if polygon.size()<3 or Geometry2D.triangulate_polygon(polygon).is_empty():return _error("GPU_POLYGON:"+source_id)
				for p: Vector2 in polygon:
					if p.x<0 or p.y<0 or p.x>native_size.x or p.y>native_size.y:return _error("GPU_POLYGON_OUTSIDE_SOURCE:"+source_id)
				polys.append(polygon)
			if polys.is_empty():return _error("EMPTY_NEW_FOREGROUND:"+source_id)
			parts.append({"id":source_id,"polygons":polys,"depth":float(originals[source_id].depth_sort_foot_y),"ordinal":int(ordinals[source_id])})
		if not seen.has(String(old.nearrail_id)):return _error("NEAR_RAIL_SOURCE_OWNER_REQUIRED:"+id)
		parts.sort_custom(func(a: Dictionary,b: Dictionary)->bool:return float(a.depth)<float(b.depth) if float(a.depth)!=float(b.depth) else int(a.ordinal)<int(b.ordinal))
		var all_polys: Array[PackedVector2Array]=[];var owners: Array[int]=[]
		for part_index: int in range(parts.size()):
			for polygon: PackedVector2Array in parts[part_index].polygons:all_polys.append(polygon);owners.append(part_index)
		var point_count: int=0
		for polygon: PackedVector2Array in all_polys:point_count+=polygon.size()
		if all_polys.size()>32 or point_count>128:return _error("GPU_POLYGON_BUDGET:"+id)
		var profile: Dictionary={"id":id,"texture":art,"size":native_size,"origin":origin,"scale":scale_factor,"rotation":rotation,"polygons":all_polys,"owners":owners,"mapped_deck_quad_world_px":mapped}
		textures[art]=true
		for original_id: String in old.visual_ids:presentations[original_id]={}
		presentations[String(old.deck_object_id)]=_presentation(originals[old.deck_object_id],profile,-1,Rect2(Vector2.ZERO,native_size))
		for part_index: int in range(parts.size()):
			var points:=PackedVector2Array()
			for polygon: PackedVector2Array in parts[part_index].polygons:points.append_array(polygon)
			var box:=Rect2(points[0],Vector2.ZERO)
			for p: Vector2 in points:box=box.expand(p)
			var first:=box.position.floor().max(Vector2.ZERO)
			var end:=box.end.ceil().min(native_size)
			presentations[String(parts[part_index].id)]=_presentation(originals[parts[part_index].id],profile,part_index,Rect2(first,end-first))
	return {"ok":true,"presentations":presentations,"shared_textures":textures,"source_bridge_count":5,"source_visual_count":93,"source_physics_unchanged":true}

static func _presentation(original: Dictionary, profile: Dictionary, part_index: int, region: Rect2) -> Dictionary:
	# Fresh dictionary only: all caller physical rows remain untouched.
	var row: Dictionary={}
	row.id=String(original.id);row.texture=profile.texture;row.centered=true
	# Keep a full-source transform at registration time. Region drawing uses only
	# Sprite.offset afterward, so native depth foot_local never changes its frame.
	row.pos=(profile.origin+(profile.size*.5*float(profile.scale)).rotated(deg_to_rad(float(profile.rotation))))/WORLD_SIZE
	row.render_size_px=profile.size*float(profile.scale);row.rotation=float(profile.rotation)
	row.sort_by_feet=part_index>=0;row.z_index=int(original.get("z_index",0))
	if part_index>=0:row.depth_sort_foot_y=float(original.depth_sort_foot_y)
	row["_bridge_native30m"]=true
	row["_bridge_clip30m"]={"profile":profile,"part_index":part_index,"region":region}
	return row

static func project(original: Dictionary, patch: Dictionary) -> Dictionary:
	var id: String=String(original.get("id",""))
	return patch.presentations[id] if patch.presentations.has(id) else original

static func attach(sprite: Sprite2D, data: Dictionary) -> bool:
	if not data.get("_bridge_native30m",false):return true
	var clip: Dictionary=data.get("_bridge_clip30m",{})
	var profile: Dictionary=clip.get("profile",{})
	if profile.is_empty() or sprite.texture==null or sprite.texture.get_size()!=profile.size:return false
	var points:=PackedVector2Array();points.resize(128)
	var counts:=PackedInt32Array();counts.resize(32)
	var owners:=PackedInt32Array();owners.resize(32);owners.fill(-1)
	var offset: int=0
	for i: int in range(profile.polygons.size()):
		var polygon: PackedVector2Array=profile.polygons[i]
		counts[i]=polygon.size();owners[i]=int(profile.owners[i])
		for p: Vector2 in polygon:points[offset]=p;offset+=1
	var material:=ShaderMaterial.new();material.shader=SHADER
	material.set_shader_parameter("source_size",profile.size)
	material.set_shader_parameter("clip_points",points);material.set_shader_parameter("clip_counts",counts);material.set_shader_parameter("clip_owners",owners)
	material.set_shader_parameter("polygon_count",profile.polygons.size());material.set_shader_parameter("part_index",int(clip.part_index))
	sprite.material=material
	sprite.region_enabled=true;sprite.region_rect=clip.region
	var region: Rect2=clip.region
	sprite.offset=region.position+region.size*.5-profile.size*.5
	sprite.set_meta(CLIP_META,clip)
	return true

static func source_pixel_visible(sprite: Sprite2D, world_point: Vector2) -> bool:
	if not sprite.has_meta(CLIP_META):return true
	var clip: Dictionary=sprite.get_meta(CLIP_META)
	var profile: Dictionary=clip.profile
	var rect:=sprite.get_rect()
	if not rect.has_area():return false
	var uv: Vector2=(sprite.to_local(world_point)-rect.position)/rect.size
	if uv.x<0 or uv.y<0 or uv.x>=1 or uv.y>=1:return false
	var region: Rect2=clip.region
	var p: Vector2=region.position+uv*region.size
	var owner: int=-1
	for i: int in range(profile.polygons.size()):
		if Geometry2D.is_point_in_polygon(p,profile.polygons[i]):owner=maxi(owner,int(profile.owners[i]))
	return owner==int(clip.part_index)
