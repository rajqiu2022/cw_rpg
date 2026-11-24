extends RefCounted
## Pure four-prop geometry/native candidate. No Field, source authority or save hook.
const SELF="res://scripts/city/luoyang_docks_workyard_20261019ac.gd"
const AUTHOR="res://data/maps/luoyang_docks_workyard_20261019ac/author.json"
const AUTHOR_SHA="85dff749b846c5f49992f4a1ae137771af4fa78faf0cca98af69c97a870e8194"
const ROOT="res://data/maps/luoyang_docks_workyard_20261019ac/runtime/"
const ID=&"ch4_s2_canal_docks"
const BASIS="DOCKS_WORKYARD_EXACT_ADD_FOUR_LOCAL_GEOMETRY_20261019ac"
const META="luoyang_docks_workyard_20261019ac"
const AA_META="luoyang_docks_district08_20261019aa"
const AA_AUTHOR_SHA="c3ba8c0a6a00738419a5733bbaa1faf34eef6add10fa89de3d6d7ba08a459c47"
const AA_BASIS="DOCKS08_EXACT_REMOVE_TWO_NEW_LOCAL_GEOMETRY_20261019aa"
const FORMAL_ENABLED=false
const EXECUTION_SUCCESSOR="res://scripts/city/luoyang_ac_district_predecessor_20261020ae.gd"
const EXECUTION_SUCCESSOR_SHA="34b8d7d563a8c001f67651f7da4fa14ea8354dfda4c8f202c8a6c6f9c3a987a8"
const AO_SUCCESSOR="res://scripts/city/luoyang_ao_district_predecessor_20261021ao.gd"
const AO_SUCCESSOR_SHA="c7523f853cde1d179a3e708bf6ee53765d6a61c2f4a57c03fb15f3655a614ced"
const AP_AUTHORITY="res://scripts/city/luoyang_execution_authority_20261022ap.gd"
const SIZE=Vector2i(3072,2048)
static func c() -> Variant: return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
static func b() -> Variant: return load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
static func g() -> Variant: return load("res://scripts/city/luoyang_harbour_life_geometry_retry3_20261016.gd")
static func p() -> Variant: return load("res://scripts/city/luoyang_building_spacing_20261017p.gd")
static func wire(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value,"\t",true,true))
static func equal(left: Variant,right: Variant) -> bool: return c()._equal_value(wire(left),wire(right))
const ORDINARY_AA_PATH="res://scripts/city/luoyang_docks_district08_20261019aa.gd"
const ORDINARY_AA_OLD_SHA="13d90a3eff5dd26a9edb310292914e7c0ad1312229fd4ad6e0e2b5761aabf001"
const ORDINARY_AA_NEW_SHA="0fa220574ada95916f7e89cd0bb4a725c07810d4a5b50d35b2069363cb24e612"
const ORDINARY_AA_PROOF="res://build/luoyang_docks_ordinary_space_20261024b_system01/READY05/AA_ordinary_source_wholebyte_proof_READY.json"
const ORDINARY_AA_PROOF_SHA="6df87e86f81f96a695aa0b9b4ce31d185bc0a65b4182fc27825460fe134605f3"
const ORDINARY_AA_CURRENT_SHA="29fdc7764fe69507dd5e14135f0dc8aef5c42dcbe51c02bd3cb61441de1c4662"
const ORDINARY_AA_CURRENT_PROOF="res://build/luoyang_city_revision_20261024c_source01/ordinary_layers02_READY/AA_current_four_hunk_to_0FA_proof_NOTREADY.json"
const ORDINARY_AA_CURRENT_PROOF_SHA="640847dd1316b64b8745718d6a2f3502998e0d806d87025f404c3e0cdb7f7db9"
static func _ordinary_aa_current_parent_bytes() -> PackedByteArray:
	# One exact pre-layer. Existing historical inverse length/rows remain unchanged.
	if FileAccess.get_sha256(ORDINARY_AA_PATH)!=ORDINARY_AA_OUTER_SHA or FileAccess.get_sha256(ORDINARY_AA_CURRENT_PROOF)!=ORDINARY_AA_CURRENT_PROOF_SHA: return PackedByteArray()
	var layer: Variant=JSON.parse_string(FileAccess.get_file_as_string(ORDINARY_AA_CURRENT_PROOF))
	if not layer is Dictionary or layer.get("schema_version")!=1 or layer.get("status")!="EXACT_AA_CURRENT_TO_FIXED_0FA_SOURCE_LAYER" or layer.get("path")!=ORDINARY_AA_PATH or layer.get("old_sha256")!=ORDINARY_AA_NEW_SHA or layer.get("new_sha256")!=ORDINARY_AA_CURRENT_SHA or layer.get("whole_inverse_exact")!=true or not layer.get("replacements") is Array or layer.replacements.size()!=4: return PackedByteArray()
	var current_bytes: PackedByteArray=_ordinary_aa_outer_parent_bytes()
	var parent_text: String=current_bytes.get_string_from_utf8()
	if parent_text.to_utf8_buffer()!=current_bytes or b().bytes_sha(current_bytes)!=ORDINARY_AA_CURRENT_SHA: return PackedByteArray()
	for index: int in range(layer.replacements.size()-1,-1,-1):
		var row: Variant=layer.replacements[index]
		if not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old.is_empty() or row.new.is_empty() or row.old==row.new or parent_text.count(row.new)!=1: return PackedByteArray()
		parent_text=parent_text.replace(row.new,row.old)
	return parent_text.to_utf8_buffer() if b().bytes_sha(parent_text.to_utf8_buffer())==ORDINARY_AA_NEW_SHA else PackedByteArray()
