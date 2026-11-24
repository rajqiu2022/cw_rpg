extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Prepared only. ROOT-approved first execution whole60s; never invokes C.prepare.
const PREPARED_READY=false
const R=preload("res://scripts/city/luoyang_district_life_20261016f.gd")
const G=preload("res://scripts/city/luoyang_district_life_geometry_20261016f.gd")
const RAW=preload("res://tests/helpers/city_life_independent_oracle_20261016f.gd")
const OLD_CROWD=preload("res://scripts/city/luoyang_harbour_life_crowd_retry3_20261016.gd")
const FINAL_RUNTIME_SHA="PENDING_FROZEN_RUNTIME"
const FINAL_BIND_SHA="PENDING_FROZEN_BIND"
const PUBLICATION_RESULT="PENDING_ROOT_ACTUAL_PUBLISHER_RESULT"
const PUBLICATION_SHA="PENDING_ROOT_ACTUAL_PUBLISHER_SHA"
var author: Dictionary={}
func precheck() -> bool:
	if not check(PREPARED_READY,"Prepared draft refuses until final source/publisher proof"): return false
	if not track(R.SELF,FINAL_RUNTIME_SHA) or not track(R.BIND_PATH,FINAL_BIND_SHA) or not track(PUBLICATION_RESULT,PUBLICATION_SHA): return false
	package=R.binding(); author=R.author(package)
	if not check(not package.is_empty() and not author.is_empty() and R.BIND_SHA==FINAL_BIND_SHA,"Exact final authored package"): return false
	for path: String in package.source_sha256:
		if not track(path,package.source_sha256[path]): return false
	for path: String in R.source_paths():
		if not source_before.has(path) and not track(path,FileAccess.get_sha256(path)): return false
	for path: String in [get_script().resource_path,"res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd","res://tests/helpers/city_life_independent_oracle_20261016f.gd","res://tests/helpers/temple_assembly_raw_oracle_20261016.gd"]:
		if not track(path,FileAccess.get_sha256(path)): return false
	return true
func _textures() -> bool:
	for id: String in ["herbal_medicine_stall_v1","official_service_annex_v1"]:
		var asset: Dictionary=author.assets[id]
		var path: String=asset.texture
		var proof: Dictionary=package.texture_proofs[path]
		var raw:=Image.load_from_file(path)
		var texture:=ResourceLoader.load(path) as Texture2D
		var compiled:=CompressedTexture2D.new()
		if not check(raw!=null and texture!=null and compiled.load(proof.compiled_path)==OK,"Two new actual nativeCTEX/import/raw, no isolated import rerun"): return false
		var imported:=texture.get_image(); var direct:=compiled.get_image()
		for image: Image in [raw,imported,direct]:
			if image==null: return check(false,"Actual complete image required")
			if image.is_compressed() and not check(image.decompress()==OK,"Read-only lossless decode"): return false
			image.convert(Image.FORMAT_RGBA8)
		var expected:=Vector2i(asset.size_px[0],asset.size_px[1])
		if not check(raw.get_size()==expected and imported.get_size()==expected and direct.get_size()==expected and imported.get_mipmap_count()==0 and direct.get_mipmap_count()==0 and raw.get_data()==imported.get_data() and raw.get_data()==direct.get_data(),"New2 fullRGBA including unchanged A1 tail; no alpha threshold cleanup"): return false
		records.append({"kind":"NEW_ACTUAL_FULL_RGBA","id":id,"texture":path,"size":expected,"includes_alpha1_tail":true})
	return true
