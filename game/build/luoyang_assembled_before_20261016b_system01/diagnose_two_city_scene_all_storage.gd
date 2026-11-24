extends "res://build/luoyang_assembled_before_20261016b_system01/diagnose_city_scene_all_storage.gd"
## One CPU process covers BOTH fixed city publications, all storage leaves.
func _storage_diff(a: SceneScript,b: SceneScript) -> Dictionary:
	var market:=super._storage_diff(a,b)
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
	return {"difference_count":_all_differences.size(),"market_difference_count":market.difference_count,"yamen_difference_count":_all_differences.size()-start,"all_differences":_all_differences.duplicate(true),"yamen_original_serial_equal":SERIAL.serialized_equal(expected,published),"adapter_not_implemented":true}