const ORDINARY_AA_OUTER_SHA="48d844c769dc768e6794afe242d8dc3d6048ca88c5449ccd55a161abc3faa871"
const ORDINARY_AA_OUTER_PROOF="res://build/luoyang_city_revision_20261024e_source01/docks31_candidates01/AA_to_fixed24c_proof_READY.json"
const ORDINARY_AA_OUTER_PROOF_SHA="495fde622c48bc66099be98f6add8fb79e7727bbacc0f285ae6fdb24487b8596"
static func _ordinary_aa_outer_parent_bytes() -> PackedByteArray:
	# Exact outer layer only; all pre-existing inner proof gates remain unchanged.
	if FileAccess.get_sha256(ORDINARY_AA_PATH)!=ORDINARY_AA_OUTER_SHA or FileAccess.get_sha256(ORDINARY_AA_OUTER_PROOF)!=ORDINARY_AA_OUTER_PROOF_SHA: return PackedByteArray()
	var layer: Variant=JSON.parse_string(FileAccess.get_file_as_string(ORDINARY_AA_OUTER_PROOF))
	if not layer is Dictionary or layer.get("schema_version")!=1 or layer.get("status")!="EXACT_24E_AA_TO_FIXED24C_ORDINARY_LAYER" or layer.get("path")!=ORDINARY_AA_PATH or layer.get("old_sha256")!=ORDINARY_AA_CURRENT_SHA or layer.get("new_sha256")!=ORDINARY_AA_OUTER_SHA or layer.get("whole_inverse_exact")!=true or not layer.get("replacements") is Array or layer.replacements.size()!=3: return PackedByteArray()
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(ORDINARY_AA_PATH)
	var text: String=bytes.get_string_from_utf8()
	if text.to_utf8_buffer()!=bytes or b().bytes_sha(bytes)!=ORDINARY_AA_OUTER_SHA: return PackedByteArray()
	for index: int in range(layer.replacements.size()-1,-1,-1):
		var row: Variant=layer.replacements[index]
		if not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old.is_empty() or row.new.is_empty() or row.old==row.new or text.count(row.new)!=1: return PackedByteArray()
		text=text.replace(row.new,row.old)
	return text.to_utf8_buffer() if b().bytes_sha(text.to_utf8_buffer())==ORDINARY_AA_CURRENT_SHA else PackedByteArray()
