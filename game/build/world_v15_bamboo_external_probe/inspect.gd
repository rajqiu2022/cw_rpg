extends SceneTree

# Executed only in the isolated audit project; never runs the RPG autoloads.
# Native Godot OBJ importer owns the geometry; this tool does not rebuild it.
const MODEL := "res://original/Bamboo 01.obj"
const EXPECTED_OBJ_SHA := "63c07217c0644acd4671871ba03b69f71ef7fa91f8a30050b43ff33ff119be77"
const EXPECTED_TEXTURES := {
	"diffuse":"40ad50b43c3f174d1965abfc8fde70c43155b78ee7fc478d28af6411c8527e59",
	"normal":"461145e7852cf38e910f139432a175c21ce144d75477e79d2b5b3f24c3e23264",
	"specular":"60f6b0f43fb920d4a3680e1cf0e8825196f807b3f4c927796792b3e0fd52e16d"}

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name()!="headless":
		push_error("This is a CPU audit, not an authorised prototype render.")
		quit(2)
		return
	if FileAccess.get_sha256(MODEL)!=EXPECTED_OBJ_SHA:
		_fail("Actual copied OBJ bytes differ from registered author source")
		return
	var mesh: ArrayMesh=load(MODEL) as ArrayMesh
	if mesh==null:
		_fail("Native OBJ importer did not produce ArrayMesh")
		return
	var minimum:=Vector3(INF,INF,INF)
	var maximum:=Vector3(-INF,-INF,-INF)
	var surfaces: Array[Dictionary]=[]
	var total_triangles:=0
	var total_draw_vertices:=0
	for index in range(mesh.get_surface_count()):
		var arrays: Array=mesh.surface_get_arrays(index)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var uv: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		var draws:=PackedInt32Array()
		if indices.is_empty():
			for i in range(vertices.size()): draws.append(i)
		else:
			draws=indices
		if draws.size()%3!=0 or uv.size()!=vertices.size() or normals.size()!=vertices.size():
			_fail("Actual imported triangle/UV/normal cardinality invalid")
			return
		for draw_index in draws:
			if draw_index<0 or draw_index>=vertices.size():
				_fail("Invalid actual draw index")
				return
			minimum=minimum.min(vertices[draw_index])
			maximum=maximum.max(vertices[draw_index])
		total_triangles+=draws.size()/3
		total_draw_vertices+=draws.size()
		surfaces.append({"surface":index,"stored_vertices":vertices.size(),"draw_indices":draws.size(),"triangles":draws.size()/3,"vertex_sha256":_hash(vertices.to_byte_array()),"normal_sha256":_hash(normals.to_byte_array()),"uv_sha256":_hash(uv.to_byte_array()),"index_sha256":_hash(indices.to_byte_array()),"imported_material_present":mesh.surface_get_material(index)!=null})
	var images: Array[Dictionary]=[]
	for channel: String in ["diffuse","normal","specular"]:
		var path: String="res://original/"+channel+".tga"
		if FileAccess.get_sha256(path)!=EXPECTED_TEXTURES[channel]:
			_fail("Actual original TGA bytes do not match author registry: "+channel)
			return
		var image: Image=Image.load_from_file(path)
		if image==null or image.is_empty() or image.get_size()!=Vector2i(512,512):
			_fail("Actual original TGA decode rejected: "+channel)
			return
		image.convert(Image.FORMAT_RGBA8)
		var data: PackedByteArray=image.get_data()
		var alpha_zero:=0
		var alpha_partial:=0
		var alpha_opaque:=0
		for offset in range(3,data.size(),4):
			if data[offset]==0: alpha_zero+=1
			elif data[offset]==255: alpha_opaque+=1
			else: alpha_partial+=1
		var decoded_sha: String=_hash(data)
		if image.save_png("res://"+channel+"_decoded.png")!=OK:
			_fail("CPU original texture evidence save failed")
			return
		if image.generate_mipmaps()!=OK:
			_fail("Original decoded texture mip construction rejected")
			return
		images.append({"channel":channel,"path":path,"source_sha256":FileAccess.get_sha256(path),"decoded_size":[512,512],"decoded_rgba8_sha256":decoded_sha,"alpha_zero":alpha_zero,"alpha_partial":alpha_partial,"alpha_opaque":alpha_opaque,"generated_mips":image.get_mipmap_count(),"saved_unmodified_decode":"res://"+channel+"_decoded.png"})
	var result: Dictionary={"status":"CPU_NATIVE_OBJ_AUDIT_ONLY_NOT_RENDER_APPROVAL","passed":total_triangles==1440,"actual_engine":Engine.get_version_info(),"native_importer":"Godot ResourceImporterOBJ","source_path":MODEL,"source_sha256":FileAccess.get_sha256(MODEL),"surfaces":surfaces,"actual_triangles":total_triangles,"actual_draw_vertices":total_draw_vertices,"used_bounds_min_source_units":_v3(minimum),"used_bounds_max_source_units":_v3(maximum),"source_units_declared":false,"proposed_preview_scale_m_per_source_unit":.01,"proposed_body_height_m":(maximum.y-minimum.y)*.01,"original_texture_audits":images,"geometry_reconstructed_by_tool":false,"gpu_capture_performed":false}
	if not _json("res://result.json",result):
		_fail("Exact JSON write failed")
		return
	mesh=null
	for i in range(4): await process_frame
	print("NATIVE_BAMBOO_CPU_AUDIT passed=",result["passed"]," triangles=",total_triangles)
	quit(0 if result["passed"] else 1)

func _json(path: String,value: Dictionary) -> bool:
	var text: String=JSON.stringify(value,"\t")
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return false
	file.store_string(text)
	file.flush()
	var error: int=file.get_error()
	file.close()
	return error==OK and FileAccess.get_file_as_string(path)==text and JSON.parse_string(text) is Dictionary

func _fail(message: String) -> void:
	push_error(message)
	_json("res://failed.json",{"status":"TECHNICAL_FAIL","reason":message})
	quit(1)

func _hash(data: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish().hex_encode()

func _v3(point: Vector3) -> Array:
	return [point.x,point.y,point.z]
