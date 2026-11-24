extends SceneTree
## Read-only source/import diagnosis. Differences are observations, not a
## relaxed production predicate or visual/Field approval. Root runs this.
const CITY_ROOT := "res://art/maps/luoyang_enclosure_v11/"
const PATCHES := {
	"ch4_s0_luoyang_gate":"20cb77de45df28def34fdeee5f7c75300182ade0a1f6af338088059e47f05de1",
	"ch4_s1_luoyang_yamen":"2e1f562c429aabc89ebd38f044192e0f8dd71738147cb51b5fba4f9d6b7b50d4",
	"ch4_s2_canal_docks":"b4b06110c299bf97dad8eb7134d8b0902135b37bc7c7f4952522ce6f30a5cf23",
	"ch4_s3_luoyang_market":"ba46bfa02e4152918d6696033450bf1f0329be01318f69449a7fad7355a85c84",
}
var tracked: Dictionary = {}
var observations: Array[Dictionary] = []
var failure := ""

func _initialize() -> void: call_deferred("_diagnose")
func _track(path: String) -> bool:
	if not FileAccess.file_exists(path): failure="Missing read-only diagnostic source: "+path; return false
	var value := {"sha256":FileAccess.get_sha256(path),"mtime_seconds":FileAccess.get_modified_time(path),"bytes":FileAccess.get_file_as_bytes(path).size()}
	if tracked.has(path) and tracked[path] != value: failure="Diagnostic source changed during read: "+path; return false
	tracked[path]=value
	return true
func _same() -> bool:
	for path: String in tracked:
		if not _track(path): return false
	return true
func _diagnose() -> void:
	var bridge: Node=root.get_node_or_null("PlatformBridge")
	if bridge==null or not bridge.has_method("set_checkpoint_saves_suspended"): push_error("Checkpoint guard unavailable"); quit(1); return
	bridge.call("set_checkpoint_saves_suspended",true)
	if bridge.call("is_checkpoint_saves_suspended")!=true: push_error("Checkpoint guard not acknowledged"); quit(1); return
	var args: PackedStringArray=OS.get_cmdline_user_args()
	var tag := ""
	for arg: String in args:
		if arg.begins_with("--import-diagnostic-tag="): tag=arg.trim_prefix("--import-diagnostic-tag=")
	if not "--diagnose-luoyang-enclosure-v15-import-rgba" in args or tag.is_empty() or not tag.is_valid_identifier() or "--activate" in args: push_error("Explicit unique read-only RGBA diagnostic required"); quit(1); return
	var output: String="res://build/luoyang_enclosure_v15_import_rgba/"+tag+"/"
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)) or DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))!=OK: push_error("Preserve existing diagnostic output"); quit(1); return
	if not _track(get_script().resource_path): _finish(output); return
	for id: String in PATCHES:
		var patch_path: String=CITY_ROOT+id+"/art_patch.json"
		if not _track(patch_path) or FileAccess.get_sha256(patch_path)!=PATCHES[id]: failure="Actual patch pin missing/changed: "+id; break
		var raw: Variant=JSON.parse_string(FileAccess.get_file_as_string(patch_path))
		if not raw is Dictionary or raw.get("canonical_scene_id")!=id or not raw.get("objects") is Array: failure="Actual patch objects unreadable: "+id; break
		for object: Dictionary in raw.objects:
			var path: String=String(object.get("texture",""))
			if path!=CITY_ROOT+id+"/entities/"+String(object.id)+".png" or raw.asset_sha256.get(path)!=FileAccess.get_sha256(path): failure="Exact independent entity PNG not bound: "+path; break
			var item: Dictionary=_image_observation(id,String(object.id),path)
			if item.is_empty(): break
			observations.append(item)
		if not failure.is_empty(): break
	_finish(output)