static func _ordinary_source_successor(path: String,expected: String) -> bool:
	# Only these two fixed ordinary edges; existing owned DT resolution stays below.
	if not ((path=="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd" and expected=="c68272dd8bb2fd989a7776a1ee970a0d082290927d1fd30734c72d59b1d0fe50") or (path==ORDINARY_AA_PATH and expected==ORDINARY_AA_OLD_SHA)): return false
	if FileAccess.get_sha256(ORDINARY_AA_PATH)!=ORDINARY_AA_OUTER_SHA or FileAccess.get_sha256(ORDINARY_AA_PROOF)!=ORDINARY_AA_PROOF_SHA: return false
	var proof: Variant=JSON.parse_string(FileAccess.get_file_as_string(ORDINARY_AA_PROOF))
	if not proof is Dictionary or proof.get("schema_version")!=1 or proof.get("status")!="EXACT_AA_ORDINARY_C_SOURCE_GATE_SUCCESSOR_NO_AUTHOR_GEOMETRY_CHANGE" or proof.get("path")!=ORDINARY_AA_PATH or proof.get("old_sha256")!=ORDINARY_AA_OLD_SHA or proof.get("new_sha256")!=ORDINARY_AA_NEW_SHA or proof.get("whole_inverse_exact")!=true or not proof.get("replacements") is Array or proof.replacements.size()!=3: return false
	var bytes: PackedByteArray=_ordinary_aa_current_parent_bytes()
	var inverse: String=bytes.get_string_from_utf8()
	if inverse.to_utf8_buffer()!=bytes or b().bytes_sha(bytes)!=ORDINARY_AA_NEW_SHA: return false
	for index: int in range(proof.replacements.size()-1,-1,-1):
		var row: Variant=proof.replacements[index]
		if not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old.is_empty() or row.new.is_empty() or row.old==row.new or inverse.count(row.new)!=1: return false
		inverse=inverse.replace(row.new,row.old)
	if b().bytes_sha(inverse.to_utf8_buffer())!=ORDINARY_AA_OLD_SHA: return false
	var aa: Variant=load(ORDINARY_AA_PATH)
	if not aa is GDScript or aa.resource_path!=ORDINARY_AA_PATH: return false
	return aa.ordinary_c_source_admitted(aa.ORDINARY_C_PATH,aa.ORDINARY_C_OLD_SHA) if path==ORDINARY_AA_PATH else aa.ordinary_c_source_admitted(path,expected)
static func author() -> Dictionary:
	if FileAccess.get_sha256(AUTHOR)!=AUTHOR_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not value is Dictionary or value.get("status")!="SOURCE_BOUND_AC_ADD_FOUR_NOT_RUNTIME" or value.get("scene_id")!=String(ID) or value.get("parent_count")!=25 or value.get("child_count")!=29 or value.get("props",[]).size()!=4: return {}
	for path: String in value.get("source_sha256",{}):
		if not path.begins_with("res://") or ".." in path: return {}
		if FileAccess.get_sha256(path)!=value.source_sha256[path]:
			if _ordinary_source_successor(path,String(value.source_sha256[path])): continue
			if FileAccess.file_exists(AP_AUTHORITY):
				var approved: Variant=load(AP_AUTHORITY)
				if approved is GDScript and approved.resource_path==AP_AUTHORITY and path in approved.OWNED and approved.approved(path,String(value.source_sha256[path])): continue
			var ao_admitted: bool=false
			if FileAccess.get_sha256(AO_SUCCESSOR)==AO_SUCCESSOR_SHA:
				var ao: Variant=load(AO_SUCCESSOR)
				ao_admitted=ao is GDScript and ao.admitted(path,String(value.source_sha256[path]))
			if ao_admitted: continue
			if FileAccess.get_sha256(EXECUTION_SUCCESSOR)!=EXECUTION_SUCCESSOR_SHA: return {}
			var successor: Variant=load(EXECUTION_SUCCESSOR)
			if not successor is GDScript or not successor.admitted(path,String(value.source_sha256[path])): return {}
	var seen: Dictionary={}
	for row: Dictionary in value.props:
		var key: String=String(row.get("id",""))
		if not key.begins_with("workyard_ac_") or seen.has(key) or row.get("role")!="workyard_low_prop" or not c()._object_solids_valid(row): return {}
		seen[key]=true
	return value