func _district(id: String) -> bool:
	var spec: Dictionary=author.districts[id]
	if not track(spec.parent_manifest.path,spec.parent_manifest.sha256): return false
	var parent: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.parent_manifest.path))
	if not track(parent.walk_path,parent.walk_sha256): return false
	var record: Dictionary=parent.record
	var oracle:=RAW.new()
	var independent:=oracle.compile_delta(author,spec)
	var projected:=G.project(author,StringName(id))
	if not check(independent.size()==spec.placements.size() and not projected.is_empty(),"All exact authored delta entities compile independently "+id): return false
	for entry: Dictionary in projected.additions+projected.replacements:
		var wanted: Array=independent[entry.id]
		if not check(wanted.size()==entry.city_v3_solid_polygons_px.size(),"Each transformed base count exact "+String(entry.id)): return false
		for index: int in wanted.size():
			var actual:=PackedVector2Array()
			for point: Array in entry.city_v3_solid_polygons_px[index]: actual.append(Vector2(point[0],point[1]))
			if not check(actual==wanted[index],"Every source-anchor/scale/renderfoot transformed point exact "+String(entry.id)): return false
	for placement: Dictionary in spec.placements:
		if String(placement.get("replaces","")).is_empty(): continue
		var original: Dictionary={}
		for object: Dictionary in record.objects:
			if object.id==placement.replaces: original=object
		var foot:=oracle.vector(placement.foot_px)
		if placement.id=="assembled_east_service_annex":
			if not check(id=="ch4_s1_luoyang_yamen" and oracle.vector(original.world_foot_px)==Vector2(2640,1210) and foot==Vector2(2610,1210) and oracle.vector(placement.expected_parent_foot_px)==Vector2(2640,1210) and oracle.vector(placement.render_foot_px)==foot and oracle.vector(placement.render_foot_delta_px)==Vector2(-30,0) and placement.scale==.46,"Only authorized east visual delta; old record/solid2640 unchanged"): return false
		elif not check(not original.is_empty() and oracle.vector(original.world_foot_px)==foot,"Every other replacement keeps exact original foot"): return false
	var mask:=Image.load_from_file(parent.walk_path)
	if not check(oracle.configure_record(record,mask,independent),"Independent combined old native solids + all new physical deltas + original mask"): return false
	var routes: Array=record.routes.duplicate(true)
	routes.append_array(spec.required_routes)
	routes.append_array(spec.get("protected_routes",[]))
	for category: String in ["portals"]:
		for slot: Dictionary in record.gameplay_slots.get(category,[]): routes.append({"id":"portal_"+String(slot.source_id),"points_px":slot.passage_path_px})
	var route_samples:=0
	for route: Dictionary in routes:
		var answer:=oracle.path(route.points_px,false,deadline)
		if not check(answer.clear,"Independent complete combined original route/portal path "+String(route.id),answer): return false
		route_samples+=int(answer.samples)
	var new_count:=0; var old_count:=0; var npc_samples:=0
	for person: Dictionary in spec.crowd:
		var foot:=oracle.vector(person.foot_px); var travel:=Vector2(float(person.get("distance_px",0)),0)
		var answer:=oracle.path([foot-travel,foot+travel],true,deadline)
		if not check(answer.clear,"All16 authored NPC continuous34x30/1085mask/17/<=4px "+String(person.id),answer): return false
		npc_samples+=int(answer.samples); new_count+=1
	if id in ["ch4_s0_luoyang_gate","ch4_s2_canal_docks"]:
		# Independently derive preserved10 lanes from old immutable source rows,
		# not the new production audit or new geometry's returned paths.
		for row: Array in OLD_CROWD.spec(StringName(id)):
			var foot:=oracle.vector(row[2]); var travel:=Vector2(float(row[3]),0)
			var answer:=oracle.path([foot-travel,foot+travel],true,deadline)
			if not check(answer.clear,"Preserved oldHarbour20 lanes full combined geometry "+String(row[0]),answer): return false
			npc_samples+=int(answer.samples); old_count+=1
	var protected: Array=[record.entry_foot_px,record.return_foot_px]
	for category: String in ["interactions","npcs","portals"]:
		for slot: Dictionary in record.gameplay_slots.get(category,[]):
			protected.append(slot.get("stand_px",slot.get("foot_px",[])))
			if category=="portals": protected.append(slot.arrival_foot_px)
	protected.append_array(spec.protected_feet)
	var delta_only:=RAW.new()
	if not check(delta_only.configure_record(record,null,independent,true),"Separate explicit delta-only guard for original occupied NPC foot"): return false
	for foot: Variant in protected:
		if not check(delta_only.npc_clear(oracle.vector(foot)),"No new solid on any original/task/portal/return/approach anchor "+str(foot)): return false
	var expected_count:=10 if id=="ch4_s3_luoyang_market" else (6 if id=="ch4_s1_luoyang_yamen" else 0)
	if not check(new_count==expected_count and old_count==(10 if id in ["ch4_s0_luoyang_gate","ch4_s2_canal_docks"] else 0),"Exact16 new and20 preserved identities, not definition inflation"): return false
	records.append({"kind":"INDEPENDENT_DELTA_COMBINED_GEOMETRY","id":id,"new_entities":independent.size(),"new_npcs":new_count,"old_harbour_npcs":old_count,"route_samples":route_samples,"npc_samples":npc_samples,"protected_anchors":protected.size(),"native_physics_not_run":true,"production_audit_not_used_as_oracle":true})
	return true
