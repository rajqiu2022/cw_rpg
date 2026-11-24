extends SceneTree
## Actual saved sampler persistence reader regression only. Calls the NEW pure
## sampler predicate on all 42 actual resources, plus targeted negatives.
## No Field, factory, capture, publication, approvals or player-slot writes.
const PROBE_PATH: String="res://tests/helpers/joint_v15_world_artifact_semantics_v9e_probe.gd"
const DIAGNOSTIC: String="res://build/joint_world_luoyang_20261003_qa/saved_sampler_diagnostic_1791428592_19486860_91988/result.json"
const ROOT: String="res://art/maps/world_map_v15_complete_v9c/"
const EXECUTABLE_SHA: String="975bf1d254b989ee12b64df4d07da692a31175f72424baa180f1078bfc0d71b0"
const SOURCE: String="res://data/maps/world_map_v15_complete_v9c_source.json"
const MANIFEST: String=ROOT+"art_contract.json"
const REPORT: String=ROOT+"whole_actual_capture.json"
const RF: String=ROOT+"terrain_height.rf"
const OLD_FAILURE: String="res://build/joint_world_luoyang_20261003_qa/world_release_199612021/actual_world_artifact_semantics.json"
const PINS: Dictionary={
	SOURCE:"85ced93c4a62361fdf35207df97d797897c4ab8d17c6d18fc1e87d222199967f",
	MANIFEST:"1e183bef51f4260cb882868051c064dc33560a79e80014b1df434ec8df56858a",
	REPORT:"cdd74b329cf84eb24ccd136a5f26afd515795ea612508d197263db31fdcfb851",
	RF:"7158eaf91c38ce55541e895b449ee5645a772a2cd037479357eedaf1917e6f4b",
	OLD_FAILURE:"8bd71065a7e4e827769d6f24f6044fe2612dbadb1fbc2972260cfb364bb2e6e7",
	PROBE_PATH:"b0d3da01ef1347385636765773f4d1a211c871f51b9338c13577f76075e0c2f0",
	DIAGNOSTIC:"add39537174b6412812e5251a0c36feeaf808e2f6ec39356acd60f22df8b84d1",
	"res://tests/helpers/joint_v15_world_artifact_semantics_probe.gd":"946fcc3f9ba9d1d46b067672bd8bd560e12bc651a96b7096d48d94a5f5f060a9",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v9c_full_proposal.gd":"4d006169a3cc0f9dc347c467d4ab05204ee2f78be790e3c75c368d77e9b5abfb",
	"res://scripts/dev/build_world_map_v15_coherent_whole_v9e_full_proposal.gd":"dcda6d3227cad5fd646b6fa3390cae5c4f71354fec1adf15552a12188a8d0121",
	ROOT+"capture/primary/actual_terrain_material.res":"4b8ec4571d316dfce70c893102c1191fbaf67b79286c1f655e5846db9da5e33a",
	ROOT+"capture/primary/actual_water_material.res":"87cedcb26ea48af86616f52a7b81b3e0c2b93c40bab5325e8d99a566bd07e750",
	ROOT+"capture/reference/actual_terrain_material.res":"0295ba8c077ae4545df1991bfaf18589396389a8fc9063ca0455b1ec264bddda",
	ROOT+"capture/reference/actual_water_material.res":"f47944f30905818ec7e451ca77f81e994d6f89ef705390ea82f0a6a9204d993b"
}
const PBR: Array[Dictionary]=[
	{"id":"leafy_grass","directory":"res://art/external/polyhaven/world_terrain_v14_sixth/leafy_grass/"},
	{"id":"grass_ground","directory":"res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/"},
	{"id":"forest_ground_04","directory":"res://art/external/polyhaven/world_terrain_v14_sixth/forest_ground_04/"},
	{"id":"rock_01","directory":"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/"},
	{"id":"brown_mud_03","directory":"res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/"},
	{"id":"aerial_grass_rock","directory":"res://art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock/"}
]
var subject: RefCounted
var negative_cases: int=0
var predicate_calls: int=0
var checks: int=0
var failures: int=0
var assertions: Array[Dictionary]=[]
var materials: Array[Dictionary]=[]
var paths: Dictionary={}
var before: Dictionary={}
var players_before: Dictionary={}
var slot_before: Variant
var save: Node
var self_path: String=""
var self_sha: String=""
var pbr_paths: Dictionary={}
var sampler_count: int=0
var generic_passes: int=0
var generic_failures: int=0
var component_failures: Dictionary={}
var independent_pbr_count: int=0
var independent_rf_count: int=0
var generated_weights_count: int=0
var weight_bytes_by_name: Dictionary={}
var environment_before: Dictionary={}
var environment_after: Dictionary={}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool,label: String) -> bool:
	checks+=1
	assertions.append({"ok":ok,"label":label})
	if not ok:
		failures+=1
		push_error("[SAVED SAMPLER IDENTITY UNIT] "+label)
	return ok

