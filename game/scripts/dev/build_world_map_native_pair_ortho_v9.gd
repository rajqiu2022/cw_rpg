extends "res://scripts/dev/build_world_map_native_pair_ortho_v8.gd"

# All geographic hooks explicitly use v9. Parent v7 CONTRACT is not consulted.
const GEOGRAPHY := preload("res://scripts/dev/world_native_pair_landmark_contract_v9.gd")
var _nav_topology: Image


func _initialize() -> void:
	if "--ferry-masks-only" in OS.get_cmdline_user_args():
		call_deferred("_build_ferry_masks_only")
	else:
		call_deferred("_build")


func _build_ferry_masks_only() -> void:
	_save_ferry_masks()
	print("[WorldNativePairV9] only pixel-aligned ferry foreground masks rebuilt; terrain/navigation unchanged")
	quit(0)


func _output_prefix() -> String:
	return GEOGRAPHY.PREFIX


func _river_x(y: float) -> float:
	return GEOGRAPHY.river_x(y)


func _road_y(x: float) -> float:
	return GEOGRAPHY.road_y(x)


func _coast_distance(pixel: Vector2) -> float:
	return GEOGRAPHY.shore_x(pixel.y)-pixel.x


func _river_distance(pixel: Vector2) -> float:
	return absf(pixel.x-_river_x(pixel.y))-GEOGRAPHY.river_half_width(pixel.y)


func _read_png(path: String) -> Image:
	if not path.ends_with("topology.png"):
		var source := Image.new()
		return source if source.load_png_from_buffer(FileAccess.get_file_as_bytes(path))==OK else null
	# New geometry starts with a clean canvas: no inherited v7 river black strip.
	var image := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGBA8)
	var centers: PackedFloat32Array=[]
	var normals: PackedFloat32Array=[]
	for x in SIZE.x:
		centers.append(_road_y(x))
		var slope := (_road_y(x+1.0)-_road_y(x-1.0))*0.5
		normals.append(sqrt(1.0+slope*slope))
	for y in SIZE.y:
		for x in SIZE.x:
			var p := Vector2(x,y)
			var coast := _coast_distance(p)
			var river := _river_distance(p)
			var road_distance := absf(y-centers[x])/normals[x]
			var road_end: Vector2=GEOGRAPHY.ROAD_STOPS[-1]
			if x>road_end.x:
				road_distance=p.distance_to(road_end)
			road_distance=minf(road_distance,_segment_distance(p,GEOGRAPHY.CITY_SPUR[0],GEOGRAPHY.CITY_SPUR[1]))
			road_distance=minf(road_distance,_segment_distance(p,GEOGRAPHY.FERRY_SPUR[0],GEOGRAPHY.FERRY_SPUR[1]))
			var coverage := 1.0-smoothstep(22.0,42.0,road_distance)
			image.set_pixel(x,y,Color(1.0 if minf(coast,river)>=0.0 else 0.0,coverage if coast>82.0 else 0.0,0.0,clampf((coast+128.0)/256.0,0.0,1.0)))
	_nav_topology=image
	return image


func _contacts() -> Array[Dictionary]:
	if not _contact_sites.is_empty():
		return _contact_sites
	for object in GEOGRAPHY.scene_objects():
		if not object.has("collision_size"):
			continue
		var foot: Vector2=object["pos"]*GEOGRAPHY.WORLD_SIZE+object["collision_offset"]*GEOGRAPHY.WORLD_SIZE
		_contact_sites.append({"id":object["id"],"foot":foot,"radius":object["collision_size"]*GEOGRAPHY.WORLD_SIZE*0.65})
	return _contact_sites


