extends RefCounted
## Independent visual-only dispatch. Frozen scene/stream/NAV contracts stay old.
## ROOT fills this exact manifest pin only after thirteen imported RGBA proofs.
const APPROVAL_SHA := "2fc156a01dba1bc5c887e4aabd45fb65e5614ab54d29101da72e217cec0fa897"
const APPROVAL_PATH := "res://art/maps/world_farmland_patch_v2_20261015/approved_manifest.json"
const NEW_ROOT := "res://art/maps/world_farmland_patch_v2_20261015/"
const OLD_ROOT := "res://art/maps/world_map_v15_complete_v9c/"
const OLD_OVERVIEW := OLD_ROOT+"overview.png"
const STREAM_PATH := "res://data/background_sets/world_map_jianghu_v15_streamed.tres"
const STREAM_SHA := "3536182ec4eba967e8cd6b5da6b8ca6bb44072022f342d190eb807995a772400"
const RESULT_SHA := "82111ba29fe10432add61e3982f51737a1b38d6dea3df60ad1ce7475488c8a49"
const IDS := ["r2_c1","r2_c2","r2_c3","r3_c1","r3_c2","r3_c3","r4_c2","r4_c3","r5_c4","r5_c5","r6_c4","r6_c5"]
static var _checked := false
static var _active := false
static var _failure := "NOT_APPROVED"
static var _mapping: Dictionary={}
static var _overview_path := OLD_OVERVIEW
static var _verification_ms := 0

static func _sha(path: String,value: Variant) -> bool:
	if not value is String or value.length()!=64: return false
	return FileAccess.file_exists(path) and FileAccess.get_sha256(path).to_lower()==value.to_lower()

static func _small_json(path: String) -> Dictionary:
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>262144: return {}
	var parsed: Variant=JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

static func _exact_size(value: Variant,expected: Vector2i) -> bool:
	if not value is Array or value.size()!=2: return false
	for i in 2:
		if typeof(value[i]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value[i])) or float(value[i])!=float(expected[i]): return false
	return true

static func _import_error(row: Dictionary,path: String,sha256: String,size: Vector2i) -> String:
	if row.get("path")!=path or row.get("source_sha256")!=sha256 or row.get("full_RGBA_exact")!=true or row.get("mipmap_count")!=0 or not _exact_size(row.get("size"),size): return "Import fullRGBA/source/size proof differs"
	if row.get("import_path")!=path+".import" or not _sha(path+".import",row.get("import_sha256")): return "Import configuration pin differs"
	var config:=ConfigFile.new()
	if config.load(path+".import")!=OK: return "Import configuration unreadable"
	for pair: Array in [["compress/mode",0],["mipmaps/generate",false],["process/fix_alpha_border",false],["process/premult_alpha",false],["process/size_limit",0],["detect_3d/compress_to",0]]:
		if config.get_value("params",pair[0],null)!=pair[1]: return "Strict import setting differs: "+String(pair[0])
	var compiled: String=row.get("compiled_path","")
	if not compiled.begins_with("res://.godot/imported/") or compiled.get_file()!=path.get_file()+"-"+path.md5_text()+".ctex" or config.get_value("remap","path","")!=compiled or config.get_value("deps","source_file","")!=path or not _sha(compiled,row.get("compiled_sha256")): return "Imported binary/source-path pin differs"
	if not ResourceLoader.exists(path,"Texture2D"): return "Approved imported texture unavailable"
	return ""

