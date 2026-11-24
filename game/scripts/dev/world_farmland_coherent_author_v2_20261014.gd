extends RefCounted
## NEW full-rectangle candidate. V1 BB5A and its seven clipped plots stay intact.
const ID := "WORLD_FARMLAND_TWO_COHERENT_WARDS_V2_20261014"
const SIZE := Vector2i(12288,8192)
const PARCELS := [
	Vector4(3210,3500,130,105),Vector4(3520,3500,130,105),Vector4(3830,3500,130,105),Vector4(4140,3500,130,105),
	Vector4(3210,3750,130,105),Vector4(3520,3750,130,105),Vector4(3830,3750,130,105),Vector4(4140,3750,130,105),
	Vector4(7180,6470,100,50),Vector4(7180,6610,100,50),Vector4(7180,6750,100,50),Vector4(7180,6890,100,50)]
const ROIS := [{"id":"linxi_fields","rect":Rect2i(2920,3300,1536,1024)}, {"id":"jiangnan_fields","rect":Rect2i(6540,5940,1536,1024)}]
const ROAD_CLEARANCE := 32
const WATER_CLEARANCE := 64
var error := ""

func height_at(bytes: PackedByteArray,p: Vector2) -> float:
	var q := p/8.0
	var base := Vector2i(floori(q.x),floori(q.y)).clamp(Vector2i.ZERO,Vector2i(1535,1023))
	var f := q-Vector2(base)
	var offset := (base.y*1537+base.x)*4
	var a := bytes.decode_float(offset); var b := bytes.decode_float(offset+4)
	var c := bytes.decode_float(offset+1537*4); var d := bytes.decode_float(offset+1537*4+4)
	return a+(b-a)*f.x+(c-a)*f.y if f.x+f.y <= 1.0 else d+(c-d)*(1.0-f.x)+(b-d)*(1.0-f.y)

func audit(roads: Image,eco: Image,rf: PackedByteArray) -> Dictionary:
	if roads == null or eco == null or roads.get_size() != SIZE/4 or eco.get_size() != SIZE/4 or rf.size() != 1537*1025*4:
		error = "Exact original owner maps/RF required."; return {}
	var records: Array[Dictionary] = []
	var all_clear := true
	for index in PARCELS.size():
		var parcel: Vector4 = PARCELS[index]
		var samples := 0; var excluded := 0
		for y in range(int(parcel.y-parcel.w),int(parcel.y+parcel.w)+1,4):
			for x in range(int(parcel.x-parcel.z),int(parcel.x+parcel.z)+1,4):
				var p := Vector2(x,y); var blocked := false
				var owner := eco.get_pixel(x/4,y/4)
				blocked = maxf(maxf(owner.r,owner.g),maxf(owner.b,owner.a)) >= .02
				for dy in [-ROAD_CLEARANCE,0,ROAD_CLEARANCE]:
					for dx in [-ROAD_CLEARANCE,0,ROAD_CLEARANCE]:
						var r := roads.get_pixel(int((p.x+dx)/4.0),int((p.y+dy)/4.0))
						blocked = blocked or r.r >= .02 or r.g >= .02 or r.b >= .02
				for dy in [-WATER_CLEARANCE,0,WATER_CLEARANCE]:
					for dx in [-WATER_CLEARANCE,0,WATER_CLEARANCE]:
						blocked = blocked or height_at(rf,p+Vector2(dx,dy)) < -.015
				samples += 1
				if blocked: excluded += 1
		all_clear = all_clear and excluded==0
		records.append({"index":index,"parcel":[parcel.x,parcel.y,parcel.z,parcel.w],"group":"linxi" if index<8 else "jiangnan","angle":0.0,"full_4px_samples":samples,"excluded_samples":excluded,"full_rectangle_clear":excluded==0})
	return {"identity":ID,"parcel_count":12,"all_rectangles_clear":all_clear,"records":records,"road_clearance_px":ROAD_CLEARANCE,"water_clearance_px":WATER_CLEARANCE,"scope":"CPU_FULL4PX_RECTANGLES_NOT_CONTINUOUS_SHADER_OR_PHYSICS_APPROVAL","nav_changed":false}

func literal_code() -> String:
	var code := "float field_owner=0.,crop=0.,furrow_n=0.;\n"
	for index in PARCELS.size():
		var p: Vector4 = PARCELS[index]
		code += """ {
 vec4 parcel=vec4(%.9f,%.9f,%.9f,%.9f);vec2 delta=p-parcel.xy;
 vec2 local=delta/parcel.zw;
 float owner=1.-smoothstep(.94,1.,max(abs(local.x),abs(local.y)));
 float phase=p.x*.523598775598;
 if(owner>field_owner){field_owner=owner;crop=.18+.25*smoothstep(.60,.90,.5+.5*sin(phase));furrow_n=cos(phase);}
 }
""" % [p.x,p.y,p.z,p.w]
	return code