func _sha(bytes: PackedByteArray) -> String:
	var hash: HashingContext=HashingContext.new()
	if hash.start(HashingContext.HASH_SHA256)!=OK or hash.update(bytes)!=OK: return ""
	return hash.finish().hex_encode()

func _read(path: String) -> Dictionary:
	var decoder: JSON=JSON.new()
	if decoder.parse(FileAccess.get_file_as_string(path))!=OK or not decoder.data is Dictionary: return {}
	return decoder.data

func _file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"exists":false}
	var file: FileAccess=FileAccess.open(path,FileAccess.READ)
	if file==null: return {"exists":true,"readable":false}
	var length: int=file.get_length()
	file.close()
	return {"exists":true,"readable":true,"bytes":length,"sha256":FileAccess.get_sha256(path).to_lower(),"mtime":FileAccess.get_modified_time(path)}

func _snapshot(inputs: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for path: String in inputs: result[path]=_file(path)
	return result

func _players() -> Dictionary:
	var result: Dictionary={}
	for slot in 5:
		for suffix: String in ["",".bak",".tmp"]:
			var path: String="user://save_%d.json%s" % [slot,suffix]
			result[ProjectSettings.globalize_path(path)]=_file(path)
	return result

func _environment() -> Dictionary:
	return {"ticks_usec":Time.get_ticks_usec(),"actual_audio_driver":AudioServer.get_driver_name(),"output_devices":AudioServer.get_output_device_list(),"output_device":AudioServer.output_device,"output_mix_rate_hz":AudioServer.get_mix_rate(),"output_latency_sec":AudioServer.get_output_latency(),"engine_version":Engine.get_version_info(),"display_driver":DisplayServer.get_name(),"executable_path":OS.get_executable_path(),"executable_sha256":FileAccess.get_sha256(OS.get_executable_path()).to_lower(),"source_version_equivalence":false}

func _number_equal(a: Variant,b: Variant) -> bool:
	return typeof(a) in [TYPE_INT,TYPE_FLOAT] and typeof(b) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(a)) and is_finite(float(b)) and float(a)==float(b)

func _equal(a: Variant,b: Variant) -> bool:
	if typeof(a) in [TYPE_INT,TYPE_FLOAT] or typeof(b) in [TYPE_INT,TYPE_FLOAT]: return _number_equal(a,b)
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not _equal(a[key],b[key]): return false
		return true
	if a is Array and b is Array:
		if a.size()!=b.size(): return false
		for index in a.size():
			if not _equal(a[index],b[index]): return false
		return true
	return typeof(a)==typeof(b) and a==b

func _all(values: Dictionary) -> bool:
	for value: Variant in values.values():
		if typeof(value)!=TYPE_BOOL or value!=true: return false
	return true

func _image_record(image: Image) -> Dictionary:
	if image==null or image.is_empty(): return {}
	var bytes: PackedByteArray=image.get_data()
	var levels: Array[Dictionary]=[]
	for level in image.get_mipmap_count()+1:
		var offset: int=image.get_mipmap_offset(level)
		var end: int=image.get_mipmap_offset(level+1) if level<image.get_mipmap_count() else bytes.size()
		levels.append({"level":level,"offset":offset,"byte_count":end-offset,"canvas":[maxi(1,image.get_width()>>level),maxi(1,image.get_height()>>level)],"sha256":_sha(bytes.slice(offset,end))})
	return {"canvas":[image.get_width(),image.get_height()],"format":image.get_format(),"mip_count":image.get_mipmap_count(),"has_mipmaps":image.has_mipmaps(),"all_mip_byte_count":bytes.size(),"RGBA_and_all_mips_sha256":_sha(bytes),"levels":levels}

