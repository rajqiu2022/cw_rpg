extends "res://build/luoyang_assembled_before_20261016b_system01/diagnose_city_record_domain.gd"
## ROOT-only pure Scene replay. No prepare, worker, images, public transition.
const C=preload("res://scripts/city/luoyang_enclosure_v11_candidate_contract.gd")
const SERIAL=preload("res://scripts/city/luoyang_city_revision_candidate_retry2_20261015.gd")
const R=preload("res://scripts/city/luoyang_city_revision_runtime_20261015.gd")
const PARENT="res://data/scenes/luoyang_city_revision_candidates_retry2_20261015/ch4_s3_luoyang_market.tres"
func _visual_diff(a: Variant,b: Variant,p: Array) -> Dictionary:
	if C.equal_visual_serialized_value(a,b,p): return {}
	if typeof(a)!=typeof(b): return _diff(a,b,p)
	if a is Dictionary and a.size()==b.size():
		for k: Variant in a:
			if not b.has(k): return {"path":p+[k],"missing_right":true}
			var d:=_visual_diff(a[k],b[k],p+[k])
			if not d.is_empty(): return d
	elif a is Array and a.size()==b.size():
		for i: int in a.size():
			var d:=_visual_diff(a[i],b[i],p+[i])
			if not d.is_empty(): return d
	return _diff(a,b,p)
func _storage_diff(a: SceneScript,b: SceneScript) -> Dictionary:
	for pair: Array in [[a,b],[a.map_layout,b.map_layout]]:
		for property: Dictionary in pair[1].get_property_list():
			var key: String=property.name
			if (int(property.usage)&PROPERTY_USAGE_STORAGE)==0 or key in ["script","map_layout","resource_path","resource_name","resource_local_to_scene"]: continue
			var d:=_visual_diff(pair[0].get(key),pair[1].get(key),[key]) if key=="visual_objects" else _diff(pair[0].get(key),pair[1].get(key),[key])
			if not d.is_empty():
				d["resource"]="SceneScript" if pair[0]==a else "WalkableMapLayout"
				return d
	return {}
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
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
	var report: Dictionary={"scope":"PURE_FIXED_PUBLISHED_PARENT_PLUS_EXACT_R_RUNTIME_DELTA_NOT_LIVE_PARENT_PROOF","serialized_equal":SERIAL.serialized_equal(expected,published),"first_diff":diff,"parent_portals":parent.map_layout.portals.size(),"elapsed_ms":Time.get_ticks_msec()-started,"source":PARENT,"source_sha":FileAccess.get_sha256(PARENT),"new_scene_sha":FileAccess.get_sha256(publication.scene_path)}
	var file:=FileAccess.open("res://build/luoyang_assembled_before_20261016b_system01/scene_storage_diagnostic_"+str(OS.get_process_id())+".json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
	print(JSON.stringify(report,"",true,true)); quit()