func _image_observation(id: String, oid: String, path: String) -> Dictionary:
	if not _track(path) or not _track(path+".import"): return {}
	var config:=ConfigFile.new()
	if config.load(path+".import")!=OK: failure="Import config unreadable: "+path; return {}
	var compiled: String=String(config.get_value("remap","path",""))
	if compiled.is_empty() or not _track(compiled): return {}
	var source: Image=Image.load_from_file(path)
	var texture: Texture2D=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
	var imported: Image=texture.get_image() if texture!=null else null
	if source==null or imported==null or source.get_size()!=imported.get_size(): failure="Source/import image missing or dimensions differ: "+path; return {}
	var source_format: int=source.get_format(); var imported_format: int=imported.get_format()
	var imported_mips: int=imported.get_mipmap_count()
	if imported.is_compressed() and imported.decompress()!=OK: failure="Actual ResourceLoader image cannot decompress: "+path; return {}
	source.convert(Image.FORMAT_RGBA8); imported.convert(Image.FORMAT_RGBA8)
	var original: PackedByteArray=source.get_data()
	var actual: PackedByteArray=imported.get_data().slice(0,source.get_width()*source.get_height()*4)
	if actual.size()!=original.size(): failure="RGBA base image byte count differs: "+path; return {}
	var bins := {"alpha_zero":{"pixels":0,"rgb_changed_pixels":0,"alpha_changed_pixels":0},"alpha_partial":{"pixels":0,"rgb_changed_pixels":0,"alpha_changed_pixels":0},"alpha_opaque":{"pixels":0,"rgb_changed_pixels":0,"alpha_changed_pixels":0}}
	var channels: Array[int]=[0,0,0,0]; var changed_pixels:=0
	var first_changed: Array[Dictionary]=[]
	var minimum:=Vector2i(source.get_width(),source.get_height()); var maximum:=Vector2i(-1,-1)
	for pixel: int in source.get_width()*source.get_height():
		var offset: int=pixel*4; var alpha: int=original[offset+3]
		var bucket: String="alpha_zero" if alpha==0 else ("alpha_opaque" if alpha==255 else "alpha_partial")
		bins[bucket].pixels+=1
		var rgb_changed: bool=false; var alpha_changed: bool=original[offset+3]!=actual[offset+3]
		for channel: int in 4:
			if original[offset+channel]!=actual[offset+channel]:
				channels[channel]+=1
				if channel<3: rgb_changed=true
		if rgb_changed: bins[bucket].rgb_changed_pixels+=1
		if alpha_changed: bins[bucket].alpha_changed_pixels+=1
		if rgb_changed or alpha_changed:
			changed_pixels+=1
			var point:=Vector2i(pixel%source.get_width(),pixel/source.get_width())
			minimum=minimum.min(point); maximum=maximum.max(point)
			if first_changed.size()<20: first_changed.append({"xy":[point.x,point.y],"source_rgba":Array(original.slice(offset,offset+4)),"imported_rgba":Array(actual.slice(offset,offset+4))})
	# Independently apply the engine's named alpha-edge operation to a duplicate
	# in memory only. It does not edit/re-encode the source PNG or import config.
	var edge_fixed: Image=source.duplicate() as Image
	edge_fixed.fix_alpha_edges()
	var edge_data: PackedByteArray=edge_fixed.get_data()
	var edge_matches: bool=edge_data==actual
	return {"city":id,"object_id":oid,"png_path":path,"png_sha256":tracked[path].sha256,"import_path":path+".import","import_sha256":tracked[path+".import"].sha256,"compiled_path":compiled,"compiled_sha256":tracked[compiled].sha256,"dimensions":[source.get_width(),source.get_height()],"source_format_before":source_format,"imported_format_before":imported_format,"imported_mipmap_count":imported_mips,"source_rgba_base_bytes":original.size(),"imported_rgba_base_bytes":actual.size(),"raw_source_matches_imported":original==actual,"changed_pixels":changed_pixels,"changed_channel_counts_rgba":channels,"source_alpha_buckets":bins,"changed_bbox_inclusive":{"minimum":[minimum.x,minimum.y],"maximum":[maximum.x,maximum.y]},"first_changed_pixels":first_changed,"actual_engine_fix_alpha_edges_clone_matches_imported":edge_matches,"fix_alpha_edges_clone_changed_source_rgba":edge_data!=original,"import_params":{"compress_mode":config.get_value("params","compress/mode"),"mipmaps_generate":config.get_value("params","mipmaps/generate"),"fix_alpha_border":config.get_value("params","process/fix_alpha_border"),"premult_alpha":config.get_value("params","process/premult_alpha"),"size_limit":config.get_value("params","process/size_limit")},"source_png_modified":false}

func _finish(output: String) -> void:
	var same: bool=_same()
	var changed_images:=0; var fixed_matches:=0; var visible_rgb_changed:=0; var alpha_changed:=0
	for item: Dictionary in observations:
		if not item.raw_source_matches_imported: changed_images+=1
		if item.actual_engine_fix_alpha_edges_clone_matches_imported: fixed_matches+=1
		visible_rgb_changed+=int(item.source_alpha_buckets.alpha_partial.rgb_changed_pixels)+int(item.source_alpha_buckets.alpha_opaque.rgb_changed_pixels)
		alpha_changed+=int(item.changed_channel_counts_rgba[3])
	var result := {"scope":"LUOYANG_V15_READ_ONLY_ACTUAL_RGBA_IMPORT_DIAGNOSIS_NOT_FIELD","complete":failure.is_empty() and same and observations.size()==28,"failure":failure,"entity_count":observations.size(),"expected_entity_count":28,"source_import_mismatch_images":changed_images,"actual_engine_fix_alpha_edges_clone_exact_matches":fixed_matches,"nonzero_source_alpha_rgb_changed_pixels":visible_rgb_changed,"alpha_changed_pixels":alpha_changed,"observations":observations,"source_before":tracked,"source_unchanged":same,"checkpoint_remains_suspended":root.get_node("PlatformBridge").call("is_checkpoint_saves_suspended"),"production_predicate_modified":false,"png_modified":false,"import_configs_modified":false,"Field_executed":false,"actual_audio_driver":AudioServer.get_driver_name()}
	var file:=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null: push_error("Diagnostic result cannot be retained"); quit(1); return
	var encoded: String=JSON.stringify(result,"\t",false)
	file.store_string(encoded+"\n"); file.flush(); var written: bool=file.get_error()==OK; file.close()
	written=written and JSON.parse_string(FileAccess.get_file_as_string(output+"result.json"))==JSON.parse_string(encoded)
	print("LUOYANG_IMPORT_RGBA_DIAGNOSTIC "+output+"result.json count="+str(observations.size())+" source_mismatch="+str(changed_images)+" fix_edges_exact="+str(fixed_matches)+" visibleRGB="+str(visible_rgb_changed)+" alpha="+str(alpha_changed))
	if not failure.is_empty(): push_error(failure)
	quit(0 if result.complete and written else 1)
