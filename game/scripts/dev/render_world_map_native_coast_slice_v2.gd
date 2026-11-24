extends "res://scripts/dev/render_world_map_native_coast_slice_v1.gd"

# Art-direction experiment built on the same coastline/road/navigation source as v1.
# Poly Haven model provenance is recorded in docs/licensed-world-assets-polyhaven-20260929.md.
const CLIFF := "res://art/external/polyhaven/coastal_cliff_01/coastal_cliff_01_1k.gltf"
const SHRUB := "res://art/external/polyhaven/shrub_03/shrub_03_1k.gltf"
const SHRUB_POSITIONS := [Vector2(-7.0, -4.2), Vector2(-2.5, -4.5), Vector2(1.0, -3.3), Vector2(-8.0, 4.6), Vector2(-3.5, 5.6)]
const OUT_SCENE_V2 := "res://build/world_map_v13_native_coast_slice_v2.png"
const OUT_WALK_V2 := "res://build/world_map_v13_native_coast_walk_v2.png"


func _scene_output() -> String:
	return OUT_SCENE_V2


func _walk_output() -> String:
	return OUT_WALK_V2


func _configure_camera(camera: Camera3D) -> void:
	camera.size = 15.0
	camera.position = Vector3(7.7, 11.0, 13.0)
	camera.look_at(Vector3(-1.0, 0.0, 0.0))


func _make_ground_material(ground_image: Image, road_image: Image) -> Material:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;
uniform sampler2D grass_tex : source_color;
uniform sampler2D stone_tex : source_color;
varying float terrain_height;
void vertex() {
	terrain_height = VERTEX.y;
}
void fragment() {
	vec3 grass = texture(grass_tex, fract(UV * 0.55)).rgb;
	vec3 stone = texture(stone_tex, fract(UV * 0.68)).rgb;
	float broad_patch = 0.5 + 0.5 * sin(UV.x * 2.4 + sin(UV.y * 3.2)) * sin(UV.y * 2.3);
	float exposed = clamp(smoothstep(0.38, 1.05, terrain_height) * 0.70 + broad_patch * 0.11, 0.0, 0.82);
	ALBEDO = mix(grass, stone, exposed) * vec3(0.79, 0.80, 0.76);
	ROUGHNESS = 0.96;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("grass_tex", ImageTexture.create_from_image(ground_image))
	material.set_shader_parameter("stone_tex", ImageTexture.create_from_image(road_image))
	return material


func _decorate_world(world: Node3D, mask: bool) -> void:
	if mask:
		_add_mask_blockers(world)
		return
	_add_water(world)
	var cliff_scene := load(CLIFF) as PackedScene
	var shrub_scene := load(SHRUB) as PackedScene
	if cliff_scene == null or shrub_scene == null:
		push_error("Poly Haven cliff/shrub model not imported")
		return
	var cliff := cliff_scene.instantiate() as Node3D
	cliff.name = "CC0CoastalCliff"
	cliff.position = Vector3(4.55, -1.0, 0.0)
	cliff.rotation_degrees.y = 90.0
	cliff.scale = Vector3(0.16, 0.13, 0.10)
	world.add_child(cliff)
	for index in SHRUB_POSITIONS.size():
		var p: Vector2 = SHRUB_POSITIONS[index]
		var shrub := shrub_scene.instantiate() as Node3D
		shrub.name = "CC0Shrub%02d" % index
		shrub.position = Vector3(p.x, _height(p.x, p.y), p.y)
		shrub.scale = Vector3.ONE * 1.45
		shrub.rotation_degrees.y = float(index * 43)
		world.add_child(shrub)


func _add_water(world: Node3D) -> void:
	var water := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(8.0, 22.0)
	water.mesh = plane
	water.position = Vector3(8.5, 0.0, 0.0)
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode cull_disabled;
varying vec2 water_position;
void vertex() {
	water_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
void fragment() {
	float ripple = sin(water_position.x * 7.0 + water_position.y * 10.0) * sin(water_position.y * 13.0 - water_position.x * 4.0);
	ALBEDO = vec3(0.095, 0.225, 0.285) + ripple * 0.009;
	ROUGHNESS = 0.32;
	METALLIC = 0.04;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	water.material_override = material
	world.add_child(water)


func _add_mask_blockers(world: Node3D) -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.BLACK
	var cliff_foot := MeshInstance3D.new()
	var cliff_box := BoxMesh.new()
	cliff_box.size = Vector3(0.86, 0.02, 14.5)
	cliff_foot.mesh = cliff_box
	cliff_foot.position = Vector3(4.22, 0.43, 0.0)
	cliff_foot.material_override = material
	world.add_child(cliff_foot)
	for p in SHRUB_POSITIONS:
		var footprint := MeshInstance3D.new()
		var disk := CylinderMesh.new()
		disk.top_radius = 0.28
		disk.bottom_radius = 0.28
		disk.height = 0.03
		footprint.mesh = disk
		footprint.position = Vector3(p.x, _height(p.x, p.y) + 0.12, p.y)
		footprint.material_override = material
		world.add_child(footprint)