func _height(p: Vector2, _topology: Image) -> float:
	# A continuous west-to-north ridge, not three disconnected mound rings.
	var ridge_center := 138.0+45.0*sin(p.x/180.0)
	var west := 2.25*exp(-pow((p.y-ridge_center)/175.0,2.0))*exp(-pow((p.x-190.0)/490.0,2.0))
	var west_shoulder := 0.75*exp(-pow((p.x-145.0)/410.0,2.0)-pow((p.y-660.0)/490.0,2.0))
	var east := 0.90*exp(-pow((p.x-2100.0)/420.0,2.0)-pow((p.y+50.0)/340.0,2.0))
	var height := west+west_shoulder+east
	var road := _height_road_distance(p)
	road=minf(road,_segment_distance(p,GEOGRAPHY.CITY_SPUR[0],GEOGRAPHY.CITY_SPUR[1]))
	road=minf(road,_segment_distance(p,GEOGRAPHY.FERRY_SPUR[0],GEOGRAPHY.FERRY_SPUR[1]))
	var flatten := 1.0-smoothstep(55.0,220.0,road)
	flatten=maxf(flatten,_ellipse_weight(p,Vector2(900,280),Vector2(370,210),1.85))
	flatten=maxf(flatten,1.0-smoothstep(30.0,240.0,_river_distance(p)))
	flatten=maxf(flatten,_ellipse_weight(p,Vector2(2390,640),Vector2(270,210),1.7))
	for site in _contacts():
		flatten=maxf(flatten,_ellipse_weight(p,site["foot"],site["radius"]+Vector2(26,22),2.8))
	return height*(1.0-flatten)*smoothstep(82.0,270.0,_coast_distance(p))


func _walk_texture(topology: Image, _walk: Texture2D) -> Texture2D:
	var image := Image.create(SIZE.x,SIZE.y,false,Image.FORMAT_RGB8)
	for y in SIZE.y:
		for x in SIZE.x:
			var p := Vector2(x,y)
			var sample := topology.get_pixel(x,y)
			var allowed := sample.r>0.5 and _coast_distance(p)>82.0 and _river_distance(p)>20.0
			# Land-side apron is allowed only on actual dry land, never bay fill.
			if GEOGRAPHY.DOCK_APPROACH.has_point(p) and sample.r>0.5 and _coast_distance(p)>12.0:
				allowed=true
			image.set_pixel(x,y,Color.WHITE if allowed else Color.BLACK)
	for y in range(0,SIZE.y,4):
		for x in range(0,SIZE.x,4):
			if image.get_pixel(x,y).r>0.5 and topology.get_pixel(x,y).g<0.02 and _gradient(Vector2(x,y),topology)>0.72:
				image.fill_rect(Rect2i(x,y,4,4),Color.BLACK)
	# Structure support never changes the natural-land mask.
	image.fill_rect(Rect2i(GEOGRAPHY.BRIDGE_DECK),Color.WHITE)
	for deck in GEOGRAPHY.DOCK_DECKS:
		image.fill_rect(Rect2i(deck),Color.WHITE)
	return ImageTexture.create_from_image(image)


func _geography_shader() -> String:
	return """
float river_center(float y){float o=y-365.0;float b=smoothstep(90.0,190.0,abs(o));return 1660.0+b*(90.0*sin(o/180.0)+35.0*sin(o/63.0));}
float river_width(float y){float o=y-365.0;return mix(64.0,50.0+26.0*pow(sin(o/145.0),2.0),smoothstep(90.0,180.0,abs(o)));}
float shore_x(float y){return 2795.0-0.36*y+30.0*sin(y*0.007)-130.0*exp(-pow((y-625.0)/75.0,2.0));}
float boxzone(vec2 p,vec2 center,vec2 halfsize,float transition){vec2 d=abs(p-center)-halfsize;return 1.0-smoothstep(0.0,transition,length(max(d,vec2(0))));}
"""


