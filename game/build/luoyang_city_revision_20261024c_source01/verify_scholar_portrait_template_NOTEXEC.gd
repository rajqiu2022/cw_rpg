extends SceneTree
## NOTRUN. Root-only isolated2PNG verification, two fixed complete-shop PNGs.
const PREPARED: String="res://prepared_READY.json"
const PREPARED_SHA: String="PENDING_PREPARED_SHA"
const LIMIT_MS: int=30000
const READY: bool=false
const EXPECTED: Dictionary={}
const PARAMS: Dictionary={
	"compress/mode":0,"compress/high_quality":false,"compress/lossy_quality":0.7,
	"compress/uastc_level":0,"compress/rdo_quality_loss":0.0,"compress/hdr_compression":1,
	"compress/normal_map":0,"compress/channel_pack":0,"mipmaps/generate":false,"mipmaps/limit":-1,
	"roughness/mode":0,"roughness/src_normal":"","process/channel_remap/red":0,
	"process/channel_remap/green":1,"process/channel_remap/blue":2,"process/channel_remap/alpha":3,
	"process/fix_alpha_border":false,"process/premult_alpha":false,"process/normal_map_invert_y":false,
	"process/hdr_as_srgb":false,"process/hdr_clamp_exposure":false,"process/size_limit":0,"detect_3d/compress_to":0
}
var checks: int=0
var failures: Array[String]=[]
var sources: Dictionary={}
var rows: Array[Dictionary]=[]
var began: int

func _initialize() -> void: call_deferred("run")
func need(ok: bool,label: String) -> bool:
	checks+=1
	if not ok: failures.append(label);printerr("SCHOLAR_PORTRAIT_IMPORT_FAIL ",label)
	return ok
func sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK or context.update(bytes)!=OK: return ""
	return context.finish().hex_encode()
func fact(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false}
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {"exists":false}
	var length: int=file.get_length();file.close()
	return {"exists":true,"sha256":FileAccess.get_sha256(path),"bytes":length,"mtime":FileAccess.get_modified_time(path)}
func track(path: String,expected: String) -> bool:
	var value: Dictionary=fact(path)
	if not need(value.get("exists")==true and expected.length()==64 and value.sha256==expected.to_lower(),"Exact frozen source "+path): return false
	if not need(not sources.has(path) or sources[path]==value,"Single unchanged source "+path): return false
	sources[path]=value;return true
func number(value: Variant) -> bool:
	return (typeof(value)==TYPE_INT or typeof(value)==TYPE_FLOAT) and is_finite(float(value))
func parameter_same(left: Variant,right: Variant) -> bool:
	if number(right): return number(left) and float(left)==float(right)
	return typeof(left)==typeof(right) and left==right