static func source_paths() -> Dictionary:
	var result: Dictionary={SELF:true,AUTHOR:true,ORDINARY_AA_PROOF:true,ORDINARY_AA_CURRENT_PROOF:true,ORDINARY_AA_OUTER_PROOF:true}
	if FileAccess.get_sha256(ORDINARY_AA_PATH)!=ORDINARY_AA_OUTER_SHA: return {}
	var aa: Variant=load(ORDINARY_AA_PATH)
	if not aa is GDScript or aa.resource_path!=ORDINARY_AA_PATH: return {}
	result.merge(aa.source_paths())
	var value: Dictionary=author()
	if value.is_empty(): return {}
	for path: String in value.source_sha256: result[path]=true
	if FileAccess.get_sha256(EXECUTION_SUCCESSOR)!=EXECUTION_SUCCESSOR_SHA: return {}
	result.merge(load(EXECUTION_SUCCESSOR).source_paths())
	if FileAccess.get_sha256(AO_SUCCESSOR)!=AO_SUCCESSOR_SHA: return {}
	result.merge(load(AO_SUCCESSOR).source_paths())
	if FileAccess.file_exists(AP_AUTHORITY):
		var paths: Dictionary=load(AP_AUTHORITY).source_paths()
		if paths.is_empty(): return {}
		result.merge(paths)
	return result
static func compose(parent: Dictionary,walk: String) -> Dictionary:
	var spec: Dictionary=author()
	if spec.is_empty() or parent.get("canonical_scene_id")!=String(ID) or parent.get("objects",[]).size()!=25 or parent.get("aa_author_sha256")!=AA_AUTHOR_SHA or walk!=ROOT+String(ID)+"/walk.png": return {}
	var next: Dictionary=parent.duplicate(true);var seen: Dictionary={}
	for row: Dictionary in parent.objects: seen[String(row.id)]=true
	for prop: Dictionary in spec.props:
		if seen.has(String(prop.id)): return {}
		seen[String(prop.id)]=true;next.objects.append(prop.duplicate(true))
	next.walk_path=walk;next["ac_geometry_basis"]=BASIS;next["ac_author_sha256"]=AUTHOR_SHA
	var inverse: Dictionary=next.duplicate(true)
	inverse.objects=inverse.objects.slice(0,25);inverse.walk_path=parent.walk_path
	inverse.erase("ac_geometry_basis");inverse.erase("ac_author_sha256")
	return next if next.objects.size()==29 and equal(inverse,parent) else {}
static func render_entry(prop: Dictionary) -> Dictionary:
	var result: Dictionary=prop.duplicate(true)
	var foot: Vector2=c()._vec(prop.world_foot_px);var size: Vector2=c()._vec(prop.render_size_px)
	result.pos=(foot+(Vector2(.5,.5)-c()._vec(prop.foot_uv))*size)/Vector2(SIZE)
	result.render_size_px=size;result.centered=true;result.sort_by_feet=true
	result.depth_sort_foot_y=foot.y/SIZE.y
	result.city_v3_solid_polygons_px=prop.solid_polygons_px.duplicate(true);result.erase("solid_polygons_px")
	return result
static func materialize(parent: SceneScript,record: Dictionary,walk: String) -> SceneScript:
	var spec: Dictionary=author()
	if spec.is_empty() or parent==null or parent.scene_id!=ID or parent.map_layout==null or parent.get_meta(AA_META,"")!=AA_AUTHOR_SHA or parent.has_meta(META) or parent.map_layout.visual_objects.size()!=25 or record.get("objects",[]).size()!=29 or record.get("ac_author_sha256")!=AUTHOR_SHA or record.get("walk_path")!=walk: return null
	var next:=parent.duplicate(true) as SceneScript
	next.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	var rows: Array[Dictionary]=[]
	for row: Dictionary in parent.map_layout.visual_objects: rows.append(row.duplicate(true))
	for index: int in 4:
		if not equal(record.objects[25+index],spec.props[index]): return null
		rows.append(render_entry(spec.props[index]))
	next.map_layout.visual_objects=rows;next.map_layout.walkable_mask_path=walk
	# Keep AA identity for existing H/District bound dispatch, add an exact child.
	next.set_meta(META,AUTHOR_SHA)
	var inverse:=next.duplicate(true) as SceneScript
	inverse.map_layout=next.map_layout.duplicate(true) as WalkableMapLayout
	inverse.map_layout.visual_objects=parent.map_layout.visual_objects.duplicate(true)
	inverse.map_layout.walkable_mask_path=parent.map_layout.walkable_mask_path;inverse.remove_meta(META)
	return next if b().equal(b().storage(inverse),b().storage(parent)) and b().equal(b().storage(inverse.map_layout),b().storage(parent.map_layout)) else null
