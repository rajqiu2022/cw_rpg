extends "res://tests/helpers/joint_v15_v9c_world_object_input_probe.gd"
## DISTINCT RELEASE scope. Original exhaustive FULL probe and every failure remain immutable.
## All inventory geometry/PNG and own-RID forbidden cores are actual; only ordinary input is stratified.
const RELEASE_ORIGIN_PATH: String = "res://tests/helpers/joint_v15_v9c_world_object_input_probe.gd"
const RELEASE_ORIGIN_SHA: String = "777ce5e66b5f8a284a4b2335136e6373a1cab37cdfb07f2bdf7df7536bf53f47"
const SELECTION_PATH: String = "res://build/joint_world_luoyang_20261003_qa/release_selection_root234_20261005_01/representative_selection.json"
const SELECTION_SHA: String = "34a6ffd4b6da7adfc953c7339e1398c5a77e6f112399e4361350050246c4704f"
var release_selection: Dictionary = {}
var static_inventory: Array[Dictionary] = []
var selected_ids: Array[String] = []
var release_geometries: Dictionary = {}
var release_blocking_cores: int = 0

func _read_selection() -> bool:
	if not _check(FileAccess.get_sha256(RELEASE_ORIGIN_PATH).to_lower()==RELEASE_ORIGIN_SHA,"immutable exhaustive probe origin exactSHA"): return false
	if not _check(FileAccess.get_sha256(SELECTION_PATH).to_lower()==SELECTION_SHA,"preexecution selection exactSHA, never replace a failed representative"): return false
	var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(SELECTION_PATH))
	if not _check(parsed is Dictionary,"selection parses as object"): return false
	release_selection=parsed
	var header: bool=release_selection.get("scope")=="PREEXECUTION_FIXED_RISK_STRATIFIED_SELECTION_NOT_TEST_RESULT" and release_selection.get("object_count")==2687 and release_selection.get("blocking_count")==2322 and release_selection.get("unique_png_sha_count")==44 and release_selection.get("selection_replacement_after_failure_permitted")==false
	if not _check(header,"exact declared release inventory and no postfailure reselection"): return false
	var actual: Dictionary={}
	var source_data: Dictionary=phase.get("source")
	for row: Dictionary in source_data.get("objects",[]):
		if not _check(not actual.has(String(row.id)),"current source unique all-inventory ID"): return false
		actual[String(row.id)]=row
	var bound: Dictionary={}
	for expected: Dictionary in release_selection.get("all_bindings",[]):
		var id: String=String(expected.get("id",""))
		var same: bool=not bound.has(id) and actual.has(id)
		if same:
			var current: Dictionary=actual[id]
			for key: String in expected:
				if key=="texture_sha256": continue
				same=same and current.has(key) and _release_binding_value_equal(key,current.get(key),expected[key])
			var current_sha: String=String((source_data.get("asset_sha256",{}) as Dictionary).get(String(current.get("texture","")),"")).to_lower()
			same=same and current_sha==expected.texture_sha256
		_check(same,"every frozen object semantic/spatial/PNG identity equals current capture, material-only Source SHA may differ: "+id)
		bound[id]=expected
	_check(bound.size()==2687 and actual.size()==2687,"exact inventory includes all current and frozen2687 IDs")
	var families: Dictionary={}
	var pngs: Dictionary={}
	for group: Dictionary in release_selection.get("png_groups",[]):
		var members: Dictionary={}
		for id: String in group.get("ids",[]):
			_check(bound.has(id) and String((bound.get(id,{}) as Dictionary).get("texture_sha256",""))==String(group.get("sha256","")),"exact PNG class membership: "+id)
			members[id]=true
		pngs[String(group.get("sha256",""))]=members
	var selected_pngs: Dictionary={}
	for row: Dictionary in release_selection.get("representatives",[]):
		var id: String=String(row.get("id",""))
		var valid: bool=bound.has(id) and not id in selected_ids and not row.get("reasons",[]).is_empty() and row.get("texture_sha256")==(bound.get(id,{}) as Dictionary).get("texture_sha256")
		_check(valid,"fixed representative identity/reasons cannot be substituted: "+id)
		selected_ids.append(id)
		selected_pngs[String(row.get("texture_sha256",""))]=true
		families[String(row.get("family",""))]=true
	_check(pngs.size()==44 and selected_pngs.size()==44 and families.size()==8 and selected_ids.size()==130,"all44 PNG classes/8families and exact130 preselected risk placements")
	return failures==0

