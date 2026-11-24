extends "res://scripts/dev/build_world_map_v15_complete_v5_full_draft.gd"

# Fault diagnosis only: exact ROOT066 inputs are not production reuse approval.
# No height generation, selector generation, ART write, publisher or Field call.
const DIAG_ROOT := "res://build/world_map_v15_root066_seam_visibility/"
const PINNED_INPUTS := {
	"res://art/external/polyhaven/world_terrain_v14_sixth/forest_ground_04/forest_ground_04_arm_2k.jpg": "a6086cb5611fabcc3dd4c9ac74bcf6cf8ed5d07e136ebe51255a5a3bea9e42c6",
	"res://art/external/polyhaven/world_terrain_v14_sixth/leafy_grass/leafy_grass_arm_2k.jpg": "70d61c669fe9d186a84f5bb50e8a337083014d7e46534306a89d47d48fd5eb0e",
	"res://art/maps/world_map_v15_complete_v5/prototypes/native_boulder1.json": "782861d676d9953c832c298b0f67c44ea5c811a55bb1b9edb4ebc9e40f54a05d",
	"res://art/external/polyhaven/world_terrain_v14_sixth/leafy_grass/leafy_grass_nor_gl_2k.jpg": "df0cf0ce96e653f033e5b934d5b12995464bda027aa53bd12e329be889aa9f45",
	"res://art/maps/world_map_v15_complete_v5/source_topology.png": "5d65605fa804faacc03f5378dd4c87c8bcce0f27e38821f11c02a839e28dbb1a",
	"res://art/maps/world_map_v15_complete_v5/prototypes/native_boulder2_actual_draw_mesh.res": "4c0bd4a0e481da8d890bd422bb5045a3972645f48853703e986ec93118153656",
	"res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/SOURCE.json": "73cc622ff50055d27694ea3980f0894f5f4e370490b61c5353ed1d5064be83ef",
	"res://art/maps/world_map_v15_complete_v5/prototypes/native_boulder1_actual_draw_mesh.res": "2da0e549c0c6fc4fdd8f876a8665e627fedf938c2b35f76bfff90c804f54c48c",
	"res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/grass_ground_arm_2k.jpg": "79554d3cb2c1cbf4351960e16bc6bba004fa3112d256ff1b500ac994694b5673",
	"res://art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock/aerial_grass_rock_diff_2k.jpg": "1a2ddfa4652adbe00447b940c40019d46f4b88245bc1b341cdf622c2110b7bc5",
	"res://scripts/dev/world_map_v15_complete_v5_surface.gd": "ad83c3c9626f86628638f1bea7abcb9b4bd7113917694fc138e14d0198cd7480",
	"res://scripts/dev/build_world_map_v15_complete_v5_full_draft.gd": "2e5efff6bf27f478bea3f6a1131c2919cdd502c6fa37f7969d60067a8c4d2f85",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/SOURCE.json": "33b0d87d8a159028397b6a7a112b66106e5b78d87130d385a26f7471eed5487a",
	"res://scripts/dev/world_map_v15_complete_v5_source.gd": "f812bcd93efe93da54866c2d61287feaeaf6bc68543493b4b54a606d99769299",
	"res://art/maps/world_map_v15_complete_v5/terrain_height.rf": "b7210634cbc2d7a2809bfab608e47930d5717459b01dc42df33ae9e6919548b9",
	"res://art/external/polyhaven/world_terrain_v14_sixth/forest_ground_04/SOURCE.json": "12565a69843af8671a4bd553358a43d3cf1cc60c12d0ddb51ddfeaa2affe1c64",
	"res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/brown_mud_03_diff_2k.jpg": "57a87dae26769677578ab53b8829fe9b1e4dfec1ae1726f2942ce99fc73f400b",
	"res://art/maps/world_map_v15_complete_v5/prototypes/native_boulder2.json": "9db386cde64980d6e29ad3b60b6e6043e5b4f22f034a036497ddaaf69537725e",
	"res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/grass_ground_diff_2k.jpg": "4272bddc71a7fa659d1deeb13a9df8c42e68a5ac8cde7523187e4a081e028258",
	"res://art/maps/world_map_v15_complete_v5/prototypes/native_boulder0_actual_draw_mesh.res": "e6f8553314e01bfc21b7cd457a596a887695aed454bbf952082de84fe0620d9d",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_diff_2k.jpg": "fe9013368539b5604602e64bfa48bef1a2a4c452fcb6894868fb556d0b14501c",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c0_actual_deck_support_mesh.res": "668022ddb74892023ef214dac5551f9b49f79d9958ccfb1126646bc7934923a9",
	"res://art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock/aerial_grass_rock_arm_2k.jpg": "a7daabd9aa877f861ced2830b792709f31a399324db47df2bdac256c0414fc14",
	"res://art/maps/world_map_v15_complete_v5/prototypes/native_boulder0.json": "bfdebaa990e6fb38a0cc474c9903411a93732f5ef69a0c85a21457a7d49dee1a",
	"res://art/external/polyhaven/world_terrain_v14_ninth/grass_ground/grass_ground_nor_gl_2k.jpg": "effa95c06af273c974476d9a74a234668a1c9292f60fffb4fa40348d638ee7f3",
	"res://art/external/polyhaven/world_terrain_v14_sixth/forest_ground_04/forest_ground_04_diff_2k.jpg": "24b8aaf4c8547305d80b0e029ec365219ab1b90748d4ca5651bdc9e75bfde5e6",
	"res://art/maps/world_map_v15_complete_v5/capture/terrain_shader.gdshader": "92ca544f08420a5acbce44390dff62d52f7eb0e4a51f397957af6296b6bbe4e5",
	"res://art/external/polyhaven/world_terrain_v14_sixth/leafy_grass/SOURCE.json": "b35404be1d8d24cafbb76b196b3046cadcc8d5362637a8711587d17daf49838e",
	"res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/SOURCE.json": "2a63317c447af47cc9752d33ad8e3bd5801159c294dc53753c557fd27626ae90",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c0_actual_terrain_mesh.res": "2c2847f1e7cc4e0948d39e8eac62cac948c35a7b31f8470c54886010120f8265",
	"res://art/maps/world_map_v15_complete_v5/terrain_mesh.res": "2eb9ad81081768f938798bf4879df705505783d2aeb9b328927289f7b51d2a9a",
	"res://scripts/dev/world_v15_outskirts_complete_v5_vegetation.gd": "032a483213e99649b4adec193d24f413cc897ccc6b7de52a29f46a26abb9a23f",
	"res://art/external/polyhaven/world_terrain_v14_sixth/leafy_grass/leafy_grass_diff_2k.jpg": "8e1c6d21365d4b89bc5a35ab664da98a78dbc3ab9ba6100474881c8619a5b113",
	"res://art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock/aerial_grass_rock_nor_gl_2k.jpg": "c6aa14b042ce243f93a6ca807f46a085711c23ad316b104578e92df7770ee285",
	"res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/brown_mud_03_arm_2k.jpg": "29dae9a0c85cb0b91bd8c9b878d184f36363472212bd6a02662f415627f06992",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_arm_2k.jpg": "a954de58336738e6f963466f1453202ef7e186bd6492106c3b989c39f0d2e23c",
	"res://art/external/polyhaven/world_terrain_v14_eighth/aerial_grass_rock/SOURCE.json": "49d4c930aac5b955aad2c2061caa625186a00fbc575aad31f15a7a5fc3bdec10",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c1_actual_terrain_mesh.res": "4a461fcf794d30f9a988fd7f6985542f0107465a8c99a821a67df7ec915428bb",
	"res://art/external/polyhaven/world_terrain_v14_sixth/forest_ground_04/forest_ground_04_nor_gl_2k.jpg": "b37ac799ed410976541e0011c246fca254e74eaa3f096ae7a7d74178db5a6d9b",
	"res://art/external/polyhaven/world_terrain_v14_sixth/brown_mud_03/brown_mud_03_nor_gl_2k.jpg": "4d9ea1c9321618dbde7bdb2287fae85b646e4bd7b27c294a3475096d30b33880",
	"res://art/external/polyhaven/world_terrain_v14_sixth/rock_01/rock_01_nor_gl_2k.jpg": "70427a2c81f85c0e1ee4a147e273d028c3d0188bad2583f2509d6df9a3d55b89",
	"res://art/maps/world_map_v15_complete_v5/seams/r0_c0--r0_c1_actual_terrain_mesh.res": "0d37c50d75d4cabe07a277edadd23536582a90ae41b7e6927649e9a609208348"
}
const ORIGINAL_PNGS := {
	"res://art/maps/world_map_v15_complete_v5/seams/r0_c0--r0_c1_walk.png": "21302105c2f77b7bc8ebb9a7871accdd1c1bc416042a2b2b7ad578153b75abe0",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c0_raw_walk.png": "d1ea0fea18eb3e9160422682ca8e8b9f5db68b6c626d987bbd43ae780e3eb5f6",
	"res://art/maps/world_map_v15_complete_v5/seams/r0_c0--r0_c1_visual.png": "d83a0faad7b3dbe5517a5ac7eb7f7cabed4027184e60b23ee47455fa4a0d7e45",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c1_walk.png": "05c83fdb5f1f2de9c549c305f8fc2297851ab2a0c25e9bd70a6f942475607eff",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c1_land.png": "fd5b767781837d5db52f5d556d8585def42cc9ab5969a3ab08fb67d3e19c1278",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c0_visual.png": "2742c70293141ada069dfe2c5f779a38096f727ff8bd7edab646b0aff91d1b57",
	"res://art/maps/world_map_v15_complete_v5/seams/r0_c0--r0_c1_shadow_off.png": "5525bf4a363110afa3366724412e6d96a2174ff835e91802954e0af49f634d76",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c0_shadow_off.png": "c779e67b88031f4913aefdb072de88f90588d1b1a046e70dc4293ce287460c6a",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c1_shadow_off.png": "acf82dd126b70ef81a72b3b9f5d762ba02c531d6f85e9ab7c955d46502e14ba2",
	"res://art/maps/world_map_v15_complete_v5/seams/r0_c0--r0_c1_land.png": "80ebf5817ac11325857d0628ebd21a2be20c5eb4a9fe69454079aec72ae3bd81",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c1_raw_walk.png": "05c83fdb5f1f2de9c549c305f8fc2297851ab2a0c25e9bd70a6f942475607eff",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c0_walk.png": "d1ea0fea18eb3e9160422682ca8e8b9f5db68b6c626d987bbd43ae780e3eb5f6",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c0_land.png": "2c76fea598a1f7d525c8aa5d89ad76d587a4dcdecb4aed208ad355cb8ea00dfb",
	"res://art/maps/world_map_v15_complete_v5/chunks/r0_c1_visual.png": "68d046131c39b43c07226e62a39331d5230fd281da8a06bce55bd1dbca8292ee",
	"res://art/maps/world_map_v15_complete_v5/seams/r0_c0--r0_c1_raw_walk.png": "21302105c2f77b7bc8ebb9a7871accdd1c1bc416042a2b2b7ad578153b75abe0"
}
var diagnostic_output := ""
var diagnostic_prototypes: Dictionary={}
var diagnostic_records: Dictionary={}
var cached_global_mesh: ArrayMesh
var cached_shader: Shader

