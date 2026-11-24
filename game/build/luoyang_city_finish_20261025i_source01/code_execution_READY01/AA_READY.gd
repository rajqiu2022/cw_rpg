extends RefCounted
## Single Docks remove-two successor. No geometry/old-source proof mutation.
const SELF="res://scripts/city/luoyang_docks_district08_20261019aa.gd"
const INDEX="res://scripts/city/luoyang_docks_district08_index_20261019aa.gd"
const AUTHOR="res://data/maps/luoyang_docks_district08_20261019aa/author.json"
const AUTHOR_SHA="c3ba8c0a6a00738419a5733bbaa1faf34eef6add10fa89de3d6d7ba08a459c47"
const ID=&"ch4_s2_canal_docks"
const BASIS="DOCKS08_EXACT_REMOVE_TWO_NEW_LOCAL_GEOMETRY_20261019aa"
const META="luoyang_docks_district08_20261019aa"
const ROOT="res://data/maps/luoyang_docks_district08_20261019aa/runtime/"
const FLAG="--luoyang-docks-district08-20261019aa"
const SIZE=Vector2i(3072,2048)
const REMOVED=["harbour_small_cargo_store","south_canal_front"]
const OLD_META="luoyang_building_spacing_author_20261017p"
static func c() -> Variant: return load("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
static func b() -> Variant: return load("res://scripts/city/luoyang_precomputed_bundle_20261018r.gd")
static func p() -> Variant: return load("res://scripts/city/luoyang_building_spacing_20261017p.gd")
static func g() -> Variant: return load("res://scripts/city/luoyang_harbour_life_geometry_retry3_20261016.gd")
static func wire(value: Variant) -> Variant: return JSON.parse_string(JSON.stringify(value,"\t",true,true))
static func equal(left: Variant,right: Variant) -> bool: return c()._equal_value(wire(left),wire(right))
static func fail(message: String) -> Dictionary: return {"ok":false,"error":message}
static func enabled() -> bool:
	if FLAG in OS.get_cmdline_user_args(): return true
	var index: Variant=load(INDEX)
	return index is GDScript and index.resource_path==INDEX and index.formal_enabled()==true
static func requested(id: StringName) -> bool: return id==ID and enabled()
const ORDINARY_C_PATH="res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd"
const ORDINARY_C_OLD_SHA="c68272dd8bb2fd989a7776a1ee970a0d082290927d1fd30734c72d59b1d0fe50"
const ORDINARY_C_NEW_SHA="b9b68f2e1daddc7dd8f19c683bd932048fda3b547e475001c854d23bfd7965b5"
const ORDINARY_C_PROOF="res://build/luoyang_docks_ordinary_space_20261024b_system01/READY05/C_ordinary_source_wholebyte_proof_READY.json"
const ORDINARY_C_PROOF_SHA="213fdb1fec3078970c24b14c004ac47cad5347664a1fd15d271f8a54eda05029"
const ORDINARY_C_CURRENT_SHA="f389b2e12e839d9005c3ac7643b69921ea31d9b7cc66d9194be0ab18c0d8b5d1"
const ORDINARY_C_CURRENT_PROOF="res://build/luoyang_city_revision_20261024c_source01/ordinary_layers02_READY/C_current_three_hunk_to_B9B_proof_NOTREADY.json"
const ORDINARY_C_CURRENT_PROOF_SHA="c7706cdb669b77d45d860cebc29a312bb37328639fe5a86c689988e2e4c25e32"
static func _ordinary_c_current_parent_bytes() -> PackedByteArray:
	# One exact pre-layer. Existing historical inverse length/rows remain unchanged.
	if FileAccess.get_sha256(ORDINARY_C_PATH)!=FINISH_C_SHA or FileAccess.get_sha256(ORDINARY_C_CURRENT_PROOF)!=ORDINARY_C_CURRENT_PROOF_SHA: return PackedByteArray()
	var layer: Variant=JSON.parse_string(FileAccess.get_file_as_string(ORDINARY_C_CURRENT_PROOF))
	if not layer is Dictionary or layer.get("schema_version")!=1 or layer.get("status")!="EXACT_C_CURRENT_TO_FIXED_B9B_SOURCE_LAYER" or layer.get("path")!=ORDINARY_C_PATH or layer.get("old_sha256")!=ORDINARY_C_NEW_SHA or layer.get("new_sha256")!=ORDINARY_C_CURRENT_SHA or layer.get("whole_inverse_exact")!=true or not layer.get("replacements") is Array or layer.replacements.size()!=3: return PackedByteArray()
	var current_bytes: PackedByteArray=_ordinary_c_outer_parent_bytes()
	var parent_text: String=current_bytes.get_string_from_utf8()
	if parent_text.to_utf8_buffer()!=current_bytes or b().bytes_sha(current_bytes)!=ORDINARY_C_CURRENT_SHA: return PackedByteArray()
	for index: int in range(layer.replacements.size()-1,-1,-1):
		var row: Variant=layer.replacements[index]
		if not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old.is_empty() or row.new.is_empty() or row.old==row.new or parent_text.count(row.new)!=1: return PackedByteArray()
		parent_text=parent_text.replace(row.new,row.old)
	return parent_text.to_utf8_buffer() if b().bytes_sha(parent_text.to_utf8_buffer())==ORDINARY_C_NEW_SHA else PackedByteArray()
const FINISH_C_SHA="a205593b9849f54d6e2edf60bffca5a6b5ea246778a9825f6d9ee4829dea8b46"
const FINISH_C_PROOF="res://build/luoyang_city_finish_20261025i_source01/code_execution_READY01/C_to_fixed25h_ordinary_proof_READY.json"
const FINISH_C_PROOF_SHA="8902f5af215b004049eac44eff5ee1297bee3051e0cd968598868e2cd0ba740d"
static func _finish_c_parent_bytes() -> PackedByteArray:
	if FileAccess.get_sha256(ORDINARY_C_PATH)!=FINISH_C_SHA or FileAccess.get_sha256(FINISH_C_PROOF)!=FINISH_C_PROOF_SHA: return PackedByteArray()
	var layer: Variant=JSON.parse_string(FileAccess.get_file_as_string(FINISH_C_PROOF))
	if not layer is Dictionary or layer.get("schema_version")!=1 or layer.get("status")!="EXACT_25I_C_TO_FIXED25H_ORDINARY_LAYER" or layer.get("path")!=ORDINARY_C_PATH or layer.get("old_sha256")!=ORDINARY_C_OUTER_SHA or layer.get("new_sha256")!=FINISH_C_SHA or layer.get("whole_inverse_exact")!=true or not layer.get("replacements") is Array or layer.replacements.size()!=8: return PackedByteArray()
	var bytes: PackedByteArray=FileAccess.get_file_as_bytes(ORDINARY_C_PATH)
	var text: String=bytes.get_string_from_utf8()
	if text.to_utf8_buffer()!=bytes or b().bytes_sha(bytes)!=FINISH_C_SHA: return PackedByteArray()
	for index: int in range(layer.replacements.size()-1,-1,-1):
		var row: Variant=layer.replacements[index]
		if not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old.is_empty() or row.new.is_empty() or row.old==row.new or text.count(row.new)!=1: return PackedByteArray()
		text=text.replace(row.new,row.old)
	return text.to_utf8_buffer() if b().bytes_sha(text.to_utf8_buffer())==ORDINARY_C_OUTER_SHA else PackedByteArray()
const ORDINARY_C_OUTER_SHA="5ba3e9f62979337c68db86b7533dd50d81c02221d7d568d3b419b970cd20d00f"
const ORDINARY_C_OUTER_PROOF="res://build/luoyang_city_revision_20261025g_source01/courtyard32_candidates01/C_to_fixed24c_proof_READY.json"
const ORDINARY_C_OUTER_PROOF_SHA="c7611a46df138e4fc057d1bb1159076a46875ccc701f13c8ffd75d1ed53bb4b0"
static func _ordinary_c_outer_parent_bytes() -> PackedByteArray:
	# Exact outer layer only; all pre-existing inner proof gates remain unchanged.
	if FileAccess.get_sha256(ORDINARY_C_PATH)!=FINISH_C_SHA or FileAccess.get_sha256(ORDINARY_C_OUTER_PROOF)!=ORDINARY_C_OUTER_PROOF_SHA: return PackedByteArray()
	var layer: Variant=JSON.parse_string(FileAccess.get_file_as_string(ORDINARY_C_OUTER_PROOF))
	if not layer is Dictionary or layer.get("schema_version")!=1 or layer.get("status")!="EXACT_24E_C_TO_FIXED24C_ORDINARY_LAYER" or layer.get("path")!=ORDINARY_C_PATH or layer.get("old_sha256")!=ORDINARY_C_CURRENT_SHA or layer.get("new_sha256")!=ORDINARY_C_OUTER_SHA or layer.get("whole_inverse_exact")!=true or not layer.get("replacements") is Array or layer.replacements.size()!=8: return PackedByteArray()
	var bytes: PackedByteArray=_finish_c_parent_bytes()
	var text: String=bytes.get_string_from_utf8()
	if text.to_utf8_buffer()!=bytes or b().bytes_sha(bytes)!=ORDINARY_C_OUTER_SHA: return PackedByteArray()
	for index: int in range(layer.replacements.size()-1,-1,-1):
		var row: Variant=layer.replacements[index]
		if not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old.is_empty() or row.new.is_empty() or row.old==row.new or text.count(row.new)!=1: return PackedByteArray()
		text=text.replace(row.new,row.old)
	return text.to_utf8_buffer() if b().bytes_sha(text.to_utf8_buffer())==ORDINARY_C_CURRENT_SHA else PackedByteArray()
static func ordinary_c_source_admitted(path: String,expected: String) -> bool:
	# Exact ordinary source edge, never an execution-owned approval.
	if path!=ORDINARY_C_PATH or expected!=ORDINARY_C_OLD_SHA or FileAccess.get_sha256(ORDINARY_C_PATH)!=FINISH_C_SHA or FileAccess.get_sha256(ORDINARY_C_PROOF)!=ORDINARY_C_PROOF_SHA: return false
	var proof: Variant=JSON.parse_string(FileAccess.get_file_as_string(ORDINARY_C_PROOF))
	if not proof is Dictionary or proof.get("schema_version")!=1 or proof.get("status")!="EXACT_DOCKS_ORDINARY_C_SOURCE_SUCCESSOR_NOT_EXECUTION_OWNER" or proof.get("path")!=ORDINARY_C_PATH or proof.get("old_sha256")!=ORDINARY_C_OLD_SHA or proof.get("new_sha256")!=ORDINARY_C_NEW_SHA or proof.get("whole_inverse_exact")!=true or not proof.get("replacements") is Array or proof.replacements.size()!=2: return false
	var bytes: PackedByteArray=_ordinary_c_current_parent_bytes()
	var inverse: String=bytes.get_string_from_utf8()
	if inverse.to_utf8_buffer()!=bytes or b().bytes_sha(bytes)!=ORDINARY_C_NEW_SHA: return false
	for index: int in range(proof.replacements.size()-1,-1,-1):
		var row: Variant=proof.replacements[index]
		if not row is Dictionary or row.size()!=2 or not row.get("old") is String or not row.get("new") is String or row.old.is_empty() or row.new.is_empty() or row.old==row.new or inverse.count(row.new)!=1: return false
		inverse=inverse.replace(row.new,row.old)
	return b().bytes_sha(inverse.to_utf8_buffer())==ORDINARY_C_OLD_SHA
static func author() -> Dictionary:
	if AUTHOR_SHA.length()!=64 or FileAccess.get_sha256(AUTHOR)!=AUTHOR_SHA: return {}
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(AUTHOR))
	if not value is Dictionary or value.get("status")!="SOURCE_BOUND_DOCKS08_REMOVE_TWO" or value.get("scene_id")!=String(ID) or value.get("remove_ids")!=REMOVED or value.get("expected_parent_count")!=27 or value.get("expected_child_count")!=25: return {}
	for path: String in value.get("source_sha256",{}):
		if not path.begins_with("res://") or ".." in path or String(value.source_sha256[path]).length()!=64: return {}
		if FileAccess.get_sha256(path)!=value.source_sha256[path] and not ordinary_c_source_admitted(path,String(value.source_sha256[path])): return {}
	return value
