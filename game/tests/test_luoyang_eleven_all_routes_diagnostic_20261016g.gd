extends "res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"
## Exhaustive diagnostic only; failed routes remain failures. No import/Field/module run.
const REG="res://data/maps/luoyang_assembled_interiors_20261016g/registry.json"
const REG_SHA="91caba319a4da4e76e7058dc18b3c27a825248096a071797559b34684fdd3771"
const RAW=preload("res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd")
const RAW_PATH="res://tests/helpers/luoyang_eleven_rooms_raw_polygon_oracle_v2_20261016g.gd"
const RAW_SHA="0f00d4a8a7bc7f514d4b0859275c2eb6d03296dd81eaa170416694c6068b2835"
func _v(value: Array) -> Vector2: return Vector2(value[0],value[1])
func _run() -> void:
	var began: int=Time.get_ticks_msec();deadline=began+60000
	root.get_node("PlatformBridge").call("set_checkpoint_saves_suspended",true);players_before=saves()
	var ready: bool=track(REG,REG_SHA) and track(RAW_PATH,RAW_SHA) and track(get_script().resource_path,FileAccess.get_sha256(get_script().resource_path)) and track("res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd",FileAccess.get_sha256("res://tests/test_luoyang_city_life_cpu_draft_20261016f.gd"))
	var route_count: int=0;var bad_routes: int=0;var bad_segments: int=0;var rooms: int=0
	if ready:
		var registry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(REG))
		for row: Dictionary in registry.rooms.values():
			if row.get("reuse_existing_accepted",false): continue
			if Time.get_ticks_msec()>=deadline: ready=false;break
			if not track(String(row.author_path),String(row.author_sha256)): ready=false;continue
			var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(row.author_path))
			var geometry: Dictionary=data.geometry
			var physical: Array=[]
			for base: Dictionary in geometry.furniture_bases: physical.append({"id":base.id,"kind":base.kind,"points_px":base.ground_polygon_px})
			var oracle:=RAW.new()
			if not check(oracle.configure(geometry.floor_regions_px,physical,Vector2(1536,1024),Vector2(1920,1280),geometry.foot_forbidden_regions_px),"Independent declared geometry configuration "+String(row.type_id),oracle.errors): ready=false;continue
			rooms+=1
			for route: Dictionary in geometry.required_routes:
				if Time.get_ticks_msec()>=deadline: ready=false;break
				route_count+=1
				var denials: Array=[];var samples: int=0
				for index: int in range(1,route.points_px.size()):
					var a: Vector2=_v(route.points_px[index-1])*1.25
					var b: Vector2=_v(route.points_px[index])*1.25
					var result: Dictionary=oracle.segment(a,b,deadline)
					if result.get("clear",false): samples+=int(result.samples)
					else:
						var rejected: Dictionary=result.duplicate(true)
						rejected["segment"]=index;rejected["from_source"]=route.points_px[index-1];rejected["to_source"]=route.points_px[index]
						if result.has("index") and result.has("steps"): rejected["sample_actual_foot"]=a.lerp(b,float(result.index)/float(result.steps))
						denials.append(rejected);bad_segments+=1
				if not denials.is_empty(): bad_routes+=1
				check(denials.is_empty(),"Diagnostic original route "+String(row.type_id)+"/"+String(route.id),denials)
				records.append({"kind":"ORIGINAL_ROUTE_DIAGNOSTIC","type":row.type_id,"route":route.id,"points_source":route.points_px,"clear":denials.is_empty(),"clear_segment_samples":samples,"denials":denials})
	check(rooms==10 and route_count==71,"All ten original authors and all71 routes visited without first-failure truncation",{"rooms":rooms,"routes":route_count})
	records.append({"kind":"DIAGNOSTIC_SCOPE","rooms":rooms,"routes":route_count,"bad_routes":bad_routes,"bad_segments":bad_segments,"old_smith_replayed":false,"RGBA_repeated":false,"module_or_Field_executed":false,"full_acceptance_claimed":false})
	finish("res://build/luoyang_eleven_all_routes_diagnostic_20261016g/%d_%d"%[OS.get_process_id(),began],began,ready and rooms==10 and route_count==71 and bad_routes==0,"ALL71_ORIGINAL_ROUTES_DIAGNOSTIC_NOT_FULL_ROOM_ACCEPTANCE")
