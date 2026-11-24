extends "res://scripts/dev/luoyang_yamen_front_asset_v9_preview.gd"

## NEW modular2.5D authoring, NOT production/native/PBR. Input PNGs untouched.
## Real placement supplies480/320ground lengths; the generated runs were short.
## Each ground-Y group exports one Sprite RGBA including its authored pivot.
const ATLAS_REL := "assets/raw/scene_module/luoyang_yamen_complete_walls_v11b/complete_wall_modules_v11b_candidate.png"
const ATLAS_SHA := "3d6dc3d61b1c57b810021005d6e922c45f9c83f6a3b0b281281971347d39a0e8"
const ATLAS_RES := "res://art/maps/luoyang_enclosure_v11/source/complete_wall_modules_v11b_candidate.png"
const GATE_RES := "res://art/maps/luoyang_enclosure_v11/source/courtyard_wall_gate_v3.png"
const S := (344.*1150./1980.)/195.
const VISUAL_GROUND_OFFSET := 9.5
const FRONT_RIDGE := 305.
const FRONT_FOOT := 500.
const NORTH_CAP_RIDGE := 826.
const NORTH_FOOT := 1003.
const NORTH_HALL_RIDGE := 543.
const MASONRY_WIDTH := 36. # Authored NEW ground solid, not alpha/roof bbox.
const HORIZONTAL_GROUND_DEPTH := MASONRY_WIDTH*.5
const SOUTH_ROOF_OFFSET := (FRONT_FOOT-FRONT_RIDGE)*S-VISUAL_GROUND_OFFSET
const NORTH_ROOF_OFFSET := (NORTH_FOOT-NORTH_CAP_RIDGE)*S-VISUAL_GROUND_OFFSET
const CORNER_CUT := FRONT_RIDGE-160./S
const NORTH_CAP_CUT := NORTH_CAP_RIDGE-160./S
const NORTH_EXTENSION := 320.-(NORTH_CAP_RIDGE-NORTH_HALL_RIDGE)*S
var atlas_image: Image
var atlas_texture: ImageTexture

func prepare() -> bool:
	if not super.prepare(): return false
	if FileAccess.get_sha256(repo_path(ATLAS_REL)).to_lower()!=ATLAS_SHA:
		error="ActualV11b source SHA mismatch; no fallback."
		return false
	atlas_image=Image.load_from_file(repo_path(ATLAS_REL))
	if atlas_image==null or atlas_image.get_size()!=Vector2i(1536,1024) or atlas_image.get_format()!=Image.FORMAT_RGBA8:
		error="ActualV11b exact nativeRGBA8 size required."
		return false
	for p: Vector2i in [Vector2i(0,200),Vector2i(768,450),Vector2i(600,900),Vector2i(1200,700)]:
		if atlas_image.get_pixelv(p).a!=0.:
			error="V11b actual background alpha probe changed."
			return false
	for record: Dictionary in author_records():
		for piece: Dictionary in record.pieces:
			var uv:=_packed(piece.uv_polygon_px)
			if Geometry2D.triangulate_polygon(uv).is_empty():
				error="V11 explicit module UV cannot triangulate: "+String(record.id)
				return false
	atlas_texture=ImageTexture.create_from_image(atlas_image)
	return true

static func _points(values: PackedVector2Array) -> Array:
	var out: Array=[]
	for p: Vector2 in values: out.append([p.x,p.y])
	return out

static func _packed(values: Array) -> PackedVector2Array:
	var out:=PackedVector2Array()
	for p: Array in values: out.append(Vector2(float(p[0]),float(p[1])))
	return out

static func _rect(x0: float,y0: float,x1: float,y1: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x0,y0),Vector2(x1,y0),Vector2(x1,y1),Vector2(x0,y1)])

static func _piece(uv: PackedVector2Array,origin: Vector2,source: String=ATLAS_RES,scale_value: float=S) -> Dictionary:
	return {"source":source,"uv_polygon_px":_points(uv),"origin_px":[origin.x,origin.y],"scale":scale_value}

