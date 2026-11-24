extends "res://scripts/dev/build_world_map_native_pair_ortho_v6.gd"

# Candidate geometry only: river, road, pads and navigation share coordinates.
# Do not reference these outputs from the shipping world until visual approval.
const CONTRACT := preload("res://scripts/dev/world_native_pair_landmark_contract_v7.gd")


func _output_prefix() -> String:
	return "res://build/world_native_pair_ortho_v7_"


func _river_x(y: float) -> float:
	return CONTRACT.river_x(y)


func _road_y(x: float) -> float:
	return CONTRACT.road_y(x)


func _segment_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	return p.distance_to(a + (b-a) * clampf((p-a).dot(b-a)/(b-a).length_squared(),0.0,1.0))


func _read_png(path: String) -> Image:
	var topology := super._read_png(path)
	if topology == null or not path.ends_with("topology.png"):
		return topology
	var road_centers := PackedFloat32Array()
	var road_normals := PackedFloat32Array()
	for x in SIZE.x:
		road_centers.append(_road_y(x))
		var slope := (_road_y(x+1.0)-_road_y(x-1.0))*0.5
		road_normals.append(sqrt(1.0+slope*slope))
	for y in SIZE.y:
		for x in SIZE.x:
			var p := Vector2(x,y)
			var sample := topology.get_pixel(x,y)
			var river := absf(x - _river_x(y))
			if river < 64.0:
				sample.r = 0.0
			# Width is perpendicular to the curve, not a vertical strip which
			# pinches the full foot probe at the steep ferry approach.
			var road_dist := absf(y-road_centers[x])/road_normals[x]
			var city_spur := _segment_distance(p,CONTRACT.CITY_SPUR[0],CONTRACT.CITY_SPUR[1])
			var ferry_spur := _segment_distance(p,CONTRACT.FERRY_SPUR[0],CONTRACT.FERRY_SPUR[1])
			road_dist = minf(road_dist,minf(city_spur,ferry_spur))
			sample.g = (1.0-smoothstep(22.0,42.0,road_dist)) if _coast_distance(p)>82.0 else 0.0
			topology.set_pixel(x,y,sample)
	return topology


func _rect_weight(pixel: Vector2, rect: Rect2, transition: float = 70.0) -> float:
	var delta := (pixel - rect.get_center()).abs() - rect.size * 0.5
	return 1.0 - smoothstep(0.0,transition,Vector2(maxf(0.0,delta.x),maxf(0.0,delta.y)).length())


func _height(pixel: Vector2, topology: Image) -> float:
	var pad := maxf(_rect_weight(pixel,Rect2(610,100,580,310)),_rect_weight(pixel,Rect2(1380,280,560,175)))
	pad = maxf(pad,_rect_weight(pixel,Rect2(2210,490,400,310)))
	# A continuous low riverbank prevents elevated hills projecting into the
	# channel as abrupt shelf steps; the same surface renders land and nav.
	pad = maxf(pad,1.0-smoothstep(82.0,190.0,absf(pixel.x-_river_x(pixel.y))))
	return super._height(pixel,topology) * (1.0-pad)


func _walk_texture(topology: Image, walk: Texture2D) -> Texture2D:
	var image := super._walk_texture(topology,walk).get_image()
	for y in SIZE.y:
		for x in SIZE.x:
			var sample := topology.get_pixel(x,y)
			# New authored road replaces the inherited v2 road stencil. It may
			# only open the land-side road core; river/sea vetoes still win.
			if sample.r>0.5 and sample.g>0.65 and _coast_distance(Vector2(x,y))>82.0:
				image.set_pixel(x,y,Color.WHITE)
			if absf(x-_river_x(y))<84.0:
				image.set_pixel(x,y,Color.BLACK)
	# Only the actual independent bridge deck supports feet above the river.
	# This exception never opens the surrounding water or the parapets.
	image.fill_rect(Rect2i(CONTRACT.BRIDGE_DECK),Color.WHITE)
	return ImageTexture.create_from_image(image)