func _independent_origin(name: String,image: Image) -> Dictionary:
	if pbr_paths.has(name):
		var path: String=pbr_paths[name]
		var expected: Image=Image.load_from_file(path)
		var mip_ok: bool=expected!=null and not expected.is_empty() and expected.generate_mipmaps()==OK
		var proof: Dictionary={"origin":"INDEPENDENT_ORIGINAL_REGISTERED_JPEG_THEN_NATIVE_FULL_MIPS","path":path,"file_sha256":paths[path],"mip_generation_ok":mip_ok,"format_exact":mip_ok and image.get_format()==expected.get_format(),"canvas_exact":mip_ok and image.get_size()==expected.get_size(),"mip_count_exact":mip_ok and image.get_mipmap_count()==expected.get_mipmap_count(),"all_mip_bytes_exact":mip_ok and image.get_data()==expected.get_data(),"expected_image":_image_record(expected) if mip_ok else {}}
		_check(mip_ok and proof.format_exact and proof.canvas_exact and proof.mip_count_exact and proof.all_mip_bytes_exact,"independent original PBR all bytes including every mip "+name)
		independent_pbr_count+=1
		expected=null
		return proof
	if name=="actual_height_rf":
		var raw: PackedByteArray=FileAccess.get_file_as_bytes(RF)
		var proof: Dictionary={"origin":"INDEPENDENT_FROZEN_RF_FILE_BYTES_NO_CONVERSION","path":RF,"file_sha256":PINS[RF],"format_exact":image.get_format()==Image.FORMAT_RF,"canvas_exact":image.get_size()==Vector2i(1537,1025),"mip_count_exact":image.get_mipmap_count()==0,"all_mip_bytes_exact":image.get_data()==raw,"raw_byte_count":raw.size()}
		_check(proof.format_exact and proof.canvas_exact and proof.mip_count_exact and proof.all_mip_bytes_exact,"actual RF sampler equals independent frozen Float32 file bytes")
		independent_rf_count+=1
		return proof
	if name in ["biome_weights","road_weights"]:
		# No ecology/factory regeneration here. Preserve record comparison and
		# independently observe equality across the two actually saved worlds;
		# do not pretend this proves their source recipe or original masks.
		var bytes: PackedByteArray=image.get_data()
		var prior: bool=weight_bytes_by_name.has(name)
		var same: bool=not prior or bytes==weight_bytes_by_name[name]
		if not prior: weight_bytes_by_name[name]=bytes
		_check(same,"actual generated weight bytes equal across saved worlds "+name)
		generated_weights_count+=1
		return {"origin":"ACTUAL_GENERATED_WEIGHTS_RECORD_AND_TWO_WORLD_BYTES_ONLY","original_recipe_rebuilt":false,"prior_world_observed":prior,"same_other_saved_world_bytes":same}
	_check(false,"unexpected sampler has no named independent diagnostic origin "+name)
	return {"origin":"UNKNOWN","complete":false}

