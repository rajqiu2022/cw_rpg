extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Pure one-entry replay of documented native projection, never C.prepare/Field/texture decode.
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const MANIFEST="res://build/luoyang_harbour_life_publication_20261016/93032_1727/ch4_s2_canal_docks/manifest.json"
const MANIFEST_SHA="0470e79beeb5e71842fb3d9fc9b3db44fe356a6c8c5ad7d7e00c585cc8ece5af"
const CANONICAL="res://data/scenes/ch4_s2_canal_docks.tres"
var differences: Array[Dictionary]=[]
func _leaf(a: Variant,b: Variant,path: Array) -> void:
	if differences.size()>=64: return
	if a is Dictionary and b is Dictionary:
		for key: Variant in a:
			if b.has(key): _leaf(a[key],b[key],path+[key])
			else: differences.append({"path":path+[key],"missing_right":true})
		for key: Variant in b:
			if not a.has(key): differences.append({"path":path+[key],"missing_left":true})
		return
	if a is Array and b is Array:
		if a.size()!=b.size(): differences.append({"path":path,"left_size":a.size(),"right_size":b.size()});return
		for index: int in a.size(): _leaf(a[index],b[index],path+[index])
		return
	if typeof(a)==typeof(b) and a==b: return
	var row: Dictionary={"path":path,"native_type":typeof(a),"persisted_type":typeof(b),"native_value":str(a),"persisted_value":str(b),"native_variant_bytes":var_to_bytes(a).hex_encode(),"persisted_variant_bytes":var_to_bytes(b).hex_encode()}
	if a is float and b is float:
		row.native_f32=PackedFloat32Array([a]).to_byte_array().hex_encode();row.persisted_f32=PackedFloat32Array([b]).to_byte_array().hex_encode()
		row.finite_float32_equal=is_finite(a) and is_finite(b) and is_finite(PackedFloat32Array([a])[0]) and is_finite(PackedFloat32Array([b])[0]) and row.native_f32==row.persisted_f32
	differences.append(row)
func _diagnose() -> bool:
	if not track(MANIFEST,MANIFEST_SHA) or not track("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","82df07a7411aa10327485db7c9e7d90df7770defb4b677907a9bc0a57c62d1d1"): return false
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	for path: String in [CANONICAL,manifest.scene_path,manifest.layout_path,get_script().resource_path,"res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"]:
		if not track(path,FileAccess.get_sha256(path)): return false
	var canonical: SceneScript=ResourceLoader.load(CANONICAL,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var published: SceneScript=ResourceLoader.load(manifest.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(canonical!=null and canonical.scene_id==&"ch4_s2_canal_docks" and published!=null,"Actual immutable canonical and published resources, no prepare"): return false
	var authored: Dictionary={};var persisted: Dictionary={};var visual_index: int=-1
	for object: Dictionary in manifest.record.objects:
		if object.id=="north_canal_warehouse": authored=object
	for index: int in published.map_layout.visual_objects.size():
		if published.map_layout.visual_objects[index].id=="north_canal_warehouse": visual_index=index;persisted=published.map_layout.visual_objects[index]
	if not check(not authored.is_empty() and visual_index>=0,"Exact first failed unchanged warehouse entry"): return false
	# Same documented native Vector2 operations as C._materialize_enclosure_after_base
	# and revision author.apply_scene; no production validator/cache is invoked.
	var native: Dictionary=authored.duplicate(true)
	var foot: Vector2=Vector2(authored.world_foot_px[0],authored.world_foot_px[1]);var render: Vector2=Vector2(authored.render_size_px[0],authored.render_size_px[1]);var uv: Vector2=Vector2(authored.foot_uv[0],authored.foot_uv[1])
	native.pos=(foot+(Vector2(.5,.5)-uv)*render)/Vector2(3072,2048);native.render_size_px=render;native.centered=true;native.sort_by_feet=authored.get("role","")!="ground_overlay"
	if not native.sort_by_feet: native.z_index=-2;native.ghost_occlusion=false
	native.depth_sort_foot_y=foot.y/2048.0;native.city_v3_solid_polygons_px=authored.solid_polygons_px.duplicate(true);native.erase("solid_polygons_px")
	_leaf(native,persisted,["visual_objects",visual_index])
	records.append({"kind":"PURE_ORIGINAL_PARENT_NATIVE_VS_PERSISTED_LEAF_DIAGNOSTIC","id":"north_canal_warehouse","canonical_scene_path":canonical.resource_path,"published_scene_path":published.resource_path,"visual_index":visual_index,"strict_equal":C._equal_value(native,persisted),"existing_path_specific_serialized_equal":C.equal_visual_serialized_value(native,persisted,["visual_objects",visual_index]),"differences":differences,"Field_or_original_26584_live_snapshot_claimed":false,"C_prepare_or_texture_or_derived_artwork_executed":false})
	print(JSON.stringify(records[-1]))
	return check(not differences.is_empty(),"Diagnostic captured concrete original-parent leaf differences; not new h acceptance")
func _run() -> void:
	var began:=Time.get_ticks_msec();deadline=began+10000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=_diagnose()
	finish("res://build/luoyang_docks_office_parent_leaf_diagnostic_20261016h/%d_%d"%[OS.get_process_id(),began],began,complete,"PURE_ORIGINAL_PARENT_ONE_ENTRY_LEAF_DIAGNOSTIC_NOT_FIELD_PASS")
