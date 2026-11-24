extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Three textures / two exact roles / one render-only building. No C.prepare.
const KEY_READY=true
const M=preload("res://scripts/city/luoyang_docks_office_roles_20261016h.gd")
const CROWD=preload("res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd")
const HELPER_SHA="0ae49505fbe837da8a06e35add9e857532d03ee70c9c9260ffa6f9a0c9e31117"
const AUTHOR_SHA="dc8d7ae836735f349360ca0bd69cc0290ebc6461470e7bd3af359ded568ec9e7"
const HARBOUR_PATH="res://scripts/city/luoyang_harbour_life_runtime_20261016.gd"
const HARBOUR_SHA="1e1e52210dbe7d5e1158ca9521835eb5f9f4d0e59b8f049141e8143e9b371cae"
const CROWD_PATH="res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd"
const CROWD_SHA="1aaea6ca19ab8abb1f164b155f24ac8a11ca43e7e4d73b1fa4fd899937b5e83b"
var data: Dictionary={}
var parent: Dictionary={}
func _v(value: Variant) -> Vector2: return value if value is Vector2 else Vector2(value[0],value[1])
func _sha(bytes: PackedByteArray) -> String:
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes);return hash.finish().hex_encode()
func _equal(a: Variant,b: Variant) -> bool:
	if a is Resource and b is Resource:
		if a is Script or b is Script: return a is Script and b is Script and a.resource_path==b.resource_path
		return _equal(_storage(a),_storage(b))
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equal(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size(): return false
		for i: int in a.size():
			if not _equal(a[i],b[i]): return false
		return true
	return typeof(a)==typeof(b) and a==b
func _storage(resource: Resource) -> Dictionary:
	var result: Dictionary={}
	for property: Dictionary in resource.get_property_list():
		if (int(property.usage)&PROPERTY_USAGE_STORAGE)!=0: result[property.name]=resource.get(property.name)
	return result
func _precheck() -> bool:
	if not check(KEY_READY,"Unfrozen prepared key refuses"): return false
	if not track(M.SELF,HELPER_SHA) or not track(M.AUTHOR_PATH,AUTHOR_SHA) or not track(HARBOUR_PATH,HARBOUR_SHA) or not track(CROWD_PATH,CROWD_SHA): return false
	data=M.author()
	if not check(not data.is_empty() and M.AUTHOR_SHA==AUTHOR_SHA and not M.FORMAL_ENABLED and M.FLAG in OS.get_cmdline_user_args(),"Exact frozen candidate author and explicit flag"): return false
	for path: String in data.source_sha256:
		if not track(path,data.source_sha256[path]): return false
	for path: String in [get_script().resource_path,"res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"]:
		if not track(path,FileAccess.get_sha256(path)): return false
	parent=JSON.parse_string(FileAccess.get_file_as_string(data.parent_manifest))
	return check(parent.record.objects.size()==28 and data.office.id=="harbour_cargo_trade_front" and data.office.no_new_portal_or_room,"Original28-object record, one precise office visual only")
func _textures() -> bool:
	var recipe: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(data.derivation_receipt.path))
	if not check(recipe.rows.size()==3 and recipe.pillow_version=="12.2.0" and not recipe.raw_pixel_edits and not recipe.cropping_alpha_threshold_or_repainting and data.derivation_receipt.raw_runtime_equal==false,"Frozen original fullcanvas one-pass Pillow receipt; not raw1254 equals160"): return false
	var roles: int=0
	for source: Dictionary in recipe.rows:
		if not track(source.raw_path,source.raw_sha256): return false
		var raw:=Image.load_from_file(source.raw_path)
		if not check(raw!=null and raw.get_size()==Vector2i(int(source.raw_size_px[0]),int(source.raw_size_px[1])),"Actual unchanged raw canvas dimensions"): return false
		raw.convert(Image.FORMAT_RGBA8)
		if not check(_sha(raw.get_data())==source.raw_rgba_sha256,"Raw original full RGBA retained"): return false
		if source.role!="office":
			if not check(source.derivation=="PILLOW_RGBA_FULL_CANVAS_ONE_RESIZE_LANCZOS_BOX_NONE_REDUCING_GAP_NONE" and not source.runtime_raw_byte_identical and source.single_frame_not_animation and raw.get_size()==Vector2i(1254,1254) and _v(source.size_px)==Vector2(160,160),"Two one-frame160 Pillow derivatives, no invented animation"): return false
			roles+=1
		var proof: Dictionary={}
		for row: Dictionary in data.texture_proofs:
			if row.texture==source.texture: proof=row
		if not check(not proof.is_empty() and proof.full_rgba_exact and proof.params23 and proof.source_sha256==source.source_sha256 and proof.rgba_sha256==source.rgba_sha256,"Bound actual isolated import proof row"): return false
		var texture:=ResourceLoader.load(proof.texture) as Texture2D
		var direct:=CompressedTexture2D.new()
		if not check(texture!=null and direct.load(proof.compiled_path)==OK,"Three native Texture2D and direct compiled binaries"): return false
		var imported:=texture.get_image();var compiled:=direct.get_image();var runtime:=Image.load_from_file(proof.texture)
		for image: Image in [runtime,imported,compiled]:
			if image==null: return check(false,"Native full image required")
			if image.is_compressed() and not check(image.decompress()==OK,"Read-only native lossless decode"): return false
			image.convert(Image.FORMAT_RGBA8)
		if not check(runtime.get_size()==Vector2i(int(proof.size_px[0]),int(proof.size_px[1])) and runtime.get_data()==imported.get_data() and runtime.get_data()==compiled.get_data() and _sha(runtime.get_data())==proof.rgba_sha256 and imported.get_mipmap_count()==0 and compiled.get_mipmap_count()==0,"Current source/import/directCTEX complete RGBA/no-mip including alpha1"): return false
		records.append({"kind":"ACTUAL_THREE_TEXTURE_ROW","role":source.role,"texture":proof.texture,"raw_size":raw.get_size(),"runtime_size":runtime.get_size(),"raw_equals_runtime_claimed":source.role=="office","raw_derivation_recomputed_with_other_kernel":false,"full_RGBA":true})
	return check(roles==2,"Exactly two raw1254 to160 recipes and one exact-copy office")
