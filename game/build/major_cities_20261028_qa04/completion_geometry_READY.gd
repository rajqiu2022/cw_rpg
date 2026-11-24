extends SceneTree
## Candidate Author mathematics only: no Field/PNG load, no scene switch/import.
const FIXTURE := "res://build/major_cities_20261028_qa04/completion_geometry_READY.json"
const OUTPUT := "res://build/major_cities_20261028_qa04/actual/"
var checks := 0
var errors: Array[String] = []
var details: Array = []
var began := 0
var spec: Dictionary = {}
var bodies: Array[Dictionary] = []
var before: Dictionary = {}
var saves_before: Dictionary = {}

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok: errors.append(label)
	return ok

func vec(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))

func rect(raw: Array) -> Rect2:
	return Rect2(float(raw[0]),float(raw[1]),float(raw[2]),float(raw[3]))

func facts(paths: Array) -> Dictionary:
	var out: Dictionary = {}
	for path: String in paths:
		var file := FileAccess.open(path,FileAccess.READ)
		out[path] = {"sha256":FileAccess.get_sha256(path),"bytes":file.get_length() if file != null else -1,"mtime_seconds":FileAccess.get_modified_time(path)}
	return out

func actor(foot: Vector2) -> Rect2:
	return Rect2(foot-Vector2(17,12),Vector2(34,24))

func independent_safe(foot: Vector2, include_npcs: bool = true) -> bool:
	var box := actor(foot)
	if not Rect2(80,80,5984,5984).encloses(box): return false
	for row: Dictionary in bodies:
		if not include_npcs and row.get("npc",false): continue
		if row.has("body") and box.intersects(row.body,true): return false
		if row.has("polygon"):
			var corners := PackedVector2Array([box.position,Vector2(box.end.x,box.position.y),box.end,Vector2(box.position.x,box.end.y)])
			if not Geometry2D.intersect_polygons(corners,row.polygon).is_empty(): return false
	return true

func projected(uv: Vector2, rows: Array) -> Variant:
	for row: Dictionary in rows:
		if actor(uv*Vector2(6144,6144)).intersects(row.body,true):
			var foot: Vector2 = row.migration_lane_foot
			return foot/Vector2(6144,6144) if independent_safe(foot) else null
	return uv

