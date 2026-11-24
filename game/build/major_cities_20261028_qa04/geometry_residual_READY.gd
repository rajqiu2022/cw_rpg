extends "res://build/major_cities_20261028_qa04/completion_geometry_READY.gd"
## Only the seven failed lanes and corrected road oracle; old whole FAIL stays.
const RESIDUAL_FIXTURE := "res://build/major_cities_20261028_qa04/geometry_residual_READY.json"

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(RESIDUAL_FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"FROZEN_SEVEN_LANES_ONLY"): finish(); return
	spec=raw; before=facts(spec.fixed_sources.keys())
	for path: String in spec.fixed_sources: check(before[path].sha256==spec.fixed_sources[path],"PIN:"+path)
	var previous: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.inherited_result))
	check(previous.passed==false and previous.checks==1122 and previous.errors.size()==8,"ORIGINAL_1122_WHOLE_FAIL_PRESERVED")
	var baseline: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.baseline))
	saves_before=facts(baseline.save15.keys())
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	if not errors.is_empty(): finish(); return
	var author: Variant=load(spec.author)
	if not check(author!=null and author.VERSION==30,"SAME_FROZEN_AUTHOR30_NO_FIELD_OR_PNG"): finish(); return
	var rows: Array=author.building_specs(); rows.append_array(author.prop_specs())
	for row: Dictionary in rows: bodies.append({"id":row.id,"body":row.body})
	var gate: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.gate_binding))
	for entry: Dictionary in gate.blockers:
		if entry.has("rect"): bodies.append({"id":entry.id,"body":rect(entry.rect)})
		else:
			var polygon:=PackedVector2Array()
			for p: Array in entry.polygon: polygon.append(vec(p))
			bodies.append({"id":entry.id,"polygon":polygon})
	for npc: Dictionary in author.npc_rows():
		bodies.append({"id":npc.npc_id,"body":npc.protection_body if npc.has("protection_body") else Rect2(npc.pos*author.SIZE-Vector2(17,12),Vector2(34,24)),"npc":true})
	var domains: Array=author.completion_occupancy_rows()
	for id: String in spec.corrected_lanes:
		var matching: Array=domains.filter(func(row: Dictionary) -> bool: return String(row.id)==id)
		if not check(matching.size()==1,"ONE_REGISTERED_FAILED_DOMAIN:"+id): continue
		var row: Dictionary=matching[0]; var lane: Vector2=vec(spec.corrected_lanes[id])
		check(row.migration_lane_foot==lane and independent_safe(lane) and author.safe_foot(lane/author.SIZE),"CORRECTED_LANE_INDEPENDENTLY_SAFE:"+id)
		var uv: Vector2=(row.body as Rect2).get_center()/author.SIZE
		check(author.migration(uv,29)==lane/author.SIZE and author.migration(uv,28)==lane/author.SIZE,"FAILED_CENTER_NOW_EXPLICIT_29_AND28_LANE:"+id)
	var ring: Array=author.roads().filter(func(row: Dictionary) -> bool: return String(row.id)=="west_ring")
	check(ring.size()==1 and ring[0].points==PackedVector2Array([Vector2(1450,880),Vector2(1450,4456)]),"WEST_RING_AUTHORED_END4456_NOT_QA_INVENTED4970")
	check_route({"id":"CORRECTED_ORACLE_WEST_RING_INSIDE_WALL","points":[[1450,1000],[1450,4456]]},author)
	var ground: Array=author.ground_patches().filter(func(row: Dictionary) -> bool: return String(row.id)=="metalwork_service_lane_real")
	check(ground.size()==1 and ground[0].polygon==PackedVector2Array([Vector2(1237,4552),Vector2(1333,4552),Vector2(1333,4840),Vector2(1630,4840),Vector2(1630,4896),Vector2(1237,4896)]) and ground[0].period==Vector2(512,512),"REAL_1285_BRANCH_PAVING_NO_NAV_REWRITE")
	details.append({"inherits_successful_components_from":spec.inherited_result,"original_whole_failure_preserved":true,"repeated_1122_matrix":false,"changed_physical_bodies":0,"seven_lane_targets":spec.corrected_lanes,"west_ring_failure_was_qa_oracle_error":true,"field_or_texture_loads":0})
	finish()

func finish() -> void:
	if not before.is_empty(): check(before==facts(before.keys()),"FROZEN_RESIDUAL_SOURCE_FIRST_FINAL")
	if not saves_before.is_empty(): check(saves_before==facts(saves_before.keys()),"SAVE15_SAME_ROOT_TICKS_SEPARATE")
	var path: String=OUTPUT+str(OS.get_process_id())+"/geometry_residual_result.json"
	if FileAccess.file_exists(path): quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(2); return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"details":details,"fixture_sha256":FileAccess.get_sha256(RESIDUAL_FIXTURE),"media_status":"PENDING_RGBA_IMPORT","actual_gameplay":false,"save_writes":0,"png_count":0},"\t")); file.close()
	print("[BianzhouGeometryResidual] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