func _run() -> void:
	var args:=OS.get_cmdline_user_args()
	if "--diagnose-root066-seam" not in args or DisplayServer.get_name()=="headless":
		error="Explicit diagnostic GPU argument required; no headless pseudo-render."
		failure_output=DIAG_ROOT
		await _finish(false)
		return
	diagnostic_output=DIAG_ROOT+str(Time.get_unix_time_from_system()).replace(".","_")+"/"
	failure_output=diagnostic_output
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(diagnostic_output))
	for path: String in PINNED_INPUTS:
		if FileAccess.get_sha256(path).to_lower()!=PINNED_INPUTS[path]:
			error="Changed ROOT066 diagnostic input: "+path
			await _probe_finish(false)
			return
	for path: String in ORIGINAL_PNGS:
		if FileAccess.get_sha256(path).to_lower()!=ORIGINAL_PNGS[path]:
			error="Changed original failure image: "+path
			await _probe_finish(false)
			return
	for name: String in BOULDER_RAW_SHA:
		if FileAccess.get_sha256(BOULDER.get_base_dir()+"/"+name)!=BOULDER_RAW_SHA[name]:
			error="Changed original boulder dependency: "+name
			await _probe_finish(false)
			return
	source=SOURCE.new()
	var rf_bytes: PackedByteArray=FileAccess.get_file_as_bytes(FULL_ROOT+"terrain_height.rf")
	if rf_bytes.size()!=SOURCE.GRID_SIZE.x*SOURCE.GRID_SIZE.y*4:
		error="Cached Float32 RF shape mismatch."
		await _probe_finish(false)
		return
	source.heights=rf_bytes.to_float32_array()
	# prepare evaluates finite route/ecology definitions against cached RF;
	# it never generates the full height grid or the 25M selector cells.
	source.prepare()
	full_rf=ImageTexture.create_from_image(Image.create_from_data(SOURCE.GRID_SIZE.x,SOURCE.GRID_SIZE.y,false,Image.FORMAT_RF,rf_bytes))
	var topology: Image=Image.load_from_file(FULL_ROOT+"source_topology.png")
	if topology==null or topology.get_size()!=SOURCE.SIZE/SOURCE.SELECTOR_STEP:
		error="Actual cached topology missing."
		await _probe_finish(false)
		return
	full_topology=ImageTexture.create_from_image(topology)
	cached_global_mesh=load(FULL_ROOT+"terrain_mesh.res") as ArrayMesh
	cached_shader=load(FULL_ROOT+"capture/terrain_shader.gdshader") as Shader
	if cached_global_mesh==null or cached_shader==null:
		error="Cached actual mesh/shader missing."
		await _probe_finish(false)
		return
	surface=SURFACE.new()
	if not surface.load_sources():
		error=surface.error
		await _probe_finish(false)
		return
	# ROOT066 did not persist these two textures. Recreate their exact 8px
	# global method once (1.57M points), not RF or conservative 25M topology.
	full_map_textures=_material_maps(Rect2(Vector2.ZERO,Vector2(SOURCE.SIZE)))
	var map_evidence: Dictionary={}
	for role: String in ["ecology","roads"]:
		var image: Image=full_map_textures[role].get_image()
		var path: String=diagnostic_output+role+"_reconstructed.png"
		if image.save_png(path)!=OK:
			error="Cannot save actual reconstructed weight texture."
			await _probe_finish(false)
			return
		map_evidence[role]={"path":path,"sha256":FileAccess.get_sha256(path),"size":[image.get_width(),image.get_height()],"method":"unchanged parent _material_maps global 8px centres; no topology generation"}
	for pose in range(3):
		var prefix: String=FULL_ROOT+"prototypes/native_boulder"+str(pose)
		var parsed: Variant=JSON.parse_string(FileAccess.get_file_as_string(prefix+".json"))
		if not parsed is Dictionary:
			error="Cached native caster record missing."
			await _probe_finish(false)
			return
		var mesh: ArrayMesh=load(parsed["actual_draw_mesh_path"]) as ArrayMesh
		if mesh==null:
			error="Cached native caster draw mesh missing."
			await _probe_finish(false)
			return
		diagnostic_prototypes[pose]={"mesh":mesh,"record":parsed,"basis":Basis(_array_v3(parsed["basis_columns"][0]),_array_v3(parsed["basis_columns"][1]),_array_v3(parsed["basis_columns"][2])),"support":_array_v3(parsed["support_m"])}
	var basis_fixed: bool="--fixed-native-basis" in args
	var cases: Array[Dictionary]=[
		{"id":"tile_left","rect":Rect2(0,0,1536,1024),"mesh_path":FULL_ROOT+"chunks/r0_c0_actual_terrain_mesh.res","geometry_rect":Rect2(-1024,-1024,3584,3072),"logical":Vector2i(1728,1216),"crop":Rect2i(96,96,1536,1024)},
		{"id":"tile_right","rect":Rect2(1536,0,1536,1024),"mesh_path":FULL_ROOT+"chunks/r0_c1_actual_terrain_mesh.res","geometry_rect":Rect2(512,-1024,3584,3072),"logical":Vector2i(1728,1216),"crop":Rect2i(96,96,1536,1024)},
		{"id":"strip_original","rect":Rect2(1520,0,32,1024),"mesh_path":FULL_ROOT+"seams/r0_c0--r0_c1_actual_terrain_mesh.res","geometry_rect":Rect2(496,-1024,2080,3072),"logical":Vector2i(224,1216),"crop":Rect2i(96,96,32,1024)},
		# Single-variable aspect control against strip_original: same mesh,
		# camera target/size/basis/light/casters, only wider native viewport.
		{"id":"strip_equal_canvas","rect":Rect2(1520,0,32,1024),"mesh_path":FULL_ROOT+"seams/r0_c0--r0_c1_actual_terrain_mesh.res","geometry_rect":Rect2(496,-1024,2080,3072),"logical":Vector2i(1728,1216),"crop":Rect2i(848,96,32,1024)}
	]
	for item: Dictionary in cases:
		var measured: Dictionary=await _probe_case(item,basis_fixed)
		if measured.is_empty():
			await _probe_finish(false)
			return
		diagnostic_records[item["id"]]=measured
	var comparisons: Dictionary={}
	var every_role_exact := true
	for role: String in ["visual","shadow_off","land","raw_walk","walk"]:
		var left: Image=diagnostic_records["tile_left"]["images"][role]
		var right: Image=diagnostic_records["tile_right"]["images"][role]
		var expected:=Image.create(32,1024,false,Image.FORMAT_RGBA8)
		expected.blit_rect(left,Rect2i(1520,0,16,1024),Vector2i.ZERO)
		expected.blit_rect(right,Rect2i(0,0,16,1024),Vector2i(16,0))
		var narrow: Image=diagnostic_records["strip_original"]["images"][role]
		var wide: Image=diagnostic_records["strip_equal_canvas"]["images"][role]
		comparisons[role]={"tile_pair_vs_original_strip":_difference(expected,narrow),"tile_pair_vs_equal_canvas_strip":_difference(expected,wide),"only_strip_viewport_width_changed":_difference(narrow,wide)}
		if not bool(comparisons[role]["tile_pair_vs_original_strip"]["byte_exact"]): every_role_exact=false
	var legacy_comparisons: Dictionary={}
	for mapping: Array in [["tile_left","chunks/r0_c0"],["tile_right","chunks/r0_c1"],["strip_original","seams/r0_c0--r0_c1"]]:
		var per_role: Dictionary={}
		for role: String in ["visual","shadow_off","land","raw_walk","walk"]:
			var original: Image=Image.load_from_file(FULL_ROOT+String(mapping[1])+"_"+role+".png")
			if original==null:
				error="Pinned original PNG decode failed."
				await _probe_finish(false)
				return
			original.convert(Image.FORMAT_RGBA8)
			per_role[role]={"original_vs_current":_difference(original,diagnostic_records[mapping[0]]["images"][role])}
			if role in ["land","raw_walk","walk"]: per_role[role]["original_binary_purity"]=_binary_stats(original)
		legacy_comparisons[mapping[0]]=per_role
	var public_records: Dictionary={}
	for id: String in diagnostic_records:
		var record: Dictionary=diagnostic_records[id].duplicate()
		record.erase("images")
		public_records[id]=record
	var result: Dictionary={"status":"DIAGNOSTIC_COMPLETED_NOT_PRODUCTION_REUSE_OR_VISUAL_APPROVAL","diagnostic_completed":true,"all_original_frustum_roles_byte_exact":every_role_exact,"executed_fixture_path":get_script().resource_path,"executed_fixture_sha256":FileAccess.get_sha256(get_script().resource_path),"pinned_fault_inputs":PINNED_INPUTS,"pinned_original_images":ORIGINAL_PNGS,"materials":surface.evidence,"actual_reconstructed_weight_maps":map_evidence,"basis_variant":"explicit ROOT066 basis" if basis_fixed else "unchanged Camera3D.look_at","cases":public_records,"comparisons":comparisons,"legacy_visibility_repair_comparisons":legacy_comparisons,"no_threshold_relaxation":true,"no_height_topology_generation":true,"no_art_writes":true}
	if not _write_json(diagnostic_output+"result.json",result):
		await _probe_finish(false)
		return
	print("ROOT066_DIAGNOSTIC_COMPLETE ",diagnostic_output," seam_exact=",every_role_exact)
	await _probe_finish(true)