static func entry() -> Dictionary:
	if not requested(ID): return {}
	var index: Variant=load(INDEX)
	var value: Dictionary=index.entry()
	return value if value.size()==2 and value.get("manifest_path")==ROOT+String(ID)+"/manifest.json" and b()._hash(value.get("manifest_sha256")) else {}
static func source_paths() -> Dictionary:
	var paths: Dictionary={SELF:true,INDEX:true,AUTHOR:true,ORDINARY_C_PROOF:true,ORDINARY_C_CURRENT_PROOF:true,ORDINARY_C_OUTER_PROOF:true,FINISH_C_PROOF:true}
	var value: Dictionary=author()
	if value.is_empty(): return paths
	for path: String in value.source_sha256: paths[path]=true
	return paths
static func find(rows: Array,id: String) -> Dictionary:
	var found: Dictionary={}
	for row: Dictionary in rows:
		if String(row.get("id",""))!=id: continue
		if not found.is_empty(): return {}
		found=row
	return found
static func compose(parent: Dictionary,walk: String) -> Dictionary:
	var spec: Dictionary=author()
	if spec.is_empty() or parent.get("canonical_scene_id")!=String(ID) or parent.get("objects",[]).size()!=27 or walk.is_empty(): return {}
	var next: Dictionary=parent.duplicate(true)
	var removed: Dictionary={}; var objects: Array=[]
	for old: Dictionary in parent.objects:
		var id: String=String(old.get("id",""))
		if id in REMOVED:
			if removed.has(id) or not equal(old,spec.parent_removed_records.get(id)): return {}
			removed[id]=true
		else: objects.append(old.duplicate(true))
	if removed.size()!=2 or objects.size()!=25: return {}
	next.objects=objects; next.walk_path=walk
	next["aa_geometry_basis"]=BASIS; next["aa_author_sha256"]=AUTHOR_SHA
	# Inverse all authorized fields, retaining complete records and ordering.
	var inverse: Dictionary=next.duplicate(true)
	inverse.objects=parent.objects.duplicate(true); inverse.walk_path=parent.walk_path
	inverse.erase("aa_geometry_basis"); inverse.erase("aa_author_sha256")
	return next if equal(inverse,parent) else {}