func _run() -> void:
	began=Time.get_ticks_msec()
	var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	if not check(raw is Dictionary and raw.get("ready")==true,"FROZEN_GEOMETRY_ONLY_FIXTURE"): finish(); return
	spec=raw
	check(spec.media_status=="PENDING_RGBA_IMPORT","EXPLICIT_NO_MEDIA_ADMISSION")
	before=facts(spec.fixed_sources.keys())
	for path: String in spec.fixed_sources: check(before[path].sha256==spec.fixed_sources[path],"PIN:"+path)
	var baseline: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.baseline))
	saves_before=facts(baseline.save15.keys())
	var platform: Node=root.get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	if not errors.is_empty(): finish(); return
	var author: Variant=load(spec.author)
	var prior: Variant=load(spec.prior_author)
	if not check(author!=null and prior!=null and author.VERSION==30 and prior.VERSION==29,"AUTHOR_ONLY_VERSION29_TO30"): finish(); return
	var all: Array=author.building_specs(); all.append_array(author.prop_specs())
	var ids: Dictionary={}
	for row: Dictionary in all:
		check(not ids.has(row.id),"UNIQUE_ENTITY:"+String(row.id)); ids[row.id]=true
		bodies.append({"id":row.id,"body":row.body})
	var gate: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.gate_binding))
	for raw_body: Dictionary in gate.blockers:
		if raw_body.has("rect"): bodies.append({"id":raw_body.id,"body":rect(raw_body.rect)})
		elif raw_body.has("polygon"):
			var polygon:=PackedVector2Array()
			for p: Array in raw_body.polygon: polygon.append(vec(p))
			bodies.append({"id":raw_body.id,"polygon":polygon})
	var npcs: Array=author.npc_rows()
	var prior_npcs: Dictionary={}
	for npc: Dictionary in prior.npc_rows(): prior_npcs[npc.npc_id]=npc
	var patrol_count:=0
	for npc: Dictionary in npcs:
		var foot: Vector2=npc.pos*author.SIZE
		var half_sweep: Vector2=(npc.get("patrol_axis",Vector2.RIGHT) as Vector2).abs()*float(npc.get("patrol_distance",0))
		var envelope:=Rect2(foot-Vector2(17,0)-half_sweep,Vector2(34,32)+half_sweep*2)
		if npc.has("protection_body"):
			check(npc.protection_body==envelope,"FULL_PATROL_ENVELOPE:"+String(npc.npc_id))
			var collisions: Array=[]
			for static_body: Dictionary in bodies:
				if static_body.get("npc",false): continue
				if static_body.has("body") and envelope.intersects(static_body.body): collisions.append(static_body.id)
			check(collisions.is_empty(),"NEW_NPC_FULL_SWEEP_OFF_STATIC_BODY:"+String(npc.npc_id)+":"+str(collisions))
			bodies.append({"id":npc.npc_id,"body":envelope,"npc":true})
		else: bodies.append({"id":npc.npc_id,"body":Rect2(foot-Vector2(17,12),Vector2(34,24)),"npc":true})
		if float(npc.get("patrol_distance",0))>0:
			patrol_count+=1
			check(String(npc.get("walk_sprite_path","")).length()>0 and npc.get("movement_mode")=="patrol","REAL_WALK_BINDING_NOT_SLIDING_IDLE:"+String(npc.npc_id))
		if String(npc.npc_id) in ["bianzhou_postmaster","bianzhou_merchant"]:
			check(npc==prior_npcs[npc.npc_id] and independent_safe(foot,false),"ORIGINAL_FUNCTIONAL_NPC_REACHABLE:"+String(npc.npc_id))
	check(npcs.size()==int(spec.npc_count) and patrol_count==int(spec.patrol_count),"FROZEN_NEW_ROLE_AND_PATROL_COUNTS")
	var domains: Array=author.completion_occupancy_rows()
	check(domains.size()==int(spec.domain_count),"FROZEN_INCREMENTAL_DOMAIN_COUNT")
	for original29_domain: Dictionary in author.new_occupancy_rows():
		check(independent_safe(original29_domain.migration_lane_foot) and author.safe_foot(original29_domain.migration_lane_foot/author.SIZE),"ORIGINAL16_LANE_REMAINS_SAFE_IN30:"+String(original29_domain.id))
	var domain_ids: Dictionary={}
	for row: Dictionary in domains:
		domain_ids[row.id]=true
		check((row.body as Rect2).size.x>0 and (row.body as Rect2).size.y>0 and independent_safe(row.migration_lane_foot),"POSITIVE_DOMAIN_REGISTERED_SAFE_LANE:"+String(row.id))
		var box: Rect2=row.body
		var feet: Array[Vector2]=[box.get_center(),Vector2(box.position.x-17,box.get_center().y),Vector2(box.end.x+17,box.get_center().y)]
		var phase29_ok:=true
		for foot: Vector2 in feet:
			var uv: Vector2=foot/author.SIZE
			if author.migration(uv,29)!=projected(uv,domains): phase29_ok=false
		check(phase29_ok,"29_DOMAIN_CENTER_AND_FULL_ACTOR_EDGES:"+String(row.id))
		var center_uv: Vector2=box.get_center()/author.SIZE
		check(author.migration(center_uv,30)==center_uv,"30_NO_SILENT_MIGRATION:"+String(row.id))
		var stage28: Variant=projected(center_uv,author.new_occupancy_rows())
		var expected28: Variant=projected(stage28,domains) if stage28 is Vector2 else null
		check(author.migration(center_uv,28)==expected28,"28_ORIGINAL16_THEN_NEW_DOMAINS:"+String(row.id))
	# Only genuinely changed presentation bodies must be registered, not all old safe points.
	var old_rows: Dictionary={}
	for row: Dictionary in prior.building_specs()+prior.prop_specs(): old_rows[row.id]=row
	var changed: Array=[]
	for row: Dictionary in all:
		if not old_rows.has(row.id) or row.body!=old_rows[row.id].body:
			changed.append(row.id); check(domain_ids.has(row.id),"CHANGED_ENTITY_EXPLICITLY_REGISTERED:"+String(row.id))
	for npc: Dictionary in npcs:
		if not prior_npcs.has(npc.npc_id) or npc.pos!=prior_npcs[npc.npc_id].pos:
			check(domain_ids.has(npc.npc_id),"NEW_OR_MOVED_NPC_EXPLICITLY_REGISTERED:"+String(npc.npc_id))
	var completion: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(spec.completion_binding))
	for row: Dictionary in author.completion_specs("building")+author.completion_specs("prop"):
		var source: Rect2=row.source_body_px
		var expected:=Rect2(row.foot+(source.position-vec(row.source_foot_px))*float(row.native_scale),source.size*float(row.native_scale))
		check(row.body==expected,"SOURCE_BOUNDS_EXACT_NATIVE_TRANSFORM:"+String(row.id))
	for wall: Dictionary in gate.objects:
		if not wall.has("source_body_region_px"): continue
		var local: Rect2=rect(wall.source_body_region_px)
		var expected:=Rect2(vec(wall.foot)+(local.position-vec(wall.source_foot_px))*float(wall.native_scale),local.size*float(wall.native_scale))
		check(body_by_id(wall.id).is_equal_approx(expected),"WALL_NATIVE_REGION_BODY_TRANSFORM:"+String(wall.id))
		check(float(wall.native_scale)>0 and not wall.has("rotation") and not wall.has("rotation_degrees"),"NO_ROTATED_OR_NONUNIFORM_FRONT_WALL:"+String(wall.id))
	check(completion.assets==spec.source_contracts,"FROZEN_SOURCE_BODY_CONTRACTS_NOT_INFERRED_FROM_ACTUAL")
	for sample: Array in spec.unaffected_feet:
		var uv: Vector2=vec(sample)/author.SIZE
		check(independent_safe(vec(sample)) and author.migration(uv,29)==uv,"LIMITED_UNAFFECTED_ENTRY_OR_SERVICE_FOOT:"+str(sample))
	for unknown: int in [0,27,31]: check(author.migration(Vector2(.5,.5),unknown)==null,"UNKNOWN_VERSION_REJECT:"+str(unknown))
	for old_uv: Array in spec.v1_feet:
		var uv: Vector2=vec(old_uv)
		var old_projection: Variant=prior._legacy_street_projection(uv,1)
		check(old_projection is Vector2 and author.migration(uv,1)==author.migration(old_projection,28),"V1_AFFINE_THEN_INCREMENTAL")
	for route: Dictionary in spec.routes: check_route(route,author)
	for relation: Dictionary in spec.wall_connections:
		var first: Rect2=body_by_id(String(relation.a)); var second: Rect2=body_by_id(String(relation.b))
		check(first.size!=Vector2.ZERO and second.size!=Vector2.ZERO and first.grow(.001).intersects(second,true),"ACTUAL_REGISTERED_WALL_CONNECTION:"+String(relation.id))
	var newer: Resource=author.layout(); var older: Resource=prior.layout()
	check(newer.get("portals")==older.get("portals") and newer.get("interactions")==older.get("interactions"),"ORIGINAL_DESTINATIONS_AND_BUSINESS_BINDING_NOT_REPLAYED")
	details.append({"new_or_changed_entities":changed,"domain_count":domains.size(),"npc_count":npcs.size(),"media_status":spec.media_status,"route_count":spec.routes.size(),"no_field_or_texture_load":true})
	finish()