func _material(row: Dictionary,index: int) -> void:
	var identity: String="primary" if index<3 else "reference"
	var kind: String="terrain" if index in [1,3] else "water"
	var path: String=ROOT+"capture/"+identity+"/actual_"+kind+"_material.res"
	if not _check(row.get("path")==path and row.get("kind")==kind and row.get("sha256")==PINS[path],"exact actual saved material role/path/SHA "+identity+"/"+kind): return
	var material: ShaderMaterial=ResourceLoader.load(path,"ShaderMaterial",ResourceLoader.CACHE_MODE_IGNORE) as ShaderMaterial
	if not _check(material!=null and material.shader!=null and material.resource_path==path,"actual saved material and shader decoded "+path): return
	var saved_uniforms: Variant=row.get("actual_uniforms")
	var actual_uniforms: Array=material.shader.get_shader_uniform_list()
	if not _check(saved_uniforms is Array and saved_uniforms.size()==actual_uniforms.size(),"complete ordered uniform record and native schema "+path): return
	var details: Array[Dictionary]=[]
	var material_row: Dictionary={"identity":identity,"kind":kind,"recorded_path":path,"loaded_material_path":material.resource_path,"saved_file_sha256":PINS[path],"shader_code_sha256":_sha(material.shader.code.to_utf8_buffer()),"recorded_shader_code_sha256":row.get("actual_code_sha256"),"uniform_count":actual_uniforms.size(),"samplers":details}
	_check(material_row.shader_code_sha256==material_row.recorded_shader_code_sha256,"saved shader code SHA equals fixed actual capture record "+path)
	for sid in actual_uniforms.size():
		var spec: Dictionary=actual_uniforms[sid]
		var name: String=String(spec.name)
		var saved: Variant=saved_uniforms[sid]
		var value: Variant=material.get_shader_parameter(name)
		if not _check(saved is Dictionary and saved.get("name")==name and _equal(saved.get("schema"),JSON.parse_string(JSON.stringify(spec))) and _number_equal(saved.get("variant_type"),typeof(value)),"ordered actual sampler/uniform name/schema/type "+identity+"/"+name): continue
		if not value is Texture2D: continue
		var texture: Texture2D=value as Texture2D
		var image: Image=texture.get_image()
		var recorded: Variant=saved.get("texture")
		var observed: Dictionary=_image_record(image)
		var components: Dictionary={"image_nonnull":image!=null and not observed.is_empty(),"texture_record_dictionary":recorded is Dictionary,"resource_path_exact":false,"canvas_exact":false,"format_exact":false,"mip_count_exact":false,"RGBA_and_all_mips_sha256_exact":false}
		if recorded is Dictionary and not observed.is_empty():
			components.resource_path_exact=typeof(recorded.get("resource_path"))==TYPE_STRING and recorded.resource_path==texture.resource_path
			components.canvas_exact=_equal(recorded.get("canvas"),observed.canvas)
			components.format_exact=_number_equal(recorded.get("format"),observed.format)
			components.mip_count_exact=_number_equal(recorded.get("mip_count"),observed.mip_count)
			components.RGBA_and_all_mips_sha256_exact=typeof(recorded.get("RGBA_and_all_mips_sha256"))==TYPE_STRING and recorded.RGBA_and_all_mips_sha256==observed.RGBA_and_all_mips_sha256
		var failed: Array[String]=[]
		for key: String in components:
			if components[key]!=true:
				failed.append(key)
				component_failures[key]=int(component_failures.get(key,0))+1
		_check(failed.size()==1 and failed[0]=="resource_path_exact","original348 sole component mismatch preserved "+identity+"/"+name)
		var full_conjunction: bool=_predicate(recorded,texture.get_class(),texture.resource_path,image,path)
		_check(full_conjunction,"real current sampler persistence identity and every mip "+identity+"/"+name)
		if full_conjunction: generic_passes+=1
		else: generic_failures+=1
		sampler_count+=1
		var original: Dictionary=_independent_origin(name,image) if image!=null and not observed.is_empty() else {"origin":"MISSING_IMAGE","complete":false}
		_check(image!=null and not observed.is_empty() and recorded is Dictionary,"sampler observations available; mismatch is retained rather than waived "+identity+"/"+name)
		details.append({"uniform_index":sid,"name":name,"native_variant_type":typeof(value),"recorded_texture":recorded,"loaded_texture_class":texture.get_class(),"loaded_resource_path":texture.resource_path,"loaded_path_is_material_subresource":texture.resource_path.begins_with(path+"::"),"observed_image":observed,"existing_generic_sampler_components":components,"current_persistence_sampler_conjunction":full_conjunction,"failed_components":failed,"independent_origin":original})
		print("SAVED_SAMPLER ",identity,"/",kind,"/",name," failed=",JSON.stringify(failed)," recorded_path=",JSON.stringify(recorded.get("resource_path") if recorded is Dictionary else null)," loaded_path=",JSON.stringify(texture.resource_path))
		image=null; texture=null; value=null
	_check(details.size()==(20 if kind=="terrain" else 1),"every expected sampler observed "+identity+"/"+kind)
	if kind=="terrain":
		var first: Texture2D=material.get_shader_parameter("leafy_grass_diff") as Texture2D
		var second: Texture2D=material.get_shader_parameter("grass_ground_diff") as Texture2D
		_check(first!=null and second!=null and first.resource_path.begins_with(path+"::ImageTexture_") and second.resource_path.begins_with(path+"::ImageTexture_"),"two actual same-parent distinct named PBR textures")
		if first!=null and second!=null:
			var first_image: Image=first.get_image()
			var second_image: Image=second.get_image()
			_check(first_image.get_size()==second_image.get_size() and first_image.get_format()==second_image.get_format() and first_image.get_mipmap_count()==second_image.get_mipmap_count() and first_image.get_data()!=second_image.get_data(),"actual swap has same canvas/format/mips but distinct bytes")
			_reject("actual same-parent cross-uniform texture swap "+identity,_row_for_image(first_image),second.get_class(),second.resource_path,second_image,path)
			first_image=null; second_image=null; first=null; second=null
	materials.append(material_row)
	material=null


