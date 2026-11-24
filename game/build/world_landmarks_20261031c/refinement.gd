extends RefCounted
## Whole native world landmark, not the walkable village scene or a new portal.
const LANDMARK := "res://art/modules/environment_repair_20261031c/lanxi_world_landmark_v1.png"
const LANDMARK_SHA := "56c18e7d89dd4406446bf16255d0864e5de9f6c59a3e1c29adcaacfd10ef14d3"
const PATH_SHADER=preload("res://build/world_landmarks_20261031c/path_blend.gdshader")
static var landmark_texture: Texture2D

static func sprites(raw: Dictionary) -> Array:
	if String(raw.id)!="lanxi_zhai":return raw.sprites
	# Original interactive door stays900,6000. Sort the compound at the gate's
	# rear plane, not the foreground path baked into the whole landmark image.
	return [{"texture":LANDMARK,"origin_px":[554.4,5617.5],"scale":0.45,"foot_px":[900,5920]}]

static func texture(path: String) -> Texture2D:
	if path!=LANDMARK:return load(path) as Texture2D
	if landmark_texture!=null:return landmark_texture
	if FileAccess.get_sha256(path)!=LANDMARK_SHA:
		push_error("[World31c] Native landmark source changed");return null
	var im:=Image.load_from_file(path)
	if im==null or im.is_empty():return null
	landmark_texture=ImageTexture.create_from_image(im)
	return landmark_texture

static func route(raw: Dictionary) -> PackedVector2Array:
	var points:=PackedVector2Array()
	for p: Array in raw.points:points.append(Vector2(float(p[0]),float(p[1])))
	if String(raw.get("source_id",""))!="lanxi_southwestern_branch":return points
	# Round only the two former right-angle elbows. Authored endpoints stay exact.
	var softened:=PackedVector2Array();softened.append(points[0])
	for i: int in range(1,points.size()-1):
		var p: Vector2=points[i]
		var radius:=minf(65.0,minf(p.distance_to(points[i-1]),p.distance_to(points[i+1]))*.35)
		var before: Vector2=p.move_toward(points[i-1],radius)
		var after: Vector2=p.move_toward(points[i+1],radius)
		softened.append(before)
		for j: int in range(1,7):
			var t:=float(j)/6.0
			softened.append(before.lerp(p,t).lerp(p.lerp(after,t),t))
	softened.append(points[points.size()-1]);return softened

static func blend_path(node: Polygon2D,raw: Dictionary,points: PackedVector2Array) -> void:
	if String(raw.get("source_id",""))!="lanxi_southwestern_branch":return
	# Reuse the already-pinned fine earth tile; the old mud image has boulders
	# which look like a raised cliff when enlarged into this narrow footpath.
	node.texture=load("res://art/maps/bianzhou_enclosure_20261028d/compacted_earth_tile_v1.png") as Texture2D
	var soil_uv:=PackedVector2Array()
	for p: Vector2 in node.polygon:soil_uv.append(p*node.texture.get_size()/384.0)
	node.uv=soil_uv
	var shader_material:=ShaderMaterial.new();shader_material.shader=PATH_SHADER
	var padded:=points.duplicate()
	while padded.size()<64:padded.append(points[points.size()-1])
	shader_material.set_shader_parameter("path_points",padded)
	shader_material.set_shader_parameter("path_count",points.size())
	shader_material.set_shader_parameter("half_width",float(raw.width)*.5)
	node.material=shader_material

static func raise_names(field: Node) -> int:
	var raised:=0
	for zone: Node in field.get("_exit_nodes"):
		if not is_instance_valid(zone):continue
		var label:=zone.get_node_or_null("Prompt") as Label
		if label==null:continue
		# World Canvas only: HUD keeps its independent higher CanvasLayer.
		label.z_as_relative=false;label.z_index=4095
		label.set_meta("world_name_foreground_31c",true);raised+=1
	return raised