func _surface_material(color: Texture2D, selector: Texture2D, mask: bool) -> ShaderMaterial:
	var material := super._surface_material(color,selector,mask)
	if mask:
		return material
	var code := material.shader.code
	code=code.replace("void fragment(){",_geography_shader()+"void fragment(){")
	code=code.replace("2795.0-0.39*y+46.0*sin(y*0.0082)+24.0*sin(y*0.021)-p.x","shore_x(y)-p.x")
	code=code.replace("abs(p.x-(1660.0+28.0*sin((p.y-365.0)*0.004)))-64.0","abs(p.x-river_center(y))-river_width(y)")
	code=code.replace("float road=topo.g;","""
 // Constructed city apron follows the curtain wall, not a circular dirt spot.
 float plaza=boxzone(p,vec2(900,381),vec2(274,45),28.0);
 vec2 slab=fract((p+vec2(0,mod(floor(p.y/20.0),2.0)*10.0))/vec2(34,20));
 float mortar=1.0-smoothstep(0.018,0.045,min(min(slab.x,1.0-slab.x),min(slab.y,1.0-slab.y)));
 vec3 paving=mix(vec3(0.46,0.425,0.34),vec3(0.365,0.35,0.295),mortar*0.65);
 paving*=0.88+0.20*noise(floor(p/vec2(34,20)));
 land=mix(land,paving,plaza*0.94);
 // Two dry field terraces flank the city-to-road approach. Fine furrows
 // supply a human scale without baking any city buildings into the base.
 float fields=max(boxzone(p,vec2(693,501),vec2(105,49),17.0),boxzone(p,vec2(1168,569),vec2(108,42),17.0));
 float furrow=0.5+0.5*sin((p.x+p.y*0.21)/4.8);
 vec3 cultivated=mix(vec3(0.34,0.30,0.195),vec3(0.285,0.32,0.17),furrow);
 land=mix(land,cultivated,fields*0.80);
 // Western connected rock shoulder, authored along the ridge geometry.
 float rockbelt=exp(-pow((p.y-(190.0+45.0*sin(p.x/180.0)))/88.0,2.0))*exp(-pow((p.x-210.0)/520.0,2.0));
 land=mix(land,stone*1.08,rockbelt*0.86);
 float landing=boxzone(p,vec2(2370,720),vec2(85,35),27.0);
 land=mix(land,mix(soil,paving,0.48),landing*0.80);
 float road=topo.g;
""")
	material.shader.code=code
	return material


func _base_material(_color: Texture2D) -> Material:
	var shader := Shader.new()
	shader.code="shader_type spatial;render_mode cull_disabled,unshaded;uniform sampler2D water_tex : source_color,repeat_enable,filter_linear_mipmap;"+_geography_shader()+"""
void fragment(){vec2 p=UV*vec2(3072,1024);float coast=p.x-shore_x(p.y);float river=river_width(p.y)-abs(p.x-river_center(p.y));float depth=max(coast,river);vec3 scan=texture(water_tex,p/1500.0).rgb;float foam=exp(-pow((depth-3.0)/6.0,2.0));vec3 water=mix(vec3(0.025,0.11,0.14),vec3(0.095,0.245,0.25),exp(-max(depth,0.0)/160.0));water*=0.76+scan.r*0.36;ALBEDO=mix(water,vec3(0.37,0.48,0.43),foam*0.5);}
"""
	var material := ShaderMaterial.new()
	material.shader=shader
	material.set_shader_parameter("water_tex",load(WATER_MAT))
	return material