func _surface_material(color: Texture2D, selector: Texture2D, mask: bool) -> ShaderMaterial:
	var material := super._surface_material(color,selector,mask)
	if mask:
		return material
	var source := material.shader.code
	# Derive shader road geometry from the same authoring contract as nav/QA.
	var start := source.find("float road_y(float x)")
	var finish := source.find("void fragment()",start)
	var road_function := "float road_y(float x) {\n"
	for index in range(CONTRACT.ROAD_STOPS.size()-1):
		var a: Vector2 = CONTRACT.ROAD_STOPS[index]
		var b: Vector2 = CONTRACT.ROAD_STOPS[index+1]
		road_function += "if(x<=%f){return mix(%f,%f,smoothstep(0.0,1.0,clamp((x-%f)/%f,0.0,1.0)));}\n" % [b.x,a.y,b.y,a.x,b.x-a.x]
	road_function += "return %f;}\n" % CONTRACT.ROAD_STOPS[-1].y
	source = source.substr(0,start)+road_function+source.substr(finish)
	source = source.replace("float coverage=(1.0-smoothstep(20.0,46.0,road_dist))*smoothstep(110.0,180.0,coast);", "float coverage=topo.g;")
	source = source.replace("land=mix(land,rock,max(exposed,bank));", "float river_edge=abs(p.x-(1660.0+28.0*sin((p.y-365.0)*0.004)))-64.0;\n bank=max(bank,(1.0-smoothstep(0.0,38.0,river_edge))*0.82);\n land=mix(land,rock,max(exposed,bank));")
	# Decorrelation rather than increasing the density of a repeated grass tile.
	source = source.replace("vec3 grass_a=texture(grass_tex,p/930.0).rgb;", "vec2 jitter=vec2(noise(p/730.0),noise((p+vec2(230,710))/730.0));\n vec3 grass_a=texture(grass_tex,p/1150.0+jitter*0.17).rgb;")
	source = source.replace("vec3 grass_b=texture(grass_tex,(p.yx+vec2(213,417))/740.0).rgb;", "vec3 grass_b=texture(grass_tex,(-p.yx+vec2(213,417))/1750.0).rgb;")
	# Smooth broad blending hides repeated tile patterns without polygonal seams.
	source = source.replace("smoothstep(0.22,0.78,broad)", "smoothstep(0.05,0.95,noise(p/700.0))")
	material.shader.code = source
	return material


func _after_outputs_saved(topology: Image) -> void:
	var route: Array = []
	for x in range(32,2396,16):
		var point := Vector2(x,_road_y(x))
		point.y -= _height(point,topology)*SIZE.y/CAMERA_SIZE/sqrt(2.0)
		route.append([point.x,point.y])
	var file := FileAccess.open(_output_prefix()+"route.json",FileAccess.WRITE)
	var deck: Rect2 = CONTRACT.BRIDGE_DECK
	file.store_string(JSON.stringify({"road_feet":route,"bridge_deck":[deck.position.x,deck.position.y,deck.size.x,deck.size.y],"river_half_width":64,"water_clearance":20,"land_mask_excludes_structural_bridge":true},"\t"))
	file.close()
	_save_front_rail()


func _save_front_rail() -> void:
	# A technical, pixel-aligned foreground mask of an existing asset; no redraw.
	var bridge := super._read_png("res://art/modules/world_map_v13/bridge_stone_eastwest_v1.png")
	if bridge == null:
		push_error("Bridge alpha source missing")
		return
	bridge.convert(Image.FORMAT_RGBA8)
	var rail := Image.create(bridge.get_width(),bridge.get_height(),false,Image.FORMAT_RGBA8)
	# Isolate the front parapet; keep identical source-canvas and placement.
	var rect := Rect2i(190,480,1400,bridge.get_height()-480)
	rail.blit_rect(bridge,rect,rect.position)
	rail.save_png("res://art/modules/world_map_v13/bridge_stone_eastwest_front_rail_v7.png")
