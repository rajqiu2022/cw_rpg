extends RefCounted

# NEW independent lightweight caster proposal. No export or SceneTree execution.
# This is an honest 2.5D plane made from the *actual* native prototype PNG, NOT
# the original GLTF draw geometry, and NOT an unrelated reused shadow image.
# Must receive root regional GPU ON/OFF approval before any FULL executor use.
const IDENTITY := "V7_ACTUAL_PROTOTYPE_RGBA_CAMERA_PLANE_CASTER_SOURCE_ONLY"
const LOGICAL_PPM := 102.4
const CAMERA_RIGHT := Vector3(1,0,0)
const CAMERA_UP := Vector3(0,0.7071067811865476,-0.7071067811865476)
const CAMERA_BACK := Vector3(0,0.7071067811865476,0.7071067811865476)
const SHADOW_ALPHA_SCISSOR := 0.12
var error := ""
var evidence: Dictionary={}

func create_caster(prototype: Dictionary,source_foot_world_m: Vector3) -> MeshInstance3D:
	error=""
	evidence.clear()
	for key in ["texture","texture_sha256","foot_uv","render_size_px"]:
		if not prototype.has(key):
			error="Missing actual prototype field: "+key
			return null
	var path: String=prototype["texture"]
	var actual_sha: String=FileAccess.get_sha256(path)
	if actual_sha.is_empty() or actual_sha.to_lower()!=String(prototype["texture_sha256"]).to_lower():
		error="Actual prototype PNG binding failed."
		return null
	var image: Image=Image.load_from_file(path)
	if image==null or image.is_empty():
		error="Actual prototype alpha image absent."
		return null
	var uv: Vector2=_vec2(prototype["foot_uv"])
	var logical: Vector2=_vec2(prototype["render_size_px"])
	if logical!=Vector2(image.get_size()) or not Rect2(Vector2.ZERO,Vector2.ONE).has_point(uv):
		error="Proposal requires exact 1:1 actual prototype canvas and measured foot_uv."
		return null
	# Mips are created on a duplicate, never mutate an imported original image.
	var duplicate: Image=image.duplicate() as Image
	if duplicate.generate_mipmaps()!=OK:
		error="Actual alpha prototype mip construction failed."
		return null
	var texture:=ImageTexture.create_from_image(duplicate)
	var material:=StandardMaterial3D.new()
	material.albedo_texture=texture
	material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.alpha_scissor_threshold=SHADOW_ALPHA_SCISSOR
	material.cull_mode=BaseMaterial3D.CULL_DISABLED
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	# PNG already contains its original native lighting. A diagnostic visible
	# plane must not light it a second time; shadow casting still uses real alpha.
	material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var positions:=PackedVector3Array()
	var uvs:=PackedVector2Array([Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)])
	var normals:=PackedVector3Array()
	for texcoord in uvs:
		var screen:=Vector2((texcoord.x-uv.x)*logical.x,(uv.y-texcoord.y)*logical.y)
		positions.append(CAMERA_RIGHT*(screen.x/LOGICAL_PPM)+CAMERA_UP*(screen.y/LOGICAL_PPM))
		normals.append(CAMERA_BACK)
	var indices:=PackedInt32Array([0,1,2,1,3,2])
	var arrays: Array=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=positions
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_TEX_UV]=uvs
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	mesh.surface_set_material(0,material)
	var caster:=MeshInstance3D.new()
	caster.mesh=mesh
	caster.position=source_foot_world_m
	caster.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	var actual: Array=mesh.surface_get_arrays(0)
	evidence={"identity":IDENTITY,"status":"SOURCE_ONLY_NOT_GPU_VERIFIED_OR_APPROVED","actual_sourcebody_path":path,"actual_sourcebody_sha256":actual_sha,"logical_canvas_px":[logical.x,logical.y],"actual_foot_uv":[uv.x,uv.y],"world_foot_m":[source_foot_world_m.x,source_foot_world_m.y,source_foot_world_m.z],"basis_columns":[[CAMERA_RIGHT.x,CAMERA_RIGHT.y,CAMERA_RIGHT.z],[CAMERA_UP.x,CAMERA_UP.y,CAMERA_UP.z],[CAMERA_BACK.x,CAMERA_BACK.y,CAMERA_BACK.z]],"logical_pixels_per_metre":LOGICAL_PPM,"actual_surface_count":mesh.get_surface_count(),"actual_draw_vertices":4,"actual_draw_indices":6,"actual_triangles":2,"native_stored_vertex_sha256":_hash(actual[Mesh.ARRAY_VERTEX].to_byte_array()),"native_stored_normal_sha256":_hash(actual[Mesh.ARRAY_NORMAL].to_byte_array()),"native_stored_uv_sha256":_hash(actual[Mesh.ARRAY_TEX_UV].to_byte_array()),"native_stored_index_sha256":_hash(actual[Mesh.ARRAY_INDEX].to_byte_array()),"actual_material_properties":{"transparency":material.transparency,"alpha_scissor_threshold":material.alpha_scissor_threshold,"cull_mode":material.cull_mode,"texture_filter":material.texture_filter,"shading_mode":material.shading_mode},"actual_cast_shadow_enum":caster.cast_shadow,"support_recipe":"plane origin is measured original prototype foot; transparent canvas vertices may be below it. NOT original GLTF minY0 support proof; original 2.5D sprite support and separate trunk collider retained","source_geometry_scope":"new project-authored camera plane derived from registered CC0 model's verified native RGBA render; do not claim plane is licensed model geometry","ground_shadow_scope":"must be newly rendered with actual plane/texture/current global light/RF; do not reuse unrelated original shadow raster","required_countercases":["actual same-camera plane body vs bound source PNG at SSAA2 alpha-aware readback","actual plane shadowON/OFF and world minY/foot support record","body alpha12 support vs original PNG; shadow scissor edges disclosed","binary caster.visible=false and authority nav unchanged","region >8% alpha union, new object physical/Y and depth QA"]}
	return caster

func _vec2(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Array and value.size()==2: return Vector2(float(value[0]),float(value[1]))
	return Vector2(INF,INF)

func _hash(bytes: PackedByteArray) -> String:
	var context:=HashingContext.new()
	if context.start(HashingContext.HASH_SHA256)!=OK: return ""
	if not bytes.is_empty() and context.update(bytes)!=OK: return ""
	return context.finish().hex_encode()