func _geometry_and_projection() -> bool:
	var original: Dictionary={}
	for object: Dictionary in parent.record.objects:
		if object.id==M.BUILDING: original=object
	if not check(not original.is_empty() and _v(original.world_foot_px)==Vector2(1720,1790) and original.solid_polygons_px.size()==1,"One unchanged physical support at original foot"): return false
	var old: Array=original.solid_polygons_px[0]
	var low: Vector2=_v(old[0]);var high: Vector2=low
	for point: Variant in old: low=low.min(_v(point));high=high.max(_v(point))
	if not check(old.size()==4,"Original support is a full closed axis rectangle"): return false
	for point: Variant in old:
		if not check(_v(point) in [low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)],"No inferred rectangle around a nonrectangular parent solid"): return false
	var office: Dictionary=data.office
	var foot: Vector2=_v(office.expected_foot_px);var anchor: Vector2=_v(office.source_ground_anchor_px);var ratio: Vector2=_v(office.render_scale_xy)
	for polygon: Array in office.ground_solid_polygons_px:
		for point: Variant in polygon:
			var world: Vector2=foot+(_v(point)-anchor)*ratio
			if not check(world.is_finite() and world.x>=low.x and world.x<=high.x and world.y>=low.y and world.y<=high.y,"Independent closed rectangle containment, not production clip result",world): return false
	var record_before: Dictionary=parent.record.duplicate(true)
	var packet: Dictionary=M.prepare_packet(parent.record)
	if not check(not packet.is_empty() and _equal(parent.record,record_before),"Actual packet keeps complete original record/NAV semantics"): return false
	var source: SceneScript=ResourceLoader.load(parent.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	if not check(source!=null,"Immutable published Scene available"): return false
	var source_before: SceneScript=source.duplicate(true) as SceneScript
	source_before.map_layout=source.map_layout.duplicate(true) as WalkableMapLayout
	var expected: SceneScript=source.duplicate(true) as SceneScript
	expected.map_layout=source.map_layout.duplicate(true) as WalkableMapLayout
	var expected_count: int=0
	for object: Dictionary in expected.map_layout.visual_objects:
		if object.id!=M.BUILDING: continue
		var historical: Dictionary={"source":object.get("source"),"source_sha256":object.get("source_sha256"),"source_size_px":object.get("source_size_px"),"actual_gpu":object.get("actual_gpu"),"scope":"Original published native render evidence ONLY; not new office artwork/GPU evidence"}
		expected_count+=1;object.texture=office.texture;object.pos=(foot-anchor*ratio)/Vector2(3072,2048);object.render_size_px=_v(office.source_size_px)*ratio;object.centered=false;object.foot_uv=[anchor.x/float(office.source_size_px[0]),anchor.y/float(office.source_size_px[1])]
		object.historical_parent_visual_provenance=historical;object.source=office.texture;object.source_sha256=data.source_sha256[String(office.texture)];object.source_size_px=office.source_size_px.duplicate();object.erase("actual_gpu");object.docks_office_visual_author=AUTHOR_SHA
	expected.set_meta(M.META,AUTHOR_SHA)
	if not check(_equal(source,source_before),"Independent expected writes preserve complete original Scene/layout storage"): return false
	var actual: SceneScript=M.materialize(source.duplicate(true),packet)
	if not check(expected_count==1 and actual!=null and _equal(actual,expected),"Every Scene/layout storage field equals independently expected source/render/historical-provenance fields plus explicit meta; other27 unchanged"): return false
	var rows: Array=CROWD.project(M.CITY);var rows_before: Array=rows.duplicate(true)
	var projected: Dictionary=M.project_npcs(actual,rows)
	if not check(projected.ok and projected.npcs.size()==10 and _equal(rows,rows_before),"Ten original role rows input untouched"): return false
	var changed: int=0
	for index: int in rows.size():
		var wanted: Dictionary=rows[index].duplicate(true)
		if wanted.npc_id in M.ROLE_IDS: wanted.sprite_path=data.roles[wanted.npc_id].texture;changed+=1
		if not check(_equal(wanted,projected.npcs[index]),"Only exact two sprite paths changed; all old positions/modes/actions/scale remain"): return false
	var gate: Array=CROWD.project(&"ch4_s0_luoyang_gate");var gate_before: Array=gate.duplicate(true)
	var gate_scene: SceneScript=SceneScript.new();gate_scene.scene_id=&"ch4_s0_luoyang_gate"
	if not check(changed==2 and gate.size()==10 and not M.project_npcs(gate_scene,gate).ok and _equal(gate,gate_before),"Gate rows out of scope and unchanged, no global WAITER replacement"): return false
	records.append({"kind":"ONE_VISUAL_TWO_ROLE_DELTA","old_objects":28,"unchanged_other_objects":27,"changed_role_sprite_paths":changed,"unchanged_docks_roles":8,"unchanged_gate_source_roles":10,"parent_solid_bounds":[low,high],"record_unchanged":true,"door_added":false,"native_Node_or_Field_claimed":false})
	return true
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+30000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=_precheck()
	if complete: complete=_textures() and _geometry_and_projection()
	finish("res://build/luoyang_docks_office_roles_cpu_20261016h/%d_%d"%[OS.get_process_id(),began],began,complete,"ONLY_THREE_TEXTURES_ONE_BUILDING_VISUAL_TWO_ROLE_PATHS_NOT_FIELD_OR_DOCKS_BIRTH")

