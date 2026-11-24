extends SceneTree
## ROOT-only source extraction. Two native decodes; no Scene/PNG/Geometry2D.
const READY=false
const INPUT="F:/Code/RPG_GAME/game/build/luoyang_city_finish_20261025i_source01/parent_projection01_NOTREADY/fixture_NOTREADY.json"
const INPUT_SHA="49fe7dc656e09d4fbf2399136ab70725e7e47592cbfd49cfea3ca7a85a131765"
var checks: int=0
var errors: Array=[]
var deadline: int=0
var sources: Dictionary={}
var first: Dictionary={}
var saves: Array=[]
var seed: Dictionary={}
var unsupported: Array=[]

func _initialize() -> void: call_deferred("run")
func check(ok: bool,where: String) -> bool:
	checks+=1
	if not ok: errors.append(where);printerr("PARENT_PROJECTION: ",where)
	return ok
func digest(b: PackedByteArray) -> String:
	var h:=HashingContext.new()
	if h.start(HashingContext.HASH_SHA256)!=OK or h.update(b)!=OK: return ""
	return h.finish().hex_encode()
func fixed_bytes(spec: Dictionary) -> PackedByteArray:
	var file:=FileAccess.open(String(spec.absolute_path),FileAccess.READ)
	if not check(file!=null,"READ_OPEN:"+String(spec.path)): return PackedByteArray()
	var size: int=file.get_length()
	if not check(size==int(spec.bytes) and size<128*1024*1024,"FIXED_BYTES:"+String(spec.path)):file.close();return PackedByteArray()
	var b: PackedByteArray=file.get_buffer(size);file.close()
	if not check(b.size()==size and digest(b)==spec.sha256,"FIXED_SHA:"+String(spec.path)):return PackedByteArray()
	first[spec.path]={"sha256":spec.sha256,"bytes":size}
	return b
func json_source(spec: Dictionary) -> Dictionary:
	var b: PackedByteArray=fixed_bytes(spec)
	if b.is_empty(): return {}
	var parsed: Variant=JSON.parse_string(b.get_string_from_utf8())
	return parsed if check(parsed is Dictionary,"PLAIN_JSON_DICTIONARY:"+String(spec.path)) else {}
func facts(paths: Array) -> Dictionary:
	var result: Dictionary={}
	for p: String in paths:
		if not FileAccess.file_exists(p):result[p]={"exists":false};continue
		var file:=FileAccess.open(p,FileAccess.READ)
		if file==null:result[p]={"exists":true,"unreadable":true};continue
		var size: int=file.get_length();file.close()
		result[p]={"exists":true,"sha256":FileAccess.get_sha256(p),"bytes":size,"modified_seconds":FileAccess.get_modified_time(p)}
	return result
func v(raw: Variant) -> Vector2:
	if raw is Vector2:return raw
	if raw is Array and raw.size()==2:return Vector2(raw[0],raw[1])
	return Vector2(INF,INF)
func polygon(raw: Variant) -> PackedVector2Array:
	var result:=PackedVector2Array()
	if not raw is Array and not raw is PackedVector2Array:return result
	for point: Variant in raw:
		var q: Vector2=v(point)
		if not q.is_finite():return PackedVector2Array()
		result.append(q)
	return result
func unstorage(raw: Variant) -> Variant:
	if raw is Dictionary:
		if raw.size()==4 and raw.has_all(["array_values","typed_builtin","typed_class_name","typed_script_path"]):
			if not check(raw.array_values is Array and String(raw.typed_script_path).is_empty(),"NO_RESOURCE_OR_SCRIPT_ARRAY"):return null
			var values: Array=[]
			for item: Variant in raw.array_values:values.append(unstorage(item))
			return Array(values,int(raw.typed_builtin),StringName(raw.typed_class_name),null)
		var result: Dictionary={}
		for key: Variant in raw:result[key]=unstorage(raw[key])
		return result
	return raw