static func materialize(parent: SceneScript,record: Dictionary,walk: String) -> SceneScript:
	if parent==null or parent.scene_id!=ID or parent.map_layout==null or record.get("aa_author_sha256")!=AUTHOR_SHA or record.get("walk_path")!=walk or not parent.has_meta(OLD_META) or parent.has_meta(META): return null
	var original: Array=parent.map_layout.visual_objects
	if original.size()!=27: return null
	var next:=parent.duplicate(true) as SceneScript
	next.map_layout=parent.map_layout.duplicate(true) as WalkableMapLayout
	var rows: Array[Dictionary]=[]; var removed: Dictionary={}
	for old: Dictionary in original:
		var id: String=String(old.get("id",""))
		if id in REMOVED:
			if removed.has(id): return null
			removed[id]=old
		else: rows.append(old.duplicate(true))
	if removed.size()!=2 or rows.size()!=25: return null
	next.map_layout.visual_objects=rows; next.map_layout.walkable_mask_path=walk
	next.remove_meta(OLD_META); next.set_meta(META,AUTHOR_SHA)
	var inverse:=next.duplicate(true) as SceneScript
	inverse.map_layout=next.map_layout.duplicate(true) as WalkableMapLayout
	inverse.map_layout.visual_objects=parent.map_layout.visual_objects.duplicate(true)
	inverse.map_layout.walkable_mask_path=parent.map_layout.walkable_mask_path
	inverse.remove_meta(META); inverse.set_meta(OLD_META,parent.get_meta(OLD_META))
	return next if b().equal(b().storage(inverse),b().storage(parent)) and b().equal(b().storage(inverse.map_layout),b().storage(parent.map_layout)) else null
