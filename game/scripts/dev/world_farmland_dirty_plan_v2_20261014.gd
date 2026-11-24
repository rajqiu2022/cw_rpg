extends RefCounted
## Safe conservative closure, not a claim of pixel-tight minimal bounds.
const OLD := preload("res://scripts/dev/world_map_v15_v9_visual_quality_proposal_surface.gd")
const NEW := preload("res://scripts/dev/world_farmland_coherent_author_v2_20261014.gd")
const IDS := ["r2_c1","r2_c2","r2_c3","r3_c1","r3_c2","r3_c3","r4_c2","r4_c3","r5_c4","r5_c5","r6_c4","r6_c5"]
const WORLD := Vector2i(12288,8192)
const TILE := Vector2i(1536,1024)
const HALO := 96
const PPM_Z := 72.40773439
var error := ""

func _whole_canvas_exact(value: Variant) -> bool:
	# JSON exact integral dimensions may arrive as Float64; don't truncate,
	# apply epsilon, or rely on Array int/float representation equality.
	if not value is Array or value.size()!=2: return false
	for index in 2:
		if typeof(value[index]) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(value[index])) or float(value[index])!=float(24576 if index==0 else 16384): return false
	return true

func resampler_support() -> Dictionary:
	# Actual current Godot Image implementation, exact scale2 and both source
	# phases. Mixed backgrounds expose positive/negative finite kernel lobes;
	# this bounds observable RGBA8 output, not an assumed resampler brand name.
	var maximum:=0
	var cases: Array[Dictionary]=[]
	for sx in [31,32]:
		for sy in [31,32]:
			for background in [0,127,255]:
				for impulse in [0,255]:
					if background==impulse: continue
					var baseline:=Image.create(64,64,false,Image.FORMAT_RGBA8)
					baseline.fill(Color(float(background)/255.0,float(background)/255.0,float(background)/255.0,1.0))
					var changed:=baseline.duplicate() as Image
					changed.set_pixel(sx,sy,Color(float(impulse)/255.0,float(impulse)/255.0,float(impulse)/255.0,1.0))
					baseline.resize(32,32,Image.INTERPOLATE_LANCZOS)
					changed.resize(32,32,Image.INTERPOLATE_LANCZOS)
					var radius:=0; var affected:=0
					for y in 32:
						for x in 32:
							if baseline.get_pixel(x,y)==changed.get_pixel(x,y): continue
							affected+=1; radius=maxi(radius,maxi(absi(x-sx/2),absi(y-sy/2)))
					maximum=maxi(maximum,radius)
					cases.append({"source_phase":[sx%2,sy%2],"background":background,"impulse":impulse,"logical_radius":radius,"affected_pixels":affected})
	if maximum<=0 or maximum>4:
		error="Current actual scale2 Lanczos observable footprint exceeds bounded4 policy."; return {}
	return {"implementation":"ACTUAL_GODOT_IMAGE_RGBA8_INTERPOLATE_LANCZOS_64_TO32_SCALE2","cases":cases,"measured_logical_radius":maximum,"allowed_logical_support_px":maximum+1,"extra_phase_alignment_guard_px":1,"actual_measured":true,"CPU_max_probe_pixels":4096,"wholeCPU_Image":false}