func _predicate(row: Variant,klass: Variant,path: Variant,image: Image,parent: String) -> bool:
	predicate_calls+=1
	return subject.call("_saved_sampler_exact",row,klass,path,image,parent)==true

func _row_for_image(image: Image) -> Dictionary:
	return {"resource_path":"","canvas":[image.get_width(),image.get_height()],"format":image.get_format(),"mip_count":image.get_mipmap_count(),"RGBA_and_all_mips_sha256":_sha(image.get_data())}

func _reject(label: String,row: Variant,klass: Variant,path: Variant,image: Image,parent: String) -> void:
	negative_cases+=1
	_check(not _predicate(row,klass,path,image,parent),"actual sampler predicate rejects "+label)

func _fixture_negatives() -> void:
	# Tiny owned fixtures call the SAME predicate as all42 real resources.
	# They are not saved resources and give no Field/art/capture credit.
	var parent: String=ROOT+"capture/primary/actual_terrain_material.res"
	var path: String=parent+"::ImageTexture_aZ09"
	var image: Image=Image.create(4,4,false,Image.FORMAT_RGB8)
	image.fill(Color(.2,.4,.6))
	_check(image.generate_mipmaps()==OK,"owned tiny full-mip fixture generated")
	var row: Dictionary=_row_for_image(image)
	_check(_predicate(row,"ImageTexture",path,image,parent),"tiny exact explicit persistence fixture positive")
	for invalid: Variant in [null,1,[],{}]:
		_reject("record absent/wrong type",invalid,"ImageTexture",path,image,parent)
	var changed: Dictionary=row.duplicate(true)
	changed.erase("resource_path")
	_reject("missing live resource_path",changed,"ImageTexture",path,image,parent)
	for invalid: Variant in [null,1,[],{},false,"res://external.png"]:
		changed=row.duplicate(true); changed.resource_path=invalid
		_reject("live path wrong type or nonempty",changed,"ImageTexture",path,image,parent)
	for invalid: Variant in [null,1,[],false,"Texture2D","CompressedTexture2D","ImageTextureOther"]:
		_reject("nonexact loaded ImageTexture class",row,invalid,path,image,parent)
	for invalid: Variant in [null,1,[],false,"","res://external.png",
		ROOT+"capture/reference/actual_terrain_material.res::ImageTexture_aZ09",
		parent+"::ImageTexture_",parent+"::Other_aZ09",parent+"::ImageTexture_a/b",
		parent+"::ImageTexture_a\\b",parent+"::ImageTexture_a::nested",
		parent+"::ImageTexture_a.b",parent+"::ImageTexture_a_b",parent+"::ImageTexture_a-b",
		parent+"::ImageTexture_汉",parent+"::ImageTexture_a b"]:
		_reject("invalid exact parent/subresource/suffix",row,"ImageTexture",invalid,image,parent)
	_reject("missing image",row,"ImageTexture",path,null,parent)
	_reject("missing parent",row,"ImageTexture",path,image,"")
	for key: String in ["canvas","format","mip_count","RGBA_and_all_mips_sha256"]:
		changed=row.duplicate(true); changed.erase(key)
		_reject("missing "+key,changed,"ImageTexture",path,image,parent)
		for invalid: Variant in [null,true,"4",[],{}]:
			changed=row.duplicate(true); changed[key]=invalid
			_reject("wrong typed "+key,changed,"ImageTexture",path,image,parent)
	for invalid: Variant in [[4,3],[4.000001,4],[4,"4"],[4,4,4],Vector2(4,4)]:
		changed=row.duplicate(true); changed.canvas=invalid
		_reject("wrong canvas dimensions/shape/types",changed,"ImageTexture",path,image,parent)
	changed=row.duplicate(true); changed.format=int(row.format)+1
	_reject("wrong image format",changed,"ImageTexture",path,image,parent)
	changed=row.duplicate(true); changed.mip_count=int(row.mip_count)-1
	_reject("wrong mip count",changed,"ImageTexture",path,image,parent)
	changed=row.duplicate(true); changed.RGBA_and_all_mips_sha256="0".repeat(64)
	_reject("wrong full data SHA",changed,"ImageTexture",path,image,parent)
	for offset: int in [0,image.get_mipmap_offset(1)]:
		var bytes: PackedByteArray=image.get_data().duplicate()
		bytes[offset]=int(bytes[offset])^1
		var mutated: Image=Image.create_from_data(4,4,true,Image.FORMAT_RGB8,bytes)
		_check(mutated.get_size()==image.get_size() and mutated.get_format()==image.get_format() and mutated.get_mipmap_count()==image.get_mipmap_count() and mutated.get_data()!=image.get_data(),"owned base/mip byte mutation retains canvas/format/mip count")
		_reject("actual base/mip image byte mutation at "+str(offset),row,"ImageTexture",path,mutated,parent)
		mutated=null
	image=null