static func local_monotonic(old_mask: Image,new_mask: Image,parent: Dictionary) -> Dictionary:
	# p's exact black-to-white-only algorithm is executed anew, not old PASS.
	var mono: Dictionary=p().mask_monotonic(old_mask,new_mask)
	if mono.get("passed")!=true: return {"passed":false,"error":"AA_REMOVE_ONLY_MONOTONIC"}
	var polygons: Array[PackedVector2Array]=[]
	for id: String in REMOVED:
		var object: Dictionary=find(parent.objects,id)
		if object.is_empty(): return {"passed":false,"error":"AA_REMOVED_SOLID_ABSENT"}
		polygons.append_array(c().object_solids([object]))
	var old_bytes: PackedByteArray=old_mask.get_data(); var new_bytes: PackedByteArray=new_mask.get_data()
	var count: int=0
	for offset: int in range(0,old_bytes.size(),4):
		if old_bytes[offset]==new_bytes[offset]: continue
		var pixel: int=offset/4; var point:=Vector2(pixel%SIZE.x,pixel/SIZE.x)
		var inside: bool=false
		for polygon: PackedVector2Array in polygons:
			# C raster uses pixel centres. Retain a 1px inclusive raster-edge box,
			# not any roof rectangle or the whole western district.
			var bounds: Rect2=Rect2(polygon[0],Vector2.ZERO)
			for vertex: Vector2 in polygon: bounds=bounds.expand(vertex)
			if bounds.grow(1.0).has_point(point): inside=true
		if not inside: return {"passed":false,"error":"AA_MASK_CHANGE_OUTSIDE_REMOVED_NATIVE_BASES","pixel":[point.x,point.y]}
		count+=1
	return {"passed":count>0,"changed_pixels":count,"monotonic":mono,"scope":"Only two old native-ground raster envelopes, not roofs"}
