extends "res://tests/test_luoyang_docks_office_roles_cpu_key_retry1_20261016h.gd"
## Single Scene storage diagnostic; no raw/import/directCTEX suite or Field.
var differences: Array=[]
func _leaf(value: Variant) -> Dictionary:
	if value is Resource: return {"typeof":typeof(value),"class":value.get_class(),"resource_path":value.resource_path}
	return {"typeof":typeof(value),"value":var_to_str(value),"variant_hex":var_to_bytes(value).hex_encode()}
func _diff(a: Variant,b: Variant,path: String) -> void:
	if differences.size()>=32: return
	if a is Resource and b is Resource:
		if a is Script or b is Script: _diff(a.resource_path,b.resource_path,path+".script_path");return
		_diff(_storage(a),_storage(b),path);return
	if a is Dictionary and b is Dictionary:
		var keys: Array=a.keys()
		for key: Variant in b:
			if key not in keys: keys.append(key)
		for key: Variant in keys:
			if not a.has(key) or not b.has(key): differences.append({"path":path+"."+str(key),"actual_has":a.has(key),"expected_has":b.has(key),"actual":_leaf(a.get(key)),"expected":_leaf(b.get(key))})
			else: _diff(a[key],b[key],path+"."+str(key))
		return
	if a is Array and b is Array:
		if a.size()!=b.size(): differences.append({"path":path+".size","actual":a.size(),"expected":b.size()})
		for index: int in mini(a.size(),b.size()): _diff(a[index],b[index],path+"["+str(index)+"]")
		return
	if typeof(a)!=typeof(b) or a!=b: differences.append({"path":path,"actual":_leaf(a),"expected":_leaf(b)})
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+10000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var complete: bool=_precheck() and track("res://tests/test_luoyang_docks_office_roles_cpu_key_retry1_20261016h.gd","35a3b1c7e62305091e64adde1a41db9883fa5659bac374563872e4c7b2c494bd")
	if complete:
		var source: SceneScript=ResourceLoader.load(parent.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
		var office_before: Dictionary={}
		for entry: Dictionary in source.map_layout.visual_objects:
			if entry.id==M.BUILDING: office_before=entry.duplicate(true)
		var expected: SceneScript=source.duplicate(true) as SceneScript
		var ids: Dictionary={"source_scene":source.get_instance_id(),"expected_scene":expected.get_instance_id(),"source_layout":source.map_layout.get_instance_id(),"expected_layout":expected.map_layout.get_instance_id()}
		var office: Dictionary=data.office
		var foot: Vector2=_v(office.expected_foot_px);var anchor: Vector2=_v(office.source_ground_anchor_px);var ratio: Vector2=_v(office.render_scale_xy)
		for entry: Dictionary in expected.map_layout.visual_objects:
			if entry.id!=M.BUILDING: continue
			entry.historical_parent_visual_provenance={"source":entry.get("source"),"source_sha256":entry.get("source_sha256"),"source_size_px":entry.get("source_size_px"),"actual_gpu":entry.get("actual_gpu"),"scope":"Original published native render evidence ONLY; not new office artwork/GPU evidence"}
			entry.texture=office.texture;entry.pos=(foot-anchor*ratio)/Vector2(3072,2048);entry.render_size_px=_v(office.source_size_px)*ratio;entry.centered=false;entry.foot_uv=[anchor.x/float(office.source_size_px[0]),anchor.y/float(office.source_size_px[1])]
			entry.source=office.texture;entry.source_sha256=data.source_sha256[String(office.texture)];entry.source_size_px=office.source_size_px.duplicate();entry.erase("actual_gpu");entry.docks_office_visual_author=AUTHOR_SHA
		expected.set_meta(M.META,AUTHOR_SHA)
		var office_after: Dictionary={}
		for entry: Dictionary in source.map_layout.visual_objects:
			if entry.id==M.BUILDING: office_after=entry.duplicate(true)
		var proofs: Dictionary={}
		for proof: Dictionary in data.texture_proofs: proofs[String(proof.texture)]=proof.duplicate(true)
		var packet: Dictionary={"author_sha256":AUTHOR_SHA,"author":data,"texture_proofs":proofs,"same_existing_base":true,"no_navigation_or_task_delta":true}
		# Actual materialize retains its unavoidable nativeTexture guards; no _textures loop.
		var actual: SceneScript=M.materialize(source.duplicate(true),packet)
		complete=check(actual!=null,"Actual materialize reproduced storage comparison input")
		if complete: _diff(actual,expected,"Scene")
		records.append({"kind":"EXACT_STORAGE_LEAF_DIAGNOSTIC","instances":ids,"source_office_before":office_before,"source_office_after_expected_write":office_after,"source_changed_by_expected_clone":not _equal(office_before,office_after),"strict_equal":actual!=null and _equal(actual,expected),"differences":differences,"raw_direct_RGBA_suite_replayed":false,"production_sources_edited":false})
	finish("res://build/luoyang_docks_office_storage_diagnostic_20261016h/%d_%d"%[OS.get_process_id(),began],began,complete,"ONLY_ACTUAL_EXPECTED_STORAGE_LEAF_VALUES_TYPES_NATIVE_BYTES")