func exercise_cpu() -> bool:
	if not _closed_boundary_cases(): return false
	if not _textures(): return false
	for id: String in author.districts:
		if not _district(id): return false
	return true
func _closed_boundary_cases() -> bool:
	var poly:=PackedVector2Array([Vector2(100,100),Vector2(160,100),Vector2(160,160),Vector2(100,160)])
	var probe:=RAW.new()
	if not probe.configure_record({"objects":[]},null,{"box":[poly]},true): return check(false,"Independent closed-boundary unit setup")
	var cases: Array=[
		{"id":"right_edge_touch","foot":Vector2(83,130),"clear":false},
		{"id":"bottom_edge_touch","foot":Vector2(130,88),"clear":false},
		{"id":"right_bottom_corner_touch","foot":Vector2(83,88),"clear":false},
		{"id":"left_edge_touch","foot":Vector2(177,130),"clear":false},
		{"id":"top_edge_touch","foot":Vector2(130,172),"clear":false},
		{"id":"rounded875_only_touch","foot":Vector2(82.999,88),"clear":false},
		{"id":"outside_one_pixel","foot":Vector2(82,88),"clear":true},
		{"id":"inside","foot":Vector2(130,130),"clear":false}]
	for item: Dictionary in cases:
		var independent: bool=probe.clear(item.foot)
		var production: bool=G.safe_foot([poly],item.foot,Vector2(17,12),true)
		if not check(independent==item.clear and production==independent,"Discrete875 oracle vs optimized full predicate: "+String(item.id),{"independent":independent,"production":production}): return false
	var white:=Image.create(3072,2048,false,Image.FORMAT_RGBA8); white.fill(Color.WHITE)
	for item: Dictionary in [{"id":"npc_right_bottom_touch","foot":Vector2(83,85),"clear":false},{"id":"npc_rounded_only_touch","foot":Vector2(82.999,85),"clear":false},{"id":"npc_outside_one_pixel","foot":Vector2(82,85),"clear":true}]:
		var independent: bool=probe.npc_clear(item.foot)
		var production: bool=G._npc_clear(item.foot,white,[poly])
		if not check(independent==item.clear and production==independent,"Discrete1085+87517 vs optimized NPC predicate: "+String(item.id),{"independent":independent,"production":production}): return false
	records.append({"kind":"INDEPENDENT_FULL875_CLOSED_BOUNDARY_CASES","count":cases.size()+3,"production_fullfalse_not_substituted":true})
	return true
func _run() -> void:
	var began:=Time.get_ticks_msec(); deadline=began+60000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true); players_before=saves()
	var complete:=false
	if precheck(): complete=exercise_cpu()
	finish("res://build/luoyang_city_life_cpu_20261016f/%d_%d"%[OS.get_process_id(),began],began,complete,"FOUR_DISTRICT_DELTA_COMBINED_CPU_NO_FIELD")