func _after_outputs_saved(topology: Image) -> void:
	var route: Array=[]
	var road_end: Vector2=GEOGRAPHY.ROAD_STOPS[-1]
	for x in range(32,roundi(road_end.x),16):
		var p := Vector2(x,_road_y(x))
		route.append([p.x,p.y-_height(p,topology)*SIZE.y/CAMERA_SIZE/sqrt(2.0)])
	route.append([road_end.x,road_end.y-_height(road_end,topology)*SIZE.y/CAMERA_SIZE/sqrt(2.0)])
	var dock_rects: Array=[]
	for rect in GEOGRAPHY.DOCK_DECKS:
		dock_rects.append([rect.position.x,rect.position.y,rect.size.x,rect.size.y])
	var output := FileAccess.open(_output_prefix()+"route.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({"road_feet":route,"bridge_deck":[1418,348,484,35],"dock_decks":dock_rects,"land_mask_excludes_structures":true},"\t"))
	output.close()
	var steep: Array=[]
	for y in range(80,420,20):
		for x in range(20,700,20):
			var p := Vector2(x,y)
			var projected_y := y-_height(p,topology)*SIZE.y/CAMERA_SIZE/sqrt(2.0)
			if _gradient(p,topology)>0.79 and topology.get_pixel(x,y).r>0.5 and projected_y>=20.0 and projected_y<SIZE.y-20:
				steep.append({"source_point":[x,y],"projected_point":[x,projected_y],"world_gradient":_gradient(p,topology)})
				if steep.size()>=12:
					break
		if steep.size()>=12:
			break
	var moves: Array=[]
	for id in GEOGRAPHY.PROP_MOVES:
		var move: Vector2=GEOGRAPHY.PROP_MOVES[id]
		moves.append({"id":id,"delta":[move.x,move.y],"visual_collision_depth_moved_together":true})
	var gentle: Array=[]
	for p in [Vector2(900,390),Vector2(2390,735),Vector2(380,448)]:
		gentle.append({"source_point":[p.x,p.y],"projected_point":[p.x,p.y-_height(p,topology)*SIZE.y/CAMERA_SIZE/sqrt(2.0)],"world_gradient":_gradient(p,topology)})
	var file := FileAccess.open(_output_prefix()+"art.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"status":"ISOLATED_VISUAL_CANDIDATE","version":"v9","geometry_contract":"v9","same_camera_visual_land_walk":true,"entities_baked":false,"prop_moves":moves,"steep_examples":steep,"gentle_examples":gentle,"new_geography_not_inherited_v7":true,"dock_decks":dock_rects,"dock_approach_is_dry_land_only":true,"construction_zones":{"city_forecourt":[626,336,548,90],"west_ridge":"connected authored shoulder","bay_center":[2412,625]}},"\t"))
	file.close()
	topology.save_png(_output_prefix()+"topology.png")
	_save_ferry_masks()


func _save_ferry_masks() -> void:
	var source := _read_png(GEOGRAPHY.ROOT+"landmark_bailu_ferry_v1.png")
	source.convert(Image.FORMAT_RGBA8)
	# These source-canvas silhouettes follow the actual roof, body and stone
	# base. The former rectangular crop also included the right linking deck.
	var pavilion_polygons := [PackedVector2Array([
		Vector2(64,155),Vector2(320,48),Vector2(537,0),Vector2(678,128),
		Vector2(659,164),Vector2(610,209),Vector2(610,263),Vector2(659,264),
		Vector2(681,293),Vector2(686,351),Vector2(679,386),Vector2(652,400),
		Vector2(593,429),Vector2(558,448),Vector2(542,471),Vector2(530,531),
		Vector2(488,565),Vector2(418,544),Vector2(180,470),Vector2(103,510),
		Vector2(100,390),Vector2(145,358),Vector2(145,258),Vector2(95,215)])]
	var pavilion := _foreground_from_polygons(source,pavilion_polygons)
	pavilion.save_png(_output_prefix()+"ferry_pavilion_foreground.png")
	# Each post/base is isolated separately, leaving intervening floor planks
	# in the below-actor layer. Caps remain physical foreground silhouettes;
	# no navigation-dependent blanket clearing or collision expansion is used.
	var rail_polygons := [
		PackedVector2Array([Vector2(905,526),Vector2(943,503),Vector2(994,521),Vector2(1020,542),Vector2(1021,582),Vector2(1000,608),Vector2(945,631),Vector2(917,608),Vector2(892,581),Vector2(881,559)]),
		PackedVector2Array([Vector2(879,592),Vector2(904,588),Vector2(923,596),Vector2(925,613),Vector2(913,628),Vector2(913,677),Vector2(933,687),Vector2(943,733),Vector2(927,757),Vector2(881,754),Vector2(866,738),Vector2(870,690),Vector2(880,675),Vector2(880,631),Vector2(868,617)]),
		PackedVector2Array([Vector2(878,729),Vector2(907,736),Vector2(910,765),Vector2(897,779),Vector2(898,823),Vector2(926,839),Vector2(943,855),Vector2(947,901),Vector2(920,924),Vector2(851,920),Vector2(831,901),Vector2(833,857),Vector2(854,833),Vector2(858,780),Vector2(848,760),Vector2(853,739)]),
		PackedVector2Array([Vector2(579,552),Vector2(610,554),Vector2(624,568),Vector2(620,591),Vector2(608,604),Vector2(610,652),Vector2(622,665),Vector2(630,684),Vector2(625,704),Vector2(569,713),Vector2(540,701),Vector2(543,670),Vector2(572,649),Vector2(575,604),Vector2(564,590),Vector2(561,571)]),
		PackedVector2Array([Vector2(480,691),Vector2(513,697),Vector2(524,714),Vector2(517,738),Vector2(508,749),Vector2(509,799),Vector2(532,815),Vector2(544,847),Vector2(545,883),Vector2(515,910),Vector2(457,906),Vector2(421,891),Vector2(425,856),Vector2(450,831),Vector2(475,806),Vector2(476,752),Vector2(465,736),Vector2(465,711)])]
	var rail := _foreground_from_polygons(source,rail_polygons)
	rail.save_png(_output_prefix()+"ferry_near_rail.png")
	var rail_metadata: Array=[]
	var rail_images: Array[Image]=[]
	assert(rail_polygons.size()==GEOGRAPHY.RAIL_PARTS.size())
	for index in rail_polygons.size():
		var part: Dictionary=GEOGRAPHY.RAIL_PARTS[index]
		var polygon: PackedVector2Array=rail_polygons[index]
		var source_bottom_y := 0.0
		for point in polygon:
			source_bottom_y=maxf(source_bottom_y,point.y)
		assert(is_equal_approx(source_bottom_y,float(part["source_bottom_y"])))
		var suffix := "ferry_rail_"+String(part["name"])+".png"
		var entity := _foreground_from_polygons(source,[polygon])
		# In an authored source overlap, the southern entity owns the source
		# pixel. This preserves the aggregate silhouette without drawing one
		# cap pixel twice at two different depth lines.
		var used := entity.get_used_rect()
		for other_index in rail_polygons.size():
			if GEOGRAPHY.rail_foot_y(GEOGRAPHY.RAIL_PARTS[other_index])<=GEOGRAPHY.rail_foot_y(part):
				continue
			var front_polygon: PackedVector2Array=rail_polygons[other_index]
			for y in range(used.position.y,used.end.y):
				for x in range(used.position.x,used.end.x):
					if entity.get_pixel(x,y).a>0.0 and Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),front_polygon):
						entity.set_pixel(x,y,Color.TRANSPARENT)
		entity.save_png(_output_prefix()+suffix)
		rail_images.append(entity)
		rail_metadata.append({"id":"lab_ferry_rail_"+String(part["name"]),"texture":suffix,"source_bottom_y":source_bottom_y,"world_foot_y":GEOGRAPHY.rail_foot_y(part)})
	var duplicate_pixels := 0
	var aggregate_mismatches := 0
	var audit_rect := rail.get_used_rect()
	for y in range(audit_rect.position.y,audit_rect.end.y):
		for x in range(audit_rect.position.x,audit_rect.end.x):
			var owners := 0
			var union_alpha := 0.0
			for entity in rail_images:
				var alpha := entity.get_pixel(x,y).a
				owners+=1 if alpha>0.0 else 0
				union_alpha=maxf(union_alpha,alpha)
			duplicate_pixels+=1 if owners>1 else 0
			aggregate_mismatches+=1 if not is_equal_approx(union_alpha,rail.get_pixel(x,y).a) else 0
	assert(duplicate_pixels==0 and aggregate_mismatches==0)
	var metadata_path := _output_prefix()+"art.json"
	if FileAccess.file_exists(metadata_path):
		var metadata: Variant=JSON.parse_string(FileAccess.get_file_as_string(metadata_path))
		if metadata is Dictionary:
			metadata["ferry_foreground_extraction"]={"method":"source_canvas_independent_entity_polygons_v3","pavilion_polygons":pavilion_polygons.size(),"individual_rail_polygons":rail_polygons.size(),"same_source_canvas":true,"floor_or_navigation_not_blanket_erased":true,"overlap_ownership":"southern_entity_unique_pixel_owner","duplicate_owned_pixels":duplicate_pixels,"aggregate_max_alpha_mismatches":aggregate_mismatches,"merged_rail_is_audit_only":true,"runtime_rail_parts":rail_metadata}
			var output := FileAccess.open(metadata_path,FileAccess.WRITE)
			output.store_string(JSON.stringify(metadata,"\t"))
			output.close()


func _foreground_from_polygons(source: Image, polygons: Array) -> Image:
	var result := Image.create(source.get_width(),source.get_height(),false,Image.FORMAT_RGBA8)
	for polygon: PackedVector2Array in polygons:
		var bounds := Rect2(polygon[0],Vector2.ZERO)
		for point in polygon:
			bounds=bounds.expand(point)
		for y in range(maxi(0,floori(bounds.position.y)),mini(source.get_height(),ceili(bounds.end.y)+1)):
			for x in range(maxi(0,floori(bounds.position.x)),mini(source.get_width(),ceili(bounds.end.x)+1)):
				if Geometry2D.is_point_in_polygon(Vector2(x+0.5,y+0.5),polygon):
					result.set_pixel(x,y,source.get_pixel(x,y))
	return result
