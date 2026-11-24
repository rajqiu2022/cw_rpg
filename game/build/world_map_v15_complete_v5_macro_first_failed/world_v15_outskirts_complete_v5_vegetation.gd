extends RefCounted

# Actual licensed model geometry, not the rejected native lance-leaf substitute.
const BAMBOO_ROOT := "res://art/external/opengameart/yughues_bamboo_v1/"
const BAMBOO_RAW := BAMBOO_ROOT+"original/Bamboo 01.obj"
const BAMBOO_MESH := BAMBOO_ROOT+"derived/bamboo_native_godot462.mesh"
const HERB := "res://art/external/polyhaven/shrub_03/shrub_03_1k.gltf"
const HERB_SHA := "b76d7c14bc027e834e82d3f984c32b5d060e62908aa90ff9420a637ca253a8ea"
static var textures: Dictionary={}
static var texture_evidence: Array[Dictionary]=[]
static var geometry_evidence: Dictionary={}

static func bamboo() -> ArrayMesh:
	var registry: Variant=JSON.parse_string(FileAccess.get_file_as_string(BAMBOO_ROOT+"SOURCE.json"))
	var receipt: Variant=JSON.parse_string(FileAccess.get_file_as_string(BAMBOO_ROOT+"derived/native_import_record.json"))
	if not registry is Dictionary or not receipt is Dictionary or registry.get("license","")!="CC0-1.0": return null
	if FileAccess.get_sha256(BAMBOO_RAW)!=String(receipt.get("source_sha256","")).to_lower(): return null
	if FileAccess.get_sha256(BAMBOO_MESH)!=String(receipt.get("derived_mesh_sha256","")).to_lower(): return null
	var original: ArrayMesh=load(BAMBOO_MESH) as ArrayMesh
	if original==null or original.get_surface_count()!=1: return null
	var arrays: Array=original.surface_get_arrays(0)
	var expected: Dictionary=receipt["surfaces"][0]
	var keys := {"vertex_sha256":Mesh.ARRAY_VERTEX,"normal_sha256":Mesh.ARRAY_NORMAL,"uv_sha256":Mesh.ARRAY_TEX_UV,"index_sha256":Mesh.ARRAY_INDEX}
	for key: String in keys:
		if _bytes_sha(arrays[keys[key]].to_byte_array())!=expected[key]: return null
	var result:=ArrayMesh.new()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var shader:=Shader.new()
	shader.code="""shader_type spatial;render_mode cull_disabled,depth_prepass_alpha;
uniform sampler2D original_diffuse:source_color,filter_linear_mipmap_anisotropic,repeat_disable;
uniform sampler2D original_normal:filter_linear_mipmap_anisotropic,repeat_disable;
uniform sampler2D original_specular:filter_linear_mipmap_anisotropic,repeat_disable;
void fragment(){vec4 c=texture(original_diffuse,UV);ALBEDO=c.rgb;ALPHA=c.a;ALPHA_SCISSOR_THRESHOLD=.35;NORMAL_MAP=texture(original_normal,UV).rgb;NORMAL_MAP_DEPTH=.7;SPECULAR=clamp(texture(original_specular,UV).r*.65,0.,1.);ROUGHNESS=.82;}
"""
	var material:=ShaderMaterial.new()
	material.shader=shader
	for channel: String in ["diffuse","normal","specular"]:
		var path: String=BAMBOO_ROOT+"original/"+channel+".tga"
		var sha: String=FileAccess.get_sha256(path)
		var verified := false
		for record in registry["files"]:
			if record["path"]=="original/"+channel+".tga" and String(record["sha256"]).to_lower()==sha: verified=true
		if not verified: return null
		if not textures.has(path):
			var image: Image=Image.load_from_file(path)
			if image==null or image.generate_mipmaps()!=OK: return null
			textures[path]=ImageTexture.create_from_image(image)
			texture_evidence.append({"path":path,"sha256":sha,"source_path":BAMBOO_ROOT+"SOURCE.json","source_sha256":FileAccess.get_sha256(BAMBOO_ROOT+"SOURCE.json"),"actual_mips":image.get_mipmap_count(),"license":"CC0-1.0","usage":"original author UVs and diffuse/normal/specular; NOT model atlas used as terrain or roughness scan"})
		material.set_shader_parameter("original_"+channel,textures[path])
	result.surface_set_material(0,material)
	geometry_evidence["bamboo"]={"source":BAMBOO_RAW,"source_sha256":FileAccess.get_sha256(BAMBOO_RAW),"derived_source":BAMBOO_MESH,"derived_sha256":FileAccess.get_sha256(BAMBOO_MESH),"native_import_receipt":BAMBOO_ROOT+"derived/native_import_record.json","receipt_sha256":FileAccess.get_sha256(BAMBOO_ROOT+"derived/native_import_record.json"),"source_import_method":"verified Godot4.6.2 ResourceImporterOBJ ArrayMesh; original positions/normals/UVs/indices exact","actual_surfaces":receipt["surfaces"],"source_units_declared":false,"metric_scale_is_authoring_choice":.015}
	return result