func verify(spec: Dictionary) -> bool:
	if not need(spec.get("status")=="EXACT_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATED_IMPORT_PREPARED" and spec.get("textures") is Array and spec.textures.size()==1,"Exact one opaque scholar portrait PNG only"): return false
	if not track("res://project.godot",String(spec.project_sha256)): return false
	for path: String in spec.protected_main_sources:
		if not track(path,String(spec.protected_main_sources[path].sha256)): return false
	for path: String in spec.main_three_absent_targets:
		if not need(not FileAccess.file_exists(path),"Production target remains ABSENT, no promotion "+path): return false
	var seen: Dictionary={}
	for item: Dictionary in spec.textures:
		var domain: String=String(item.domain)
		if not need(EXPECTED.has(domain) and not seen.has(domain),"Unique fixed mask domain"): return false
		seen[domain]=true
		var path: String=String(EXPECTED[domain].png)
		var size: Vector2i=Vector2i(int(EXPECTED[domain].source_size[0]),int(EXPECTED[domain].source_size[1]))
		var compiled_path: String="res://.godot/imported/"+path.get_file()+"-"+path.md5_text()+".ctex"
		if not need(item.source_size is Array and item.source_size.size()==2 and parameter_same(item.source_size[0],EXPECTED[domain].source_size[0]) and parameter_same(item.source_size[1],EXPECTED[domain].source_size[1]),"Exact finite size operands despite JSON number representation"): return false
		if not need(item.png==path and item.compiled==compiled_path and item.png_sha256==EXPECTED[domain].png_sha256 and item.decoded_RGBA_sha256==EXPECTED[domain].decoded_RGBA_sha256,"Hard-fixed original paths/PNG/RGBA identity, not observed expected"): return false
		if not track(path,String(EXPECTED[domain].png_sha256)): return false
		var config:=ConfigFile.new()
		if not need(config.load(path+".import")==OK,"Read actual isolated sidecar"): return false
		if not need(config.get_value("remap","importer","")=="texture" and config.get_value("remap","type","")=="CompressedTexture2D" and config.get_value("remap","path","")==compiled_path,"Exact ordinary lossless remap"): return false
		if not need(config.has_section("params") and config.get_section_keys("params").size()==23,"Exactly23 frozen parameters, not texture format23"): return false
		for key: String in PARAMS:
			if not need(parameter_same(config.get_value("params",key,null),PARAMS[key]),"Exact parameter "+key): return false
		for key: String in config.get_section_keys("remap"):
			if not need(not key.begins_with("path.") and not key.contains("s3tc"),"No platform remap alternate"): return false
		var destinations: Variant=config.get_value("deps","dest_files",null)
		if not need(config.get_value("deps","source_file","")==path and destinations is Array and destinations.size()==1 and destinations[0]==compiled_path,"Exact one compiled destination/source path"): return false
		if not track(path+".import",FileAccess.get_sha256(path+".import")) or not track(compiled_path,FileAccess.get_sha256(compiled_path)): return false
		var raw: Image=Image.load_from_file(path)
		var imported_texture: Texture2D=ResourceLoader.load(path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		var direct_texture: Texture2D=ResourceLoader.load(compiled_path,"",ResourceLoader.CACHE_MODE_IGNORE) as Texture2D
		if not need(raw!=null and imported_texture!=null and direct_texture!=null,"Independent raw/import/directctex entry points"): return false
		var imported: Image=imported_texture.get_image();var direct: Image=direct_texture.get_image()
		if not need(imported!=null and direct!=null,"Both actual image payloads"): return false
		for image: Image in [raw,imported,direct]:
			if not need(not image.has_mipmaps() and image.get_size()==size,"Full fixed native size/mip0"): return false
			if image.is_compressed() and not need(image.decompress()==OK,"Lossless actual decompression"): return false
			image.convert(Image.FORMAT_RGBA8)
			if not need(image.get_format()==Image.FORMAT_RGBA8 and image.get_data().size()==size.x*size.y*4,"WholeRGBA8 bytes, no crop/sample shortcut"): return false
		var rgba_data: PackedByteArray=raw.get_data()
		var opaque: bool=true
		for alpha_index: int in range(3,rgba_data.size(),4):
			if rgba_data[alpha_index]!=255:
				opaque=false;break
		if not need(opaque,"Every source RGBA alpha is255; opaque portrait, not background removal"): return false
		if not need(raw.get_data()==imported.get_data() and raw.get_data()==direct.get_data() and sha(raw.get_data())==EXPECTED[domain].decoded_RGBA_sha256,"Entire raw/import/direct RGBA equals independent predeclared identity"): return false
		rows.append({"domain":domain,"png":path,"png_sha256":EXPECTED[domain].png_sha256,"decoded_RGBA_sha256":EXPECTED[domain].decoded_RGBA_sha256,"sidecar":path+".import","sidecar_sha256":FileAccess.get_sha256(path+".import"),"compiled":compiled_path,"compiled_sha256":FileAccess.get_sha256(compiled_path),"full_RGBA_exact":true,"opaque_full_RGBA":true,"size":[size.x,size.y],"raw_format_after_RGBA_conversion":raw.get_format(),"alpha_used_rect_after_full_RGBA":raw.get_used_rect(),"params23":true,"mipmaps":0,"detect_3d_compress_to":0,"promoted":false})
		if not need(Time.get_ticks_msec()-began<LIMIT_MS,"Finite30s verification"): return false
	return need(seen.size()==1,"Exactly one independently expected portrait PNG verified")

func run() -> void:
	began=Time.get_ticks_msec()
	var result_path: String="res://scholar_portrait_import_result_%d.json"%OS.get_process_id()
	var passed: bool=need(READY,"NOTREADY: Root authorizes only the NEW isolated verifier")
	if passed: passed=need(OS.get_cmdline_user_args().is_empty() and root.get_child_count()==0 and not FileAccess.file_exists(result_path),"No autoloads/args, NEW result only")
	if passed: passed=track(PREPARED,PREPARED_SHA)
	var spec: Variant=JSON.parse_string(FileAccess.get_file_as_string(PREPARED)) if passed else null
	if passed: passed=need(spec is Dictionary,"Frozen prepared manifest")
	if passed: passed=track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)) and verify(spec)
	var after: Dictionary={}
	for path: String in sources: after[path]=fact(path)
	if not need(after==sources,"All main/copy/seededproject/newimport/ctex sources unchanged during verifier"): passed=false
	if spec is Dictionary:
		for path: String in spec.main_three_absent_targets:
			if not need(not FileAccess.file_exists(path),"Main three targets still ABSENT"): passed=false
	if not need(Time.get_ticks_msec()-began<LIMIT_MS,"Whole fixed30s"): passed=false
	var report: Dictionary={"passed":passed and failures.is_empty(),"scope":"ONLY_ONE_OPAQUE_SCHOLAR_PORTRAIT_ISOLATED_FULL_RGBA_NOT_RUNTIME","checks":checks,"failures":failures,"elapsed_ms":Time.get_ticks_msec()-began,"limit_ms":LIMIT_MS,"rows":rows,"source_first":sources,"source_final":after,"production_promotions":0,"engine_import_calls_by_verifier":0,"geometry_Field_CPU_renderer_calls":0,"prepared_sha256":PREPARED_SHA}
	var file:=FileAccess.open(result_path,FileAccess.WRITE)
	if file==null: passed=false
	else: file.store_string(JSON.stringify(report,"\t",true,true));file.close()
	print("SCHOLAR_PORTRAIT_IMPORT_RESULT=",result_path)
	quit(0 if passed and failures.is_empty() else 1)
