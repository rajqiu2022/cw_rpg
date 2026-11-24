extends "res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd"

## NEW authoring candidate. Only the four visual material owners change.
## No prepare/site/height/selector/route/door/solid/support override.
const V9_ID := "V9_VISUAL_QUALITY_RF_DRY_MATERIAL_OWNERS_PROPOSAL"

func _v9_hash(p: Vector2) -> float:
	var v: float=sin(p.dot(Vector2(127.1,311.7)))*43758.5453
	return v-floorf(v)

func _v9_noise(p: Vector2) -> float:
	var i:=p.floor()
	var f: Vector2=p-i
	f=f*f*(Vector2(3,3)-2.*f)
	return lerpf(lerpf(_v9_hash(i),_v9_hash(i+Vector2.RIGHT),f.x),lerpf(_v9_hash(i+Vector2.DOWN),_v9_hash(i+Vector2.ONE),f.x),f.y)

func habitat(p: Vector2) -> Vector4:
	var owner: Vector4=super.habitat(p)
	var h: float=triangle_height(p)
	if h<=WATER_Y: return owner
	var q: Vector2=p.clamp(Vector2.ZERO,Vector2(SIZE))/float(GRID_STEP)
	var cell:=Vector2i(mini(floori(q.x),GRID_SIZE.x-2),mini(floori(q.y),GRID_SIZE.y-2))
	var local: Vector2=q-Vector2(cell)
	var grade: float=triangle_gradient(cell,local.x+local.y>1.)
	var road: Vector2=road_distance(p)
	var clear: float=smoothstep(road.y+4.,road.y+36.,road.x)
	var dry: float=smoothstep(WATER_Y,WATER_Y+.04,h)
	# Rock material is allowed on the existing dry limestone apron, not only
	# high mountains. This does not invent rock geometry, cliffs or blockers.
	var west: float=1.-smoothstep(.48,1.1,((p-Vector2(1160,3100))/Vector2(1160,2200)).length())
	var patch: float=_v9_noise(Vector2(p.x/102.4,p.y/72.40773439)/3.7)*.55+_v9_noise(p/880.+Vector2(8,-3))*.45
	owner.y=maxf(owner.y,west*clear*dry*(.38+.55*smoothstep(.28,.70,patch)))
	# Accumulation is broken across real RF height/grade and metre-scale patches.
	# The frozen shelf silhouette remains; no displacement or fake weathered mesh.
	var north: float=1.-smoothstep(.50,1.12,((p-Vector2(5000,430))/Vector2(4700,950)).length())
	var snow: float=smoothstep(.90,2.0,h)*(1.-smoothstep(.30,1.05,grade))
	var deposit: float=.30+.66*smoothstep(.30,.69,patch)
	owner.w=lerpf(owner.w,snow*deposit,north)
	owner.y=maxf(owner.y,north*dry*(1.-snow*deposit)*smoothstep(.75,2.1,h)*.86)
	# Existing legal low dry soil only. No ALPHA, water-plane, selector or NAV
	# override. The visible sheen later is a soil material, NOT a new puddle body.
	var marsh: float=1.-smoothstep(.46,1.13,((p-Vector2(10920,6850))/Vector2(1820,1640)).length())
	var tea: float=smoothstep(.40,1.12,((p-Vector2(11100,7900))/Vector2(760,690)).length())
	var low: float=(1.-smoothstep(.20,.67,h))*(1.-smoothstep(.12,.43,grade))
	owner.z=maxf(owner.z,marsh*tea*low*dry*clear*(.68+.28*smoothstep(.25,.72,patch)))
	return owner.clamp(Vector4.ZERO,Vector4.ONE)

func v9_execution_contract() -> Dictionary:
	return {"identity":V9_ID,"actual_script":{"path":get_script().resource_path,"sha256":FileAccess.get_sha256(get_script().resource_path)},
		"parent":{"path":"res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd","sha256":FileAccess.get_sha256("res://scripts/dev/world_map_v15_complete_v8_ecology_source_proposal.gd")},
		"scope":"source4px visual material owners only; not changed landform/water/walk support",
		"unchanged":"cached Float32 RF/global mesh/topology/selector/all native sites/27 routes/16 doors/solids/support",
		"limitations":"cannot remove frozen rectangular shelf geometry; no new reeds or physical wetland",
		"production_approved":false,"visual_approved":false}