func _run() -> void:
	self_path=get_script().resource_path
	self_sha=FileAccess.get_sha256(self_path).to_lower()
	paths=PINS.duplicate(true)
	paths[self_path]=self_sha
	before=_snapshot(paths)
	players_before=_players()
	environment_before=_environment()
	_check(environment_before.actual_audio_driver=="WASAPI","actual audio driver is WASAPI at diagnostic start; no Dummy fallback credit")
	_check(environment_before.executable_sha256==EXECUTABLE_SHA,"actual diagnostic engine executable exact SHA at start")
	save=root.get_node_or_null("SaveManager")
	_check(save!=null and current_scene==null,"normal autoload context, no Field/main scene")
	if save!=null: slot_before=save.get("active_slot")
	for path: String in paths: _check(before[path].get("readable")==true and before[path].get("sha256")==paths[path],"fixed current input SHA "+path)
	if failures!=0: await _finish(); return
	var script: Script=load(PROBE_PATH)
	if not _check(script!=null and script.can_instantiate(),"actual current sampler reader can instantiate"): await _finish(); return
	subject=script.new()
	_fixture_negatives()
	var manifest: Dictionary=_read(MANIFEST)
	var report: Dictionary=_read(REPORT)
	if not _check(manifest.get("asset_sha256") is Dictionary and report.get("v9c_revision_evidence") is Dictionary,"fixed manifest catalog and actual capture revision typed"): await _finish(); return
	var catalog: Dictionary=manifest.asset_sha256
	for asset: Dictionary in PBR:
		var registration_path: String=asset.directory+"SOURCE.json"
		if not _check(catalog.get(registration_path) is String,"original PBR registration bound by frozen catalog "+registration_path): continue
		paths[registration_path]=catalog[registration_path]
		var registration: Dictionary=_read(registration_path)
		_check(registration.get("asset")==asset.id and registration.get("license")=="CC0-1.0" and registration.get("channels") is Array,"actual original registered PBR asset/license/channels "+asset.id)
		for channel: String in ["diff","nor_gl","arm"]:
			var name: String=asset.id+"_"+channel
			var path: String=asset.directory+name+"_2k.jpg"
			var matching: Array[Dictionary]=[]
			for item: Variant in registration.get("channels",[]):
				if item is Dictionary and item.get("channel")==channel: matching.append(item)
			if not _check(catalog.get(path) is String and matching.size()==1 and matching[0].get("sha256")==catalog[path] and matching[0].get("md5_verified")==true,"unique registered original channel/current raw SHA "+name): continue
			paths[path]=catalog[path]
			pbr_paths[name]=path
	before=_snapshot(paths)
	for path: String in paths: _check(before[path].get("readable")==true and before[path].get("sha256")==paths[path],"every consumed original/art/source input before exact SHA "+path)
	if failures!=0: await _finish(); return
	var rows: Variant=report.v9c_revision_evidence.get("attached_material_creations")
	if not _check(rows is Array and rows.size()==5,"initial plus exactly four saved material rows"): await _finish(); return
	for index in range(1,5):
		if _check(rows[index] is Dictionary,"typed actual saved material row "+str(index)): _material(rows[index],index)
	_check(materials.size()==4 and sampler_count==42 and generic_passes==42 and generic_failures==0 and independent_pbr_count==36 and independent_rf_count==2 and generated_weights_count==4,"complete four-material/42-sampler diagnostic; 36 independent PBR + 2 independent RF + 4 honest generated-weight observations")
	weight_bytes_by_name.clear()
	subject=null
	manifest.clear(); report.clear()
	await _finish()