static func geometry(record: Dictionary,mask: Image,parent: Dictionary,old_mask: Image) -> Dictionary:
	var original: Dictionary=g().audit(record,mask)
	if original.get("passed")!=true: return {"passed":false,"error":"AA_ORIGINAL_ROUTES_CROWD","audit":original}
	var solids: Array[PackedVector2Array]=c().object_solids(record.objects)
	if not c()._all_gameplay_safe_cpu(record,mask,solids,Callable()): return {"passed":false,"error":"AA_ORIGINAL_GAMEPLAY"}
	var mono: Dictionary=local_monotonic(old_mask,mask,parent)
	if mono.get("passed")!=true: return mono
	var combined: Dictionary=p().combined_geometry(record,mask)
	if combined.get("passed")!=true: return {"passed":false,"error":"AA_DISTRICT_COMBINED","audit":combined}
	var stations: Array=[]
	for raw: Array in author().new_clearance_stations_px:
		var foot:=Vector2(raw[0],raw[1])
		if not c()._safe_body_cpu(foot,mask,solids) or not g().seventeen(foot,mask): return {"passed":false,"error":"AA_NEW_CLEARANCE","foot_px":raw}
		stations.append(raw.duplicate())
	return {"passed":true,"basis":BASIS,"original_routes":original,"local_mask":mono,"combined":combined,"clearance_stations":stations,"full87517":true,"npc_continuous_body_px":[34,30],"all_npcs_portals_routes_unchanged":true}
static func bound(scene: SceneScript) -> bool:
	return requested(ID) and scene!=null and scene.scene_id==ID and scene.get_meta(META,"")==AUTHOR_SHA and not scene.has_meta(OLD_META) and b().whole_bound(scene)
static func restore_parent_record(scene: SceneScript,current: Dictionary,expected: Dictionary,data: Dictionary) -> Dictionary:
	if not bound(scene) or data.get("geometry_basis")!=BASIS or data.get("aa_author_sha256")!=AUTHOR_SHA: return {}
	var child: Dictionary=data.record.duplicate(true)
	for key: String in ["harbour_runtime_binding_sha","harbour_parent_task_semantics_preserved"]:
		if not current.has(key): child.erase(key)
	return expected.duplicate(true) if equal(current,child) and equal(expected,data.get("aa_district_parent_record")) else {}
