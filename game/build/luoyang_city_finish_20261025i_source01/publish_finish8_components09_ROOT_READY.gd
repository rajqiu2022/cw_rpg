extends SceneTree
# Root-only SOURCE publication. No Field, collector, old packet decode or routes.
# Independent geometry and local pixel expectations are comparisons, never inputs
# to deriving render/solids or choosing coordinates.
const READY: bool=true
const INPUT: String="res://build/luoyang_city_finish_20261025i_source01/finish8_publication_input09_ROOT_READY.json"
const INPUT_SHA: String="55752ce70d13a5077ca770df49ea6359086e5d7b75dd7e4140ae594d547e787a"
var config: Dictionary={}
var first: Dictionary={}
var saves: Dictionary={}
var checks: int=0
var errors: Array=[]
var outputs: Dictionary={}
var started: int=0
var out: String=""
var source_math: Variant
var payload_math: Variant
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: errors.append(label);printerr("FINISH8_PUBLICATION:",label)
	return ok
func sha(bytes: PackedByteArray) -> String:
	var h: HashingContext=HashingContext.new();h.start(HashingContext.HASH_SHA256);h.update(bytes);return h.finish().hex_encode()
func j(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return value if value is Dictionary else {}
func binary(path: String) -> Variant: return bytes_to_var(FileAccess.get_file_as_bytes(path))
func facts() -> Dictionary:
	var values: Dictionary={}
	for path: String in config.save_absolute_paths:
		if not FileAccess.file_exists(path): values[path]={"exists":false};continue
		var stream: FileAccess=FileAccess.open(path,FileAccess.READ)
		if stream==null: values[path]={"exists":true,"unreadable":true};continue
		var count: int=stream.get_length();stream.close()
		values[path]={"exists":true,"bytes":count,"sha256":FileAccess.get_sha256(path),"modified_seconds":FileAccess.get_modified_time(path)}
	return values
func save_bytes(path: String,value: PackedByteArray) -> Dictionary:
	if FileAccess.file_exists(path): return {}
	var stream: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	if stream==null: return {}
	stream.store_buffer(value);stream.close()
	if FileAccess.get_sha256(path)!=sha(value): return {}
	return {"path":path,"sha256":sha(value),"bytes":value.size()}
func finish() -> void:
	var last: Dictionary={}
	for path: String in first: last[path]=FileAccess.get_sha256(path)
	check(last==first,"COMPLETE_FIXED_SOURCE_FIRST_FINAL")
	var last_saves: Dictionary=facts() if not config.is_empty() else {}
	check(var_to_bytes(last_saves)==var_to_bytes(saves),"SAVE15_FIRST_FINAL_READONLY")
	var report: Dictionary={"status":"SOURCE_FINISH8_COMPONENTS_NOT_RUNTIME_OR_WHOLE_ART","complete":errors.is_empty() and outputs.size()==8,"passed":errors.is_empty() and outputs.size()==8,"checks":checks,"errors":errors.duplicate(true),"elapsed_ms":Time.get_ticks_msec()-started,"source_first":first,"source_final":last,"save_first":saves,"save_final":last_saves,"scenes":outputs,"packet_decodes":0,"collector_calls":0,"Field_calls":0,"route_replay_calls":0,"import_calls":0,"original_native_writes":0,"prior_claim":"Inherited exact independent components plus source-owned raster publication and six exact new-domain byte comparisons, not independent full new RGBA hashes."}
	if not out.is_empty(): save_bytes(out+"/result.json",(JSON.stringify(report,"\t")+"\n").to_utf8_buffer())
	print(JSON.stringify({"status":report.status,"passed":report.passed,"checks":checks,"errors":errors,"output":out}));quit(0 if report.passed else 1)
func image(path: String) -> Image:
	var result: Image=Image.load_from_file(path)
	if result==null or result.get_size()!=Vector2i(3072,2048): return null
	if result.get_format()==Image.FORMAT_RGB8: result.convert(Image.FORMAT_RGBA8)
	return result if result.get_format()==Image.FORMAT_RGBA8 and not result.has_mipmaps() else null
func shapes(rows: Array) -> Array:
	var result: Array=[]
	for row: Dictionary in rows: result.append(source_math.p(row.points_px))
	return result
func exact_shapes(actual: Array,expected: Array,label: String) -> bool:
	if not check(actual.size()==expected.size(),label+":COUNT"): return false
	for i: int in range(actual.size()):
		if not check(var_to_bytes(actual[i])==var_to_bytes(expected[i]),label+":"+str(i)): return false
	return true
func active(rows: Array,closed: Array) -> Array:
	var result: Array=[]
	for row: Dictionary in rows:
		var poly: PackedVector2Array=source_math.p(row.points_px)
		if poly.size()<3: continue
		var low: Vector2=poly[0];var high: Vector2=low
		for point: Vector2 in poly: low=low.min(point);high=high.max(point)
		if low.x<=float(closed[2]) and high.x>=float(closed[0]) and low.y<=float(closed[3]) and high.y>=float(closed[1]): result.append({"shape":poly,"low":low,"high":high,"kind":String(row.get("kind",""))})
	return result
func blocked(point: Vector2,rows: Array,half_open_native_rects: bool) -> bool:
	if point.x<24 or point.x>=3048 or point.y<24 or point.y>=2024: return true
	for row: Dictionary in rows:
		if row.kind=="AP_RECT_CEIL_LOW_FLOOR_HIGH_INCLUSIVE":
			if point.x>=ceili(row.low.x) and point.x<=floori(row.high.x) and point.y>=ceili(row.low.y) and point.y<=floori(row.high.y): return true
		elif half_open_native_rects and row.kind=="EXACT_EXISTING_CLOSED_RECT":
			if point.x>=ceili(row.low.x) and point.x<ceili(row.high.x) and point.y>=ceili(row.low.y) and point.y<ceili(row.high.y): return true
		elif point.x>=floori(row.low.x) and point.x<=ceili(row.high.x) and point.y>=floori(row.low.y) and point.y<=ceili(row.high.y) and Geometry2D.is_point_in_polygon(point,row.shape): return true
	return false
func domain_bytes(bytes: PackedByteArray,closed: Array) -> PackedByteArray:
	var value: PackedByteArray=PackedByteArray()
	for y: int in range(int(closed[1]),int(closed[3])+1):
		value.append_array(bytes.slice((y*3072+int(closed[0]))*4,(y*3072+int(closed[2])+1)*4))
	return value
func raster(parent: PackedByteArray,support: PackedByteArray,rows: Array,domains: Array,half_open_native_rects: bool,white_floor: bool=false) -> Dictionary:
	var after: PackedByteArray=parent.duplicate();var positions: PackedInt32Array=PackedInt32Array();var old: PackedByteArray=PackedByteArray();var visited: int=0
	var seen: Dictionary={}
	for closed: Array in domains:
		var prepared: Array=active(rows,closed)
		for y: int in range(int(closed[1]),int(closed[3])+1):
			if Time.get_ticks_msec()-started>int(config.whole_budget_ms): return {}
			for x: int in range(int(closed[0]),int(closed[2])+1):
				var pixel: int=y*3072+x
				if seen.has(pixel): continue
				seen[pixel]=true;visited+=1
				var offset: int=pixel*4;var black: bool=blocked(Vector2(x,y),prepared,half_open_native_rects)
				var next: PackedByteArray=PackedByteArray([0,0,0,255]) if black else (PackedByteArray([255,255,255,255]) if white_floor else support.slice(offset,offset+4))
				if parent.slice(offset,offset+4)!=next:
					positions.append(offset);old.append_array(parent.slice(offset,offset+4))
					for channel: int in range(4): after[offset+channel]=next[channel]
	var inverse: PackedByteArray=after.duplicate()
	for i: int in range(positions.size()):
		for channel: int in range(4): inverse[positions[i]+channel]=old[i*4+channel]
	if not check(inverse==parent,"SOURCE_RASTER_FULL_RGBA_INVERSE_AND_OUTSIDE_BYTES"): return {}
	return {"RGBA":after,"visited":visited,"changed":positions.size(),"inverse":{"byte_offsets":positions,"old_RGBA":old}}
func compare_domain(before: PackedByteArray,after: PackedByteArray,id: String,expected: Array) -> bool:
	for row: Dictionary in expected:
		if row.scene_id!=id: continue
		if not check(domain_bytes(before,row.closed_xyxy)==row.before_RGBA,"INDEPENDENT_DOMAIN_BEFORE:"+id+":"+str(row.closed_xyxy)): return false
		if not check(domain_bytes(after,row.closed_xyxy)==row.after_RGBA,"INDEPENDENT_DOMAIN_AFTER:"+id+":"+str(row.closed_xyxy)): return false
	return true
func named_from_polygons(polygons: Array) -> Array:
	var rows: Array=[]
	for index: int in range(polygons.size()): rows.append({"id":"source_shape_"+str(index),"kind":"SOURCE_POLYGON","points_px":polygons[index]})
	return rows
func schema_exact(a: Variant,b: Variant,path: Array=[]) -> bool:
	# Only explicitly named coordinate containers admit the approved Vector2f32
	# storage comparison. Non-coordinate schema/scalars remain exact and complete.
	var coordinate: bool=false
	for item: Variant in path:
		if String(item) in ["foot_px","source_ground_anchor_px","size_px","ground_polygon_px","floor_regions_px"]: coordinate=true
	if coordinate and a is Array and b is Array and a.size()==2 and b.size()==2 and typeof(a[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(a[1]) in [TYPE_INT,TYPE_FLOAT] and typeof(b[0]) in [TYPE_INT,TYPE_FLOAT] and typeof(b[1]) in [TYPE_INT,TYPE_FLOAT]:
		return var_to_bytes(source_math.v(a))==var_to_bytes(source_math.v(b))
	if typeof(a)!=typeof(b): return false
	if a is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not schema_exact(a[key],b[key],path+[key]): return false
		return true
	if a is Array:
		if a.size()!=b.size(): return false
		for index: int in range(a.size()):
			if not schema_exact(a[index],b[index],path+[str(index)]): return false
		return true
	return a==b
func run() -> void:
	started=Time.get_ticks_msec()
	if not READY or FileAccess.get_sha256(INPUT)!=INPUT_SHA: push_error("NOT_ROOT_READY_EXACT_INPUT");quit(2);return
	config=j(INPUT)
	if not check(config.get("ready")==true and not DirAccess.dir_exists_absolute(config.output_root),"ROOT_NEW_COMPONENT_OUTPUT_ONLY"): quit(2);return
	var platform: Node=get_root().get_node_or_null("PlatformBridge")
	if platform!=null: platform.call("set_checkpoint_saves_suspended",true)
	saves=facts()
	for path: String in config.sources:
		first[path]=FileAccess.get_sha256(path)
		if not check(first[path]==config.sources[path],"FIXED_INPUT_SOURCE:"+path): finish();return
	out=String(config.output_root)+"/"+str(OS.get_process_id())
	if not check(DirAccess.make_dir_recursive_absolute(out)==OK,"NEW_COMPONENT_DIRECTORY"): finish();return
	source_math=load(config.source_views);payload_math=load(config.payload_builder)
	var helpers: Dictionary={"axis":load(config.axis_helper),"artisan":load(config.artisan_helper),"temple":load(config.temple_builder),"adjacent":load(config.adjacent_helper),"payload":payload_math}
	for code: Variant in helpers.values():
		if not check(code is GDScript and code.can_instantiate(),"PUBLICATION_DEPENDENCY_LOAD"): finish();return
	if not check(source_math is GDScript and source_math.can_instantiate(),"SOURCE_VIEW_LOAD"): finish();return
	var inputs: Dictionary={}
	for field: String in config.json_inputs: inputs[field]=j(config.json_inputs[field])
	for field: String in config.binary_inputs: inputs[field]=binary(config.binary_inputs[field])
	inputs.craft=helpers.artisan.derive(inputs.artisan_old_author,inputs.artisan_life_author,inputs.artisan_author,inputs.processed_buildings)
	if not check(inputs.craft.get("ok")==true,"SOURCE_PROCESSED_ARTISAN_DERIVE"): finish();return
	var prior_low: Dictionary=j(config.priors.low.path)
	var prior_artisan: Dictionary=j(config.priors.artisan.path)
	var prior_adjacent: Dictionary=j(config.priors.adjacent.path)
	var prior_temple: Dictionary=j(config.priors.temple.path)
	var residual: Dictionary=j(config.priors.residual.path)
	var expected: Dictionary=binary(config.priors.residual.geometry_path)
	var artisan_expected: Dictionary=binary(config.priors.artisan.geometry_path)
	var low_expected: Dictionary=binary(config.priors.low.geometry_path)
	if not check(prior_low.get("passed")==true and prior_artisan.get("passed")==true and prior_temple.get("passed")==true and residual.get("passed")==true and expected.has_all(["geometry","domain_expected"]),"FIXED_INDEPENDENT_COMPONENTS_NOT_PARENT_WHOLE_FAIL_WASH"): finish();return
	for scene_spec: Dictionary in config.scenes:
		var id: String=String(scene_spec.id)
		if config.inherited_scenes.has(id):
			outputs[id]=config.inherited_scenes[id].duplicate(true)
			continue
		var original_source_scene: SceneScript=load(scene_spec.parent_scene) as SceneScript
		var original_layout: WalkableMapLayout=load(scene_spec.parent_layout) as WalkableMapLayout
		if not check(original_source_scene!=null and original_layout!=null,"FIXED_PACKET_PAIRED_NATIVE_RESOURCES:"+id): finish();return
		# B/Family materialize their fixed packet layout_storage, not a stale external reference.
		# This source expression copies only the Scene container; old stored artifacts remain untouched.
		var original: SceneScript=original_source_scene.duplicate(false) as SceneScript
		original.map_layout=original_layout
		var view: Dictionary=source_math.derive(id,original,inputs,helpers)
		if not check(view.get("ok")==true,"SOURCE_TERMINAL_VIEW:"+id):
			errors.append({"strict_source_diagnostic":source_math.diagnose(id,original,inputs,helpers)})
			finish();return
		if id in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen"]:
			if not check(var_to_bytes(view.named_ground)==var_to_bytes(expected.geometry[id]),"INDEPENDENT_FINAL_AXIS_TYPED_TABLE:"+id): finish();return
		elif id=="luoyang_artisan_residential_20261022ap":
			if not exact_shapes(view.effective_solids,shapes(artisan_expected.new44),"INDEPENDENT_ARTISAN_FINAL44_BITS"): finish();return
		elif id=="ch4_s4_ancient_temple":
			var independent: Dictionary=prior_temple.prior.expected_source_author
			if not check(schema_exact(independent,inputs.temple_author),"INDEPENDENT_TEMPLE_SOURCE_AUTHOR_SCHEMA"): finish();return
			var projected: Array=[]
			for base: Dictionary in independent.geometry.furniture_bases:
				var points: PackedVector2Array=source_math.p(base.ground_polygon_px)
				for index: int in range(points.size()): points[index]=(points[index]/Vector2(1536,1024))*Vector2(1920,1280)
				projected.append(points)
			if not exact_shapes(view.effective_solids,projected,"INDEPENDENT_TEMPLE_STORED_UV_FINAL_WORLD_BITS"): finish();return
		else:
			if not exact_shapes(shapes(view.named_ground),shapes(expected.geometry[id].new_appended),"INDEPENDENT_ADJACENT_NEW_SOURCE_BITS:"+id): finish();return
		var packed: Dictionary=payload_math.build(id,view.world_size_px,view.parent_native_navigation,view.parent_navigation,view.parent_blockers,view.parent_solids,view.effective_navigation,view.effective_solids,view.portal_before,view.portal_after,view.interaction_patches,view.npc_migrations,view.new_NPCs,view.effective_walkable_polygons)
		if not check(packed.get("ok")==true,"COMPLETE_VIEW_TYPED_INVERSE_PAYLOAD:"+id): finish();return
		packed.payload.new_route_contracts=[]
		for route: Dictionary in source_math.route_contracts():
			if route.source_id!=id: continue
			var portal: Dictionary=source_math.find(view.portal_after,String(route.source_portal_id))
			if not check(not portal.is_empty() and portal.target_pos==route.normalized,"SOURCE_AUTHORED_ROUTE_TARGET_ROW:"+id): finish();return
			packed.payload.new_route_contracts.append({"source_scene_id":route.source_id,"target_scene_id":route.target_id,"source_portal_id":route.source_portal_id,"source_foot_px":route.source_foot,"target_foot_px":route.target_foot,"expected_normalized":route.normalized,"source_target_pos":portal.target_pos,"source_portal_row":portal.duplicate(true),"kind":route.target_kind})
		packed.fingerprints.new_route_contracts=sha(var_to_bytes(packed.payload.new_route_contracts))
		var prefix: String=out+"/"+id
		if not check(DirAccess.make_dir_recursive_absolute(prefix)==OK,"NEW_SCENE_COMPONENT_DIRECTORY"): finish();return
		var media: Dictionary={"kind":"SOURCE_POLYGON_ONLY"};var raster_receipts: Array=[]
		if id!="ch4_s4_ancient_temple":
			var original_mask: Image=image(scene_spec.mask_parent.path)
			if not check(original_mask!=null and sha(original_mask.get_data())==scene_spec.mask_parent.RGBA_sha256,"FIXED_MASK_PARENT:"+id): finish();return
			var stage_before: PackedByteArray=original_mask.get_data();var support: PackedByteArray=stage_before.duplicate();var base: Dictionary={}
			if id in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen"]:
				var raw: Image=image(scene_spec.raw_support.path)
				if not check(raw!=null,"RAW_SUPPORT:"+id): finish();return
				support=raw.get_data()
				var low_source: Dictionary=source_math.scene_spec(inputs.axis_low_author,id)
				var low_rows: Array=[]
				for raw_row: Dictionary in low_source.new_all_primitive_rows_source_model:
					low_rows.append({"id":String(raw_row.id),"owner_id":String(raw_row.owner_id),"kind":String(raw_row.kind),"points_px":source_math.p(raw_row.points_px)})
				if not check(var_to_bytes(low_rows)==var_to_bytes(low_expected[id]),"SOURCE_LOW49_44_INDEPENDENT_TYPED_EXPECTATION:"+id): finish();return
				base=raster(stage_before,support,low_rows,prior_low.scenes[id].closed_domains_xyxy,true)
				if not check(not base.is_empty() and sha(base.RGBA)==prior_low.scenes[id].expected_child_RGBA_sha256,"INHERITED49_44_SOURCE_OWNED_PUBLICATION:"+id): finish();return
			elif id=="luoyang_artisan_residential_20261022ap":
				var source_craft_rows: Array=source_math.named_artisan(inputs.craft,inputs.artisan_old_author)
				if not exact_shapes(shapes(source_craft_rows),shapes(artisan_expected.new44),"SOURCE_DERIVED_ARTISAN_RASTER_ROWS"): finish();return
				base=raster(stage_before,support,source_craft_rows,prior_artisan.prior.closed_domains_xyxy,false,true)
				if not check(not base.is_empty() and sha(base.RGBA)==prior_artisan.prior.expected_child_RGBA_sha256 and base.changed==int(prior_artisan.prior.changed_pixels),"INDEPENDENT_ARTISAN_PIXEL_PRIOR"): finish();return
			else:
				var old_local: Dictionary=helpers.adjacent.derive(id,inputs.adjacent_old_author,inputs.adjacent_library,view.parent_navigation,source_math.find(inputs.craft.building_and_life_render,"new_plain_kitchen_rear_house"),view.parent_navigation if id=="ch4_s2_canal_docks" else [])
				if not check(old_local.get("ok")==true,"INHERITED22_SOURCE_OWNED_DERIVE:"+id): finish();return
				var old_added: Array=old_local.added_render.duplicate(true)
				if id=="luoyang_estate_riverside_20261021ai": old_added.pop_back()
				base=raster(stage_before,support,source_math.named_polygons(old_added),prior_adjacent.scenes[id].closed_domains_xyxy,false)
				if not check(not base.is_empty() and sha(base.RGBA)==prior_adjacent.scenes[id].expected_child_RGBA_sha256,"INHERITED22_EXACT_PIXEL_COMPONENT_NOT_ROUTE_WHOLE_PASS:"+id): finish();return
			var final_bytes: PackedByteArray=base.RGBA;var domains: Array=[]
			for domain: Dictionary in expected.domain_expected:
				if domain.scene_id==id: domains.append(domain.closed_xyxy)
			if not domains.is_empty():
				var final_rows: Array=view.named_ground
				if id in ["ch4_s0_luoyang_gate","ch4_s1_luoyang_yamen"]: final_rows=view.named_ground
				var delta: Dictionary=raster(final_bytes,support,final_rows,domains,false)
				if not check(not delta.is_empty() and compare_domain(final_bytes,delta.RGBA,id,expected.domain_expected),"SIX_INDEPENDENT_NEW_DOMAIN_BYTE_EXPECTATIONS:"+id): finish();return
				final_bytes=delta.RGBA;raster_receipts.append({"stage":"independent_six_domains","visited":delta.visited,"changed":delta.changed,"inverse":save_bytes(prefix+"/last_domain_inverse.bin",var_to_bytes(delta.inverse))})
			var mask: Image=Image.create_from_data(3072,2048,false,Image.FORMAT_RGBA8,final_bytes)
			var path: String=prefix+"/walk_overlay.png"
			if not check(not FileAccess.file_exists(path) and mask.save_png(path)==OK,"NEW_SOURCE_MASK_ONLY:"+id): finish();return
			media={"kind":"RAW_RGBA8_PENDING_ISOLATED_IMPORT","path":path,"sha256":FileAccess.get_sha256(path),"RGBA_sha256":sha(final_bytes),"size":[3072,2048],"mipmaps":false}
			raster_receipts.append({"stage":"source_base_publication","visited":base.visited,"changed":base.changed,"inverse":save_bytes(prefix+"/source_base_inverse.bin",var_to_bytes(base.inverse))})
		var payload: Dictionary=save_bytes(prefix+"/payload.bin",var_to_bytes(packed.payload))
		var geometry: Dictionary=save_bytes(prefix+"/effective_solids.bin",var_to_bytes(view.effective_solids))
		if not check(not payload.is_empty() and not geometry.is_empty(),"PACKED_ARTIFACTS_BYTES_READBACK:"+id): finish();return
		outputs[id]={"payload":payload,"geometry":geometry,"mask":media,"fingerprints":packed.fingerprints,"parent_native_count":view.parent_native_navigation.size(),"parent_navigation_count":view.parent_navigation.size(),"effective_navigation_count":view.effective_navigation.size(),"effective_solid_count":view.effective_solids.size(),"raster_receipts":raster_receipts,"original_storage_unchanged":true,"new_whole_typed_inverse":true,"actual_Field_pass":false}
	finish()