func _array_v3(raw: Array) -> Vector3:
	return Vector3(raw[0],raw[1],raw[2])

func _probe_case(item: Dictionary,basis_fixed: bool) -> Dictionary:
	var id: String=item["id"]
	var rect: Rect2=item["rect"]
	var logical: Vector2i=item["logical"]
	var crop: Rect2i=item["crop"]
	active_view=SubViewport.new()
	active_view.size=logical*SSAA
	active_view.msaa_3d=Viewport.MSAA_DISABLED
	active_view.own_world_3d=true
	active_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(active_view)
	var world:=Node3D.new()
	active_view.add_child(world)
	var env:=WorldEnvironment.new()
	env.environment=surface.environment()
	world.add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-55,-34,0)
	sun.light_energy=.85
	sun.shadow_enabled=true
	sun.shadow_normal_bias=2.
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance=60.
	world.add_child(sun)
	var terrain:=MeshInstance3D.new()
	terrain.mesh=load(item["mesh_path"]) as ArrayMesh
	if terrain.mesh==null:
		error="Missing actual cached window mesh."
		return {}
	var material: ShaderMaterial=surface.terrain_material(full_map_textures["ecology"],full_map_textures["roads"],Rect2(Vector2.ZERO,Vector2(SOURCE.SIZE)))
	if material==null or material.shader==null or material.shader.code!=cached_shader.code:
		error="Cached shader and actual material code differ."
		return {}
	terrain.material_override=material
	world.add_child(terrain)
	var water:=MeshInstance3D.new()
	water.mesh=_mesh(item["geometry_rect"],true)
	water.material_override=surface.water_material(full_rf,Vector2i.ZERO,SOURCE.GRID_SIZE)
	water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(water)
	var camera:=Camera3D.new()
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=float(logical.y)/SOURCE.PPM
	camera.near=.05
	camera.far=100.
	var target: Vector3=SOURCE.point3(rect.get_center(),0.)
	camera.position=target+Vector3(0,20,20)
	world.add_child(camera)
	camera.look_at(target)
	if basis_fixed: camera.basis=Basis(Vector3(1,0,0),Vector3(0,.70710676908493,-.70710676908493),Vector3(0,.70710676908493,.70710676908493))
	camera.current=true
	var coverage: Dictionary=_receiver_coverage(camera,terrain.mesh as ArrayMesh,active_view.size)
	if not coverage["passed"]:
		error="Diagnostic actual mesh/camera coverage failed."
		return {}
	var casters: Array[MeshInstance3D]=[]
	var caster_records: Array[Dictionary]=[]
	for site: Dictionary in source.vegetation_sites:
		if not Rect2(item["geometry_rect"]).has_point(site["source_foot"]): continue
		if site["kind"]!="boulder":
			error="Unexpected native species in bounded cached north diagnosis: "+String(site["kind"])
			return {}
		var proto: Dictionary=diagnostic_prototypes[int(site["pose"])]
		var caster:=MeshInstance3D.new()
		caster.mesh=proto["mesh"]
		var foot: Vector2=site["source_foot"]
		caster.transform=Transform3D(proto["basis"],SOURCE.point3(foot,source.triangle_height(foot))-Vector3(proto["support"]))
		caster.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		world.add_child(caster)
		casters.append(caster)
		caster_records.append({"id":site["id"],"pose":site["pose"],"source_foot":[foot.x,foot.y],"mesh_path":proto["record"]["actual_draw_mesh_path"],"mesh_sha256":proto["record"]["actual_draw_mesh_sha256"],"basis_columns":[_v3(caster.basis.x),_v3(caster.basis.y),_v3(caster.basis.z)],"origin":_v3(caster.position),"actual_on_cast_shadow_enum":caster.cast_shadow})
	await _sync()
	if not _shader_gate(material,["biome_weights","road_weights","grass_ground_diff","rock_01_arm"]) or not _shader_gate(water.material_override,["actual_height_rf","grid_origin","grid_shape"]):
		error="Actual diagnostic shader binding failed."
		return {}
	var images: Dictionary={}
	var outputs: Dictionary={}
	var on: Dictionary=await _full_read_exact(diagnostic_output+id+"_visual",logical,SSAA,crop)
	if on.is_empty(): return {}
	images["visual"]=on["logical_image"]
	on.erase("logical_image")
	outputs["visual"]=on
	# The authorized repair is visibility, NOT reducing the shadow shader.
	# Their SHADOWS_ONLY material/geometry/transform remains unchanged.
	for caster in casters: caster.visible=false
	var off: Dictionary=await _full_read_exact(diagnostic_output+id+"_shadow_off",logical,SSAA,crop)
	if off.is_empty(): return {}
	images["shadow_off"]=off["logical_image"]
	off.erase("logical_image")
	outputs["shadow_off"]=off
	active_view.size=logical
	water.visible=false
	env.environment.background_mode=Environment.BG_COLOR
	env.environment.background_color=Color(0,0,0,1)
	terrain.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	terrain.material_override=_full_authority(0)
	var land: Dictionary=await _full_read_exact(diagnostic_output+id+"_land",logical,1,crop)
	if land.is_empty(): return {}
	images["land"]=land["logical_image"]
	land.erase("logical_image")
	outputs["land"]=land
	terrain.material_override=_full_authority(1)
	var raw_walk: Dictionary=await _full_read_exact(diagnostic_output+id+"_raw_walk",logical,1,crop)
	if raw_walk.is_empty(): return {}
	images["raw_walk"]=raw_walk["logical_image"]
	raw_walk.erase("logical_image")
	outputs["raw_walk"]=raw_walk
	var support:=MeshInstance3D.new()
	support.mesh=load(FULL_ROOT+"chunks/r0_c0_actual_deck_support_mesh.res") as ArrayMesh
	if support.mesh==null:
		error="Missing exact saved support mesh."
		return {}
	var white:=StandardMaterial3D.new()
	white.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	white.cull_mode=BaseMaterial3D.CULL_DISABLED
	white.albedo_color=Color.WHITE
	support.material_override=white
	world.add_child(support)
	var walk: Dictionary=await _full_read_exact(diagnostic_output+id+"_walk",logical,1,crop)
	if walk.is_empty(): return {}
	images["walk"]=walk["logical_image"]
	walk.erase("logical_image")
	outputs["walk"]=walk
	var binary: Dictionary={}
	for role: String in ["land","raw_walk","walk"]: binary[role]=_binary_stats(images[role])
	var camera_record: Dictionary={"projection":camera.projection,"size":camera.size,"position":_v3(camera.position),"basis_columns":[_v3(camera.basis.x),_v3(camera.basis.y),_v3(camera.basis.z)],"raw_canvas":[logical.x*SSAA,logical.y*SSAA],"logical_canvas":[logical.x,logical.y],"global_center_px":[rect.get_center().x,rect.get_center().y],"crop_px":[crop.position.x,crop.position.y,crop.size.x,crop.size.y]}
	active_view.queue_free()
	active_view=null
	await _sync()
	return {"id":id,"mesh_path":item["mesh_path"],"mesh_sha256":PINNED_INPUTS[item["mesh_path"]],"camera":camera_record,"coverage":coverage,"casters":caster_records,"off_method":"same SHADOWS_ONLY casters visible=false; no material/geometry/shadow bias change","binary_caster_visibility":false,"terrain_self_shadow_remains_on_during_visual_and_OFF":true,"outputs":outputs,"binary_purity":binary,"images":images}