func typed(raw: Variant,depth: int=0) -> Variant:
	if depth>=48:unsupported.append("DEPTH");return null
	if raw is Vector2:return {"type":"Vector2","values":[float(raw.x),float(raw.y)],"f32_le_hex":PackedVector2Array([raw]).to_byte_array().hex_encode()}
	if raw is PackedVector2Array:
		var points: Array=[]
		for p: Vector2 in raw:points.append([float(p.x),float(p.y)])
		return {"type":"PackedVector2Array","points":points,"f32_le_hex":raw.to_byte_array().hex_encode()}
	if raw is Dictionary:
		var entries: Array=[]
		for key: Variant in raw:
			if typeof(key) not in [TYPE_STRING,TYPE_STRING_NAME]:unsupported.append("DICTIONARY_KEY");return null
			entries.append({"key":String(key),"key_type":typeof(key),"value":typed(raw[key],depth+1)})
		return {"type":"Dictionary","entries":entries}
	if raw is Array:
		var values: Array=[]
		for item: Variant in raw:values.append(typed(item,depth+1))
		return {"type":"Array","typed_builtin":raw.get_typed_builtin(),"typed_class_name":String(raw.get_typed_class_name()),"values":values}
	if typeof(raw) in [TYPE_NIL,TYPE_BOOL,TYPE_INT,TYPE_FLOAT,TYPE_STRING]:return raw
	if raw is StringName:return {"type":"StringName","value":String(raw)}
	if typeof(raw) in [TYPE_VECTOR2I,TYPE_RECT2,TYPE_RECT2I,TYPE_COLOR,TYPE_VECTOR3,TYPE_VECTOR3I,TYPE_TRANSFORM2D,TYPE_PACKED_BYTE_ARRAY,TYPE_PACKED_INT32_ARRAY,TYPE_PACKED_INT64_ARRAY,TYPE_PACKED_FLOAT32_ARRAY,TYPE_PACKED_FLOAT64_ARRAY,TYPE_PACKED_STRING_ARRAY,TYPE_PACKED_VECTOR3_ARRAY]:
		return {"type_id":typeof(raw),"var_to_bytes_hex":var_to_bytes(raw).hex_encode()}
	unsupported.append(str(typeof(raw)));return {"unsupported_type":typeof(raw)}
func dg_source_projection(author: Dictionary,id: String) -> Dictionary:
	var spec: Dictionary=author.get("districts",{}).get(id,{})
	if spec.is_empty():return {}
	var additions: Array=[];var replacements: Array=[]
	for placement: Dictionary in spec.get("placements",[]):
		var asset: Dictionary=author.assets.get(placement.asset_id,{})
		if asset.is_empty():return {}
		var foot: Vector2=v(placement.foot_px)
		var scale_value: float=float(placement.scale)
		var size: Vector2=v(asset.size_px)
		var anchor: Vector2=v(asset.source_ground_anchor_px)
		var solids: Array=[]
		for raw: Variant in asset.get("ground_solid_polygons_px",[]):
			var points: Array=[]
			for p: Vector2 in polygon(raw):
				var q: Vector2=foot+(p-anchor)*scale_value
				points.append([float(q.x),float(q.y)])
			if not check(points.size()>=3,"SOURCE_POLYGON_ONLY_NOT_TRIANGULATE"):return {}
			solids.append(points)
		var entry: Dictionary={"id":placement.id,"texture":String(asset.texture),"pos":(foot+(size*.5-anchor)*scale_value)/Vector2(3072,2048),"render_size_px":size*scale_value,"centered":true,"sort_by_feet":true,"depth_sort_foot_y":foot.y/2048.0,"world_foot_px":[float(foot.x),float(foot.y)],"physical_center_px":[float(foot.x),float(foot.y)],"collision_size_px":[0.0,0.0],"city_v3_solid_polygons_px":solids,"blocking":true,"district_life_asset_id":placement.asset_id,"district_life_fade":placement.get("fade",false)}
		if String(placement.get("replaces","")).is_empty():additions.append(entry)
		else:entry.replaces=placement.replaces;replacements.append(entry)
	return {"additions":additions,"replacements":replacements}