static func _wall_record(id: String,x: float,low_y: float,high_y: float,pieces: Array,extra_solids: Array=[]) -> Dictionary:
	var solids: Array=[_points(_rect(x-MASONRY_WIDTH*.5,low_y,x+MASONRY_WIDTH*.5,high_y))]
	solids.append_array(extra_solids)
	return {"id":id,"world_foot_px":[x,high_y],"ground_y_range_px":[low_y,high_y],"physical_center_px":[x,(low_y+high_y)*.5],"collision_size_px":[0,0],"solid_polygons_px":solids,"blocking":true,"pieces":pieces}

func author_records() -> Array:
	# Plain JSON-shaped dictionaries, exporter owns actual RGBA/contract files.
	var records: Array=[]
	for left: bool in [true,false]:
		var side: String="west" if left else "east"
		var x: float=960. if left else 2110.
		var source_axis: float=120. if left else 1418.
		var origin_x: float=x-source_axis*S
		var roof_x0: float=97. if left else 1346.
		var roof_x1: float=191. if left else 1445.
		# Entire connected front/corner below the source cut, not oldV9 beneath.
		var gate_end: float=source_axis+(LEFT_END-x)/S if left else source_axis+(RIGHT_START-x)/S
		var uv: PackedVector2Array
		if left:
			uv=PackedVector2Array([Vector2(89,CORNER_CUT),Vector2(191,CORNER_CUT),Vector2(191,300),Vector2(gate_end,300),Vector2(gate_end,519),Vector2(89,519)])
		else:
			uv=PackedVector2Array([Vector2(1346,CORNER_CUT),Vector2(1451,CORNER_CUT),Vector2(1451,519),Vector2(gate_end,519),Vector2(gate_end,300),Vector2(1346,300)])
		var front_span:=Vector2(960.,LEFT_END) if left else Vector2(RIGHT_START,2110.)
		var horizontal:=_points(_rect(front_span.x,1680.-HORIZONTAL_GROUND_DEPTH,front_span.y,1680.))
		records.append(_wall_record("v11_yamen_"+side+"_south_1680",x,1520.,1680.,[_piece(uv,Vector2(origin_x,1689.5-FRONT_FOOT*S))],[horizontal]))
		# Real repeated straight interior, no stretched run and no repeated cap.
		var middle_uv:=_rect(roof_x0,82.,roof_x1,82.+160./S)
		var middle_origin:=Vector2(origin_x,1360.-SOUTH_ROOF_OFFSET-82.*S)
		records.append(_wall_record("v11_yamen_"+side+"_south_1520",x,1360.,1520.,[_piece(middle_uv,middle_origin)]))
		# Keep actual north-facing/away opening termination from original tip.
		var tip_uv:=_rect(roof_x0,15.,roof_x1,23.+160./S)
		var tip_origin:=Vector2(origin_x,1200.-SOUTH_ROOF_OFFSET-23.*S)
		records.append(_wall_record("v11_yamen_"+side+"_south_1360",x,1200.,1360.,[_piece(tip_uv,tip_origin)]))
		# There is NO draw/solid in groundY940..1200.
		var north_axis: float=468. if left else 1071.
		var north_origin_x: float=x-north_axis*S
		var cap_origin:=Vector2(north_origin_x,949.5-NORTH_FOOT*S)
		var cap_uv:=_rect(420.,NORTH_CAP_CUT,518.,1010.) if left else _rect(1022.,NORTH_CAP_CUT,1119.,1010.)
		records.append(_wall_record("v11_yamen_"+side+"_north_940",x,780.,940.,[_piece(cap_uv,cap_origin)]))
		# Short actual hall joint and original upper roof shifted as ONE piece.
		# The missing30logical is a separate equal-scale interior strip, not warp.
		var hall_uv: PackedVector2Array
		var inward_end: float=north_axis+(64./S if left else -64./S)
		if left:
			hall_uv=PackedVector2Array([Vector2(420,524),Vector2(inward_end,524),Vector2(inward_end,615),Vector2(518,615),Vector2(518,NORTH_CAP_CUT),Vector2(420,NORTH_CAP_CUT)])
		else:
			hall_uv=PackedVector2Array([Vector2(inward_end,524),Vector2(1119,524),Vector2(1119,NORTH_CAP_CUT),Vector2(1022,NORTH_CAP_CUT),Vector2(1022,615),Vector2(inward_end,615)])
		var hall_origin:=cap_origin-Vector2(0,NORTH_EXTENSION)
		var interior_uv:=_rect(427.,610.,518.,610.+NORTH_EXTENSION/S) if left else _rect(1022.,610.,1119.,610.+NORTH_EXTENSION/S)
		var interior_origin:=Vector2(north_origin_x,780.-NORTH_EXTENSION-NORTH_ROOF_OFFSET-610.*S)
		var join_span:=Vector2(960.,1008.) if left else Vector2(2062.,2110.)
		var join_solid:=_points(_rect(join_span.x,620.,join_span.y,620.+HORIZONTAL_GROUND_DEPTH))
		records.append(_wall_record("v11_yamen_"+side+"_north_780",x,620.,780.,[_piece(hall_uv,hall_origin),_piece(interior_uv,interior_origin)],[join_solid]))
	# Original central timber/roof/shoes ONLY. Old broad gate-wing solids omitted.
	# Newly authored two jamb grounds, original aperture remains unobstructed.
	var jambs: Array=[_points(_rect(1422.5,1666.,1470.5,1703.5)),_points(_rect(1600.5,1666.,1652.5,1703.5))]
	records.append({"id":"south_court_gate","world_foot_px":[1536.,1700.],"ground_y_range_px":[1666.,1703.5],"physical_center_px":[1536.,1700.],"collision_size_px":[0,0],"solid_polygons_px":jambs,"blocking":true,"pieces":[_piece(PackedVector2Array(GATE_UV),GATE_ORIGIN,GATE_RES,GATE_SCALE)]})
	return records

