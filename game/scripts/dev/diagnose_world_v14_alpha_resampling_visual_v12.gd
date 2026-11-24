extends SceneTree

const RESAMPLE := preload("res://scripts/dev/native_alpha_aware_resample_visual_v12.gd")
const RESAMPLE_PATH := "res://scripts/dev/native_alpha_aware_resample_visual_v12.gd"
const INPUT := "res://build/world_map_v14_ninth_native_preview_visual_v11_forest_transition/"
const OUTPUT := "res://build/world_map_v14_alpha_resampling_visual_v12/"
const EXPECTED_CAPTURE_SOURCE := "de5f1026505ada4bd0515543b238b45f2b608be4aeb90685b498dedffa1fc11a"

func _initialize() -> void:
	call_deferred("_audit")

func _sha(image: Image) -> String:
	var hashing:=HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(image.get_data())
	return hashing.finish().hex_encode()

func _rgba(image: Image,point: Vector2i) -> Array:
	var value: Color=image.get_pixelv(point)
	return [roundi(value.r*255.),roundi(value.g*255.),roundi(value.b*255.),roundi(value.a*255.)]

func _straight(raw: Image,logical_size: Vector2i) -> Image:
	var result:=raw.duplicate() as Image
	result.convert(Image.FORMAT_RGBA8)
	result.resize(logical_size.x,logical_size.y,Image.INTERPOLATE_LANCZOS)
	return result

func _stats(a: Image,b: Image) -> Dictionary:
	var alpha_different: int=0
	var nonzero_support_different: int=0
	var alpha012_support_different: int=0
	var rgb_different: int=0
	var maximum_alpha_delta: int=0
	var maximum_rgb_delta: int=0
	var pixel_samples: Array=[]
	for y in a.get_height():
		for x in a.get_width():
			var p:=Vector2i(x,y)
			var first: Array=_rgba(a,p)
			var second: Array=_rgba(b,p)
			var delta: int=absi(first[3]-second[3])
			if delta>0: alpha_different+=1
			maximum_alpha_delta=maxi(maximum_alpha_delta,delta)
			if (first[3]>0)!=(second[3]>0): nonzero_support_different+=1
			if (float(first[3])/255.>.12)!=(float(second[3])/255.>.12): alpha012_support_different+=1
			var color_delta: int=maxi(absi(first[0]-second[0]),maxi(absi(first[1]-second[1]),absi(first[2]-second[2])))
			maximum_rgb_delta=maxi(maximum_rgb_delta,color_delta)
			if color_delta>0: rgb_different+=1
			if (delta>0 or color_delta>0) and pixel_samples.size()<24:
				pixel_samples.append({"point":[x,y],"straight_rgba":first,"alpha_aware_rgba":second})
	return {"alpha_different_pixels":alpha_different,"max_alpha_byte_delta":maximum_alpha_delta,"alpha_nonzero_support_changed":nonzero_support_different,"alpha_above_012_support_changed":alpha012_support_different,"rgb_different_pixels":rgb_different,"max_rgb_byte_delta":maximum_rgb_delta,"first_different_pixels":pixel_samples,"straight_used_rect":_rect(a.get_used_rect()),"alpha_aware_used_rect":_rect(b.get_used_rect())}

func _rect(rect: Rect2i) -> Array:
	return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]

func _write(path: String,value: Dictionary) -> bool:
	var bytes: PackedByteArray=JSON.stringify(value,"\t").to_utf8_buffer()
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_buffer(bytes)
	file.flush()
	var saved: bool=file.get_error()==OK
	file.close()
	var reader:=FileAccess.open(path,FileAccess.READ)
	if reader==null: return false
	var actual: PackedByteArray=reader.get_buffer(reader.get_length())
	reader.close()
	return saved and actual==bytes and JSON.parse_string(actual.get_string_from_utf8()) is Dictionary

func _alpha_zero_counterfactual(raw: Image,color: Color) -> Image:
	# Change ONLY unassociated RGB of fully transparent pixels, in memory.
	# Physical coverage/opaque colours/raw source files remain unchanged.
	var result:=raw.duplicate() as Image
	for y in result.get_height():
		for x in result.get_width():
			if result.get_pixel(x,y).a==0.:
				result.set_pixel(x,y,Color(color.r,color.g,color.b,0.))
	return result

func _finish(code: int) -> void:
	# Dedicated CPU tool only. Do not change normal game's cursor lifecycle.
	Input.set_custom_mouse_cursor(null,Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_POINTING_HAND)
	Input.set_custom_mouse_cursor(null,Input.CURSOR_WAIT)
	var manager: Node=root.get_node_or_null("CursorManager")
	if manager!=null:
		for field: String in ["_arrow","_hand","_wait"]: manager.set(field,null)
	for frame in 4: await process_frame
	quit(code)