func _finish() -> void:
	var audio: Node=root.get_node_or_null("AudioManager")
	if audio!=null: audio.call("stop_bgm",.15)
	await create_timer(.25).timeout
	for shape in [Input.CURSOR_ARROW,Input.CURSOR_POINTING_HAND,Input.CURSOR_WAIT]: Input.set_custom_mouse_cursor(null,shape)
	for frame in 16: await process_frame
	environment_after=_environment()
	_check(environment_after.actual_audio_driver=="WASAPI","actual audio driver is WASAPI after cleanup; no Dummy fallback credit")
	_check(environment_after.executable_sha256==EXECUTABLE_SHA and environment_after.executable_path==environment_before.get("executable_path"),"actual diagnostic engine executable exact SHA/path unchanged after cleanup")
	var after: Dictionary=_snapshot(paths)
	_check(after==before,"all consumed actual artifact/source/registration/JPEG/unit bytes and mtime unchanged")
	_check(_players()==players_before and save!=null and save.get("active_slot")==slot_before,"all15 protected player files and active slot unchanged without restoration writes")
	var output: String="res://build/joint_world_luoyang_20261003_qa/saved_sampler_identity_units_%d_%d_%d/" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec(),OS.get_process_id()]
	if not _check(not DirAccess.dir_exists_absolute(output) and DirAccess.make_dir_recursive_absolute(output)==OK,"unique BUILD-only diagnostic output"): quit(1); return
	var payload: String=JSON.stringify({"schema":1,"scope":"ACTUAL42_SAVED_SAMPLER_IDENTITY_READER_UNITS_NOT_FIELD_OR_RELEASE","environment_before":environment_before,"environment_after":environment_after,"expected_executable_sha256":EXECUTABLE_SHA,"source_version_equivalence":false,"checks":checks,"failures":failures,"diagnostics_complete":failures==0 and materials.size()==4 and sampler_count==42,"current_persistence_sampler_passes":generic_passes,"current_persistence_sampler_failures":generic_failures,"existing_generic_component_failure_counts":component_failures,"original_generic_identity_check_dropped":false,"artifact_sampler_all_passed":sampler_count==42 and generic_failures==0,"materials":materials,"assertions":assertions,"pins":paths,"before":before,"after":after,"source_path":self_path,"source_sha256":self_sha,"independent_PBR_samplers":independent_pbr_count,"independent_RF_samplers":independent_rf_count,"generated_weight_record_only_samplers":generated_weights_count,"capture_executed":false,"factory_executed":false,"current_pure_sampler_predicate_executed":true,"predicate_calls":predicate_calls,"negative_cases":negative_cases,"Field_executed":false,"release_complete":false,"formal_cutover":false,"output":output},"\t",true)
	var file: FileAccess=FileAccess.open(output+"result.json",FileAccess.WRITE)
	if file==null: _check(false,"diagnostic result open")
	else:
		file.store_string(payload); file.flush()
		var error: Error=file.get_error()
		file.close()
		_check(error==OK and FileAccess.get_file_as_string(output+"result.json")==payload,"diagnostic result exact flush/readback")
	print("SAVED_SAMPLER_IDENTITY_UNIT checks=%d failures=%d observed=%d generic_pass=%d generic_fail=%d components=%s output=%s" % [checks,failures,sampler_count,generic_passes,generic_failures,JSON.stringify(component_failures),output])
	quit(0 if failures==0 else 1)