func source_catalog() -> Dictionary:
	return {ATLAS_RES:ATLAS_SHA,GATE_RES:GATE_SHA}

func authoring_observations() -> Dictionary:
	return {"scope":"V11_MODULAR_COMPLETE_YAMEN_WALL_CANDIDATE_NOT_ADOPTED","carrier_groups":11,"primitive_count":13,"uniform_atlas_scale":S,"original_short_run_not_claimed_complete":true,"north_extension_logical_px":NORTH_EXTENSION,"south_ground_foot_y":1680.,"south_visual_brick_foot_y":1689.5,"masonry_width_authored_logical_px":MASONRY_WIDTH,"horizontal_ground_depth_authored_logical_px":HORIZONTAL_GROUND_DEPTH,"open_ground_y":[940,1200],"known_risks":["Actual tile phase at repeat joints requires GPU visual review","Cap cross-section profile differs from horizontal upright; no equal-height proof","NEW masonry solid and Y ordering need actualField17point Physics","Hall joint above masonry ground is not collision from roof bbox"],"old_v9_front_not_under_drawn":true,"central_gate_source_uv_preserved":true,"alpha_threshold_or_bitmap_edit":false,"production_approved":false}

func baseline_walls(parent: Node2D,rect: Rect2i,zoom: int) -> Array[Polygon2D]:
	return super.walls(parent,rect,zoom)

func walls(parent: Node2D,rect: Rect2i,zoom: int) -> Array[Polygon2D]:
	var nodes: Array[Polygon2D]=[]
	for record: Dictionary in author_records():
		if String(record.id)=="south_court_gate": continue # gate() draws once.
		var j: int=0
		for piece: Dictionary in record.pieces:
			var o: Array=piece.origin_px
			nodes.append(_polygon(parent,_packed(piece.uv_polygon_px),atlas_texture,Vector2(float(o[0]),float(o[1])),float(piece.scale),rect,zoom,String(record.id)+"_piece_"+str(j),10))
			j+=1
	return nodes

func release() -> void:
	atlas_texture=null
	atlas_image=null
	super.release()
