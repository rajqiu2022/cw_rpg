extends "res://tests/helpers/joint_v15_v9c_world_geometry_phase.gd"
## RELEASE layered domains only. Immutable parent mesh/RF/derived/all five
## 32px reference comparisons remain inherited, never given physical credit.
const ORIGIN_SHA := "6ee5d11e56fb7d8cffaa2475abe801222cb94e417e2c8c0d4f0dac7586a02333"
var original_raster_records: Array[Dictionary]=[]

func _raster_segment(raw: RefCounted,a: Vector2,b: Vector2) -> Dictionary:
	var clear: bool=a.is_finite() and b.is_finite() and a.distance_to(b)==8.
	var centers: Array=[]
	for index in 3:
		var center: Vector2=a.lerp(b,float(index)/2.)
		var shoes: PackedVector2Array=raw.call("samples",center)
		var pixels: Array=[]
		clear=shoes.size()==17 and clear
		for shoe: Vector2 in shoes:
			var evidence: Dictionary=raw.call("pixel_evidence",shoe)
			pixels.append(evidence)
			clear=bool(evidence.get("clear",false)) and clear
		centers.append({"center_px":[center.x,center.y],"all17_raw_pixels":pixels})
	return {"clear":clear,"centers":centers,"max_step_px":4,"scope":"ORIGINAL_CAPTURED_RASTER_ONLY_NOT_SOURCE_SOLID_OR_PHYSICS_PASS","normal_input_executed":false,"source_solids_pass_claimed":false,"actual_Physics_pass_claimed":false}

