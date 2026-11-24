extends SceneTree
## Pure NEW-author replay; no C.prepare, images, GPU, router or player state.
const A=preload("res://scripts/city/luoyang_city_assembled_retry2_20261016b.gd")
const OLD="res://art/maps/luoyang_city_revision_retry2_20261015/ch4_s3_luoyang_market/candidate_manifest.json"
const NEW="res://build/luoyang_city_assembled_publication_20261016b/78428_1686/ch4_s3_luoyang_market/manifest.json"
func _read(path: String) -> Dictionary: return JSON.parse_string(FileAccess.get_file_as_string(path))
func _diff(a: Variant,b: Variant,p: Array=[]) -> Dictionary:
	if typeof(a)!=typeof(b): return {"path":p,"left_type":type_string(typeof(a)),"right_type":type_string(typeof(b)),"left":str(a),"right":str(b)}
	if a is Dictionary:
		if a.size()!=b.size(): return {"path":p,"left_size":a.size(),"right_size":b.size(),"left_keys":a.keys(),"right_keys":b.keys()}
		for k: Variant in a:
			if not b.has(k): return {"path":p+[k],"missing_right":true}
			var d:=_diff(a[k],b[k],p+[k])
			if not d.is_empty(): return d
	elif a is Array:
		if a.size()!=b.size(): return {"path":p,"left_size":a.size(),"right_size":b.size()}
		for i: int in a.size():
			var d:=_diff(a[i],b[i],p+[i])
			if not d.is_empty(): return d
	elif a!=b: return {"path":p,"left_type":type_string(typeof(a)),"right_type":type_string(typeof(b)),"left":str(a),"right":str(b),"left_json":JSON.stringify(a,"",true,true),"right_json":JSON.stringify(b,"",true,true)}
	return {}
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true)
	var started:=Time.get_ticks_msec(); var old:=_read(OLD); var publication:=_read(NEW)
	# These three complete fields have already passed the original R strict
	# comparison before child execution. Restore that exact published parent,
	# removing only child-added receipts, not ignoring any comparison field.
	var parent: Dictionary=publication.record.duplicate(true)
	for k: String in ["objects","gameplay_slots","routes","walk_path"]: parent[k]=old[k].duplicate(true) if old[k] is Array or old[k] is Dictionary else old[k]
	for k: String in ["assembled_author_sha_20261016b","assembled_parent_identity_20261016b","assembled_portals_preserved_except_explicit_room_moves","assembled_relocated_rooms"]: parent.erase(k)
	var disabled: Array=[]
	for slot: Dictionary in parent.gameplay_slots.portals:
		if slot.get("source_id")=="enter_southwest_market_front_room": disabled.append(slot)
	for slot: Dictionary in disabled: parent.gameplay_slots.portals.erase(slot)
	var data:=A.author(); var donors: Dictionary={}
	for path: String in data.source_sha256:
		if path.ends_with(".json"): donors[path]=_read(path)
	var record:=A.compose(parent,A.spec_for(data,&"ch4_s3_luoyang_market"),donors)
	if not record.is_empty(): record.walk_path=publication.walk_path
	var report: Dictionary={"scope":"PURE_PUBLISHED_PARENT_REPLAY_NOT_ACTUAL_LIVE_PARENT_PROOF","first_diff":_diff(record,publication.record),"elapsed_ms":Time.get_ticks_msec()-started,"old_sha":FileAccess.get_sha256(OLD),"new_sha":FileAccess.get_sha256(NEW),"author_sha":A.AUTHOR_SHA}
	var out:="res://build/luoyang_assembled_before_20261016b_system01/record_domain_diagnostic_"+str(OS.get_process_id())+".json"
	var file:=FileAccess.open(out,FileAccess.WRITE); file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
	print(JSON.stringify(report,"",true,true)); quit()