static func textures(spec: Dictionary) -> Dictionary:
	var rows: Array=[]
	for proof: Dictionary in spec.texture_proofs:
		var path: String=String(proof.texture);var config:=ConfigFile.new()
		if FileAccess.get_sha256(proof.import_path)!=proof.import_sha256 or FileAccess.get_sha256(proof.compiled_path)!=proof.compiled_sha256 or config.load(proof.import_path)!=OK or config.get_section_keys("params").size()!=23: return {"passed":false,"error":"AC_TEXTURE_SOURCE_OR_PARAMS"}
		for key: String in spec.params23:
			var actual: Variant=config.get_value("params",key,null);var expected: Variant=spec.params23[key]
			var same_kind: bool=(actual is bool and expected is bool) or (actual is String and expected is String) or ((actual is int or actual is float) and (expected is int or expected is float))
			if not same_kind or actual!=expected: return {"passed":false,"error":"AC_TEXTURE_PARAM:"+key}
		if config.get_value("remap","path","")!=proof.compiled_path or config.has_section_key("remap","path.s3tc") or config.get_value("deps","source_file","")!=path or config.get_value("remap","metadata",{}).get("vram_texture",true)!=false: return {"passed":false,"error":"AC_TEXTURE_REMAP"}
		var raw: Image=Image.load_from_file(path)
		var texture:=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var direct:=CompressedTexture2D.new()
		if raw==null or texture==null or direct.load(proof.compiled_path)!=OK: return {"passed":false,"error":"AC_TEXTURE_LOAD"}
		var imported: Image=texture.get_image();var native: Image=direct.get_image()
		if imported==null or native==null: return {"passed":false,"error":"AC_TEXTURE_IMAGE"}
		for image: Image in [raw,imported,native]:
			if image.is_compressed() and image.decompress()!=OK: return {"passed":false,"error":"AC_TEXTURE_DECODE"}
			if image.get_mipmap_count()!=0: return {"passed":false,"error":"AC_TEXTURE_MIPMAP"}
			image.convert(Image.FORMAT_RGBA8)
		if raw.get_size()!=imported.get_size() or raw.get_size()!=native.get_size() or raw.get_data()!=imported.get_data() or raw.get_data()!=native.get_data(): return {"passed":false,"error":"AC_TEXTURE_FULL_RGBA"}
		rows.append({"texture":path,"rgba_sha256":b().bytes_sha(raw.get_data()),"size_px":[raw.get_width(),raw.get_height()],"full_rgba_exact":true,"params23":true,"zero_mipmaps":true,"import_path":proof.import_path,"import_sha256":proof.import_sha256,"compiled_path":proof.compiled_path,"compiled_sha256":proof.compiled_sha256})
	return {"passed":rows.size()==3,"unique_textures":rows.size(),"instances":4,"rows":rows}
static func add_only_mask(old_mask: Image,new_mask: Image,props: Array) -> Dictionary:
	if old_mask==null or new_mask==null or old_mask.get_size()!=SIZE or new_mask.get_size()!=SIZE: return {"passed":false,"error":"AC_MASK_SIZE"}
	var old_bytes: PackedByteArray=old_mask.get_data();var new_bytes: PackedByteArray=new_mask.get_data()
	var polygons: Array[PackedVector2Array]=c().object_solids(props);var counts: Array[int]=[0,0,0,0];var changed: int=0
	for offset: int in range(0,old_bytes.size(),4):
		if old_bytes[offset]==new_bytes[offset] and old_bytes[offset+1]==new_bytes[offset+1] and old_bytes[offset+2]==new_bytes[offset+2] and old_bytes[offset+3]==new_bytes[offset+3]: continue
		if old_bytes[offset]!=255 or old_bytes[offset+1]!=255 or old_bytes[offset+2]!=255 or old_bytes[offset+3]!=255 or new_bytes[offset]!=0 or new_bytes[offset+1]!=0 or new_bytes[offset+2]!=0 or new_bytes[offset+3]!=255: return {"passed":false,"error":"AC_NOT_EXACT_WHITE_TO_BLACK"}
		var pixel: int=offset/4;var point:=Vector2(pixel%SIZE.x,pixel/SIZE.x);var found: int=-1
		for index: int in polygons.size():
			if Geometry2D.is_point_in_polygon(point,polygons[index]):
				if found!=-1: return {"passed":false,"error":"AC_NEW_SOLIDS_OVERLAP"}
				found=index
		if found<0: return {"passed":false,"error":"AC_CHANGED_INTEGER_PIXEL_OUTSIDE_NEW_SOLIDS","pixel":[point.x,point.y]}
		counts[found]+=1;changed+=1
	for count: int in counts:
		if count<=0: return {"passed":false,"error":"AC_PROP_HAS_NO_NEW_PHYSICAL_RASTER"}
	return {"passed":changed>0,"blocked_pixels":changed,"per_prop_blocked_pixels":counts,"old_blocked_never_restored":true,"integer_point_polygon_membership_exact":true,"unchanged_pixels_all_RGBA_exact":true}