static func _manifest_error(manifest: Dictionary) -> String:
	if manifest.get("schema")!=1 or manifest.get("approved")!=true or manifest.get("approved_by")!="root" or manifest.get("candidate_result_sha256")!=RESULT_SHA: return "Explicit ROOT candidate approval missing"
	if manifest.get("stream_path")!=STREAM_PATH or manifest.get("stream_sha256")!=STREAM_SHA or not _sha(STREAM_PATH,STREAM_SHA): return "Frozen original stream differs"
	var proof: Dictionary=manifest.get("import_proof",{})
	var proof_path: String=proof.get("path","")
	if not proof_path.begins_with("res://build/world_farmland_") or not _sha(proof_path,proof.get("sha256")): return "Independent import proof pin missing"
	var imported:=_small_json(proof_path)
	if imported.get("passed")!=true or imported.get("candidate_result_sha256")!=RESULT_SHA or imported.get("rows",[]).size()!=13: return "Thirteen actual imports not proved"
	var imports: Dictionary={}
	for row: Dictionary in imported.rows:
		var path: String=row.get("path","")
		if imports.has(path): return "Duplicate imported texture proof"
		imports[path]=row
	var entries: Array=manifest.get("entries",[])
	if entries.size()!=12: return "Exactly twelve visual replacements required"
	var mapping: Dictionary={}; var seen: Array[String]=[]
	for entry: Dictionary in entries:
		var id: String=entry.get("id","")
		if not IDS.has(id) or seen.has(id): return "Unknown/duplicate patch cell"
		seen.append(id)
		var old_path:=OLD_ROOT+"chunks/"+id+"_visual.png"
		var new_path:=NEW_ROOT+id+"_visual.png"
		var parts:=id.split("_"); var row:=int(parts[0].trim_prefix("r")); var col:=int(parts[1].trim_prefix("c"))
		var rect: Variant=entry.get("logical_rect")
		if not rect is Array or rect.size()!=4: return "Patch rectangle missing"
		for index in 4:
			var expected: int=[col*1536,row*1024,1536,1024][index]
			if typeof(rect[index]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(rect[index])) or float(rect[index])!=float(expected): return "Patch rectangle differs"
		if entry.get("old_path")!=old_path or entry.get("path")!=new_path or entry.get("draw_scale")!=1.0 or not _sha(old_path,entry.get("old_sha256")) or not _sha(new_path,entry.get("sha256")): return "Patch original/new identity differs"
		var error:=_import_error(imports.get(new_path,{}),new_path,String(entry.sha256),Vector2i(1536,1024))
		if not error.is_empty(): return error
		mapping[old_path]=new_path
	if seen!=IDS: return "Patch cells not in approved exact order"
	var overview: Dictionary=manifest.get("overview",{})
	if overview.get("old_path")!=OLD_OVERVIEW or overview.get("path")!=NEW_ROOT+"overview.png" or not _sha(OLD_OVERVIEW,overview.get("old_sha256")) or not _sha(String(overview.get("path","")),overview.get("sha256")): return "Overview source identity differs"
	var overview_error:=_import_error(imports.get(overview.path,{}),overview.path,String(overview.sha256),Vector2i(3072,2048))
	if not overview_error.is_empty(): return overview_error
	_mapping=mapping; _overview_path=overview.path
	return ""

static func _approved() -> bool:
	if _checked: return _active
	_checked=true
	# Pending integration is inert and does not read any map or large source.
	if APPROVAL_SHA.length()!=64: return false
	var started:=Time.get_ticks_msec()
	if not _sha(APPROVAL_PATH,APPROVAL_SHA): _failure="Approval manifest pin differs"
	else: _failure=_manifest_error(_small_json(APPROVAL_PATH))
	_active=_failure.is_empty(); _verification_ms=Time.get_ticks_msec()-started
	if not _active:
		_mapping.clear(); _overview_path=OLD_OVERVIEW
		push_warning("[WorldFarmlandVisualPatch] Keeping original visuals: "+_failure)
	return _active

static func _eligible(stream: StreamedBackgroundSet,prefer_desktop: bool) -> bool:
	if stream==null or stream.resource_path!=STREAM_PATH or stream.logical_size!=Vector2i(12288,8192): return false
	var chunks:=stream.get_chunks(prefer_desktop)
	if chunks.size()!=64: return false
	var seen: Dictionary={}
	for entry: Dictionary in chunks:
		var rect: Variant=entry.get("logical_rect")
		if not rect is Rect2 or rect.size!=Vector2(1536,1024): return false
		var col:=int(rect.position.x)/1536; var row:=int(rect.position.y)/1024
		var id:="r%d_c%d"%[row,col]
		if row<0 or row>7 or col<0 or col>7 or rect.position!=Vector2(col*1536,row*1024) or seen.has(id) or entry.get("path")!=OLD_ROOT+"chunks/"+id+"_visual.png" or entry.get("draw_position")!=rect.position or entry.get("draw_scale")!=1.0: return false
		seen[id]=true
	return true

static func effective_chunks(stream: StreamedBackgroundSet,prefer_desktop: bool) -> Array[Dictionary]:
	if stream==null: return []
	var original:=stream.get_chunks(prefer_desktop)
	if not _eligible(stream,prefer_desktop) or not _approved(): return original
	var effective: Array[Dictionary]=[]
	for entry: Dictionary in original:
		var copy:=entry.duplicate(true)
		var path: String=entry.get("path","")
		if _mapping.has(path): copy.path=_mapping[path]
		effective.append(copy)
	return effective

static func overview_path(scene: SceneScript) -> String:
	if scene==null or scene.background_path!=OLD_OVERVIEW or scene.map_layout==null or scene.streamed_background==null or scene.map_layout.schema_version!=15 or not scene.scene_id in [&"world_map_jianghu",&"world_map_jianghu_v15"]: return OLD_OVERVIEW
	if not _eligible(scene.streamed_background,scene.streamed_background.uses_desktop_variant()) or not _approved(): return OLD_OVERVIEW
	return _overview_path

static func debug_state() -> Dictionary:
	return {"checked":_checked,"active":_active,"failure":_failure,"approval_sha256":APPROVAL_SHA,"replacement_count":_mapping.size(),"overview_path":_overview_path,"verification_ms":_verification_ms,"NAV_changed":false,"scene_mutated":false}