func _audit() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var ignored:=FileAccess.open(OUTPUT+".gdignore",FileAccess.WRITE)
	if ignored==null: await _finish(1);return
	ignored.store_string("")
	ignored.close()
	var metadata_path: String=INPUT+"entities/native_tree_000.json"
	var raw_metadata: Variant=JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
	if not raw_metadata is Dictionary:
		push_error("Alpha audit missing immutable actual capture metadata")
		await _finish(1);return
	var metadata: Dictionary=raw_metadata
	var raw_path: String=metadata["sourcebody_ssaa_evidence"]["raw_body_path"]
	var repeat_path: String=metadata["sourcebody_ssaa_evidence"]["raw_repeat_path"]
	var source_before: String=FileAccess.get_sha256(raw_path)
	var repeat_before: String=FileAccess.get_sha256(repeat_path)
	if metadata["executed_builder_sha256"]!=EXPECTED_CAPTURE_SOURCE or source_before!=metadata["sourcebody_ssaa_evidence"]["raw_body_png_sha256"] or repeat_before!=metadata["sourcebody_ssaa_evidence"]["raw_repeat_png_sha256"]:
		push_error("Alpha audit raw proof identity mismatch")
		await _finish(1);return
	var raw: Image=Image.load_from_file(raw_path)
	var raw_repeat: Image=Image.load_from_file(repeat_path)
	var canvas: Array=metadata["sourcebody_canvas"]
	var logical_size:=Vector2i(int(canvas[0]),int(canvas[1]))
	if raw==null or raw_repeat==null or raw.get_size()!=logical_size*2:
		push_error("Alpha audit actual raw canvas mismatch")
		await _finish(1);return
	var straight: Image=_straight(raw,logical_size)
	var straight_repeat: Image=_straight(raw_repeat,logical_size)
	var aware: Image=RESAMPLE.resample(raw,logical_size)
	var aware_repeat: Image=RESAMPLE.resample(raw_repeat,logical_size)
	if aware==null or aware_repeat==null: await _finish(1);return
	var repeat_exact: bool=raw.get_data()==raw_repeat.get_data() and straight.get_data()==straight_repeat.get_data() and aware.get_data()==aware_repeat.get_data()
	var crop_data: Array=metadata["sourcebody_crop_rect"]
	var crop:=Rect2i(int(crop_data[0]),int(crop_data[1]),int(crop_data[2]),int(crop_data[3]))
	var actual_export: Image=Image.load_from_file(metadata["texture_path"])
	var baseline_crop: Image=straight.get_region(crop)
	var baseline_crop_exact: bool=actual_export!=null and actual_export.get_size()==baseline_crop.get_size() and actual_export.get_data()==baseline_crop.get_data()
	var counter_records: Array=[]
	var counter_images: Dictionary={}
	var counterfactual_valid: bool=true
	for counter in [{"id":"alpha0_black","color":Color.BLACK},{"id":"alpha0_arbitrary_green","color":Color(.2,.8,.4,1.)}]:
		var counter_raw: Image=_alpha_zero_counterfactual(raw,counter["color"])
		var counter_straight: Image=_straight(counter_raw,logical_size)
		var counter_aware: Image=RESAMPLE.resample(counter_raw,logical_size)
		var invariant: bool=counter_aware!=null and counter_aware.get_data()==aware.get_data()
		var baseline_changed: bool=counter_straight.get_data()!=straight.get_data()
		counterfactual_valid=counterfactual_valid and invariant and baseline_changed
		counter_records.append({"id":counter["id"],"only_fully_transparent_rgb_changed":true,"raw_in_memory_sha256":_sha(counter_raw),"alpha_aware_exactly_invariant":invariant,"straight_result_changed":baseline_changed,"straight_rgba_sha256":_sha(counter_straight),"alpha_aware_rgba_sha256":_sha(counter_aware) if counter_aware!=null else ""})
		counter_images[String(counter["id"])+"_straight"]=counter_straight
		counter_images[String(counter["id"])+"_alpha_aware"]=counter_aware
	var ground_path: String=INPUT+"bianzhou_revision_terrain_shadow_off.png"
	var ground: Image=Image.load_from_file(ground_path)
	if ground==null: await _finish(1);return
	var origin_data: Array=metadata["sourcebody_origin_world_px"]
	var world_origin:=Vector2(float(origin_data[0]),float(origin_data[1]))
	var local_origin:=Vector2(1050,1430)-Vector2(768,512)
	var destination:=Vector2i(world_origin-local_origin)
	var ground_straight:=ground.duplicate() as Image
	var ground_aware:=ground.duplicate() as Image
	ground_straight.blend_rect(straight,Rect2i(Vector2i.ZERO,logical_size),destination)
	ground_aware.blend_rect(aware,Rect2i(Vector2i.ZERO,logical_size),destination)
	var images: Dictionary={"straight_body":straight,"straight_repeat":straight_repeat,"alpha_aware_body":aware,"alpha_aware_repeat":aware_repeat,"straight_crop":straight.get_region(crop),"alpha_aware_crop":aware.get_region(crop),"actual_ground_straight":ground_straight,"actual_ground_alpha_aware":ground_aware}
	images.merge(counter_images)
	var outputs: Dictionary={}
	var saved: bool=true
	for name: String in images:
		var path: String=OUTPUT+name+".png"
		if images[name]==null: saved=false;continue
		saved=saved and images[name].save_png(path)==OK
		outputs[name]={"path":path,"png_sha256":FileAccess.get_sha256(path),"rgba_sha256":_sha(images[name])}
	var edge_samples: Array=[]
	for point in [Vector2i(379,350),Vector2i(377,350),Vector2i(380,350),Vector2i(379,349)]:
		edge_samples.append({"logical_sourcebody_pixel":[point.x,point.y],"cropped_sprite_pixel":[point.x-crop.position.x,point.y-crop.position.y],"raw_ssaa2_origin":[point.x*2,point.y*2],"raw_2x2_rgba":[_rgba(raw,point*2),_rgba(raw,point*2+Vector2i(1,0)),_rgba(raw,point*2+Vector2i(0,1)),_rgba(raw,point*2+Vector2i(1,1))],"straight_rgba":_rgba(straight,point),"alpha_aware_rgba":_rgba(aware,point)})
	var raw_unchanged: bool=source_before==FileAccess.get_sha256(raw_path) and repeat_before==FileAccess.get_sha256(repeat_path)
	var passed: bool=saved and repeat_exact and raw_unchanged and baseline_crop_exact and counterfactual_valid
	var evidence: Dictionary={"status":"ALPHA_SPATIAL_RECONSTRUCTION_DIAGNOSTIC_PASS" if passed else "ALPHA_SPATIAL_RECONSTRUCTION_DIAGNOSTIC_FAIL","visual_approved":false,"production_approved":false,"new_gpu_capture":false,"raw_source_path":raw_path,"raw_repeat_path":repeat_path,"raw_source_sha256":source_before,"raw_repeat_sha256":repeat_before,"raw_files_unchanged":raw_unchanged,"raw_repeat_exact":raw.get_data()==raw_repeat.get_data(),"all_derived_repeats_byte_exact":repeat_exact,"actual_raw_canvas":[raw.get_width(),raw.get_height()],"logical_canvas":[logical_size.x,logical_size.y],"unchanged_camera":metadata["sourcebody_camera"],"raw_background_rgba":_rgba(raw,Vector2i.ZERO),"edge_samples":edge_samples,"all_pixel_changes":_stats(straight,aware),"source_capture_builder_sha256":EXPECTED_CAPTURE_SOURCE,"source_metadata_path":metadata_path,"source_metadata_sha256":FileAccess.get_sha256(metadata_path),"diagnostic_path":get_script().resource_path,"diagnostic_sha256":FileAccess.get_sha256(get_script().resource_path),"helper_path":RESAMPLE_PATH,"helper_sha256":FileAccess.get_sha256(RESAMPLE_PATH),"opaque_ground_path":ground_path,"opaque_ground_sha256":FileAccess.get_sha256(ground_path),"logical_sourcebody_world_origin":[world_origin.x,world_origin.y],"local_ground_crop_origin":[local_origin.x,local_origin.y],"actual_body_blend_destination":[destination.x,destination.y],"outputs":outputs,"method":"one native frame RGBAF premultiply RGB*alpha -> same spatial Lanczos -> unpremultiply if alpha>0 -> RGBA8; no temporal blend, alpha cutout, tint or repeat tolerance","scope":"CPU spatial reconstruction only; alpha/support changes explicitly measured, caster/geometry/terrain/nav not changed; actual ground comparison isolates one real body, not full scene approval"}
	evidence["baseline_matches_actual_export"]={"path":metadata["texture_path"],"png_sha256":FileAccess.get_sha256(metadata["texture_path"]),"source_crop_rect":_rect(crop),"raw_mapping":"crop pixel(84,238) -> logical sourcebody(379,350) -> native SSAA2 origin(758,700)","byte_exact":baseline_crop_exact}
	evidence["transparent_rgb_counterfactuals"]=counter_records
	evidence["counterfactual_invariance_passed"]=counterfactual_valid
	if not _write(OUTPUT+"result.json",evidence): passed=false
	print("[AlphaAwareV12] actual raw repeated reconstruction passed=",passed," alpha_changes=",evidence["all_pixel_changes"]["alpha_different_pixels"]," nonzero_support_changes=",evidence["all_pixel_changes"]["alpha_nonzero_support_changed"])
	await _finish(0 if passed else 1)
