extends "res://scripts/dev/world_map_v15_v9_visual_quality_proposal_ecology_source.gd"

## Independent response to ROOT193 actual visual failure. Visual owners only.
## All geometry/RF/selector/sites/routes/doors/support are inherited untouched.
const V9B_ID := "V9B_DRY_RF_REGIONAL_MINERAL_SILT_SNOW_OWNERS_PROPOSAL"

func habitat(p: Vector2) -> Vector4:
	var owner: Vector4=super.habitat(p)
	var h: float=triangle_height(p)
	if h<=WATER_Y: return owner
	var q: Vector2=p.clamp(Vector2.ZERO,Vector2(SIZE))/float(GRID_STEP)
	var cell:=Vector2i(mini(floori(q.x),GRID_SIZE.x-2),mini(floori(q.y),GRID_SIZE.y-2))
	var local: Vector2=q-Vector2(cell)
	var grade: float=triangle_gradient(cell,local.x+local.y>1.)
	var lane: Vector2=road_distance(p)
	var clear: float=smoothstep(lane.y+4.,lane.y+36.,lane.x)
	var dry: float=smoothstep(WATER_Y,WATER_Y+.04,h)
	var patch: float=_v9_noise(Vector2(p.x/102.4,p.y/72.40773439)/2.6)*.62+_v9_noise(p/630.+Vector2(4,11))*.38
	var north: float=1.-smoothstep(.50,1.12,((p-Vector2(5000,430))/Vector2(4700,950)).length())
	# Stronger continuous snow accumulation on the SAME existing upper shoulders;
	# steep faces remain mineral. Does not remove the frozen shelf silhouette.
	var accumulation: float=smoothstep(.80,1.5,h)*(1.-smoothstep(.42,1.2,grade))*(.66+.30*smoothstep(.25,.70,patch))
	owner.w=lerpf(owner.w,accumulation,north)
	var west: float=1.-smoothstep(.48,1.1,((p-Vector2(1160,3100))/Vector2(1160,2200)).length())
	owner.y=maxf(owner.y,west*clear*dry*(.62+.32*smoothstep(.24,.70,patch)))
	var marsh: float=1.-smoothstep(.46,1.13,((p-Vector2(10920,6850))/Vector2(1820,1640)).length())
	var tea: float=smoothstep(.40,1.12,((p-Vector2(11100,7900))/Vector2(760,690)).length())
	var low: float=(1.-smoothstep(.20,.67,h))*(1.-smoothstep(.12,.43,grade))
	owner.z=maxf(owner.z,marsh*tea*low*dry*clear*(.82+.16*smoothstep(.25,.72,patch)))
	return owner.clamp(Vector4.ZERO,Vector4.ONE)

func v9_execution_contract() -> Dictionary:
	var record: Dictionary=super.v9_execution_contract()
	record["identity"]=V9B_ID
	record["actual_script"]={"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)}
	record["parent"]={"path":"res://scripts/dev/world_map_v15_v9_visual_quality_proposal_ecology_source.gd","sha256":FileAccess.get_sha256("res://scripts/dev/world_map_v15_v9_visual_quality_proposal_ecology_source.gd")}
	record["limitations"]="dry soil/snow/mineral materials only; fixed RF river/shelves/sites cannot become natural new wetland/reeds or weathered rock geometry"
	return record