func _seams(manifest: Dictionary, source: Dictionary, catalog: Dictionary, raw: RefCounted) -> void:
	if not _check(FileAccess.get_sha256("res://tests/helpers/joint_v15_v9c_world_geometry_phase.gd")==ORIGIN_SHA,"immutable mesh/RF/derived/reference geometry origin exactSHA"): return
	var authored: Variant = source.get("seams")
	var captured: Variant = manifest.get("seams")
	if not _check(authored is Array and authored.size()==112 and captured is Array and captured.size()==112,"exact112 authored+independent actual reference seam records, enumeration alone insufficient"): return
	var actual_by_id: Dictionary = {}
	for entry: Variant in captured:
		if not _check(entry is Dictionary and not actual_by_id.has(String(entry.get("id",""))),"typed unique captured seam"): continue
		actual_by_id[String(entry.id)]=entry
	var expected: Dictionary = {}
	for row in 8:
		for col in 8:
			if col<7: expected["r%d_c%d--r%d_c%d"%[row,col,row,col+1]]={"from":"r%d_c%d"%[row,col],"to":"r%d_c%d"%[row,col+1],"axis":"x","line":(col+1)*TILE.x,"start":row*TILE.y,"length":TILE.y}
			if row<7: expected["r%d_c%d--r%d_c%d"%[row,col,row+1,col]]={"from":"r%d_c%d"%[row,col],"to":"r%d_c%d"%[row+1,col],"axis":"y","line":(row+1)*TILE.y,"start":col*TILE.x,"length":TILE.x}
	var used: Dictionary = {}
	for authored_entry: Variant in authored:
		if not _check(authored_entry is Dictionary,"typed authored seam"): continue
		var id: String = String(authored_entry.get("id",""))
		if not _check(expected.has(id) and actual_by_id.has(id) and not used.has(id),"each actual internal neighbor has original and independent reference: "+id): continue
		used[id]=true
		var record: Dictionary = actual_by_id[id]
		var edge: Dictionary = expected[id]
		var edge_errors_before: int = errors.size()
		_check(authored_entry.get("from")==edge.from and authored_entry.get("to")==edge.to and record.get("from")==edge.from and record.get("to")==edge.to,"reference binds independently enumerated neighbor pair "+id)
		var reference: Variant = record.get("independent_reference_capture")
		if not _check(reference is Dictionary,"independent neighboring geometry capture, not self-crop "+id): continue
		_whole_geometry_binding(reference,catalog,id)
		var rect_value: Variant = reference.get("logical_rect_px")
		if not _check(_integer_rect(rect_value),"reference global rectangle exact integral native domain; no silent integer truncation "+id): continue
		var rect: Rect2i = Rect2i(int(rect_value[0]),int(rect_value[1]),int(rect_value[2]),int(rect_value[3]))
		var strip: Rect2i = Rect2i(edge.line-16,edge.start,32,edge.length) if edge.axis=="x" else Rect2i(edge.start,edge.line-16,edge.length,32)
		if not _check(rect.encloses(strip),"independent reference covers full boundary on both sides "+id): continue
		var kinds_completed: Array[String] = []
		for kind: String in ["visual","shadow_off","land","raw_walk","walk"]:
			var path: String = String(reference.get(kind+"_path",""))
			var repeat_path: String = String(reference.get(kind+"_repeat_path",""))
			if not _check(_bound(path,catalog) and _bound(repeat_path,catalog) and path!=repeat_path and FileAccess.get_sha256(path)==FileAccess.get_sha256(repeat_path),"real independent reference PNG repeat bytes "+id+"/"+kind): continue
			var image: Image = Image.load_from_file(path)
			if not _check(image!=null and image.get_size()==rect.size,"reference actual one-logical-pixel dimensions "+id): continue
			var left_path: String = ROOT+"chunks/"+edge.from+"_"+kind+".png"
			var right_path: String = ROOT+"chunks/"+edge.to+"_"+kind+".png"
			if not _check(_bound(left_path,catalog) and _bound(right_path,catalog) and path!=left_path and path!=right_path,"both original chunks bound independently, reference not either original PNG "+id+"/"+kind): continue
			var left: Image = Image.load_from_file(left_path)
			var right: Image = Image.load_from_file(right_path)
			if not _check(left!=null and right!=null and left.get_size()==TILE and right.get_size()==TILE,"actual frozen pair PNG readable "+id): continue
			image.convert(Image.FORMAT_RGBA8)
			left.convert(Image.FORMAT_RGBA8)
			right.convert(Image.FORMAT_RGBA8)
			var exact: bool = true
			for y in range(strip.position.y,strip.end.y):
				for x in range(strip.position.x,strip.end.x):
					var global_pixel: Vector2i = Vector2i(x,y)
					var cell: Vector2i = Vector2i(floori(float(x)/TILE.x),floori(float(y)/TILE.y))
					var pair_image: Image = left if (edge.axis=="x" and x<edge.line) or (edge.axis=="y" and y<edge.line) else right
					exact=exact and pair_image.get_pixelv(global_pixel-cell*TILE)==image.get_pixelv(global_pixel-rect.position)
			_check(exact,"entire32px strip original RGBA equals independent reference, both sides "+id+"/"+kind)
			if exact: kinds_completed.append(kind)
		var classification: String = String(authored_entry.get("classification",""))
		var witnesses: Variant = authored_entry.get("projected_witnesses")
		_check(classification in ["open","blocked"] and record.get("classification")==classification,"explicit actual open/blocked seam semantics "+id)
		if not _check(witnesses is Array and not witnesses.is_empty(),"seam has explicit projected nav witnesses "+id): continue
		for witness: Variant in witnesses:
			if not _check(witness is Dictionary,"typed projected seam witness"): continue
			if classification=="open":
				var a: Vector2 = _point(witness.get("from_px"))
				var b: Vector2 = _point(witness.get("to_px"))
				var crossing: bool = a.x<edge.line and b.x>edge.line if edge.axis=="x" else a.y<edge.line and b.y>edge.line
				var reason: Dictionary = _raster_segment(raw,a,b)
				original_raster_records.append({"seam_id":id,"witness_index":original_raster_records.size()%12,"original_witness":witness.duplicate(true),"raster_only":reason})
				_check(crossing and bool(reason.get("clear",false)),"original captured cross-boundary RASTER ONLY entire<=4px/17 shoes legal; solids are separate "+id)
			else:
				var point: Vector2 = _point(witness.get("foot_px"))
				_check(point.is_finite() and not bool(raw.call("clear",point)),"explicit blocked seam foot denied without forcing all112 open "+id)
		edge_evidence.append({"id":id,"classification":classification,"reference":reference.duplicate(true),"witnesses":witnesses.duplicate(true),"exact_kinds":kinds_completed,"all_edge_pixels_checked":kinds_completed.size()==5,"all_predicates_passed":errors.size()==edge_errors_before})
	_check(used.size()==112 and edge_evidence.size()==112,"all112 actual independent reference + navigation classifications completed")
	_check(original_raster_records.size()==1344,"all original1344 RASTER ONLY full17 witnesses retained, not physical pass")


func report() -> Dictionary:
	var result: Dictionary=super.report()
	result["scope"]="RELEASE_LAYERED_SAVED_GEOMETRY_ALL112_FIVE_ROLE_REFERENCES_ORIGINAL1344_RASTER_ONLY"
	result["original_raster_seam_records"]=original_raster_records.duplicate(true)
	result["original_raster_witness_count"]=original_raster_records.size()
	result["source_solid_Physics_credit"]=false
	result["immutable_geometry_origin_sha256"]=ORIGIN_SHA
	return result

func release() -> void:
	super.release()
	original_raster_records.clear()