func _binary_stats(image: Image) -> Dictionary:
	var bytes: PackedByteArray=image.get_data()
	var nonbinary:=0
	for pixel in range(bytes.size() >> 2):
		var n:=pixel*4
		var black: bool=bytes[n]==0 and bytes[n+1]==0 and bytes[n+2]==0
		var white: bool=bytes[n]==255 and bytes[n+1]==255 and bytes[n+2]==255
		if not black and not white: nonbinary+=1
	return {"pixels":bytes.size() >> 2,"nonbinary_rgb_pixels":nonbinary,"pure_black_white":nonbinary==0,"no_post_capture_thresholding":true}

func _difference(expected: Image,actual: Image) -> Dictionary:
	var a: PackedByteArray=expected.get_data()
	var b: PackedByteArray=actual.get_data()
	if expected.get_size()!=actual.get_size() or a.size()!=b.size(): return {"byte_exact":false,"size_mismatch":true}
	var count:=0
	var pixel_count:=0
	var alpha_count:=0
	var maximum:=0
	var histogram: Dictionary={}
	for pixel in range(a.size() >> 2):
		var changed:=false
		for channel in range(4):
			var n:=pixel*4+channel
			var delta: int=absi(int(a[n])-int(b[n]))
			if delta==0: continue
			count+=1
			changed=true
			maximum=maxi(maximum,delta)
			histogram[str(delta)]=int(histogram.get(str(delta),0))+1
			if channel==3: alpha_count+=1
		if changed: pixel_count+=1
	return {"byte_exact":count==0,"different_bytes":count,"different_pixels":pixel_count,"alpha_different_bytes":alpha_count,"max_delta":maximum,"absolute_delta_histogram":histogram}

func _probe_finish(completed: bool) -> void:
	diagnostic_records.clear()
	diagnostic_prototypes.clear()
	cached_global_mesh=null
	cached_shader=null
	await _finish(completed)