func _release_binding_value_equal(key: String,actual: Variant,expected: Variant) -> bool:
	if key!="collision_offset": return actual==expected
	# Independent QA native-value oracle: this specific field is consumed as
	# Vector2. Require all native bits, not decimal epsilon or a new selection.
	if not actual is Array or actual.size()!=2 or not expected is Array or expected.size()!=2: return false
	for index in 2:
		if typeof(actual[index]) not in [TYPE_INT,TYPE_FLOAT] or typeof(expected[index]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(actual[index])) or not is_finite(float(expected[index])): return false
	var actual_native:=Vector2(float(actual[0]),float(actual[1]))
	var expected_native:=Vector2(float(expected[0]),float(expected[1]))
	return actual_native.is_finite() and expected_native.is_finite() and var_to_bytes(actual_native)==var_to_bytes(expected_native)

func _own_forbidden_core(id: String,geometry: Dictionary) -> Dictionary:
	var player: Node2D=field.get("_player") as Node2D
	var container: Node2D=field.get("world_container") as Node2D
	var body_shape: CollisionShape2D=player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if not _check(is_instance_valid(player) and player.is_inside_tree() and tree.current_scene==field and body_shape!=null and body_shape.shape!=null,"live actual Player shape/currentField before forbidden-core query: "+id): return {"passed":false}
	var expected_rids: Dictionary={}
	for shape: Dictionary in geometry.get("actual_shapes",[]): expected_rids[int(shape.rid)]=true
	var tried: Array[Dictionary]=[]
	for polygon: PackedVector2Array in geometry.get("source_polygons",[]):
		var indices: PackedInt32Array=Geometry2D.triangulate_polygon(polygon)
		for index in range(0,indices.size(),3):
			var center: Vector2=(polygon[indices[index]]+polygon[indices[index+1]]+polygon[indices[index+2]])/3
			if not Geometry2D.is_point_in_polygon(center,polygon): continue
			var evidence: Dictionary=raw.call("foot_evidence",center)
			var query:=PhysicsShapeQueryParameters2D.new()
			query.shape=body_shape.shape
			query.transform=body_shape.global_transform
			query.transform.origin+=container.to_global(center)-player.global_position
			query.collision_mask=int(player.get("collision_mask"))
			query.exclude=[player.call("get_rid")]
			query.collide_with_areas=false
			# Maximum exceeds the entire2687-object inventory; crowded hits cannot hide own RID.
			var hits: Array[Dictionary]=player.get_world_2d().direct_space_state.intersect_shape(query,4096)
			var hit_rows: Array[Dictionary]=[]
			var own: bool=false
			for hit: Dictionary in hits:
				var rid: RID=hit.get("rid",RID())
				var collider: Object=hit.get("collider")
				var rid_id: int=rid.get_id()
				own=own or expected_rids.has(rid_id)
				hit_rows.append({"rid":rid_id,"path":str((collider as Node).get_path()) if collider is Node else str(collider),"own_object_rid":expected_rids.has(rid_id)})
			var row: Dictionary={"core_px":[center.x,center.y],"raw_full17":evidence,"hits":hit_rows,"own_rid_hit":own,"player_shape_class":body_shape.shape.get_class(),"player_shape_transform":str(body_shape.global_transform),"query_transform":str(query.transform),"player_was_not_moved":true}
			tried.append(row)
			if own and evidence.get("clear")==false:
				_check(true,"own object RID, not neighbor, blocks independently forbidden complete17 core: "+id)
				return {"passed":true,"matched":row,"tried_count":tried.size()}
	_check(false,"blocking object has no attributable actual Physics/complete17 forbidden core: "+id)
	return {"passed":false,"tried":tried}