func derive(rf: PackedByteArray,camera: Dictionary) -> Dictionary:
	if rf.size()!=1537*1025*4: error="Exact original RF grid required."; return {}
	# Caller independently pins the original whole proof/RF. This reduction
	# applies only to its centered, 45-degree orthographic camera—not a ROI view.
	if camera.get("projection")!=1 or camera.get("keep_aspect")!=1 or camera.get("size_m")!=80.0 or camera.get("PPM_X")!=102.4 or not _whole_canvas_exact(camera.get("whole_visual_native_canvas")):
		error="Original whole45 camera/source PPM binding required."; return {}
	var kernel:=resampler_support()
	if kernel.is_empty(): return {}
	var parcels: Array[Dictionary]=[]
	var cells: Dictionary={}
	for revision: String in ["old18","new12"]:
		var source: Array=OLD.V9_PARCELS if revision=="old18" else NEW.PARCELS
		for index in source.size():
			var parcel: Vector4=source[index]
			var angle: float=sin(float(index)*2.17)*.61 if revision=="old18" else 0.0
			var grow: float=1.014 if revision=="old18" else 1.0
			var span_x: float=(absf(cos(angle))*parcel.z+absf(sin(angle))*parcel.w)*grow
			var span_y: float=(absf(sin(angle))*parcel.z+absf(cos(angle))*parcel.w)*grow
			# Extra one source pixel conservatively covers float32 shader angle/
			# multiplication boundaries. No RF, mesh or camera is modified.
			var low:=Vector2i(floori(parcel.x-span_x)-1,floori(parcel.y-span_y)-1)
			var high:=Vector2i(ceili(parcel.x+span_x)+1,ceili(parcel.y+span_y)+1)
			var min_h:=INF; var max_h:=-INF
			for y in range(floori(float(low.y)/8.0),ceili(float(high.y)/8.0)+1):
				for x in range(floori(float(low.x)/8.0),ceili(float(high.x)/8.0)+1):
					var height: float=rf.decode_float((y*1537+x)*4)
					if not is_finite(height): error="Nonfinite original RF node."; return {}
					min_h=minf(min_h,height); max_h=maxf(max_h,height)
			# Stored triangle height is affine within each cell. Its extrema are
			# bounded by all surrounding RF vertices, including outside corners.
			var projected_low:=Vector2i(low.x,floori(float(low.y)-max_h*PPM_Z)-1)
			var projected_high:=Vector2i(high.x,ceili(float(high.y)-min_h*PPM_Z)+1)
			var projected:=Rect2i(projected_low,projected_high-projected_low+Vector2i.ONE)
			var halo_rect:=projected.grow(HALO).intersection(Rect2i(Vector2i.ZERO,WORLD))
			var touched: Array[String]=[]
			for row in range(halo_rect.position.y/TILE.y,(halo_rect.end.y-1)/TILE.y+1):
				for col in range(halo_rect.position.x/TILE.x,(halo_rect.end.x-1)/TILE.x+1):
					var id:="r%d_c%d"%[row,col]
					cells[id]=true; touched.append(id)
			parcels.append({"revision":revision,"index":index,"parcel":[parcel.x,parcel.y,parcel.z,parcel.w],"angle_radians":angle,"owner_outer_margin":grow,"source_bounds":[low.x,low.y,high.x,high.y],"RF_vertex_extrema":[min_h,max_h],"screen_bounds":[projected.position.x,projected.position.y,projected.size.x,projected.size.y],"halo_bounds":[halo_rect.position.x,halo_rect.position.y,halo_rect.size.x,halo_rect.size.y],"tiles":touched})
	var actual: Array=cells.keys(); actual.sort()
	if actual!=IDS: error="Calculated current old18+new12+RF/96 closure differs from fixed12."; return {}
	var tiles: Array[Dictionary]=[]
	for id: String in IDS:
		var pieces:=id.split("_")
		var row:=int(pieces[0].trim_prefix("r")); var col:=int(pieces[1].trim_prefix("c"))
		tiles.append({"id":id,"rect":Rect2i(Vector2i(col*TILE.x,row*TILE.y),TILE),"row":row,"col":col})
	return {"schema":1,"scope":"CONSERVATIVE_OLD18_NEW12_ORIGINAL_RF_SCREEN_PROJECTION_PLUS96","old_count":18,"new_count":12,"tile_count":12,"ids":IDS.duplicate(),"tiles":tiles,"parcels":parcels,"numeric_source_padding_px":1,"numeric_screen_padding_px":1,"halo_px":HALO,"resampler_support":kernel,"projection_binding":{"original_whole_camera":camera.duplicate(true),"source_PPM_X":102.4,"source_PPM_Z":PPM_Z,"formula":"screen_x=source_x; screen_y=source_y-original_affine_RF_height*PPM_Z","fixed_original45_only":true,"float32_camera_and_shader_roundoff_covered_by_extra1px":true},"RF_or_NAV_changed":false,"pixel_tight_minimum_claim":false}