static func low_grass(variant: int) -> ArrayMesh:
	if FileAccess.get_sha256(HERB)!=HERB_SHA: return null
	var document:=GLTFDocument.new()
	var state:=GLTFState.new()
	if document.append_from_file(HERB,state)!=OK: return null
	var scene: Node=document.generate_scene(state)
	if scene==null: return null
	var nodes: Array[MeshInstance3D]=[]
	_collect(scene,nodes)
	if nodes.size()!=4:
		scene.free()
		return null
	var node: MeshInstance3D=nodes[variant%4]
	var mesh: ArrayMesh=node.mesh as ArrayMesh
	if mesh==null:
		scene.free()
		return null
	var result:=ArrayMesh.new()
	for i in range(mesh.get_surface_count()):
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,mesh.surface_get_arrays(i))
		var original: StandardMaterial3D=mesh.surface_get_material(i) as StandardMaterial3D
		if original==null:
			scene.free()
			return null
		var material: StandardMaterial3D=original.duplicate() as StandardMaterial3D
		for key: String in ["albedo_texture","normal_texture","roughness_texture","ao_texture"]:
			var texture: Texture2D=material.get(key)
			if texture==null: continue
			var identity: String="herb_"+String(key)+"_"+str(texture.get_instance_id())
			var image: Image=texture.get_image().duplicate() as Image
			if image==null or (image.is_compressed() and image.decompress()!=OK) or image.generate_mipmaps()!=OK:
				scene.free()
				return null
			textures[identity]=ImageTexture.create_from_image(image)
			material.set(key,textures[identity])
		material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		if material.transparency!=BaseMaterial3D.TRANSPARENCY_DISABLED:
			material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			material.alpha_scissor_threshold=.4
		result.surface_set_material(i,material)
	geometry_evidence["marsh_%d"%variant]={"source":HERB,"source_sha256":HERB_SHA,"source_import_method":"GLTFDocument raw scene; select one of four independent shrub variants and remove directory translation only","selected_node":String(node.name),"selected_variant":variant%4,"nature":"real low ground plant, NOT tall reeds","geometry_indices_unchanged":true,"license_evidence":"docs/licensed-world-assets-polyhaven-20260929.md registered Shrub03 CC0","material_derivative":"original maps duplicated before decompression/mips; original glTF/texture bytes unchanged; anisotropic mips and existing alpha surfaces scissor.4"}
	scene.free()
	return result

static func _collect(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D: result.append(node as MeshInstance3D)
	for child in node.get_children(): _collect(child,result)

static func _bytes_sha(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

static func plant(kind: String,variant: int=0) -> ArrayMesh:
	return bamboo() if kind=="bamboo" else low_grass(variant)

static func release() -> void:
	textures.clear()
	texture_evidence.clear()
	geometry_evidence.clear()

static func timber_material() -> ShaderMaterial:
	var shader:=Shader.new()
	shader.code="""shader_type spatial;uniform float native_timber_contract=1.;varying vec3 p;void vertex(){p=VERTEX;}void fragment(){float grain=.5+.5*sin(p.x*92.+sin(p.y*12.+p.z*8.)*2.);float weather=.5+.5*sin(p.x*13.+p.y*17.);ALBEDO=mix(vec3(.17,.12,.068),vec3(.42,.31,.18),grain*.45+weather*.4);ROUGHNESS=clamp(.91*native_timber_contract,0.,1.);SPECULAR=.18;}"""
	var result:=ShaderMaterial.new()
	result.shader=shader
	return result


static func waymarker() -> ArrayMesh:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var box:=BoxMesh.new()
	box.size=Vector3(.08,.75,.08)
	tool.append_from(box,0,Transform3D(Basis.IDENTITY,Vector3(0,.375,0)))
	box=BoxMesh.new()
	box.size=Vector3(.42,.16,.035)
	tool.append_from(box,0,Transform3D(Basis.IDENTITY,Vector3(.08,.57,0)))
	var arrow:=SurfaceTool.new()
	arrow.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in [Vector3(.29,.49,.022),Vector3(.38,.57,.022),Vector3(.29,.65,.022)]: arrow.add_vertex(p)
	arrow.generate_normals()
	var arrow_mesh: ArrayMesh=arrow.commit()
	tool.append_from(arrow_mesh,0,Transform3D.IDENTITY)
	var mesh: ArrayMesh=tool.commit()
	mesh.surface_set_material(0,timber_material())
	return mesh

static func discovery() -> ArrayMesh:
	var tool:=SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var base:=BoxMesh.new()
	base.size=Vector3(.30,.17,.20)
	tool.append_from(base,0,Transform3D(Basis.IDENTITY,Vector3(0,.085,0)))
	var plank:=BoxMesh.new()
	plank.size=Vector3(.33,.022,.22)
	tool.append_from(plank,0,Transform3D(Basis.IDENTITY,Vector3(0,.18,0)))
	# Visible slats/ribs and bound material rolls, not a single solid brown box.
	for offset: float in [-.12,-.04,.04,.12]:
		plank=BoxMesh.new()
		plank.size=Vector3(.022,.155,.225)
		tool.append_from(plank,0,Transform3D(Basis.IDENTITY,Vector3(offset,.09,0)))
	var roll:=CylinderMesh.new()
	roll.top_radius=.03
	roll.bottom_radius=.03
	roll.height=.27
	roll.radial_segments=10
	for i in range(3): tool.append_from(roll,0,Transform3D(Basis(Vector3.FORWARD,PI*.5),Vector3(0,.225+i*.035,0)))
	var mesh: ArrayMesh=tool.commit()
	mesh.surface_set_material(0,timber_material())
	return mesh