static func geometry(record: Dictionary,mask: Image,parent: Dictionary,old_mask: Image) -> Dictionary:
	var spec: Dictionary=author()
	if spec.is_empty(): return {"passed":false,"error":"AC_AUTHOR_UNAVAILABLE"}
	var mono: Dictionary=add_only_mask(old_mask,mask,spec.props)
	if mono.get("passed")!=true: return mono
	var solids: Array[PackedVector2Array]=c().object_solids(record.objects)
	if not c()._all_gameplay_safe_cpu(record,mask,solids,Callable()): return {"passed":false,"error":"AC_ORIGINAL_FULL_GAMEPLAY"}
	var routes: Dictionary=g().audit(record,mask)
	if routes.get("passed")!=true: return {"passed":false,"error":"AC_ORIGINAL_ROUTES_AND_SIX_LANES","audit":routes}
	var combined: Dictionary=p().combined_geometry(record,mask)
	if combined.get("passed")!=true: return {"passed":false,"error":"AC_DISTRICT_COMBINED","audit":combined}
	var new_solids: Array[PackedVector2Array]=c().object_solids(spec.props)
	var prior_solids: Array[PackedVector2Array]=c().object_solids(parent.objects)
	for index: int in new_solids.size():
		for old: PackedVector2Array in prior_solids:
			if not Geometry2D.intersect_polygons(new_solids[index],old).is_empty(): return {"passed":false,"error":"AC_PROP_INTERSECTS_ORIGINAL_SOLID","index":index}
		for domain: Dictionary in spec.protected.moving_domains:
			var center: Vector2=c()._vec(domain.center_px);var extent:=Vector2(float(domain.radius_px)+17,float(domain.radius_px)+15)
			var box:=PackedVector2Array([center-extent,center+Vector2(extent.x,-extent.y),center+extent,center+Vector2(-extent.x,extent.y)])
			if not Geometry2D.intersect_polygons(new_solids[index],box).is_empty(): return {"passed":false,"error":"AC_PROP_INTERSECTS_PROTECTED_MOVING_DOMAIN","index":index}
	var count: int=0
	for route: Dictionary in spec.local_probe_routes:
		for segment: int in range(route.points_px.size()-1):
			var from: Vector2=c()._vec(route.points_px[segment]);var to: Vector2=c()._vec(route.points_px[segment+1]);var steps: int=maxi(1,ceili(from.distance_to(to)/4.0))
			for step: int in range(steps+1):
				var foot:=from.lerp(to,float(step)/steps)
				if not c()._safe_body_cpu(foot,mask,solids) or not g().seventeen(foot,mask): return {"passed":false,"error":"AC_FOUR_PROP_APPROACH","route":route.id,"foot_px":[foot.x,foot.y]}
				count+=1
	for raw: Variant in [[754,610]]+spec.protected.npc_feet_px.values()+spec.protected.portals_px.values()+spec.protected.task_points_px.values():
		var foot: Vector2=c()._vec(raw)
		if not c()._safe_body_cpu(foot,mask,solids) or not g().seventeen(foot,mask): return {"passed":false,"error":"AC_PROTECTED_DOOR_NPC_PORTAL_TASK","foot_px":raw}
	return {"passed":true,"full87517":true,"mask_delta":mono,"original_routes":routes,"combined":combined,"local_approach_samples":count,"four_new_solids":4,"original_25_and_gameplay_unchanged":true,"npc_continuous_body_px":[34,30],"moving_domains_no_new_overlap":true,"max_step_px":4}