func primitives(rows: Array) -> Array:
	var result: Array=[]
	for row: Dictionary in rows:
		for ordinal: int in range(row.get("city_v3_solid_polygons_px",[]).size()):
			var p: PackedVector2Array=polygon(row.city_v3_solid_polygons_px[ordinal])
			if not check(p.size()>=3,"PARENT_POLY_FINITE:"+String(row.id)):return []
			result.append({"id":String(row.id)+"_poly_"+str(ordinal),"owner_id":row.id,"kind":"EXACT_EXISTING_POLYGON","points_px":p})
		var size: Vector2=v(row.get("collision_size_px",[0,0]))
		if size.x>0:
			if not check(size.is_finite() and size.y>0,"EXACT_NATIVE_RECT_SIZE"):return []
			var center: Vector2=v(row.physical_center_px)
			var low: Vector2=center-size*.5;var high: Vector2=low+size
			result.append({"id":String(row.id)+"_rect","owner_id":row.id,"kind":"EXACT_EXISTING_CLOSED_RECT","points_px":PackedVector2Array([low,Vector2(high.x,low.y),high,Vector2(low.x,high.y)])})
	return result
func run() -> void:
	var started: int=Time.get_ticks_msec();deadline=started+20000
	var fixture_raw: PackedByteArray=FileAccess.get_file_as_bytes(INPUT)
	var fixture: Variant=JSON.parse_string(fixture_raw.get_string_from_utf8())
	if not check(READY and digest(fixture_raw)==INPUT_SHA and fixture is Dictionary and fixture.get("ready")==true,"ROOT_READY_FIXED_INPUT"):quit(1);return
	sources=fixture.sources
	if not check(not DirAccess.dir_exists_absolute(fixture.output_absolute),"NEW_ABSENT_OUTPUT"):quit(1);return
	for spec: Dictionary in sources.values():
		# Packets are read once below, then final-hashed once at the end.
		if spec.get("kind")=="PACKET":continue
		if fixed_bytes(spec).is_empty():quit(1);return
	var save_first: Dictionary=facts(fixture.save_absolute_paths)
	var dg: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(sources.dg_author.absolute_path))
	var courts_author: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(sources.courts_author.absolute_path))
	var dg_math: Variant=load(String(sources.dg_math.absolute_path))
	var courts_math: Variant=load(String(sources.courts_pure.absolute_path))
	if not check(dg_math is GDScript and dg_math.can_instantiate() and courts_math is GDScript and courts_math.can_instantiate(),"PARSE_ONLY_TWO_EXISTING_PURE_DEPENDENCIES"):quit(1);return
	for spec: Dictionary in fixture.packets:
		if not check(Time.get_ticks_msec()<deadline,"WHOLE20S_BEFORE_PACKET"):break
		var b: PackedByteArray=fixed_bytes(spec)
		if b.is_empty():break
		var raw: Variant=bytes_to_var(b)
		if not check(raw is Dictionary and raw.get("record") is Dictionary and raw.record.get("canonical_scene_id")==spec.scene_id,"FIXED_PACKET_CANONICAL_RECORD"):break
		var native_rows: Variant=unstorage(raw.get("layout_storage",{}).get("fields",{}).get("visual_objects"))
		if not check(native_rows is Array and native_rows.size()==int(spec.native_count) and raw.record.objects.size()==int(spec.native_count),"FULL_NATIVE_VISUAL_OBJECT_PREFIX"):break
		var projected: Dictionary=dg_source_projection(dg,spec.scene_id)
		if not check(not projected.is_empty(),"FIXED_DG_SOURCE_EXPRESSION"):break
		# This existing function is only dictionary replacement/append. It does
		# not invoke DG.project/triangulation, compile geometry or touch a Scene.
		var effective: Array=dg_math.apply_render(native_rows,projected)
		if not check(effective.size()==native_rows.size()+projected.additions.size(),"DG_COMPLETE_ROW_COUNT"):break
		var courts: Dictionary={}
		if spec.scene_id=="ch4_s1_luoyang_yamen":
			courts=courts_math.project_render(courts_author,effective)
			if not check(courts.get("ok")==true and var_to_bytes(courts_math.restore_render(courts))==var_to_bytes(effective),"CURRENT24C_TWO_ROW_WHOLE_TYPED_INVERSE"):break
			effective=courts.render
		var ground: Array=primitives(effective)
		if spec.scene_id=="ch4_s1_luoyang_yamen":
			var canonical_ground: Dictionary=courts_math.derive(courts_author)
			if not check(canonical_ground.get("ok")==true and canonical_ground.combined.size()==40,"CURRENT40_SOURCE_PRIMITIVES_NOT_LIVE"):break
			# Keep canonical40 as a separate exact source table; rendering row
			# owner IDs differ from the historic native/DG primitive IDs.
			courts["canonical_combined40"]=canonical_ground.combined
		seed[spec.scene_id]={"fixed_packet":spec,"native_record_objects":raw.record.objects,"native_visual_rows":native_rows,"DG_source_projection":projected,"effective_parent_render":effective,"render_primitive_rows":ground,"courts_source_40":courts.get("canonical_combined40",[]),"record_and_render_body_bytes":digest(var_to_bytes([raw.record.objects,effective,ground]))}
	var source_final: Dictionary={}
	for spec: Dictionary in sources.values():
		source_final[spec.path]={"sha256":FileAccess.get_sha256(spec.absolute_path),"bytes":int(FileAccess.get_file_as_bytes(spec.absolute_path).size()) if spec.kind!="PACKET" else int(spec.bytes)}
		check(first.get(spec.path)==source_final[spec.path],"SOURCE_FIRST_FINAL:"+String(spec.path))
	var save_final: Dictionary=facts(fixture.save_absolute_paths)
	check(var_to_bytes(save_first)==var_to_bytes(save_final),"READONLY15_SAVE_FIRST_FINAL")
	check(seed.size()==2 and unsupported.is_empty() and Time.get_ticks_msec()<deadline,"TWO_FIXED_SEEDS20S_NO_UNSUPPORTED")
	var json_seed: Variant=typed(seed)
	check(unsupported.is_empty(),"TYPED_PRIMITIVE_JSON_PROJECTION_COMPLETE")
	var report: Dictionary={"status":"ROOT_TWO_PARENT_SOURCE_PROJECTION_ONLY_NOT_GEOMETRY_OR_RUNTIME_PASS","complete":errors.is_empty(),"checks":checks,"failures":errors.size(),"errors":errors,"elapsed_ms":Time.get_ticks_msec()-started,"native_decode_count":seed.size(),"source_first":first,"source_final":source_final,"save_first":save_first,"save_final":save_final,"primitive_source_seed":json_seed,"no_Scene_PNG_Geometry2D_PIP_Physics_collector":true}
	if DirAccess.make_dir_recursive_absolute(fixture.output_absolute)!=OK:quit(1);return
	var file:=FileAccess.open(fixture.output_absolute+"/result.json",FileAccess.WRITE)
	if file==null:quit(1);return
	file.store_string(JSON.stringify(report,"\t")+"\n");file.close()
	if errors.is_empty():
		var binary:=FileAccess.open(fixture.output_absolute+"/parent_source_seeds.bin",FileAccess.WRITE)
		if binary==null:quit(1);return
		binary.store_buffer(var_to_bytes(seed));binary.close()
	quit(0 if errors.is_empty() else 1)
