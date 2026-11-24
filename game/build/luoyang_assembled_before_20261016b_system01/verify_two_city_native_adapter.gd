extends "res://build/luoyang_assembled_before_20261016b_system01/diagnose_city_scene_all_storage.gd"
## ROOT-only two-city native-serialization positives and strict negatives.
const ADAPTER=preload("res://scripts/city/luoyang_city_assembled_serialized_20261016b.gd")
func _storage_diff(a: SceneScript,b: SceneScript) -> Dictionary:
	var market:=super._storage_diff(a,b)
	var market_test:=_test_adapter(a,b)
	for row: Dictionary in _all_differences: row["scene_id"]="ch4_s3_luoyang_market"
	var start:=_all_differences.size()
	var publication:=_read(NEW.replace("ch4_s3_luoyang_market","ch4_s1_luoyang_yamen"))
	var baseline:=_read("res://art/maps/luoyang_modular_v3_wall_street_proposal/root_wall_v5/ch4_s1_luoyang_yamen/art_contract.json")
	var patch:=_read("res://art/maps/luoyang_enclosure_v11/ch4_s1_luoyang_yamen/art_patch.json")
	var parent_record: Dictionary=publication.record.duplicate(true)
	var objects: Array=[]
	for object: Dictionary in baseline.objects:
		if not object.id in patch.remove_object_ids: objects.append(object.duplicate(true))
	objects.append_array(patch.objects.duplicate(true))
	parent_record.objects=objects; parent_record.routes=baseline.routes.duplicate(true)
	for key: String in ["assembled_author_sha_20261016b","assembled_parent_identity_20261016b","assembled_portals_preserved_except_explicit_room_moves","assembled_relocated_rooms"]: parent_record.erase(key)
	var data:=A.author(); var donors: Dictionary={}
	for path: String in data.source_sha256:
		if path.ends_with(".json"): donors[path]=_read(path)
	var record:=A.compose(parent_record,A.spec_for(data,&"ch4_s1_luoyang_yamen"),donors)
	record.walk_path=publication.walk_path
	# Yamen has no R fourth-layer delta. Its published parent is the unchanged
	# canonical enclosure Scene, which A duplicates before doing its own edits.
	var parent:=ResourceLoader.load("res://data/scenes/ch4_s1_luoyang_yamen.tres","",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var expected:=A.apply_scene(parent,record,String(publication.walk_path))
	var published:=ResourceLoader.load(publication.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	for pair: Array in [[expected,published],[expected.map_layout,published.map_layout]]:
		for property: Dictionary in pair[1].get_property_list():
			var key: String=property.name
			if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or key in ["script","map_layout","resource_path","resource_name","resource_local_to_scene"]: continue
			_collect(pair[0].get(key),pair[1].get(key),[key],key=="visual_objects")
	for i: int in range(start,_all_differences.size()): _all_differences[i]["scene_id"]="ch4_s1_luoyang_yamen"
	var yamen_test:=_test_adapter(expected,published)
	return {"adapter_checks_pass":market_test.passed and yamen_test.passed,"adapter_checks":[market_test,yamen_test],"difference_count":_all_differences.size(),"market_difference_count":market.difference_count,"yamen_difference_count":_all_differences.size()-start,"all_differences":_all_differences.duplicate(true),"yamen_original_serial_equal":SERIAL.serialized_equal(expected,published),"adapter_source_sha":FileAccess.get_sha256("res://scripts/city/luoyang_city_assembled_serialized_20261016b.gd")}


func _clone(scene: SceneScript) -> SceneScript:
	var out:=scene.duplicate(true) as SceneScript
	out.map_layout=scene.map_layout.duplicate(true) as WalkableMapLayout
	return out
func _tree(scene: SceneScript) -> Dictionary:
	for entry: Dictionary in scene.map_layout.visual_objects:
		if ADAPTER.TREES[String(scene.scene_id)].has(String(entry.id)): return entry
	return {}
func _test_adapter(native: SceneScript,published: SceneScript) -> Dictionary:
	var checks: Array=[]
	checks.append({"id":"full_all_storage_positive","passed":ADAPTER.equal(native,published)})
	var changed:=_clone(published); var item:=_tree(changed)
	item.collision_size_px[0]=float(item.collision_size_px[0])+1.0
	checks.append({"id":"one_pixel_physical_difference_refused","passed":not ADAPTER.equal(native,changed)})
	changed=_clone(published); item=_tree(changed)
	var bits:=PackedFloat32Array([float(item.collision_size_px[0])]).to_byte_array()
	bits.encode_u32(0,bits.decode_u32(0)+1)
	item.collision_size_px[0]=float(bits.to_float32_array()[0])
	checks.append({"id":"one_native_ulp_difference_refused","passed":not ADAPTER.equal(native,changed)})
	changed=_clone(published); item=_tree(changed); item.collision_size_px.append(0.0)
	checks.append({"id":"native_vector_count_refused","passed":not ADAPTER.equal(native,changed)})
	changed=_clone(published); item=_tree(changed); item.assembled_transform_20261016b.source_id="not_the_frozen_donor"
	checks.append({"id":"transform_source_refused","passed":not ADAPTER.equal(native,changed)})
	changed=_clone(published); changed.set_meta(A.META,"wrong_source")
	checks.append({"id":"source_author_identity_refused","passed":not ADAPTER.equal(native,changed)})
	changed=_clone(published); changed.player_spawn+=Vector2(1.0/3072,0)
	checks.append({"id":"unrelated_storage_change_refused","passed":not ADAPTER.equal(native,changed)})
	var passed:=true
	for row: Dictionary in checks: passed=passed and row.passed
	return {"scene_id":String(native.scene_id),"passed":passed,"checks":checks}

func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var source_before:=_source_snapshot()
	var started:=Time.get_ticks_msec(); var old:=_read(OLD); var publication:=_read(NEW)
	var parent_record: Dictionary=publication.record.duplicate(true)
	for k: String in ["objects","gameplay_slots","routes","walk_path"]: parent_record[k]=old[k].duplicate(true) if old[k] is Array or old[k] is Dictionary else old[k]
	for k: String in ["assembled_author_sha_20261016b","assembled_parent_identity_20261016b","assembled_portals_preserved_except_explicit_room_moves","assembled_relocated_rooms"]: parent_record.erase(k)
	var slots: Array=[]
	for slot: Dictionary in parent_record.gameplay_slots.portals:
		if slot.get("source_id")!="enter_southwest_market_front_room": slots.append(slot)
	parent_record.gameplay_slots.portals=slots
	var data:=A.author(); var donors: Dictionary={}
	for path: String in data.source_sha256:
		if path.ends_with(".json"): donors[path]=_read(path)
	var native_record:=A.compose(parent_record,A.spec_for(data,&"ch4_s3_luoyang_market"),donors)
	native_record.walk_path=publication.walk_path
	# Exact, explicit post-publication delta from frozen R.materialize source:
	# remove only SW doorway, enable remaining8, add the fixed runtime metadata.
	var frozen:=ResourceLoader.load(PARENT,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var parent:=frozen.duplicate(true) as SceneScript
	parent.map_layout=frozen.map_layout.duplicate(true) as WalkableMapLayout
	var portals: Array[Dictionary]=[]
	for portal: Dictionary in parent.map_layout.portals:
		if portal.get("candidate_only",false):
			if portal.get("building_id")=="southwest_market_front": continue
			portal.enabled=true; portal.router_install_status="EXPLICIT_NESTED_ID_RESOLVER_CANDIDATE"
		portals.append(portal)
	parent.map_layout.portals=portals
	parent.set_meta(R.META,R.CITY_PINS[String(parent.scene_id)].manifest)
	parent.set_meta("city_revision_runtime_binding_sha",R.BIND_SHA)
	parent.set_meta("city_revision_published_scene_path",PARENT)
	parent.set_meta("city_revision_source_scene_path","res://data/scenes/ch4_s3_luoyang_market.tres")
	parent.set_meta("city_frontage_revision_runtime_status","ROOT_APPROVED_DEFAULT_REVISION")
	var expected:=A.apply_scene(parent,native_record,String(publication.walk_path))
	var published:=ResourceLoader.load(publication.scene_path,"",ResourceLoader.CACHE_MODE_IGNORE) as SceneScript
	var diff:=_storage_diff(expected,published)
	var source_after:=_source_snapshot()
	var passed: bool=diff.get("adapter_checks_pass",false) and source_before==source_after
	var report: Dictionary={"passed":passed,"sources_before":source_before,"sources_after":source_after,"scope":"PURE_FIXED_PUBLISHED_PARENT_PLUS_EXACT_R_RUNTIME_DELTA_NOT_LIVE_PARENT_PROOF","serialized_equal":SERIAL.serialized_equal(expected,published),"first_diff":diff,"parent_portals":parent.map_layout.portals.size(),"elapsed_ms":Time.get_ticks_msec()-started,"source":PARENT,"source_sha":FileAccess.get_sha256(PARENT),"new_scene_sha":FileAccess.get_sha256(publication.scene_path)}
	var file:=FileAccess.open("res://build/luoyang_assembled_before_20261016b_system01/two_city_native_adapter_cpu_"+str(OS.get_process_id())+".json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
	print(JSON.stringify(report,"",true,true)); quit(0 if passed else 1)
func _source_snapshot() -> Dictionary:
	var out: Dictionary={}
	for path: String in [PARENT,NEW,"res://build/luoyang_city_assembled_publication_20261016b/78428_1686/ch4_s1_luoyang_yamen/manifest.json","res://scripts/city/luoyang_city_assembled_serialized_20261016b.gd","res://scripts/city/luoyang_city_assembled_runtime_20261016b.gd","res://data/maps/luoyang_city_assembled_20261016b/runtime_bindings.json","res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd","res://scripts/field/field_walkable_controller.gd","res://scripts/city/luoyang_functional_interiors_20261016.gd"]:
		out[path]=FileAccess.get_sha256(path)
	return out