func body_by_id(id: String) -> Rect2:
	for row: Dictionary in bodies:
		if String(row.id)==id and row.has("body"): return row.body
	return Rect2()

func check_route(route: Dictionary, author: Variant) -> void:
	var points: Array=route.points
	for i: int in range(points.size()-1):
		var a: Vector2=vec(points[i]); var b: Vector2=vec(points[i+1])
		if not check(a.x==b.x or a.y==b.y,"AXIS_ALIGNED_CONNECTION:"+String(route.id)): continue
		# Exact Minkowski sweep, not thousands of arbitrary pixel samples.
		var sweep:=Rect2(Vector2(minf(a.x,b.x),minf(a.y,b.y))-Vector2(17,12),(a-b).abs()+Vector2(34,24))
		var collisions: Array=[]
		for row: Dictionary in bodies:
			if row.has("body") and sweep.intersects(row.body,true): collisions.append(row.id)
			elif row.has("polygon"):
				var corners:=PackedVector2Array([sweep.position,Vector2(sweep.end.x,sweep.position.y),sweep.end,Vector2(sweep.position.x,sweep.end.y)])
				if not Geometry2D.intersect_polygons(corners,row.polygon).is_empty(): collisions.append(row.id)
		check(collisions.is_empty(),"CONTINUOUS_FULL34X24_CONNECTION:"+String(route.id)+":"+str(i)+":"+str(collisions))
		check(author.safe_foot(a/author.SIZE) and independent_safe(a),"CONNECTION_ENDPOINT_ORACLE:"+String(route.id))

func finish() -> void:
	if not before.is_empty(): check(before==facts(before.keys()),"SMALL_FROZEN_SOURCES_FIRST_FINAL")
	if not saves_before.is_empty(): check(saves_before==facts(saves_before.keys()),"SAVE15_UNCHANGED_ROOT_PRECISE_TICKS_SEPARATE")
	var path: String=OUTPUT+str(OS.get_process_id())+"/geometry_result.json"
	if FileAccess.file_exists(path): quit(2); return
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: quit(2); return
	file.store_string(JSON.stringify({"passed":errors.is_empty(),"checks":checks,"errors":errors,"elapsed_ms":Time.get_ticks_msec()-began,"details":details,"fixture_sha256":FileAccess.get_sha256(FIXTURE),"media_status":spec.get("media_status","UNAVAILABLE"),"actual_gameplay":false,"png_count":0,"save_writes":0,"field_or_texture_loads":0},"\t")); file.close()
	print("[BianzhouCompletionGeometry] "+str(checks)+" checks / "+str(errors.size())+" failures; "+path)
	quit(0 if errors.is_empty() else 1)