func run(owner: RefCounted) -> Dictionary:
	phase=owner
	tree=phase.get("owner_tree") as SceneTree
	driver=phase.get("input_driver") as RefCounted
	raw=phase.get("oracle") as RefCounted
	if not _read_selection(): return _finish()
	var world: SceneScript=phase.get("world") as SceneScript
	if not _check(bool(await phase.call("_open_owned_world_fixture",world.player_spawn*SIZE)),"normal whole-world Field for full inventory and release representatives"): return _finish()
	field=phase.get("field")
	var container: Node2D=field.get("world_container") as Node2D
	for entry: Dictionary in world.map_layout.visual_objects:
		var id: String=String(entry.get("id",""))
		_check(not id.is_empty() and not entries.has(id),"unique published inventory ID: "+id)
		entries[id]=entry
	for sprite: Sprite2D in field.get("_scene_object_nodes"):
		if not String(sprite.name).begins_with("SceneObject_"): continue
		var id: String=String(sprite.name).trim_prefix("SceneObject_")
		_check(entries.has(id) and not props.has(id),"runtime current inventory identity: "+id)
		props[id]=sprite
	_check(props.size()==2687 and entries.size()==2687,"all2687 actual Sprite identities, not selected-only runtime")
	var frozen: Dictionary={}
	for row: Dictionary in release_selection.get("all_bindings",[]): frozen[String(row.id)]=row
	for id: String in entries:
		if not props.has(id): continue
		var entry: Dictionary=entries[id]
		var sprite: Sprite2D=props[id]
		var texture_path: String=String(entry.get("texture",""))
		var sha: String=FileAccess.get_sha256(texture_path).to_lower()
		_check(texture_path.begins_with(ROOT) and sprite.texture!=null and sprite.texture.resource_path==texture_path and sha==String((frozen.get(id,{}) as Dictionary).get("texture_sha256","")),"each actual current PNG matches frozen44-group identity: "+id)
		_check(container.to_local(sprite.global_position).distance_to(_p(entry.pos)*SIZE)<.01 and (sprite.get_rect().size*sprite.scale.abs()).distance_to(_p(entry.render_size_px))<.01 and sprite.texture_filter==CanvasItem.TEXTURE_FILTER_LINEAR,"original actual render position/size/LINEAR contract: "+id)
		var geometry: Dictionary=_physical_inventory(entry,sprite)
		release_geometries[id]=geometry
		_check(bool(geometry.blocking)==bool(entry.get("blocking",false)),"declared blocking agrees with own actual shapes: "+id)
		var forbidden: Dictionary={"blocking":false,"actual_body_absent":geometry.exact_binding}
		if bool(geometry.blocking):
			forbidden=_own_forbidden_core(id,geometry)
			if bool(forbidden.get("passed",false)): release_blocking_cores+=1
		else:
			_check(bool(geometry.exact_binding) and geometry.actual_shapes.is_empty(),"nonblocking inventory actually has no own collider: "+id)
		if not bool(entry.get("sort_by_feet",false)):
			var foot: float=float((field.get("_player") as Node2D).call("get_depth_sort_y"))
			_check(not bool(geometry.blocking) and sprite.z_index<clampi(floori(foot/8),0,1024),"every ground deck gives NO foreground/strong-alpha credit: "+id)
		static_inventory.append({"id":id,"texture":texture_path,"texture_sha256":sha,"geometry":geometry,"forbidden_core":forbidden})
	_check(static_inventory.size()==2687 and release_blocking_cores==2322,"all2687 actual bindings and all2322 own-RID forbidden cores, no missing-core waiver")
	# All sprites remain in props so inherited exact union includes unselected neighbors.
	for id: String in selected_ids:
		if not _check(entries.has(id) and props.has(id) and release_geometries.has(id),"fixed selected actual object exists: "+id): continue
		var entry: Dictionary=entries[id]
		var geometry: Dictionary=release_geometries[id]
		var collision: Dictionary=await _collision_trial(id,geometry) if bool(geometry.blocking) else {"blocking":false,"actual_body_absent":geometry.exact_binding}
		var visibility: Dictionary={}
		if bool(entry.get("sort_by_feet",false)): visibility=await _alpha_trial(entry,props[id])
		else: visibility={"scope":"GROUND_VISUAL_NO_FOREGROUND_CREDIT","complete":not bool(geometry.blocking),"support_walk_proof":"ORIGINAL_BRIDGE_AND_ALL27_ROUTE_PHASES_REQUIRED"}
		records.append({"id":id,"geometry":geometry,"collision":collision,"current_alpha":visibility})
	return _finish()

func _finish() -> Dictionary:
	_check(FileAccess.get_sha256(SELECTION_PATH).to_lower()==SELECTION_SHA,"same fixed selection through entire actual release input")
	var complete: bool=failures==0 and static_inventory.size()==2687 and release_blocking_cores==2322 and records.size()==130
	var report: Dictionary={"scope":"RELEASE_ALL_INVENTORY_PHYSICS_AND_FIXED_RISK_REPRESENTATIVE_NORMAL_INPUT_NOT_EXHAUSTIVE_FULL","checks":checks,"failures":failures,"release_complete":complete,"complete":false,"legacy_full_executed":false,"exhaustive_2687_normal_input_executed":false,"selection_path":SELECTION_PATH,"selection_sha256":SELECTION_SHA,"object_ids":entries.keys(),"static_inventory_count":static_inventory.size(),"attributed_forbidden_core_count":release_blocking_cores,"unique_png_sha_count":44,"families":release_selection.get("families",[]),"representative_ids":selected_ids.duplicate(),"representative_count":records.size(),"selection_reasons":release_selection.get("representatives",[]),"static_inventory":static_inventory.duplicate(true),"records":records.duplicate(true),"executing_script_path":get_script().resource_path,"executing_script_sha256":FileAccess.get_sha256(get_script().resource_path),"visual_approved":false}
	_check(bool(phase.call("_write_json","release_inventory_and_representatives.json",report)),"all release inventory and fixed input evidence checked readback")
	report.checks=checks
	report.failures=failures
	report.release_complete=complete and failures==0
	if alpha!=null: alpha.call("release")
	alpha=null
	entries.clear()
	props.clear()
	release_geometries.clear()
	field=null
	driver=null
	raw=null
	phase=null
	tree=null
	return report

